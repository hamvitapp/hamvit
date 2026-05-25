import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'chart_aggregation_service.dart';
import 'chart_insight_engine.dart';

enum DashboardPeriod {
  days7,
  days30,
  days90,
  year1,
  all,
}

extension DashboardPeriodX on DashboardPeriod {
  String get label {
    switch (this) {
      case DashboardPeriod.days7:
        return '7 dias';
      case DashboardPeriod.days30:
        return '30 dias';
      case DashboardPeriod.days90:
        return '90 dias';
      case DashboardPeriod.year1:
        return '1 ano';
      case DashboardPeriod.all:
        return 'Tudo';
    }
  }

  int? get days {
    switch (this) {
      case DashboardPeriod.days7:
        return 7;
      case DashboardPeriod.days30:
        return 30;
      case DashboardPeriod.days90:
        return 90;
      case DashboardPeriod.year1:
        return 365;
      case DashboardPeriod.all:
        return null;
    }
  }

  static DashboardPeriod fromName(String? value) {
    for (final item in DashboardPeriod.values) {
      if (item.name == value) return item;
    }
    return DashboardPeriod.days7;
  }
}

class DashboardPoint {
  final DateTime date;
  final double value;

  const DashboardPoint({required this.date, required this.value});
}

class DashboardMetricData {
  final String id;
  final String title;
  final String subtitle;
  final String unit;
  final List<DashboardPoint> points;
  final double? goal;
  final String insight;
  final String emptyMessage;
  final String summary;

  const DashboardMetricData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.unit,
    required this.points,
    required this.goal,
    required this.insight,
    required this.emptyMessage,
    required this.summary,
  });

  bool get isEmpty => points.every((p) => p.value == 0);
}

class DashboardMetricsSnapshot {
  final DashboardPeriod period;
  final DateTime start;
  final DateTime end;
  final List<DashboardMetricData> metrics;

  const DashboardMetricsSnapshot({
    required this.period,
    required this.start,
    required this.end,
    required this.metrics,
  });
}

class DashboardMetricsService {
  DashboardMetricsService({
    required this.aggregation,
    required this.insights,
  });

  final ChartAggregationService aggregation;
  final HamvitChartInsightEngine insights;

  Future<DashboardMetricsSnapshot> fetchSnapshot(DashboardPeriod period) async {
    final result = await aggregation.aggregate(period);

    DashboardMetricData buildMetric({
      required String id,
      required String title,
      required String subtitle,
      required String unit,
      required List<DashboardPoint> points,
      required double? goal,
      required String emptyMessage,
      required String summary,
    }) {
      final insight = insights.build(
        metricId: id,
        points: points,
        goal: goal,
        unit: unit,
      );

      return DashboardMetricData(
        id: id,
        title: title,
        subtitle: subtitle,
        unit: unit,
        points: points,
        goal: goal,
        insight: insight,
        emptyMessage: emptyMessage,
        summary: summary,
      );
    }

    final metrics = <DashboardMetricData>[
      buildMetric(
        id: 'water',
        title: 'Água',
        subtitle: 'Consumo diário de hidratação',
        unit: 'ml',
        points: result.water,
        goal: result.waterGoal,
        emptyMessage: 'Registre sua primeira hidratação.',
        summary: result.waterSummary,
      ),
      buildMetric(
        id: 'calories',
        title: 'Calorias',
        subtitle: 'Ingestão diária no período',
        unit: 'kcal',
        points: result.calories,
        goal: result.caloriesGoal,
        emptyMessage: 'Registre sua primeira refeição.',
        summary: result.caloriesSummary,
      ),
      buildMetric(
        id: 'habits',
        title: 'Hábitos',
        subtitle: 'Hábitos concluídos por dia',
        unit: 'hábitos',
        points: result.habits,
        goal: result.habitsGoal,
        emptyMessage: 'Conclua seu primeiro hábito do período.',
        summary: result.habitsSummary,
      ),
      buildMetric(
        id: 'activity',
        title: 'Atividade',
        subtitle: 'Minutos ativos por dia',
        unit: 'min',
        points: result.activity,
        goal: result.activityGoal,
        emptyMessage: 'Inicie uma atividade para ver seu movimento.',
        summary: result.activitySummary,
      ),
      buildMetric(
        id: 'sleep',
        title: 'Sono',
        subtitle: 'Horas dormidas por dia',
        unit: 'h',
        points: result.sleep,
        goal: result.sleepGoal,
        emptyMessage: 'Registre seu primeiro sono.',
        summary: result.sleepSummary,
      ),
      buildMetric(
        id: 'weight',
        title: 'Evolução de peso',
        subtitle: 'Peso ao longo do tempo',
        unit: 'kg',
        points: result.weight,
        goal: result.weightGoal,
        emptyMessage: 'Registre seu peso para acompanhar a evolução.',
        summary: result.weightSummary,
      ),
      buildMetric(
        id: 'bmi',
        title: 'IMC',
        subtitle: 'Índice de massa corporal estimado',
        unit: 'IMC',
        points: result.bmi,
        goal: result.bmiGoal,
        emptyMessage: 'Adicione altura e peso para gerar IMC.',
        summary: result.bmiSummary,
      ),
      buildMetric(
        id: 'consistency',
        title: 'Consistência',
        subtitle: 'Percentual diário de metas cumpridas',
        unit: '%',
        points: result.consistency,
        goal: result.consistencyGoal,
        emptyMessage: 'Seu histórico de constância aparecerá aqui.',
        summary: result.consistencySummary,
      ),
    ];

    return DashboardMetricsSnapshot(
      period: period,
      start: result.start,
      end: result.end,
      metrics: metrics,
    );
  }
}

class DashboardPeriodController extends StateNotifier<DashboardPeriod> {
  DashboardPeriodController() : super(DashboardPeriod.days7) {
    unawaited(_load());
  }

  static const _key = 'hamvit_dashboard_period';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    state = DashboardPeriodX.fromName(saved);
  }

  Future<void> setPeriod(DashboardPeriod value) async {
    if (state == value) return;
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, value.name);
  }
}

final dashboardPeriodProvider =
    StateNotifierProvider<DashboardPeriodController, DashboardPeriod>(
  (ref) => DashboardPeriodController(),
);

final dashboardMetricsServiceProvider = Provider<DashboardMetricsService>((ref) {
  final client = ref.watch(supabaseClientProvider) ?? Supabase.instance.client;
  final userId = ref.watch(currentUserProvider)?.id;
  final aggregation = ChartAggregationService(client: client, userId: userId);
  final insights = HamvitChartInsightEngine();
  return DashboardMetricsService(aggregation: aggregation, insights: insights);
});

final dashboardSnapshotProvider = FutureProvider<DashboardMetricsSnapshot>((ref) async {
  final period = ref.watch(dashboardPeriodProvider);
  final service = ref.watch(dashboardMetricsServiceProvider);
  return service.fetchSnapshot(period);
});
