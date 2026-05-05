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
  });

  factory RescueReport.fromMap(String id, Map<String, dynamic> map) => RescueReport(
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
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        resolvedAt: map['resolvedAt'] != null ? (map['resolvedAt'] as Timestamp).toDate() : null,
      );

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
      };
}
