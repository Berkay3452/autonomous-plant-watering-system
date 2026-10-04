import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/strings.dart';
import '../models/alert.dart';
import '../models/watering_event.dart';
import '../services/device_service.dart';
import 'pots_provider.dart';
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
    required this.pots,
    required this.settings,
  }) {
    _load();
  }

  final SharedPreferences _prefs;
  final DeviceService device;
  final PotsProvider pots;
  final SettingsProvider settings;

  static const _kAlerts = 'alerts.v3';
  static const _maxAlerts = 100;

  final List<AppAlert> _alerts = [];
  final Map<String, DateTime> _lastSent = {};
  final Map<String, DateTime> _drySince = {};
  final _newAlerts = StreamController<AppAlert>.broadcast();
  bool _wasOnline = false;
  StreamSubscription<WateringEvent>? _eventSub;

  List<AppAlert> get alerts => List.unmodifiable(_alerts);
  int get unreadCount => _alerts.where((a) => !a.read).length;

  /// Yeni oluşan her uyarı. Ekranda kısa mesaj (SnackBar) göstermek için.
  Stream<AppAlert> get newAlerts => _newAlerts.stream;

  void init() {
    pots.addListener(_evaluate);
    _eventSub = device.events.listen(_onEvent);
  }

  String _plantName(String potId) =>
      pots.plantOf(potId)?.name ?? pots.potById(potId)?.name ?? '';

  void _evaluate() {
    final now = DateTime.now();
    if (pots.isOnline) _wasOnline = true;

    // Bitki susadı: nem, minimum eşiğin altında belirli süre kalırsa.
    for (final pot in pots.pots) {
      final live = pots.liveOf(pot.id);
      final plant = pots.plantOf(pot.id);
      if (pots.isOnline && live != null && plant != null && live.moisture < plant.minMoisture) {
        final since = _drySince.putIfAbsent(pot.id, () => now);
        if (now.difference(since) >= Duration(seconds: settings.dryConfirmSeconds)) {
          _raise(
            AlertType.plantDry,
            args: [plant.name, '${live.moisture.round()}'],
            potId: pot.id,
          );
        }
      } else {
        _drySince.remove(pot.id);
      }
    }

    // Depo düşük (depo ortaktır).
    final tank = pots.tank;
    if (pots.isOnline && tank.isLow) {
      _raise(
        AlertType.tankLow,
        args: ['${tank.level!.round()}', tank.isCritical ? '1' : '0'],
      );
    }

    // Cihaz çevrimdışı (daha önce bağlanmışsa).
    if (_wasOnline && !pots.isOnline) {
      _raise(AlertType.deviceOffline, args: ['${settings.offlineAfterSeconds}']);
    }
  }

  void _onEvent(WateringEvent event) {
    // Manuel sulamanın sonucu zaten ekranda gösteriliyor.
    if (event.source == WateringSource.manual) return;
    final note = event.message;
    if (event.success) {
      _raise(
        AlertType.wateringDone,
        args: [_plantName(event.potId), '${event.amountPercent}'],
        note: note,
        potId: event.potId,
        respectCooldown: false,
      );
    } else {
      _raise(
        AlertType.wateringBlocked,
        args: [_plantName(event.potId)],
        note: note,
        potId: event.potId,
        respectCooldown: false,
      );
    }
  }

  void _raise(
    AlertType type, {
    List<String> args = const [],
    Msg? note,
    String? potId,
    bool respectCooldown = true,
  }) {
    final now = DateTime.now();
    final key = '${type.name}:${potId ?? ''}';
    final last = _lastSent[key];
    if (respectCooldown &&
        last != null &&
        now.difference(last) < Duration(minutes: settings.alertRepeatMinutes)) {
      return;
    }
    _lastSent[key] = now;
    final alert = AppAlert(
      id: 'alert-${now.microsecondsSinceEpoch}',
      type: type,
      potId: potId,
      time: now,
      args: args,
      noteKey: note?.key,
      noteArgs: [for (final a in note?.args ?? const []) a is Msg ? a.resolve() : '$a'],
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
    _drySince.clear();
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
    pots.removeListener(_evaluate);
    _eventSub?.cancel();
    _newAlerts.close();
    super.dispose();
  }
}
