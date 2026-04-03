import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FocusBeatsArrangementTemplate {
  const FocusBeatsArrangementTemplate({
    required this.id,
    required this.name,
    required this.patternText,
    this.isFavorite = false,
  });

  final String id;
  final String name;
  final String patternText;
  final bool isFavorite;

  FocusBeatsArrangementTemplate copyWith({
    String? id,
    String? name,
    String? patternText,
    bool? isFavorite,
  }) {
    return FocusBeatsArrangementTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      patternText: patternText ?? this.patternText,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'pattern_text': patternText,
      'is_favorite': isFavorite,
    };
  }

  static FocusBeatsArrangementTemplate? fromJsonValue(Object? value) {
    if (value is! Map) {
      return null;
    }
    final map = value.cast<Object?, Object?>();
    final id = '${map['id'] ?? ''}'.trim();
    final name = '${map['name'] ?? ''}'.trim();
    final patternText = '${map['pattern_text'] ?? ''}'.trim();
    if (id.isEmpty || name.isEmpty || patternText.isEmpty) {
      return null;
    }
    return FocusBeatsArrangementTemplate(
      id: id,
      name: name,
      patternText: patternText,
      isFavorite: map['is_favorite'] as bool? ?? false,
    );
  }
}

class FocusBeatsPrefsState {
  const FocusBeatsPrefsState({
    this.bpm = 72,
    this.beatsPerBar = 4,
    this.subdivision = 1,
    this.soundId = 'pendulum',
    this.animationId = 'pendulum',
    this.linkedSelection = true,
    this.patternText = '2bar+2bar',
    this.patternEnabled = false,
    this.masterVolume = 0.9,
    this.accentVolume = 1.0,
    this.regularVolume = 0.78,
    this.subdivisionVolume = 0.54,
    this.hapticsEnabled = true,
    this.arrangementTemplates = const <FocusBeatsArrangementTemplate>[],
    this.activeArrangementTemplateId,
  });

  final int bpm;
  final int beatsPerBar;
  final int subdivision;
  final String soundId;
  final String animationId;
  final bool linkedSelection;
  final String patternText;
  final bool patternEnabled;
  final double masterVolume;
  final double accentVolume;
  final double regularVolume;
  final double subdivisionVolume;
  final bool hapticsEnabled;
  final List<FocusBeatsArrangementTemplate> arrangementTemplates;
  final String? activeArrangementTemplateId;

  FocusBeatsPrefsState copyWith({
    int? bpm,
    int? beatsPerBar,
    int? subdivision,
    String? soundId,
    String? animationId,
    bool? linkedSelection,
    String? patternText,
    bool? patternEnabled,
    double? masterVolume,
    double? accentVolume,
    double? regularVolume,
    double? subdivisionVolume,
    bool? hapticsEnabled,
    List<FocusBeatsArrangementTemplate>? arrangementTemplates,
    String? activeArrangementTemplateId,
  }) {
    return FocusBeatsPrefsState(
      bpm: bpm ?? this.bpm,
      beatsPerBar: beatsPerBar ?? this.beatsPerBar,
      subdivision: subdivision ?? this.subdivision,
      soundId: soundId ?? this.soundId,
      animationId: animationId ?? this.animationId,
      linkedSelection: linkedSelection ?? this.linkedSelection,
      patternText: patternText ?? this.patternText,
      patternEnabled: patternEnabled ?? this.patternEnabled,
      masterVolume: masterVolume ?? this.masterVolume,
      accentVolume: accentVolume ?? this.accentVolume,
      regularVolume: regularVolume ?? this.regularVolume,
      subdivisionVolume: subdivisionVolume ?? this.subdivisionVolume,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      arrangementTemplates: arrangementTemplates ?? this.arrangementTemplates,
      activeArrangementTemplateId:
          activeArrangementTemplateId ?? this.activeArrangementTemplateId,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'bpm': bpm,
      'beats_per_bar': beatsPerBar,
      'subdivision': subdivision,
      'sound_id': soundId,
      'animation_id': animationId,
      'linked_selection': linkedSelection,
      'pattern_text': patternText,
      'pattern_enabled': patternEnabled,
      'master_volume': masterVolume,
      'accent_volume': accentVolume,
      'regular_volume': regularVolume,
      'subdivision_volume': subdivisionVolume,
      'haptics_enabled': hapticsEnabled,
      'arrangement_templates': arrangementTemplates
          .map((template) => template.toJson())
          .toList(growable: false),
      'active_arrangement_template_id': activeArrangementTemplateId,
    };
  }

  static FocusBeatsPrefsState fromJsonValue(Object? value) {
    if (value is! Map) {
      return const FocusBeatsPrefsState();
    }
    final map = value.cast<Object?, Object?>();
    final templatesRaw = map['arrangement_templates'];
    final templates = templatesRaw is List
        ? templatesRaw
              .map(FocusBeatsArrangementTemplate.fromJsonValue)
              .whereType<FocusBeatsArrangementTemplate>()
              .toList(growable: false)
        : const <FocusBeatsArrangementTemplate>[];
    final activeTemplateId =
        '${map['active_arrangement_template_id'] ?? ''}'.trim().isEmpty
        ? null
        : '${map['active_arrangement_template_id']}'.trim();
    return FocusBeatsPrefsState(
      bpm: ((map['bpm'] as num?)?.toInt() ?? 72).clamp(30, 220),
      beatsPerBar: ((map['beats_per_bar'] as num?)?.toInt() ?? 4).clamp(2, 12),
      subdivision: ((map['subdivision'] as num?)?.toInt() ?? 1).clamp(1, 6),
      soundId: '${map['sound_id'] ?? 'pendulum'}'.trim().isEmpty
          ? 'pendulum'
          : '${map['sound_id']}'.trim(),
      animationId: '${map['animation_id'] ?? 'pendulum'}'.trim().isEmpty
          ? 'pendulum'
          : '${map['animation_id']}'.trim(),
      linkedSelection: map['linked_selection'] as bool? ?? true,
      patternText: '${map['pattern_text'] ?? '2bar+2bar'}'.trim().isEmpty
          ? '2bar+2bar'
          : '${map['pattern_text']}'.trim(),
      patternEnabled: map['pattern_enabled'] as bool? ?? false,
      masterVolume: ((map['master_volume'] as num?)?.toDouble() ?? 0.9).clamp(
        0.0,
        1.0,
      ),
      accentVolume: ((map['accent_volume'] as num?)?.toDouble() ?? 1.0).clamp(
        0.0,
        1.0,
      ),
      regularVolume: ((map['regular_volume'] as num?)?.toDouble() ?? 0.78)
          .clamp(0.0, 1.0),
      subdivisionVolume:
          ((map['subdivision_volume'] as num?)?.toDouble() ?? 0.54).clamp(
            0.0,
            1.0,
          ),
      hapticsEnabled: map['haptics_enabled'] as bool? ?? true,
      arrangementTemplates: templates,
      activeArrangementTemplateId: activeTemplateId,
    );
  }
}

class ToolboxFocusBeatsPrefsService {
  const ToolboxFocusBeatsPrefsService._();

  static Future<File> _resolveFile() async {
    final supportDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(supportDir.path, 'toolbox'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File(p.join(dir.path, 'focus_beats_prefs.json'));
  }

  static Future<FocusBeatsPrefsState> load() async {
    try {
      final file = await _resolveFile();
      if (!await file.exists()) {
        return const FocusBeatsPrefsState();
      }
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return const FocusBeatsPrefsState();
      }
      return FocusBeatsPrefsState.fromJsonValue(jsonDecode(raw));
    } catch (_) {
      return const FocusBeatsPrefsState();
    }
  }

  static Future<void> save(FocusBeatsPrefsState state) async {
    try {
      final file = await _resolveFile();
      await file.writeAsString(jsonEncode(state.toJson()), flush: true);
    } catch (_) {}
  }
}
