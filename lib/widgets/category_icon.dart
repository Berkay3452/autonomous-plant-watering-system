import 'package:flutter/material.dart';

import '../models/plant.dart';

/// Bitki kategorisinin çizgi simgesi. Kaktüs için Material'da simge olmadığından
/// kendimiz çiziyoruz.
class CategoryIcon extends StatelessWidget {
  const CategoryIcon({super.key, required this.category, this.size = 26, this.color});

  final PlantCategory category;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? Theme.of(context).colorScheme.primary;
    return switch (category) {
      PlantCategory.tropical => Icon(Icons.eco_outlined, size: size, color: c),
      PlantCategory.succulent => Icon(Icons.spa_outlined, size: size, color: c),
      PlantCategory.cactus => SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _CactusIconPainter(c)),
        ),
      PlantCategory.flowering => Icon(Icons.filter_vintage_outlined, size: size, color: c),
      PlantCategory.herb => Icon(Icons.grass, size: size, color: c),
      PlantCategory.vegetable => Icon(Icons.apple, size: size, color: c),
    };
  }
}

class _CactusIconPainter extends CustomPainter {
  _CactusIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      // Gövde.
      ..moveTo(w * 0.42, h * 0.92)
      ..lineTo(w * 0.42, h * 0.2)
      ..quadraticBezierTo(w * 0.42, h * 0.08, w * 0.5, h * 0.08)
      ..quadraticBezierTo(w * 0.58, h * 0.08, w * 0.58, h * 0.2)
      ..lineTo(w * 0.58, h * 0.92)
      // Sol kol.
      ..moveTo(w * 0.42, h * 0.62)
      ..lineTo(w * 0.28, h * 0.62)
      ..quadraticBezierTo(w * 0.2, h * 0.62, w * 0.2, h * 0.54)
      ..lineTo(w * 0.2, h * 0.4)
      // Sağ kol.
      ..moveTo(w * 0.58, h * 0.5)
      ..lineTo(w * 0.72, h * 0.5)
      ..quadraticBezierTo(w * 0.8, h * 0.5, w * 0.8, h * 0.42)
      ..lineTo(w * 0.8, h * 0.3);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CactusIconPainter old) => old.color != color;
}
