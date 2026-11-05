import 'pet.dart';

/// How the pet list is ordered.
enum PetSort { newest, oldest, name }

/// Age buckets used by the filter sheet.
enum AgeGroup { any, young, adult, senior }

/// Client-side filters for the pet list. They run on pets already loaded
/// from Firestore, so they need no extra queries or indexes.
class PetFilters {
  final String? gender; // 'male' / 'female' / null for any
  final AgeGroup ageGroup;
  final bool vaccinatedOnly;
  final bool sterilizedOnly;
  final bool availableOnly;
  final PetSort sort;

  const PetFilters({
    this.gender,
    this.ageGroup = AgeGroup.any,
    this.vaccinatedOnly = false,
    this.sterilizedOnly = false,
    this.availableOnly = false,
    this.sort = PetSort.newest,
  });

  static const none = PetFilters();

  /// Number of active filters (sort is not counted), for the badge.
  int get activeCount =>
      (gender != null ? 1 : 0) +
      (ageGroup != AgeGroup.any ? 1 : 0) +
      (vaccinatedOnly ? 1 : 0) +
      (sterilizedOnly ? 1 : 0) +
      (availableOnly ? 1 : 0);

  bool get isDefault => activeCount == 0 && sort == PetSort.newest;

  PetFilters copyWith({
    String? gender,
    bool clearGender = false,
    AgeGroup? ageGroup,
    bool? vaccinatedOnly,
    bool? sterilizedOnly,
    bool? availableOnly,
    PetSort? sort,
  }) =>
      PetFilters(
        gender: clearGender ? null : (gender ?? this.gender),
        ageGroup: ageGroup ?? this.ageGroup,
        vaccinatedOnly: vaccinatedOnly ?? this.vaccinatedOnly,
        sterilizedOnly: sterilizedOnly ?? this.sterilizedOnly,
        availableOnly: availableOnly ?? this.availableOnly,
        sort: sort ?? this.sort,
      );

  /// Whether [p] passes every active filter (sort is ignored).
  bool matches(Pet p) {
    if (gender != null && p.gender.toLowerCase() != gender) return false;
    if (vaccinatedOnly && !p.vaccinated) return false;
    if (sterilizedOnly && !p.sterilized) return false;
    if (availableOnly && p.status != 'available') return false;
    if (ageGroup != AgeGroup.any && ageGroupOf(p.age) != ageGroup) {
      return false;
    }
    return true;
  }

  List<Pet> apply(List<Pet> pets) {
    final out = pets.where(matches).toList();

    switch (sort) {
      case PetSort.newest:
        out.sort((a, b) => _date(b).compareTo(_date(a)));
      case PetSort.oldest:
        out.sort((a, b) => _date(a).compareTo(_date(b)));
      case PetSort.name:
        out.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return out;
  }

  Map<String, dynamic> toJson() => {
        if (gender != null) 'gender': gender,
        'ageGroup': ageGroup.name,
        'vaccinatedOnly': vaccinatedOnly,
        'sterilizedOnly': sterilizedOnly,
        'availableOnly': availableOnly,
        'sort': sort.name,
      };

  /// Lenient: unknown or missing values fall back to the defaults, so
  /// searches saved by an older app version still load.
  factory PetFilters.fromJson(Map<String, dynamic> json) {
    T byName<T extends Enum>(List<T> values, Object? name, T fallback) =>
        values.firstWhere((v) => v.name == name, orElse: () => fallback);
    final g = json['gender'];
    return PetFilters(
      gender: g == 'male' || g == 'female' ? g as String : null,
      ageGroup: byName(AgeGroup.values, json['ageGroup'], AgeGroup.any),
      vaccinatedOnly: json['vaccinatedOnly'] == true,
      sterilizedOnly: json['sterilizedOnly'] == true,
      availableOnly: json['availableOnly'] == true,
      sort: byName(PetSort.values, json['sort'], PetSort.newest),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PetFilters &&
      other.gender == gender &&
      other.ageGroup == ageGroup &&
      other.vaccinatedOnly == vaccinatedOnly &&
      other.sterilizedOnly == sterilizedOnly &&
      other.availableOnly == availableOnly &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(
      gender, ageGroup, vaccinatedOnly, sterilizedOnly, availableOnly, sort);

  static DateTime _date(Pet p) =>
      p.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  /// Parses free-text ages such as "2 years", "6 months", "3 mois",
  /// "8 weeks" or "1.5" into years. Returns null when no number is found.
  static double? parseAgeYears(String raw) {
    final text = raw.toLowerCase();
    final match = RegExp(r'(\d+(?:[.,]\d+)?)').firstMatch(text);
    if (match == null) return null;
    final n = double.tryParse(match.group(1)!.replaceAll(',', '.'));
    if (n == null) return null;
    if (RegExp(r'(week|sem|smenn)').hasMatch(text)) return n / 52;
    if (RegExp(r'(month|mois|mwa|\bm\b|mo\b)').hasMatch(text)) return n / 12;
    return n;
  }

  /// Young: under 1 year, adult: 1–7, senior: over 7. Unknown ages
  /// return [AgeGroup.any] and are hidden only when an age filter is on.
  static AgeGroup ageGroupOf(String raw) {
    final years = parseAgeYears(raw);
    if (years == null) return AgeGroup.any;
    if (years < 1) return AgeGroup.young;
    if (years <= 7) return AgeGroup.adult;
    return AgeGroup.senior;
  }
}
