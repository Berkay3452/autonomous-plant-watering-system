import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/schedule.dart';
import '../providers/pot_provider.dart';
import '../providers/schedule_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Sulama planı ekleme / düzenleme.
///
/// Hızlı kullanım: varsayılan zaman 2 dk sonrası ve %50. Hazır seçeneklerden
/// birine dokunup "Kaydet" demek yeterli (hedef: en fazla 4 dokunuş).
class ScheduleEditScreen extends StatefulWidget {
  const ScheduleEditScreen({super.key, required this.potId, this.schedule});

  final String potId;
  final WateringSchedule? schedule;

  @override
  State<ScheduleEditScreen> createState() => _ScheduleEditScreenState();
}

class _ScheduleEditScreenState extends State<ScheduleEditScreen> {
  late DateTime _time;
  late ScheduleRepeat _repeat;
  late int _amount;
  late bool _active;

  bool get _isNew => widget.schedule == null;

  @override
  void initState() {
    super.initState();
    final s = widget.schedule;
    _time = s?.time ?? _roundToMinute(DateTime.now().add(const Duration(minutes: 2)));
    _repeat = s?.repeat ?? ScheduleRepeat.once;
    _amount = s?.amountPercent ?? 50;
    _active = s?.active ?? true;
  }

  static DateTime _roundToMinute(DateTime t) => DateTime(t.year, t.month, t.day, t.hour, t.minute);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _time.isBefore(now) ? now : _time,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;
    setState(() => _time = DateTime(date.year, date.month, date.day, _time.hour, _time.minute));
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_time),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time == null) return;
    setState(() => _time = DateTime(_time.year, _time.month, _time.day, time.hour, time.minute));
  }

  void _applyPreset(DateTime time, ScheduleRepeat repeat) {
    setState(() {
      _time = _roundToMinute(time);
      _repeat = repeat;
    });
  }

  void _save() {
    final provider = context.read<ScheduleProvider>();
    final now = DateTime.now();
    if (_repeat == ScheduleRepeat.once && !_time.isAfter(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tek seferlik plan için ileri bir zaman seçin.')),
      );
      return;
    }

    final existing = widget.schedule;
    if (existing == null) {
      provider.add(WateringSchedule(
        id: provider.newId(),
        potId: widget.potId,
        time: _time,
        repeat: _repeat,
        amountPercent: _amount,
        active: _active,
        createdAt: now,
      ));
    } else {
      // Zaman değiştiyse eski "son çalışma" bilgisi yeni zamanı engellemesin.
      provider.update(WateringSchedule(
        id: existing.id,
        potId: existing.potId,
        time: _time,
        repeat: _repeat,
        amountPercent: _amount,
        active: _active,
        createdAt: now,
      ));
    }
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Plan silinsin mi?'),
        content: const Text('Bu sulama planı cihazdan da kaldırılacak.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    context.read<ScheduleProvider>().remove(widget.schedule!.id);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final pot = context.watch<PotProvider>();
    final estimate = pot.estimateDose(_amount);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final tomorrow8 = DateTime(now.year, now.month, now.day + 1, 8);

    final String repeatHint = switch (_repeat) {
      ScheduleRepeat.once => 'Yalnızca ${formatDateTime(_time)} tarihinde bir kez sular.',
      ScheduleRepeat.daily => 'Her gün saat ${formatTime(_time)} sular.',
      ScheduleRepeat.weekly => 'Her ${formatWeekday(_time)} saat ${formatTime(_time)} sular.',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Yeni sulama planı' : 'Planı düzenle'),
        actions: [
          if (!_isNew)
            IconButton(
              tooltip: 'Sil',
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: const Text('Kaydet'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.yard_outlined),
              title: Text(pot.pot.name),
              subtitle: Text(pot.plant?.name ?? 'Bitki seçilmedi'),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Hızlı seçim', style: text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ActionChip(
                avatar: const Icon(Icons.timer_outlined, size: 18),
                label: const Text('2 dk sonra'),
                onPressed: () => _applyPreset(now.add(const Duration(minutes: 2)), ScheduleRepeat.once),
              ),
              ActionChip(
                avatar: const Icon(Icons.timer_outlined, size: 18),
                label: const Text('1 saat sonra'),
                onPressed: () => _applyPreset(now.add(const Duration(hours: 1)), ScheduleRepeat.once),
              ),
              ActionChip(
                avatar: const Icon(Icons.wb_twilight, size: 18),
                label: const Text('Yarın 08:00'),
                onPressed: () => _applyPreset(tomorrow8, ScheduleRepeat.once),
              ),
              ActionChip(
                avatar: const Icon(Icons.repeat, size: 18),
                label: const Text('Her gün 08:00'),
                onPressed: () => _applyPreset(tomorrow8, ScheduleRepeat.daily),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Zaman', style: text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('Tarih'),
                  subtitle: Text(formatDate(_time)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickDate,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('Saat'),
                  subtitle: Text(formatTime(_time)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _pickTime,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Tekrar', style: text.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<ScheduleRepeat>(
            segments: [
              for (final r in ScheduleRepeat.values) ButtonSegment(value: r, label: Text(r.label)),
            ],
            selected: {_repeat},
            onSelectionChanged: (v) => setState(() => _repeat = v.first),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(repeatHint, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Text('Su miktarı', style: text.titleSmall),
              const Spacer(),
              Text(
                formatPercent(_amount),
                style: text.titleLarge?.copyWith(color: AppColors.water, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          Slider(
            value: _amount.toDouble(),
            min: 5,
            max: 100,
            divisions: 19,
            label: formatPercent(_amount),
            onChanged: (v) => setState(() => _amount = v.round()),
          ),
          Text(
            '≈ ${estimate.ml.round()} ml · pompa ${formatSeconds(estimate.seconds)}'
            '${estimate.capped ? ' (azami süreyle sınırlı)' : ''}',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Plan etkin'),
            subtitle: const Text('Kapalı planlar cihazda çalışmaz.'),
            value: _active,
            onChanged: (v) => setState(() => _active = v),
          ),
        ],
      ),
    );
  }
}
