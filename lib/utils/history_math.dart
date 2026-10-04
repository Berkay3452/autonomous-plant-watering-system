import '../l10n/strings.dart';
import '../models/reading.dart';
import 'formatters.dart';

/// Geçmiş ekranındaki zaman aralığı seçimi.
enum ChartRange {
  day('Gün', Duration(days: 1), Duration(minutes: 15)),
  week('Hafta', Duration(days: 7), Duration(hours: 1)),
  month('Ay', Duration(days: 30), Duration(hours: 4));

  const ChartRange(this.label, this.duration, this.bucket);

  final String label;
  final Duration duration;

  /// Grafikte noktaların gruplanacağı aralık.
  final Duration bucket;
}

/// Grafiğin alt eksenindeki bir etiket.
class ChartTick {
  const ChartTick(this.time, this.label);

  final DateTime time;
  final String label;
}

/// Nem grafiğinin gösterdiği zaman penceresi ve eksen etiketleri.
class ChartWindow {
  const ChartWindow(this.start, this.end, this.ticks);

  final DateTime start;
  final DateTime end;
  final List<ChartTick> ticks;
}

/// Sıcaklık çubuk grafiğindeki tek çubuk. [value] null ise henüz veri yoktur.
class BarBucket {
  const BarBucket(this.label, this.value, {this.highlight = false});

  final String label;
  final double? value;
  final bool highlight;
}

DateTime startOfDay(DateTime t) => DateTime(t.year, t.month, t.day);

ChartWindow chartWindow(ChartRange range, DateTime now) {
  switch (range) {
    case ChartRange.day:
      final start = startOfDay(now);
      final ticks = <ChartTick>[];
      for (final hour in const [0, 6, 12, 18]) {
        final t = start.add(Duration(hours: hour));
        // "Şimdi" etiketine çok yakın olanı atla.
        if (now.difference(t) > const Duration(hours: 2, minutes: 30)) {
          ticks.add(ChartTick(t, formatHm(hour, 0)));
        }
      }
      ticks.add(ChartTick(now, Strings.t('Şimdi')));
      return ChartWindow(start, now, ticks);
    case ChartRange.week:
      final start = startOfDay(now.subtract(const Duration(days: 6)));
      final ticks = [
        for (var i = 0; i < 7; i++)
          ChartTick(
            DateTime(start.year, start.month, start.day + i, 12),
            weekdayShort(DateTime(start.year, start.month, start.day + i).weekday),
          ),
      ];
      return ChartWindow(start, now, ticks);
    case ChartRange.month:
      final start = startOfDay(now.subtract(const Duration(days: 29)));
      final ticks = [
        for (var i = 0; i < 30; i += 7)
          ChartTick(
            DateTime(start.year, start.month, start.day + i),
            formatDayMonth(DateTime(start.year, start.month, start.day + i)),
          ),
      ];
      return ChartWindow(start, now, ticks);
  }
}

/// Sıcaklık çubukları. Her zaman 7 çubuk döner; sonuncusu güncel değerdir.
///
/// - Gün: bugünün 4 saatlik dilimleri (00–04, ..., 20–24) + "Şimdi".
/// - Hafta: son 7 günün ortalaması, sonuncusu bugün.
/// - Ay: 5 günlük 6 dilim + "Şimdi".
List<BarBucket> temperatureBuckets(
  ChartRange range,
  List<Reading> readings,
  DateTime now,
  double? currentTemperature,
) {
  double? average(DateTime from, DateTime to) {
    final values = [
      for (final r in readings)
        if (!r.time.isBefore(from) && r.time.isBefore(to)) r.temperature,
    ];
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  final latest = currentTemperature ?? (readings.isEmpty ? null : readings.last.temperature);

  switch (range) {
    case ChartRange.day:
      final start = startOfDay(now);
      return [
        for (var i = 0; i < 6; i++)
          BarBucket(
            (i * 4).toString().padLeft(2, '0'),
            start.add(Duration(hours: i * 4)).isAfter(now)
                ? null
                : average(start.add(Duration(hours: i * 4)), start.add(Duration(hours: i * 4 + 4))),
          ),
        BarBucket(Strings.t('Şimdi'), latest, highlight: true),
      ];
    case ChartRange.week:
      final first = startOfDay(now.subtract(const Duration(days: 6)));
      return [
        for (var i = 0; i < 7; i++)
          BarBucket(
            i == 6 ? Strings.t('Bugün') : weekdayShort(DateTime(first.year, first.month, first.day + i).weekday),
            i == 6
                ? latest
                : average(
                    DateTime(first.year, first.month, first.day + i),
                    DateTime(first.year, first.month, first.day + i + 1),
                  ),
            highlight: i == 6,
          ),
      ];
    case ChartRange.month:
      final first = startOfDay(now.subtract(const Duration(days: 29)));
      return [
        for (var i = 0; i < 6; i++)
          BarBucket(
            formatDayMonth(DateTime(first.year, first.month, first.day + i * 5)),
            average(
              DateTime(first.year, first.month, first.day + i * 5),
              DateTime(first.year, first.month, first.day + i * 5 + 5),
            ),
          ),
        BarBucket(Strings.t('Şimdi'), latest, highlight: true),
      ];
  }
}

/// Ölçümleri [bucket] uzunluğundaki aralıklara bölüp ortalamasını alır.
/// En son ölçüm her zaman korunur, böylece grafik güncel değerde biter.
List<Reading> downsampleReadings(List<Reading> readings, Duration bucket) {
  if (readings.length < 2) return readings;
  final bucketMs = bucket.inMilliseconds;
  final result = <Reading>[];
  var currentKey = readings.first.time.millisecondsSinceEpoch ~/ bucketMs;
  var sumMoisture = 0.0;
  var sumTemp = 0.0;
  var count = 0;
  var bucketTime = readings.first.time;

  void flush() {
    if (count == 0) return;
    result.add(Reading(
      potId: readings.first.potId,
      time: bucketTime,
      moisture: sumMoisture / count,
      temperature: sumTemp / count,
    ));
  }

  for (final r in readings) {
    final key = r.time.millisecondsSinceEpoch ~/ bucketMs;
    if (key != currentKey) {
      flush();
      currentKey = key;
      sumMoisture = 0;
      sumTemp = 0;
      count = 0;
    }
    sumMoisture += r.moisture;
    sumTemp += r.temperature;
    count++;
    bucketTime = r.time;
  }
  flush();

  // Son grubun ortalaması yerine gerçek son değeri göster.
  result[result.length - 1] = readings.last;
  return result;
}
