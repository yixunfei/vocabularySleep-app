import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class SoothingPrefsState {
  const SoothingPrefsState({
    this.favoriteModeIds = const <String>{},
    this.recentModeIds = const <String>[],
    this.lastTrackIndexByMode = const <String, int>{},
    this.lastModeId,
    this.continuePlaybackOnExit = false,
  });

  final Set<String> favoriteModeIds;
  final List<String> recentModeIds;
  final Map<String, int> lastTrackIndexByMode;
  final String? lastModeId;
  final bool continuePlaybackOnExit;

  Map<String, Object?> toJson() {
    final favorites = favoriteModeIds.toList(growable: false)..sort();
    return <String, Object?>{
      'favorite_mode_ids': favorites,
      'recent_mode_ids': recentModeIds,
      'last_track_index_by_mode': lastTrackIndexByMode,
      'last_mode_id': lastModeId,
      'continue_playback_on_exit': continuePlaybackOnExit,
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
