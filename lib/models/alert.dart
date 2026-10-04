import '../l10n/strings.dart';

enum AlertType {
  plantDry(isWarning: true),
  tankLow(isWarning: true),
  deviceOffline(isWarning: true),
  wateringBlocked(isWarning: true),
  wateringDone(isWarning: false);

  const AlertType({required this.isWarning});

  final bool isWarning;

  static AlertType fromName(String? name) =>
      values.firstWhere((t) => t.name == name, orElse: () => AlertType.wateringDone);
}

/// Uygulama içi bildirim kaydı.
///
/// Metin saklanmaz; yalnızca tür ve değerler saklanır, böylece dil
/// değişince eski bildirimler de yeni dilde görünür.
///
/// [args] türe göre değişir:
/// - plantDry: bitki adı, nem (%)
/// - tankLow: doluluk (%), kritik mi ("1" / "0")
/// - deviceOffline: veri gelmeyen süre (sn)
/// - wateringDone: bitki adı, miktar (%)
/// - wateringBlocked: bitki adı
class AppAlert {
  const AppAlert({
    required this.id,
    required this.type,
    required this.time,
    this.potId,
    this.args = const [],
    this.noteKey,
    this.noteArgs = const [],
    this.read = false,
  });

  final String id;
  final AlertType type;
  final String? potId;
  final DateTime time;
  final List<String> args;

  /// Cihazın eklediği not (çeviri anahtarı ve değerleri).
  final String? noteKey;
  final List<String> noteArgs;
  final bool read;

  String _arg(int i) => i < args.length ? args[i] : '';

  /// Bitki adı. Hazır bitkilerin adı seçili dile çevrilir, kullanıcının eklediği
  /// bitkilerin adı olduğu gibi kalır.
  String get _plant => Strings.t(_arg(0));

  String? get _note => noteKey == null ? null : Strings.t(noteKey!, noteArgs);

  /// Bildirim başlığı, seçili dilde.
  String get title => switch (type) {
        AlertType.plantDry => Strings.t('{0} susadı', [_plant]),
        AlertType.tankLow => Strings.t('Su deposu azalıyor'),
        AlertType.deviceOffline => Strings.t('Cihaz çevrimdışı'),
        AlertType.wateringBlocked => Strings.t('Sulama yapılamadı'),
        AlertType.wateringDone => Strings.t('Sulama tamamlandı'),
      };

  /// Bildirim metni, seçili dilde.
  String get message => switch (type) {
        AlertType.plantDry => Strings.t('Toprak nemi %{0}\'e düştü. Sulama zamanı.', [_arg(1)]),
        AlertType.tankLow => _arg(1) == '1'
            ? Strings.t('Depo seviyesi %{0}. Pompalar kilitlendi, depoyu doldur.', [_arg(0)])
            : Strings.t('Depo seviyesi %{0}. Yakında doldurman gerekebilir.', [_arg(0)]),
        AlertType.deviceOffline =>
          Strings.t('Cihazdan {0} sn\'dir veri gelmiyor. Programlı sulama cihazda sürer.', [_arg(0)]),
        AlertType.wateringDone => [
            Strings.t('{0} · %{1} su verildi.', [_plant, _arg(1)]),
            ?_note,
          ].join(' '),
        AlertType.wateringBlocked => Strings.t(
            '{0}: {1}',
            [_plant, _note ?? Strings.t('Bir güvenlik kuralı sulamayı engelledi.')],
          ),
      };

  AppAlert copyWith({bool? read}) => AppAlert(
        id: id,
        type: type,
        potId: potId,
        time: time,
        args: args,
        noteKey: noteKey,
        noteArgs: noteArgs,
        read: read ?? this.read,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'potId': potId,
        'time': time.toIso8601String(),
        'args': args,
        'noteKey': noteKey,
        'noteArgs': noteArgs,
        'read': read,
      };

  factory AppAlert.fromJson(Map<String, dynamic> json) {
    List<String> strings(Object? value) =>
        (value as List<dynamic>? ?? const []).map((e) => '$e').toList();
    return AppAlert(
      id: json['id'] as String,
      type: AlertType.fromName(json['type'] as String?),
      potId: json['potId'] as String?,
      time: DateTime.parse(json['time'] as String),
      args: strings(json['args']),
      noteKey: json['noteKey'] as String?,
      noteArgs: strings(json['noteArgs']),
      read: json['read'] as bool? ?? false,
    );
  }
}
