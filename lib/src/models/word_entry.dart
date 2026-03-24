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

  Map<String, Object?> toJsonMap() {
    return <String, Object?>{
      'word': word,
      'fields': fields.map((item) => item.toJsonMap()).toList(growable: false),
      'rawContent': rawContent,
    };
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
    List<WordFieldItem> fields = const <WordFieldItem>[],
    this.rawContent = '',
    String rawFieldsJson = '',
  }) : _fields = fields,
       _rawFieldsJson = rawFieldsJson;

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
  final String rawContent;
  final List<WordFieldItem> _fields;
  final String _rawFieldsJson;

  List<WordFieldItem> get fields {
    if (_fields.isNotEmpty) return _fields;

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
    if (_rawFieldsJson.trim().isEmpty) {
      return fallbackFields;
    }

    return mergeFieldItems(<WordFieldItem>[
      ...parseFieldItemsJson(_rawFieldsJson),
      ...fallbackFields,
    ]);
  }

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
    String? rawFieldsJson,
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
      fields: fields ?? _fields,
      rawContent: rawContent ?? this.rawContent,
      rawFieldsJson: fields == null ? (rawFieldsJson ?? _rawFieldsJson) : '',
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

  Map<String, Object?> toJsonMap() {
    return <String, Object?>{
      'id': id,
      'wordbookId': wordbookId,
      'word': word,
      'meaning': meaning,
      'examples': examples,
      'etymology': etymology,
      'roots': roots,
      'affixes': affixes,
      'variations': variations,
      'memory': memory,
      'story': story,
      'fields': fields.map((item) => item.toJsonMap()).toList(growable: false),
      'rawContent': rawContent,
    };
  }

  static WordEntry fromJsonMap(Map<String, Object?> map) {
    List<String>? parseExamples(Object? raw) {
      if (raw is List) {
        final output = raw
            .map((item) => sanitizeDisplayText('$item'))
            .where((item) => item.isNotEmpty)
            .toList(growable: false);
        return output.isEmpty ? null : output;
      }
      if (raw is String && raw.trim().isNotEmpty) {
        final output = raw
            .split(RegExp(r'\r?\n'))
            .map(sanitizeDisplayText)
            .where((item) => item.isNotEmpty)
            .toList(growable: false);
        return output.isEmpty ? null : output;
      }
      return null;
    }

    List<WordFieldItem> parseFields(Object? raw) {
      if (raw is! List) {
        return const <WordFieldItem>[];
      }
      return parseFieldItemsJson(jsonEncode(raw));
    }

    String? sanitizeNullable(Object? raw) {
      final cleaned = sanitizeDisplayText('${raw ?? ''}');
      return cleaned.isEmpty ? null : cleaned;
    }

    return WordEntry(
      id: (map['id'] as num?)?.toInt(),
      wordbookId: ((map['wordbookId'] as num?) ?? 0).toInt(),
      word: sanitizeDisplayText('${map['word'] ?? ''}'),
      meaning: sanitizeNullable(map['meaning']),
      examples: parseExamples(map['examples']),
      etymology: sanitizeNullable(map['etymology']),
      roots: sanitizeNullable(map['roots']),
      affixes: sanitizeNullable(map['affixes']),
      variations: sanitizeNullable(map['variations']),
      memory: sanitizeNullable(map['memory']),
      story: sanitizeNullable(map['story']),
      fields: parseFields(map['fields']),
      rawContent: sanitizeDisplayText('${map['rawContent'] ?? ''}'),
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

    final rowId = (map['id'] as num?)?.toInt();
    final rowWordbookId = ((map['wordbook_id'] as num?) ?? 0).toInt();
    final entryJson = '${map['entry_json'] ?? ''}'.trim();
    if (entryJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(entryJson);
        if (decoded is Map) {
          final entry = WordEntry.fromJsonMap(decoded.cast<String, Object?>());
          return entry.copyWith(
            id: rowId ?? entry.id,
            wordbookId: rowWordbookId > 0 ? rowWordbookId : entry.wordbookId,
            word: sanitizeDisplayText(map['word']?.toString() ?? entry.word),
            meaning: sanitizeNullable(map['meaning']) ?? entry.meaning,
            examples: examples ?? entry.examples,
            etymology: sanitizeNullable(map['etymology']) ?? entry.etymology,
            roots: sanitizeNullable(map['roots']) ?? entry.roots,
            affixes: sanitizeNullable(map['affixes']) ?? entry.affixes,
            variations: sanitizeNullable(map['variations']) ?? entry.variations,
            memory: sanitizeNullable(map['memory']) ?? entry.memory,
            story: sanitizeNullable(map['story']) ?? entry.story,
            rawContent: sanitizeDisplayText(
              map['raw_content']?.toString() ?? entry.rawContent,
            ),
          );
        }
      } catch (_) {
        // Fall back to legacy columns if the structured payload is invalid.
      }
    }

    return WordEntry(
      id: rowId,
      wordbookId: rowWordbookId,
      word: sanitizeDisplayText(map['word']?.toString() ?? ''),
      meaning: sanitizeNullable(map['meaning']),
      examples: examples,
      etymology: sanitizeNullable(map['etymology']),
      roots: sanitizeNullable(map['roots']),
      affixes: sanitizeNullable(map['affixes']),
      variations: sanitizeNullable(map['variations']),
      memory: sanitizeNullable(map['memory']),
      story: sanitizeNullable(map['story']),
      fields: const <WordFieldItem>[],
      rawContent: sanitizeDisplayText(map['raw_content']?.toString() ?? ''),
      rawFieldsJson: map['fields_json']?.toString() ?? '',
    );
  }
}
