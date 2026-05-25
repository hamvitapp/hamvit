import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsAccountData {
  final String userId;
  final String name;
  final String email;
  final String planLabel;
  final DateTime? createdAt;
  final String? objective;

  const SettingsAccountData({
    required this.userId,
    required this.name,
    required this.email,
    required this.planLabel,
    required this.createdAt,
    required this.objective,
  });
}

class NotificationPreference {
  final String category;
  final bool enabled;
  final TimeOfDay? reminderTime;

  const NotificationPreference({
    required this.category,
    required this.enabled,
    this.reminderTime,
  });

  NotificationPreference copyWith({
    bool? enabled,
    TimeOfDay? reminderTime,
  }) {
    return NotificationPreference(
      category: category,
      enabled: enabled ?? this.enabled,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }
}

class NotificationSettingsData {
  final bool enabled;
  final Map<String, NotificationPreference> categories;

  const NotificationSettingsData({
    required this.enabled,
    required this.categories,
  });
}

class AccessibilitySettingsData {
  final String textSize;
  final bool highContrast;
  final bool reduceMotion;
  final bool simpleMode;
  final bool largerButtons;
  final bool simplifiedLanguage;

  const AccessibilitySettingsData({
    required this.textSize,
    required this.highContrast,
    required this.reduceMotion,
    required this.simpleMode,
    required this.largerButtons,
    required this.simplifiedLanguage,
  });

  AccessibilitySettingsData copyWith({
    String? textSize,
    bool? highContrast,
    bool? reduceMotion,
    bool? simpleMode,
    bool? largerButtons,
    bool? simplifiedLanguage,
  }) {
    return AccessibilitySettingsData(
      textSize: textSize ?? this.textSize,
      highContrast: highContrast ?? this.highContrast,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      simpleMode: simpleMode ?? this.simpleMode,
      largerButtons: largerButtons ?? this.largerButtons,
      simplifiedLanguage: simplifiedLanguage ?? this.simplifiedLanguage,
    );
  }
}

class PrivacyProtectionSettingsData {
  final bool screenshotProtectionEnabled;
  final bool hideRecentAppsPreview;
  final bool appBlurEnabled;

  const PrivacyProtectionSettingsData({
    required this.screenshotProtectionEnabled,
    required this.hideRecentAppsPreview,
    required this.appBlurEnabled,
  });

  static const defaults = PrivacyProtectionSettingsData(
    screenshotProtectionEnabled: true,
    hideRecentAppsPreview: true,
    appBlurEnabled: true,
  );

  PrivacyProtectionSettingsData copyWith({
    bool? screenshotProtectionEnabled,
    bool? hideRecentAppsPreview,
    bool? appBlurEnabled,
  }) {
    return PrivacyProtectionSettingsData(
      screenshotProtectionEnabled:
          screenshotProtectionEnabled ?? this.screenshotProtectionEnabled,
      hideRecentAppsPreview:
          hideRecentAppsPreview ?? this.hideRecentAppsPreview,
      appBlurEnabled: appBlurEnabled ?? this.appBlurEnabled,
    );
  }
}

class BiometricSettingsData {
  final bool biometricUnlockEnabled;
  final bool biometricSensitiveScreensEnabled;
  final DateTime? lastBiometricUnlockAt;

  const BiometricSettingsData({
    required this.biometricUnlockEnabled,
    required this.biometricSensitiveScreensEnabled,
    required this.lastBiometricUnlockAt,
  });

  static const defaults = BiometricSettingsData(
    biometricUnlockEnabled: false,
    biometricSensitiveScreensEnabled: false,
    lastBiometricUnlockAt: null,
  );

  BiometricSettingsData copyWith({
    bool? biometricUnlockEnabled,
    bool? biometricSensitiveScreensEnabled,
    DateTime? lastBiometricUnlockAt,
    bool clearLastBiometricUnlockAt = false,
  }) {
    return BiometricSettingsData(
      biometricUnlockEnabled:
          biometricUnlockEnabled ?? this.biometricUnlockEnabled,
      biometricSensitiveScreensEnabled: biometricSensitiveScreensEnabled ??
          this.biometricSensitiveScreensEnabled,
      lastBiometricUnlockAt: clearLastBiometricUnlockAt
          ? null
          : (lastBiometricUnlockAt ?? this.lastBiometricUnlockAt),
    );
  }
}

class PrivacySettingsData {
  final bool aiFoodPhotoConsent;
  final int sharedReports;
  final int linkedProfessionals;
  final PrivacyProtectionSettingsData protection;

  const PrivacySettingsData({
    required this.aiFoodPhotoConsent,
    required this.sharedReports,
    required this.linkedProfessionals,
    required this.protection,
  });
}

class DataExportStatus {
  final DateTime? lastSyncAt;
  final int pendingMutations;

  const DataExportStatus({
    required this.lastSyncAt,
    required this.pendingMutations,
  });
}

class SettingsRepository {
  final SupabaseClient? _client;

  SettingsRepository(this._client);

  User? get _user => _client?.auth.currentUser;

  Future<SettingsAccountData> loadAccountData() async {
    final client = _client;
    final user = _user;
    if (client == null || user == null) {
      throw Exception('Usuário não autenticado.');
    }

    final profileRows = await client
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .limit(1);
    final profile = profileRows.isNotEmpty
        ? Map<String, dynamic>.from(profileRows.first as Map)
        : <String, dynamic>{};

    final prefRow = await _loadCurrentUserPreferencesRow(user.id);
    final prefsData = _readPrefsData(prefRow);
    final onboarding = _asMap(prefsData['onboarding']);

    final rawName = (profile['display_name'] ?? profile['full_name'] ?? user.userMetadata?['display_name'])?.toString();
    final normalizedName = (rawName == null || rawName.trim().isEmpty)
        ? (user.email?.split('@').first ?? 'Usuário HAMVIT')
        : rawName.trim();

    final profileCreated = _parseDate(profile['created_at']?.toString());
    final userCreated = _parseDate(user.createdAt);

    final isPremium =
        (profile['premium_active'] == true) || profile['plan']?.toString() == 'premium_lifetime';

    return SettingsAccountData(
      userId: user.id,
      name: normalizedName,
      email: user.email ?? '-',
      planLabel: isPremium ? 'Premium Vitalício' : 'Free',
      createdAt: profileCreated ?? userCreated,
      objective: onboarding['objective']?.toString(),
    );
  }

  Future<void> updateDisplayName(String newName) async {
    final client = _client;
    final user = _user;
    if (client == null || user == null) throw Exception('Usuário não autenticado.');

    await client.from('profiles').update({
      'display_name': newName,
      'full_name': newName,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', user.id);
  }

  Future<void> sendPasswordRecoveryLink() async {
    final client = _client;
    final user = _user;
    if (client == null || user?.email == null) throw Exception('E-mail de recuperação indisponível.');
    await client.auth.resetPasswordForEmail(user!.email!);
  }

  Future<void> updatePassword(String newPassword) async {
    final client = _client;
    if (client == null) throw Exception('Supabase indisponível.');
    await client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> signOutCurrentDevice() async {
    final client = _client;
    if (client == null) return;
    await client.auth.signOut();
  }

  Future<void> signOutAllDevices() async {
    final client = _client;
    if (client == null) return;
    await client.auth.signOut();
  }

  Future<NotificationSettingsData> loadNotificationSettings() async {
    final client = _client;
    final user = _user;
    if (client == null || user == null) throw Exception('Usuário não autenticado.');

    final defaults = _defaultNotificationCategories();

    try {
      final rows = await client
          .from('notification_preferences')
          .select('*')
          .eq('user_id', user.id);

      if (rows.isEmpty) {
        return NotificationSettingsData(enabled: true, categories: defaults);
      }

      final mapped = Map<String, NotificationPreference>.from(defaults);
      var generalEnabled = true;

      for (final row in rows) {
        final map = Map<String, dynamic>.from(row as Map);
        if (map.containsKey('data') && map['data'] is Map) {
          final data = Map<String, dynamic>.from(map['data'] as Map);
          generalEnabled = _asBool(data['enabled'], fallback: generalEnabled);
          final categories = _asMap(data['categories']);
          categories.forEach((key, value) {
            final entry = _asMap(value);
            mapped[key] = NotificationPreference(
              category: key,
              enabled: _asBool(entry['enabled'], fallback: mapped[key]?.enabled ?? true),
              reminderTime: _parseTime(entry['reminder_time']?.toString()),
            );
          });
          continue;
        }

        final category = map['category']?.toString();
        if (category == null || category.isEmpty) continue;
        mapped[category] = NotificationPreference(
          category: category,
          enabled: _asBool(map['enabled'], fallback: true),
          reminderTime: _parseTime(map['reminder_time']?.toString()),
        );
      }

      return NotificationSettingsData(enabled: generalEnabled, categories: mapped);
    } catch (_) {
      return NotificationSettingsData(enabled: true, categories: defaults);
    }
  }

  Future<void> saveNotificationSettings(NotificationSettingsData data) async {
    final client = _client;
    final user = _user;
    if (client == null || user == null) throw Exception('Usuário não autenticado.');

    final nowIso = DateTime.now().toIso8601String();

    // Caminho preferencial: formato estruturado por categoria/canal.
    try {
      await _saveNotificationSettingsStructured(
        userId: user.id,
        data: data,
        nowIso: nowIso,
      );
      return;
    } catch (_) {
      // Fallback para ambientes sem índice único de upsert ou com schema parcial.
    }

    try {
      await _saveNotificationSettingsLegacyTable(
        userId: user.id,
        data: data,
      );
      return;
    } catch (_) {
      // Fallback final: persistir no user_preferences.data para não perder preferência.
    }

    await _saveNotificationSettingsInUserPreferences(user.id, data, nowIso);
  }

  Future<void> _saveNotificationSettingsStructured({
    required String userId,
    required NotificationSettingsData data,
    required String nowIso,
  }) async {
    final client = _client;
    if (client == null) throw Exception('Supabase indisponível.');

    for (final entry in data.categories.entries) {
      final category = entry.key;
      final payload = {
        'enabled': data.enabled && entry.value.enabled,
        'reminder_time': _formatTime(entry.value.reminderTime),
        'updated_at': nowIso,
      };

      final updated = await client
          .from('notification_preferences')
          .update(payload)
          .eq('user_id', userId)
          .eq('category', category)
          .eq('channel', 'push')
          .select('id')
          .limit(1);

      if (updated.isNotEmpty) continue;

      await client.from('notification_preferences').insert({
        'user_id': userId,
        'category': category,
        'channel': 'push',
        ...payload,
      });
    }
  }

  Future<void> _saveNotificationSettingsLegacyTable({
    required String userId,
    required NotificationSettingsData data,
  }) async {
    final client = _client;
    if (client == null) throw Exception('Supabase indisponível.');

    final row = await _loadCurrentNotificationPreferencesRow(userId);
    final payload = {
      'enabled': data.enabled,
      'categories': {
        for (final entry in data.categories.entries)
          entry.key: {
            'enabled': entry.value.enabled,
            'reminder_time': _formatTime(entry.value.reminderTime),
          }
      }
    };

    if (row != null) {
      await client.from('notification_preferences').update({'data': payload}).eq('id', row['id']);
    } else {
      await client.from('notification_preferences').insert({'user_id': userId, 'data': payload});
    }
  }

  Future<void> _saveNotificationSettingsInUserPreferences(
    String userId,
    NotificationSettingsData data,
    String nowIso,
  ) async {
    final client = _client;
    if (client == null) throw Exception('Supabase indisponível.');

    final current = await _loadCurrentUserPreferencesRow(userId);
    final prefs = _readPrefsData(current);
    prefs['notifications'] = {
      'enabled': data.enabled,
      'updated_at': nowIso,
      'categories': {
        for (final entry in data.categories.entries)
          entry.key: {
            'enabled': entry.value.enabled,
            'reminder_time': _formatTime(entry.value.reminderTime),
          }
      }
    };

    if (current != null) {
      await client.from('user_preferences').update({'data': prefs}).eq('id', current['id']);
    } else {
      await client.from('user_preferences').insert({'user_id': userId, 'data': prefs});
    }
  }

  Future<PrivacySettingsData> loadPrivacySettings() async {
    final client = _client;
    final user = _user;
    if (client == null || user == null) throw Exception('Usuário não autenticado.');

    var consentAccepted = true;
    try {
      final rows = await client
          .from('user_consents')
          .select('*')
          .eq('user_id', user.id)
          .eq('consent_key', 'ai_food_photo')
          .order('created_at', ascending: false)
          .limit(1);
      if (rows.isNotEmpty) {
        final row = Map<String, dynamic>.from(rows.first as Map);
        consentAccepted = _asBool(row['accepted'], fallback: true);
      }
    } catch (_) {
      final prefRow = await _loadCurrentUserPreferencesRow(user.id);
      final data = _readPrefsData(prefRow);
      final privacy = _asMap(data['privacy']);
      consentAccepted = _asBool(privacy['ai_food_photo'], fallback: true);
    }

    int sharedReports = 0;
    int linkedProfessionals = 0;

    try {
      final reports = await client
          .from('report_shares')
          .select('id')
          .limit(200);
      sharedReports = reports.length;
    } catch (_) {
      sharedReports = 0;
    }

    try {
      final links = await client
          .from('patient_professional_links')
          .select('id')
          .eq('user_id', user.id);
      linkedProfessionals = links.length;
    } catch (_) {
      linkedProfessionals = 0;
    }

    final protection = await loadPrivacyProtectionSettings();

    return PrivacySettingsData(
      aiFoodPhotoConsent: consentAccepted,
      sharedReports: sharedReports,
      linkedProfessionals: linkedProfessionals,
      protection: protection,
    );
  }

  Future<PrivacyProtectionSettingsData> loadPrivacyProtectionSettings() async {
    final user = _user;
    if (user == null) throw Exception('Usuário não autenticado.');

    final current = await _loadCurrentUserPreferencesRow(user.id);
    if (current == null) return PrivacyProtectionSettingsData.defaults;

    final data = _readPrefsData(current);
    final privacyProtection = _asMap(data['privacy_protection']);

    final screenshotProtectionEnabled = _asNullableBool(
          current['screenshot_protection_enabled'],
        ) ??
        _asBool(
          privacyProtection['screenshot_protection_enabled'],
          fallback: PrivacyProtectionSettingsData.defaults
              .screenshotProtectionEnabled,
        );

    final hideRecentAppsPreview = _asNullableBool(
          current['hide_recent_apps_preview'],
        ) ??
        _asBool(
          privacyProtection['hide_recent_apps_preview'],
          fallback:
              PrivacyProtectionSettingsData.defaults.hideRecentAppsPreview,
        );

    final appBlurEnabled = _asNullableBool(current['app_blur_enabled']) ??
        _asBool(
          privacyProtection['app_blur_enabled'],
          fallback: PrivacyProtectionSettingsData.defaults.appBlurEnabled,
        );

    return PrivacyProtectionSettingsData(
      screenshotProtectionEnabled: screenshotProtectionEnabled,
      hideRecentAppsPreview: hideRecentAppsPreview,
      appBlurEnabled: appBlurEnabled,
    );
  }

  Future<void> savePrivacyProtectionSettings(
    PrivacyProtectionSettingsData settings,
  ) async {
    final client = _client;
    final user = _user;
    if (client == null || user == null) throw Exception('Usuário não autenticado.');

    final current = await _loadCurrentUserPreferencesRow(user.id);
    final data = _readPrefsData(current);
    data['privacy_protection'] = {
      'screenshot_protection_enabled': settings.screenshotProtectionEnabled,
      'hide_recent_apps_preview': settings.hideRecentAppsPreview,
      'app_blur_enabled': settings.appBlurEnabled,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final rowPayload = {
      'data': data,
      'screenshot_protection_enabled': settings.screenshotProtectionEnabled,
      'hide_recent_apps_preview': settings.hideRecentAppsPreview,
      'app_blur_enabled': settings.appBlurEnabled,
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      if (current != null) {
        await client.from('user_preferences').update(rowPayload).eq('id', current['id']);
      } else {
        await client.from('user_preferences').insert({
          'user_id': user.id,
          ...rowPayload,
        });
      }
      return;
    } catch (_) {
      // Fallback para ambientes sem novas colunas aplicadas.
    }

    if (current != null) {
      await client.from('user_preferences').update({'data': data}).eq('id', current['id']);
    } else {
      await client.from('user_preferences').insert({
        'user_id': user.id,
        'data': data,
      });
    }
  }

  Future<BiometricSettingsData> loadBiometricSettings() async {
    final user = _user;
    if (user == null) throw Exception('Usuário não autenticado.');

    final current = await _loadCurrentUserPreferencesRow(user.id);
    if (current == null) return BiometricSettingsData.defaults;

    final data = _readPrefsData(current);
    final security = _asMap(data['security']);
    final biometric = _asMap(security['biometric']);

    final unlockEnabled = _asNullableBool(current['biometric_unlock_enabled']) ??
        _asBool(
          biometric['biometric_unlock_enabled'],
          fallback: BiometricSettingsData.defaults.biometricUnlockEnabled,
        );

    final sensitiveEnabled =
        _asNullableBool(current['biometric_sensitive_screens_enabled']) ??
            _asBool(
              biometric['biometric_sensitive_screens_enabled'],
              fallback:
                  BiometricSettingsData.defaults.biometricSensitiveScreensEnabled,
            );

    final lastUnlockMillis = _asNullableInt(current['last_biometric_unlock_at']);
    DateTime? lastUnlock;
    if (lastUnlockMillis != null && lastUnlockMillis > 0) {
      lastUnlock =
          DateTime.fromMillisecondsSinceEpoch(lastUnlockMillis, isUtc: true)
              .toLocal();
    } else {
      final iso = biometric['last_biometric_unlock_at']?.toString();
      lastUnlock = _parseDate(iso);
    }

    return BiometricSettingsData(
      biometricUnlockEnabled: unlockEnabled,
      biometricSensitiveScreensEnabled: sensitiveEnabled,
      lastBiometricUnlockAt: lastUnlock,
    );
  }

  Future<void> saveBiometricSettings(BiometricSettingsData settings) async {
    final client = _client;
    final user = _user;
    if (client == null || user == null) throw Exception('Usuário não autenticado.');

    final nowIso = DateTime.now().toIso8601String();
    final current = await _loadCurrentUserPreferencesRow(user.id);
    final data = _readPrefsData(current);
    final security = _asMap(data['security']);
    final biometric = _asMap(security['biometric']);

    biometric['biometric_unlock_enabled'] = settings.biometricUnlockEnabled;
    biometric['biometric_sensitive_screens_enabled'] =
        settings.biometricSensitiveScreensEnabled;
    biometric['last_biometric_unlock_at'] =
        settings.lastBiometricUnlockAt?.toUtc().toIso8601String();
    biometric['updated_at'] = nowIso;
    security['biometric'] = biometric;
    data['security'] = security;

    final rowPayload = {
      'data': data,
      'biometric_unlock_enabled': settings.biometricUnlockEnabled,
      'biometric_sensitive_screens_enabled':
          settings.biometricSensitiveScreensEnabled,
      'last_biometric_unlock_at':
          settings.lastBiometricUnlockAt?.toUtc().millisecondsSinceEpoch,
      'updated_at': nowIso,
    };

    try {
      if (current != null) {
        await client
            .from('user_preferences')
            .update(rowPayload)
            .eq('id', current['id']);
      } else {
        await client.from('user_preferences').insert({
          'user_id': user.id,
          ...rowPayload,
        });
      }
      return;
    } catch (_) {
      // Fallback para ambientes sem novas colunas aplicadas.
    }

    if (current != null) {
      await client.from('user_preferences').update({'data': data}).eq('id', current['id']);
    } else {
      await client.from('user_preferences').insert({
        'user_id': user.id,
        'data': data,
      });
    }
  }

  Future<void> setAiFoodPhotoConsent(bool accepted) async {
    final client = _client;
    final user = _user;
    if (client == null || user == null) throw Exception('Usuário não autenticado.');

    try {
      await client.from('user_consents').upsert({
        'user_id': user.id,
        'consent_key': 'ai_food_photo',
        'accepted': accepted,
        'accepted_at': accepted ? DateTime.now().toIso8601String() : null,
        'revoked_at': accepted ? null : DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,consent_key');
    } catch (_) {
      // keep fallback in preferences json
    }

    final current = await _loadCurrentUserPreferencesRow(user.id);
    final data = _readPrefsData(current);
    final privacy = _asMap(data['privacy']);
    privacy['ai_food_photo'] = accepted;
    data['privacy'] = privacy;

    if (current != null) {
      await client.from('user_preferences').update({'data': data}).eq('id', current['id']);
    } else {
      await client.from('user_preferences').insert({'user_id': user.id, 'data': data});
    }
  }

  Future<void> revokeProfessionalLinks() async {
    final client = _client;
    final user = _user;
    if (client == null || user == null) throw Exception('Usuário não autenticado.');
    await client.from('patient_professional_links').delete().eq('user_id', user.id);
  }

  Future<AccessibilitySettingsData> loadAccessibilitySettings() async {
    final user = _user;
    if (user == null) throw Exception('Usuário não autenticado.');

    final current = await _loadCurrentUserPreferencesRow(user.id);
    final data = _readPrefsData(current);
    final accessibility = _asMap(data['accessibility']);

    return AccessibilitySettingsData(
      textSize: (accessibility['text_size'] ?? 'padrao').toString(),
      highContrast: _asBool(accessibility['high_contrast'], fallback: false),
      reduceMotion: _asBool(accessibility['reduce_motion'], fallback: false),
      simpleMode: _asBool(accessibility['simple_mode'], fallback: false),
      largerButtons: _asBool(accessibility['larger_buttons'], fallback: false),
      simplifiedLanguage: _asBool(accessibility['simplified_language'], fallback: false),
    );
  }

  Future<void> saveAccessibilitySettings(AccessibilitySettingsData settings) async {
    final client = _client;
    final user = _user;
    if (client == null || user == null) throw Exception('Usuário não autenticado.');

    final current = await _loadCurrentUserPreferencesRow(user.id);
    final data = _readPrefsData(current);
    data['accessibility'] = {
      'text_size': settings.textSize,
      'high_contrast': settings.highContrast,
      'reduce_motion': settings.reduceMotion,
      'simple_mode': settings.simpleMode,
      'larger_buttons': settings.largerButtons,
      'simplified_language': settings.simplifiedLanguage,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (current != null) {
      await client.from('user_preferences').update({
        'data': data,
        'text_size': settings.textSize,
        'high_contrast': settings.highContrast,
        'reduce_motion': settings.reduceMotion,
        'simple_mode': settings.simpleMode,
        'larger_buttons': settings.largerButtons,
        'simplified_language': settings.simplifiedLanguage,
      }).eq('id', current['id']);
    } else {
      await client.from('user_preferences').insert({
        'user_id': user.id,
        'data': data,
        'text_size': settings.textSize,
        'high_contrast': settings.highContrast,
        'reduce_motion': settings.reduceMotion,
        'simple_mode': settings.simpleMode,
        'larger_buttons': settings.largerButtons,
        'simplified_language': settings.simplifiedLanguage,
      });
    }
  }

  Future<DataExportStatus> loadDataExportStatus() async {
    final client = _client;
    final user = _user;
    if (client == null || user == null) throw Exception('Usuário não autenticado.');

    DateTime? lastSyncAt;
    int pending = 0;

    try {
      final rows = await client
          .from('client_mutations')
          .select('sync_status, updated_at')
          .eq('user_id', user.id)
          .order('updated_at', ascending: false)
          .limit(200);
      pending = rows.where((row) {
        final map = Map<String, dynamic>.from(row as Map);
        final status = map['sync_status']?.toString();
        return status == 'pending' || status == 'failed' || status == 'conflict';
      }).length;
      if (rows.isNotEmpty) {
        final newest = Map<String, dynamic>.from(rows.first as Map);
        lastSyncAt = _parseDate(newest['updated_at']?.toString());
      }
    } catch (_) {
      pending = 0;
    }

    return DataExportStatus(lastSyncAt: lastSyncAt, pendingMutations: pending);
  }

  Future<void> requestDataExport(String requestType) async {
    final client = _client;
    final user = _user;
    if (client == null || user == null) throw Exception('Usuário não autenticado.');

    await client.from('data_export_requests').insert({
      'user_id': user.id,
      'request_type': requestType,
      'status': 'requested',
      'requested_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> requestAccountDeletion({String? reason}) async {
    final client = _client;
    final user = _user;
    if (client == null || user == null) throw Exception('Usuário não autenticado.');

    await client.from('account_deletion_requests').insert({
      'user_id': user.id,
      'status': 'requested',
      'reason': reason,
      'requested_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> loadGeneratedReports() async {
    final client = _client;
    final user = _user;
    if (client == null || user == null) return const [];

    try {
      final rows = await client
          .from('generated_reports')
          .select('id, format, created_at, storage_path')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(10);
      return List<Map<String, dynamic>>.from(rows.map((row) => Map<String, dynamic>.from(row as Map)));
    } catch (_) {
      return const [];
    }
  }

  Future<void> logAudit(String action, Map<String, dynamic> payload) async {
    final client = _client;
    final user = _user;
    if (client == null || user == null) return;

    try {
      await client.from('audit_logs').insert({
        'actor_user_id': user.id,
        'action': action,
        'payload': payload,
      });
    } catch (_) {
      // audit should never block primary actions.
    }
  }

  Map<String, NotificationPreference> _defaultNotificationCategories() {
    return {
      'agua': const NotificationPreference(category: 'agua', enabled: true, reminderTime: TimeOfDay(hour: 9, minute: 0)),
      'refeicoes': const NotificationPreference(category: 'refeicoes', enabled: true, reminderTime: TimeOfDay(hour: 12, minute: 0)),
      'habitos': const NotificationPreference(category: 'habitos', enabled: true),
      'treino_caminhada': const NotificationPreference(category: 'treino_caminhada', enabled: true, reminderTime: TimeOfDay(hour: 18, minute: 0)),
      'sono': const NotificationPreference(category: 'sono', enabled: true, reminderTime: TimeOfDay(hour: 22, minute: 0)),
      'relatorios': const NotificationPreference(category: 'relatorios', enabled: true),
      'premium_pagamentos': const NotificationPreference(category: 'premium_pagamentos', enabled: true),
      'ia_pendente': const NotificationPreference(category: 'ia_pendente', enabled: true),
    };
  }

  Future<Map<String, dynamic>?> _loadCurrentNotificationPreferencesRow(String uid) async {
    final client = _client;
    if (client == null) return null;

    final rows = await client
        .from('notification_preferences')
        .select('*')
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(1);

    if (rows.isEmpty) return null;
    return Map<String, dynamic>.from(rows.first as Map);
  }

  Future<Map<String, dynamic>?> _loadCurrentUserPreferencesRow(String uid) async {
    final client = _client;
    if (client == null) return null;

    final rows = await client
        .from('user_preferences')
        .select('*')
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(1);

    if (rows.isEmpty) return null;
    return Map<String, dynamic>.from(rows.first as Map);
  }

  Map<String, dynamic> _readPrefsData(Map<String, dynamic>? row) {
    final data = row?['data'];
    if (data is Map<String, dynamic>) return Map<String, dynamic>.from(data);
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  bool _asBool(dynamic value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }
    return fallback;
  }

  bool? _asNullableBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }
    return null;
  }

  int? _asNullableInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value);
  }

  TimeOfDay? _parseTime(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String? _formatTime(TimeOfDay? time) {
    if (time == null) return null;
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
