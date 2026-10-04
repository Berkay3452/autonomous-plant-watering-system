import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/plant.dart';
import '../providers/plants_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/app_background.dart';
import '../widgets/category_icon.dart';
import '../widgets/circle_icon_button.dart';

/// Yeni bitki profili ekleme ya da kullanıcının eklediği bitkiyi düzenleme.
class PlantFormScreen extends StatefulWidget {
  const PlantFormScreen({super.key, this.plant, this.initialCategory});

  final Plant? plant;
  final PlantCategory? initialCategory;

  @override
  State<PlantFormScreen> createState() => _PlantFormScreenState();
}

class _PlantFormScreenState extends State<PlantFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late PlantCategory _category;
  late WaterNeed _waterNeed;
  late double _minMoisture;
  late RangeValues _ideal;
  late RangeValues _temperature;

  bool get _isNew => widget.plant == null;

  @override
  void initState() {
    super.initState();
    final p = widget.plant;
    _name = TextEditingController(text: p?.name ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _category = p?.category ?? widget.initialCategory ?? PlantCategory.tropical;
    _waterNeed = p?.waterNeed ?? WaterNeed.medium;
    _minMoisture = (p?.minMoisture ?? 35).toDouble();
    _ideal = RangeValues((p?.idealMoistureMin ?? 45).toDouble(), (p?.idealMoistureMax ?? 65).toDouble());
    _temperature = RangeValues(p?.tempMin ?? 18, p?.tempMax ?? 28);
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_minMoisture > _ideal.start) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(context.t('Minimum nem, ideal aralığın alt sınırından büyük olamaz.')),
        ));
      return;
    }
    final provider = context.read<PlantsProvider>();
    final plant = Plant(
      id: widget.plant?.id ?? provider.newCustomId(),
      name: _name.text.trim(),
      category: _category,
      minMoisture: _minMoisture.round(),
      idealMoistureMin: _ideal.start.round(),
      idealMoistureMax: _ideal.end.round(),
      waterNeed: _waterNeed,
      tempMin: _temperature.start.roundToDouble(),
      tempMax: _temperature.end.roundToDouble(),
      description: _description.text.trim(),
      source: ValueSource.user,
    );
    if (_isNew) {
      provider.addCustom(plant);
    } else {
      provider.updateCustom(plant);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final t = context.t;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.page, 14, AppSpacing.page, 8),
                child: Row(
                  children: [
                    CircleIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      tooltip: t('Geri'),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(_isNew ? t('Yeni bitki') : t('Bitkiyi düzenle'), style: text.headlineMedium),
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
              ),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.page),
                    children: [
                      TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(labelText: t('Bitki adı')),
                        validator: (v) => (v == null || v.trim().isEmpty) ? t('Bir ad gir') : null,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      DropdownButtonFormField<PlantCategory>(
                        initialValue: _category,
                        decoration: InputDecoration(labelText: t('Kategori')),
                        dropdownColor: p.sheet,
                        borderRadius: BorderRadius.circular(20),
                        items: [
                          for (final c in PlantCategory.values)
                            DropdownMenuItem(
                              value: c,
                              child: Row(
                                children: [
                                  CategoryIcon(category: c, size: 20, color: p.primary),
                                  const SizedBox(width: 10),
                                  Text(t(c.label)),
                                ],
                              ),
                            ),
                        ],
                        onChanged: (v) => setState(() => _category = v ?? _category),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      DropdownButtonFormField<WaterNeed>(
                        initialValue: _waterNeed,
                        decoration: InputDecoration(labelText: t('Su ihtiyacı')),
                        dropdownColor: p.sheet,
                        borderRadius: BorderRadius.circular(20),
                        items: [
                          for (final w in WaterNeed.values) DropdownMenuItem(value: w, child: Text(t(w.label))),
                        ],
                        onChanged: (v) => setState(() => _waterNeed = v ?? _waterNeed),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _LabeledValue(label: t('Minimum nem'), value: formatPercent(_minMoisture)),
                      Text(
                        t('Bu değerin altında "bitki susadı" bildirimi gider ve otomatik modda sulama başlar.'),
                        style: text.bodySmall,
                      ),
                      Slider(
                        value: _minMoisture,
                        min: 0,
                        max: 90,
                        divisions: 90,
                        label: formatPercent(_minMoisture),
                        onChanged: (v) => setState(() => _minMoisture = v),
                      ),
                      _LabeledValue(
                        label: t('İdeal nem aralığı'),
                        value: formatPercentRange(_ideal.start, _ideal.end),
                      ),
                      RangeSlider(
                        values: _ideal,
                        min: 0,
                        max: 100,
                        divisions: 100,
                        labels: RangeLabels(formatPercent(_ideal.start), formatPercent(_ideal.end)),
                        onChanged: (v) => setState(() => _ideal = v),
                      ),
                      _LabeledValue(
                        label: t('Uygun sıcaklık'),
                        value: formatTempRange(_temperature.start, _temperature.end),
                      ),
                      RangeSlider(
                        values: _temperature,
                        min: 0,
                        max: 45,
                        divisions: 45,
                        labels: RangeLabels(
                          formatTemperature(_temperature.start),
                          formatTemperature(_temperature.end),
                        ),
                        onChanged: (v) => setState(() => _temperature = v),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextFormField(
                        controller: _description,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(labelText: t('Bakım notu (isteğe bağlı)')),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.page, 4, AppSpacing.page, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check_rounded),
                    label: Text(t('Kaydet')),
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

class _LabeledValue extends StatelessWidget {
  const _LabeledValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(child: Text(label, style: text.titleSmall)),
        Text(value, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}
