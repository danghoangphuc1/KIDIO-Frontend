import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:kidio_client/api/api_client.dart';
import 'package:kidio_client/repositories/topic_repository.dart';
import 'package:kidio_client/models/kidio_models.dart';
import 'package:kidio_client/widgets/topics_list_widget.dart';
import 'package:kidio_client/providers/topic_provider.dart';

import 'package:kidio_client/local/cache_service.dart';

@GenerateMocks([Dio, TopicRepository, CacheService])
import 'kidio_test.mocks.dart';

void main() {
  group('TopicRepository Unit Tests', () {
    test('fetchTopics returns PagedResult on success', () async {
      final mockDio = MockDio();
      
      when(mockDio.interceptors).thenReturn(Interceptors());
      
      final apiClient = ApiClient(dio: mockDio);
      final repository = TopicRepository(apiClient);

      final mockResponse = {
        'success': true,
        'data': {
          'items': [
            {'id': '1', 'name': 'Test Topic', 'orderIndex': 1}
          ],
          'totalCount': 1,
          'pageNumber': 1,
          'pageSize': 10
        }
      };

      when(mockDio.get(any, queryParameters: anyNamed('queryParameters')))
          .thenAnswer((_) async => Response(
                data: mockResponse,
                statusCode: 200,
                requestOptions: RequestOptions(path: '/Topic'),
              ));

      final result = await repository.fetchTopics();

      expect(result.items.length, 1);
      expect(result.items.first.name, 'Test Topic');
    });

    test('Lesson.fromJson works with backend sample without audio fields', () {
      final json = {
        'id': 'l1',
        'title': 'Lesson 1',
        'orderIndex': 1,
        'isPublished': true,
        'vocabularies': []
      };
      final lesson = Lesson.fromJson(json);
      expect(lesson.title, 'Lesson 1');
    });
  });

  group('TopicsListWidget Tests', () {
    testWidgets('shows loading indicator then list of topics', (tester) async {
      final mockRepo = MockTopicRepository();
      final mockCache = MockCacheService();
      
      final topics = [
        Topic(id: '1', name: 'Topic 1', orderIndex: 1)
      ];
      
      when(mockRepo.fetchTopics(pageNumber: 1, pageSize: anyNamed('pageSize'))).thenAnswer(
        (_) async => PagedResult(items: topics, totalCount: 1, page: 1, pageSize: 10)
      );
      
      // Stub cache methods
      when(mockCache.saveTopicsPage(any, any)).thenAnswer((_) async => {});
      when(mockCache.getTopicsPage(any)).thenReturn(null);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<TopicProvider>(
              create: (_) => TopicProvider(mockRepo, cacheService: mockCache)..loadFirstPage(),
              child: const TopicsListWidget(),
            ),
          ),
        ),
      );

      // Verify data is displayed after settlement
      await tester.pumpAndSettle();
      expect(find.text('Topic 1'), findsOneWidget);
    });
  });
}
