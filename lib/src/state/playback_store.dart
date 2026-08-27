import 'package:flutter/foundation.dart';

import '../models/play_config.dart';
import '../models/settings_dto.dart';
import '../models/word_entry.dart';

class PlaybackUnitProgress {
  const PlaybackUnitProgress({
    required this.current,
    required this.total,
    required this.activeUnit,
  });

  static const empty = PlaybackUnitProgress(
    current: 0,
    total: 0,
    activeUnit: null,
  );

  final int current;
  final int total;
  final PlayUnit? activeUnit;

  bool sameAs(int nextCurrent, int nextTotal, PlayUnit? nextActiveUnit) {
    return current == nextCurrent &&
        total == nextTotal &&
        activeUnit == nextActiveUnit;
  }
}

/// Owns playback-session domain state.
///
/// AppState keeps orchestration and side effects, while this store keeps
/// mutable playback state isolated.
class PlaybackStore {
  bool isPlaying = false;
  bool isPaused = false;
  int currentUnit = 0;
  int totalUnits = 0;
  PlayUnit? activeUnit;
  int? playingWordbookId;
  String? playingWordbookName;
  String? playingWord;
  List<WordEntry> playingScopeWords = <WordEntry>[];
  int playingScopeIndex = 0;
  int playSessionId = 0;
  bool playbackScopeRestarting = false;
  int? queuedPlaybackScopeTarget;
  int wordbookPlaybackSyncToken = 0;
  Map<String, PlaybackProgressSnapshot> playbackProgressByWordbookPath =
      <String, PlaybackProgressSnapshot>{};
  final ValueNotifier<PlaybackUnitProgress> unitProgress =
      ValueNotifier<PlaybackUnitProgress>(PlaybackUnitProgress.empty);
  // Playback changes are high frequency (one event per word). Keep them on a
  // dedicated channel so unrelated AppState listeners do not rebuild for each
  // pronunciation step.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  void notifyChanged() {
    revision.value += 1;
  }

  void setUnitProgress(int current, int total, PlayUnit? activeUnit) {
    if (unitProgress.value.sameAs(current, total, activeUnit)) {
      return;
    }
    currentUnit = current;
    totalUnits = total;
    this.activeUnit = activeUnit;
    unitProgress.value = PlaybackUnitProgress(
      current: current,
      total: total,
      activeUnit: activeUnit,
    );
  }

  void resetUnitProgress() {
    setUnitProgress(0, 0, null);
  }

  void dispose() {
    unitProgress.dispose();
    revision.dispose();
  }
}
