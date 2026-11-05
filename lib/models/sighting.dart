import 'package:cloud_firestore/cloud_firestore.dart';

/// A photo + GPS report of an animal seen in the street.
///
/// Either a free-roaming stray, or a sighting of an animal that someone has
/// reported lost (then [lostReportId] links to the `lostfound` document).
class Sighting {
  final String id;
  final String reporterId;
  final String reporterName;
  final String animalType;
  final String description;

  /// `data:image/jpeg;base64,...` or an https URL.
  final String? imageUrl;
  final double latitude;
  final double longitude;

  /// Horizontal GPS accuracy in metres, when the fix came from the device.
  final double? accuracyMeters;

  /// True when the user moved the pin by hand instead of using raw GPS.
  final bool manuallyPlaced;
  final String? locationLabel;
  final String? lostReportId;

  /// `open`, `resolved` or `hidden` (moderated).
  final String status;
  final DateTime? createdAt;

  const Sighting({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.animalType,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    this.accuracyMeters,
    this.manuallyPlaced = false,
    this.locationLabel,
    this.lostReportId,
    this.status = 'open',
    this.createdAt,
  });

  bool get isLinkedToLostReport => lostReportId != null && lostReportId!.isNotEmpty;

  factory Sighting.fromMap(String id, Map<String, dynamic> map) {
    final geo = map['geo'];
    final ts = map['createdAt'];
    return Sighting(
      id: id,
      reporterId: map['reporterId'] as String? ?? '',
      reporterName: map['reporterName'] as String? ?? '',
      animalType: map['animalType'] as String? ?? 'Animal',
      description: map['description'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      latitude: geo is GeoPoint ? geo.latitude : 0,
      longitude: geo is GeoPoint ? geo.longitude : 0,
      accuracyMeters: (map['accuracyMeters'] as num?)?.toDouble(),
      manuallyPlaced: map['manuallyPlaced'] as bool? ?? false,
      locationLabel: map['locationLabel'] as String?,
      lostReportId: map['lostReportId'] as String?,
      status: map['status'] as String? ?? 'open',
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'reporterId': reporterId,
        'reporterName': reporterName,
        'animalType': animalType,
        'description': description,
        'imageUrl': imageUrl,
        'geo': GeoPoint(latitude, longitude),
        'accuracyMeters': accuracyMeters,
        'manuallyPlaced': manuallyPlaced,
        'locationLabel': locationLabel,
        'lostReportId': lostReportId,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
