import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Toprak nemini gösteren dairesel gösterge. İdeal aralık yay üzerinde
/// açık renkle işaretlenir.
class MoistureGauge extends StatelessWidget {
  const MoistureGauge({
    super.key,
    required this.value,
    required this.color,
    this.idealMin,
    this.idealMax,
    this.size = 120,
    this.label = 'Toprak nemi',
  });

  /// 0–100 arası nem. Null ise "—" gösterilir.
  final double? value;
  final Color color;
  final int? idealMin;
  final int? idealMax;
  final double size;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: (value ?? 0).clamp(0, 100)),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, animated, _) {
          return CustomPaint(
            painter: _GaugePainter(
              value: animated,
              color: color,
              trackColor: scheme.surfaceContainerHighest,
              idealColor: AppColors.ideal.withValues(alpha: 0.35),
              idealMin: idealMin,
              idealMax: idealMax,
              strokeWidth: size * 0.09,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value == null ? '—' : formatPercent(animated),
                    style: (size >= 110 ? text.headlineMedium : text.titleLarge)
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    label,
                    style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.value,
    required this.color,
    required this.trackColor,
    required this.idealColor,
    required this.strokeWidth,
    this.idealMin,
    this.idealMax,
  });

  final double value;
  final Color color;
  final Color trackColor;
  final Color idealColor;
  final double strokeWidth;
  final int? idealMin;
  final int? idealMax;

  // Yay, alttaki 90°'lik boşluk hariç 270° çizilir.
  static const double _start = 135 * pi / 180;
  static const double _sweep = 270 * pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    Paint stroke(Color c, double width) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = width;

    canvas.drawArc(rect, _start, _sweep, false, stroke(trackColor, strokeWidth));

    if (idealMin != null && idealMax != null) {
      final from = _start + _sweep * idealMin! / 100;
      final sweep = _sweep * (idealMax! - idealMin!) / 100;
      canvas.drawArc(rect, from, sweep, false, stroke(idealColor, strokeWidth));
    }

    if (value > 0) {
      canvas.drawArc(
        rect,
        _start,
        _sweep * value / 100,
        false,
        stroke(color, strokeWidth * 0.55),
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value ||
      old.color != color ||
      old.idealMin != idealMin ||
      old.idealMax != idealMax ||
      old.trackColor != trackColor;
}
