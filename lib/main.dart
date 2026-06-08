import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'api/api_client.dart';
import 'repositories/topic_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/child_repository.dart';
import 'repositories/progress_repository.dart';
import 'repositories/vocabulary_repository.dart';
import 'repositories/achievement_repository.dart';
import 'repositories/pronunciation_repository.dart';
import 'repositories/tts_repository.dart';
import 'services/auth_api.dart';
import 'services/child_api.dart';
import 'services/progress_api.dart';
import 'services/vocabulary_api.dart';
import 'services/achievement_api.dart';
import 'services/pronunciation_api.dart';
import 'services/tts_api.dart';
import 'services/dashboard_api.dart';
import 'repositories/dashboard_repository.dart';
import 'providers/dashboard_provider.dart';
import 'providers/topic_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/child_provider.dart';
import 'providers/progress_provider.dart';
import 'providers/pronunciation_provider.dart';
import 'screens/topics_list_screen.dart';
import 'screens/login_screen.dart';
import 'screens/child_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  await Hive.openBox('kidio_cache');
  
  final apiClient = ApiClient();
  
  // API Services
  final authApi = AuthApi(apiClient.dio);
  final childApi = ChildApi(apiClient.dio);
  final progressApi = ProgressApi(apiClient.dio);
  final vocabApi = VocabularyApi(apiClient.dio);
  final achievementApi = AchievementApi(apiClient.dio);
  final pronunciationApi = PronunciationApi(apiClient.dio);
  final ttsApi = TtsApi(apiClient.dio);
  final dashboardApi = DashboardApi(apiClient.dio);
  
  // Repositories
  final authRepository = AuthRepository(authApi, apiClient);
  final topicRepository = TopicRepository(apiClient);
  final childRepository = ChildRepository(childApi);
  final progressRepository = ProgressRepository(progressApi);
  final vocabRepository = VocabularyRepository(vocabApi);
  final achievementRepository = AchievementRepository(achievementApi);
  final pronunciationRepository = PronunciationRepository(pronunciationApi);
  final ttsRepository = TtsRepository(ttsApi);
  final dashboardRepository = DashboardRepository(dashboardApi);

  apiClient.onRefreshToken = authRepository.refreshIfNeeded;

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: topicRepository),
        Provider.value(value: authRepository),
        Provider.value(value: childRepository),
        Provider.value(value: progressRepository),
        Provider.value(value: vocabRepository),
        Provider.value(value: achievementRepository),
        Provider.value(value: pronunciationRepository),
        Provider.value(value: ttsRepository),
        Provider.value(value: dashboardRepository),
        ChangeNotifierProvider(
          create: (context) => AuthProvider(authRepository)..tryRestoreSession(),
        ),
        ChangeNotifierProvider(
          create: (context) => ChildProvider(childRepository),
        ),
        ChangeNotifierProvider(
          create: (context) => DashboardProvider(dashboardRepository),
        ),
        ChangeNotifierProxyProvider<AuthRepository, TopicProvider>(
          create: (context) => TopicProvider(topicRepository),
          update: (context, auth, previous) => previous ?? TopicProvider(topicRepository),
        ),
        ChangeNotifierProvider(
          create: (context) => ProgressProvider(progressRepository, achievementRepository),
        ),
        ChangeNotifierProvider(
          create: (context) => PronunciationProvider(pronunciationRepository),
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
      debugShowCheckedModeBanner: false,
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
    final authProvider = context.watch<AuthProvider>();
    final childProvider = context.watch<ChildProvider>();

    // 1. Nếu chưa đăng nhập -> Màn hình Login
    if (!authProvider.isAuthenticated) {
      return const LoginScreen();
    }

    // 2. Nếu đã đăng nhập, kiểm tra xem đã chọn đứa trẻ nào chưa
    if (childProvider.selectedChild == null) {
      return const ChildSelectionScreen();
    }

    // 3. Đã chọn trẻ -> Vào học
    return const TopicsListScreen();
  }
}
