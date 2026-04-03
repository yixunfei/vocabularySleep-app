import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'toolbox_schulte_engine.dart';

class SchulteJumpBestRecord {
  const SchulteJumpBestRecord({required this.score, required this.rounds});

  final int score;
  final int rounds;

  Map<String, Object?> toJson() {
    return <String, Object?>{'score': score, 'rounds': rounds};
  }

  bool isBetterThan(SchulteJumpBestRecord? other) {
    if (other == null) {
      return true;
    }
    if (score != other.score) {
      return score > other.score;
    }
    return rounds > other.rounds;
  }

  static SchulteJumpBestRecord? fromJsonValue(Object? value) {
    if (value is! Map) {
      return null;
    }

    final map = value.cast<Object?, Object?>();
    final score = (map['score'] as num?)?.toInt();
    final rounds = (map['rounds'] as num?)?.toInt() ?? 0;
    if (score == null || score < 0 || rounds < 0) {
      return null;
    }
    return SchulteJumpBestRecord(score: score, rounds: rounds);
  }
}

class SchulteGridPrefsState {
  const SchulteGridPrefsState({
    this.boardSize = 5,
    this.shapeId = 'square',
    this.modeId = 'timer',
    this.sourceModeId = 'numbers',
    this.customText = '',
    this.contentSplitModeId = 'character',
    this.stripWhitespace = true,
    this.ignorePunctuation = false,
    this.countdownSeconds = 45,
    this.jumpSeconds = 60,
    this.highlightNextTarget = true,
    this.showMemoryHint = true,
    this.hapticsEnabled = true,
    this.wrongTapPenaltyEnabled = false,
    this.bestTimeMsByKey = const <String, int>{},
    this.bestJumpRecordByKey = const <String, SchulteJumpBestRecord>{},
  });

  final int boardSize;
  final String shapeId;
  final String modeId;
  final String sourceModeId;
  final String customText;
  final String contentSplitModeId;
  final bool stripWhitespace;
  final bool ignorePunctuation;
  final int countdownSeconds;
  final int jumpSeconds;
  final bool highlightNextTarget;
  final bool showMemoryHint;
  final bool hapticsEnabled;
  final bool wrongTapPenaltyEnabled;
  final Map<String, int> bestTimeMsByKey;
  final Map<String, SchulteJumpBestRecord> bestJumpRecordByKey;

  SchulteGridPrefsState copyWith({
    int? boardSize,
    String? shapeId,
    String? modeId,
    String? sourceModeId,
    String? customText,
    String? contentSplitModeId,
    bool? stripWhitespace,
    bool? ignorePunctuation,
    int? countdownSeconds,
    int? jumpSeconds,
    bool? highlightNextTarget,
    bool? showMemoryHint,
    bool? hapticsEnabled,
    bool? wrongTapPenaltyEnabled,
    Map<String, int>? bestTimeMsByKey,
    Map<String, SchulteJumpBestRecord>? bestJumpRecordByKey,
  }) {
    return SchulteGridPrefsState(
      boardSize: boardSize ?? this.boardSize,
      shapeId: shapeId ?? this.shapeId,
      modeId: modeId ?? this.modeId,
      sourceModeId: sourceModeId ?? this.sourceModeId,
      customText: customText ?? this.customText,
      contentSplitModeId: contentSplitModeId ?? this.contentSplitModeId,
      stripWhitespace: stripWhitespace ?? this.stripWhitespace,
      ignorePunctuation: ignorePunctuation ?? this.ignorePunctuation,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      jumpSeconds: jumpSeconds ?? this.jumpSeconds,
      highlightNextTarget: highlightNextTarget ?? this.highlightNextTarget,
      showMemoryHint: showMemoryHint ?? this.showMemoryHint,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      wrongTapPenaltyEnabled:
          wrongTapPenaltyEnabled ?? this.wrongTapPenaltyEnabled,
      bestTimeMsByKey: bestTimeMsByKey ?? this.bestTimeMsByKey,
      bestJumpRecordByKey: bestJumpRecordByKey ?? this.bestJumpRecordByKey,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'grid_size': boardSize,
      'shape_id': shapeId,
      'mode_id': modeId,
      'source_mode_id': sourceModeId,
      'content_text': customText,
      'content_split_mode_id': contentSplitModeId,
      'strip_whitespace': stripWhitespace,
      'ignore_punctuation': ignorePunctuation,
      'countdown_seconds': countdownSeconds,
      'jump_seconds': jumpSeconds,
      'highlight_next_target': highlightNextTarget,
      'show_memory_hint': showMemoryHint,
      'haptics_enabled': hapticsEnabled,
      'wrong_tap_penalty_enabled': wrongTapPenaltyEnabled,
      'best_time_ms_by_key': bestTimeMsByKey,
      'best_jump_record_by_key': bestJumpRecordByKey.map(
        (key, value) => MapEntry<String, Object?>(key, value.toJson()),
      ),
    };
  }

  static SchulteGridPrefsState fromJsonValue(Object? value) {
    if (value is! Map) {
      return const SchulteGridPrefsState();
    }

    final map = value.cast<Object?, Object?>();
    return SchulteGridPrefsState(
      boardSize: sanitizeSchulteBoardSize(
        (map['grid_size'] as num?)?.toInt() ?? 5,
      ),
      shapeId: SchulteBoardShape.fromId('${map['shape_id'] ?? 'square'}').id,
      modeId: SchultePlayMode.fromId('${map['mode_id'] ?? 'timer'}').id,
      sourceModeId: SchulteSourceMode.fromId(
        '${map['source_mode_id'] ?? 'numbers'}',
      ).id,
      customText: _limitText('${map['content_text'] ?? ''}'),
      contentSplitModeId: SchulteContentSplitMode.fromId(
        '${map['content_split_mode_id'] ?? map['content_token_mode_id'] ?? 'character'}',
      ).id,
      stripWhitespace:
          map['strip_whitespace'] as bool? ??
          map['content_trim_whitespace'] as bool? ??
          true,
      ignorePunctuation:
          map['ignore_punctuation'] as bool? ??
          map['content_ignore_punctuation'] as bool? ??
          false,
      countdownSeconds: sanitizeSchulteCountdownSeconds(
        (map['countdown_seconds'] as num?)?.toInt() ?? 45,
      ),
      jumpSeconds: sanitizeSchulteJumpSeconds(
        (map['jump_seconds'] as num?)?.toInt() ??
            (map['time_attack_seconds'] as num?)?.toInt() ??
            60,
      ),
      highlightNextTarget:
          map['highlight_next_target'] as bool? ??
          map['show_target_hint'] as bool? ??
          true,
      showMemoryHint:
          map['show_memory_hint'] as bool? ??
          map['show_upcoming_strip'] as bool? ??
          true,
      hapticsEnabled: map['haptics_enabled'] as bool? ?? true,
      wrongTapPenaltyEnabled:
          map['wrong_tap_penalty_enabled'] as bool? ??
          map['wrong_penalty_enabled'] as bool? ??
          false,
      bestTimeMsByKey: _readBestTimeMap(map),
      bestJumpRecordByKey: _readBestJumpMap(map),
    );
  }

  static Map<String, int> _readBestTimeMap(Map<Object?, Object?> map) {
    final result = <String, int>{};

    final direct = map['best_time_ms_by_key'];
    if (direct is Map) {
      for (final entry in direct.entries) {
        final key = '${entry.key}'.trim();
        final value = (entry.value as num?)?.toInt();
        if (key.isEmpty || value == null || value < 0) {
          continue;
        }
        result[key] = value;
      }
    }

    final legacyTop3 = map['best_time_top3_ms_by_key'];
    if (legacyTop3 is Map) {
      for (final entry in legacyTop3.entries) {
        final key = '${entry.key}'.trim();
        if (key.isEmpty || entry.value is! List) {
          continue;
        }
        final values = (entry.value as List)
            .map((item) => (item as num?)?.toInt())
            .whereType<int>()
            .where((item) => item >= 0)
            .toList(growable: false);
        if (values.isEmpty) {
          continue;
        }
        final best = values.reduce(math.min);
        final current = result[key];
        if (current == null || best < current) {
          result[key] = best;
        }
      }
    }

    return result;
  }

  static Map<String, SchulteJumpBestRecord> _readBestJumpMap(
    Map<Object?, Object?> map,
  ) {
    final result = <String, SchulteJumpBestRecord>{};

    final direct = map['best_jump_record_by_key'];
    if (direct is Map) {
      for (final entry in direct.entries) {
        final key = '${entry.key}'.trim();
        final record = SchulteJumpBestRecord.fromJsonValue(entry.value);
        if (key.isEmpty || record == null) {
          continue;
        }
        result[key] = record;
      }
    }

    final legacyScoreMap = map['best_score_by_key'];
    if (legacyScoreMap is Map) {
      for (final entry in legacyScoreMap.entries) {
        final key = '${entry.key}'.trim();
        final score = (entry.value as num?)?.toInt();
        if (key.isEmpty || score == null || score < 0) {
          continue;
        }
        final record = SchulteJumpBestRecord(score: score, rounds: 0);
        if (record.isBetterThan(result[key])) {
          result[key] = record;
        }
      }
    }

    final legacyTop3 = map['best_score_top3_by_key'];
    if (legacyTop3 is Map) {
      for (final entry in legacyTop3.entries) {
        final key = '${entry.key}'.trim();
        if (key.isEmpty || entry.value is! List) {
          continue;
        }
        final values = (entry.value as List)
            .map((item) => (item as num?)?.toInt())
            .whereType<int>()
            .where((item) => item >= 0)
            .toList(growable: false);
        if (values.isEmpty) {
          continue;
        }
        final record = SchulteJumpBestRecord(
          score: values.reduce(math.max),
          rounds: 0,
        );
        if (record.isBetterThan(result[key])) {
          result[key] = record;
        }
      }
    }

    return result;
  }

  static String _limitText(String value) {
    if (value.length <= 12000) {
      return value;
    }
    return value.substring(0, 12000);
  }
}

class ToolboxSchultePrefsService {
  const ToolboxSchultePrefsService._();

  static Future<File> _resolveFile() async {
    final supportDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(supportDir.path, 'toolbox'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File(p.join(dir.path, 'schulte_grid_prefs.json'));
  }

  static Future<SchulteGridPrefsState> load() async {
    try {
      final file = await _resolveFile();
      if (!await file.exists()) {
        return const SchulteGridPrefsState();
      }

      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return const SchulteGridPrefsState();
      }

      return SchulteGridPrefsState.fromJsonValue(jsonDecode(raw));
    } catch (_) {
      return const SchulteGridPrefsState();
    }
  }

  static Future<void> save(SchulteGridPrefsState state) async {
    try {
      final file = await _resolveFile();
      await file.writeAsString(jsonEncode(state.toJson()), flush: true);
    } catch (_) {}
  }
}
