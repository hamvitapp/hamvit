import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/maps/map_tile_provider_config.dart';
import 'activity_models.dart';

class ActivityRouteMapWidget extends StatelessWidget {
  final List<ActivityRoutePoint> points;
  final double height;

  const ActivityRouteMapWidget({
    super.key,
    required this.points,
    this.height = 260,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('Rota indisponivel para esta atividade.')),
      );
    }

    final latLng = points.map((e) => e.toLatLng()).toList(growable: false);
    final first = latLng.first;
    final last = latLng.last;

    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: first,
            initialZoom: 15,
          ),
          children: [
            TileLayer(
              urlTemplate: MapTileProviderConfig.osm.urlTemplate,
              userAgentPackageName: MapTileProviderConfig.osm.userAgentPackageName,
            ),
            PolylineLayer(
              polylines: [
                Polyline(points: latLng, strokeWidth: 4, color: Colors.cyanAccent),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: first,
                  width: 28,
                  height: 28,
                  child: const Icon(Icons.play_arrow, color: Colors.greenAccent),
                ),
                Marker(
                  point: last,
                  width: 28,
                  height: 28,
                  child: const Icon(Icons.flag, color: Colors.redAccent),
                ),
              ],
            ),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(MapTileProviderConfig.osm.attribution),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

