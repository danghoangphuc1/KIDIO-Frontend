import 'package:dio/dio.dart';

class LoginResponse {
  final bool success;
  final String? accessToken;
  final String? refreshToken;
  final String? message;

  LoginResponse({required this.success, this.accessToken, this.refreshToken, this.message});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return LoginResponse(
      success: json['success'] ?? false,
      accessToken: data != null ? data['accessToken'] : null,
      refreshToken: data != null ? data['refreshToken'] : null,
      message: json['message'],
    );
  }
}

class AuthApi {
  final Dio _dio;

  AuthApi(this._dio);

  Future<LoginResponse> loginWithGoogle(String idToken) async {
    try {
      final response = await _dio.post('Auth/google', data: {
        'idToken': idToken,
      });

      if (response.data is Map<String, dynamic>) {
        return LoginResponse.fromJson(response.data);
      }
      return LoginResponse(success: false, message: "Server returned invalid format");
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return LoginResponse(success: false, message: e.toString());
    }
  }

  Future<LoginResponse> login(String email, String password) async {
    try {
      final response = await _dio.post('Auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.data is Map<String, dynamic>) {
        return LoginResponse.fromJson(response.data);
      }
      return LoginResponse(success: false, message: "Server returned invalid format");
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return LoginResponse(success: false, message: e.toString());
    }
  }

  Future<LoginResponse> register({
    required String email,
    required String password,
    required String confirmPassword,
    required String displayName,
  }) async {
    try {
      final response = await _dio.post('Auth/register', data: {
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
        'displayName': displayName,
      });

      if (response.data is Map<String, dynamic>) {
        // Register returns RegisterResponse in data, but we might want to map it to success/message
        final success = response.data['success'] ?? false;
        final message = response.data['message'] ?? (success ? "Registration successful" : "Registration failed");
        return LoginResponse(success: success, message: message);
      }
      return LoginResponse(success: false, message: "Server returned invalid format");
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return LoginResponse(success: false, message: e.toString());
    }
  }

  Future<LoginResponse> refresh(String refreshToken) async {
    try {
      final response = await _dio.post('Auth/refresh', data: {
        'refreshToken': refreshToken,
      });
      return LoginResponse.fromJson(response.data);
    } catch (_) {
      return LoginResponse(success: false);
    }
  }

  LoginResponse _handleDioError(DioException e) {
    String errorMsg = "Connection error";
    final dynamic responseData = e.response?.data;
    if (responseData is Map) {
      errorMsg = responseData['message'] ?? e.message ?? "Unknown error";
      // Handle validation errors if any
      if (responseData['errors'] != null) {
        final errors = responseData['errors'];
        if (errors is List) {
          errorMsg = errors.join("\n");
        } else if (errors is Map) {
          errorMsg = errors.values.expand((v) => v is List ? v : [v]).join("\n");
        }
      }
    } else if (responseData is String && responseData.isNotEmpty) {
      errorMsg = responseData;
    } else {
      errorMsg = "Error ${e.response?.statusCode}: ${e.message}";
    }
    return LoginResponse(success: false, message: errorMsg);
  }
}
