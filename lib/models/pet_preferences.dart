class PetPreferences {
  final List<String> types;
  final String ageRange;
  final String? preferredLocation;
  final String? gender;

  const PetPreferences({
    this.types = const [],
    this.ageRange = 'any',
    this.preferredLocation,
    this.gender,
  });

  factory PetPreferences.fromMap(Map<String, dynamic> map) {
    return PetPreferences(
      types: (map['types'] as List<dynamic>?)?.cast<String>() ?? [],
      ageRange: map['ageRange'] as String? ?? 'any',
      preferredLocation: map['preferredLocation'] as String?,
      gender: map['gender'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'types': types,
        'ageRange': ageRange,
        'preferredLocation': preferredLocation,
        'gender': gender,
      };

  PetPreferences copyWith({
    List<String>? types,
    String? ageRange,
    String? preferredLocation,
    String? gender,
  }) =>
      PetPreferences(
        types: types ?? this.types,
        ageRange: ageRange ?? this.ageRange,
        preferredLocation: preferredLocation ?? this.preferredLocation,
        gender: gender ?? this.gender,
      );
}
