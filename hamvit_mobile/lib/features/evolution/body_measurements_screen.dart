import 'package:flutter/material.dart';

import '../../core/hamvit_date_utils.dart';
import '../../shared/widgets/hamvit_date_field.dart';

class BodyMeasurementPayload {
  final DateTime measuredAt;
  final double? waistCm;
  final double? abdomenCm;
  final double? chestCm;
  final double? armCm;
  final double? thighCm;
  final double? hipCm;

  const BodyMeasurementPayload({
    required this.measuredAt,
    required this.waistCm,
    required this.abdomenCm,
    required this.chestCm,
    required this.armCm,
    required this.thighCm,
    required this.hipCm,
  });
}

class BodyMeasurementsScreen extends StatefulWidget {
  final Future<void> Function(BodyMeasurementPayload payload) onSave;

  const BodyMeasurementsScreen({super.key, required this.onSave});

  @override
  State<BodyMeasurementsScreen> createState() => _BodyMeasurementsScreenState();
}

class _BodyMeasurementsScreenState extends State<BodyMeasurementsScreen> {
  final _waistCtrl = TextEditingController();
  final _abdomenCtrl = TextEditingController();
  final _chestCtrl = TextEditingController();
  final _armCtrl = TextEditingController();
  final _thighCtrl = TextEditingController();
  final _hipCtrl = TextEditingController();
  final _dateCtrl = TextEditingController(text: HamvitDateUtils.formatDateBr(DateTime.now()));

  DateTime _measuredAt = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _waistCtrl.dispose();
    _abdomenCtrl.dispose();
    _chestCtrl.dispose();
    _armCtrl.dispose();
    _thighCtrl.dispose();
    _hipCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  double? _valueOf(TextEditingController controller) {
    final raw = controller.text.trim();
    if (raw.isEmpty) return null;
    return double.tryParse(raw.replaceAll(',', '.'));
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(
        BodyMeasurementPayload(
          measuredAt: _measuredAt,
          waistCm: _valueOf(_waistCtrl),
          abdomenCm: _valueOf(_abdomenCtrl),
          chestCm: _valueOf(_chestCtrl),
          armCm: _valueOf(_armCtrl),
          thighCm: _valueOf(_thighCtrl),
          hipCm: _valueOf(_hipCtrl),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao salvar medidas: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Medidas corporais', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              HamvitDateField(
                label: 'Data da medicao',
                controller: _dateCtrl,
                onIsoChanged: (iso) {
                  if (iso == null) return;
                  final parsed = HamvitDateUtils.tryParseIsoDate(iso);
                  if (parsed != null) _measuredAt = parsed;
                },
                lastDate: DateTime.now(),
              ),
              const SizedBox(height: 8),
              _field('Cintura (cm)', _waistCtrl),
              _field('Abdomen (cm)', _abdomenCtrl),
              _field('Peito (cm)', _chestCtrl),
              _field('Braco (cm)', _armCtrl),
              _field('Coxa (cm)', _thighCtrl),
              _field('Quadril (cm)', _hipCtrl),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: Text(_saving ? 'Salvando...' : 'Salvar medidas'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}