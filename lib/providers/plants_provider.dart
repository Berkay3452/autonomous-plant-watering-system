import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/plant_catalog.dart';
import '../models/plant.dart';

/// Hazır bitki kataloğu + kullanıcının eklediği bitkiler.
class PlantsProvider extends ChangeNotifier {
  PlantsProvider(this._prefs) {
    _load();
  }

  final SharedPreferences _prefs;
  static const _kCustomPlants = 'plants.custom';

  final List<Plant> _custom = [];

  List<Plant> get all => [...plantCatalog, ..._custom];

  List<Plant> get customPlants => List.unmodifiable(_custom);

  Plant? byId(String? id) {
    if (id == null) return null;
    for (final plant in all) {
      if (plant.id == id) return plant;
    }
    return null;
  }

  List<Plant> inCategory(PlantCategory category) =>
      all.where((p) => p.category == category).toList();

  String newCustomId() => 'custom-${DateTime.now().microsecondsSinceEpoch}';

  void addCustom(Plant plant) {
    _custom.add(plant);
    _save();
  }

  void updateCustom(Plant plant) {
    final index = _custom.indexWhere((p) => p.id == plant.id);
    if (index == -1) return;
    _custom[index] = plant;
    _save();
  }

  void deleteCustom(String id) {
    _custom.removeWhere((p) => p.id == id);
    _save();
  }

  void _load() {
    final raw = _prefs.getString(_kCustomPlants);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      _custom
        ..clear()
        ..addAll(list.map((e) => Plant.fromJson(e as Map<String, dynamic>)));
    } catch (e) {
      debugPrint('Kayıtlı bitkiler okunamadı: $e');
    }
  }

  void _save() {
    _prefs.setString(
      _kCustomPlants,
      jsonEncode(_custom.map((p) => p.toJson()).toList()),
    );
    notifyListeners();
  }
}
