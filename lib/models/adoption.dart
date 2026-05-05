import 'package:cloud_firestore/cloud_firestore.dart';

enum AdoptionStage { application, screening, meet_greet, trial, completed, rejected }

class StageRecord {
  final AdoptionStage stage;
  final DateTime timestamp;
  final String? notes;
  final String? changedBy;

  const StageRecord({required this.stage, required this.timestamp, this.notes, this.changedBy});

  factory StageRecord.fromMap(Map<String, dynamic> map) => StageRecord(
        stage: AdoptionStage.values.firstWhere((s) => s.name == map['stage'] as String?,
            orElse: () => AdoptionStage.application),
        timestamp: (map['timestamp'] as Timestamp).toDate(),
        notes: map['notes'] as String?,
        changedBy: map['changedBy'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'stage': stage.name,
        'timestamp': FieldValue.serverTimestamp(),
        'notes': notes,
        'changedBy': changedBy,
      };
}

class Adoption {
  final String id;
  final String petId;
  final String petName;
  final String adopterId;
  final String adopterName;
  final String adopterEmail;
  final String adopterPhone;
  final AdoptionStage currentStage;
  final List<StageRecord> stageHistory;
  final DateTime createdAt;
  final String? rejectionReason;

  const Adoption({
    required this.id,
    required this.petId,
    required this.petName,
    required this.adopterId,
    required this.adopterName,
    required this.adopterEmail,
    required this.adopterPhone,
    this.currentStage = AdoptionStage.application,
    this.stageHistory = const [],
    required this.createdAt,
    this.rejectionReason,
  });

  factory Adoption.fromMap(String id, Map<String, dynamic> map) => Adoption(
        id: id,
        petId: map['petId'] ?? '',
        petName: map['petName'] ?? '',
        adopterId: map['adopterId'] ?? '',
        adopterName: map['adopterName'] ?? '',
        adopterEmail: map['adopterEmail'] ?? '',
        adopterPhone: map['adopterPhone'] ?? '',
        currentStage: AdoptionStage.values.firstWhere((s) => s.name == map['currentStage'] as String?,
            orElse: () => AdoptionStage.application),
        stageHistory: (map['stageHistory'] as List<dynamic>?)
                ?.map((e) => StageRecord.fromMap(e as Map<String, dynamic>))
                .toList() ?? [],
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        rejectionReason: map['rejectionReason'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'petId': petId,
        'petName': petName,
        'adopterId': adopterId,
        'adopterName': adopterName,
        'adopterEmail': adopterEmail,
        'adopterPhone': adopterPhone,
        'currentStage': currentStage.name,
        'stageHistory': stageHistory.map((e) => e.toMap()).toList(),
        'createdAt': FieldValue.serverTimestamp(),
        'rejectionReason': rejectionReason,
      };
}
