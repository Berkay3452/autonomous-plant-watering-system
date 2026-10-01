import 'package:intl/intl.dart';

const _locale = 'tr_TR';

/// Türkçede yüzde işareti sayının önüne yazılır: %45.
String formatPercent(num value) => '%${value.round()}';

String formatTemperature(double value) => '${_decimal(value)} °C';

String formatSeconds(double seconds) => '${_decimal(seconds)} sn';

String _decimal(double value) => NumberFormat('0.0', _locale).format(value);

String formatTime(DateTime t) => DateFormat.Hm(_locale).format(t);

String formatDate(DateTime t) => DateFormat('d MMMM y, EEEE', _locale).format(t);

String formatDateTime(DateTime t) => DateFormat('d MMM y, HH:mm', _locale).format(t);

String formatWeekday(DateTime t) => DateFormat.EEEE(_locale).format(t);

/// "az önce", "5 dk önce", "3 sa önce", "dün 14:20" ya da tarih.
String formatRelative(DateTime t, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final diff = current.difference(t);
  if (diff.isNegative) return formatUpcoming(t, now: current);
  if (diff.inSeconds < 45) return 'az önce';
  if (diff.inMinutes < 60) return '${diff.inMinutes.clamp(1, 59)} dk önce';
  if (diff.inHours < 24 && _sameDay(t, current)) return '${diff.inHours} sa önce';
  if (_sameDay(t, current.subtract(const Duration(days: 1)))) return 'dün ${formatTime(t)}';
  return formatDateTime(t);
}

/// İleri tarih: "Bugün 14:30", "Yarın 08:00", "3 Eki Cuma 08:00".
String formatUpcoming(DateTime t, {DateTime? now}) {
  final current = now ?? DateTime.now();
  if (_sameDay(t, current)) return 'Bugün ${formatTime(t)}';
  if (_sameDay(t, current.add(const Duration(days: 1)))) return 'Yarın ${formatTime(t)}';
  return DateFormat('d MMM EEEE, HH:mm', _locale).format(t);
}

/// "2 dk 30 sn sonra" gibi geri sayım metni.
String formatCountdown(DateTime t, {DateTime? now}) {
  final diff = t.difference(now ?? DateTime.now());
  if (diff.isNegative) return 'şimdi';
  if (diff.inMinutes < 1) return '${diff.inSeconds} sn sonra';
  if (diff.inHours < 1) return '${diff.inMinutes} dk sonra';
  if (diff.inDays < 1) {
    final minutes = diff.inMinutes % 60;
    return '${diff.inHours} sa${minutes > 0 ? ' $minutes dk' : ''} sonra';
  }
  return '${diff.inDays} gün sonra';
}

String formatMinutes(int minutes) {
  if (minutes < 60) return '$minutes dk';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '$h sa' : '$h sa $m dk';
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
