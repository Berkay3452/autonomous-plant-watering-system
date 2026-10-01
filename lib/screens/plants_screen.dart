import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/plant.dart';
import '../providers/plants_provider.dart';
import '../providers/pot_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/plant_detail_sheet.dart';
import 'plant_form_screen.dart';

/// Bitki kategorileri ve profilleri. [pickMode] açıksa saksıya bitki seçmek
/// için açılmıştır; seçim yapılınca ekran kapanır.
class PlantsScreen extends StatefulWidget {
  const PlantsScreen({super.key, this.pickMode = false});

  final bool pickMode;

  @override
  State<PlantsScreen> createState() => _PlantsScreenState();
}

class _PlantsScreenState extends State<PlantsScreen> {
  PlantCategory? _category;
  String _query = '';

  Future<void> _openPlant(Plant plant) async {
    final pot = context.read<PotProvider>();
    final plants = context.read<PlantsProvider>();
    final action = await showPlantDetailSheet(
      context,
      plant: plant,
      isAssigned: pot.pot.plantId == plant.id,
    );
    if (!mounted || action == null) return;

    switch (action) {
      case 'assign':
        pot.assignPlant(plant.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${pot.pot.name} için ${plant.name} seçildi.')),
        );
        if (widget.pickMode) Navigator.of(context).pop();
      case 'edit':
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PlantFormScreen(plant: plant)),
        );
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('${plant.name} silinsin mi?'),
            content: const Text('Bu bitki saksıya atanmışsa saksı boşaltılır.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil')),
            ],
          ),
        );
        if (confirmed == true) plants.deleteCustom(plant.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plantsProvider = context.watch<PlantsProvider>();
    final assignedId = context.select<PotProvider, String?>((p) => p.pot.plantId);
    final plants = plantsProvider.filter(category: _category, query: _query);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    // "Tümü" seçiliyken kategorilere göre grupla.
    final groups = <PlantCategory, List<Plant>>{};
    for (final p in plants) {
      groups.putIfAbsent(p.category, () => []).add(p);
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.pickMode ? 'Bitki seç' : 'Bitkiler')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PlantFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Bitki ekle'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.page, 0, AppSpacing.page, AppSpacing.sm),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Bitki ara',
                border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(28))),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: const Text('Tümü'),
                    selected: _category == null,
                    onSelected: (_) => setState(() => _category = null),
                  ),
                ),
                for (final c in plantsProvider.categories)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ChoiceChip(
                      avatar: Icon(c.icon, size: 18),
                      label: Text(c.label),
                      selected: _category == c,
                      onSelected: (_) => setState(() => _category = _category == c ? null : c),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: plants.isEmpty
                ? Center(
                    child: Text('Aramanızla eşleşen bitki yok.', style: text.bodyMedium),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.sm, AppSpacing.page, 96),
                    children: [
                      for (final entry in groups.entries) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, AppSpacing.md, 4, AppSpacing.sm),
                          child: Row(
                            children: [
                              Icon(entry.key.icon, size: 18, color: scheme.primary),
                              const SizedBox(width: 6),
                              Text(
                                entry.key.label,
                                style: text.titleSmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 6),
                              Text('(${entry.value.length})', style: text.labelMedium),
                            ],
                          ),
                        ),
                        Card(
                          child: Column(
                            children: [
                              for (var i = 0; i < entry.value.length; i++) ...[
                                if (i > 0) const Divider(height: 1, indent: 72),
                                _PlantTile(
                                  plant: entry.value[i],
                                  assigned: entry.value[i].id == assignedId,
                                  onTap: () => _openPlant(entry.value[i]),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _PlantTile extends StatelessWidget {
  const _PlantTile({required this.plant, required this.assigned, required this.onTap});

  final Plant plant;
  final bool assigned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: assigned ? scheme.primary : scheme.primaryContainer,
        child: Icon(
          assigned ? Icons.check : plant.category.icon,
          color: assigned ? scheme.onPrimary : scheme.onPrimaryContainer,
        ),
      ),
      title: Row(
        children: [
          Flexible(child: Text(plant.name, overflow: TextOverflow.ellipsis)),
          if (plant.isCustom) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: scheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Özel',
                style: TextStyle(fontSize: 11, color: scheme.onTertiaryContainer),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        'Nem ${formatPercent(plant.idealMoistureMin)}–${plant.idealMoistureMax} · '
        'Su: ${plant.waterNeed.label} · ${plant.tempMin.round()}–${plant.tempMax.round()} °C',
      ),
      trailing: assigned
          ? Text('Saksıda', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600))
          : const Icon(Icons.chevron_right),
    );
  }
}
