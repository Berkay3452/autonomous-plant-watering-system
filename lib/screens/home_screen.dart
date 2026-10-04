import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/pot.dart';
import '../providers/alerts_provider.dart';
import '../providers/pots_provider.dart';
import '../providers/schedule_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_background.dart';
import '../widgets/circle_icon_button.dart';
import '../widgets/metric_card.dart';
import '../widgets/moisture_ring.dart';
import '../widgets/pill_segmented.dart';
import '../widgets/plant_illustration.dart';
import '../widgets/status_pill.dart';
import '../widgets/water_now_sheet.dart';
import 'schedule_screen.dart';

/// Ana sayfa: seçili saksının bitkisi, nemi, durumu ve hızlı sulama.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onOpenNotifications});

  final VoidCallback onOpenNotifications;

  String _headline(PotsProvider pots, PotStatus status) {
    final live = pots.liveOf(pots.selectedId);
    if (live == null) {
      return pots.connection == DeviceConnection.offline
          ? Strings.t('Cihaza ulaşılamıyor')
          : Strings.t('Cihaza bağlanılıyor');
    }
    return switch (status) {
      PotStatus.noPlant => Strings.t('Saksına bir bitki seç'),
      PotStatus.dry => Strings.t('Bitkinin suya ihtiyacı var'),
      PotStatus.low => Strings.t('Bitkin biraz kuru'),
      PotStatus.wet => Strings.t('Bitkin fazla ıslak'),
      _ => Strings.t('Bitkin iyi görünüyor'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final pots = context.watch<PotsProvider>();
    final schedules = context.watch<ScheduleProvider>();
    final settings = context.watch<SettingsProvider>();
    final unread = context.select<AlertsProvider, int>((a) => a.unreadCount);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final t = context.t;

    final pot = pots.selected;
    final plant = pots.plantOf(pot.id);
    final live = pots.liveOf(pot.id);
    final status = pots.statusOf(pot.id);
    final next = schedules.nextFor(pot.id);
    final tank = pots.tank;

    return AppBackground(
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Stack(
            children: [
              // Bitkinin arkasındaki büyük yuvarlak.
              Positioned(
                top: 120,
                left: -20,
                right: -20,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: p.blob, shape: BoxShape.circle),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.page, 14, AppSpacing.page, 120),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t('Merhaba, {0}', [settings.userName]),
                                style: text.bodyLarge?.copyWith(color: p.textMuted),
                              ),
                              const SizedBox(height: 2),
                              Text(_headline(pots, status), style: text.headlineSmall),
                            ],
                          ),
                        ),
                        CircleIconButton(
                          icon: Icons.notifications_none_rounded,
                          tooltip: t('Bildirimler'),
                          showDot: unread > 0,
                          onPressed: onOpenNotifications,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    PillSegmented<String>(
                      items: [for (final item in pots.pots) (item.id, t(item.name))],
                      value: pot.id,
                      onChanged: pots.selectPot,
                    ),
                    if (pots.connection == DeviceConnection.offline) ...[
                      const SizedBox(height: 12),
                      _OfflineBanner(error: pots.connectionError?.resolve()),
                    ],
                    const SizedBox(height: 12),
                    MoistureRing(
                      size: 212,
                      value: live?.moisture,
                      child: PlantIllustration(kind: plantKindFor(plant), size: 128),
                    ),
                    const SizedBox(height: 12),
                    Text(plant == null ? t('Bitki seçilmedi') : t(plant.name), style: text.headlineSmall?.copyWith(fontSize: 23)),
                    const SizedBox(height: 0),
                    Text(
                      '${plant == null ? t('Boş saksı') : t(plant.category.typeLabel)} · ${t(pot.name)}',
                      style: text.bodyLarge?.copyWith(color: p.textMuted),
                    ),
                    const SizedBox(height: 10),
                    StatusPill(label: t(status.homeLabel), tone: status.tone),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: MetricCard(
                            icon: Icons.water_drop_outlined,
                            label: t('Toprak nemi'),
                            value: live == null ? '—' : formatPercent(live.moisture),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: MetricCard(
                            icon: Icons.thermostat_rounded,
                            label: t('Sıcaklık'),
                            value: live == null ? '—' : formatTemperature(live.temperature),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: MetricCard(
                            icon: Icons.propane_tank_outlined,
                            label: t('Su deposu'),
                            value: tank.level == null ? '—' : formatPercent(tank.level!),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: MetricCard(
                            icon: Icons.schedule_rounded,
                            label: t('Sonraki sulama'),
                            value: next == null ? t('Kapalı') : formatNextShort(next),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => ScheduleScreen(potId: pot.id)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: pots.isOnline ? () => showWaterNowSheet(context, potId: pot.id) : null,
                        icon: const Icon(Icons.water_drop_outlined),
                        label: Text(t('Şimdi Sula')),
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

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: p.warnBg, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: p.warnFg),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              error ?? context.t('Cihazdan veri gelmiyor. Programlı sulama cihazda sürer.'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: p.warnFg),
            ),
          ),
        ],
      ),
    );
  }
}
