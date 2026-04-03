class Pet {
  final String id;
  final String name;
  final String type;
  final String location;
  final String description;
  final String? imageUrl;
  final String age;
  final String gender;
  final bool vaccinated;
  final bool sterilized;
  final bool dewormed;
  final String status;
  final String contact;
  final String? uploadedBy;
  final String? uploaderEmail;
  final bool isUserUpload;
  final DateTime? createdAt;

  Pet({
    required this.id,
    required this.name,
    required this.type,
    required this.location,
    required this.description,
    this.imageUrl,
    required this.age,
    required this.gender,
    this.vaccinated = false,
    this.sterilized = false,
    this.dewormed = false,
    this.status = 'available',
    required this.contact,
    this.uploadedBy,
    this.uploaderEmail,
    this.isUserUpload = false,
    this.createdAt,
  });

  factory Pet.fromMap(String id, Map<String, dynamic> map) {
    return Pet(
      id: id,
      name: map['name'] ?? 'Unknown',
      type: map['type'] ?? 'pet',
      location: map['location'] ?? 'Mauritius',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'],
      age: map['age'] ?? 'Unknown',
      gender: map['gender'] ?? 'Unknown',
      vaccinated: map['vaccinated'] == true,
      sterilized: map['sterilized'] == true,
      dewormed: map['dewormed'] == true,
      status: map['status'] ?? 'available',
      contact: map['contact'] ?? '',
      uploadedBy: map['uploadedBy'],
      uploaderEmail: map['uploaderEmail'],
      isUserUpload: map['isUserUpload'] == true,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'location': location,
      'description': description,
      'imageUrl': imageUrl,
      'age': age,
      'gender': gender,
      'vaccinated': vaccinated,
      'sterilized': sterilized,
      'dewormed': dewormed,
      'status': status,
      'contact': contact,
      'uploadedBy': uploadedBy,
      'uploaderEmail': uploaderEmail,
      'isUserUpload': isUserUpload,
    };
  }

  Pet copyWith({
    String? id,
    String? name,
    String? type,
    String? location,
    String? description,
    String? imageUrl,
    String? age,
    String? gender,
    bool? vaccinated,
    bool? sterilized,
    bool? dewormed,
    String? status,
    String? contact,
    String? uploadedBy,
    String? uploaderEmail,
    bool? isUserUpload,
    DateTime? createdAt,
  }) {
    return Pet(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      location: location ?? this.location,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      vaccinated: vaccinated ?? this.vaccinated,
      sterilized: sterilized ?? this.sterilized,
      dewormed: dewormed ?? this.dewormed,
      status: status ?? this.status,
      contact: contact ?? this.contact,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploaderEmail: uploaderEmail ?? this.uploaderEmail,
      isUserUpload: isUserUpload ?? this.isUserUpload,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
