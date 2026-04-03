import 'package:flutter/material.dart';
import '../repositories/lost_found_repository.dart';
import '../models/lost_found.dart';
import '../utils/result.dart';

class LostFoundProvider extends ChangeNotifier {
  final LostFoundRepository _repository;

  List<LostFound> _reports = [];
  List<LostFound> _filteredReports = [];
  String _selectedFilter = 'All';
  bool _isLoading = false;
  String? _error;

  LostFoundProvider(this._repository) {
    // Listen to reports stream
    final result = _repository.getLostFoundStream();
    result.when(
      success: (stream) {
        stream.listen((reports) {
          _reports = reports;
          _applyFilters();
        });
      },
      failure: (message) {
        _error = message;
        notifyListeners();
      },
    );
  }

  // Getters
  List<LostFound> get reports => _filteredReports;
  String get selectedFilter => _selectedFilter;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Available filters
  List<String> get filters => ['All', 'Lost', 'Found'];

  // Get reports stream for UI
  Stream<List<LostFound>> get reportsStream {
    final result = _repository.getLostFoundStream(typeFilter: _selectedFilter);
    return result.when(
      success: (stream) => stream,
      failure: (message) {
        _error = message;
        return Stream.value([]);
      },
    );
  }

  // Apply filter
  void _applyFilters() {
    if (_selectedFilter == 'All') {
      _filteredReports = _reports;
    } else {
      _filteredReports = _reports
          .where((report) => report.type == _selectedFilter)
          .toList();
    }
    notifyListeners();
  }

  // Set type filter
  void setFilter(String filter) {
    _selectedFilter = filter;
    _applyFilters();
  }

  // Add a new report
  Future<bool> addReport(LostFound report) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _repository.addLostFound(report);
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

  // Update a report
  Future<bool> updateReport(LostFound report) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _repository.updateLostFound(report);
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

  // Delete a report
  Future<bool> deleteReport(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _repository.deleteLostFound(id);
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

  // Get report by ID
  Future<LostFound?> getReportById(String id) async {
    final result = await _repository.getLostFoundById(id);
    return result.when(
      success: (report) => report,
      failure: (message) {
        _error = message;
        return null;
      },
    );
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
