import 'package:flutter/material.dart';
import '../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider(this._repository);

  Future<void> tryRestoreSession() async {
    final token = await _repository.tryRestoreSession();
    _isAuthenticated = token != null;
    notifyListeners();
  }

  Future<bool> loginWithGoogle(String idToken) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.loginWithGoogle(idToken);
      if (response.success) {
        _isAuthenticated = true;
        return true;
      } else {
        _errorMessage = response.message ?? 'Login failed';
        return false;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.login(email, password);
      if (response.success) {
        _isAuthenticated = true;
        return true;
      } else {
        _errorMessage = response.message ?? 'Login failed';
        return false;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String confirmPassword,
    required String displayName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.register(
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        displayName: displayName,
      );
      if (response.success) {
        return true;
      } else {
        _errorMessage = response.message ?? 'Registration failed';
        return false;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    _isAuthenticated = false;
    notifyListeners();
  }
}
