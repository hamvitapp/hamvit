import 'dashboard_metrics_service.dart';

class HamvitChartInsightEngine {
  String build({
    required String metricId,
    required List<DashboardPoint> points,
    required double? goal,
    required String unit,
  }) {
    if (points.isEmpty || points.every((p) => p.value <= 0)) {
      return switch (metricId) {
        'water' => 'Comece com pequenos registros de água para ativar seu histórico.',
        'calories' => 'Quando você registrar refeições, o equilíbrio calórico ficará visível aqui.',
        'habits' => 'Cada hábito concluído fortalece sua consistência diária.',
        'activity' => 'Movimentos curtos ao longo do dia já geram evolução no gráfico.',
        'sleep' => 'Registrar o sono ajuda a entender seu ritmo de recuperação.',
        'weight' => 'Registrar peso de forma periódica ajuda a observar tendência com calma.',
        'bmi' => 'Com peso e altura atualizados, seu IMC será acompanhado aqui.',
        _ => 'A constância aparece com o avanço dos seus registros diários.',
      };
    }

    final first = points.first.value;
    final last = points.last.value;
    final delta = last - first;
    final trend = delta.abs() < 0.001
        ? 'estável'
        : (delta > 0 ? 'em alta' : 'em queda');

    final avg = points.map((e) => e.value).reduce((a, b) => a + b) / points.length;
    final goalHits = goal == null
        ? 0
        : points.where((p) => p.value >= goal).length;

    final goalPart = goal == null
        ? ''
        : ' Meta atingida em $goalHits de ${points.length} dias.';

    return switch (metricId) {
      'water' =>
        'Sua hidratação está $trend. Média recente de ${avg.toStringAsFixed(0)} $unit.$goalPart',
      'calories' =>
        'Seu consumo ficou $trend, com média de ${avg.toStringAsFixed(0)} $unit.$goalPart',
      'habits' =>
        'Sua rotina de hábitos está $trend. Você manteve ${avg.toStringAsFixed(1)} hábitos por dia em média.',
      'activity' =>
        'Seu nível de movimento está $trend, com ${avg.toStringAsFixed(0)} $unit por dia em média.$goalPart',
      'sleep' =>
        'Seu sono ficou $trend com média de ${avg.toStringAsFixed(1)} $unit por dia.$goalPart',
      'weight' =>
        'Sua evolução de peso está $trend. Acompanhe sem pressa e com constância.',
      'bmi' =>
        'Seu IMC está $trend ao longo do período. Foque em equilíbrio sustentável.',
      _ =>
        'Sua consistência está $trend, com média de ${avg.toStringAsFixed(0)}% no período.',
    };
  }
}
