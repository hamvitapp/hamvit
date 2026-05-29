import '../dashboard/domain/dashboard_metrics_service.dart';

class ReportInsightEngine {
  List<Map<String, String>> build({
    required List<DashboardPoint> waterCurrent,
    required List<DashboardPoint> waterPrevious,
    required double waterGoal,
    required List<DashboardPoint> caloriesCurrent,
    required List<DashboardPoint> caloriesPrevious,
    required double caloriesGoal,
    required List<DashboardPoint> habitsCurrent,
    required List<DashboardPoint> habitsPrevious,
    required List<DashboardPoint> sleepCurrent,
    required List<DashboardPoint> sleepPrevious,
    required List<DashboardPoint> activityCurrent,
    required List<DashboardPoint> activityPrevious,
    required List<DashboardPoint> weightCurrent,
    required List<DashboardPoint> weightPrevious,
    required double? weightTarget,
  }) {
    final insights = <Map<String, String>>[];

    final waterAvg = _avg(waterCurrent);
    final waterPrevAvg = _avg(waterPrevious);
    if (waterAvg > 0) {
      insights.add(_trendInsight(
        titleUp: 'Hidratacao em evolucao',
        titleDown: 'Hidratacao em atencao',
        current: waterAvg,
        previous: waterPrevAvg,
        bodyUp: 'Sua media diaria de agua subiu em relacao ao periodo anterior.',
        bodyDown: 'Sua media diaria de agua caiu; reforcar lembretes pode ajudar.',
      ));
      final goalDays = waterCurrent.where((p) => p.value >= waterGoal).length;
      insights.add({
        'type': goalDays >= (waterCurrent.length * 0.6) ? 'advance' : 'attention',
        'title': 'Aderencia de hidratacao',
        'body': 'Voce bateu a meta de agua em $goalDays dias do periodo selecionado.',
      });
    }

    final calAvg = _avg(caloriesCurrent);
    if (calAvg > 0) {
      final deltaGoal = calAvg - caloriesGoal;
      insights.add({
        'type': deltaGoal.abs() <= caloriesGoal * 0.1 ? 'advance' : 'attention',
        'title': 'Aderencia calorica',
        'body': deltaGoal.abs() <= caloriesGoal * 0.1
            ? 'Sua media calorica ficou proxima da meta no periodo.'
            : 'Sua media calorica ficou ${deltaGoal > 0 ? 'acima' : 'abaixo'} da meta no periodo.',
      });
    }

    insights.add(_trendInsight(
      titleUp: 'Constancia de habitos em alta',
      titleDown: 'Constancia de habitos oscilando',
      current: _nonZeroRate(habitsCurrent),
      previous: _nonZeroRate(habitsPrevious),
      bodyUp: 'Voce registrou habitos com mais regularidade que no periodo anterior.',
      bodyDown: 'A regularidade de habitos caiu; pequenas metas diarias podem recuperar ritmo.',
    ));

    insights.add(_trendInsight(
      titleUp: 'Sono com melhor consistencia',
      titleDown: 'Sono menos consistente',
      current: _avg(sleepCurrent),
      previous: _avg(sleepPrevious),
      bodyUp: 'Sua media de sono melhorou no periodo selecionado.',
      bodyDown: 'Sua media de sono reduziu no periodo; vale revisar rotina noturna.',
    ));

    insights.add(_trendInsight(
      titleUp: 'Atividade fisica em crescimento',
      titleDown: 'Atividade fisica em queda',
      current: _sum(activityCurrent),
      previous: _sum(activityPrevious),
      bodyUp: 'Seu volume de minutos ativos aumentou em relacao ao periodo anterior.',
      bodyDown: 'Seu volume de minutos ativos caiu; retomar frequencia semanal ajuda.',
    ));

    final latestWeight = weightCurrent.where((e) => e.value > 0).isEmpty
        ? null
        : weightCurrent.where((e) => e.value > 0).last.value;
    if (latestWeight != null && weightTarget != null && weightTarget > 0) {
      final diff = (latestWeight - weightTarget).abs();
      insights.add({
        'type': diff <= 1.0 ? 'advance' : 'baseline',
        'title': 'Proximidade da meta de peso',
        'body': diff <= 1.0
            ? 'Seu peso atual esta muito proximo da meta definida.'
            : 'Voce esta a ${diff.toStringAsFixed(1)} kg da meta de peso.',
      });
    }

    if (insights.isEmpty) {
      return const [
        {
          'type': 'baseline',
          'title': 'Sem dados suficientes no periodo',
          'body': 'Registre mais informacoes para liberar analises evolutivas completas.',
        }
      ];
    }
    return insights;
  }

  Map<String, String> _trendInsight({
    required String titleUp,
    required String titleDown,
    required double current,
    required double previous,
    required String bodyUp,
    required String bodyDown,
  }) {
    if (current >= previous) {
      return {'type': 'advance', 'title': titleUp, 'body': bodyUp};
    }
    return {'type': 'attention', 'title': titleDown, 'body': bodyDown};
  }

  double _sum(List<DashboardPoint> points) =>
      points.fold<double>(0, (acc, e) => acc + e.value);

  double _avg(List<DashboardPoint> points) {
    if (points.isEmpty) return 0;
    return _sum(points) / points.length;
  }

  double _nonZeroRate(List<DashboardPoint> points) {
    if (points.isEmpty) return 0;
    return points.where((p) => p.value > 0).length / points.length;
  }
}

