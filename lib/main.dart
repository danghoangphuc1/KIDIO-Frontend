import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'api/api_client.dart';
import 'repositories/topic_repository.dart';
import 'repositories/auth_repository.dart';
import 'services/auth_api.dart';
import 'providers/topic_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/topics_list_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  await Hive.openBox('kidio_cache');
  
  final apiClient = ApiClient();
  final authApi = AuthApi(apiClient.dio);
  final authRepository = AuthRepository(authApi, apiClient);
  final topicRepository = TopicRepository(apiClient);

  apiClient.onRefreshToken = authRepository.refreshIfNeeded;

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: topicRepository),
        Provider.value(value: authRepository),
        ChangeNotifierProvider(
          create: (context) => AuthProvider(authRepository)..tryRestoreSession(),
        ),
        ChangeNotifierProxyProvider<AuthRepository, TopicProvider>(
          create: (context) => TopicProvider(topicRepository),
          update: (context, auth, previous) => previous ?? TopicProvider(topicRepository),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KIDIO Client',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.watch<AuthProvider>().isAuthenticated;
    return isAuthenticated ? const TopicsListScreen() : const LoginScreen();
  }
}
