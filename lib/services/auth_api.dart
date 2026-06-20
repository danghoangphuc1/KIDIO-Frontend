import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../models/kidio_models.dart';

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

  Future<LoginResponse> resendVerification(String email) async {
    try {
      final response = await _dio.post('Auth/resend-verification', data: {
        'email': email,
      });
      return LoginResponse(
        success: response.data['success'] ?? false,
        message: response.data['message'],
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return LoginResponse(success: false, message: e.toString());
    }
  }

  Future<LoginResponse> forgotPassword(String email) async {
    try {
      final response = await _dio.post('Auth/forgot-password', data: {
        'email': email,
      });
      return LoginResponse(
        success: response.data['success'] ?? false,
        message: response.data['message'],
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return LoginResponse(success: false, message: e.toString());
    }
  }

  Future<LoginResponse> resetPassword({
    required String token,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    try {
      final response = await _dio.post('Auth/reset-password', data: {
        'token': token,
        'newPassword': newPassword,
        'confirmNewPassword': confirmNewPassword,
      });
      return LoginResponse(
        success: response.data['success'] ?? false,
        message: response.data['message'],
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return LoginResponse(success: false, message: e.toString());
    }
  }

  Future<LoginResponse> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    try {
      final response = await _dio.post('Auth/change-password', data: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
        'confirmNewPassword': confirmNewPassword,
      });
      return LoginResponse(
        success: response.data['success'] ?? false,
        message: response.data['message'],
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return LoginResponse(success: false, message: e.toString());
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('Auth/logout');
    } catch (e) {
      rethrow;
    }
  }

  // --- Parental PIN APIs ---
  Future<LoginResponse> setParentPin(String userId, String newPin) async {
    try {
      final response = await _dio.post('users/parent-pin', data: {
        'userId': userId,
        'newPin': newPin,
      });
      return LoginResponse(
        success: response.data['success'] ?? true, // Assume true if 200 OK
        message: response.data['message'],
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return LoginResponse(success: false, message: e.toString());
    }
  }

  Future<LoginResponse> verifyPassword(String userId, String password) async {
    try {
      final response = await _dio.post('users/verify-password', data: {
        'userId': userId,
        'password': password,
      });
      final bool isSuccess = response.data['data'] == true;
      return LoginResponse(
        success: isSuccess,
        message: response.data['message'],
      );
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return LoginResponse(success: false, message: e.toString());
    }
  }

  Future<UserProfile> getCurrentUser() async {
    try {
      final response = await _dio.get('Auth/me');
      final data = response.data['data'] ?? response.data;
      return UserProfile.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  LoginResponse _handleDioError(DioException e) {
    if (e.error is ApiException) {
      return LoginResponse(success: false, message: (e.error as ApiException).message);
    }

    String errorMsg = "Lỗi kết nối mạng";
    final dynamic responseData = e.response?.data;
    if (responseData is Map) {
      errorMsg = responseData['message'] ?? responseData['Message'] ?? "Đã có lỗi xảy ra";
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
      if (e.type == DioExceptionType.connectionTimeout) {
        errorMsg = "Kết nối quá chậm, vui lòng thử lại";
      } else if (e.type == DioExceptionType.connectionError) {
        errorMsg = "Không thể kết nối đến máy chủ";
      }
    }
    return LoginResponse(success: false, message: errorMsg);
  }
}
