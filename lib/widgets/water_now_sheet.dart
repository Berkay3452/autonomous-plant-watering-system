import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pot_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// "Şimdi sula" alt sayfasını açar. Sulama başlatılırsa sonucu SnackBar ile
/// gösterir.
Future<void> showWaterNowSheet(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final message = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _WaterNowSheet(),
  );
  if (message != null) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _WaterNowSheet extends StatefulWidget {
  const _WaterNowSheet();

  @override
  State<_WaterNowSheet> createState() => _WaterNowSheetState();
}

class _WaterNowSheetState extends State<_WaterNowSheet> {
  int _amount = 50;
  bool _sending = false;

  static const _presets = [25, 50, 75, 100];

  Future<void> _start(PotProvider pot) async {
    setState(() => _sending = true);
    final result = await pot.waterNow(_amount);
    if (!mounted) return;
    Navigator.of(context).pop(
      result.accepted
          ? 'Sulama başladı: ≈ ${result.ml.round()} ml, ${formatSeconds(result.durationSeconds)}.'
          : 'Sulama başlatılamadı. ${result.message}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final pot = context.watch<PotProvider>();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final estimate = pot.estimateDose(_amount);
    final snapshot = pot.snapshot;

    String? problem;
    if (!pot.isOnline) {
      problem = 'Cihaz çevrimdışı. Komut gönderilemez.';
    } else if (snapshot?.pumpLocked ?? false) {
      problem = 'Depo kritik seviyede, pompa kilitli. Önce depoyu doldurun.';
    } else if (snapshot?.pumpRunning ?? false) {
      problem = 'Pompa şu anda çalışıyor.';
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Şimdi sula', style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            '${pot.pot.name}${pot.plant != null ? ' · ${pot.plant!.name}' : ''}',
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Text('Su miktarı', style: text.titleMedium),
              const Spacer(),
              Text(
                formatPercent(_amount),
                style: text.headlineSmall?.copyWith(
                  color: AppColors.water,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Slider(
            value: _amount.toDouble(),
            min: 5,
            max: 100,
            divisions: 19,
            label: formatPercent(_amount),
            onChanged: _sending ? null : (v) => setState(() => _amount = v.round()),
          ),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final p in _presets)
                ChoiceChip(
                  label: Text(formatPercent(p)),
                  selected: _amount == p,
                  onSelected: _sending ? null : (_) => setState(() => _amount = p),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.water.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.water_drop, color: AppColors.water),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    '≈ ${estimate.ml.round()} ml su · pompa ${formatSeconds(estimate.seconds)} çalışır'
                    '${estimate.capped ? '\nAzami pompa süresi nedeniyle doz sınırlandı.' : ''}',
                    style: text.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              '%100 = tam doz (${pot.pot.fullDoseMl} ml). Ayarlar ekranından değiştirilebilir.',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          if (problem != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(problem, style: text.bodyMedium?.copyWith(color: AppColors.danger)),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _sending || problem != null ? null : () => _start(pot),
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.water_drop),
              label: Text(_sending ? 'Gönderiliyor…' : 'Sulamayı başlat'),
            ),
          ),
        ],
      ),
    );
  }
}
