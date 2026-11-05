import 'dart:math' as math;

/// Centre of Mauritius, used as the default map position.
const double mauritiusLat = -20.25;
const double mauritiusLng = 57.55;

/// Great-circle distance in kilometres.
double haversineKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  final dLat = _rad(lat2 - lat1);
  final dLng = _rad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_rad(lat1)) * math.cos(_rad(lat2)) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return 2 * r * math.asin(math.min(1.0, math.sqrt(a)));
}

double _rad(double deg) => deg * math.pi / 180.0;

/// "350 m" / "4.2 km"
String formatDistance(double km) {
  if (km < 1) return '${(km * 1000).round()} m';
  return '${km.toStringAsFixed(km < 10 ? 1 : 0)} km';
}

/// Rough bounding box check so obviously wrong fixes (0,0 etc.) are flagged.
bool isInMauritiusRegion(double lat, double lng) =>
    lat > -21.0 && lat < -19.0 && lng > 56.9 && lng < 58.0 ||
    // Rodrigues
    lat > -20.0 && lat < -19.4 && lng > 63.0 && lng < 63.7;

/// "-20.16412, 57.50201"
String formatLatLng(double lat, double lng) =>
    '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
