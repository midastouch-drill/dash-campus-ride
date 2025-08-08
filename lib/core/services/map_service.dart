import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Abstract map service to isolate map provider specifics and enable
/// background‑safe, testable integrations. Concrete implementation will be
/// backed by Google Maps SDK once keys are provided.
abstract class MapService {
  Future<void> init({bool darkMode = false});

  Future<void> setCamera({
    required double lat,
    required double lng,
    double zoom,
  });

  Future<void> addMarker({
    required String id,
    required double lat,
    required double lng,
    String? label,
  });

  Future<void> drawRoute(List<List<double>> coordinates);

  Future<void> setGeofence(List<List<double>> polygonCoords);

  Future<void> clear();
}

class NoopMapService implements MapService {
  @override
  Future<void> init({bool darkMode = false}) async {
    if (kDebugMode) print('[MapService] init darkMode=$darkMode');
  }

  @override
  Future<void> setCamera({required double lat, required double lng, double zoom = 15}) async {
    if (kDebugMode) print('[MapService] setCamera ($lat,$lng) z=$zoom');
  }

  @override
  Future<void> addMarker({required String id, required double lat, required double lng, String? label}) async {
    if (kDebugMode) print('[MapService] addMarker id=$id ($lat,$lng) label=$label');
  }

  @override
  Future<void> drawRoute(List<List<double>> coordinates) async {
    if (kDebugMode) print('[MapService] drawRoute points=${coordinates.length}');
  }

  @override
  Future<void> setGeofence(List<List<double>> polygonCoords) async {
    if (kDebugMode) print('[MapService] setGeofence vertices=${polygonCoords.length}');
  }

  @override
  Future<void> clear() async {
    if (kDebugMode) print('[MapService] clear');
  }
}

final mapServiceProvider = Provider<MapService>((ref) => NoopMapService());
