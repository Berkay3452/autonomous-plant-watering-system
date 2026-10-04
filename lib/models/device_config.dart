/// Cihaza gönderilen saksıya özel ayarlar.
class PotConfig {
  const PotConfig({
    this.fullDoseMl = 200,
    this.minMoisture = 0,
    this.targetMoisture = 0,
  });

  /// %100 sulamanın karşılığı (ml).
  final int fullDoseMl;

  /// Otomatik modda sulamanın başladığı nem (%).
  final int minMoisture;

  /// Otomatik modda sulamanın durduğu nem (%).
  final int targetMoisture;
}

/// Uygulamanın cihaza gönderdiği ayarlar. Güvenlik kuralları (kuru çalışma,
/// azami pompa süresi, asgari bekleme) cihaz tarafında uygulanır.
class DeviceConfig {
  const DeviceConfig({
    this.autoMode = false,
    this.tankCriticalPercent = 5,
    this.maxPumpSeconds = 30,
    this.minIntervalSeconds = 60,
    this.pots = const {},
  });

  /// Nem eşiğin altına inince cihazın kendiliğinden sulaması.
  final bool autoMode;
  final int tankCriticalPercent;
  final int maxPumpSeconds;
  final int minIntervalSeconds;
  final Map<String, PotConfig> pots;

  PotConfig potConfig(String potId) => pots[potId] ?? const PotConfig();
}
