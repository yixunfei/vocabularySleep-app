import '../models/play_config.dart';
import '../models/settings_dto.dart';
import '../models/word_entry.dart';

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
}
