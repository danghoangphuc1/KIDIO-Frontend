import 'package:flutter/material.dart';
import '../repositories/auth_repository.dart';
import '../models/kidio_models.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  UserProfile? _currentUser;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserProfile? get currentUser => _currentUser;
  bool get isAdmin => _currentUser?.roles?.contains('Admin') ?? false;

  AuthProvider(this._repository);

  Future<void> tryRestoreSession() async {
    final token = await _repository.tryRestoreSession();
    if (token != null) {
      try {
        final user = await _repository.getCurrentUser();
        
        // Prevent race conditions if the user logged out or changed session
        // while we were waiting for the slow API to respond.
        final currentToken = await _repository.tryRestoreSession();
        if (currentToken != token) return;
        
        _currentUser = user;
        _isAuthenticated = true;
      } catch (e) {
        _isAuthenticated = false;
        _currentUser = null;
      }
    } else {
      _isAuthenticated = false;
      _currentUser = null;
    }
    notifyListeners();
  }

  Future<bool> loginWithGoogle(String idToken) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.loginWithGoogle(idToken);
      if (response.success) {
        try {
          _currentUser = await _repository.getCurrentUser();
          _isAuthenticated = true;
        } catch (e) {
          _isAuthenticated = false;
          _currentUser = null;
          _errorMessage = 'Failed to fetch user profile';
          return false;
        }
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
        try {
          _currentUser = await _repository.getCurrentUser();
          _isAuthenticated = true;
        } catch (e) {
          _isAuthenticated = false;
          _currentUser = null;
          _errorMessage = 'Failed to fetch user profile';
          return false;
        }
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

  Future<bool> resendVerification(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.resendVerification(email);
      if (response.success) {
        return true;
      } else {
        _errorMessage = response.message ?? 'Failed to resend email';
        return false;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.forgotPassword(email);
      if (response.success) {
        return true;
      } else {
        _errorMessage = response.message ?? 'Yêu cầu thất bại';
        return false;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword({
    required String token,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.resetPassword(
        token: token,
        newPassword: newPassword,
        confirmNewPassword: confirmNewPassword,
      );
      if (response.success) {
        return true;
      } else {
        _errorMessage = response.message ?? 'Đặt lại mật khẩu thất bại';
        return false;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
        confirmNewPassword: confirmNewPassword,
      );
      if (response.success) {
        return true;
      } else {
        _errorMessage = response.message ?? 'Thay đổi mật khẩu thất bại';
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
    _currentUser = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // --- PIN Logic ---
  Future<bool> hasParentPin() async {
    if (_currentUser == null) return false;
    return await _repository.hasParentPin(_currentUser!.id);
  }

  Future<bool> setParentPin(String pin) async {
    if (_currentUser == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _repository.setParentPin(_currentUser!.id, pin);
      if (!response.success) {
        _errorMessage = response.message ?? 'Cập nhật mã PIN thất bại';
        return false;
      }
      return true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyParentPin(String pin) async {
    if (_currentUser == null) return false;
    return await _repository.verifyParentPin(_currentUser!.id, pin);
  }

  Future<void> deleteParentPin() async {
    if (_currentUser == null) return;
    await _repository.deleteParentPin(_currentUser!.id);
  }

  Future<bool> verifyPassword(String password) async {
    if (_currentUser == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.verifyPassword(_currentUser!.id, password);
      if (!response.success) {
        _errorMessage = response.message ?? 'Mật khẩu không chính xác';
        return false;
      }
      return true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Anti brute-force ---
  Future<int> getWrongPinAttempts() async {
    if (_currentUser == null) return 0;
    return await _repository.getWrongPinAttempts(_currentUser!.id);
  }

  Future<void> incrementWrongPinAttempts() async {
    if (_currentUser == null) return;
    await _repository.incrementWrongPinAttempts(_currentUser!.id);
  }

  Future<void> resetWrongPinAttempts() async {
    if (_currentUser == null) return;
    await _repository.resetWrongPinAttempts(_currentUser!.id);
  }

  Future<DateTime?> getPinLockExpiration() async {
    if (_currentUser == null) return null;
    return await _repository.getPinLockExpiration(_currentUser!.id);
  }

  Future<void> setPinLockExpiration(DateTime expiration) async {
    if (_currentUser == null) return;
    await _repository.setPinLockExpiration(_currentUser!.id, expiration);
  }
}
