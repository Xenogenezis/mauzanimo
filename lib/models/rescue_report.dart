import 'package:cloud_firestore/cloud_firestore.dart';

class RescueReport {
  final String id;
  final String description;
  final String location;
  final String animalType;
  final String urgency;
  final String status;
  final String? imageUrl;
  final String reporterId;
  final String reporterName;
  final String reporterPhone;
  final String? assignedVolunteerId;
  final String? assignedVolunteerName;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  /// Map pin of where the animal is (`geo` GeoPoint). Optional: older
  /// reports and reports made without a pin only have the [location] text.
  final double? latitude;
  final double? longitude;

  const RescueReport({
    required this.id,
    required this.description,
    required this.location,
    required this.animalType,
    required this.urgency,
    this.status = 'pending',
    this.imageUrl,
    required this.reporterId,
    required this.reporterName,
    required this.reporterPhone,
    this.assignedVolunteerId,
    this.assignedVolunteerName,
    required this.createdAt,
    this.resolvedAt,
    this.latitude,
    this.longitude,
  });

  bool get hasGeo => latitude != null && longitude != null;

  factory RescueReport.fromMap(String id, Map<String, dynamic> map) {
    final geo = map['geo'];
    final created = map['createdAt'];
    final resolved = map['resolvedAt'];
    return RescueReport(
      id: id,
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      animalType: map['animalType'] ?? '',
      urgency: map['urgency'] ?? 'medium',
      status: map['status'] ?? 'pending',
      imageUrl: map['imageUrl'] as String?,
      reporterId: map['reporterId'] ?? '',
      reporterName: map['reporterName'] ?? '',
      reporterPhone: map['reporterPhone'] ?? '',
      assignedVolunteerId: map['assignedVolunteerId'] as String?,
      assignedVolunteerName: map['assignedVolunteerName'] as String?,
      // The server timestamp is null in the local snapshot until it is
      // written, so a report just created on this device reads as "now".
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
      resolvedAt: resolved is Timestamp ? resolved.toDate() : null,
      latitude: geo is GeoPoint ? geo.latitude : null,
      longitude: geo is GeoPoint ? geo.longitude : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'description': description,
        'location': location,
        'animalType': animalType,
        'urgency': urgency,
        'status': status,
        'imageUrl': imageUrl,
        'reporterId': reporterId,
        'reporterName': reporterName,
        'reporterPhone': reporterPhone,
        'assignedVolunteerId': assignedVolunteerId,
        'assignedVolunteerName': assignedVolunteerName,
        'createdAt': FieldValue.serverTimestamp(),
        'resolvedAt': resolvedAt,
        if (hasGeo) 'geo': GeoPoint(latitude!, longitude!),
      };
}
