part of '../toolbox_sound_tools.dart';

class _PickupProfile {
  const _PickupProfile({
    required this.id,
    required this.targetBrightness,
    required this.targetLevel,
    required this.suggestedGate,
  });

  final String id;
  final double targetBrightness;
  final double targetLevel;
  final double suggestedGate;
}

class _PickupPreset {
  const _PickupPreset({
    required this.id,
    required this.profileId,
    required this.preamp,
    required this.gate,
    required this.presence,
    required this.phaseReverse,
  });

  final String id;
  final String profileId;
  final double preamp;
  final double gate;
  final double presence;
  final bool phaseReverse;
}

class _PickupSessionStats {
  _PickupSessionStats();

  int totalSamples = 0;
  int validPitchSamples = 0;
  double maxPeak = 0;
  double avgLevel = 0;
  double minLevel = 1;
  int clipWarnings = 0;
  int lowInputWarnings = 0;
  int pitchStabilityScore = 0;
  DateTime? startTime;
  Duration? duration;
  Map<String, int> noteCount = <String, int>{};

  void reset() {
    totalSamples = 0;
    validPitchSamples = 0;
    maxPeak = 0;
    avgLevel = 0;
    minLevel = 1;
    clipWarnings = 0;
    lowInputWarnings = 0;
    pitchStabilityScore = 0;
    startTime = null;
    duration = null;
    noteCount.clear();
  }

  void updateSample(double level, double peak, String? note) {
    totalSamples += 1;
    if (level > avgLevel) {
      avgLevel = level;
    }
    if (level < minLevel && level > 0.02) {
      minLevel = level;
    }
    if (peak > maxPeak) {
      maxPeak = peak;
    }
    if (peak > 0.92) {
      clipWarnings += 1;
    }
    if (level < 0.08) {
      lowInputWarnings += 1;
    }
    if (note != null) {
      validPitchSamples += 1;
      noteCount[note] = (noteCount[note] ?? 0) + 1;
    }
  }
}

class _PickupTool extends StatefulWidget {
  const _PickupTool({this.fullScreen = false});

  final bool fullScreen;

  @override
  State<_PickupTool> createState() => _PickupToolState();
}

class _PickupToolState extends State<_PickupTool>
    with TickerProviderStateMixin {
  static const List<_PickupProfile> _profiles = <_PickupProfile>[
    _PickupProfile(
      id: 'piezo',
      targetBrightness: 0.34,
      targetLevel: 0.34,
      suggestedGate: 0.12,
    ),
    _PickupProfile(
      id: 'contact',
      targetBrightness: 0.24,
      targetLevel: 0.30,
      suggestedGate: 0.10,
    ),
    _PickupProfile(
      id: 'magnetic',
      targetBrightness: 0.20,
      targetLevel: 0.28,
      suggestedGate: 0.14,
    ),
    _PickupProfile(
      id: 'condenser',
      targetBrightness: 0.42,
      targetLevel: 0.38,
      suggestedGate: 0.08,
    ),
    _PickupProfile(
      id: 'dynamic',
      targetBrightness: 0.28,
      targetLevel: 0.32,
      suggestedGate: 0.16,
    ),
  ];

  static const List<_PickupPreset> _presets = <_PickupPreset>[
    _PickupPreset(
      id: 'balanced',
      profileId: 'piezo',
      preamp: 0.54,
      gate: 0.12,
      presence: 0.50,
      phaseReverse: false,
    ),
    _PickupPreset(
      id: 'warm',
      profileId: 'magnetic',
      preamp: 0.40,
      gate: 0.14,
      presence: 0.35,
      phaseReverse: false,
    ),
    _PickupPreset(
      id: 'bright',
      profileId: 'condenser',
      preamp: 0.65,
      gate: 0.08,
      presence: 0.70,
      phaseReverse: false,
    ),
    _PickupPreset(
      id: 'ambient',
      profileId: 'contact',
      preamp: 0.48,
      gate: 0.10,
      presence: 0.40,
      phaseReverse: false,
    ),
    _PickupPreset(
      id: 'low_noise',
      profileId: 'dynamic',
      preamp: 0.72,
      gate: 0.18,
      presence: 0.55,
      phaseReverse: false,
    ),
  ];

  static const List<String> _noteNames = <String>[
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];

  final AudioRecorder _recorder = AudioRecorder();
  final _PickupSessionStats _stats = _PickupSessionStats();

  StreamSubscription<Uint8List>? _pcmSubscription;
  StreamSubscription<RecordState>? _stateSubscription;

  String _profileId = _profiles.first.id;
  String _presetId = 'balanced';
  bool _hasPermission = false;
  bool _monitoring = false;
  bool _starting = false;
  bool _phaseReverse = false;
  String? _error;
  bool _showGuide = false;
  bool _showStats = false;
  bool _freezeFrame = false;
  DateTime? _freezeCapturedAt;

  double _preamp = 0.54;
  double _gate = 0.14;
  double _presence = 0.50;
  double _inputLevel = 0;
  double _peakLevel = 0;
  double _brightness = 0.24;
  double? _frequency;
  int? _cents;
  String? _noteLabel;
  String? _previousNote;
  int _stableNoteCount = 0;
  final List<double> _pitchMedianWindow = <double>[];

  final List<double> _history = List<double>.generate(48, (_) => 0);
  final List<double> _levelHistory = List<double>.generate(60, (_) => 0);
  final List<double> _peakHistory = List<double>.generate(60, (_) => 0);
  final List<_SpectrumBand> _spectrumBands = List<_SpectrumBand>.generate(
    8,
    (_) => _SpectrumBand.empty,
  );

  late final AnimationController _pulseController;
  late final AnimationController _fadeController;

  _PickupProfile get _activeProfile {
    return _profiles.firstWhere(
      (item) => item.id == _profileId,
      orElse: () => _profiles.first,
    );
  }

  _PickupPreset get _activePreset {
    return _presets.firstWhere(
      (item) => item.id == _presetId,
      orElse: () => _presets.first,
    );
  }

  bool _isCompactPhoneWidth(double width) =>
      width < (widget.fullScreen ? 520 : 430);

  String _profileLabel(AppI18n i18n, String profileId) {
    return switch (profileId) {
      'contact' => i18n.t('toolbox.sound.pickup.profile_contact'),
      'magnetic' => i18n.t('toolbox.sound.pickup.profile_magnetic'),
      'condenser' => i18n.t('toolbox.sound.pickup.profile_condenser'),
      'dynamic' => i18n.t('toolbox.sound.pickup.profile_dynamic'),
      _ => i18n.t('toolbox.sound.pickup.profile_piezo'),
    };
  }

  String _presetLabel(AppI18n i18n, String presetId) {
    return switch (presetId) {
      'warm' => i18n.t('toolbox.sound.pickup.preset_label'),
      'bright' => i18n.t('toolbox.sound.pickup.preset_bright'),
      'ambient' => i18n.t('toolbox.sound.pickup.preset_ambient'),
      'low_noise' => i18n.t('toolbox.sound.pickup.preset_low_noise'),
      'balanced' => i18n.t('toolbox.sound.pickup.preset_balanced'),
      _ => i18n.t('toolbox.sound.pickup.preset_custom'),
    };
  }

  String _profileSubtitle(AppI18n i18n) {
    return switch (_profileId) {
      'contact' => i18n.t('toolbox.sound.pickup.profile_contact_sub'),
      'magnetic' => i18n.t('toolbox.sound.pickup.profile_magnetic_sub'),
      'condenser' => i18n.t('toolbox.sound.pickup.profile_condenser_sub'),
      'dynamic' => i18n.t('toolbox.sound.pickup.profile_dynamic_sub'),
      _ => i18n.t('toolbox.sound.pickup.profile_piezo_sub'),
    };
  }

  double get _effectiveLevel =>
      (_inputLevel * (0.58 + _preamp * 1.05)).clamp(0.0, 1.0);

  double get _effectivePeak =>
      (_peakLevel * (0.58 + _preamp * 1.05)).clamp(0.0, 1.0);

  double get _effectiveBrightness =>
      (_brightness + (_presence - 0.5) * 0.30).clamp(0.0, 1.0);

  String _toneBalanceLabel(AppI18n i18n) {
    final value = _effectiveBrightness;
    if (value < 0.18) {
      return i18n.t('toolbox.sound.pickup.tone_dark');
    }
    if (value > 0.42) {
      return i18n.t('toolbox.sound.pickup.tone_bright');
    }
    return i18n.t('toolbox.sound.pickup.tone_balanced');
  }

  String _statusLabel(AppI18n i18n) {
    if (_freezeFrame) {
      return i18n.t('toolbox.sound.pickup.status_frozen');
    }
    if (_starting) {
      return i18n.t('toolbox.sound.pickup.status_starting');
    }
    if (_monitoring) {
      return i18n.t('toolbox.sound.pickup.status_monitoring');
    }
    return i18n.t('toolbox.sound.pickup.status_idle');
  }

  String _pitchDisplay() {
    if (_noteLabel == null) return '--';
    final cents = _cents;
    if (cents == null) return _noteLabel!;
    final centsText = cents == 0 ? '0c' : '${cents > 0 ? '+' : ''}${cents}c';
    return '$_noteLabel $centsText';
  }

  String _pitchAccuracyLabel(AppI18n i18n) {
    final cents = _cents;
    if (cents == null) return '--';
    if (cents.abs() <= 5) {
      return i18n.t('toolbox.sound.pickup.pitch_precise');
    }
    if (cents.abs() <= 15) {
      return i18n.t('toolbox.sound.pickup.pitch_good');
    }
    if (cents.abs() <= 30) {
      return i18n.t('toolbox.sound.pickup.pitch_off');
    }
    return i18n.t('toolbox.sound.pickup.pitch_out_of_tune');
  }

  Color _pitchAccuracyColor() {
    final cents = _cents;
    if (cents == null) return Colors.grey;
    if (cents.abs() <= 5) return const Color(0xFF22C55E);
    if (cents.abs() <= 15) return const Color(0xFF3B82F6);
    if (cents.abs() <= 30) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _qualityScore(AppI18n i18n) {
    if (!_monitoring || _stats.totalSamples < 10) {
      return '--';
    }
    var score = 100;
    score -= (_stats.clipWarnings * 5).clamp(0, 30);
    score -= (_stats.lowInputWarnings * 3).clamp(0, 20);
    if (_stats.validPitchSamples < _stats.totalSamples * 0.6) {
      score -= 15;
    }
    score = score.clamp(0, 100);
    if (score >= 90) {
      return i18n.t('toolbox.sound.pickup.quality_excellent', params: {'score': '\$score'});
    }
    if (score >= 75) {
      return i18n.t('toolbox.sound.pickup.quality_good', params: {'score': '\$score'});
    }
    if (score >= 60) {
      return i18n.t('toolbox.sound.pickup.quality_fair', params: {'score': '\$score'});
    }
    return i18n.t('toolbox.sound.pickup.quality_needs_work', params: {'score': '\$score'});
  }

  String _guidance(AppI18n i18n) {
    if (_error != null) return _error!;
    if (_freezeFrame) {
      return i18n.t('toolbox.sound.pickup.guidance_frozen');
    }
    if (!_hasPermission && !_monitoring) {
      return i18n.t('toolbox.sound.pickup.guidance_no_perm');
    }
    if (!_monitoring) {
      return i18n.t('toolbox.sound.pickup.guidance_idle');
    }
    if (_effectivePeak > 0.96) {
      return i18n.t('toolbox.sound.pickup.guidance_peak');
    }
    if (_effectiveLevel < _gate * 0.92) {
      return i18n.t('toolbox.sound.pickup.guidance_low_input');
    }
    if (_noteLabel == null) {
      return i18n.t('toolbox.sound.pickup.guidance_unstable');
    }
    final brightnessDelta =
        (_effectiveBrightness - _activeProfile.targetBrightness).abs();
    if (_effectiveBrightness < _activeProfile.targetBrightness - 0.08) {
      return i18n.t('toolbox.sound.pickup.guidance_dark');
    }
    if (_effectiveBrightness > _activeProfile.targetBrightness + 0.08) {
      return i18n.t('toolbox.sound.pickup.guidance_bright');
    }
    if (_phaseReverse) {
      return i18n.t('toolbox.sound.pickup.guidance_phase');
    }
    if (brightnessDelta <= 0.08 &&
        (_effectiveLevel - _activeProfile.targetLevel).abs() <= 0.08) {
      return i18n.t('toolbox.sound.pickup.guidance_balanced');
    }
    return i18n.t('toolbox.sound.pickup.guidance_default');
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadPreset(_activePreset);
  }

  void _loadPreset(_PickupPreset preset) {
    setState(() {
      _presetId = preset.id;
      _profileId = preset.profileId;
      _preamp = preset.preamp;
      _gate = preset.gate;
      _presence = preset.presence;
      _phaseReverse = preset.phaseReverse;
    });
  }

  Future<void> _startMonitoring() async {
    if (_starting || _monitoring) return;
    setState(() {
      _starting = true;
      _error = null;
      _freezeFrame = false;
      _freezeCapturedAt = null;
    });
    try {
      final granted = await _recorder.hasPermission();
      if (!granted) {
        if (!mounted) return;
        setState(() {
          _hasPermission = false;
          _starting = false;
          _error = _toolboxI18n(context).t('toolbox.sound.pickup.error_perm_denied');
        });
        return;
      }

      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 44100,
          numChannels: 1,
          autoGain: false,
          echoCancel: false,
          noiseSuppress: false,
          streamBufferSize: 4096,
        ),
      );

      await _pcmSubscription?.cancel();
      _pcmSubscription = stream.listen(
        _handlePcmChunk,
        onError: (Object error, StackTrace stackTrace) {
          if (!mounted) return;
          setState(() {
            _error = '$error';
            _monitoring = false;
          });
        },
        onDone: () {
          if (!mounted) return;
          setState(() => _monitoring = false);
        },
        cancelOnError: false,
      );

      _stateSubscription ??= _recorder.onStateChanged().listen((state) {
        if (!mounted) return;
        setState(() {
          _monitoring =
              state == RecordState.record || state == RecordState.pause;
        });
      });

      if (!mounted) return;
      _stats.reset();
      _pitchMedianWindow.clear();
      _stableNoteCount = 0;
      _previousNote = null;
      _stats.startTime = DateTime.now();
      setState(() {
        _hasPermission = true;
        _starting = false;
        _monitoring = true;
        _showGuide = false;
      });
      _pulseController.repeat();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _monitoring = false;
        _error = '$error';
      });
    }
  }

  Future<void> _stopMonitoring() async {
    await _pcmSubscription?.cancel();
    _pcmSubscription = null;
    try {
      await _recorder.stop();
    } catch (_) {}
    if (!mounted) return;
    _stats.duration = _stats.startTime != null
        ? DateTime.now().difference(_stats.startTime!)
        : null;
    setState(() => _monitoring = false);
    _pulseController.stop();
  }

  void _toggleFreezeFrame() {
    setState(() {
      _freezeFrame = !_freezeFrame;
      _freezeCapturedAt = _freezeFrame ? DateTime.now() : null;
    });
    if (_freezeFrame) {
      _pulseController.stop();
      return;
    }
    if (_monitoring) {
      _pulseController.repeat();
    }
  }

  void _handlePcmChunk(Uint8List chunk) {
    if (_freezeFrame) {
      return;
    }
    final byteData = ByteData.sublistView(chunk);
    final sampleCount = byteData.lengthInBytes ~/ 2;
    if (sampleCount < 256) return;

    var peak = 0.0;
    var sumSquares = 0.0;
    var sumAbs = 0.0;
    var diffAbs = 0.0;
    var previous = 0.0;
    final normalized = List<double>.filled(sampleCount, 0.0);
    for (var i = 0; i < sampleCount; i += 1) {
      final value = byteData.getInt16(i * 2, Endian.little) / 32768.0;
      normalized[i] = value;
      final absValue = value.abs();
      if (absValue > peak) peak = absValue;
      sumSquares += value * value;
      sumAbs += absValue;
      if (i > 0) {
        diffAbs += (value - previous).abs();
      }
      previous = value;
    }

    final rms = math.sqrt(sumSquares / sampleCount);
    final brightness = (diffAbs / math.max(1e-6, sumAbs * 2.2))
        .clamp(0.0, 1.0)
        .toDouble();

    _updateSpectrumBands(normalized, sampleCount);

    final detectedFrequency = rms > 0.012
        ? _smoothDetectedFrequency(_detectPitchAdvanced(normalized, 44100))
        : _smoothDetectedFrequency(null);

    String? noteLabel;
    int? cents;
    if (detectedFrequency != null) {
      final midi = 69 + 12 * math.log(detectedFrequency / 440.0) / math.ln2;
      final nearestMidi = midi.round();
      final noteName = _noteNames[((nearestMidi % 12) + 12) % 12];
      final octave = (nearestMidi ~/ 12) - 1;
      noteLabel = '$noteName$octave';
      cents = ((midi - nearestMidi) * 100).round();

      if (noteLabel == _previousNote) {
        _stableNoteCount += 1;
      } else {
        _stableNoteCount = 0;
        _previousNote = noteLabel;
      }
      if (_stableNoteCount < 3) {
        noteLabel = null;
        cents = null;
      }
    } else {
      _stableNoteCount = 0;
      _previousNote = null;
    }

    final bucketCount = 8;
    final bucketSize = math.max(1, normalized.length ~/ bucketCount);
    for (var bucket = 0; bucket < bucketCount; bucket += 1) {
      final start = bucket * bucketSize;
      if (start >= normalized.length) break;
      final end = math.min(normalized.length, start + bucketSize);
      var localSum = 0.0;
      for (var i = start; i < end; i += 1) {
        localSum += normalized[i].abs();
      }
      final value = (localSum / (end - start) * 2.4).clamp(0.0, 1.0);
      _history.removeAt(0);
      _history.add(value);
    }

    _levelHistory.removeAt(0);
    _levelHistory.add(rms.clamp(0.0, 1.0));
    _peakHistory.removeAt(0);
    _peakHistory.add(peak.clamp(0.0, 1.0));

    _stats.updateSample(rms, peak, noteLabel);

    if (!mounted) return;
    setState(() {
      _inputLevel = rms.clamp(0.0, 1.0);
      _peakLevel = peak.clamp(0.0, 1.0);
      _brightness = brightness;
      _frequency = detectedFrequency;
      _noteLabel = noteLabel;
      _cents = cents;
    });
  }

  void _updateSpectrumBands(List<double> samples, int sampleCount) {
    const bandCount = 8;
    const bandRanges = <(int, int)>[
      (60, 120),
      (120, 250),
      (250, 500),
      (500, 1000),
      (1000, 2000),
      (2000, 4000),
      (4000, 8000),
      (8000, 16000),
    ];

    final windowSize = _largestPowerOfTwo(math.min(sampleCount, 2048));
    if (windowSize < 256) {
      for (var band = 0; band < bandCount; band += 1) {
        final (lowHz, highHz) = bandRanges[band];
        _spectrumBands[band] = _SpectrumBand(
          level: 0,
          centerHz: (lowHz + highHz) / 2,
        );
      }
      return;
    }

    final start = sampleCount - windowSize;
    final real = List<double>.filled(windowSize, 0.0);
    final imag = List<double>.filled(windowSize, 0.0);
    for (var i = 0; i < windowSize; i += 1) {
      final window = 0.5 - 0.5 * math.cos(2 * math.pi * i / (windowSize - 1));
      real[i] = samples[start + i] * window;
    }
    _fftInPlace(real, imag);

    final halfSize = windowSize ~/ 2;
    final magnitudes = List<double>.filled(halfSize, 0.0);
    var maxMagnitude = 1e-9;
    for (var bin = 1; bin < halfSize; bin += 1) {
      final magnitude = math.sqrt(
        real[bin] * real[bin] + imag[bin] * imag[bin],
      );
      magnitudes[bin] = magnitude;
      if (magnitude > maxMagnitude) {
        maxMagnitude = magnitude;
      }
    }
    final hzPerBin = 44100 / windowSize;

    for (var band = 0; band < bandCount; band += 1) {
      final (lowHz, highHz) = bandRanges[band];
      final lowSample = math.max(1, (lowHz / hzPerBin).floor());
      final highSample = math.min(halfSize - 1, (highHz / hzPerBin).ceil());
      var bandSum = 0.0;
      var bandCountSamples = 0;
      for (var i = lowSample; i <= highSample; i += 1) {
        bandSum += magnitudes[i];
        bandCountSamples += 1;
      }
      final bandLevel = bandCountSamples > 0
          ? (math.sqrt((bandSum / bandCountSamples) / maxMagnitude) * 1.2)
                .clamp(0.0, 1.0)
          : 0.0;
      _spectrumBands[band] = _SpectrumBand(
        level: bandLevel,
        centerHz: (lowHz + highHz) / 2,
      );
    }
  }

  double? _smoothDetectedFrequency(double? frequency) {
    if (frequency == null || frequency.isNaN || frequency.isInfinite) {
      _pitchMedianWindow.clear();
      return null;
    }
    _pitchMedianWindow.add(frequency);
    if (_pitchMedianWindow.length > 5) {
      _pitchMedianWindow.removeAt(0);
    }
    final sorted = List<double>.of(_pitchMedianWindow)..sort();
    return sorted[sorted.length ~/ 2];
  }

  int _largestPowerOfTwo(int value) {
    var power = 1;
    while (power * 2 <= value) {
      power *= 2;
    }
    return power;
  }

  void _fftInPlace(List<double> real, List<double> imag) {
    final length = real.length;
    var j = 0;
    for (var i = 1; i < length; i += 1) {
      var bit = length >> 1;
      while ((j & bit) != 0) {
        j ^= bit;
        bit >>= 1;
      }
      j ^= bit;
      if (i < j) {
        final realTemp = real[i];
        real[i] = real[j];
        real[j] = realTemp;
        final imagTemp = imag[i];
        imag[i] = imag[j];
        imag[j] = imagTemp;
      }
    }

    for (var size = 2; size <= length; size <<= 1) {
      final halfSize = size >> 1;
      final angle = -2 * math.pi / size;
      final phaseStepReal = math.cos(angle);
      final phaseStepImag = math.sin(angle);
      for (var start = 0; start < length; start += size) {
        var currentReal = 1.0;
        var currentImag = 0.0;
        for (var offset = 0; offset < halfSize; offset += 1) {
          final evenIndex = start + offset;
          final oddIndex = evenIndex + halfSize;
          final oddReal =
              real[oddIndex] * currentReal - imag[oddIndex] * currentImag;
          final oddImag =
              real[oddIndex] * currentImag + imag[oddIndex] * currentReal;
          final evenReal = real[evenIndex];
          final evenImag = imag[evenIndex];

          real[evenIndex] = evenReal + oddReal;
          imag[evenIndex] = evenImag + oddImag;
          real[oddIndex] = evenReal - oddReal;
          imag[oddIndex] = evenImag - oddImag;

          final nextReal =
              currentReal * phaseStepReal - currentImag * phaseStepImag;
          currentImag =
              currentReal * phaseStepImag + currentImag * phaseStepReal;
          currentReal = nextReal;
        }
      }
    }
  }

  double? _detectPitchAdvanced(List<double> samples, int sampleRate) {
    if (samples.length < 2048) return null;
    final window = samples.length > 4096
        ? samples.sublist(samples.length - 4096)
        : samples;
    final mean = window.reduce((a, b) => a + b) / window.length;
    for (var i = 0; i < window.length; i += 1) {
      window[i] = window[i] - mean;
    }

    final windowed = List<double>.filled(window.length, 0.0);
    for (var i = 0; i < window.length; i += 1) {
      final hamming = 0.54 - 0.46 * math.cos(2 * math.pi * i / window.length);
      windowed[i] = window[i] * hamming;
    }

    final minLag = math.max(24, sampleRate ~/ 1000);
    final maxLag = math.min(window.length ~/ 2, sampleRate ~/ 65);
    var bestLag = 0;
    var bestScore = 0.0;
    var secondBestScore = 0.0;

    for (var lag = minLag; lag <= maxLag; lag += 1) {
      var correlation = 0.0;
      var energyA = 0.0;
      var energyB = 0.0;
      for (var i = 0; i < window.length - lag; i += 1) {
        final a = windowed[i];
        final b = windowed[i + lag];
        correlation += a * b;
        energyA += a * a;
        energyB += b * b;
      }
      final denominator = math.sqrt(energyA * energyB);
      if (denominator <= 1e-9) continue;
      final score = correlation / denominator;
      if (score > bestScore) {
        secondBestScore = bestScore;
        bestScore = score;
        bestLag = lag;
      } else if (score > secondBestScore) {
        secondBestScore = score;
      }
    }

    if (bestLag == 0 || bestScore < 0.72) return null;

    final refinedLag = _refineLagParabolic(windowed, bestLag);
    final frequency = sampleRate / refinedLag;

    if (frequency < 65 || frequency > 1400) return null;

    final clarity = bestScore - secondBestScore;
    if (clarity < 0.08) return null;

    return frequency;
  }

  double _refineLagParabolic(List<double> window, int lag) {
    if (lag <= 1 || lag >= window.length - 1) return lag.toDouble();
    var y0 = 0.0;
    var y1 = 0.0;
    var y2 = 0.0;
    for (var i = 0; i < window.length - lag - 1; i += 1) {
      y0 += window[i] * window[i + lag - 1];
      y1 += window[i] * window[i + lag];
      y2 += window[i] * window[i + lag + 1];
    }
    final denominator = 2 * (y0 - 2 * y1 + y2);
    if (denominator.abs() < 1e-9) return lag.toDouble();
    final offset = (y0 - y2) / denominator;
    return lag + offset;
  }

  Widget _buildSpectrumDisplay(AppI18n i18n, ThemeData theme) {
    final compact = _isCompactPhoneWidth(MediaQuery.sizeOf(context).width);
    final barHeight = compact ? 80.0 : 100.0;
    final labels = <String>[
      i18n.t('toolbox.sound.pickup.spectrum_low'),
      i18n.t('toolbox.sound.pickup.spectrum_mid_l'),
      i18n.t('toolbox.sound.pickup.spectrum_mid'),
      i18n.t('toolbox.sound.pickup.spectrum_mid_h'),
      i18n.t('toolbox.sound.pickup.spectrum_high'),
      i18n.t('toolbox.sound.pickup.spectrum_v_high'),
      i18n.t('toolbox.sound.pickup.spectrum_ext'),
      i18n.t('toolbox.sound.pickup.spectrum_top'),
    ];

    return Container(
      height: barHeight + 24,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: _spectrumBands
            .asMap()
            .entries
            .map((entry) {
              final index = entry.key;
              final band = entry.value;
              final barColor = band.level > 0.85
                  ? const Color(0xFFF97316)
                  : band.level > 0.6
                  ? const Color(0xFF22C55E)
                  : const Color(0xFF3B82F6).withValues(alpha: 0.6);
              return Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 60),
                      height: math.max(4, band.level * barHeight),
                      width: compact ? 18 : 24,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      labels[index],
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                    ),
                  ],
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }

  Widget _buildHistoryGraph(AppI18n i18n, ThemeData theme) {
    final compact = _isCompactPhoneWidth(MediaQuery.sizeOf(context).width);
    final graphHeight = compact ? 60.0 : 80.0;
    final graphWidth = compact ? 180.0 : 220.0;

    return SizedBox(
      width: graphWidth,
      height: graphHeight + 30,
      child: Column(
        children: <Widget>[
          SizedBox(
            height: graphHeight,
            child: CustomPaint(
              size: Size(graphWidth, graphHeight),
              painter: _HistoryGraphPainter(
                levelHistory: _levelHistory,
                peakHistory: _peakHistory,
                gateThreshold: _gate,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    i18n.t('toolbox.sound.pickup.level'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              Row(
                children: <Widget>[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF97316),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    i18n.t('toolbox.sound.pickup.peak'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMeterStage(BuildContext context, AppI18n i18n, ThemeData theme) {
    final level = _effectiveLevel;
    final peak = _effectivePeak;
    final compact = _isCompactPhoneWidth(MediaQuery.sizeOf(context).width);
    final meterColor = peak > 0.92
        ? const Color(0xFFF97316)
        : level > _gate
        ? const Color(0xFF22C55E)
        : const Color(0xFF64748B);

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.fullScreen ? 24 : 20),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF0F172A), Color(0xFF111827)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      i18n.t('toolbox.sound.pickup.live_monitor'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text(
                        _statusLabel(i18n),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_freezeFrame)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Text(
                          i18n.t('toolbox.sound.pickup.snapshot'),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: const Color(0xFF7DD3FC),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  if (_freezeFrame) const SizedBox(width: 8),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: _pitchAccuracyColor().withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text(
                        _pitchAccuracyLabel(i18n),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: _pitchAccuracyColor(),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    flex: compact ? 5 : 4,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Stack(
                        alignment: Alignment.center,
                        children: <Widget>[
                          SizedBox.expand(
                            child: AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return CircularProgressIndicator(
                                  value: level,
                                  strokeWidth: compact ? 10 : 12,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.08,
                                  ),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    meterColor.withValues(
                                      alpha: _monitoring
                                          ? 0.8 + 0.2 * _pulseController.value
                                          : 1.0,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                _pitchDisplay(),
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _frequency == null
                                    ? '-- Hz'
                                    : '${_frequency!.toStringAsFixed(1)} Hz',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${(_effectiveLevel * 100).round()}%',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: meterColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          i18n.t('toolbox.sound.pickup.advice_label', params: {'text': _guidance(i18n)}),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildHistoryGraph(i18n, theme),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildSpectrumDisplay(i18n, theme),
              const SizedBox(height: 14),
              _buildPitchTunerDisplay(i18n, theme),
              const SizedBox(height: 14),
              _buildScaleKeyboard(i18n, theme),
              const SizedBox(height: 10),
              SizedBox(
                height: compact ? 56 : 68,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: _history
                      .map(
                        (value) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 80),
                              height: math.max(4, value * (compact ? 56 : 68)),
                              decoration: BoxDecoration(
                                color: meterColor.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPitchTunerDisplay(AppI18n i18n, ThemeData theme) {
    final cents = _cents ?? 0;
    final hasNote = _noteLabel != null;
    final compact = _isCompactPhoneWidth(MediaQuery.sizeOf(context).width);
    final barWidth = compact ? 180.0 : 240.0;
    final barHeight = compact ? 28.0 : 36.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                i18n.t('toolbox.sound.pickup.pitch_deviation'),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                hasNote ? '${cents > 0 ? '+' : ''}$cents c' : '-- c',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: hasNote ? _pitchAccuracyColor() : Colors.grey,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: barWidth,
            height: barHeight,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Container(
                  width: barWidth,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Positioned(
                  left: 0,
                  child: Container(
                    width: barHeight,
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.3),
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(8),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '♭',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.red.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  child: Container(
                    width: barHeight,
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.3),
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(8),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '♯',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.red.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: barWidth / 2 - 2,
                  child: Container(
                    width: 4,
                    height: barHeight + 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (hasNote)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 100),
                    left:
                        (barWidth / 2 +
                                (cents.clamp(-50, 50) / 50) *
                                    (barWidth / 2 - barHeight) -
                                6)
                            .clamp(0.0, barWidth - 12),
                    child: Container(
                      width: 12,
                      height: barHeight - 4,
                      decoration: BoxDecoration(
                        color: _pitchAccuracyColor(),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: _pitchAccuracyColor().withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                '-50c',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
              Text(
                i18n.t('toolbox.sound.pickup.in_tune'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: hasNote && cents.abs() <= 5
                      ? const Color(0xFF22C55E)
                      : Colors.white.withValues(alpha: 0.4),
                ),
              ),
              Text(
                '+50c',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScaleKeyboard(AppI18n i18n, ThemeData theme) {
    final compact = _isCompactPhoneWidth(MediaQuery.sizeOf(context).width);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final currentNote = _noteLabel;
    final currentMidi = _frequency != null
        ? (69 + 12 * math.log(_frequency! / 440.0) / math.ln2).round()
        : null;

    final keyWidth = compact ? 28.0 : 32.0;
    final keySpacing = 2.0;
    final keysPerOctave = 12;
    final visibleOctaves = compact ? 1 : 2;
    final totalKeys = keysPerOctave * visibleOctaves;

    final octaveStart = currentMidi != null
        ? ((currentMidi ~/ 12) - 1) * 12
        : 48;

    final visibleNotes = <int>[];
    for (var i = 0; i < totalKeys; i += 1) {
      visibleNotes.add(octaveStart + i);
    }

    final keyboardWidth = (keyWidth + keySpacing) * totalKeys;
    final shouldScroll = keyboardWidth > screenWidth - 48;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                i18n.t('toolbox.sound.pickup.scale_view'),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              if (currentNote != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _pitchAccuracyColor().withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    currentNote,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: _pitchAccuracyColor(),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (_frequency != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    '${_frequency!.toStringAsFixed(1)} Hz',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: compact ? 52 : 60,
            child: shouldScroll
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _buildKeyboardRow(
                      visibleNotes,
                      keyWidth,
                      keySpacing,
                      compact,
                      theme,
                      currentNote,
                    ),
                  )
                : _buildKeyboardRow(
                    visibleNotes,
                    keyWidth,
                    keySpacing,
                    compact,
                    theme,
                    currentNote,
                  ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _pitchAccuracyColor(),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                i18n.t('toolbox.sound.pickup.current_key'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                i18n.t('toolbox.sound.pickup.detected_key'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                i18n.t('toolbox.sound.pickup.sharp_key'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboardRow(
    List<int> visibleNotes,
    double keyWidth,
    double keySpacing,
    bool compact,
    ThemeData theme,
    String? currentNote,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: visibleNotes
          .map((midi) {
            final pitchClass = ((midi % 12) + 12) % 12;
            final isSharp = const <int>{1, 3, 6, 8, 10}.contains(pitchClass);
            final noteName = _noteNames[pitchClass];
            final octave = (midi ~/ 12) - 1;
            final fullNote = '$noteName$octave';
            final isActive = currentNote == fullNote;
            final isRecent = _stats.noteCount.containsKey(fullNote);

            return Container(
              width: keyWidth,
              margin: EdgeInsets.symmetric(horizontal: keySpacing / 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isActive
                            ? _pitchAccuracyColor()
                            : isSharp
                            ? Colors.white.withValues(alpha: 0.18)
                            : isRecent
                            ? const Color(0xFF3B82F6).withValues(alpha: 0.35)
                            : Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                        border: isActive
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                        boxShadow: isActive
                            ? <BoxShadow>[
                                BoxShadow(
                                  color: _pitchAccuracyColor().withValues(
                                    alpha: 0.5,
                                  ),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            noteName,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: isActive
                                  ? Colors.white
                                  : isSharp
                                  ? Colors.white.withValues(alpha: 0.7)
                                  : Colors.white.withValues(alpha: 0.5),
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          if (!isSharp || isActive)
                            Text(
                              '$octave',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isActive
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : Colors.white.withValues(alpha: 0.35),
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          })
          .toList(growable: false),
    );
  }

  Widget _buildStatsPanel(AppI18n i18n, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    i18n.t('toolbox.sound.pickup.session_stats'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => setState(() => _showStats = false),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                ToolboxMetricCard(
                  label: i18n.t('toolbox.sound.pickup.duration'),
                  value: _stats.duration != null
                      ? '${_stats.duration!.inMinutes}m ${_stats.duration!.inSeconds % 60}s'
                      : '--',
                ),
                ToolboxMetricCard(
                  label: i18n.t('toolbox.sound.pickup.samples_label'),
                  value: '${_stats.totalSamples}',
                ),
                ToolboxMetricCard(
                  label: i18n.t('toolbox.sound.pickup.clip_warns'),
                  value: '${_stats.clipWarnings}',
                ),
                ToolboxMetricCard(
                  label: i18n.t('toolbox.sound.pickup.low_input_label'),
                  value: '${_stats.lowInputWarnings}',
                ),
                ToolboxMetricCard(
                  label: i18n.t('toolbox.sound.pickup.max_peak'),
                  value: '${(_stats.maxPeak * 100).round()}%',
                ),
                ToolboxMetricCard(
                  label: i18n.t('toolbox.sound.pickup.pitch_stable'),
                  value: _stats.totalSamples > 0
                      ? '${((_stats.validPitchSamples / _stats.totalSamples) * 100).round()}%'
                      : '--',
                ),
                ToolboxMetricCard(
                  label: i18n.t('toolbox.sound.pickup.notes_label'),
                  value: '${_stats.noteCount.length}',
                ),
                ToolboxMetricCard(
                  label: i18n.t('toolbox.sound.pickup.quality'),
                  value: _qualityScore(i18n),
                ),
              ],
            ),
            if (_stats.noteCount.isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              Text(
                i18n.t('toolbox.sound.pickup.detected_notes'),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _stats.noteCount.entries
                    .map(
                      (entry) => Chip(
                        label: Text('${entry.key}: ${entry.value}'),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGuidePanel(AppI18n i18n, ThemeData theme) {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return Opacity(opacity: _fadeController.value, child: child);
      },
      child: Card(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      i18n.t('toolbox.sound.pickup.quick_guide'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _fadeController.reverse();
                      setState(() => _showGuide = false);
                    },
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...<Widget>[
                _buildGuideStep(
                  i18n,
                  theme,
                  Icons.mic_rounded,
                  i18n.t('toolbox.sound.pickup.guide_start_monitor'),
                  i18n.t('toolbox.sound.pickup.guide_start_monitor_body'),
                ),
                const SizedBox(height: 8),
                _buildGuideStep(
                  i18n,
                  theme,
                  Icons.music_note_rounded,
                  i18n.t('toolbox.sound.pickup.guide_play_note'),
                  i18n.t('toolbox.sound.pickup.guide_play_note_body'),
                ),
                const SizedBox(height: 8),
                _buildGuideStep(
                  i18n,
                  theme,
                  Icons.tune_rounded,
                  i18n.t('toolbox.sound.pickup.guide_adjust_params'),
                  i18n.t('toolbox.sound.pickup.guide_adjust_params_body'),
                ),
                const SizedBox(height: 8),
                _buildGuideStep(
                  i18n,
                  theme,
                  Icons.save_rounded,
                  i18n.t('toolbox.sound.pickup.guide_save_preset'),
                  i18n.t('toolbox.sound.pickup.guide_save_preset_body'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuideStep(
    AppI18n i18n,
    ThemeData theme,
    IconData icon,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(description, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    unawaited(_pcmSubscription?.cancel());
    unawaited(_stateSubscription?.cancel());
    unawaited(_recorder.dispose());
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    final theme = Theme.of(context);

    return _buildInstrumentPanelShell(
      context,
      fullScreen: widget.fullScreen,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = _isCompactPhoneWidth(constraints.maxWidth);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (_showGuide && !_monitoring) ...<Widget>[
                _buildGuidePanel(i18n, theme),
                const SizedBox(height: 14),
              ],
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  ToolboxMetricCard(label: 'Status', value: _statusLabel(i18n)),
                  if (_freezeCapturedAt != null)
                    ToolboxMetricCard(
                      label: i18n.t('toolbox.sound.pickup.snapshot'),
                      value:
                          '${_freezeCapturedAt!.hour.toString().padLeft(2, '0')}:'
                          '${_freezeCapturedAt!.minute.toString().padLeft(2, '0')}:'
                          '${_freezeCapturedAt!.second.toString().padLeft(2, '0')}',
                    ),
                  ToolboxMetricCard(
                    label: 'Profile',
                    value: _profileLabel(i18n, _profileId),
                  ),
                  ToolboxMetricCard(
                    label: 'Peak',
                    value: '${(_effectivePeak * 100).round()}%',
                  ),
                  ToolboxMetricCard(
                    label: 'Tone',
                    value: _toneBalanceLabel(i18n),
                  ),
                  ToolboxMetricCard(label: 'Pitch', value: _pitchDisplay()),
                  ToolboxMetricCard(
                    label: i18n.t('toolbox.sound.pickup.score_label'),
                    value: _qualityScore(i18n),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SectionHeader(
                title: i18n.t('toolbox.sound.pickup.pickup_stage'),
                subtitle: compact ? i18n.t('toolbox.sound.pickup.pickup_stage_compact') : i18n.t('toolbox.sound.pickup.pickup_stage_full'),
              ),
              const SizedBox(height: 10),
              _buildMeterStage(context, i18n, theme),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  FilledButton.tonalIcon(
                    onPressed: _monitoring ? _stopMonitoring : _startMonitoring,
                    icon: Icon(
                      _monitoring
                          ? Icons.stop_circle_rounded
                          : Icons.mic_rounded,
                    ),
                    label: Text(
                      i18n.t(_monitoring ? 'toolbox.sound.pickup.stop_monitor' : 'toolbox.sound.pickup.start_monitor'),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: (_monitoring || _freezeFrame)
                        ? _toggleFreezeFrame
                        : null,
                    icon: Icon(
                      _freezeFrame
                          ? Icons.play_circle_outline_rounded
                          : Icons.ac_unit_rounded,
                    ),
                    label: Text(
                      i18n.t(_freezeFrame ? 'toolbox.sound.pickup.resume_live' : 'toolbox.sound.pickup.freeze_snapshot'),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _freezeFrame = false;
                        _freezeCapturedAt = null;
                        _pitchMedianWindow.clear();
                        _history
                          ..clear()
                          ..addAll(List<double>.filled(48, 0));
                        _levelHistory
                          ..clear()
                          ..addAll(List<double>.filled(60, 0));
                        _peakHistory
                          ..clear()
                          ..addAll(List<double>.filled(60, 0));
                        _spectrumBands
                          ..clear()
                          ..addAll(
                            List<_SpectrumBand>.filled(8, _SpectrumBand.empty),
                          );
                        _frequency = null;
                        _noteLabel = null;
                        _cents = null;
                        _inputLevel = 0;
                        _peakLevel = 0;
                        _brightness = _activeProfile.targetBrightness;
                        _previousNote = null;
                        _stableNoteCount = 0;
                        _stats.reset();
                      });
                      if (_monitoring) {
                        _pulseController.repeat();
                      } else {
                        _pulseController.stop();
                      }
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(i18n.t('toolbox.sound.pickup.reset_readings')),
                  ),
                  if (_monitoring)
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _showStats = !_showStats),
                      icon: Icon(
                        _showStats
                            ? Icons.analytics_rounded
                            : Icons.bar_chart_rounded,
                      ),
                      label: Text(
                        i18n.t(_showStats ? 'toolbox.sound.pickup.hide_stats' : 'toolbox.sound.pickup.show_stats'),
                      ),
                    ),
                  if (!_showGuide && !_monitoring)
                    TextButton.icon(
                      onPressed: () {
                        _fadeController.forward();
                        setState(() => _showGuide = true);
                      },
                      icon: const Icon(Icons.help_outline_rounded),
                      label: Text(i18n.t('toolbox.sound.pickup.guide_button')),
                    ),
                ],
              ),
              if (_showStats) ...<Widget>[
                const SizedBox(height: 14),
                _buildStatsPanel(i18n, theme),
              ],
              const SizedBox(height: 14),
              SectionHeader(
                title: i18n.t('toolbox.sound.pickup.quick_presets'),
                subtitle: i18n.t('toolbox.sound.pickup.quick_presets_sub'),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presets
                    .map(
                      (preset) => ChoiceChip(
                        label: Text(_presetLabel(i18n, preset.id)),
                        selected: preset.id == _presetId,
                        onSelected: (_) => _loadPreset(preset),
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: 14),
              SectionHeader(
                title: i18n.t('toolbox.sound.pickup.pickup_type'),
                subtitle: _profileSubtitle(i18n),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _profiles
                    .map(
                      (item) => ChoiceChip(
                        avatar: Icon(_profileIcon(item.id), size: 16),
                        label: Text(_profileLabel(i18n, item.id)),
                        selected: item.id == _profileId,
                        onSelected: (_) => setState(() {
                          _profileId = item.id;
                          _presetId = 'custom';
                          _gate = _activeProfile.suggestedGate;
                        }),
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: 14),
              SectionHeader(
                title: i18n.t('toolbox.sound.pickup.calibration'),
                subtitle: i18n.t('toolbox.sound.pickup.calibration_sub'),
              ),
              const SizedBox(height: 10),
              Text(
                i18n.t('toolbox.sound.pickup.calibration_note'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          i18n.t('toolbox.sound.pickup.preamp_pct', params: {'pct': '\${(_preamp * 100).round()}'}),
                          style: theme.textTheme.bodyMedium,
                        ),
                        Slider(
                          value: _preamp,
                          min: 0.0,
                          max: 1.0,
                          divisions: 20,
                          onChanged: (value) => setState(() {
                            _preamp = value;
                            _presetId = 'custom';
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          i18n.t('toolbox.sound.pickup.gate_pct', params: {'pct': '\${(_gate * 100).round()}'}),
                          style: theme.textTheme.bodyMedium,
                        ),
                        Slider(
                          value: _gate,
                          min: 0.05,
                          max: 0.35,
                          divisions: 15,
                          onChanged: (value) => setState(() {
                            _gate = value;
                            _presetId = 'custom';
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          i18n.t('toolbox.sound.pickup.presence_pct', params: {'pct': '\${(_presence * 100).round()}'}),
                          style: theme.textTheme.bodyMedium,
                        ),
                        Slider(
                          value: _presence,
                          min: 0.0,
                          max: 1.0,
                          divisions: 20,
                          onChanged: (value) => setState(() {
                            _presence = value;
                            _presetId = 'custom';
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SwitchListTile.adaptive(
                      value: _phaseReverse,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) => setState(() {
                        _phaseReverse = value;
                        _presetId = 'custom';
                      }),
                      title: Text(
                        i18n.t('toolbox.sound.pickup.phase_rev'),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                i18n.t('toolbox.sound.pickup.phase_rev_hint'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _profileIcon(String profileId) {
    return switch (profileId) {
      'contact' => Icons.touch_app_rounded,
      'magnetic' => Icons.battery_charging_full_rounded,
      'condenser' => Icons.sensors_rounded,
      'dynamic' => Icons.volume_up_rounded,
      _ => Icons.cable_rounded,
    };
  }
}

class _SpectrumBand {
  const _SpectrumBand({required this.level, required this.centerHz});

  final double level;
  final double centerHz;

  static const _SpectrumBand empty = _SpectrumBand(level: 0, centerHz: 0);
}

class _HistoryGraphPainter extends CustomPainter {
  _HistoryGraphPainter({
    required this.levelHistory,
    required this.peakHistory,
    required this.gateThreshold,
  });

  final List<double> levelHistory;
  final List<double> peakHistory;
  final double gateThreshold;

  @override
  void paint(Canvas canvas, Size size) {
    final levelPaint = Paint()
      ..color = const Color(0xFF22C55E)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final peakPaint = Paint()
      ..color = const Color(0xFFF97316)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final gatePaint = Paint()
      ..color = const Color(0xFF64748B).withValues(alpha: 0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final stepX = size.width / (levelHistory.length - 1);

    final gateY = size.height * (1 - gateThreshold.clamp(0.0, 1.0));
    canvas.drawLine(Offset(0, gateY), Offset(size.width, gateY), gatePaint);

    final levelPath = Path();
    for (var i = 0; i < levelHistory.length; i += 1) {
      final x = i * stepX;
      final y = size.height * (1 - levelHistory[i].clamp(0.0, 1.0));
      if (i == 0) {
        levelPath.moveTo(x, y);
      } else {
        levelPath.lineTo(x, y);
      }
    }
    canvas.drawPath(levelPath, levelPaint);

    final peakPath = Path();
    for (var i = 0; i < peakHistory.length; i += 1) {
      final x = i * stepX;
      final y = size.height * (1 - peakHistory[i].clamp(0.0, 1.0));
      if (i == 0) {
        peakPath.moveTo(x, y);
      } else {
        peakPath.lineTo(x, y);
      }
    }
    canvas.drawPath(peakPath, peakPaint);
  }

  @override
  bool shouldRepaint(covariant _HistoryGraphPainter oldDelegate) {
    return levelHistory != oldDelegate.levelHistory ||
        peakHistory != oldDelegate.peakHistory ||
        gateThreshold != oldDelegate.gateThreshold;
  }
}
