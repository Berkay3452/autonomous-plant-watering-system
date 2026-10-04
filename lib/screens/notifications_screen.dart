import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/alert.dart';
import '../providers/alerts_provider.dart';
import '../providers/pots_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_background.dart';
import '../widgets/app_card.dart';
import '../widgets/circle_icon_button.dart';

/// Bildirimler: uyarı geçmişi, güne göre gruplu. Ana sayfadaki zilden açılır.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Future<void> _confirmClear(BuildContext context) async {
    final alerts = context.read<AlertsProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t('Tüm bildirimler silinsin mi?')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.t('Vazgeç'))),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.t('Temizle')),
          ),
        ],
      ),
    );
    if (confirmed == true) alerts.clear();
  }

  @override
  Widget build(BuildContext context) {
    final alertsProvider = context.watch<AlertsProvider>();
    final alerts = alertsProvider.alerts;
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final t = context.t;

    // Güne göre grupla (liste zaten en yeni başta).
    final groups = <String, List<AppAlert>>{};
    for (final alert in alerts) {
      groups.putIfAbsent(formatDayHeader(alert.time), () => []).add(alert);
    }

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.page, 14, 8, 6),
                child: Row(
                  children: [
                    CircleIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      tooltip: t('Geri'),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(t('Bildirimler'), style: text.headlineMedium),
                      ),
                    ),
                    TextButton(
                      onPressed: alertsProvider.unreadCount == 0 ? null : alertsProvider.markAllRead,
                      child: Text(
                        t('Tümünü okundu say'),
                        style: text.labelMedium?.copyWith(
                          color: alertsProvider.unreadCount == 0 ? p.textMuted : p.primary,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: alerts.isEmpty
                    ? const _EmptyState()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.page, 4, AppSpacing.page, 32),
                        children: [
                          for (final entry in groups.entries) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 14, 4, 10),
                              child: Text(
                                entry.key,
                                style: text.bodyLarge?.copyWith(color: p.textMuted, fontWeight: FontWeight.w800),
                              ),
                            ),
                            for (final alert in entry.value)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Dismissible(
                                  key: ValueKey(alert.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 24),
                                    decoration: BoxDecoration(
                                      color: p.warnBg,
                                      borderRadius: BorderRadius.circular(AppRadius.card),
                                    ),
                                    child: Icon(Icons.delete_outline_rounded, color: p.warnFg),
                                  ),
                                  onDismissed: (_) => alertsProvider.remove(alert.id),
                                  child: _AlertCard(alert: alert),
                                ),
                              ),
                          ],
                          const SizedBox(height: 8),
                          Center(
                            child: TextButton.icon(
                              onPressed: () => _confirmClear(context),
                              icon: Icon(Icons.delete_outline_rounded, size: 20, color: p.textMuted),
                              label: Text(
                                t('Tüm bildirimleri temizle'),
                                style: text.labelMedium?.copyWith(color: p.textMuted, fontSize: 13.5),
                              ),
                            ),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(color: p.okBg, shape: BoxShape.circle),
              child: Icon(Icons.notifications_none_rounded, size: 40, color: p.okFg),
            ),
            const SizedBox(height: 16),
            Text(context.t('Bildirim yok'), style: text.titleLarge),
            const SizedBox(height: 6),
            Text(
              context.t('Bitkin susadığında, depo azaldığında ya da cihaz çevrimdışı olduğunda burada görünür.'),
              textAlign: TextAlign.center,
              style: text.bodyLarge?.copyWith(color: p.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});

  final AppAlert alert;

  IconData get _icon => switch (alert.type) {
        AlertType.plantDry => Icons.water_drop_outlined,
        AlertType.tankLow => Icons.propane_tank_outlined,
        AlertType.deviceOffline => Icons.wifi_off_rounded,
        AlertType.wateringBlocked => Icons.block_rounded,
        AlertType.wateringDone => Icons.check_circle_outline_rounded,
      };

  Future<void> _waterNow(BuildContext context) async {
    final pots = context.read<PotsProvider>();
    final alerts = context.read<AlertsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final potId = alert.potId;
    if (potId == null) return;
    alerts.markRead(alert.id);
    final result = await pots.waterNow(potId, 50);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(
          result.accepted
              ? Strings.t('Sulama başladı: ≈ {0} ml, {1}.', [result.ml.round(), formatSeconds(result.durationSeconds)])
              : Strings.t('Sulama başlatılamadı. {0}', [result.message!.resolve()]),
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final warning = alert.type.isWarning;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
      onTap: () => context.read<AlertsProvider>().markRead(alert.id),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: warning ? p.warnBg : p.okBg, shape: BoxShape.circle),
                child: Icon(_icon, color: warning ? p.warnButtonOnLight : p.okFg, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(alert.title, style: text.titleMedium?.copyWith(fontSize: 18))),
                        if (!alert.read)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(color: p.primary, shape: BoxShape.circle),
                          ),
                        Text(
                          formatTime(alert.time),
                          style: text.bodyMedium?.copyWith(color: p.textMuted, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(alert.message, style: text.bodyLarge?.copyWith(color: p.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          if (alert.type == AlertType.plantDry && alert.potId != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: p.warnButton,
                  foregroundColor: p.onWarnButton,
                  minimumSize: const Size(64, 46),
                ),
                onPressed: () => _waterNow(context),
                icon: const Icon(Icons.water_drop_outlined, size: 20),
                label: Text(context.t('Şimdi Sula')),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
