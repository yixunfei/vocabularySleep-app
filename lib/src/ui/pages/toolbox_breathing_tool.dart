import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../services/audio_player_source_helper.dart';
import '../../services/cstcloud_resource_cache_service.dart';
import '../../services/toolbox_breathing_audio_repository.dart';
import '../../services/toolbox_breathing_catalog.dart';
import '../../services/toolbox_breathing_prefs_service.dart';
import '../ui_copy.dart';
import '../widgets/section_header.dart';
import 'toolbox_breathing_ui_parts.dart';
import 'toolbox_tool_shell.dart';

enum _BreathingVoiceAvailability { off, checking, ready, unavailable }

class _BreathingSessionSummary {
  const _BreathingSessionSummary({
    required this.title,
    required this.body,
    required this.nextStep,
  });

  final String title;
  final String body;
  final String nextStep;
}

class _BoltAssessment {
  const _BoltAssessment({
    required this.label,
    required this.body,
    required this.nextStep,
    required this.recommendedScenarioIds,
    required this.tint,
    required this.altitudeReady,
  });

  final String label;
  final String body;
  final String nextStep;
  final List<String> recommendedScenarioIds;
  final Color tint;
  final bool altitudeReady;
}

class BreathingPracticeReleaseCard extends StatefulWidget {
  const BreathingPracticeReleaseCard({super.key});

  @override
  State<BreathingPracticeReleaseCard> createState() =>
      _BreathingPracticeReleaseCardState();
}

class _BreathingPracticeReleaseCardState
    extends State<BreathingPracticeReleaseCard>
    with SingleTickerProviderStateMixin {
  static const List<int> _targetOptions = <int>[2, 3, 4, 5, 8, 10, 12, 15];
  static const String _altitudeScenarioId = 'altitude_sim_3663';

  late final AnimationController _controller;
  late final StreamSubscription<void> _previewCompleteSub;
  final AudioPlayer _cuePlayer = AudioPlayer();
  final AudioPlayer _previewPlayer = AudioPlayer();
  final AudioPlayer _systemPlayer = AudioPlayer();
  final Stopwatch _boltStopwatch = Stopwatch();
  Timer? _clock;
  Timer? _boltClock;

  CstCloudResourceCacheService? _resourceCache;
  ToolboxBreathingAudioRepository? _cueRepo;
  late BreathingScenario _scenario;
  late BreathingThemeSpec _theme;

  bool _includeHoldStage = true;
  bool _voiceOn = true;
  bool _textOn = true;
  bool _hapticOn = true;
  bool _includeRecoveryStage = false;
  bool _running = false;
  bool _previewing = false;
  bool _finishing = false;
  bool _boltRunning = false;
  bool _boltPreparing = false;
  bool _boltExpanded = false;
  bool _sessionPreparing = false;
  int _targetMinutes = 5;
  int _stageIndex = 0;
  int _rounds = 0;
  int _completedSessions = 0;
  int _totalSeconds = 0;
  int _availableCueCount = 0;
  int _expectedCueCount = 0;
  int _shortStageSilentCount = 0;
  int _lastBoltSeconds = 0;
  int _bestBoltSeconds = 0;
  Duration _elapsedBeforeRun = Duration.zero;
  DateTime? _runStartedAt;
  _BreathingVoiceAvailability _voiceAvailability =
      _BreathingVoiceAvailability.checking;
  BreathingCueSourceKind? _voiceSourceKind;
  String? _lastVoiceLocation;
  _BreathingSessionSummary? _lastSummary;
  bool _voiceLocaleNoticeShown = false;
  bool _voiceLocaleDialogOpen = false;
  int _systemCueSequenceToken = 0;

  List<BreathingStagePlan> get _loopStages {
    final filtered = _scenario.stages
        .where((stage) {
          if (!_includeHoldStage && stage.kind == BreathingStageKind.hold) {
            return false;
          }
          if (!_includeRecoveryStage && stage.kind == BreathingStageKind.rest) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
    return filtered.isEmpty ? _scenario.stages : filtered;
  }

  int get _loopCycleSeconds =>
      _loopStages.fold<int>(0, (sum, stage) => sum + stage.seconds);

  BreathingStagePlan get _stage => _loopStages[_stageIndex];
  BreathingStagePlan get _nextStage =>
      _loopStages[(_stageIndex + 1) % _loopStages.length];

  Duration get _elapsed {
    if (!_running || _runStartedAt == null) {
      return _elapsedBeforeRun;
    }
    return _elapsedBeforeRun + DateTime.now().difference(_runStartedAt!);
  }

  Duration get _targetDuration => Duration(minutes: _targetMinutes);

  double get _targetProgress {
    final total = _targetDuration.inMilliseconds;
    if (total <= 0) {
      return 0;
    }
    return (_elapsed.inMilliseconds / total).clamp(0.0, 1.0).toDouble();
  }

  void _normalizeStageIndex() {
    final length = _loopStages.length;
    if (length <= 0) {
      _stageIndex = 0;
      return;
    }
    if (_stageIndex < 0 || _stageIndex >= length) {
      _stageIndex = 0;
    }
  }

  @override
  void initState() {
    super.initState();
    _scenario = BreathingExperienceCatalog.scenarios.first;
    _theme = BreathingExperienceCatalog.themeById(_scenario.themeId);
    _controller = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && _running) {
          _onStageDone();
        }
      });
    _previewCompleteSub = _previewPlayer.onPlayerComplete.listen((_) {
      if (mounted && _previewing) {
        setState(() => _previewing = false);
      }
    });
    _syncDuration();
    unawaited(_loadPrefs());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    CstCloudResourceCacheService? nextCache;
    try {
      nextCache = Provider.of<CstCloudResourceCacheService>(
        context,
        listen: false,
      );
    } on ProviderNotFoundException {
      nextCache = null;
    }
    nextCache ??= _resourceCache ?? CstCloudResourceCacheService();
    if (!identical(_resourceCache, nextCache) || _cueRepo == null) {
      _resourceCache = nextCache;
      _cueRepo = ToolboxBreathingAudioRepository(nextCache);
      if (_voiceOn) {
        unawaited(_maybeShowNonChineseVoiceNotice());
        unawaited(_warmScenarioCues());
      }
    }
  }

  @override
  void dispose() {
    _clock?.cancel();
    _boltClock?.cancel();
    unawaited(_previewCompleteSub.cancel());
    unawaited(_cuePlayer.dispose());
    unawaited(_previewPlayer.dispose());
    unawaited(_systemPlayer.dispose());
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await ToolboxBreathingPrefsService.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _scenario = BreathingExperienceCatalog.scenarioById(prefs.presetId);
      _theme = BreathingExperienceCatalog.themeById(prefs.themeId);
      _targetMinutes = prefs.targetMinutes;
      _includeHoldStage = prefs.breathHoldEnabled;
      _includeRecoveryStage = prefs.includeRecoveryStage;
      _voiceOn = prefs.voiceGuidanceEnabled;
      _textOn = prefs.textGuidanceEnabled;
      _hapticOn = prefs.hapticsEnabled;
      _completedSessions = prefs.completedSessions;
      _totalSeconds = prefs.totalPracticeSeconds;
      _lastBoltSeconds = prefs.lastBoltSeconds;
      _bestBoltSeconds = prefs.bestBoltSeconds;
      _voiceAvailability = _voiceOn
          ? _BreathingVoiceAvailability.checking
          : _BreathingVoiceAvailability.off;
      _voiceSourceKind = null;
      _lastVoiceLocation = null;
    });
    _normalizeStageIndex();
    _syncDuration();
    if (_voiceOn) {
      unawaited(_maybeShowNonChineseVoiceNotice());
      unawaited(_warmScenarioCues());
    }
  }

  void _savePrefs() {
    unawaited(
      ToolboxBreathingPrefsService.save(
        BreathingPracticePrefsState(
          presetId: _scenario.id,
          themeId: _theme.id,
          targetMinutes: _targetMinutes,
          breathHoldEnabled: _includeHoldStage,
          includeRecoveryStage: _includeRecoveryStage,
          voiceGuidanceEnabled: _voiceOn,
          textGuidanceEnabled: _textOn,
          hapticsEnabled: _hapticOn,
          completedSessions: _completedSessions,
          totalPracticeSeconds: _totalSeconds,
          lastBoltSeconds: _lastBoltSeconds,
          bestBoltSeconds: _bestBoltSeconds,
        ),
      ),
    );
  }

  void _syncDuration() {
    _controller.duration = Duration(seconds: _stage.seconds);
  }

  List<String> _localeTags(Locale locale) {
    final language = locale.languageCode.trim().toLowerCase();
    final country = (locale.countryCode ?? '').trim().toLowerCase();
    final tags = <String>{};
    if (language.isNotEmpty && country.isNotEmpty) {
      tags.add('$language-$country');
      tags.add('${language}_$country');
    }
    if (language.isNotEmpty) {
      tags.add(language);
    }
    if (language == 'zh') {
      tags.add('zh-cn');
      tags.add('zh_cn');
    }
    tags.add('default');
    return tags.toList(growable: false);
  }

  bool _localeUsesChineseVoice(Locale locale) {
    return locale.languageCode.trim().toLowerCase() == 'zh';
  }

  Future<void> _maybeShowNonChineseVoiceNotice() async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted ||
        !_voiceOn ||
        _voiceLocaleDialogOpen ||
        _voiceLocaleNoticeShown) {
      return;
    }
    final locale = Localizations.maybeLocaleOf(context);
    if (locale == null || _localeUsesChineseVoice(locale)) {
      return;
    }
    final i18n = AppI18n(locale.languageCode);
    _voiceLocaleDialogOpen = true;
    final keepVoice = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            pickUiText(
              i18n,
              zh: '当前语音仅支持中文',
              en: 'Voice is Chinese-only for now',
            ),
          ),
          content: Text(
            pickUiText(
              i18n,
              zh: '呼吸阶段语音目前只提供中文录音。你仍可继续使用当前界面语言的文案与计时，但语音会播放中文引导。',
              en: 'Breathing voice guidance is currently recorded in Chinese only. The interface can stay in your current language, but spoken cues will play in Chinese.',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(pickUiText(i18n, zh: '关闭语音', en: 'Turn voice off')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                pickUiText(i18n, zh: '继续使用中文语音', en: 'Keep Chinese voice'),
              ),
            ),
          ],
        );
      },
    );
    _voiceLocaleDialogOpen = false;
    if (!mounted) {
      return;
    }
    setState(() => _voiceLocaleNoticeShown = true);
    if (keepVoice == false) {
      await _setVoiceEnabled(false, showLocaleNotice: false);
    }
  }

  String? _effectiveCueIdForStage(BreathingStagePlan stage) {
    if (stage.kind == BreathingStageKind.rest) {
      return null;
    }
    if (stage.kind == BreathingStageKind.hold && !_includeHoldStage) {
      return null;
    }
    if (stage.seconds <= 2) {
      return switch (stage.kind) {
        BreathingStageKind.inhale => 'inhale_soft',
        BreathingStageKind.exhale => 'exhale_soft',
        BreathingStageKind.hold => 'hold_soft',
        BreathingStageKind.rest => null,
      };
    }
    return stage.cueId;
  }

  int _scenarioStageIndex(BreathingStagePlan stage) {
    final originalIndex = _scenario.stages.indexOf(stage);
    if (originalIndex >= 0) {
      return originalIndex;
    }
    return _stageIndex;
  }

  Duration _cueSafetyPaddingForStage(BreathingStagePlan stage) {
    if (stage.seconds <= 2) {
      return Duration.zero;
    }
    if (stage.seconds <= 4) {
      return const Duration(milliseconds: 80);
    }
    return const Duration(milliseconds: 180);
  }

  Duration? _resolvedCueDuration(BreathingResolvedCue resolved) {
    return resolved.duration ??
        (resolved.cue.approxDurationMs > 0
            ? Duration(milliseconds: resolved.cue.approxDurationMs)
            : null);
  }

  double _cuePlaybackRateForStage(
    BreathingStagePlan stage,
    BreathingResolvedCue resolved,
  ) {
    final cueDuration = _resolvedCueDuration(resolved);
    if (cueDuration == null || cueDuration <= Duration.zero) {
      return 1.0;
    }
    final paddingMs = _cueSafetyPaddingForStage(stage).inMilliseconds;
    final targetWindowMs = math.max(240, stage.seconds * 1000 - paddingMs);
    return (cueDuration.inMilliseconds / targetWindowMs)
        .clamp(1.0, 2.0)
        .toDouble();
  }

  bool _canPlayResolvedCueForStage(
    BreathingStagePlan stage,
    BreathingResolvedCue resolved,
  ) {
    final cueDuration = _resolvedCueDuration(resolved);
    if (cueDuration == null) {
      return false;
    }
    final playbackRate = _cuePlaybackRateForStage(stage, resolved);
    final adjustedDurationMs =
        cueDuration.inMilliseconds / playbackRate.clamp(0.75, 2.0);
    return stage.seconds * 1000 >=
        adjustedDurationMs.round() +
            _cueSafetyPaddingForStage(stage).inMilliseconds;
  }

  Future<BreathingResolvedCue?> _resolveStageCueForStage(
    BreathingStagePlan stage,
  ) async {
    final cueId = _effectiveCueIdForStage(stage);
    if (cueId == null) {
      return null;
    }
    final repo = _cueRepo;
    if (repo == null || !mounted) {
      return null;
    }
    return repo.resolveScenarioStage(
      _scenario.id,
      stageIndex: _scenarioStageIndex(stage),
      stageKind: stage.kind,
      fallbackCueId: cueId,
      languageTags: _localeTags(Localizations.localeOf(context)),
    );
  }

  Future<void> _warmScenarioCues() async {
    if (!mounted || !_voiceOn) {
      if (mounted) {
        setState(() => _voiceAvailability = _BreathingVoiceAvailability.off);
      }
      return;
    }
    final repo = _cueRepo;
    if (repo == null) {
      return;
    }
    final localeTags = _localeTags(Localizations.localeOf(context));
    final scenarioId = _scenario.id;
    final includeRecoveryStage = _includeRecoveryStage;
    final includeHoldStage = _includeHoldStage;
    const flowCueIds = <String>[
      'session_start',
      'session_complete',
      'bolt_prepare',
      'bolt_start',
      'bolt_stop',
      'bolt_recover',
    ];
    final expectedCueCount =
        _loopStages
            .where((stage) => _effectiveCueIdForStage(stage) != null)
            .length +
        (_scenario.previewCueId == null ? 0 : 1);
    setState(() {
      _voiceAvailability = _BreathingVoiceAvailability.checking;
      _expectedCueCount = expectedCueCount;
      _shortStageSilentCount = 0;
    });
    final resolved = <BreathingResolvedCue>[];
    var silentShortCueCount = 0;
    final previewCueId = _scenario.previewCueId;
    if (previewCueId != null) {
      final preview = await repo.resolve(
        previewCueId,
        languageTags: localeTags,
      );
      if (preview != null) {
        resolved.add(preview);
      }
    }
    for (final stage in _loopStages) {
      final stageCue = await _resolveStageCueForStage(stage);
      if (stageCue == null) {
        continue;
      }
      if (_canPlayResolvedCueForStage(stage, stageCue)) {
        resolved.add(stageCue);
      } else {
        silentShortCueCount += 1;
      }
    }
    await repo.warmUpCueIds(flowCueIds, languageTags: localeTags);
    if (!mounted ||
        !_voiceOn ||
        _scenario.id != scenarioId ||
        _includeRecoveryStage != includeRecoveryStage ||
        _includeHoldStage != includeHoldStage) {
      return;
    }
    setState(() {
      _availableCueCount = resolved.length;
      _expectedCueCount = expectedCueCount;
      _shortStageSilentCount = silentShortCueCount;
      _voiceAvailability = resolved.isNotEmpty
          ? _BreathingVoiceAvailability.ready
          : _BreathingVoiceAvailability.unavailable;
      _voiceSourceKind = resolved.isNotEmpty ? resolved.first.kind : null;
      _lastVoiceLocation = resolved.isNotEmpty ? resolved.first.location : null;
    });
  }

  Future<bool> _playResolvedCue(
    BreathingResolvedCue resolved, {
    required AudioPlayer player,
    required bool respectVoiceSetting,
    double playbackRate = 1.0,
  }) async {
    if (respectVoiceSetting && !_voiceOn) {
      return false;
    }
    final repo = _cueRepo;
    if (repo == null || !mounted) {
      return false;
    }
    try {
      if (respectVoiceSetting && !_voiceOn) {
        return false;
      }
      await player.stop();
      await player.setPlaybackRate(playbackRate.clamp(0.75, 2.0).toDouble());
      await AudioPlayerSourceHelper.play(
        player,
        resolved.source,
        volume: 1.0,
        tag: 'breathing_voice',
        data: <String, Object?>{
          'cueId': resolved.cue.id,
          'sourceKind': resolved.kind.name,
          'location': resolved.location,
          'respectVoiceSetting': respectVoiceSetting,
          'playbackRate': playbackRate,
        },
      );
      if (mounted) {
        setState(() {
          _voiceAvailability = _BreathingVoiceAvailability.ready;
          _voiceSourceKind = resolved.kind;
          _lastVoiceLocation = resolved.location;
        });
      }
      return true;
    } catch (_) {
      if (mounted && respectVoiceSetting) {
        setState(
          () => _voiceAvailability = _BreathingVoiceAvailability.unavailable,
        );
      }
      return false;
    }
  }

  Future<bool> _playCueId(
    String cueId, {
    required AudioPlayer player,
    required bool respectVoiceSetting,
    double playbackRate = 1.0,
  }) async {
    if (respectVoiceSetting && !_voiceOn) {
      return false;
    }
    if (_cueRepo == null || !mounted) {
      return false;
    }
    final resolved = await _cueRepo!.resolve(
      cueId,
      languageTags: _localeTags(Localizations.localeOf(context)),
    );
    if (resolved == null) {
      if (mounted && respectVoiceSetting) {
        setState(
          () => _voiceAvailability = _BreathingVoiceAvailability.unavailable,
        );
      }
      return false;
    }
    return _playResolvedCue(
      resolved,
      player: player,
      respectVoiceSetting: respectVoiceSetting,
      playbackRate: playbackRate,
    );
  }

  Duration _resolvedCueDurationOrFallback(
    BreathingResolvedCue resolved, {
    Duration fallback = const Duration(milliseconds: 1200),
  }) {
    return _resolvedCueDuration(resolved) ?? fallback;
  }

  Future<void> _stopSystemCue() async {
    _systemCueSequenceToken += 1;
    try {
      await _systemPlayer.stop();
    } catch (_) {}
  }

  Future<void> _playSystemCueSequence(
    List<String> cueIds, {
    bool respectVoiceSetting = true,
    Duration gap = const Duration(milliseconds: 140),
  }) async {
    if (respectVoiceSetting && !_voiceOn) {
      return;
    }
    if (_cueRepo == null || !mounted) {
      return;
    }
    final sequenceToken = _systemCueSequenceToken + 1;
    _systemCueSequenceToken = sequenceToken;
    await _stopPreview();
    try {
      await _systemPlayer.stop();
    } catch (_) {}
    for (final cueId in cueIds) {
      if (!mounted || _systemCueSequenceToken != sequenceToken) {
        return;
      }
      final resolved = await _cueRepo!.resolve(
        cueId,
        languageTags: _localeTags(Localizations.localeOf(context)),
      );
      if (resolved == null) {
        continue;
      }
      final played = await _playResolvedCue(
        resolved,
        player: _systemPlayer,
        respectVoiceSetting: respectVoiceSetting,
      );
      if (!played) {
        continue;
      }
      final waitDuration = _resolvedCueDurationOrFallback(resolved) + gap;
      await Future<void>.delayed(waitDuration);
    }
  }

  Future<void> _stopPreview() async {
    if (_previewing && mounted) {
      setState(() => _previewing = false);
    }
    try {
      await _previewPlayer.stop();
    } catch (_) {}
  }

  Future<void> _previewScenarioCue() async {
    final cueId = _scenario.previewCueId;
    if (cueId == null || _running) {
      return;
    }
    if (_previewing) {
      await _stopPreview();
      return;
    }
    await _cuePlayer.stop();
    if (mounted) {
      setState(() => _previewing = true);
    }
    final played = await _playCueId(
      cueId,
      player: _previewPlayer,
      respectVoiceSetting: false,
    );
    if (!played && mounted) {
      setState(() => _previewing = false);
    }
  }

  void _performHaptic() {
    if (!_hapticOn) {
      return;
    }
    switch (_stage.kind) {
      case BreathingStageKind.hold:
        HapticFeedback.lightImpact();
      case BreathingStageKind.inhale:
      case BreathingStageKind.exhale:
      case BreathingStageKind.rest:
        HapticFeedback.selectionClick();
    }
  }

  Future<void> _announceStage() async {
    _performHaptic();
    final resolved = await _resolveStageCueForStage(_stage);
    if (resolved == null || !_canPlayResolvedCueForStage(_stage, resolved)) {
      return;
    }
    await _playResolvedCue(
      resolved,
      player: _cuePlayer,
      respectVoiceSetting: true,
      playbackRate: _cuePlaybackRateForStage(_stage, resolved),
    );
  }

  Duration get _boltElapsed =>
      Duration(milliseconds: _boltStopwatch.elapsedMilliseconds);

  void _tickBolt() {
    _boltClock?.cancel();
    _boltClock = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || !_boltRunning) {
        _boltClock?.cancel();
        return;
      }
      setState(() {});
    });
  }

  Future<void> _startBoltTest() async {
    if (_running || _boltRunning || _boltPreparing || _sessionPreparing) {
      return;
    }
    await _stopSystemCue();
    await _stopPreview();
    if (!mounted) {
      return;
    }
    setState(() {
      _boltPreparing = true;
      _boltExpanded = true;
    });
    await _playSystemCueSequence(<String>['bolt_prepare', 'bolt_start']);
    if (!mounted || !_boltPreparing) {
      return;
    }
    _boltStopwatch
      ..reset()
      ..start();
    setState(() {
      _boltPreparing = false;
      _boltRunning = true;
    });
    _tickBolt();
  }

  Future<void> _stopBoltTest() async {
    if (_boltPreparing) {
      await _stopSystemCue();
      if (!mounted) {
        return;
      }
      setState(() => _boltPreparing = false);
      return;
    }
    if (!_boltRunning) {
      return;
    }
    _boltStopwatch.stop();
    _boltClock?.cancel();
    final seconds = (_boltStopwatch.elapsedMilliseconds / 1000).floor();
    setState(() {
      _boltRunning = false;
      if (seconds > 0) {
        _lastBoltSeconds = seconds;
        _bestBoltSeconds = math.max(_bestBoltSeconds, seconds);
      }
    });
    _savePrefs();
    unawaited(_playSystemCueSequence(<String>['bolt_stop', 'bolt_recover']));
  }

  Future<void> _resetBoltTest() async {
    await _stopSystemCue();
    _boltClock?.cancel();
    _boltStopwatch
      ..stop()
      ..reset();
    if (!mounted) {
      return;
    }
    setState(() {
      _boltRunning = false;
      _boltPreparing = false;
    });
  }

  void _tickStart() {
    _clock?.cancel();
    _clock = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted) {
        return;
      }
      if (_running && _elapsed >= _targetDuration) {
        unawaited(_finishSession());
        return;
      }
      setState(() {});
    });
  }

  Future<void> _startSession() async {
    if (_running || _boltRunning || _boltPreparing || _sessionPreparing) {
      return;
    }
    await _stopSystemCue();
    await _stopPreview();
    if (!mounted) {
      return;
    }
    setState(() {
      _sessionPreparing = true;
      _lastSummary = null;
    });
    await _playSystemCueSequence(<String>['session_start']);
    if (!mounted || !_sessionPreparing) {
      return;
    }
    setState(() {
      _sessionPreparing = false;
      _running = true;
      _runStartedAt = DateTime.now();
    });
    if (_controller.value <= 0 || _controller.value >= 1) {
      _syncDuration();
      _controller.forward(from: 0);
      unawaited(_announceStage());
    } else {
      _controller.forward();
    }
    _tickStart();
  }

  Future<void> _pauseSession() async {
    if (!_running) {
      return;
    }
    final elapsed = _elapsed;
    _controller.stop(canceled: false);
    _clock?.cancel();
    await _cuePlayer.stop();
    await _stopSystemCue();
    if (!mounted) {
      return;
    }
    setState(() {
      _running = false;
      _elapsedBeforeRun = elapsed;
      _runStartedAt = null;
    });
  }

  Future<void> _resetSession() async {
    _clock?.cancel();
    _controller.stop();
    _controller.value = 0;
    await _cuePlayer.stop();
    await _stopSystemCue();
    await _stopPreview();
    if (!mounted) {
      return;
    }
    setState(() {
      _running = false;
      _sessionPreparing = false;
      _stageIndex = 0;
      _rounds = 0;
      _elapsedBeforeRun = Duration.zero;
      _runStartedAt = null;
      _lastSummary = null;
    });
  }

  Future<bool> _confirmScenarioSelection(BreathingScenario scenario) async {
    if (!mounted || scenario.id != _altitudeScenarioId) {
      return true;
    }
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final boltHint = _lastBoltSeconds <= 0
        ? pickUiText(
            i18n,
            zh: '建议先做一次 BOLT 测试，确认自己在第一次明确呼吸欲望出现前能稳定停留的秒数。',
            en: 'Run a BOLT check first so you know how many seconds you can comfortably stay before the first clear urge to breathe.',
          )
        : _lastBoltSeconds < 20
        ? pickUiText(
            i18n,
            zh: '你最近的 BOLT 是 $_lastBoltSeconds 秒。一般建议先把 BOLT 稳定到 20 秒左右，再尝试高海拔模拟。',
            en: 'Your recent BOLT is $_lastBoltSeconds s. It is usually better to build toward roughly 20 seconds before trying altitude simulation.',
          )
        : pickUiText(
            i18n,
            zh: '你最近的 BOLT 是 $_lastBoltSeconds 秒。练习时仍然只停在舒适边界，不要硬扛。',
            en: 'Your recent BOLT is $_lastBoltSeconds s. Still stay inside comfort and do not force the hold.',
          );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            pickUiText(i18n, zh: '启用高海拔模拟？', en: 'Use altitude simulation?'),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  pickUiText(
                    i18n,
                    zh: '这是进阶练习，会加入“长呼气 + 呼后屏息”来模拟更稀薄空气下的呼吸约束。请只在白天、静坐或安全站立时短练。',
                    en: 'This advanced drill adds a long exhale plus an exhale hold to simulate a thinner-air constraint. Use it only briefly during the day while seated or standing safely.',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  boltHint,
                  style: Theme.of(dialogContext).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Text(
                  pickUiText(
                    i18n,
                    zh: '如果出现头晕、胸闷、刺麻或恢复吸气明显失控，请立刻停止并恢复自然呼吸。',
                    en: 'Stop immediately and return to natural breathing if you get dizzy, tight-chested, tingly, or lose control of the recovery breath.',
                  ),
                  style: Theme.of(dialogContext).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(pickUiText(i18n, zh: '取消', en: 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(pickUiText(i18n, zh: '继续选择', en: 'Continue')),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }

  Future<void> _applyScenario(BreathingScenario scenario) async {
    if (_scenario.id == scenario.id) {
      return;
    }
    final confirmed = await _confirmScenarioSelection(scenario);
    if (!confirmed) {
      return;
    }
    await _resetSession();
    if (!mounted) {
      return;
    }
    setState(() {
      _scenario = scenario;
      _theme = BreathingExperienceCatalog.themeById(scenario.themeId);
      _targetMinutes = scenario.recommendedMinutes;
      _stageIndex = 0;
      _voiceAvailability = _voiceOn
          ? _BreathingVoiceAvailability.checking
          : _BreathingVoiceAvailability.off;
      _voiceSourceKind = null;
      _lastVoiceLocation = null;
      _availableCueCount = 0;
      _expectedCueCount = 0;
    });
    _normalizeStageIndex();
    _syncDuration();
    _savePrefs();
    if (_voiceOn) {
      unawaited(_warmScenarioCues());
    }
  }

  Future<void> _setIncludeRecoveryStage(bool value) async {
    if (_includeRecoveryStage == value) {
      return;
    }
    await _resetSession();
    if (!mounted) {
      return;
    }
    setState(() {
      _includeRecoveryStage = value;
      _stageIndex = 0;
      _voiceAvailability = _voiceOn
          ? _BreathingVoiceAvailability.checking
          : _BreathingVoiceAvailability.off;
      _voiceSourceKind = null;
      _lastVoiceLocation = null;
      _availableCueCount = 0;
      _expectedCueCount = 0;
    });
    _normalizeStageIndex();
    _syncDuration();
    _savePrefs();
    if (_voiceOn) {
      unawaited(_warmScenarioCues());
    }
  }

  Future<void> _setIncludeHoldStage(bool value) async {
    if (_includeHoldStage == value) {
      return;
    }
    await _resetSession();
    if (!mounted) {
      return;
    }
    setState(() {
      _includeHoldStage = value;
      _stageIndex = 0;
      _voiceAvailability = _voiceOn
          ? _BreathingVoiceAvailability.checking
          : _BreathingVoiceAvailability.off;
      _voiceSourceKind = null;
      _lastVoiceLocation = null;
      _availableCueCount = 0;
      _expectedCueCount = 0;
    });
    _normalizeStageIndex();
    _syncDuration();
    _savePrefs();
    if (_voiceOn) {
      unawaited(_warmScenarioCues());
    }
  }

  Future<void> _setVoiceEnabled(
    bool value, {
    bool showLocaleNotice = true,
  }) async {
    if (_voiceOn == value) {
      if (value && showLocaleNotice) {
        unawaited(_maybeShowNonChineseVoiceNotice());
      }
      return;
    }
    if (!value) {
      await _cuePlayer.stop();
      await _stopSystemCue();
      await _stopPreview();
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _voiceOn = value;
      _voiceAvailability = value
          ? _BreathingVoiceAvailability.checking
          : _BreathingVoiceAvailability.off;
      if (!value) {
        _voiceSourceKind = null;
        _lastVoiceLocation = null;
        _availableCueCount = 0;
        _expectedCueCount = 0;
        _shortStageSilentCount = 0;
      }
    });
    if (value) {
      if (showLocaleNotice) {
        unawaited(_maybeShowNonChineseVoiceNotice());
      }
      unawaited(_warmScenarioCues());
    }
    _savePrefs();
  }

  void _onStageDone() {
    final nextIndex = (_stageIndex + 1) % _loopStages.length;
    setState(() {
      _stageIndex = nextIndex;
      if (nextIndex == 0) {
        _rounds += 1;
      }
    });
    if (_elapsed >= _targetDuration) {
      unawaited(_finishSession());
      return;
    }
    _syncDuration();
    _controller.forward(from: 0);
    unawaited(_announceStage());
  }

  Future<void> _skipStage() async {
    _controller.stop();
    _controller.value = 0;
    setState(() {
      _stageIndex = (_stageIndex + 1) % _loopStages.length;
      if (_stageIndex == 0) {
        _rounds += 1;
      }
    });
    _syncDuration();
    if (_running) {
      _controller.forward(from: 0);
      unawaited(_announceStage());
    }
  }

  Future<void> _finishSession() async {
    if (_finishing) {
      return;
    }
    _finishing = true;
    final elapsed = _elapsed;
    _clock?.cancel();
    _controller.stop(canceled: false);
    await _cuePlayer.stop();
    await _stopSystemCue();
    await _stopPreview();
    if (!mounted) {
      _finishing = false;
      return;
    }
    final summary = _buildSummary(
      AppI18n(Localizations.localeOf(context).languageCode),
      elapsed,
    );
    setState(() {
      _running = false;
      _elapsedBeforeRun = elapsed;
      _runStartedAt = null;
      _completedSessions += 1;
      _totalSeconds += elapsed.inSeconds;
      _lastSummary = summary;
    });
    _savePrefs();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(summary.title)));
    unawaited(_playSystemCueSequence(<String>['session_complete']));
    _finishing = false;
  }

  _BreathingSessionSummary _buildSummary(AppI18n i18n, Duration elapsed) {
    final cycles = math.max(
      1,
      elapsed.inSeconds ~/ math.max(1, _loopCycleSeconds),
    );
    final nextStep = switch (_scenario.id) {
      'sleep_46' || 'sleep_478' => pickUiText(
        i18n,
        zh: '下一步：放下屏幕，保持环境昏暗，直接进入休息。',
        en: 'Next: put the screen away, dim the room, and move into rest.',
      ),
      'box_4444' || 'focus_nasal_44' => pickUiText(
        i18n,
        zh: '下一步：立刻开始下一段任务，把刚建立的节拍带进去。',
        en: 'Next: begin the next task now while the rhythm is still fresh.',
      ),
      'physiological_sigh_216' => pickUiText(
        i18n,
        zh: '下一步：恢复自然呼吸 30-60 秒，再决定是否需要再来一轮短练。',
        en: 'Next: return to natural breathing for 30-60 seconds before deciding whether to repeat.',
      ),
      _altitudeScenarioId => pickUiText(
        i18n,
        zh: '下一步：先让呼吸完全恢复安静，再决定是否继续；高海拔模拟之间宁可少做，也不要硬顶。',
        en: 'Next: let the breath fully settle before deciding whether to continue; with altitude simulation, less is better than forcing another round.',
      ),
      _ => pickUiText(
        i18n,
        zh: '下一步：给身体留半分钟安静余量，再进入下一个动作。',
        en: 'Next: give the body half a minute of quiet space before the next activity.',
      ),
    };
    return _BreathingSessionSummary(
      title: pickUiText(
        i18n,
        zh: '完成：${_scenario.name.resolve(i18n)}',
        en: 'Completed: ${_scenario.name.resolve(i18n)}',
      ),
      body: pickUiText(
        i18n,
        zh: '本次练习 ${_fmt(elapsed)}，约完成 $cycles 轮。${_scenario.scene.resolve(i18n)}',
        en: 'Completed ${_fmt(elapsed)} and about $cycles cycles. ${_scenario.scene.resolve(i18n)}',
      ),
      nextStep: nextStep,
    );
  }

  double _orbScale(double progress) {
    return switch (_stage.kind) {
      BreathingStageKind.inhale =>
        0.72 + Curves.easeOutCubic.transform(progress) * 0.38,
      BreathingStageKind.hold => 1.1,
      BreathingStageKind.exhale =>
        1.1 - Curves.easeInCubic.transform(progress) * 0.38,
      BreathingStageKind.rest => 0.72,
    };
  }

  String _fmt(Duration value) {
    final total = value.inSeconds;
    final mm = (total ~/ 60).toString().padLeft(2, '0');
    final ss = (total % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  String _voiceLabel(AppI18n i18n) {
    return switch (_voiceAvailability) {
      _BreathingVoiceAvailability.off => pickUiText(
        i18n,
        zh: '语音提示已关闭',
        en: 'Voice guidance is off',
      ),
      _BreathingVoiceAvailability.checking => pickUiText(
        i18n,
        zh: '正在检查语音资源',
        en: 'Checking voice resources',
      ),
      _BreathingVoiceAvailability.ready => switch (_voiceSourceKind) {
        BreathingCueSourceKind.remote => pickUiText(
          i18n,
          zh: '云端缓存语音已就绪',
          en: 'Cloud voice is ready',
        ),
        BreathingCueSourceKind.asset ||
        null => pickUiText(i18n, zh: '内置语音已就绪', en: 'Bundled voice is ready'),
      },
      _BreathingVoiceAvailability.unavailable => pickUiText(
        i18n,
        zh: '当前场景没有匹配到可用语音',
        en: 'No usable voice cue matched this scenario',
      ),
    };
  }

  String _voiceSubtitle(AppI18n i18n) {
    switch (_voiceAvailability) {
      case _BreathingVoiceAvailability.off:
        return pickUiText(
          i18n,
          zh: '你仍可使用文字提示和轻震动跟练。',
          en: 'Text prompts and haptics still work when voice is off.',
        );
      case _BreathingVoiceAvailability.checking:
        return pickUiText(
          i18n,
          zh: '优先检查可用语音，并自动判断短节拍是否适合播报。',
          en: 'Checking available cues, adapting short stages, and keeping pause stages silent by default.',
        );
      case _BreathingVoiceAvailability.ready:
        final parts = <String>[];
        if (_expectedCueCount > 0) {
          parts.add(
            pickUiText(
              i18n,
              zh: '$_availableCueCount/$_expectedCueCount 个节拍语音已就绪',
              en: '$_availableCueCount/$_expectedCueCount cues ready',
            ),
          );
        }
        if (_shortStageSilentCount > 0) {
          parts.add(
            pickUiText(
              i18n,
              zh: '$_shortStageSilentCount 个短节拍自动改为静默，避免语音压拍',
              en: '$_shortStageSilentCount short stages stay silent to protect timing',
            ),
          );
        }
        parts.add(pickUiText(i18n, zh: '停顿阶段保持静音', en: 'Pause stays silent'));
        return parts.isEmpty
            ? pickUiText(i18n, zh: '语音可用。', en: 'Voice guidance is available.')
            : parts.join(' · ');
      case _BreathingVoiceAvailability.unavailable:
        return pickUiText(
          i18n,
          zh: '建议先使用文字和震动；如果需要语音，可检查资源包是否完整。',
          en: 'Use text and haptics for now; check the voice assets if you need audio guidance.',
        );
    }
  }

  String _voiceSourceChipLabel(AppI18n i18n) {
    return switch (_voiceSourceKind) {
      BreathingCueSourceKind.remote => pickUiText(
        i18n,
        zh: '云端缓存',
        en: 'Cloud cache',
      ),
      BreathingCueSourceKind.asset ||
      null => pickUiText(i18n, zh: '内置资源', en: 'Bundled'),
    };
  }

  IconData _voiceStatusIcon() {
    return switch (_voiceAvailability) {
      _BreathingVoiceAvailability.off => Icons.volume_off_rounded,
      _BreathingVoiceAvailability.checking => Icons.downloading_rounded,
      _BreathingVoiceAvailability.ready => switch (_voiceSourceKind) {
        BreathingCueSourceKind.remote => Icons.cloud_done_rounded,
        BreathingCueSourceKind.asset || null => Icons.library_music_rounded,
      },
      _BreathingVoiceAvailability.unavailable => Icons.error_outline_rounded,
    };
  }

  Color _voiceStatusColor(BuildContext context) {
    return switch (_voiceAvailability) {
      _BreathingVoiceAvailability.off => Theme.of(context).colorScheme.outline,
      _BreathingVoiceAvailability.checking => Theme.of(
        context,
      ).colorScheme.primary,
      _BreathingVoiceAvailability.ready => const Color(0xFF2E9D6A),
      _BreathingVoiceAvailability.unavailable => Theme.of(
        context,
      ).colorScheme.error,
    };
  }

  String _stageFlowLabel(AppI18n i18n) {
    return _loopStages
        .map(
          (stage) =>
              '${stage.label.resolve(i18n)} ${stage.seconds}${pickUiText(i18n, zh: '秒', en: 's')}',
        )
        .join(' · ');
  }

  String _paceLabel(AppI18n i18n) {
    final value = _loopCycleSeconds <= 0 ? 0 : 60 / _loopCycleSeconds;
    final formatted = value >= 10
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return pickUiText(
      i18n,
      zh: '约 $formatted 轮/分钟',
      en: '~$formatted cycles/min',
    );
  }

  String _friendlyVoiceLocation() {
    final value = (_lastVoiceLocation ?? '').trim();
    if (value.isEmpty) {
      return '';
    }
    return p.basename(value);
  }

  String _scenarioNameById(String id, AppI18n i18n) =>
      BreathingExperienceCatalog.scenarioById(id).name.resolve(i18n);

  _BoltAssessment _boltAssessmentFor(AppI18n i18n, int seconds) {
    if (seconds <= 0) {
      return _BoltAssessment(
        label: pickUiText(i18n, zh: '尚未测试', en: 'Not tested yet'),
        body: pickUiText(
          i18n,
          zh: '先做一次 BOLT 测试，再根据结果决定是该优先练轻柔鼻呼吸、稳态慢呼吸，还是可以进入更进阶的屏息练习。',
          en: 'Run one BOLT check first so you can decide whether to prioritize gentle nasal work, steady slow breathing, or more advanced hold work.',
        ),
        nextStep: pickUiText(
          i18n,
          zh: '先从腹式 4-2-6-2、平息长呼 3-6 这类低刺激练习开始。',
          en: 'Start with lower-intensity drills such as Diaphragm 4-2-6-2 or Calm 3-6.',
        ),
        recommendedScenarioIds: const <String>[
          'diaphragm_4262',
          'calm_36',
          'sleep_46',
        ],
        tint: const Color(0xFF6B7A8C),
        altitudeReady: false,
      );
    }
    if (seconds < 10) {
      return _BoltAssessment(
        label: pickUiText(i18n, zh: 'BOLT 偏低', en: 'Low BOLT'),
        body: pickUiText(
          i18n,
          zh: '先把重点放在鼻呼吸、放松和轻柔呼气，不要追求长时间屏息或高强度空气饥饿。',
          en: 'Focus first on nasal breathing, relaxation, and gentle exhales rather than long holds or strong air hunger.',
        ),
        nextStep: pickUiText(
          i18n,
          zh: '优先做低刺激练习，并把“停在第一次明确呼吸欲望前后”当作上限。',
          en: 'Stay with low-intensity drills and treat the first clear urge to breathe as the ceiling.',
        ),
        recommendedScenarioIds: const <String>[
          'diaphragm_4262',
          'calm_36',
          'sleep_46',
        ],
        tint: const Color(0xFFC56A4A),
        altitudeReady: false,
      );
    }
    if (seconds < 20) {
      return _BoltAssessment(
        label: pickUiText(i18n, zh: 'BOLT 建设期', en: 'BOLT building'),
        body: pickUiText(
          i18n,
          zh: '已经可以做稳态慢呼吸和短屏息，但仍应把重点放在安静、鼻吸鼻呼与稳定节律上。',
          en: 'You can start using steady slow breathing and short holds, but the priority is still quiet nasal rhythm rather than hard breath-hold work.',
        ),
        nextStep: pickUiText(
          i18n,
          zh: '先把 BOLT 稳到 20 秒左右，再考虑高海拔模拟。',
          en: 'Build toward roughly 20 seconds before considering altitude simulation.',
        ),
        recommendedScenarioIds: const <String>[
          'coherent_55',
          'relax_4262',
          'focus_nasal_44',
        ],
        tint: const Color(0xFFB58B2C),
        altitudeReady: false,
      );
    }
    if (seconds < 30) {
      return _BoltAssessment(
        label: pickUiText(i18n, zh: 'BOLT 稳定区', en: 'Stable BOLT'),
        body: pickUiText(
          i18n,
          zh: '你通常已经能承受轻到中等的空气饥饿，可以尝试更明确的节律控制和短时进阶练习。',
          en: 'You can usually tolerate mild to moderate air hunger now, which opens the door to clearer pacing work and short advanced drills.',
        ),
        nextStep: pickUiText(
          i18n,
          zh: '可以少量尝试高海拔模拟，但恢复吸气仍要安静、可控。',
          en: 'You can sample altitude simulation briefly, but the recovery inhale still needs to stay calm and controlled.',
        ),
        recommendedScenarioIds: const <String>[
          'box_4444',
          'parasym_4462',
          _altitudeScenarioId,
        ],
        tint: const Color(0xFF2E8B57),
        altitudeReady: true,
      );
    }
    return _BoltAssessment(
      label: pickUiText(i18n, zh: 'BOLT 进阶区', en: 'Advanced BOLT'),
      body: pickUiText(
        i18n,
        zh: '你已经有不错的空气饥饿耐受度，可以把短时高海拔模拟、经典 4-7-8 等更进阶节律作为补充，而不是主训练。',
        en: 'You have a solid tolerance to air hunger now, so brief altitude simulation and advanced rhythms like Classic 4-7-8 can work as supplemental drills rather than the main practice.',
      ),
      nextStep: pickUiText(
        i18n,
        zh: '继续把鼻呼吸、低刺激恢复和高强度短练搭配使用，不要把每次都练到极限。',
        en: 'Keep combining nasal recovery work with short advanced drills, and avoid pushing every session to the limit.',
      ),
      recommendedScenarioIds: const <String>[
        _altitudeScenarioId,
        'sleep_478',
        'physiological_sigh_216',
      ],
      tint: const Color(0xFF3478C0),
      altitudeReady: true,
    );
  }

  List<String> _generalTechniqueTips(AppI18n i18n) {
    return <String>[
      pickUiText(
        i18n,
        zh: '基础原则先看鼻呼吸与轻柔呼吸，嘴巴更适合吃饭而不是日常换气。',
        en: 'Start with nasal and gentle breathing. The mouth is better for eating than for routine ventilation.',
      ),
      pickUiText(
        i18n,
        zh: '呼吸要安静、平顺、像水流一样连续，不要用力“深吸一大口”。',
        en: 'Keep the breath quiet, smooth, and continuous like flowing water instead of forcing a giant inhale.',
      ),
      pickUiText(
        i18n,
        zh: 'BOLT 和屏息都停在第一次明确呼吸欲望附近，不做最大憋气测试。',
        en: 'For both BOLT and breath holds, stop around the first clear urge to breathe rather than testing a maximal hold.',
      ),
    ];
  }

  List<String> _scenarioTutorialSteps(AppI18n i18n) {
    final steps = <String>[
      for (final entry in _loopStages.asMap().entries)
        '${entry.key + 1}. ${entry.value.label.resolve(i18n)} ${entry.value.seconds}${pickUiText(i18n, zh: '秒', en: 's')}: ${entry.value.prompt.resolve(i18n)}',
    ];
    switch (_scenario.id) {
      case 'diaphragm_4262':
        steps.add(
          pickUiText(
            i18n,
            zh: '用腹部带动节律，肩膀不要跟着抬起；如果一开始不习惯，就先让动作小一点。',
            en: 'Let the belly drive the rhythm and keep the shoulders out of it; make the motion smaller if you are just learning.',
          ),
        );
        break;
      case 'focus_nasal_44' || 'box_4444':
        steps.add(
          pickUiText(
            i18n,
            zh: '把计数感放在节律一致，而不是吸得更大；练完后立刻进入下一段专注任务。',
            en: 'Keep the count consistent instead of making the breath bigger, then move straight into the next focus task.',
          ),
        );
        break;
      case 'sleep_46' || 'sleep_478':
        steps.add(
          pickUiText(
            i18n,
            zh: '睡前模式宁可小口、安静，也不要把自己练清醒；如果越练越精神，就退回 4-6。',
            en: 'At bedtime, smaller and quieter is better than waking yourself up; step back to 4-6 if the practice makes you more alert.',
          ),
        );
        break;
      case 'physiological_sigh_216':
        steps.add(
          pickUiText(
            i18n,
            zh: '把它当作 1 到 2 分钟的短练，练完先恢复自然呼吸 30 到 60 秒，再决定要不要继续。',
            en: 'Treat it as a 1-2 minute drill, then return to natural breathing for 30-60 seconds before deciding whether to continue.',
          ),
        );
        break;
      case _altitudeScenarioId:
        steps.add(
          pickUiText(
            i18n,
            zh: '高海拔模拟只停在“明确想呼吸但还能稳住”的边界；恢复吸气必须安静，不能猛吸。',
            en: 'In altitude simulation, stop at the edge where the urge to breathe is clear but still controlled, and keep the recovery inhale quiet rather than sharp.',
          ),
        );
        break;
      default:
        steps.add(
          pickUiText(
            i18n,
            zh: '如果某一段开始费力、发紧或想追求更大口，先把幅度减小，再继续跟节律。',
            en: 'If any phase starts to feel effortful or tight, shrink the breath before trying to continue the rhythm.',
          ),
        );
        break;
    }
    return steps;
  }

  Widget _buildBulletList(
    BuildContext context,
    List<String> items, {
    required Color tint,
    IconData icon = Icons.check_circle_outline_rounded,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(icon, size: 16, color: tint),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Color _stageTint(BreathingStageKind kind) {
    return switch (kind) {
      BreathingStageKind.inhale => _theme.orbStart,
      BreathingStageKind.hold => _theme.accent,
      BreathingStageKind.exhale => _theme.orbEnd,
      BreathingStageKind.rest => Colors.white.withValues(alpha: 0.32),
    };
  }

  Widget _buildScenarioSelector(AppI18n i18n) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: BreathingExperienceCatalog.scenarios
          .map(
            (scenario) => ChoiceChip(
              selected: scenario.id == _scenario.id,
              onSelected: (_) => unawaited(_applyScenario(scenario)),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (scenario.advanced) ...<Widget>[
                    const Icon(Icons.bolt_rounded, size: 16),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      scenario.name.resolve(i18n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  // ignore: unused_element
  Widget _buildScenarioGuideCard(BuildContext context, AppI18n i18n) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey<String>('breathing-guide-${_scenario.id}'),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _theme.orbEnd.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.menu_book_rounded,
              size: 18,
              color: _theme.orbEnd,
            ),
          ),
          title: Text(
            pickUiText(i18n, zh: '呼吸说明', en: 'Breathing guide'),
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            pickUiText(
              i18n,
              zh: '展开查看研究依据、身体要点、适用时机和节拍说明。',
              en: 'Expand for research basis, body focus, when to use, and cycle flow.',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          children: <Widget>[
            BreathingInsightTile(
              title: pickUiText(i18n, zh: '研究依据', en: 'Research basis'),
              body: _scenario.researchBasis.resolve(i18n),
              icon: Icons.science_outlined,
              tint: _theme.orbEnd,
            ),
            const SizedBox(height: 10),
            BreathingInsightTile(
              title: pickUiText(i18n, zh: '作用机制', en: 'How it works'),
              body: _scenario.mechanism.resolve(i18n),
              icon: Icons.monitor_heart_outlined,
              tint: _theme.orbStart,
            ),
            const SizedBox(height: 12),
            Text(
              pickUiText(i18n, zh: '身体关注', en: 'Body focus'),
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(_scenario.bodyFocus.resolve(i18n)),
            const SizedBox(height: 10),
            Text(
              pickUiText(i18n, zh: '适用情境', en: 'When to use'),
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(_scenario.whenToUse.resolve(i18n)),
            const SizedBox(height: 10),
            Text(
              pickUiText(i18n, zh: '节拍流程', en: 'Cycle flow'),
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              _stageFlowLabel(i18n),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioOverviewCard(BuildContext context, AppI18n i18n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _scenario.scene.resolve(i18n),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(_scenario.description.resolve(i18n)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _theme.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(_theme.icon, color: _theme.orbEnd),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ..._scenario.tags.map(
                (tag) => ScenarioTagChip(
                  label: tag.resolve(i18n),
                  color: _theme.orbEnd,
                ),
              ),
              ScenarioTagChip(label: _paceLabel(i18n), color: _theme.orbStart),
              if (_scenario.advanced)
                ScenarioTagChip(
                  label: pickUiText(i18n, zh: '进阶', en: 'Advanced'),
                  color: Theme.of(context).colorScheme.error,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                key: PageStorageKey<String>('breathing-guide-${_scenario.id}'),
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 2,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                shape: const Border(),
                collapsedShape: const Border(),
                leading: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _theme.orbEnd.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: 18,
                    color: _theme.orbEnd,
                  ),
                ),
                title: Text(
                  pickUiText(i18n, zh: '呼吸说明', en: 'Breathing guide'),
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  pickUiText(
                    i18n,
                    zh: '展开查看研究依据、身体要点、适用时机和节拍说明。',
                    en: 'Expand for research basis, body focus, when to use, and cycle flow.',
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                children: <Widget>[
                  BreathingInsightTile(
                    title: pickUiText(i18n, zh: '研究依据', en: 'Research basis'),
                    body: _scenario.researchBasis.resolve(i18n),
                    icon: Icons.science_outlined,
                    tint: _theme.orbEnd,
                  ),
                  const SizedBox(height: 10),
                  BreathingInsightTile(
                    title: pickUiText(i18n, zh: '作用机制', en: 'How it works'),
                    body: _scenario.mechanism.resolve(i18n),
                    icon: Icons.monitor_heart_outlined,
                    tint: _theme.orbStart,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    pickUiText(i18n, zh: '身体关注', en: 'Body focus'),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_scenario.bodyFocus.resolve(i18n)),
                  const SizedBox(height: 10),
                  Text(
                    pickUiText(i18n, zh: '适用情境', en: 'When to use'),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_scenario.whenToUse.resolve(i18n)),
                  const SizedBox(height: 12),
                  Text(
                    pickUiText(i18n, zh: '练习步骤', en: 'Practice steps'),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildBulletList(
                    context,
                    _scenarioTutorialSteps(i18n),
                    tint: _theme.orbEnd,
                    icon: Icons.route_rounded,
                  ),
                  const SizedBox(height: 12),
                  VoiceStatusPill(
                    label: _voiceLabel(i18n),
                    subtitle: _voiceSubtitle(i18n),
                    icon: _voiceStatusIcon(),
                    iconColor: _voiceStatusColor(context),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      ScenarioTagChip(
                        label: _voiceSourceChipLabel(i18n),
                        color: _voiceStatusColor(context),
                      ),
                      if (_expectedCueCount > 0)
                        ScenarioTagChip(
                          label: pickUiText(
                            i18n,
                            zh: '语音覆盖 $_availableCueCount/$_expectedCueCount',
                            en: 'Coverage $_availableCueCount/$_expectedCueCount',
                          ),
                          color: _theme.orbStart,
                        ),
                      if (_shortStageSilentCount > 0)
                        ScenarioTagChip(
                          label: pickUiText(
                            i18n,
                            zh: '短节拍静默 $_shortStageSilentCount',
                            en: 'Silent short $_shortStageSilentCount',
                          ),
                          color: _theme.accent,
                        ),
                    ],
                  ),
                  if (_friendlyVoiceLocation().isNotEmpty) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      pickUiText(
                        i18n,
                        zh: '最近匹配语音：${_friendlyVoiceLocation()}',
                        en: 'Last matched cue: ${_friendlyVoiceLocation()}',
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    pickUiText(i18n, zh: '节拍流程', en: 'Cycle flow'),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _stageFlowLabel(i18n),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    pickUiText(i18n, zh: '通用技巧', en: 'Core technique'),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildBulletList(
                    context,
                    _generalTechniqueTips(i18n),
                    tint: _theme.orbStart,
                    icon: Icons.air_rounded,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: _running || _scenario.previewCueId == null
                    ? null
                    : () => unawaited(_previewScenarioCue()),
                icon: Icon(
                  _previewing
                      ? Icons.stop_circle_outlined
                      : Icons.volume_up_rounded,
                ),
                label: Text(
                  _previewing
                      ? pickUiText(i18n, zh: '停止预听', en: 'Stop preview')
                      : pickUiText(i18n, zh: '预听引导', en: 'Preview guidance'),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _targetMinutes == _scenario.recommendedMinutes
                    ? null
                    : () {
                        setState(
                          () => _targetMinutes = _scenario.recommendedMinutes,
                        );
                        _savePrefs();
                      },
                icon: const Icon(Icons.schedule_rounded),
                label: Text(
                  pickUiText(
                    i18n,
                    zh: '使用建议 ${_scenario.recommendedMinutes} 分钟',
                    en: 'Use ${_scenario.recommendedMinutes} min',
                  ),
                ),
              ),
            ],
          ),
          if (_scenario.caution != null) ...<Widget>[
            const SizedBox(height: 12),
            SafetyNoteCard(
              title: pickUiText(i18n, zh: '注意', en: 'Caution'),
              body: _scenario.caution!.resolve(i18n),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBoltCard(BuildContext context, AppI18n i18n) {
    final assessment = _boltAssessmentFor(i18n, _lastBoltSeconds);
    final liveSeconds = (_boltElapsed.inMilliseconds / 1000).toStringAsFixed(1);
    final currentValue = _boltRunning
        ? '$liveSeconds ${pickUiText(i18n, zh: '秒', en: 's')}'
        : _lastBoltSeconds > 0
        ? '$_lastBoltSeconds ${pickUiText(i18n, zh: '秒', en: 's')}'
        : '--';
    final bestValue = _bestBoltSeconds > 0
        ? '$_bestBoltSeconds ${pickUiText(i18n, zh: '秒', en: 's')}'
        : '--';
    final boltSteps = <String>[
      pickUiText(
        i18n,
        zh: '先坐稳 30 到 60 秒，让呼吸恢复安静，再开始测试。',
        en: 'Sit quietly for 30-60 seconds first so the breath settles before you test.',
      ),
      pickUiText(
        i18n,
        zh: '用鼻子轻轻小吸、轻轻小呼，然后开始计时并捏住鼻子。',
        en: 'Take a small inhale and small exhale through the nose, then start timing and pinch the nose.',
      ),
      pickUiText(
        i18n,
        zh: '在第一次明确想呼吸时就停止，不做最大憋气挑战。',
        en: 'Stop at the first clear urge to breathe rather than turning this into a maximal-hold challenge.',
      ),
      pickUiText(
        i18n,
        zh: '测试后用安静鼻呼吸恢复；如果恢复时想猛吸，说明这次憋得太久了。',
        en: 'Recover with quiet nasal breathing. If you need to gasp on recovery, you held too long.',
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _boltExpanded = !_boltExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: assessment.tint.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.speed_rounded, color: assessment.tint),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          pickUiText(i18n, zh: 'BOLT 测试', en: 'BOLT test'),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pickUiText(
                            i18n,
                            zh: _boltExpanded
                                ? '测的是第一次明确呼吸欲望前的舒适停留，不是拼最长憋气。'
                                : '默认折叠显示摘要，展开后查看步骤、结果解读与推荐练习。',
                            en: _boltExpanded
                                ? 'This measures your comfortable pause before the first clear urge to breathe, not the longest possible hold.'
                                : 'Collapsed by default for a compact summary. Expand for steps, interpretation, and drill recommendations.',
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _boltExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ScenarioTagChip(
                label:
                    '${pickUiText(i18n, zh: '当前', en: 'Current')} $currentValue',
                color: assessment.tint,
              ),
              ScenarioTagChip(
                label:
                    '${pickUiText(i18n, zh: '区间', en: 'Band')} ${assessment.label}',
                color: _theme.orbEnd,
              ),
              ScenarioTagChip(
                label: '${pickUiText(i18n, zh: '最佳', en: 'Best')} $bestValue',
                color: _theme.orbStart,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: (_running || _sessionPreparing)
                    ? null
                    : () => _boltRunning
                          ? unawaited(_stopBoltTest())
                          : unawaited(_startBoltTest()),
                icon: Icon(
                  _boltPreparing
                      ? Icons.hourglass_top_rounded
                      : _boltRunning
                      ? Icons.stop_circle_rounded
                      : Icons.play_arrow_rounded,
                ),
                label: Text(
                  _boltPreparing
                      ? pickUiText(i18n, zh: '准备中', en: 'Preparing')
                      : _boltRunning
                      ? pickUiText(i18n, zh: '记录结果', en: 'Save result')
                      : pickUiText(i18n, zh: '开始测试', en: 'Start test'),
                ),
              ),
              OutlinedButton.icon(
                onPressed:
                    (_boltPreparing ||
                        _boltRunning ||
                        _lastBoltSeconds > 0 ||
                        _boltElapsed > Duration.zero)
                    ? () => unawaited(_resetBoltTest())
                    : null,
                icon: const Icon(Icons.restart_alt_rounded),
                label: Text(pickUiText(i18n, zh: '重置', en: 'Reset')),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _boltExpanded = !_boltExpanded),
                icon: Icon(
                  _boltExpanded
                      ? Icons.unfold_less_rounded
                      : Icons.unfold_more_rounded,
                ),
                label: Text(
                  pickUiText(
                    i18n,
                    zh: _boltExpanded ? '收起详情' : '展开详情',
                    en: _boltExpanded ? 'Collapse' : 'Expand',
                  ),
                ),
              ),
            ],
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _boltExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  BreathingInsightTile(
                    title: pickUiText(
                      i18n,
                      zh: _lastBoltSeconds > 0
                          ? '结果解读：${assessment.label}'
                          : '怎么理解 BOLT',
                      en: _lastBoltSeconds > 0
                          ? 'Interpretation: ${assessment.label}'
                          : 'How to read BOLT',
                    ),
                    body: _lastBoltSeconds > 0
                        ? '${assessment.body} ${assessment.nextStep}'
                        : pickUiText(
                            i18n,
                            zh: 'BOLT 常被用来粗略判断你当前对空气饥饿的耐受度，以及更适合做轻柔练习还是进阶屏息。',
                            en: 'BOLT is often used as a rough read on your current tolerance to air hunger and whether you should emphasize gentle work or more advanced breath holds.',
                          ),
                    icon: Icons.insights_rounded,
                    tint: assessment.tint,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    pickUiText(i18n, zh: '测试步骤', en: 'Test steps'),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildBulletList(
                    context,
                    boltSteps,
                    tint: assessment.tint,
                    icon: Icons.timer_outlined,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pickUiText(i18n, zh: '推荐练习', en: 'Recommended drills'),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: assessment.recommendedScenarioIds
                        .map((scenarioId) {
                          final scenario =
                              BreathingExperienceCatalog.scenarioById(
                                scenarioId,
                              );
                          return ActionChip(
                            avatar: Icon(
                              scenario.id == _altitudeScenarioId
                                  ? Icons.terrain_rounded
                                  : Icons.self_improvement_rounded,
                              size: 16,
                            ),
                            label: Text(_scenarioNameById(scenario.id, i18n)),
                            onPressed: () =>
                                unawaited(_applyScenario(scenario)),
                          );
                        })
                        .toList(growable: false),
                  ),
                  if (!assessment.altitudeReady) ...<Widget>[
                    const SizedBox(height: 10),
                    Text(
                      pickUiText(
                        i18n,
                        zh: '当前结果不建议直接进入高海拔模拟，先把鼻呼吸和安静恢复练稳。',
                        en: 'This score does not suggest going straight into altitude simulation yet. Build nasal breathing and calm recovery first.',
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeCard(BuildContext context, AppI18n i18n) {
    final remainStage = math.max(
      0,
      (_stage.seconds - (_stage.seconds * _controller.value)).ceil(),
    );
    final remainSession = (_targetDuration - _elapsed).inSeconds.clamp(
      0,
      24 * 3600,
    );
    final stageLabel = _textOn
        ? _stage.label.resolve(i18n)
        : pickUiText(i18n, zh: '跟随光球', en: 'Follow the orb');
    final stagePrompt = _textOn
        ? _stage.prompt.resolve(i18n)
        : pickUiText(i18n, zh: '保持自然呼吸', en: 'Keep the breath natural');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[_theme.bgStart, _theme.bgEnd],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 260,
                child: Text(
                  _theme.mood.resolve(i18n),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ),
              BreathingMetricPill(
                label: pickUiText(i18n, zh: '单轮时长', en: 'Cycle'),
                value: pickUiText(
                  i18n,
                  zh: '$_loopCycleSeconds 秒',
                  en: '$_loopCycleSeconds s',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final visualSize = math.min(
                340.0,
                math.max(220.0, constraints.maxWidth - 8),
              );
              final orbDiameter = visualSize * 0.58;
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final progress = _controller.value;
                  return Column(
                    children: <Widget>[
                      SizedBox(
                        width: visualSize,
                        height: visualSize,
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            CustomPaint(
                              size: Size.square(visualSize),
                              painter: BreathingAuraPainter(
                                progress: progress,
                                stageKind: _stage.kind,
                                color: _theme.accent,
                                secondary: _theme.orbEnd,
                              ),
                            ),
                            Transform.scale(
                              scale: _orbScale(progress),
                              child: Container(
                                width: orbDiameter,
                                height: orbDiameter,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: <Color>[
                                      _theme.orbStart,
                                      _theme.orbEnd,
                                    ],
                                  ),
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color: _theme.orbStart.withValues(
                                        alpha: 0.32,
                                      ),
                                      blurRadius: 32,
                                      spreadRadius: 6,
                                    ),
                                  ],
                                ),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final compact = constraints.maxWidth < 148;
                                    final showPrompt =
                                        constraints.maxWidth >= 148;
                                    final innerPadding = compact ? 8.0 : 18.0;
                                    final iconSize = compact ? 24.0 : 42.0;
                                    final labelStyle = compact
                                        ? Theme.of(context).textTheme.titleSmall
                                        : Theme.of(
                                            context,
                                          ).textTheme.titleLarge;
                                    final promptStyle = compact
                                        ? Theme.of(context).textTheme.labelSmall
                                        : Theme.of(context).textTheme.bodySmall;
                                    return Padding(
                                      padding: EdgeInsets.all(innerPadding),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          Icon(
                                            switch (_stage.kind) {
                                              BreathingStageKind.inhale =>
                                                Icons.south_west_rounded,
                                              BreathingStageKind.hold =>
                                                Icons
                                                    .pause_circle_filled_rounded,
                                              BreathingStageKind.exhale =>
                                                Icons.north_east_rounded,
                                              BreathingStageKind.rest =>
                                                Icons.self_improvement_rounded,
                                            },
                                            color: Colors.white.withValues(
                                              alpha: 0.96,
                                            ),
                                            size: iconSize,
                                          ),
                                          SizedBox(height: compact ? 4 : 8),
                                          Text(
                                            stageLabel,
                                            style: labelStyle?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: compact ? 2 : 3,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (showPrompt) ...<Widget>[
                                            SizedBox(height: compact ? 3 : 6),
                                            Text(
                                              stagePrompt,
                                              style: promptStyle?.copyWith(
                                                color: Colors.white.withValues(
                                                  alpha: 0.88,
                                                ),
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: compact ? 2 : 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        pickUiText(
                          i18n,
                          zh: '本段剩 $remainStage 秒 · 第 ${_rounds + 1} 轮 · 下一步 ${_nextStage.label.resolve(i18n)}',
                          en: '$remainStage s left · Round ${_rounds + 1} · Next ${_nextStage.label.resolve(i18n)}',
                        ),
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 10),
          BreathingStageTimeline(
            stages: _loopStages,
            activeIndex: _stageIndex,
            i18n: i18n,
            stageTintBuilder: _stageTint,
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: _targetProgress,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              valueColor: AlwaysStoppedAnimation<Color>(_theme.accent),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: <Widget>[
              BreathingMetricPill(
                label: pickUiText(i18n, zh: '目标', en: 'Target'),
                value: pickUiText(
                  i18n,
                  zh: '$_targetMinutes 分钟',
                  en: '$_targetMinutes min',
                ),
              ),
              BreathingMetricPill(
                label: pickUiText(i18n, zh: '已完成', en: 'Done'),
                value: _fmt(_elapsed),
              ),
              BreathingMetricPill(
                label: pickUiText(i18n, zh: '剩余', en: 'Left'),
                value:
                    '${remainSession ~/ 60}:${(remainSession % 60).toString().padLeft(2, '0')}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: <Widget>[
              FilledButton.icon(
                onPressed: (_boltRunning || _boltPreparing || _sessionPreparing)
                    ? null
                    : () => unawaited(
                        _running ? _pauseSession() : _startSession(),
                      ),
                icon: Icon(
                  _sessionPreparing
                      ? Icons.hourglass_top_rounded
                      : _running
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
                label: Text(
                  _sessionPreparing
                      ? pickUiText(i18n, zh: '准备中', en: 'Preparing')
                      : _running
                      ? pickUiText(i18n, zh: '暂停', en: 'Pause')
                      : pickUiText(i18n, zh: '开始', en: 'Start'),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _sessionPreparing
                    ? null
                    : () => unawaited(_skipStage()),
                icon: const Icon(Icons.skip_next_rounded),
                label: Text(pickUiText(i18n, zh: '下一阶段', en: 'Next stage')),
              ),
              OutlinedButton.icon(
                onPressed: _sessionPreparing
                    ? null
                    : () => unawaited(_resetSession()),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(pickUiText(i18n, zh: '重置', en: 'Reset')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, AppI18n i18n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            pickUiText(i18n, zh: '训练设置', en: 'Session setup'),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            pickUiText(i18n, zh: '主题', en: 'Theme'),
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: BreathingExperienceCatalog.themes
                .map(
                  (theme) => ChoiceChip(
                    selected: theme.id == _theme.id,
                    onSelected: (_) {
                      setState(() => _theme = theme);
                      _savePrefs();
                    },
                    label: Text(theme.name.resolve(i18n)),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
          Text(
            pickUiText(i18n, zh: '时长', en: 'Duration'),
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _targetOptions
                .map(
                  (minutes) => ChoiceChip(
                    selected: _targetMinutes == minutes,
                    onSelected: (_) {
                      setState(() => _targetMinutes = minutes);
                      _savePrefs();
                    },
                    label: Text(
                      pickUiText(i18n, zh: '$minutes 分钟', en: '$minutes min'),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            value: _includeHoldStage,
            onChanged: (value) => unawaited(_setIncludeHoldStage(value)),
            title: Text(pickUiText(i18n, zh: '屏息阶段', en: 'Breath-hold stage')),
            subtitle: Text(
              pickUiText(
                i18n,
                zh: '默认开启。关闭后会跳过所有屏息步骤，只保留吸气/呼气/停顿。',
                en: 'On by default. Turn this off to skip all hold phases and keep only inhale, exhale, and pause.',
              ),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile.adaptive(
            value: _includeRecoveryStage,
            onChanged: (value) => unawaited(_setIncludeRecoveryStage(value)),
            title: Text(pickUiText(i18n, zh: '保留恢复段', en: 'Recovery stage')),
            subtitle: Text(
              pickUiText(
                i18n,
                zh: '关闭后只保留主要呼吸步骤，更适合连续跟练；停顿阶段也不会播报语音。',
                en: 'When off, the loop keeps only the main breathing phases for smoother repetition, and pause stages stay silent.',
              ),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile.adaptive(
            value: _voiceOn,
            onChanged: (value) => unawaited(_setVoiceEnabled(value)),
            title: Text(pickUiText(i18n, zh: '语音提示', en: 'Voice cues')),
            subtitle: Text(
              pickUiText(
                i18n,
                zh: '优先下载并缓存云端语音；语音会跟随吸气/呼气/屏息阶段，停顿阶段默认保持静音。',
                en: 'Cloud cues are downloaded and cached first. Voice follows inhale, exhale, and hold phases, while pause stays silent by default.',
              ),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile.adaptive(
            value: _textOn,
            onChanged: (value) {
              setState(() => _textOn = value);
              _savePrefs();
            },
            title: Text(pickUiText(i18n, zh: '文字提示', en: 'Text cues')),
            subtitle: Text(
              pickUiText(
                i18n,
                zh: '显示当前动作、身体提示和倒计时；如果想闭眼练习，可以只保留语音与震动。',
                en: 'Show the current action, body prompt, and countdown. Turn this off for eyes-closed practice.',
              ),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile.adaptive(
            value: _hapticOn,
            onChanged: (value) {
              setState(() => _hapticOn = value);
              _savePrefs();
            },
            title: Text(pickUiText(i18n, zh: '震动反馈', en: 'Haptics')),
            subtitle: Text(
              pickUiText(
                i18n,
                zh: '阶段切换时给轻微触感，适合不盯着屏幕也能跟练。',
                en: 'Adds subtle pulses on stage changes so you can follow without staring at the screen.',
              ),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SectionHeader(
              title: pickUiText(i18n, zh: '呼吸训练场景', en: 'Breathing scenarios'),
              subtitle: pickUiText(
                i18n,
                zh: '针对移动端优化：修复乱码、重做窄屏布局、改进语音播报与短节拍适配，并补充更有依据的训练场景。',
                en: 'Optimized for mobile: cleaned copy, improved narrow-screen layout, better cue timing, and more evidence-aware breathing scenarios.',
              ),
            ),
            const SizedBox(height: 12),
            _buildScenarioSelector(i18n),
            const SizedBox(height: 14),
            _buildScenarioOverviewCard(context, i18n),
            const SizedBox(height: 16),
            _buildBoltCard(context, i18n),
            const SizedBox(height: 16),
            _buildPracticeCard(context, i18n),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                ToolboxMetricCard(
                  label: pickUiText(i18n, zh: '轮数', en: 'Rounds'),
                  value: '$_rounds',
                ),
                ToolboxMetricCard(
                  label: pickUiText(i18n, zh: '已完成场次', en: 'Sessions'),
                  value: '$_completedSessions',
                ),
                ToolboxMetricCard(
                  label: pickUiText(i18n, zh: '累计时长', en: 'Total time'),
                  value: _fmt(Duration(seconds: _totalSeconds)),
                ),
                ToolboxMetricCard(
                  label: pickUiText(i18n, zh: '语音来源', en: 'Voice'),
                  value: _voiceSourceChipLabel(i18n),
                ),
                ToolboxMetricCard(
                  label: pickUiText(i18n, zh: 'BOLT', en: 'BOLT'),
                  value: _lastBoltSeconds > 0
                      ? '$_lastBoltSeconds ${pickUiText(i18n, zh: '秒', en: 's')}'
                      : '--',
                ),
              ],
            ),
            if (_lastSummary != null) ...<Widget>[
              const SizedBox(height: 14),
              SessionSummaryCard(
                title: _lastSummary!.title,
                body: _lastSummary!.body,
                nextStep: _lastSummary!.nextStep,
              ),
            ],
            const SizedBox(height: 14),
            _buildSettingsCard(context, i18n),
            const SizedBox(height: 14),
            SafetyNoteCard(
              title: pickUiText(i18n, zh: '安全提醒', en: 'Safety note'),
              body: pickUiText(
                i18n,
                zh: '不要在驾驶、骑行或任何需要持续警觉的场景中使用。若出现头晕、胸闷、刺痛或明显不适，请立刻停止并恢复自然呼吸。睡前与长呼气模式应以舒适为先，不把自己练到缺氧感。',
                en: 'Do not use while driving or in any situation that requires continuous alertness. Stop immediately if you feel dizzy, tight-chested, tingly, or clearly uncomfortable. Keep bedtime and long-exhale work comfortably below the point of air hunger.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
