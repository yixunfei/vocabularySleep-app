import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class BreathingPracticePrefsState {
  const BreathingPracticePrefsState({
    this.presetId = 'diaphragm_4262',
    this.themeId = 'ocean',
    this.targetMinutes = 5,
    this.includeRecoveryStage = false,
    this.voiceGuidanceEnabled = true,
    this.textGuidanceEnabled = true,
    this.hapticsEnabled = true,
    this.completedSessions = 0,
    this.totalPracticeSeconds = 0,
  });

  final String presetId;
  final String themeId;
  final int targetMinutes;
  final bool includeRecoveryStage;
  final bool voiceGuidanceEnabled;
  final bool textGuidanceEnabled;
  final bool hapticsEnabled;
  final int completedSessions;
  final int totalPracticeSeconds;

  BreathingPracticePrefsState copyWith({
    String? presetId,
    String? themeId,
    int? targetMinutes,
    bool? includeRecoveryStage,
    bool? voiceGuidanceEnabled,
    bool? textGuidanceEnabled,
    bool? hapticsEnabled,
    int? completedSessions,
    int? totalPracticeSeconds,
  }) {
    return BreathingPracticePrefsState(
      presetId: presetId ?? this.presetId,
      themeId: themeId ?? this.themeId,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      includeRecoveryStage: includeRecoveryStage ?? this.includeRecoveryStage,
      voiceGuidanceEnabled: voiceGuidanceEnabled ?? this.voiceGuidanceEnabled,
      textGuidanceEnabled: textGuidanceEnabled ?? this.textGuidanceEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      completedSessions: completedSessions ?? this.completedSessions,
      totalPracticeSeconds: totalPracticeSeconds ?? this.totalPracticeSeconds,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'preset_id': presetId,
      'theme_id': themeId,
      'target_minutes': targetMinutes,
      'include_recovery_stage': includeRecoveryStage,
      'voice_guidance_enabled': voiceGuidanceEnabled,
      'text_guidance_enabled': textGuidanceEnabled,
      'haptics_enabled': hapticsEnabled,
      'completed_sessions': completedSessions,
      'total_practice_seconds': totalPracticeSeconds,
    };
  }

  static BreathingPracticePrefsState fromJsonValue(Object? value) {
    if (value is! Map) {
      return const BreathingPracticePrefsState();
    }
    final map = value.cast<Object?, Object?>();
    final rawPresetId = '${map['preset_id'] ?? 'diaphragm_4262'}'.trim();
    final rawThemeId = '${map['theme_id'] ?? 'ocean'}'.trim();
    return BreathingPracticePrefsState(
      presetId: ToolboxBreathingPrefsService._normalizePresetId(rawPresetId),
      themeId: ToolboxBreathingPrefsService._normalizeThemeId(rawThemeId),
      targetMinutes: ((map['target_minutes'] as num?)?.toInt() ?? 5)
          .clamp(2, 20)
          .toInt(),
      includeRecoveryStage: map['include_recovery_stage'] as bool? ?? false,
      voiceGuidanceEnabled: map['voice_guidance_enabled'] as bool? ?? true,
      textGuidanceEnabled: map['text_guidance_enabled'] as bool? ?? true,
      hapticsEnabled: map['haptics_enabled'] as bool? ?? true,
      completedSessions: ((map['completed_sessions'] as num?)?.toInt() ?? 0)
          .clamp(0, 999999)
          .toInt(),
      totalPracticeSeconds:
          ((map['total_practice_seconds'] as num?)?.toInt() ?? 0)
              .clamp(0, 2147483647)
              .toInt(),
    );
  }
}

class ToolboxBreathingPrefsService {
  const ToolboxBreathingPrefsService._();

  static Future<File> _resolveFile() async {
    final supportDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(supportDir.path, 'toolbox'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File(p.join(dir.path, 'breathing_practice_prefs.json'));
  }

  static Future<BreathingPracticePrefsState> load() async {
    try {
      final file = await _resolveFile();
      if (!await file.exists()) {
        return const BreathingPracticePrefsState();
      }
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return const BreathingPracticePrefsState();
      }
      return BreathingPracticePrefsState.fromJsonValue(jsonDecode(raw));
    } catch (_) {
      return const BreathingPracticePrefsState();
    }
  }

  static Future<void> save(BreathingPracticePrefsState state) async {
    try {
      final file = await _resolveFile();
      await file.writeAsString(jsonEncode(state.toJson()), flush: true);
    } catch (_) {
      // Best-effort persistence.
    }
  }

  static String _normalizePresetId(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return 'diaphragm_4262';
    }
    return switch (normalized) {
      'box_4_4_4_4' => 'box_4444',
      'box_4444' => 'box_4444',
      'unwind_4262' => 'relax_4262',
      'deep_36' => 'calm_36',
      'refresh_3131' => 'focus_nasal_44',
      'energize_3131' => 'focus_nasal_44',
      'altitude_2442' => 'physiological_sigh_216',
      _ => normalized,
    };
  }

  static String _normalizeThemeId(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return 'ocean';
    }
    return switch (normalized) {
      'ocean_glow' => 'ocean',
      'sunset' => 'ember',
      _ => normalized,
    };
  }
}
