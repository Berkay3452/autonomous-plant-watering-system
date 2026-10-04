import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/schedule.dart';
import '../providers/pots_provider.dart';
import '../providers/schedule_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_background.dart';
import '../widgets/app_card.dart';
import '../widgets/circle_icon_button.dart';
import '../widgets/pill_segmented.dart';

/// Sulama programı: saksının sulama saati, günleri ve su miktarı.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key, required this.potId});

  final String potId;

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late String _potId;
  late bool _active;
  late int _hour;
  late int _minute;
  late Set<int> _weekdays;
  late int _amount;

  @override
  void initState() {
    super.initState();
    _potId = widget.potId;
    _load();
  }

  /// Seçili saksının kayıtlı programını ekrana yükler.
  void _load() {
    final saved = context.read<ScheduleProvider>().forPot(_potId) ??
        WateringSchedule.initial(_potId, DateTime.now());
    _active = saved.active;
    _hour = saved.hour;
    _minute = saved.minute;
    _weekdays = {...saved.weekdays};
    _amount = saved.amountPercent;
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _hour, minute: _minute),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time == null) return;
    setState(() {
      _hour = time.hour;
      _minute = time.minute;
    });
  }

  void _toggleDay(int weekday) {
    setState(() {
      if (_weekdays.contains(weekday)) {
        _weekdays.remove(weekday);
      } else {
        _weekdays.add(weekday);
      }
    });
  }

  WateringSchedule _draft() => WateringSchedule(
        id: _potId,
        potId: _potId,
        hour: _hour,
        minute: _minute,
        weekdays: _weekdays,
        amountPercent: _amount,
        createdAt: DateTime.now(),
        active: _active,
      );

  void _save() {
    if (_weekdays.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(context.t('En az bir gün seç.'))));
      return;
    }
    context.read<ScheduleProvider>().save(_draft());
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(Strings.t('Sulama programı kaydedildi.'))));
  }

  @override
  Widget build(BuildContext context) {
    final pots = context.watch<PotsProvider>();
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final t = context.t;

    final plant = pots.plantOf(_potId);
    final estimate = pots.estimateDose(_potId, _amount);
    final next = _draft().nextOccurrence(DateTime.now());

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.page, 14, AppSpacing.page, 28),
            children: [
              Row(
                children: [
                  CircleIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    tooltip: t('Geri'),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(child: Center(child: Text(t('Sulama programı'), style: text.headlineMedium))),
                  const SizedBox(width: 44),
                ],
              ),
              const SizedBox(height: 16),
              PillSegmented<String>(
                items: [for (final pot in pots.pots) (pot.id, t(pot.name))],
                value: _potId,
                onChanged: (id) => setState(() {
                  _potId = id;
                  _load();
                }),
              ),
              const SizedBox(height: 12),
              AppCard(
                padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t('Otomatik sulama'), style: text.titleLarge),
                          const SizedBox(height: 2),
                          Text(
                            _active
                                ? t('{0} program saatinde sulanır', [t(plant?.name ?? 'Bitki')])
                                : t('Program kapalı, otomatik sulama yapılmaz'),
                            style: text.bodyMedium?.copyWith(color: p.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Switch(value: _active, onChanged: (v) => setState(() => _active = v)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, color: p.primary),
                        const SizedBox(width: 10),
                        Text(t('Sulama saati'), style: text.titleLarge),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Material(
                      color: p.isDark ? p.tile : p.blob,
                      borderRadius: BorderRadius.circular(26),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(26),
                        onTap: _pickTime,
                        child: Container(
                          height: 78,
                          alignment: Alignment.center,
                          child: Text(
                            formatHm(_hour, _minute),
                            style: text.headlineLarge?.copyWith(fontSize: 46, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (var day = DateTime.monday; day <= DateTime.sunday; day++)
                          _DayChip(
                            label: weekdayShort(day),
                            selected: _weekdays.contains(day),
                            onTap: () => _toggleDay(day),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      !_active
                          ? t('Program kapalı.')
                          : next == null
                              ? t('Sulama günü seçilmedi.')
                              : t('Sıradaki sulama: {0} ({1})', [formatUpcoming(next), formatCountdown(next)]),
                      style: text.bodyMedium?.copyWith(color: p.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.water_drop_outlined, color: p.primary),
                        const SizedBox(width: 10),
                        Text(t('Su miktarı'), style: text.titleLarge),
                        const Spacer(),
                        Text(
                          formatPercent(_amount),
                          style: text.headlineLarge?.copyWith(
                            color: p.primary,
                            fontSize: 38,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Slider(
                      value: _amount.toDouble(),
                      min: 5,
                      max: 100,
                      divisions: 19,
                      onChanged: (v) => setState(() => _amount = v.round()),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (final label in [formatPercent(5), formatPercent(50), formatPercent(100)])
                            Text(label, style: text.bodyMedium?.copyWith(color: p.textMuted, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      t('≈ {0} ml · pompa {1}', [estimate.ml.round(), formatSeconds(estimate.seconds)]) +
                          (estimate.capped ? t(' (azami süreyle sınırlı)') : ''),
                      style: text.bodyMedium?.copyWith(color: p.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 56,
                child: FilledButton(onPressed: _save, child: Text(t('Kaydet'))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? p.primary : (p.isDark ? p.control : p.tile),
          shape: BoxShape.circle,
        ),
        child: Text(
          label,
          style: text.labelMedium?.copyWith(
            fontSize: 11.5,
            color: selected ? p.onPrimary : p.text,
          ),
        ),
      ),
    );
  }
}
