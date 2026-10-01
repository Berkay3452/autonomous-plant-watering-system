import 'package:flutter/material.dart';

import '../models/device_snapshot.dart';
import '../models/plant.dart';
import '../models/pot.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'moisture_gauge.dart';
import 'status_chip.dart';

/// Panelde saksının özetini gösteren kart.
class PotCard extends StatelessWidget {
  const PotCard({
    super.key,
    required this.pot,
    required this.plant,
    required this.status,
    required this.snapshot,
    this.onTap,
    this.onChoosePlant,
  });

  final Pot pot;
  final Plant? plant;
  final PotStatus status;
  final DeviceSnapshot? snapshot;
  final VoidCallback? onTap;
  final VoidCallback? onChoosePlant;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final color = AppColors.forStatus(status, scheme);
    final s = snapshot;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(pot.name, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  StatusChip(status: status),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  MoistureGauge(
                    value: s?.moisture,
                    color: color == scheme.outline ? AppColors.moisture : color,
                    idealMin: plant?.idealMoistureMin,
                    idealMax: plant?.idealMoistureMax,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: plant == null
                        ? _NoPlant(onChoosePlant: onChoosePlant)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(plant!.category.icon, size: 18, color: scheme.primary),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      plant!.name,
                                      style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'İdeal nem ${formatPercent(plant!.idealMoistureMin)}–${plant!.idealMoistureMax}',
                                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _InfoRow(
                                icon: Icons.thermostat,
                                color: AppColors.temperature,
                                text: s == null ? '—' : formatTemperature(s.temperature),
                              ),
                              _InfoRow(
                                icon: Icons.water_drop_outlined,
                                color: AppColors.humidity,
                                text: s == null ? '—' : 'Hava nemi ${formatPercent(s.humidity)}',
                              ),
                              _InfoRow(
                                icon: Icons.history,
                                color: scheme.onSurfaceVariant,
                                text: s?.lastWatered == null
                                    ? 'Henüz sulanmadı'
                                    : 'Sulandı: ${formatRelative(s!.lastWatered!)}',
                              ),
                            ],
                          ),
                  ),
                ],
              ),
              if (s?.pumpRunning ?? false) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    const Icon(Icons.water, size: 18, color: AppColors.water),
                    const SizedBox(width: 6),
                    Text('Pompa çalışıyor…', style: text.labelLarge?.copyWith(color: AppColors.water)),
                  ],
                ),
                const SizedBox(height: 6),
                const LinearProgressIndicator(color: AppColors.water),
              ],
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Detaylar için dokunun',
                  style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _NoPlant extends StatelessWidget {
  const _NoPlant({this.onChoosePlant});

  final VoidCallback? onChoosePlant;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bu saksıya henüz bitki atanmadı.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.sm),
        FilledButton.tonalIcon(
          onPressed: onChoosePlant,
          icon: const Icon(Icons.local_florist),
          label: const Text('Bitki seç'),
        ),
      ],
    );
  }
}
