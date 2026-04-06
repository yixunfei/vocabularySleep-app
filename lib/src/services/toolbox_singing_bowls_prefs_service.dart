import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class SingingBowlsPrefsState {
  const SingingBowlsPrefsState({
    this.frequencyId = 'heart',
    this.voiceId = 'crystal',
    this.autoPlayIntervalMs = 5000,
    this.soundEnabled = true,
    this.hapticsEnabled = true,
  });

  final String frequencyId;
  final String voiceId;
  final int autoPlayIntervalMs;
  final bool soundEnabled;
  final bool hapticsEnabled;

  SingingBowlsPrefsState copyWith({
    String? frequencyId,
    String? voiceId,
    int? autoPlayIntervalMs,
    bool? soundEnabled,
    bool? hapticsEnabled,
  }) {
    return SingingBowlsPrefsState(
      frequencyId: frequencyId ?? this.frequencyId,
      voiceId: voiceId ?? this.voiceId,
      autoPlayIntervalMs: autoPlayIntervalMs ?? this.autoPlayIntervalMs,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'frequency_id': frequencyId,
      'voice_id': voiceId,
      'auto_play_interval_ms': autoPlayIntervalMs,
      'sound_enabled': soundEnabled,
      'haptics_enabled': hapticsEnabled,
    };
  }

  static SingingBowlsPrefsState fromJsonValue(Object? value) {
    if (value is! Map) {
      return const SingingBowlsPrefsState();
    }
    final map = value.cast<Object?, Object?>();
    return SingingBowlsPrefsState(
      frequencyId: _normalizeFrequencyId('${map['frequency_id'] ?? 'heart'}'),
      voiceId: _normalizeVoiceId('${map['voice_id'] ?? 'crystal'}'),
      autoPlayIntervalMs:
          ((map['auto_play_interval_ms'] as num?)?.toInt() ?? 5000)
              .clamp(2000, 30000)
              .toInt(),
      soundEnabled: map['sound_enabled'] as bool? ?? true,
      hapticsEnabled: map['haptics_enabled'] as bool? ?? true,
    );
  }

  static String _normalizeFrequencyId(String rawValue) {
    return switch (rawValue.trim()) {
      'root' => 'root',
      'sacral' => 'sacral',
      'solar' => 'solar',
      'heart' => 'heart',
      'throat' => 'throat',
      'third-eye' => 'third_eye',
      'third_eye' => 'third_eye',
      'crown' => 'crown',
      '174' => '174',
      '285' => '285',
      'om' => 'om',
      '432' => '432',
      _ => 'heart',
    };
  }

  static String _normalizeVoiceId(String rawValue) {
    return switch (rawValue.trim()) {
      'crystal' => 'crystal',
      'brass' => 'brass',
      'deep' => 'deep',
      'pure' => 'pure',
      _ => 'crystal',
    };
  }
}

class ToolboxSingingBowlsPrefsService {
  const ToolboxSingingBowlsPrefsService._();

  static Future<File> _resolveFile() async {
    final supportDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(supportDir.path, 'toolbox'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File(p.join(dir.path, 'singing_bowls_prefs.json'));
  }

  static Future<SingingBowlsPrefsState> load() async {
    try {
      final file = await _resolveFile();
      if (!await file.exists()) {
        return const SingingBowlsPrefsState();
      }
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return const SingingBowlsPrefsState();
      }
      return SingingBowlsPrefsState.fromJsonValue(jsonDecode(raw));
    } catch (_) {
      return const SingingBowlsPrefsState();
    }
  }

  static Future<void> save(SingingBowlsPrefsState state) async {
    try {
      final file = await _resolveFile();
      await file.writeAsString(jsonEncode(state.toJson()), flush: true);
    } catch (_) {
      // Best-effort persistence.
    }
  }
}
