import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/dashboard_repository.dart';
import '../domain/dashboard_models.dart';
import '../domain/dashboard_metrics_service.dart';

@Deprecated('Use dashboardPeriodProvider from dashboard_metrics_service.dart')
final dashboardRangeProvider = StateProvider<DashboardRange>((ref) => DashboardRange.sevenDays);

@Deprecated('Use dashboardSnapshotProvider from dashboard_metrics_service.dart')
final dashboardChartsProvider = FutureProvider<DashboardChartsData>((ref) async {
  final range = ref.watch(dashboardRangeProvider);
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.fetchCharts(range);
});

final dashboardPremiumSnapshotProvider = dashboardSnapshotProvider;
