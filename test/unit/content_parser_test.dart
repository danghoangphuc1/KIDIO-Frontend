import 'package:flutter_test/flutter_test.dart';
import 'package:kidio_client/utils/content_parser.dart';

void main() {
  group('ContentParser Tests', () {
    test('parseToPlainText handles simple string', () {
      const input = 'Hello World';
      expect(ContentParser.parseToPlainText(input), 'Hello World');
    });

    test('parseToPlainText handles Quill-like JSON list', () {
      const input = '[{"insert": "Hello "}, {"insert": "World"}]';
      expect(ContentParser.parseToPlainText(input), 'Hello World');
    });

    test('parseToPlainText handles Quill-like JSON map with ops', () {
      const input = '{"ops": [{"insert": "Hello "}, {"insert": "Quill"}]}';
      expect(ContentParser.parseToPlainText(input), 'Hello Quill');
    });

    test('parseToPlainText returns empty for null/empty', () {
      expect(ContentParser.parseToPlainText(null), '');
      expect(ContentParser.parseToPlainText(''), '');
    });
  });
}
