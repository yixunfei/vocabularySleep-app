// ignore_for_file: unused_element, unused_field

import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../i18n/app_i18n.dart';
import '../../models/play_config.dart';
import '../../services/app_log_service.dart';
import '../../services/audio_player_source_helper.dart';
import '../../services/cstcloud_resource_cache_service.dart';
import '../../services/toolbox_soothing_audio_service.dart';
import '../../services/toolbox_soothing_prefs_service.dart';
import '../../state/app_state_provider.dart';
import 'toolbox_soothing_music/playback_intent_policy.dart';
import 'toolbox_soothing_music/runtime_store.dart';
import 'toolbox_soothing_music/track_catalog.dart';
import 'toolbox_soothing_music/track_loader.dart';
import 'toolbox_soothing_music_v2_copy.dart';
import '../motion/app_motion.dart';
import '../legacy_style.dart';
import '../modal_helpers.dart';
import '../theme/app_theme.dart';
import '../ui_copy.dart';

part 'toolbox_soothing_music_v2_widgets.dart';
part 'toolbox_soothing_music_v2_models.dart';
part 'toolbox_soothing_music_v2_data.dart';
part 'toolbox_soothing_music_v2_labels.dart';
part 'toolbox_soothing_music_v2_playback.dart';
part 'toolbox_soothing_music_v2_stage.dart';
part 'toolbox_soothing_music_v2_arrangement.dart';

final AudioContext _soothingAudioContext = AudioContextConfig(
  focus: AudioContextConfigFocus.mixWithOthers,
).build();

typedef _SoothingTrack = SoothingMusicTrack;
typedef _SoothingRuntimeStore = SoothingMusicRuntimeStore;

class SoothingMusicV2Page extends ConsumerStatefulWidget {
  const SoothingMusicV2Page({super.key});

  @override
  ConsumerState<SoothingMusicV2Page> createState() =>
      _SoothingMusicV2PageState();
}

enum _ModeLibraryFilter { all, favorites, recent }

enum _SoothingPageMenuAction {
  toggleContinuePlayback,
  playbackSingleLoop,
  playbackModeCycle,
  playbackArrangement,
  editArrangement,
  toggleFullscreen,
}

class _SoothingMusicV2PageState extends ConsumerState<SoothingMusicV2Page>
    with SingleTickerProviderStateMixin {
  final AppLogService _log = AppLogService.instance;
  static const List<double> _defaultStageBands = <double>[
    0.18,
    0.22,
    0.26,
    0.24,
    0.18,
    0.14,
  ];
  static List<_SoothingTrack> _tracksForMode(String modeId) {
    return SoothingMusicTrackCatalog.tracksForMode(modeId);
  }

  late final AudioPlayer _player;
  late final AnimationController _orbitController;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<PlayerState>? _stateSubscription;
  StreamSubscription<void>? _completeSubscription;
  Timer? _sleepTimer;
  CstCloudResourceCacheService? _remoteResourceCache;
  SoothingMusicTrackLoader? _trackLoader;

  _SoothingModeTheme _mode = _modes[1];
  _ModeLibraryFilter _modeFilter = _ModeLibraryFilter.all;
  SoothingSceneAudio? _scene;
  int _trackIndex = 0;
  bool _playing = false;
  bool _playbackIntent = false;
  bool _muted = false;
  bool _loading = false;
  bool _tracksExpanded = false;
  bool _continuePlaybackOnExit = false;
  bool _fullscreen = false;
  double _volume = 0.62;
  double? _draggingRatio;
  Duration _position = Duration.zero;
  Duration _duration = const Duration(minutes: 2);
  Duration? _sleepRemaining;
  int _spectrumFrameIndex = -1;
  List<double> _stageBands = _defaultStageBands;
  String? _audioErrorLabelKey;
  String? _trackLoadLabelKey;
  double? _trackLoadProgress;
  int _trackLoadReceivedBytes = 0;
  int _trackLoadTotalBytes = 0;
  int _asyncLoadToken = 0;
  bool _handlingPlaybackCompletion = false;
  bool _disposed = false;
  Future<void> _playerMutationQueue = Future<void>.value();

  void _setViewState(VoidCallback updates) {
    if (!mounted) {
      return;
    }
    setState(updates);
  }

  Future<void> _enterImmersiveMode() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  Future<void> _exitImmersiveMode() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  Future<void> _setFullscreen(bool value) async {
    if (_fullscreen == value) {
      return;
    }
    setState(() {
      _fullscreen = value;
    });
    if (value) {
      await _enterImmersiveMode();
    } else {
      await _exitImmersiveMode();
    }
  }

  @override
  void initState() {
    super.initState();
    _player = _SoothingRuntimeStore.retainedPlayer ?? AudioPlayer();
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );
    _positionSubscription = _player.onPositionChanged.listen((value) {
      if (!mounted) return;
      setState(() {
        _position = value;
        _updateStageSpectrum();
      });
      _SoothingRuntimeStore.activePosition = value;
      _SoothingRuntimeStore.notifyChanged();
    });
    _durationSubscription = _player.onDurationChanged.listen((value) {
      if (!mounted || value.inMilliseconds <= 0) return;
      setState(() {
        _duration = value;
        _updateStageSpectrum(force: true);
      });
      _SoothingRuntimeStore.activeDuration = value;
      _SoothingRuntimeStore.notifyChanged();
    });
    _stateSubscription = _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      final nextPlaying = state == PlayerState.playing;
      if (SoothingPlaybackIntentPolicy.shouldIgnoreTransientPause(
        loading: _loading,
        playbackIntent: _playbackIntent,
        nextPlaying: nextPlaying,
      )) {
        // Ignore transient stop/pause events while switching tracks with autoplay intent.
        return;
      }
      if (_playing == nextPlaying) return;
      _setViewState(() {
        _playing = nextPlaying;
        if (nextPlaying) {
          _playbackIntent = true;
        } else if (!_loading) {
          _playbackIntent = false;
        }
      });
      _SoothingRuntimeStore.activePlaying = nextPlaying;
      _SoothingRuntimeStore.notifyChanged();
      if (nextPlaying) {
        _orbitController.repeat();
      } else {
        _orbitController.stop();
      }
    });
    _completeSubscription = _player.onPlayerComplete.listen((_) {
      unawaited(_handlePlaybackCompletion());
    });
    unawaited(_initAudio());
  }

  @override
  void dispose() {
    _disposed = true;
    _asyncLoadToken += 1;
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _stateSubscription?.cancel();
    _completeSubscription?.cancel();
    _sleepTimer?.cancel();
    _orbitController.dispose();
    if (_fullscreen) {
      unawaited(_exitImmersiveMode());
    }
    final shouldRetainPlayer = _continuePlaybackOnExit && _playbackVisualActive;
    if (shouldRetainPlayer) {
      unawaited(
        _SoothingRuntimeStore.attachRetainedPlaybackController(_player),
      );
      _SoothingRuntimeStore.retainedPlayer = _player;
      _SoothingRuntimeStore.activeModeId = _mode.id;
      _SoothingRuntimeStore.activeTrackIndex = _trackIndex;
      _SoothingRuntimeStore.activePlaying = _playbackVisualActive;
      _SoothingRuntimeStore.activeVolume = _volume;
      _SoothingRuntimeStore.activeMuted = _muted;
      _SoothingRuntimeStore.activePosition = _position;
      _SoothingRuntimeStore.activeDuration = _duration;
      _SoothingRuntimeStore.notifyChanged();
    } else {
      _SoothingRuntimeStore.detachRetainedPlaybackController();
      if (identical(_SoothingRuntimeStore.retainedPlayer, _player)) {
        _SoothingRuntimeStore.retainedPlayer = null;
      }
      _SoothingRuntimeStore.activePlaying = false;
      _SoothingRuntimeStore.notifyChanged();
      unawaited(_player.dispose());
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    CstCloudResourceCacheService? nextCache;
    try {
      nextCache = ref.read(cstCloudResourceCacheProvider);
    } on StateError {
      nextCache = null;
    }
    if (!identical(_remoteResourceCache, nextCache) || _trackLoader == null) {
      _remoteResourceCache = nextCache;
      _trackLoader = SoothingMusicTrackLoader(
        remoteResourceCache: _remoteResourceCache,
      );
      _SoothingRuntimeStore.updateRemoteResourceCache(_remoteResourceCache);
    }
  }

  double get _progressRatio {
    if (_draggingRatio != null) return _draggingRatio!;
    final durationMs = _duration.inMilliseconds;
    if (durationMs <= 0) return 0;
    return (_position.inMilliseconds / durationMs).clamp(0.0, 1.0);
  }

  bool get _playbackVisualActive => SoothingPlaybackIntentPolicy.visualActive(
    playing: _playing,
    loading: _loading,
    playbackIntent: _playbackIntent,
  );

  void _resetStageSpectrum() {
    _spectrumFrameIndex = -1;
    _stageBands = _defaultStageBands;
  }

  int _resolvedSpectrumFrameIndex() {
    final frames = _scene?.spectrumFrames;
    if (frames == null || frames.isEmpty) {
      return -1;
    }
    return (_progressRatio * (frames.length - 1)).round().clamp(
      0,
      frames.length - 1,
    );
  }

  void _updateStageSpectrum({bool force = false}) {
    final frames = _scene?.spectrumFrames;
    if (frames == null || frames.isEmpty) {
      if (force || !identical(_stageBands, _defaultStageBands)) {
        _resetStageSpectrum();
      }
      return;
    }
    final nextFrameIndex = _resolvedSpectrumFrameIndex();
    if (!force && nextFrameIndex == _spectrumFrameIndex) {
      return;
    }
    _spectrumFrameIndex = nextFrameIndex;
    _stageBands = List<double>.unmodifiable(frames[nextFrameIndex]);
  }

  List<_SoothingModeTheme> _modesForFilter(_ModeLibraryFilter filter) {
    switch (filter) {
      case _ModeLibraryFilter.all:
        return _modes;
      case _ModeLibraryFilter.favorites:
        final favoriteIds = _SoothingRuntimeStore.favoriteModeIds;
        return _modes.where((mode) => favoriteIds.contains(mode.id)).toList();
      case _ModeLibraryFilter.recent:
        return _recentModes;
    }
  }

  List<_SoothingModeTheme> get _recentModes {
    return _SoothingRuntimeStore.recentModeIds
        .map(
          (id) => _modes
              .where((mode) => mode.id == id)
              .cast<_SoothingModeTheme?>()
              .firstOrNull,
        )
        .whereType<_SoothingModeTheme>()
        .toList(growable: false);
  }

  SoothingPlaybackMode get _playbackMode => _SoothingRuntimeStore.playbackMode;
  List<SoothingPlaybackArrangementStep> get _arrangementSteps =>
      _SoothingRuntimeStore.arrangementSteps;

  int _restoredTrackIndexForMode(String modeId) {
    final tracks = _tracksForMode(modeId);
    if (tracks.isEmpty) {
      return 0;
    }
    final saved = _SoothingRuntimeStore.lastTrackIndexByMode[modeId] ?? 0;
    return saved.clamp(0, tracks.length - 1).toInt();
  }

  String _playbackModeLabel(AppI18n i18n, SoothingPlaybackMode mode) {
    return switch (mode) {
      SoothingPlaybackMode.singleLoop => pickUiText(
        i18n,
        zh: '单曲循环',
        en: 'Single loop',
      ),
      SoothingPlaybackMode.modeCycle => pickUiText(
        i18n,
        zh: '主题内顺播',
        en: 'Mode cycle',
      ),
      SoothingPlaybackMode.arrangement => pickUiText(
        i18n,
        zh: '编排播放',
        en: 'Arrangement',
      ),
    };
  }

  String _playbackModeSummary(AppI18n i18n) {
    if (_playbackMode != SoothingPlaybackMode.arrangement) {
      return _playbackModeLabel(i18n, _playbackMode);
    }
    final steps = _arrangementSteps.length;
    if (steps <= 0) {
      return pickUiText(
        i18n,
        zh: '编排播放（未配置）',
        en: 'Arrangement (not configured)',
      );
    }
    final activeTemplate = _activeArrangementTemplate;
    if (activeTemplate != null) {
      return pickUiText(
        i18n,
        zh: '编排播放 · ${activeTemplate.name}',
        en: 'Arrangement · ${activeTemplate.name}',
      );
    }
    return pickUiText(
      i18n,
      zh: '编排播放 · $steps 段',
      en: 'Arrangement · $steps steps',
    );
  }

  SoothingPlaybackArrangementTemplate? get _activeArrangementTemplate {
    final activeId = _SoothingRuntimeStore.activeArrangementTemplateId;
    if ((activeId ?? '').trim().isEmpty) {
      return null;
    }
    for (final template in _SoothingRuntimeStore.arrangementTemplates) {
      if (template.id == activeId) {
        return template;
      }
    }
    return null;
  }

  String _arrangementProgressSummary(AppI18n i18n) {
    if (_playbackMode != SoothingPlaybackMode.arrangement ||
        _arrangementSteps.isEmpty) {
      return _playbackModeSummary(i18n);
    }
    final currentIndex = _SoothingRuntimeStore.arrangementStepIndex.clamp(
      0,
      _arrangementSteps.length - 1,
    );
    final currentStep = _arrangementSteps[currentIndex];
    final currentMode = _modes.firstWhere(
      (mode) => mode.id == currentStep.modeId,
      orElse: () => _mode,
    );
    final tracks = _tracksForMode(currentMode.id);
    final safeTrackIndex = currentStep.trackIndex.clamp(0, tracks.length - 1);
    final trackLabel = SoothingMusicCopy.trackLabel(
      i18n,
      tracks[safeTrackIndex].labelKey,
    );
    final repeat = (_SoothingRuntimeStore.arrangementStepPlayCount + 1).clamp(
      1,
      currentStep.repeatCount,
    );
    return pickUiText(
      i18n,
      zh: '第 ${currentIndex + 1}/${_arrangementSteps.length} 段 · ${currentMode.title(i18n)} · $trackLabel · $repeat/${currentStep.repeatCount} 次',
      en: 'Step ${currentIndex + 1}/${_arrangementSteps.length} · ${currentMode.title(i18n)} · $trackLabel · $repeat/${currentStep.repeatCount}',
    );
  }

  void _setPlaybackMode(SoothingPlaybackMode mode) {
    if (_playbackMode == mode) {
      return;
    }
    if (mode == SoothingPlaybackMode.arrangement && _arrangementSteps.isEmpty) {
      _SoothingRuntimeStore.arrangementSteps =
          <SoothingPlaybackArrangementStep>[
            SoothingPlaybackArrangementStep(
              modeId: _mode.id,
              trackIndex: _trackIndex,
              repeatCount: 1,
            ),
          ];
      _SoothingRuntimeStore.arrangementStepIndex = 0;
      _SoothingRuntimeStore.arrangementStepPlayCount = 0;
      _SoothingRuntimeStore.activeArrangementTemplateId = null;
    }
    setState(() {
      _SoothingRuntimeStore.playbackMode = mode;
    });
    _SoothingRuntimeStore.notifyChanged();
    unawaited(_persistPrefs());
  }

  Future<void> _seekToRatio(double ratio) async {
    final durationMs = _duration.inMilliseconds;
    if (durationMs <= 0) return;
    final nextPosition = Duration(milliseconds: (durationMs * ratio).round());
    await _player.seek(nextPosition);
    if (!mounted) return;
    setState(() {
      _position = nextPosition;
      _updateStageSpectrum(force: true);
    });
  }

  Future<void> _persistPrefs() {
    return ToolboxSoothingPrefsService.save(
      SoothingPrefsState(
        favoriteModeIds: _SoothingRuntimeStore.favoriteModeIds,
        recentModeIds: _SoothingRuntimeStore.recentModeIds,
        lastTrackIndexByMode: _SoothingRuntimeStore.lastTrackIndexByMode,
        lastModeId: _SoothingRuntimeStore.lastModeId,
        continuePlaybackOnExit: _continuePlaybackOnExit,
        playbackMode: _SoothingRuntimeStore.playbackMode,
        arrangementSteps: _SoothingRuntimeStore.arrangementSteps,
        arrangementTemplates: _SoothingRuntimeStore.arrangementTemplates,
        activeArrangementTemplateId:
            _SoothingRuntimeStore.activeArrangementTemplateId,
      ),
    );
  }

  void _clearAudioError() {
    _audioErrorLabelKey = null;
  }

  void _clearTrackLoadState({int? loadToken}) {
    if (!_isLoadTokenActive(loadToken)) {
      return;
    }
    if (!mounted) {
      _trackLoadLabelKey = null;
      _trackLoadProgress = null;
      _trackLoadReceivedBytes = 0;
      _trackLoadTotalBytes = 0;
      return;
    }
    setState(() {
      _trackLoadLabelKey = null;
      _trackLoadProgress = null;
      _trackLoadReceivedBytes = 0;
      _trackLoadTotalBytes = 0;
    });
  }

  String _format(Duration value) {
    final minutes = value.inMinutes.toString();
    final seconds = (value.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = <String>['B', 'KB', 'MB', 'GB'];
    var value = bytes.toDouble();
    var unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex += 1;
    }
    final digits = value >= 10 || unitIndex == 0 ? 0 : 1;
    return '${value.toStringAsFixed(digits)} ${units[unitIndex]}';
  }

  String? _audioErrorText(AppI18n i18n) {
    final key = _audioErrorLabelKey;
    if (key == null || key.isEmpty) return null;
    final label = key.startsWith('mode:')
        ? SoothingMusicCopy.modeTitle(i18n, key.substring(5))
        : key.startsWith('track:')
        ? SoothingMusicCopy.trackLabel(i18n, key.substring(6))
        : key;
    return SoothingMusicCopy.text(
      i18n,
      'track.audio_error',
      params: <String, Object?>{'label': label},
    );
  }

  String? _trackLoadText(AppI18n i18n) {
    final labelKey = _trackLoadLabelKey;
    if (!_loading || labelKey == null || labelKey.isEmpty) {
      return null;
    }
    final label = SoothingMusicCopy.trackLabel(i18n, labelKey);
    final progress = _trackLoadProgress;
    final bytesText = _trackLoadTotalBytes > 0
        ? '${_formatBytes(_trackLoadReceivedBytes)} / ${_formatBytes(_trackLoadTotalBytes)}'
        : _trackLoadReceivedBytes > 0
        ? _formatBytes(_trackLoadReceivedBytes)
        : null;
    if (progress == null) {
      return bytesText == null ? label : '$label · $bytesText';
    }
    final percent = (progress * 100).round();
    return bytesText == null
        ? '$label · $percent%'
        : '$label · $percent% · $bytesText';
  }

  void _startSleepTimer(Duration? value) {
    _sleepTimer?.cancel();
    setState(() {
      _sleepRemaining = value;
    });
    if (value == null) return;

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final remaining = _sleepRemaining;
      if (remaining == null) {
        timer.cancel();
        return;
      }
      if (remaining <= const Duration(seconds: 1)) {
        timer.cancel();
        await _player.pause();
        _SoothingRuntimeStore.activePlaying = false;
        _SoothingRuntimeStore.notifyChanged();
        if (!mounted) return;
        setState(() {
          _sleepRemaining = null;
        });
        return;
      }
      if (!mounted) return;
      setState(() {
        _sleepRemaining = remaining - const Duration(seconds: 1);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final isDark = AppThemeTokens.of(context).isDark;
    final appearance = LegacyStyle.appearance;
    final palette = _SoothingVisualPalette.resolve(
      isDark: isDark,
      appearance: appearance,
      mode: _mode,
    );
    final baseEffectBoost =
        (_fullscreen ? 1.22 : 0.82) +
        appearance.normalizedEffectIntensity * (_fullscreen ? 1.46 : 1.1);
    final baseWaveBoost =
        (_fullscreen ? 1.08 : 0.76) +
        appearance.normalizedGradientIntensity * (_fullscreen ? 1.18 : 0.9);

    final controls = <Widget>[
      IconButton(
        tooltip: _copySleepTimerButtonLabel(i18n),
        onPressed: () => _showSleepTimerSheet(context, i18n),
        icon: Icon(
          Icons.timer_outlined,
          color: _fullscreen ? Colors.white : const Color(0xFF10263A),
        ),
      ),
      PopupMenuButton<_SoothingPageMenuAction>(
        tooltip: pickUiText(i18n, zh: '播放设置', en: 'Playback settings'),
        icon: Icon(
          Icons.more_vert_rounded,
          color: _fullscreen ? Colors.white : const Color(0xFF10263A),
        ),
        onSelected: (value) {
          switch (value) {
            case _SoothingPageMenuAction.toggleContinuePlayback:
              setState(() {
                _continuePlaybackOnExit = !_continuePlaybackOnExit;
                _SoothingRuntimeStore.continuePlaybackOnExit =
                    _continuePlaybackOnExit;
              });
              _SoothingRuntimeStore.notifyChanged();
              unawaited(_persistPrefs());
              return;
            case _SoothingPageMenuAction.playbackSingleLoop:
              _setPlaybackMode(SoothingPlaybackMode.singleLoop);
              return;
            case _SoothingPageMenuAction.playbackModeCycle:
              _setPlaybackMode(SoothingPlaybackMode.modeCycle);
              return;
            case _SoothingPageMenuAction.playbackArrangement:
              _setPlaybackMode(SoothingPlaybackMode.arrangement);
              return;
            case _SoothingPageMenuAction.editArrangement:
              unawaited(_showArrangementSheet(context, i18n));
              return;
            case _SoothingPageMenuAction.toggleFullscreen:
              unawaited(_setFullscreen(!_fullscreen));
              return;
          }
        },
        itemBuilder: (context) => <PopupMenuEntry<_SoothingPageMenuAction>>[
          CheckedPopupMenuItem<_SoothingPageMenuAction>(
            value: _SoothingPageMenuAction.playbackSingleLoop,
            checked: _playbackMode == SoothingPlaybackMode.singleLoop,
            child: Text(pickUiText(i18n, zh: '单曲循环', en: 'Single loop')),
          ),
          CheckedPopupMenuItem<_SoothingPageMenuAction>(
            value: _SoothingPageMenuAction.playbackModeCycle,
            checked: _playbackMode == SoothingPlaybackMode.modeCycle,
            child: Text(pickUiText(i18n, zh: '主题内顺播', en: 'Mode cycle')),
          ),
          CheckedPopupMenuItem<_SoothingPageMenuAction>(
            value: _SoothingPageMenuAction.playbackArrangement,
            checked: _playbackMode == SoothingPlaybackMode.arrangement,
            child: Text(pickUiText(i18n, zh: '编排播放', en: 'Arrangement')),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<_SoothingPageMenuAction>(
            value: _SoothingPageMenuAction.editArrangement,
            child: Text(pickUiText(i18n, zh: '编辑编排', en: 'Edit arrangement')),
          ),
          PopupMenuItem<_SoothingPageMenuAction>(
            value: _SoothingPageMenuAction.toggleFullscreen,
            child: Text(
              pickUiText(
                i18n,
                zh: _fullscreen ? '退出全屏' : '进入全屏',
                en: _fullscreen ? 'Exit fullscreen' : 'Enter fullscreen',
              ),
            ),
          ),
          const PopupMenuDivider(),
          CheckedPopupMenuItem<_SoothingPageMenuAction>(
            value: _SoothingPageMenuAction.toggleContinuePlayback,
            checked: _continuePlaybackOnExit,
            child: Text(SoothingMusicCopy.text(i18n, 'setting.keep_playing')),
          ),
        ],
      ),
    ];

    return Scaffold(
      backgroundColor: palette.backgroundBottom,
      extendBodyBehindAppBar: _fullscreen,
      appBar: _fullscreen
          ? AppBar(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              shadowColor: Colors.transparent,
              title: Text(
                _copyPageTitle(i18n),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              actions: controls,
            )
          : AppBar(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF10263A),
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              shadowColor: Colors.transparent,
              flexibleSpace: const DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFE4EBF0))),
                ),
              ),
              title: Text(
                _copyPageTitle(i18n),
                style: const TextStyle(
                  color: Color(0xFF10263A),
                  fontWeight: FontWeight.w800,
                ),
              ),
              actions: controls,
            ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 980;
          final compactLayout = !wide;
          final compactEffectBoost = compactLayout
              ? (constraints.maxWidth < 430 ? 1.42 : 1.24)
              : 1.0;
          final compactWaveBoost = compactLayout
              ? (constraints.maxWidth < 430 ? 1.36 : 1.18)
              : 1.0;
          final effectBoost = (baseEffectBoost * compactEffectBoost)
              .clamp(0.86, 3.2)
              .toDouble();
          final waveBoost = (baseWaveBoost * compactWaveBoost)
              .clamp(0.8, 3.0)
              .toDouble();
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  palette.backgroundTop,
                  palette.backgroundBottom,
                ],
              ),
            ),
            child: SafeArea(
              top: false,
              child: wide
                  ? Row(
                      children: <Widget>[
                        SizedBox(
                          width: 332,
                          child: _buildModePanel(
                            context,
                            i18n,
                            palette: palette,
                          ),
                        ),
                        Expanded(
                          child: _buildStageArea(
                            context,
                            i18n,
                            palette: palette,
                            compact: false,
                            effectBoost: effectBoost,
                            waveBoost: waveBoost,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: <Widget>[
                        _buildCompactHeader(context, i18n, palette: palette),
                        Expanded(
                          child: _buildStageArea(
                            context,
                            i18n,
                            palette: palette,
                            compact: true,
                            effectBoost: effectBoost,
                            waveBoost: waveBoost,
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompactHeader(
    BuildContext context,
    AppI18n i18n, {
    required _SoothingVisualPalette palette,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: palette.panelSurface,
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _copyModesButtonLabel(i18n),
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: PopupMenuButton<_SoothingModeTheme>(
                  tooltip: _copyModesButtonLabel(i18n),
                  onSelected: (mode) => unawaited(_setMode(mode)),
                  itemBuilder: (context) => _modes
                      .map(
                        (mode) => PopupMenuItem<_SoothingModeTheme>(
                          value: mode,
                          child: Row(
                            children: <Widget>[
                              Icon(
                                mode.icon,
                                size: 18,
                                color: _mode.id == mode.id
                                    ? palette.accent
                                    : palette.textSecondary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  mode.title(i18n),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_mode.id == mode.id)
                                Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color: palette.accent,
                                ),
                            ],
                          ),
                        ),
                      )
                      .toList(growable: false),
                  child: _CompactCurrentModeCard(
                    title: _mode.title(i18n),
                    subtitle: _mode.subtitle(i18n),
                    accent: palette.accent,
                    icon: _mode.icon,
                    isFavorite: _SoothingRuntimeStore.favoriteModeIds.contains(
                      _mode.id,
                    ),
                    onToggleFavorite: () => _toggleFavorite(_mode.id),
                    palette: palette,
                    dropdownEnabled: true,
                    showFavoriteButton: false,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: palette.panelSurfaceMuted,
                  shape: BoxShape.circle,
                  border: Border.all(color: palette.border),
                ),
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _toggleFavorite(_mode.id),
                  icon: Icon(
                    _SoothingRuntimeStore.favoriteModeIds.contains(_mode.id)
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 18,
                    color:
                        _SoothingRuntimeStore.favoriteModeIds.contains(_mode.id)
                        ? palette.accent
                        : palette.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          if (_sleepRemaining != null) ...<Widget>[
            const SizedBox(height: 10),
            _InfoPill(
              icon: Icons.timer_outlined,
              label: _copyActiveSleepTimerLabel(i18n, _sleepRemaining!),
              palette: palette,
              accent: palette.accent,
            ),
          ],
          const SizedBox(height: 10),
          _InfoPill(
            icon: Icons.repeat_rounded,
            label: _playbackModeSummary(i18n),
            palette: palette,
            accent: palette.orbitAccent,
          ),
          if (_playbackMode == SoothingPlaybackMode.arrangement) ...<Widget>[
            const SizedBox(height: 8),
            _InfoPill(
              icon: Icons.playlist_play_rounded,
              label: _arrangementProgressSummary(i18n),
              palette: palette,
              accent: palette.accent,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModePanel(
    BuildContext context,
    AppI18n i18n, {
    required _SoothingVisualPalette palette,
  }) {
    final visibleModes = _modesForFilter(_modeFilter);

    return Container(
      decoration: BoxDecoration(
        color: palette.panelSurface,
        border: Border(right: BorderSide(color: palette.border)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _copyPageTitle(i18n),
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _copyPageSubtitle(i18n),
            style: TextStyle(color: palette.textSecondary, height: 1.45),
          ),
          const SizedBox(height: 16),
          _buildModeFilterBar(
            i18n,
            palette: palette,
            filter: _modeFilter,
            onChanged: (value) {
              setState(() {
                _modeFilter = value;
              });
            },
          ),
          if (_sleepRemaining != null) ...<Widget>[
            const SizedBox(height: 12),
            _InfoPill(
              icon: Icons.timer_outlined,
              label: _copyActiveSleepTimerLabel(i18n, _sleepRemaining!),
              palette: palette,
              accent: palette.accent,
            ),
          ],
          const SizedBox(height: 12),
          _InfoPill(
            icon: Icons.repeat_rounded,
            label: _playbackModeSummary(i18n),
            palette: palette,
            accent: palette.orbitAccent,
          ),
          if (_playbackMode == SoothingPlaybackMode.arrangement) ...<Widget>[
            const SizedBox(height: 8),
            _InfoPill(
              icon: Icons.playlist_play_rounded,
              label: _arrangementProgressSummary(i18n),
              palette: palette,
              accent: palette.accent,
            ),
          ],
          const SizedBox(height: 14),
          Expanded(
            child: visibleModes.isEmpty
                ? _buildEmptyModeState(
                    i18n,
                    palette: palette,
                    filter: _modeFilter,
                    onReset: () {
                      setState(() {
                        _modeFilter = _ModeLibraryFilter.all;
                      });
                    },
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        for (
                          var index = 0;
                          index < visibleModes.length;
                          index += 1
                        )
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: index == visibleModes.length - 1 ? 0 : 10,
                            ),
                            child: _buildModeTile(
                              visibleModes[index],
                              i18n,
                              palette: palette,
                              compact: false,
                              onTap: () => _setMode(visibleModes[index]),
                              onFavoriteTap: () =>
                                  _toggleFavorite(visibleModes[index].id),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyModeState(
    AppI18n i18n, {
    required _SoothingVisualPalette palette,
    required _ModeLibraryFilter filter,
    required VoidCallback onReset,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: palette.panelSurfaceMuted,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            filter == _ModeLibraryFilter.favorites
                ? Icons.favorite_outline_rounded
                : Icons.history_toggle_off_rounded,
            size: 34,
            color: palette.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            _copyEmptyModeTitle(i18n, filter),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _copyEmptyModeSubtitle(i18n, filter),
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onReset,
            child: Text(_copyShowAllModesLabel(i18n)),
          ),
        ],
      ),
    );
  }

  Widget _buildModeFilterBar(
    AppI18n i18n, {
    required _SoothingVisualPalette palette,
    required _ModeLibraryFilter filter,
    required ValueChanged<_ModeLibraryFilter> onChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _ModeLibraryFilter.values
          .map(
            (value) => _ModeFilterChip(
              label: _copyModeFilterLabel(i18n, value),
              selected: filter == value,
              palette: palette,
              onTap: () => onChanged(value),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildModeTile(
    _SoothingModeTheme mode,
    AppI18n i18n, {
    required _SoothingVisualPalette palette,
    required bool compact,
    required VoidCallback onTap,
    required VoidCallback onFavoriteTap,
  }) {
    final selected = _mode.id == mode.id;
    final favorite = _SoothingRuntimeStore.favoriteModeIds.contains(mode.id);
    final tileAccent = Color.lerp(palette.accent, mode.accent, 0.66)!;
    final trackCount = _tracksForMode(mode.id).length;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? Color.lerp(palette.panelSurfaceMuted, tileAccent, 0.12)!
                : palette.panelSurfaceMuted,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? tileAccent.withValues(alpha: 0.84)
                  : palette.border.withValues(alpha: 0.95),
              width: selected ? 1.4 : 1,
            ),
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: tileAccent.withValues(
                        alpha: palette.isDark ? 0.2 : 0.12,
                      ),
                      blurRadius: 24,
                      spreadRadius: 1,
                    ),
                  ]
                : const <BoxShadow>[],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tileAccent.withValues(alpha: selected ? 0.18 : 0.1),
                  border: Border.all(
                    color: tileAccent.withValues(alpha: selected ? 0.58 : 0.24),
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(mode.icon, color: tileAccent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            mode.title(i18n),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: palette.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (selected)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: tileAccent.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: tileAccent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _copyActiveModeLabel(i18n),
                                  style: TextStyle(
                                    color: tileAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mode.subtitle(i18n),
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _InfoPill(
                      icon: Icons.library_music_rounded,
                      label: _copyTrackCountLabel(i18n, trackCount),
                      palette: palette,
                      dense: true,
                      accent: tileAccent,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: _copyFavoriteToggleLabel(i18n),
                visualDensity: VisualDensity.compact,
                onPressed: onFavoriteTap,
                icon: Icon(
                  favorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 20,
                  color: favorite ? tileAccent : palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSleepTimerSheet(BuildContext context, AppI18n i18n) async {
    final values = <Duration?>[
      null,
      const Duration(minutes: 10),
      const Duration(minutes: 20),
      const Duration(minutes: 30),
      const Duration(minutes: 45),
      const Duration(minutes: 60),
    ];
    final selection = await showModalBottomSheet<Duration?>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            children: values
                .map((value) {
                  final label = _copySleepTimerOptionLabel(i18n, value);
                  final selected = value == null
                      ? _sleepRemaining == null
                      : _sleepRemaining?.inMinutes == value.inMinutes;
                  return ListTile(
                    title: Text(label),
                    trailing: selected ? const Icon(Icons.check_rounded) : null,
                    onTap: () => Navigator.of(context).pop(value),
                  );
                })
                .toList(growable: false),
          ),
        );
      },
    );
    if (!mounted) return;
    _startSleepTimer(selection);
  }

  Future<void> _showModeSheet(
    BuildContext context,
    AppI18n i18n, {
    required _SoothingVisualPalette palette,
  }) async {
    var sheetFilter = _modeFilter;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final visibleModes = _modesForFilter(sheetFilter);
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.84,
              minChildSize: 0.54,
              maxChildSize: 0.94,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _copyBrowseModesTitle(i18n),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _copyBrowseModesSubtitle(i18n),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 14),
                      _buildModeFilterBar(
                        i18n,
                        palette: palette,
                        filter: sheetFilter,
                        onChanged: (value) {
                          setState(() {
                            _modeFilter = value;
                          });
                          setModalState(() {
                            sheetFilter = value;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: visibleModes.isEmpty
                            ? _buildEmptyModeState(
                                i18n,
                                palette: palette,
                                filter: sheetFilter,
                                onReset: () {
                                  setState(() {
                                    _modeFilter = _ModeLibraryFilter.all;
                                  });
                                  setModalState(() {
                                    sheetFilter = _ModeLibraryFilter.all;
                                  });
                                },
                              )
                            : ListView.separated(
                                controller: scrollController,
                                itemCount: visibleModes.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final mode = visibleModes[index];
                                  return _buildModeTile(
                                    mode,
                                    i18n,
                                    palette: palette,
                                    compact: false,
                                    onTap: () {
                                      Navigator.of(sheetContext).pop();
                                      unawaited(_setMode(mode));
                                    },
                                    onFavoriteTap: () {
                                      _toggleFavorite(mode.id);
                                      setModalState(() {});
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
