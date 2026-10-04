import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:autonomous_plant_watering_system/data/plant_catalog.dart';
import 'package:autonomous_plant_watering_system/models/plant.dart';
import 'package:autonomous_plant_watering_system/models/pot.dart';
import 'package:autonomous_plant_watering_system/models/reading.dart';
import 'package:autonomous_plant_watering_system/models/schedule.dart';
import 'package:autonomous_plant_watering_system/utils/formatters.dart';
import 'package:autonomous_plant_watering_system/utils/history_math.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr_TR'));

  group('Bitki kataloğu', () {
    test('kimlikler benzersiz', () {
      final ids = plantCatalog.map((p) => p.id).toSet();
      expect(ids.length, plantCatalog.length);
    });

    test('her kategoride en az bir bitki var', () {
      for (final c in PlantCategory.values) {
        expect(plantCatalog.where((p) => p.category == c), isNotEmpty, reason: c.label);
      }
    });

    test('nem değerleri tutarlı: min <= ideal alt <= ideal üst', () {
      for (final p in plantCatalog) {
        expect(p.minMoisture <= p.idealMoistureMin, isTrue, reason: p.name);
        expect(p.idealMoistureMin <= p.idealMoistureMax, isTrue, reason: p.name);
        expect(p.tempMin < p.tempMax, isTrue, reason: p.name);
      }
    });

    test('domates doküman değerleriyle aynı', () {
      final tomato = plantCatalog.firstWhere((p) => p.id == 'domates');
      expect(tomato.minMoisture, 40);
      expect(tomato.idealMoistureMin, 55);
      expect(tomato.idealMoistureMax, 70);
      expect(tomato.tempMin, 18);
      expect(tomato.tempMax, 30);
    });

    test('tasarımdaki iki bitki var', () {
      expect(plantCatalog.any((p) => p.id == 'difenbahya'), isTrue);
      expect(plantCatalog.any((p) => p.id == 'baris-cicegi'), isTrue);
    });

    test('JSON gidiş-dönüş', () {
      final p = plantCatalog.first;
      final copy = Plant.fromJson(p.toJson());
      expect(copy.name, p.name);
      expect(copy.category, p.category);
      expect(copy.idealMoistureMax, p.idealMoistureMax);
    });

    test('eski kayıtlardaki bilinmeyen kategori çökmeden okunur', () {
      final json = plantCatalog.first.toJson()..['category'] = 'houseplant';
      expect(Plant.fromJson(json).category, PlantCategory.tropical);
    });
  });

  group('Saksı durumu', () {
    final tomato = plantCatalog.firstWhere((p) => p.id == 'domates');

    test('eşiklere göre durum', () {
      expect(evaluatePotStatus(50, null), PotStatus.noPlant);
      expect(evaluatePotStatus(null, tomato), PotStatus.unknown);
      expect(evaluatePotStatus(30, tomato), PotStatus.dry);
      expect(evaluatePotStatus(45, tomato), PotStatus.low);
      expect(evaluatePotStatus(60, tomato), PotStatus.ideal);
      expect(evaluatePotStatus(80, tomato), PotStatus.wet);
    });

    test('yalnızca susuz durum sulama gerektirir', () {
      expect(PotStatus.dry.needsWater, isTrue);
      expect(PotStatus.ideal.needsWater, isFalse);
      expect(PotStatus.low.needsWater, isFalse);
    });
  });

  group('Sulama programı', () {
    // 1 Ekim 2026 Perşembe.
    final created = DateTime(2026, 10, 1, 7, 0);

    WateringSchedule make({
      Set<int> days = const {DateTime.monday, DateTime.wednesday, DateTime.friday, DateTime.sunday},
      int hour = 8,
      int minute = 0,
      bool active = true,
      DateTime? lastRun,
    }) =>
        WateringSchedule(
          id: 'pot-1',
          potId: 'pot-1',
          hour: hour,
          minute: minute,
          weekdays: days,
          amountPercent: 40,
          createdAt: created,
          active: active,
          lastRun: lastRun,
        );

    test('sıradaki sulama bir sonraki seçili günde', () {
      final s = make();
      // Perşembe 09:00 → sıradaki Cuma 08:00.
      expect(s.nextOccurrence(DateTime(2026, 10, 1, 9, 0)), DateTime(2026, 10, 2, 8, 0));
      // Cuma 08:00'den sonra → Pazar 08:00.
      expect(s.nextOccurrence(DateTime(2026, 10, 2, 9, 0)), DateTime(2026, 10, 4, 8, 0));
      // Pazar 08:00'den sonra → Pazartesi 08:00.
      expect(s.nextOccurrence(DateTime(2026, 10, 4, 9, 0)), DateTime(2026, 10, 5, 8, 0));
    });

    test('bugün saat henüz gelmediyse sıradaki bugün', () {
      final s = make(days: const {DateTime.thursday});
      expect(s.nextOccurrence(DateTime(2026, 10, 1, 7, 0)), DateTime(2026, 10, 1, 8, 0));
      expect(s.nextOccurrence(DateTime(2026, 10, 1, 8, 1)), DateTime(2026, 10, 8, 8, 0));
    });

    test('gün seçilmediyse sıradaki yok', () {
      final s = make(days: const {});
      expect(s.nextOccurrence(DateTime(2026, 10, 1, 9, 0)), isNull);
      expect(s.lastOccurrence(DateTime(2026, 10, 1, 9, 0)), isNull);
    });

    test('zamanında çalışır, ikinci kez çalışmaz', () {
      final s = make(days: const {DateTime.thursday});
      expect(s.isDue(DateTime(2026, 10, 1, 7, 59)), isFalse);
      expect(s.isDue(DateTime(2026, 10, 1, 8, 0, 3)), isTrue);
      final ran = s.copyWith(lastRun: DateTime(2026, 10, 1, 8, 0, 3));
      expect(ran.isDue(DateTime(2026, 10, 1, 8, 0, 6)), isFalse);
    });

    test('seçili olmayan günde çalışmaz', () {
      final s = make(days: const {DateTime.monday});
      expect(s.isDue(DateTime(2026, 10, 1, 8, 0, 3)), isFalse);
    });

    test('çok eski kaçırılmış zaman atlanır', () {
      final s = make(days: const {DateTime.thursday});
      expect(s.isDue(DateTime(2026, 10, 1, 9, 0)), isFalse);
    });

    test('kapalı program çalışmaz', () {
      final s = make(days: const {DateTime.thursday}, active: false);
      expect(s.isDue(DateTime(2026, 10, 1, 8, 0, 3)), isFalse);
    });

    test('kaydedilmeden önceki zaman çalışmaz', () {
      // Program 08:02'de kaydedildi; 08:00 zamanı geçmişte kaldı.
      final s = make(days: const {DateTime.thursday}).copyWith(createdAt: DateTime(2026, 10, 1, 8, 2));
      expect(s.isDue(DateTime(2026, 10, 1, 8, 3)), isFalse);
    });

    test('2 dakika sonrasına kurulan program tetiklenir', () {
      final now = DateTime(2026, 10, 1, 14, 0, 30);
      final s = WateringSchedule(
        id: 'pot-1',
        potId: 'pot-1',
        hour: 14,
        minute: 2,
        weekdays: {now.weekday},
        amountPercent: 50,
        createdAt: now,
      );
      expect(s.isDue(DateTime(2026, 10, 1, 14, 1, 59)), isFalse);
      expect(s.isDue(DateTime(2026, 10, 1, 14, 2, 2)), isTrue);
    });

    test('JSON gidiş-dönüş', () {
      final s = make();
      final copy = WateringSchedule.fromJson(s.toJson());
      expect(copy.hour, s.hour);
      expect(copy.minute, s.minute);
      expect(copy.weekdays, s.weekdays);
      expect(copy.amountPercent, s.amountPercent);
      expect(copy.active, s.active);
    });
  });

  group('Grafik verisi', () {
    final start = DateTime(2026, 10, 1, 10, 0);

    List<Reading> minutely(int count, {double temp = 20}) => [
          for (var i = 0; i < count; i++)
            Reading(
              potId: 'pot-1',
              time: start.add(Duration(minutes: i)),
              moisture: i.toDouble(),
              temperature: temp,
            ),
        ];

    test('aralıklara bölünür ve son değer korunur', () {
      final result = downsampleReadings(minutely(60), const Duration(minutes: 10));
      expect(result.length, 6);
      expect(result.first.moisture, closeTo(4.5, 0.001));
      expect(result.last.moisture, 59);
    });

    test('gün penceresi gece yarısından şimdiye kadar', () {
      final now = DateTime(2026, 10, 1, 20, 0);
      final w = chartWindow(ChartRange.day, now);
      expect(w.start, DateTime(2026, 10, 1));
      expect(w.end, now);
      expect(w.ticks.last.label, 'Şimdi');
      expect(w.ticks.map((t) => t.label), containsAll(['00:00', '06:00', '12:00', '18:00'].where((l) => l != '18:00')));
    });

    test('hafta ve ay pencereleri', () {
      final now = DateTime(2026, 10, 10, 12, 0);
      expect(chartWindow(ChartRange.week, now).start, DateTime(2026, 10, 4));
      expect(chartWindow(ChartRange.week, now).ticks.length, 7);
      expect(chartWindow(ChartRange.month, now).start, DateTime(2026, 9, 11));
    });

    test('sıcaklık çubukları: her zaman 7 çubuk, sonuncusu güncel değer', () {
      final now = DateTime(2026, 10, 1, 12, 0);
      final readings = [
        for (var h = 0; h < 12; h++)
          Reading(
            potId: 'pot-1',
            time: DateTime(2026, 10, 1, h, 30),
            moisture: 50,
            temperature: 20.0 + h,
          ),
      ];
      for (final range in ChartRange.values) {
        final buckets = temperatureBuckets(range, readings, now, 25);
        expect(buckets.length, 7, reason: range.label);
        expect(buckets.last.value, 25, reason: range.label);
        expect(buckets.last.highlight, isTrue, reason: range.label);
      }
      // 00–04 dilimi: 0:30, 1:30, 2:30, 3:30 → 20, 21, 22, 23 ortalaması.
      final day = temperatureBuckets(ChartRange.day, readings, now, 25);
      expect(day.first.value, closeTo(21.5, 0.001));
      // Gelecekteki dilimlerde veri yok (öğle 12:00'den sonrası).
      expect(day[4].value, isNull);
    });
  });

  group('Biçimlendirme', () {
    tearDown(() => TemperatureFormat.fahrenheit = false);

    test('sıcaklık Celsius ve Fahrenheit', () {
      expect(formatTemperature(23), '23°C');
      TemperatureFormat.fahrenheit = true;
      expect(formatTemperature(0), '32°F');
      expect(formatTemperature(100), '212°F');
      expect(formatTempRange(18, 30), '64–86°F');
    });

    test('yüzde ve saat', () {
      expect(formatPercent(62.4), '%62');
      expect(formatHm(8, 5), '08:05');
      expect(weekdayShort(1), 'Pzt');
      expect(weekdayShort(7), 'Paz');
    });

    test('kısa sıradaki gösterimi', () {
      final now = DateTime(2026, 10, 1, 9, 0);
      expect(formatNextShort(DateTime(2026, 10, 1, 18, 0), now: now), '18:00');
      expect(formatNextShort(DateTime(2026, 10, 2, 8, 0), now: now), 'Yarın 08:00');
      expect(formatNextShort(DateTime(2026, 10, 4, 8, 0), now: now), 'Paz 08:00');
    });
  });
}
