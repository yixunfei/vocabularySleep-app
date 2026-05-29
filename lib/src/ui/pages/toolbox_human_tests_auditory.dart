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
      title: pickUiText(
        i18n,
        zh: '听觉测试',
        en: 'Auditory test',
        ja: '聴覚テスト',
        de: 'Auditory test',
        fr: 'Test auditif',
        es: 'Prueba de auditoria',
        ru: 'Слуховой тест',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '通过频率、音量和方向任务，观察自己对声音变化的反应。',
        en: 'Use frequency, volume, and direction tasks to observe how you respond to sound changes.',
        ja: 'Use frequency, volume, and direction tasks to observe how you respond to sound changes.',
        de: 'Use frequency, volume, and direction tasks to observe how you respond to sound changes.',
        fr: 'Use frequency, volume, and direction tasks to observe how you respond to sound changes.',
        es: 'Use frequency, volume, and direction tasks to observe how you respond to sound changes.',
        ru: 'Use frequency, volume, and direction tasks to observe how you respond to sound changes.',
      ),
      accent: _accent,
      icon: Icons.hearing_rounded,
      status: pickUiText(
        i18n,
        zh: '戴上耳机，准备好判断声音变化',
        en: 'Next: wear headphones, choose a mode, and start a hearing test set',
        ja: 'Next: wear headphones, choose a mode, and start a hearing test set',
        de: 'Next: wear headphones, choose a mode, and start a hearing test set',
        fr: 'Suivant : porter un casque, choisir un mode et commencer un ensemble de tests auditifs',
        es: 'Siguiente: usar auriculares, elegir un modo y comenzar un set de prueba auditiva',
        ru: 'Следующая статья: Наденьте наушники, выберите режим и запустите тестовый набор для слуха',
      ),
      child: const AuditoryLabPanel(),
    );
  }
}

class _AuditoryModeCopy {
  const _AuditoryModeCopy({
    required this.zhLabel,
    required this.enLabel,
    required this.jaLabel,
    required this.deLabel,
    required this.frLabel,
    required this.esLabel,
    required this.ruLabel,
    required this.zhDescription,
    required this.enDescription,
    required this.jaDescription,
    required this.deDescription,
    required this.frDescription,
    required this.esDescription,
    required this.ruDescription,
    required this.icon,
  });

  final String zhLabel;
  final String enLabel;
  final String jaLabel;
  final String deLabel;
  final String frLabel;
  final String esLabel;
  final String ruLabel;
  final String zhDescription;
  final String enDescription;
  final String jaDescription;
  final String deDescription;
  final String frDescription;
  final String esDescription;
  final String ruDescription;
  final IconData icon;

  String label(AppI18n i18n) => pickUiText(
    i18n,
    zh: zhLabel,
    en: enLabel,
    ja: jaLabel,
    de: deLabel,
    fr: frLabel,
    es: esLabel,
    ru: ruLabel,
  );

  String description(AppI18n i18n) => pickUiText(
    i18n,
    zh: zhDescription,
    en: enDescription,
    ja: jaDescription,
    de: deDescription,
    fr: frDescription,
    es: esDescription,
    ru: ruDescription,
  );
}

class _AuditoryStimulusSpec {
  const _AuditoryStimulusSpec({
    required this.id,
    required this.mode,
    required this.zhLabel,
    required this.enLabel,
    required this.jaLabel,
    required this.deLabel,
    required this.frLabel,
    required this.esLabel,
    required this.ruLabel,
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
  final String zhLabel;
  final String enLabel;
  final String jaLabel;
  final String deLabel;
  final String frLabel;
  final String esLabel;
  final String ruLabel;
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
    required this.labelZh,
    required this.labelEn,
    required this.labelJa,
    required this.labelDe,
    required this.labelFr,
    required this.labelEs,
    required this.labelRu,
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
  final String labelZh;
  final String labelEn;
  final String labelJa;
  final String labelDe;
  final String labelFr;
  final String labelEs;
  final String labelRu;
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

  String label(AppI18n i18n) => pickUiText(
    i18n,
    zh: labelZh,
    en: labelEn,
    ja: labelJa,
    de: labelDe,
    fr: labelFr,
    es: labelEs,
    ru: labelRu,
  );
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
      zhLabel: '频率',
      enLabel: 'Frequency',
      jaLabel: '周波数',
      deLabel: 'Frequenz',
      frLabel: 'Fréquence',
      esLabel: 'Frecuencia',
      ruLabel: 'Частота',
      zhDescription: '逐步提高频率、音量和节奏复杂度；听到声音后点击。',
      enDescription:
          'Hear varied frequencies and rhythmic loudness; tap when audible.',
      jaDescription: '周波数、音量、リズムの変化を聞き、聞こえたらタップします。',
      deDescription:
          'Höre wechselnde Frequenzen, Lautstärken und Rhythmen und tippe, wenn du den Ton hörst.',
      frDescription:
          'Écoutez des fréquences, volumes et rythmes variés, puis touchez dès que vous entendez le son.',
      esDescription:
          'Escucha frecuencias, volúmenes y ritmos variados; toca cuando oigas el sonido.',
      ruDescription:
          'Слушайте разные частоты, громкость и ритмы, затем нажимайте, когда слышите звук.',
      icon: Icons.graphic_eq_rounded,
    ),
    _AuditoryMode.sensitivity: _AuditoryModeCopy(
      zhLabel: '灵敏度',
      enLabel: 'Sensitivity',
      jaLabel: '感度',
      deLabel: 'Empfindlichkeit',
      frLabel: 'Sensibilité',
      esLabel: 'Sensibilidad',
      ruLabel: 'Чувствительность',
      zhDescription: '围绕选定频率估计可听音量下限。',
      enDescription:
          'Check audible volume levels around a selected base frequency.',
      jaDescription: '選んだ基準周波数で、聞き取れる音量の範囲を確認します。',
      deDescription:
          'Prüfe hörbare Lautstärken rund um eine ausgewählte Grundfrequenz.',
      frDescription:
          'Vérifiez les niveaux audibles autour d’une fréquence de référence.',
      esDescription:
          'Comprueba los niveles audibles alrededor de una frecuencia base.',
      ruDescription:
          'Проверьте слышимые уровни громкости вокруг выбранной базовой частоты.',
      icon: Icons.volume_up_rounded,
    ),
    _AuditoryMode.spatial: _AuditoryModeCopy(
      zhLabel: '空间',
      enLabel: 'Spatial',
      jaLabel: '空間',
      deLabel: 'Richtung',
      frLabel: 'Espace',
      esLabel: 'Espacio',
      ruLabel: 'Пространство',
      zhDescription: '判断声源方向，并用空间按钮或指针标记感知位置。',
      enDescription:
          'Localize the sound direction and mark the perceived position with the slider.',
      jaDescription: '音の方向を聞き分け、感じた位置をスライダーで示します。',
      deDescription:
          'Bestimme die Richtung des Tons und markiere die wahrgenommene Position.',
      frDescription:
          'Repérez la direction du son et indiquez la position perçue.',
      esDescription:
          'Ubica la dirección del sonido y marca la posición percibida.',
      ruDescription:
          'Определите направление звука и отметьте предполагаемое положение.',
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
        zhLabel: '预览',
        enLabel: 'Preview',
        jaLabel: 'プレビュー',
        deLabel: 'Vorschau',
        frLabel: 'Aperçu',
        esLabel: 'Vista previa',
        ruLabel: 'Предпросмотр',
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
        zhLabel: '${_formatFrequency(frequency)} 阶梯',
        enLabel: '${_formatFrequency(frequency)} step',
        jaLabel: '${_formatFrequency(frequency)} ステップ',
        deLabel: '${_formatFrequency(frequency)} Stufe',
        frLabel: '${_formatFrequency(frequency)} palier',
        esLabel: '${_formatFrequency(frequency)} paso',
        ruLabel: '${_formatFrequency(frequency)} шаг',
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
            zhLabel: '${(level * 100).round()}% 阶梯',
            enLabel: '${(level * 100).round()}% step',
            jaLabel: '${(level * 100).round()}% ステップ',
            deLabel: '${(level * 100).round()}% Stufe',
            frLabel: '${(level * 100).round()}% palier',
            esLabel: '${(level * 100).round()}% paso',
            ruLabel: '${(level * 100).round()}% шаг',
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
            zhLabel: '${angle.round()}°',
            enLabel: '${angle.round()}°',
            jaLabel: '${angle.round()}°',
            deLabel: '${angle.round()}°',
            frLabel: '${angle.round()}°',
            esLabel: '${angle.round()}°',
            ruLabel: '${angle.round()}°',
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
          labelZh: stimulus.zhLabel,
          labelEn: stimulus.enLabel,
          labelJa: stimulus.jaLabel,
          labelDe: stimulus.deLabel,
          labelFr: stimulus.frLabel,
          labelEs: stimulus.esLabel,
          labelRu: stimulus.ruLabel,
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
          title: pickUiText(
            i18n,
            zh: '听觉设置',
            en: 'Auditory settings',
            ja: '聴覚設定',
            de: 'Auditory settings',
            fr: 'Paramètres auditifs',
            es: 'Ajustes de los auditores',
            ru: 'Аудиторские настройки',
          ),
          subtitle: pickUiText(
            i18n,
            zh: '频率、音量、方向和报告选项都在这里。',
            en: 'Adjust frequency groups, volume ladders, spatial directions, previews, and report style.',
            ja: 'Adjust frequency groups, volume ladders, spatial directions, previews, and report style.',
            de: 'Adjust frequency groups, volume ladders, spatial directions, previews, and report style.',
            fr: 'Adjust frequency groups, volume ladders, spatial directions, previews, and report style.',
            es: 'Adjust frequency groups, volume ladders, spatial directions, previews, and report style.',
            ru: 'Adjust frequency groups, volume ladders, spatial directions, previews, and report style.',
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
        ? pickUiText(
            i18n,
            zh: '定位',
            en: 'Localization',
            ja: 'Localization',
            de: 'Localization',
            fr: 'Localisation',
            es: 'Localización',
            ru: 'Локализация',
          )
        : pickUiText(
            i18n,
            zh: '听到率',
            en: 'Heard rate',
            ja: 'Heard rate',
            de: 'Heard rate',
            fr: 'Taux d\'écoute',
            es: 'Tasa de riesgo',
            ru: 'Показатель слуха',
          );
    return <(String, String)>[
      (
        pickUiText(
          i18n,
          zh: '进度',
          en: 'Progress',
          ja: 'Progress',
          de: 'Progress',
          fr: 'Progrès accomplis',
          es: 'Progresos',
          ru: 'Прогресс',
        ),
        '$_roundIndex/$_targetRoundCount',
      ),
      (
        pickUiText(
          i18n,
          zh: '模式',
          en: 'Mode',
          ja: 'Mode',
          de: 'Mode',
          fr: 'Mode',
          es: 'Modo',
          ru: 'Режим',
        ),
        _modeCopies[_mode]!.label(i18n),
      ),
      (scoreLabel, '${(_scoreRatio * 100).round()}%'),
      (
        _mode == _AuditoryMode.spatial
            ? pickUiText(
                i18n,
                zh: '平均偏差',
                en: 'Avg error',
                ja: '平均エラー',
                de: 'Avg error',
                fr: 'Erreur Avg',
                es: 'Error de Avg',
                ru: 'ошибка Avg',
              )
            : pickUiText(
                i18n,
                zh: '平均反应',
                en: 'Avg response',
                ja: '平均応答',
                de: 'Avg response',
                fr: 'Réponse',
                es: 'Respuesta de Avg',
                ru: 'Авг ответ',
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
                  pickUiText(
                    i18n,
                    zh: '合成音播放失败，已尝试使用系统提示音兜底。',
                    en: 'Synthetic tone playback failed; a system alert fallback was attempted.',
                    ja: 'Synthetic tone playback failed; a system alert fallback was attempted.',
                    de: 'Synthetic tone playback failed; a system alert fallback was attempted.',
                    fr: 'La lecture de tons synthétiques a échoué; une alerte système a été tentée.',
                    es: 'Falló la reproducción de tono sintético; se intentó un retroceso de alerta del sistema.',
                    ru: 'Воспроизведение синтетического тона не удалось; была предпринята попытка восстановления системного оповещения.',
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
                    pickUiText(
                      i18n,
                      zh: '听到后点击',
                      en: 'Tap when heard',
                      ja: 'Tap when heard',
                      de: 'Tap when heard',
                      fr: 'Tapez quand vous avez entendu',
                      es: 'Toca cuando se escucha',
                      ru: 'Прыжок, когда слышно',
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
                    label: pickUiText(
                      i18n,
                      zh: '开始',
                      en: 'Start',
                      ja: 'Start',
                      de: 'Start',
                      fr: 'Démarrer',
                      es: 'Comienzo',
                      ru: 'Начинать',
                    ),
                    icon: Icons.play_arrow_rounded,
                    onPressed: _busy ? null : _start,
                  ),
                  OutlinedButton.icon(
                    onPressed: _sessionRunning || _busy
                        ? () => _reset(clearMode: false)
                        : null,
                    icon: const Icon(Icons.stop_rounded),
                    label: Text(pickUiText(i18n, zh: '结束', en: 'Stop')),
                  ),
                  OutlinedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(
                      pickUiText(
                        i18n,
                        zh: '重置',
                        en: 'Reset',
                        ja: 'Reset',
                        de: 'Reset',
                        fr: 'Réinitialiser',
                        es: 'Reset',
                        ru: 'сброс',
                      ),
                    ),
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
                        pickUiText(
                          i18n,
                          zh: '重播',
                          en: 'Replay',
                          ja: 'Replay',
                          de: 'Replay',
                          fr: 'Rejouer',
                          es: 'Replay',
                          ru: 'воспроизведение',
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
                ? pickUiText(
                    i18n,
                    zh: '上一轮已记录',
                    en: 'Last round recorded',
                    ja: 'Last round recorded',
                    de: 'Last round recorded',
                    fr: 'Dernier tour enregistré',
                    es: 'Última ronda grabada',
                    ru: 'Последний раунд записан',
                  )
                : pickUiText(
                    i18n,
                    zh: '上一轮未命中',
                    en: 'Last round missed',
                    ja: 'Last round missed',
                    de: 'Last round missed',
                    fr: 'Dernier tour manqué',
                    es: 'Última ronda perdida',
                    ru: 'Последний пропущенный раунд',
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
                pickUiText(
                  i18n,
                  zh: '八向面板',
                  en: '8-way pad',
                  ja: '8方向パッド',
                  de: '8-way pad',
                  fr: '8-way pad',
                  es: 'Almohadilla de 8 vías',
                  ru: '8-полосная площадка',
                ),
              ),
              icon: const Icon(Icons.diamond_outlined),
            ),
            ButtonSegment<_SpatialInputMode>(
              value: _SpatialInputMode.pointer,
              label: Text(
                pickUiText(
                  i18n,
                  zh: '方向指针',
                  en: 'Pointer',
                  ja: 'Pointer',
                  de: 'Pointer',
                  fr: 'Pointeur',
                  es: 'Pointer',
                  ru: 'указатель',
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
            pickUiText(
              i18n,
              zh: '确认位置',
              en: 'Confirm position',
              ja: 'する',
              de: 'Confirm position',
              fr: 'Confirmer la position',
              es: 'Confirmación de posición',
              ru: 'Подтвердить позицию',
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
          label: pickUiText(
            i18n,
            zh: '测试轮数',
            en: 'Rounds',
            ja: 'Rounds',
            de: 'Rounds',
            fr: 'Rondes',
            es: 'Rondas',
            ru: 'Круги',
          ),
          valueText: pickUiText(
            i18n,
            zh: '$roundCount 轮',
            en: '$roundCount rounds',
            ja: '$roundCountラウンド',
            de: '$roundCount rounds',
            fr: '$roundCount rounds',
            es: '&gt; &gt; &gt;',
            ru: '$roundCount раунды',
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
          pickUiText(
            i18n,
            zh: '频率模式建议 10 轮，其它模式可按需调整。',
            en: 'Frequency defaults to 10 rounds, and each mode can be customized.',
            ja: 'Frequency defaults to 10 rounds, and each mode can be customized.',
            de: 'Frequency defaults to 10 rounds, and each mode can be customized.',
            fr: 'La fréquence par défaut à 10 tours, et chaque mode peut être personnalisé.',
            es: 'Frecuencia predeterminada a 10 rondas, y cada modo se puede personalizar.',
            ru: 'Частота по умолчанию до 10 раундов, и каждый режим можно настроить.',
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
          pickUiText(
            i18n,
            zh: '玩法细节',
            en: 'Mode settings',
            ja: 'Mode settings',
            de: 'Mode settings',
            fr: 'Paramètres du mode',
            es: 'Ajustes del modo',
            ru: 'Настройки режимов',
          ),
        ),
        if (_mode == _AuditoryMode.frequency) _buildFrequencySettings(i18n),
        if (_mode == _AuditoryMode.sensitivity) _buildSensitivitySettings(i18n),
        if (_mode == _AuditoryMode.spatial) _buildSpatialSettings(i18n),
        const SizedBox(height: 14),
        _sectionLabel(
          pickUiText(
            i18n,
            zh: '播放与报告',
            en: 'Playback and report',
            ja: 'Playback and report',
            de: 'Playback and report',
            fr: 'Lecture et rapport',
            es: 'Retorno e informe',
            ru: 'Воспроизведение и отчет',
          ),
        ),
        _AuditorySettingSlider(
          label: pickUiText(
            i18n,
            zh: '单音时长',
            en: 'Tone duration',
            ja: 'Tone duration',
            de: 'Tone duration',
            fr: 'Durée de la tonalité',
            es: 'Duración del tono',
            ru: 'Длительность тонуса',
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
          label: pickUiText(
            i18n,
            zh: '响应窗口',
            en: 'Response window',
            ja: 'Response window',
            de: 'Response window',
            fr: 'Fenêtre de réponse',
            es: 'ventana de respuesta',
            ru: 'Окно отклика',
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
            pickUiText(
              i18n,
              zh: '允许重播',
              en: 'Allow replay',
              ja: '許可リプレイを許可',
              de: 'Allow replay',
              fr: 'Permettre un replay',
              es: 'Permitir la repetición',
              ru: 'Разрешить воспроизведение',
            ),
          ),
          value: _allowReplay,
          onChanged: (value) => setState(() => _allowReplay = value),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(
            pickUiText(
              i18n,
              zh: '详细分组报告',
              en: 'Detailed group report',
              ja: 'Detailed group report',
              de: 'Detailed group report',
              fr: 'Rapport détaillé du groupe',
              es: 'Informe del grupo detallado',
              ru: 'Подробный доклад группы',
            ),
          ),
          value: _showGroupReport,
          onChanged: (value) => setState(() => _showGroupReport = value),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(
            pickUiText(
              i18n,
              zh: '显示详细记录',
              en: 'Show details',
              ja: '詳細を表示',
              de: 'Details anzeigen',
              fr: 'Afficher les détails',
              es: 'Mostrar detalles',
              ru: 'Показать детали',
            ),
          ),
          value: _showRawData,
          onChanged: (value) => setState(() => _showRawData = value),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(
            pickUiText(
              i18n,
              zh: '自动弹出报告',
              en: 'Auto report',
              ja: '自動レポート',
              de: 'Auto report',
              fr: 'Rapport automatique',
              es: 'Informe automático',
              ru: 'Автоотчет',
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
                pickUiText(
                  i18n,
                  zh: '试听当前模式',
                  en: 'Preview current mode',
                  ja: 'Preview current mode',
                  de: 'Preview current mode',
                  fr: 'Aperçu du mode actuel',
                  es: 'Previsualizar el modo actual',
                  ru: 'Предварительный просмотр текущего режима',
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _records.isEmpty
                  ? null
                  : () => unawaited(_showReport()),
              icon: const Icon(Icons.summarize_rounded),
              label: Text(
                pickUiText(
                  i18n,
                  zh: '查看报告',
                  en: 'View report',
                  ja: 'View report',
                  de: 'View report',
                  fr: 'Consulter le rapport',
                  es: 'Ver informe',
                  ru: 'Посмотреть доклад',
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
          pickUiText(
            i18n,
            zh: '频率范围',
            en: 'Frequency range',
            ja: 'Frequency range',
            de: 'Frequency range',
            fr: 'Plage de fréquences',
            es: 'Rango de frecuencia',
            ru: 'Частотный диапазон',
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
          label: pickUiText(
            i18n,
            zh: '分析频段',
            en: 'Analysis bands',
            ja: '分析バンド',
            de: 'Analysis bands',
            fr: 'Bandes d\'analyse',
            es: 'Bandas de análisis',
            ru: 'Полосы анализа',
          ),
          values: bandOptions,
          selected: _analysisBands,
          labelFor: (value) => '$value',
          onSelected: (value) => setState(() => _analysisBands = value),
        ),
        _AuditorySettingSlider(
          label: pickUiText(
            i18n,
            zh: '频率音量标尺',
            en: 'Frequency volume scale',
            ja: 'Frequency volume scale',
            de: 'Frequency volume scale',
            fr: 'Échelle de volume de fréquence',
            es: 'Escala de volumen de frecuencia',
            ru: 'Масштаб частотных объемов',
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
          label: pickUiText(
            i18n,
            zh: '节奏响度深度',
            en: 'Rhythmic loudness depth',
            ja: 'Rhythmic loudness depth',
            de: 'Rhythmic loudness depth',
            fr: 'Profondeur de bruit rythmique',
            es: 'Profundidad de ruido rítmico',
            ru: 'Ритмическая глубина громкости',
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
            pickUiText(
              i18n,
              zh: '混合节奏模式',
              en: 'Mix rhythm patterns',
              ja: 'Mix rhythm patterns',
              de: 'Mix rhythm patterns',
              fr: 'Mélanger les rythmes',
              es: 'Patrones de ritmo mixto',
              ru: 'Смешайте ритмические паттерны',
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
          label: pickUiText(
            i18n,
            zh: '基准频率',
            en: 'Base frequency',
            ja: '基本周波数',
            de: 'Base frequency',
            fr: 'Fréquence de base',
            es: 'Frecuencia de la base',
            ru: 'Базовая частота',
          ),
          values: _baseFrequencies,
          selected: _sensitivityBaseFrequency,
          labelFor: _formatFrequency,
          onSelected: (value) =>
              setState(() => _sensitivityBaseFrequency = value),
        ),
        _choiceRow<int>(
          label: pickUiText(
            i18n,
            zh: '灵敏度阶数',
            en: 'Sensitivity levels',
            ja: 'Sensitivity levels',
            de: 'Sensitivity levels',
            fr: 'Niveaux de sensibilité',
            es: 'Niveles de sensibilidad',
            ru: 'Уровни чувствительности',
          ),
          values: levelOptions,
          selected: _sensitivityLevelCount,
          labelFor: (value) => '$value',
          onSelected: (value) => setState(() => _sensitivityLevelCount = value),
        ),
        _AuditorySettingSlider(
          label: pickUiText(
            i18n,
            zh: '最低输出',
            en: 'Minimum output',
            ja: 'Minimum output',
            de: 'Minimum output',
            fr: 'Sortie minimale',
            es: 'Producción mínima',
            ru: 'Минимальный выход',
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
          label: pickUiText(
            i18n,
            zh: '最高输出',
            en: 'Maximum output',
            ja: 'Maximum output',
            de: 'Maximum output',
            fr: 'Sortie maximale',
            es: 'Producción máxima',
            ru: 'Максимальный выход',
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
            pickUiText(
              i18n,
              zh: '对数音量阶梯',
              en: 'Log volume steps',
              ja: 'Log volume steps',
              de: 'Log volume steps',
              fr: 'Étapes de l\'enregistrement du volume',
              es: 'Pasos del volumen de registro',
              ru: 'Лог объемных шагов',
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
          label: pickUiText(
            i18n,
            zh: '方向数量',
            en: 'Direction count',
            ja: 'Direction count',
            de: 'Direction count',
            fr: 'Nombre de directions',
            es: 'Cuenta de dirección',
            ru: 'Прямой счет',
          ),
          values: directionOptions,
          selected: _directionCount,
          labelFor: (value) => '$value',
          onSelected: (value) => setState(() => _directionCount = value),
        ),
        _AuditorySettingSlider(
          label: pickUiText(
            i18n,
            zh: '空间音量',
            en: 'Spatial volume',
            ja: 'Spatial volume',
            de: 'Spatial volume',
            fr: 'Volume spatial',
            es: 'Volumen espacial',
            ru: 'Пространственный объем',
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
          label: pickUiText(
            i18n,
            zh: '空间容差',
            en: 'Spatial tolerance',
            ja: 'Spatial tolerance',
            de: 'Spatial tolerance',
            fr: 'Tolérance spatiale',
            es: 'Tolerancia espacial',
            ru: 'Пространственная толерантность',
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
          label: pickUiText(
            i18n,
            zh: '指针平滑',
            en: 'Slider smoothing',
            ja: 'Slider smoothing',
            de: 'Slider smoothing',
            fr: 'Slider lissant',
            es: 'Flujo deslizante',
            ru: 'Сглаживание слайдера',
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
            pickUiText(
              i18n,
              zh: '自定义方向',
              en: 'Custom direction',
              ja: 'Custom direction',
              de: 'Custom direction',
              fr: 'Direction personnalisée',
              es: 'Dirección personalizada',
              ru: 'Индивидуальное направление',
            ),
          ),
          value: _customSpatialDirection,
          onChanged: _busy
              ? null
              : (value) => setState(() => _customSpatialDirection = value),
        ),
        if (_customSpatialDirection)
          _AuditorySettingSlider(
            label: pickUiText(
              i18n,
              zh: '自定义目标方向',
              en: 'Custom target direction',
              ja: 'Custom target direction',
              de: 'Custom target direction',
              fr: 'Direction de la cible personnalisée',
              es: 'Dirección de destino personalizada',
              ru: 'Пользовательское целевое направление',
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
            pickUiText(
              i18n,
              zh: '显示方向标签',
              en: 'Show direction labels',
              ja: 'Show direction labels',
              de: 'Show direction labels',
              fr: 'Afficher les étiquettes de direction',
              es: 'Mostrar etiquetas de dirección',
              ru: 'Показать этикетки направления',
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
            pickUiText(
              i18n,
              zh: '听觉测试报告',
              en: 'Auditory test report',
              ja: '聴覚テストレポート',
              de: 'Auditory test report',
              fr: 'Rapport d\'essai auditif',
              es: 'Informe de prueba de auditores',
              ru: 'Отчет об испытаниях',
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
                          ? pickUiText(
                              i18n,
                              zh: '定位',
                              en: 'Localization',
                              ja: 'Localization',
                              de: 'Localization',
                              fr: 'Localisation',
                              es: 'Localización',
                              ru: 'Локализация',
                            )
                          : pickUiText(
                              i18n,
                              zh: '听到率',
                              en: 'Heard rate',
                              ja: 'Heard rate',
                              de: 'Heard rate',
                              fr: 'Taux d\'écoute',
                              es: 'Tasa de riesgo',
                              ru: 'Показатель слуха',
                            ),
                      '${(_scoreRatio * 100).round()}%',
                    ),
                    (
                      pickUiText(
                        i18n,
                        zh: '平均反应',
                        en: 'Avg response',
                        ja: '平均応答',
                        de: 'Avg response',
                        fr: 'Réponse',
                        es: 'Respuesta de Avg',
                        ru: 'Авг ответ',
                      ),
                      _averageMs == 0 ? '-' : _formatMilliseconds(_averageMs),
                    ),
                    (
                      pickUiText(
                        i18n,
                        zh: '最佳连击',
                        en: 'Best streak',
                        ja: 'ベストストリーク',
                        de: 'Best streak',
                        fr: 'Meilleure série',
                        es: 'La mejor racha',
                        ru: 'Лучшая полоса',
                      ),
                      '$_bestStreak',
                    ),
                    (
                      pickUiText(
                        i18n,
                        zh: '未命中',
                        en: 'Misses',
                        ja: 'Misses',
                        de: 'Misses',
                        fr: 'Mlle',
                        es: 'Misses',
                        ru: 'Мисс.',
                      ),
                      '$_misses',
                    ),
                    (
                      pickUiText(
                        i18n,
                        zh: '抢答',
                        en: 'False starts',
                        ja: 'False starts',
                        de: 'False starts',
                        fr: 'Faux départs',
                        es: 'False comienza',
                        ru: 'Ложные старты',
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
                  pickUiText(
                    i18n,
                    zh: '提醒：设备、耳机和环境都会影响结果。这里适合日常观察和练习对比，不能替代专业检查。',
                    en: 'Note: device, headphones, and room conditions can affect results. Use this for everyday observation and practice comparison; it does not replace a professional check.',
                    ja: '注: 端末、イヤホン、部屋の状態によって結果は変わります。日々の観察や練習の比較に使い、専門的な確認の代わりにはしないでください。',
                    de: 'Hinweis: Gerät, Kopfhörer und Raum können die Ergebnisse beeinflussen. Nutze sie für Alltag, Übung und Vergleich; sie ersetzen keine fachliche Kontrolle.',
                    fr: 'Remarque : l’appareil, les écouteurs et la pièce peuvent influencer les résultats. Utilisez-les pour observer et comparer vos entraînements ; ils ne remplacent pas un contrôle professionnel.',
                    es: 'Nota: el dispositivo, los auriculares y la habitación pueden influir en los resultados. Úsalos para observar y comparar tu práctica; no sustituyen una revisión profesional.',
                    ru: 'Примечание: устройство, наушники и комната могут влиять на результаты. Используйте их для наблюдения и сравнения тренировок; они не заменяют профессиональную проверку.',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                pickUiText(
                  i18n,
                  zh: '关闭',
                  en: 'Close',
                  ja: '閉じる',
                  de: 'Close',
                  fr: 'Fermer',
                  es: 'Cerca',
                  ru: 'Закрыть',
                ),
              ),
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
            pickUiText(
              i18n,
              zh: '详细分组',
              en: 'Detailed groups',
              ja: '詳細グループ',
              de: 'Detaillierte Gruppen',
              fr: 'Groupes détaillés',
              es: 'Grupos detallados',
              ru: 'Подробные группы',
            ),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            switch (_mode) {
              _AuditoryMode.frequency => pickUiText(
                i18n,
                zh: '高频截止估计: ${estimatedFrequencyCutoff == null ? '--' : _formatFrequency(estimatedFrequencyCutoff)}',
                en: 'Estimated high-frequency cutoff: ${estimatedFrequencyCutoff == null ? '--' : _formatFrequency(estimatedFrequencyCutoff)}',
                ja: '高周波の推定上限: ${estimatedFrequencyCutoff == null ? '--' : _formatFrequency(estimatedFrequencyCutoff)}',
                de: 'Geschätzte Hochfrequenzgrenze: ${estimatedFrequencyCutoff == null ? '--' : _formatFrequency(estimatedFrequencyCutoff)}',
                fr: 'Limite haute fréquence estimée : ${estimatedFrequencyCutoff == null ? '--' : _formatFrequency(estimatedFrequencyCutoff)}',
                es: 'Límite estimado de alta frecuencia: ${estimatedFrequencyCutoff == null ? '--' : _formatFrequency(estimatedFrequencyCutoff)}',
                ru: 'Оценка верхней частоты: ${estimatedFrequencyCutoff == null ? '--' : _formatFrequency(estimatedFrequencyCutoff)}',
              ),
              _AuditoryMode.sensitivity => pickUiText(
                i18n,
                zh: '估计可听下限: ${(_estimatedThreshold() * 100).round()}%',
                en: 'Estimated audible threshold: ${(_estimatedThreshold() * 100).round()}%',
                ja: '推定可聴しきい値: ${(_estimatedThreshold() * 100).round()}%',
                de: 'Geschätzte Hörschwelle: ${(_estimatedThreshold() * 100).round()}%',
                fr: 'Seuil sonore estimé: ${(_estimatedThreshold() * 100).round()}%',
                es: 'Umbral audible estimado: ${(_estimatedThreshold() * 100).round()}%',
                ru: 'Оценка порога слышимости: ${(_estimatedThreshold() * 100).round()}%',
              ),
              _AuditoryMode.spatial => pickUiText(
                i18n,
                zh: '平均方位误差: ${_averageSpatialError.round()}°',
                en: 'Average direction error: ${_averageSpatialError.round()}°',
                ja: '平均方向誤差: ${_averageSpatialError.round()}°',
                de: 'Durchschnittlicher Richtungsfehler: ${_averageSpatialError.round()}°',
                fr: 'Erreur de direction moyenne : ${_averageSpatialError.round()}°',
                es: 'Error medio de dirección: ${_averageSpatialError.round()}°',
                ru: 'Средняя ошибка направления: ${_averageSpatialError.round()}°',
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
      return '${index + 1}. ${pickUiText(i18n, zh: '输出', en: 'Output', ja: 'Output', de: 'Output', fr: 'Produit', es: 'Producto', ru: 'выход')} ${level.toStringAsFixed(2)}: $heard/$total ($ratio%)';
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
        return pickUiText(
          i18n,
          zh: '可以先用 8 个方向、宽裕容差和较高空间音量建立基准，稳定后再切到 12 或 16 个方向。',
          en: 'Suggestion: start with 8 directions, wider tolerance, and higher spatial volume; move to 16 directions after results stabilize.',
          ja: 'Suggestion: start with 8 directions, wider tolerance, and higher spatial volume; move to 16 directions after results stabilize.',
          de: 'Suggestion: start with 8 directions, wider tolerance, and higher spatial volume; move to 16 directions after results stabilize.',
          fr: 'Suggestion : commencer par 8 directions, une tolérance plus grande et un volume spatial plus élevé; passer à 16 directions après stabilisation des résultats.',
          es: 'Sugerencia: empezar con 8 direcciones, mayor tolerancia y mayor volumen espacial; pasar a 16 direcciones después de que los resultados se estabilicen.',
          ru: 'Предложение: начать с 8 направлений, более широкой терпимости и более высокого пространственного объема; перейти к 16 направлениям после стабилизации результатов.',
        );
      }
      return pickUiText(
        i18n,
        zh: '定位已经比较稳，可以提高方向数或收紧容差，继续细分方位。',
        en: 'Suggestion: localization is stable; increase direction count or reduce tolerance.',
        ja: '提案: 方向の聞き分けは安定しています。方向数を増やすか、許容範囲を少し狭めてみましょう。',
        de: 'Vorschlag: Die Richtungswahrnehmung ist stabil. Erhöhe die Richtungsanzahl oder verringere die Toleranz.',
        fr: 'Suggestion : la localisation est stable; augmenter le nombre de directions ou réduire la tolérance.',
        es: 'Sugerencia: la localización es estable; aumentar el número de dirección o reducir la tolerancia.',
        ru: 'Локализация стабильна; увеличить количество направлений или уменьшить толерантность.',
      );
    }
    final high = _records
        .where((record) => record.frequencyHz >= 4000)
        .toList(growable: false);
    final highRate = high.isEmpty
        ? 1.0
        : high.where((record) => record.heard).length / high.length;
    if (_mode == _AuditoryMode.frequency && highRate < 0.6) {
      return pickUiText(
        i18n,
        zh: '如果高频可闻性偏弱，可以把上限缩到 6000-8000 Hz，并用 16-20 组重新测一次。',
        en: 'Suggestion: if high-frequency audibility is weak, narrow the top range to 6000-8000 Hz and retest with 16-20 groups.',
        ja: 'Suggestion: if high-frequency audibility is weak, narrow the top range to 6000-8000 Hz and retest with 16-20 groups.',
        de: 'Suggestion: if high-frequency audibility is weak, narrow the top range to 6000-8000 Hz and retest with 16-20 groups.',
        fr: 'Suggestion : si l\'audibilité à haute fréquence est faible, réduire la gamme supérieure à 6000-8000 Hz et tester de nouveau avec 16-20 groupes.',
        es: 'Sugerencia: si la audibilidad de alta frecuencia es débil, estrecha el rango superior a 6000-8000 Hz y retesta con 16-20 grupos.',
        ru: 'Предложение: если высокочастотная слышимость слаба, сузьте верхний диапазон до 6000-8000 Гц и повторно протестируйте с 16-20 группами.',
      );
    }
    if (_mode == _AuditoryMode.sensitivity) {
      final threshold = _estimatedThreshold();
      return pickUiText(
        i18n,
        zh: '估计可听下限约 ${(threshold * 100).round()}%。可以降低最低输出，并用 16-20 阶重测。',
        en: 'Suggestion: estimated audible threshold is about ${(threshold * 100).round()}%. Lower the minimum output and retest with 16-20 levels.',
        ja: 'Suggestion: estimated audible threshold is about ${(threshold * 100).round()}%. Lower the minimum output and retest with 16-20 levels.',
        de: 'Suggestion: estimated audible threshold is about ${(threshold * 100).round()}%. Lower the minimum output and retest with 16-20 levels.',
        fr: 'Suggestion : le seuil sonore estimé est d\'environ ${(threshold * 100).round()}%. Abaissez la sortie minimale et retestez avec 16-20 niveaux.',
        es: 'Sugerencia: umbral audible estimado es alrededor de יv0/%. Disminuya la producción y la prueba mínima con 16-20 niveles.',
        ru: 'Предложение: оценочный звуковой порог составляет около ${(threshold * 100).round()}%. Снижение минимального выхода и повторный тест с 16-20 уровнями.',
      );
    }
    return pickUiText(
      i18n,
      zh: '当前设置可以继续保留；如果结果波动较大，可以增加轮数，并减小节奏音量变化。',
      en: 'Suggestion: keep this setup; if results fluctuate, increase test size and lower rhythmic loudness depth.',
      ja: 'Suggestion: keep this setup; if results fluctuate, increase test size and lower rhythmic loudness depth.',
      de: 'Suggestion: keep this setup; if results fluctuate, increase test size and lower rhythmic loudness depth.',
      fr: 'Suggestion : conservez cette configuration ; si les résultats fluctuent, augmentez la taille du test et réduisez la profondeur rythmique.',
      es: 'Sugerencia: mantener esta configuración; si los resultados fluctúan, aumentar el tamaño de la prueba y bajar la profundidad de ruido rítmico.',
      ru: 'Предложение: сохранить эту настройку; если результаты колеблются, увеличить размер теста и снизить глубину ритмической громкости.',
    );
  }

  String _phaseText(AppI18n i18n) {
    return switch (_phase) {
      _AuditoryPhase.idle => pickUiText(
        i18n,
        zh: '点击开始后，听到声音立即点击按钮响应。',
        en: 'Press start and wait for a random sound.',
        ja: 'Press start and wait for a random sound.',
        de: 'Press start and wait for a random sound.',
        fr: 'Appuyez sur Démarrer et attendre un son aléatoire.',
        es: 'Presione el inicio y espere un sonido aleatorio.',
        ru: 'Нажмите «Пуск» и ждите случайного звука.',
      ),
      _AuditoryPhase.waiting => _activePhaseText(i18n),
      _AuditoryPhase.cue => _activePhaseText(i18n),
      _AuditoryPhase.done => pickUiText(
        i18n,
        zh: '测试完成，可查看报告或重新开始。',
        en: 'Session complete. View the report or restart.',
        ja: 'Session complete. View the report or restart.',
        de: 'Session complete. View the report or restart.',
        fr: 'La séance est terminée. Affiche le rapport ou redémarre.',
        es: 'Sesión completa. Vea el informe o reinicie.',
        ru: 'Заседание завершено. Посмотреть отчет или перезапустить.',
      ),
    };
  }

  String _activePhaseText(AppI18n i18n) {
    if (_mode == _AuditoryMode.spatial) {
      return pickUiText(
        i18n,
        zh: '保持专注，听到声音后选择感知方位。',
        en: 'Stay focused. Choose the perceived direction when you hear the sound.',
        ja: 'Stay focused. Choose the perceived direction when you hear the sound.',
        de: 'Stay focused. Choose the perceived direction when you hear the sound.',
        fr: 'Restez concentré. Choisissez la direction perçue lorsque vous entendez le son.',
        es: 'Mantente concentrado. Elija la dirección percibida cuando escuche el sonido.',
        ru: 'Сосредоточься. Выберите направление восприятия, когда вы слышите звук.',
      );
    }
    return pickUiText(
      i18n,
      zh: '保持专注，听到声音后点击。',
      en: 'Stay focused. Tap when you hear the sound.',
      ja: 'Stay focused. Tap when you hear the sound.',
      de: 'Stay focused. Tap when you hear the sound.',
      fr: 'Restez concentré. Tapez quand vous entendez le son.',
      es: 'Mantente concentrado. Toca cuando escuchas el sonido.',
      ru: 'Сосредоточься. Нажмите, когда слышите звук.',
    );
  }

  String _currentHint(AppI18n i18n, _AuditoryStimulusSpec spec) {
    if (_mode == _AuditoryMode.frequency ||
        _mode == _AuditoryMode.sensitivity) {
      return '${_formatFrequency(spec.frequencyHz)} / ${(spec.outputVolume * 100).round()}%';
    }
    if (!_showDirectionLabels) {
      return pickUiText(
        i18n,
        zh: '空间声源',
        en: 'Spatial sound',
        ja: 'Spatial sound',
        de: 'Spatial sound',
        fr: 'Son spatial',
        es: 'Sonido espacial',
        ru: 'Пространственный звук',
      );
    }
    return _formatDirection(spec.directionDegrees ?? 0, i18n);
  }

  String _sizeSuggestion(AppI18n i18n) {
    return pickUiText(
      i18n,
      zh: '快速筛查用 10-12 轮就够；想测得更稳，可以用 16-20 轮，并让分析频段数接近轮次规模。',
      en: 'Suggested test size: use 10-12 rounds for a quick screen; use 16-20 rounds for assessment and keep analysis bands close to the round count.',
      ja: 'Suggested test size: use 10-12 rounds for a quick screen; use 16-20 rounds for assessment and keep analysis bands close to the round count.',
      de: 'Suggested test size: use 10-12 rounds for a quick screen; use 16-20 rounds for assessment and keep analysis bands close to the round count.',
      fr: 'Taille suggérée de l\'essai : utiliser 10-12 rondes pour un écran rapide; utiliser 16-20 rondes pour l\'évaluation et garder les bandes d\'analyse près du nombre de rondes.',
      es: 'Tamaño de prueba sugerido: utilizar 10-12 rondas para una pantalla rápida; utilizar 16-20 rondas para evaluación y mantener bandas de análisis cerca del recuento redondo.',
      ru: 'Предлагаемый размер теста: используйте 10-12 раундов для быстрого экрана; используйте 16-20 раундов для оценки и держите полосы анализа близко к количеству раундов.',
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
      0 => pickUiText(
        i18n,
        zh: '前方',
        en: 'Front',
        ja: 'Front',
        de: 'Front',
        fr: 'Avant',
        es: 'Frente',
        ru: 'Фронт',
      ),
      1 => pickUiText(
        i18n,
        zh: '右前方',
        en: 'Front right',
        ja: 'Front right',
        de: 'Front right',
        fr: 'Devant à droite',
        es: 'Frente derecho',
        ru: 'Спереди справа',
      ),
      2 => pickUiText(
        i18n,
        zh: '右侧',
        en: 'Right',
        ja: 'Right',
        de: 'Right',
        fr: 'Droite',
        es: 'Bien.',
        ru: 'Правильно.',
      ),
      3 => pickUiText(
        i18n,
        zh: '右后方',
        en: 'Back right',
        ja: 'バック右',
        de: 'Back right',
        fr: 'En arrière à droite',
        es: 'Atrás derecho',
        ru: 'Направо.',
      ),
      4 => pickUiText(
        i18n,
        zh: '后方',
        en: 'Back',
        ja: 'バック',
        de: 'Back',
        fr: 'Précédent',
        es: 'Atrás',
        ru: 'Назад',
      ),
      5 => pickUiText(
        i18n,
        zh: '左后方',
        en: 'Back left',
        ja: 'バック左',
        de: 'Back left',
        fr: 'Retour à gauche',
        es: 'A la izquierda',
        ru: 'Налево.',
      ),
      6 => pickUiText(
        i18n,
        zh: '左侧',
        en: 'Left',
        ja: 'Left',
        de: 'Left',
        fr: 'Gauche',
        es: 'Izquierda',
        ru: 'Левый',
      ),
      _ => pickUiText(
        i18n,
        zh: '左前方',
        en: 'Front left',
        ja: 'Front left',
        de: 'Front left',
        fr: 'Avant gauche',
        es: 'Front izquierda',
        ru: 'Левый фронт',
      ),
    };
    return '$label ${normalized.round()}°';
  }

  String _spatialSelectionLabel(AppI18n i18n) {
    final value = _spatialGuessDegrees;
    if (value == null) {
      return pickUiText(
        i18n,
        zh: '未选择方位',
        en: 'No direction selected',
        ja: 'No direction selected',
        de: 'No direction selected',
        fr: 'Aucune direction sélectionnée',
        es: 'No hay dirección seleccionada',
        ru: 'Не выбранное направление',
      );
    }
    return _formatDirection(value, i18n);
  }

  String _directionName(double value, AppI18n i18n) {
    final normalized = value % 360;
    return switch ((normalized / 45).round() % 8) {
      0 => pickUiText(
        i18n,
        zh: '前',
        en: 'Front',
        ja: 'Front',
        de: 'Front',
        fr: 'Avant',
        es: 'Frente',
        ru: 'Фронт',
      ),
      1 => pickUiText(
        i18n,
        zh: '右前',
        en: 'Front right',
        ja: 'Front right',
        de: 'Front right',
        fr: 'Devant à droite',
        es: 'Frente derecho',
        ru: 'Спереди справа',
      ),
      2 => pickUiText(
        i18n,
        zh: '右',
        en: 'Right',
        ja: 'Right',
        de: 'Right',
        fr: 'Droite',
        es: 'Bien.',
        ru: 'Правильно.',
      ),
      3 => pickUiText(
        i18n,
        zh: '右后',
        en: 'Back right',
        ja: 'バック右',
        de: 'Back right',
        fr: 'En arrière à droite',
        es: 'Atrás derecho',
        ru: 'Направо.',
      ),
      4 => pickUiText(
        i18n,
        zh: '后',
        en: 'Back',
        ja: 'バック',
        de: 'Back',
        fr: 'Précédent',
        es: 'Atrás',
        ru: 'Назад',
      ),
      5 => pickUiText(
        i18n,
        zh: '左后',
        en: 'Back left',
        ja: 'バック左',
        de: 'Back left',
        fr: 'Retour à gauche',
        es: 'A la izquierda',
        ru: 'Налево.',
      ),
      6 => pickUiText(
        i18n,
        zh: '左',
        en: 'Left',
        ja: 'Left',
        de: 'Left',
        fr: 'Gauche',
        es: 'Izquierda',
        ru: 'Левый',
      ),
      _ => pickUiText(
        i18n,
        zh: '左前',
        en: 'Front left',
        ja: 'Front left',
        de: 'Front left',
        fr: 'Avant gauche',
        es: 'Front izquierda',
        ru: 'Левый фронт',
      ),
    };
  }

  static String _rhythmLabel(_AuditoryRhythm rhythm, AppI18n i18n) {
    return switch (rhythm) {
      _AuditoryRhythm.steady => pickUiText(
        i18n,
        zh: '平稳',
        en: 'Steady',
        ja: 'Steady',
        de: 'Steady',
        fr: 'Stabilité',
        es: 'Tranquila',
        ru: 'стойкий',
      ),
      _AuditoryRhythm.doublePulse => pickUiText(
        i18n,
        zh: '双脉冲',
        en: 'Double pulse',
        ja: 'Double pulse',
        de: 'Double pulse',
        fr: 'Double impulsion',
        es: 'Pulso doble',
        ru: 'Двойной импульс',
      ),
      _AuditoryRhythm.triplePulse => pickUiText(
        i18n,
        zh: '三脉冲',
        en: 'Triple pulse',
        ja: 'Triple pulse',
        de: 'Triple pulse',
        fr: 'Trois impulsions',
        es: 'Pulso triple',
        ru: 'Тройной пульс',
      ),
      _AuditoryRhythm.rising => pickUiText(
        i18n,
        zh: '上升',
        en: 'Rising',
        ja: 'Rising',
        de: 'Rising',
        fr: 'Augmentation',
        es: 'Rising',
        ru: 'подъем',
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
