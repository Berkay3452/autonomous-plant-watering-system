/// Su deposu durumu.
class Tank {
  const Tank({
    required this.level,
    required this.alertThreshold,
    required this.criticalThreshold,
    required this.capacityMl,
  });

  /// Doluluk (%). Veri yoksa null.
  final double? level;

  /// Kullanıcının belirlediği uyarı eşiği (%).
  final int alertThreshold;

  /// Bu seviyenin altında pompalar kilitlenir (%).
  final int criticalThreshold;

  final double capacityMl;

  bool get isLow => level != null && level! < alertThreshold;
  bool get isCritical => level != null && level! <= criticalThreshold;
  double? get volumeMl => level == null ? null : capacityMl * level! / 100;
}
