import 'package:flutter/material.dart';

class HamvitTreadmillSummaryCard extends StatelessWidget {
  final double distanceKm;
  final double speedKmh;
  final double caloriesKcal;

  const HamvitTreadmillSummaryCard({
    super.key,
    required this.distanceKm,
    required this.speedKmh,
    required this.caloriesKcal,
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
              'Resumo da esteira',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text('Distancia estimada: ${distanceKm.toStringAsFixed(2)} km'),
            Text('Velocidade media: ${speedKmh.toStringAsFixed(1)} km/h'),
            Text('Calorias estimadas: ${caloriesKcal.toStringAsFixed(0)} kcal'),
            const SizedBox(height: 6),
            const Text(
              'Movimento tambem conta. Consistencia vale mais que intensidade.',
            ),
          ],
        ),
      ),
    );
  }
}

