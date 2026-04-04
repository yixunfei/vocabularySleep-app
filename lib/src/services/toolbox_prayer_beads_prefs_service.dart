import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PrayerBeadsPrefsState {
  const PrayerBeadsPrefsState({
    this.materialId = 'sandalwood',
    this.beadCount = 108,
    this.sessionCount = 0,
    this.allTimeCount = 0,
    this.soundEnabled = true,
    this.hapticsEnabled = true,
  });

  final String materialId;
  final int beadCount;
  final int sessionCount;
  final int allTimeCount;
  final bool soundEnabled;
  final bool hapticsEnabled;

  PrayerBeadsPrefsState copyWith({
    String? materialId,
    int? beadCount,
    int? sessionCount,
    int? allTimeCount,
    bool? soundEnabled,
    bool? hapticsEnabled,
  }) {
    return PrayerBeadsPrefsState(
      materialId: materialId ?? this.materialId,
      beadCount: beadCount ?? this.beadCount,
      sessionCount: sessionCount ?? this.sessionCount,
      allTimeCount: allTimeCount ?? this.allTimeCount,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'material_id': materialId,
      'bead_count': beadCount,
      'session_count': sessionCount,
      'all_time_count': allTimeCount,
      'sound_enabled': soundEnabled,
      'haptics_enabled': hapticsEnabled,
    };
  }

  static PrayerBeadsPrefsState fromJsonValue(Object? value) {
    if (value is! Map) {
      return const PrayerBeadsPrefsState();
    }
    final map = value.cast<Object?, Object?>();
    final beadCount = ((map['bead_count'] as num?)?.toInt() ?? 108)
        .clamp(27, 108)
        .toInt();
    final normalizedBeadCount = switch (beadCount) {
      < 41 => 27,
      < 81 => 54,
      _ => 108,
    };
    return PrayerBeadsPrefsState(
      materialId: _normalizeMaterialId('${map['material_id'] ?? 'sandalwood'}'),
      beadCount: normalizedBeadCount,
      sessionCount: ((map['session_count'] as num?)?.toInt() ?? 0)
          .clamp(0, 999999)
          .toInt(),
      allTimeCount: ((map['all_time_count'] as num?)?.toInt() ?? 0)
          .clamp(0, 999999999)
          .toInt(),
      soundEnabled: map['sound_enabled'] as bool? ?? true,
      hapticsEnabled: map['haptics_enabled'] as bool? ?? true,
    );
  }

  static String _normalizeMaterialId(String rawValue) {
    final value = rawValue.trim();
    if (value.isEmpty) {
      return 'sandalwood';
    }
    return switch (value) {
      'jade' => 'jade',
      'lapis' => 'lapis',
      'bodhi' => 'bodhi',
      'obsidian' => 'obsidian',
      _ => 'sandalwood',
    };
  }
}

class ToolboxPrayerBeadsPrefsService {
  const ToolboxPrayerBeadsPrefsService._();

  static Future<File> _resolveFile() async {
    final supportDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(supportDir.path, 'toolbox'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return File(p.join(dir.path, 'prayer_beads_prefs.json'));
  }

  static Future<PrayerBeadsPrefsState> load() async {
    try {
      final file = await _resolveFile();
      if (!await file.exists()) {
        return const PrayerBeadsPrefsState();
      }
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return const PrayerBeadsPrefsState();
      }
      return PrayerBeadsPrefsState.fromJsonValue(jsonDecode(raw));
    } catch (_) {
      return const PrayerBeadsPrefsState();
    }
  }

  static Future<void> save(PrayerBeadsPrefsState state) async {
    try {
      final file = await _resolveFile();
      await file.writeAsString(jsonEncode(state.toJson()), flush: true);
    } catch (_) {
      // Best-effort persistence.
    }
  }
}
