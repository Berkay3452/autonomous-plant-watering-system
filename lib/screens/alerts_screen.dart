import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/alert.dart';
import '../providers/alerts_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Uyarı geçmişi ve uyarı eşiği ayarı.
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  Future<void> _confirmClear(BuildContext context) async {
    final alerts = context.read<AlertsProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tüm bildirimler silinsin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Temizle')),
        ],
      ),
    );
    if (confirmed == true) alerts.clear();
  }

  @override
  Widget build(BuildContext context) {
    final alertsProvider = context.watch<AlertsProvider>();
    final settings = context.watch<SettingsProvider>();
    final alerts = alertsProvider.alerts;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          IconButton(
            tooltip: 'Tümünü okundu say',
            onPressed: alertsProvider.unreadCount == 0 ? null : alertsProvider.markAllRead,
            icon: const Icon(Icons.done_all),
          ),
          IconButton(
            tooltip: 'Temizle',
            onPressed: alerts.isEmpty ? null : () => _confirmClear(context),
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, AppSpacing.xl),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.waves, color: AppColors.water),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text('Depo uyarı eşiği', style: text.titleSmall)),
                      Text(
                        formatPercent(settings.tankAlertThreshold),
                        style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  Slider(
                    value: settings.tankAlertThreshold.toDouble(),
                    min: 5,
                    max: 50,
                    divisions: 9,
                    label: formatPercent(settings.tankAlertThreshold),
                    onChanged: (v) => settings.setTankAlertThreshold(v.round()),
                  ),
                  Text(
                    'Bitki susuz uyarısı, saksıdaki bitkinin minimum nem değerine göre verilir. '
                    'Aynı uyarı ${formatMinutes(settings.alertRepeatMinutes)} içinde tekrar gönderilmez.',
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (alerts.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 64),
              child: Column(
                children: [
                  Icon(Icons.notifications_none, size: 64, color: scheme.outline),
                  const SizedBox(height: AppSpacing.md),
                  Text('Bildirim yok', style: text.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Bitki susuz kaldığında, depo azaldığında ya da cihaz\n'
                    'çevrimdışı olduğunda burada görünür.',
                    textAlign: TextAlign.center,
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            )
          else
            for (final alert in alerts)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Dismissible(
                  key: ValueKey(alert.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: const Icon(Icons.delete_outline, color: AppColors.danger),
                  ),
                  onDismissed: (_) => alertsProvider.remove(alert.id),
                  child: _AlertTile(alert: alert, onTap: () => alertsProvider.markRead(alert.id)),
                ),
              ),
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert, required this.onTap});

  final AppAlert alert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final color = switch (alert.type) {
      AlertType.plantDry || AlertType.wateringBlocked || AlertType.deviceOffline => AppColors.danger,
      AlertType.tankLow => AppColors.warning,
      AlertType.wateringDone => AppColors.ideal,
    };

    return Card(
      color: alert.read ? null : color.withValues(alpha: 0.08),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(alert.type.icon, color: color),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                alert.type.label,
                style: text.titleSmall?.copyWith(fontWeight: alert.read ? FontWeight.w500 : FontWeight.w700),
              ),
            ),
            if (!alert.read)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(alert.message),
            const SizedBox(height: 4),
            Text(formatRelative(alert.time), style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
