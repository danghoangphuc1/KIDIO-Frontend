import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:kidio_client/screens/login_screen.dart';
import 'package:kidio_client/providers/auth_provider.dart';
import 'package:kidio_client/repositories/auth_repository.dart';

@GenerateMocks([AuthRepository])
import 'login_screen_test.mocks.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    late MockAuthRepository mockAuthRepository;
    late AuthProvider mockAuthProvider;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      mockAuthProvider = AuthProvider(mockAuthRepository);
    });

    Widget createWidgetUnderTest() {
      return MaterialApp(
        home: ChangeNotifierProvider<AuthProvider>.value(
          value: mockAuthProvider,
          child: const LoginScreen(),
        ),
      );
    }

    testWidgets('Should display login form elements correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Kiem tra xem co hien thi cac TextField khong
      expect(find.byType(TextField), findsNWidgets(2)); // Email & Password
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Mật khẩu'), findsOneWidget);

      // Kiem tra xem co nut DANG NHAP khong
      expect(find.text('ĐĂNG NHẬP'), findsOneWidget);
      
      // Kiem tra xem co nut DANG NHAP VOI GOOGLE khong
      expect(find.text('ĐĂNG NHẬP VỚI GOOGLE'), findsOneWidget);
    });

    testWidgets('Should show error when form is empty and submitted', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Tap vao nut Dang nhap ngay lap tuc
      await tester.tap(find.text('ĐĂNG NHẬP'));
      await tester.pump();

      // Form validation se hien thi thong bao loi
      expect(find.text('Vui lòng nhập email'), findsOneWidget);
      expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
    });
  });
}
