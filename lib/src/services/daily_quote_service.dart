import 'dart:convert';

import 'package:http/http.dart' as http;

class DailyQuoteService {
  DailyQuoteService({http.Client? client}) : _client = client;

  final http.Client? _client;

  Future<String> fetchQuote() async {
    final client = _client ?? http.Client();
    try {
      final uri = Uri.parse(
        'https://v.api.aa1.cn/api/yiyan/index.php?type=json',
      );
      final response = await client.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError(
          'Daily quote request failed (${response.statusCode}).',
        );
      }

      final body = utf8.decode(response.bodyBytes, allowMalformed: true);
      return parseQuotePayload(body);
    } finally {
      if (_client == null) {
        client.close();
      }
    }
  }

  static String parseQuotePayload(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Daily quote payload must be a JSON object.');
    }

    final payload = decoded.cast<String, Object?>();
    final quote = cleanQuoteBody('${payload['yiyan'] ?? ''}');
    final source = cleanQuoteBody('${payload['from'] ?? ''}');
    if (quote.isEmpty) {
      throw const FormatException('Daily quote payload is empty.');
    }
    if (source.isEmpty || source == quote) {
      return quote;
    }
    return '$quote\n- $source';
  }

  static String cleanQuoteBody(String raw) {
    var cleaned = raw.trim();
    if (cleaned.isEmpty) {
      return '';
    }

    cleaned = cleaned
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&ldquo;', '"')
        .replaceAll('&rdquo;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&amp;', '&');

    final lines = cleaned
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    return lines.join('\n');
  }
}
