import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/plant.dart';
import '../providers/plants_provider.dart';
import '../providers/pots_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_background.dart';
import '../widgets/app_card.dart';
import '../widgets/circle_icon_button.dart';
import '../widgets/plant_detail_sheet.dart';
import '../widgets/plant_illustration.dart';
import 'plant_form_screen.dart';

/// Seçilen kategorideki bitkiler. Bitkiye dokunulunca ayrıntılar açılır;
/// oradan saksıya atanır.
class PlantListScreen extends StatelessWidget {
  const PlantListScreen({super.key, required this.potId, required this.category});

  final String potId;
  final PlantCategory category;

  Future<void> _open(BuildContext context, Plant plant) async {
    final pots = context.read<PotsProvider>();
    final plants = context.read<PlantsProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final pot = pots.potById(potId);

    final action = await showPlantDetailSheet(
      context,
      plant: plant,
      isAssigned: pot?.plantId == plant.id,
      potName: context.t(pot?.name ?? 'Saksı'),
    );
    if (action == null || !context.mounted) return;

    switch (action) {
      case 'assign':
        pots.assignPlant(potId, plant.id);
        navigator.popUntil((route) => route.isFirst);
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(Strings.t('{0} için {1} seçildi.', [Strings.t(pot?.name ?? 'Saksı'), Strings.t(plant.name)])),
          ));
      case 'edit':
        await navigator.push(MaterialPageRoute(builder: (_) => PlantFormScreen(plant: plant)));
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.t('{0} silinsin mi?', [plant.name])),
            content: Text(context.t('Bu bitki bir saksıya atanmışsa saksı boşaltılır.')),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.t('Vazgeç'))),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
                onPressed: () => Navigator.pop(context, true),
                child: Text(context.t('Sil')),
              ),
            ],
          ),
        );
        if (confirmed == true) plants.deleteCustom(plant.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plants = context.watch<PlantsProvider>().inCategory(category);
    final assignedId = context.select<PotsProvider, String?>((p) => p.potById(potId)?.plantId);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final t = context.t;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.page, 14, AppSpacing.page, 0),
                child: Row(
                  children: [
                    CircleIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      tooltip: t('Geri'),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    Expanded(child: Center(child: Text(t(category.label), style: text.headlineMedium))),
                    const SizedBox(width: 44),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(34, 12, 34, 14),
                child: Text(
                  t('Saksıdaki bitkiyi seç. Nem eşikleri ve sıcaklık önerileri ona göre ayarlanır.'),
                  textAlign: TextAlign.center,
                  style: text.bodyLarge?.copyWith(color: p.textMuted),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.page, 4, AppSpacing.page, 24),
                  children: [
                    for (final plant in plants)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          padding: const EdgeInsets.all(12),
                          onTap: () => _open(context, plant),
                          child: Row(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: p.okBg,
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Center(child: PlantIllustration(kind: plantKindFor(plant), size: 58)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            t(plant.name),
                                            overflow: TextOverflow.ellipsis,
                                            style: text.titleMedium?.copyWith(fontSize: 18),
                                          ),
                                        ),
                                        if (plant.isCustom) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: p.accent,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              t('Özel'),
                                              style: text.labelSmall?.copyWith(color: p.onAccent),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      t('Nem {0} · {1}', [
                                        formatPercentRange(plant.idealMoistureMin, plant.idealMoistureMax),
                                        formatTempRange(plant.tempMin, plant.tempMax),
                                      ]),
                                      style: text.bodyMedium?.copyWith(color: p.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              if (plant.id == assignedId)
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(color: p.primary, shape: BoxShape.circle),
                                  child: Icon(Icons.check_rounded, size: 19, color: p.onPrimary),
                                )
                              else
                                Icon(Icons.chevron_right_rounded, color: p.textMuted),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: p.isDark ? Colors.white : p.primary,
                        side: BorderSide(color: p.isDark ? Colors.white54 : p.primary, width: 2),
                      ),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => PlantFormScreen(initialCategory: category)),
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: Text(t('Kendi bitkini ekle')),
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
