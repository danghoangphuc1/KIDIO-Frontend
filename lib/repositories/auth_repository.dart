import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_api.dart';
import '../api/api_client.dart';
import '../models/kidio_models.dart';

class AuthRepository {
  final AuthApi _authApi;
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage;

  AuthRepository(this._authApi, this._apiClient, {FlutterSecureStorage? storage}) 
      : _storage = storage ?? const FlutterSecureStorage();

  Future<LoginResponse> loginWithGoogle(String idToken) async {
    final response = await _authApi.loginWithGoogle(idToken);
    if (response.success && response.accessToken != null) {
      await _storage.write(key: 'accessToken', value: response.accessToken);
      await _storage.write(key: 'refreshToken', value: response.refreshToken);
      _apiClient.setAuthToken(response.accessToken);
    }
    return response;
  }

  Future<LoginResponse> login(String email, String password) async {
    final response = await _authApi.login(email, password);
    if (response.success && response.accessToken != null) {
      await _storage.write(key: 'accessToken', value: response.accessToken);
      await _storage.write(key: 'refreshToken', value: response.refreshToken);
      _apiClient.setAuthToken(response.accessToken);
    }
    return response;
  }

  Future<LoginResponse> register({
    required String email,
    required String password,
    required String confirmPassword,
    required String displayName,
  }) async {
    return await _authApi.register(
      email: email,
      password: password,
      confirmPassword: confirmPassword,
      displayName: displayName,
    );
  }

  Future<LoginResponse> resendVerification(String email) => _authApi.resendVerification(email);

  Future<LoginResponse> forgotPassword(String email) => _authApi.forgotPassword(email);

  Future<LoginResponse> resetPassword({
    required String token,
    required String newPassword,
    required String confirmNewPassword,
  }) =>
      _authApi.resetPassword(
        token: token,
        newPassword: newPassword,
        confirmNewPassword: confirmNewPassword,
      );

  Future<LoginResponse> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) =>
      _authApi.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
        confirmNewPassword: confirmNewPassword,
      );

  Future<void> logout() async {
    try {
      await _authApi.logout();
    } catch (_) {
      // Ignore API errors on logout
    }
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
    _apiClient.setAuthToken(null);
  }

  Future<UserProfile> getCurrentUser() => _authApi.getCurrentUser();

  Future<String?> tryRestoreSession() async {
    final token = await _storage.read(key: 'accessToken');
    if (token != null) {
      _apiClient.setAuthToken(token);
    }
    return token;
  }

  Future<bool> refreshIfNeeded() async {
    final rt = await _storage.read(key: 'refreshToken');
    if (rt == null) return false;

    final response = await _authApi.refresh(rt);
    if (response.success && response.accessToken != null) {
      await _storage.write(key: 'accessToken', value: response.accessToken);
      if (response.refreshToken != null) {
        await _storage.write(key: 'refreshToken', value: response.refreshToken);
      }
      _apiClient.setAuthToken(response.accessToken);
      return true;
    }
    return false;
  }

  // --- Parental PIN Logic ---
  String _getPinKey(String userId) => 'parent_pin_$userId';
  String _getLockTimeKey(String userId) => 'pin_lock_time_$userId';
  String _getWrongAttemptsKey(String userId) => 'pin_wrong_attempts_$userId';

  Future<bool> hasParentPin(String userId) async {
    final pin = await _storage.read(key: _getPinKey(userId));
    return pin != null && pin.isNotEmpty;
  }

  Future<LoginResponse> setParentPin(String userId, String pin) async {
    // Gọi API Backend để lưu PIN
    final response = await _authApi.setParentPin(userId, pin);
    if (response.success) {
      // Lưu Local nếu API thành công
      await _storage.write(key: _getPinKey(userId), value: pin);
      // Reset số lần nhập sai
      await _storage.delete(key: _getWrongAttemptsKey(userId));
      await _storage.delete(key: _getLockTimeKey(userId));
    }
    return response;
  }

  Future<bool> verifyParentPin(String userId, String inputPin) async {
    final pin = await _storage.read(key: _getPinKey(userId));
    return pin == inputPin;
  }

  Future<void> deleteParentPin(String userId) async {
    await _storage.delete(key: _getPinKey(userId));
  }

  Future<LoginResponse> verifyPassword(String userId, String password) async {
    return await _authApi.verifyPassword(userId, password);
  }

  // Anti brute-force
  Future<int> getWrongPinAttempts(String userId) async {
    final val = await _storage.read(key: _getWrongAttemptsKey(userId));
    return int.tryParse(val ?? '0') ?? 0;
  }

  Future<void> incrementWrongPinAttempts(String userId) async {
    final attempts = await getWrongPinAttempts(userId);
    await _storage.write(key: _getWrongAttemptsKey(userId), value: (attempts + 1).toString());
  }

  Future<void> resetWrongPinAttempts(String userId) async {
    await _storage.delete(key: _getWrongAttemptsKey(userId));
  }

  Future<DateTime?> getPinLockExpiration(String userId) async {
    final val = await _storage.read(key: _getLockTimeKey(userId));
    if (val == null) return null;
    return DateTime.tryParse(val);
  }

  Future<void> setPinLockExpiration(String userId, DateTime expiration) async {
    await _storage.write(key: _getLockTimeKey(userId), value: expiration.toIso8601String());
  }
}
