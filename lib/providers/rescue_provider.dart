import 'package:flutter/material.dart';
import '../models/rescue_report.dart';
import '../repositories/rescue_repository.dart';
import '../utils/result.dart';

class RescueProvider extends ChangeNotifier {
  final RescueRepository _repository;
  final List<RescueReport> _reports = [];
  bool _isLoading = false;
  String? _error;

  RescueProvider(this._repository);

  List<RescueReport> get reports => _reports;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> createReport(RescueReport report) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    final result = await _repository.createReport(report);
    _isLoading = false;
    return result.when(
      success: (_) { notifyListeners(); return true; },
      failure: (msg) { _error = msg; notifyListeners(); return false; },
    );
  }

  Future<bool> assignVolunteer(String id, String volunteerId, String volunteerName) async {
    final result = await _repository.assignVolunteer(id, volunteerId, volunteerName);
    return result.isSuccess;
  }

  void clearError() { _error = null; notifyListeners(); }
}
