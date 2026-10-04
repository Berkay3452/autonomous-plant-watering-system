import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Geri ve zil düğmeleri gibi yuvarlak simge düğmesi. [showDot] okunmamış
/// bildirim noktası gösterir.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.showDot = false,
    this.tooltip,
    this.size = 44,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final bool showDot;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Tooltip(
      message: tooltip ?? '',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Material(
                color: p.isDark ? p.control : Colors.white,
                elevation: p.isDark ? 0 : 2,
                shadowColor: const Color(0x22123D1C),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onPressed,
                  child: Icon(icon, color: p.isDark ? Colors.white : p.text, size: size * 0.5),
                ),
              ),
            ),
            if (showDot)
              Positioned(
                right: size * 0.2,
                top: size * 0.16,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: p.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: p.isDark ? p.control : Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
