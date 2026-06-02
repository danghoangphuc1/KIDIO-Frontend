import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/topic_provider.dart';

class TopicsListWidget extends StatelessWidget {
  const TopicsListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TopicProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null && provider.topics.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.errorMessage}'),
                  ElevatedButton(
                    onPressed: provider.loadFirstPage,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (provider.topics.isEmpty) {
          return const Center(child: Text('No topics found.'));
        }

        return ListView.builder(
          itemCount: provider.topics.length,
          itemBuilder: (context, index) {
            final topic = provider.topics[index];
            return ListTile(
              title: Text(topic.name),
              subtitle: Text('${topic.totalLessons ?? 0} lessons'),
            );
          },
        );
      },
    );
  }
}
