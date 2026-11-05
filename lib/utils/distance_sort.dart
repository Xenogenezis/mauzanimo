import 'package:cloud_firestore/cloud_firestore.dart';

import 'geo_utils.dart';

/// Distance in km from ([lat], [lng]) to [geo], or null when [geo] is not a
/// [GeoPoint] (posts created before locations were captured).
double? distanceKmToGeo(Object? geo, double lat, double lng) {
  if (geo is! GeoPoint) return null;
  return haversineKm(lat, lng, geo.latitude, geo.longitude);
}

/// Returns a new list with the items that have a known distance first,
/// nearest first, followed by the items without a distance in their
/// original order. Items at the same distance keep their original order.
List<T> sortByDistance<T>(List<T> items, double? Function(T item) distanceKm) {
  final withDistance = <(int, double, T)>[];
  final withoutDistance = <T>[];
  for (var i = 0; i < items.length; i++) {
    final d = distanceKm(items[i]);
    if (d == null || d.isNaN) {
      withoutDistance.add(items[i]);
    } else {
      withDistance.add((i, d, items[i]));
    }
  }
  withDistance.sort((a, b) {
    final byDistance = a.$2.compareTo(b.$2);
    return byDistance != 0 ? byDistance : a.$1.compareTo(b.$1);
  });
  return [
    for (final e in withDistance) e.$3,
    ...withoutDistance,
  ];
}
