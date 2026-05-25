import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/hamvit_colors.dart';
import 'domain/dashboard_metrics_service.dart';
import 'widgets/hamvit_chart_card.dart';
import 'widgets/hamvit_loading_chart_state.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(dashboardSnapshotProvider);
    await ref.read(dashboardSnapshotProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(dashboardPeriodProvider);
    final snapshotAsync = ref.watch(dashboardSnapshotProvider);

    const chartColors = {
      'water': HamvitColors.accentCyan,
      'calories': Color(0xFFE7AE57),
      'habits': Color(0xFF63D38A),
      'activity': HamvitColors.accentBlue,
      'sleep': Color(0xFF8D86E8),
      'weight': Color(0xFF53C7B2),
      'bmi': Color(0xFF62A3F8),
      'consistency': Color(0xFF6DE0D0),
    };

    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 120),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  HamvitColors.darkCard.withValues(alpha: 0.92),
                  HamvitColors.primaryNavy.withValues(alpha: 0.88),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Text(
              'Dashboard wellness premium: metas visuais, insights e tendência real dos seus dados.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: HamvitColors.darkText,
                    height: 1.35,
                  ),
            ),
          ),
          const SizedBox(height: 10),
          snapshotAsync.when(
            loading: () => const HamvitLoadingChartState(),
            error: (error, _) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Falha ao carregar dashboard premium',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$error',
                    style: const TextStyle(color: HamvitColors.darkTextMuted),
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: () => _refresh(ref),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
            data: (snapshot) {
              return Column(
                children: [
                  for (final metric in snapshot.metrics)
                    HamvitChartCard(
                      metric: metric,
                      color: chartColors[metric.id] ?? HamvitColors.accentCyan,
                      period: selectedPeriod,
                      onPeriodChanged: (next) => ref
                          .read(dashboardPeriodProvider.notifier)
                          .setPeriod(next),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
