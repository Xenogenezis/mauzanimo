import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/pet_repository.dart';
import '../models/pet.dart';
import '../models/pet_preferences.dart';
import '../models/pet_filters.dart';
import '../models/saved_search.dart';
import '../utils/new_since.dart';
import '../utils/result.dart';

class PetProvider extends ChangeNotifier {
  final PetRepository _petRepository;

  List<Pet> _pets = [];
  List<Pet> _filteredPets = [];
  String _searchQuery = '';
  String _selectedFilter = 'All';
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _currentLimit = 20;
  StreamSubscription<List<Pet>>? _subscription;
  PetPreferences? _preferences;

  /// SharedPreferences keys for the device-local list features.
  static const lastVisitKey = 'pet_list_last_visit_ms';
  static const savedSearchesKey = 'pet_saved_searches';

  final Future<SharedPreferences> Function() _prefs;

  PetProvider(this._petRepository,
      {Future<SharedPreferences> Function()? prefs})
      : _prefs = prefs ?? SharedPreferences.getInstance {
    _setupStream();
    _loadLocalState();
  }

  // Getters
  List<Pet> get pets => _filteredPets;
  String get searchQuery => _searchQuery;
  String get selectedFilter => _selectedFilter;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;

  // Available filters
  List<String> get filters => ['All', 'Dogs', 'Cats', 'Others'];

  void _setupStream() {
    _subscription?.cancel();
    final result = _petRepository.getPetsStream(
      typeFilter: _selectedFilter,
      limit: _currentLimit,
    );
    result.when(
      success: (stream) {
        _subscription = stream.listen(
          (pets) {
            _pets = pets;
            _hasMore = pets.length >= _currentLimit;
            _applyFilters();
          },
          onError: (error) {
            _error = 'Failed to load pets. Please try again.';
            _isLoading = false;
            notifyListeners();
          },
        );
      },
      failure: (message) {
        _error = message;
        notifyListeners();
      },
    );
  }

  void _applyFilters() {
    // Moderated (hidden) pets never show in the list.
    var result = _pets.where((pet) => !pet.hidden).toList();

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((pet) {
        return pet.name.toLowerCase().contains(query) ||
            pet.location.toLowerCase().contains(query) ||
            pet.description.toLowerCase().contains(query);
      }).toList();
    }

    if (_preferences != null) {
      final prefs = _preferences!;
      if (prefs.types.isNotEmpty) {
        result = result.where((p) => prefs.types.contains(p.type.toLowerCase())).toList();
      }
      if (prefs.gender != null && prefs.gender != 'any') {
        result = result.where((p) => p.gender.toLowerCase() == prefs.gender!.toLowerCase()).toList();
      }
      if (prefs.preferredLocation != null && prefs.preferredLocation!.isNotEmpty) {
        result = result.where((p) => p.location.toLowerCase().contains(prefs.preferredLocation!.toLowerCase())).toList();
      }
      if (prefs.ageRange != 'any') {
        result = result.where((p) => _matchesAgeRange(p.age, prefs.ageRange)).toList();
      }
    }

    _filteredPets = _listFilters.apply(result);
    notifyListeners();
  }

  PetFilters _listFilters = PetFilters.none;
  PetFilters get listFilters => _listFilters;

  void setListFilters(PetFilters filters) {
    _listFilters = filters;
    _applyFilters();
  }

  // ---- "New since your last visit" (device-local) ----

  /// Time of the previous visit, read once at start-up. It stays fixed for
  /// this session, so ribbons do not vanish when the user briefly leaves.
  DateTime? _lastVisit;
  bool _newBannerDismissed = false;
  List<SavedSearch> _savedSearches = [];

  DateTime? get lastVisit => _lastVisit;

  /// Whether [pet] was created after the previous visit.
  bool isNewPet(Pet pet) => isNewSince(pet, _lastVisit);

  /// New pets among those currently shown.
  int get newPetCount => countNewSince(_filteredPets, _lastVisit);

  bool get showNewBanner => !_newBannerDismissed && newPetCount > 0;

  void dismissNewBanner() {
    _newBannerDismissed = true;
    notifyListeners();
  }

  Future<void> _loadLocalState() async {
    try {
      final prefs = await _prefs();
      final ms = prefs.getInt(lastVisitKey);
      _lastVisit = ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
      _savedSearches =
          SavedSearch.decodeList(prefs.getString(savedSearchesKey));
      notifyListeners();
    } catch (_) {
      // No storage (tests, private browsing): the features stay off.
    }
  }

  /// Records "now" as the last visit. Called when the user leaves the pet
  /// list or the app, not on open, so the current visit still shows what
  /// was added since the previous one.
  Future<void> markVisited([DateTime? now]) async {
    try {
      final prefs = await _prefs();
      await prefs.setInt(
          lastVisitKey, (now ?? DateTime.now()).millisecondsSinceEpoch);
    } catch (_) {}
  }

  // ---- Saved searches / local pet alerts ----

  List<SavedSearch> get savedSearches => List.unmodifiable(_savedSearches);

  bool get canSaveSearch => _savedSearches.length < SavedSearch.maxCount;

  Future<void> _persistSavedSearches() async {
    try {
      final prefs = await _prefs();
      await prefs.setString(
          savedSearchesKey, SavedSearch.encodeList(_savedSearches));
    } catch (_) {}
  }

  /// Saves the current type chip, sheet [filters] (defaults to the active
  /// ones) and search text under [name]. Returns false when the limit of
  /// [SavedSearch.maxCount] is reached or the name is empty.
  Future<bool> saveCurrentSearch(String name, {PetFilters? filters}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || !canSaveSearch) return false;
    final now = DateTime.now();
    _savedSearches = [
      ..._savedSearches,
      SavedSearch(
        id: now.microsecondsSinceEpoch.toString(),
        name: trimmed,
        typeFilter: _selectedFilter,
        filters: filters ?? _listFilters,
        query: _searchQuery,
        lastOpened: now,
      ),
    ];
    notifyListeners();
    await _persistSavedSearches();
    return true;
  }

  Future<void> deleteSavedSearch(String id) async {
    _savedSearches = _savedSearches.where((s) => s.id != id).toList();
    notifyListeners();
    await _persistSavedSearches();
  }

  /// Applies [search] to the list and marks the alert as opened now.
  Future<void> applySavedSearch(SavedSearch search) async {
    _searchQuery = search.query;
    _listFilters = search.filters;
    if (_selectedFilter != search.typeFilter) {
      _selectedFilter = search.typeFilter;
      _currentLimit = 20;
      _hasMore = true;
      _setupStream();
    }
    _applyFilters();
    _savedSearches = [
      for (final s in _savedSearches)
        s.id == search.id ? s.copyWith(lastOpened: DateTime.now()) : s,
    ];
    notifyListeners();
    await _persistSavedSearches();
  }

  /// Recent pets of every type, used to count new matches for the alerts.
  /// Uses the same query as the list (no extra index).
  Future<List<Pet>> recentPetsForAlerts({int limit = 100}) async {
    final result =
        _petRepository.getPetsStream(typeFilter: 'All', limit: limit);
    return result.when(
      success: (stream) async {
        try {
          return await stream.first.timeout(const Duration(seconds: 10));
        } catch (_) {
          return _pets;
        }
      },
      failure: (_) async => _pets,
    );
  }

  void setPreferences(PetPreferences? prefs) {
    _preferences = prefs;
    _applyFilters();
  }

  bool _matchesAgeRange(String petAge, String range) {
    // "6 months" used to parse as 6 years; the shared parser handles units.
    final group = PetFilters.ageGroupOf(petAge);
    if (group == AgeGroup.any) return true;
    return range == 'any' || group.name == range;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void setFilter(String filter) {
    if (_selectedFilter == filter) return;
    _selectedFilter = filter;
    _currentLimit = 20;
    _hasMore = true;
    _setupStream();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    _currentLimit += 20;
    _setupStream();

    _isLoadingMore = false;
    notifyListeners();
  }

  Future<bool> addPet(Pet pet) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _petRepository.addPet(pet);
    final success = result.when(
      success: (_) {
        _isLoading = false;
        notifyListeners();
        return true;
      },
      failure: (message) {
        _error = message;
        _isLoading = false;
        notifyListeners();
        return false;
      },
    );
    return success;
  }

  Future<bool> updatePet(Pet pet) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _petRepository.updatePet(pet);
    final success = result.when(
      success: (_) {
        _isLoading = false;
        notifyListeners();
        return true;
      },
      failure: (message) {
        _error = message;
        _isLoading = false;
        notifyListeners();
        return false;
      },
    );
    return success;
  }

  Future<bool> deletePet(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _petRepository.deletePet(id);
    final success = result.when(
      success: (_) {
        _isLoading = false;
        notifyListeners();
        return true;
      },
      failure: (message) {
        _error = message;
        _isLoading = false;
        notifyListeners();
        return false;
      },
    );
    return success;
  }

  Future<Pet?> getPetById(String id) async {
    final result = await _petRepository.getPetById(id);
    return result.when(
      success: (pet) => pet,
      failure: (message) {
        _error = message;
        return null;
      },
    );
  }

  Stream<List<Pet>> getUserPetsStream(String userId) {
    final result = _petRepository.getUserPetsStream(userId);
    return result.when(
      success: (stream) => stream,
      failure: (message) {
        _error = message;
        return Stream.value([]);
      },
    );
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
