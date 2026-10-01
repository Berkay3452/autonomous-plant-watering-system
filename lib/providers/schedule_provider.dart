import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/schedule.dart';
import '../models/watering_event.dart';
import '../services/device_service.dart';

/// Sulama planları. Her değişiklikte planlar cihaza da gönderilir; planı
/// çalıştıran taraf cihazdır.
class ScheduleProvider extends ChangeNotifier {
  ScheduleProvider({required this._prefs, required this.device}) {
    _load();
  }

  final SharedPreferences _prefs;
  final DeviceService device;
  static const _kSchedules = 'schedules.all';

  final List<WateringSchedule> _schedules = [];
  StreamSubscription<WateringEvent>? _eventSub;

  /// Sıradaki çalışma zamanına göre sıralı. Pasif ve süresi geçmiş planlar sonda.
  List<WateringSchedule> get schedules {
    final now = DateTime.now();
    final list = List.of(_schedules);
    list.sort((a, b) {
      final an = a.active ? a.nextOccurrence(now) : null;
      final bn = b.active ? b.nextOccurrence(now) : null;
      if (an == null && bn == null) return b.time.compareTo(a.time);
      if (an == null) return 1;
      if (bn == null) return -1;
      return an.compareTo(bn);
    });
    return list;
  }

  List<WateringSchedule> forPot(String potId) =>
      schedules.where((s) => s.potId == potId).toList();

  /// Saksının sıradaki planlı sulaması.
  ({WateringSchedule schedule, DateTime time})? nextFor(String potId) {
    final now = DateTime.now();
    ({WateringSchedule schedule, DateTime time})? best;
    for (final s in _schedules) {
      if (!s.active || s.potId != potId) continue;
      final next = s.nextOccurrence(now);
      if (next == null) continue;
      if (best == null || next.isBefore(best.time)) best = (schedule: s, time: next);
    }
    return best;
  }

  Future<void> init() async {
    _eventSub = device.events.listen(_onEvent);
    await device.syncSchedules(_schedules);
  }

  String newId() => 'schedule-${DateTime.now().microsecondsSinceEpoch}';

  void add(WateringSchedule schedule) {
    _schedules.add(schedule);
    _commit();
  }

  void update(WateringSchedule schedule) {
    final index = _schedules.indexWhere((s) => s.id == schedule.id);
    if (index == -1) return;
    _schedules[index] = schedule;
    _commit();
  }

  void remove(String id) {
    _schedules.removeWhere((s) => s.id == id);
    _commit();
  }

  void setActive(String id, bool active) {
    final index = _schedules.indexWhere((s) => s.id == id);
    if (index == -1) return;
    _schedules[index] = _schedules[index].copyWith(active: active);
    _commit();
  }

  void _onEvent(WateringEvent event) {
    final id = event.scheduleId;
    if (id == null) return;
    final index = _schedules.indexWhere((s) => s.id == id);
    if (index == -1) return;
    final s = _schedules[index];
    _schedules[index] = s.copyWith(
      lastRun: event.time,
      active: s.repeat == ScheduleRepeat.once ? false : s.active,
    );
    _commit();
  }

  void _commit() {
    _prefs.setString(
      _kSchedules,
      jsonEncode(_schedules.map((s) => s.toJson()).toList()),
    );
    device.syncSchedules(_schedules);
    notifyListeners();
  }

  void _load() {
    final raw = _prefs.getString(_kSchedules);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      _schedules
        ..clear()
        ..addAll(list.map((e) => WateringSchedule.fromJson(e as Map<String, dynamic>)));
    } catch (e) {
      debugPrint('Planlar okunamadı: $e');
    }
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    super.dispose();
  }
}
