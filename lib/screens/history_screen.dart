import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../providers/pots_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/history_math.dart';
import '../widgets/app_background.dart';
import '../widgets/app_card.dart';
import '../widgets/history_charts.dart';
import '../widgets/pill_segmented.dart';

/// Geçmiş: seçili saksının nem ve sıcaklık grafikleri (gün / hafta / ay).
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  ChartRange _range = ChartRange.day;

  @override
  Widget build(BuildContext context) {
    final pots = context.watch<PotsProvider>();
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final t = context.t;

    final pot = pots.selected;
    final live = pots.liveOf(pot.id);
    final now = DateTime.now();
    final window = chartWindow(_range, now);
    final points = downsampleReadings(
      pots.readingsSince(pot.id, window.start),
      _range.bucket,
    );
    final month = pots.readingsSince(pot.id, now.subtract(const Duration(days: 30)));
    final buckets = temperatureBuckets(_range, month, now, live?.temperature);
    final events = pots.wateringLog(pot.id);

    return AppBackground(
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.page, 22, AppSpacing.page, 120),
          children: [
            Row(
              children: [
                Expanded(child: Text(t('Geçmiş'), style: text.headlineMedium)),
                PopupMenuButton<String>(
                  tooltip: t('Saksı seç'),
                  onSelected: pots.selectPot,
                  position: PopupMenuPosition.under,
                  itemBuilder: (_) => [
                    for (final item in pots.pots)
                      PopupMenuItem(value: item.id, child: Text(t(item.name), style: text.titleSmall)),
                  ],
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(18, 10, 12, 10),
                    decoration: BoxDecoration(
                      color: p.isDark ? p.control : p.card,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: p.isDark ? Colors.transparent : p.control, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(t(pot.name), style: text.titleSmall),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down_rounded, color: p.text),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            PillSegmented<ChartRange>(
              items: [for (final r in ChartRange.values) (r, t(r.label))],
              value: _range,
              onChanged: (r) => setState(() => _range = r),
            ),
            const SizedBox(height: 14),
            AppCard(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t('Toprak nemi'),
                              style: text.bodyLarge?.copyWith(color: p.textMuted, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              live == null ? '—' : formatPercent(live.moisture),
                              style: text.headlineLarge?.copyWith(fontSize: 38, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: p.accent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: p.isDark ? Colors.white : p.chartLine,
                                  width: 2.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(t('Sulama'), style: text.bodyLarge?.copyWith(color: p.textMuted, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  MoistureLineChart(points: points, window: window, events: events),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppCard(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('Sıcaklık'),
                    style: text.bodyLarge?.copyWith(color: p.textMuted, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    live == null ? '—' : formatTemperature(live.temperature),
                    style: text.headlineLarge?.copyWith(fontSize: 38, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  TemperatureBars(buckets: buckets),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
