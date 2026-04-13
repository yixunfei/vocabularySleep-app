import 'dart:convert';

import 'practice_session_record.dart';
import 'todo_item.dart';
import 'tomato_timer.dart';
import 'word_field.dart';
import 'word_entry.dart';
import 'word_memory_progress.dart';
import 'wordbook.dart';
import 'wordbook_schema_v1.dart';

const String userDataExportSchema = 'vocabulary_sleep.user_data_export';
const int userDataExportSchemaVersion = 3;
const int userDataExportLegacySchemaVersion = 2;

class UserDataExportValidationException implements Exception {
  const UserDataExportValidationException(this.message);

  final String message;

  @override
  String toString() => 'UserDataExportValidationException: $message';
}

class PracticeReviewExportSummary {
  const PracticeReviewExportSummary({
    required this.todaySessions,
    required this.todayReviewed,
    required this.todayRemembered,
    required this.totalSessions,
    required this.totalReviewed,
    required this.totalRemembered,
    required this.todayAccuracy,
    required this.totalAccuracy,
    required this.lastSessionTitle,
    required this.defaultQuestionType,
  });

  final int todaySessions;
  final int todayReviewed;
  final int todayRemembered;
  final int totalSessions;
  final int totalReviewed;
  final int totalRemembered;
  final double todayAccuracy;
  final double totalAccuracy;
  final String lastSessionTitle;
  final String defaultQuestionType;

  Map<String, Object?> toJsonMap() {
    return <String, Object?>{
      'todaySessions': todaySessions,
      'todayReviewed': todayReviewed,
      'todayRemembered': todayRemembered,
      'totalSessions': totalSessions,
      'totalReviewed': totalReviewed,
      'totalRemembered': totalRemembered,
      'todayAccuracy': todayAccuracy,
      'totalAccuracy': totalAccuracy,
      'lastSessionTitle': lastSessionTitle,
      'defaultQuestionType': defaultQuestionType,
    };
  }
}

class PracticeExportWordEntry {
  const PracticeExportWordEntry({
    this.id,
    required this.wordbookId,
    required this.word,
    required this.meaning,
    required this.reasons,
    this.memoryProgress,
  });

  final int? id;
  final int wordbookId;
  final String word;
  final String meaning;
  final List<String> reasons;
  final WordMemoryProgress? memoryProgress;

  Map<String, Object?> toJsonMap() {
    return <String, Object?>{
      'id': id,
      'wordbookId': wordbookId,
      'word': word,
      'meaning': meaning,
      'reasons': reasons,
      'memoryProgress': memoryProgress?.toMap(),
    };
  }
}

class PracticeReviewExportPayload {
  const PracticeReviewExportPayload({
    required this.exportedAt,
    this.schemaVersion = 1,
    required this.summary,
    this.metadata = const <String, Object?>{},
    this.weakReasonCounts = const <String, int>{},
    this.sessionHistory = const <PracticeSessionRecord>[],
    this.wrongNotebook = const <PracticeExportWordEntry>[],
  });

  final DateTime exportedAt;
  final int schemaVersion;
  final PracticeReviewExportSummary summary;
  final Map<String, Object?> metadata;
  final Map<String, int> weakReasonCounts;
  final List<PracticeSessionRecord> sessionHistory;
  final List<PracticeExportWordEntry> wrongNotebook;

  Map<String, Object?> toJsonMap() {
    return <String, Object?>{
      'exported_at': exportedAt.toIso8601String(),
      'schema_version': schemaVersion,
      'summary': summary.toJsonMap(),
      'metadata': metadata,
      'weakReasonCounts': weakReasonCounts,
      'sessionHistory': sessionHistory
          .map((record) => record.toMap())
          .toList(growable: false),
      'wrongNotebook': wrongNotebook
          .map((entry) => entry.toJsonMap())
          .toList(growable: false),
    };
  }
}

class PracticeWrongNotebookExportPayload {
  const PracticeWrongNotebookExportPayload({
    required this.exportedAt,
    this.schemaVersion = 1,
    required this.count,
    this.metadata = const <String, Object?>{},
    this.entries = const <PracticeExportWordEntry>[],
  });

  final DateTime exportedAt;
  final int schemaVersion;
  final int count;
  final Map<String, Object?> metadata;
  final List<PracticeExportWordEntry> entries;

  Map<String, Object?> toJsonMap() {
    return <String, Object?>{
      'exported_at': exportedAt.toIso8601String(),
      'schema_version': schemaVersion,
      'count': count,
      'metadata': metadata,
      'entries': entries
          .map((entry) => entry.toJsonMap())
          .toList(growable: false),
    };
  }
}

class UserDataExportWordbook {
  const UserDataExportWordbook({
    required this.wordbook,
    required this.words,
    this.standardBook,
  });

  final Wordbook wordbook;
  final List<UserDataExportWordRecord> words;
  final WordbookBookMetaV1? standardBook;

  WordbookSchemaV1? tryBuildStandardWordbook() {
    if ((wordbook.schemaVersion ?? '').trim() != wordbookSchemaV1 ||
        words.isEmpty) {
      return null;
    }

    final standardEntries = <WordbookEntryV1>[];
    for (final word in words) {
      final standardEntry = word.tryParseStandardEntry();
      if (standardEntry == null) {
        return null;
      }
      standardEntries.add(standardEntry);
    }

    final bookMeta =
        standardBook ?? _tryBuildStandardBookMetaFromMetadataJson();
    if (bookMeta == null) {
      return null;
    }

    return WordbookSchemaV1(
      schemaVersion: wordbookSchemaV1,
      book: bookMeta,
      entries: standardEntries,
    );
  }

  WordbookBookMetaV1? _tryBuildStandardBookMetaFromMetadataJson() {
    final metadataMap = _tryDecodeObjectMap(wordbook.metadataJson);
    if (metadataMap == null) {
      return null;
    }
    final bookId = sanitizeDisplayText(
      '${metadataMap['id'] ?? wordbook.path.trim()}',
    );
    final sourceLanguage = sanitizeDisplayText(
      '${metadataMap['source_language'] ?? ''}',
    );
    final targetLanguage = sanitizeDisplayText(
      '${metadataMap['target_language'] ?? ''}',
    );
    final direction = sanitizeDisplayText('${metadataMap['direction'] ?? ''}');
    if (bookId.isEmpty ||
        sourceLanguage.isEmpty ||
        targetLanguage.isEmpty ||
        direction.isEmpty) {
      return null;
    }
    return WordbookBookMetaV1(
      id: bookId,
      name: sanitizeDisplayText('${metadataMap['name'] ?? wordbook.name}'),
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      direction: direction,
      entryCount: words.length,
      createdAt: sanitizeDisplayText('${metadataMap['created_at'] ?? ''}'),
      updatedAt: sanitizeDisplayText('${metadataMap['updated_at'] ?? ''}'),
      sources: _readStringList(metadataMap['sources']),
      tags: _readStringList(metadataMap['tags']),
      description: sanitizeDisplayText('${metadataMap['description'] ?? ''}'),
      license: sanitizeDisplayText('${metadataMap['license'] ?? ''}'),
      extra: _readObjectMap(metadataMap['extra']),
    );
  }

  factory UserDataExportWordbook.fromJsonMap(Map<String, Object?> map) {
    final words = <UserDataExportWordRecord>[];
    final rawWords = map['words'];
    if (rawWords is List) {
      for (final item in rawWords) {
        if (item is Map<String, Object?>) {
          words.add(UserDataExportWordRecord.fromJsonMap(item));
        } else if (item is Map) {
          words.add(
            UserDataExportWordRecord.fromJsonMap(item.cast<String, Object?>()),
          );
        }
      }
    }

    return UserDataExportWordbook(
      wordbook: Wordbook.fromMap(<String, Object?>{
        'id': map['id'] ?? 0,
        'name': map['name'],
        'path': map['path'],
        'word_count': map['word_count'],
        'created_at': map['created_at'],
        'schema_version': map['schema_version'],
        'metadata_json': map['metadata_json'],
      }),
      words: words,
      standardBook: _readStandardBookMeta(map['standard_book']),
    );
  }

  Map<String, Object?> toJsonMap() {
    return <String, Object?>{
      'id': wordbook.id,
      'name': wordbook.name,
      'path': wordbook.path,
      'word_count': wordbook.wordCount,
      'created_at': wordbook.createdAt?.toIso8601String(),
      'schema_version': wordbook.schemaVersion,
      'metadata_json': wordbook.metadataJson,
      if (standardBook != null) 'standard_book': standardBook!.toJsonMap(),
      'words': words.map((word) => word.toJsonMap()).toList(growable: false),
    };
  }
}

class UserDataExportWordRecord {
  const UserDataExportWordRecord({
    this.id,
    required this.wordbookId,
    required this.word,
    this.entryUid,
    this.meaning,
    this.primaryGloss,
    this.schemaVersion,
    this.sortIndex,
    this.examples,
    this.etymology,
    this.roots,
    this.affixes,
    this.variations,
    this.memory,
    this.story,
    this.sourcePayloadJson,
    this.fields = const <WordFieldItem>[],
    this.rawContent = '',
  });

  final int? id;
  final int wordbookId;
  final String word;
  final String? entryUid;
  final String? meaning;
  final String? primaryGloss;
  final String? schemaVersion;
  final int? sortIndex;
  final List<String>? examples;
  final String? etymology;
  final String? roots;
  final String? affixes;
  final String? variations;
  final String? memory;
  final String? story;
  final String? sourcePayloadJson;
  final List<WordFieldItem> fields;
  final String rawContent;

  WordbookEntryV1? tryParseStandardEntry() {
    if ((schemaVersion ?? '').trim() != wordbookSchemaV1) {
      return null;
    }
    final payloadMap = _tryDecodeObjectMap(sourcePayloadJson);
    if (payloadMap == null) {
      return null;
    }
    try {
      return WordbookEntryV1.fromJsonMap(payloadMap);
    } catch (_) {
      return null;
    }
  }

  factory UserDataExportWordRecord.fromJsonMap(Map<String, Object?> map) {
    List<String>? readStringList(Object? raw) {
      if (raw is! List) return null;
      final output = raw
          .map((item) => '$item'.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
      return output.isEmpty ? null : output;
    }

    List<WordFieldItem> readFields(Object? raw) {
      if (raw is! List) return const <WordFieldItem>[];
      return parseFieldItemsJson(jsonEncode(raw));
    }

    String? readNullableText(Object? raw) {
      final text = sanitizeDisplayText('${raw ?? ''}');
      return text.isEmpty ? null : text;
    }

    return UserDataExportWordRecord(
      id: (map['id'] as num?)?.toInt(),
      wordbookId: ((map['wordbook_id'] as num?) ?? 0).toInt(),
      word: sanitizeDisplayText('${map['word'] ?? ''}'),
      entryUid: readNullableText(map['entry_uid']),
      meaning: readNullableText(map['meaning']),
      primaryGloss: readNullableText(map['primary_gloss']),
      schemaVersion: readNullableText(map['schema_version']),
      sortIndex: (map['sort_index'] as num?)?.toInt(),
      examples: readStringList(map['examples']),
      etymology: readNullableText(map['etymology']),
      roots: readNullableText(map['roots']),
      affixes: readNullableText(map['affixes']),
      variations: readNullableText(map['variations']),
      memory: readNullableText(map['memory']),
      story: readNullableText(map['story']),
      sourcePayloadJson: readNullableText(map['source_payload_json']),
      fields: readFields(map['fields']),
      rawContent: sanitizeDisplayText('${map['raw_content'] ?? ''}'),
    );
  }

  WordEntryPayload toWordEntryPayload() {
    final mergedFields = fields.isNotEmpty
        ? fields
        : buildFieldItemsFromRecord(<String, Object?>{
            'meaning': meaning,
            'examples': examples,
            'etymology': etymology,
            'roots': roots,
            'affixes': affixes,
            'variations': variations,
            'memory': memory,
            'story': story,
          });
    return WordEntryPayload(
      word: word,
      fields: mergedFields,
      rawContent: rawContent,
      entryUid: entryUid,
      primaryGloss: primaryGloss ?? meaning,
      schemaVersion: schemaVersion,
      sortIndex: sortIndex,
      sourcePayloadJson: sourcePayloadJson,
    );
  }

  WordEntryPayload toRestorablePayload() {
    final standardEntry = tryParseStandardEntry();
    if (standardEntry == null) {
      return toWordEntryPayload();
    }

    final standardPayload = standardEntry.toPayload();
    final mergedFields = fields.isEmpty
        ? standardPayload.fields
        : mergeFieldItems(<WordFieldItem>[
            ...standardPayload.fields,
            ...fields,
          ]);
    final resolvedRawContent = sanitizeDisplayText(rawContent);

    return standardPayload.copyWith(
      word: word.trim().isEmpty ? standardPayload.word : word,
      fields: mergedFields,
      rawContent: resolvedRawContent.isEmpty
          ? standardPayload.rawContent
          : resolvedRawContent,
      entryUid: entryUid ?? standardPayload.entryUid,
      primaryGloss: primaryGloss ?? standardPayload.primaryGloss,
      schemaVersion: schemaVersion ?? standardPayload.schemaVersion,
      sortIndex: sortIndex ?? standardPayload.sortIndex,
      sourcePayloadJson: sourcePayloadJson ?? standardPayload.sourcePayloadJson,
    );
  }

  Map<String, Object?> toJsonMap() {
    return <String, Object?>{
      'id': id,
      'wordbook_id': wordbookId,
      'word': word,
      'entry_uid': entryUid,
      'meaning': meaning,
      'primary_gloss': primaryGloss,
      'schema_version': schemaVersion,
      'sort_index': sortIndex,
      'examples': examples,
      'etymology': etymology,
      'roots': roots,
      'affixes': affixes,
      'variations': variations,
      'memory': memory,
      'story': story,
      'source_payload_json': sourcePayloadJson,
      'fields': fields
          .map((field) => field.toJsonMap())
          .toList(growable: false),
      'raw_content': rawContent,
    };
  }
}

class UserDataExportPayload {
  const UserDataExportPayload({
    required this.exportedAt,
    this.schema = userDataExportSchema,
    this.schemaVersion = userDataExportSchemaVersion,
    required this.sections,
    this.wordbooks = const <UserDataExportWordbook>[],
    this.todos = const <TodoItem>[],
    this.notes = const <PlanNote>[],
    this.progress = const <WordMemoryProgress>[],
    this.timerRecords = const <TomatoTimerRecord>[],
    this.settings = const <String, String>{},
  });

  final DateTime exportedAt;
  final String schema;
  final int schemaVersion;
  final List<String> sections;
  final List<UserDataExportWordbook> wordbooks;
  final List<TodoItem> todos;
  final List<PlanNote> notes;
  final List<WordMemoryProgress> progress;
  final List<TomatoTimerRecord> timerRecords;
  final Map<String, String> settings;

  static UserDataExportPayload validatedFromJsonMap(Map<String, Object?> map) {
    final schema = sanitizeDisplayText('${map['schema'] ?? ''}');
    final schemaVersion = (map['schema_version'] as num?)?.toInt();

    if (schema.isEmpty) {
      if (schemaVersion != userDataExportLegacySchemaVersion) {
        throw UserDataExportValidationException(
          '导出文件缺少 schema 标识，且 schema_version=$schemaVersion 不受支持。当前仅支持旧版 v2 导出或新版 $userDataExportSchema v$userDataExportSchemaVersion。',
        );
      }
    } else if (schema != userDataExportSchema) {
      throw UserDataExportValidationException(
        '导出文件 schema 为 "$schema"，当前仅支持 $userDataExportSchema。',
      );
    }

    if (schema.isNotEmpty && schemaVersion != userDataExportSchemaVersion) {
      throw UserDataExportValidationException(
        '导出文件 schema_version=$schemaVersion 不受支持。当前仅支持 $userDataExportSchema 的 v$userDataExportSchemaVersion。',
      );
    }

    final rawSections = map['sections'];
    if (rawSections is! List || rawSections.isEmpty) {
      throw const UserDataExportValidationException(
        '导出文件缺少有效 sections，无法判断需要恢复的数据范围。',
      );
    }

    return UserDataExportPayload.fromJsonMap(map);
  }

  factory UserDataExportPayload.fromJsonMap(Map<String, Object?> map) {
    List<String> readSections(Object? raw) {
      if (raw is! List) return const <String>[];
      return raw
          .map((item) => '$item'.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }

    List<UserDataExportWordbook> readWordbooks(Object? raw) {
      if (raw is! List) return const <UserDataExportWordbook>[];
      final output = <UserDataExportWordbook>[];
      for (final item in raw) {
        if (item is Map<String, Object?>) {
          output.add(UserDataExportWordbook.fromJsonMap(item));
        } else if (item is Map) {
          output.add(
            UserDataExportWordbook.fromJsonMap(item.cast<String, Object?>()),
          );
        }
      }
      return output;
    }

    List<TodoItem> readTodos(Object? raw) {
      if (raw is! List) return const <TodoItem>[];
      return raw
          .whereType<Map>()
          .map((item) => TodoItem.fromMap(item.cast<String, Object?>()))
          .toList(growable: false);
    }

    List<PlanNote> readNotes(Object? raw) {
      if (raw is! List) return const <PlanNote>[];
      return raw
          .whereType<Map>()
          .map((item) => PlanNote.fromMap(item.cast<String, Object?>()))
          .toList(growable: false);
    }

    List<WordMemoryProgress> readProgress(Object? raw) {
      if (raw is! List) return const <WordMemoryProgress>[];
      return raw
          .whereType<Map>()
          .map(
            (item) => WordMemoryProgress.fromMap(item.cast<String, Object?>()),
          )
          .toList(growable: false);
    }

    List<TomatoTimerRecord> readTimerRecords(Object? raw) {
      if (raw is! List) return const <TomatoTimerRecord>[];
      return raw
          .whereType<Map>()
          .map(
            (item) => TomatoTimerRecord.fromMap(item.cast<String, Object?>()),
          )
          .toList(growable: false);
    }

    Map<String, String> readSettings(Object? raw) {
      if (raw is! Map) return const <String, String>{};
      return <String, String>{
        for (final entry in raw.entries) '${entry.key}': '${entry.value ?? ''}',
      };
    }

    return UserDataExportPayload(
      exportedAt:
          DateTime.tryParse('${map['exported_at'] ?? ''}') ?? DateTime.now(),
      schema: sanitizeDisplayText('${map['schema'] ?? ''}'),
      schemaVersion:
          (map['schema_version'] as num?)?.toInt() ??
          userDataExportLegacySchemaVersion,
      sections: readSections(map['sections']),
      wordbooks: readWordbooks(map['wordbooks']),
      todos: readTodos(map['todos']),
      notes: readNotes(map['notes']),
      progress: readProgress(map['progress']),
      timerRecords: readTimerRecords(map['timer_records']),
      settings: readSettings(map['settings']),
    );
  }

  Map<String, Object?> toJsonMap() {
    return <String, Object?>{
      'exported_at': exportedAt.toIso8601String(),
      'schema': schema,
      'schema_version': schemaVersion,
      'sections': sections,
      if (wordbooks.isNotEmpty)
        'wordbooks': wordbooks
            .map((item) => item.toJsonMap())
            .toList(growable: false),
      if (todos.isNotEmpty)
        'todos': todos.map((item) => item.toMap()).toList(growable: false),
      if (notes.isNotEmpty)
        'notes': notes.map((item) => item.toMap()).toList(growable: false),
      if (progress.isNotEmpty)
        'progress': progress
            .map((item) => item.toMap())
            .toList(growable: false),
      if (timerRecords.isNotEmpty)
        'timer_records': timerRecords
            .map((item) => item.toMap())
            .toList(growable: false),
      if (settings.isNotEmpty) 'settings': settings,
    };
  }
}

Map<String, Object?>? _tryDecodeObjectMap(String? raw) {
  final text = sanitizeDisplayText(raw ?? '');
  if (text.isEmpty) {
    return null;
  }
  try {
    final decoded = jsonDecode(text);
    if (decoded is Map<String, Object?>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.cast<String, Object?>();
    }
  } catch (_) {
    return null;
  }
  return null;
}

List<String> _readStringList(Object? raw) {
  if (raw is! List) {
    return const <String>[];
  }
  return raw
      .map((item) => sanitizeDisplayText('$item'))
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

Map<String, Object?> _readObjectMap(Object? raw) {
  if (raw is Map<String, Object?>) {
    return raw;
  }
  if (raw is Map) {
    return raw.cast<String, Object?>();
  }
  return const <String, Object?>{};
}

WordbookBookMetaV1? _readStandardBookMeta(Object? raw) {
  final map = _readObjectMap(raw);
  if (map.isEmpty) {
    return null;
  }
  try {
    final book = WordbookBookMetaV1.fromJsonMap(map);
    if (book.id.trim().isEmpty ||
        book.sourceLanguage.trim().isEmpty ||
        book.targetLanguage.trim().isEmpty ||
        book.direction.trim().isEmpty) {
      return null;
    }
    return book;
  } catch (_) {
    return null;
  }
}
