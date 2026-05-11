part of 'toolbox_human_tests.dart';

enum _MicLabMode { low, high, sustain, noise }

class AuditoryLabPanel extends StatelessWidget {
  const AuditoryLabPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionHeader(
          title: pickUiText(i18n, zh: '音量校准', en: 'Volume calibration'),
          subtitle: pickUiText(
            i18n,
            zh: '先检查播放音量，再进入频率、灵敏度、空间和麦克风测试。尽量让输出稳定在推荐范围。',
            en: 'Check playback volume first, then run frequency, sensitivity, spatial, and mic tests. Keep output near the recommended range.',
          ),
        ),
        const SizedBox(height: 10),
        const _AuditoryVolumeReadinessCard(),
        const SizedBox(height: 12),
        const _AuditoryTestCard(),
      ],
    );
  }
}

class AcousticExperimentTestPage extends StatelessWidget {
  const AcousticExperimentTestPage({super.key});

  static const Color _accent = Color(0xFF7F8B55);

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: pickUiText(i18n, zh: '声学实验', en: 'Acoustic experiment'),
      subtitle: pickUiText(
        i18n,
        zh: '使用麦克风观察低音、高音、持续发声和环境噪声，输出相对声学指标。',
        en: 'Use the microphone to observe low tone, high tone, vocal sustain, and ambient noise with relative acoustic metrics.',
      ),
      accent: _accent,
      icon: Icons.mic_external_on_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：允许麦克风权限，选择实验模式并开始监测',
        en: 'Next: allow microphone access, choose a mode, and start monitoring',
      ),
      child: const AcousticExperimentPanel(),
    );
  }
}

class AcousticExperimentPanel extends StatelessWidget {
  const AcousticExperimentPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionHeader(
          title: pickUiText(i18n, zh: '麦克风声学实验', en: 'Mic acoustic lab'),
          subtitle: pickUiText(
            i18n,
            zh: '通过麦克风测低音、高音、持续性和环境噪声。结果为本地自测参考，不构成诊断。',
            en: 'Use the microphone to measure low tone, high tone, sustain, and ambient noise. Results are local self-check references, not a diagnosis.',
          ),
        ),
        const SizedBox(height: 10),
        _HumanSettingsSection(
          title: pickUiText(i18n, zh: '声学指标', en: 'Acoustic metrics'),
          subtitle: pickUiText(
            i18n,
            zh: '显示相对 dBFS、峰值、音高、稳定性、持续性、曲线平滑度和环境评分。',
            en: 'Shows relative dBFS, peak, pitch, stability, sustain, smoothness, and ambient score.',
          ),
          initiallyExpanded: true,
          child: const _AuditoryMicLabCard(),
        ),
      ],
    );
  }
}

class _AuditoryVolumeReadinessCard extends StatefulWidget {
  const _AuditoryVolumeReadinessCard();

  @override
  State<_AuditoryVolumeReadinessCard> createState() =>
      _AuditoryVolumeReadinessCardState();
}

class _AuditoryVolumeReadinessCardState
    extends State<_AuditoryVolumeReadinessCard> {
  ToolboxAudioVolumeSnapshot? _snapshot;
  bool _loading = true;
  bool _applying = false;
  bool _promptShown = false;
  String? _statusText;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_refreshVolumeState());
    });
  }

  Future<void> _refreshVolumeState() async {
    setState(() {
      _loading = true;
      _statusText = null;
    });
    try {
      final snapshot = await ToolboxAudioVolumeService.inspectPlaybackVolume(
        recommendedRatio: 0.65,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshot = snapshot;
        _loading = false;
        _statusText = snapshot.message ?? 'ok';
      });
      if (snapshot.needsAdjustment && snapshot.canAutoApply) {
        if (!mounted) {
          return;
        }
        setState(() => _statusText = 'auto_applying');
        await _applyRecommendedVolume();
      } else if (!snapshot.canAutoApply &&
          snapshot.needsAdjustment &&
          !_promptShown) {
        _promptShown = true;
        await _showManualAdjustmentPrompt(snapshot);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _statusText = 'read_failed';
      });
    }
  }

  Future<void> _applyRecommendedVolume() async {
    final snapshot = _snapshot;
    if (snapshot == null || !snapshot.canAutoApply || _applying) {
      return;
    }
    setState(() => _applying = true);
    try {
      final applied =
          await ToolboxAudioVolumeService.applyRecommendedPlaybackVolume(
            recommendedRatio: snapshot.recommendedRatio,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshot = applied;
        _applying = false;
        _statusText =
            applied.message ?? (applied.needsAdjustment ? 'auto_failed' : 'ok');
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _applying = false;
        _statusText = 'auto_failed';
      });
    }
  }

  Future<void> _showManualAdjustmentPrompt(
    ToolboxAudioVolumeSnapshot snapshot,
  ) async {
    if (!mounted) {
      return;
    }
    final context = this.context;
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            pickUiText(
              i18n,
              zh: '请手动调整系统音量',
              en: 'Adjust system volume manually',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                pickUiText(
                  i18n,
                  zh: '当前设备无法自动改动系统媒体音量，请先把音量调到推荐范围再继续测试。',
                  en: 'This device cannot change the system media volume automatically. Please move the volume into the recommended range before continuing.',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                pickUiText(
                  i18n,
                  zh: '当前值: ${(snapshot.currentRatio * 100).round()}%  推荐值: ${(snapshot.recommendedRatio * 100).round()}%',
                  en: 'Current: ${(snapshot.currentRatio * 100).round()}%  Recommended: ${(snapshot.recommendedRatio * 100).round()}%',
                ),
              ),
              if (snapshot.currentIndex != null &&
                  snapshot.maxIndex != null) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  pickUiText(
                    i18n,
                    zh: '系统音量档位: ${snapshot.currentIndex}/${snapshot.maxIndex}',
                    en: 'System volume index: ${snapshot.currentIndex}/${snapshot.maxIndex}',
                  ),
                ),
              ],
              if (snapshot.currentDb != null) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  pickUiText(
                    i18n,
                    zh: '参考输出: ${snapshot.currentDb!.toStringAsFixed(1)} dB',
                    en: 'Reference output: ${snapshot.currentDb!.toStringAsFixed(1)} dB',
                  ),
                ),
              ],
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(pickUiText(i18n, zh: '稍后', en: 'Later')),
            ),
            FilledButton.tonalIcon(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _refreshVolumeState();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: Text(pickUiText(i18n, zh: '我已调整', en: 'I adjusted it')),
            ),
          ],
        );
      },
    );
  }

  String _volumeStatusMessage(
    AppI18n i18n,
    ToolboxAudioVolumeSnapshot? snapshot,
  ) {
    if (_statusText == 'auto_applying') {
      return pickUiText(
        i18n,
        zh: '正在自动调整系统媒体音量...',
        en: 'Adjusting system media volume automatically...',
      );
    }
    if (_statusText == 'read_failed') {
      return pickUiText(
        i18n,
        zh: '无法读取系统媒体音量。请手动把媒体音量调到约 65%。',
        en: 'Cannot read system media volume. Set media volume near 65% manually.',
      );
    }
    if (_statusText == 'auto_failed') {
      return pickUiText(
        i18n,
        zh: '自动调整未完成。请手动调整系统媒体音量后重新检查。',
        en: 'Automatic adjustment did not complete. Adjust media volume manually and recheck.',
      );
    }
    if (snapshot == null) {
      return pickUiText(i18n, zh: '等待设备音量检查。', en: 'Waiting for volume check.');
    }
    if (!snapshot.isSupported) {
      return pickUiText(
        i18n,
        zh: '当前平台不支持读取系统音量，请按设备音量键手动校准。',
        en: 'This platform cannot report system volume; calibrate manually with volume keys.',
      );
    }
    if (snapshot.needsAdjustment) {
      return snapshot.canAutoApply
          ? pickUiText(
              i18n,
              zh: '音量不在建议范围内，可使用自动调整或手动调到推荐值。',
              en: 'Volume is outside the recommended range. Use auto adjust or set it manually.',
            )
          : pickUiText(
              i18n,
              zh: '音量不在建议范围内，请手动调到推荐值再开始测试。',
              en: 'Volume is outside the recommended range. Set it manually before testing.',
            );
    }
    return pickUiText(
      i18n,
      zh: '系统媒体音量已处于建议范围。',
      en: 'System media volume is in the recommended range.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final snapshot = _snapshot;
    final current = snapshot?.currentRatio ?? 0;
    final recommended = snapshot?.recommendedRatio ?? 0.65;
    final needsAdjustment = snapshot?.needsAdjustment ?? false;
    return _HumanPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              ToolboxMetricCard(
                label: pickUiText(i18n, zh: '平台', en: 'Platform'),
                value: snapshot?.platformName ?? '--',
              ),
              ToolboxMetricCard(
                label: pickUiText(i18n, zh: '当前', en: 'Current'),
                value: '${(current * 100).round()}%',
              ),
              ToolboxMetricCard(
                label: pickUiText(i18n, zh: '推荐', en: 'Recommended'),
                value: '${(recommended * 100).round()}%',
              ),
              ToolboxMetricCard(
                label: pickUiText(i18n, zh: '自动调整', en: 'Auto adjust'),
                value: snapshot == null
                    ? '--'
                    : snapshot.canAutoApply
                    ? pickUiText(i18n, zh: '可用', en: 'Yes')
                    : pickUiText(i18n, zh: '手动', en: 'Manual'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: current.clamp(0.0, 1.0).toDouble(),
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _loading
                ? pickUiText(
                    i18n,
                    zh: '正在检查系统音量...',
                    en: 'Checking system volume...',
                  )
                : needsAdjustment
                ? pickUiText(
                    i18n,
                    zh: '音量未落在推荐范围内，请先调整再开始测试。',
                    en: 'The volume is outside the recommended range. Adjust it before starting the test.',
                  )
                : pickUiText(
                    i18n,
                    zh: '系统音量已适合当前听觉测试。',
                    en: 'The system volume is ready for the current hearing test.',
                  ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (snapshot?.message != null &&
              snapshot!.message!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              _volumeStatusMessage(i18n, snapshot),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: _loading ? null : _refreshVolumeState,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(pickUiText(i18n, zh: '重新检查', en: 'Recheck')),
              ),
              if (snapshot != null && snapshot.canAutoApply)
                FilledButton.tonalIcon(
                  onPressed: _applying ? null : _applyRecommendedVolume,
                  icon: const Icon(Icons.volume_up_rounded),
                  label: Text(
                    _applying
                        ? pickUiText(i18n, zh: '正在调整', en: 'Adjusting')
                        : pickUiText(i18n, zh: '自动调整', en: 'Auto adjust'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MicModeSpec {
  const _MicModeSpec({
    required this.zhLabel,
    required this.enLabel,
    required this.zhDescription,
    required this.enDescription,
    required this.icon,
    required this.targetMinHz,
    required this.targetMaxHz,
  });

  final String zhLabel;
  final String enLabel;
  final String zhDescription;
  final String enDescription;
  final IconData icon;
  final double targetMinHz;
  final double targetMaxHz;

  String label(AppI18n i18n) => pickUiText(i18n, zh: zhLabel, en: enLabel);

  String description(AppI18n i18n) =>
      pickUiText(i18n, zh: zhDescription, en: enDescription);
}

class _AuditoryMicLabCard extends StatefulWidget {
  const _AuditoryMicLabCard();

  @override
  State<_AuditoryMicLabCard> createState() => _AuditoryMicLabCardState();
}

class _AuditoryMicLabCardState extends State<_AuditoryMicLabCard> {
  static const Map<_MicLabMode, _MicModeSpec>
  _modeSpecs = <_MicLabMode, _MicModeSpec>{
    _MicLabMode.low: _MicModeSpec(
      zhLabel: '低音',
      enLabel: 'Low tone',
      zhDescription: '请用低沉、稳定的声音持续发声，检查低频音高、幅度和稳定性。',
      enDescription:
          'Produce a low, steady hum and check low-frequency pitch, level, and stability.',
      icon: Icons.arrow_downward_rounded,
      targetMinHz: 110,
      targetMaxHz: 240,
    ),
    _MicLabMode.high: _MicModeSpec(
      zhLabel: '高音',
      enLabel: 'High tone',
      zhDescription: '请用较高的声音持续发声，观察高频音高与曲线平滑程度。',
      enDescription:
          'Produce a higher tone and observe the high-frequency pitch and curve smoothness.',
      icon: Icons.arrow_upward_rounded,
      targetMinHz: 360,
      targetMaxHz: 860,
    ),
    _MicLabMode.sustain: _MicModeSpec(
      zhLabel: '持续',
      enLabel: 'Sustain',
      zhDescription: '保持均匀发声 5 秒以上，系统会给出持续性和波动指标。',
      enDescription:
          'Hold a steady sound for 5+ seconds and measure sustain and variation.',
      icon: Icons.graphic_eq_rounded,
      targetMinHz: 160,
      targetMaxHz: 420,
    ),
    _MicLabMode.noise: _MicModeSpec(
      zhLabel: '噪声仪',
      enLabel: 'Noise meter',
      zhDescription: '保持安静，测量环境噪声、峰值和相对分贝。',
      enDescription:
          'Stay quiet to measure ambient noise, peak, and relative dBFS.',
      icon: Icons.hearing_disabled_rounded,
      targetMinHz: 0,
      targetMaxHz: 0,
    ),
  };

  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _pcmSubscription;
  StreamSubscription<RecordState>? _stateSubscription;
  final List<double> _levelHistory = List<double>.filled(72, 0);
  final List<double> _pitchWindow = <double>[];
  final Stopwatch _stopwatch = Stopwatch();

  _MicLabMode _mode = _MicLabMode.low;
  bool _starting = false;
  bool _running = false;
  String? _error;
  double _level = 0;
  double _peak = 0;
  double _dbfs = -120;
  double? _pitchHz;
  double _pitchStability = 0;
  double _sustainScore = 0;
  double _ambientScore = 0;
  double _lastCurveSmoothness = 0;

  @override
  void dispose() {
    unawaited(_pcmSubscription?.cancel());
    unawaited(_stateSubscription?.cancel());
    unawaited(_recorder.dispose());
    _stopwatch
      ..stop()
      ..reset();
    super.dispose();
  }

  void _setMode(_MicLabMode mode) {
    if (_mode == mode || _running || _starting) {
      return;
    }
    setState(() {
      _mode = mode;
      _error = null;
      _pitchWindow.clear();
      _levelHistory.fillRange(0, _levelHistory.length, 0);
      _pitchHz = null;
      _pitchStability = 0;
      _sustainScore = 0;
      _ambientScore = 0;
      _lastCurveSmoothness = 0;
      _level = 0;
      _peak = 0;
      _dbfs = -120;
    });
  }

  Future<void> _startMonitoring() async {
    if (_starting || _running) {
      return;
    }
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      final granted = await _recorder.hasPermission();
      if (!granted) {
        if (!mounted) {
          return;
        }
        setState(() {
          _starting = false;
          _error = 'microphone_permission_denied';
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
          if (!mounted) {
            return;
          }
          setState(() {
            _error = '$error';
            _running = false;
            _starting = false;
          });
        },
        onDone: () {
          if (!mounted) {
            return;
          }
          setState(() {
            _running = false;
            _starting = false;
          });
        },
        cancelOnError: false,
      );

      _stateSubscription ??= _recorder.onStateChanged().listen((state) {
        if (!mounted) {
          return;
        }
        setState(() {
          _running = state == RecordState.record || state == RecordState.pause;
        });
      });

      if (!mounted) {
        return;
      }
      _stopwatch
        ..reset()
        ..start();
      setState(() {
        _starting = false;
        _running = true;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _starting = false;
        _running = false;
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
    if (!mounted) {
      return;
    }
    _stopwatch
      ..stop()
      ..reset();
    setState(() => _running = false);
  }

  void _reset() {
    setState(() {
      _error = null;
      _pitchWindow.clear();
      _levelHistory.fillRange(0, _levelHistory.length, 0);
      _pitchHz = null;
      _pitchStability = 0;
      _sustainScore = 0;
      _ambientScore = 0;
      _lastCurveSmoothness = 0;
      _level = 0;
      _peak = 0;
      _dbfs = -120;
    });
  }

  void _handlePcmChunk(Uint8List chunk) {
    final byteData = ByteData.sublistView(chunk);
    final sampleCount = byteData.lengthInBytes ~/ 2;
    if (sampleCount < 256) {
      return;
    }

    var peak = 0.0;
    var sumSquares = 0.0;
    final samples = List<double>.filled(sampleCount, 0);
    for (var i = 0; i < sampleCount; i += 1) {
      final value = byteData.getInt16(i * 2, Endian.little) / 32768.0;
      samples[i] = value;
      final absValue = value.abs();
      if (absValue > peak) {
        peak = absValue;
      }
      sumSquares += value * value;
    }

    final rms = math.sqrt(sumSquares / sampleCount);
    final dbfs = rms <= 1e-6
        ? -120.0
        : (20 * math.log(rms) / math.ln10).clamp(-120.0, 0.0).toDouble();
    final detectedPitch = _detectPitch(samples, 44100);
    _pushLevelHistory(rms);
    if (detectedPitch != null) {
      _pitchWindow.add(detectedPitch);
      if (_pitchWindow.length > 10) {
        _pitchWindow.removeAt(0);
      }
    } else if (_pitchWindow.length > 6) {
      _pitchWindow.removeAt(0);
    }

    final smoothPitch = _smoothedPitch();
    final stability = _pitchStabilityScore(smoothPitch);
    final sustain = _sustainScoreForMode(rms, smoothPitch);
    final ambientScore = _ambientNoiseScore(dbfs);
    final curveSmoothness = _curveSmoothness();

    if (!mounted) {
      return;
    }
    setState(() {
      _level = rms.clamp(0.0, 1.0).toDouble();
      _peak = peak.clamp(0.0, 1.0).toDouble();
      _dbfs = dbfs;
      _pitchHz = smoothPitch;
      _pitchStability = stability;
      _sustainScore = sustain;
      _ambientScore = ambientScore;
      _lastCurveSmoothness = curveSmoothness;
    });
  }

  void _pushLevelHistory(double level) {
    _levelHistory.removeAt(0);
    _levelHistory.add(level.clamp(0.0, 1.0).toDouble());
  }

  double? _smoothedPitch() {
    if (_pitchWindow.isEmpty) {
      return null;
    }
    final sorted = List<double>.of(_pitchWindow)..sort();
    return sorted[sorted.length ~/ 2];
  }

  double _pitchStabilityScore(double? pitch) {
    if (pitch == null || _pitchWindow.length < 3) {
      return 0;
    }
    final mean =
        _pitchWindow.fold<double>(0, (sum, value) => sum + value) /
        _pitchWindow.length;
    final variance =
        _pitchWindow.fold<double>(
          0,
          (sum, value) => sum + math.pow(value - mean, 2).toDouble(),
        ) /
        _pitchWindow.length;
    final deviation = math.sqrt(variance);
    final normalized = 1 - (deviation / math.max(1.0, mean * 0.08));
    return normalized.clamp(0.0, 1.0).toDouble();
  }

  double _sustainScoreForMode(double level, double? pitch) {
    if (_mode == _MicLabMode.noise) {
      return 0;
    }
    final spec = _modeSpecs[_mode]!;
    final targetCenter = (spec.targetMinHz + spec.targetMaxHz) / 2;
    final targetSpan = math.max(1.0, spec.targetMaxHz - spec.targetMinHz);
    final pitchScore = pitch == null
        ? 0.0
        : (1 - ((pitch - targetCenter).abs() / (targetSpan * 0.75)))
              .clamp(0.0, 1.0)
              .toDouble();
    final levelConsistency = _levelConsistency();
    return (pitchScore * 0.6 + levelConsistency * 0.4)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  double _ambientNoiseScore(double dbfs) {
    final quiet = dbfs <= -52;
    if (quiet) {
      return 1.0;
    }
    final normalized = 1 - (((dbfs + 52) / 38).clamp(0.0, 1.0));
    return normalized.toDouble();
  }

  double _levelConsistency() {
    final values = _levelHistory.where((value) => value > 0.001).toList();
    if (values.length < 3) {
      return 0;
    }
    final mean =
        values.fold<double>(0, (sum, value) => sum + value) / values.length;
    final meanDelta =
        values
            .map((value) => (value - mean).abs())
            .fold<double>(0, (sum, value) => sum + value) /
        values.length;
    final normalized = 1 - (meanDelta / math.max(0.08, mean * 0.9));
    return normalized.clamp(0.0, 1.0).toDouble();
  }

  double _curveSmoothness() {
    final values = _levelHistory.where((value) => value > 0.001).toList();
    if (values.length < 4) {
      return 0;
    }
    var delta = 0.0;
    for (var i = 1; i < values.length; i += 1) {
      delta += (values[i] - values[i - 1]).abs();
    }
    final normalized = 1 - (delta / math.max(0.2, values.length * 0.18));
    return normalized.clamp(0.0, 1.0).toDouble();
  }

  String _noiseLabel(AppI18n i18n) {
    if (_dbfs <= -52) {
      return pickUiText(i18n, zh: '安静', en: 'Quiet');
    }
    if (_dbfs <= -38) {
      return pickUiText(i18n, zh: '中等', en: 'Moderate');
    }
    return pickUiText(i18n, zh: '偏吵', en: 'Noisy');
  }

  String _pitchNoteLabel(double frequency) {
    final midi = (69 + 12 * math.log(frequency / 440.0) / math.ln2).round();
    const noteNames = <String>[
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
    final noteName = noteNames[((midi % 12) + 12) % 12];
    final octave = (midi ~/ 12) - 1;
    return '$noteName$octave';
  }

  double? _detectPitch(List<double> samples, int sampleRate) {
    if (samples.length < 2048) {
      return null;
    }
    final window = samples.length > 4096
        ? samples.sublist(samples.length - 4096)
        : List<double>.of(samples);
    final mean =
        window.fold<double>(0, (sum, value) => sum + value) / window.length;
    for (var i = 0; i < window.length; i += 1) {
      window[i] -= mean;
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
        final a = window[i];
        final b = window[i + lag];
        correlation += a * b;
        energyA += a * a;
        energyB += b * b;
      }
      final denominator = math.sqrt(energyA * energyB);
      if (denominator <= 1e-9) {
        continue;
      }
      final score = correlation / denominator;
      if (score > bestScore) {
        secondBestScore = bestScore;
        bestScore = score;
        bestLag = lag;
      } else if (score > secondBestScore) {
        secondBestScore = score;
      }
    }

    if (bestLag == 0 || bestScore < 0.72) {
      return null;
    }
    final refinedLag = _refineLag(window, bestLag);
    final frequency = sampleRate / refinedLag;
    if (frequency < 65 || frequency > 1400) {
      return null;
    }
    if ((bestScore - secondBestScore) < 0.08) {
      return null;
    }
    return frequency;
  }

  double _refineLag(List<double> window, int lag) {
    if (lag <= 1 || lag >= window.length - 1) {
      return lag.toDouble();
    }
    var y0 = 0.0;
    var y1 = 0.0;
    var y2 = 0.0;
    for (var i = 0; i < window.length - lag - 1; i += 1) {
      y0 += window[i] * window[i + lag - 1];
      y1 += window[i] * window[i + lag];
      y2 += window[i] * window[i + lag + 1];
    }
    final denominator = 2 * (y0 - 2 * y1 + y2);
    if (denominator.abs() < 1e-9) {
      return lag.toDouble();
    }
    final offset = (y0 - y2) / denominator;
    return lag + offset;
  }

  String _modeSummary(AppI18n i18n) {
    final spec = _modeSpecs[_mode]!;
    return switch (_mode) {
      _MicLabMode.low => pickUiText(
        i18n,
        zh: '目标: ${spec.targetMinHz.round()}-${spec.targetMaxHz.round()} Hz',
        en: 'Target: ${spec.targetMinHz.round()}-${spec.targetMaxHz.round()} Hz',
      ),
      _MicLabMode.high => pickUiText(
        i18n,
        zh: '目标: ${spec.targetMinHz.round()}-${spec.targetMaxHz.round()} Hz',
        en: 'Target: ${spec.targetMinHz.round()}-${spec.targetMaxHz.round()} Hz',
      ),
      _MicLabMode.sustain => pickUiText(
        i18n,
        zh: '保持稳定 5 秒以上，系统会读持续性和波动。',
        en: 'Hold steady for 5+ seconds; the system reads sustain and variation.',
      ),
      _MicLabMode.noise => pickUiText(
        i18n,
        zh: '保持安静，读环境噪声底和峰值。',
        en: 'Stay quiet and read the ambient floor and peaks.',
      ),
    };
  }

  Color _meterColor() {
    if (_mode == _MicLabMode.noise) {
      if (_dbfs <= -52) {
        return const Color(0xFF22C55E);
      }
      if (_dbfs <= -38) {
        return const Color(0xFFF59E0B);
      }
      return const Color(0xFFEF4444);
    }
    if (_pitchStability >= 0.82) {
      return const Color(0xFF22C55E);
    }
    if (_pitchStability >= 0.55) {
      return const Color(0xFF3B82F6);
    }
    return const Color(0xFFF97316);
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final theme = Theme.of(context);
    final spec = _modeSpecs[_mode]!;
    final levelPercent = _mode == _MicLabMode.noise
        ? ((_dbfs + 120) / 120).clamp(0.0, 1.0)
        : _level.clamp(0.0, 1.0);
    final pitchLabel = _pitchHz == null
        ? '--'
        : '${_pitchHz!.toStringAsFixed(1)} Hz · ${_pitchNoteLabel(_pitchHz!)}';
    return _HumanPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _MicLabMode.values
                .map((mode) {
                  final modeSpec = _modeSpecs[mode]!;
                  return ChoiceChip(
                    avatar: Icon(modeSpec.icon, size: 18),
                    label: Text(modeSpec.label(i18n)),
                    selected: _mode == mode,
                    onSelected: _running || _starting
                        ? null
                        : (_) => _setMode(mode),
                  );
                })
                .toList(growable: false),
          ),
          const SizedBox(height: 12),
          Text(
            spec.description(i18n),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              ToolboxMetricCard(
                label: pickUiText(i18n, zh: '电平', en: 'Level'),
                value: '${(_level * 100).round()}%',
              ),
              ToolboxMetricCard(
                label: pickUiText(i18n, zh: '峰值', en: 'Peak'),
                value: '${(_peak * 100).round()}%',
              ),
              ToolboxMetricCard(
                label: pickUiText(i18n, zh: '分贝', en: 'dBFS'),
                value: _dbfs.toStringAsFixed(1),
              ),
              ToolboxMetricCard(
                label: pickUiText(i18n, zh: '音高', en: 'Pitch'),
                value: pitchLabel,
              ),
              ToolboxMetricCard(
                label: pickUiText(i18n, zh: '稳定性', en: 'Stability'),
                value: '${(_pitchStability * 100).round()}%',
              ),
              ToolboxMetricCard(
                label: pickUiText(i18n, zh: '持续性', en: 'Sustain'),
                value: '${(_sustainScore * 100).round()}%',
              ),
              ToolboxMetricCard(
                label: pickUiText(i18n, zh: '曲线平滑', en: 'Smoothness'),
                value: '${(_lastCurveSmoothness * 100).round()}%',
              ),
              ToolboxMetricCard(
                label: pickUiText(i18n, zh: '环境评分', en: 'Ambient'),
                value: '${(_ambientScore * 100).round()}%',
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 560;
              final chartHeight = compact ? 96.0 : 112.0;
              return Column(
                children: <Widget>[
                  SizedBox(
                    height: chartHeight,
                    child: CustomPaint(
                      painter: _MicLevelHistoryPainter(
                        levelHistory: _levelHistory,
                        accent: _meterColor(),
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            minHeight: 10,
                            value: levelPercent,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _meterColor(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _mode == _MicLabMode.noise
                            ? '${_noiseLabel(i18n)} · ${_dbfs.toStringAsFixed(1)} dBFS'
                            : _mode == _MicLabMode.sustain
                            ? '${(_sustainScore * 100).round()}% · ${(_lastCurveSmoothness * 100).round()}%'
                            : '${(_pitchStability * 100).round()}% · ${(_lastCurveSmoothness * 100).round()}%',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: _meterColor(),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            _modeSummary(i18n),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              _error == 'microphone_permission_denied'
                  ? pickUiText(
                      i18n,
                      zh: '麦克风权限被拒绝，请允许后再开始测试。',
                      en: 'Microphone permission was denied. Allow it and try again.',
                    )
                  : _error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: _starting
                    ? null
                    : _running
                    ? _stopMonitoring
                    : _startMonitoring,
                icon: Icon(_running ? Icons.stop_rounded : Icons.mic_rounded),
                label: Text(
                  _starting
                      ? pickUiText(i18n, zh: '正在启动', en: 'Starting')
                      : _running
                      ? pickUiText(i18n, zh: '停止监测', en: 'Stop')
                      : pickUiText(i18n, zh: '开始监测', en: 'Start'),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _running || _starting ? _reset : null,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(pickUiText(i18n, zh: '重置', en: 'Reset')),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            pickUiText(
              i18n,
              zh: '建议：低音/高音时保持单一持续音；持续测试时尽量保持同一音高；噪声仪时保持安静并远离风噪。',
              en: 'Tip: keep a single steady sound for low/high mode, hold one pitch for sustain mode, and stay quiet for the noise meter.',
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _MicLevelHistoryPainter extends CustomPainter {
  const _MicLevelHistoryPainter({
    required this.levelHistory,
    required this.accent,
  });

  final List<double> levelHistory;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final background = Paint()
      ..color = accent.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(16)),
      background,
    );

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i += 1) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path();
    final fill = Path();
    final count = levelHistory.length;
    for (var i = 0; i < count; i += 1) {
      final level = levelHistory[i].clamp(0.0, 1.0);
      final x = count <= 1 ? 0.0 : size.width * i / (count - 1);
      final y = size.height - (level * size.height);
      if (i == 0) {
        path.moveTo(x, y);
        fill.moveTo(x, size.height);
        fill.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fill.lineTo(x, y);
      }
    }
    fill.lineTo(size.width, size.height);
    fill.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          accent.withValues(alpha: 0.34),
          accent.withValues(alpha: 0.02),
        ],
      ).createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawPath(fill, fillPaint);

    final linePaint = Paint()
      ..color = accent
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _MicLevelHistoryPainter oldDelegate) {
    return oldDelegate.levelHistory != levelHistory ||
        oldDelegate.accent != accent;
  }
}
