import 'dart:convert';

class ContentParser {
  /// Parses contentJson into a human-readable plain text string.
  /// Handles simple text blocks and Quill-like structures.
  static String parseToPlainText(String? contentJson) {
    if (contentJson == null || contentJson.isEmpty) return '';

    try {
      // Try to parse as JSON
      final dynamic decoded = jsonDecode(contentJson);

      if (decoded is List) {
        // Handle list of blocks (e.g., Quill)
        return decoded.map((block) {
          if (block is Map && block.containsKey('insert')) {
            return block['insert'].toString();
          }
          return '';
        }).join('');
      } else if (decoded is Map) {
        // Handle Map structures
        if (decoded.containsKey('ops') && decoded['ops'] is List) {
          return (decoded['ops'] as List).map((op) {
            if (op is Map && op.containsKey('insert')) {
              return op['insert'].toString();
            }
            return '';
          }).join('');
        }
        if (decoded.containsKey('blocks') && decoded['blocks'] is List) {
          return (decoded['blocks'] as List).map((block) {
            if (block is Map && block.containsKey('text')) {
              return block['text'].toString();
            }
            return '';
          }).join('\n');
        }
        if (decoded.containsKey('text')) return decoded['text'].toString();
      }
      
      return contentJson; // Fallback to raw string if format unknown
    } catch (_) {
      // If not JSON, return as is
      return contentJson;
    }
  }
}
