import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/reading.dart';
import '../models/schedule.dart';
import '../models/watering_event.dart';
import '../providers/pot_provider.dart';
import '../providers/schedule_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/connection_badge.dart';
import '../widgets/moisture_chart.dart';
import '../widgets/parameter_tile.dart';
import '../widgets/range_bar.dart';
import '../widgets/section_header.dart';
import '../widgets/status_chip.dart';
import '../widgets/water_now_sheet.dart';
import 'plants_screen.dart';
import 'schedule_edit_screen.dart';

/// Saksı detayı: tüm parametrelerin canlı takibi, geçmiş grafiği, sulama
/// planları ve son sulamalar.
class PotDetailScreen extends StatefulWidget {
  const PotDetailScreen({super.key});

  @override
  State<PotDetailScreen> createState() => _PotDetailScreenState();
}

class _PotDetailScreenState extends State<PotDetailScreen> {
  ChartRange _range = ChartRange.day;
  ChartMetric _metric = ChartMetric.moisture;

  Future<void> _rename(PotProvider pot) async {
    final controller = TextEditingController(text: pot.pot.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saksı adı'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Örn. Balkon domatesi'),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Kaydet')),
        ],
      ),
    );
    controller.dispose();
    if (name != null) pot.rename(name);
  }

  void _choosePlant() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PlantsScreen(pickMode: true)),
    );
  }

  void _editSchedule(String potId, [WateringSchedule? schedule]) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ScheduleEditScreen(potId: potId, schedule: schedule),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final pot = context.watch<PotProvider>();
    final schedules = context.watch<ScheduleProvider>().forPot(pot.pot.id);
    final s = pot.snapshot;
    final plant = pot.plant;
    final tank = pot.tank;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final readings = pot.readings(_range);

    String? moistureWarning;
    if (s != null && plant != null) {
      if (s.moisture < plant.minMoisture) {
        moistureWarning = 'Minimum eşiğin (${formatPercent(plant.minMoisture)}) altında. Sulama gerekli.';
      } else if (s.moisture < plant.idealMoistureMin) {
        moistureWarning = 'İdeal aralığın biraz altında.';
      } else if (s.moisture > plant.idealMoistureMax) {
        moistureWarning = 'İdeal aralığın üstünde. Bir süre sulama yapılmamalı.';
      }
    }

    String? temperatureWarning;
    if (s != null && plant != null) {
      if (s.temperature < plant.tempMin) {
        temperatureWarning = '${plant.name} için soğuk (en az ${plant.tempMin.round()} °C).';
      } else if (s.temperature > plant.tempMax) {
        temperatureWarning = '${plant.name} için sıcak (en fazla ${plant.tempMax.round()} °C).';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(pot.pot.name),
        actions: [
          IconButton(
            tooltip: 'Adı değiştir',
            onPressed: () => _rename(pot),
            icon: const Icon(Icons.edit_outlined),
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.page),
            child: ConnectionBadge(connection: pot.connection),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: pot.isOnline ? () => showWaterNowSheet(context) : null,
        backgroundColor: pot.isOnline ? null : scheme.surfaceContainerHighest,
        icon: const Icon(Icons.water_drop),
        label: const Text('Şimdi sula'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, 96),
        children: [
          // Bitki başlığı
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              leading: CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                child: Icon(plant?.category.icon ?? Icons.yard_outlined, color: scheme.onPrimaryContainer),
              ),
              title: Text(
                plant?.name ?? 'Bitki seçilmedi',
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Align(alignment: Alignment.centerLeft, child: StatusChip(status: pot.status)),
              ),
              trailing: TextButton(
                onPressed: _choosePlant,
                child: Text(plant == null ? 'Seç' : 'Değiştir'),
              ),
            ),
          ),

          const SectionHeader(title: 'Canlı değerler'),
          ParameterTile(
            icon: Icons.grass,
            label: 'Toprak nemi',
            value: s == null ? '—' : formatPercent(s.moisture),
            color: AppColors.moisture,
            subtitle: plant == null
                ? 'Hedef aralık için saksıya bitki atayın.'
                : 'İdeal ${formatPercent(plant.idealMoistureMin)}–${plant.idealMoistureMax} · '
                    'min ${formatPercent(plant.minMoisture)}',
            footer: RangeBar(
              value: s?.moisture,
              min: 0,
              max: 100,
              idealMin: plant?.idealMoistureMin.toDouble(),
              idealMax: plant?.idealMoistureMax.toDouble(),
              threshold: plant?.minMoisture.toDouble(),
              color: AppColors.moisture,
            ),
            warning: moistureWarning,
          ),
          const SizedBox(height: AppSpacing.md),
          ParameterTile(
            icon: Icons.thermostat,
            label: 'Ortam sıcaklığı',
            value: s == null ? '—' : formatTemperature(s.temperature),
            color: AppColors.temperature,
            subtitle: plant == null
                ? null
                : 'Uygun aralık ${plant.tempMin.round()}–${plant.tempMax.round()} °C',
            footer: RangeBar(
              value: s?.temperature,
              min: 0,
              max: 45,
              idealMin: plant?.tempMin,
              idealMax: plant?.tempMax,
              color: AppColors.temperature,
            ),
            warning: temperatureWarning,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: ParameterTile(
                  icon: Icons.cloud_outlined,
                  label: 'Hava nemi',
                  value: s == null ? '—' : formatPercent(s.humidity),
                  color: AppColors.humidity,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ParameterTile(
                  icon: Icons.waves,
                  label: 'Depo',
                  value: tank.level == null ? '—' : formatPercent(tank.level!),
                  color: tank.isLow ? AppColors.warning : AppColors.water,
                  subtitle: tank.isCritical
                      ? 'Pompa kilitli'
                      : tank.isLow
                          ? 'Eşiğin altında'
                          : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: ParameterTile(
                  icon: Icons.history,
                  label: 'Son sulama',
                  value: s?.lastWatered == null ? '—' : formatTime(s!.lastWatered!),
                  color: scheme.primary,
                  subtitle: s?.lastWatered == null ? 'Kayıt yok' : formatRelative(s!.lastWatered!),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ParameterTile(
                  icon: Icons.settings_input_component_outlined,
                  label: 'Pompa',
                  value: s == null
                      ? '—'
                      : s.pumpRunning
                          ? 'Açık'
                          : 'Kapalı',
                  color: (s?.pumpRunning ?? false) ? AppColors.water : scheme.outline,
                  subtitle: (s?.pumpLocked ?? false) ? 'Kuru çalışma kilidi' : 'Hazır',
                ),
              ),
            ],
          ),

          const SectionHeader(title: 'Geçmiş'),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
              child: Column(
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      SegmentedButton<ChartMetric>(
                        showSelectedIcon: false,
                        segments: [
                          for (final m in ChartMetric.values)
                            ButtonSegment(value: m, label: Text(m == ChartMetric.moisture ? 'Nem' : 'Sıcaklık')),
                        ],
                        selected: {_metric},
                        onSelectionChanged: (v) => setState(() => _metric = v.first),
                      ),
                      SegmentedButton<ChartRange>(
                        showSelectedIcon: false,
                        segments: [
                          for (final r in ChartRange.values) ButtonSegment(value: r, label: Text(r.label)),
                        ],
                        selected: {_range},
                        onSelectionChanged: (v) => setState(() => _range = v.first),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  MoistureChart(readings: readings, range: _range, metric: _metric, plant: plant),
                  const SizedBox(height: AppSpacing.md),
                  _ChartStats(readings: readings, metric: _metric),
                ],
              ),
            ),
          ),

          SectionHeader(
            title: 'Sulama planları',
            trailing: TextButton.icon(
              onPressed: () => _editSchedule(pot.pot.id),
              icon: const Icon(Icons.add),
              label: const Text('Ekle'),
            ),
          ),
          if (schedules.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Henüz plan yok. Belirli bir saatte otomatik sulama için plan ekleyin.',
                  style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (final schedule in schedules)
                    _ScheduleTile(
                      schedule: schedule,
                      onTap: () => _editSchedule(pot.pot.id, schedule),
                    ),
                ],
              ),
            ),

          const SectionHeader(title: 'Son sulamalar'),
          if (pot.recentEvents.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Bu oturumda henüz sulama yapılmadı.',
                  style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (final event in pot.recentEvents.take(10)) _EventTile(event: event),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ChartStats extends StatelessWidget {
  const _ChartStats({required this.readings, required this.metric});

  final List<Reading> readings;
  final ChartMetric metric;

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) return const SizedBox.shrink();
    final values = readings
        .map((r) => metric == ChartMetric.moisture ? r.moisture : r.temperature)
        .toList();
    final low = values.reduce(min);
    final high = values.reduce(max);
    final avg = values.reduce((a, b) => a + b) / values.length;
    String f(double v) => metric == ChartMetric.moisture ? formatPercent(v) : formatTemperature(v);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _Stat(label: 'En düşük', value: f(low)),
        _Stat(label: 'Ortalama', value: f(avg)),
        _Stat(label: 'En yüksek', value: f(high)),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(value, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        Text(label, style: text.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({required this.schedule, required this.onTap});

  final WateringSchedule schedule;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ScheduleProvider>();
    final next = schedule.nextOccurrence(DateTime.now());
    final scheme = Theme.of(context).colorScheme;

    final String subtitle;
    if (!schedule.active) {
      subtitle = schedule.repeat == ScheduleRepeat.once && schedule.lastRun != null
          ? 'Tamamlandı · ${formatRelative(schedule.lastRun!)}'
          : 'Kapalı';
    } else if (next == null) {
      subtitle = 'Zamanı geçti';
    } else {
      subtitle = 'Sıradaki: ${formatUpcoming(next)} (${formatCountdown(next)})';
    }

    final String title = switch (schedule.repeat) {
      ScheduleRepeat.once => formatDateTime(schedule.time),
      ScheduleRepeat.daily => 'Her gün ${formatTime(schedule.time)}',
      ScheduleRepeat.weekly => 'Her ${formatWeekday(schedule.time)} ${formatTime(schedule.time)}',
    };

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: schedule.active ? AppColors.water.withValues(alpha: 0.15) : scheme.surfaceContainerHighest,
        child: Text(
          formatPercent(schedule.amountPercent),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: schedule.active ? AppColors.water : scheme.outline,
          ),
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: schedule.active,
        onChanged: (v) => provider.setActive(schedule.id, v),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final WateringEvent event;

  @override
  Widget build(BuildContext context) {
    final color = event.success ? AppColors.water : AppColors.danger;
    return ListTile(
      leading: Icon(event.success ? Icons.water_drop : Icons.block, color: color),
      title: Text(
        event.success
            ? '${event.source.label} · ${event.ml.round()} ml (${formatPercent(event.amountPercent)})'
            : '${event.source.label} · yapılamadı',
      ),
      subtitle: Text(
        [formatRelative(event.time), if (event.message != null) event.message!].join(' · '),
      ),
    );
  }
}
