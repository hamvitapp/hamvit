import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/activity_refresh_provider.dart';
import 'providers/activity_live_provider.dart';

import '../../shared/widgets/hamvit_module_widgets.dart';
import '../../shared/widgets/hamvit_onboarding_widgets.dart';
import '../home/providers/home_dashboard_provider.dart';
import '../onboarding/providers/onboarding_profile_provider.dart';
import 'activity_tracking_engine.dart';
import 'activity_type_selector.dart';
import 'calorie_estimation_service.dart';
import 'indoor_activity_screen.dart';
import 'treadmill_activity_screen.dart';

class ActivitiesPage extends ConsumerStatefulWidget {
  const ActivitiesPage({super.key});

  @override
  ConsumerState<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends ConsumerState<ActivitiesPage> {
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
  List<String> _history = const [];

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

    final since = DateTime.now().subtract(const Duration(days: 7));

    List<dynamic> rows;
    try {
      rows = await client
          .from('activity_sessions')
          .select(
              'id, activity_type, activity_environment, tracking_mode, started_at, finished_at, ended_at, duration_seconds, distance_meters, distance_m, manual_distance_meters, estimated_calories_kcal')
          .eq('user_id', user.id)
          .gte('started_at', since.toIso8601String())
          .order('started_at', ascending: false)
          .limit(50);
    } catch (_) {
      rows = await client
          .from('activity_sessions')
          .select('id, activity_type, started_at, ended_at, distance_m')
          .eq('user_id', user.id)
          .gte('started_at', since.toIso8601String())
          .order('started_at', ascending: false)
          .limit(50);
    }

    var totalMin = 0;
    var totalKm = 0.0;
    var totalCalories = 0.0;
    final history = <String>[];

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
      history.add(
          '$type ($env) - ${km.toStringAsFixed(2)} km - ${durationMin} min');
    }

    if (!mounted) return;
    setState(() {
      _weekActiveMinBase = totalMin;
      _weekDistanceKmBase = totalKm;
      _weekCaloriesBase = totalCalories;
      _history = history.take(7).toList(growable: false);
    });
  }

  Future<void> _start(ActivityTypeOption type) async {
    if (type.environment == ActivityEnvironment.outdoor) {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
    }

    final now = DateTime.now();
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    _sessionId = null;
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
  }

  Future<void> _finish() async {
    if (!_running) return;
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

    if (sessionId != null) {
      try {
        await client.from('activity_sessions').update({
          'finished_at': _endedAt!.toIso8601String(),
          'duration_seconds': durationSeconds,
          'distance_meters': _isIndoor ? null : finalDistanceM,
          'manual_distance_meters': _isIndoor ? finalDistanceM : null,
          'manual_speed_kmh': _isIndoor ? finalSpeedKmh : null,
          'average_pace_seconds': paceSeconds,
          'average_speed_kmh': avgSpeed,
          'estimated_calories_kcal': calories,
          'activity_environment': _isIndoor ? 'indoor' : 'outdoor',
          'tracking_mode': _isIndoor ? 'manual' : 'gps',
        }).eq('id', sessionId);
      } catch (_) {
        try {
          await client.from('activity_sessions').update({
            'ended_at': _endedAt!.toIso8601String(),
            'distance_m': finalDistanceM,
          }).eq('id', sessionId);
        } catch (_) {}
      }
    }

    _sessionId = null;
    // limpar overlay live
    try {
      ref.read(activityLiveStateProvider.notifier).state = null;
    } catch (_) {}
    await _loadWeeklyFromDb();
    ref.invalidate(homeDashboardProvider);
    setState(() {});

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
  }

  @override
  void dispose() {
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
        const HamvitSectionHeader(
          title: 'Atividade fisica',
          subtitle:
              'Outdoor com GPS e indoor por estimativa. Movimento tambem conta.',
        ),
        const SizedBox(height: 12),
        if (onboarding.needsActivitySoftGate) ...[
          HamvitSoftGateCard(
            title: 'Complete seus dados para estimativas mais precisas.',
            subtitle:
                'Consistencia vale mais que intensidade. Voce pode iniciar agora.',
            buttonLabel: 'Completar dados',
            onTap: () => context.go('/profile/body-data'),
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
        Card(
          child: ListTile(
            title: Text(_paused ? 'Retomar atividade' : 'Pausar atividade'),
            subtitle: const Text('Pausa/retoma o rastreio'),
            onTap: _running ? _pauseOrResume : null,
          ),
        ),
        Card(
          child: ListTile(
            title: const Text('Finalizar atividade'),
            subtitle: const Text('Finaliza e congela os totais'),
            onTap: _running ? _finish : null,
          ),
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
        HamvitHistoryCard(
          title: 'Historico de atividades',
          items: _history,
          icon: Icons.route_outlined,
        ),
      ],
    );
  }
}
