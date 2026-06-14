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
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
