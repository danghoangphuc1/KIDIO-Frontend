import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:kidio_client/api/api_client.dart';
import 'package:kidio_client/services/auth_api.dart';
import 'package:kidio_client/repositories/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

@GenerateMocks([AuthApi, ApiClient, Dio, FlutterSecureStorage])
import 'auth_repository_test.mocks.dart';

void main() {
  group('AuthRepository Tests', () {
    late MockAuthApi mockAuthApi;
    late MockApiClient mockApiClient;
    late MockFlutterSecureStorage mockStorage;
    late AuthRepository repository;

    setUp(() {
      mockAuthApi = MockAuthApi();
      mockApiClient = MockApiClient();
      mockStorage = MockFlutterSecureStorage();
      repository = AuthRepository(mockAuthApi, mockApiClient, storage: mockStorage);
    });

    test('loginWithGoogle success updates ApiClient token and stores it', () async {
      final loginResponse = LoginResponse(
        success: true,
        accessToken: 'test_token',
        refreshToken: 'test_refresh'
      );

      when(mockAuthApi.loginWithGoogle(any)).thenAnswer((_) async => loginResponse);
      when(mockStorage.write(key: anyNamed('key'), value: anyNamed('value')))
          .thenAnswer((_) async => {});

      await repository.loginWithGoogle('google_id_token');

      verify(mockAuthApi.loginWithGoogle('google_id_token')).called(1);
      verify(mockStorage.write(key: 'accessToken', value: 'test_token')).called(1);
      verify(mockApiClient.setAuthToken('test_token')).called(1);
    });

    test('logout clears ApiClient token and storage', () async {
      when(mockStorage.delete(key: anyNamed('key'))).thenAnswer((_) async => {});
      
      await repository.logout();
      
      verify(mockStorage.delete(key: 'accessToken')).called(1);
      verify(mockApiClient.setAuthToken(null)).called(1);
    });
  });
}
