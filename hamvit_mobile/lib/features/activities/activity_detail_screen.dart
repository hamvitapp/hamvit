import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'activity_models.dart';
import 'activity_repository.dart';
import 'activity_route_map_widget.dart';

class ActivityDetailScreen extends StatefulWidget {
  final Map<String, dynamic> session;
  const ActivityDetailScreen({super.key, required this.session});

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  bool _loading = true;
  List<ActivityRoutePoint> _points = const [];

  bool get _isOutdoor =>
      (widget.session['activity_environment'] ?? '').toString() == 'outdoor';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!_isOutdoor) {
      setState(() => _loading = false);
      return;
    }
    final sessionId = (widget.session['id'] ?? '').toString();
    if (sessionId.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    final repo = ActivityRepository(Supabase.instance.client);
    var points = await repo.loadRoutePoints(sessionId);
    if (points.isEmpty) {
      final summaryRaw = widget.session['route_summary_json'];
      if (summaryRaw is Map) {
        final summary = Map<String, dynamic>.from(summaryRaw);
        final rawPoints = summary['points'];
        if (rawPoints is List) {
          points = rawPoints
              .asMap()
              .entries
              .map((entry) {
                final idx = entry.key;
                final e = entry.value;
                if (e is! Map) return null;
                final m = Map<String, dynamic>.from(e);
                final lat = (m['lat'] as num?)?.toDouble();
                final lng = (m['lng'] as num?)?.toDouble();
                if (lat == null || lng == null) return null;
                final tsRaw = m['ts']?.toString();
                final ts = DateTime.tryParse(tsRaw ?? '');
                return ActivityRoutePoint(
                  latitude: lat,
                  longitude: lng,
                  recordedAt: ts ?? DateTime.now(),
                  pointOrder: idx,
                );
              })
              .whereType<ActivityRoutePoint>()
              .toList(growable: false);
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _points = points;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final type = (widget.session['activity_type'] ?? 'Atividade').toString();
    final distance = ((widget.session['distance_meters'] ?? 0) as num?)?.toDouble() ??
        0.0;
    final duration = ((widget.session['duration_seconds'] ?? 0) as num?)?.toInt() ?? 0;
    final calories =
        ((widget.session['estimated_calories_kcal'] ?? 0) as num?)?.toDouble() ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(type)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Distancia: ${(distance / 1000).toStringAsFixed(2)} km'),
                Text('Tempo: ${(duration ~/ 60)} min ${duration % 60}s'),
                Text('Calorias estimadas: ${calories.toStringAsFixed(0)} kcal'),
                const SizedBox(height: 12),
                if (_isOutdoor)
                  ActivityRouteMapWidget(points: _points)
                else
                  const Text('Atividade indoor: sem mapa.'),
              ],
            ),
    );
  }
}
