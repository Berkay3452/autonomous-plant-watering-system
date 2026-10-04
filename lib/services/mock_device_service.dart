import 'dart:async';
import 'dart:math';

import '../l10n/strings.dart';
import '../models/device_config.dart';
import '../models/device_snapshot.dart';
import '../models/reading.dart';
import '../models/schedule.dart';
import '../models/watering_event.dart';
import 'device_service.dart';

/// Tek saksının sahte durumu.
class _PotSim {
  _PotSim(
    this.id, {
    required this.moisture,
    required this.temperature,
    required this.humidity,
    required this.tempOffset,
  });

  final String id;
  double moisture;
  double temperature;
  double humidity;

  /// Saksının ortam sıcaklığına göre farkı (°C). Saksılar farklı noktalarda.
  final double tempOffset;
  bool pumpRunning = false;
  DateTime? lastWatered;
  Timer? pumpTimer;
  bool autoCycle = false;
  final List<Reading> history = [];
  final List<WateringEvent> events = [];
}

/// ESP32'yi taklit eden sahte cihaz.
///
/// Firmware mantığını (doküman 3.5) basitçe canlandırır: toprak zamanla kurur,
/// pompa çalışınca depo azalır ve nem artar, programlar cihaz tarafında
/// çalışır, kuru çalışma / azami süre / asgari bekleme kuralları uygulanır.
/// "Çevrimdışı" moddayken veri göndermez ama programlı sulamayı sürdürür.
class MockDeviceService implements DeviceService {
  MockDeviceService({
    this.tickInterval = const Duration(seconds: 3),
    Random? random,
    DateTime Function()? clock,
  })  : _random = random ?? Random(),
        _now = clock ?? DateTime.now {
    _pots = {
      pot1: _PotSim(pot1, moisture: 62, temperature: 23, humidity: 48, tempOffset: 0),
      pot2: _PotSim(pot2, moisture: 30, temperature: 22, humidity: 47, tempOffset: -1),
    };
  }

  static const String pot1 = 'pot-1';
  static const String pot2 = 'pot-2';

  /// Pompalanan her ml suyun toprak neminde yarattığı artış (yüzde puanı).
  static const double _moisturePerMl = 0.175;
  static const Duration _historyRange = Duration(days: 30);
  static const Duration _pumpStep = Duration(milliseconds: 250);

  final Duration tickInterval;
  final Random _random;

  /// Şu anki zaman. Testlerde sahte saat verilebilir.
  final DateTime Function() _now;

  final _snapshotController = StreamController<DeviceSnapshot>.broadcast();
  final _eventController = StreamController<WateringEvent>.broadcast();

  late final Map<String, _PotSim> _pots;
  Timer? _ticker;
  bool _connected = false;
  bool _offline = false;

  double _tankMl = 1560;
  double _dryingMultiplier = 1;

  DeviceConfig _config = const DeviceConfig();
  List<WateringSchedule> _schedules = [];
  final Map<String, DateTime> _scheduleFired = {};
  final List<WateringEvent> _pendingEvents = [];
  DeviceSnapshot? _last;

  @override
  String get name => 'Sahte cihaz (mock)';

  @override
  bool get isConnected => _connected;

  @override
  List<String> get potIds => _pots.keys.toList();

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
    _generateHistory(_now());
    _connected = true;
    _ticker = Timer.periodic(tickInterval, (_) => _tick());
    _emit();
  }

  @override
  Future<void> disconnect() async {
    _ticker?.cancel();
    for (final pot in _pots.values) {
      pot.pumpTimer?.cancel();
      pot.pumpRunning = false;
    }
    _connected = false;
  }

  @override
  Future<List<Reading>> fetchHistory(String potId, Duration range) async {
    final from = _now().subtract(range);
    return _pots[potId]?.history.where((r) => r.time.isAfter(from)).toList() ?? [];
  }

  @override
  Future<List<WateringEvent>> fetchEvents(String potId, Duration range) async {
    final from = _now().subtract(range);
    return _pots[potId]?.events.where((e) => e.time.isAfter(from)).toList() ?? [];
  }

  @override
  Future<WateringResult> waterNow(String potId, int amountPercent) async {
    if (!_connected || _offline) {
      return const WateringResult.rejected(Msg('Cihaza ulaşılamıyor.'));
    }
    if (!_pots.containsKey(potId)) {
      return const WateringResult.rejected(Msg('Bu saksı cihazda tanımlı değil.'));
    }
    // Komut gecikmesi (hedef: 2 sn altında).
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _startWatering(potId, WateringSource.manual, amountPercent);
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

  void drySoil(String potId) {
    final pot = _pots[potId];
    if (pot == null) return;
    pot.moisture = 15;
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
    final now = _now();
    for (final pot in _pots.values) {
      _simulateEnvironment(pot, now);
      _checkAutoMode(pot, now);
      final last = pot.history.isEmpty ? null : pot.history.last.time;
      if (last == null || now.difference(last) >= const Duration(minutes: 1)) {
        pot.history.add(Reading(
          potId: pot.id,
          time: now,
          moisture: pot.moisture,
          temperature: pot.temperature,
        ));
        final cutoff = now.subtract(_historyRange);
        pot.history.removeWhere((r) => r.time.isBefore(cutoff));
      }
    }
    _checkSchedules(now);
    _emit();
  }

  void _simulateEnvironment(_PotSim pot, DateTime now) {
    final targetTemp = _dailyTemperature(now) + pot.tempOffset;
    pot.temperature += (targetTemp - pot.temperature) * 0.1 + _noise(0.08);
    final targetHumidity = 50 - (pot.temperature - 22) * 2;
    pot.humidity += (targetHumidity - pot.humidity) * 0.1 + _noise(0.2);
    pot.humidity = pot.humidity.clamp(20, 90);

    if (!pot.pumpRunning) {
      // Sıcaklık arttıkça toprak daha hızlı kurur. 3 sn'lik adımda 0,006 puan:
      // saatte ~7 puan (demo için gerçeğinden hızlı ama izlenebilir).
      final heatFactor = 1 + (pot.temperature - 22) * 0.05;
      pot.moisture -= 0.006 * _dryingMultiplier * heatFactor + _noise(0.003);
      pot.moisture = pot.moisture.clamp(0, 100);
    }
  }

  void _checkSchedules(DateTime now) {
    for (final schedule in _schedules) {
      if (!_pots.containsKey(schedule.potId)) continue;
      final fired = _scheduleFired[schedule.id];
      var effective = schedule;
      if (fired != null && (schedule.lastRun == null || fired.isAfter(schedule.lastRun!))) {
        effective = schedule.copyWith(lastRun: fired);
      }
      if (effective.isDue(now)) {
        _scheduleFired[schedule.id] = now;
        _startWatering(
          schedule.potId,
          WateringSource.scheduled,
          schedule.amountPercent,
          scheduleId: schedule.id,
        );
      }
    }
  }

  void _checkAutoMode(_PotSim pot, DateTime now) {
    final cfg = _config.potConfig(pot.id);
    if (!_config.autoMode || cfg.minMoisture <= 0) {
      pot.autoCycle = false;
      return;
    }
    if (pot.moisture < cfg.minMoisture) pot.autoCycle = true;
    if (pot.moisture >= cfg.targetMoisture) pot.autoCycle = false;
    // Kısa doz ver, bekle, tekrar ölç. Bekleme, asgari aralık kuralıyla sağlanır.
    if (pot.autoCycle && _blockReason(pot, now) == null) {
      _startWatering(pot.id, WateringSource.auto, 25);
    }
  }

  /// Sulamayı engelleyen bir güvenlik kuralı varsa açıklamasını döndürür.
  Msg? _blockReason(_PotSim pot, DateTime now) {
    if (pot.pumpRunning) return const Msg('Pompa zaten çalışıyor.');
    if (_tankPercent <= _config.tankCriticalPercent) {
      return const Msg('Depo kritik seviyede, pompa kilitli (kuru çalışma koruması).');
    }
    final last = pot.lastWatered;
    if (last != null) {
      final wait = Duration(seconds: _config.minIntervalSeconds) - now.difference(last);
      if (wait > Duration.zero) {
        final seconds = wait.inSeconds + 1;
        final remaining = seconds >= 60 ? Msg('{0} dk', [(seconds / 60).ceil()]) : Msg('{0} sn', [seconds]);
        return Msg(
          'Son sulamanın üzerinden yeterli süre geçmedi. {0} sonra tekrar deneyin (aşırı sulama koruması).',
          [remaining],
        );
      }
    }
    return null;
  }

  WateringResult _startWatering(
    String potId,
    WateringSource source,
    int amountPercent, {
    String? scheduleId,
  }) {
    final pot = _pots[potId]!;
    final now = _now();
    final reason = _blockReason(pot, now);
    if (reason != null) {
      _publishEvent(pot, WateringEvent(
        potId: potId,
        time: now,
        source: source,
        amountPercent: amountPercent,
        success: false,
        message: reason,
        scheduleId: scheduleId,
      ));
      return WateringResult.rejected(reason);
    }

    var targetMl = _config.potConfig(potId).fullDoseMl * amountPercent / 100;
    var duration = targetMl / pumpFlowMlPerSec;
    Msg? note;
    if (duration > _config.maxPumpSeconds) {
      duration = _config.maxPumpSeconds.toDouble();
      targetMl = duration * pumpFlowMlPerSec;
      note = Msg('Azami pompa süresi ({0} sn) nedeniyle doz kısaltıldı.', [_config.maxPumpSeconds]);
    }

    pot.pumpRunning = true;
    _emit();

    var delivered = 0.0;
    final stepMl = pumpFlowMlPerSec * _pumpStep.inMilliseconds / 1000;
    pot.pumpTimer = Timer.periodic(_pumpStep, (timer) {
      final amount = min(stepMl, targetMl - delivered);
      _tankMl = max(0, _tankMl - amount);
      pot.moisture = min(100, pot.moisture + amount * _moisturePerMl);
      delivered += amount;

      final tankCritical = _tankPercent <= _config.tankCriticalPercent;
      if (delivered >= targetMl - 0.001 || tankCritical) {
        timer.cancel();
        pot.pumpRunning = false;
        pot.lastWatered = _now();
        if (tankCritical && delivered < targetMl - 0.001) {
          note = const Msg('Depo kritik seviyeye düştü, pompa erken durduruldu.');
        }
        final event = WateringEvent(
          potId: potId,
          time: pot.lastWatered!,
          source: source,
          amountPercent: amountPercent,
          success: true,
          ml: delivered,
          durationSeconds: delivered / pumpFlowMlPerSec,
          message: note,
          scheduleId: scheduleId,
        );
        pot.events.add(event);
        _publishEvent(pot, event, record: false);
      }
      _emit();
    });

    return WateringResult.accepted(ml: targetMl, durationSeconds: duration);
  }

  void _publishEvent(_PotSim pot, WateringEvent event, {bool record = true}) {
    if (record && event.success) pot.events.add(event);
    if (_offline) {
      _pendingEvents.add(event);
    } else {
      _eventController.add(event);
    }
  }

  void _emit() {
    if (!_connected || _offline || _snapshotController.isClosed) return;
    final snapshot = DeviceSnapshot(
      time: _now(),
      tankLevel: _tankPercent,
      pumpLocked: _tankPercent <= _config.tankCriticalPercent,
      pots: {
        for (final pot in _pots.values)
          pot.id: PotLive(
            moisture: pot.moisture,
            temperature: pot.temperature,
            humidity: pot.humidity,
            pumpRunning: pot.pumpRunning,
            lastWatered: pot.lastWatered,
          ),
      },
    );
    _last = snapshot;
    _snapshotController.add(snapshot);
  }

  /// Son 30 gün için gerçekçi görünen geçmiş üretir: nem yavaşça düşer,
  /// sabah 08:00'de programlı sulamayla yükselir; sıcaklık gün içinde dalgalanır.
  void _generateHistory(DateTime now) {
    // Saksı 1 düzenli sulanır (Pzt, Çar, Cum, Paz). Saksı 2 son 30 saattir
    // sulanmamış gibi kurur, böylece "sulama gerekli" durumu görülebilir.
    _generatePotHistory(
      _pots[pot1]!,
      now,
      start: 58,
      days: const {1, 3, 5, 7},
      gain: 20,
      cap: 68,
      amountPercent: 40,
    );
    _generatePotHistory(
      _pots[pot2]!,
      now,
      start: 58,
      days: const {1, 2, 3, 4, 5, 6, 7},
      gain: 12,
      cap: 66,
      amountPercent: 40,
      lateDryFrom: now.subtract(const Duration(hours: 30)),
    );
    _tankMl = tankCapacityMl * 0.78;
  }

  void _generatePotHistory(
    _PotSim pot,
    DateTime now, {
    required double start,
    required Set<int> days,
    required double gain,
    required double cap,
    required int amountPercent,
    DateTime? lateDryFrom,
  }) {
    pot.history.clear();
    pot.events.clear();
    var t = DateTime(now.year, now.month, now.day, now.hour, now.minute ~/ 15 * 15)
        .subtract(_historyRange);
    var moisture = start;
    DateTime? lastWatered;
    while (t.isBefore(now)) {
      final temperature = _dailyTemperature(t) + pot.tempOffset + _noise(0.4);
      final late = lateDryFrom != null && t.isAfter(lateDryFrom);
      final heat = 1 + (temperature - 22) * 0.05;
      moisture -= (late ? 0.3 : 0.12 * heat) + _noise(0.03);
      if (!late && t.hour == 8 && t.minute == 0 && days.contains(t.weekday)) {
        // Toprak zaten yeterince nemliyse (üst sınıra yakınsa) az su verilir.
        final added = min(gain, max(0.0, cap - moisture));
        if (added >= 3) {
          moisture += added;
          lastWatered = t;
          pot.events.add(WateringEvent(
            potId: pot.id,
            time: t,
            source: WateringSource.scheduled,
            amountPercent: amountPercent,
            success: true,
            ml: added / _moisturePerMl,
            durationSeconds: added / _moisturePerMl / pumpFlowMlPerSec,
            scheduleId: pot.id,
          ));
        }
      }
      moisture = moisture.clamp(0, 100);
      pot.history.add(Reading(
        potId: pot.id,
        time: t,
        moisture: moisture,
        temperature: temperature,
      ));
      t = t.add(const Duration(minutes: 15));
    }
    pot.moisture = moisture;
    pot.temperature = _dailyTemperature(now) + pot.tempOffset;
    pot.lastWatered = lastWatered;
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
    for (final pot in _pots.values) {
      pot.pumpTimer?.cancel();
    }
    _snapshotController.close();
    _eventController.close();
  }
}
