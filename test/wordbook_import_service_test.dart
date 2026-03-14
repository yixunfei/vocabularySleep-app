import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/services/wordbook_import_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WordbookImportService', () {
    test('parseJsonTextAsync parses standard json payloads', () async {
      final service = WordbookImportService();
      final entries = await service.parseJsonTextAsync(
        jsonEncode(<Map<String, Object?>>[
          <String, Object?>{
            'word': 'alpha',
            'definition': 'the first letter',
            'examples': <String>['alpha example'],
          },
          <String, Object?>{
            'word': 'beta',
            'content': 'Meaning: the second letter',
          },
        ]),
      );

      expect(entries.map((item) => item.word), <String>['alpha', 'beta']);
      expect(entries.first.fields, isNotEmpty);
      expect(entries.last.rawContent, contains('Meaning'));
    });

    test('parseJsonText keeps jsonl fallback support', () {
      final service = WordbookImportService();
      const jsonl = '''
{"word":"gamma","definition":"third"}
{"word":"delta","definition":"fourth"}
''';

      final entries = service.parseJsonText(jsonl);

      expect(entries.map((item) => item.word), <String>['gamma', 'delta']);
      expect(entries.every((item) => item.fields.isNotEmpty), isTrue);
    });
  });
}
