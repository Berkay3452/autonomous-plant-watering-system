import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uygulama ayarları. Hepsi telefonda (shared_preferences) saklanır.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._prefs) {
    _load();
  }

  final SharedPreferences _prefs;

  static const _kTheme = 'settings.themeMode';
  static const _kTankAlert = 'settings.tankAlertThreshold';
  static const _kTankCritical = 'settings.tankCriticalThreshold';
  static const _kAutoMode = 'settings.autoMode';
  static const _kMaxPump = 'settings.maxPumpSeconds';
  static const _kMinInterval = 'settings.minIntervalMinutes';
  static const _kAlertRepeat = 'settings.alertRepeatMinutes';
  static const _kOfflineAfter = 'settings.offlineAfterSeconds';
  static const _kDryConfirm = 'settings.dryConfirmSeconds';

  ThemeMode _themeMode = ThemeMode.system;
  int _tankAlertThreshold = 20;
  int _tankCriticalThreshold = 5;
  bool _autoMode = false;
  int _maxPumpSeconds = 30;
  int _minIntervalMinutes = 1;
  int _alertRepeatMinutes = 360;
  int _offlineAfterSeconds = 30;
  int _dryConfirmSeconds = 60;

  ThemeMode get themeMode => _themeMode;

  /// Depo bu yüzdenin altına inince bildirim gider.
  int get tankAlertThreshold => _tankAlertThreshold;

  /// Depo bu yüzdeye inince pompalar kilitlenir (kuru çalışma koruması).
  int get tankCriticalThreshold => _tankCriticalThreshold;

  /// Nem bitkinin minimum eşiğinin altına inince otomatik sulama.
  bool get autoMode => _autoMode;

  /// Tek sulamada pompanın en fazla çalışma süresi.
  int get maxPumpSeconds => _maxPumpSeconds;

  /// İki sulama arasında en az bekleme. Doküman örneği 10 dk; demo için 1 dk.
  int get minIntervalMinutes => _minIntervalMinutes;

  /// Aynı uyarının tekrar gönderilmesi için geçmesi gereken süre.
  int get alertRepeatMinutes => _alertRepeatMinutes;

  /// Bu süre boyunca veri gelmezse cihaz çevrimdışı sayılır.
  int get offlineAfterSeconds => _offlineAfterSeconds;

  /// Nem bu süre boyunca eşiğin altında kalırsa "bitki susuz" bildirimi gider.
  int get dryConfirmSeconds => _dryConfirmSeconds;

  void _load() {
    final theme = _prefs.getString(_kTheme);
    _themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == theme,
      orElse: () => ThemeMode.system,
    );
    _tankAlertThreshold = _prefs.getInt(_kTankAlert) ?? _tankAlertThreshold;
    _tankCriticalThreshold = _prefs.getInt(_kTankCritical) ?? _tankCriticalThreshold;
    _autoMode = _prefs.getBool(_kAutoMode) ?? _autoMode;
    _maxPumpSeconds = _prefs.getInt(_kMaxPump) ?? _maxPumpSeconds;
    _minIntervalMinutes = _prefs.getInt(_kMinInterval) ?? _minIntervalMinutes;
    _alertRepeatMinutes = _prefs.getInt(_kAlertRepeat) ?? _alertRepeatMinutes;
    _offlineAfterSeconds = _prefs.getInt(_kOfflineAfter) ?? _offlineAfterSeconds;
    _dryConfirmSeconds = _prefs.getInt(_kDryConfirm) ?? _dryConfirmSeconds;
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _prefs.setString(_kTheme, mode.name);
    notifyListeners();
  }

  void setTankAlertThreshold(int value) {
    _tankAlertThreshold = value;
    _prefs.setInt(_kTankAlert, value);
    notifyListeners();
  }

  void setTankCriticalThreshold(int value) {
    _tankCriticalThreshold = value;
    _prefs.setInt(_kTankCritical, value);
    notifyListeners();
  }

  void setAutoMode(bool value) {
    _autoMode = value;
    _prefs.setBool(_kAutoMode, value);
    notifyListeners();
  }

  void setMaxPumpSeconds(int value) {
    _maxPumpSeconds = value;
    _prefs.setInt(_kMaxPump, value);
    notifyListeners();
  }

  void setMinIntervalMinutes(int value) {
    _minIntervalMinutes = value;
    _prefs.setInt(_kMinInterval, value);
    notifyListeners();
  }

  void setAlertRepeatMinutes(int value) {
    _alertRepeatMinutes = value;
    _prefs.setInt(_kAlertRepeat, value);
    notifyListeners();
  }

  void setOfflineAfterSeconds(int value) {
    _offlineAfterSeconds = value;
    _prefs.setInt(_kOfflineAfter, value);
    notifyListeners();
  }

  void setDryConfirmSeconds(int value) {
    _dryConfirmSeconds = value;
    _prefs.setInt(_kDryConfirm, value);
    notifyListeners();
  }
}
