import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/plant.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'plant_illustration.dart';
import 'range_bar.dart';

/// Bitki profilinin ayrıntılarını gösteren alt sayfa.
///
/// Sonuç: "assign" (saksıya ata), "edit" (düzenle), "delete" (sil) ya da null.
Future<String?> showPlantDetailSheet(
  BuildContext context, {
  required Plant plant,
  required bool isAssigned,
  required String potName,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _PlantDetailSheet(plant: plant, isAssigned: isAssigned, potName: potName),
  );
}

class _PlantDetailSheet extends StatelessWidget {
  const _PlantDetailSheet({required this.plant, required this.isAssigned, required this.potName});

  final Plant plant;
  final bool isAssigned;
  final String potName;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final t = context.t;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: p.isDark ? p.heroInner : p.blob,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Center(child: PlantIllustration(kind: plantKindFor(plant), size: 56)),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t(plant.name), style: text.headlineSmall),
                    Text(t(plant.category.typeLabel), style: text.bodyLarge?.copyWith(color: p.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          if (plant.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(t(plant.description), style: text.bodyLarge),
          ],
          const SizedBox(height: AppSpacing.xl),
          _ProfileRow(
            label: t('Toprak nemi'),
            value: t('min {0} · ideal {1}', [
              formatPercent(plant.minMoisture),
              formatPercentRange(plant.idealMoistureMin, plant.idealMoistureMax),
            ]),
            child: RangeBar(
              value: null,
              min: 0,
              max: 100,
              idealMin: plant.idealMoistureMin.toDouble(),
              idealMax: plant.idealMoistureMax.toDouble(),
              threshold: plant.minMoisture.toDouble(),
            ),
          ),
          _ProfileRow(
            label: t('Sıcaklık'),
            value: formatTempRange(plant.tempMin, plant.tempMax),
            child: RangeBar(
              value: null,
              min: 0,
              max: 45,
              idealMin: plant.tempMin,
              idealMax: plant.tempMax,
            ),
          ),
          _ProfileRow(label: t('Su ihtiyacı'), value: t(plant.waterNeed.label)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                plant.source == ValueSource.document ? Icons.verified_outlined : Icons.info_outline,
                size: 16,
                color: p.textMuted,
              ),
              const SizedBox(width: 6),
              Expanded(child: Text(t(plant.source.label), style: text.bodySmall)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: isAssigned ? null : () => Navigator.pop(context, 'assign'),
            icon: Icon(isAssigned ? Icons.check : Icons.add),
            label: Text(isAssigned ? t('{0} için seçili', [potName]) : t('{0} için seç', [potName])),
          ),
          if (plant.isCustom) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context, 'edit'),
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(t('Düzenle')),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context, 'delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: p.warnText,
                      side: BorderSide(color: p.warnText, width: 2),
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(t('Sil')),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.label, required this.value, this.child});

  final String label;
  final String value;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: text.titleSmall)),
              Text(value, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
          if (child != null) ...[const SizedBox(height: AppSpacing.sm), child!],
        ],
      ),
    );
  }
}
