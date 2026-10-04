import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Ekran zemini: düz renk ve sol üstte tasarımdaki büyük yuvarlak dekor.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child, this.blob = true});

  final Widget child;
  final bool blob;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ColoredBox(
      color: p.bg,
      child: Stack(
        children: [
          if (blob)
            Positioned(
              left: -60,
              top: -76,
              child: Container(
                width: 276,
                height: 276,
                decoration: BoxDecoration(color: p.blob, shape: BoxShape.circle),
              ),
            ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}
