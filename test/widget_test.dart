import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:autonomous_plant_watering_system/data/plant_catalog.dart';
import 'package:autonomous_plant_watering_system/models/plant.dart';
import 'package:autonomous_plant_watering_system/models/pot.dart';
import 'package:autonomous_plant_watering_system/theme/app_theme.dart';
import 'package:autonomous_plant_watering_system/widgets/metric_card.dart';
import 'package:autonomous_plant_watering_system/widgets/pill_segmented.dart';
import 'package:autonomous_plant_watering_system/widgets/plant_illustration.dart';
import 'package:autonomous_plant_watering_system/widgets/status_pill.dart';

Widget _host(Widget child, {bool dark = false}) => MaterialApp(
      theme: dark ? AppTheme.dark(googleFonts: false) : AppTheme.light(googleFonts: false),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('StatusPill durum metnini gösterir', (tester) async {
    await tester.pumpWidget(_host(StatusPill(label: PotStatus.dry.label, tone: PotStatus.dry.tone)));
    expect(find.text('Sulama gerekli'), findsOneWidget);
  });

  testWidgets('MetricCard başlık ve değeri gösterir (koyu temada da)', (tester) async {
    for (final dark in [false, true]) {
      await tester.pumpWidget(_host(
        const SizedBox(
          width: 170,
          child: MetricCard(icon: Icons.water_drop_outlined, label: 'Toprak nemi', value: '%62'),
        ),
        dark: dark,
      ));
      expect(find.text('Toprak nemi'), findsOneWidget);
      expect(find.text('%62'), findsOneWidget);
    }
  });

  testWidgets('PillSegmented seçimi değiştirir', (tester) async {
    var value = 'a';
    await tester.pumpWidget(_host(
      StatefulBuilder(
        builder: (context, setState) => SizedBox(
          width: 300,
          child: PillSegmented<String>(
            items: const [('a', 'Saksı 1'), ('b', 'Saksı 2')],
            value: value,
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Saksı 2'));
    await tester.pump();
    expect(value, 'b');
  });

  testWidgets('PillSegmented devre dışı seçenek yine de bildirir ama çağıran karar verir', (tester) async {
    String? tapped;
    await tester.pumpWidget(_host(
      SizedBox(
        width: 300,
        child: PillSegmented<String>(
          items: const [('tr', 'Türkçe'), ('en', 'English')],
          value: 'tr',
          disabled: const {'en'},
          onChanged: (v) => tapped = v,
        ),
      ),
    ));
    await tester.tap(find.text('English'));
    expect(tapped, 'en');
  });

  testWidgets('her bitki türü çizilir', (tester) async {
    for (final kind in PlantKind.values) {
      await tester.pumpWidget(_host(PlantIllustration(kind: kind, size: 100)));
      expect(find.byType(PlantIllustration), findsOneWidget, reason: kind.name);
    }
  });

  test('bitkiye uygun çizim seçilir', () {
    Plant plant(String id) => plantCatalog.firstWhere((p) => p.id == id);
    expect(plantKindFor(null), PlantKind.empty);
    expect(plantKindFor(plant('difenbahya')), PlantKind.leafy);
    expect(plantKindFor(plant('baris-cicegi')), PlantKind.lily);
    expect(plantKindFor(plant('aloe-vera')), PlantKind.rosette);
    expect(plantKindFor(plant('kaktus')), PlantKind.cactus);
    expect(plantKindFor(plant('sardunya')), PlantKind.flower);
    expect(plantKindFor(plant('feslegen')), PlantKind.herb);
    expect(plantKindFor(plant('domates')), PlantKind.fruit);
  });
}
