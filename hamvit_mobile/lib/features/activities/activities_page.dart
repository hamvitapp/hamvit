import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/hamvit_onboarding_widgets.dart';
import '../onboarding/providers/onboarding_profile_provider.dart';

class ActivitiesPage extends ConsumerStatefulWidget {
  const ActivitiesPage({super.key});

  @override
  ConsumerState<ActivitiesPage> createState() => _ActivitiesPageState();
}

class _ActivitiesPageState extends ConsumerState<ActivitiesPage> {
  StreamSubscription<Position>? _sub;
  final List<Position> _points = [];

  bool _running = false;
  bool _paused = false;
  DateTime? _startedAt;
  DateTime? _endedAt;

  double _distanceM = 0;
  final double _metWalkRun = 7.0;

  Duration get _elapsed {
    final start = _startedAt;
    if (start == null) return Duration.zero;
    final end = _endedAt ?? DateTime.now();
    return end.difference(start);
  }

  Future<void> _start() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return;
    }

    _points.clear();
    _distanceM = 0;
    _startedAt = DateTime.now();
    _endedAt = null;
    _running = true;
    _paused = false;

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
        _distanceM += Geolocator.distanceBetween(prev.latitude, prev.longitude, pos.latitude, pos.longitude);
      }
      setState(() => _points.add(pos));
    });

    setState(() {});
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
    await _sub?.cancel();
    _sub = null;
    setState(() {});
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

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = ref.watch(onboardingProfileProvider);
    final weightKg = onboarding.weightKg ?? 70;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (onboarding.needsActivitySoftGate) ...[
          HamvitSoftGateCard(
            title: 'Complete seus dados para calcular calorias e metas com mais precisão.',
            subtitle: 'Sem bloqueio: você ainda pode iniciar caminhada e corrida agora.',
            buttonLabel: 'Completar Dados',
            onTap: () => context.go('/onboarding/activity'),
          ),
          const SizedBox(height: 10),
        ],
        const Text('Caminhada e corrida com GPS'),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            title: const Text('Iniciar atividade'),
            subtitle: const Text('Inicia captura de posição e distância'),
            onTap: _running ? null : _start,
          ),
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
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: ${_running ? (_paused ? 'pausado' : 'em andamento') : 'parado'}'),
                Text('Tempo: ${_elapsed.inMinutes} min ${_elapsed.inSeconds % 60}s'),
                Text('Distância: ${(_distanceM / 1000).toStringAsFixed(2)} km'),
                Text('Ritmo médio: $_avgPaceMinPerKm'),
                Text('Velocidade média: ${_avgSpeedKmh.toStringAsFixed(2)} km/h'),
                Text('Calorias estimadas: ${_calories(weightKg).toStringAsFixed(0)} kcal'),
                const SizedBox(height: 6),
                const Text('Calorias estimadas por MET = MET × peso × duração(h).'),
                if (onboarding.needsActivitySoftGate)
                  const Text('Calculo limitado por dados parciais de perfil.'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
