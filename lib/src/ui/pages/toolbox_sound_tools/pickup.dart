part of '../toolbox_sound_tools.dart';

class _PickupProfile {
  const _PickupProfile({
    required this.id,
    required this.targetBrightness,
    required this.targetLevel,
  });

  final String id;
  final double targetBrightness;
  final double targetLevel;
}

class _PickupTool extends StatefulWidget {
  const _PickupTool({this.fullScreen = false});

  final bool fullScreen;

  @override
  State<_PickupTool> createState() => _PickupToolState();
}

class _PickupToolState extends State<_PickupTool> {
  static const List<_PickupProfile> _profiles = <_PickupProfile>[
    _PickupProfile(id: 'piezo', targetBrightness: 0.34, targetLevel: 0.34),
    _PickupProfile(id: 'contact', targetBrightness: 0.24, targetLevel: 0.30),
    _PickupProfile(id: 'magnetic', targetBrightness: 0.20, targetLevel: 0.28),
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

  StreamSubscription<Uint8List>? _pcmSubscription;
  StreamSubscription<RecordState>? _stateSubscription;

  String _profileId = _profiles.first.id;
  bool _hasPermission = false;
  bool _monitoring = false;
  bool _starting = false;
  bool _phaseReverse = false;
  String? _error;

  double _preamp = 0.54;
  double _gate = 0.14;
  double _presence = 0.50;
  double _inputLevel = 0;
  double _peakLevel = 0;
  double _brightness = 0.24;
  double? _frequency;
  int? _cents;
  String? _noteLabel;
  final List<double> _history = List<double>.filled(42, 0);

  _PickupProfile get _activeProfile {
    return _profiles.firstWhere(
      (item) => item.id == _profileId,
      orElse: () => _profiles.first,
    );
  }

  bool _isCompactPhoneWidth(double width) =>
      width < (widget.fullScreen ? 520 : 430);

  String _profileLabel(AppI18n i18n, String profileId) {
    return switch (profileId) {
      'contact' => pickUiText(i18n, zh: '接触式', en: 'Contact'),
      'magnetic' => pickUiText(i18n, zh: '磁拾', en: 'Magnetic'),
      _ => pickUiText(i18n, zh: '压电', en: 'Piezo'),
    };
  }

  String _profileSubtitle(AppI18n i18n) {
    return switch (_profileId) {
      'contact' => pickUiText(
        i18n,
        zh: '更关注箱体与桌面振动，适合接触式贴片拾音。',
        en: 'Focuses more on body vibration for contact-style pickups.',
      ),
      'magnetic' => pickUiText(
        i18n,
        zh: '更适合圆润、中低频更厚的磁拾响应。',
        en: 'Targets a rounder response closer to magnetic pickups.',
      ),
      _ => pickUiText(
        i18n,
        zh: '默认面向压电拾音，强调清晰前缘和动态峰值。',
        en: 'Targets a typical piezo response with clear attack and peaks.',
      ),
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
      return pickUiText(i18n, zh: '偏闷', en: 'Dark');
    }
    if (value > 0.42) {
      return pickUiText(i18n, zh: '偏亮', en: 'Bright');
    }
    return pickUiText(i18n, zh: '平衡', en: 'Balanced');
  }

  String _statusLabel(AppI18n i18n) {
    if (_starting) {
      return pickUiText(i18n, zh: '启动中', en: 'Starting');
    }
    if (_monitoring) {
      return pickUiText(i18n, zh: '监听中', en: 'Monitoring');
    }
    return pickUiText(i18n, zh: '待机', en: 'Idle');
  }

  String _pitchDisplay() {
    if (_noteLabel == null) return '--';
    final cents = _cents;
    if (cents == null) return _noteLabel!;
    final centsText = cents == 0 ? '0c' : '${cents > 0 ? '+' : ''}${cents}c';
    return '$_noteLabel $centsText';
  }

  String _guidance(AppI18n i18n) {
    if (_error != null) return _error!;
    if (!_hasPermission && !_monitoring) {
      return pickUiText(
        i18n,
        zh: '需要麦克风权限才能开始拾音调校。',
        en: 'Microphone permission is required before pickup calibration starts.',
      );
    }
    if (!_monitoring) {
      return pickUiText(
        i18n,
        zh: '点击开始监听，然后在稳定单音下观察电平、峰值与音高。',
        en: 'Start monitoring, then play stable single notes to inspect level, peak, and pitch.',
      );
    }
    if (_effectivePeak > 0.96) {
      return pickUiText(
        i18n,
        zh: '峰值接近削波，建议降低前级增益或拉远麦克风距离。',
        en: 'Peak is near clipping; lower preamp or increase the mic distance.',
      );
    }
    if (_effectiveLevel < _gate * 0.92) {
      return pickUiText(
        i18n,
        zh: '输入偏小，建议靠近拾音点或适当提高前级增益。',
        en: 'Input is low; move closer to the pickup spot or raise the preamp slightly.',
      );
    }
    if (_noteLabel == null) {
      return pickUiText(
        i18n,
        zh: '当前基频不稳定，先保持单音持续发声，再做拾音调节。',
        en: 'Pitch is unstable; hold a single sustained note before adjusting the pickup.',
      );
    }
    final brightnessDelta =
        (_effectiveBrightness - _activeProfile.targetBrightness).abs();
    if (_effectiveBrightness < _activeProfile.targetBrightness - 0.08) {
      return pickUiText(
        i18n,
        zh: '当前偏闷，可提高亮度补偿或让拾音点更靠近琴桥。',
        en: 'The signal is dark; raise presence or move the pickup closer to the bridge.',
      );
    }
    if (_effectiveBrightness > _activeProfile.targetBrightness + 0.08) {
      return pickUiText(
        i18n,
        zh: '当前偏亮，可降低亮度补偿或让拾音点稍远离琴桥。',
        en: 'The signal is bright; reduce presence or move the pickup slightly away from the bridge.',
      );
    }
    if (_phaseReverse) {
      return pickUiText(
        i18n,
        zh: '相位已反转，适合与第二路拾音并用时对比低频厚度。',
        en: 'Phase is inverted; compare the low-end when blending with a second pickup.',
      );
    }
    if (brightnessDelta <= 0.08 &&
        (_effectiveLevel - _activeProfile.targetLevel).abs() <= 0.08) {
      return pickUiText(
        i18n,
        zh: '当前拾音已接近平衡，可微调噪声门收紧底噪。',
        en: 'The pickup is close to balanced; fine-tune the gate to tighten the noise floor.',
      );
    }
    return pickUiText(
      i18n,
      zh: '继续小幅调整前级、噪声门和亮度补偿，优先让峰值留出余量。',
      en: 'Continue with small preamp, gate, and presence changes while keeping peak headroom.',
    );
  }

  Future<void> _startMonitoring() async {
    if (_starting || _monitoring) return;
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      final granted = await _recorder.hasPermission();
      if (!granted) {
        if (!mounted) return;
        setState(() {
          _hasPermission = false;
          _starting = false;
          _error = pickUiText(
            _toolboxI18n(context, listen: false),
            zh: '麦克风权限被拒绝。',
            en: 'Microphone permission was denied.',
          );
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
      setState(() {
        _hasPermission = true;
        _starting = false;
        _monitoring = true;
      });
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
    setState(() => _monitoring = false);
  }

  void _handlePcmChunk(Uint8List chunk) {
    final byteData = ByteData.sublistView(chunk);
    final sampleCount = byteData.lengthInBytes ~/ 2;
    if (sampleCount < 128) return;

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
    final detectedFrequency = rms > 0.015
        ? _detectPitch(normalized, 44100)
        : null;

    String? noteLabel;
    int? cents;
    if (detectedFrequency != null) {
      final midi = 69 + 12 * math.log(detectedFrequency / 440.0) / math.ln2;
      final nearestMidi = midi.round();
      final noteName = _noteNames[((nearestMidi % 12) + 12) % 12];
      final octave = (nearestMidi ~/ 12) - 1;
      noteLabel = '$noteName$octave';
      cents = ((midi - nearestMidi) * 100).round();
    }

    final bucketCount = 6;
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

  double? _detectPitch(List<double> samples, int sampleRate) {
    if (samples.length < 1024) return null;
    final window = samples.length > 2048
        ? samples.sublist(samples.length - 2048)
        : samples;
    final mean = window.reduce((a, b) => a + b) / window.length;
    for (var i = 0; i < window.length; i += 1) {
      window[i] = window[i] - mean;
    }

    final minLag = math.max(24, sampleRate ~/ 1000);
    final maxLag = math.min(window.length ~/ 2, sampleRate ~/ 65);
    var bestLag = 0;
    var bestScore = 0.0;

    for (var lag = minLag; lag <= maxLag; lag += 1) {
      var correlation = 0.0;
      var energyA = 0.0;
      var energyB = 0.0;
      for (var i = 0; i < window.length - lag; i += 1) {
        final a = window[i];
        final b = window[i + lag];
        correlation += a * b;
        energyA += a * a;
        energyB += b * b;
      }
      final denominator = math.sqrt(energyA * energyB);
      if (denominator <= 1e-9) continue;
      final score = correlation / denominator;
      if (score > bestScore) {
        bestScore = score;
        bestLag = lag;
      }
    }

    if (bestLag == 0 || bestScore < 0.72) return null;
    final frequency = sampleRate / bestLag;
    if (frequency < 65 || frequency > 1400) return null;
    return frequency;
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
                      pickUiText(i18n, zh: '实时拾音监看', en: 'Live pickup monitor'),
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
                            child: CircularProgressIndicator(
                              value: level,
                              strokeWidth: compact ? 10 : 12,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.08,
                              ),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                meterColor,
                              ),
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
                          pickUiText(
                            i18n,
                            zh: '建议：${_guidance(i18n)}',
                            en: 'Advice: ${_guidance(i18n)}',
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: compact ? 68 : 80,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: _history
                                .map(
                                  (value) => Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 1,
                                      ),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 80,
                                        ),
                                        height: math.max(
                                          6,
                                          value * (compact ? 68 : 80),
                                        ),
                                        decoration: BoxDecoration(
                                          color: meterColor.withValues(
                                            alpha: 0.92,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_pcmSubscription?.cancel());
    unawaited(_stateSubscription?.cancel());
    unawaited(_recorder.dispose());
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
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  ToolboxMetricCard(label: 'Status', value: _statusLabel(i18n)),
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
                ],
              ),
              const SizedBox(height: 14),
              SectionHeader(
                title: pickUiText(i18n, zh: '拾音舞台', en: 'Pickup stage'),
                subtitle: pickUiText(
                  i18n,
                  zh: compact
                      ? '通过手机麦克风观察拾音电平、峰值、音高与明亮度，快速完成调校。'
                      : '通过麦克风实时分析电平、峰值、基频和音色倾向，辅助完成拾音调校。',
                  en: compact
                      ? 'Use the phone mic to inspect pickup level, peaks, pitch, and brightness.'
                      : 'Use the microphone to inspect level, peaks, pitch, and tonal balance in real time.',
                ),
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
                      pickUiText(
                        i18n,
                        zh: _monitoring ? '停止监听' : '开始监听',
                        en: _monitoring ? 'Stop monitor' : 'Start monitor',
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => setState(() {
                      _history
                        ..clear()
                        ..addAll(List<double>.filled(42, 0));
                      _frequency = null;
                      _noteLabel = null;
                      _cents = null;
                      _inputLevel = 0;
                      _peakLevel = 0;
                      _brightness = _activeProfile.targetBrightness;
                    }),
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(pickUiText(i18n, zh: '重置读数', en: 'Reset')),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SectionHeader(
                title: pickUiText(i18n, zh: '拾音类型', en: 'Pickup type'),
                subtitle: _profileSubtitle(i18n),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _profiles
                    .map(
                      (item) => ChoiceChip(
                        label: Text(_profileLabel(i18n, item.id)),
                        selected: _profileId == item.id,
                        onSelected: (_) => setState(() => _profileId = item.id),
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: 14),
              SectionHeader(
                title: pickUiText(i18n, zh: '调校参数', en: 'Calibration'),
                subtitle: pickUiText(
                  i18n,
                  zh: '前级增益用于预估输入余量，噪声门控制静音底噪，亮度补偿用于观察音色趋势。',
                  en: 'Preamp estimates headroom, gate controls noise floor, and presence tracks tonal brightness.',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                pickUiText(
                  i18n,
                  zh: '前级增益 ${(_preamp * 100).round()}%',
                  en: 'Preamp ${(_preamp * 100).round()}%',
                ),
              ),
              Slider(
                value: _preamp,
                min: 0.0,
                max: 1.0,
                divisions: 20,
                onChanged: (value) => setState(() => _preamp = value),
              ),
              Text(
                pickUiText(
                  i18n,
                  zh: '噪声门 ${(_gate * 100).round()}%',
                  en: 'Gate ${(_gate * 100).round()}%',
                ),
              ),
              Slider(
                value: _gate,
                min: 0.05,
                max: 0.35,
                divisions: 15,
                onChanged: (value) => setState(() => _gate = value),
              ),
              Text(
                pickUiText(
                  i18n,
                  zh: '亮度补偿 ${(_presence * 100).round()}%',
                  en: 'Presence ${(_presence * 100).round()}%',
                ),
              ),
              Slider(
                value: _presence,
                min: 0.0,
                max: 1.0,
                divisions: 20,
                onChanged: (value) => setState(() => _presence = value),
              ),
              SwitchListTile.adaptive(
                value: _phaseReverse,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) => setState(() => _phaseReverse = value),
                title: Text(pickUiText(i18n, zh: '相位反转', en: 'Phase reverse')),
                subtitle: Text(
                  pickUiText(
                    i18n,
                    zh: '双拾音或外接前级并用时，可用来对比低频厚度。',
                    en: 'Useful for comparing low-end when blending two pickup sources.',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
