import 'dart:math';

import 'package:flutter/material.dart';

import '../models/plant.dart';

/// Çizilen bitki türleri.
enum PlantKind { leafy, rosette, lily, cactus, flower, herb, fruit, empty }

/// Bitkiye uygun çizimi seçer. Bitki yoksa boş saksı çizilir.
PlantKind plantKindFor(Plant? plant) {
  if (plant == null) return PlantKind.empty;
  switch (plant.id) {
    case 'baris-cicegi':
      return PlantKind.lily;
    case 'difenbahya':
    case 'salon-sarmasigi':
      return PlantKind.leafy;
  }
  return switch (plant.category) {
    PlantCategory.tropical => PlantKind.leafy,
    PlantCategory.succulent => PlantKind.rosette,
    PlantCategory.cactus => PlantKind.cactus,
    PlantCategory.flowering => PlantKind.flower,
    PlantCategory.herb => PlantKind.herb,
    PlantCategory.vegetable => PlantKind.fruit,
  };
}

/// Tasarımdaki düz renkli saksı + bitki çizimi. [size] çizimin yüksekliğidir.
class PlantIllustration extends StatelessWidget {
  const PlantIllustration({super.key, required this.kind, this.size = 140});

  final PlantKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 0.8,
      height: size,
      child: CustomPaint(painter: _PlantPainter(kind)),
    );
  }
}

class _PotColors {
  const _PotColors(this.body, this.shade, this.rim, this.band);

  final Color body;
  final Color shade;
  final Color rim;
  final Color? band;
}

const _cream = _PotColors(Color(0xFFFBF7EA), Color(0xFFEFE6D0), Color(0xFFF3ECD8), Color(0xFFB5DE5C));
const _gray = _PotColors(Color(0xFF5C6E65), Color(0xFF4B5C54), Color(0xFF6A7C73), null);
const _terracotta = _PotColors(Color(0xFFCB7541), Color(0xFFB4642F), Color(0xFFD88652), null);

class _PlantPainter extends CustomPainter {
  _PlantPainter(this.kind);

  final PlantKind kind;

  static const _darkLeaf = Color(0xFF2F7D41);
  static const _midLeaf = Color(0xFF55AE7C);
  static const _lightLeaf = Color(0xFF7DCB9C);
  static const _vein = Color(0x88DFF5E5);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final base = Offset(w * 0.5, h * 0.64);

    // Zemindeki gölge.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.95), width: w * 0.8, height: h * 0.055),
      Paint()..color = const Color(0x22000000),
    );

    switch (kind) {
      case PlantKind.leafy:
        _leafy(canvas, base, w, h);
      case PlantKind.rosette:
        _rosette(canvas, base, w, h);
      case PlantKind.lily:
        _lily(canvas, base, w, h);
      case PlantKind.cactus:
        _cactus(canvas, w, h);
      case PlantKind.flower:
        _flower(canvas, base, w, h);
      case PlantKind.herb:
        _herb(canvas, base, w, h);
      case PlantKind.fruit:
        _fruit(canvas, base, w, h);
      case PlantKind.empty:
        _sprout(canvas, base, w, h);
    }

    final colors = switch (kind) {
      PlantKind.lily => _gray,
      PlantKind.cactus || PlantKind.fruit => _terracotta,
      _ => _cream,
    };
    _pot(canvas, w, h, colors);
  }

  void _leaf(Canvas c, Offset base, double angle, double length, double width, Color color,
      {bool vein = false}) {
    c.save();
    c.translate(base.dx, base.dy);
    c.rotate(angle * pi / 180);
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-width, -length * 0.45, 0, -length)
      ..quadraticBezierTo(width, -length * 0.45, 0, 0)
      ..close();
    c.drawPath(path, Paint()..color = color);
    if (vein) {
      c.drawLine(
        Offset(0, -length * 0.1),
        Offset(0, -length * 0.8),
        Paint()
          ..color = _vein
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
    }
    c.restore();
  }

  void _leafy(Canvas c, Offset b, double w, double h) {
    _leaf(c, b, -58, h * 0.40, w * 0.17, _darkLeaf, vein: true);
    _leaf(c, b, 58, h * 0.40, w * 0.17, _darkLeaf, vein: true);
    _leaf(c, b, -30, h * 0.50, w * 0.18, _midLeaf, vein: true);
    _leaf(c, b, 30, h * 0.50, w * 0.18, _midLeaf, vein: true);
    _leaf(c, b, 0, h * 0.57, w * 0.17, _lightLeaf, vein: true);
  }

  void _rosette(Canvas c, Offset b, double w, double h) {
    const angles = [-68.0, 68.0, -46.0, 46.0, -24.0, 24.0, 0.0];
    const lengths = [0.34, 0.34, 0.42, 0.42, 0.48, 0.48, 0.52];
    for (var i = 0; i < angles.length; i++) {
      _leaf(c, b, angles[i], h * lengths[i], w * 0.1, i.isEven ? _darkLeaf : _midLeaf);
    }
  }

  void _lily(Canvas c, Offset b, double w, double h) {
    const angles = [-62.0, 62.0, -40.0, 40.0, -18.0, 18.0];
    const lengths = [0.34, 0.34, 0.42, 0.42, 0.48, 0.48];
    for (var i = 0; i < angles.length; i++) {
      _leaf(c, b, angles[i], h * lengths[i], w * 0.1, i < 2 ? const Color(0xFF2E7D4F) : const Color(0xFF3F9462));
    }
    for (final (angle, length) in const [(-14.0, 0.5), (14.0, 0.44)]) {
      c.save();
      c.translate(b.dx + (angle < 0 ? -w * 0.03 : w * 0.03), b.dy);
      c.rotate(angle * pi / 180);
      c.drawLine(
        Offset.zero,
        Offset(0, -h * length * 0.7),
        Paint()
          ..color = const Color(0xFF3F9462)
          ..strokeWidth = 2,
      );
      c.translate(0, -h * length * 0.45);
      final spathe = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(-w * 0.13, -h * 0.1, 0, -h * 0.26)
        ..quadraticBezierTo(w * 0.13, -h * 0.1, 0, 0)
        ..close();
      c.drawPath(spathe, Paint()..color = Colors.white);
      c.drawLine(
        Offset.zero,
        Offset(0, -h * 0.14),
        Paint()
          ..color = const Color(0xFFF2D16B)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
      c.restore();
    }
  }

  void _cactus(Canvas c, double w, double h) {
    final paint = Paint()..color = const Color(0xFF4F9A5E);
    final dark = Paint()..color = const Color(0xFF3F864F);
    // Sol kol.
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(w * 0.24, h * 0.38, w * 0.46, h * 0.46), Radius.circular(w * 0.04)),
      dark,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(w * 0.24, h * 0.28, w * 0.33, h * 0.46), Radius.circular(w * 0.05)),
      dark,
    );
    // Sağ kol.
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(w * 0.54, h * 0.44, w * 0.76, h * 0.52), Radius.circular(w * 0.04)),
      dark,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(w * 0.67, h * 0.32, w * 0.76, h * 0.52), Radius.circular(w * 0.05)),
      dark,
    );
    // Gövde.
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(w * 0.38, h * 0.14, w * 0.62, h * 0.7), Radius.circular(w * 0.12)),
      paint,
    );
    final line = Paint()
      ..color = const Color(0x55FFFFFF)
      ..strokeWidth = 1.5;
    for (final x in [0.44, 0.5, 0.56]) {
      c.drawLine(Offset(w * x, h * 0.2), Offset(w * x, h * 0.66), line);
    }
  }

  void _flower(Canvas c, Offset b, double w, double h) {
    final stem = Paint()
      ..color = const Color(0xFF3F9462)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const heads = [(0.28, 0.3), (0.5, 0.16), (0.72, 0.32)];
    const colors = [Color(0xFFF48FB1), Color(0xFFFFB74D), Color(0xFFBA68C8)];
    for (var i = 0; i < heads.length; i++) {
      final top = Offset(w * heads[i].$1, h * heads[i].$2);
      final path = Path()
        ..moveTo(b.dx, b.dy)
        ..quadraticBezierTo(b.dx + (top.dx - b.dx) * 0.2, (b.dy + top.dy) / 2, top.dx, top.dy);
      c.drawPath(path, stem);
    }
    _leaf(c, b, -50, h * 0.22, w * 0.1, _midLeaf);
    _leaf(c, b, 50, h * 0.22, w * 0.1, _midLeaf);
    for (var i = 0; i < heads.length; i++) {
      final center = Offset(w * heads[i].$1, h * heads[i].$2);
      for (var k = 0; k < 5; k++) {
        final a = k * 2 * pi / 5;
        c.drawCircle(center + Offset(cos(a), sin(a)) * (w * 0.07), w * 0.06, Paint()..color = colors[i]);
      }
      c.drawCircle(center, w * 0.045, Paint()..color = const Color(0xFFFFE082));
    }
  }

  void _herb(Canvas c, Offset b, double w, double h) {
    const angles = [-75.0, 75.0, -55.0, 55.0, -35.0, 35.0, -15.0, 15.0, 0.0];
    const lengths = [0.26, 0.26, 0.34, 0.34, 0.4, 0.4, 0.45, 0.45, 0.5];
    for (var i = 0; i < angles.length; i++) {
      _leaf(
        c,
        b + Offset((i.isEven ? -1 : 1) * w * 0.05, 0),
        angles[i],
        h * lengths[i],
        w * 0.07,
        i % 3 == 0 ? _darkLeaf : (i % 3 == 1 ? _midLeaf : _lightLeaf),
      );
    }
  }

  void _fruit(Canvas c, Offset b, double w, double h) {
    c.drawLine(
      b,
      Offset(w * 0.5, h * 0.2),
      Paint()
        ..color = const Color(0xFF3F9462)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    _leaf(c, Offset(w * 0.5, h * 0.5), -55, h * 0.26, w * 0.09, _darkLeaf);
    _leaf(c, Offset(w * 0.5, h * 0.5), 55, h * 0.26, w * 0.09, _darkLeaf);
    _leaf(c, Offset(w * 0.5, h * 0.34), -45, h * 0.2, w * 0.08, _midLeaf);
    _leaf(c, Offset(w * 0.5, h * 0.34), 45, h * 0.2, w * 0.08, _midLeaf);
    for (final (x, y) in const [(0.34, 0.5), (0.64, 0.42), (0.52, 0.56)]) {
      c.drawCircle(Offset(w * x, h * y), w * 0.075, Paint()..color = const Color(0xFFE5483B));
      c.drawCircle(Offset(w * x, h * y - w * 0.07), w * 0.025, Paint()..color = _darkLeaf);
    }
  }

  void _sprout(Canvas c, Offset b, double w, double h) {
    _leaf(c, b, -35, h * 0.16, w * 0.08, _midLeaf);
    _leaf(c, b, 35, h * 0.16, w * 0.08, _lightLeaf);
  }

  void _pot(Canvas c, double w, double h, _PotColors colors) {
    // Toprak.
    c.drawOval(
      Rect.fromLTRB(w * 0.2, h * 0.595, w * 0.8, h * 0.655),
      Paint()..color = const Color(0xFF6B4A3A),
    );
    // Saksı gövdesi.
    final body = Path()
      ..moveTo(w * 0.22, h * 0.66)
      ..lineTo(w * 0.78, h * 0.66)
      ..lineTo(w * 0.69, h * 0.92)
      ..quadraticBezierTo(w * 0.68, h * 0.94, w * 0.64, h * 0.94)
      ..lineTo(w * 0.36, h * 0.94)
      ..quadraticBezierTo(w * 0.32, h * 0.94, w * 0.31, h * 0.92)
      ..close();
    c.save();
    c.clipPath(body);
    c.drawPath(body, Paint()..color = colors.body);
    c.drawRect(Rect.fromLTRB(w * 0.62, h * 0.6, w, h), Paint()..color = colors.shade);
    if (colors.band != null) {
      c.drawRect(Rect.fromLTRB(0, h * 0.74, w, h * 0.79), Paint()..color = colors.band!);
    }
    c.restore();
    // Kenar.
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.18, h * 0.625, w * 0.82, h * 0.69),
        Radius.circular(h * 0.03),
      ),
      Paint()..color = colors.rim,
    );
  }

  @override
  bool shouldRepaint(_PlantPainter old) => old.kind != kind;
}
