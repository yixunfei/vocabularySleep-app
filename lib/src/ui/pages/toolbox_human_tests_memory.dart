part of 'toolbox_human_tests.dart';

class ChimpTestPage extends StatelessWidget {
  const ChimpTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_memory.chimp_test_705527',
      ),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests_memory.includes_classic_sequential_number_and_color_sequence_mo_7ea5da',
      ),
      accent: const Color(0xFF6C8D42),
      icon: Icons.grid_view_rounded,
      status: i18n.t(
        'inline.ui.pages.toolbox_human_tests_memory.next_replay_the_shown_order_by_tapping_targets_7f9ce6',
      ),
      child: const _ChimpTestCard(),
    );
  }
}

class _ChimpTestCard extends StatefulWidget {
  const _ChimpTestCard();

  @override
  State<_ChimpTestCard> createState() => _ChimpTestCardState();
}

enum _ChimpMode { classic, sequential, colorSequence }

class _ChimpColorToken {
  const _ChimpColorToken({required this.color, required this.labelKey});

  final Color color;
  final String labelKey;

  String label(AppI18n i18n) => i18n.t(labelKey);
}

class _ChimpTestCardState extends State<_ChimpTestCard> {
  static const int _initialLevel = 4;
  static const int _minGridSize = 4;
  static const int _maxGridSize = 6;
  static const Color _accent = Color(0xFF6C8D42);
  static const List<_ChimpColorToken> _colorPalette = <_ChimpColorToken>[
    _ChimpColorToken(
      color: Color(0xFFE86D6D),
      labelKey: 'inline.plan297.human_tests.memory.color.red.7414460a9e',
    ),
    _ChimpColorToken(
      color: Color(0xFF5AA7E8),
      labelKey: 'inline.plan297.human_tests.memory.color.blue.709aec8dac',
    ),
    _ChimpColorToken(
      color: Color(0xFF69B97E),
      labelKey: 'inline.plan297.human_tests.memory.color.green.73f310e247',
    ),
    _ChimpColorToken(
      color: Color(0xFFE8B45A),
      labelKey: 'inline.plan297.human_tests.memory.color.yellow.c52f6d87d0',
    ),
    _ChimpColorToken(
      color: Color(0xFFC283E6),
      labelKey: 'inline.plan297.human_tests.memory.color.purple.d8c97fdf64',
    ),
    _ChimpColorToken(
      color: Color(0xFF58B5A8),
      labelKey: 'inline.plan297.human_tests.memory.color.cyan.c2ceed9654',
    ),
    _ChimpColorToken(
      color: Color(0xFFE69252),
      labelKey: 'inline.plan297.human_tests.memory.color.orange.a7b0feedb2',
    ),
    _ChimpColorToken(
      color: Color(0xFF8AA0E8),
      labelKey: 'inline.plan297.human_tests.memory.color.indigo.32b3e46bfd',
    ),
  ];

  final math.Random _random = math.Random();
  int _level = _initialLevel;
  _ChimpMode _mode = _ChimpMode.classic;
  int _gridSize = 5;
  int _maxTargetCount = 12;
  int _sequenceSpeedMs = 520;
  int _colorCount = 4;
  bool _showAnswer = false;
  bool _showNextHint = false;
  bool _oneMistakeRescue = false;
  bool _autoReport = true;
  List<int> _positions = const <int>[];
  List<Color> _sequenceColors = const <Color>[];
  Map<int, Color> _colorByCell = <int, Color>{};
  List<int> _targetCells = const <int>[];
  List<int> _targetStepIndexes = const <int>[];
  Color? _targetColor;
  int _next = 1;
  bool _hidden = false;
  bool _failed = false;
  bool _complete = false;
  bool _showingSequence = false;
  bool _input = false;
  int? _highlightedCell;
  String? _highlightedLabel;
  int? _warningCell;
  bool _rescueUsedThisRound = false;
  bool _sessionEnded = false;
  bool _reportDialogOpen = false;
  DateTime? _roundStartedAt;
  int _attemptedRounds = 0;
  int _completedRounds = 0;
  int _failedRounds = 0;
  int _totalTaps = 0;
  int _mistakes = 0;
  int _bestCompletedTargets = 0;
  List<Duration> _roundDurations = const <Duration>[];
  int _playbackToken = 0;

  @override
  void dispose() {
    _playbackToken += 1;
    super.dispose();
  }

  String _modeLabel(AppI18n i18n, _ChimpMode mode) {
    return switch (mode) {
      _ChimpMode.classic => i18n.t(
        'inline.ui.pages.toolbox_human_tests_memory.classic_mode_a03b8d',
      ),
      _ChimpMode.sequential => i18n.t(
        'inline.ui.pages.toolbox_human_tests_memory.sequential_number_mode_bebc5b',
      ),
      _ChimpMode.colorSequence => i18n.t(
        'inline.ui.pages.toolbox_human_tests_memory.color_sequence_mode_b66f18',
      ),
    };
  }

  List<_ChimpColorToken> get _activeColorPalette =>
      _colorPalette.take(_colorCount).toList(growable: false);

  List<int> get _expectedCells =>
      _mode == _ChimpMode.colorSequence ? _targetCells : _positions;

  int get _gridCount => _gridSize * _gridSize;

  int get _targetCount => _expectedCells.length;

  int? get _nextExpectedCell {
    final expected = _expectedCells;
    if (!_input || _positions.isEmpty || _next < 1 || _next > expected.length) {
      return null;
    }
    return expected[_next - 1];
  }

  String _colorName(AppI18n i18n, Color color) {
    final token = _colorPalette.firstWhere(
      (item) => item.color == color,
      orElse: () => _colorPalette.first,
    );
    return token.label(i18n);
  }

  String _colorSequenceSummary(AppI18n i18n) {
    if (_positions.isEmpty || _sequenceColors.isEmpty) {
      return '-';
    }
    final labels = List<String>.generate(_positions.length, (index) {
      final colorName = _colorName(i18n, _sequenceColors[index]);
      return '$colorName x${index + 1}';
    });
    return labels.join(', ');
  }

  String _targetHint(AppI18n i18n) {
    if (_targetColor == null || _targetStepIndexes.isEmpty) {
      return '';
    }
    final colorName = _colorName(i18n, _targetColor!);
    final sequenceLabel = _targetStepIndexes.map((step) => 'x$step').join(', ');
    return i18n.t(
      'inline.ui.pages.toolbox_human_tests_memory.target_color_colorname_tap_sequencelabel_in_order_624267',
      params: <String, Object?>{
        'colorName': colorName,
        'sequenceLabel': sequenceLabel,
      },
    );
  }

  String _statusText(AppI18n i18n) {
    if (_showingSequence) {
      return _mode == _ChimpMode.colorSequence
          ? i18n.t(
              'inline.ui.pages.toolbox_human_tests_memory.showing_sequence_colorsequencesummary_i18n_ce5324',
              params: <String, Object?>{
                'colorSequenceSummary': _colorSequenceSummary(i18n),
              },
            )
          : i18n.t(
              'inline.ui.pages.toolbox_human_tests_memory.playing_in_order_memorize_positions_1aa220',
            );
    }
    if (_failed) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_memory.wrong_order_this_set_has_ended_02f491',
      );
    }
    if (_complete) {
      return _sessionEnded
          ? i18n.t(
              'inline.ui.pages.toolbox_human_tests_memory.target_cap_cleared_this_set_is_complete_37399f',
            )
          : i18n.t(
              'inline.ui.pages.toolbox_human_tests_memory.complete_target_count_increased_ec0339',
            );
    }
    if (_showNextHint && _nextExpectedCell != null) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_memory.hint_the_next_cell_is_outlined_06a8ac',
      );
    }
    if (_mode == _ChimpMode.colorSequence && _positions.isNotEmpty) {
      return _targetHint(i18n);
    }
    return i18n.t(
      'inline.ui.pages.toolbox_human_tests_memory.press_start_then_finish_targets_in_order_74523f',
    );
  }

  void _resetRoundState() {
    _playbackToken += 1;
    _positions = const <int>[];
    _sequenceColors = const <Color>[];
    _colorByCell = <int, Color>{};
    _targetCells = const <int>[];
    _targetStepIndexes = const <int>[];
    _targetColor = null;
    _next = 1;
    _hidden = false;
    _failed = false;
    _complete = false;
    _showingSequence = false;
    _input = false;
    _highlightedCell = null;
    _highlightedLabel = null;
    _warningCell = null;
    _rescueUsedThisRound = false;
    _sessionEnded = false;
    _roundStartedAt = null;
  }

  void _clearSessionStats() {
    _attemptedRounds = 0;
    _completedRounds = 0;
    _failedRounds = 0;
    _totalTaps = 0;
    _mistakes = 0;
    _bestCompletedTargets = 0;
    _roundDurations = const <Duration>[];
  }

  void _applySetting(VoidCallback updater, {bool resetStats = true}) {
    if (_showingSequence) {
      return;
    }
    setState(() {
      updater();
      _maxTargetCount = _maxTargetCount.clamp(2, _gridCount).toInt();
      if (resetStats) {
        _clearSessionStats();
      }
      _resetRoundState();
      _level = math.min(_initialLevel, _maxTargetCount);
    });
  }

  void _resetSession() {
    setState(() {
      _level = math.min(_initialLevel, _maxTargetCount);
      _clearSessionStats();
      _resetRoundState();
    });
  }

  void _markRoundStarted() {
    _roundStartedAt = DateTime.now();
    _warningCell = null;
    _rescueUsedThisRound = false;
    _sessionEnded = false;
  }

  void _recordTap({required bool mistake}) {
    _totalTaps += 1;
    if (mistake) {
      _mistakes += 1;
    }
  }

  void _finishRound({required bool success}) {
    final startedAt = _roundStartedAt;
    final duration = startedAt == null
        ? null
        : DateTime.now().difference(startedAt);
    _attemptedRounds += 1;
    if (success) {
      _completedRounds += 1;
      _bestCompletedTargets = math.max(_bestCompletedTargets, _targetCount);
      if (duration != null) {
        _roundDurations = <Duration>[..._roundDurations, duration];
      }
    } else {
      _failedRounds += 1;
    }
    _roundStartedAt = null;
  }

  void _handleWrongCell(int cell) {
    _recordTap(mistake: true);
    if (_oneMistakeRescue && !_rescueUsedThisRound) {
      setState(() {
        _hidden = true;
        _warningCell = cell;
        _rescueUsedThisRound = true;
      });
      return;
    }
    _finishRound(success: false);
    setState(() {
      _hidden = true;
      _failed = true;
      _input = false;
      _warningCell = cell;
      _sessionEnded = true;
    });
    if (_autoReport) {
      _showCompletionReport(success: false);
    }
  }

  void _handleRoundSuccess() {
    final reachedCap = _targetCount >= _maxTargetCount;
    _finishRound(success: true);
    setState(() {
      _complete = true;
      _input = false;
      _warningCell = null;
      if (reachedCap) {
        _sessionEnded = true;
      } else {
        _level = math.min(_maxTargetCount, _level + 1);
      }
    });
    if (reachedCap && _autoReport) {
      _showCompletionReport(success: true);
    }
  }

  void _showCompletionReport({required bool success}) {
    if (!mounted || _reportDialogOpen) {
      return;
    }
    _reportDialogOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _reportDialogOpen = false;
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (_) => _ChimpCompletionReportDialog(
          modeLabel: _modeLabel(
            AppI18n(Localizations.localeOf(context).languageCode),
            _mode,
          ),
          success: success,
          gridSize: _gridSize,
          maxTargetCount: _maxTargetCount,
          attemptedRounds: _attemptedRounds,
          completedRounds: _completedRounds,
          failedRounds: _failedRounds,
          totalTaps: _totalTaps,
          mistakes: _mistakes,
          bestCompletedTargets: _bestCompletedTargets,
          durations: List<Duration>.unmodifiable(_roundDurations),
          showAnswer: _showAnswer,
          showNextHint: _showNextHint,
          oneMistakeRescue: _oneMistakeRescue,
          accent: _accent,
        ),
      );
      _reportDialogOpen = false;
    });
  }

  Future<void> _startRound() async {
    if (_sessionEnded || _failed) {
      setState(() {
        _level = math.min(_initialLevel, _maxTargetCount);
        _resetRoundState();
      });
    }
    if (_mode == _ChimpMode.classic) {
      _startClassicRound();
      return;
    }
    if (_mode == _ChimpMode.sequential) {
      await _startSequentialRound();
      return;
    }
    await _startColorRound();
  }

  void _startClassicRound() {
    final cells = List<int>.generate(_gridCount, (index) => index)
      ..shuffle(_random);
    setState(() {
      _markRoundStarted();
      _positions = cells.take(_level).toList(growable: false);
      _sequenceColors = const <Color>[];
      _colorByCell = <int, Color>{};
      _targetCells = const <int>[];
      _targetStepIndexes = const <int>[];
      _targetColor = null;
      _next = 1;
      _hidden = false;
      _failed = false;
      _complete = false;
      _showingSequence = false;
      _input = true;
      _highlightedCell = null;
      _highlightedLabel = null;
    });
  }

  Future<void> _startSequentialRound() async {
    final cells = List<int>.generate(_gridCount, (index) => index)
      ..shuffle(_random);
    setState(() {
      _positions = cells.take(_level).toList(growable: false);
      _sequenceColors = const <Color>[];
      _colorByCell = <int, Color>{};
      _targetCells = const <int>[];
      _targetStepIndexes = const <int>[];
      _targetColor = null;
      _next = 1;
      _hidden = true;
      _failed = false;
      _complete = false;
      _showingSequence = true;
      _input = false;
      _highlightedCell = null;
      _highlightedLabel = null;
    });
    await _playSequence(useXLabel: false);
  }

  Future<void> _startColorRound() async {
    final sequenceLength = math.max(4, math.min(_level, _gridCount));
    final cells = List<int>.generate(_gridCount, (index) => index)
      ..shuffle(_random);
    final sequenceCells = cells.take(sequenceLength).toList(growable: false);
    final sequenceColors = List<Color>.generate(
      sequenceCells.length,
      (_) => _sample(_random, _activeColorPalette).color,
    );
    if (sequenceColors.length >= 2) {
      final forcedColor = _sample(_random, _activeColorPalette).color;
      final firstIndex = _random.nextInt(sequenceColors.length);
      var secondIndex = _random.nextInt(sequenceColors.length - 1);
      if (secondIndex >= firstIndex) {
        secondIndex += 1;
      }
      sequenceColors[firstIndex] = forcedColor;
      sequenceColors[secondIndex] = forcedColor;
    }
    final counts = <Color, int>{};
    for (final color in sequenceColors) {
      counts[color] = (counts[color] ?? 0) + 1;
    }
    final repeatedColors = counts.entries
        .where((entry) => entry.value > 1)
        .map((entry) => entry.key)
        .toList(growable: false);
    final targetColor = _sample(
      _random,
      repeatedColors.isNotEmpty
          ? repeatedColors
          : _activeColorPalette
                .map((token) => token.color)
                .toList(growable: false),
    );
    final targetCells = <int>[];
    final targetStepIndexes = <int>[];
    final colorByCell = <int, Color>{};
    for (var i = 0; i < sequenceCells.length; i += 1) {
      final cell = sequenceCells[i];
      final color = sequenceColors[i];
      colorByCell[cell] = color;
      if (color == targetColor) {
        targetCells.add(cell);
        targetStepIndexes.add(i + 1);
      }
    }
    setState(() {
      _positions = sequenceCells;
      _sequenceColors = sequenceColors;
      _colorByCell = colorByCell;
      _targetCells = targetCells;
      _targetStepIndexes = targetStepIndexes;
      _targetColor = targetColor;
      _next = 1;
      _hidden = true;
      _failed = false;
      _complete = false;
      _showingSequence = true;
      _input = false;
      _highlightedCell = null;
      _highlightedLabel = null;
    });
    await _playSequence(useXLabel: true);
  }

  Future<void> _playSequence({required bool useXLabel}) async {
    final token = ++_playbackToken;
    await Future<void>.delayed(const Duration(milliseconds: 260));
    for (var i = 0; i < _positions.length; i += 1) {
      if (!mounted || token != _playbackToken) {
        return;
      }
      setState(() {
        _highlightedCell = _positions[i];
        _highlightedLabel = useXLabel ? 'x${i + 1}' : '${i + 1}';
      });
      await Future<void>.delayed(Duration(milliseconds: _sequenceSpeedMs));
      if (!mounted || token != _playbackToken) {
        return;
      }
      setState(() {
        _highlightedCell = null;
        _highlightedLabel = null;
      });
      await Future<void>.delayed(
        Duration(milliseconds: math.max(120, _sequenceSpeedMs ~/ 4)),
      );
    }
    if (!mounted || token != _playbackToken) {
      return;
    }
    setState(() {
      _markRoundStarted();
      _showingSequence = false;
      _input = true;
    });
  }

  void _tapCell(int cell) {
    if (_failed || _complete || _positions.isEmpty || _showingSequence) {
      return;
    }
    if (_mode == _ChimpMode.classic) {
      _tapClassic(cell);
      return;
    }
    _tapOrdered(cell);
  }

  void _tapClassic(int cell) {
    final number = _positions.indexOf(cell) + 1;
    if (number <= 0) {
      _handleWrongCell(cell);
      return;
    }
    if (number == _next) {
      _recordTap(mistake: false);
      final finished = _next >= _targetCount;
      setState(() {
        _hidden = true;
        _next += 1;
        _warningCell = null;
      });
      if (finished) {
        _handleRoundSuccess();
      }
    } else {
      _handleWrongCell(cell);
    }
  }

  void _tapOrdered(int cell) {
    if (!_input) {
      return;
    }
    final expected = _expectedCells;
    final expectedCell = expected[_next - 1];
    if (cell != expectedCell) {
      _handleWrongCell(cell);
      return;
    }
    _recordTap(mistake: false);
    final finished = _next >= expected.length;
    setState(() {
      _next += 1;
      _warningCell = null;
    });
    if (finished) {
      _handleRoundSuccess();
    }
  }

  Color _cellColor(BuildContext context, int index, bool solved) {
    final colorScheme = Theme.of(context).colorScheme;
    if (_warningCell == index) {
      return colorScheme.errorContainer;
    }
    if (_showNextHint && _nextExpectedCell == index && _input) {
      return _accent.withValues(alpha: 0.16);
    }
    if (_mode == _ChimpMode.colorSequence) {
      if (_highlightedCell == index) {
        return (_colorByCell[index] ?? colorScheme.primaryContainer).withValues(
          alpha: 0.92,
        );
      }
      if (_showAnswer && _colorByCell.containsKey(index)) {
        return (_colorByCell[index] ?? colorScheme.primaryContainer).withValues(
          alpha: 0.52,
        );
      }
      if (solved) {
        return (_targetColor ?? colorScheme.primary).withValues(alpha: 0.30);
      }
      return colorScheme.surface;
    }
    if (_highlightedCell == index) {
      return colorScheme.primaryContainer;
    }
    if (_showAnswer && _positions.contains(index)) {
      return colorScheme.primaryContainer.withValues(alpha: 0.56);
    }
    return colorScheme.surface;
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final canEditSettings = !_showingSequence;
    final gridGap = _gridSize >= 6 ? 6.0 : 8.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (i18n.t('toolbox.sound.piano.mode'), _modeLabel(i18n, _mode)),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_aim_widgets.targets_d13c96',
              ),
              '$_targetCount',
            ),
            (
              i18n.t('inline.ui.pages.toolbox_human_tests_memory.board_113334'),
              '$_gridSize x $_gridSize',
            ),
            (
              i18n.t('next'),
              _positions.isEmpty || _complete
                  ? '-'
                  : '$_next/${math.max(1, _targetCount)}',
            ),
            (i18n.t('toolbox.breathing.best'), '$_bestCompletedTargets'),
          ],
        ),
        const SizedBox(height: 12),
        _HumanPanel(
          child: Column(
            children: <Widget>[
              _HumanSettingsSection(
                title: i18n.t('settings'),
                subtitle: i18n.t(
                  'inline.ui.pages.toolbox_human_tests_memory.mode_board_size_difficulty_cap_and_assists_09be90',
                ),
                initiallyExpanded: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _ChimpMode.values
                          .map(
                            (mode) => ChoiceChip(
                              label: Text(_modeLabel(i18n, mode)),
                              selected: _mode == mode,
                              onSelected: !canEditSettings
                                  ? null
                                  : (_) {
                                      _applySetting(() {
                                        _mode = mode;
                                      });
                                    },
                            ),
                          )
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      i18n.t(
                        'inline.ui.pages.toolbox_human_tests_memory.max_board_size_fc548b',
                      ),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    Slider(
                      value: _gridSize.toDouble(),
                      min: _minGridSize.toDouble(),
                      max: _maxGridSize.toDouble(),
                      divisions: _maxGridSize - _minGridSize,
                      label: '$_gridSize x $_gridSize',
                      onChanged: !canEditSettings
                          ? null
                          : (value) {
                              _applySetting(() {
                                _gridSize = value.round();
                                _maxTargetCount = math.min(
                                  _maxTargetCount,
                                  _gridCount,
                                );
                              });
                            },
                    ),
                    Text(
                      i18n.t(
                        'inline.ui.pages.toolbox_human_tests_memory.set_target_cap_cf9ed0',
                      ),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    Slider(
                      value: _maxTargetCount.toDouble(),
                      min: 4,
                      max: _gridCount.toDouble(),
                      divisions: math.max(1, _gridCount - 4),
                      label: '$_maxTargetCount',
                      onChanged: !canEditSettings
                          ? null
                          : (value) {
                              _applySetting(() {
                                _maxTargetCount = value.round();
                                _level = math.min(_level, _maxTargetCount);
                              });
                            },
                    ),
                    if (_mode != _ChimpMode.classic) ...<Widget>[
                      const SizedBox(height: 10),
                      Text(
                        i18n.t(
                          'inline.ui.pages.toolbox_human_tests_memory.number_color_switch_speed_25b9c8',
                        ),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Slider(
                        value: _sequenceSpeedMs.toDouble(),
                        min: 260,
                        max: 900,
                        divisions: 16,
                        label: '$_sequenceSpeedMs ms',
                        onChanged: !canEditSettings
                            ? null
                            : (value) {
                                _applySetting(
                                  () => _sequenceSpeedMs = value.round(),
                                );
                              },
                      ),
                    ],
                    if (_mode == _ChimpMode.colorSequence) ...<Widget>[
                      Text(
                        i18n.t(
                          'inline.ui.pages.toolbox_human_tests_memory.color_count_47de48',
                        ),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      Slider(
                        value: _colorCount.toDouble(),
                        min: 3,
                        max: 8,
                        divisions: 5,
                        label: '$_colorCount',
                        onChanged: !canEditSettings
                            ? null
                            : (value) {
                                _applySetting(
                                  () => _colorCount = value.round(),
                                );
                              },
                      ),
                    ],
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        i18n.t(
                          'inline.ui.pages.toolbox_human_tests_memory.show_answer_611b2f',
                        ),
                      ),
                      subtitle: Text(
                        i18n.t(
                          'inline.ui.pages.toolbox_human_tests_memory.keep_numbers_colors_or_target_positions_visible_during_i_0b001d',
                        ),
                      ),
                      value: _showAnswer,
                      onChanged: !canEditSettings
                          ? null
                          : (value) {
                              _applySetting(() => _showAnswer = value);
                            },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        i18n.t(
                          'inline.ui.pages.toolbox_human_tests_memory.next_step_hint_9df1c2',
                        ),
                      ),
                      subtitle: Text(
                        i18n.t(
                          'inline.ui.pages.toolbox_human_tests_memory.off_by_default_outline_the_next_expected_cell_7bd6ba',
                        ),
                      ),
                      value: _showNextHint,
                      onChanged: !canEditSettings
                          ? null
                          : (value) {
                              _applySetting(() => _showNextHint = value);
                            },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        i18n.t(
                          'inline.ui.pages.toolbox_human_tests_memory.one_mistake_rescue_2bdd0b',
                        ),
                      ),
                      subtitle: Text(
                        i18n.t(
                          'inline.ui.pages.toolbox_human_tests_memory.off_by_default_the_first_wrong_tap_warns_instead_of_endi_62df64',
                        ),
                      ),
                      value: _oneMistakeRescue,
                      onChanged: !canEditSettings
                          ? null
                          : (value) {
                              _applySetting(() => _oneMistakeRescue = value);
                            },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        i18n.t(
                          'inline.ui.pages.toolbox_human_tests_auditory.auto_report_4b91e0',
                        ),
                      ),
                      subtitle: Text(
                        i18n.t(
                          'inline.ui.pages.toolbox_human_tests_memory.show_the_statistical_report_when_the_test_ends_9cbaf9',
                        ),
                      ),
                      value: _autoReport,
                      onChanged: !canEditSettings
                          ? null
                          : (value) {
                              _applySetting(
                                () => _autoReport = value,
                                resetStats: false,
                              );
                            },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              AspectRatio(
                aspectRatio: 1,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _gridCount,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _gridSize,
                    crossAxisSpacing: gridGap,
                    mainAxisSpacing: gridGap,
                  ),
                  itemBuilder: (context, index) {
                    final number = _positions.indexOf(index) + 1;
                    final solved = _expectedCells
                        .take(_next - 1)
                        .contains(index);
                    final showClassicNumber =
                        _mode == _ChimpMode.classic &&
                        number > 0 &&
                        (!_hidden || _showAnswer) &&
                        !solved;
                    final showHighlightedLabel =
                        _highlightedCell == index && _highlightedLabel != null;
                    final showAnswerLabel =
                        _showAnswer && _expectedCells.contains(index);
                    final label = showClassicNumber
                        ? '$number'
                        : showHighlightedLabel
                        ? _highlightedLabel!
                        : showAnswerLabel
                        ? '${_expectedCells.indexOf(index) + 1}'
                        : '';
                    final highlightedByHint =
                        _showNextHint && _nextExpectedCell == index && _input;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _tapCell(index),
                        child: Ink(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: _cellColor(context, index, solved),
                            border: Border.all(
                              color: (_warningCell == index)
                                  ? Theme.of(context).colorScheme.error
                                  : highlightedByHint
                                  ? _accent
                                  : Theme.of(
                                      context,
                                    ).colorScheme.outlineVariant,
                              width:
                                  (_highlightedCell == index ||
                                      solved ||
                                      highlightedByHint ||
                                      _warningCell == index)
                                  ? 2
                                  : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              label,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: _warningCell == index
                                        ? Theme.of(context).colorScheme.error
                                        : null,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _statusText(i18n),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  _HumanActionButton(
                    label: _positions.isEmpty || _sessionEnded || _failed
                        ? i18n.t('toolbox.breathing.start')
                        : i18n.t(
                            'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.next_round_ad9935',
                          ),
                    icon: Icons.play_arrow_rounded,
                    onPressed: _showingSequence ? null : _startRound,
                  ),
                  OutlinedButton.icon(
                    onPressed: _resetSession,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: Text(i18n.t('appearanceReset')),
                  ),
                  OutlinedButton.icon(
                    onPressed: _attemptedRounds == 0 || _reportDialogOpen
                        ? null
                        : () => _showCompletionReport(
                            success: _sessionEnded && !_failed,
                          ),
                    icon: const Icon(Icons.analytics_rounded),
                    label: Text(i18n.t('toolbox.sleep.assist.reportCard')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChimpCompletionReportDialog extends StatelessWidget {
  const _ChimpCompletionReportDialog({
    required this.modeLabel,
    required this.success,
    required this.gridSize,
    required this.maxTargetCount,
    required this.attemptedRounds,
    required this.completedRounds,
    required this.failedRounds,
    required this.totalTaps,
    required this.mistakes,
    required this.bestCompletedTargets,
    required this.durations,
    required this.showAnswer,
    required this.showNextHint,
    required this.oneMistakeRescue,
    required this.accent,
  });

  final String modeLabel;
  final bool success;
  final int gridSize;
  final int maxTargetCount;
  final int attemptedRounds;
  final int completedRounds;
  final int failedRounds;
  final int totalTaps;
  final int mistakes;
  final int bestCompletedTargets;
  final List<Duration> durations;
  final bool showAnswer;
  final bool showNextHint;
  final bool oneMistakeRescue;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final accuracy = totalTaps == 0
        ? 0.0
        : ((totalTaps - mistakes) / totalTaps * 100).clamp(0.0, 100.0);
    final averageDuration = durations.isEmpty
        ? null
        : Duration(
            milliseconds:
                (durations
                            .map((item) => item.inMilliseconds)
                            .reduce((a, b) => a + b) /
                        durations.length)
                    .round(),
          );
    final bestDuration = durations.isEmpty
        ? null
        : durations.map((item) => item.inMilliseconds).reduce(math.min);
    final assisted = showAnswer || showNextHint || oneMistakeRescue;
    final analysis = _analysisText(
      i18n,
      accuracy,
      averageDuration,
      bestCompletedTargets,
      maxTargetCount,
      mistakes,
    );

    return _HumanReportDialogFrame(
      title: Text(
        i18n.t(
          'inline.ui.pages.toolbox_human_tests_memory.chimp_test_report_7ee181',
        ),
      ),
      accent: accent,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (
              i18n.t('inline.plan295.life.result.e1843313cacb'),
              success
                  ? i18n.t(
                      'inline.ui.pages.toolbox_human_tests_memory.cleared_c85927',
                    )
                  : i18n.t(
                      'inline.ui.pages.toolbox_human_tests_memory.stopped_348036',
                    ),
            ),
            (i18n.t('toolbox.sound.piano.mode'), modeLabel),
            (
              i18n.t('inline.ui.pages.toolbox_human_tests_memory.board_113334'),
              '$gridSize x $gridSize',
            ),
            (i18n.t('rounds'), '$completedRounds/$attemptedRounds'),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_memory.failed_2896ef',
              ),
              '$failedRounds',
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_memory.best_targets_b32608',
              ),
              '$bestCompletedTargets/$maxTargetCount',
            ),
            (
              i18n.t('inline.ui.pages.practice_review_page.accuracy_8cf5a1'),
              '${accuracy.round()}%',
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_bimanual.mistakes_ea8156',
              ),
              '$mistakes',
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_cognition.avg_time_a74bf4',
              ),
              averageDuration == null
                  ? '-'
                  : _formatSeconds(averageDuration.inMilliseconds / 1000),
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_drag_tracking.best_time_1330b3',
              ),
              bestDuration == null ? '-' : _formatSeconds(bestDuration / 1000),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _ChimpReportBlock(
          title: i18n.t(
            'inline.ui.pages.toolbox_human_tests_memory.analysis_b0b53c',
          ),
          body: analysis,
          accent: accent,
        ),
        const SizedBox(height: 10),
        _ChimpReportBlock(
          title: i18n.t(
            'inline.ui.pages.toolbox_human_tests_memory.assists_c1835d',
          ),
          body: assisted
              ? i18n.t(
                  'inline.plan296.ui.pages.toolbox.human.tests.memory.assists_enabled_treat_this_as_practice.2f4835b9fc',
                  params: <String, Object?>{
                    'p0': _enabledAssistLabels(i18n).join(' / '),
                  },
                )
              : i18n.t(
                  'inline.ui.pages.toolbox_human_tests_memory.no_answer_or_hint_assist_was_enabled_so_the_score_is_clo_d9fe90',
                ),
          accent: accent,
        ),
      ],
    );
  }

  List<String> _enabledAssistLabels(AppI18n i18n) {
    return <String>[
      if (showAnswer)
        i18n.t('inline.ui.pages.toolbox_human_tests_memory.show_answer_611b2f'),
      if (showNextHint)
        i18n.t(
          'inline.ui.pages.toolbox_human_tests_memory.next_step_hint_9df1c2',
        ),
      if (oneMistakeRescue)
        i18n.t(
          'inline.ui.pages.toolbox_human_tests_memory.one_mistake_rescue_2bdd0b',
        ),
    ];
  }

  static String _analysisText(
    AppI18n i18n,
    double accuracy,
    Duration? averageTime,
    int bestTargets,
    int targetCap,
    int mistakes,
  ) {
    if (bestTargets >= targetCap && accuracy >= 95) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_memory.accuracy_is_steady_and_the_cap_is_cleared_raise_target_c_eb4f86',
      );
    }
    if (accuracy >= 85) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_memory.performance_is_stable_next_turn_assists_off_or_lower_pla_88fcb6',
      );
    }
    if (mistakes > 0) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_memory.most_loss_comes_from_order_errors_practice_route_plannin_4f0b7f',
      );
    }
    if (averageTime != null && averageTime.inMilliseconds > 6000) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_memory.accurate_but_pace_is_slow_keep_the_target_count_and_try_a946ce',
      );
    }
    return i18n.t(
      'inline.ui.pages.toolbox_human_tests_memory.start_with_a_smaller_board_and_lower_target_count_then_s_e189da',
    );
  }
}

class _ChimpReportBlock extends StatelessWidget {
  const _ChimpReportBlock({
    required this.title,
    required this.body,
    required this.accent,
  });

  final String title;
  final String body;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: accent.withValues(alpha: 0.08),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(body, style: theme.textTheme.bodyMedium?.copyWith(height: 1.35)),
        ],
      ),
    );
  }
}

class SequenceMemoryTestPage extends StatelessWidget {
  const SequenceMemoryTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_memory.sequence_memory_8c2989',
      ),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests_memory.watch_the_light_sequence_then_tap_the_panels_in_the_same_79dacb',
      ),
      accent: const Color(0xFF7C6BC8),
      icon: Icons.auto_awesome_motion_rounded,
      status: i18n.t(
        'inline.ui.pages.toolbox_human_tests_memory.next_replay_the_sequence_08cd45',
      ),
      child: const _SequenceMemoryCard(),
    );
  }
}

class _SequenceMemoryCard extends StatefulWidget {
  const _SequenceMemoryCard();

  @override
  State<_SequenceMemoryCard> createState() => _SequenceMemoryCardState();
}

class _SequenceMemoryCardState extends State<_SequenceMemoryCard> {
  final math.Random _random = math.Random();
  static const List<Color> _palette = <Color>[
    Color(0xFF4F8BC9),
    Color(0xFF57A76A),
    Color(0xFFD0913D),
    Color(0xFFC15A72),
    Color(0xFF8367C7),
    Color(0xFF3FA7B2),
    Color(0xFF6E8AF6),
    Color(0xFFE06A4B),
    Color(0xFF4AA3A0),
  ];
  static const List<IconData> _icons = <IconData>[
    Icons.circle_rounded,
    Icons.crop_square_rounded,
    Icons.change_history_rounded,
    Icons.star_rounded,
    Icons.favorite_rounded,
    Icons.bolt_rounded,
    Icons.flag_rounded,
    Icons.lightbulb_rounded,
    Icons.local_fire_department_rounded,
  ];
  static const int _minItemCount = 4;
  static const int _maxItemCount = 9;

  int _level = 1;
  int _itemCount = 6;
  List<int> _sequence = <int>[];
  int _inputIndex = 0;
  int? _lit;
  bool _showing = false;
  bool _input = false;
  bool _failed = false;
  bool _repeatFlash = false;
  int? _pressedCell;
  bool? _pressedCorrect;
  int _pressSerial = 0;
  int _flashSerial = 0;
  int _roundToken = 0;

  Future<void> _startRound() async {
    final token = ++_roundToken;
    final sequence = List<int>.generate(
      _level,
      (_) => _random.nextInt(_itemCount),
    );
    setState(() {
      _sequence = sequence;
      _inputIndex = 0;
      _lit = null;
      _showing = true;
      _input = false;
      _failed = false;
      _repeatFlash = false;
      _pressedCell = null;
      _pressedCorrect = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 260));
    var previousItem = -1;
    for (final item in sequence) {
      if (!mounted || token != _roundToken) {
        return;
      }
      final repeat = previousItem == item;
      if (repeat) {
        setState(() {
          _lit = null;
          _repeatFlash = false;
        });
        await Future<void>.delayed(const Duration(milliseconds: 160));
      }
      if (!mounted || token != _roundToken) {
        return;
      }
      setState(() {
        _lit = item;
        _flashSerial += 1;
        _repeatFlash = repeat;
      });
      await Future<void>.delayed(Duration(milliseconds: repeat ? 520 : 400));
      if (!mounted || token != _roundToken) {
        return;
      }
      setState(() {
        _lit = null;
        _repeatFlash = false;
      });
      await Future<void>.delayed(Duration(milliseconds: repeat ? 200 : 140));
      previousItem = item;
    }
    if (!mounted || token != _roundToken) {
      return;
    }
    setState(() {
      _showing = false;
      _input = true;
      _pressedCell = null;
      _pressedCorrect = null;
    });
  }

  void _tap(int index) {
    if (!_input) {
      return;
    }
    final correct = _sequence[_inputIndex] == index;
    _showPressFeedback(index: index, correct: correct);
    if (!correct) {
      setState(() {
        _failed = true;
        _input = false;
      });
      return;
    }
    if (_inputIndex + 1 >= _sequence.length) {
      final token = _roundToken;
      setState(() {
        _level += 1;
        _input = false;
        _repeatFlash = false;
      });
      Future<void>.delayed(const Duration(milliseconds: 240), () {
        if (!mounted || token != _roundToken || _failed || _input) {
          return;
        }
        _startRound();
      });
      return;
    }
    setState(() => _inputIndex += 1);
  }

  void _showPressFeedback({required int index, required bool correct}) {
    final serial = _pressSerial + 1;
    setState(() {
      _pressedCell = index;
      _pressedCorrect = correct;
      _pressSerial = serial;
    });
    Future<void>.delayed(const Duration(milliseconds: 220), () {
      if (!mounted || _pressSerial != serial) {
        return;
      }
      setState(() {
        _pressedCell = null;
        _pressedCorrect = null;
      });
    });
  }

  void _setItemCount(int value) {
    if (_showing || _input) {
      return;
    }
    final next = value.clamp(_minItemCount, _maxItemCount).toInt();
    if (_itemCount == next) {
      return;
    }
    _roundToken += 1;
    setState(() {
      _itemCount = next;
      _level = 1;
      _sequence = <int>[];
      _inputIndex = 0;
      _lit = null;
      _showing = false;
      _input = false;
      _failed = false;
      _repeatFlash = false;
      _pressedCell = null;
      _pressedCorrect = null;
    });
  }

  void _reset() {
    _roundToken += 1;
    setState(() {
      _level = 1;
      _sequence = <int>[];
      _inputIndex = 0;
      _lit = null;
      _showing = false;
      _input = false;
      _failed = false;
      _repeatFlash = false;
      _pressedCell = null;
      _pressedCorrect = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final crossAxisCount = _itemCount <= 4 ? 2 : 3;
    final childAspectRatio = _itemCount <= 4 ? 1.45 : 1.22;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (i18n.t('toolbox.sound.pickup.level'), '$_level'),
            (
              i18n.t('progress'),
              _input ? '$_inputIndex/${_sequence.length}' : '-',
            ),
            (
              i18n.t('inline.ui.pages.toolbox_human_tests_memory.icons_6035f3'),
              '$_itemCount',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _HumanSettingsSection(
          title: i18n.t(
            'inline.ui.pages.toolbox_human_tests_memory.sequence_settings_f62cef',
          ),
          subtitle: i18n.t(
            'inline.ui.pages.toolbox_human_tests_memory.adjust_the_icon_count_before_starting_a_new_round_25d2fa',
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      i18n.t(
                        'inline.ui.pages.toolbox_human_tests_memory.icon_count_bca327',
                      ),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '$_itemCount',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
              Slider(
                value: _itemCount.toDouble(),
                min: _minItemCount.toDouble(),
                max: _maxItemCount.toDouble(),
                divisions: _maxItemCount - _minItemCount,
                label: '$_itemCount',
                onChanged: (_showing || _input)
                    ? null
                    : (value) => _setItemCount(value.round()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _HumanPanel(
          child: Column(
            children: <Widget>[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _itemCount,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: childAspectRatio,
                ),
                itemBuilder: (context, index) {
                  final active = _lit == index;
                  final pressed = _pressedCell == index;
                  final pressedCorrect = _pressedCorrect;
                  return GestureDetector(
                    onTap: () => _tap(index),
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey<String>(
                        'sequence-flash-$index-$_flashSerial-$_pressSerial',
                      ),
                      tween: Tween<double>(
                        begin: 0,
                        end: active || pressed ? 1 : 0,
                      ),
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      builder: (context, pulse, child) {
                        final color = _palette[index];
                        final icon = _icons[index];
                        final feedbackColor = pressedCorrect == false
                            ? Theme.of(context).colorScheme.error
                            : Colors.white;
                        return Transform.scale(
                          scale:
                              1 +
                              pulse *
                                  (pressed
                                      ? 0.10
                                      : _repeatFlash
                                      ? 0.12
                                      : 0.08),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: color.withValues(
                                alpha: active || pressed ? 0.82 : 0.22,
                              ),
                              border: Border.all(
                                color: pressed
                                    ? feedbackColor.withValues(alpha: 0.95)
                                    : color.withValues(
                                        alpha: active ? 0.95 : 0.32,
                                      ),
                                width: active || pressed ? 3 : 1,
                              ),
                              boxShadow: active || pressed
                                  ? <BoxShadow>[
                                      BoxShadow(
                                        color: (pressed ? feedbackColor : color)
                                            .withValues(
                                              alpha: 0.22 + pulse * 0.18,
                                            ),
                                        blurRadius: 10 + pulse * 8,
                                        spreadRadius: 1 + pulse * 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Stack(
                              children: <Widget>[
                                Center(
                                  child: Icon(
                                    icon,
                                    size: active || pressed ? 34 : 28,
                                    color: Colors.white.withValues(
                                      alpha: active || pressed ? 0.98 : 0.84,
                                    ),
                                  ),
                                ),
                                if (pressed)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: feedbackColor.withValues(
                                          alpha: 0.92,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        pressedCorrect == false
                                            ? Icons.close_rounded
                                            : Icons.check_rounded,
                                        size: 18,
                                        color: pressedCorrect == false
                                            ? Colors.white
                                            : color,
                                      ),
                                    ),
                                  ),
                                if (_input && _sequence.isNotEmpty)
                                  Positioned(
                                    left: 8,
                                    bottom: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        color: Colors.black.withValues(
                                          alpha: 0.20,
                                        ),
                                      ),
                                      child: Text(
                                        '${math.min(_inputIndex + 1, _sequence.length)}/${_sequence.length}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                    ),
                                  ),
                                if (active && _repeatFlash)
                                  Positioned.fill(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              if (_failed)
                Text(
                  i18n.t(
                    'inline.ui.pages.toolbox_human_tests_memory.wrong_sequence_reset_and_try_again_d16140',
                  ),
                )
              else if (_showing)
                Text(
                  i18n.t(
                    'inline.ui.pages.toolbox_human_tests_memory.playing_sequence_9e231b',
                  ),
                ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  _HumanActionButton(
                    label: i18n.t('toolbox.breathing.start'),
                    icon: Icons.play_arrow_rounded,
                    onPressed: _showing ? null : _startRound,
                  ),
                  OutlinedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: Text(i18n.t('appearanceReset')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
