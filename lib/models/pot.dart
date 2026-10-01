import 'plant.dart';

/// Saksı ayarları. Canlı ölçümler [DeviceSnapshot] içinde gelir.
class Pot {
  const Pot({
    required this.id,
    required this.name,
    this.plantId,
    this.fullDoseMl = 200,
  });

  final String id;
  final String name;

  /// Saksıya atanmış bitkinin kimliği. Null ise bitki seçilmemiştir.
  final String? plantId;

  /// %100 sulama miktarının karşılığı (ml). Doküman 3.4: "tam doz".
  final int fullDoseMl;

  Pot copyWith({String? name, String? plantId, bool clearPlant = false, int? fullDoseMl}) {
    return Pot(
      id: id,
      name: name ?? this.name,
      plantId: clearPlant ? null : (plantId ?? this.plantId),
      fullDoseMl: fullDoseMl ?? this.fullDoseMl,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'plantId': plantId,
        'fullDoseMl': fullDoseMl,
      };

  factory Pot.fromJson(Map<String, dynamic> json) {
    return Pot(
      id: json['id'] as String,
      name: json['name'] as String,
      plantId: json['plantId'] as String?,
      fullDoseMl: json['fullDoseMl'] as int? ?? 200,
    );
  }
}

/// Saksının bitkiye göre nem durumu.
enum PotStatus {
  noPlant('Bitki seçilmedi'),
  unknown('Veri yok'),
  dry('Susuz'),
  low('İdealin altında'),
  ideal('İdeal'),
  wet('Fazla ıslak');

  const PotStatus(this.label);

  final String label;
}

PotStatus evaluatePotStatus(double? moisture, Plant? plant) {
  if (plant == null) return PotStatus.noPlant;
  if (moisture == null) return PotStatus.unknown;
  if (moisture < plant.minMoisture) return PotStatus.dry;
  if (moisture < plant.idealMoistureMin) return PotStatus.low;
  if (moisture <= plant.idealMoistureMax) return PotStatus.ideal;
  return PotStatus.wet;
}
