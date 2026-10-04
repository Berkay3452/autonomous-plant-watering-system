import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/plant.dart';
import '../providers/pots_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/app_card.dart';
import '../widgets/category_icon.dart';
import '../widgets/circle_icon_button.dart';
import 'plant_list_screen.dart';

/// Bitki türü: saksı için bitki kategorisi seçilir, sonra bitkiye geçilir.
class PlantTypeScreen extends StatefulWidget {
  const PlantTypeScreen({super.key, required this.potId});

  final String potId;

  @override
  State<PlantTypeScreen> createState() => _PlantTypeScreenState();
}

class _PlantTypeScreenState extends State<PlantTypeScreen> {
  late PlantCategory _selected;

  @override
  void initState() {
    super.initState();
    final plant = context.read<PotsProvider>().plantOf(widget.potId);
    _selected = plant?.category ?? PlantCategory.tropical;
  }

  @override
  Widget build(BuildContext context) {
    final pots = context.watch<PotsProvider>();
    final pot = pots.potById(widget.potId);
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
                    Expanded(
                      child: Center(child: Text(t('Bitki türü'), style: text.headlineMedium)),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(34, 14, 34, 18),
                child: Text(
                  t('{0} için bitki kategorisini seç. Sulama önerileri buna göre ayarlanır.', [t(pot?.name ?? 'Saksı')]),
                  textAlign: TextAlign.center,
                  style: text.bodyLarge?.copyWith(color: p.textMuted, fontSize: 16),
                ),
              ),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                  children: [
                    for (final category in PlantCategory.values)
                      _CategoryCard(
                        category: category,
                        selected: category == _selected,
                        onTap: () => setState(() => _selected = category),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.page, 8, AppSpacing.page, 18),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    iconAlignment: IconAlignment.end,
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => PlantListScreen(potId: widget.potId, category: _selected),
                    )),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(t('Devam et')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.selected, required this.onTap});

  final PlantCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final t = context.t;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: selected ? p.primary : Colors.transparent, width: 3),
      ),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: p.okBg, shape: BoxShape.circle),
                  child: Center(child: CategoryIcon(category: category, size: 24, color: p.okFg)),
                ),
                const Spacer(),
                if (selected)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(color: p.primary, shape: BoxShape.circle),
                    child: Icon(Icons.check_rounded, size: 18, color: p.onPrimary),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              t(category.label),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.titleMedium?.copyWith(fontSize: 18),
            ),
            Row(
              children: [
                Icon(Icons.water_drop, size: 13, color: p.primary),
                const SizedBox(width: 4),
                Text(
                  t(category.waterLabel),
                  style: text.bodyMedium?.copyWith(color: p.textMuted, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
