import 'dart:async';

import 'package:flutter/material.dart';

import 'nutrition_service.dart';

class ManualMealEntryScreen extends StatefulWidget {
  const ManualMealEntryScreen({super.key, required this.service});

  final NutritionService service;

  @override
  State<ManualMealEntryScreen> createState() => _ManualMealEntryScreenState();
}

class _ManualMealEntryScreenState extends State<ManualMealEntryScreen> {
  static const _mealTypes = <Map<String, String>>[
    {'value': 'cafe_da_manha', 'label': 'Café da manhã'},
    {'value': 'lanche_manha', 'label': 'Lanche da manhã'},
    {'value': 'almoco', 'label': 'Almoço'},
    {'value': 'lanche_tarde', 'label': 'Lanche da tarde'},
    {'value': 'jantar', 'label': 'Jantar'},
    {'value': 'ceia', 'label': 'Ceia'},
  ];

  final _searchCtrl = TextEditingController();
  final _items = <Map<String, dynamic>>[];
  Timer? _debounce;
  String _mealType = 'almoco';
  bool _loadingFoods = false;
  bool _saving = false;
  List<Map<String, dynamic>> _foods = const [];

  int get _calories => _sum('calories');
  int get _protein => _sum('protein_g');
  int get _carbs => _sum('carbs_g');
  int get _fat => _sum('fat_g');

  @override
  void initState() {
    super.initState();
    _loadFoods('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  int _sum(String key) => _items.fold<int>(
        0,
        (total, item) => total + ((item[key] as num?)?.round() ?? 0),
      );

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
  }

  Future<void> _loadFoods(String query) async {
    setState(() => _loadingFoods = true);
    try {
      final foods = await widget.service.searchFoods(query);
      if (mounted) setState(() => _foods = foods);
    } finally {
      if (mounted) setState(() => _loadingFoods = false);
    }
  }

  void _searchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      _loadFoods(query);
    });
  }

  Future<void> _addFood(Map<String, dynamic> food,
      {Map<String, dynamic>? replacing}) async {
    final gramsCtrl = TextEditingController(
      text: (replacing?['grams'] as num?)?.toStringAsFixed(0) ?? '100',
    );
    final grams = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(food['name']?.toString() ?? 'Alimento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Por 100 g: ${_toDouble(food['calories']).round()} kcal | '
              'P ${_toDouble(food['protein_g']).toStringAsFixed(1)} g | '
              'C ${_toDouble(food['carbs_g']).toStringAsFixed(1)} g | '
              'G ${_toDouble(food['fats_g']).toStringAsFixed(1)} g',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: gramsCtrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Quantidade em gramas',
                suffixText: 'g',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final value =
                  double.tryParse(gramsCtrl.text.replaceAll(',', '.').trim());
              if (value != null && value > 0) Navigator.pop(context, value);
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
    gramsCtrl.dispose();
    if (grams == null || !mounted) return;

    final ratio = grams / 100;
    final item = <String, dynamic>{
      'food_id': food['id'],
      'name': food['name'],
      'grams': grams,
      'quantity': grams,
      'portion_label': 'gramas',
      'calories': _toDouble(food['calories']) * ratio,
      'protein_g': _toDouble(food['protein_g']) * ratio,
      'carbs_g': _toDouble(food['carbs_g']) * ratio,
      'fat_g': _toDouble(food['fats_g']) * ratio,
      '_food': food,
    };
    setState(() {
      if (replacing == null) {
        _items.add(item);
      } else {
        _items[_items.indexOf(replacing)] = item;
      }
    });
  }

  Future<void> _save() async {
    if (_items.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      await widget.service.registerDetailedMeal(
        mealType: _mealType,
        items: _items,
      );
      if (!mounted) return;
      Navigator.pop(context, {
        'meal_type': _mealType,
        'calories': _calories,
        'protein_g': _protein,
        'carbs_g': _carbs,
        'fat_g': _fat,
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao salvar refeição: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar refeição')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            initialValue: _mealType,
            decoration: const InputDecoration(labelText: 'Tipo da refeição'),
            items: _mealTypes
                .map((item) => DropdownMenuItem(
                      value: item['value'],
                      child: Text(item['label']!),
                    ))
                .toList(growable: false),
            onChanged: (value) =>
                setState(() => _mealType = value ?? _mealType),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchCtrl,
            onChanged: _searchChanged,
            decoration: const InputDecoration(
              labelText: 'Buscar alimento',
              hintText: 'Ex.: arroz, frango, banana',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 8),
          if (_loadingFoods)
            const LinearProgressIndicator()
          else
            SizedBox(
              height: 180,
              child: ListView.builder(
                itemCount: _foods.length,
                itemBuilder: (context, index) {
                  final food = _foods[index];
                  return ListTile(
                    dense: true,
                    title: Text(food['name']?.toString() ?? ''),
                    subtitle: Text(
                        '${_toDouble(food['calories']).round()} kcal / 100 g'),
                    trailing: const Icon(Icons.add_circle_outline),
                    onTap: () => _addFood(food),
                  );
                },
              ),
            ),
          const Divider(height: 24),
          Text('Itens da refeição',
              style: Theme.of(context).textTheme.titleMedium),
          if (_items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Adicione ao menos um alimento.'),
            )
          else
            ..._items.map(
              (item) => Card(
                child: ListTile(
                  title: Text(item['name']?.toString() ?? ''),
                  subtitle: Text(
                    '${(item['grams'] as num).toStringAsFixed(0)} g | '
                    '${(item['calories'] as num).round()} kcal | '
                    'P ${(item['protein_g'] as num).toStringAsFixed(1)} g | '
                    'C ${(item['carbs_g'] as num).toStringAsFixed(1)} g | '
                    'G ${(item['fat_g'] as num).toStringAsFixed(1)} g',
                  ),
                  onTap: () => _addFood(
                    item['_food'] as Map<String, dynamic>,
                    replacing: item,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => setState(() => _items.remove(item)),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Total: $_calories kcal | Proteínas: $_protein g | '
                'Carboidratos: $_carbs g | Gorduras: $_fat g',
              ),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _items.isEmpty || _saving ? null : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('Salvar refeição'),
          ),
        ],
      ),
    );
  }
}
