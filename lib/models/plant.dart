import 'package:flutter/material.dart';

/// Bitki kategorileri. Bitkiler ekranında filtre olarak kullanılır.
enum PlantCategory {
  vegetable('Sebzeler', Icons.eco),
  herb('Aromatik bitkiler', Icons.spa),
  succulent('Sukulent ve kaktüsler', Icons.wb_sunny_outlined),
  houseplant('Salon bitkileri', Icons.local_florist),
  other('Diğer', Icons.yard);

  const PlantCategory(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Bitkinin su ihtiyacı (dokümandaki "sulamaSeviyesi" alanı).
enum WaterNeed {
  low('Düşük'),
  medium('Orta'),
  mediumHigh('Orta / Yüksek'),
  high('Yüksek');

  const WaterNeed(this.label);

  final String label;
}

/// Profil değerlerinin nereden geldiğini gösterir. Ekipçe doğrulanmamış
/// değerleri arayüzde ayırt edebilmek için tutulur.
enum ValueSource {
  document('Proje dokümanındaki değerler'),
  documentPartial('Nem değerleri dokümandan, sıcaklık aralığı tahmini'),
  estimate('Genel bakım bilgisi, ekipçe doğrulanmalı'),
  user('Kullanıcı tarafından eklendi');

  const ValueSource(this.label);

  final String label;
}

/// Bitki profili. Nem değerleri kapasitif sensörün yüzde ölçeğindedir.
///
/// [minMoisture] otomatik sulamanın ve "bitki susuz" bildiriminin eşiğidir;
/// [idealMoistureMin]–[idealMoistureMax] aralığı hedef seviyedir.
class Plant {
  const Plant({
    required this.id,
    required this.name,
    required this.category,
    required this.minMoisture,
    required this.idealMoistureMin,
    required this.idealMoistureMax,
    required this.waterNeed,
    required this.tempMin,
    required this.tempMax,
    this.description = '',
    this.source = ValueSource.estimate,
  });

  final String id;
  final String name;
  final PlantCategory category;
  final int minMoisture;
  final int idealMoistureMin;
  final int idealMoistureMax;
  final WaterNeed waterNeed;
  final double tempMin;
  final double tempMax;
  final String description;
  final ValueSource source;

  bool get isCustom => source == ValueSource.user;

  Plant copyWith({
    String? name,
    PlantCategory? category,
    int? minMoisture,
    int? idealMoistureMin,
    int? idealMoistureMax,
    WaterNeed? waterNeed,
    double? tempMin,
    double? tempMax,
    String? description,
  }) {
    return Plant(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      minMoisture: minMoisture ?? this.minMoisture,
      idealMoistureMin: idealMoistureMin ?? this.idealMoistureMin,
      idealMoistureMax: idealMoistureMax ?? this.idealMoistureMax,
      waterNeed: waterNeed ?? this.waterNeed,
      tempMin: tempMin ?? this.tempMin,
      tempMax: tempMax ?? this.tempMax,
      description: description ?? this.description,
      source: source,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.name,
        'minMoisture': minMoisture,
        'idealMoistureMin': idealMoistureMin,
        'idealMoistureMax': idealMoistureMax,
        'waterNeed': waterNeed.name,
        'tempMin': tempMin,
        'tempMax': tempMax,
        'description': description,
        'source': source.name,
      };

  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      id: json['id'] as String,
      name: json['name'] as String,
      category: PlantCategory.values.byName(json['category'] as String),
      minMoisture: json['minMoisture'] as int,
      idealMoistureMin: json['idealMoistureMin'] as int,
      idealMoistureMax: json['idealMoistureMax'] as int,
      waterNeed: WaterNeed.values.byName(json['waterNeed'] as String),
      tempMin: (json['tempMin'] as num).toDouble(),
      tempMax: (json['tempMax'] as num).toDouble(),
      description: json['description'] as String? ?? '',
      source: ValueSource.values.byName(json['source'] as String? ?? 'user'),
    );
  }
}
