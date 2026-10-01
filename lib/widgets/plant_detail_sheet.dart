import 'package:flutter/material.dart';

import '../models/plant.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'range_bar.dart';

/// Bitki profilinin ayrıntılarını gösteren alt sayfa.
///
/// Sonuç: "assign" (saksıya ata), "edit" (düzenle), "delete" (sil) ya da null.
Future<String?> showPlantDetailSheet(
  BuildContext context, {
  required Plant plant,
  required bool isAssigned,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _PlantDetailSheet(plant: plant, isAssigned: isAssigned),
  );
}

class _PlantDetailSheet extends StatelessWidget {
  const _PlantDetailSheet({required this.plant, required this.isAssigned});

  final Plant plant;
  final bool isAssigned;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: scheme.primaryContainer,
                child: Icon(plant.category.icon, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plant.name, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
                    Text(plant.category.label, style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          if (plant.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(plant.description, style: text.bodyLarge),
          ],
          const SizedBox(height: AppSpacing.xl),
          _ProfileRow(
            label: 'Toprak nemi',
            value: 'min ${formatPercent(plant.minMoisture)} · ideal '
                '${formatPercent(plant.idealMoistureMin)}–${plant.idealMoistureMax}',
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
            label: 'Sıcaklık',
            value: '${plant.tempMin.round()}–${plant.tempMax.round()} °C',
            child: RangeBar(
              value: null,
              min: 0,
              max: 45,
              idealMin: plant.tempMin,
              idealMax: plant.tempMax,
            ),
          ),
          _ProfileRow(label: 'Su ihtiyacı', value: plant.waterNeed.label),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                plant.source == ValueSource.document ? Icons.verified_outlined : Icons.info_outline,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  plant.source.label,
                  style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: isAssigned ? null : () => Navigator.pop(context, 'assign'),
            icon: Icon(isAssigned ? Icons.check : Icons.add),
            label: Text(isAssigned ? 'Saksıda bu bitki var' : 'Saksıya ata'),
          ),
          if (plant.isCustom) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context, 'edit'),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Düzenle'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context, 'delete'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Sil'),
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
              Text(value, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          if (child != null) ...[const SizedBox(height: AppSpacing.sm), child!],
        ],
      ),
    );
  }
}
