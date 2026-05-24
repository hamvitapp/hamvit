import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/widgets/hamvit_module_widgets.dart';
import '../../shared/widgets/hamvit_onboarding_widgets.dart';
import '../home/providers/home_dashboard_provider.dart';
import '../onboarding/providers/onboarding_profile_provider.dart';

class ActivitiesPage extends ConsumerStatefulWidget {
  const ActivitiesPage({super.key});

  @override
  ConsumerState<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends ConsumerState<ActivitiesPage> {
  StreamSubscription<Position>? _sub;
  Timer? _clockTicker;
  final List<Position> _points = [];
  List<String> _history = const [];

  bool _running = false;
  bool _paused = false;
  DateTime? _startedAt;
  DateTime? _endedAt;
  String _activityType = 'caminhada';
  String? _sessionId;

  double _distanceM = 0;
  final double _metWalkRun = 7.0;

  int _weekActiveMinBase = 0;
  double _weekDistanceKmBase = 0;

  int _minutesFromSeconds(int seconds) {
    if (seconds <= 0) return 0;
    return max(1, (seconds / 60).ceil());
  }

  Duration get _elapsed {
    final start = _startedAt;
    if (start == null) return Duration.zero;
    final end = _endedAt ?? DateTime.now();
    return end.difference(start);
  }

  double get _hours => max(_elapsed.inSeconds / 3600, 0);
  double _calories(double weightKg) => _metWalkRun * weightKg * _hours;
  double get _avgSpeedKmh => _hours == 0 ? 0 : (_distanceM / 1000) / _hours;

  String get _avgPaceMinPerKm {
    if (_distanceM <= 0) return '--';
    final secPerKm = _elapsed.inSeconds / (_distanceM / 1000);
    final m = (secPerKm ~/ 60).toString().padLeft(2, '0');
    final s = (secPerKm % 60).round().toString().padLeft(2, '0');
    return '$m:$s /km';
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
              'id, activity_type, started_at, finished_at, ended_at, duration_seconds, distance_meters, distance_m')
          .eq('user_id', user.id)
          .gte('started_at', since.toIso8601String())
          .order('started_at', ascending: false)
          .limit(30);
    } catch (_) {
      rows = await client
          .from('activity_sessions')
          .select('id, activity_type, started_at, ended_at, distance_m')
          .eq('user_id', user.id)
          .gte('started_at', since.toIso8601String())
          .order('started_at', ascending: false)
          .limit(30);
    }

    var totalMin = 0;
    var totalKm = 0.0;
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
      final km =
          (distanceMeters > 0 ? distanceMeters / 1000 : distanceMAlt / 1000);

      totalMin += durationMin;
      totalKm += km;

      final type =
          _capitalize((row['activity_type'] ?? 'atividade').toString());
      history.add('$type • ${km.toStringAsFixed(2)} km • ${durationMin} min');
    }

    if (!mounted) return;
    setState(() {
      _weekActiveMinBase = totalMin;
      _weekDistanceKmBase = totalKm;
      _history = history.take(7).toList(growable: false);
    });
  }

  Future<void> _start(String activityType) async {
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
              'activity_type': activityType,
              'started_at': now.toIso8601String(),
              'created_at': now.toIso8601String(),
            })
            .select('id')
            .single();
        _sessionId = row['id']?.toString();
      } catch (_) {}
    }

    _points.clear();
    _distanceM = 0;
    _startedAt = now;
    _endedAt = null;
    _running = true;
    _paused = false;
    _activityType = activityType;

    _sub?.cancel();
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

    _clockTicker?.cancel();
    _clockTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_running || _paused) return;
      setState(() {});
    });

    setState(() {});
  }

  Future<void> _startActivityPicker() async {
    if (_running) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Selecione o tipo de atividade',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.directions_walk),
                  title: const Text('Caminhada'),
                  onTap: () => Navigator.of(context).pop('caminhada'),
                ),
                ListTile(
                  leading: const Icon(Icons.directions_run),
                  title: const Text('Corrida'),
                  onTap: () => Navigator.of(context).pop('corrida'),
                ),
              ],
            ),
          ),
        );
      },
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

    final client = Supabase.instance.client;
    final sessionId = _sessionId;
    final durationSeconds = _elapsed.inSeconds;

    if (sessionId != null) {
      try {
        await client.from('activity_sessions').update({
          'finished_at': _endedAt!.toIso8601String(),
          'duration_seconds': durationSeconds,
          'distance_meters': _distanceM,
        }).eq('id', sessionId);
      } catch (_) {
        try {
          await client.from('activity_sessions').update({
            'ended_at': _endedAt!.toIso8601String(),
            'distance_m': _distanceM,
          }).eq('id', sessionId);
        } catch (_) {}
      }
    }

    _sessionId = null;
    await _loadWeeklyFromDb();
    ref.invalidate(homeDashboardProvider);
    setState(() {});
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

    final currentDistanceKm = _running ? (_distanceM / 1000) : 0.0;
    final currentActiveMin = _running ? _elapsed.inMinutes : 0;

    final weekDistanceKm = _weekDistanceKmBase + currentDistanceKm;
    final weekActiveMin = _weekActiveMinBase + currentActiveMin;
    final weekCalories = ((_weekActiveMinBase / 60) * _metWalkRun * weightKg) +
        _calories(weightKg);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const HamvitSectionHeader(
          title: 'Atividade física',
          subtitle:
              'Caminhada, corrida e histórico semanal em um único módulo permanente.',
        ),
        const SizedBox(height: 12),
        if (onboarding.needsActivitySoftGate) ...[
          HamvitSoftGateCard(
            title: 'Complete seus dados para estimativas mais precisas.',
            subtitle:
                'Sem bloqueio: você ainda pode usar caminhada e corrida agora.',
            buttonLabel: 'Completar Dados',
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
                label: 'Distância da semana',
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
          helper: 'Estimativa baseada em tempo ativo e perfil.',
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Status: ${_running ? (_paused ? 'pausado' : 'em andamento') : 'parado'}'),
                Text('Tipo atual: $_activityType'),
                Text(
                    'Tempo: ${_elapsed.inMinutes} min ${_elapsed.inSeconds % 60}s'),
                Text(
                    'Distância atual: ${(_distanceM / 1000).toStringAsFixed(2)} km'),
                Text('Ritmo médio: $_avgPaceMinPerKm'),
                Text(
                    'Velocidade média: ${_avgSpeedKmh.toStringAsFixed(2)} km/h'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        HamvitHistoryCard(
          title: 'Histórico de atividades',
          items: _history,
          icon: Icons.route_outlined,
        ),
      ],
    );
  }
}
