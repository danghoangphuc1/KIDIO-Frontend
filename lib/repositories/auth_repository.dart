import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_api.dart';
import '../api/api_client.dart';

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
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
    _apiClient.setAuthToken(null);
  }

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
}
