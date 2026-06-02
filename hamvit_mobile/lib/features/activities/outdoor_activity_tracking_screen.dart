import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/maps/map_tile_provider_config.dart';
import 'activity_models.dart';
import 'gps_tracking_service.dart';

class OutdoorTrackingResult {
  final List<ActivityRoutePoint> points;
  final DateTime startedAt;
  final DateTime finishedAt;
  final double distanceMeters;
  final int durationSeconds;

  const OutdoorTrackingResult({
    required this.points,
    required this.startedAt,
    required this.finishedAt,
    required this.distanceMeters,
    required this.durationSeconds,
  });
}

class OutdoorActivityTrackingScreen extends StatefulWidget {
  final String title;
  const OutdoorActivityTrackingScreen({super.key, required this.title});

  @override
  State<OutdoorActivityTrackingScreen> createState() =>
      _OutdoorActivityTrackingScreenState();
}

class _OutdoorActivityTrackingScreenState
    extends State<OutdoorActivityTrackingScreen> {
  final GpsTrackingService _gps = GpsTrackingService();
  final MapController _mapController = MapController();
  final List<ActivityRoutePoint> _points = [];

  Timer? _timer;
  DateTime? _startedAt;
  bool _running = false;
  bool _paused = false;
  String _status = 'GPS buscando sinal...';

  int get _durationSeconds {
    if (_startedAt == null) return 0;
    return DateTime.now().difference(_startedAt!).inSeconds;
  }

  double get _distanceMeters => _gps.distanceMeters;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final ok = await _gps.ensurePermissions();
    if (!ok) {
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }
    _startedAt = DateTime.now();
    _running = true;
    _status = 'Rota sendo gravada.';
    await _gps.start((point) {
      if (!_running || _paused) return;
      setState(() => _points.add(point));
      _mapController.move(LatLng(point.latitude, point.longitude), _mapController.camera.zoom);
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_running || _paused || !mounted) return;
      setState(() {});
    });
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gps.stop();
    super.dispose();
  }

  void _togglePause() {
    if (!_running) return;
    setState(() {
      _paused = !_paused;
      _status = _paused ? 'Pausado.' : 'Rota sendo gravada.';
    });
  }

  Future<void> _finish() async {
    if (!_running || _startedAt == null) return;
    _running = false;
    await _gps.stop();
    final finished = DateTime.now();
    final rawDuration = finished.difference(_startedAt!).inSeconds;
    final safeDuration = rawDuration <= 0 ? 1 : rawDuration;
    if (!mounted) return;
    Navigator.of(context).pop(
      OutdoorTrackingResult(
        points: List<ActivityRoutePoint>.from(_points),
        startedAt: _startedAt!,
        finishedAt: finished,
        distanceMeters: _distanceMeters,
        durationSeconds: safeDuration,
      ),
    );
  }

  Future<bool> _onBackRequested() async {
    if (!_running) return true;
    final shouldFinish = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar atividade?'),
        content: const Text(
          'Deseja finalizar e salvar esta atividade agora?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Continuar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Descartar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Finalizar e salvar'),
          ),
        ],
      ),
    );

    if (shouldFinish == true) {
      await _finish();
      return false;
    }

    if (shouldFinish == null) {
      _running = false;
      await _gps.stop();
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final route = _points.map((e) => e.toLatLng()).toList(growable: false);
    final center = route.isNotEmpty ? route.last : const LatLng(-23.5505, -46.6333);
    final km = _distanceMeters / 1000;
    final speed = _durationSeconds > 0 ? km / (_durationSeconds / 3600) : 0.0;
    final pace = km > 0 ? (_durationSeconds / km).round() : 0;
    final paceLabel = pace <= 0
        ? '--'
        : '${(pace ~/ 60).toString().padLeft(2, '0')}:${(pace % 60).toString().padLeft(2, '0')} /km';

    return WillPopScope(
      onWillPop: _onBackRequested,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final canPop = await _onBackRequested();
              if (canPop && mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(initialCenter: center, initialZoom: 16),
                  children: [
                    TileLayer(
                      urlTemplate: MapTileProviderConfig.osm.urlTemplate,
                      userAgentPackageName: MapTileProviderConfig.osm.userAgentPackageName,
                    ),
                    if (route.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: route,
                            strokeWidth: 4,
                            color: Colors.cyanAccent,
                          ),
                        ],
                      ),
                    if (route.isNotEmpty)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: route.first,
                            width: 26,
                            height: 26,
                            child: const Icon(Icons.play_arrow, color: Colors.greenAccent),
                          ),
                          Marker(
                            point: route.last,
                            width: 26,
                            height: 26,
                            child: const Icon(Icons.my_location, color: Colors.white),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(_status),
            Text('Tempo: ${(_durationSeconds ~/ 60)} min ${_durationSeconds % 60}s'),
            Text('Distancia: ${km.toStringAsFixed(2)} km'),
            Text('Velocidade media: ${speed.toStringAsFixed(2)} km/h'),
            Text('Ritmo medio: $paceLabel'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _togglePause,
                    icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
                    label: Text(_paused ? 'Retomar' : 'Pausar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _finish,
                    icon: const Icon(Icons.flag),
                    label: const Text('Finalizar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Mapa indisponivel offline, mas a rota continuara sendo gravada.',
              style: TextStyle(fontSize: 12),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
