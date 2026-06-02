import 'dart:async';
import 'dart:math';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/activity_refresh_provider.dart';
import 'providers/activity_live_provider.dart';

import '../../shared/widgets/hamvit_module_widgets.dart';
import '../../shared/widgets/hamvit_onboarding_widgets.dart';
import '../dashboard/domain/dashboard_metrics_service.dart';
import '../home/providers/home_dashboard_provider.dart';
import '../onboarding/providers/onboarding_profile_provider.dart';
import '../reports/report_controller.dart';
import 'activity_detail_screen.dart';
import 'activity_repository.dart';
import 'activity_tracking_engine.dart';
import 'activity_type_selector.dart';
import 'calorie_estimation_service.dart';
import 'indoor_activity_screen.dart';
import 'outdoor_activity_tracking_screen.dart';
import 'treadmill_activity_screen.dart';

class ActivitiesPage extends ConsumerStatefulWidget {
  const ActivitiesPage({super.key});

  @override
  ConsumerState<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends ConsumerState<ActivitiesPage> {
  static const _pendingActivitySessionsKey = 'hamvit_pending_activity_sessions_v1';
  static const _liveActivitySessionKey = 'hamvit_live_activity_session_v1';
  static const _options = <ActivityTypeOption>[
    ActivityTypeOption(
      id: 'caminhada_outdoor',
      label: 'Caminhada outdoor',
      environment: ActivityEnvironment.outdoor,
      trackingMode: ActivityTrackingMode.gps,
      icon: Icons.directions_walk,
    ),
    ActivityTypeOption(
      id: 'corrida_outdoor',
      label: 'Corrida outdoor',
      environment: ActivityEnvironment.outdoor,
      trackingMode: ActivityTrackingMode.gps,
      icon: Icons.directions_run,
    ),
    ActivityTypeOption(
      id: 'caminhada_indoor',
      label: 'Caminhada indoor',
      environment: ActivityEnvironment.indoor,
      trackingMode: ActivityTrackingMode.manual,
      icon: Icons.directions_walk,
    ),
    ActivityTypeOption(
      id: 'corrida_indoor',
      label: 'Corrida indoor',
      environment: ActivityEnvironment.indoor,
      trackingMode: ActivityTrackingMode.manual,
      icon: Icons.directions_run,
    ),
    ActivityTypeOption(
      id: 'esteira',
      label: 'Esteira',
      environment: ActivityEnvironment.indoor,
      trackingMode: ActivityTrackingMode.manual,
      icon: Icons.fitness_center,
    ),
    ActivityTypeOption(
      id: 'bicicleta_ergometrica',
      label: 'Bicicleta ergometrica',
      environment: ActivityEnvironment.indoor,
      trackingMode: ActivityTrackingMode.manual,
      icon: Icons.pedal_bike,
    ),
  ];

  StreamSubscription<Position>? _sub;
  Timer? _clockTicker;
  int _lastDashboardInvalidateAt = 0;
  final List<Position> _points = [];
  List<_ActivityHistoryEntry> _history = const [];

  bool _running = false;
  bool _paused = false;
  DateTime? _startedAt;
  DateTime? _endedAt;
  ActivityTypeOption _currentType = _options.first;
  String? _sessionId;

  double _distanceM = 0;
  double _manualSpeedKmh = 6.0;
  double _manualDistanceM = 0;

  int _weekActiveMinBase = 0;
  double _weekDistanceKmBase = 0;
  double _weekCaloriesBase = 0;
  ActivityRepository get _activityRepository =>
      ActivityRepository(Supabase.instance.client);

  Duration get _elapsed {
    final start = _startedAt;
    if (start == null) return Duration.zero;
    final end = _endedAt ?? DateTime.now();
    return end.difference(start);
  }

  int get _elapsedSeconds => max(0, _elapsed.inSeconds);

  bool get _isIndoor => _currentType.environment == ActivityEnvironment.indoor;
  bool get _isTreadmill => _currentType.id == 'esteira';

  int _minutesFromSeconds(int seconds) {
    if (seconds <= 0) return 0;
    return max(1, (seconds / 60).ceil());
  }

  String _capitalize(String v) =>
      v.isEmpty ? v : '${v[0].toUpperCase()}${v.substring(1)}';

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.round();
    if (value is String) {
      final parsed = double.tryParse(value.replaceAll(',', '.').trim());
      return parsed?.round() ?? 0;
    }
    return 0;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value.replaceAll(',', '.').trim());
      return parsed ?? 0;
    }
    return 0;
  }

  double _currentDistanceMeters() {
    if (_isIndoor) {
      final estimated = ActivityTrackingEngine.manualDistanceMeters(
        speedKmh: _manualSpeedKmh,
        durationSeconds: _elapsedSeconds,
      );
      return _manualDistanceM > 0 ? _manualDistanceM : estimated;
    }
    return _distanceM;
  }

  double _currentSpeedKmh() {
    if (_isIndoor) {
      if (_manualDistanceM > 0 && _elapsedSeconds > 0) {
        return ActivityTrackingEngine.averageSpeedKmh(
          distanceMeters: _manualDistanceM,
          durationSeconds: _elapsedSeconds,
        );
      }
      return _manualSpeedKmh;
    }
    final distance = _currentDistanceMeters();
    if (_elapsedSeconds <= 0 || distance <= 0) return 0;
    return ActivityTrackingEngine.averageSpeedKmh(
      distanceMeters: distance,
      durationSeconds: _elapsedSeconds,
    );
  }

  int _currentPaceSeconds() {
    final distance = _currentDistanceMeters();
    if (_elapsedSeconds <= 0 || distance <= 0) return 0;
    return ActivityTrackingEngine.averagePaceSeconds(
      distanceMeters: distance,
      durationSeconds: _elapsedSeconds,
    );
  }

  String _paceLabel(int paceSeconds) {
    if (paceSeconds <= 0) return '--';
    final m = (paceSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (paceSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s /km';
  }

  double _metForCurrentType() {
    return CalorieEstimationService.metForIndoor(
      activityType: _currentType.id,
      speedKmh: _currentSpeedKmh(),
    );
  }

  double _estimatedCalories(double weightKg) {
    return CalorieEstimationService.estimateCalories(
      met: _metForCurrentType(),
      weightKg: weightKg,
      durationSeconds: _elapsedSeconds,
    );
  }

  Future<void> _loadWeeklyFromDb() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;
    await _flushPendingActivitySessions();

    final since = DateTime.now().subtract(const Duration(days: 7));

    List<dynamic> rows;
    try {
      rows = await client
          .from('activity_sessions')
          .select(
              'id, activity_type, activity_environment, tracking_mode, started_at, finished_at, ended_at, duration_seconds, distance_meters, distance_m, manual_distance_meters, estimated_calories_kcal, average_pace_seconds, route_summary_json')
          .eq('user_id', user.id)
          .gte('started_at', since.toIso8601String())
          .order('started_at', ascending: false)
          .limit(50);
    } catch (_) {
      try {
        rows = await client
            .from('activity_sessions')
            .select('id, activity_type, started_at, ended_at, distance_m, route_summary_json')
            .eq('user_id', user.id)
            .gte('started_at', since.toIso8601String())
            .order('started_at', ascending: false)
            .limit(50);
      } catch (_) {
        // fallback maximo: evita "sumir" com historico quando houver
        // diferenca de schema entre ambientes.
        rows = await client
            .from('activity_sessions')
            .select('id, activity_type, started_at, ended_at, distance_m')
            .eq('user_id', user.id)
            .gte('started_at', since.toIso8601String())
            .order('started_at', ascending: false)
            .limit(50);
      }
    }

    var totalMin = 0;
    var totalKm = 0.0;
    var totalCalories = 0.0;
    final history = <_ActivityHistoryEntry>[];

    for (final row in rows) {
      final startedAt = DateTime.tryParse((row['started_at'] ?? '').toString());
      final finishedAt = DateTime.tryParse(
          (row['finished_at'] ?? row['ended_at'] ?? '').toString());
      final durationSeconds = _toInt(row['duration_seconds']);
      final durationMin = durationSeconds > 0
          ? _minutesFromSeconds(durationSeconds)
          : (startedAt != null &&
                  finishedAt != null &&
                  finishedAt.isAfter(startedAt)
              ? _minutesFromSeconds(finishedAt.difference(startedAt).inSeconds)
              : 0);

      final distanceMeters = _toDouble(row['distance_meters']);
      final distanceMAlt = _toDouble(row['distance_m']);
      final distanceManual = _toDouble(row['manual_distance_meters']);
      final km = (distanceMeters > 0
              ? distanceMeters
              : distanceManual > 0
                  ? distanceManual
                  : distanceMAlt) /
          1000;

      totalMin += durationMin;
      totalKm += km;
      totalCalories += _toDouble(row['estimated_calories_kcal']);

      final type = _capitalize((row['activity_type'] ?? 'atividade').toString());
      final env = (row['activity_environment'] ?? '').toString().toLowerCase() ==
              'indoor'
          ? 'indoor'
          : 'outdoor';
      history.add(_ActivityHistoryEntry(
        sessionId: (row['id'] ?? '').toString(),
        type: type,
        environment: env,
        distanceKm: km,
        durationMin: durationMin,
        caloriesKcal: _toDouble(row['estimated_calories_kcal']).round(),
        paceLabel: _paceLabel(_toInt(row['average_pace_seconds'])),
        startedAt: startedAt,
        rawSession: Map<String, dynamic>.from(row as Map),
      ));
    }

    // Inclui itens pendentes locais para não "sumirem" da lista quando
    // a sincronização remota falha temporariamente.
    final prefs = await SharedPreferences.getInstance();
    final pendingRaw = prefs.getStringList(_pendingActivitySessionsKey) ?? const <String>[];
    for (final raw in pendingRaw) {
      try {
        final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        final startedAt = DateTime.tryParse((map['started_at'] ?? '').toString());
        if (startedAt == null || startedAt.isBefore(since)) continue;

        final durationSeconds = _toInt(map['duration_seconds']);
        final distanceMeters = _toDouble(map['distance_meters']);
        final manualDistance = _toDouble(map['manual_distance_meters']);
        final km = (distanceMeters > 0 ? distanceMeters : manualDistance) / 1000;
        final pace = _toInt(map['average_pace_seconds']);
        final type = _capitalize((map['activity_type'] ?? 'atividade').toString());
        final env = (map['activity_environment'] ?? '').toString().toLowerCase() == 'indoor'
            ? 'indoor'
            : 'outdoor';

        history.add(_ActivityHistoryEntry(
          sessionId: 'pending_${startedAt.millisecondsSinceEpoch}',
          type: type,
          environment: env,
          distanceKm: km,
          durationMin: _minutesFromSeconds(durationSeconds),
          caloriesKcal: _toDouble(map['estimated_calories_kcal']).round(),
          paceLabel: _paceLabel(pace),
          startedAt: startedAt,
          rawSession: map,
        ));
      } catch (_) {}
    }

    history.sort((a, b) {
      final ad = a.startedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = b.startedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });

    final visibleHistory = history.take(7).toList(growable: false);
    // Garante consistencia entre cards semanais e lista exibida.
    final visibleMin = visibleHistory.fold<int>(0, (acc, e) => acc + e.durationMin);
    final visibleKm = visibleHistory.fold<double>(0.0, (acc, e) => acc + e.distanceKm);
    final visibleKcal =
        visibleHistory.fold<double>(0.0, (acc, e) => acc + e.caloriesKcal.toDouble());

    if (!mounted) return;
    setState(() {
      _weekActiveMinBase = visibleMin;
      _weekDistanceKmBase = visibleKm;
      _weekCaloriesBase = visibleKcal;
      _history = visibleHistory;
    });
    debugPrint('ActivitiesPage: history refreshed with ${_history.length} items');
  }

  Future<void> _start(ActivityTypeOption type) async {
    debugPrint('ActivitiesPage: atividade iniciada ${type.id}');
    if (type.environment == ActivityEnvironment.outdoor) {
      await _startOutdoorFlow(type);
      return;
    }

    final now = DateTime.now();
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    _sessionId = null;
    await _clearLiveSessionState();
    if (user != null) {
      try {
        final row = await client
            .from('activity_sessions')
            .insert({
              'user_id': user.id,
              'activity_type': type.id,
              'activity_environment':
                  type.environment == ActivityEnvironment.indoor
                      ? 'indoor'
                      : 'outdoor',
              'tracking_mode': type.trackingMode.name,
              'started_at': now.toIso8601String(),
              'created_at': now.toIso8601String(),
              if (type.environment == ActivityEnvironment.indoor)
                'manual_speed_kmh': _manualSpeedKmh,
            })
            .select('id')
            .single();
        _sessionId = row['id']?.toString();
      } catch (_) {}
    }

    _points.clear();
    _distanceM = 0;
    _manualDistanceM = 0;
    _startedAt = now;
    _endedAt = null;
    _running = true;
    _paused = false;
    _currentType = type;

    _sub?.cancel();
    if (type.environment == ActivityEnvironment.outdoor) {
      _sub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 5,
        ),
      ).listen((pos) {
        if (!_running || _paused) return;
        if (_points.isNotEmpty) {
          final prev = _points.last;
          _distanceM += Geolocator.distanceBetween(
              prev.latitude, prev.longitude, pos.latitude, pos.longitude);
        }
        setState(() => _points.add(pos));
      });
    }

    _clockTicker?.cancel();
    _clockTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_running || _paused) return;
      // Atualiza UI local
      setState(() {});
      if (_elapsedSeconds % 3 == 0) {
        _persistLiveSessionState();
      }
      // Incrementa o tick global para notificar outras telas (ex: Hoje)
      try {
        final elapsed = _elapsedSeconds;
        if (elapsed - _lastDashboardInvalidateAt >= 10) {
          _lastDashboardInvalidateAt = elapsed;
          // incrementa o provider global
          // debug print para verificar que o tick está sendo incrementado
          try {
            debugPrint('ActivitiesPage: incrementing activity tick at ${DateTime.now()}');
            ref.read(activityRefreshTickProvider.notifier).state++;
            // atualiza provider com dados em memoria para dashboard consumir
            try {
              final weightKg = ref.read(onboardingProfileProvider).weightKg ?? 70;
              final overlay = ActivityLiveData(
                distanceKm: _currentDistanceMeters() / 1000,
                activeMinutes: _minutesFromSeconds(_elapsedSeconds),
                caloriesKcal: _estimatedCalories(weightKg).round(),
              );
              ref.read(activityLiveStateProvider.notifier).state = overlay;
            } catch (e) {
              debugPrint('ActivitiesPage: failed to update live overlay: $e');
            }
          } catch (e) {
            debugPrint('ActivitiesPage: failed to increment tick: $e');
          }
        }
      } catch (_) {}
    });

    setState(() {});
  }

  Future<void> _startOutdoorFlow(ActivityTypeOption type) async {
    final result = await Navigator.of(context).push<OutdoorTrackingResult>(
      MaterialPageRoute(
        builder: (_) => OutdoorActivityTrackingScreen(title: type.label),
      ),
    );
    if (result == null) return;

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    final avgSpeed = ActivityTrackingEngine.averageSpeedKmh(
      distanceMeters: result.distanceMeters,
      durationSeconds: result.durationSeconds,
    );
    final avgPace = ActivityTrackingEngine.averagePaceSeconds(
      distanceMeters: result.distanceMeters,
      durationSeconds: result.durationSeconds,
    );
    final weightKg = ref.read(onboardingProfileProvider).weightKg ?? 70;
    final calories = CalorieEstimationService.estimateCalories(
      met: CalorieEstimationService.metForIndoor(
        activityType: type.id,
        speedKmh: avgSpeed,
      ),
      weightKg: weightKg,
      durationSeconds: result.durationSeconds,
    );

    final payload = <String, dynamic>{
      if (user != null) 'user_id': user.id,
      'activity_type': type.id,
      'activity_environment': 'outdoor',
      'tracking_mode': 'gps',
      'started_at': result.startedAt.toIso8601String(),
      'finished_at': result.finishedAt.toIso8601String(),
      'ended_at': result.finishedAt.toIso8601String(),
      'duration_seconds': result.durationSeconds,
      'distance_meters': result.distanceMeters,
      'distance_m': result.distanceMeters,
      'average_pace_seconds': avgPace,
      'average_speed_kmh': avgSpeed,
      'estimated_calories_kcal': calories,
      'created_at': result.startedAt.toIso8601String(),
      'route_summary_json': {
        'points_count': result.points.length,
        'points': result.points
            .take(600)
            .map((p) => {
                  'lat': p.latitude,
                  'lng': p.longitude,
                  'ts': p.recordedAt.toIso8601String(),
                })
            .toList(growable: false),
      },
    };

    var savedRemotely = false;
    try {
      final row = await client
          .from('activity_sessions')
          .insert(payload)
          .select('id')
          .single();
      final sessionId = row['id']?.toString();
      savedRemotely = true;
      if (sessionId != null && sessionId.isNotEmpty && user != null) {
        await _activityRepository.saveRoutePoints(
          sessionId: sessionId,
          userId: user.id,
          points: result.points,
        );
      }
    } catch (e) {
      debugPrint('ActivitiesPage: falha ao salvar outdoor remoto: $e');
      // Compatibilidade com bancos sem route_summary_json.
      try {
        final legacyPayload = Map<String, dynamic>.from(payload)
          ..remove('route_summary_json');
        final row = await client
            .from('activity_sessions')
            .insert(legacyPayload)
            .select('id')
            .single();
        final sessionId = row['id']?.toString();
        savedRemotely = true;
        if (sessionId != null && sessionId.isNotEmpty && user != null) {
          await _activityRepository.saveRoutePoints(
            sessionId: sessionId,
            userId: user.id,
            points: result.points,
          );
        }
      } catch (e2) {
        debugPrint('ActivitiesPage: falha fallback legado outdoor: $e2');
        await _queuePendingActivitySession(payload);
      }
    }

    // Atualizacao otimista: a atividade aparece na lista imediatamente,
    // mesmo se a sincronizacao remota estiver pendente.
    final localEntry = _ActivityHistoryEntry(
      sessionId: 'local_${DateTime.now().millisecondsSinceEpoch}',
      type: _capitalize(type.id),
      environment: 'outdoor',
      distanceKm: result.distanceMeters / 1000,
      durationMin: _minutesFromSeconds(result.durationSeconds),
      caloriesKcal: calories.round(),
      paceLabel: _paceLabel(avgPace),
      startedAt: result.startedAt,
      rawSession: Map<String, dynamic>.from(payload),
    );
    if (mounted) {
      setState(() {
        _history = [localEntry, ..._history].take(7).toList(growable: false);
        _weekActiveMinBase += _minutesFromSeconds(result.durationSeconds);
        _weekDistanceKmBase += result.distanceMeters / 1000;
        _weekCaloriesBase += calories;
      });
    }

    await _loadWeeklyFromDb();
    ref.read(activityRefreshTickProvider.notifier).state++;
    ref.invalidate(homeDashboardProvider);
    ref.invalidate(dashboardSnapshotProvider);
    ref.invalidate(evolutionReportProvider);
    ref.invalidate(reportHistoryProvider);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          savedRemotely
              ? 'Atividade salva com sucesso.'
              : 'Atividade salva localmente e sincronizando com a nuvem.',
        ),
      ),
    );
  }

  Future<void> _startActivityPicker() async {
    if (_running) return;
    final selected = await showModalBottomSheet<ActivityTypeOption>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: HamvitActivityModeSelector(
          options: _options,
          onSelected: (item) => Navigator.of(context).pop(item),
        ),
      ),
    );

    if (selected == null) return;
    await _start(selected);
  }

  void _pauseOrResume() {
    if (!_running) return;
    setState(() => _paused = !_paused);
    debugPrint('ActivitiesPage: atividade ${_paused ? 'pausada' : 'retomada'}');
  }

  Future<void> _queuePendingActivitySession(Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_pendingActivitySessionsKey) ?? <String>[];
    existing.add(jsonEncode(payload));
    await prefs.setStringList(_pendingActivitySessionsKey, existing);
    debugPrint('ActivitiesPage: payload salvo local/offline');
  }

  Future<void> _flushPendingActivitySessions() async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList(_pendingActivitySessionsKey) ?? <String>[];
    if (queue.isEmpty) return;
    final client = Supabase.instance.client;
    final pending = <String>[];
    for (final raw in queue) {
      try {
        final payload = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        await client.from('activity_sessions').insert(payload);
        debugPrint('ActivitiesPage: pending activity synced');
      } catch (_) {
        pending.add(raw);
      }
    }
    await prefs.setStringList(_pendingActivitySessionsKey, pending);
  }

  Future<void> _persistLiveSessionState() async {
    if (!_running || _startedAt == null) return;
    final prefs = await SharedPreferences.getInstance();
    final payload = <String, dynamic>{
      'running': _running,
      'paused': _paused,
      'startedAt': _startedAt!.toIso8601String(),
      'currentTypeId': _currentType.id,
      'sessionId': _sessionId,
      'distanceM': _distanceM,
      'manualDistanceM': _manualDistanceM,
      'manualSpeedKmh': _manualSpeedKmh,
      'points': _points
          .map((p) => {
                'lat': p.latitude,
                'lng': p.longitude,
              })
          .toList(growable: false),
    };
    await prefs.setString(_liveActivitySessionKey, jsonEncode(payload));
  }

  Future<void> _clearLiveSessionState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_liveActivitySessionKey);
  }

  Future<void> _restoreLiveSessionState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_liveActivitySessionKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final startedAt = DateTime.tryParse((map['startedAt'] ?? '').toString());
      if (startedAt == null || map['running'] != true) return;
      final typeId = (map['currentTypeId'] ?? '').toString();
      final matches = _options.where((e) => e.id == typeId);
      _currentType = matches.isNotEmpty ? matches.first : _currentType;
      _startedAt = startedAt;
      _endedAt = null;
      _running = true;
      _paused = map['paused'] == true;
      _sessionId = (map['sessionId'] ?? '').toString().isEmpty
          ? null
          : (map['sessionId'] ?? '').toString();
      _distanceM = _toDouble(map['distanceM']);
      _manualDistanceM = _toDouble(map['manualDistanceM']);
      _manualSpeedKmh = _toDouble(map['manualSpeedKmh']) > 0
          ? _toDouble(map['manualSpeedKmh'])
          : _manualSpeedKmh;

      _points.clear();

      _sub?.cancel();
      if (_currentType.environment == ActivityEnvironment.outdoor) {
        _sub = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 5,
          ),
        ).listen((pos) {
          if (!_running || _paused) return;
          if (_points.isNotEmpty) {
            final prev = _points.last;
            _distanceM += Geolocator.distanceBetween(
                prev.latitude, prev.longitude, pos.latitude, pos.longitude);
          }
          setState(() => _points.add(pos));
        });
      }

      _clockTicker?.cancel();
      _clockTicker = Timer.periodic(const Duration(seconds: 1), (_) async {
        if (!mounted || !_running || _paused) return;
        setState(() {});
        await _persistLiveSessionState();
      });
    } catch (_) {
      await _clearLiveSessionState();
    }
  }

  Future<void> _finish() async {
    if (!_running) return;
    debugPrint('ActivitiesPage: atividade finalizada');
    _endedAt = DateTime.now();
    _running = false;
    _paused = false;
    _clockTicker?.cancel();
    _clockTicker = null;
    await _sub?.cancel();
    _sub = null;

    double finalDistanceM = _currentDistanceMeters();
    double finalSpeedKmh = _currentSpeedKmh();

    if (_isIndoor) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => HamvitDistanceEditor(
          initialDistanceKm: finalDistanceM / 1000,
          initialSpeedKmh: finalSpeedKmh,
          onConfirm: (distanceKm, speedKmh) {
            finalDistanceM = distanceKm * 1000;
            finalSpeedKmh = speedKmh;
            _manualDistanceM = finalDistanceM;
            _manualSpeedKmh = finalSpeedKmh;
          },
        ),
      );
    }

    final durationSeconds = _elapsedSeconds;
    final paceSeconds = ActivityTrackingEngine.averagePaceSeconds(
      distanceMeters: finalDistanceM,
      durationSeconds: durationSeconds,
    );
    final avgSpeed = finalSpeedKmh > 0
        ? finalSpeedKmh
        : ActivityTrackingEngine.averageSpeedKmh(
            distanceMeters: finalDistanceM,
            durationSeconds: durationSeconds,
          );

    final weightKg = ref.read(onboardingProfileProvider).weightKg ?? 70;
    final calories = CalorieEstimationService.estimateCalories(
      met: CalorieEstimationService.metForIndoor(
        activityType: _currentType.id,
        speedKmh: avgSpeed,
      ),
      weightKg: weightKg,
      durationSeconds: durationSeconds,
    );

    final client = Supabase.instance.client;
    final sessionId = _sessionId;
    final user = client.auth.currentUser;

    final payload = <String, dynamic>{
      if (user != null) 'user_id': user.id,
      'activity_type': _currentType.id,
      'activity_environment': _isIndoor ? 'indoor' : 'outdoor',
      'tracking_mode': _isIndoor ? 'manual' : 'gps',
      'started_at': _startedAt?.toIso8601String(),
      'finished_at': _endedAt!.toIso8601String(),
      'duration_seconds': durationSeconds,
      'distance_meters': _isIndoor ? null : finalDistanceM,
      'manual_distance_meters': _isIndoor ? finalDistanceM : null,
      'manual_speed_kmh': _isIndoor ? finalSpeedKmh : null,
      'average_pace_seconds': paceSeconds,
      'average_speed_kmh': avgSpeed,
      'estimated_calories_kcal': calories,
      'created_at': _startedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
    debugPrint('ActivitiesPage: payload salvo => $payload');

    var persisted = false;
    if (sessionId != null) {
      try {
        await client.from('activity_sessions').update(payload).eq('id', sessionId);
        persisted = true;
        debugPrint('ActivitiesPage: update sessão ok');
      } catch (_) {
        debugPrint('ActivitiesPage: falha update sessão, tentando insert final');
      }
    }
    if (!persisted) {
      try {
        await client.from('activity_sessions').insert(payload);
        persisted = true;
        debugPrint('ActivitiesPage: insert sessão final ok');
      } catch (_) {
        debugPrint('ActivitiesPage: falha insert remoto, salvando offline');
      }
    }
    if (!persisted) {
      await _queuePendingActivitySession(payload);
    }

    _sessionId = null;
    await _clearLiveSessionState();
    // limpar overlay live
    try {
      ref.read(activityLiveStateProvider.notifier).state = null;
    } catch (_) {}
    await _loadWeeklyFromDb();
    ref.read(activityRefreshTickProvider.notifier).state++;
    ref.invalidate(homeDashboardProvider);
    ref.invalidate(dashboardSnapshotProvider);
    ref.invalidate(evolutionReportProvider);
    ref.invalidate(reportHistoryProvider);
    setState(() {});
    debugPrint('ActivitiesPage: providers invalidados apos finalizar');

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resumo da atividade'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipo: ${_currentType.label}'),
            Text('Duracao: ${_elapsed.inMinutes} min ${_elapsed.inSeconds % 60}s'),
            Text('Distancia: ${(finalDistanceM / 1000).toStringAsFixed(2)} km'),
            Text('Velocidade media: ${avgSpeed.toStringAsFixed(2)} km/h'),
            Text('Ritmo medio: ${_paceLabel(paceSeconds)}'),
            Text('Calorias estimadas: ${calories.toStringAsFixed(0)} kcal'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadWeeklyFromDb();
    _restoreLiveSessionState();
  }

  @override
  void dispose() {
    _persistLiveSessionState();
    _clockTicker?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = ref.watch(onboardingProfileProvider);
    final weightKg = onboarding.weightKg ?? 70;

    final currentDistanceKm = _currentDistanceMeters() / 1000;
    final currentActiveMin = _running ? _minutesFromSeconds(_elapsedSeconds) : 0;

    final weekDistanceKm = _weekDistanceKmBase + (_running ? currentDistanceKm : 0);
    final weekActiveMin = _weekActiveMinBase + currentActiveMin;
    final weekCalories = _weekCaloriesBase + (_running ? _estimatedCalories(weightKg) : 0);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (onboarding.needsActivitySoftGate) ...[
          HamvitSoftGateCard(
            title: 'Complete seus dados para estimativas mais precisas.',
            subtitle:
                'Consistencia vale mais que intensidade. Voce pode iniciar agora.',
            buttonLabel: 'Completar dados',
            onTap: () => context.push('/profile/body-data'),
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _running ? null : _startActivityPicker,
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Iniciar caminhada/corrida'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isIndoor)
          HamvitIndoorControls(
            speedKmh: _manualSpeedKmh,
            onSpeedChanged: (value) => setState(() {
              _manualSpeedKmh = value;
              if (_running) {
                _manualDistanceM = ActivityTrackingEngine.manualDistanceMeters(
                  speedKmh: _manualSpeedKmh,
                  durationSeconds: _elapsedSeconds,
                );
              }
            }),
          ),
        if (_isTreadmill)
          HamvitTreadmillSummaryCard(
            distanceKm: currentDistanceKm,
            speedKmh: _currentSpeedKmh(),
            caloriesKcal: _estimatedCalories(weightKg),
          ),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _running ? _pauseOrResume : null,
                icon: Icon(
                  _paused ? Icons.play_arrow : Icons.pause, 
                  size: 18,
                ),
                label: Text(_paused ? 'Retomar' : 'Pausar'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: _running ? _finish : null,
                icon: const Icon(Icons.flag, size: 18),
                label: const Text('Finalizar'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: HamvitMetricCard(
                label: 'Tempo ativo na semana',
                value: '$weekActiveMin min',
                icon: Icons.timer_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: HamvitMetricCard(
                label: 'Distancia da semana',
                value: '${weekDistanceKm.toStringAsFixed(1)} km',
                icon: Icons.map_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        HamvitMetricCard(
          label: 'Calorias estimadas',
          value: '${weekCalories.toStringAsFixed(0)} kcal',
          icon: Icons.local_fire_department_outlined,
          helper: 'Estimativa baseada em MET, duracao e perfil.',
        ),
        const SizedBox(height: 8),
        HamvitActivityMetrics(
          activityTypeLabel: _currentType.label,
          environmentLabel: _isIndoor ? 'indoor' : 'outdoor',
          durationSeconds: _elapsedSeconds,
          distanceKm: currentDistanceKm,
          speedKmh: _currentSpeedKmh(),
          caloriesKcal: _estimatedCalories(weightKg),
          paceLabel: _paceLabel(_currentPaceSeconds()),
        ),
        const SizedBox(height: 8),
        _ActivityHistoryCard(
          entries: _history,
          onTap: (entry) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ActivityDetailScreen(session: entry.rawSession),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ActivityHistoryEntry {
  final String sessionId;
  final String type;
  final String environment;
  final double distanceKm;
  final int durationMin;
  final int caloriesKcal;
  final String paceLabel;
  final DateTime? startedAt;
  final Map<String, dynamic> rawSession;

  const _ActivityHistoryEntry({
    required this.sessionId,
    required this.type,
    required this.environment,
    required this.distanceKm,
    required this.durationMin,
    required this.caloriesKcal,
    required this.paceLabel,
    required this.startedAt,
    required this.rawSession,
  });
}

class _ActivityHistoryCard extends StatelessWidget {
  final List<_ActivityHistoryEntry> entries;
  final ValueChanged<_ActivityHistoryEntry> onTap;
  const _ActivityHistoryCard({required this.entries, required this.onTap});

  @override
  Widget build(BuildContext context) {
    String groupOf(DateTime? startedAt) {
      if (startedAt == null) return 'Mais antigas';
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final day = DateTime(startedAt.year, startedAt.month, startedAt.day);
      final diff = today.difference(day).inDays;
      if (diff == 0) return 'Hoje';
      if (diff == 1) return 'Ontem';
      if (diff <= 6) return 'Esta semana';
      return 'Mais antigas';
    }

    String fmt(DateTime? value) {
      if (value == null) return '--';
      String two(int n) => n.toString().padLeft(2, '0');
      return '${two(value.day)}/${two(value.month)} ${two(value.hour)}:${two(value.minute)}';
    }

    final grouped = <String, List<_ActivityHistoryEntry>>{
      'Hoje': [],
      'Ontem': [],
      'Esta semana': [],
      'Mais antigas': [],
    };
    for (final item in entries) {
      grouped[groupOf(item.startedAt)]!.add(item);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.route_outlined, size: 18),
                const SizedBox(width: 6),
                Text('Historico de atividades', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            if (entries.isEmpty) const Text('Sem historico ainda.'),
            if (entries.isNotEmpty)
              for (final group in ['Hoje', 'Ontem', 'Esta semana', 'Mais antigas'])
                if (grouped[group]!.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 6),
                    child: Text(group, style: Theme.of(context).textTheme.titleSmall),
                  ),
                  for (final item in grouped[group]!)
                    InkWell(
                      onTap: () => onTap(item),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(item.environment == 'indoor' ? Icons.home_outlined : Icons.explore_outlined, size: 18),
                                const SizedBox(width: 6),
                                Expanded(child: Text('${item.type} • ${item.environment}', style: Theme.of(context).textTheme.titleSmall)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('${item.distanceKm.toStringAsFixed(2)} km • ${item.durationMin} min • ${item.caloriesKcal} kcal'),
                            Text('Ritmo: ${item.paceLabel} • ${fmt(item.startedAt)}', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      ),
                    ),
                ],
          ],
        ),
      ),
    );
  }
}
