/// Geçmiş grafiği için tek ölçüm noktası.
class Reading {
  const Reading({
    required this.potId,
    required this.time,
    required this.moisture,
    required this.temperature,
  });

  final String potId;
  final DateTime time;
  final double moisture;
  final double temperature;
}
