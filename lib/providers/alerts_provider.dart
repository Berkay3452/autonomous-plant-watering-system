import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/alert.dart';
import '../models/watering_event.dart';
import '../services/device_service.dart';
import '../utils/formatters.dart';
import 'pot_provider.dart';
import 'settings_provider.dart';

/// Bildirim kuralları (doküman 4.6) ve uyarı geçmişi.
///
/// Şimdilik bildirimler uygulama içinde gösterilir. Telefonun bildirim
/// çubuğuna düşmesi için ileride flutter_local_notifications eklenecek;
/// uygulama kapalıyken bildirim için sunucu tarafı gerekir.
class AlertsProvider extends ChangeNotifier {
  AlertsProvider({
    required this._prefs,
    required this.device,
    required this.pot,
    required this.settings,
  }) {
    _load();
  }

  final SharedPreferences _prefs;
  final DeviceService device;
  final PotProvider pot;
  final SettingsProvider settings;

  static const _kAlerts = 'alerts.all';
  static const _maxAlerts = 100;

  final List<AppAlert> _alerts = [];
  final Map<AlertType, DateTime> _lastSent = {};
  final _newAlerts = StreamController<AppAlert>.broadcast();
  DateTime? _drySince;
  bool _wasOnline = false;
  StreamSubscription<WateringEvent>? _eventSub;

  List<AppAlert> get alerts => List.unmodifiable(_alerts);
  int get unreadCount => _alerts.where((a) => !a.read).length;

  /// Yeni oluşan her uyarı. Ekranda kısa mesaj (SnackBar) göstermek için.
  Stream<AppAlert> get newAlerts => _newAlerts.stream;

  void init() {
    pot.addListener(_evaluate);
    _eventSub = device.events.listen(_onEvent);
  }

  void _evaluate() {
    final now = DateTime.now();
    final snapshot = pot.snapshot;
    final plant = pot.plant;

    if (pot.isOnline) _wasOnline = true;

    // Bitki susuz: nem, minimum eşiğin altında belirli süre kalırsa.
    if (pot.isOnline && snapshot != null && plant != null && snapshot.moisture < plant.minMoisture) {
      _drySince ??= now;
      if (now.difference(_drySince!) >= Duration(seconds: settings.dryConfirmSeconds)) {
        _raise(
          AlertType.plantDry,
          '${pot.pot.name}: toprak nemi ${formatPercent(snapshot.moisture)}. '
          '${plant.name} için en az ${formatPercent(plant.minMoisture)} olmalı.',
        );
      }
    } else {
      _drySince = null;
    }

    // Depo düşük.
    final tank = pot.tank;
    if (pot.isOnline && tank.isLow) {
      _raise(
        AlertType.tankLow,
        'Su deposu ${formatPercent(tank.level!)}. Uyarı eşiği ${formatPercent(tank.alertThreshold)}.'
        '${tank.isCritical ? ' Pompalar kilitlendi.' : ''}',
      );
    }

    // Cihaz çevrimdışı (daha önce bağlanmışsa).
    if (_wasOnline && !pot.isOnline) {
      _raise(
        AlertType.deviceOffline,
        'Cihazdan ${settings.offlineAfterSeconds} sn\'dir veri gelmiyor. Planlı sulama '
        'cihazda çalışmaya devam eder.',
      );
    }
  }

  void _onEvent(WateringEvent event) {
    // Manuel sulamanın sonucu zaten ekranda gösteriliyor.
    if (event.source == WateringSource.manual) return;
    if (event.success) {
      _raise(
        AlertType.wateringDone,
        '${event.source.label} sulama: ${event.ml.round()} ml su verildi '
        '(%${event.amountPercent}).${event.message != null ? ' ${event.message}' : ''}',
        respectCooldown: false,
      );
    } else {
      _raise(
        AlertType.wateringBlocked,
        '${event.source.label} sulama yapılamadı. ${event.message ?? ''}',
        respectCooldown: false,
      );
    }
  }

  void _raise(AlertType type, String message, {bool respectCooldown = true}) {
    final now = DateTime.now();
    final last = _lastSent[type];
    if (respectCooldown &&
        last != null &&
        now.difference(last) < Duration(minutes: settings.alertRepeatMinutes)) {
      return;
    }
    _lastSent[type] = now;
    final alert = AppAlert(
      id: 'alert-${now.microsecondsSinceEpoch}',
      type: type,
      potId: pot.pot.id,
      time: now,
      message: message,
    );
    _alerts.insert(0, alert);
    if (_alerts.length > _maxAlerts) _alerts.removeLast();
    _newAlerts.add(alert);
    _save();
  }

  void markRead(String id) {
    final index = _alerts.indexWhere((a) => a.id == id);
    if (index == -1 || _alerts[index].read) return;
    _alerts[index] = _alerts[index].copyWith(read: true);
    _save();
  }

  void markAllRead() {
    for (var i = 0; i < _alerts.length; i++) {
      _alerts[i] = _alerts[i].copyWith(read: true);
    }
    _save();
  }

  void remove(String id) {
    _alerts.removeWhere((a) => a.id == id);
    _save();
  }

  void clear() {
    _alerts.clear();
    _save();
  }

  /// Uyarı tekrar sürelerini sıfırlar (test ve demo için).
  void resetCooldowns() {
    _lastSent.clear();
    _drySince = null;
  }

  void _load() {
    final raw = _prefs.getString(_kAlerts);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      _alerts
        ..clear()
        ..addAll(list.map((e) => AppAlert.fromJson(e as Map<String, dynamic>)));
    } catch (e) {
      debugPrint('Bildirimler okunamadı: $e');
    }
  }

  void _save() {
    _prefs.setString(_kAlerts, jsonEncode(_alerts.map((a) => a.toJson()).toList()));
    notifyListeners();
  }

  @override
  void dispose() {
    pot.removeListener(_evaluate);
    _eventSub?.cancel();
    _newAlerts.close();
    super.dispose();
  }
}
