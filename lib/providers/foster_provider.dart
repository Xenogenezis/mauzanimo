import 'package:flutter/material.dart';
import '../models/foster.dart';
import '../repositories/foster_repository.dart';
import '../utils/result.dart';

class FosterProvider extends ChangeNotifier {
  final FosterRepository _repository;
  List<Foster> _fosters = [];
  bool _isLoading = false;
  String? _error;

  FosterProvider(this._repository);

  List<Foster> get fosters => _fosters;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> createFoster(Foster foster) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    final result = await _repository.createFoster(foster);
    _isLoading = false;
    return result.when(
      success: (_) { notifyListeners(); return true; },
      failure: (msg) { _error = msg; notifyListeners(); return false; },
    );
  }

  Future<bool> updateStatus(String id, String status, {DateTime? endDate}) async {
    final result = await _repository.updateFosterStatus(id, status, endDate: endDate);
    return result.isSuccess;
  }

  void clearError() { _error = null; notifyListeners(); }
}
