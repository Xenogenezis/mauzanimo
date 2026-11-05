import 'dart:convert';

import 'pet.dart';
import 'pet_filters.dart';

/// A pet-list search the user saved as a local "alert": the type chip,
/// the filter sheet values and the search text, under a name.
/// Stored on the device only (SharedPreferences), never in Firestore.
class SavedSearch {
  /// Most saved searches a user can keep.
  static const maxCount = 5;

  final String id;
  final String name;
  final String typeFilter; // 'All', 'Dogs', 'Cats', 'Others'
  final PetFilters filters;
  final String query;

  /// When the alert was saved or last opened; pets created after this
  /// count as "new matches".
  final DateTime lastOpened;

  const SavedSearch({
    required this.id,
    required this.name,
    this.typeFilter = 'All',
    this.filters = PetFilters.none,
    this.query = '',
    required this.lastOpened,
  });

  SavedSearch copyWith({String? name, DateTime? lastOpened}) => SavedSearch(
        id: id,
        name: name ?? this.name,
        typeFilter: typeFilter,
        filters: filters,
        query: query,
        lastOpened: lastOpened ?? this.lastOpened,
      );

  /// Same rules as the pet list: the type chip mirrors the Firestore
  /// `type == typeFilter.toLowerCase()` query, the text matches name,
  /// location or description, then the sheet filters.
  bool matches(Pet pet) {
    if (typeFilter != 'All' &&
        pet.type.toLowerCase() != typeFilter.toLowerCase()) {
      return false;
    }
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty &&
        !pet.name.toLowerCase().contains(q) &&
        !pet.location.toLowerCase().contains(q) &&
        !pet.description.toLowerCase().contains(q)) {
      return false;
    }
    return filters.matches(pet);
  }

  /// Pets that match and were created after [lastOpened].
  int newMatchCount(Iterable<Pet> pets) => pets
      .where((p) =>
          p.createdAt != null &&
          p.createdAt!.isAfter(lastOpened) &&
          matches(p))
      .length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'typeFilter': typeFilter,
        'filters': filters.toJson(),
        'query': query,
        'lastOpened': lastOpened.millisecondsSinceEpoch,
      };

  factory SavedSearch.fromJson(Map<String, dynamic> json) => SavedSearch(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        typeFilter: json['typeFilter'] as String? ?? 'All',
        filters: json['filters'] is Map
            ? PetFilters.fromJson(
                Map<String, dynamic>.from(json['filters'] as Map))
            : PetFilters.none,
        query: json['query'] as String? ?? '',
        lastOpened: DateTime.fromMillisecondsSinceEpoch(
            (json['lastOpened'] as num?)?.toInt() ?? 0),
      );

  /// Encodes a list for SharedPreferences.
  static String encodeList(List<SavedSearch> list) =>
      jsonEncode([for (final s in list) s.toJson()]);

  /// Decodes a stored list; corrupt data yields an empty list and bad
  /// entries are skipped. Never returns more than [maxCount].
  static List<SavedSearch> decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((m) => SavedSearch.fromJson(Map<String, dynamic>.from(m)))
          .where((s) => s.id.isNotEmpty)
          .take(maxCount)
          .toList();
    } on FormatException {
      return [];
    }
  }
}
