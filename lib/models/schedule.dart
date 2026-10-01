enum ScheduleRepeat {
  once('Tek sefer'),
  daily('Her gün'),
  weekly('Her hafta');

  const ScheduleRepeat(this.label);

  final String label;
}

/// Sulama planı. Gerçek sistemde ESP32 belleğinde (NVS) saklanır, böylece
/// internet kesilse de çalışır.
class WateringSchedule {
  const WateringSchedule({
    required this.id,
    required this.potId,
    required this.time,
    required this.repeat,
    required this.amountPercent,
    required this.createdAt,
    this.active = true,
    this.lastRun,
  });

  final String id;
  final String potId;

  /// İlk sulama zamanı. Günlük planda saat, haftalık planda gün + saat
  /// bu değerden alınır.
  final DateTime time;
  final ScheduleRepeat repeat;
  final int amountPercent;
  final bool active;
  final DateTime createdAt;
  final DateTime? lastRun;

  /// [now] anına kadarki en son planlanmış zaman. Henüz hiç gelmediyse null.
  DateTime? lastOccurrence(DateTime now) {
    switch (repeat) {
      case ScheduleRepeat.once:
        return time.isAfter(now) ? null : time;
      case ScheduleRepeat.daily:
        var candidate = DateTime(now.year, now.month, now.day, time.hour, time.minute);
        if (candidate.isAfter(now)) {
          candidate = DateTime(now.year, now.month, now.day - 1, time.hour, time.minute);
        }
        return candidate.isBefore(time) ? null : candidate;
      case ScheduleRepeat.weekly:
        final diff = (now.weekday - time.weekday) % 7;
        var candidate = DateTime(now.year, now.month, now.day - diff, time.hour, time.minute);
        if (candidate.isAfter(now)) {
          candidate = DateTime(now.year, now.month, now.day - diff - 7, time.hour, time.minute);
        }
        return candidate.isBefore(time) ? null : candidate;
    }
  }

  /// [now] anından sonraki ilk planlanmış zaman. Tek seferlik plan geçtiyse null.
  DateTime? nextOccurrence(DateTime now) {
    if (time.isAfter(now)) return time;
    switch (repeat) {
      case ScheduleRepeat.once:
        return null;
      case ScheduleRepeat.daily:
        var candidate = DateTime(now.year, now.month, now.day, time.hour, time.minute);
        if (!candidate.isAfter(now)) {
          candidate = DateTime(now.year, now.month, now.day + 1, time.hour, time.minute);
        }
        return candidate;
      case ScheduleRepeat.weekly:
        final diff = (time.weekday - now.weekday) % 7;
        var candidate = DateTime(now.year, now.month, now.day + diff, time.hour, time.minute);
        if (!candidate.isAfter(now)) {
          candidate = DateTime(now.year, now.month, now.day + diff + 7, time.hour, time.minute);
        }
        return candidate;
    }
  }

  /// Plan şu an çalıştırılmalı mı? Çok eski (kaçırılmış) zamanlar [grace]
  /// süresinden sonra atlanır.
  bool isDue(DateTime now, {Duration grace = const Duration(minutes: 5)}) {
    if (!active) return false;
    final occurrence = lastOccurrence(now);
    if (occurrence == null) return false;
    if (now.difference(occurrence) > grace) return false;
    final reference = lastRun ?? createdAt;
    return occurrence.isAfter(reference);
  }

  WateringSchedule copyWith({
    DateTime? time,
    ScheduleRepeat? repeat,
    int? amountPercent,
    bool? active,
    DateTime? lastRun,
  }) {
    return WateringSchedule(
      id: id,
      potId: potId,
      time: time ?? this.time,
      repeat: repeat ?? this.repeat,
      amountPercent: amountPercent ?? this.amountPercent,
      createdAt: createdAt,
      active: active ?? this.active,
      lastRun: lastRun ?? this.lastRun,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'potId': potId,
        'time': time.toIso8601String(),
        'repeat': repeat.name,
        'amountPercent': amountPercent,
        'active': active,
        'createdAt': createdAt.toIso8601String(),
        'lastRun': lastRun?.toIso8601String(),
      };

  factory WateringSchedule.fromJson(Map<String, dynamic> json) {
    return WateringSchedule(
      id: json['id'] as String,
      potId: json['potId'] as String,
      time: DateTime.parse(json['time'] as String),
      repeat: ScheduleRepeat.values.byName(json['repeat'] as String),
      amountPercent: json['amountPercent'] as int,
      active: json['active'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastRun: json['lastRun'] == null ? null : DateTime.parse(json['lastRun'] as String),
    );
  }
}
