import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
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

  late final AnimationController _controller;
  late final StreamSubscription<void> _previewCompleteSub;
  final AudioPlayer _cuePlayer = AudioPlayer();
  final AudioPlayer _previewPlayer = AudioPlayer();
  Timer? _clock;

  CstCloudResourceCacheService? _resourceCache;
  ToolboxBreathingAudioRepository? _cueRepo;
  late BreathingScenario _scenario;
  late BreathingThemeSpec _theme;

  bool _voiceOn = true;
  bool _textOn = true;
  bool _hapticOn = true;
  bool _includeRecoveryStage = false;
  bool _running = false;
  bool _previewing = false;
  bool _finishing = false;
  int _targetMinutes = 5;
  int _stageIndex = 0;
  int _rounds = 0;
  int _completedSessions = 0;
  int _totalSeconds = 0;
  int _availableCueCount = 0;
  int _expectedCueCount = 0;
  int _shortStageSilentCount = 0;
  Duration _elapsedBeforeRun = Duration.zero;
  DateTime? _runStartedAt;
  _BreathingVoiceAvailability _voiceAvailability =
      _BreathingVoiceAvailability.checking;
  BreathingCueSourceKind? _voiceSourceKind;
  String? _lastVoiceLocation;
  _BreathingSessionSummary? _lastSummary;

  List<BreathingStagePlan> get _loopStages {
    if (_includeRecoveryStage) {
      return _scenario.stages;
    }
    final filtered = _scenario.stages
        .where((stage) => stage.kind != BreathingStageKind.rest)
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
        unawaited(_warmScenarioCues());
      }
    }
  }

  @override
  void dispose() {
    _clock?.cancel();
    unawaited(_previewCompleteSub.cancel());
    unawaited(_cuePlayer.dispose());
    unawaited(_previewPlayer.dispose());
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
      _includeRecoveryStage = prefs.includeRecoveryStage;
      _voiceOn = prefs.voiceGuidanceEnabled;
      _textOn = prefs.textGuidanceEnabled;
      _hapticOn = prefs.hapticsEnabled;
      _completedSessions = prefs.completedSessions;
      _totalSeconds = prefs.totalPracticeSeconds;
      _voiceAvailability = _voiceOn
          ? _BreathingVoiceAvailability.checking
          : _BreathingVoiceAvailability.off;
      _voiceSourceKind = null;
      _lastVoiceLocation = null;
    });
    _normalizeStageIndex();
    _syncDuration();
    if (_voiceOn) {
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
          includeRecoveryStage: _includeRecoveryStage,
          voiceGuidanceEnabled: _voiceOn,
          textGuidanceEnabled: _textOn,
          hapticsEnabled: _hapticOn,
          completedSessions: _completedSessions,
          totalPracticeSeconds: _totalSeconds,
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

  String? _effectiveCueIdForStage(BreathingStagePlan stage) {
    if (stage.kind == BreathingStageKind.rest && !_includeRecoveryStage) {
      return null;
    }
    if (stage.seconds <= 2) {
      return switch (stage.kind) {
        BreathingStageKind.inhale => 'inhale_soft',
        BreathingStageKind.exhale => 'exhale_soft',
        BreathingStageKind.hold => 'hold_soft',
        BreathingStageKind.rest => stage.cueId,
      };
    }
    return stage.cueId;
  }

  double _cuePlaybackRateForStage(BreathingStagePlan stage, String cueId) {
    final cue = BreathingExperienceCatalog.cues[cueId];
    if (cue == null) {
      return 1.0;
    }
    final targetWindowMs = math.max(420, stage.seconds * 1000 - 180);
    return (cue.approxDurationMs / targetWindowMs).clamp(1.0, 2.0).toDouble();
  }

  bool _canPlayCueForStage(BreathingStagePlan stage, {String? cueId}) {
    final resolvedCueId = cueId ?? _effectiveCueIdForStage(stage);
    if (resolvedCueId == null) {
      return false;
    }
    final playbackRate = _cuePlaybackRateForStage(stage, resolvedCueId);
    final repo = _cueRepo;
    if (repo == null) {
      final cue = BreathingExperienceCatalog.cues[resolvedCueId];
      if (cue == null) {
        return false;
      }
      return cue.approxDurationMs <= stage.seconds * 1000;
    }
    return repo.canPlayCueWithinStage(
      resolvedCueId,
      stageDuration: Duration(seconds: stage.seconds),
      playbackRate: playbackRate,
    );
  }

  Set<String> _warmUpCueIds() {
    final cueIds = <String>{};
    if (_scenario.previewCueId != null) {
      cueIds.add(_scenario.previewCueId!);
    }
    for (final stage in _loopStages) {
      final cueId = _effectiveCueIdForStage(stage);
      if (cueId == null || !_canPlayCueForStage(stage, cueId: cueId)) {
        continue;
      }
      cueIds.add(cueId);
    }
    return cueIds;
  }

  int _shortStageSkipCount() {
    var count = 0;
    for (final stage in _loopStages) {
      final cueId = _effectiveCueIdForStage(stage);
      if (cueId != null && !_canPlayCueForStage(stage, cueId: cueId)) {
        count += 1;
      }
    }
    return count;
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
    final scenarioId = _scenario.id;
    final includeRecoveryStage = _includeRecoveryStage;
    final warmUpCueIds = _warmUpCueIds();
    final silentShortCueCount = _shortStageSkipCount();
    setState(() {
      _voiceAvailability = _BreathingVoiceAvailability.checking;
      _expectedCueCount = warmUpCueIds.length;
      _shortStageSilentCount = silentShortCueCount;
    });
    final resolved = await repo.warmUpCueIds(
      warmUpCueIds,
      languageTags: _localeTags(Localizations.localeOf(context)),
    );
    if (!mounted ||
        _scenario.id != scenarioId ||
        _includeRecoveryStage != includeRecoveryStage) {
      return;
    }
    setState(() {
      _availableCueCount = resolved.length;
      _expectedCueCount = warmUpCueIds.length;
      _shortStageSilentCount = silentShortCueCount;
      _voiceAvailability = resolved.isNotEmpty
          ? _BreathingVoiceAvailability.ready
          : _BreathingVoiceAvailability.unavailable;
      _voiceSourceKind = resolved.isNotEmpty ? resolved.first.kind : null;
      _lastVoiceLocation = resolved.isNotEmpty ? resolved.first.location : null;
    });
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
    final repo = _cueRepo;
    if (repo == null || !mounted) {
      return false;
    }
    try {
      final resolved = await repo.resolve(
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
      await player.stop();
      await player.setPlaybackRate(playbackRate.clamp(0.75, 2.0).toDouble());
      await player.play(resolved.source);
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
    final cueId = _effectiveCueIdForStage(_stage);
    if (cueId == null || !_canPlayCueForStage(_stage, cueId: cueId)) {
      return;
    }
    await _playCueId(
      cueId,
      player: _cuePlayer,
      respectVoiceSetting: true,
      playbackRate: _cuePlaybackRateForStage(_stage, cueId),
    );
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
    if (_running) {
      return;
    }
    await _stopPreview();
    setState(() {
      _running = true;
      _runStartedAt = DateTime.now();
      _lastSummary = null;
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
    await _stopPreview();
    if (!mounted) {
      return;
    }
    setState(() {
      _running = false;
      _stageIndex = 0;
      _rounds = 0;
      _elapsedBeforeRun = Duration.zero;
      _runStartedAt = null;
      _lastSummary = null;
    });
  }

  Future<void> _applyScenario(BreathingScenario scenario) async {
    if (_scenario.id == scenario.id) {
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
          en: 'Checking available cues and whether short stages can support playback.',
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
    final value = _scenario.cyclesPerMinute;
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

  Color _stageTint(BreathingStageKind kind) {
    return switch (kind) {
      BreathingStageKind.inhale => _theme.orbStart,
      BreathingStageKind.hold => _theme.accent,
      BreathingStageKind.exhale => _theme.orbEnd,
      BreathingStageKind.rest => Colors.white.withValues(alpha: 0.32),
    };
  }

  Widget _buildScenarioSelector(AppI18n i18n) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: BreathingExperienceCatalog.scenarios
            .map(
              (scenario) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  selected: scenario.id == _scenario.id,
                  onSelected: (_) => unawaited(_applyScenario(scenario)),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (scenario.advanced) ...<Widget>[
                        const Icon(Icons.bolt_rounded, size: 16),
                        const SizedBox(width: 4),
                      ],
                      Text(scenario.name.resolve(i18n)),
                    ],
                  ),
                ),
              ),
            )
            .toList(growable: false),
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
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            _stageFlowLabel(i18n),
            style: Theme.of(context).textTheme.bodySmall,
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
                onPressed: () =>
                    unawaited(_running ? _pauseSession() : _startSession()),
                icon: Icon(
                  _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
                label: Text(
                  _running
                      ? pickUiText(i18n, zh: '暂停', en: 'Pause')
                      : pickUiText(i18n, zh: '开始', en: 'Start'),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => unawaited(_skipStage()),
                icon: const Icon(Icons.skip_next_rounded),
                label: Text(pickUiText(i18n, zh: '下一阶段', en: 'Next stage')),
              ),
              OutlinedButton.icon(
                onPressed: () => unawaited(_resetSession()),
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: BreathingExperienceCatalog.themes
                  .map(
                    (theme) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        selected: theme.id == _theme.id,
                        onSelected: (_) {
                          setState(() => _theme = theme);
                          _savePrefs();
                        },
                        label: Text(theme.name.resolve(i18n)),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
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
            value: _includeRecoveryStage,
            onChanged: (value) => unawaited(_setIncludeRecoveryStage(value)),
            title: Text(pickUiText(i18n, zh: '保留恢复段', en: 'Recovery stage')),
            subtitle: Text(
              pickUiText(
                i18n,
                zh: '关闭后只保留吸气/停留/呼气，更适合连续跟练。',
                en: 'When off, loop only inhale, hold, and exhale for smoother repetition.',
              ),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile.adaptive(
            value: _voiceOn,
            onChanged: (value) {
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
                }
              });
              if (!value) {
                unawaited(_cuePlayer.stop());
              } else {
                unawaited(_warmScenarioCues());
              }
              _savePrefs();
            },
            title: Text(pickUiText(i18n, zh: '语音提示', en: 'Voice cues')),
            subtitle: Text(
              pickUiText(
                i18n,
                zh: '优先下载并缓存云端语音；太短的节拍会自动转为文字和震动，避免语音压住节奏。',
                en: 'Cloud cues are downloaded and cached first; very short stages automatically fall back to text and haptics.',
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
