import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tek bir ölçümü (nem, sıcaklık, depo...) başlık, değer ve açıklamayla
/// gösteren kart. İsteğe bağlı olarak altına [footer] (örn. RangeBar) eklenir.
class ParameterTile extends StatelessWidget {
  const ParameterTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.subtitle,
    this.footer,
    this.warning,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String? subtitle;
  final Widget? footer;

  /// Değer hedefin dışındaysa kısa uyarı metni.
  final String? warning;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final iconBox = Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 20),
    );
    final labelText = Text(
      label,
      style: text.titleSmall?.copyWith(color: scheme.onSurfaceVariant),
      overflow: TextOverflow.ellipsis,
    );
    final valueText = Text(value, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dar kartta (yan yana iki kart) değer başlığın altına iner.
            LayoutBuilder(
              builder: (context, constraints) => constraints.maxWidth < 240
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            iconBox,
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(child: labelText),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        FittedBox(fit: BoxFit.scaleDown, child: valueText),
                      ],
                    )
                  : Row(
                      children: [
                        iconBox,
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: labelText),
                        valueText,
                      ],
                    ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(subtitle!, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            ],
            if (footer != null) ...[
              const SizedBox(height: AppSpacing.md),
              footer!,
            ],
            if (warning != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      warning!,
                      style: text.bodySmall?.copyWith(color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
