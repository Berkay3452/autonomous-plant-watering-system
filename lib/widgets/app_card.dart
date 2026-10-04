import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tasarımdaki yuvarlak köşeli kart. Açık temada yumuşak gölge, koyu temada
/// yarı saydam yüzey kullanır.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
    this.onTap,
    this.radius = AppRadius.card,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final shape = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? p.card,
        borderRadius: shape,
        boxShadow: p.isDark
            ? null
            : const [BoxShadow(color: Color(0x14123D1C), blurRadius: 18, offset: Offset(0, 6))],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: shape,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
