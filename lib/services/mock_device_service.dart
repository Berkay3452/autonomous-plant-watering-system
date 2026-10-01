import 'dart:async';
import 'dart:math';

import '../models/device_config.dart';
import '../models/device_snapshot.dart';
import '../models/reading.dart';
import '../models/schedule.dart';
import '../models/watering_event.dart';
import 'device_service.dart';

/// ESP32'yi taklit eden sahte cihaz.
///
/// Firmware mantığını (doküman 3.5) basitçe canlandırır: toprak zamanla kurur,
/// pompa çalışınca depo azalır ve nem artar, planlar cihaz tarafında çalışır,
/// kuru çalışma / azami süre / asgari bekleme kuralları uygulanır.
/// "Çevrimdışı" moddayken veri göndermez ama planlı sulamayı sürdürür.
class MockDeviceService implements DeviceService {
  MockDeviceService({
    this.tickInterval = const Duration(seconds: 3),
    Random? random,
  }) : _random = random ?? Random();

  static const String defaultPotId = 'pot-1';

  /// Pompalanan her ml suyun toprak neminde yarattığı artış (yüzde puanı).
  static const double _moisturePerMl = 0.175;
  static const Duration _historyRange = Duration(days: 7);
  static const Duration _pumpStep = Duration(milliseconds: 250);

  final Duration tickInterval;
  final Random _random;

  final _snapshotController = StreamController<DeviceSnapshot>.broadcast();
  final _eventController = StreamController<WateringEvent>.broadcast();

  Timer? _ticker;
  Timer? _pumpTimer;
  bool _connected = false;
  bool _offline = false;

  double _moisture = 58;
  double _temperature = 23;
  double _humidity = 48;
  double _tankMl = 1600;
  bool _pumpRunning = false;
  DateTime? _lastWatered;
  bool _autoCycleActive = false;
  double _dryingMultiplier = 1;

  DeviceConfig _config = const DeviceConfig();
  List<WateringSchedule> _schedules = [];
  final Map<String, DateTime> _scheduleFired = {};
  final List<Reading> _history = [];
  final List<WateringEvent> _pendingEvents = [];
  DeviceSnapshot? _last;

  @override
  String get name => 'Sahte cihaz (mock)';

  @override
  bool get isConnected => _connected;

  @override
  double get pumpFlowMlPerSec => 8;

  @override
  double get tankCapacityMl => 2000;

  @override
  Stream<DeviceSnapshot> get snapshots => _snapshotController.stream;

  @override
  Stream<WateringEvent> get events => _eventController.stream;

  @override
  DeviceSnapshot? get lastSnapshot => _last;

  bool get isOffline => _offline;
  double get dryingMultiplier => _dryingMultiplier;
  double get _tankPercent => _tankMl / tankCapacityMl * 100;

  @override
  Future<void> connect() async {
    if (_connected) return;
    // Gerçek bağlantı gecikmesini taklit et.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _generateHistory(DateTime.now());
    _connected = true;
    _ticker = Timer.periodic(tickInterval, (_) => _tick());
    _emit();
  }

  @override
  Future<void> disconnect() async {
    _ticker?.cancel();
    _pumpTimer?.cancel();
    _pumpRunning = false;
    _connected = false;
  }

  @override
  Future<List<Reading>> fetchHistory(String potId, Duration range) async {
    final from = DateTime.now().subtract(range);
    return _history.where((r) => r.time.isAfter(from)).toList();
  }

  @override
  Future<WateringResult> waterNow(String potId, int amountPercent) async {
    if (!_connected || _offline) {
      return const WateringResult.rejected('Cihaza ulaşılamıyor.');
    }
    // Komut gecikmesi (hedef: 2 sn altında).
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _startWatering(WateringSource.manual, amountPercent);
  }

  @override
  Future<void> syncSchedules(List<WateringSchedule> schedules) async {
    _schedules = List.of(schedules);
  }

  @override
  Future<void> updateConfig(DeviceConfig config) async {
    _config = config;
    _emit();
  }

  // ---------------------------------------------------------------------------
  // Simülasyon kontrolleri (yalnızca test ve demo için; Ayarlar ekranında).

  void refillTank() {
    _tankMl = tankCapacityMl;
    _emit();
  }

  void setTankLevel(double percent) {
    _tankMl = tankCapacityMl * percent.clamp(0, 100) / 100;
    _emit();
  }

  void drySoil() {
    _moisture = 15;
    _emit();
  }

  void setDryingMultiplier(double value) {
    _dryingMultiplier = value;
  }

  void setOffline(bool offline) {
    _offline = offline;
    if (!offline) {
      // Bağlantı gelince bekleyen olayları gönder (gerçek cihaz da böyle yapar).
      for (final event in _pendingEvents) {
        _eventController.add(event);
      }
      _pendingEvents.clear();
      _emit();
    }
  }

  // ---------------------------------------------------------------------------

  void _tick() {
    final now = DateTime.now();
    _simulateEnvironment(now);
    _checkSchedules(now);
    _checkAutoMode(now);

    _history.add(Reading(
      potId: defaultPotId,
      time: now,
      moisture: _moisture,
      temperature: _temperature,
    ));
    final cutoff = now.subtract(_historyRange);
    _history.removeWhere((r) => r.time.isBefore(cutoff));

    _emit();
  }

  void _simulateEnvironment(DateTime now) {
    final targetTemp = _dailyTemperature(now);
    _temperature += (targetTemp - _temperature) * 0.1 + _noise(0.08);
    final targetHumidity = 50 - (_temperature - 22) * 2;
    _humidity += (targetHumidity - _humidity) * 0.1 + _noise(0.2);
    _humidity = _humidity.clamp(20, 90);

    if (!_pumpRunning) {
      // Sıcaklık arttıkça toprak daha hızlı kurur. 3 sn'lik adımda 0,02 puan:
      // saatte ~24 puan (demo için gerçeğinden hızlı ama izlenebilir).
      final heatFactor = 1 + (_temperature - 22) * 0.05;
      _moisture -= 0.02 * _dryingMultiplier * heatFactor + _noise(0.01);
      _moisture = _moisture.clamp(0, 100);
    }
  }

  void _checkSchedules(DateTime now) {
    for (final schedule in _schedules) {
      final fired = _scheduleFired[schedule.id];
      var effective = schedule;
      if (fired != null && (schedule.lastRun == null || fired.isAfter(schedule.lastRun!))) {
        effective = schedule.copyWith(lastRun: fired);
      }
      if (effective.isDue(now)) {
        _scheduleFired[schedule.id] = now;
        _startWatering(
          WateringSource.scheduled,
          schedule.amountPercent,
          scheduleId: schedule.id,
        );
      }
    }
  }

  void _checkAutoMode(DateTime now) {
    if (!_config.autoMode) {
      _autoCycleActive = false;
      return;
    }
    if (_moisture < _config.autoMinMoisture) _autoCycleActive = true;
    if (_moisture >= _config.autoTargetMoisture) _autoCycleActive = false;
    // Kısa doz ver, bekle, tekrar ölç. Bekleme, asgari aralık kuralıyla sağlanır.
    if (_autoCycleActive && _blockReason(now) == null) {
      _startWatering(WateringSource.auto, 25);
    }
  }

  /// Sulamayı engelleyen bir güvenlik kuralı varsa açıklamasını döndürür.
  String? _blockReason(DateTime now) {
    if (_pumpRunning) return 'Pompa zaten çalışıyor.';
    if (_tankPercent <= _config.tankCriticalPercent) {
      return 'Depo kritik seviyede, pompa kilitli (kuru çalışma koruması).';
    }
    final last = _lastWatered;
    if (last != null) {
      final wait = Duration(seconds: _config.minIntervalSeconds) - now.difference(last);
      if (wait > Duration.zero) {
        final seconds = wait.inSeconds + 1;
        final text = seconds >= 60 ? '${(seconds / 60).ceil()} dk' : '$seconds sn';
        return 'Son sulamanın üzerinden yeterli süre geçmedi. $text sonra tekrar '
            'deneyin (aşırı sulama koruması).';
      }
    }
    return null;
  }

  WateringResult _startWatering(
    WateringSource source,
    int amountPercent, {
    String? scheduleId,
  }) {
    final now = DateTime.now();
    final reason = _blockReason(now);
    if (reason != null) {
      _publishEvent(WateringEvent(
        potId: defaultPotId,
        time: now,
        source: source,
        amountPercent: amountPercent,
        success: false,
        message: reason,
        scheduleId: scheduleId,
      ));
      return WateringResult.rejected(reason);
    }

    var targetMl = _config.fullDoseMl * amountPercent / 100;
    var duration = targetMl / pumpFlowMlPerSec;
    String? note;
    if (duration > _config.maxPumpSeconds) {
      duration = _config.maxPumpSeconds.toDouble();
      targetMl = duration * pumpFlowMlPerSec;
      note = 'Azami pompa süresi (${_config.maxPumpSeconds} sn) nedeniyle doz kısaltıldı.';
    }

    _pumpRunning = true;
    _emit();

    var delivered = 0.0;
    final stepMl = pumpFlowMlPerSec * _pumpStep.inMilliseconds / 1000;
    _pumpTimer = Timer.periodic(_pumpStep, (timer) {
      final amount = min(stepMl, targetMl - delivered);
      _tankMl = max(0, _tankMl - amount);
      _moisture = min(100, _moisture + amount * _moisturePerMl);
      delivered += amount;

      final tankCritical = _tankPercent <= _config.tankCriticalPercent;
      if (delivered >= targetMl - 0.001 || tankCritical) {
        timer.cancel();
        _pumpRunning = false;
        _lastWatered = DateTime.now();
        if (tankCritical && delivered < targetMl - 0.001) {
          note = 'Depo kritik seviyeye düştü, pompa erken durduruldu.';
        }
        _publishEvent(WateringEvent(
          potId: defaultPotId,
          time: _lastWatered!,
          source: source,
          amountPercent: amountPercent,
          success: true,
          ml: delivered,
          durationSeconds: delivered / pumpFlowMlPerSec,
          message: note,
          scheduleId: scheduleId,
        ));
      }
      _emit();
    });

    return WateringResult.accepted(ml: targetMl, durationSeconds: duration);
  }

  void _publishEvent(WateringEvent event) {
    if (_offline) {
      _pendingEvents.add(event);
    } else {
      _eventController.add(event);
    }
  }

  void _emit() {
    if (!_connected || _offline || _snapshotController.isClosed) return;
    final snapshot = DeviceSnapshot(
      time: DateTime.now(),
      moisture: _moisture,
      temperature: _temperature,
      humidity: _humidity,
      tankLevel: _tankPercent,
      pumpRunning: _pumpRunning,
      pumpLocked: _tankPercent <= _config.tankCriticalPercent,
      lastWatered: _lastWatered,
    );
    _last = snapshot;
    _snapshotController.add(snapshot);
  }

  /// Son 7 gün için gerçekçi görünen geçmiş veri üretir: nem yavaşça düşer,
  /// eşiğe gelince sulanır; sıcaklık gün içinde dalgalanır.
  void _generateHistory(DateTime now) {
    _history.clear();
    var t = now.subtract(_historyRange);
    var moisture = 64.0;
    var tank = tankCapacityMl;
    DateTime? lastWatered;
    while (t.isBefore(now)) {
      final temperature = _dailyTemperature(t) + _noise(0.4);
      moisture -= 0.25 * (1 + (temperature - 22) * 0.05) + _noise(0.08);
      if (moisture < 44) {
        moisture += 200 * 0.6 * _moisturePerMl;
        tank -= 120;
        lastWatered = t;
      }
      moisture = moisture.clamp(0, 100);
      _history.add(Reading(
        potId: defaultPotId,
        time: t,
        moisture: moisture,
        temperature: temperature,
      ));
      t = t.add(const Duration(minutes: 15));
    }
    _moisture = moisture;
    _temperature = _dailyTemperature(now);
    _tankMl = max(tank, tankCapacityMl * 0.6);
    _lastWatered = lastWatered;
  }

  /// Gün içi sıcaklık eğrisi: en düşük sabah 03:00, en yüksek öğleden sonra 15:00.
  double _dailyTemperature(DateTime t) {
    final hour = t.hour + t.minute / 60;
    return 22 + 4 * sin(2 * pi * (hour - 9) / 24);
  }

  double _noise(double amplitude) => (_random.nextDouble() * 2 - 1) * amplitude;

  @override
  void dispose() {
    _ticker?.cancel();
    _pumpTimer?.cancel();
    _snapshotController.close();
    _eventController.close();
  }
}
