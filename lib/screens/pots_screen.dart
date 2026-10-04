import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/pot.dart';
import '../providers/pots_provider.dart';
import '../providers/schedule_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_background.dart';
import '../widgets/app_card.dart';
import '../widgets/plant_illustration.dart';
import '../widgets/status_pill.dart';
import 'plant_type_screen.dart';
import 'schedule_screen.dart';

/// Saksılarım: tüm saksıların özeti ve ortak su deposu.
class PotsScreen extends StatelessWidget {
  const PotsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pots = context.watch<PotsProvider>();
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final t = context.t;
    final tank = pots.tank;

    return AppBackground(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, 22, AppSpacing.page, 120),
          children: [
            Text(t('Saksılarım'), style: text.headlineMedium),
            const SizedBox(height: 2),
            Text(
              pots.isOnline ? t('{0} saksı bağlı', [pots.pots.length]) : t('Cihaz çevrimdışı'),
              style: text.bodyLarge?.copyWith(color: p.textMuted),
            ),
            const SizedBox(height: 18),
            for (final pot in pots.pots) ...[
              _PotTile(pot: pot),
              const SizedBox(height: 14),
            ],
            AppCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(color: p.okBg, shape: BoxShape.circle),
                        child: Icon(Icons.propane_tank_outlined, color: p.okFg, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Text(t('Su deposu'), style: text.titleLarge)),
                      Text(
                        tank.level == null ? '—' : formatPercent(tank.level!),
                        style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: ((tank.level ?? 0) / 100).clamp(0.0, 1.0),
                      minHeight: 14,
                      backgroundColor: p.track,
                      color: tank.isLow ? p.warnText : p.primary,
                    ),
                  ),
                  if (tank.isLow) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: p.warnText),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            tank.isCritical
                                ? t('Depo kritik seviyede, pompalar kilitli.')
                                : t('Depo azalıyor, yakında doldurman gerekebilir.'),
                            style: text.bodyMedium?.copyWith(color: p.warnText),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PotTile extends StatelessWidget {
  const _PotTile({required this.pot});

  final Pot pot;

  @override
  Widget build(BuildContext context) {
    final pots = context.watch<PotsProvider>();
    final schedules = context.watch<ScheduleProvider>();
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final t = context.t;

    final plant = pots.plantOf(pot.id);
    final live = pots.liveOf(pot.id);
    final status = pots.statusOf(pot.id);
    final next = schedules.nextFor(pot.id);

    final nextText = status.needsWater
        ? t('Şimdi')
        : (next == null ? t('Kapalı') : formatNextShort(next));

    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PlantTypeScreen(potId: pot.id)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(color: p.okBg, borderRadius: BorderRadius.circular(26)),
                child: Center(child: PlantIllustration(kind: plantKindFor(plant), size: 78)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant == null ? t('Bitki seçilmedi') : t(plant.name),
                      style: text.titleLarge?.copyWith(fontSize: 22),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${t(pot.name)} · ${plant == null ? t('Boş') : t(plant.category.label)}',
                      style: text.bodyLarge?.copyWith(color: p.textMuted),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: StatusPill(label: t(status.label), tone: status.tone),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: t('Nem'),
                  value: live == null ? '—' : formatPercent(live.moisture),
                  warn: status.needsWater,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  label: t('Sıcaklık'),
                  value: live == null ? '—' : formatTemperature(live.temperature),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  label: t('Sıradaki'),
                  value: nextText,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ScheduleScreen(potId: pot.id)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, this.warn = false, this.onTap});

  final String label;
  final String value;
  final bool warn;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final bg = warn ? p.warnTile : (p.isDark ? p.tile : p.tile);
    final fg = warn ? p.warnFg : p.text;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  maxLines: 1,
                  style: text.bodyMedium?.copyWith(
                    color: warn ? p.warnFg : p.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: text.titleLarge?.copyWith(color: fg, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
