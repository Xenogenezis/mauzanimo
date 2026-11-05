import 'package:geolocator/geolocator.dart';

/// Result of asking the device for its position.
class LocationFix {
  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  const LocationFix(this.latitude, this.longitude, this.accuracyMeters);
}

enum LocationFailure { serviceDisabled, denied, deniedForever, timeout, unknown }

class LocationException implements Exception {
  final LocationFailure reason;
  const LocationException(this.reason);
}

/// Thin wrapper over geolocator so screens don't deal with permission flow.
class LocationService {
  const LocationService();

  Future<LocationFix> currentFix() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(LocationFailure.serviceDisabled);
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied) {
      throw const LocationException(LocationFailure.denied);
    }
    if (perm == LocationPermission.deniedForever) {
      throw const LocationException(LocationFailure.deniedForever);
    }
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return LocationFix(pos.latitude, pos.longitude, pos.accuracy);
    } on Exception catch (e) {
      // Fall back to the last known position if a fresh fix times out.
      final last = await Geolocator.getLastKnownPosition().catchError((_) => null);
      if (last != null) return LocationFix(last.latitude, last.longitude, last.accuracy);
      if (e.toString().contains('Timeout')) {
        throw const LocationException(LocationFailure.timeout);
      }
      throw const LocationException(LocationFailure.unknown);
    }
  }

  /// True if location is already allowed (no permission dialog needed).
  Future<bool> hasPermission() async {
    final p = await Geolocator.checkPermission();
    return p == LocationPermission.always || p == LocationPermission.whileInUse;
  }

  Future<bool> openSettings() => Geolocator.openAppSettings();
}
