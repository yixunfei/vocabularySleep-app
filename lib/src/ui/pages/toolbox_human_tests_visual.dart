part of 'toolbox_human_tests.dart';

class ColorVisionTestPage extends StatelessWidget {
  const ColorVisionTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_visual.color_vision_26e312',
      ),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests_visual.classic_odd_tile_and_mixed_color_matching_with_per_hue_a_d43bb4',
      ),
      accent: _ColorVisionCardState.accent,
      icon: Icons.palette_rounded,
      status: i18n.t(
        'inline.ui.pages.toolbox_human_tests_visual.next_choose_a_mode_and_tap_the_target_color_176fda',
      ),
      child: const _ColorVisionCard(),
    );
  }
}

class _ColorVisionCard extends StatefulWidget {
  const _ColorVisionCard();

  @override
  State<_ColorVisionCard> createState() => _ColorVisionCardState();
}

enum _ColorVisionMode { oddTile, mixedMatch }

enum _ColorVisionFilter { full, avoidRedGreen, avoidBlueYellow, grayscale }

enum _ColorVisionLivesPreset { one, three, five, unlimited }

enum _ColorVisionHueBand { red, orange, yellow, green, cyan, blue, purple }

enum _ColorVisionDeltaAxis { hue, saturation, lightness }

class _ColorVisionCell {
  const _ColorVisionCell({
    required this.color,
    required this.correct,
    required this.targetTwin,
    required this.decoyLevel,
  });

  final Color color;
  final bool correct;
  final bool targetTwin;
  final int decoyLevel;
}

class _ColorVisionRoundRecord {
  const _ColorVisionRoundRecord({
    required this.level,
    required this.gridSize,
    required this.mode,
    required this.hueBand,
    required this.deltaAxis,
    required this.delta,
    required this.targetCount,
    required this.correct,
    required this.usedHint,
  });

  final int level;
  final int gridSize;
  final _ColorVisionMode mode;
  final _ColorVisionHueBand hueBand;
  final _ColorVisionDeltaAxis deltaAxis;
  final double delta;
  final int targetCount;
  final bool correct;
  final bool usedHint;
}

class _ColorVisionReportData {
  const _ColorVisionReportData({
    required this.level,
    required this.bestLevel,
    required this.rounds,
    required this.correctRounds,
    required this.wrongRounds,
    required this.hintsUsed,
    required this.mode,
    required this.filter,
    required this.initialGrid,
    required this.maxGrid,
    required this.records,
  });

  final int level;
  final int bestLevel;
  final int rounds;
  final int correctRounds;
  final int wrongRounds;
  final int hintsUsed;
  final _ColorVisionMode mode;
  final _ColorVisionFilter filter;
  final int initialGrid;
  final int maxGrid;
  final List<_ColorVisionRoundRecord> records;

  double get accuracy => rounds <= 0 ? 0 : correctRounds / rounds;

  double get averageCorrectDelta {
    final passed = records.where((record) => record.correct).toList();
    if (passed.isEmpty) {
      return 0;
    }
    return passed.fold<double>(0, (sum, record) => sum + record.delta) /
        passed.length;
  }

  double get averageMissDelta {
    final missed = records.where((record) => !record.correct).toList();
    if (missed.isEmpty) {
      return 0;
    }
    return missed.fold<double>(0, (sum, record) => sum + record.delta) /
        missed.length;
  }
}

class _ColorVisionBandStat {
  const _ColorVisionBandStat({
    required this.band,
    required this.total,
    required this.correct,
    required this.averageDelta,
  });

  final _ColorVisionHueBand band;
  final int total;
  final int correct;
  final double averageDelta;

  double get accuracy => total <= 0 ? 0 : correct / total;
}

class _ColorVisionAxisStat {
  const _ColorVisionAxisStat({
    required this.axis,
    required this.total,
    required this.correct,
  });

  final _ColorVisionDeltaAxis axis;
  final int total;
  final int correct;

  double get accuracy => total <= 0 ? 0 : correct / total;
}

class _ColorVisionCardState extends State<_ColorVisionCard> {
  static const Color accent = Color(0xFF3F9A6B);
  static const int _minGridSize = 3;
  static const int _maxGridSize = 8;

  final math.Random _random = math.Random();
  _ColorVisionMode _mode = _ColorVisionMode.oddTile;
  _ColorVisionFilter _filter = _ColorVisionFilter.full;
  _ColorVisionLivesPreset _livesPreset = _ColorVisionLivesPreset.three;
  int _initialGrid = 3;
  int _maxGrid = 5;
  int _sameTargetCount = 1;
  bool _randomTargetCount = false;

  int _level = 1;
  int _bestLevel = 1;
  int _lives = 3;
  int _rounds = 0;
  int _correctRounds = 0;
  int _wrongRounds = 0;
  int _hintsUsed = 0;
  bool _gameOver = false;
  bool _hintActive = false;
  bool _roundHintUsed = false;
  bool _reportDialogOpen = false;

  double _targetHue = 130;
  double _targetSaturation = 0.46;
  double _targetLightness = 0.58;
  double _currentDelta = 0.12;
  _ColorVisionHueBand _hueBand = _ColorVisionHueBand.green;
  _ColorVisionDeltaAxis _deltaAxis = _ColorVisionDeltaAxis.lightness;
  Color _targetColor = const Color(0xFF72B98E);
  List<_ColorVisionCell> _cells = const <_ColorVisionCell>[];
  Set<int> _correctIndexes = const <int>{};
  final List<_ColorVisionRoundRecord> _records = <_ColorVisionRoundRecord>[];

  bool get _unlimitedLives => _livesPreset == _ColorVisionLivesPreset.unlimited;

  int get _currentGridSize {
    final stepped = _initialGrid + ((_level - 1) ~/ 4);
    return stepped.clamp(_initialGrid, _maxGrid);
  }

  int get _cellCount => _currentGridSize * _currentGridSize;

  int get _targetCount {
    if (_mode == _ColorVisionMode.oddTile) {
      return 1;
    }
    final maxTargets = math.min(_sameTargetCount, math.max(1, _cellCount ~/ 3));
    if (!_randomTargetCount) {
      return maxTargets;
    }
    return 1 + _random.nextInt(maxTargets);
  }

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  void _newRound() {
    _hintActive = false;
    _roundHintUsed = false;
    final base = _randomBaseHsl();
    _targetHue = base.hue;
    _targetSaturation = base.saturation;
    _targetLightness = base.lightness;
    _targetColor = base.toColor();
    _hueBand = _hueBandFor(_targetHue);
    _deltaAxis = _sample(_random, _ColorVisionDeltaAxis.values);
    _currentDelta = math.max(0.018, 0.15 - _level * 0.005);
    if (_mode == _ColorVisionMode.oddTile) {
      _buildOddTileRound(base);
    } else {
      _buildMixedMatchRound(base);
    }
  }

  void _buildOddTileRound(HSLColor base) {
    final odd = _shiftHsl(base, _deltaAxis, _signedDelta());
    final oddIndex = _random.nextInt(_cellCount);
    _correctIndexes = <int>{oddIndex};
    _cells = List<_ColorVisionCell>.generate(_cellCount, (index) {
      return _ColorVisionCell(
        color: index == oddIndex ? odd.toColor() : base.toColor(),
        correct: index == oddIndex,
        targetTwin: index == oddIndex,
        decoyLevel: index == oddIndex ? 0 : 2,
      );
    }, growable: false);
  }

  void _buildMixedMatchRound(HSLColor target) {
    final targetCount = _targetCount;
    final indexes = List<int>.generate(_cellCount, (index) => index)
      ..shuffle(_random);
    final correctIndexes = indexes.take(targetCount).toSet();
    _correctIndexes = correctIndexes;
    _cells = List<_ColorVisionCell>.generate(_cellCount, (index) {
      if (correctIndexes.contains(index)) {
        return _ColorVisionCell(
          color: target.toColor(),
          correct: true,
          targetTwin: true,
          decoyLevel: 0,
        );
      }
      final distanceTier = 1 + _random.nextInt(4);
      final axis = _sample(_random, _ColorVisionDeltaAxis.values);
      final localDelta = _currentDelta * (0.42 + distanceTier * 0.24);
      return _ColorVisionCell(
        color: _shiftHsl(target, axis, _signedDelta(localDelta)).toColor(),
        correct: false,
        targetTwin: false,
        decoyLevel: distanceTier,
      );
    }, growable: false);
  }

  HSLColor _randomBaseHsl() {
    final hue = _randomHue();
    final saturation = _filter == _ColorVisionFilter.grayscale
        ? 0.03 + _random.nextDouble() * 0.05
        : 0.36 + _random.nextDouble() * 0.28;
    final lightness = 0.44 + _random.nextDouble() * 0.22;
    return HSLColor.fromAHSL(1, hue, saturation, lightness);
  }

  double _randomHue() {
    final ranges = switch (_filter) {
      _ColorVisionFilter.full => const <(double, double)>[(0, 360)],
      _ColorVisionFilter.avoidRedGreen => const <(double, double)>[
        (32, 86),
        (176, 286),
        (292, 326),
      ],
      _ColorVisionFilter.avoidBlueYellow => const <(double, double)>[
        (0, 34),
        (96, 188),
        (286, 360),
      ],
      _ColorVisionFilter.grayscale => const <(double, double)>[(0, 360)],
    };
    final range = _sample(_random, ranges);
    return range.$1 + _random.nextDouble() * (range.$2 - range.$1);
  }

  HSLColor _shiftHsl(
    HSLColor source,
    _ColorVisionDeltaAxis axis,
    double delta,
  ) {
    return switch (axis) {
      _ColorVisionDeltaAxis.hue => source.withHue(
        (source.hue + delta * 170) % 360,
      ),
      _ColorVisionDeltaAxis.saturation => source.withSaturation(
        (source.saturation + delta).clamp(0.02, 0.84),
      ),
      _ColorVisionDeltaAxis.lightness => source.withLightness(
        (source.lightness + delta).clamp(0.18, 0.84),
      ),
    };
  }

  double _signedDelta([double? value]) {
    final delta = value ?? _currentDelta;
    return _random.nextBool() ? delta : -delta;
  }

  void _tap(int index) {
    if (_gameOver || index < 0 || index >= _cells.length) {
      return;
    }
    final roundLevel = _level;
    final roundGridSize = _currentGridSize;
    final correct = _correctIndexes.contains(index);
    setState(() {
      _rounds += 1;
      if (correct) {
        _correctRounds += 1;
        _level += 1;
        _bestLevel = math.max(_bestLevel, _level);
      } else {
        _wrongRounds += 1;
        if (!_unlimitedLives) {
          _lives -= 1;
          _gameOver = _lives <= 0;
        }
      }
      _records.add(
        _ColorVisionRoundRecord(
          level: roundLevel,
          gridSize: roundGridSize,
          mode: _mode,
          hueBand: _hueBand,
          deltaAxis: _deltaAxis,
          delta: _currentDelta,
          targetCount: _correctIndexes.length,
          correct: correct,
          usedHint: _roundHintUsed,
        ),
      );
      if (!_gameOver) {
        _newRound();
      }
    });
    if (_gameOver) {
      _showCompletionReport();
    }
  }

  void _showHint() {
    if (_gameOver || _cells.isEmpty) {
      return;
    }
    setState(() {
      _hintActive = true;
      if (!_roundHintUsed) {
        _roundHintUsed = true;
        _hintsUsed += 1;
      }
    });
  }

  void _finishNow() {
    setState(() {
      _gameOver = true;
    });
    _showCompletionReport();
  }

  void _reset() {
    setState(() {
      _level = 1;
      _bestLevel = 1;
      _lives = _livesForPreset(_livesPreset);
      _rounds = 0;
      _correctRounds = 0;
      _wrongRounds = 0;
      _hintsUsed = 0;
      _gameOver = false;
      _hintActive = false;
      _roundHintUsed = false;
      _records.clear();
      _newRound();
    });
  }

  void _restartWithSettings() {
    _lives = _livesForPreset(_livesPreset);
    _level = 1;
    _bestLevel = 1;
    _rounds = 0;
    _correctRounds = 0;
    _wrongRounds = 0;
    _hintsUsed = 0;
    _gameOver = false;
    _records.clear();
    _newRound();
  }

  void _setMode(_ColorVisionMode mode) {
    if (_mode == mode) {
      return;
    }
    setState(() {
      _mode = mode;
      if (_mode == _ColorVisionMode.mixedMatch && _initialGrid < 4) {
        _initialGrid = 4;
      }
      if (_maxGrid < _initialGrid) {
        _maxGrid = _initialGrid;
      }
      _restartWithSettings();
    });
  }

  void _setFilter(_ColorVisionFilter filter) {
    setState(() {
      _filter = filter;
      _restartWithSettings();
    });
  }

  void _setLivesPreset(_ColorVisionLivesPreset preset) {
    setState(() {
      _livesPreset = preset;
      _restartWithSettings();
    });
  }

  void _setInitialGrid(double value) {
    final next = value.round().clamp(_minGridSize, _maxGridSize);
    setState(() {
      _initialGrid = next;
      _maxGrid = math.max(_maxGrid, _initialGrid);
      _restartWithSettings();
    });
  }

  void _setMaxGrid(double value) {
    final next = value.round().clamp(_initialGrid, _maxGridSize);
    setState(() {
      _maxGrid = next;
      _restartWithSettings();
    });
  }

  void _setSameTargetCount(double value) {
    setState(() {
      _sameTargetCount = value.round().clamp(1, 8);
      _restartWithSettings();
    });
  }

  void _setRandomTargetCount(bool value) {
    setState(() {
      _randomTargetCount = value;
      _restartWithSettings();
    });
  }

  _ColorVisionReportData _buildReportData() {
    return _ColorVisionReportData(
      level: _level,
      bestLevel: _bestLevel,
      rounds: _rounds,
      correctRounds: _correctRounds,
      wrongRounds: _wrongRounds,
      hintsUsed: _hintsUsed,
      mode: _mode,
      filter: _filter,
      initialGrid: _initialGrid,
      maxGrid: _maxGrid,
      records: List<_ColorVisionRoundRecord>.unmodifiable(_records),
    );
  }

  void _showCompletionReport() {
    if (!mounted || _reportDialogOpen) {
      return;
    }
    final report = _buildReportData();
    _reportDialogOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _reportDialogOpen = false;
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (_) => _ColorVisionReportDialog(
          data: report,
          accent: accent,
          modeLabel: (mode) => _modeLabel(
            AppI18n(Localizations.localeOf(context).languageCode),
            mode,
          ),
          filterLabel: (filter) => _filterLabel(
            AppI18n(Localizations.localeOf(context).languageCode),
            filter,
          ),
          bandLabel: (band) => _hueBandLabel(
            AppI18n(Localizations.localeOf(context).languageCode),
            band,
          ),
          axisLabel: (axis) => _axisLabel(
            AppI18n(Localizations.localeOf(context).languageCode),
            axis,
          ),
        ),
      );
      _reportDialogOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (i18n.t('toolbox.sound.pickup.level'), '$_level'),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_cognition.lives_1176de',
              ),
              _livesLabel(i18n),
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_visual_memory.grid_39884f',
              ),
              '${_currentGridSize}x$_currentGridSize',
            ),
            (
              i18n.t('inline.ui.pages.practice_review_page.accuracy_8cf5a1'),
              _rounds <= 0
                  ? '0%'
                  : '${((_correctRounds / _rounds) * 100).round()}%',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _HumanSettingsSection(
          title: i18n.t(
            'inline.ui.pages.toolbox_human_tests_visual.color_vision_settings_80e7ff',
          ),
          subtitle: i18n.t(
            'inline.ui.pages.toolbox_human_tests_visual.mode_color_filter_lives_and_grid_settings_restart_the_cu_727da9',
          ),
          initiallyExpanded: true,
          child: _buildSettings(context, i18n),
        ),
        const SizedBox(height: 12),
        _HumanPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  _HumanPill(text: _modeLabel(i18n, _mode), accent: accent),
                  _HumanPill(
                    text: _filterLabel(i18n, _filter),
                    accent: Theme.of(context).colorScheme.tertiary,
                  ),
                  _HumanPill(
                    text: _axisLabel(i18n, _deltaAxis),
                    accent: Theme.of(context).colorScheme.primary,
                  ),
                  _HumanPill(
                    text: i18n.t(
                      'inline.ui.pages.toolbox_human_tests_visual.delta_currentdelta_100_tostringasfixed_1_5d6eb1',
                    ),
                    accent: Theme.of(context).colorScheme.secondary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_mode == _ColorVisionMode.mixedMatch) ...<Widget>[
                _ColorVisionTargetPrompt(
                  i18n: i18n,
                  color: _targetColor,
                  targetCount: _correctIndexes.length,
                ),
                const SizedBox(height: 12),
              ],
              AspectRatio(
                aspectRatio: 1,
                child: _ColorVisionGrid(
                  i18n: i18n,
                  cells: _cells,
                  gridSize: _currentGridSize,
                  hintActive: _hintActive,
                  onTap: _tap,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _stageHint(i18n),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_gameOver) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  i18n.t(
                    'inline.ui.pages.toolbox_human_tests_visual.test_over_review_the_report_or_reset_to_try_again_e647d6',
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  _HumanActionButton(
                    label: i18n.t(
                      'inline.ui.pages.toolbox_human_tests_visual.hint_972a23',
                    ),
                    icon: Icons.tips_and_updates_rounded,
                    onPressed: _gameOver ? null : _showHint,
                  ),
                  OutlinedButton.icon(
                    onPressed: _finishNow,
                    icon: const Icon(Icons.analytics_rounded),
                    label: Text(
                      i18n.t(
                        'inline.ui.pages.toolbox_human_tests_visual.end_and_analyze_acc9d1',
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _rounds <= 0 ? null : _showCompletionReport,
                    icon: const Icon(Icons.query_stats_rounded),
                    label: Text(
                      i18n.t(
                        'inline.ui.pages.toolbox_human_tests_aim.view_report_05b6eb',
                      ),
                    ),
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

  Widget _buildSettings(BuildContext context, AppI18n i18n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          i18n.t('toolbox.sound.piano.mode'),
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _ColorVisionMode.values
              .map(
                (mode) => ChoiceChip(
                  label: Text(_modeLabel(i18n, mode)),
                  selected: _mode == mode,
                  onSelected: (_) => _setMode(mode),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 14),
        Text(
          i18n.t(
            'inline.ui.pages.toolbox_human_tests_visual.color_filter_66f3f7',
          ),
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _ColorVisionFilter.values
              .map(
                (filter) => ChoiceChip(
                  label: Text(_filterLabel(i18n, filter)),
                  selected: _filter == filter,
                  onSelected: (_) => _setFilter(filter),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 14),
        Text(
          i18n.t(
            'inline.ui.pages.toolbox_human_tests_visual.maximum_lives_a358c7',
          ),
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _ColorVisionLivesPreset.values
              .map(
                (preset) => ChoiceChip(
                  label: Text(_livesPresetLabel(i18n, preset)),
                  selected: _livesPreset == preset,
                  onSelected: (_) => _setLivesPreset(preset),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 14),
        _ColorVisionSettingSlider(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_visual.initial_grid_f642cd',
          ),
          valueText: '${_initialGrid}x$_initialGrid',
          value: _initialGrid.toDouble(),
          min: _minGridSize.toDouble(),
          max: _maxGridSize.toDouble(),
          divisions: _maxGridSize - _minGridSize,
          onChanged: _setInitialGrid,
        ),
        _ColorVisionSettingSlider(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_visual.maximum_grid_519887',
          ),
          valueText: '${_maxGrid}x$_maxGrid',
          value: _maxGrid.toDouble(),
          min: _initialGrid.toDouble(),
          max: _maxGridSize.toDouble(),
          divisions: _maxGridSize - _initialGrid,
          onChanged: _setMaxGrid,
        ),
        if (_mode == _ColorVisionMode.mixedMatch) ...<Widget>[
          _ColorVisionSettingSlider(
            label: i18n.t(
              'inline.ui.pages.toolbox_human_tests_visual.matching_targets_589cb2',
            ),
            valueText: _randomTargetCount
                ? i18n.t(
                    'inline.ui.pages.toolbox_human_tests_visual.random_1_sametargetcount_ef7206',
                  )
                : '$_sameTargetCount',
            value: _sameTargetCount.toDouble(),
            min: 1,
            max: 8,
            divisions: 7,
            onChanged: _setSameTargetCount,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_visual.random_target_count_3023e3',
              ),
            ),
            subtitle: Text(
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_visual.each_round_samples_the_matching_target_count_between_1_a_00225e',
              ),
            ),
            value: _randomTargetCount,
            onChanged: _setRandomTargetCount,
          ),
        ],
      ],
    );
  }

  String _stageHint(AppI18n i18n) {
    if (_mode == _ColorVisionMode.oddTile) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_visual.find_the_only_different_tile_hints_add_a_target_border_a_02209b',
      );
    }
    return i18n.t(
      'inline.ui.pages.toolbox_human_tests_visual.match_the_target_swatch_above_then_tap_a_tile_with_the_e_f59b8c',
    );
  }

  String _modeLabel(AppI18n i18n, _ColorVisionMode mode) {
    return switch (mode) {
      _ColorVisionMode.oddTile => i18n.t(
        'inline.ui.pages.toolbox_human_tests_visual.odd_tile_929431',
      ),
      _ColorVisionMode.mixedMatch => i18n.t(
        'inline.ui.pages.toolbox_human_tests_visual.mixed_match_ec0257',
      ),
    };
  }

  String _filterLabel(AppI18n i18n, _ColorVisionFilter filter) {
    return switch (filter) {
      _ColorVisionFilter.full => i18n.t(
        'inline.ui.pages.toolbox_human_tests_visual.full_spectrum_a23be2',
      ),
      _ColorVisionFilter.avoidRedGreen => i18n.t(
        'inline.ui.pages.toolbox_human_tests_visual.avoid_red_green_22b70f',
      ),
      _ColorVisionFilter.avoidBlueYellow => i18n.t(
        'inline.ui.pages.toolbox_human_tests_visual.avoid_blue_yellow_c79720',
      ),
      _ColorVisionFilter.grayscale => i18n.t(
        'inline.ui.pages.toolbox_human_tests_visual.low_saturation_b1ace2',
      ),
    };
  }

  String _livesPresetLabel(AppI18n i18n, _ColorVisionLivesPreset preset) {
    return switch (preset) {
      _ColorVisionLivesPreset.one => i18n.t(
        'inline.ui.pages.toolbox_human_tests_visual.1_life_49a973',
      ),
      _ColorVisionLivesPreset.three => i18n.t(
        'inline.ui.pages.toolbox_human_tests_visual.3_lives_423f2a',
      ),
      _ColorVisionLivesPreset.five => i18n.t(
        'inline.ui.pages.toolbox_human_tests_visual.5_lives_0b911b',
      ),
      _ColorVisionLivesPreset.unlimited => i18n.t(
        'inline.ui.pages.toolbox_human_tests_bimanual.unlimited_13e814',
      ),
    };
  }

  String _livesLabel(AppI18n i18n) {
    if (_unlimitedLives) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_bimanual.unlimited_13e814',
      );
    }
    return '$_lives';
  }

  String _hueBandLabel(AppI18n i18n, _ColorVisionHueBand band) {
    return switch (band) {
      _ColorVisionHueBand.red => i18n.t('inline.plan295.life.red.a80dab852185'),
      _ColorVisionHueBand.orange => i18n.t(
        'inline.plan295.life.orange.314513e06d79',
      ),
      _ColorVisionHueBand.yellow => i18n.t(
        'inline.plan295.life.yellow.d7182985d92a',
      ),
      _ColorVisionHueBand.green => i18n.t(
        'inline.plan295.life.green.b645407522f6',
      ),
      _ColorVisionHueBand.cyan => i18n.t(
        'inline.plan295.life.cyan.4455b90fad29',
      ),
      _ColorVisionHueBand.blue => i18n.t(
        'inline.plan295.life.blue.e74cca65888f',
      ),
      _ColorVisionHueBand.purple => i18n.t(
        'inline.ui.pages.toolbox_human_tests_visual.purple_a1e6b3',
      ),
    };
  }

  String _axisLabel(AppI18n i18n, _ColorVisionDeltaAxis axis) {
    return switch (axis) {
      _ColorVisionDeltaAxis.hue => i18n.t(
        'inline.ui.pages.toolbox_human_tests_visual.hue_shift_cc64e6',
      ),
      _ColorVisionDeltaAxis.saturation => i18n.t(
        'inline.ui.pages.toolbox_human_tests_visual.saturation_shift_399fd5',
      ),
      _ColorVisionDeltaAxis.lightness => i18n.t(
        'inline.ui.pages.toolbox_human_tests_visual.lightness_shift_6ebb52',
      ),
    };
  }

  int _livesForPreset(_ColorVisionLivesPreset preset) {
    return switch (preset) {
      _ColorVisionLivesPreset.one => 1,
      _ColorVisionLivesPreset.three => 3,
      _ColorVisionLivesPreset.five => 5,
      _ColorVisionLivesPreset.unlimited => 999,
    };
  }

  _ColorVisionHueBand _hueBandFor(double hue) {
    final normalized = hue % 360;
    if (normalized < 20 || normalized >= 334) {
      return _ColorVisionHueBand.red;
    }
    if (normalized < 48) {
      return _ColorVisionHueBand.orange;
    }
    if (normalized < 82) {
      return _ColorVisionHueBand.yellow;
    }
    if (normalized < 158) {
      return _ColorVisionHueBand.green;
    }
    if (normalized < 202) {
      return _ColorVisionHueBand.cyan;
    }
    if (normalized < 264) {
      return _ColorVisionHueBand.blue;
    }
    return _ColorVisionHueBand.purple;
  }
}
