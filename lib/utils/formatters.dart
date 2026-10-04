import 'package:intl/intl.dart';

import '../l10n/strings.dart';

/// Sıcaklık birimi seçimi. Ayarlar'dan değişince [SettingsProvider] günceller;
/// ölçümler her zaman °C olarak saklanır, yalnızca gösterim dönüştürülür.
class TemperatureFormat {
  TemperatureFormat._();

  static bool fahrenheit = false;

  static String get unit => fahrenheit ? '°F' : '°C';

  static double convert(double celsius) => fahrenheit ? celsius * 9 / 5 + 32 : celsius;
}

/// Türkçede yüzde işareti sayının önüne (%45), İngilizcede sonuna (45%) yazılır.
String formatPercent(num value) =>
    Strings.lang == AppLang.tr ? '%${value.round()}' : '${value.round()}%';

/// "%55–70" ya da İngilizcede "55–70%".
String formatPercentRange(num min, num max) => Strings.lang == AppLang.tr
    ? '%${min.round()}–${max.round()}'
    : '${min.round()}–${max.round()}%';

/// "23°C" ya da birim Fahrenheit ise "73°F".
String formatTemperature(double celsius) =>
    '${TemperatureFormat.convert(celsius).round()}${TemperatureFormat.unit}';

/// "18–30°C".
String formatTempRange(double minCelsius, double maxCelsius) =>
    '${TemperatureFormat.convert(minCelsius).round()}–'
    '${TemperatureFormat.convert(maxCelsius).round()}${TemperatureFormat.unit}';

String formatSeconds(double seconds) =>
    Strings.t('{0} sn', [NumberFormat('0.0', Strings.localeName).format(seconds)]);

String formatTime(DateTime t) => DateFormat.Hm(Strings.localeName).format(t);

/// "08:00" (saat ve dakikadan).
String formatHm(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

String formatDate(DateTime t) => DateFormat('d MMMM y, EEEE', Strings.localeName).format(t);

String formatDateTime(DateTime t) => DateFormat('d MMM y, HH:mm', Strings.localeName).format(t);

String formatWeekday(DateTime t) => DateFormat.EEEE(Strings.localeName).format(t);

/// "Pzt", "Sal"... (1 = pazartesi) ya da "Mon", "Tue"...
String weekdayShort(int weekday) {
  const tr = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
  const en = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return (Strings.lang == AppLang.tr ? tr : en)[(weekday - 1) % 7];
}

/// "5 Eki" ya da "5 Oct".
String formatDayMonth(DateTime t) => DateFormat('d MMM', Strings.localeName).format(t);

/// "az önce", "5 dk önce", "3 sa önce", "dün 14:20" ya da tarih.
String formatRelative(DateTime t, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final diff = current.difference(t);
  if (diff.isNegative) return formatUpcoming(t, now: current);
  if (diff.inSeconds < 45) return Strings.t('az önce');
  if (diff.inMinutes < 60) return Strings.t('{0} dk önce', [diff.inMinutes.clamp(1, 59)]);
  if (diff.inHours < 24 && isSameDay(t, current)) {
    return Strings.t('{0} sa önce', [diff.inHours]);
  }
  if (isSameDay(t, current.subtract(const Duration(days: 1)))) {
    return Strings.t('dün {0}', [formatTime(t)]);
  }
  return formatDateTime(t);
}

/// İleri tarih: "Bugün 14:30", "Yarın 08:00", "3 Eki Cuma 08:00".
String formatUpcoming(DateTime t, {DateTime? now}) {
  final current = now ?? DateTime.now();
  if (isSameDay(t, current)) return Strings.t('Bugün {0}', [formatTime(t)]);
  if (isSameDay(t, current.add(const Duration(days: 1)))) {
    return Strings.t('Yarın {0}', [formatTime(t)]);
  }
  return DateFormat('d MMM EEEE, HH:mm', Strings.localeName).format(t);
}

/// Kısa "sıradaki" gösterimi: bugünse "18:00", değilse "Yarın 08:00" ya da "Cum 08:00".
String formatNextShort(DateTime t, {DateTime? now}) {
  final current = now ?? DateTime.now();
  if (isSameDay(t, current)) return formatTime(t);
  if (isSameDay(t, current.add(const Duration(days: 1)))) {
    return Strings.t('Yarın {0}', [formatTime(t)]);
  }
  return '${weekdayShort(t.weekday)} ${formatTime(t)}';
}

/// "2 dk 30 sn sonra" gibi geri sayım metni.
String formatCountdown(DateTime t, {DateTime? now}) {
  final diff = t.difference(now ?? DateTime.now());
  if (diff.isNegative) return Strings.t('şimdi');
  if (diff.inMinutes < 1) return Strings.t('{0} sn sonra', [diff.inSeconds]);
  if (diff.inHours < 1) return Strings.t('{0} dk sonra', [diff.inMinutes]);
  if (diff.inDays < 1) {
    final minutes = diff.inMinutes % 60;
    return minutes > 0
        ? Strings.t('{0} sa {1} dk sonra', [diff.inHours, minutes])
        : Strings.t('{0} sa sonra', [diff.inHours]);
  }
  return Strings.t('{0} gün sonra', [diff.inDays]);
}

String formatMinutes(int minutes) {
  if (minutes < 60) return Strings.t('{0} dk', [minutes]);
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? Strings.t('{0} sa', [h]) : Strings.t('{0} sa {1} dk', [h, m]);
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Bildirim listesindeki gün başlığı: "Bugün", "Dün" ya da "3 Eki".
String formatDayHeader(DateTime t, {DateTime? now}) {
  final current = now ?? DateTime.now();
  if (isSameDay(t, current)) return Strings.t('Bugün');
  if (isSameDay(t, current.subtract(const Duration(days: 1)))) return Strings.t('Dün');
  return formatDayMonth(t);
}
