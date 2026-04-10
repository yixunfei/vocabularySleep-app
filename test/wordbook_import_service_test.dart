import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/models/word_field.dart';
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

    test(
      'parseJsonTextAsync parses metadata wrapped chinese wordbook json',
      () async {
        final service = WordbookImportService();
        final entries = await service.parseJsonTextAsync(
          jsonEncode(<String, Object?>{
            '元数据': <String, Object?>{'词条数量': 1, '语言方向': '中文 -> 英语'},
            '词条列表': <Map<String, Object?>>[
              <String, Object?>{
                '目标单词': 'the',
                '中文释义': '定冠词；用于特指的人或事物。',
                '音标/发音标注': <String, Object?>{
                  '英式音标': '/the-uk/',
                  '美式音标': '/the-us/',
                  '补充说明': 'weak before consonants',
                },
                '词性分类': <String>['冠词'],
                '常见搭配组词': <String>['the book'],
                '场景化例句': <Map<String, Object?>>[
                  <String, Object?>{
                    '含义类别': '日常交流',
                    '例句原文': 'Read the book.',
                    '中文翻译': '读这本书。',
                  },
                ],
                '词根溯源': '源自古英语。',
                '词缀分析': '无',
                '形态变形': <String>['thee'],
                '记忆辅助策略': '联想特指对象。',
                '趣味文化小故事': '常见于高频表达。',
              },
            ],
          }),
        );

        expect(entries.map((item) => item.word), <String>['the']);
        expect(entries.first.rawContent, contains('定冠词'));

        final legacy = toLegacyFields(entries.first.fields);
        expect(legacy.meaning, contains('定冠词'));
        expect(legacy.examples, isNotNull);
        expect(legacy.examples!.first, contains('Read the book.'));
        expect(legacy.examples!.first, contains('中文：读这本书。'));
        expect(legacy.etymology, contains('古英语'));
        expect(legacy.affixes, contains('无'));
        expect(legacy.variations, contains('thee'));
        expect(legacy.memory, contains('联想特指对象'));
        expect(legacy.story, contains('高频表达'));

        final pronunciationField = entries.first.fields.firstWhere(
          (item) => item.label == '音标/发音标注',
        );
        expect(pronunciationField.asText(), contains('英式音标: /the-uk/'));
        expect(pronunciationField.asText(), contains('美式音标: /the-us/'));
      },
    );

    test(
      'parseJsonTextAsync parses separate meaning/examples/etymology fields correctly',
      () async {
        final service = WordbookImportService();
        final entries = await service.parseJsonTextAsync(
          jsonEncode(<Map<String, Object?>>[
            <String, Object?>{
              'word': 'of',
              'content':
                  '### 分析词义\n\n"of" content here.\n\n### 列举例句\n\n1. Example sentence.\n\n### 词根\n\nroots content.\n',
              'meaning': '"of" meaning text.',
              'examples': <String>[
                'Example 1 from examples field.',
                'Example 2 from examples field.',
              ],
              'etymology': 'Etymology from separate field.',
              'roots': 'Roots from separate field.',
              'affixes': 'Affixes from separate field.',
            },
          ]),
        );

        expect(entries.length, 1);
        expect(entries.first.word, 'of');
        expect(entries.first.rawContent, contains('分析词义'));

        final fields = entries.first.fields;
        expect(fields.any((f) => f.key == 'meaning'), isTrue);
        expect(fields.any((f) => f.key == 'examples'), isTrue);
        expect(fields.any((f) => f.key == 'etymology'), isTrue);
        expect(fields.any((f) => f.key == 'roots'), isTrue);
        expect(fields.any((f) => f.key == 'affixes'), isTrue);

        final examplesField = fields.firstWhere((f) => f.key == 'examples');
        expect(examplesField.value, isA<List>());
        expect((examplesField.value as List).length, 2);

        final legacy = toLegacyFields(fields);
        expect(legacy.examples, isNotNull);
        expect(legacy.examples!.length, 2);
        expect(
          legacy.examples!.first,
          contains('Example 1 from examples field.'),
        );
        expect(legacy.etymology, contains('Etymology from separate field.'));
        expect(legacy.roots, contains('Roots from separate field.'));
        expect(legacy.affixes, contains('Affixes from separate field.'));
      },
    );
  });
}
