import 'package:flutter/material.dart';
import '../repositories/lost_found_repository.dart';
import '../models/lost_found.dart';

class LostFoundProvider extends ChangeNotifier {
  final LostFoundRepository _repository;

  List<LostFound> _reports = [];
  List<LostFound> _filteredReports = [];
  String _selectedFilter = 'All';
  bool _isLoading = false;
  String? _error;

  LostFoundProvider(this._repository) {
    // Listen to reports stream
    _repository.getLostFoundStream().listen((reports) {
      _reports = reports;
      _applyFilters();
    });
  }

  // Getters
  List<LostFound> get reports => _filteredReports;
  String get selectedFilter => _selectedFilter;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Available filters
  List<String> get filters => ['All', 'Lost', 'Found'];

  // Get reports stream for UI
  Stream<List<LostFound>> get reportsStream =>
      _repository.getLostFoundStream(typeFilter: _selectedFilter);

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

    try {
      await _repository.addLostFound(report);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update a report
  Future<bool> updateReport(LostFound report) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.updateLostFound(report);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete a report
  Future<bool> deleteReport(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.deleteLostFound(id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get report by ID
  Future<LostFound?> getReportById(String id) async {
    try {
      return await _repository.getLostFoundById(id);
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
