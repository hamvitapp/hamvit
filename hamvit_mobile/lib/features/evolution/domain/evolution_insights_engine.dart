import 'weight_progress_engine.dart';

class EvolutionInsightsEngine {
  static List<String> build({
    required WeightProgressSummary summary,
    required int registerCount,
    required double? latestBmi,
  }) {
    final insights = <String>[];

    if (registerCount == 0) {
      insights.add('Comece registrando seu peso para acompanhar sua evolucao com dados reais.');
      return insights;
    }

    if (registerCount >= 8) {
      insights.add('Voce mantem boa consistencia de registros.');
    } else {
      insights.add('Pequenas evolucoes tambem contam. Continue registrando no seu ritmo.');
    }

    final diff = summary.differenceKg;
    if (diff != null) {
      if (diff < 0) {
        insights.add('Seu peso reduziu ${diff.abs().toStringAsFixed(1)} kg desde o inicio.');
      } else if (diff > 0) {
        insights.add('Seu peso aumentou ${diff.toStringAsFixed(1)} kg desde o inicio.');
      } else {
        insights.add('Seu peso esta estavel desde o inicio dos registros.');
      }
    }

    if (latestBmi != null) {
      if (latestBmi < 25) {
        insights.add('Seu IMC atual esta em uma faixa considerada adequada.');
      } else {
        insights.add('Seu IMC esta em evolucao. Mantenha foco em consistencia, nao em pressa.');
      }
    }

    return insights;
  }
}