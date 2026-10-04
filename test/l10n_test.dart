import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:autonomous_plant_watering_system/data/plant_catalog.dart';
import 'package:autonomous_plant_watering_system/l10n/en.dart';
import 'package:autonomous_plant_watering_system/l10n/strings.dart';
import 'package:autonomous_plant_watering_system/models/alert.dart';
import 'package:autonomous_plant_watering_system/models/plant.dart';
import 'package:autonomous_plant_watering_system/models/pot.dart';
import 'package:autonomous_plant_watering_system/models/watering_event.dart';
import 'package:autonomous_plant_watering_system/providers/settings_provider.dart';
import 'package:autonomous_plant_watering_system/utils/formatters.dart';
import 'package:autonomous_plant_watering_system/utils/history_math.dart';

/// Kaynak koddaki `t('..')`, `Strings.t('..')`, `Msg('..')` ve `NavTab('..')`
/// çağrılarındaki metinleri toplar.
Set<String> _keysInSource() {
  final call = RegExp(
    r'''(?:\bt|\.t|Msg|NavTab)\(\s*(?:'((?:[^'\\]|\\.)*)'|"((?:[^"\\]|\\.)*)")''',
    dotAll: true,
  );
  String unescape(String s) => s
      .replaceAll(r"\'", "'")
      .replaceAll(r'\"', '"')
      .replaceAll(r'\n', '\n')
      .replaceAll(r'\$', r'$')
      .replaceAll(r'\\', r'\');

  final keys = <String>{};
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where((f) => !f.path.replaceAll('\\', '/').contains('lib/l10n/'));
  for (final file in files) {
    for (final m in call.allMatches(file.readAsStringSync())) {
      keys.add(unescape(m.group(1) ?? m.group(2)!));
    }
  }
  return keys;
}

Set<String> _placeholders(String s) =>
    RegExp(r'\{\d+\}').allMatches(s).map((m) => m.group(0)!).toSet();

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  tearDown(() {
    Strings.lang = AppLang.tr;
    TemperatureFormat.fahrenheit = false;
  });

  group('Çeviri eksiksizliği', () {
    test('kodda geçen her metnin İngilizcesi var', () {
      final keys = _keysInSource();
      expect(keys.length, greaterThan(150), reason: 'kaynak taraması çalışmıyor olabilir');
      final missing = keys.where((k) => !enStrings.containsKey(k)).toList()..sort();
      expect(missing, isEmpty, reason: 'en.dart içinde eksik çeviriler');
    });

    test('enum etiketleri ve bitki kataloğu çevrilmiş', () {
      final labels = <String>{
        for (final c in PlantCategory.values) ...[c.label, c.typeLabel, c.waterLabel],
        for (final w in WaterNeed.values) w.label,
        for (final s in ValueSource.values) s.label,
        for (final s in PotStatus.values) ...[s.label, s.homeLabel],
        for (final s in WateringSource.values) s.label,
        for (final r in ChartRange.values) r.label,
        for (final p in plantCatalog) ...[p.name, p.description],
        'Saksı',
        'Saksı 1',
        'Saksı 2',
        'Sahte cihaz (mock)',
        'sn',
      };
      final missing = labels.where((k) => !enStrings.containsKey(k)).toList()..sort();
      expect(missing, isEmpty);
    });

    test('yer tutucular Türkçe ve İngilizce metinde aynı', () {
      final broken = [
        for (final e in enStrings.entries)
          if (!_placeholders(e.key).containsAll(_placeholders(e.value)) ||
              !_placeholders(e.value).containsAll(_placeholders(e.key)))
            e.key,
      ];
      expect(broken, isEmpty);
    });

    test('çeviriler boş değil ve Türkçeden farklı (birkaç istisna dışında)', () {
      const same = {
        'Aloe vera', '{0}: {1}', 'Celsius (°C)', 'Fahrenheit (°F)', 'min {0} · ideal {1}',
        'Sıradaki sulama: {0} ({1})', 'Hızlı kuruma',
      };
      for (final e in enStrings.entries) {
        expect(e.value.trim(), isNotEmpty, reason: e.key);
      }
      final untranslated = [
        for (final e in enStrings.entries)
          if (e.key == e.value && !same.contains(e.key)) e.key,
      ];
      // Anahtar Türkçe harf içeriyorsa çevrilmiş olmalı.
      final turkishLeft = untranslated.where((k) => RegExp('[ğüşıöçĞÜŞİÖÇ]').hasMatch(k)).toList();
      expect(turkishLeft, isEmpty);
    });
  });

  group('Strings.t', () {
    test('Türkçede metin aynen döner, yer tutucular dolar', () {
      expect(Strings.t('Merhaba, {0}', ['Ayşe']), 'Merhaba, Ayşe');
      expect(Strings.t('Bu çeviride yok'), 'Bu çeviride yok');
    });

    test('İngilizcede çevrilir, çevirisi olmayan metin olduğu gibi kalır', () {
      Strings.lang = AppLang.en;
      expect(Strings.t('Merhaba, {0}', ['Ayşe']), 'Hello, Ayşe');
      expect(Strings.t('{0} için {1} seçildi.', ['Pot 1', 'Basil']), 'Basil selected for Pot 1.');
      expect(Strings.t('Kullanıcının kendi bitki adı'), 'Kullanıcının kendi bitki adı');
    });

    test('Msg dil değişince yeniden çevrilir ve iç içe Msg çözülür', () {
      const msg = Msg('Son sulamanın üzerinden yeterli süre geçmedi. {0} sonra tekrar deneyin (aşırı sulama koruması).', [
        Msg('{0} dk', [2]),
      ]);
      expect(msg.resolve(), contains('2 dk sonra'));
      Strings.lang = AppLang.en;
      expect(msg.resolve(), 'Not enough time has passed since the last watering. Try again in 2 min (overwatering protection).');
    });

    test('dil kodu', () {
      expect(AppLang.fromCode('en'), AppLang.en);
      expect(AppLang.fromCode('xx'), AppLang.tr);
      expect(AppLang.en.locale, const Locale('en', 'US'));
    });
  });

  group('Biçimlendirme İngilizcede', () {
    test('yüzde sayının sonuna yazılır', () {
      expect(formatPercent(62), '%62');
      expect(formatPercentRange(50, 65), '%50–65');
      Strings.lang = AppLang.en;
      expect(formatPercent(62), '62%');
      expect(formatPercentRange(50, 65), '50–65%');
    });

    test('gün adları, sıradaki sulama ve geri sayım', () {
      Strings.lang = AppLang.en;
      final now = DateTime(2026, 10, 1, 9, 0);
      expect(weekdayShort(1), 'Mon');
      expect(weekdayShort(7), 'Sun');
      expect(formatNextShort(DateTime(2026, 10, 1, 18, 0), now: now), '18:00');
      expect(formatNextShort(DateTime(2026, 10, 2, 8, 0), now: now), 'Tomorrow 08:00');
      expect(formatNextShort(DateTime(2026, 10, 4, 8, 0), now: now), 'Sun 08:00');
      expect(formatCountdown(DateTime(2026, 10, 1, 11, 30), now: now), 'in 2 h 30 min');
      expect(formatRelative(DateTime(2026, 10, 1, 8, 50), now: now), '10 min ago');
      expect(formatDayHeader(DateTime(2026, 9, 30), now: now), 'Yesterday');
      expect(formatSeconds(2.5), '2.5 s');
      expect(formatMinutes(90), '1 h 30 min');
    });

    test('tarih adları İngilizce', () {
      Strings.lang = AppLang.en;
      expect(formatDayMonth(DateTime(2026, 10, 5)), '5 Oct');
      expect(formatWeekday(DateTime(2026, 10, 1)), 'Thursday');
      Strings.lang = AppLang.tr;
      expect(formatDayMonth(DateTime(2026, 10, 5)), '5 Eki');
      expect(formatWeekday(DateTime(2026, 10, 1)), 'Perşembe');
    });

    test('grafik etiketleri', () {
      Strings.lang = AppLang.en;
      final w = chartWindow(ChartRange.day, DateTime(2026, 10, 1, 20, 0));
      expect(w.ticks.last.label, 'Now');
      final week = chartWindow(ChartRange.week, DateTime(2026, 10, 10, 12, 0));
      expect(week.ticks.first.label, 'Sun');
    });
  });

  group('Bildirimler dile göre çevrilir', () {
    final time = DateTime(2026, 10, 1, 10, 0);

    test('susayan bitki bildirimi', () {
      final alert = AppAlert(id: '1', type: AlertType.plantDry, time: time, args: const ['Barış Çiçeği', '18']);
      expect(alert.title, 'Barış Çiçeği susadı');
      expect(alert.message, "Toprak nemi %18'e düştü. Sulama zamanı.");
      Strings.lang = AppLang.en;
      expect(alert.title, 'Peace lily is thirsty');
      expect(alert.message, 'Soil moisture dropped to 18%. Time to water.');
    });

    test('depo, çevrimdışı ve sulama bildirimleri', () {
      final tank = AppAlert(id: '2', type: AlertType.tankLow, time: time, args: const ['12', '0']);
      final tankCritical = AppAlert(id: '3', type: AlertType.tankLow, time: time, args: const ['4', '1']);
      final offline = AppAlert(id: '4', type: AlertType.deviceOffline, time: time, args: const ['30']);
      final done = AppAlert(
        id: '5',
        type: AlertType.wateringDone,
        time: time,
        args: const ['Difenbahya', '40'],
        noteKey: 'Depo kritik seviyeye düştü, pompa erken durduruldu.',
      );
      final blocked = AppAlert(
        id: '6',
        type: AlertType.wateringBlocked,
        time: time,
        args: const ['Difenbahya'],
        noteKey: 'Pompa zaten çalışıyor.',
      );
      expect(tank.message, 'Depo seviyesi %12. Yakında doldurman gerekebilir.');
      expect(done.message, 'Difenbahya · %40 su verildi. Depo kritik seviyeye düştü, pompa erken durduruldu.');

      Strings.lang = AppLang.en;
      expect(tank.title, 'Water tank is running low');
      expect(tank.message, 'Tank level is 12%. You may need to refill soon.');
      expect(tankCritical.message, 'Tank level is 4%. Pumps are locked, refill the tank.');
      expect(offline.title, 'Device offline');
      expect(offline.message, startsWith('No data from the device for 30 s.'));
      expect(done.title, 'Watering complete');
      expect(done.message, 'Dieffenbachia · 40% water given. Tank dropped to a critical level, the pump stopped early.');
      expect(blocked.message, 'Dieffenbachia: The pump is already running.');
    });

    test('bildirim JSON gidiş-dönüş, dil sonradan değişse de çevrilir', () {
      final alert = AppAlert(id: '7', type: AlertType.plantDry, time: time, args: const ['Nane', '20'], potId: 'pot-1');
      final copy = AppAlert.fromJson(alert.toJson());
      expect(copy.args, ['Nane', '20']);
      expect(copy.potId, 'pot-1');
      Strings.lang = AppLang.en;
      expect(copy.title, 'Mint is thirsty');
    });
  });

  group('Dil ayarı', () {
    test('seçim kaydedilir, Strings.lang güncellenir, yeniden açılışta geri gelir', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final settings = SettingsProvider(prefs);
      expect(settings.language, AppLang.tr);
      var notified = 0;
      settings.addListener(() => notified++);

      settings.setLanguage(AppLang.en);
      expect(Strings.lang, AppLang.en);
      expect(settings.language, AppLang.en);
      expect(notified, 1);

      Strings.lang = AppLang.tr;
      final reopened = SettingsProvider(prefs);
      expect(reopened.language, AppLang.en);
      expect(Strings.lang, AppLang.en);
    });
  });
}
