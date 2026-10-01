import 'package:flutter_test/flutter_test.dart';

import 'package:autonomous_plant_watering_system/data/plant_catalog.dart';
import 'package:autonomous_plant_watering_system/models/plant.dart';
import 'package:autonomous_plant_watering_system/models/pot.dart';
import 'package:autonomous_plant_watering_system/models/reading.dart';
import 'package:autonomous_plant_watering_system/models/schedule.dart';
import 'package:autonomous_plant_watering_system/providers/pot_provider.dart';

void main() {
  group('Bitki kataloğu', () {
    test('kimlikler benzersiz', () {
      final ids = plantCatalog.map((p) => p.id).toSet();
      expect(ids.length, plantCatalog.length);
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

    test('JSON gidiş-dönüş', () {
      final p = plantCatalog.first;
      final copy = Plant.fromJson(p.toJson());
      expect(copy.name, p.name);
      expect(copy.category, p.category);
      expect(copy.idealMoistureMax, p.idealMoistureMax);
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
  });

  group('Sulama planı', () {
    final created = DateTime(2026, 10, 1, 7, 0);

    WateringSchedule make(DateTime time, ScheduleRepeat repeat, {DateTime? lastRun}) => WateringSchedule(
          id: 's',
          potId: 'pot-1',
          time: time,
          repeat: repeat,
          amountPercent: 50,
          createdAt: created,
          lastRun: lastRun,
        );

    test('tek seferlik plan zamanında çalışır, sonra çalışmaz', () {
      final s = make(DateTime(2026, 10, 1, 8, 0), ScheduleRepeat.once);
      expect(s.isDue(DateTime(2026, 10, 1, 7, 59)), isFalse);
      expect(s.isDue(DateTime(2026, 10, 1, 8, 0, 3)), isTrue);
      final ran = s.copyWith(lastRun: DateTime(2026, 10, 1, 8, 0, 3));
      expect(ran.isDue(DateTime(2026, 10, 1, 8, 0, 6)), isFalse);
    });

    test('çok eski kaçırılmış zaman atlanır', () {
      final s = make(DateTime(2026, 10, 1, 8, 0), ScheduleRepeat.once);
      expect(s.isDue(DateTime(2026, 10, 1, 9, 0)), isFalse);
    });

    test('günlük plan her gün aynı saatte', () {
      final s = make(DateTime(2026, 10, 1, 8, 0), ScheduleRepeat.daily,
          lastRun: DateTime(2026, 10, 1, 8, 0, 5));
      expect(s.isDue(DateTime(2026, 10, 1, 20, 0)), isFalse);
      expect(s.isDue(DateTime(2026, 10, 2, 8, 0, 2)), isTrue);
      expect(s.nextOccurrence(DateTime(2026, 10, 1, 9, 0)), DateTime(2026, 10, 2, 8, 0));
    });

    test('haftalık plan aynı gün', () {
      // 1 Ekim 2026 Perşembe.
      final s = make(DateTime(2026, 10, 1, 8, 0), ScheduleRepeat.weekly,
          lastRun: DateTime(2026, 10, 1, 8, 0, 5));
      expect(s.nextOccurrence(DateTime(2026, 10, 2, 9, 0)), DateTime(2026, 10, 8, 8, 0));
      expect(s.isDue(DateTime(2026, 10, 8, 8, 1)), isTrue);
      expect(s.isDue(DateTime(2026, 10, 7, 8, 1)), isFalse);
    });

    test('başlangıçtan önce çalışmaz', () {
      final s = make(DateTime(2026, 10, 5, 8, 0), ScheduleRepeat.daily);
      expect(s.lastOccurrence(DateTime(2026, 10, 3, 9, 0)), isNull);
      expect(s.nextOccurrence(DateTime(2026, 10, 3, 9, 0)), DateTime(2026, 10, 5, 8, 0));
    });

    test('JSON gidiş-dönüş', () {
      final s = make(DateTime(2026, 10, 1, 8, 0), ScheduleRepeat.weekly);
      final copy = WateringSchedule.fromJson(s.toJson());
      expect(copy.time, s.time);
      expect(copy.repeat, s.repeat);
      expect(copy.amountPercent, s.amountPercent);
    });
  });

  group('Grafik verisi', () {
    test('aralıklara bölünür ve son değer korunur', () {
      final start = DateTime(2026, 10, 1, 10, 0);
      final readings = [
        for (var i = 0; i < 60; i++)
          Reading(
            potId: 'pot-1',
            time: start.add(Duration(minutes: i)),
            moisture: i.toDouble(),
            temperature: 20,
          ),
      ];
      final result = downsampleReadings(readings, const Duration(minutes: 10));
      expect(result.length, 6);
      expect(result.first.moisture, closeTo(4.5, 0.001));
      expect(result.last.moisture, 59);
    });
  });
}
