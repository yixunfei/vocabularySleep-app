import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

enum _BreathingVoiceAvailability { off, checking, remote, unavailable }

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
  static const List<int> _targetOptions = <int>[2, 3, 5, 8, 10, 15];

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
  Duration _elapsedBeforeRun = Duration.zero;
  DateTime? _runStartedAt;
  _BreathingVoiceAvailability _voiceAvailability =
      _BreathingVoiceAvailability.checking;
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

  Iterable<String> _scenarioCueIds() sync* {
    if (_scenario.previewCueId != null) {
      yield _scenario.previewCueId!;
    }
    for (final stage in _loopStages) {
      final cueId = _effectiveCueIdForStage(stage);
      if (cueId != null) {
        yield cueId;
      }
    }
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
    setState(() => _voiceAvailability = _BreathingVoiceAvailability.checking);
    final resolved = await repo.warmUpCueIds(
      _scenarioCueIds(),
      languageTags: _localeTags(Localizations.localeOf(context)),
    );
    if (!mounted ||
        _scenario.id != scenarioId ||
        _includeRecoveryStage != includeRecoveryStage) {
      return;
    }
    setState(() {
      _voiceAvailability = resolved.isNotEmpty
          ? _BreathingVoiceAvailability.remote
          : _BreathingVoiceAvailability.unavailable;
      if (resolved.isNotEmpty) {
        _lastVoiceLocation = resolved.first.location;
      }
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
          _voiceAvailability = _BreathingVoiceAvailability.remote;
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

  double _cuePlaybackRateForStage(BreathingStagePlan stage) {
    if (stage.kind != BreathingStageKind.inhale &&
        stage.kind != BreathingStageKind.exhale) {
      return 1.0;
    }
    if (stage.seconds <= 1) {
      return 2.0;
    }
    if (stage.seconds <= 2) {
      return 1.85;
    }
    if (stage.seconds == 3) {
      return 1.35;
    }
    return 1.0;
  }

  Future<void> _announceStage() async {
    _performHaptic();
    final cueId = _effectiveCueIdForStage(_stage);
    if (cueId == null) {
      return;
    }
    await _playCueId(
      cueId,
      player: _cuePlayer,
      respectVoiceSetting: true,
      playbackRate: _cuePlaybackRateForStage(_stage),
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
      'sleep_478' => pickUiText(
        i18n,
        zh: '下一步建议：放下屏幕，调暗环境光，直接进入休息。',
        en: 'Next: dim the environment and move straight into rest.',
      ),
      'energize_3131' => pickUiText(
        i18n,
        zh: '下一步建议：立刻开始下一个专注任务，把刚建立的节奏带进去。',
        en: 'Next: start the next focus task while the rhythm is fresh.',
      ),
      'altitude_2442' => pickUiText(
        i18n,
        zh: '下一步建议：先休息 1 分钟，再决定是否继续，不要连续叠加强度。',
        en: 'Next: rest for a minute before deciding whether to continue.',
      ),
      _ => pickUiText(
        i18n,
        zh: '下一步建议：如果身体更稳更慢，可以保持当前节奏再做 1-2 分钟。',
        en: 'Next: if the body feels steadier, stay with the rhythm for 1-2 more minutes.',
      ),
    };
    return _BreathingSessionSummary(
      title: pickUiText(
        i18n,
        zh: '练习完成：${_scenario.name.resolve(i18n)}',
        en: 'Completed: ${_scenario.name.resolve(i18n)}',
      ),
      body: pickUiText(
        i18n,
        zh: '完成 ${_fmt(elapsed)}，约 $cycles 轮。${_scenario.scene.resolve(i18n)}。',
        en: 'Completed ${_fmt(elapsed)} and about $cycles cycles. ${_scenario.scene.resolve(i18n)}.',
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
        zh: '\u5df2\u5173\u95ed',
        en: 'Off',
      ),
      _BreathingVoiceAvailability.checking => pickUiText(
        i18n,
        zh: '\u68c0\u67e5\u4e2d',
        en: 'Checking',
      ),
      _BreathingVoiceAvailability.remote => pickUiText(
        i18n,
        zh: '\u4e91\u7aef\u8bed\u97f3',
        en: 'Cloud',
      ),
      _BreathingVoiceAvailability.unavailable => pickUiText(
        i18n,
        zh: '\u4e0d\u53ef\u7528',
        en: 'Unavailable',
      ),
    };
  }

  String _voiceSubtitle(AppI18n i18n) {
    return switch (_voiceAvailability) {
      _BreathingVoiceAvailability.off => pickUiText(
        i18n,
        zh: '\u8bed\u97f3\u63d0\u793a\u5df2\u5173\u95ed',
        en: 'Voice guidance is off',
      ),
      _BreathingVoiceAvailability.checking => pickUiText(
        i18n,
        zh: '\u6b63\u5728\u9884\u70ed S3 \u8bed\u97f3',
        en: 'Checking S3 voice files',
      ),
      _BreathingVoiceAvailability.remote => pickUiText(
        i18n,
        zh: '\u4ec5\u4f7f\u7528\u8fdc\u7a0b S3 \u4e0b\u8f7d\u8bed\u97f3\u6587\u4ef6',
        en: 'Using remote S3 voice files only',
      ),
      _BreathingVoiceAvailability.unavailable => pickUiText(
        i18n,
        zh: '\u5f53\u524d\u573a\u666f\u672a\u627e\u5230\u5339\u914d\u97f3\u9891\u6587\u4ef6',
        en: 'No matching cue file found',
      ),
    };
  }

  IconData _voiceStatusIcon() {
    return switch (_voiceAvailability) {
      _BreathingVoiceAvailability.off => Icons.volume_off_rounded,
      _BreathingVoiceAvailability.checking => Icons.downloading_rounded,
      _BreathingVoiceAvailability.remote => Icons.cloud_done_rounded,
      _BreathingVoiceAvailability.unavailable => Icons.error_outline_rounded,
    };
  }

  Color _voiceStatusColor(BuildContext context) {
    return switch (_voiceAvailability) {
      _BreathingVoiceAvailability.off => Theme.of(context).colorScheme.outline,
      _BreathingVoiceAvailability.checking => Theme.of(
        context,
      ).colorScheme.primary,
      _BreathingVoiceAvailability.remote => const Color(0xFF2E9D6A),
      _BreathingVoiceAvailability.unavailable => Theme.of(
        context,
      ).colorScheme.error,
    };
  }

  String _stageFlowLabel(AppI18n i18n) {
    return _loopStages
        .map(
          (stage) =>
              '${stage.label.resolve(i18n)} ${stage.seconds}${pickUiText(i18n, zh: '\u79d2', en: 's')}',
        )
        .join(' 路 ');
  }

  Color _stageTint(BreathingStageKind kind) {
    return switch (kind) {
      BreathingStageKind.inhale => _theme.orbStart,
      BreathingStageKind.hold => _theme.accent,
      BreathingStageKind.exhale => _theme.orbEnd,
      BreathingStageKind.rest => Colors.white.withValues(alpha: 0.32),
    };
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final stageProgress = _controller.value;
    final remainStage = math.max(
      0,
      (_stage.seconds - (_stage.seconds * stageProgress)).ceil(),
    );
    final remainSession = (_targetDuration - _elapsed).inSeconds.clamp(
      0,
      24 * 3600,
    );
    final stageLabel = _textOn
        ? _stage.label.resolve(i18n)
        : pickUiText(i18n, zh: '璺熼殢鍏夌悆绉诲姩', en: 'Follow the orb');
    final stagePrompt = _textOn
        ? _stage.prompt.resolve(i18n)
        : pickUiText(i18n, zh: '淇濇寔鑷劧鍛煎惛', en: 'Keep the breath natural');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SectionHeader(
              title: pickUiText(i18n, zh: '鍛煎惛鍦烘櫙', en: 'Breathing scenarios'),
              subtitle: pickUiText(
                i18n,
                zh: '围绕“循环跟练”设计：默认专注吸-停-呼，恢复阶段可按需开启。',
                en: 'Optimized for loop practice: inhale/hold/exhale by default, optional recovery stage.',
              ),
              trailing: VoiceStatusPill(
                label: _voiceLabel(i18n),
                subtitle: _voiceSubtitle(i18n),
                icon: _voiceStatusIcon(),
                iconColor: _voiceStatusColor(context),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
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
                          Text(scenario.name.resolve(i18n)),
                        ],
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
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
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
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
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _scenario.tags
                        .map(
                          (tag) => ScenarioTagChip(
                            label: tag.resolve(i18n),
                            color: _theme.orbEnd,
                          ),
                        )
                        .toList(growable: false),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    pickUiText(i18n, zh: '鍔ㄤ綔閲嶇偣', en: 'Body focus'),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_scenario.bodyFocus.resolve(i18n)),
                  const SizedBox(height: 10),
                  Text(
                    pickUiText(i18n, zh: '閫傜敤鍦烘櫙', en: 'When to use'),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_scenario.whenToUse.resolve(i18n)),
                  const SizedBox(height: 10),
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
                              ? pickUiText(
                                  i18n,
                                  zh: '鍋滄璇曞惉',
                                  en: 'Stop preview',
                                )
                              : pickUiText(
                                  i18n,
                                  zh: '璇曞惉寮曞',
                                  en: 'Preview guidance',
                                ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed:
                            _targetMinutes == _scenario.recommendedMinutes
                            ? null
                            : () {
                                setState(
                                  () => _targetMinutes =
                                      _scenario.recommendedMinutes,
                                );
                                _savePrefs();
                              },
                        icon: const Icon(Icons.schedule_rounded),
                        label: Text(
                          pickUiText(
                            i18n,
                            zh: '鐢ㄦ帹鑽?${_scenario.recommendedMinutes} 鍒嗛挓',
                            en: 'Use ${_scenario.recommendedMinutes} min',
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_scenario.caution != null) ...<Widget>[
                    const SizedBox(height: 12),
                    SafetyNoteCard(
                      title: pickUiText(i18n, zh: '娉ㄦ剰', en: 'Caution'),
                      body: _scenario.caution!.resolve(i18n),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
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
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          _theme.mood.resolve(i18n),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          pickUiText(
                            i18n,
                            zh: '周期 $_loopCycleSeconds 秒',
                            en: '$_loopCycleSeconds s cycle',
                          ),
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final progress = _controller.value;
                      return SizedBox(
                        width: 300,
                        height: 280,
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            CustomPaint(
                              size: const Size.square(280),
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
                                width: 166,
                                height: 166,
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
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Icon(
                                      switch (_stage.kind) {
                                        BreathingStageKind.inhale =>
                                          Icons.south_west_rounded,
                                        BreathingStageKind.hold =>
                                          Icons.pause_circle_filled_rounded,
                                        BreathingStageKind.exhale =>
                                          Icons.north_east_rounded,
                                        BreathingStageKind.rest =>
                                          Icons.self_improvement_rounded,
                                      },
                                      color: Colors.white.withValues(
                                        alpha: 0.96,
                                      ),
                                      size: 44,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      stageLabel,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      stagePrompt,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Colors.white.withValues(
                                              alpha: 0.88,
                                            ),
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 2,
                              child: Text(
                                pickUiText(
                                  i18n,
                                  zh: '鍓╀綑 $remainStage 绉?路 绗?${_rounds + 1} 杞?路 涓嬩竴姝?${_nextStage.label.resolve(i18n)}',
                                  en: '$remainStage s left 路 Round ${_rounds + 1} 路 Next ${_nextStage.label.resolve(i18n)}',
                                ),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 8),
                  Text(
                    pickUiText(
                      i18n,
                      zh: '鐩爣 $_targetMinutes 鍒嗛挓 路 宸插畬鎴?${_fmt(_elapsed)} 路 鍓╀綑 ${remainSession ~/ 60}:${(remainSession % 60).toString().padLeft(2, '0')}',
                      en: 'Target $_targetMinutes min 路 Done ${_fmt(_elapsed)} 路 Left ${remainSession ~/ 60}:${(remainSession % 60).toString().padLeft(2, '0')}',
                    ),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: () =>
                      unawaited(_running ? _pauseSession() : _startSession()),
                  icon: Icon(
                    _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  ),
                  label: Text(
                    _running
                        ? pickUiText(i18n, zh: '鏆傚仠', en: 'Pause')
                        : pickUiText(i18n, zh: '开始', en: 'Start'),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => unawaited(_skipStage()),
                  icon: const Icon(Icons.skip_next_rounded),
                  label: Text(pickUiText(i18n, zh: '涓嬩竴闃舵', en: 'Next stage')),
                ),
                OutlinedButton.icon(
                  onPressed: () => unawaited(_resetSession()),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(pickUiText(i18n, zh: '閲嶇疆', en: 'Reset')),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                ToolboxMetricCard(
                  label: pickUiText(i18n, zh: '杞暟', en: 'Rounds'),
                  value: '$_rounds',
                ),
                ToolboxMetricCard(
                  label: pickUiText(i18n, zh: '瀹屾垚娆℃暟', en: 'Sessions'),
                  value: '$_completedSessions',
                ),
                ToolboxMetricCard(
                  label: pickUiText(i18n, zh: '绱鏃堕暱', en: 'Total time'),
                  value: _fmt(Duration(seconds: _totalSeconds)),
                ),
                ToolboxMetricCard(
                  label: pickUiText(i18n, zh: '璇煶鏉ユ簮', en: 'Voice'),
                  value: _voiceLabel(i18n),
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
            Text(
              pickUiText(i18n, zh: '涓婚姘涘洿', en: 'Theme'),
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
              pickUiText(i18n, zh: '缁冧範鏃堕暱', en: 'Session duration'),
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
                        pickUiText(
                          i18n,
                          zh: '$minutes 鍒嗛挓',
                          en: '$minutes min',
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 10),
            SwitchListTile.adaptive(
              value: _includeRecoveryStage,
              onChanged: (value) => unawaited(_setIncludeRecoveryStage(value)),
              title: Text(pickUiText(i18n, zh: '鎭㈠闃舵', en: 'Recovery stage')),
              subtitle: Text(
                pickUiText(
                  i18n,
                  zh: '关闭后仅保留吸气/停留/呼气循环，更适合连续跟练（推荐）。',
                  en: 'When off, loop only inhale/hold/exhale for continuous practice.',
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
                });
                if (!value) {
                  unawaited(_cuePlayer.stop());
                } else {
                  unawaited(_warmScenarioCues());
                }
                _savePrefs();
              },
              title: Text(pickUiText(i18n, zh: '璇煶鎻愮ず', en: 'Voice cues')),
              subtitle: Text(
                pickUiText(
                  i18n,
                  zh: '仅使用 S3 路径 follow_this_breath/follow_this_breath 的中文音频；快速阶段自动提速并优先使用“吸气/呼气”通用音频。',
                  en: 'Prefer Chinese cue files under follow_this_breath/follow_this_breath; fast stages auto-speed up generic inhale/exhale cues.',
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
              title: Text(pickUiText(i18n, zh: '鏂囧瓧鎻愮ず', en: 'Text cues')),
              subtitle: Text(
                pickUiText(
                  i18n,
                  zh: '显示当前动作、身体提示和倒计时。',
                  en: 'Show stage labels, body prompts, and countdowns.',
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
              title: Text(pickUiText(i18n, zh: '瑙︽劅鎻愮ず', en: 'Haptics')),
              subtitle: Text(
                pickUiText(
                  i18n,
                  zh: '阶段切换时给轻微触觉反馈，便于闭眼跟练。',
                  en: 'Use subtle pulses on stage changes for eyes-closed practice.',
                ),
              ),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            SafetyNoteCard(
              title: pickUiText(i18n, zh: '鍙戝竷寤鸿', en: 'Safety note'),
              body: pickUiText(
                i18n,
                zh: '驾驶、骑行或任何需要持续警觉的场景不要使用。若出现头晕、胸闷或明显不适，请立刻停止。高海拔模拟属于进阶功能，不替代医疗或专业训练建议。',
                en: 'Do not use while driving or in situations requiring continuous alertness. Stop immediately if you feel dizzy or uncomfortable. Altitude simulation is an advanced feature, not medical guidance.',
              ),
            ),
            if ((_lastVoiceLocation ?? '').trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                pickUiText(
                  i18n,
                  zh: '鏈€杩戝懡涓殑璇煶璧勬簮锛?_lastVoiceLocation',
                  en: 'Last matched cue: $_lastVoiceLocation',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
