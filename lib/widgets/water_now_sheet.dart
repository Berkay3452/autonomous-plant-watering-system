import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../providers/pots_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// "Şimdi sula" alt sayfasını açar. Sulama başlatılırsa sonucu SnackBar ile
/// gösterir. [potId] verilmezse seçili saksı sulanır.
Future<void> showWaterNowSheet(BuildContext context, {String? potId}) async {
  final messenger = ScaffoldMessenger.of(context);
  final id = potId ?? context.read<PotsProvider>().selectedId;
  final message = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _WaterNowSheet(potId: id),
  );
  if (message != null) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _WaterNowSheet extends StatefulWidget {
  const _WaterNowSheet({required this.potId});

  final String potId;

  @override
  State<_WaterNowSheet> createState() => _WaterNowSheetState();
}

class _WaterNowSheetState extends State<_WaterNowSheet> {
  int _amount = 50;
  bool _sending = false;

  static const _presets = [25, 50, 75, 100];

  Future<void> _start(PotsProvider pots) async {
    setState(() => _sending = true);
    final result = await pots.waterNow(widget.potId, _amount);
    if (!mounted) return;
    Navigator.of(context).pop(
      result.accepted
          ? Strings.t('Sulama başladı: ≈ {0} ml, {1}.', [result.ml.round(), formatSeconds(result.durationSeconds)])
          : Strings.t('Sulama başlatılamadı. {0}', [result.message!.resolve()]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pots = context.watch<PotsProvider>();
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final t = context.t;
    final pot = pots.potById(widget.potId);
    final plant = pots.plantOf(widget.potId);
    final live = pots.liveOf(widget.potId);
    final estimate = pots.estimateDose(widget.potId, _amount);

    String? problem;
    if (!pots.isOnline) {
      problem = t('Cihaz çevrimdışı. Komut gönderilemez.');
    } else if (pots.snapshot?.pumpLocked ?? false) {
      problem = t('Depo kritik seviyede, pompa kilitli. Önce depoyu doldur.');
    } else if (live?.pumpRunning ?? false) {
      problem = t('Pompa şu anda çalışıyor.');
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
          Text(t('Şimdi sula'), style: text.headlineSmall),
          const SizedBox(height: 4),
          Text(
            '${t(pot?.name ?? '')}${plant != null ? ' · ${t(plant.name)}' : ''}',
            style: text.bodyLarge?.copyWith(color: p.textMuted),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Text(t('Su miktarı'), style: text.titleMedium),
              const Spacer(),
              Text(
                formatPercent(_amount),
                style: text.headlineSmall?.copyWith(color: p.primary, fontWeight: FontWeight.w700),
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
              for (final preset in _presets)
                ChoiceChip(
                  label: Text(formatPercent(preset)),
                  selected: _amount == preset,
                  showCheckmark: false,
                  labelStyle: text.labelMedium?.copyWith(
                    color: _amount == preset ? p.onPrimary : p.text,
                  ),
                  onSelected: _sending ? null : (_) => setState(() => _amount = preset),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: p.isDark ? p.tile : p.blob,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Icon(Icons.water_drop, color: p.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    t('≈ {0} ml su · pompa {1} çalışır', [estimate.ml.round(), formatSeconds(estimate.seconds)]) +
                        (estimate.capped ? '\n${t('Azami pompa süresi nedeniyle doz sınırlandı.')}' : ''),
                    style: text.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              t('%100 = tam doz ({0} ml). Ayarlar ekranından değiştirilebilir.', [pot?.fullDoseMl ?? 200]),
              style: text.bodySmall,
            ),
          ),
          if (problem != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(Icons.error_outline, color: p.warnText, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(problem, style: text.bodyMedium?.copyWith(color: p.warnText)),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _sending || problem != null ? null : () => _start(pots),
              icon: _sending
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: p.onPrimary),
                    )
                  : const Icon(Icons.water_drop_outlined),
              label: Text(_sending ? t('Gönderiliyor…') : t('Sulamayı başlat')),
            ),
          ),
        ],
      ),
    );
  }
}
