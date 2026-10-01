import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:autonomous_plant_watering_system/models/pot.dart';
import 'package:autonomous_plant_watering_system/widgets/range_bar.dart';
import 'package:autonomous_plant_watering_system/widgets/status_chip.dart';

void main() {
  testWidgets('StatusChip durum metnini gösterir', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: StatusChip(status: PotStatus.dry)),
    ));
    expect(find.text('Susuz'), findsOneWidget);
  });

  testWidgets('RangeBar değer olmadan da çizilir', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 300,
          child: RangeBar(value: null, min: 0, max: 100, idealMin: 40, idealMax: 60, threshold: 30),
        ),
      ),
    ));
    expect(find.byType(RangeBar), findsOneWidget);
  });
}
