import 'package:flutter/material.dart';

class HamvitIndoorControls extends StatelessWidget {
  final double speedKmh;
  final ValueChanged<double> onSpeedChanged;

  const HamvitIndoorControls({
    super.key,
    required this.speedKmh,
    required this.onSpeedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Controles indoor',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text('Velocidade atual: ${speedKmh.toStringAsFixed(1)} km/h'),
            Slider(
              min: 3,
              max: 20,
              divisions: 34,
              value: speedKmh.clamp(3, 20),
              onChanged: onSpeedChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class HamvitActivityMetrics extends StatelessWidget {
  final String activityTypeLabel;
  final String environmentLabel;
  final int durationSeconds;
  final double distanceKm;
  final double speedKmh;
  final double caloriesKcal;
  final String paceLabel;

  const HamvitActivityMetrics({
    super.key,
    required this.activityTypeLabel,
    required this.environmentLabel,
    required this.durationSeconds,
    required this.distanceKm,
    required this.speedKmh,
    required this.caloriesKcal,
    required this.paceLabel,
  });

  @override
  Widget build(BuildContext context) {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipo: $activityTypeLabel'),
            Text('Modo: $environmentLabel'),
            Text('Tempo: $minutes min ${seconds}s'),
            Text('Distancia: ${distanceKm.toStringAsFixed(2)} km'),
            Text('Velocidade media: ${speedKmh.toStringAsFixed(2)} km/h'),
            Text('Ritmo medio: $paceLabel'),
            Text('Calorias estimadas: ${caloriesKcal.toStringAsFixed(0)} kcal'),
          ],
        ),
      ),
    );
  }
}

class HamvitDistanceEditor extends StatefulWidget {
  final double initialDistanceKm;
  final double initialSpeedKmh;
  final void Function(double distanceKm, double speedKmh) onConfirm;

  const HamvitDistanceEditor({
    super.key,
    required this.initialDistanceKm,
    required this.initialSpeedKmh,
    required this.onConfirm,
  });

  @override
  State<HamvitDistanceEditor> createState() => _HamvitDistanceEditorState();
}

class _HamvitDistanceEditorState extends State<HamvitDistanceEditor> {
  late final TextEditingController _distanceCtrl;
  late final TextEditingController _speedCtrl;

  @override
  void initState() {
    super.initState();
    _distanceCtrl =
        TextEditingController(text: widget.initialDistanceKm.toStringAsFixed(2));
    _speedCtrl =
        TextEditingController(text: widget.initialSpeedKmh.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _distanceCtrl.dispose();
    _speedCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajustar valores indoor'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _distanceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Distancia final (km)',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _speedCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Velocidade media (km/h)',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final distance =
                double.tryParse(_distanceCtrl.text.replaceAll(',', '.'));
            final speed = double.tryParse(_speedCtrl.text.replaceAll(',', '.'));
            if (distance == null || speed == null || distance < 0 || speed < 0) {
              return;
            }
            widget.onConfirm(distance, speed);
            Navigator.of(context).pop();
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

