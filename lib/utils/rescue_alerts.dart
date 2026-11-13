import 'dart:convert';

import '../models/rescue_report.dart';
import 'geo_utils.dart';

/// Distances (km) a rescuer can choose for their alert area. 50 km covers
/// practically the whole island.
const List<int> rescueAlertRadii = [5, 10, 20, 50];

/// A volunteer/rescuer's "alert me about rescues near me" settings.
///
/// Stored on the device only (SharedPreferences): the area is compared with
/// rescue reports locally, so a rescuer's location is never uploaded or
/// visible to other users.
class RescueAlertPrefs {
  final bool enabled;
  final double? latitude;
  final double? longitude;
  final int radiusKm;

  /// Only alert for `high` and `critical` reports.
  final bool urgentOnly;

  const RescueAlertPrefs({
    this.enabled = false,
    this.latitude,
    this.longitude,
    this.radiusKm = 10,
    this.urgentOnly = false,
  });

  bool get hasArea => latitude != null && longitude != null;

  /// Alerts are on and there is an area to compare against.
  bool get isActive => enabled && hasArea;

  RescueAlertPrefs copyWith({
    bool? enabled,
    double? latitude,
    double? longitude,
    int? radiusKm,
    bool? urgentOnly,
  }) =>
      RescueAlertPrefs(
        enabled: enabled ?? this.enabled,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        radiusKm: radiusKm ?? this.radiusKm,
        urgentOnly: urgentOnly ?? this.urgentOnly,
      );

  String encode() => jsonEncode({
        'enabled': enabled,
        'lat': latitude,
        'lng': longitude,
        'radiusKm': radiusKm,
        'urgentOnly': urgentOnly,
      });

  /// Reads what [encode] wrote. Anything unreadable gives the defaults.
  static RescueAlertPrefs decode(String? raw) {
    if (raw == null || raw.isEmpty) return const RescueAlertPrefs();
    try {
      final m = jsonDecode(raw);
      if (m is! Map) return const RescueAlertPrefs();
      final radius = m['radiusKm'];
      return RescueAlertPrefs(
        enabled: m['enabled'] == true,
        latitude: (m['lat'] as num?)?.toDouble(),
        longitude: (m['lng'] as num?)?.toDouble(),
        radiusKm: radius is int && rescueAlertRadii.contains(radius) ? radius : 10,
        urgentOnly: m['urgentOnly'] == true,
      );
    } catch (_) {
      return const RescueAlertPrefs();
    }
  }
}

/// A rescue report together with its distance from the rescuer's area.
class NearbyRescue {
  final RescueReport report;
  final double distanceKm;
  const NearbyRescue(this.report, this.distanceKm);
}

int _urgencyRank(String urgency) => switch (urgency) {
      'critical' => 0,
      'high' => 1,
      _ => 2,
    };

/// Distance from the centre of the rescuer's area to [report], or null when
/// either side has no position.
double? distanceToReport(RescueReport report, RescueAlertPrefs prefs) {
  if (!prefs.hasArea || !report.hasGeo) return null;
  return haversineKm(prefs.latitude!, prefs.longitude!, report.latitude!, report.longitude!);
}

/// Open rescue reports inside the rescuer's area, most urgent first and then
/// nearest first. Empty when alerts are off or no area is set.
///
/// Only `pending` reports with a map pin count: an assigned or resolved
/// report no longer needs anyone, and a report without a pin cannot be
/// placed.
List<NearbyRescue> nearbyRescues(Iterable<RescueReport> reports, RescueAlertPrefs prefs) {
  if (!prefs.isActive) return const [];
  final out = <NearbyRescue>[];
  for (final r in reports) {
    if (r.status != 'pending') continue;
    if (prefs.urgentOnly && _urgencyRank(r.urgency) > 1) continue;
    final d = distanceToReport(r, prefs);
    if (d == null || d > prefs.radiusKm) continue;
    out.add(NearbyRescue(r, d));
  }
  out.sort((a, b) {
    final u = _urgencyRank(a.report.urgency).compareTo(_urgencyRank(b.report.urgency));
    return u != 0 ? u : a.distanceKm.compareTo(b.distanceKm);
  });
  return out;
}
