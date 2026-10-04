import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/schedule.dart';
import '../models/watering_event.dart';
import '../services/device_service.dart';

/// Saksıların sulama programları (saksı başına bir tane). Her değişiklikte
/// programlar cihaza da gönderilir; programı çalıştıran taraf cihazdır.
class ScheduleProvider extends ChangeNotifier {
  ScheduleProvider({required this._prefs, required this.device, required List<String> potIds}) {
    _load();
    for (final id in potIds) {
      _schedules.putIfAbsent(id, () => WateringSchedule.initial(id, DateTime.now()));
    }
  }

  final SharedPreferences _prefs;
  final DeviceService device;
  static const _kSchedules = 'schedules.v2';

  final Map<String, WateringSchedule> _schedules = {};
  StreamSubscription<WateringEvent>? _eventSub;

  WateringSchedule? forPot(String potId) => _schedules[potId];

  /// Saksının sıradaki programlı sulama zamanı. Program kapalıysa null.
  DateTime? nextFor(String potId) {
    final s = _schedules[potId];
    if (s == null || !s.active) return null;
    return s.nextOccurrence(DateTime.now());
  }

  Future<void> init() async {
    _eventSub = device.events.listen(_onEvent);
    await device.syncSchedules(_schedules.values.toList());
  }

  /// Programı kaydeder. Kayıt anı, geçmişte kalmış saatlerin hemen çalışmasını
  /// engellemek için programın başlangıcı sayılır.
  void save(WateringSchedule schedule) {
    _schedules[schedule.potId] = schedule.copyWith(createdAt: DateTime.now());
    _commit();
  }

  void _onEvent(WateringEvent event) {
    final id = event.scheduleId;
    if (id == null) return;
    final s = _schedules[id];
    if (s == null) return;
    _schedules[id] = s.copyWith(lastRun: event.time);
    _commit();
  }

  void _commit() {
    _prefs.setString(
      _kSchedules,
      jsonEncode(_schedules.values.map((s) => s.toJson()).toList()),
    );
    device.syncSchedules(_schedules.values.toList());
    notifyListeners();
  }

  void _load() {
    final raw = _prefs.getString(_kSchedules);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      for (final e in list) {
        final s = WateringSchedule.fromJson(e as Map<String, dynamic>);
        _schedules[s.potId] = s;
      }
    } catch (e) {
      debugPrint('Programlar okunamadı: $e');
    }
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }
}
