import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/strings.dart';
import '../models/device_config.dart';
import '../models/device_snapshot.dart';
import '../models/plant.dart';
import '../models/pot.dart';
import '../models/reading.dart';
import '../models/tank.dart';
import '../models/watering_event.dart';
import '../services/device_service.dart';
import 'plants_provider.dart';
import 'settings_provider.dart';

enum DeviceConnection { connecting, online, offline }

/// Saksıların ayarları, canlı verileri, geçmişi ve ortak su deposu.
class PotsProvider extends ChangeNotifier {
  PotsProvider({
    required this._prefs,
    required this.device,
    required this.plants,
    required this.settings,
  }) {
    _load();
    plants.addListener(_onPlantsChanged);
    settings.addListener(_pushConfig);
  }

  final SharedPreferences _prefs;
  final DeviceService device;
  final PlantsProvider plants;
  final SettingsProvider settings;

  static const _kPots = 'pots.v2';
  static const _historySpan = Duration(days: 30);
  static const _maxLogPerPot = 200;

  /// İlk açılışta gelen saksılar (tasarımdaki örnek: iki saksı).
  static const defaultPots = [
    Pot(id: 'pot-1', name: 'Saksı 1', plantId: 'difenbahya'),
    Pot(id: 'pot-2', name: 'Saksı 2', plantId: 'baris-cicegi'),
  ];

  List<Pot> _pots = List.of(defaultPots);
  String _selectedId = defaultPots.first.id;
  DeviceSnapshot? _snapshot;
  final Map<String, List<Reading>> _readings = {};
  final Map<String, List<WateringEvent>> _log = {};
  DeviceConnection _connection = DeviceConnection.connecting;
  Msg? _connectionError;

  StreamSubscription<DeviceSnapshot>? _snapshotSub;
  StreamSubscription<WateringEvent>? _eventSub;
  Timer? _watchdog;

  List<Pot> get pots => List.unmodifiable(_pots);
  Pot get selected => potById(_selectedId) ?? _pots.first;
  String get selectedId => selected.id;
  DeviceSnapshot? get snapshot => _snapshot;
  DeviceConnection get connection => _connection;
  bool get isOnline => _connection == DeviceConnection.online;
  Msg? get connectionError => _connectionError;

  Pot? potById(String id) {
    for (final pot in _pots) {
      if (pot.id == id) return pot;
    }
    return null;
  }

  Plant? plantOf(String potId) => plants.byId(potById(potId)?.plantId);

  PotLive? liveOf(String potId) => _snapshot?.pots[potId];

  PotStatus statusOf(String potId) =>
      evaluatePotStatus(liveOf(potId)?.moisture, plantOf(potId));

  Tank get tank => Tank(
        level: _snapshot?.tankLevel,
        alertThreshold: settings.tankAlertThreshold,
        criticalThreshold: settings.tankCriticalThreshold,
        capacityMl: device.tankCapacityMl,
      );

  void selectPot(String id) {
    if (id == _selectedId || potById(id) == null) return;
    _selectedId = id;
    notifyListeners();
  }

  /// Cihaza bağlanır, geçmişi çeker ve canlı veriyi dinlemeye başlar.
  Future<void> init() async {
    _snapshotSub = device.snapshots.listen(_onSnapshot);
    _eventSub = device.events.listen(_onEvent);
    _watchdog = Timer.periodic(const Duration(seconds: 2), (_) => _checkOnline());
    try {
      await device.connect();
      await _pushConfig();
      for (final pot in _pots) {
        _readings[pot.id] = await device.fetchHistory(pot.id, _historySpan);
        _log[pot.id] = (await device.fetchEvents(pot.id, _historySpan)).reversed.toList();
      }
      _snapshot ??= device.lastSnapshot;
      _connectionError = null;
    } catch (e) {
      _connectionError = Msg('Cihaza bağlanılamadı: {0}', ['$e']);
      _connection = DeviceConnection.offline;
    }
    _checkOnline();
    notifyListeners();
  }

  /// Saksının [from] anından bu yana ölçümleri.
  List<Reading> readingsSince(String potId, DateTime from) =>
      (_readings[potId] ?? const []).where((r) => !r.time.isBefore(from)).toList();

  /// Saksının tamamlanan sulamaları, en yeni başta.
  List<WateringEvent> wateringLog(String potId) => List.unmodifiable(_log[potId] ?? const []);

  Future<WateringResult> waterNow(String potId, int amountPercent) async {
    if (!isOnline) {
      return const WateringResult.rejected(Msg('Cihaz çevrimdışı, komut gönderilemedi.'));
    }
    return device.waterNow(potId, amountPercent);
  }

  /// Seçilen miktarın yaklaşık su hacmi ve pompa süresi.
  ({double ml, double seconds, bool capped}) estimateDose(String potId, int amountPercent) {
    final fullDose = potById(potId)?.fullDoseMl ?? 200;
    var ml = fullDose * amountPercent / 100;
    var seconds = ml / device.pumpFlowMlPerSec;
    var capped = false;
    if (seconds > settings.maxPumpSeconds) {
      seconds = settings.maxPumpSeconds.toDouble();
      ml = seconds * device.pumpFlowMlPerSec;
      capped = true;
    }
    return (ml: ml, seconds: seconds, capped: capped);
  }

  void assignPlant(String potId, String? plantId) {
    _update(potId, (p) => plantId == null ? p.copyWith(clearPlant: true) : p.copyWith(plantId: plantId));
    _pushConfig();
  }

  void rename(String potId, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _update(potId, (p) => p.copyWith(name: trimmed));
  }

  void setFullDoseMl(String potId, int ml) {
    _update(potId, (p) => p.copyWith(fullDoseMl: ml));
    _pushConfig();
  }

  void _update(String potId, Pot Function(Pot) change) {
    final index = _pots.indexWhere((p) => p.id == potId);
    if (index == -1) return;
    _pots[index] = change(_pots[index]);
    _save();
  }

  void _onSnapshot(DeviceSnapshot snapshot) {
    _snapshot = snapshot;
    final cutoff = DateTime.now().subtract(_historySpan);
    for (final entry in snapshot.pots.entries) {
      final list = _readings.putIfAbsent(entry.key, () => []);
      final last = list.isEmpty ? null : list.last.time;
      // Geçmişe dakikada bir nokta eklenir; grafik şişmesin.
      if (last == null || snapshot.time.difference(last) >= const Duration(minutes: 1)) {
        list.add(Reading(
          potId: entry.key,
          time: snapshot.time,
          moisture: entry.value.moisture,
          temperature: entry.value.temperature,
        ));
        list.removeWhere((r) => r.time.isBefore(cutoff));
      }
    }
    _checkOnline(notify: false);
    notifyListeners();
  }

  void _onEvent(WateringEvent event) {
    if (event.success) {
      final list = _log.putIfAbsent(event.potId, () => []);
      list.insert(0, event);
      if (list.length > _maxLogPerPot) list.removeLast();
    }
    notifyListeners();
  }

  void _checkOnline({bool notify = true}) {
    if (!device.isConnected && _snapshot == null) return;
    final last = _snapshot?.time;
    final limit = Duration(seconds: settings.offlineAfterSeconds);
    final online = last != null && DateTime.now().difference(last) < limit;
    final next = online ? DeviceConnection.online : DeviceConnection.offline;
    if (next != _connection) {
      _connection = next;
      if (notify) notifyListeners();
    }
  }

  void _onPlantsChanged() {
    // Atanmış özel bitki silindiyse o saksıyı boşalt.
    for (final pot in List.of(_pots)) {
      if (pot.plantId != null && plants.byId(pot.plantId) == null) {
        assignPlant(pot.id, null);
      }
    }
    _pushConfig();
    notifyListeners();
  }

  Future<void> _pushConfig() {
    return device.updateConfig(DeviceConfig(
      autoMode: settings.autoMode,
      tankCriticalPercent: settings.tankCriticalThreshold,
      maxPumpSeconds: settings.maxPumpSeconds,
      minIntervalSeconds: settings.minIntervalMinutes * 60,
      pots: {
        for (final pot in _pots)
          pot.id: PotConfig(
            fullDoseMl: pot.fullDoseMl,
            minMoisture: plantOf(pot.id)?.minMoisture ?? 0,
            targetMoisture: plantOf(pot.id)?.idealMoistureMin ?? 0,
          ),
      },
    ));
  }

  void _load() {
    final raw = _prefs.getString(_kPots);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final loaded = list.map((e) => Pot.fromJson(e as Map<String, dynamic>)).toList();
      if (loaded.isNotEmpty) {
        _pots = loaded;
        _selectedId = loaded.first.id;
      }
    } catch (e) {
      debugPrint('Saksı ayarları okunamadı: $e');
    }
  }

  void _save() {
    _prefs.setString(_kPots, jsonEncode(_pots.map((p) => p.toJson()).toList()));
    notifyListeners();
  }

  @override
  void dispose() {
    plants.removeListener(_onPlantsChanged);
    settings.removeListener(_pushConfig);
    _snapshotSub?.cancel();
    _eventSub?.cancel();
    _watchdog?.cancel();
    super.dispose();
  }
}
