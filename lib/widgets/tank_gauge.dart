import 'package:flutter/material.dart';

import '../models/tank.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Su deposu doluluk göstergesi: dikey depo çizimi + metin.
class TankGauge extends StatelessWidget {
  const TankGauge({super.key, required this.tank, this.onTap});

  final Tank tank;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final level = tank.level;
    final color = tank.isCritical
        ? AppColors.danger
        : tank.isLow
            ? AppColors.warning
            : AppColors.water;

    final String statusText;
    if (level == null) {
      statusText = 'Veri bekleniyor';
    } else if (tank.isCritical) {
      statusText = 'Kritik seviye, pompa kilitli';
    } else if (tank.isLow) {
      statusText = 'Yakında doldurulmalı';
    } else {
      statusText = 'Yeterli';
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              _TankShape(level: level, color: color, threshold: tank.alertThreshold),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Su deposu', style: text.titleSmall?.copyWith(color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 2),
                    Text(
                      level == null ? '—' : formatPercent(level),
                      style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (tank.volumeMl != null)
                      Text(
                        '≈ ${tank.volumeMl!.round()} ml / ${tank.capacityMl.round()} ml',
                        style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Icon(
                          tank.isLow ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                          size: 16,
                          color: color,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            statusText,
                            style: text.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Uyarı eşiği ${formatPercent(tank.alertThreshold)}',
                      style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TankShape extends StatelessWidget {
  const _TankShape({required this.level, required this.color, required this.threshold});

  final double? level;
  final Color color;
  final int threshold;

  static const double _width = 56;
  static const double _height = 96;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fraction = ((level ?? 0) / 100).clamp(0.0, 1.0);
    return Container(
      width: _width,
      height: _height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant, width: 2),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              height: (_height - 4) * fraction,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color.withValues(alpha: 0.65), color],
                ),
              ),
            ),
            // Uyarı eşiği çizgisi.
            Positioned(
              bottom: (_height - 4) * threshold / 100,
              left: 0,
              right: 0,
              child: Container(height: 1.5, color: AppColors.danger.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }
}
