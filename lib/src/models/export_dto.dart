import 'practice_session_record.dart';
import 'todo_item.dart';
import 'tomato_timer.dart';
import 'word_field.dart';
import 'word_memory_progress.dart';
import 'wordbook.dart';

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
  const UserDataExportWordbook({required this.wordbook, required this.words});

  final Wordbook wordbook;
  final List<UserDataExportWordRecord> words;

  Map<String, Object?> toJsonMap() {
    return <String, Object?>{
      'id': wordbook.id,
      'name': wordbook.name,
      'path': wordbook.path,
      'word_count': wordbook.wordCount,
      'created_at': wordbook.createdAt?.toIso8601String(),
      'words': words.map((word) => word.toJsonMap()).toList(growable: false),
    };
  }
}

class UserDataExportWordRecord {
  const UserDataExportWordRecord({
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
    this.fields = const <WordFieldItem>[],
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

  Map<String, Object?> toJsonMap() {
    return <String, Object?>{
      'id': id,
      'wordbook_id': wordbookId,
      'word': word,
      'meaning': meaning,
      'examples': examples,
      'etymology': etymology,
      'roots': roots,
      'affixes': affixes,
      'variations': variations,
      'memory': memory,
      'story': story,
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
    this.schemaVersion = 2,
    required this.sections,
    this.wordbooks = const <UserDataExportWordbook>[],
    this.todos = const <TodoItem>[],
    this.notes = const <PlanNote>[],
    this.progress = const <WordMemoryProgress>[],
    this.timerRecords = const <TomatoTimerRecord>[],
    this.settings = const <String, String>{},
  });

  final DateTime exportedAt;
  final int schemaVersion;
  final List<String> sections;
  final List<UserDataExportWordbook> wordbooks;
  final List<TodoItem> todos;
  final List<PlanNote> notes;
  final List<WordMemoryProgress> progress;
  final List<TomatoTimerRecord> timerRecords;
  final Map<String, String> settings;

  Map<String, Object?> toJsonMap() {
    return <String, Object?>{
      'exported_at': exportedAt.toIso8601String(),
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
