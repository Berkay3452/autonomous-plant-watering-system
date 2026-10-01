import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:autonomous_plant_watering_system/models/device_config.dart';
import 'package:autonomous_plant_watering_system/models/watering_event.dart';
import 'package:autonomous_plant_watering_system/services/mock_device_service.dart';

void main() {
  late MockDeviceService device;

  setUp(() async {
    device = MockDeviceService(tickInterval: const Duration(hours: 1), random: Random(1));
    await device.connect();
    await device.updateConfig(const DeviceConfig(minIntervalSeconds: 0));
  });

  tearDown(() => device.dispose());

  test('bağlanınca 7 günlük geçmiş ve canlı veri gelir', () async {
    final history = await device.fetchHistory(MockDeviceService.defaultPotId, const Duration(days: 7));
    expect(history.length, greaterThan(600));
    expect(device.lastSnapshot, isNotNull);
  });

  test('sulama depoyu azaltır ve nemi artırır', () async {
    device.refillTank();
    final before = device.lastSnapshot!;
    final eventFuture = device.events.first;

    final result = await device.waterNow(MockDeviceService.defaultPotId, 50);
    expect(result.accepted, isTrue);
    expect(result.ml, closeTo(100, 0.01));

    final event = await eventFuture.timeout(const Duration(seconds: 20));
    expect(event.success, isTrue);
    expect(event.source, WateringSource.manual);

    final after = device.lastSnapshot!;
    expect(after.tankLevel, lessThan(before.tankLevel));
    expect(after.moisture, greaterThan(before.moisture));
    expect(after.pumpRunning, isFalse);
    expect(after.lastWatered, isNotNull);
  });

  test('depo kritik seviyedeyken pompa kilitlenir', () async {
    device.setTankLevel(3);
    final result = await device.waterNow(MockDeviceService.defaultPotId, 50);
    expect(result.accepted, isFalse);
    expect(result.message, contains('kuru çalışma'));
    expect(device.lastSnapshot!.pumpLocked, isTrue);
  });

  test('azami pompa süresi dozu sınırlar', () async {
    device.refillTank();
    await device.updateConfig(const DeviceConfig(fullDoseMl: 500, maxPumpSeconds: 5, minIntervalSeconds: 0));
    final result = await device.waterNow(MockDeviceService.defaultPotId, 100);
    expect(result.accepted, isTrue);
    expect(result.durationSeconds, 5);
    expect(result.ml, closeTo(5 * device.pumpFlowMlPerSec, 0.01));
  });

  test('çevrimdışıyken komut reddedilir', () async {
    device.setOffline(true);
    final result = await device.waterNow(MockDeviceService.defaultPotId, 50);
    expect(result.accepted, isFalse);
  });
}
