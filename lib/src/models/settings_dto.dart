import 'word_entry.dart';
import 'word_field.dart';
import 'practice_question_type.dart';
import 'practice_session_record.dart';

class TestModeState {
  const TestModeState({
    this.enabled = false,
    this.revealed = false,
    this.hintRevealed = false,
  });

  static const TestModeState defaults = TestModeState();

  final bool enabled;
  final bool revealed;
  final bool hintRevealed;

  factory TestModeState.fromJsonValue(Object? value) {
    if (value is! Map) {
      return defaults;
    }
    return TestModeState(
      enabled: value['enabled'] == true,
      revealed: value['revealed'] == true,
      hintRevealed: value['hintRevealed'] == true,
    );
  }

  Map<String, Object?> toJsonMap() {
    return <String, Object?>{
      'enabled': enabled,
      'revealed': revealed,
      'hintRevealed': hintRevealed,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is TestModeState &&
        other.enabled == enabled &&
        other.revealed == revealed &&
        other.hintRevealed == hintRevealed;
  }

  @override
  int get hashCode => Object.hash(enabled, revealed, hintRevealed);
}

class PracticeSessionPreferences {
  const PracticeSessionPreferences({
    this.autoAddWeakWordsToTask = false,
    this.autoPlayPronunciation = false,
    this.showHintsByDefault = false,
    this.showAnswerFeedbackDialog = true,
    this.defaultQuestionType = PracticeQuestionType.flashcard,
  });

  static const PracticeSessionPreferences defaults =
      PracticeSessionPreferences();

  final bool autoAddWeakWordsToTask;
  final bool autoPlayPronunciation;
  final bool showHintsByDefault;
  final bool showAnswerFeedbackDialog;
  final PracticeQuestionType defaultQuestionType;

  factory PracticeSessionPreferences.fromJsonValue(Object? value) {
    if (value is! Map) {
      return defaults;
    }
    return PracticeSessionPreferences(
      autoAddWeakWordsToTask: value['autoAddWeakWordsToTask'] == true,
      autoPlayPronunciation: value['autoPlayPronunciation'] == true,
      showHintsByDefault: value['showHintsByDefault'] == true,
      showAnswerFeedbackDialog: value['showAnswerFeedbackDialog'] != false,
      defaultQuestionType: PracticeQuestionType.fromStorage(
        '${value['defaultQuestionType'] ?? 'flashcard'}',
      ),
    );
  }

  Map<String, Object?> toJsonMap() {
    return <String, Object?>{
      'autoAddWeakWordsToTask': autoAddWeakWordsToTask,
      'autoPlayPronunciation': autoPlayPronunciation,
      'showHintsByDefault': showHintsByDefault,
      'showAnswerFeedbackDialog': showAnswerFeedbackDialog,
      'defaultQuestionType': defaultQuestionType.storageValue,
    };
  }
}

class PracticeTrackedEntrySnapshot {
  const PracticeTrackedEntrySnapshot({
    required this.wordbookId,
    required this.word,
    this.id,
    this.entryUid,
    this.primaryGloss,
    this.meaning,
    this.rawContent = '',
    this.fields = const <WordFieldItem>[],
  });

  final int? id;
  final int wordbookId;
  final String word;
  final String? entryUid;
  final String? primaryGloss;
  final String? meaning;
  final String rawContent;
  final List<WordFieldItem> fields;

  factory PracticeTrackedEntrySnapshot.fromWordEntry(WordEntry entry) {
    final summaryMeaning = entry.summaryMeaningText.trim();
    final needsRawContentFallback =
        entry.entryUid?.trim().isNotEmpty != true &&
        (entry.primaryGloss?.trim().isNotEmpty != true &&
            summaryMeaning.isEmpty);
    return PracticeTrackedEntrySnapshot(
      id: entry.id,
      wordbookId: entry.wordbookId,
      word: entry.word,
      entryUid: entry.entryUid,
      primaryGloss: entry.primaryGloss,
      meaning: summaryMeaning.isEmpty ? entry.meaning : summaryMeaning,
      rawContent: needsRawContentFallback ? entry.rawContent : '',
      fields: const <WordFieldItem>[],
    );
  }

  factory PracticeTrackedEntrySnapshot.fromJsonMap(Map<String, Object?> map) {
    final rawFields = map['fields'];
    final parsedFields = <WordFieldItem>[];
    if (rawFields is List) {
      for (final item in rawFields) {
        if (item is Map<String, Object?>) {
          final key = '${item['key'] ?? ''}'.trim();
          if (key.isEmpty) {
            continue;
          }
          final label = '${item['label'] ?? key}'.trim();
          final rawValue = item['value'];
          final fieldValue = switch (rawValue) {
            List<dynamic>() =>
              rawValue
                  .map((entry) => '$entry'.trim())
                  .where((entry) => entry.isNotEmpty)
                  .toList(growable: false),
            _ => '$rawValue'.trim(),
          };
          parsedFields.add(
            WordFieldItem(
              key: key,
              label: label.isEmpty ? key : label,
              value: fieldValue,
              style: WordFieldStyle.fromJsonMap(item['style']),
            ),
          );
        } else if (item is Map) {
          final cast = item.cast<String, Object?>();
          final key = '${cast['key'] ?? ''}'.trim();
          if (key.isEmpty) {
            continue;
          }
          final label = '${cast['label'] ?? key}'.trim();
          final rawValue = cast['value'];
          final fieldValue = switch (rawValue) {
            List<dynamic>() =>
              rawValue
                  .map((entry) => '$entry'.trim())
                  .where((entry) => entry.isNotEmpty)
                  .toList(growable: false),
            _ => '$rawValue'.trim(),
          };
          parsedFields.add(
            WordFieldItem(
              key: key,
              label: label.isEmpty ? key : label,
              value: fieldValue,
              style: WordFieldStyle.fromJsonMap(cast['style']),
            ),
          );
        }
      }
    }

    int? readId(Object? value) {
      if (value is int) return value > 0 ? value : null;
      if (value is num) {
        final parsed = value.toInt();
        return parsed > 0 ? parsed : null;
      }
      return null;
    }

    return PracticeTrackedEntrySnapshot(
      id: readId(map['id']),
      wordbookId: ((map['wordbookId'] as num?) ?? 0).toInt(),
      word: '${map['word'] ?? ''}'.trim(),
      entryUid: '${map['entryUid'] ?? ''}'.trim().isEmpty
          ? null
          : '${map['entryUid']}'.trim(),
      primaryGloss: '${map['primaryGloss'] ?? ''}'.trim().isEmpty
          ? null
          : '${map['primaryGloss']}'.trim(),
      meaning: '${map['meaning'] ?? ''}'.trim().isEmpty
          ? null
          : '${map['meaning']}'.trim(),
      rawContent: '${map['rawContent'] ?? ''}',
      fields: parsedFields,
    );
  }

  Map<String, Object?> toJsonMap() {
    return <String, Object?>{
      'id': id,
      'wordbookId': wordbookId,
      'word': word,
      'entryUid': entryUid,
      'primaryGloss': primaryGloss,
      'meaning': meaning,
      if (rawContent.trim().isNotEmpty) 'rawContent': rawContent,
      if (fields.isNotEmpty)
        'fields': fields
            .map((field) => field.toJsonMap())
            .toList(growable: false),
    };
  }

  WordEntry toWordEntry() {
    return WordEntry(
      id: id,
      wordbookId: wordbookId,
      word: word,
      entryUid: entryUid,
      primaryGloss: primaryGloss,
      meaning: meaning,
      rawContent: rawContent,
      fields: fields,
    );
  }
}

enum PracticeRoundSource {
  currentScope,
  wholeWordbook,
  wrongNotebook,
  taskWords,
  favorites,
  recentWeak,
}

extension PracticeRoundSourceStorage on PracticeRoundSource {
  String get storageValue => switch (this) {
    PracticeRoundSource.currentScope => 'current_scope',
    PracticeRoundSource.wholeWordbook => 'whole_wordbook',
    PracticeRoundSource.wrongNotebook => 'wrong_notebook',
    PracticeRoundSource.taskWords => 'task_words',
    PracticeRoundSource.favorites => 'favorites',
    PracticeRoundSource.recentWeak => 'recent_weak',
  };

  static PracticeRoundSource fromStorage(String raw) {
    return switch (raw.trim()) {
      'whole_wordbook' => PracticeRoundSource.wholeWordbook,
      'wrong_notebook' => PracticeRoundSource.wrongNotebook,
      'task_words' => PracticeRoundSource.taskWords,
      'favorites' => PracticeRoundSource.favorites,
      'recent_weak' => PracticeRoundSource.recentWeak,
      _ => PracticeRoundSource.currentScope,
    };
  }
}

enum PracticeRoundStartMode { resumeCursor, currentWord, fromStart }

extension PracticeRoundStartModeStorage on PracticeRoundStartMode {
  String get storageValue => switch (this) {
    PracticeRoundStartMode.resumeCursor => 'resume_cursor',
    PracticeRoundStartMode.currentWord => 'current_word',
    PracticeRoundStartMode.fromStart => 'from_start',
  };

  static PracticeRoundStartMode fromStorage(String raw) {
    return switch (raw.trim()) {
      'current_word' => PracticeRoundStartMode.currentWord,
      'from_start' => PracticeRoundStartMode.fromStart,
      _ => PracticeRoundStartMode.resumeCursor,
    };
  }
}

class PracticeRoundSettings {
  const PracticeRoundSettings({
    this.source = PracticeRoundSource.currentScope,
    this.startMode = PracticeRoundStartMode.resumeCursor,
    this.roundSize = 10,
    this.shuffle = false,
    this.collapsed = true,
  });

  static const PracticeRoundSettings defaults = PracticeRoundSettings();

  final PracticeRoundSource source;
  final PracticeRoundStartMode startMode;
  final int roundSize;
  final bool shuffle;
  final bool collapsed;

  factory PracticeRoundSettings.fromJsonValue(Object? value) {
    if (value is! Map) {
      return defaults;
    }

    int readRoundSize(Object? raw) {
      if (raw is int) {
        return raw.clamp(1, 200);
      }
      if (raw is num) {
        return raw.toInt().clamp(1, 200);
      }
      return defaults.roundSize;
    }

    return PracticeRoundSettings(
      source: PracticeRoundSourceStorage.fromStorage(
        '${value['source'] ?? PracticeRoundSource.currentScope.name}',
      ),
      startMode: PracticeRoundStartModeStorage.fromStorage(
        '${value['startMode'] ?? PracticeRoundStartMode.resumeCursor.name}',
      ),
      roundSize: readRoundSize(value['roundSize']),
      shuffle: value['shuffle'] == true,
      collapsed: value['collapsed'] != false,
    );
  }

  PracticeRoundSettings copyWith({
    PracticeRoundSource? source,
    PracticeRoundStartMode? startMode,
    int? roundSize,
    bool? shuffle,
    bool? collapsed,
  }) {
    final nextRoundSize = roundSize ?? this.roundSize;
    return PracticeRoundSettings(
      source: source ?? this.source,
      startMode: startMode ?? this.startMode,
      roundSize: nextRoundSize.clamp(1, 200),
      shuffle: shuffle ?? this.shuffle,
      collapsed: collapsed ?? this.collapsed,
    );
  }

  Map<String, Object?> toJsonMap() {
    return <String, Object?>{
      'source': source.storageValue,
      'startMode': startMode.storageValue,
      'roundSize': roundSize.clamp(1, 200),
      'shuffle': shuffle,
      'collapsed': collapsed,
    };
  }
}

class PracticeDashboardState {
  const PracticeDashboardState({
    this.date = '',
    this.todaySessions = 0,
    this.todayReviewed = 0,
    this.todayRemembered = 0,
    this.totalSessions = 0,
    this.totalReviewed = 0,
    this.totalRemembered = 0,
    this.lastSessionTitle = '',
    this.rememberedWords = const <String>[],
    this.weakWords = const <String>[],
    this.weakReasonIdsByWord = const <String, List<String>>{},
    this.history = const <PracticeSessionRecord>[],
    this.sessionPrefs = PracticeSessionPreferences.defaults,
    this.roundSettings = PracticeRoundSettings.defaults,
    this.launchCursors = const <String, int>{},
    this.trackedEntries = const <PracticeTrackedEntrySnapshot>[],
  });

  static const PracticeDashboardState defaults = PracticeDashboardState();

  final String date;
  final int todaySessions;
  final int todayReviewed;
  final int todayRemembered;
  final int totalSessions;
  final int totalReviewed;
  final int totalRemembered;
  final String lastSessionTitle;
  final List<String> rememberedWords;
  final List<String> weakWords;
  final Map<String, List<String>> weakReasonIdsByWord;
  final List<PracticeSessionRecord> history;
  final PracticeSessionPreferences sessionPrefs;
  final PracticeRoundSettings roundSettings;
  final Map<String, int> launchCursors;
  final List<PracticeTrackedEntrySnapshot> trackedEntries;

  factory PracticeDashboardState.fromJsonValue(Object? value) {
    if (value is! Map) {
      return defaults;
    }

    int readInt(Object? raw) {
      if (raw is int) return raw < 0 ? 0 : raw;
      if (raw is num) {
        final parsed = raw.toInt();
        return parsed < 0 ? 0 : parsed;
      }
      return 0;
    }

    List<String> readWords(Object? raw) {
      if (raw is! List) {
        return const <String>[];
      }
      final normalized = <String>[];
      for (final item in raw) {
        final word = '$item'.trim();
        if (word.isEmpty || normalized.contains(word)) {
          continue;
        }
        normalized.add(word);
      }
      return normalized.take(40).toList(growable: false);
    }

    Map<String, List<String>> readReasonMap(Object? raw) {
      if (raw is! Map) {
        return <String, List<String>>{};
      }
      final output = <String, List<String>>{};
      for (final entry in raw.entries) {
        final key = '${entry.key}'.trim().toLowerCase();
        if (key.isEmpty) {
          continue;
        }
        final reasons = <String>[];
        final source = entry.value is List
            ? entry.value as List
            : const <Object?>[];
        for (final item in source) {
          final value = '$item'.trim();
          if (!practiceWeakReasonIds.contains(value) ||
              reasons.contains(value)) {
            continue;
          }
          reasons.add(value);
        }
        output[key] = reasons.isEmpty ? const <String>['recall'] : reasons;
      }
      return output;
    }

    Map<String, int> readLaunchCursors(Object? raw) {
      if (raw is! Map) {
        return <String, int>{};
      }
      final output = <String, int>{};
      for (final entry in raw.entries) {
        final key = '${entry.key}'.trim();
        if (key.isEmpty) {
          continue;
        }
        output[key] = readInt(entry.value);
      }
      return output;
    }

    List<PracticeSessionRecord> readHistory(Object? raw) {
      if (raw is! List) {
        return const <PracticeSessionRecord>[];
      }
      return raw
          .whereType<Map>()
          .map(
            (item) =>
                PracticeSessionRecord.fromMap(item.cast<String, Object?>()),
          )
          .toList(growable: false);
    }

    List<PracticeTrackedEntrySnapshot> readTrackedEntries(Object? raw) {
      if (raw is! List) {
        return const <PracticeTrackedEntrySnapshot>[];
      }
      final entries = <PracticeTrackedEntrySnapshot>[];
      for (final item in raw) {
        if (item is Map<String, Object?>) {
          final snapshot = PracticeTrackedEntrySnapshot.fromJsonMap(item);
          if (snapshot.word.trim().isEmpty || snapshot.wordbookId <= 0) {
            continue;
          }
          entries.add(snapshot);
        } else if (item is Map) {
          final snapshot = PracticeTrackedEntrySnapshot.fromJsonMap(
            item.cast<String, Object?>(),
          );
          if (snapshot.word.trim().isEmpty || snapshot.wordbookId <= 0) {
            continue;
          }
          entries.add(snapshot);
        }
      }
      return entries;
    }

    return PracticeDashboardState(
      date: '${value['date'] ?? ''}'.trim(),
      todaySessions: readInt(value['todaySessions']),
      todayReviewed: readInt(value['todayReviewed']),
      todayRemembered: readInt(value['todayRemembered']),
      totalSessions: readInt(value['totalSessions']),
      totalReviewed: readInt(value['totalReviewed']),
      totalRemembered: readInt(value['totalRemembered']),
      lastSessionTitle: '${value['lastSessionTitle'] ?? ''}'.trim(),
      rememberedWords: readWords(value['rememberedWords']),
      weakWords: readWords(value['weakWords']),
      weakReasonIdsByWord: readReasonMap(value['weakReasonIdsByWord']),
      history: readHistory(value['history']),
      sessionPrefs: PracticeSessionPreferences.fromJsonValue(
        value['sessionPrefs'],
      ),
      roundSettings: PracticeRoundSettings.fromJsonValue(
        value['roundSettings'],
      ),
      launchCursors: readLaunchCursors(value['launchCursors']),
      trackedEntries: readTrackedEntries(value['trackedEntries']),
    );
  }

  Map<String, Object?> toJsonMap() {
    return <String, Object?>{
      'date': date,
      'todaySessions': todaySessions,
      'todayReviewed': todayReviewed,
      'todayRemembered': todayRemembered,
      'totalSessions': totalSessions,
      'totalReviewed': totalReviewed,
      'totalRemembered': totalRemembered,
      'lastSessionTitle': lastSessionTitle,
      'rememberedWords': rememberedWords,
      'weakWords': weakWords,
      'weakReasonIdsByWord': weakReasonIdsByWord,
      'history': history
          .map((record) => record.toMap())
          .toList(growable: false),
      'sessionPrefs': sessionPrefs.toJsonMap(),
      'roundSettings': roundSettings.toJsonMap(),
      'launchCursors': launchCursors,
      'trackedEntries': trackedEntries
          .map((entry) => entry.toJsonMap())
          .toList(growable: false),
    };
  }
}

class PlaybackProgressSnapshot {
  const PlaybackProgressSnapshot({
    required this.wordbookPath,
    this.wordId,
    this.entryUid,
    this.primaryGloss,
    required this.word,
    required this.updatedAt,
  });

  final String wordbookPath;
  final int? wordId;
  final String? entryUid;
  final String? primaryGloss;
  final String word;
  final DateTime updatedAt;

  factory PlaybackProgressSnapshot.fromJsonMap(Map<String, Object?> map) {
    int? readId(Object? raw) {
      if (raw is int) {
        return raw > 0 ? raw : null;
      }
      if (raw is num) {
        final value = raw.toInt();
        return value > 0 ? value : null;
      }
      return null;
    }

    return PlaybackProgressSnapshot(
      wordbookPath: '${map['wordbookPath'] ?? ''}'.trim(),
      wordId: readId(map['wordId']),
      entryUid: '${map['entryUid'] ?? ''}'.trim().isEmpty
          ? null
          : '${map['entryUid']}'.trim(),
      primaryGloss: '${map['primaryGloss'] ?? ''}'.trim().isEmpty
          ? null
          : '${map['primaryGloss']}'.trim(),
      word: '${map['word'] ?? ''}'.trim(),
      updatedAt:
          DateTime.tryParse('${map['updatedAt'] ?? ''}') ?? DateTime.now(),
    );
  }

  Map<String, Object?> toJsonMap() {
    return <String, Object?>{
      'wordbookPath': wordbookPath,
      'wordId': wordId,
      'entryUid': entryUid,
      'primaryGloss': primaryGloss,
      'word': word,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
