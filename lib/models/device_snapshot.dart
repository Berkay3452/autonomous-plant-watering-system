/// Bir saksının anlık ölçümleri.
class PotLive {
  const PotLive({
    required this.moisture,
    required this.temperature,
    required this.humidity,
    required this.pumpRunning,
    this.lastWatered,
  });

  /// Toprak nemi (%).
  final double moisture;

  /// Sıcaklık (°C).
  final double temperature;

  /// Hava nemi (%).
  final double humidity;

  final bool pumpRunning;
  final DateTime? lastWatered;
}

/// Cihazdan (ESP32) gelen anlık ölçüm paketi.
class DeviceSnapshot {
  const DeviceSnapshot({
    required this.time,
    required this.tankLevel,
    required this.pumpLocked,
    required this.pots,
  });

  final DateTime time;

  /// Su deposu doluluk oranı (%). Depo tüm saksılar için ortaktır.
  final double tankLevel;

  /// Kuru çalışma koruması devrede mi (depo kritik seviyenin altında).
  final bool pumpLocked;

  /// Saksı kimliğine göre ölçümler.
  final Map<String, PotLive> pots;
}
