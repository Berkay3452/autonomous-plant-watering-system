import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:autonomous_plant_watering_system/models/device_config.dart';
import 'package:autonomous_plant_watering_system/models/schedule.dart';
import 'package:autonomous_plant_watering_system/models/watering_event.dart';
import 'package:autonomous_plant_watering_system/services/mock_device_service.dart';

void main() {
  const pot1 = MockDeviceService.pot1;
  const pot2 = MockDeviceService.pot2;
  late MockDeviceService device;

  setUp(() async {
    device = MockDeviceService(tickInterval: const Duration(hours: 1), random: Random(1));
    await device.connect();
    await device.updateConfig(const DeviceConfig(minIntervalSeconds: 0));
  });

  tearDown(() => device.dispose());

  test('iki saksı tanımlı ve bağlanınca canlı veri gelir', () {
    expect(device.potIds, [pot1, pot2]);
    final snapshot = device.lastSnapshot!;
    expect(snapshot.pots.keys, containsAll([pot1, pot2]));
    expect(snapshot.tankLevel, closeTo(78, 0.5));
  });

  test('30 günlük geçmiş ve sulama kayıtları üretilir', () async {
    final history = await device.fetchHistory(pot1, const Duration(days: 30));
    expect(history.length, greaterThan(2500));
    final events = await device.fetchEvents(pot1, const Duration(days: 30));
    expect(events, isNotEmpty);
    expect(events.every((e) => e.success && e.potId == pot1), isTrue);
    // Hafta içinde 4 gün (Pzt, Çar, Cum, Paz) sulanır: 30 günde ~17 kez.
    expect(events.length, inInclusiveRange(12, 20));
  });

  test('saksı 2 sulanmamış gibi kuru başlar', () {
    final snapshot = device.lastSnapshot!;
    expect(snapshot.pots[pot2]!.moisture, lessThan(40));
    expect(snapshot.pots[pot1]!.moisture, greaterThan(snapshot.pots[pot2]!.moisture));
  });

  test('sulama yalnızca o saksının nemini artırır, depo azalır', () async {
    device.refillTank();
    final before = device.lastSnapshot!;
    final eventFuture = device.events.first;

    final result = await device.waterNow(pot2, 50);
    expect(result.accepted, isTrue);
    expect(result.ml, closeTo(100, 0.01));

    final event = await eventFuture.timeout(const Duration(seconds: 20));
    expect(event.success, isTrue);
    expect(event.potId, pot2);
    expect(event.source, WateringSource.manual);

    final after = device.lastSnapshot!;
    expect(after.pots[pot2]!.moisture, greaterThan(before.pots[pot2]!.moisture));
    expect(after.pots[pot1]!.moisture, closeTo(before.pots[pot1]!.moisture, 0.5));
    expect(after.tankLevel, lessThan(before.tankLevel));
    expect(after.pots[pot2]!.pumpRunning, isFalse);
    expect(after.pots[pot2]!.lastWatered, isNotNull);
    // Sulama geçmişe de yazılır.
    final events = await device.fetchEvents(pot2, const Duration(days: 1));
    expect(events.any((e) => e.source == WateringSource.manual), isTrue);
  });

  test('depo kritik seviyedeyken pompa kilitlenir', () async {
    device.setTankLevel(3);
    final result = await device.waterNow(pot1, 50);
    expect(result.accepted, isFalse);
    expect(result.message!.resolve(), contains('kuru çalışma'));
    expect(device.lastSnapshot!.pumpLocked, isTrue);
  });

  test('azami pompa süresi dozu sınırlar', () async {
    device.refillTank();
    await device.updateConfig(const DeviceConfig(
      maxPumpSeconds: 5,
      minIntervalSeconds: 0,
      pots: {pot1: PotConfig(fullDoseMl: 500)},
    ));
    final result = await device.waterNow(pot1, 100);
    expect(result.accepted, isTrue);
    expect(result.durationSeconds, 5);
    expect(result.ml, closeTo(5 * device.pumpFlowMlPerSec, 0.01));
  });

  group('Programlı sulama (cihaz kendisi çalıştırır)', () {
    // 1 Ekim 2026 Perşembe 08:00:10; program 08:00'de.
    final fakeNow = DateTime(2026, 10, 1, 8, 0, 10);

    Future<MockDeviceService> connect() async {
      final d = MockDeviceService(
        tickInterval: const Duration(milliseconds: 50),
        random: Random(1),
        clock: () => fakeNow,
      );
      await d.connect();
      await d.updateConfig(const DeviceConfig(minIntervalSeconds: 0));
      d.refillTank();
      return d;
    }

    WateringSchedule schedule({
      bool active = true,
      Set<int> days = const {DateTime.thursday},
      int amount = 25,
    }) =>
        WateringSchedule(
          id: pot2,
          potId: pot2,
          hour: 8,
          minute: 0,
          weekdays: days,
          amountPercent: amount,
          createdAt: DateTime(2026, 10, 1, 7, 0),
          active: active,
        );

    test('zamanı gelen program saksıyı sular', () async {
      final d = await connect();
      addTearDown(d.dispose);
      final eventFuture = d.events.first;
      await d.syncSchedules([schedule()]);

      final event = await eventFuture.timeout(const Duration(seconds: 10));
      expect(event.source, WateringSource.scheduled);
      expect(event.potId, pot2);
      expect(event.success, isTrue);
      expect(event.amountPercent, 25);
      expect(event.ml, closeTo(50, 0.5));
    });

    test('aynı program aynı dakikada ikinci kez çalışmaz', () async {
      final d = await connect();
      addTearDown(d.dispose);
      final events = <WateringEvent>[];
      final sub = d.events.listen(events.add);
      addTearDown(sub.cancel);
      // %10 = 20 ml; pompa 20 / 8 ≈ 2,5 sn çalışır.
      await d.syncSchedules([schedule(amount: 10)]);

      // Pompa bitsin ve üstüne birkaç tick daha geçsin.
      await Future<void>.delayed(const Duration(seconds: 5));
      final scheduled = events.where((e) => e.source == WateringSource.scheduled).toList();
      expect(scheduled.length, 1, reason: 'program bir kez çalışmalı, engellenen deneme de olmamalı');
      expect(scheduled.single.success, isTrue);
    });

    test('kapalı program ve seçili olmayan gün sulamaz', () async {
      final d = await connect();
      addTearDown(d.dispose);
      final events = <WateringEvent>[];
      final sub = d.events.listen(events.add);
      addTearDown(sub.cancel);

      await d.syncSchedules([
        schedule(active: false),
        schedule(days: const {DateTime.monday}),
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(events, isEmpty);
    });
  });

  test('tanımsız saksı ve çevrimdışı cihaz reddedilir', () async {
    expect((await device.waterNow('pot-99', 50)).accepted, isFalse);
    device.setOffline(true);
    expect((await device.waterNow(pot1, 50)).accepted, isFalse);
  });
}
