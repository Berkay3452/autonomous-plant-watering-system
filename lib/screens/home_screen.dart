import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/alerts_provider.dart';
import '../providers/pot_provider.dart';
import '../providers/schedule_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/connection_badge.dart';
import '../widgets/parameter_tile.dart';
import '../widgets/pot_card.dart';
import '../widgets/tank_gauge.dart';
import '../widgets/water_now_sheet.dart';
import 'plants_screen.dart';
import 'pot_detail_screen.dart';
import 'schedule_edit_screen.dart';

/// Panel (ana sayfa): saksı özeti, depo seviyesi, bağlantı durumu ve
/// "şimdi sula".
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onOpenAlerts});

  final VoidCallback? onOpenAlerts;

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PotDetailScreen()));
  }

  void _choosePlant(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PlantsScreen(pickMode: true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pot = context.watch<PotProvider>();
    final schedules = context.watch<ScheduleProvider>();
    final unreadWarnings = context.select<AlertsProvider, int>(
      (a) => a.alerts.where((x) => !x.read && x.type.isWarning).length,
    );
    final snapshot = pot.snapshot;
    final next = schedules.nextFor(pot.pot.id);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel'),
        actions: [
          ConnectionBadge(connection: pot.connection),
          const SizedBox(width: AppSpacing.page),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.sm, AppSpacing.page, AppSpacing.xl),
        children: [
          if (pot.connectionError != null)
            _Banner(
              icon: Icons.error_outline,
              color: AppColors.danger,
              text: pot.connectionError!,
            ),
          if (pot.connection == DeviceConnection.offline && pot.connectionError == null)
            const _Banner(
              icon: Icons.wifi_off,
              color: AppColors.danger,
              text: 'Cihazdan veri gelmiyor. Planlı sulama cihazda sürer; '
                  'bağlantı gelince veriler güncellenir.',
            ),
          if (unreadWarnings > 0)
            _Banner(
              icon: Icons.notifications_active_outlined,
              color: AppColors.warning,
              text: '$unreadWarnings okunmamış uyarı var.',
              onTap: onOpenAlerts,
            ),
          PotCard(
            pot: pot.pot,
            plant: pot.plant,
            status: pot.status,
            snapshot: snapshot,
            onTap: () => _openDetail(context),
            onChoosePlant: () => _choosePlant(context),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: pot.isOnline ? () => showWaterNowSheet(context) : null,
                  icon: const Icon(Icons.water_drop),
                  label: const Text('Şimdi sula'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ScheduleEditScreen(potId: pot.pot.id),
                  )),
                  icon: const Icon(Icons.event_outlined),
                  label: const Text('Plan ekle'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: scheme.secondaryContainer,
                child: Icon(Icons.schedule, color: scheme.onSecondaryContainer),
              ),
              title: const Text('Sıradaki sulama'),
              subtitle: Text(
                next == null
                    ? 'Planlanmış sulama yok'
                    : '${formatUpcoming(next.time)} · ${formatPercent(next.schedule.amountPercent)} · '
                        '${next.schedule.repeat.label}',
              ),
              trailing: next == null
                  ? null
                  : Text(formatCountdown(next.time), style: text.labelMedium),
              onTap: () => _openDetail(context),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TankGauge(tank: pot.tank, onTap: () => _openDetail(context)),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: ParameterTile(
                  icon: Icons.thermostat,
                  label: 'Sıcaklık',
                  value: snapshot == null ? '—' : formatTemperature(snapshot.temperature),
                  color: AppColors.temperature,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ParameterTile(
                  icon: Icons.cloud_outlined,
                  label: 'Hava nemi',
                  value: snapshot == null ? '—' : formatPercent(snapshot.humidity),
                  color: AppColors.humidity,
                ),
              ),
            ],
          ),
          if (snapshot != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Text(
                'Son güncelleme: ${formatTime(snapshot.time)}',
                textAlign: TextAlign.center,
                style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.color, required this.text, this.onTap});

  final IconData icon;
  final Color color;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: Text(text)),
                if (onTap != null) Icon(Icons.chevron_right, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
