import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

enum ChartRange {
  day('24 saat', Duration(hours: 24), Duration(minutes: 10)),
  week('7 gün', Duration(days: 7), Duration(hours: 1));

  const ChartRange(this.label, this.duration, this.bucket);

  final String label;
  final Duration duration;

  /// Grafikte noktaların gruplanacağı aralık.
  final Duration bucket;
}

enum DeviceConnection { connecting, online, offline }

/// Tek saksının ayarları, canlı verileri ve geçmişi.
class PotProvider extends ChangeNotifier {
  PotProvider({
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

  static const _kPot = 'pot.main';
  static const _maxEvents = 30;

  Pot _pot = const Pot(id: 'pot-1', name: 'Saksı 1');
  DeviceSnapshot? _snapshot;
  final List<Reading> _readings = [];
  final List<WateringEvent> _events = [];
  DeviceConnection _connection = DeviceConnection.connecting;
  String? _connectionError;

  StreamSubscription<DeviceSnapshot>? _snapshotSub;
  StreamSubscription<WateringEvent>? _eventSub;
  Timer? _watchdog;

  Pot get pot => _pot;
  Plant? get plant => plants.byId(_pot.plantId);
  DeviceSnapshot? get snapshot => _snapshot;
  DeviceConnection get connection => _connection;
  bool get isOnline => _connection == DeviceConnection.online;
  String? get connectionError => _connectionError;
  List<WateringEvent> get recentEvents => List.unmodifiable(_events);

  PotStatus get status => evaluatePotStatus(_snapshot?.moisture, plant);

  Tank get tank => Tank(
        level: _snapshot?.tankLevel,
        alertThreshold: settings.tankAlertThreshold,
        criticalThreshold: settings.tankCriticalThreshold,
        capacityMl: device.tankCapacityMl,
      );

  /// Cihaza bağlanır, geçmişi çeker ve canlı veriyi dinlemeye başlar.
  Future<void> init() async {
    _snapshotSub = device.snapshots.listen(_onSnapshot);
    _eventSub = device.events.listen(_onEvent);
    _watchdog = Timer.periodic(const Duration(seconds: 2), (_) => _checkOnline());
    try {
      await device.connect();
      await _pushConfig();
      final history = await device.fetchHistory(_pot.id, ChartRange.week.duration);
      _readings
        ..clear()
        ..addAll(history);
      _snapshot ??= device.lastSnapshot;
      _connectionError = null;
    } catch (e) {
      _connectionError = 'Cihaza bağlanılamadı: $e';
      _connection = DeviceConnection.offline;
    }
    _checkOnline();
    notifyListeners();
  }

  /// [range] için grafikte gösterilecek ölçümler (aralıklara bölünüp ortalaması
  /// alınmış).
  List<Reading> readings(ChartRange range) {
    final from = DateTime.now().subtract(range.duration);
    final inRange = _readings.where((r) => r.time.isAfter(from)).toList();
    return downsampleReadings(inRange, range.bucket);
  }

  Future<WateringResult> waterNow(int amountPercent) async {
    if (!isOnline) {
      return const WateringResult.rejected('Cihaz çevrimdışı, komut gönderilemedi.');
    }
    return device.waterNow(_pot.id, amountPercent);
  }

  /// Seçilen miktarın yaklaşık su hacmi ve pompa süresi.
  ({double ml, double seconds, bool capped}) estimateDose(int amountPercent) {
    var ml = _pot.fullDoseMl * amountPercent / 100;
    var seconds = ml / device.pumpFlowMlPerSec;
    var capped = false;
    if (seconds > settings.maxPumpSeconds) {
      seconds = settings.maxPumpSeconds.toDouble();
      ml = seconds * device.pumpFlowMlPerSec;
      capped = true;
    }
    return (ml: ml, seconds: seconds, capped: capped);
  }

  void assignPlant(String? plantId) {
    _pot = plantId == null ? _pot.copyWith(clearPlant: true) : _pot.copyWith(plantId: plantId);
    _save();
    _pushConfig();
  }

  void rename(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _pot = _pot.copyWith(name: trimmed);
    _save();
  }

  void setFullDoseMl(int ml) {
    _pot = _pot.copyWith(fullDoseMl: ml);
    _save();
    _pushConfig();
  }

  void _onSnapshot(DeviceSnapshot snapshot) {
    _snapshot = snapshot;
    final last = _readings.isEmpty ? null : _readings.last;
    if (last == null || snapshot.time.difference(last.time).inSeconds >= 1) {
      _readings.add(Reading(
        potId: _pot.id,
        time: snapshot.time,
        moisture: snapshot.moisture,
        temperature: snapshot.temperature,
      ));
      final cutoff = DateTime.now().subtract(ChartRange.week.duration);
      _readings.removeWhere((r) => r.time.isBefore(cutoff));
    }
    _checkOnline(notify: false);
    notifyListeners();
  }

  void _onEvent(WateringEvent event) {
    _events.insert(0, event);
    if (_events.length > _maxEvents) _events.removeLast();
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
    // Atanmış özel bitki silindiyse saksıyı boşalt.
    if (_pot.plantId != null && plant == null) {
      assignPlant(null);
    } else {
      _pushConfig();
      notifyListeners();
    }
  }

  Future<void> _pushConfig() {
    final p = plant;
    return device.updateConfig(DeviceConfig(
      fullDoseMl: _pot.fullDoseMl,
      autoMode: settings.autoMode && p != null,
      autoMinMoisture: p?.minMoisture ?? 0,
      autoTargetMoisture: p?.idealMoistureMin ?? 0,
      tankCriticalPercent: settings.tankCriticalThreshold,
      maxPumpSeconds: settings.maxPumpSeconds,
      minIntervalSeconds: settings.minIntervalMinutes * 60,
    ));
  }

  void _load() {
    final raw = _prefs.getString(_kPot);
    if (raw == null) return;
    try {
      _pot = Pot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Saksı ayarları okunamadı: $e');
    }
  }

  void _save() {
    _prefs.setString(_kPot, jsonEncode(_pot.toJson()));
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

/// Ölçümleri [bucket] uzunluğundaki aralıklara bölüp ortalamasını alır.
/// En son ölçüm her zaman korunur, böylece grafik güncel değerde biter.
List<Reading> downsampleReadings(List<Reading> readings, Duration bucket) {
  if (readings.length < 2) return readings;
  final bucketMs = bucket.inMilliseconds;
  final result = <Reading>[];
  var currentKey = readings.first.time.millisecondsSinceEpoch ~/ bucketMs;
  var sumMoisture = 0.0;
  var sumTemp = 0.0;
  var count = 0;
  var bucketTime = readings.first.time;

  void flush() {
    if (count == 0) return;
    result.add(Reading(
      potId: readings.first.potId,
      time: bucketTime,
      moisture: sumMoisture / count,
      temperature: sumTemp / count,
    ));
  }

  for (final r in readings) {
    final key = r.time.millisecondsSinceEpoch ~/ bucketMs;
    if (key != currentKey) {
      flush();
      currentKey = key;
      sumMoisture = 0;
      sumTemp = 0;
      count = 0;
    }
    sumMoisture += r.moisture;
    sumTemp += r.temperature;
    count++;
    bucketTime = r.time;
  }
  flush();

  // Son grubun ortalaması yerine gerçek son değeri göster.
  result[result.length - 1] = readings.last;
  return result;
}
