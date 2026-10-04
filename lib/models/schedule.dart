/// Saksının haftalık sulama programı ("Sulama programı" ekranı).
///
/// Gerçek sistemde ESP32 belleğinde (NVS) saklanır, böylece internet kesilse
/// de çalışır. Her saksı için tek program vardır; [id] saksının kimliğidir.
class WateringSchedule {
  const WateringSchedule({
    required this.id,
    required this.potId,
    required this.hour,
    required this.minute,
    required this.weekdays,
    required this.amountPercent,
    required this.createdAt,
    this.active = true,
    this.lastRun,
  });

  /// Varsayılan program: Pzt, Çar, Cum, Paz 08:00, %40 su.
  factory WateringSchedule.initial(String potId, DateTime now) => WateringSchedule(
        id: potId,
        potId: potId,
        hour: 8,
        minute: 0,
        weekdays: const {
          DateTime.monday,
          DateTime.wednesday,
          DateTime.friday,
          DateTime.sunday,
        },
        amountPercent: 40,
        createdAt: now,
      );

  final String id;
  final String potId;
  final int hour;
  final int minute;

  /// Sulama günleri; [DateTime.monday] (1) ile [DateTime.sunday] (7) arası.
  final Set<int> weekdays;
  final int amountPercent;
  final bool active;
  final DateTime createdAt;
  final DateTime? lastRun;

  DateTime _at(DateTime day) => DateTime(day.year, day.month, day.day, hour, minute);

  /// [now] anına kadarki en son planlanmış zaman. Henüz hiç gelmediyse null.
  DateTime? lastOccurrence(DateTime now) {
    if (weekdays.isEmpty) return null;
    for (var i = 0; i <= 7; i++) {
      final day = DateTime(now.year, now.month, now.day - i);
      if (!weekdays.contains(day.weekday)) continue;
      final candidate = _at(day);
      if (!candidate.isAfter(now)) return candidate;
    }
    return null;
  }

  /// [now] anından sonraki ilk planlanmış zaman.
  DateTime? nextOccurrence(DateTime now) {
    if (weekdays.isEmpty) return null;
    for (var i = 0; i <= 7; i++) {
      final day = DateTime(now.year, now.month, now.day + i);
      if (!weekdays.contains(day.weekday)) continue;
      final candidate = _at(day);
      if (candidate.isAfter(now)) return candidate;
    }
    return null;
  }

  /// Program şu an çalıştırılmalı mı? Çok eski (kaçırılmış) zamanlar [grace]
  /// süresinden sonra atlanır. Program kaydedilmeden önceki zamanlar da atlanır.
  bool isDue(DateTime now, {Duration grace = const Duration(minutes: 5)}) {
    if (!active) return false;
    final occurrence = lastOccurrence(now);
    if (occurrence == null) return false;
    if (now.difference(occurrence) > grace) return false;
    final reference = lastRun ?? createdAt;
    return occurrence.isAfter(reference);
  }

  WateringSchedule copyWith({
    int? hour,
    int? minute,
    Set<int>? weekdays,
    int? amountPercent,
    bool? active,
    DateTime? createdAt,
    DateTime? lastRun,
  }) {
    return WateringSchedule(
      id: id,
      potId: potId,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      weekdays: weekdays ?? this.weekdays,
      amountPercent: amountPercent ?? this.amountPercent,
      createdAt: createdAt ?? this.createdAt,
      active: active ?? this.active,
      lastRun: lastRun ?? this.lastRun,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'potId': potId,
        'hour': hour,
        'minute': minute,
        'weekdays': (weekdays.toList()..sort()),
        'amountPercent': amountPercent,
        'active': active,
        'createdAt': createdAt.toIso8601String(),
        'lastRun': lastRun?.toIso8601String(),
      };

  factory WateringSchedule.fromJson(Map<String, dynamic> json) {
    return WateringSchedule(
      id: json['id'] as String,
      potId: json['potId'] as String,
      hour: json['hour'] as int,
      minute: json['minute'] as int,
      weekdays: (json['weekdays'] as List<dynamic>).map((e) => e as int).toSet(),
      amountPercent: json['amountPercent'] as int,
      active: json['active'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastRun: json['lastRun'] == null ? null : DateTime.parse(json['lastRun'] as String),
    );
  }
}
