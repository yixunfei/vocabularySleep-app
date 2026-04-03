import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const String _woodfishDefaultFloatingText = '\u529f\u5fb7 +1';

class WoodfishPrefsState {
  const WoodfishPrefsState({
    this.soundId = 'temple',
    this.visualStyleId = 'zen_amber',
    this.reboundArcId = 'compact',
    this.rhythmPresetId = 'calm_four',
    this.bpm = 68,
    this.beatsPerCycle = 4,
    this.subdivision = 1,
    this.accentEvery = 4,
    this.masterVolume = 0.9,
    this.accentBoost = 0.18,
    this.resonance = 0.7,
    this.brightness = 0.48,
    this.pitch = 0.0,
    this.strike = 0.55,
    this.targetCount = 108,
    this.hapticsEnabled = true,
    this.autoStopAtGoal = true,
    this.allTimeCount = 0,
    this.floatingText = _woodfishDefaultFloatingText,
  });

  final String soundId;
  final String visualStyleId;
  final String reboundArcId;
  final String rhythmPresetId;
  final int bpm;
  final int beatsPerCycle;
  final int subdivision;
  final int accentEvery;
  final double masterVolume;
  final double accentBoost;
  final double resonance;
  final double brightness;
  final double pitch;
  final double strike;
  final int targetCount;
  final bool hapticsEnabled;
  final bool autoStopAtGoal;
  final int allTimeCount;
  final String floatingText;

  WoodfishPrefsState copyWith({
    String? soundId,
    String? visualStyleId,
    String? reboundArcId,
    String? rhythmPresetId,
    int? bpm,
    int? beatsPerCycle,
    int? subdivision,
    int? accentEvery,
    double? masterVolume,
    double? accentBoost,
    double? resonance,
    double? brightness,
    double? pitch,
    double? strike,
    int? targetCount,
    bool? hapticsEnabled,
    bool? autoStopAtGoal,
    int? allTimeCount,
    String? floatingText,
  }) {
    return WoodfishPrefsState(
      soundId: soundId ?? this.soundId,
      visualStyleId: visualStyleId ?? this.visualStyleId,
      reboundArcId: reboundArcId ?? this.reboundArcId,
      rhythmPresetId: rhythmPresetId ?? this.rhythmPresetId,
      bpm: bpm ?? this.bpm,
      beatsPerCycle: beatsPerCycle ?? this.beatsPerCycle,
      subdivision: subdivision ?? this.subdivision,
      accentEvery: accentEvery ?? this.accentEvery,
      masterVolume: masterVolume ?? this.masterVolume,
      accentBoost: accentBoost ?? this.accentBoost,
      resonance: resonance ?? this.resonance,
      brightness: brightness ?? this.brightness,
      pitch: pitch ?? this.pitch,
      strike: strike ?? this.strike,
      targetCount: targetCount ?? this.targetCount,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      autoStopAtGoal: autoStopAtGoal ?? this.autoStopAtGoal,
      allTimeCount: allTimeCount ?? this.allTimeCount,
      floatingText: floatingText ?? this.floatingText,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'sound_id': soundId,
      'visual_style_id': visualStyleId,
      'rebound_arc_id': reboundArcId,
      'rhythm_preset_id': rhythmPresetId,
      'bpm': bpm,
      'beats_per_cycle': beatsPerCycle,
      'subdivision': subdivision,
      'accent_every': accentEvery,
      'master_volume': masterVolume,
      'accent_boost': accentBoost,
      'resonance': resonance,
      'brightness': brightness,
      'pitch': pitch,
      'strike': strike,
      'target_count': targetCount,
      'haptics_enabled': hapticsEnabled,
      'auto_stop_at_goal': autoStopAtGoal,
      'all_time_count': allTimeCount,
      'floating_text': floatingText,
    };
  }

  static WoodfishPrefsState fromJsonValue(Object? value) {
    if (value is! Map) {
      return const WoodfishPrefsState();
    }
    final map = value.cast<Object?, Object?>();
    final beatsPerCycle = ((map['beats_per_cycle'] as num?)?.toInt() ?? 4)
        .clamp(1, 16)
        .toInt();
    final subdivision = ((map['subdivision'] as num?)?.toInt() ?? 1)
        .clamp(1, 6)
        .toInt();
    final maxAccent = (beatsPerCycle * subdivision).clamp(1, 64).toInt();
    final floatingRaw = '${map['floating_text'] ?? ''}'
        .replaceAll('\n', ' ')
        .trim();
    final floatingText = floatingRaw.isEmpty
        ? _woodfishDefaultFloatingText
        : floatingRaw.substring(0, math.min(18, floatingRaw.length));
    return WoodfishPrefsState(
      soundId: '${map['sound_id'] ?? 'temple'}'.trim().isEmpty
          ? 'temple'
          : '${map['sound_id']}'.trim(),
      visualStyleId: '${map['visual_style_id'] ?? 'zen_amber'}'.trim().isEmpty
          ? 'zen_amber'
          : '${map['visual_style_id']}'.trim(),
      reboundArcId: '${map['rebound_arc_id'] ?? 'compact'}'.trim().isEmpty
          ? 'compact'
          : '${map['rebound_arc_id']}'.trim(),
      rhythmPresetId: '${map['rhythm_preset_id'] ?? 'calm_four'}'.trim().isEmpty
          ? 'calm_four'
          : '${map['rhythm_preset_id']}'.trim(),
      bpm: ((map['bpm'] as num?)?.toInt() ?? 68).clamp(36, 220).toInt(),
      beatsPerCycle: beatsPerCycle,
      subdivision: subdivision,
      accentEvery: ((map['accent_every'] as num?)?.toInt() ?? 4)
          .clamp(1, maxAccent)
          .toInt(),
      masterVolume: ((map['master_volume'] as num?)?.toDouble() ?? 0.9).clamp(
        0.0,
        1.0,
      ),
      accentBoost: ((map['accent_boost'] as num?)?.toDouble() ?? 0.18).clamp(
        0.0,
        0.6,
      ),
      resonance: ((map['resonance'] as num?)?.toDouble() ?? 0.7).clamp(
        0.0,
        1.0,
      ),
      brightness: ((map['brightness'] as num?)?.toDouble() ?? 0.48).clamp(
        0.0,
        1.0,
      ),
      pitch: ((map['pitch'] as num?)?.toDouble() ?? 0.0).clamp(-6.0, 6.0),
      strike: ((map['strike'] as num?)?.toDouble() ?? 0.55).clamp(0.0, 1.0),
      targetCount: ((map['target_count'] as num?)?.toInt() ?? 108)
          .clamp(1, 9999)
          .toInt(),
      hapticsEnabled: map['haptics_enabled'] as bool? ?? true,
      autoStopAtGoal: map['auto_stop_at_goal'] as bool? ?? true,
      allTimeCount: ((map['all_time_count'] as num?)?.toInt() ?? 0).clamp(
        0,
        999999999,
      ),
      floatingText: floatingText,
    );
  }
}

class ToolboxWoodfishPrefsService {
  const ToolboxWoodfishPrefsService._();

  static Future<File> _resolveFile() async {
    final supportDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(supportDir.path, 'toolbox'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File(p.join(dir.path, 'woodfish_prefs.json'));
  }

  static Future<WoodfishPrefsState> load() async {
    try {
      final file = await _resolveFile();
      if (!await file.exists()) {
        return const WoodfishPrefsState();
      }
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return const WoodfishPrefsState();
      }
      return WoodfishPrefsState.fromJsonValue(jsonDecode(raw));
    } catch (_) {
      return const WoodfishPrefsState();
    }
  }

  static Future<void> save(WoodfishPrefsState state) async {
    try {
      final file = await _resolveFile();
      await file.writeAsString(jsonEncode(state.toJson()), flush: true);
    } catch (_) {}
  }
}
