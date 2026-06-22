import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class ApiClient {
  late final Dio _dio;
  // Dynamically compute the API Base URL to work across different developers' local setups:
  // - Flutter Web: connects to the same host that serves the web page.
  // - Android Emulator: connects to 10.0.2.2 (special loopback for emulator).
  // - iOS Simulator / Desktop: connects to localhost.
  static String get _baseUrl {
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    if (kDebugMode) {
      // Dành cho phát triển local
      // - Nếu dùng Android Emulator: dùng 'http://10.0.2.2:5109/api/'
      // - Nếu dùng iOS Simulator / Web / Desktop: dùng 'http://localhost:5109/api/'
      // - Nếu dùng thiết bị thật (như điện thoại Android qua Wi-Fi): hãy đổi thành IP máy tính của bạn (VD: 'http://192.168.1.5:5109/api/')
      
      return 'http://192.168.1.10:5109/api/'; // Hoặc thay đổi theo nhu cầu test thiết bị ở đây
    }
    // Production Render API endpoint
    return 'https://kidio-be.onrender.com/api/';
  }
  Future<bool> Function()? onRefreshToken;

  ApiClient({Dio? dio, String? authToken}) {
    _dio = dio ?? Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
      ),
    );

    // Bypass SSL certificate validation for non-web platforms (to handle self-signed certs on real devices)
    if (!kIsWeb) {
      _dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.connectionTimeout = const Duration(seconds: 10);
          client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
          return client;
        },
      );
    }

    _dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException e, handler) async {
        final path = e.requestOptions.path.toLowerCase();
        if (e.response?.statusCode == 401 && onRefreshToken != null && !path.contains('refresh') && !path.contains('login')) {
          final success = await onRefreshToken!();
          if (success) {
            final options = e.requestOptions;
            options.headers['Authorization'] = _dio.options.headers['Authorization'];
            try {
              final response = await _dio.fetch(options);
              return handler.resolve(response);
            } catch (retryError) {
              return handler.next(e);
            }
          }
        }

        String message = 'Đã có lỗi xảy ra, vui lòng thử lại sau';
        if (e.response != null) {
          final dynamic data = e.response?.data;
          int? statusCode = e.response?.statusCode;
          
          if (data is Map) {
            message = data['message'] ?? data['Message'] ?? e.response?.statusMessage ?? 'Lỗi hệ thống ($statusCode)';
            // Xử lý lỗi validation từ .NET
            if (data['errors'] != null) {
              final errors = data['errors'];
              if (errors is Map) {
                message = errors.values.expand((v) => v is List ? v : [v]).join("\n");
              }
            }
          } else if (data is String && data.isNotEmpty) {
            message = data;
          } else {
            message = 'Lỗi từ máy chủ ($statusCode)';
          }
          final apiException = ApiException(message, statusCode: statusCode);
          return handler.next(e.copyWith(error: apiException));
        }

        // Xử lý lỗi kết nối mạng
        if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
          message = 'Kết nối quá chậm, vui lòng kiểm tra lại mạng Wi-Fi';
        } else if (e.type == DioExceptionType.connectionError) {
          message = 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra IP hoặc Firewall';
        } else if (e.type == DioExceptionType.badCertificate) {
          message = 'Lỗi bảo mật chứng chỉ (SSL). Vui lòng cấu hình lại HTTPS';
        }

        final apiException = ApiException(message);
        return handler.next(e.copyWith(error: apiException));
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) return handler.next(e);

        final isGet = e.requestOptions.method == 'GET';
        final isRetry = e.requestOptions.extra['isRetry'] == true;

        if (isGet && !isRetry && e.error is! ApiException) {
          try {
            e.requestOptions.extra['isRetry'] = true;
            final response = await _dio.fetch(e.requestOptions);
            return handler.resolve(response);
          } catch (_) {}
        }
        return handler.next(e);
      },
    ));

    _dio.interceptors.add(LogInterceptor(
      requestHeader: true,
      responseHeader: true,
      responseBody: true,
      logPrint: (obj) => debugPrint(obj.toString()),
    ));
  }

  void setAuthToken(String? token) {
    if (token == null) {
      _dio.options.headers.remove('Authorization');
    } else {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Dio get dio => _dio;
}
