/// Cihazdan (ESP32) gelen anlık ölçüm paketi.
class DeviceSnapshot {
  const DeviceSnapshot({
    required this.time,
    required this.moisture,
    required this.temperature,
    required this.humidity,
    required this.tankLevel,
    required this.pumpRunning,
    required this.pumpLocked,
    this.lastWatered,
  });

  final DateTime time;

  /// Toprak nemi (%).
  final double moisture;

  /// Ortam sıcaklığı (°C).
  final double temperature;

  /// Hava nemi (%).
  final double humidity;

  /// Su deposu doluluk oranı (%).
  final double tankLevel;

  final bool pumpRunning;

  /// Kuru çalışma koruması devrede mi (depo kritik seviyenin altında).
  final bool pumpLocked;

  final DateTime? lastWatered;
}
