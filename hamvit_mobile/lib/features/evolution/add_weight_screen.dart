import 'package:flutter/material.dart';

import '../../core/hamvit_date_utils.dart';
import '../../shared/widgets/hamvit_date_field.dart';

class AddWeightPayload {
  final double weightKg;
  final DateTime loggedAt;
  final String? notes;

  const AddWeightPayload({
    required this.weightKg,
    required this.loggedAt,
    required this.notes,
  });
}

class AddWeightScreen extends StatefulWidget {
  final Future<void> Function(AddWeightPayload payload) onSave;

  const AddWeightScreen({super.key, required this.onSave});

  @override
  State<AddWeightScreen> createState() => _AddWeightScreenState();
}

class _AddWeightScreenState extends State<AddWeightScreen> {
  final _weightCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _dateCtrl = TextEditingController(text: HamvitDateUtils.formatDateBr(DateTime.now()));
  DateTime _loggedAt = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _notesCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final weight = double.tryParse(_weightCtrl.text.trim().replaceAll(',', '.'));
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um peso valido.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.onSave(
        AddWeightPayload(
          weightKg: weight,
          loggedAt: _loggedAt,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao salvar pesagem: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
              Text('Registrar peso', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              TextField(
                controller: _weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Peso (kg)',
                  hintText: 'Ex.: 84,6',
                ),
              ),
              const SizedBox(height: 8),
              HamvitDateField(
                label: 'Data da pesagem',
                controller: _dateCtrl,
                onIsoChanged: (iso) {
                  if (iso == null) return;
                  final parsed = HamvitDateUtils.tryParseIsoDate(iso);
                  if (parsed != null) _loggedAt = parsed;
                },
                lastDate: DateTime.now(),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesCtrl,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observacao opcional',
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: Text(_saving ? 'Salvando...' : 'Salvar pesagem'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}