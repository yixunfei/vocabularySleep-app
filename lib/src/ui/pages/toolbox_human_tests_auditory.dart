part of 'toolbox_human_tests.dart';

enum _AuditoryMode { frequency, sensitivity, spatial }

enum _AuditoryPhase { idle, waiting, cue, done }

enum _AuditoryRhythm { steady, doublePulse, triplePulse, rising }

enum _SpatialInputMode { pad, pointer }

class AuditoryReactionTestPage extends StatelessWidget {
  const AuditoryReactionTestPage({super.key});

  static const Color _accent = Color(0xFF6E9BC3);

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory.auditory_test_65f8f1',
      ),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory.use_frequency_volume_and_direction_tasks_to_observe_how_8a234a',
      ),
      accent: _accent,
      icon: Icons.hearing_rounded,
      status: i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory.next_wear_headphones_choose_a_mode_and_start_a_hearing_t_32f23e',
      ),
      child: const AuditoryLabPanel(),
    );
  }
}

class _AuditoryModeCopy {
  const _AuditoryModeCopy({
    required this.labelKey,
    required this.descriptionKey,
    required this.icon,
  });

  final String labelKey;
  final String descriptionKey;
  final IconData icon;

  String label(AppI18n i18n) => i18n.t(labelKey);

  String description(AppI18n i18n) => i18n.t(descriptionKey);
}

class _AuditoryStimulusSpec {
  const _AuditoryStimulusSpec({
    required this.id,
    required this.mode,
    required this.labelKey,
    this.labelParams = const <String, Object?>{},
    required this.frequencyHz,
    this.frequencyEndHz,
    required this.outputVolume,
    this.outputVolumeEnd,
    required this.pan,
    required this.rhythm,
    required this.durationMs,
    this.directionDegrees,
  });

  final String id;
  final _AuditoryMode mode;
  final String labelKey;
  final Map<String, Object?> labelParams;
  final double frequencyHz;
  final double? frequencyEndHz;
  final double outputVolume;
  final double? outputVolumeEnd;
  final double pan;
  final _AuditoryRhythm rhythm;
  final int durationMs;
  final double? directionDegrees;

  String get cacheKey =>
      '$id-${frequencyHz.round()}-${(outputVolume * 1000).round()}-'
      '${(frequencyEndHz ?? frequencyHz).round()}-'
      '${((outputVolumeEnd ?? outputVolume) * 1000).round()}-'
      '${(pan * 1000).round()}-${rhythm.name}-$durationMs';
}

class _AuditoryRecord {
  const _AuditoryRecord({
    required this.mode,
    required this.labelKey,
    this.labelParams = const <String, Object?>{},
    required this.frequencyHz,
    required this.outputVolume,
    required this.rhythm,
    required this.heard,
    required this.correct,
    required this.milliseconds,
    this.falseStart = false,
    this.directionDegrees,
    this.guessDegrees,
    this.angleError,
  });

  final _AuditoryMode mode;
  final String labelKey;
  final Map<String, Object?> labelParams;
  final double frequencyHz;
  final double outputVolume;
  final _AuditoryRhythm rhythm;
  final bool heard;
  final bool correct;
  final int milliseconds;
  final bool falseStart;
  final double? directionDegrees;
  final double? guessDegrees;
  final double? angleError;

  String label(AppI18n i18n) => i18n.t(labelKey, params: labelParams);
}

class _AuditoryTestCard extends StatefulWidget {
  const _AuditoryTestCard();

  @override
  State<_AuditoryTestCard> createState() => _AuditoryTestCardState();
}

class _AuditoryTestCardState extends State<_AuditoryTestCard> {
  static const Color _accent = AuditoryReactionTestPage._accent;
  static final AppLogService _log = AppLogService.instance;
  static const List<_AuditoryMode> _modeOrder = <_AuditoryMode>[
    _AuditoryMode.frequency,
    _AuditoryMode.sensitivity,
    _AuditoryMode.spatial,
  ];
  static const Map<_AuditoryMode, _AuditoryModeCopy>
  _modeCopies = <_AuditoryMode, _AuditoryModeCopy>{
    _AuditoryMode.frequency: _AuditoryModeCopy(
      labelKey:
          'inline.plan297.human_tests.auditory.mode.label.frequency.5239dcfa76',
      descriptionKey:
          'inline.plan297.human_tests.auditory.mode.description.hear_varied_frequencies_and_rhythmic_loudness_tap_wh.60c3127ea0',
      icon: Icons.graphic_eq_rounded,
    ),
    _AuditoryMode.sensitivity: _AuditoryModeCopy(
      labelKey:
          'inline.plan297.human_tests.auditory.mode.label.sensitivity.e9177d11c0',
      descriptionKey:
          'inline.plan297.human_tests.auditory.mode.description.check_audible_volume_levels_around_a_selected_base_f.834dfffd51',
      icon: Icons.volume_up_rounded,
    ),
    _AuditoryMode.spatial: _AuditoryModeCopy(
      labelKey:
          'inline.plan297.human_tests.auditory.mode.label.spatial.9f1665885a',
      descriptionKey:
          'inline.plan297.human_tests.auditory.mode.description.localize_the_sound_direction_and_mark_the_perceived_.974ce1b242',
      icon: Icons.explore_rounded,
    ),
  };
  static const List<double> _baseFrequencies = <double>[
    250,
    500,
    1000,
    2000,
    4000,
  ];
  static final AudioContext _audioContext = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
  ).build();

  final math.Random _random = math.Random();
  final Stopwatch _stopwatch = Stopwatch();
  final AudioPlayer _player = AudioPlayer();
  final Map<String, Uint8List> _toneCache = <String, Uint8List>{};
  final Map<String, String> _tonePathCache = <String, String>{};
  final List<_AuditoryRecord> _records = <_AuditoryRecord>[];

  List<_AuditoryStimulusSpec> _sessionStimuli = <_AuditoryStimulusSpec>[];
  Timer? _signalTimer;
  Timer? _timeoutTimer;
  Timer? _transitionTimer;
  int _token = 0;
  int _playbackSerial = 0;
  bool _audioConfigured = false;
  Future<void> _pendingPlaybackSilence = Future<void>.value();

  _AuditoryMode _mode = _AuditoryMode.frequency;
  _AuditoryPhase _phase = _AuditoryPhase.idle;
  _AuditoryStimulusSpec? _currentStimulus;
  int _roundCount = 10;
  int _roundIndex = 0;
  int _waitingSeed = 0;
  int _bestStreak = 0;
  int _streak = 0;
  int _falseStarts = 0;
  bool _playbackError = false;
  bool? _lastCorrect;

  RangeValues _frequencyRange = const RangeValues(125, 8000);
  int _analysisBands = 16;
  double _frequencyVolumeScale = 0.72;
  double _rhythmDepth = 0.52;
  bool _includeRhythmPatterns = true;

  double _sensitivityBaseFrequency = 1000;
  int _sensitivityLevelCount = 12;
  double _minimumOutput = 0.06;
  double _maximumOutput = 0.72;
  bool _logSensitivitySteps = true;

  int _directionCount = 8;
  double _spatialVolume = 0.76;
  double _spatialTolerance = 22;
  double _spatialSmoothing = 0.35;
  _SpatialInputMode _spatialInputMode = _SpatialInputMode.pad;
  bool _customSpatialDirection = false;
  double _customDirectionDegrees = 90;
  double? _spatialGuessDegrees;
  bool _showDirectionLabels = true;

  int _toneDurationMs = 920;
  int _responseWindowMs = 3800;
  bool _allowReplay = true;
  bool _showGroupReport = true;
  bool _showRawData = false;
  bool _autoReport = true;

  bool get _isWindowsDesktop =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  bool get _busy =>
      _phase == _AuditoryPhase.waiting || _phase == _AuditoryPhase.cue;

  double get _spatialDisplayDegrees => _spatialGuessDegrees ?? 90;

  bool get _hasSpatialGuess => _spatialGuessDegrees != null;

  bool get _sessionRunning =>
      _sessionStimuli.isNotEmpty &&
      _phase != _AuditoryPhase.done &&
      _roundIndex < _sessionStimuli.length;

  bool get _canPlayDemoAudio => !_busy && !_sessionRunning;

  int get _targetRoundCount =>
      _sessionStimuli.isEmpty ? _roundCountFor(_mode) : _sessionStimuli.length;

  int get _misses => _records.where((record) => !record.correct).length;

  double get _scoreRatio {
    if (_records.isEmpty) {
      return 0;
    }
    return _records.where((record) => record.correct).length / _records.length;
  }

  int get _averageMs {
    final timingRecords = _records
        .where((record) => !record.falseStart && record.milliseconds > 0)
        .toList(growable: false);
    if (timingRecords.isEmpty) {
      return 0;
    }
    final total = timingRecords.fold<int>(
      0,
      (sum, record) => sum + record.milliseconds,
    );
    return (total / timingRecords.length).round();
  }

  double get _averageSpatialError {
    final errors = _records
        .map((record) => record.angleError)
        .whereType<double>()
        .toList(growable: false);
    if (errors.isEmpty) {
      return 0;
    }
    return errors.fold<double>(0, (sum, value) => sum + value) / errors.length;
  }

  static const Duration _playbackAdvanceTimeout = Duration(milliseconds: 320);
  static const Duration _playbackAdvancePollInterval = Duration(
    milliseconds: 40,
  );
  static const Duration _slowPlaybackStepThreshold = Duration(
    milliseconds: 220,
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _token += 1;
    _playbackSerial += 1;
    _signalTimer?.cancel();
    _timeoutTimer?.cancel();
    _transitionTimer?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    unawaited(_player.dispose());
    super.dispose();
  }

  void _start() {
    _reset(clearMode: false);
    setState(() {
      _sessionStimuli = _buildSessionStimuli();
    });
    _scheduleRound();
  }

  void _reset({bool clearMode = false}) {
    _token += 1;
    _playbackSerial += 1;
    _signalTimer?.cancel();
    _timeoutTimer?.cancel();
    _transitionTimer?.cancel();
    _queuePlaybackSilence(reason: 'reset');
    _stopwatch
      ..stop()
      ..reset();
    setState(() {
      if (clearMode) {
        _mode = _AuditoryMode.frequency;
      }
      _records.clear();
      _roundIndex = 0;
      _bestStreak = 0;
      _streak = 0;
      _falseStarts = 0;
      _playbackError = false;
      _lastCorrect = null;
      _currentStimulus = null;
      _phase = _AuditoryPhase.idle;
      _sessionStimuli = <_AuditoryStimulusSpec>[];
      _spatialGuessDegrees = null;
    });
  }

  List<_AuditoryStimulusSpec> _buildSessionStimuli() {
    return switch (_mode) {
      _AuditoryMode.frequency => _frequencySequence(),
      _AuditoryMode.sensitivity => _sensitivitySequence(),
      _AuditoryMode.spatial => _spatialSequence(),
    };
  }

  _AuditoryStimulusSpec _previewStimulusForMode(_AuditoryMode mode) {
    final stimuli = switch (mode) {
      _AuditoryMode.frequency => _frequencySequence(),
      _AuditoryMode.sensitivity => _sensitivitySequence(),
      _AuditoryMode.spatial => _spatialSequence(),
    };
    if (stimuli.isEmpty) {
      return _AuditoryStimulusSpec(
        id: 'preview-empty',
        mode: mode,
        labelKey: 'inline.plan297.human_tests.auditory.stimulus.preview',
        frequencyHz: 1000,
        outputVolume: 0.7,
        pan: 0,
        rhythm: _AuditoryRhythm.steady,
        durationMs: _toneDurationMs,
      );
    }
    return stimuli[stimuli.length ~/ 2];
  }

  int _scheduledDelayFor(_AuditoryStimulusSpec spec) {
    final rhythmPenalty = switch (spec.rhythm) {
      _AuditoryRhythm.steady => 0,
      _AuditoryRhythm.doublePulse => 120,
      _AuditoryRhythm.triplePulse => 170,
      _AuditoryRhythm.rising => 210,
    };
    final baseDelay = switch (_mode) {
      _AuditoryMode.frequency => 1160,
      _AuditoryMode.sensitivity => 1000,
      _AuditoryMode.spatial => 900,
    };
    final jitter = _random.nextInt(900);
    final softJitter = _random.nextInt(180) - 60;
    return (baseDelay + rhythmPenalty + jitter + softJitter)
        .clamp(760, 3000)
        .toInt();
  }

  List<_AuditoryStimulusSpec> _frequencySequence() {
    final count = _roundCountFor(_AuditoryMode.frequency);
    final start = math.max(80.0, _frequencyRange.start.clamp(60.0, 12000.0));
    final end = math.max(
      start + 150,
      _frequencyRange.end.clamp(start + 150, 12000.0),
    );
    final startLog = math.log(start);
    final endLog = math.log(end);
    final stimuli = List<_AuditoryStimulusSpec>.generate(count, (index) {
      final progress = count <= 1 ? 0.0 : index / (count - 1);
      final eased = progress < 0.5
          ? math.pow(progress / 0.5, 1.12).toDouble() * 0.48
          : 0.48 + math.pow((progress - 0.5) / 0.5, 0.78).toDouble() * 0.52;
      final frequency = math.exp(startLog + (endLog - startLog) * eased);
      final tailStart = (count * 0.58).floor();
      final tailProgress = index >= tailStart && count - tailStart > 1
          ? (index - tailStart) / (count - tailStart - 1)
          : 0.0;
      final sweepEnd = index >= tailStart
          ? end * (0.84 + tailProgress * 0.16)
          : frequency * (1.01 + progress * 0.04);
      final outputVolume =
          (_frequencyVolumeScale *
                  (0.64 + progress * 0.24 + tailProgress * 0.12))
              .clamp(0.06, 1.0)
              .toDouble();
      final outputVolumeEnd = (outputVolume * (1.03 + progress * 0.05))
          .clamp(0.06, 1.0)
          .toDouble();
      final rhythm = !_includeRhythmPatterns
          ? _AuditoryRhythm.steady
          : progress < 0.24
          ? _AuditoryRhythm.steady
          : progress < 0.52
          ? _AuditoryRhythm.doublePulse
          : progress < 0.82
          ? _AuditoryRhythm.triplePulse
          : _AuditoryRhythm.rising;
      final durationMs = (_toneDurationMs + (progress * 520).round())
          .clamp(780, 2200)
          .toInt();
      return _AuditoryStimulusSpec(
        id: 'frequency-$index',
        mode: _AuditoryMode.frequency,
        labelKey: 'inline.plan297.human_tests.auditory.stimulus.frequency_step',
        labelParams: <String, Object?>{'p0': _formatFrequency(frequency)},
        frequencyHz: frequency,
        frequencyEndHz: sweepEnd,
        outputVolume: outputVolume,
        outputVolumeEnd: outputVolumeEnd,
        pan: 0,
        rhythm: rhythm,
        durationMs: durationMs,
      );
    });
    stimuli.shuffle(_random);
    return stimuli;
  }

  List<_AuditoryStimulusSpec> _sensitivitySequence() {
    final count = _roundCountFor(_AuditoryMode.sensitivity);
    final levels = _sensitivityLevels();
    if (levels.isEmpty) {
      return const <_AuditoryStimulusSpec>[];
    }
    final sequence = <double>[];
    var pass = 0;
    while (sequence.length < count) {
      final currentLevels = pass.isEven
          ? levels
          : levels.reversed.toList(growable: false);
      for (
        var index = 0;
        index < currentLevels.length && sequence.length < count;
        index++
      ) {
        final level = currentLevels[index];
        sequence.add(level);
        final isThresholdBand =
            index < math.max(3, levels.length ~/ 3) ||
            index == levels.length ~/ 2 ||
            index >= levels.length - 3;
        if (isThresholdBand || (pass > 0 && index.isEven)) {
          sequence.add(level);
        }
      }
      pass += 1;
    }
    while (sequence.length < count) {
      sequence.add(sequence.last);
    }
    final stimuli = sequence
        .take(count)
        .toList(growable: false)
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key;
          final level = entry.value;
          final normalized = count <= 1 ? 0.0 : index / (count - 1);
          final durationMs =
              (_toneDurationMs + ((1 - normalized) * 280).round())
                  .clamp(760, 1600)
                  .toInt();
          return _AuditoryStimulusSpec(
            id: 'sensitivity-$index',
            mode: _AuditoryMode.sensitivity,
            labelKey:
                'inline.plan297.human_tests.auditory.stimulus.sensitivity_step',
            labelParams: <String, Object?>{'p0': (level * 100).round()},
            frequencyHz: _sensitivityBaseFrequency,
            outputVolume: level,
            outputVolumeEnd: null,
            pan: 0,
            rhythm: _AuditoryRhythm.steady,
            durationMs: durationMs,
          );
        })
        .toList(growable: false);
    stimuli.shuffle(_random);
    return stimuli;
  }

  List<_AuditoryStimulusSpec> _spatialSequence() {
    final count = _roundCountFor(_AuditoryMode.spatial);
    final targets = _spatialTargetAngles();
    final angles = <double>[];
    while (angles.length < count) {
      angles.add(targets[angles.length % targets.length]);
    }
    final shuffledAngles = List<double>.from(angles.take(count));
    if (!_customSpatialDirection) {
      shuffledAngles.shuffle(_random);
    }
    return shuffledAngles
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key;
          final angle = entry.value % 360;
          final normalized = angle % 360;
          final frontBackBias = math
              .cos(normalized / 180 * math.pi)
              .clamp(-1.0, 1.0)
              .toDouble();
          final sideBias = math
              .sin(normalized / 180 * math.pi)
              .clamp(-1.0, 1.0)
              .toDouble();
          final pan = (sideBias * 0.88).clamp(-1.0, 1.0).toDouble();
          final frequency = 920.0 + frontBackBias * 90 + (index % 3) * 14;
          return _AuditoryStimulusSpec(
            id: 'spatial-$index-${angle.round()}',
            mode: _AuditoryMode.spatial,
            labelKey: 'inline.plan297.human_tests.auditory.stimulus.degrees',
            labelParams: <String, Object?>{'p0': angle.round()},
            frequencyHz: frequency,
            frequencyEndHz: frequency * (frontBackBias > 0 ? 1.04 : 0.96),
            outputVolume:
                (_spatialVolume *
                        (0.88 + index / math.max(1, count - 1) * 0.12))
                    .clamp(0.1, 1.0)
                    .toDouble(),
            outputVolumeEnd: (_spatialVolume * 0.9).clamp(0.08, 1.0).toDouble(),
            pan: pan,
            rhythm: index % 4 == 0
                ? _AuditoryRhythm.doublePulse
                : _AuditoryRhythm.steady,
            durationMs: (_toneDurationMs + (index % 2 == 0 ? 120 : 60))
                .clamp(760, 1800)
                .toInt(),
            directionDegrees: normalized,
          );
        })
        .toList(growable: false);
  }

  List<double> _spatialTargetAngles() {
    if (_customSpatialDirection) {
      return <double>[_customDirectionDegrees % 360];
    }
    if (_spatialInputMode == _SpatialInputMode.pad) {
      return <double>[0, 45, 90, 135, 180, 225, 270, 315];
    }
    return _directionAngles();
  }

  void _setMode(_AuditoryMode mode) {
    if (_mode == mode) {
      return;
    }
    setState(() => _mode = mode);
    _reset(clearMode: false);
  }

  (int, int) _roundBoundsFor(_AuditoryMode mode) {
    return switch (mode) {
      _AuditoryMode.frequency => (10, 40),
      _AuditoryMode.sensitivity => (10, 40),
      _AuditoryMode.spatial => (10, 32),
    };
  }

  int _roundCountFor(_AuditoryMode mode) {
    final bounds = _roundBoundsFor(mode);
    return _roundCount.clamp(bounds.$1, bounds.$2).toInt();
  }

  void _scheduleRound() {
    if (!mounted) {
      return;
    }
    if (_sessionStimuli.isEmpty) {
      _sessionStimuli = _buildSessionStimuli();
    }
    if (_roundIndex >= _sessionStimuli.length) {
      _finish();
      return;
    }
    final token = ++_token;
    _signalTimer?.cancel();
    _timeoutTimer?.cancel();
    _transitionTimer?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    final current = _sessionStimuli[_roundIndex];
    setState(() {
      _phase = _AuditoryPhase.waiting;
      _lastCorrect = null;
      _currentStimulus = current;
      _waitingSeed = _random.nextInt(1 << 31);
      if (_mode == _AuditoryMode.spatial) {
        _spatialGuessDegrees = null;
      }
    });
    unawaited(_prepareStimulus(current).then<void>((_) {}, onError: (_) {}));
    final delayMs = _scheduledDelayFor(current);
    _signalTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted || token != _token || _phase != _AuditoryPhase.waiting) {
        return;
      }
      unawaited(_emitCue(token));
    });
  }

  Future<void> _emitCue(int token) async {
    final stimulus = _currentStimulus;
    if (stimulus == null) {
      return;
    }
    if (!mounted || token != _token || _phase != _AuditoryPhase.waiting) {
      return;
    }
    await _playStimulus(stimulus);
    if (!mounted || token != _token || _phase != _AuditoryPhase.waiting) {
      return;
    }
    _stopwatch
      ..reset()
      ..start();
    setState(() => _phase = _AuditoryPhase.cue);
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(Duration(milliseconds: _responseWindowMs), () {
      if (!mounted || token != _token || _phase != _AuditoryPhase.cue) {
        return;
      }
      _recordCurrent(
        heard: false,
        correct: false,
        milliseconds: _responseWindowMs,
      );
    });
  }

  Future<void> _ensureAudioConfigured() async {
    if (_audioConfigured) {
      return;
    }
    await _player.setPlayerMode(PlayerMode.mediaPlayer);
    if (!_isWindowsDesktop) {
      await _player.setAudioContext(_audioContext);
    }
    await _player.setReleaseMode(ReleaseMode.release);
    _audioConfigured = true;
  }

  Map<String, Object?> _playbackLogData({
    _AuditoryStimulusSpec? spec,
    required int serial,
    int? attempt,
    String? step,
    String? reason,
    String? sourcePath,
    String? state,
    int? elapsedMs,
  }) {
    final data = <String, Object?>{
      'playerId': _player.playerId,
      'serial': serial,
    };
    if (step != null) data['step'] = step;
    if (reason != null) data['reason'] = reason;
    if (attempt != null) data['attempt'] = attempt;
    if (sourcePath != null) data['path'] = sourcePath;
    if (state != null) data['state'] = state;
    if (elapsedMs != null) data['elapsedMs'] = elapsedMs;
    if (spec != null) {
      data
        ..['mode'] = spec.mode.name
        ..['id'] = spec.id
        ..['frequencyHz'] = spec.frequencyHz
        ..['pan'] = spec.pan
        ..['rhythm'] = spec.rhythm.name;
    }
    return data;
  }

  void _logPlaybackStepTiming({
    required String step,
    required int serial,
    required int elapsedMs,
    _AuditoryStimulusSpec? spec,
    int? attempt,
    String? sourcePath,
    String? reason,
    String? state,
  }) {
    if (!_isWindowsDesktop &&
        elapsedMs < _slowPlaybackStepThreshold.inMilliseconds) {
      return;
    }
    _log.d(
      'human_tests_auditory',
      'playback step timing',
      data: _playbackLogData(
        spec: spec,
        serial: serial,
        attempt: attempt,
        step: step,
        reason: reason,
        sourcePath: sourcePath,
        state: state,
        elapsedMs: elapsedMs,
      ),
    );
  }

  Future<T> _tracePlaybackStep<T>(
    String step,
    Future<T> Function() action, {
    _AuditoryStimulusSpec? spec,
    required int serial,
    int? attempt,
    String? sourcePath,
    String? reason,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await action();
      stopwatch.stop();
      _logPlaybackStepTiming(
        step: step,
        spec: spec,
        serial: serial,
        attempt: attempt,
        sourcePath: sourcePath,
        reason: reason,
        elapsedMs: stopwatch.elapsedMilliseconds,
        state: _player.state.name,
      );
      return result;
    } catch (error) {
      stopwatch.stop();
      final data = _playbackLogData(
        spec: spec,
        serial: serial,
        attempt: attempt,
        step: step,
        reason: reason,
        sourcePath: sourcePath,
        state: _player.state.name,
        elapsedMs: stopwatch.elapsedMilliseconds,
      );
      data['error'] = '$error';
      _log.w('human_tests_auditory', 'playback step failed', data: data);
      rethrow;
    }
  }

  Future<void> _awaitPendingPlaybackSilence() async {
    while (true) {
      final pending = _pendingPlaybackSilence;
      try {
        await pending;
      } catch (_) {}
      if (identical(pending, _pendingPlaybackSilence)) {
        return;
      }
    }
  }

  void _queuePlaybackSilence({required String reason}) {
    final serial = _playbackSerial;
    final state = _player.state;
    if (state != PlayerState.playing) {
      if (_isWindowsDesktop) {
        _log.d(
          'human_tests_auditory',
          'playback silence skipped',
          data: _playbackLogData(
            serial: serial,
            reason: reason,
            state: state.name,
          ),
        );
      }
      return;
    }
    final next = _pendingPlaybackSilence.catchError((_) {}).then((_) async {
      await _tracePlaybackStep(
        'pause',
        () => _player.pause(),
        serial: serial,
        reason: reason,
      );
    });
    _pendingPlaybackSilence = next.catchError((_) {});
    unawaited(_pendingPlaybackSilence);
  }

  Uint8List _toneBytesFor(_AuditoryStimulusSpec spec) {
    if (_toneCache.length > 96) {
      _toneCache.clear();
      _tonePathCache.clear();
    }
    return _toneCache.putIfAbsent(
      spec.cacheKey,
      () => _buildToneBytes(spec, rhythmDepth: _rhythmDepth),
    );
  }

  Future<String> _prepareStimulus(_AuditoryStimulusSpec spec) async {
    final cachedPath = _tonePathCache[spec.cacheKey];
    if (cachedPath != null) {
      return cachedPath;
    }
    final bytes = _toneBytesFor(spec);
    final path = await AudioPlayerSourceHelper.tempFilePathForBytes(
      bytes,
      mimeType: 'audio/wav',
      data: <String, Object?>{
        'sourcePath': 'human_tests_auditory_${spec.cacheKey}.wav',
      },
    );
    _tonePathCache[spec.cacheKey] = path;
    return path;
  }

  Future<void> _playStimulus(_AuditoryStimulusSpec spec) async {
    final serial = ++_playbackSerial;
    try {
      await _ensureAudioConfigured();
      if (!mounted || serial != _playbackSerial) {
        return;
      }
      await _awaitPendingPlaybackSilence();
      if (!mounted || serial != _playbackSerial) {
        return;
      }
      if (_player.state == PlayerState.playing) {
        await _tracePlaybackStep(
          'pause_before_source',
          () => _player.pause(),
          spec: spec,
          serial: serial,
          reason: 'refresh_source',
        );
      }
      final sourcePath = await _tracePlaybackStep(
        'prepare_stimulus',
        () => _prepareStimulus(spec),
        spec: spec,
        serial: serial,
      );
      if (!mounted || serial != _playbackSerial) {
        return;
      }
      await _preparePlaybackSource(
        spec,
        sourcePath,
        serial: serial,
        attempt: 1,
      );
      final started = await _startPlaybackAndVerify(
        spec,
        sourcePath,
        serial: serial,
        attempt: 1,
      );
      if (!started) {
        throw StateError('Auditory stimulus playback did not advance.');
      }
      if (mounted && _playbackError) {
        setState(() => _playbackError = false);
      }
    } catch (error, stackTrace) {
      _log.e(
        'human_tests_auditory',
        'playback failed; system alert fallback used',
        error: error,
        stackTrace: stackTrace,
        data: <String, Object?>{
          'playerId': _player.playerId,
          'mode': spec.mode.name,
          'id': spec.id,
          'frequencyHz': spec.frequencyHz,
          'pan': spec.pan,
          'rhythm': spec.rhythm.name,
          'error': '$error',
        },
      );
      try {
        await SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
      if (mounted) {
        setState(() => _playbackError = true);
      }
    }
  }

  Future<void> _preparePlaybackSource(
    _AuditoryStimulusSpec spec,
    String sourcePath, {
    required int serial,
    required int attempt,
  }) async {
    if (!mounted || serial != _playbackSerial) {
      return;
    }
    await _tracePlaybackStep(
      'setSource',
      () => AudioPlayerSourceHelper.setSource(
        _player,
        DeviceFileSource(sourcePath, mimeType: 'audio/wav'),
        tag: 'human_tests_auditory',
        data: <String, Object?>{
          'mode': spec.mode.name,
          'id': spec.id,
          'frequencyHz': spec.frequencyHz,
          'pan': spec.pan,
          'rhythm': spec.rhythm.name,
          'path': sourcePath,
          'attempt': attempt,
        },
      ),
      spec: spec,
      serial: serial,
      attempt: attempt,
      sourcePath: sourcePath,
    );
    if (!mounted || serial != _playbackSerial) {
      return;
    }
    final duration = await _tracePlaybackStep(
      'waitForDuration',
      () => AudioPlayerSourceHelper.waitForDuration(
        _player,
        tag: 'human_tests_auditory',
        data: <String, Object?>{
          'mode': spec.mode.name,
          'id': spec.id,
          'frequencyHz': spec.frequencyHz,
          'pan': spec.pan,
          'rhythm': spec.rhythm.name,
          'path': sourcePath,
          'attempt': attempt,
        },
        timeout: const Duration(seconds: 5),
      ),
      spec: spec,
      serial: serial,
      attempt: attempt,
      sourcePath: sourcePath,
    );
    if (duration == null) {
      throw TimeoutException('Auditory stimulus duration was not resolved.');
    }
    if (!mounted || serial != _playbackSerial) {
      return;
    }
    await _tracePlaybackStep(
      'setVolume',
      () => _player.setVolume(1.0),
      spec: spec,
      serial: serial,
      attempt: attempt,
      sourcePath: sourcePath,
    );
  }

  Future<bool> _startPlaybackAndVerify(
    _AuditoryStimulusSpec spec,
    String sourcePath, {
    required int serial,
    required int attempt,
  }) async {
    for (var retryIndex = 0; retryIndex < 2; retryIndex += 1) {
      if (!mounted || serial != _playbackSerial) {
        return false;
      }
      await _tracePlaybackStep(
        'resume',
        () => _player.resume(),
        spec: spec,
        serial: serial,
        attempt: attempt + retryIndex,
        sourcePath: sourcePath,
      );
      final started = await _tracePlaybackStep(
        'waitForPlaybackAdvance',
        () => _waitForPlaybackAdvance(
          serial,
          sourcePath: sourcePath,
          attempt: attempt + retryIndex,
          spec: spec,
        ),
        spec: spec,
        serial: serial,
        attempt: attempt + retryIndex,
        sourcePath: sourcePath,
      );
      if (started) {
        return true;
      }
      if (retryIndex == 0) {
        _log.w(
          'human_tests_auditory',
          'playback stalled after resume; reloading source once',
          data: _playbackLogData(
            spec: spec,
            serial: serial,
            attempt: attempt,
            sourcePath: sourcePath,
            state: _player.state.name,
            reason: 'retry_reload',
          ),
        );
        if (_player.state == PlayerState.playing) {
          await _tracePlaybackStep(
            'pause_before_retry',
            () => _player.pause(),
            spec: spec,
            serial: serial,
            attempt: attempt + retryIndex,
            sourcePath: sourcePath,
            reason: 'retry_reload',
          );
        }
        if (!mounted || serial != _playbackSerial) {
          return false;
        }
        await _preparePlaybackSource(
          spec,
          sourcePath,
          serial: serial,
          attempt: attempt + 1,
        );
      }
    }
    return false;
  }

  Future<bool> _waitForPlaybackAdvance(
    int serial, {
    required _AuditoryStimulusSpec spec,
    required String sourcePath,
    required int attempt,
    Duration timeout = _playbackAdvanceTimeout,
    Duration pollInterval = _playbackAdvancePollInterval,
    int minimumPositionMs = 1,
  }) async {
    if (_isWindowsDesktop) {
      return _waitForPlaybackAdvanceWindows(
        serial,
        spec: spec,
        sourcePath: sourcePath,
        attempt: attempt,
        timeout: timeout,
        pollInterval: pollInterval,
        minimumPositionMs: minimumPositionMs,
      );
    }
    final deadline = DateTime.now().add(timeout);
    while (mounted &&
        serial == _playbackSerial &&
        DateTime.now().isBefore(deadline)) {
      if (_player.state == PlayerState.playing) {
        final position = await _player.getCurrentPosition();
        if (position != null && position.inMilliseconds >= minimumPositionMs) {
          return true;
        }
      }
      await Future<void>.delayed(pollInterval);
    }
    if (!mounted || serial != _playbackSerial) {
      return false;
    }
    final position = await _player.getCurrentPosition();
    final started =
        _player.state == PlayerState.playing &&
        position != null &&
        position.inMilliseconds >= minimumPositionMs;
    if (!started) {
      _log.w(
        'human_tests_auditory',
        'playback position did not advance',
        data: <String, Object?>{
          'playerId': _player.playerId,
          'mode': spec.mode.name,
          'id': spec.id,
          'frequencyHz': spec.frequencyHz,
          'pan': spec.pan,
          'rhythm': spec.rhythm.name,
          'path': sourcePath,
          'attempt': attempt,
          'state': _player.state.name,
          'positionMs': position?.inMilliseconds,
        },
      );
    }
    return started;
  }

  Future<bool> _waitForPlaybackAdvanceWindows(
    int serial, {
    required _AuditoryStimulusSpec spec,
    required String sourcePath,
    required int attempt,
    required Duration timeout,
    required Duration pollInterval,
    required int minimumPositionMs,
  }) async {
    final deadline = DateTime.now().add(timeout);
    final completer = Completer<bool>();
    late final StreamSubscription<Duration> positionSubscription;
    late final StreamSubscription<PlayerState> stateSubscription;

    void completeWithPosition(Duration position) {
      if (position.inMilliseconds < minimumPositionMs ||
          completer.isCompleted) {
        return;
      }
      completer.complete(true);
    }

    positionSubscription = _player.onPositionChanged.listen(
      completeWithPosition,
      onError: (Object error, StackTrace stackTrace) {
        if (completer.isCompleted) {
          return;
        }
        _log.w(
          'human_tests_auditory',
          'playback position stream error',
          data: <String, Object?>{
            ..._playbackLogData(
              spec: spec,
              serial: serial,
              attempt: attempt,
              sourcePath: sourcePath,
              step: 'waitForPlaybackAdvance',
            ),
            'error': '$error',
          },
        );
      },
    );
    stateSubscription = _player.onPlayerStateChanged.listen(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {
        if (completer.isCompleted) {
          return;
        }
        _log.w(
          'human_tests_auditory',
          'playback state stream error',
          data: <String, Object?>{
            ..._playbackLogData(
              spec: spec,
              serial: serial,
              attempt: attempt,
              sourcePath: sourcePath,
              step: 'waitForPlaybackAdvance',
            ),
            'error': '$error',
          },
        );
      },
    );

    try {
      while (mounted &&
          serial == _playbackSerial &&
          !completer.isCompleted &&
          DateTime.now().isBefore(deadline)) {
        if (_player.state == PlayerState.playing) {
          await Future.any<void>(<Future<void>>[
            completer.future.then((_) {}),
            Future<void>.delayed(pollInterval),
          ]);
        } else {
          await Future<void>.delayed(pollInterval);
        }
      }
      if (!mounted || serial != _playbackSerial) {
        return false;
      }
      if (completer.isCompleted) {
        return true;
      }
      final started = _player.state == PlayerState.playing;
      if (!started) {
        _log.w(
          'human_tests_auditory',
          'playback position did not advance',
          data: <String, Object?>{
            'playerId': _player.playerId,
            'mode': spec.mode.name,
            'id': spec.id,
            'frequencyHz': spec.frequencyHz,
            'pan': spec.pan,
            'rhythm': spec.rhythm.name,
            'path': sourcePath,
            'attempt': attempt,
            'state': _player.state.name,
          },
        );
        return false;
      }
      _log.d(
        'human_tests_auditory',
        'playback position confirmation degraded to state check',
        data: <String, Object?>{
          ..._playbackLogData(
            spec: spec,
            serial: serial,
            attempt: attempt,
            sourcePath: sourcePath,
            step: 'waitForPlaybackAdvance',
            state: _player.state.name,
          ),
          'positionEventReceived': false,
        },
      );
      return true;
    } finally {
      await positionSubscription.cancel();
      await stateSubscription.cancel();
    }
  }

  void _tapHeard() {
    if (_phase == _AuditoryPhase.waiting) {
      final stimulus = _currentStimulus;
      if (stimulus != null) {
        _recordCurrent(
          heard: false,
          correct: false,
          milliseconds: 0,
          falseStart: true,
        );
      }
      return;
    }
    if (_phase != _AuditoryPhase.cue) {
      return;
    }
    final stimulus = _currentStimulus;
    if (stimulus == null) {
      return;
    }
    _recordCurrent(
      heard: true,
      correct: true,
      milliseconds: math.max(1, _stopwatch.elapsedMilliseconds),
    );
  }

  void _confirmSpatial() {
    final guess = _spatialGuessDegrees;
    if (guess == null) {
      return;
    }
    if (_phase == _AuditoryPhase.waiting) {
      _recordCurrent(
        heard: false,
        correct: false,
        milliseconds: 0,
        falseStart: true,
      );
      return;
    }
    if (_phase != _AuditoryPhase.cue) {
      return;
    }
    final target = _currentStimulus?.directionDegrees ?? 0;
    final error = _angleDistance(target, guess);
    _recordCurrent(
      heard: true,
      correct: error <= _spatialTolerance,
      milliseconds: math.max(1, _stopwatch.elapsedMilliseconds),
      guessDegrees: guess,
      angleError: error,
    );
  }

  void _recordCurrent({
    required bool heard,
    required bool correct,
    required int milliseconds,
    bool falseStart = false,
    double? guessDegrees,
    double? angleError,
  }) {
    final stimulus = _currentStimulus;
    if (stimulus == null) {
      return;
    }
    _signalTimer?.cancel();
    _timeoutTimer?.cancel();
    _playbackSerial += 1;
    _stopwatch.stop();
    _queuePlaybackSilence(reason: 'record_current');
    setState(() {
      _records.add(
        _AuditoryRecord(
          mode: _mode,
          labelKey: stimulus.labelKey,
          labelParams: stimulus.labelParams,
          frequencyHz: stimulus.frequencyHz,
          outputVolume: stimulus.outputVolume,
          rhythm: stimulus.rhythm,
          heard: heard,
          correct: correct,
          milliseconds: milliseconds,
          falseStart: falseStart,
          directionDegrees: stimulus.directionDegrees,
          guessDegrees: guessDegrees,
          angleError: angleError,
        ),
      );
      _roundIndex += 1;
      _lastCorrect = correct;
      if (correct) {
        _streak += 1;
        _bestStreak = math.max(_bestStreak, _streak);
      } else {
        _streak = 0;
      }
      if (falseStart) {
        _falseStarts += 1;
      }
      _phase = _roundIndex >= _sessionStimuli.length
          ? _AuditoryPhase.done
          : _AuditoryPhase.idle;
    });
    _transitionTimer?.cancel();
    _transitionTimer = Timer(const Duration(milliseconds: 540), () {
      if (!mounted) {
        return;
      }
      if (_roundIndex >= _sessionStimuli.length) {
        _finish();
      } else {
        _scheduleRound();
      }
    });
  }

  void _finish() {
    _signalTimer?.cancel();
    _timeoutTimer?.cancel();
    _transitionTimer?.cancel();
    _playbackSerial += 1;
    _queuePlaybackSilence(reason: 'finish');
    _stopwatch
      ..stop()
      ..reset();
    setState(() => _phase = _AuditoryPhase.done);
    if (_autoReport) {
      unawaited(_showReport());
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HumanMetricWrap(metrics: _metrics(i18n)),
        const SizedBox(height: 12),
        _HumanSettingsSection(
          title: i18n.t(
            'inline.ui.pages.toolbox_human_tests_auditory.auditory_settings_c7e5b6',
          ),
          subtitle: i18n.t(
            'inline.ui.pages.toolbox_human_tests_auditory.adjust_frequency_groups_volume_ladders_spatial_direction_a77db3',
          ),
          initiallyExpanded: true,
          child: _buildSettings(context, i18n),
        ),
        const SizedBox(height: 12),
        _HumanPanel(child: _buildStage(context, i18n)),
      ],
    );
  }

  List<(String, String)> _metrics(AppI18n i18n) {
    final scoreLabel = _mode == _AuditoryMode.spatial
        ? i18n.t(
            'inline.ui.pages.toolbox_human_tests_auditory.localization_7eacab',
          )
        : i18n.t(
            'inline.ui.pages.toolbox_human_tests_auditory.heard_rate_21be7e',
          );
    return <(String, String)>[
      (i18n.t('progress'), '$_roundIndex/$_targetRoundCount'),
      (i18n.t('toolbox.sound.piano.mode'), _modeCopies[_mode]!.label(i18n)),
      (scoreLabel, '${(_scoreRatio * 100).round()}%'),
      (
        _mode == _AuditoryMode.spatial
            ? i18n.t(
                'inline.ui.pages.toolbox_human_tests_auditory.avg_error_f2ab21',
              )
            : i18n.t(
                'inline.ui.pages.toolbox_human_tests_auditory.avg_response_3140b8',
              ),
        _mode == _AuditoryMode.spatial
            ? '${_averageSpatialError.round()}°'
            : (_averageMs == 0 ? '-' : _formatMilliseconds(_averageMs)),
      ),
    ];
  }

  Widget _buildStage(BuildContext context, AppI18n i18n) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final current = _currentStimulus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            ..._modeOrder.map((mode) {
              final copy = _modeCopies[mode]!;
              return ChoiceChip(
                avatar: Icon(copy.icon, size: 18),
                label: Text(copy.label(i18n)),
                selected: _mode == mode,
                onSelected: _busy ? null : (_) => _setMode(mode),
              );
            }),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: colorScheme.surface,
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            children: <Widget>[
              Icon(_modeCopies[_mode]!.icon, color: _accent, size: 48),
              const SizedBox(height: 8),
              Text(
                _phaseText(i18n),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _modeCopies[_mode]!.description(i18n),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              _buildAuditoryStatusSlot(i18n, current),
              if (_playbackError) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  i18n.t(
                    'inline.ui.pages.toolbox_human_tests_auditory.synthetic_tone_playback_failed_a_system_alert_fallback_w_3daccd',
                  ),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              if (_mode == _AuditoryMode.spatial)
                _buildSpatialAnswer(i18n)
              else
                FilledButton.icon(
                  onPressed: _busy ? _tapHeard : null,
                  icon: const Icon(Icons.touch_app_rounded),
                  label: Text(
                    i18n.t(
                      'inline.ui.pages.toolbox_human_tests_auditory.tap_when_heard_a354ae',
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(190, 58),
                  ),
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: <Widget>[
                  _HumanActionButton(
                    label: i18n.t('toolbox.breathing.start'),
                    icon: Icons.play_arrow_rounded,
                    onPressed: _busy ? null : _start,
                  ),
                  OutlinedButton.icon(
                    onPressed: _sessionRunning || _busy
                        ? () => _reset(clearMode: false)
                        : null,
                    icon: const Icon(Icons.stop_rounded),
                    label: Text(i18n.t('stop')),
                  ),
                  OutlinedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(i18n.t('appearanceReset')),
                  ),
                  if (_allowReplay)
                    OutlinedButton.icon(
                      onPressed: _canPlayDemoAudio
                          ? current == null
                                ? () => unawaited(_previewCurrentMode())
                                : () => unawaited(_playStimulus(current))
                          : null,
                      icon: const Icon(Icons.hearing_rounded),
                      label: Text(
                        i18n.t(
                          'inline.ui.pages.toolbox_human_tests_auditory.replay_2cd06c',
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (_lastCorrect != null) ...<Widget>[
          const SizedBox(height: 10),
          _HumanPill(
            text: _lastCorrect!
                ? i18n.t(
                    'inline.ui.pages.toolbox_human_tests_auditory.last_round_recorded_8ee0c6',
                  )
                : i18n.t(
                    'inline.ui.pages.toolbox_human_tests_auditory.last_round_missed_323436',
                  ),
            accent: _lastCorrect! ? const Color(0xFF4E8B6B) : Colors.redAccent,
          ),
        ],
      ],
    );
  }

  Widget _buildSpatialAnswer(AppI18n i18n) => _buildSpatialAnswerPanel(i18n);

  Widget _buildAuditoryStatusSlot(
    AppI18n i18n,
    _AuditoryStimulusSpec? current,
  ) {
    final active =
        _phase == _AuditoryPhase.waiting || _phase == _AuditoryPhase.cue;
    final completed = current != null && _phase == _AuditoryPhase.done;
    return SizedBox(
      key: const ValueKey<String>('auditory-status-slot'),
      height: 64,
      child: Center(
        child: active
            ? _AuditoryWaitingMarker(
                key: const ValueKey<String>('auditory-wait-marker'),
                seed: _waitingSeed,
                accent: _accent,
              )
            : completed
            ? _HumanPill(text: _currentHint(i18n, current), accent: _accent)
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildSpatialAnswerPanel(AppI18n i18n) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedDegrees = _spatialGuessDegrees;
    final spatialDisplayDegrees = _spatialDisplayDegrees;
    final hasSpatialGuess = _hasSpatialGuess;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SegmentedButton<_SpatialInputMode>(
          segments: <ButtonSegment<_SpatialInputMode>>[
            ButtonSegment<_SpatialInputMode>(
              value: _SpatialInputMode.pad,
              label: Text(
                i18n.t(
                  'inline.ui.pages.toolbox_human_tests_auditory.8_way_pad_e0afed',
                ),
              ),
              icon: const Icon(Icons.diamond_outlined),
            ),
            ButtonSegment<_SpatialInputMode>(
              value: _SpatialInputMode.pointer,
              label: Text(
                i18n.t(
                  'inline.ui.pages.toolbox_human_tests_auditory.pointer_5c53b2',
                ),
              ),
              icon: const Icon(Icons.tune_rounded),
            ),
          ],
          selected: <_SpatialInputMode>{_spatialInputMode},
          onSelectionChanged: _busy
              ? null
              : (selection) =>
                    setState(() => _spatialInputMode = selection.first),
        ),
        const SizedBox(height: 12),
        if (_spatialInputMode == _SpatialInputMode.pad)
          _SpatialSpeakerPad(
            selectedDegrees: selectedDegrees,
            enabled: _busy,
            showLabels: _showDirectionLabels,
            accent: _accent,
            labelFor: (angle) => _formatDirection(angle, i18n),
            shortLabelFor: (angle) => _directionName(angle, i18n),
            onSelected: (angle) {
              setState(() => _spatialGuessDegrees = angle);
              _confirmSpatial();
            },
          )
        else ...<Widget>[
          _SpatialPointerDial(
            valueDegrees: spatialDisplayDegrees,
            hasSelection: hasSpatialGuess,
            enabled: _busy,
            accent: _accent,
            label: _spatialSelectionLabel(i18n),
            onChanged: _setSpatialGuess,
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Icon(Icons.explore_rounded, color: colorScheme.onSurfaceVariant),
              Expanded(
                child: Slider(
                  value: spatialDisplayDegrees,
                  min: 0,
                  max: 360,
                  divisions: 72,
                  label: _spatialSelectionLabel(i18n),
                  onChanged: _busy ? _setSpatialGuess : null,
                ),
              ),
              SizedBox(
                width: 72,
                child: Text(
                  hasSpatialGuess ? '${spatialDisplayDegrees.round()}°' : '-',
                  textAlign: TextAlign.end,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 4),
        FilledButton.icon(
          onPressed: _busy && hasSpatialGuess ? _confirmSpatial : null,
          icon: const Icon(Icons.check_rounded),
          label: Text(
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_auditory.confirm_position_3c5bcd',
            ),
          ),
          style: FilledButton.styleFrom(minimumSize: const Size(190, 52)),
        ),
      ],
    );
  }

  void _setSpatialGuess(double targetDegrees) {
    setState(() {
      final normalizedTarget = targetDegrees % 360;
      final current = _spatialGuessDegrees;
      if (current == null || _spatialSmoothing == 0) {
        _spatialGuessDegrees = normalizedTarget;
        return;
      }
      final diff = ((normalizedTarget - current + 540) % 360) - 180;
      _spatialGuessDegrees =
          (current + diff * (1 - _spatialSmoothing * 0.55)) % 360;
    });
  }

  Widget _buildSettings(BuildContext context, AppI18n i18n) {
    final roundBounds = _roundBoundsFor(_mode);
    final roundCount = _roundCountFor(_mode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _AuditorySettingSlider(
          label: i18n.t('rounds'),
          valueText: i18n.t(
            'inline.ui.pages.toolbox_human_tests_auditory.roundcount_rounds_685a31',
            params: <String, Object?>{'roundCount': roundCount},
          ),
          value: roundCount.toDouble(),
          min: roundBounds.$1.toDouble(),
          max: roundBounds.$2.toDouble(),
          divisions: roundBounds.$2 - roundBounds.$1,
          onChanged: _busy
              ? null
              : (value) => setState(() => _roundCount = value.round()),
        ),
        Text(
          i18n.t(
            'inline.ui.pages.toolbox_human_tests_auditory.frequency_defaults_to_10_rounds_and_each_mode_can_be_cus_22ca27',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        Text(
          _sizeSuggestion(i18n),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 14),
        _sectionLabel(
          i18n.t(
            'inline.ui.pages.toolbox_human_tests_auditory.mode_settings_1b453c',
          ),
        ),
        if (_mode == _AuditoryMode.frequency) _buildFrequencySettings(i18n),
        if (_mode == _AuditoryMode.sensitivity) _buildSensitivitySettings(i18n),
        if (_mode == _AuditoryMode.spatial) _buildSpatialSettings(i18n),
        const SizedBox(height: 14),
        _sectionLabel(
          i18n.t(
            'inline.ui.pages.toolbox_human_tests_auditory.playback_and_report_1c20c4',
          ),
        ),
        _AuditorySettingSlider(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_auditory.tone_duration_1bd78e',
          ),
          valueText: '$_toneDurationMs ms',
          value: _toneDurationMs.toDouble(),
          min: 700,
          max: 2200,
          divisions: 30,
          onChanged: _busy
              ? null
              : (value) => setState(() => _toneDurationMs = value.round()),
        ),
        _AuditorySettingSlider(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_auditory.response_window_3840f8',
          ),
          valueText: '${(_responseWindowMs / 1000).toStringAsFixed(1)} s',
          value: _responseWindowMs.toDouble(),
          min: 1200,
          max: 5000,
          divisions: 19,
          onChanged: _busy
              ? null
              : (value) => setState(() => _responseWindowMs = value.round()),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_auditory.allow_replay_20377d',
            ),
          ),
          value: _allowReplay,
          onChanged: (value) => setState(() => _allowReplay = value),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_auditory.detailed_group_report_813500',
            ),
          ),
          value: _showGroupReport,
          onChanged: (value) => setState(() => _showGroupReport = value),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_auditory.show_details_d95165',
            ),
          ),
          value: _showRawData,
          onChanged: (value) => setState(() => _showRawData = value),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_auditory.auto_report_4b91e0',
            ),
          ),
          value: _autoReport,
          onChanged: (value) => setState(() => _autoReport = value),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: <Widget>[
            OutlinedButton.icon(
              onPressed: _canPlayDemoAudio
                  ? () => unawaited(_previewCurrentMode())
                  : null,
              icon: const Icon(Icons.play_circle_outline_rounded),
              label: Text(
                i18n.t(
                  'inline.ui.pages.toolbox_human_tests_auditory.preview_current_mode_78a9e6',
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _records.isEmpty
                  ? null
                  : () => unawaited(_showReport()),
              icon: const Icon(Icons.summarize_rounded),
              label: Text(
                i18n.t(
                  'inline.ui.pages.toolbox_human_tests_aim.view_report_05b6eb',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFrequencySettings(AppI18n i18n) {
    final bandOptions = <int>[16, 20, 24, 32];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          i18n.t(
            'inline.ui.pages.toolbox_human_tests_auditory.frequency_range_e745a8',
          ),
        ),
        RangeSlider(
          values: _frequencyRange,
          min: 60,
          max: 12000,
          divisions: 120,
          labels: RangeLabels(
            _formatFrequency(_frequencyRange.start),
            _formatFrequency(_frequencyRange.end),
          ),
          onChanged: _busy
              ? null
              : (values) => setState(() {
                  final start = math.min(values.start, values.end - 200);
                  final end = math.max(values.end, start + 200);
                  _frequencyRange = RangeValues(start, end);
                }),
        ),
        _choiceRow<int>(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_auditory.analysis_bands_9a8d52',
          ),
          values: bandOptions,
          selected: _analysisBands,
          labelFor: (value) => '$value',
          onSelected: (value) => setState(() => _analysisBands = value),
        ),
        _AuditorySettingSlider(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_auditory.frequency_volume_scale_b41fc9',
          ),
          valueText: '${(_frequencyVolumeScale * 100).round()}%',
          value: _frequencyVolumeScale,
          min: 0.32,
          max: 1,
          divisions: 17,
          onChanged: _busy
              ? null
              : (value) => setState(() => _frequencyVolumeScale = value),
        ),
        _AuditorySettingSlider(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_auditory.rhythmic_loudness_depth_faceee',
          ),
          valueText: '${(_rhythmDepth * 100).round()}%',
          value: _rhythmDepth,
          min: 0,
          max: 0.9,
          divisions: 18,
          onChanged: _busy
              ? null
              : (value) => setState(() => _rhythmDepth = value),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_auditory.mix_rhythm_patterns_76ada3',
            ),
          ),
          value: _includeRhythmPatterns,
          onChanged: _busy
              ? null
              : (value) => setState(() => _includeRhythmPatterns = value),
        ),
      ],
    );
  }

  Widget _buildSensitivitySettings(AppI18n i18n) {
    final levelOptions = <int>[12, 16, 20, 24];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _choiceRow<double>(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_auditory.base_frequency_64a87c',
          ),
          values: _baseFrequencies,
          selected: _sensitivityBaseFrequency,
          labelFor: _formatFrequency,
          onSelected: (value) =>
              setState(() => _sensitivityBaseFrequency = value),
        ),
        _choiceRow<int>(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_auditory.sensitivity_levels_c8f644',
          ),
          values: levelOptions,
          selected: _sensitivityLevelCount,
          labelFor: (value) => '$value',
          onSelected: (value) => setState(() => _sensitivityLevelCount = value),
        ),
        _AuditorySettingSlider(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_auditory.minimum_output_247a29',
          ),
          valueText: '${(_minimumOutput * 100).round()}%',
          value: _minimumOutput,
          min: 0.02,
          max: 0.3,
          divisions: 14,
          onChanged: _busy
              ? null
              : (value) => setState(() {
                  _minimumOutput = value;
                  _maximumOutput = math.max(_maximumOutput, value + 0.08);
                }),
        ),
        _AuditorySettingSlider(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_auditory.maximum_output_d36237',
          ),
          valueText: '${(_maximumOutput * 100).round()}%',
          value: _maximumOutput,
          min: 0.35,
          max: 1,
          divisions: 13,
          onChanged: _busy
              ? null
              : (value) => setState(() {
                  _maximumOutput = value;
                  _minimumOutput = math.min(_minimumOutput, value - 0.08);
                }),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_auditory.log_volume_steps_abc0d1',
            ),
          ),
          value: _logSensitivitySteps,
          onChanged: _busy
              ? null
              : (value) => setState(() => _logSensitivitySteps = value),
        ),
      ],
    );
  }

  Widget _buildSpatialSettings(AppI18n i18n) {
    final directionOptions = <int>[8, 12, 16];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _choiceRow<int>(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_auditory.direction_count_90c455',
          ),
          values: directionOptions,
          selected: _directionCount,
          labelFor: (value) => '$value',
          onSelected: (value) => setState(() => _directionCount = value),
        ),
        _AuditorySettingSlider(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_auditory.spatial_volume_4f35b3',
          ),
          valueText: '${(_spatialVolume * 100).round()}%',
          value: _spatialVolume,
          min: 0.2,
          max: 1,
          divisions: 20,
          onChanged: _busy
              ? null
              : (value) => setState(() => _spatialVolume = value),
        ),
        _AuditorySettingSlider(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_auditory.spatial_tolerance_68199e',
          ),
          valueText: '${_spatialTolerance.round()}°',
          value: _spatialTolerance,
          min: 8,
          max: 40,
          divisions: 16,
          onChanged: _busy
              ? null
              : (value) => setState(() => _spatialTolerance = value),
        ),
        _AuditorySettingSlider(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_auditory.slider_smoothing_f70ad6',
          ),
          valueText: '${(_spatialSmoothing * 100).round()}%',
          value: _spatialSmoothing,
          min: 0,
          max: 1,
          divisions: 20,
          onChanged: (value) => setState(() => _spatialSmoothing = value),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_auditory.custom_direction_9f8efe',
            ),
          ),
          value: _customSpatialDirection,
          onChanged: _busy
              ? null
              : (value) => setState(() => _customSpatialDirection = value),
        ),
        if (_customSpatialDirection)
          _AuditorySettingSlider(
            label: i18n.t(
              'inline.ui.pages.toolbox_human_tests_auditory.custom_target_direction_85c106',
            ),
            valueText: _formatDirection(_customDirectionDegrees, i18n),
            value: _customDirectionDegrees,
            min: 0,
            max: 360,
            divisions: 72,
            onChanged: _busy
                ? null
                : (value) => setState(() => _customDirectionDegrees = value),
          ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_auditory.show_direction_labels_ea6e01',
            ),
          ),
          value: _showDirectionLabels,
          onChanged: (value) => setState(() => _showDirectionLabels = value),
        ),
      ],
    );
  }

  Widget _choiceRow<T>({
    required String label,
    required List<T> values,
    required T selected,
    required String Function(T value) labelFor,
    required ValueChanged<T> onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values
                .map(
                  (value) => ChoiceChip(
                    label: Text(labelFor(value)),
                    selected: value == selected,
                    onSelected: _busy ? null : (_) => onSelected(value),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }

  Future<void> _previewCurrentMode() async {
    if (!_canPlayDemoAudio) {
      return;
    }
    await _playStimulus(_previewStimulusForMode(_mode));
  }

  Future<void> _showReport() async {
    if (!mounted || _records.isEmpty) {
      return;
    }
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_auditory.auditory_test_report_685711',
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _HumanMetricWrap(
                  metrics: <(String, String)>[
                    (
                      _mode == _AuditoryMode.spatial
                          ? i18n.t(
                              'inline.ui.pages.toolbox_human_tests_auditory.localization_7eacab',
                            )
                          : i18n.t(
                              'inline.ui.pages.toolbox_human_tests_auditory.heard_rate_21be7e',
                            ),
                      '${(_scoreRatio * 100).round()}%',
                    ),
                    (
                      i18n.t(
                        'inline.ui.pages.toolbox_human_tests_auditory.avg_response_3140b8',
                      ),
                      _averageMs == 0 ? '-' : _formatMilliseconds(_averageMs),
                    ),
                    (
                      i18n.t(
                        'inline.ui.pages.toolbox_human_tests_aim_widgets.best_streak_5a5a71',
                      ),
                      '$_bestStreak',
                    ),
                    (
                      i18n.t(
                        'inline.ui.pages.toolbox_human_tests_auditory.misses_bcc2a1',
                      ),
                      '$_misses',
                    ),
                    (
                      i18n.t(
                        'inline.ui.pages.toolbox_human_tests_auditory.false_starts_9a365d',
                      ),
                      '$_falseStarts',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_showGroupReport) _buildGroupReport(i18n),
                const SizedBox(height: 10),
                _HumanPanel(child: Text(_recommendation(i18n))),
                const SizedBox(height: 10),
                if (_showRawData) _buildRawRecords(i18n),
                Text(
                  i18n.t(
                    'inline.ui.pages.toolbox_human_tests_auditory.note_device_headphones_and_room_conditions_can_affect_re_aedd19',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(i18n.t('inline.plan295.life.close.370fb8697deb')),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGroupReport(AppI18n i18n) {
    final rows = switch (_mode) {
      _AuditoryMode.frequency => _frequencyReportRows(),
      _AuditoryMode.sensitivity => _sensitivityReportRows(i18n),
      _AuditoryMode.spatial => _spatialReportRows(i18n),
    };
    final estimatedFrequencyCutoff = _estimatedFrequencyCutoff();
    return _HumanPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_auditory.detailed_groups_ded14a',
            ),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            switch (_mode) {
              _AuditoryMode.frequency => i18n.t(
                'inline.plan296.ui.pages.toolbox.human.tests.auditory.estimated_high_frequency_cutoff.e8dfdd2adc',
                params: <String, Object?>{
                  'p0': estimatedFrequencyCutoff == null
                      ? '--'
                      : _formatFrequency(estimatedFrequencyCutoff),
                },
              ),
              _AuditoryMode.sensitivity => i18n.t(
                'inline.ui.pages.toolbox_human_tests_auditory.estimated_audible_threshold_estimatedthreshold_100_round_38a1f6',
                params: <String, Object?>{
                  'estimatedThreshold': (_estimatedThreshold() * 100).round(),
                },
              ),
              _AuditoryMode.spatial => i18n.t(
                'inline.ui.pages.toolbox_human_tests_auditory.average_direction_error_averagespatialerror_round_2f16c4',
                params: <String, Object?>{
                  'averageSpatialError': _averageSpatialError.round(),
                },
              ),
            },
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(row),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRawRecords(AppI18n i18n) {
    final rows = _records
        .asMap()
        .entries
        .map((entry) {
          final index = entry.key + 1;
          final record = entry.value;
          final suffix = record.mode == _AuditoryMode.spatial
              ? ' / ${record.guessDegrees?.round() ?? 0}° / ${record.angleError?.round() ?? 0}°'
              : ' / ${_rhythmLabel(record.rhythm, i18n)}';
          return '$index. ${record.label(i18n)}: ${record.correct ? 'OK' : 'MISS'} ${record.milliseconds} ms$suffix';
        })
        .toList(growable: false);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _HumanPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rows.map((row) => Text(row)).toList(growable: false),
        ),
      ),
    );
  }

  List<String> _frequencyReportRows() {
    return List<String>.generate(_analysisBands, (index) {
      final bands = _frequencyBands(_analysisBands);
      final range = bands[index];
      final inBand = _records
          .where(
            (record) =>
                record.frequencyHz >= range.start &&
                record.frequencyHz <= range.end,
          )
          .toList(growable: false);
      final heard = inBand.where((record) => record.heard).length;
      final total = inBand.length;
      final ratio = total == 0 ? 0 : (heard / total * 100).round();
      return '${index + 1}. ${_formatFrequency(range.start)}-${_formatFrequency(range.end)}: $heard/$total ($ratio%)';
    });
  }

  List<String> _sensitivityReportRows(AppI18n i18n) {
    final levels = _sensitivityLevels();
    return List<String>.generate(levels.length, (index) {
      final level = levels[index];
      final inLevel = _records
          .where((record) => (record.outputVolume - level).abs() < 0.012)
          .toList(growable: false);
      final heard = inLevel.where((record) => record.heard).length;
      final total = inLevel.length;
      final ratio = total == 0 ? 0 : (heard / total * 100).round();
      return '${index + 1}. ${i18n.t('inline.ui.pages.toolbox_human_tests_auditory.output_dafb97')} ${level.toStringAsFixed(2)}: $heard/$total ($ratio%)';
    });
  }

  List<String> _spatialReportRows(AppI18n i18n) {
    final directions = _directionAngles();
    return List<String>.generate(directions.length, (index) {
      final angle = directions[index];
      final inDirection = _records
          .where(
            (record) =>
                record.directionDegrees != null &&
                _angleDistance(record.directionDegrees!, angle) <
                    (360 / _directionCount / 2 + 0.1),
          )
          .toList(growable: false);
      final correct = inDirection.where((record) => record.correct).length;
      final total = inDirection.length;
      final errors = inDirection
          .map((record) => record.angleError)
          .whereType<double>()
          .toList(growable: false);
      final avgError = errors.isEmpty
          ? 0
          : errors.fold<double>(0, (sum, value) => sum + value) / errors.length;
      return '${index + 1}. ${_formatDirection(angle, i18n)}: $correct/$total, ${avgError.round()}°';
    });
  }

  String _recommendation(AppI18n i18n) {
    if (_mode == _AuditoryMode.spatial) {
      if (_averageSpatialError > _spatialTolerance * 1.5) {
        return i18n.t(
          'inline.ui.pages.toolbox_human_tests_auditory.suggestion_start_with_8_directions_wider_tolerance_and_h_b0f996',
        );
      }
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory.suggestion_localization_is_stable_increase_direction_cou_1c066a',
      );
    }
    final high = _records
        .where((record) => record.frequencyHz >= 4000)
        .toList(growable: false);
    final highRate = high.isEmpty
        ? 1.0
        : high.where((record) => record.heard).length / high.length;
    if (_mode == _AuditoryMode.frequency && highRate < 0.6) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory.suggestion_if_high_frequency_audibility_is_weak_narrow_t_21ed94',
      );
    }
    if (_mode == _AuditoryMode.sensitivity) {
      final threshold = _estimatedThreshold();
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory.suggestion_estimated_audible_threshold_is_about_threshol_10fd1a',
        params: <String, Object?>{'threshold': (threshold * 100).round()},
      );
    }
    return i18n.t(
      'inline.ui.pages.toolbox_human_tests_auditory.suggestion_keep_this_setup_if_results_fluctuate_increase_f9f0c7',
    );
  }

  String _phaseText(AppI18n i18n) {
    return switch (_phase) {
      _AuditoryPhase.idle => i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory.press_start_and_wait_for_a_random_sound_0f9b41',
      ),
      _AuditoryPhase.waiting => _activePhaseText(i18n),
      _AuditoryPhase.cue => _activePhaseText(i18n),
      _AuditoryPhase.done => i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory.session_complete_view_the_report_or_restart_d5948e',
      ),
    };
  }

  String _activePhaseText(AppI18n i18n) {
    if (_mode == _AuditoryMode.spatial) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory.stay_focused_choose_the_perceived_direction_when_you_hea_0da0bb',
      );
    }
    return i18n.t(
      'inline.ui.pages.toolbox_human_tests_auditory.stay_focused_tap_when_you_hear_the_sound_c781a2',
    );
  }

  String _currentHint(AppI18n i18n, _AuditoryStimulusSpec spec) {
    if (_mode == _AuditoryMode.frequency ||
        _mode == _AuditoryMode.sensitivity) {
      return '${_formatFrequency(spec.frequencyHz)} / ${(spec.outputVolume * 100).round()}%';
    }
    if (!_showDirectionLabels) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory.spatial_sound_ebc6fa',
      );
    }
    return _formatDirection(spec.directionDegrees ?? 0, i18n);
  }

  String _sizeSuggestion(AppI18n i18n) {
    return i18n.t(
      'inline.ui.pages.toolbox_human_tests_auditory.suggested_test_size_use_10_12_rounds_for_a_quick_screen_e596ff',
    );
  }

  List<RangeValues> _frequencyBands(int count) {
    final start = _frequencyRange.start.clamp(60.0, 12000.0).toDouble();
    final end = _frequencyRange.end.clamp(start + 100, 12000.0).toDouble();
    final minLog = math.log(start);
    final maxLog = math.log(end);
    return List<RangeValues>.generate(count, (index) {
      final a = index / count;
      final b = (index + 1) / count;
      return RangeValues(
        math.exp(minLog + (maxLog - minLog) * a),
        math.exp(minLog + (maxLog - minLog) * b),
      );
    });
  }

  List<double> _sensitivityLevels() {
    final total = _sensitivityLevelCount.clamp(8, 24).toInt();
    final minValue = math.max(0.01, _minimumOutput);
    final maxValue = math.max(minValue + 0.02, _maximumOutput);
    return List<double>.generate(total, (index) {
      final ratio = total == 1 ? 0.0 : index / (total - 1);
      final eased = _logSensitivitySteps
          ? math.pow(ratio, 1.35).toDouble()
          : ratio;
      final value = minValue + (maxValue - minValue) * eased;
      return value.clamp(minValue, maxValue).toDouble();
    });
  }

  List<double> _directionAngles() {
    return List<double>.generate(
      _directionCount,
      (index) => index * 360 / _directionCount,
    );
  }

  double _estimatedThreshold() {
    final sensitivityRecords = _records
        .where((record) => record.mode == _AuditoryMode.sensitivity)
        .toList(growable: false);
    if (sensitivityRecords.isEmpty) {
      return _maximumOutput;
    }
    final heard = sensitivityRecords
        .where((record) => record.heard)
        .toList(growable: false);
    final missed = sensitivityRecords
        .where((record) => !record.heard)
        .toList(growable: false);
    if (heard.isEmpty) {
      return _maximumOutput;
    }
    if (missed.isEmpty) {
      return heard.map((record) => record.outputVolume).reduce(math.min);
    }
    final highestMiss = missed
        .map((record) => record.outputVolume)
        .reduce(math.max);
    final lowestHit = heard
        .map((record) => record.outputVolume)
        .reduce(math.min);
    return ((highestMiss + lowestHit) / 2)
        .clamp(_minimumOutput, _maximumOutput)
        .toDouble();
  }

  double? _estimatedFrequencyCutoff() {
    final frequencyRecords = _records
        .where((record) => record.mode == _AuditoryMode.frequency)
        .toList(growable: false);
    if (frequencyRecords.isEmpty) {
      return null;
    }
    final heardFrequencies = frequencyRecords
        .where((record) => record.heard && record.frequencyHz >= 250)
        .map((record) => record.frequencyHz)
        .toList(growable: false);
    final missedHighFrequencies = frequencyRecords
        .where((record) => !record.heard && record.frequencyHz >= 4000)
        .map((record) => record.frequencyHz)
        .toList(growable: false);
    final highestHeard = heardFrequencies.isEmpty
        ? null
        : heardFrequencies.reduce(math.max);
    final firstMissedHigh = missedHighFrequencies.isEmpty
        ? null
        : missedHighFrequencies.reduce(math.min);
    if (highestHeard == null) {
      return firstMissedHigh;
    }
    if (firstMissedHigh == null) {
      return highestHeard;
    }
    return firstMissedHigh > highestHeard
        ? (highestHeard + firstMissedHigh) / 2
        : highestHeard;
  }

  static double _angleDistance(double a, double b) {
    final diff = ((a - b).abs() % 360).toDouble();
    return diff > 180 ? 360 - diff : diff;
  }

  static String _formatFrequency(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(value >= 10000 ? 0 : 1)} kHz';
    }
    return '${value.round()} Hz';
  }

  String _formatDirection(double value, AppI18n i18n) {
    final normalized = value % 360;
    final label = switch ((normalized / 45).round() % 8) {
      0 => i18n.t('inline.ui.pages.toolbox_human_tests_auditory.front_47418f'),
      1 => i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory.front_right_a3f226',
      ),
      2 => i18n.t('inline.ui.pages.toolbox_human_tests_auditory.right_594268'),
      3 => i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory.back_right_731f4e',
      ),
      4 => i18n.t('inline.ui.pages.toolbox_human_tests_auditory.back_1ed784'),
      5 => i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory.back_left_26a1be',
      ),
      6 => i18n.t('toolbox.breathing.left'),
      _ => i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory.front_left_2ec86b',
      ),
    };
    return '$label ${normalized.round()}°';
  }

  String _spatialSelectionLabel(AppI18n i18n) {
    final value = _spatialGuessDegrees;
    if (value == null) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory.no_direction_selected_8fa127',
      );
    }
    return _formatDirection(value, i18n);
  }

  String _directionName(double value, AppI18n i18n) {
    final normalized = value % 360;
    return switch ((normalized / 45).round() % 8) {
      0 => i18n.t('inline.ui.pages.toolbox_human_tests_auditory.front_47418f'),
      1 => i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory.front_right_a3f226',
      ),
      2 => i18n.t('inline.ui.pages.toolbox_human_tests_auditory.right_594268'),
      3 => i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory.back_right_731f4e',
      ),
      4 => i18n.t('inline.ui.pages.toolbox_human_tests_auditory.back_1ed784'),
      5 => i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory.back_left_26a1be',
      ),
      6 => i18n.t('toolbox.breathing.left'),
      _ => i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory.front_left_2ec86b',
      ),
    };
  }

  static String _rhythmLabel(_AuditoryRhythm rhythm, AppI18n i18n) {
    return switch (rhythm) {
      _AuditoryRhythm.steady => i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory.steady_73508d',
      ),
      _AuditoryRhythm.doublePulse => i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory.double_pulse_fc5430',
      ),
      _AuditoryRhythm.triplePulse => i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory.triple_pulse_40e963',
      ),
      _AuditoryRhythm.rising => i18n.t(
        'inline.ui.pages.toolbox_human_tests_auditory.rising_126b52',
      ),
    };
  }

  static Uint8List _buildToneBytes(
    _AuditoryStimulusSpec spec, {
    required double rhythmDepth,
  }) {
    const sampleRate = 44100;
    const attackMs = 14;
    const releaseMs = 54;
    const channelCount = 2;
    const bytesPerSample = 2;
    final durationMs = spec.durationMs.clamp(180, 2400);
    final sampleCount = (sampleRate * durationMs / 1000).round();
    final byteCount = sampleCount * channelCount * bytesPerSample;
    final buffer = ByteData(44 + byteCount);

    void writeString(int offset, String value) {
      for (var index = 0; index < value.length; index++) {
        buffer.setUint8(offset + index, value.codeUnitAt(index));
      }
    }

    writeString(0, 'RIFF');
    buffer.setUint32(4, 36 + byteCount, Endian.little);
    writeString(8, 'WAVE');
    writeString(12, 'fmt ');
    buffer.setUint32(16, 16, Endian.little);
    buffer.setUint16(20, 1, Endian.little);
    buffer.setUint16(22, channelCount, Endian.little);
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(
      28,
      sampleRate * channelCount * bytesPerSample,
      Endian.little,
    );
    buffer.setUint16(32, channelCount * bytesPerSample, Endian.little);
    buffer.setUint16(34, 16, Endian.little);
    writeString(36, 'data');
    buffer.setUint32(40, byteCount, Endian.little);

    final attackSamples = (sampleRate * attackMs / 1000).round();
    final releaseSamples = (sampleRate * releaseMs / 1000).round();
    final pan = spec.pan.clamp(-1.0, 1.0).toDouble();
    final panPosition = (pan + 1) / 2;
    final leftGain = math.cos(panPosition * math.pi / 2);
    final rightGain = math.sin(panPosition * math.pi / 2);
    final twoPi = math.pi * 2;

    var phase = 0.0;
    for (var index = 0; index < sampleCount; index++) {
      final attackEnvelope = attackSamples <= 0
          ? 1.0
          : (index / attackSamples).clamp(0.0, 1.0).toDouble();
      final releaseEnvelope = releaseSamples <= 0
          ? 1.0
          : ((sampleCount - index) / releaseSamples).clamp(0.0, 1.0).toDouble();
      final envelope = math.min(attackEnvelope, releaseEnvelope);
      final t = index / sampleRate;
      final progress = sampleCount <= 1 ? 0.0 : index / (sampleCount - 1);
      final frequency = spec.frequencyEndHz == null
          ? spec.frequencyHz
          : spec.frequencyHz +
                (spec.frequencyEndHz! - spec.frequencyHz) * progress;
      final volumeRamp = spec.outputVolumeEnd == null
          ? 1.0
          : (spec.outputVolume +
                    (spec.outputVolumeEnd! - spec.outputVolume) * progress) /
                math.max(0.001, spec.outputVolume);
      final rhythm = _rhythmEnvelope(
        spec.rhythm,
        t,
        durationMs / 1000,
        rhythmDepth,
      );
      phase += twoPi * frequency / sampleRate;
      final tone = math.sin(phase);
      final softHarmonic = math.sin(phase * 2) * 0.08;
      final sample =
          (tone + softHarmonic) *
          envelope *
          rhythm *
          spec.outputVolume *
          volumeRamp *
          0.72;
      final left = _toPcm16(sample * leftGain);
      final right = _toPcm16(sample * rightGain);
      final offset = 44 + index * channelCount * bytesPerSample;
      buffer.setInt16(offset, left, Endian.little);
      buffer.setInt16(offset + bytesPerSample, right, Endian.little);
    }

    return buffer.buffer.asUint8List();
  }

  static double _rhythmEnvelope(
    _AuditoryRhythm rhythm,
    double t,
    double durationSeconds,
    double depth,
  ) {
    final safeDepth = depth.clamp(0.0, 0.95).toDouble();
    return switch (rhythm) {
      _AuditoryRhythm.steady => 1,
      _AuditoryRhythm.doublePulse =>
        1 - safeDepth * (math.sin(math.pi * 2 * t / durationSeconds * 2).abs()),
      _AuditoryRhythm.triplePulse =>
        1 - safeDepth * (math.sin(math.pi * 2 * t / durationSeconds * 3).abs()),
      _AuditoryRhythm.rising =>
        (1 - safeDepth) + safeDepth * (t / durationSeconds).clamp(0.0, 1.0),
    };
  }

  static int _toPcm16(double value) {
    final normalized = value.clamp(-1.0, 1.0).toDouble();
    return (normalized * 32767).round().clamp(-32768, 32767).toInt();
  }
}

class _AuditoryWaitingMarker extends StatelessWidget {
  const _AuditoryWaitingMarker({
    super.key,
    required this.seed,
    required this.accent,
  });

  final int seed;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final random = math.Random(seed);
    final colorScheme = Theme.of(context).colorScheme;
    final segments = List<Widget>.generate(8, (index) {
      final width = 10.0 + random.nextInt(30);
      final height = 4.0 + random.nextInt(4);
      final top = random.nextDouble() * 16;
      final alpha = 0.18 + random.nextDouble() * 0.34;
      return Padding(
        padding: EdgeInsets.only(top: top, right: index == 7 ? 0 : 7),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: accent.withValues(alpha: alpha),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.22),
            ),
          ),
        ),
      );
    });
    return SizedBox(
      height: 46,
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: segments,
        ),
      ),
    );
  }
}

class _SpatialSpeakerPad extends StatelessWidget {
  const _SpatialSpeakerPad({
    required this.selectedDegrees,
    required this.enabled,
    required this.showLabels,
    required this.accent,
    required this.labelFor,
    required this.shortLabelFor,
    required this.onSelected,
  });

  static const List<double> _angles = <double>[
    0,
    45,
    90,
    135,
    180,
    225,
    270,
    315,
  ];

  static const List<Alignment> _alignments = <Alignment>[
    Alignment(0, -1),
    Alignment(0.76, -0.76),
    Alignment(1, 0),
    Alignment(0.76, 0.76),
    Alignment(0, 1),
    Alignment(-0.76, 0.76),
    Alignment(-1, 0),
    Alignment(-0.76, -0.76),
  ];

  final double? selectedDegrees;
  final bool enabled;
  final bool showLabels;
  final Color accent;
  final String Function(double angle) labelFor;
  final String Function(double angle) shortLabelFor;
  final ValueChanged<double> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 320.0;
        final size = available.clamp(252.0, 330.0).toDouble();
        return Center(
          child: SizedBox.square(
            dimension: size,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: <Widget>[
                Container(
                  width: size * 0.64,
                  height: size * 0.64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.52,
                    ),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                ),
                Container(
                  width: size * 0.28,
                  height: size * 0.28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.surface,
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Icon(
                    Icons.hearing_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                for (var index = 0; index < _angles.length; index += 1)
                  Align(
                    alignment: _alignments[index],
                    child: _SpatialSpeakerButton(
                      key: ValueKey<String>(
                        'auditory-spatial-direction-${_angles[index].round()}',
                      ),
                      angle: _angles[index],
                      selected:
                          selectedDegrees != null &&
                          _AuditoryTestCardState._angleDistance(
                                selectedDegrees!,
                                _angles[index],
                              ) <=
                              1,
                      enabled: enabled,
                      showLabel: showLabels,
                      accent: accent,
                      tooltip: labelFor(_angles[index]),
                      label: shortLabelFor(_angles[index]),
                      onSelected: onSelected,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SpatialSpeakerButton extends StatelessWidget {
  const _SpatialSpeakerButton({
    super.key,
    required this.angle,
    required this.selected,
    required this.enabled,
    required this.showLabel,
    required this.accent,
    required this.tooltip,
    required this.label,
    required this.onSelected,
  });

  final double angle;
  final bool selected;
  final bool enabled;
  final bool showLabel;
  final Color accent;
  final String tooltip;
  final String label;
  final ValueChanged<double> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final foreground = selected
        ? accent
        : enabled
        ? colorScheme.onSurfaceVariant
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.38);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: selected ? accent.withValues(alpha: 0.16) : colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? accent : colorScheme.outlineVariant,
          ),
        ),
        child: InkWell(
          onTap: enabled ? () => onSelected(angle) : null,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: showLabel ? 72 : 54,
            height: showLabel ? 58 : 54,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.speaker_rounded, size: 20, color: foreground),
                if (showLabel) ...<Widget>[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpatialPointerDial extends StatelessWidget {
  const _SpatialPointerDial({
    required this.valueDegrees,
    required this.hasSelection,
    required this.enabled,
    required this.accent,
    required this.label,
    required this.onChanged,
  });

  final double valueDegrees;
  final bool hasSelection;
  final bool enabled;
  final Color accent;
  final String label;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 300.0;
        final size = available.clamp(220.0, 300.0).toDouble();
        void updateFromPosition(Offset position) {
          final center = Offset(size / 2, size / 2);
          final dx = position.dx - center.dx;
          final dy = position.dy - center.dy;
          if (dx.abs() < 0.5 && dy.abs() < 0.5) {
            return;
          }
          final angle = (math.atan2(dx, -dy) * 180 / math.pi + 360) % 360;
          onChanged(angle);
        }

        return Center(
          child: _HumanPointerDragBoundary(
            enabled: enabled,
            behavior: HitTestBehavior.deferToChild,
            onPointerDown: (event) => updateFromPosition(event.localPosition),
            onPointerMove: (event) => updateFromPosition(event.localPosition),
            child: Semantics(
              label: label,
              enabled: enabled,
              child: SizedBox.square(
                dimension: size,
                child: CustomPaint(
                  painter: _SpatialPointerPainter(
                    valueDegrees: valueDegrees,
                    showPointer: hasSelection,
                    accent: accent,
                    ringColor: colorScheme.outlineVariant,
                    fillColor: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.48,
                    ),
                    markerColor: colorScheme.onSurfaceVariant,
                  ),
                  child: Center(
                    child: Container(
                      width: size * 0.46,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SpatialPointerPainter extends CustomPainter {
  const _SpatialPointerPainter({
    required this.valueDegrees,
    required this.showPointer,
    required this.accent,
    required this.ringColor,
    required this.fillColor,
    required this.markerColor,
  });

  final double valueDegrees;
  final bool showPointer;
  final Color accent;
  final Color ringColor;
  final Color fillColor;
  final Color markerColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.43;
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    final ringPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    canvas
      ..drawCircle(center, radius, fillPaint)
      ..drawCircle(center, radius, ringPaint)
      ..drawCircle(center, radius * 0.62, ringPaint);

    final axisPaint = Paint()
      ..color = ringColor.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final angle in const <double>[0, 90, 180, 270]) {
      final start = _polar(center, radius * 0.24, angle);
      final end = _polar(center, radius * 0.92, angle);
      canvas.drawLine(start, end, axisPaint);
    }

    final markerPaint = Paint()
      ..color = markerColor.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;
    for (var index = 0; index < 8; index += 1) {
      final marker = _polar(center, radius * 0.96, index * 45);
      canvas.drawCircle(marker, index.isEven ? 4.4 : 3.1, markerPaint);
    }

    if (!showPointer) {
      return;
    }
    final pointerEnd = _polar(center, radius * 0.74, valueDegrees);
    final pointerPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, pointerEnd, pointerPaint);
    canvas.drawCircle(pointerEnd, 8, Paint()..color = accent);
    canvas.drawCircle(center, 5, Paint()..color = accent);
  }

  static Offset _polar(Offset center, double radius, double degrees) {
    final radians = degrees * math.pi / 180;
    return Offset(
      center.dx + math.sin(radians) * radius,
      center.dy - math.cos(radians) * radius,
    );
  }

  @override
  bool shouldRepaint(covariant _SpatialPointerPainter oldDelegate) {
    return oldDelegate.valueDegrees != valueDegrees ||
        oldDelegate.showPointer != showPointer ||
        oldDelegate.accent != accent ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.markerColor != markerColor;
  }
}

class _AuditorySettingSlider extends StatelessWidget {
  const _AuditorySettingSlider({
    required this.label,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
  });

  final String label;
  final String valueText;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(label)),
              Text(
                valueText,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Slider(
            value: value.clamp(min, max).toDouble(),
            min: min,
            max: max,
            divisions: divisions,
            label: valueText,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
