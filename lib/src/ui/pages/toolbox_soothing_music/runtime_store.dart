import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../../../services/audio_player_source_helper.dart';
import '../../../services/cstcloud_resource_cache_service.dart';
import '../../../services/toolbox_soothing_prefs_service.dart';
import 'track_catalog.dart';
import 'track_loader.dart';

class SoothingMusicRuntimeStore {
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static Set<String> favoriteModeIds = <String>{};
  static List<String> recentModeIds = <String>[];
  static Map<String, int> lastTrackIndexByMode = <String, int>{};
  static String? lastModeId;
  static SoothingPlaybackMode playbackMode = SoothingPlaybackMode.singleLoop;
  static List<SoothingPlaybackArrangementStep> arrangementSteps =
      <SoothingPlaybackArrangementStep>[];
  static List<SoothingPlaybackArrangementTemplate> arrangementTemplates =
      <SoothingPlaybackArrangementTemplate>[];
  static String? activeArrangementTemplateId;
  static int arrangementStepIndex = 0;
  static int arrangementStepPlayCount = 0;
  static AudioPlayer? retainedPlayer;
  static String? activeModeId;
  static int activeTrackIndex = 0;
  static bool activePlaying = false;
  static double activeVolume = 0.62;
  static bool activeMuted = false;
  static Duration activePosition = Duration.zero;
  static Duration activeDuration = const Duration(minutes: 2);
  static bool continuePlaybackOnExit = false;
  static CstCloudResourceCacheService? remoteResourceCache;

  static SoothingMusicTrackLoader? _trackLoader;
  static StreamSubscription<void>? _completionSubscription;
  static bool _advancing = false;
  static bool _notificationQueued = false;

  static void notifyChanged() {
    final scheduler = SchedulerBinding.instance;
    final phase = scheduler.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      _flushNotification();
      return;
    }
    if (_notificationQueued) {
      return;
    }
    _notificationQueued = true;
    scheduler.addPostFrameCallback((_) {
      _notificationQueued = false;
      _flushNotification();
    });
  }

  static void _flushNotification() {
    revision.value = revision.value + 1;
  }

  static void updateRemoteResourceCache(CstCloudResourceCacheService? cache) {
    if (identical(remoteResourceCache, cache) && _trackLoader != null) {
      return;
    }
    remoteResourceCache = cache;
    _trackLoader = SoothingMusicTrackLoader(remoteResourceCache: cache);
  }

  static void detachRetainedPlaybackController() {
    final subscription = _completionSubscription;
    _completionSubscription = null;
    if (subscription != null) {
      unawaited(subscription.cancel());
    }
  }

  static Future<void> attachRetainedPlaybackController(
    AudioPlayer player,
  ) async {
    detachRetainedPlaybackController();
    if (playbackMode == SoothingPlaybackMode.singleLoop) {
      await player.setReleaseMode(ReleaseMode.loop);
      notifyChanged();
      return;
    }
    await player.setReleaseMode(ReleaseMode.stop);
    _completionSubscription = player.onPlayerComplete.listen((_) {
      unawaited(_advanceRetainedPlayback(player));
    });
    notifyChanged();
  }

  static SoothingMusicTrackLoader get _resolvedTrackLoader => _trackLoader ??=
      SoothingMusicTrackLoader(remoteResourceCache: remoteResourceCache);

  static Future<void> _advanceRetainedPlayback(AudioPlayer player) async {
    if (_advancing || !activePlaying) {
      return;
    }
    _advancing = true;
    try {
      switch (playbackMode) {
        case SoothingPlaybackMode.singleLoop:
          await player.seek(Duration.zero);
          await player.resume();
          notifyChanged();
          return;
        case SoothingPlaybackMode.modeCycle:
          final modeId = activeModeId;
          if (modeId == null || modeId.trim().isEmpty) {
            await player.seek(Duration.zero);
            await player.resume();
            notifyChanged();
            return;
          }
          final tracks = SoothingMusicTrackCatalog.tracksForMode(modeId);
          if (tracks.isEmpty) {
            return;
          }
          final nextIndex = (activeTrackIndex + 1) % tracks.length;
          await _playTrack(player, modeId: modeId, trackIndex: nextIndex);
          return;
        case SoothingPlaybackMode.arrangement:
          await _advanceArrangement(player);
          return;
      }
    } finally {
      _advancing = false;
    }
  }

  static Future<void> _advanceArrangement(AudioPlayer player) async {
    if (arrangementSteps.isEmpty) {
      await player.seek(Duration.zero);
      await player.resume();
      notifyChanged();
      return;
    }
    final currentIndex = arrangementStepIndex.clamp(
      0,
      arrangementSteps.length - 1,
    );
    final currentStep = arrangementSteps[currentIndex];
    final playedCount = arrangementStepPlayCount + 1;
    if (playedCount < currentStep.repeatCount) {
      arrangementStepPlayCount = playedCount;
      await player.seek(Duration.zero);
      await player.resume();
      notifyChanged();
      return;
    }
    final nextIndex = (currentIndex + 1) % arrangementSteps.length;
    final nextStep = arrangementSteps[nextIndex];
    arrangementStepIndex = nextIndex;
    arrangementStepPlayCount = 0;
    await _playTrack(
      player,
      modeId: nextStep.modeId,
      trackIndex: nextStep.trackIndex,
    );
  }

  static Future<void> _playTrack(
    AudioPlayer player, {
    required String modeId,
    required int trackIndex,
  }) async {
    final tracks = SoothingMusicTrackCatalog.tracksForMode(modeId);
    if (tracks.isEmpty) {
      return;
    }
    final safeTrackIndex = trackIndex.clamp(0, tracks.length - 1);
    final track = tracks[safeTrackIndex];
    final bytes = await _resolvedTrackLoader.load(track);
    await player.stop();
    await AudioPlayerSourceHelper.setSource(
      player,
      BytesSource(bytes, mimeType: 'audio/mp4'),
      tag: 'soothing_audio_runtime',
      data: <String, Object?>{
        'modeId': modeId,
        'trackAssetPath': track.assetPath,
        'bytes': bytes.length,
      },
    );
    final duration = await AudioPlayerSourceHelper.waitForDuration(
      player,
      tag: 'soothing_audio_runtime',
      data: <String, Object?>{
        'modeId': modeId,
        'trackAssetPath': track.assetPath,
        'playerId': player.playerId,
      },
    );
    if (duration != null) {
      activeDuration = duration;
    }
    activeModeId = modeId;
    activeTrackIndex = safeTrackIndex;
    lastModeId = modeId;
    lastTrackIndexByMode[modeId] = safeTrackIndex;
    activePosition = Duration.zero;
    await player.setVolume(activeMuted ? 0 : activeVolume);
    await player.seek(Duration.zero);
    await player.resume();
    activePlaying = true;
    notifyChanged();
  }
}
