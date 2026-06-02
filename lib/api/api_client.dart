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
  // Updated to machine IP from ipconfig
  static const String _baseUrl = 'https://192.168.88.147:7014/api/';
  Future<bool> Function()? onRefreshToken;

  ApiClient({Dio? dio, String? authToken}) {
    _dio = dio ?? Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
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
          client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
          return client;
        },
      );
    }

    _dio.interceptors.add(InterceptorsWrapper(
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401 && onRefreshToken != null) {
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

        String message = 'An unexpected error occurred';
        if (e.response != null) {
          if (e.response?.data is Map) {
            message = e.response?.data?['message'] ?? e.response?.statusMessage ?? message;
          } else {
            message = e.response?.data?.toString() ?? e.response?.statusMessage ?? message;
          }
          final apiException = ApiException(message, statusCode: e.response?.statusCode);
          return handler.next(e.copyWith(error: apiException));
        }
        return handler.next(e);
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
