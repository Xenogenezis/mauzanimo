import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/auth_repository.dart';
import '../models/user_profile.dart';
import '../utils/result.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  User? _user;
  UserProfile? _userProfile;
  String? _error;
  bool _isLoading = false;
  bool _isProfileLoading = false;

  AuthProvider(this._authRepository) {
    _user = _authRepository.currentUser;
    _authRepository.authStateChanges.listen((user) async {
      _user = user;
      if (user != null) {
        await _loadUserProfile(user.uid);
      } else {
        _userProfile = null;
      }
      notifyListeners();
    });
  }

  // Getters
  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  bool get isProfileLoading => _isProfileLoading;
  String? get error => _error;
  String? get uid => _user?.uid;
  String? get email => _user?.email;
  String get displayName => _userProfile?.name ?? _user?.email ?? 'User';

  // Load user profile from Firestore
  Future<void> _loadUserProfile(String uid) async {
    _isProfileLoading = true;
    notifyListeners();

    final result = await _authRepository.getUserProfile(uid);
    result.when(
      success: (profile) {
        _userProfile = profile;
      },
      failure: (message) {
        // Profile not found is okay
        _userProfile = null;
      },
    );

    _isProfileLoading = false;
    notifyListeners();
  }

  // Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authRepository.signIn(email, password);
    final success = result.when(
      success: (credential) {
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

  // Register with email and password
  Future<bool> register(String email, String password, String name, {String? phone}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authRepository.register(email, password, name, phone: phone);
    final success = result.when(
      success: (credential) {
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

  // Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    final result = await _authRepository.signOut();
    result.when(
      success: (_) {
        // Success
      },
      failure: (message) {
        _error = message;
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  // Send password reset email
  Future<bool> sendPasswordReset(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authRepository.sendPasswordReset(email);
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

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh user profile
  Future<void> refreshProfile() async {
    if (_user != null) {
      await _loadUserProfile(_user!.uid);
    }
  }
}
