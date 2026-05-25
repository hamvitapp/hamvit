import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase_provider.dart';
import '../data/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(supabaseClientProvider));
});

final settingsAccountProvider = FutureProvider<SettingsAccountData>((ref) async {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.loadAccountData();
});

final settingsPrivacyProvider = FutureProvider<PrivacySettingsData>((ref) async {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.loadPrivacySettings();
});

final settingsDataExportStatusProvider = FutureProvider<DataExportStatus>((ref) async {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.loadDataExportStatus();
});

final settingsGeneratedReportsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.loadGeneratedReports();
});
