/// Uygulamanın cihaza gönderdiği ayarlar. Güvenlik kuralları (kuru çalışma,
/// azami pompa süresi, asgari bekleme) cihaz tarafında uygulanır.
class DeviceConfig {
  const DeviceConfig({
    this.fullDoseMl = 200,
    this.autoMode = false,
    this.autoMinMoisture = 40,
    this.autoTargetMoisture = 55,
    this.tankCriticalPercent = 5,
    this.maxPumpSeconds = 30,
    this.minIntervalSeconds = 60,
  });

  final int fullDoseMl;
  final bool autoMode;
  final int autoMinMoisture;
  final int autoTargetMoisture;
  final int tankCriticalPercent;
  final int maxPumpSeconds;
  final int minIntervalSeconds;
}
