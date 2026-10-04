import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Ana sayfadaki bitki halkası: ortada [child] (bitki çizimi), çevresinde
/// toprak nemini gösteren ilerleme yayı. Yay 12 yönünden saat yönünde dolar.
class MoistureRing extends StatelessWidget {
  const MoistureRing({super.key, required this.value, required this.child, this.size = 224});

  /// 0–100 arası nem. Null ise yay çizilmez.
  final double? value;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: ((value ?? 0).clamp(0, 100)) / 100),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, progress, child) => CustomPaint(
        painter: _RingPainter(
          progress: progress,
          inner: p.heroInner,
          ring: p.ring,
          track: p.ringTrack,
        ),
        child: SizedBox(width: size, height: size, child: Center(child: child)),
      ),
      child: child,
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.inner, required this.ring, required this.track});

  final double progress;
  final Color inner;
  final Color ring;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 6.5;
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - stroke / 2 - 1;

    canvas.drawCircle(center, radius - 14, Paint()..color = inner);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, paint..color = track);
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        paint..color = ring,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.inner != inner || old.ring != ring || old.track != track;
}
