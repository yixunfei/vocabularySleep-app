import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../../i18n/app_i18n.dart';
import '../../services/audio_player_source_helper.dart';
import '../../services/cstcloud_resource_cache_service.dart';
import '../../services/toolbox_breathing_audio_repository.dart';
import '../../services/toolbox_breathing_catalog.dart';
import '../../services/toolbox_breathing_prefs_service.dart';
import '../../state/app_state_provider.dart';
import '../widgets/section_header.dart';
import 'toolbox_breathing_ui_parts.dart';
import 'toolbox_tool_shell.dart';

part 'toolbox_breathing_tool_voice.dart';

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

class BreathingPracticeReleaseCard extends ConsumerStatefulWidget {
  const BreathingPracticeReleaseCard({super.key});

  @override
  ConsumerState<BreathingPracticeReleaseCard> createState() =>
      _BreathingPracticeReleaseCardState();
}

class _BreathingPracticeReleaseCardState
    extends ConsumerState<BreathingPracticeReleaseCard>
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
  int _boltPreparationGeneration = 0;
  int _sessionPreparationGeneration = 0;

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
      nextCache = ref.read(cstCloudResourceCacheProvider);
    } on StateError {
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
      final loadedScenario = BreathingExperienceCatalog.scenarioById(
        prefs.presetId,
      );
      _scenario = loadedScenario;
      _theme = BreathingExperienceCatalog.themeById(loadedScenario.themeId);
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

  void _updateState(VoidCallback updater) {
    if (!mounted) {
      return;
    }
    setState(updater);
  }

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
    final preparationGeneration = ++_boltPreparationGeneration;
    await _stopSystemCue();
    await _stopPreview();
    if (!mounted || preparationGeneration != _boltPreparationGeneration) {
      return;
    }
    setState(() {
      _boltPreparing = true;
      _boltExpanded = true;
    });
    try {
      await _playSystemCueSequence(<String>['bolt_prepare', 'bolt_start']);
      if (!mounted ||
          !_boltPreparing ||
          preparationGeneration != _boltPreparationGeneration) {
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
    } finally {
      if (mounted &&
          _boltPreparing &&
          preparationGeneration == _boltPreparationGeneration) {
        setState(() => _boltPreparing = false);
      }
    }
  }

  Future<void> _stopBoltTest() async {
    if (_boltPreparing) {
      _boltPreparationGeneration += 1;
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
    _boltPreparationGeneration += 1;
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
    final preparationGeneration = ++_sessionPreparationGeneration;
    await _stopSystemCue();
    await _stopPreview();
    if (!mounted || preparationGeneration != _sessionPreparationGeneration) {
      return;
    }
    setState(() {
      _sessionPreparing = true;
      _lastSummary = null;
    });
    try {
      await _playSystemCueSequence(<String>['session_start']);
      if (!mounted ||
          !_sessionPreparing ||
          preparationGeneration != _sessionPreparationGeneration) {
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
    } finally {
      if (mounted &&
          _sessionPreparing &&
          preparationGeneration == _sessionPreparationGeneration) {
        setState(() => _sessionPreparing = false);
      }
    }
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
    _sessionPreparationGeneration += 1;
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
        ? i18n.t(
            'inline.plan294.breathing.run_a_bolt_check_first_so_you_know_how_many_seco_c2c60be9',
          )
        : _lastBoltSeconds < 20
        ? i18n.t(
            'inline.plan294.breathing.your_recent_bolt_is_value_s_it_is_usually_better_b95808b3',
            params: <String, Object?>{'lastBoltSeconds': _lastBoltSeconds},
          )
        : i18n.t(
            'inline.plan294.breathing.your_recent_bolt_is_value_s_still_stay_inside_co_42bf0ef2',
            params: <String, Object?>{'lastBoltSeconds': _lastBoltSeconds},
          );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            i18n.t('inline.plan294.breathing.use_altitude_simulation_728c5c5e'),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  i18n.t(
                    'inline.plan294.breathing.this_advanced_drill_adds_a_long_exhale_plus_an_e_b6ec519e',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  boltHint,
                  style: Theme.of(dialogContext).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Text(
                  i18n.t(
                    'inline.plan294.breathing.stop_immediately_and_return_to_natural_breathing_9485b3c1',
                  ),
                  style: Theme.of(dialogContext).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(i18n.t('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(i18n.t('inline.plan294.breathing.continue_36efcbe3')),
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
      'sleep_46' || 'sleep_478' => i18n.t(
        'inline.plan294.breathing.next_put_the_screen_away_dim_the_room_and_move_i_1e0ec473',
      ),
      'box_4444' || 'focus_nasal_44' => i18n.t(
        'inline.plan294.breathing.next_begin_the_next_task_now_while_the_rhythm_is_6792f916',
      ),
      'physiological_sigh_216' => i18n.t(
        'inline.plan294.breathing.next_return_to_natural_breathing_for_30_60_secon_59b66ade',
      ),
      _altitudeScenarioId => i18n.t(
        'inline.plan294.breathing.next_let_the_breath_fully_settle_before_deciding_0c97b72e',
      ),
      _ => i18n.t(
        'inline.plan294.breathing.next_give_the_body_half_a_minute_of_quiet_space__82a0b744',
      ),
    };
    return _BreathingSessionSummary(
      title: i18n.t(
        'inline.plan294.breathing.completed_value_a5eefca9',
        params: <String, Object?>{'scenario': _scenario.name.resolve(i18n)},
      ),
      body: i18n.t(
        'inline.plan294.breathing.completed_value_and_about_value_cycles_value_52f6c172',
        params: <String, Object?>{
          'fmtElapsed': _fmt(elapsed),
          'cycles': cycles,
          'scenarioScene': _scenario.scene.resolve(i18n),
        },
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
      _BreathingVoiceAvailability.off => i18n.t(
        'inline.plan294.breathing.voice_guidance_is_off_7b585a90',
      ),
      _BreathingVoiceAvailability.checking => i18n.t(
        'inline.plan294.breathing.checking_voice_resources_8592be85',
      ),
      _BreathingVoiceAvailability.ready => switch (_voiceSourceKind) {
        BreathingCueSourceKind.remote => i18n.t(
          'inline.plan294.breathing.cloud_voice_is_ready_57a78687',
        ),
        BreathingCueSourceKind.asset || null => i18n.t(
          'inline.plan294.breathing.bundled_voice_is_ready_ad8dde21',
        ),
      },
      _BreathingVoiceAvailability.unavailable => i18n.t(
        'inline.plan294.breathing.no_usable_voice_cue_matched_this_scenario_dd320278',
      ),
    };
  }

  String _voiceSubtitle(AppI18n i18n) {
    switch (_voiceAvailability) {
      case _BreathingVoiceAvailability.off:
        return i18n.t(
          'inline.plan294.breathing.text_prompts_and_haptics_still_work_when_voice_i_284e44df',
        );
      case _BreathingVoiceAvailability.checking:
        return i18n.t(
          'inline.plan294.breathing.checking_available_cues_adapting_short_stages_an_91e89833',
        );
      case _BreathingVoiceAvailability.ready:
        final parts = <String>[];
        if (_expectedCueCount > 0) {
          parts.add(
            i18n.t(
              'inline.plan294.breathing.value_value_cues_ready_d186cb84',
              params: <String, Object?>{
                'availableCueCount': _availableCueCount,
                'expectedCueCount': _expectedCueCount,
              },
            ),
          );
        }
        if (_shortStageSilentCount > 0) {
          parts.add(
            i18n.t(
              'inline.plan294.breathing.value_short_stages_stay_silent_to_protect_timing_de7c8705',
              params: <String, Object?>{
                'shortStageSilentCount': _shortStageSilentCount,
              },
            ),
          );
        }
        parts.add(
          i18n.t('inline.plan294.breathing.pause_stays_silent_c855c4a9'),
        );
        return parts.isEmpty
            ? i18n.t(
                'inline.plan294.breathing.voice_guidance_is_available_9dc405c5',
              )
            : parts.join(' · ');
      case _BreathingVoiceAvailability.unavailable:
        return i18n.t(
          'inline.plan294.breathing.use_text_and_haptics_for_now_check_the_voice_ass_0bdfc2e6',
        );
    }
  }

  String _voiceSourceChipLabel(AppI18n i18n) {
    return switch (_voiceSourceKind) {
      BreathingCueSourceKind.remote => i18n.t(
        'inline.plan294.breathing.cloud_cache_fc27eabe',
      ),
      BreathingCueSourceKind.asset ||
      null => i18n.t('inline.plan294.breathing.bundled_abcbb0ae'),
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
              '${stage.label.resolve(i18n)} ${stage.seconds}${i18n.t('toolbox.breathing.seconds_unit')}',
        )
        .join(' · ');
  }

  String _paceLabel(AppI18n i18n) {
    final value = _loopCycleSeconds <= 0 ? 0 : 60 / _loopCycleSeconds;
    final formatted = value >= 10
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return i18n.t(
      'inline.plan294.breathing.value_cycles_min_e897befc',
      params: <String, Object?>{'formatted': formatted},
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
        label: i18n.t('toolbox.breathing.not_tested_yet'),
        body: i18n.t(
          'inline.plan294.breathing.run_one_bolt_check_first_so_you_can_decide_wheth_60a2d6fd',
        ),
        nextStep: i18n.t(
          'inline.plan294.breathing.start_with_lower_intensity_drills_such_as_diaphr_fb0dafff',
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
        label: i18n.t('inline.plan294.breathing.low_bolt_ec90371b'),
        body: i18n.t(
          'inline.plan294.breathing.focus_first_on_nasal_breathing_relaxation_and_ge_6b78cc6e',
        ),
        nextStep: i18n.t(
          'inline.plan294.breathing.stay_with_low_intensity_drills_and_treat_the_fir_6a8b66d3',
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
        label: i18n.t('inline.plan294.breathing.bolt_building_2a9ed7a6'),
        body: i18n.t(
          'inline.plan294.breathing.you_can_start_using_steady_slow_breathing_and_sh_95bbcf39',
        ),
        nextStep: i18n.t(
          'inline.plan294.breathing.build_toward_roughly_20_seconds_before_consideri_275735a2',
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
        label: i18n.t('inline.plan294.breathing.stable_bolt_2ecf7947'),
        body: i18n.t(
          'inline.plan294.breathing.you_can_usually_tolerate_mild_to_moderate_air_hu_d7d401e0',
        ),
        nextStep: i18n.t(
          'inline.plan294.breathing.you_can_sample_altitude_simulation_briefly_but_t_271dd6d1',
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
      label: i18n.t('inline.plan294.breathing.advanced_bolt_bf1f7c51'),
      body: i18n.t(
        'inline.plan294.breathing.you_have_a_solid_tolerance_to_air_hunger_now_so__4450c4f3',
      ),
      nextStep: i18n.t(
        'inline.plan294.breathing.keep_combining_nasal_recovery_work_with_short_ad_e6d7f448',
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
      i18n.t(
        'inline.plan294.breathing.start_with_nasal_and_gentle_breathing_the_mouth__b96d24e3',
      ),
      i18n.t(
        'inline.plan294.breathing.keep_the_breath_quiet_smooth_and_continuous_like_5c2eaaf9',
      ),
      i18n.t(
        'inline.plan294.breathing.for_both_bolt_and_breath_holds_stop_around_the_f_31509086',
      ),
    ];
  }

  List<String> _scenarioTutorialSteps(AppI18n i18n) {
    final steps = <String>[
      for (final entry in _loopStages.asMap().entries)
        '${entry.key + 1}. ${entry.value.label.resolve(i18n)} ${entry.value.seconds}${i18n.t('toolbox.breathing.seconds_unit')}: ${entry.value.prompt.resolve(i18n)}',
    ];
    switch (_scenario.id) {
      case 'diaphragm_4262':
        steps.add(
          i18n.t(
            'inline.plan294.breathing.let_the_belly_drive_the_rhythm_and_keep_the_shou_de37da85',
          ),
        );
        break;
      case 'focus_nasal_44' || 'box_4444':
        steps.add(
          i18n.t(
            'inline.plan294.breathing.keep_the_count_consistent_instead_of_making_the__7c64389f',
          ),
        );
        break;
      case 'sleep_46' || 'sleep_478':
        steps.add(
          i18n.t(
            'inline.plan294.breathing.at_bedtime_smaller_and_quieter_is_better_than_wa_83444abb',
          ),
        );
        break;
      case 'physiological_sigh_216':
        steps.add(
          i18n.t(
            'inline.plan294.breathing.treat_it_as_a_1_2_minute_drill_then_return_to_na_b3075856',
          ),
        );
        break;
      case _altitudeScenarioId:
        steps.add(
          i18n.t(
            'inline.plan294.breathing.in_altitude_simulation_stop_at_the_edge_where_th_b420eb57',
          ),
        );
        break;
      default:
        steps.add(
          i18n.t(
            'inline.plan294.breathing.if_any_phase_starts_to_feel_effortful_or_tight_s_de43f735',
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
      BreathingStageKind.rest => _theme.accent.withValues(alpha: 0.72),
    };
  }

  bool _stageUsesDarkBackground(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  List<Color> _practiceStageGradient(BuildContext context) {
    if (_stageUsesDarkBackground(context)) {
      return <Color>[_theme.bgStart, _theme.bgEnd];
    }
    return <Color>[
      Color.alphaBlend(
        _theme.orbStart.withValues(alpha: 0.18),
        const Color(0xFFFFF3E2),
      ),
      Color.alphaBlend(
        _theme.orbEnd.withValues(alpha: 0.24),
        const Color(0xFFFFD8BB),
      ),
    ];
  }

  Color _practiceStageForeground(BuildContext context) {
    return _stageUsesDarkBackground(context)
        ? Colors.white
        : const Color(0xFF2B211A);
  }

  Color _practiceStageMutedForeground(BuildContext context) {
    return _stageUsesDarkBackground(context)
        ? Colors.white.withValues(alpha: 0.74)
        : const Color(0xFF66524A);
  }

  Color _practiceStagePanelFill(BuildContext context) {
    return _stageUsesDarkBackground(context)
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.white.withValues(alpha: 0.52);
  }

  Color _practiceStagePanelBorder(BuildContext context) {
    return _stageUsesDarkBackground(context)
        ? Colors.white.withValues(alpha: 0.14)
        : const Color(0xFF7A4B2F).withValues(alpha: 0.18);
  }

  Color _readableOn(Color color) {
    return color.computeLuminance() > 0.52
        ? const Color(0xFF172027)
        : Colors.white;
  }

  Widget _buildScenarioSelector(AppI18n i18n) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: BreathingExperienceCatalog.scenarios
          .map(
            (scenario) => BreathingSelectableChip(
              selected: scenario.id == _scenario.id,
              onTap: () => unawaited(_applyScenario(scenario)),
              tint: scenario.id == _scenario.id
                  ? _theme.orbEnd
                  : _theme.orbStart,
              leading: scenario.advanced
                  ? Icon(
                      Icons.bolt_rounded,
                      size: 16,
                      color: scenario.id == _scenario.id
                          ? _theme.orbEnd
                          : _theme.orbStart,
                    )
                  : null,
              label: Text(
                scenario.name.resolve(i18n),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
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
            i18n.t('inline.plan294.breathing.breathing_guide_187d125e'),
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            i18n.t(
              'inline.plan294.breathing.expand_for_research_basis_body_focus_when_to_use_4f1dac47',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          children: <Widget>[
            BreathingInsightTile(
              title: i18n.t('inline.plan294.breathing.research_basis_7ab521bc'),
              body: _scenario.researchBasis.resolve(i18n),
              icon: Icons.science_outlined,
              tint: _theme.orbEnd,
            ),
            const SizedBox(height: 10),
            BreathingInsightTile(
              title: i18n.t('inline.plan294.breathing.how_it_works_7873349c'),
              body: _scenario.mechanism.resolve(i18n),
              icon: Icons.monitor_heart_outlined,
              tint: _theme.orbStart,
            ),
            const SizedBox(height: 12),
            Text(
              i18n.t('inline.plan294.breathing.body_focus_0bfc282f'),
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(_scenario.bodyFocus.resolve(i18n)),
            const SizedBox(height: 10),
            Text(
              i18n.t('inline.plan294.breathing.when_to_use_5a03e079'),
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(_scenario.whenToUse.resolve(i18n)),
            const SizedBox(height: 10),
            Text(
              i18n.t('inline.plan294.breathing.cycle_flow_d49b5ac3'),
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
    return BreathingPanelCard(
      tint: _theme.orbEnd,
      fillAlpha: 0.06,
      borderAlpha: 0.18,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          _theme.orbStart.withValues(alpha: 0.12),
          Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
          _theme.orbEnd.withValues(alpha: 0.08),
        ],
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
                  label: i18n.t('inline.plan294.breathing.advanced_5895a1d0'),
                  color: Theme.of(context).colorScheme.error,
                ),
            ],
          ),
          const SizedBox(height: 14),
          BreathingPanelCard(
            padding: EdgeInsets.zero,
            tint: _theme.orbEnd,
            fillAlpha: 0.05,
            borderAlpha: 0.14,
            radius: 18,
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
                  i18n.t('inline.plan294.breathing.breathing_guide_187d125e'),
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  i18n.t(
                    'inline.plan294.breathing.expand_for_research_basis_body_focus_when_to_use_4f1dac47',
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                children: <Widget>[
                  BreathingInsightTile(
                    title: i18n.t(
                      'inline.plan294.breathing.research_basis_7ab521bc',
                    ),
                    body: _scenario.researchBasis.resolve(i18n),
                    icon: Icons.science_outlined,
                    tint: _theme.orbEnd,
                  ),
                  const SizedBox(height: 10),
                  BreathingInsightTile(
                    title: i18n.t(
                      'inline.plan294.breathing.how_it_works_7873349c',
                    ),
                    body: _scenario.mechanism.resolve(i18n),
                    icon: Icons.monitor_heart_outlined,
                    tint: _theme.orbStart,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    i18n.t('inline.plan294.breathing.body_focus_0bfc282f'),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_scenario.bodyFocus.resolve(i18n)),
                  const SizedBox(height: 10),
                  Text(
                    i18n.t('inline.plan294.breathing.when_to_use_5a03e079'),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_scenario.whenToUse.resolve(i18n)),
                  const SizedBox(height: 12),
                  Text(
                    i18n.t('toolbox.breathing.practice_steps'),
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
                          label: i18n.t(
                            'inline.plan294.breathing.coverage_value_value_20b6e21e',
                            params: <String, Object?>{
                              'availableCueCount': _availableCueCount,
                              'expectedCueCount': _expectedCueCount,
                            },
                          ),
                          color: _theme.orbStart,
                        ),
                      if (_shortStageSilentCount > 0)
                        ScenarioTagChip(
                          label: i18n.t(
                            'inline.plan294.breathing.silent_short_value_267977bd',
                            params: <String, Object?>{
                              'shortStageSilentCount': _shortStageSilentCount,
                            },
                          ),
                          color: _theme.accent,
                        ),
                    ],
                  ),
                  if (_friendlyVoiceLocation().isNotEmpty) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      i18n.t(
                        'inline.plan294.breathing.last_matched_cue_value_b5ab39e2',
                        params: <String, Object?>{
                          'friendlyVoiceLocation': _friendlyVoiceLocation(),
                        },
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    i18n.t('inline.plan294.breathing.cycle_flow_d49b5ac3'),
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
                    i18n.t('inline.plan294.breathing.core_technique_146539d7'),
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
                      ? i18n.t('inline.plan294.breathing.stop_preview_7fb28c98')
                      : i18n.t(
                          'inline.plan294.breathing.preview_guidance_3ef9cb3e',
                        ),
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
                  i18n.t(
                    'inline.plan294.breathing.use_value_min_24233949',
                    params: <String, Object?>{
                      'scenarioRecommendedMinutes':
                          _scenario.recommendedMinutes,
                    },
                  ),
                ),
              ),
            ],
          ),
          if (_scenario.caution != null) ...<Widget>[
            const SizedBox(height: 12),
            SafetyNoteCard(
              title: i18n.t('toolbox.breathing.caution'),
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
        ? '$liveSeconds ${i18n.t('toolbox.breathing.seconds_unit')}'
        : _lastBoltSeconds > 0
        ? '$_lastBoltSeconds ${i18n.t('toolbox.breathing.seconds_unit')}'
        : '--';
    final bestValue = _bestBoltSeconds > 0
        ? '$_bestBoltSeconds ${i18n.t('toolbox.breathing.seconds_unit')}'
        : '--';
    final boltSteps = <String>[
      i18n.t(
        'inline.plan294.breathing.sit_quietly_for_30_60_seconds_first_so_the_breat_5ad70a5c',
      ),
      i18n.t(
        'inline.plan294.breathing.take_a_small_inhale_and_small_exhale_through_the_d1951ee3',
      ),
      i18n.t(
        'inline.plan294.breathing.stop_at_the_first_clear_urge_to_breathe_rather_t_53fccdef',
      ),
      i18n.t(
        'inline.plan294.breathing.recover_with_quiet_nasal_breathing_if_you_need_t_39d1a9a7',
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
                          i18n.t('toolbox.breathing.bolt_test'),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _boltExpanded
                              ? i18n.t(
                                  'inline.plan295.breathing.this_measures_your_comfortable_pause.b6af45648e35',
                                )
                              : i18n.t(
                                  'inline.plan295.breathing.collapsed_by_default_for_a_compact_s.6370f8a32d7a',
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
                label: '${i18n.t('toolbox.breathing.current')} $currentValue',
                color: assessment.tint,
              ),
              ScenarioTagChip(
                label:
                    '${i18n.t('inline.plan294.breathing.band_070340a8')} ${assessment.label}',
                color: _theme.orbEnd,
              ),
              ScenarioTagChip(
                label: '${i18n.t('toolbox.breathing.best')} $bestValue',
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
                      ? i18n.t('toolbox.breathing.preparing')
                      : _boltRunning
                      ? i18n.t('inline.plan294.breathing.save_result_dc50a487')
                      : i18n.t('toolbox.breathing.start_test'),
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
                label: Text(i18n.t('appearanceReset')),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _boltExpanded = !_boltExpanded),
                icon: Icon(
                  _boltExpanded
                      ? Icons.unfold_less_rounded
                      : Icons.unfold_more_rounded,
                ),
                label: Text(
                  _boltExpanded
                      ? i18n.t('inline.plan295.breathing.collapse.0b47184ebf0f')
                      : i18n.t('inline.plan295.breathing.expand.face3cd93c1c'),
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
                    title: _lastBoltSeconds > 0
                        ? i18n.t(
                            'inline.plan295.breathing.interpretation_assessment_label.fc570901e88f',
                            params: <String, Object?>{
                              'assessmentLabel': assessment.label,
                              'assessment.label': assessment.label,
                            },
                          )
                        : i18n.t(
                            'inline.plan295.breathing.how_to_read_bolt.8942d80de46d',
                          ),
                    body: _lastBoltSeconds > 0
                        ? '${assessment.body} ${assessment.nextStep}'
                        : i18n.t(
                            'inline.plan294.breathing.bolt_is_often_used_as_a_rough_read_on_your_curre_149decb3',
                          ),
                    icon: Icons.insights_rounded,
                    tint: assessment.tint,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    i18n.t('toolbox.breathing.test_steps'),
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
                    i18n.t('toolbox.breathing.recommended_drills'),
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
                      i18n.t(
                        'inline.plan294.breathing.this_score_does_not_suggest_going_straight_into__62a21d43',
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
    final remainSession = (_targetDuration - _elapsed).inSeconds.clamp(
      0,
      24 * 3600,
    );
    final stageLabel = _textOn
        ? _stage.label.resolve(i18n)
        : i18n.t('inline.plan294.breathing.follow_the_orb_faac40d5');
    final stagePrompt = _textOn
        ? _stage.prompt.resolve(i18n)
        : i18n.t('inline.plan294.breathing.keep_the_breath_natural_a64ed4b6');
    final stageGradient = _practiceStageGradient(context);
    final stageForeground = _practiceStageForeground(context);
    final stageMutedForeground = _practiceStageMutedForeground(context);
    final stagePanelFill = _practiceStagePanelFill(context);
    final stagePanelBorder = _practiceStagePanelBorder(context);
    final orbTextColor = _readableOn(_theme.orbEnd);
    final orbMutedTextColor = orbTextColor.withValues(alpha: 0.78);
    final primaryControlColor = _stageUsesDarkBackground(context)
        ? _theme.accent
        : Color.alphaBlend(
            _theme.orbEnd.withValues(alpha: 0.64),
            const Color(0xFF8B4E33),
          );
    final primaryControlForeground = _readableOn(primaryControlColor);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: stageGradient,
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
                    color: stageForeground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              BreathingMetricPill(
                label: i18n.t('inline.plan294.breathing.cycle_1ca94239'),
                value: i18n.t(
                  'inline.ui.pages.toolbox_breathing_tool.loopcycleseconds_s_0c3e97',
                  params: <String, Object?>{
                    'loopCycleSeconds': _loopCycleSeconds,
                  },
                ),
                foregroundColor: stageForeground,
                mutedForegroundColor: stageMutedForeground,
                fillColor: stagePanelFill,
                borderColor: stagePanelBorder,
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
                                            color: orbTextColor,
                                            size: iconSize,
                                          ),
                                          SizedBox(height: compact ? 4 : 8),
                                          Text(
                                            stageLabel,
                                            style: labelStyle?.copyWith(
                                              color: orbTextColor,
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
                                                color: orbMutedTextColor,
                                                fontWeight: FontWeight.w600,
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
                        i18n.t(
                          'inline.plan294.breathing.value_s_left_round_value_next_value_43938d7c',
                          params: <String, Object?>{
                            'remainStage': math
                                .max(
                                  0,
                                  (_stage.seconds * (1 - _controller.value))
                                      .ceil(),
                                )
                                .toInt(),
                            'rounds': _rounds + 1,
                            'nextStageLabel':
                                _loopStages[(_stageIndex + 1) %
                                        _loopStages.length]
                                    .label
                                    .resolve(i18n),
                          },
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: stageMutedForeground,
                          fontWeight: FontWeight.w600,
                        ),
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
            foregroundColor: stageForeground,
            mutedForegroundColor: stageMutedForeground,
            inactiveFillColor: stagePanelFill,
            inactiveBorderColor: stagePanelBorder,
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: _targetProgress,
              backgroundColor: stagePanelFill,
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
                label: i18n.t('toolbox.breathing.target'),
                value: i18n.t(
                  'inline.ui.pages.toolbox_breathing_tool.targetminutes_min_029964',
                  params: <String, Object?>{'targetMinutes': _targetMinutes},
                ),
                foregroundColor: stageForeground,
                mutedForegroundColor: stageMutedForeground,
                fillColor: stagePanelFill,
                borderColor: stagePanelBorder,
              ),
              BreathingMetricPill(
                label: i18n.t('inline.plan294.breathing.done_fe297e5a'),
                value: _fmt(_elapsed),
                foregroundColor: stageForeground,
                mutedForegroundColor: stageMutedForeground,
                fillColor: stagePanelFill,
                borderColor: stagePanelBorder,
              ),
              BreathingMetricPill(
                label: i18n.t('inline.plan294.breathing.left_a0d89e6f'),
                value:
                    '${remainSession ~/ 60}:${(remainSession % 60).toString().padLeft(2, '0')}',
                foregroundColor: stageForeground,
                mutedForegroundColor: stageMutedForeground,
                fillColor: stagePanelFill,
                borderColor: stagePanelBorder,
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
                style: FilledButton.styleFrom(
                  backgroundColor: primaryControlColor,
                  foregroundColor: primaryControlForeground,
                  disabledBackgroundColor: primaryControlColor.withValues(
                    alpha: 0.36,
                  ),
                  disabledForegroundColor: primaryControlForeground.withValues(
                    alpha: 0.58,
                  ),
                ),
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
                      ? i18n.t('toolbox.breathing.preparing')
                      : _running
                      ? i18n.t('inline.plan294.breathing.pause_b6fe36b8')
                      : i18n.t('toolbox.breathing.start'),
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: stageForeground,
                  backgroundColor: stagePanelFill,
                  side: BorderSide(color: stagePanelBorder),
                ),
                onPressed: _sessionPreparing
                    ? null
                    : () => unawaited(_skipStage()),
                icon: const Icon(Icons.skip_next_rounded),
                label: Text(i18n.t('toolbox.breathing.next_stage')),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: stageForeground,
                  backgroundColor: stagePanelFill,
                  side: BorderSide(color: stagePanelBorder),
                ),
                onPressed: _sessionPreparing
                    ? null
                    : () => unawaited(_resetSession()),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(i18n.t('appearanceReset')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, AppI18n i18n) {
    return BreathingPanelCard(
      tint: _theme.orbStart,
      fillAlpha: 0.05,
      borderAlpha: 0.14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            i18n.t('inline.plan294.breathing.session_setup_0a4f32d7'),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            i18n.t('appearanceThemeTitle'),
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
                  (theme) => BreathingSelectableChip(
                    selected: theme.id == _theme.id,
                    onTap: () {
                      setState(() => _theme = theme);
                      _savePrefs();
                    },
                    tint: theme.orbEnd,
                    label: Text(theme.name.resolve(i18n)),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
          Text(
            i18n.t('inline.plan294.breathing.duration_7b90564f'),
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
                  (minutes) => BreathingSelectableChip(
                    selected: _targetMinutes == minutes,
                    onTap: () {
                      setState(() => _targetMinutes = minutes);
                      _savePrefs();
                    },
                    tint: _theme.accent,
                    label: Text(
                      i18n.t(
                        'inline.ui.pages.toolbox_breathing_tool.minutes_min_373b41',
                        params: <String, Object?>{'minutes': minutes},
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 8),
          Material(
            type: MaterialType.transparency,
            child: Column(
              children: <Widget>[
                SwitchListTile.adaptive(
                  value: _includeHoldStage,
                  onChanged: (value) => unawaited(_setIncludeHoldStage(value)),
                  title: Text(i18n.t('toolbox.breathing.breath_hold_stage')),
                  subtitle: Text(
                    i18n.t(
                      'inline.plan294.breathing.on_by_default_turn_this_off_to_skip_all_hold_pha_51f0422b',
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile.adaptive(
                  value: _includeRecoveryStage,
                  onChanged: (value) =>
                      unawaited(_setIncludeRecoveryStage(value)),
                  title: Text(
                    i18n.t('inline.plan294.breathing.recovery_stage_25591247'),
                  ),
                  subtitle: Text(
                    i18n.t(
                      'inline.plan294.breathing.when_off_the_loop_keeps_only_the_main_breathing__90b5dbd6',
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile.adaptive(
                  value: _voiceOn,
                  onChanged: (value) => unawaited(_setVoiceEnabled(value)),
                  title: Text(i18n.t('toolbox.breathing.voice_cues')),
                  subtitle: Text(
                    i18n.t(
                      'inline.plan294.breathing.cloud_cues_are_downloaded_and_cached_first_voice_d82f5299',
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
                  title: Text(
                    i18n.t('inline.plan294.breathing.text_cues_2c05233d'),
                  ),
                  subtitle: Text(
                    i18n.t(
                      'inline.plan294.breathing.show_the_current_action_body_prompt_and_countdow_80d08090',
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
                  title: Text(
                    i18n.t('inline.plan294.breathing.haptics_b2ca72e4'),
                  ),
                  subtitle: Text(
                    i18n.t(
                      'inline.plan294.breathing.adds_subtle_pulses_on_stage_changes_so_you_can_f_f66b095f',
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
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
              title: i18n.t(
                'inline.plan294.breathing.breathing_scenarios_516fd8a0',
              ),
              subtitle: i18n.t(
                'inline.plan294.breathing.optimized_for_mobile_cleaned_copy_improved_narro_b34cae79',
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
                  label: i18n.t('inline.plan294.breathing.rounds_06b0afec'),
                  value: '$_rounds',
                ),
                ToolboxMetricCard(
                  label: i18n.t('inline.plan294.breathing.sessions_56f23224'),
                  value: '$_completedSessions',
                ),
                ToolboxMetricCard(
                  label: i18n.t('inline.plan294.breathing.total_time_edee2084'),
                  value: _fmt(Duration(seconds: _totalSeconds)),
                ),
                ToolboxMetricCard(
                  label: i18n.t('inline.plan294.breathing.voice_e0595c4f'),
                  value: _voiceSourceChipLabel(i18n),
                ),
                ToolboxMetricCard(
                  label: i18n.t('toolbox.breathing.bolt'),
                  value: _lastBoltSeconds > 0
                      ? '$_lastBoltSeconds ${i18n.t('toolbox.breathing.seconds_unit')}'
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
              title: i18n.t('inline.plan294.breathing.safety_note_e100b974'),
              body: i18n.t(
                'inline.plan294.breathing.do_not_use_while_driving_or_in_any_situation_tha_abad4d6c',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
