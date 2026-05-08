part of 'toolbox_human_tests.dart';

enum _AuditoryMode { reaction, frequency, volume, channel }

enum _AuditoryPhase { idle, waiting, cue, done }

enum _AuditoryStimulus {
  cue,
  hz500,
  hz1000,
  hz4000,
  soft,
  normal,
  loud,
  left,
  center,
  right,
}

class AuditoryReactionTestPage extends StatelessWidget {
  const AuditoryReactionTestPage({super.key});

  static const Color _accent = Color(0xFF6E9BC3);

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: pickUiText(i18n, zh: '听觉反应', en: 'Auditory reaction'),
      subtitle: pickUiText(
        i18n,
        zh: '使用合成提示音训练听觉反应，并模拟频率、音量和左右声道辨别。',
        en: 'Train reaction to synthetic cue tones, with simulated frequency, volume, and channel checks.',
      ),
      accent: _accent,
      icon: Icons.hearing_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：打开声音并开始一组听觉挑战',
        en: 'Next: enable audio and start an auditory challenge',
      ),
      child: const _AuditoryReactionCard(),
    );
  }
}

class _AuditoryModeCopy {
  const _AuditoryModeCopy({
    required this.zhLabel,
    required this.enLabel,
    required this.zhDescription,
    required this.enDescription,
    required this.icon,
  });

  final String zhLabel;
  final String enLabel;
  final String zhDescription;
  final String enDescription;
  final IconData icon;

  String label(AppI18n i18n) => pickUiText(i18n, zh: zhLabel, en: enLabel);

  String description(AppI18n i18n) =>
      pickUiText(i18n, zh: zhDescription, en: enDescription);
}

class _AuditoryStimulusSpec {
  const _AuditoryStimulusSpec({
    required this.mode,
    required this.zhLabel,
    required this.enLabel,
    required this.icon,
    required this.frequencyHz,
    required this.outputVolume,
    required this.leftGain,
    required this.rightGain,
  });

  final _AuditoryMode mode;
  final String zhLabel;
  final String enLabel;
  final IconData icon;
  final double frequencyHz;
  final double outputVolume;
  final double leftGain;
  final double rightGain;

  String label(AppI18n i18n) => pickUiText(i18n, zh: zhLabel, en: enLabel);
}

class _AuditoryRecord {
  const _AuditoryRecord({
    required this.mode,
    required this.stimulus,
    required this.correct,
    required this.milliseconds,
    this.falseStart = false,
  });

  final _AuditoryMode mode;
  final _AuditoryStimulus stimulus;
  final bool correct;
  final int milliseconds;
  final bool falseStart;
}

class _AuditoryReactionCard extends StatefulWidget {
  const _AuditoryReactionCard();

  @override
  State<_AuditoryReactionCard> createState() => _AuditoryReactionCardState();
}

class _AuditoryReactionCardState extends State<_AuditoryReactionCard> {
  static const Color _accent = AuditoryReactionTestPage._accent;
  static const List<_AuditoryMode> _modeOrder = <_AuditoryMode>[
    _AuditoryMode.reaction,
    _AuditoryMode.frequency,
    _AuditoryMode.volume,
    _AuditoryMode.channel,
  ];
  static const Map<_AuditoryMode, _AuditoryModeCopy>
  _modeCopies = <_AuditoryMode, _AuditoryModeCopy>{
    _AuditoryMode.reaction: _AuditoryModeCopy(
      zhLabel: '反应',
      enLabel: 'Reaction',
      zhDescription: '听到提示音后尽快点击。',
      enDescription: 'Tap as soon as the cue tone appears.',
      icon: Icons.speed_rounded,
    ),
    _AuditoryMode.frequency: _AuditoryModeCopy(
      zhLabel: '频率',
      enLabel: 'Frequency',
      zhDescription: '辨别低频、中频或高频提示音。',
      enDescription: 'Identify low, mid, or high-frequency tones.',
      icon: Icons.graphic_eq_rounded,
    ),
    _AuditoryMode.volume: _AuditoryModeCopy(
      zhLabel: '音量',
      enLabel: 'Volume',
      zhDescription: '辨别同一频率下的低、中、高音量。',
      enDescription: 'Identify soft, medium, or loud tones at one frequency.',
      icon: Icons.volume_up_rounded,
    ),
    _AuditoryMode.channel: _AuditoryModeCopy(
      zhLabel: '声道',
      enLabel: 'Channel',
      zhDescription: '辨别声音来自左侧、中间或右侧。',
      enDescription: 'Identify whether the tone is left, centered, or right.',
      icon: Icons.compare_arrows_rounded,
    ),
  };
  static const List<_AuditoryStimulus> _reactionStimuli = <_AuditoryStimulus>[
    _AuditoryStimulus.cue,
  ];
  static const List<_AuditoryStimulus> _frequencyStimuli = <_AuditoryStimulus>[
    _AuditoryStimulus.hz500,
    _AuditoryStimulus.hz1000,
    _AuditoryStimulus.hz4000,
  ];
  static const List<_AuditoryStimulus> _volumeStimuli = <_AuditoryStimulus>[
    _AuditoryStimulus.soft,
    _AuditoryStimulus.normal,
    _AuditoryStimulus.loud,
  ];
  static const List<_AuditoryStimulus> _channelStimuli = <_AuditoryStimulus>[
    _AuditoryStimulus.left,
    _AuditoryStimulus.center,
    _AuditoryStimulus.right,
  ];
  static const Map<_AuditoryStimulus, _AuditoryStimulusSpec> _stimulusSpecs =
      <_AuditoryStimulus, _AuditoryStimulusSpec>{
        _AuditoryStimulus.cue: _AuditoryStimulusSpec(
          mode: _AuditoryMode.reaction,
          zhLabel: '提示音',
          enLabel: 'Cue',
          icon: Icons.hearing_rounded,
          frequencyHz: 1000,
          outputVolume: 0.78,
          leftGain: 0.9,
          rightGain: 0.9,
        ),
        _AuditoryStimulus.hz500: _AuditoryStimulusSpec(
          mode: _AuditoryMode.frequency,
          zhLabel: '500 Hz',
          enLabel: '500 Hz',
          icon: Icons.south_rounded,
          frequencyHz: 500,
          outputVolume: 0.78,
          leftGain: 0.9,
          rightGain: 0.9,
        ),
        _AuditoryStimulus.hz1000: _AuditoryStimulusSpec(
          mode: _AuditoryMode.frequency,
          zhLabel: '1 kHz',
          enLabel: '1 kHz',
          icon: Icons.remove_rounded,
          frequencyHz: 1000,
          outputVolume: 0.78,
          leftGain: 0.9,
          rightGain: 0.9,
        ),
        _AuditoryStimulus.hz4000: _AuditoryStimulusSpec(
          mode: _AuditoryMode.frequency,
          zhLabel: '4 kHz',
          enLabel: '4 kHz',
          icon: Icons.north_rounded,
          frequencyHz: 4000,
          outputVolume: 0.78,
          leftGain: 0.9,
          rightGain: 0.9,
        ),
        _AuditoryStimulus.soft: _AuditoryStimulusSpec(
          mode: _AuditoryMode.volume,
          zhLabel: '低音量',
          enLabel: 'Soft',
          icon: Icons.volume_mute_rounded,
          frequencyHz: 1000,
          outputVolume: 0.28,
          leftGain: 0.9,
          rightGain: 0.9,
        ),
        _AuditoryStimulus.normal: _AuditoryStimulusSpec(
          mode: _AuditoryMode.volume,
          zhLabel: '中音量',
          enLabel: 'Medium',
          icon: Icons.volume_down_rounded,
          frequencyHz: 1000,
          outputVolume: 0.56,
          leftGain: 0.9,
          rightGain: 0.9,
        ),
        _AuditoryStimulus.loud: _AuditoryStimulusSpec(
          mode: _AuditoryMode.volume,
          zhLabel: '高音量',
          enLabel: 'Loud',
          icon: Icons.volume_up_rounded,
          frequencyHz: 1000,
          outputVolume: 0.92,
          leftGain: 0.9,
          rightGain: 0.9,
        ),
        _AuditoryStimulus.left: _AuditoryStimulusSpec(
          mode: _AuditoryMode.channel,
          zhLabel: '左声道',
          enLabel: 'Left',
          icon: Icons.keyboard_arrow_left_rounded,
          frequencyHz: 1000,
          outputVolume: 0.82,
          leftGain: 1,
          rightGain: 0,
        ),
        _AuditoryStimulus.center: _AuditoryStimulusSpec(
          mode: _AuditoryMode.channel,
          zhLabel: '双声道',
          enLabel: 'Both',
          icon: Icons.center_focus_strong_rounded,
          frequencyHz: 1000,
          outputVolume: 0.82,
          leftGain: 0.72,
          rightGain: 0.72,
        ),
        _AuditoryStimulus.right: _AuditoryStimulusSpec(
          mode: _AuditoryMode.channel,
          zhLabel: '右声道',
          enLabel: 'Right',
          icon: Icons.keyboard_arrow_right_rounded,
          frequencyHz: 1000,
          outputVolume: 0.82,
          leftGain: 0,
          rightGain: 1,
        ),
      };
  static final AudioContext _audioContext = AudioContextConfig(
    focus: AudioContextConfigFocus.mixWithOthers,
  ).build();

  final math.Random _random = math.Random();
  final Stopwatch _stopwatch = Stopwatch();
  final AudioPlayer _player = AudioPlayer();
  final Map<_AuditoryStimulus, Uint8List> _toneCache =
      <_AuditoryStimulus, Uint8List>{};
  final List<_AuditoryRecord> _records = <_AuditoryRecord>[];
  Timer? _signalTimer;
  Timer? _transitionTimer;
  int _token = 0;
  bool _audioConfigured = false;

  _AuditoryMode _mode = _AuditoryMode.reaction;
  _AuditoryPhase _phase = _AuditoryPhase.idle;
  _AuditoryStimulus _currentStimulus = _AuditoryStimulus.cue;
  int _roundCount = 8;
  int _roundIndex = 0;
  int _correct = 0;
  int _wrong = 0;
  int _falseStarts = 0;
  int _streak = 0;
  int _bestStreak = 0;
  bool _playbackError = false;
  bool? _lastCorrect;

  double get _accuracy {
    final total = _correct + _wrong;
    return total == 0 ? 0 : _correct / total;
  }

  int get _averageMs {
    final timingRecords = _records
        .where((item) => !item.falseStart && item.milliseconds > 0)
        .toList(growable: false);
    if (timingRecords.isEmpty) {
      return 0;
    }
    final total = timingRecords.fold<int>(
      0,
      (sum, item) => sum + item.milliseconds,
    );
    return (total / timingRecords.length).round();
  }

  @override
  void initState() {
    super.initState();
    _primeToneCache();
  }

  @override
  void dispose() {
    _token += 1;
    _signalTimer?.cancel();
    _transitionTimer?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    unawaited(_player.dispose());
    super.dispose();
  }

  void _primeToneCache() {
    for (final entry in _stimulusSpecs.entries) {
      _toneCache[entry.key] = _buildToneBytes(entry.value);
    }
  }

  void _start() {
    _token += 1;
    _signalTimer?.cancel();
    _transitionTimer?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    setState(() {
      _records.clear();
      _roundIndex = 0;
      _correct = 0;
      _wrong = 0;
      _falseStarts = 0;
      _streak = 0;
      _bestStreak = 0;
      _lastCorrect = null;
      _playbackError = false;
      _phase = _AuditoryPhase.idle;
    });
    _scheduleRound();
  }

  void _reset() {
    _token += 1;
    _signalTimer?.cancel();
    _transitionTimer?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    setState(() {
      _records.clear();
      _roundIndex = 0;
      _correct = 0;
      _wrong = 0;
      _falseStarts = 0;
      _streak = 0;
      _bestStreak = 0;
      _lastCorrect = null;
      _playbackError = false;
      _phase = _AuditoryPhase.idle;
    });
  }

  void _setMode(_AuditoryMode mode) {
    if (_mode == mode) {
      return;
    }
    setState(() {
      _mode = mode;
      _currentStimulus = _stimuliForMode(mode).first;
    });
    _reset();
  }

  void _scheduleRound() {
    if (!mounted) {
      return;
    }
    if (_roundIndex >= _roundCount) {
      _finish();
      return;
    }
    final token = ++_token;
    _signalTimer?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    setState(() {
      _phase = _AuditoryPhase.waiting;
      _lastCorrect = null;
      _currentStimulus = _sample(_random, _stimuliForMode(_mode));
    });
    final delayMs = 900 + _random.nextInt(1700);
    _signalTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted || token != _token || _phase != _AuditoryPhase.waiting) {
        return;
      }
      _emitCue();
    });
  }

  void _emitCue() {
    _stopwatch
      ..reset()
      ..start();
    setState(() => _phase = _AuditoryPhase.cue);
    unawaited(_playStimulus(_currentStimulus));
  }

  Future<void> _ensureAudioConfigured() async {
    if (_audioConfigured) {
      return;
    }
    await _player.setReleaseMode(ReleaseMode.stop);
    _audioConfigured = true;
  }

  Future<void> _playStimulus(_AuditoryStimulus stimulus) async {
    final spec = _stimulusSpecs[stimulus]!;
    final bytes = _toneCache[stimulus] ?? _buildToneBytes(spec);
    _toneCache[stimulus] = bytes;
    try {
      await _ensureAudioConfigured();
      await _player.stop();
      await AudioPlayerSourceHelper.play(
        _player,
        BytesSource(bytes, mimeType: 'audio/wav'),
        volume: spec.outputVolume,
        tag: 'human_tests_auditory',
        ctx: _audioContext,
        mode: PlayerMode.lowLatency,
        data: <String, Object?>{
          'mode': spec.mode.name,
          'stimulus': stimulus.name,
          'frequencyHz': spec.frequencyHz,
          'leftGain': spec.leftGain,
          'rightGain': spec.rightGain,
        },
      );
      if (mounted && _playbackError) {
        setState(() => _playbackError = false);
      }
    } catch (_) {
      try {
        await SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
      if (mounted) {
        setState(() => _playbackError = true);
      }
    }
  }

  void _tapReaction() {
    if (_phase == _AuditoryPhase.waiting) {
      _recordAnswer(correct: false, falseStart: true, milliseconds: 0);
      return;
    }
    if (_phase != _AuditoryPhase.cue) {
      return;
    }
    final elapsed = math.max(1, _stopwatch.elapsedMilliseconds);
    _recordAnswer(correct: true, milliseconds: elapsed);
  }

  void _chooseStimulus(_AuditoryStimulus stimulus) {
    if (_phase != _AuditoryPhase.cue) {
      return;
    }
    final elapsed = math.max(1, _stopwatch.elapsedMilliseconds);
    _recordAnswer(correct: stimulus == _currentStimulus, milliseconds: elapsed);
  }

  void _recordAnswer({
    required bool correct,
    required int milliseconds,
    bool falseStart = false,
  }) {
    _signalTimer?.cancel();
    _stopwatch.stop();
    setState(() {
      _records.add(
        _AuditoryRecord(
          mode: _mode,
          stimulus: _currentStimulus,
          correct: correct,
          milliseconds: milliseconds,
          falseStart: falseStart,
        ),
      );
      _roundIndex += 1;
      _lastCorrect = correct;
      if (correct) {
        _correct += 1;
        _streak += 1;
        _bestStreak = math.max(_bestStreak, _streak);
      } else {
        _wrong += 1;
        _streak = 0;
      }
      if (falseStart) {
        _falseStarts += 1;
      }
      _phase = _roundIndex >= _roundCount
          ? _AuditoryPhase.done
          : _AuditoryPhase.idle;
    });
    _transitionTimer?.cancel();
    _transitionTimer = Timer(const Duration(milliseconds: 620), () {
      if (!mounted) {
        return;
      }
      if (_roundIndex >= _roundCount) {
        _finish();
      } else {
        _scheduleRound();
      }
    });
  }

  void _finish() {
    _signalTimer?.cancel();
    _transitionTimer?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    setState(() => _phase = _AuditoryPhase.done);
    unawaited(_showReport());
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (
              pickUiText(i18n, zh: '进度', en: 'Progress'),
              '$_roundIndex/$_roundCount',
            ),
            (
              pickUiText(i18n, zh: '模式', en: 'Mode'),
              _modeCopies[_mode]!.label(i18n),
            ),
            (
              pickUiText(i18n, zh: '准确率', en: 'Accuracy'),
              '${(_accuracy * 100).round()}%',
            ),
            (
              pickUiText(i18n, zh: '平均反应', en: 'Avg response'),
              _averageMs == 0 ? '-' : _formatMilliseconds(_averageMs),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _HumanPanel(child: _buildStage(context, i18n)),
        const SizedBox(height: 12),
        _HumanSettingsSection(
          title: pickUiText(i18n, zh: '听觉设置', en: 'Auditory settings'),
          subtitle: pickUiText(
            i18n,
            zh: '选择反应、频率、音量或声道模拟。结果仅用于本地自测，不代表医学诊断。',
            en: 'Choose reaction, frequency, volume, or channel simulation. Results are local self-check feedback, not a medical diagnosis.',
          ),
          child: _buildSettings(context, i18n),
        ),
      ],
    );
  }

  Widget _buildStage(BuildContext context, AppI18n i18n) {
    final theme = Theme.of(context);
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
                onSelected:
                    _phase == _AuditoryPhase.waiting ||
                        _phase == _AuditoryPhase.cue
                    ? null
                    : (_) => _setMode(mode),
              );
            }),
            _HumanActionButton(
              label: pickUiText(i18n, zh: '开始', en: 'Start'),
              icon: Icons.play_arrow_rounded,
              onPressed: _start,
            ),
            OutlinedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(pickUiText(i18n, zh: '重置', en: 'Reset')),
            ),
          ],
        ),
        const SizedBox(height: 14),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: _phase == _AuditoryPhase.cue
                ? _accent.withValues(alpha: 0.12)
                : Theme.of(context).colorScheme.surface,
            border: Border.all(
              color: _phase == _AuditoryPhase.cue
                  ? _accent.withValues(alpha: 0.45)
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            children: <Widget>[
              Icon(_stageIcon(), color: _accent, size: 48),
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
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (_playbackError) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  pickUiText(
                    i18n,
                    zh: '合成音播放失败，已尝试系统提示音。',
                    en: 'Synthetic tone playback failed; system alert fallback was attempted.',
                  ),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              if (_mode == _AuditoryMode.reaction)
                FilledButton.icon(
                  onPressed:
                      _phase == _AuditoryPhase.waiting ||
                          _phase == _AuditoryPhase.cue
                      ? _tapReaction
                      : null,
                  icon: const Icon(Icons.touch_app_rounded),
                  label: Text(
                    pickUiText(i18n, zh: '听到后点击', en: 'Tap when heard'),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(180, 58),
                  ),
                )
              else
                _buildStimulusChoices(i18n),
            ],
          ),
        ),
        if (_lastCorrect != null) ...<Widget>[
          const SizedBox(height: 10),
          _HumanPill(
            text: _lastCorrect!
                ? pickUiText(i18n, zh: '上一轮正确', en: 'Last round correct')
                : pickUiText(i18n, zh: '上一轮失误', en: 'Last round missed'),
            accent: _lastCorrect! ? const Color(0xFF4E8B6B) : Colors.redAccent,
          ),
        ],
      ],
    );
  }

  IconData _stageIcon() {
    if (_phase == _AuditoryPhase.cue && _mode == _AuditoryMode.reaction) {
      return _stimulusSpecs[_currentStimulus]!.icon;
    }
    return _modeCopies[_mode]!.icon;
  }

  String _phaseText(AppI18n i18n) {
    return switch (_phase) {
      _AuditoryPhase.idle => pickUiText(
        i18n,
        zh: '点击开始后等待随机提示音。',
        en: 'Press start and wait for a random cue tone.',
      ),
      _AuditoryPhase.waiting => pickUiText(
        i18n,
        zh: '保持安静，提示音会随机出现。',
        en: 'Hold steady. The cue tone will appear at a random time.',
      ),
      _AuditoryPhase.cue =>
        _mode == _AuditoryMode.reaction
            ? pickUiText(i18n, zh: '现在响应。', en: 'Respond now.')
            : pickUiText(
                i18n,
                zh: '选择刚才听到的选项。',
                en: 'Choose the option you just heard.',
              ),
      _AuditoryPhase.done => pickUiText(
        i18n,
        zh: '本组完成，可重新开始。',
        en: 'Session complete. Restart when ready.',
      ),
    };
  }

  Widget _buildStimulusChoices(AppI18n i18n) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: _stimuliForMode(_mode)
          .map((stimulus) {
            final spec = _stimulusSpecs[stimulus]!;
            return OutlinedButton.icon(
              onPressed: _phase == _AuditoryPhase.cue
                  ? () => _chooseStimulus(stimulus)
                  : null,
              icon: Icon(spec.icon),
              label: Text(spec.label(i18n)),
            );
          })
          .toList(growable: false),
    );
  }

  Widget _buildSettings(BuildContext context, AppI18n i18n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(pickUiText(i18n, zh: '轮数', en: 'Rounds')),
        Wrap(
          spacing: 8,
          children: <int>[6, 8, 10, 12]
              .map(
                (value) => ChoiceChip(
                  label: Text('$value'),
                  selected: _roundCount == value,
                  onSelected:
                      _phase == _AuditoryPhase.waiting ||
                          _phase == _AuditoryPhase.cue
                      ? null
                      : (_) => setState(() => _roundCount = value),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 12),
        Text(pickUiText(i18n, zh: '试听当前测试音', en: 'Preview test tones')),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _stimuliForMode(_mode)
              .map((stimulus) {
                final spec = _stimulusSpecs[stimulus]!;
                return IconButton.filledTonal(
                  tooltip: spec.label(i18n),
                  onPressed: () => unawaited(_playStimulus(stimulus)),
                  icon: Icon(spec.icon),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }

  Future<void> _showReport() async {
    if (!mounted || _records.isEmpty) {
      return;
    }
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(pickUiText(i18n, zh: '听觉反应报告', en: 'Auditory report')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _HumanMetricWrap(
                  metrics: <(String, String)>[
                    (
                      pickUiText(i18n, zh: '准确率', en: 'Accuracy'),
                      '${(_accuracy * 100).round()}%',
                    ),
                    (
                      pickUiText(i18n, zh: '平均反应', en: 'Avg response'),
                      _averageMs == 0 ? '-' : _formatMilliseconds(_averageMs),
                    ),
                    (
                      pickUiText(i18n, zh: '最佳连击', en: 'Best streak'),
                      '$_bestStreak',
                    ),
                    (
                      pickUiText(i18n, zh: '抢答', en: 'False starts'),
                      '$_falseStarts',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _HumanPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _modeOrder
                        .map((mode) {
                          final modeRecords = _records
                              .where((record) => record.mode == mode)
                              .toList(growable: false);
                          if (modeRecords.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          final correct = modeRecords
                              .where((record) => record.correct)
                              .length;
                          final ratio = (correct / modeRecords.length * 100)
                              .round();
                          final label = _modeCopies[mode]!.label(i18n);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              '$label: $correct/${modeRecords.length} ($ratio%)',
                            ),
                          );
                        })
                        .toList(growable: false),
                  ),
                ),
                const SizedBox(height: 10),
                _HumanPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _stimuliForMode(_mode)
                        .map((stimulus) {
                          final total = _records
                              .where((record) => record.stimulus == stimulus)
                              .length;
                          final correct = _records
                              .where(
                                (record) =>
                                    record.stimulus == stimulus &&
                                    record.correct,
                              )
                              .length;
                          final label = _stimulusSpecs[stimulus]!.label(i18n);
                          final ratio = total == 0
                              ? 0
                              : (correct / total * 100).round();
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text('$label: $correct/$total ($ratio%)'),
                          );
                        })
                        .toList(growable: false),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  pickUiText(
                    i18n,
                    zh: '提示：这是模拟听觉训练，不替代标准听力检查。',
                    en: 'Note: this is simulated auditory training, not a substitute for a clinical hearing exam.',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(pickUiText(i18n, zh: '关闭', en: 'Close')),
            ),
          ],
        );
      },
    );
  }

  static List<_AuditoryStimulus> _stimuliForMode(_AuditoryMode mode) {
    return switch (mode) {
      _AuditoryMode.reaction => _reactionStimuli,
      _AuditoryMode.frequency => _frequencyStimuli,
      _AuditoryMode.volume => _volumeStimuli,
      _AuditoryMode.channel => _channelStimuli,
    };
  }

  static Uint8List _buildToneBytes(_AuditoryStimulusSpec spec) {
    const sampleRate = 44100;
    const durationMs = 300;
    const attackMs = 12;
    const releaseMs = 48;
    const channelCount = 2;
    const bytesPerSample = 2;
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
    final twoPi = math.pi * 2;

    for (var index = 0; index < sampleCount; index++) {
      final attackEnvelope = attackSamples <= 0
          ? 1.0
          : (index / attackSamples).clamp(0.0, 1.0);
      final releaseEnvelope = releaseSamples <= 0
          ? 1.0
          : ((sampleCount - index) / releaseSamples).clamp(0.0, 1.0);
      final envelope = math.min(attackEnvelope, releaseEnvelope);
      final sample =
          math.sin(twoPi * spec.frequencyHz * index / sampleRate) *
          envelope *
          0.82;
      final left = _toPcm16(sample * spec.leftGain);
      final right = _toPcm16(sample * spec.rightGain);
      final offset = 44 + index * channelCount * bytesPerSample;
      buffer.setInt16(offset, left, Endian.little);
      buffer.setInt16(offset + bytesPerSample, right, Endian.little);
    }

    return buffer.buffer.asUint8List();
  }

  static int _toPcm16(double value) {
    final normalized = value.clamp(-1.0, 1.0);
    return (normalized * 32767).round().clamp(-32768, 32767).toInt();
  }
}
