class LostFound {
  final String id;
  final String type; // 'Lost' or 'Found'
  final String animalType;
  final String description;
  final String location;
  final String contact;
  final String? imageUrl;
  final DateTime? createdAt;
  final String? userId;

  LostFound({
    required this.id,
    required this.type,
    required this.animalType,
    required this.description,
    required this.location,
    required this.contact,
    this.imageUrl,
    this.createdAt,
    this.userId,
  });

  factory LostFound.fromMap(String id, Map<String, dynamic> map) {
    return LostFound(
      id: id,
      type: map['type'] ?? 'Lost',
      animalType: map['animalType'] ?? 'Animal',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      contact: map['contact'] ?? '',
      imageUrl: map['imageUrl'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : null,
      userId: map['userId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'animalType': animalType,
      'description': description,
      'location': location,
      'contact': contact,
      'imageUrl': imageUrl,
      'userId': userId,
    };
  }

  LostFound copyWith({
    String? id,
    String? type,
    String? animalType,
    String? description,
    String? location,
    String? contact,
    String? imageUrl,
    DateTime? createdAt,
    String? userId,
  }) {
    return LostFound(
      id: id ?? this.id,
      type: type ?? this.type,
      animalType: animalType ?? this.animalType,
      description: description ?? this.description,
      location: location ?? this.location,
      contact: contact ?? this.contact,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
    );
  }
}
