import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:kidio_client/providers/auth_provider.dart';
import 'package:kidio_client/repositories/auth_repository.dart';
import 'package:kidio_client/services/auth_api.dart';
import 'package:kidio_client/models/kidio_models.dart';

@GenerateMocks([AuthRepository])
import 'auth_provider_test.mocks.dart';

void main() {
  group('AuthProvider Unit Tests', () {
    late MockAuthRepository mockRepository;
    late AuthProvider authProvider;

    setUp(() {
      mockRepository = MockAuthRepository();
      authProvider = AuthProvider(mockRepository);
    });

    test('Initial state should not be authenticated', () {
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.isLoading, false);
    });

    test('Login success should update state to authenticated', () async {
      final successResponse = LoginResponse(success: true, accessToken: 'token');
      final mockUser = UserProfile(id: '1', email: 'test@gmail.com', roles: ['User'], displayName: 'Test');
      
      when(mockRepository.login(any, any)).thenAnswer((_) async => successResponse);
      when(mockRepository.getCurrentUser()).thenAnswer((_) async => mockUser);
      
      final result = await authProvider.login('test@gmail.com', '123456');
      
      expect(result, true);
      expect(authProvider.isAuthenticated, true);
      expect(authProvider.isLoading, false);
    });

    test('Login fail should keep state as not authenticated', () async {
      final failResponse = LoginResponse(success: false, message: 'Lỗi');
      when(mockRepository.login(any, any)).thenAnswer((_) async => failResponse);
      
      final result = await authProvider.login('test@gmail.com', 'wrong_pass');
      
      expect(result, false);
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.isLoading, false);
    });
  });
}
