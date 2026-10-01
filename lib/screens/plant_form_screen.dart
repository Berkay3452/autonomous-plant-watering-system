import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/plant.dart';
import '../providers/plants_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Yeni bitki profili ekleme ya da kullanıcının eklediği bitkiyi düzenleme.
class PlantFormScreen extends StatefulWidget {
  const PlantFormScreen({super.key, this.plant});

  final Plant? plant;

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
    _category = p?.category ?? PlantCategory.other;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum nem, ideal aralığın alt sınırından büyük olamaz.')),
      );
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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(_isNew ? 'Yeni bitki' : 'Bitkiyi düzenle')),
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Bitki adı'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Bir ad girin' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<PlantCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: [
                for (final c in PlantCategory.values)
                  DropdownMenuItem(
                    value: c,
                    child: Row(children: [Icon(c.icon, size: 20), const SizedBox(width: 8), Text(c.label)]),
                  ),
              ],
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<WaterNeed>(
              initialValue: _waterNeed,
              decoration: const InputDecoration(labelText: 'Su ihtiyacı'),
              items: [
                for (final w in WaterNeed.values) DropdownMenuItem(value: w, child: Text(w.label)),
              ],
              onChanged: (v) => setState(() => _waterNeed = v ?? _waterNeed),
            ),
            const SizedBox(height: AppSpacing.xl),
            _LabeledValue(label: 'Minimum nem', value: formatPercent(_minMoisture)),
            Text(
              'Bu değerin altında "bitki susuz" bildirimi gider ve otomatik modda sulama başlar.',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
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
              label: 'İdeal nem aralığı',
              value: '${formatPercent(_ideal.start)}–${_ideal.end.round()}',
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
              label: 'Uygun sıcaklık',
              value: '${_temperature.start.round()}–${_temperature.end.round()} °C',
            ),
            RangeSlider(
              values: _temperature,
              min: 0,
              max: 45,
              divisions: 45,
              labels: RangeLabels('${_temperature.start.round()} °C', '${_temperature.end.round()} °C'),
              onChanged: (v) => setState(() => _temperature = v),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _description,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Bakım notu (isteğe bağlı)'),
            ),
          ],
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
