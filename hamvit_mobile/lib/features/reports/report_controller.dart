import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'report_repository.dart';

final reportPeriodProvider = StateProvider<ReportPeriodType>((ref) {
  return ReportPeriodType.days7;
});

final evolutionReportProvider = FutureProvider<EvolutionReportData>((ref) async {
  final repo = ref.watch(reportRepositoryProvider);
  final period = ref.watch(reportPeriodProvider);
  return repo.loadEvolutionReport(period: period);
});

final reportHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(reportRepositoryProvider);
  return repo.loadReportsHistory();
});
