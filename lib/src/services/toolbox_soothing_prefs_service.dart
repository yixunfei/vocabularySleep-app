import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum SoothingPlaybackMode { singleLoop, modeCycle, arrangement }

extension SoothingPlaybackModeStorage on SoothingPlaybackMode {
  String get storageValue => switch (this) {
    SoothingPlaybackMode.singleLoop => 'single_loop',
    SoothingPlaybackMode.modeCycle => 'mode_cycle',
    SoothingPlaybackMode.arrangement => 'arrangement',
  };

  static SoothingPlaybackMode fromStorage(String? value) {
    return switch ((value ?? '').trim()) {
      'mode_cycle' => SoothingPlaybackMode.modeCycle,
      'arrangement' => SoothingPlaybackMode.arrangement,
      _ => SoothingPlaybackMode.singleLoop,
    };
  }
}

class SoothingPlaybackArrangementStep {
  const SoothingPlaybackArrangementStep({
    required this.modeId,
    required this.trackIndex,
    this.repeatCount = 1,
  });

  final String modeId;
  final int trackIndex;
  final int repeatCount;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'mode_id': modeId,
      'track_index': trackIndex,
      'repeat_count': repeatCount,
    };
  }

  SoothingPlaybackArrangementStep copyWith({
    String? modeId,
    int? trackIndex,
    int? repeatCount,
  }) {
    return SoothingPlaybackArrangementStep(
      modeId: modeId ?? this.modeId,
      trackIndex: trackIndex ?? this.trackIndex,
      repeatCount: repeatCount ?? this.repeatCount,
    );
  }

  static SoothingPlaybackArrangementStep? fromJsonValue(Object? value) {
    if (value is! Map) {
      return null;
    }
    final map = value.cast<Object?, Object?>();
    final modeId = '${map['mode_id'] ?? ''}'.trim();
    if (modeId.isEmpty) {
      return null;
    }
    return SoothingPlaybackArrangementStep(
      modeId: modeId,
      trackIndex: (map['track_index'] as num?)?.toInt() ?? 0,
      repeatCount: ((map['repeat_count'] as num?)?.toInt() ?? 1).clamp(1, 99),
    );
  }
}

class SoothingPlaybackArrangementTemplate {
  const SoothingPlaybackArrangementTemplate({
    required this.id,
    required this.name,
    required this.steps,
  });

  final String id;
  final String name;
  final List<SoothingPlaybackArrangementStep> steps;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'steps': steps.map((step) => step.toJson()).toList(growable: false),
    };
  }

  SoothingPlaybackArrangementTemplate copyWith({
    String? id,
    String? name,
    List<SoothingPlaybackArrangementStep>? steps,
  }) {
    return SoothingPlaybackArrangementTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      steps: steps ?? this.steps,
    );
  }

  static SoothingPlaybackArrangementTemplate? fromJsonValue(Object? value) {
    if (value is! Map) {
      return null;
    }
    final map = value.cast<Object?, Object?>();
    final id = '${map['id'] ?? ''}'.trim();
    final name = '${map['name'] ?? ''}'.trim();
    if (id.isEmpty || name.isEmpty) {
      return null;
    }
    final stepsRaw = map['steps'];
    final steps = stepsRaw is List
        ? stepsRaw
              .map(SoothingPlaybackArrangementStep.fromJsonValue)
              .whereType<SoothingPlaybackArrangementStep>()
              .toList(growable: false)
        : const <SoothingPlaybackArrangementStep>[];
    if (steps.isEmpty) {
      return null;
    }
    return SoothingPlaybackArrangementTemplate(
      id: id,
      name: name,
      steps: steps,
    );
  }
}

class SoothingPrefsState {
  const SoothingPrefsState({
    this.favoriteModeIds = const <String>{},
    this.recentModeIds = const <String>[],
    this.lastTrackIndexByMode = const <String, int>{},
    this.lastModeId,
    this.continuePlaybackOnExit = false,
    this.playbackMode = SoothingPlaybackMode.singleLoop,
    this.arrangementSteps = const <SoothingPlaybackArrangementStep>[],
    this.arrangementTemplates = const <SoothingPlaybackArrangementTemplate>[],
    this.activeArrangementTemplateId,
  });

  final Set<String> favoriteModeIds;
  final List<String> recentModeIds;
  final Map<String, int> lastTrackIndexByMode;
  final String? lastModeId;
  final bool continuePlaybackOnExit;
  final SoothingPlaybackMode playbackMode;
  final List<SoothingPlaybackArrangementStep> arrangementSteps;
  final List<SoothingPlaybackArrangementTemplate> arrangementTemplates;
  final String? activeArrangementTemplateId;

  Map<String, Object?> toJson() {
    final favorites = favoriteModeIds.toList(growable: false)..sort();
    return <String, Object?>{
      'favorite_mode_ids': favorites,
      'recent_mode_ids': recentModeIds,
      'last_track_index_by_mode': lastTrackIndexByMode,
      'last_mode_id': lastModeId,
      'continue_playback_on_exit': continuePlaybackOnExit,
      'playback_mode': playbackMode.storageValue,
      'arrangement_steps': arrangementSteps
          .map((step) => step.toJson())
          .toList(growable: false),
      'arrangement_templates': arrangementTemplates
          .map((template) => template.toJson())
          .toList(growable: false),
      'active_arrangement_template_id': activeArrangementTemplateId,
    };
  }

  static SoothingPrefsState fromJsonValue(Object? value) {
    if (value is! Map) {
      return const SoothingPrefsState();
    }
    final map = value.cast<Object?, Object?>();
    final favoriteRaw = map['favorite_mode_ids'];
    final recentRaw = map['recent_mode_ids'];
    final tracksRaw = map['last_track_index_by_mode'];
    final arrangementRaw = map['arrangement_steps'];
    final arrangementTemplatesRaw = map['arrangement_templates'];
    return SoothingPrefsState(
      favoriteModeIds: favoriteRaw is List
          ? favoriteRaw
                .map((item) => '$item'.trim())
                .where((item) => item.isNotEmpty)
                .toSet()
          : const <String>{},
      recentModeIds: recentRaw is List
          ? recentRaw
                .map((item) => '$item'.trim())
                .where((item) => item.isNotEmpty)
                .toList(growable: false)
          : const <String>[],
      lastTrackIndexByMode: tracksRaw is Map
          ? <String, int>{
              for (final entry in tracksRaw.entries)
                if ('${entry.key}'.trim().isNotEmpty)
                  '${entry.key}'.trim(): (entry.value as num?)?.toInt() ?? 0,
            }
          : const <String, int>{},
      lastModeId: '${map['last_mode_id'] ?? ''}'.trim().isEmpty
          ? null
          : '${map['last_mode_id']}'.trim(),
      continuePlaybackOnExit:
          map['continue_playback_on_exit'] as bool? ?? false,
      playbackMode: SoothingPlaybackModeStorage.fromStorage(
        '${map['playback_mode'] ?? ''}',
      ),
      arrangementSteps: arrangementRaw is List
          ? arrangementRaw
                .map(SoothingPlaybackArrangementStep.fromJsonValue)
                .whereType<SoothingPlaybackArrangementStep>()
                .toList(growable: false)
          : const <SoothingPlaybackArrangementStep>[],
      arrangementTemplates: arrangementTemplatesRaw is List
          ? arrangementTemplatesRaw
                .map(SoothingPlaybackArrangementTemplate.fromJsonValue)
                .whereType<SoothingPlaybackArrangementTemplate>()
                .toList(growable: false)
          : const <SoothingPlaybackArrangementTemplate>[],
      activeArrangementTemplateId:
          '${map['active_arrangement_template_id'] ?? ''}'.trim().isEmpty
          ? null
          : '${map['active_arrangement_template_id']}'.trim(),
    );
  }
}

class ToolboxSoothingPrefsService {
  const ToolboxSoothingPrefsService._();

  static Future<File> _resolveFile() async {
    final supportDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(supportDir.path, 'toolbox'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File(p.join(dir.path, 'soothing_prefs.json'));
  }

  static Future<SoothingPrefsState> load() async {
    try {
      final file = await _resolveFile();
      if (!await file.exists()) {
        return const SoothingPrefsState();
      }
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return const SoothingPrefsState();
      }
      return SoothingPrefsState.fromJsonValue(jsonDecode(raw));
    } catch (_) {
      return const SoothingPrefsState();
    }
  }

  static Future<void> save(SoothingPrefsState state) async {
    try {
      final file = await _resolveFile();
      await file.writeAsString(jsonEncode(state.toJson()), flush: true);
    } catch (_) {
      // Best-effort persistence.
    }
  }
}
