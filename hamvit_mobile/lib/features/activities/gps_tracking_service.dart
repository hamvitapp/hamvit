import 'dart:async';
import 'dart:math';

import 'package:geolocator/geolocator.dart';

import 'activity_models.dart';

class GpsTrackingService {
  static const double maxAcceptedAccuracyMeters = 65;
  static const double minDistanceMeters = 2;
  static const int minSecondsBetweenPoints = 2;
  static const double maxReasonableSpeedMps = 12;

  StreamSubscription<Position>? _subscription;
  final List<ActivityRoutePoint> _points = [];
  DateTime? _lastAcceptedAt;
  double _distanceMeters = 0;

  List<ActivityRoutePoint> get points => List.unmodifiable(_points);
  double get distanceMeters => _distanceMeters;

  Future<bool> ensurePermissions() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return false;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<void> start(void Function(ActivityRoutePoint point) onPoint) async {
    await stop();
    _points.clear();
    _distanceMeters = 0;
    _lastAcceptedAt = null;

    // Captura inicial para não perder atividades curtas/baixa movimentação.
    try {
      final initial = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final first = _toPoint(initial, 0);
      if (_shouldAccept(first, isInitial: true)) {
        _points.add(first);
        _lastAcceptedAt = first.recordedAt;
        onPoint(first);
      }
    } catch (_) {}

    _subscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2,
      ),
    ).listen((position) {
      final point = _toPoint(position, _points.length);
      if (!_shouldAccept(point, isInitial: false)) return;
      if (_points.isNotEmpty) {
        final prev = _points.last;
        final seg = Geolocator.distanceBetween(
          prev.latitude,
          prev.longitude,
          point.latitude,
          point.longitude,
        );
        _distanceMeters += max(0, seg);
      }
      _points.add(point);
      _lastAcceptedAt = point.recordedAt;
      onPoint(point);
    });
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  ActivityRoutePoint _toPoint(Position p, int order) {
    return ActivityRoutePoint(
      latitude: p.latitude,
      longitude: p.longitude,
      altitude: p.altitude,
      accuracy: p.accuracy,
      speedMps: p.speed,
      heading: p.heading,
      recordedAt: p.timestamp ?? DateTime.now(),
      pointOrder: order,
    );
  }

  bool _shouldAccept(ActivityRoutePoint p, {required bool isInitial}) {
    if (p.accuracy != null && p.accuracy! > maxAcceptedAccuracyMeters) {
      return false;
    }
    if (isInitial || _points.isEmpty) return true;
    final prev = _points.last;
    final deltaSeconds = p.recordedAt.difference(prev.recordedAt).inSeconds;
    final distance = Geolocator.distanceBetween(
      prev.latitude,
      prev.longitude,
      p.latitude,
      p.longitude,
    );
    if (deltaSeconds > 0) {
      final speed = distance / deltaSeconds;
      if (speed > maxReasonableSpeedMps) return false;
    }
    final enoughDistance = distance >= minDistanceMeters;
    final enoughTime = _lastAcceptedAt == null
        ? true
        : p.recordedAt.difference(_lastAcceptedAt!).inSeconds >=
            minSecondsBetweenPoints;
    return enoughDistance || enoughTime;
  }
}
