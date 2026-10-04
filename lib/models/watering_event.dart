import '../l10n/strings.dart';

enum WateringSource {
  manual('Manuel'),
  scheduled('Programlı'),
  auto('Otomatik');

  const WateringSource(this.label);

  /// Türkçe ad; ekranda `t(label)` ile çevrilir.
  final String label;
}

/// Cihazın tamamladığı ya da reddettiği bir sulama.
class WateringEvent {
  const WateringEvent({
    required this.potId,
    required this.time,
    required this.source,
    required this.amountPercent,
    required this.success,
    this.ml = 0,
    this.durationSeconds = 0,
    this.message,
    this.scheduleId,
  });

  final String potId;
  final DateTime time;
  final WateringSource source;
  final int amountPercent;
  final bool success;
  final double ml;
  final double durationSeconds;

  /// Engellendiyse nedeni ya da ek bilgi.
  final Msg? message;

  /// Programlı sulamada ilgili programın kimliği.
  final String? scheduleId;
}

/// "Şimdi sula" komutunun cihazdan dönen ilk yanıtı.
class WateringResult {
  const WateringResult.accepted({required this.ml, required this.durationSeconds})
      : accepted = true,
        message = null;

  const WateringResult.rejected(Msg this.message)
      : accepted = false,
        ml = 0,
        durationSeconds = 0;

  final bool accepted;
  final Msg? message;
  final double ml;
  final double durationSeconds;
}
