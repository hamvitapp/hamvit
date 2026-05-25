import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings_repository.dart';
import 'settings_provider.dart';

class NotificationPreferencesNotifier extends AsyncNotifier<NotificationSettingsData> {
  late final SettingsRepository _repo;

  @override
  Future<NotificationSettingsData> build() async {
    _repo = ref.read(settingsRepositoryProvider);
    return _repo.loadNotificationSettings();
  }

  Future<void> setGeneralEnabled(bool enabled) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final next = NotificationSettingsData(enabled: enabled, categories: current.categories);
    state = AsyncData(next);
    try {
      await _repo.saveNotificationSettings(next);
    } catch (e, st) {
      state = AsyncError(e, st);
      state = AsyncData(current);
      rethrow;
    }
  }

  Future<void> setCategoryEnabled(String category, bool enabled) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final existing = current.categories[category];
    if (existing == null) return;

    final categories = Map<String, NotificationPreference>.from(current.categories)
      ..[category] = existing.copyWith(enabled: enabled);

    final next = NotificationSettingsData(enabled: current.enabled, categories: categories);
    state = AsyncData(next);
    try {
      await _repo.saveNotificationSettings(next);
    } catch (e, st) {
      state = AsyncError(e, st);
      state = AsyncData(current);
      rethrow;
    }
  }

  Future<void> setReminderTime(String category, TimeOfDay time) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final existing = current.categories[category];
    if (existing == null) return;

    final categories = Map<String, NotificationPreference>.from(current.categories)
      ..[category] = existing.copyWith(reminderTime: time);

    final next = NotificationSettingsData(enabled: current.enabled, categories: categories);
    state = AsyncData(next);
    try {
      await _repo.saveNotificationSettings(next);
    } catch (e, st) {
      state = AsyncError(e, st);
      state = AsyncData(current);
      rethrow;
    }
  }
}

final notificationPreferencesProvider =
    AsyncNotifierProvider<NotificationPreferencesNotifier, NotificationSettingsData>(
  NotificationPreferencesNotifier.new,
);
