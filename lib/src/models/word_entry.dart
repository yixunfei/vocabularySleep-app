import 'dart:convert';

import 'word_field.dart';

class WordEntryPayload {
  const WordEntryPayload({
    required this.word,
    required this.fields,
    this.rawContent = '',
  });

  final String word;
  final List<WordFieldItem> fields;
  final String rawContent;

  WordEntryPayload copyWith({
    String? word,
    List<WordFieldItem>? fields,
    String? rawContent,
  }) {
    return WordEntryPayload(
      word: word ?? this.word,
      fields: fields ?? this.fields,
      rawContent: rawContent ?? this.rawContent,
    );
  }
}

class WordEntry {
  const WordEntry({
    this.id,
    required this.wordbookId,
    required this.word,
    this.meaning,
    this.examples,
    this.etymology,
    this.roots,
    this.affixes,
    this.variations,
    this.memory,
    this.story,
    required this.fields,
    this.rawContent = '',
  });

  final int? id;
  final int wordbookId;
  final String word;
  final String? meaning;
  final List<String>? examples;
  final String? etymology;
  final String? roots;
  final String? affixes;
  final String? variations;
  final String? memory;
  final String? story;
  final List<WordFieldItem> fields;
  final String rawContent;

  WordEntry copyWith({
    int? id,
    int? wordbookId,
    String? word,
    String? meaning,
    List<String>? examples,
    String? etymology,
    String? roots,
    String? affixes,
    String? variations,
    String? memory,
    String? story,
    List<WordFieldItem>? fields,
    String? rawContent,
  }) {
    return WordEntry(
      id: id ?? this.id,
      wordbookId: wordbookId ?? this.wordbookId,
      word: word ?? this.word,
      meaning: meaning ?? this.meaning,
      examples: examples ?? this.examples,
      etymology: etymology ?? this.etymology,
      roots: roots ?? this.roots,
      affixes: affixes ?? this.affixes,
      variations: variations ?? this.variations,
      memory: memory ?? this.memory,
      story: story ?? this.story,
      fields: fields ?? this.fields,
      rawContent: rawContent ?? this.rawContent,
    );
  }

  WordEntryPayload toPayload() {
    final fallbackFields = buildFieldItemsFromRecord(<String, Object?>{
      'meaning': meaning,
      'examples': examples,
      'etymology': etymology,
      'roots': roots,
      'affixes': affixes,
      'variations': variations,
      'memory': memory,
      'story': story,
    });

    final mergedFields = mergeFieldItems(<WordFieldItem>[
      ...fields,
      ...fallbackFields,
    ]);

    return WordEntryPayload(
      word: word,
      fields: mergedFields,
      rawContent: rawContent.isNotEmpty ? rawContent : (meaning ?? ''),
    );
  }

  static WordEntry fromMap(Map<String, Object?> map) {
    String? sanitizeNullable(Object? raw) {
      final cleaned = sanitizeDisplayText('${raw ?? ''}');
      return cleaned.isEmpty ? null : cleaned;
    }

    List<String>? examples;
    final rawExamples = map['examples'];
    if (rawExamples is String && rawExamples.trim().isNotEmpty) {
      try {
        final parsed = jsonDecode(rawExamples);
        if (parsed is List) {
          examples = parsed
              .map((item) => sanitizeDisplayText('$item'))
              .where((item) => item.isNotEmpty)
              .toList();
        }
      } catch (_) {
        examples = rawExamples
            .split(RegExp(r'\r?\n'))
            .map((line) => sanitizeDisplayText(line))
            .where((line) => line.isNotEmpty)
            .toList();
      }
    }

    final fieldItems = parseFieldItemsJson(
      map['fields_json']?.toString() ?? '',
    );
    final mergedFields = mergeFieldItems(<WordFieldItem>[
      ...fieldItems,
      ...buildFieldItemsFromRecord(<String, Object?>{
        'meaning': map['meaning'],
        'examples': examples,
        'etymology': map['etymology'],
        'roots': map['roots'],
        'affixes': map['affixes'],
        'variations': map['variations'],
        'memory': map['memory'],
        'story': map['story'],
      }),
    ]);

    return WordEntry(
      id: (map['id'] as num?)?.toInt(),
      wordbookId: ((map['wordbook_id'] as num?) ?? 0).toInt(),
      word: sanitizeDisplayText(map['word']?.toString() ?? ''),
      meaning: sanitizeNullable(map['meaning']),
      examples: examples,
      etymology: sanitizeNullable(map['etymology']),
      roots: sanitizeNullable(map['roots']),
      affixes: sanitizeNullable(map['affixes']),
      variations: sanitizeNullable(map['variations']),
      memory: sanitizeNullable(map['memory']),
      story: sanitizeNullable(map['story']),
      fields: mergedFields,
      rawContent: sanitizeDisplayText(map['raw_content']?.toString() ?? ''),
    );
  }
}
