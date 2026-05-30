part of 'toolbox_human_tests.dart';

class VisualMemoryTestPage extends StatelessWidget {
  const VisualMemoryTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_visual_memory.visual_memory_152214',
      ),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests_visual_memory.from_classic_positions_to_random_target_colors_higher_le_a8aae3',
      ),
      accent: const Color(0xFF8B6BC8),
      icon: Icons.dashboard_customize_rounded,
      status: i18n.t(
        'inline.ui.pages.toolbox_human_tests_visual_memory.next_choose_a_mode_observe_then_reproduce_the_targets_010f8f',
      ),
      child: const _VisualMemoryCard(),
    );
  }
}

class _VisualMemoryCard extends StatefulWidget {
  const _VisualMemoryCard();

  @override
  State<_VisualMemoryCard> createState() => _VisualMemoryCardState();
}

enum _VisualMemoryDifficulty { relaxed, standard, challenge, custom }

enum _VisualMemoryMode { positions, colorTargets, targetColor }

enum _VisualMemoryPalette { soft, vivid, contrast }

enum _VisualMemoryMarkKind { target, decoy, distractor }

class _VisualMemoryDifficultySpec {
  const _VisualMemoryDifficultySpec({
    required this.startGrid,
    required this.maxGrid,
    required this.gridStep,
    required this.baseTargets,
    required this.targetEvery,
    required this.targetCap,
    required this.missLimit,
    required this.lives,
    required this.observeMilliseconds,
  });

  final int startGrid;
  final int maxGrid;
  final int gridStep;
  final int baseTargets;
  final int targetEvery;
  final int targetCap;
  final int missLimit;
  final int lives;
  final int observeMilliseconds;
}

class _VisualMemoryColorToken {
  const _VisualMemoryColorToken({required this.color, required this.labelKey});

  final Color color;
  final String labelKey;

  String label(AppI18n i18n) => i18n.t(labelKey);
}

class _VisualMemoryPaletteSpec {
  const _VisualMemoryPaletteSpec({
    required this.labelKey,
    required this.colors,
  });
  final String labelKey;
  final List<_VisualMemoryColorToken> colors;

  String label(AppI18n i18n) => i18n.t(labelKey);
}

class _VisualMemoryCellMark {
  const _VisualMemoryCellMark({required this.kind, required this.color});

  final _VisualMemoryMarkKind kind;
  final Color color;
}

class _VisualMemoryRoundResult {
  const _VisualMemoryRoundResult({
    required this.level,
    required this.gridSize,
    required this.targets,
    required this.mistakes,
    required this.success,
    required this.mode,
    required this.targetColor,
  });

  final int level;
  final int gridSize;
  final int targets;
  final int mistakes;
  final bool success;
  final _VisualMemoryMode mode;
  final _VisualMemoryColorToken? targetColor;
}

class _VisualMemoryReportData {
  const _VisualMemoryReportData({
    required this.roundsStarted,
    required this.completedRounds,
    required this.failedRounds,
    required this.bestLevel,
    required this.correctTaps,
    required this.wrongTaps,
    required this.colorWrongTaps,
    required this.distractorWrongTaps,
    required this.blankWrongTaps,
    required this.totalTargetsShown,
    required this.duration,
    required this.mode,
    required this.difficulty,
    required this.colorPressure,
    required this.rounds,
  });

  final int roundsStarted;
  final int completedRounds;
  final int failedRounds;
  final int bestLevel;
  final int correctTaps;
  final int wrongTaps;
  final int colorWrongTaps;
  final int distractorWrongTaps;
  final int blankWrongTaps;
  final int totalTargetsShown;
  final Duration duration;
  final _VisualMemoryMode mode;
  final _VisualMemoryDifficulty difficulty;
  final double colorPressure;
  final List<_VisualMemoryRoundResult> rounds;
}

class _VisualMemoryCardState extends State<_VisualMemoryCard> {
  static const Color accent = Color(0xFF8B6BC8);
  static const Color distractorColor = Color(0xFF8D95A6);
  static const int _minGridSize = 4;
  static const int _maxGridSize = 6;

  static const Map<_VisualMemoryDifficulty, _VisualMemoryDifficultySpec>
  _difficultySpecs = <_VisualMemoryDifficulty, _VisualMemoryDifficultySpec>{
    _VisualMemoryDifficulty.relaxed: _VisualMemoryDifficultySpec(
      startGrid: 4,
      maxGrid: 5,
      gridStep: 6,
      baseTargets: 3,
      targetEvery: 2,
      targetCap: 11,
      missLimit: 4,
      lives: 4,
      observeMilliseconds: 1500,
    ),
    _VisualMemoryDifficulty.standard: _VisualMemoryDifficultySpec(
      startGrid: 4,
      maxGrid: 6,
      gridStep: 4,
      baseTargets: 3,
      targetEvery: 1,
      targetCap: 18,
      missLimit: 3,
      lives: 3,
      observeMilliseconds: 1200,
    ),
    _VisualMemoryDifficulty.challenge: _VisualMemoryDifficultySpec(
      startGrid: 5,
      maxGrid: 6,
      gridStep: 3,
      baseTargets: 5,
      targetEvery: 1,
      targetCap: 24,
      missLimit: 2,
      lives: 2,
      observeMilliseconds: 950,
    ),
  };

  static const Map<_VisualMemoryPalette, _VisualMemoryPaletteSpec>
  _paletteSpecs = <_VisualMemoryPalette, _VisualMemoryPaletteSpec>{
    _VisualMemoryPalette.soft: _VisualMemoryPaletteSpec(
      labelKey:
          'inline.plan297.human_tests.visual_memory.palette.soft.31f353d2d7',
      colors: <_VisualMemoryColorToken>[
        _VisualMemoryColorToken(
          color: Color(0xFF7C72D9),
          labelKey:
              'inline.plan297.human_tests.visual_memory.color.purple.9c53c62b6e',
        ),
        _VisualMemoryColorToken(
          color: Color(0xFF5C9DDC),
          labelKey:
              'inline.plan297.human_tests.visual_memory.color.blue.bf1fca5dd8',
        ),
        _VisualMemoryColorToken(
          color: Color(0xFF5DBA8D),
          labelKey:
              'inline.plan297.human_tests.visual_memory.color.green.3ce1214ca2',
        ),
        _VisualMemoryColorToken(
          color: Color(0xFFE0A54A),
          labelKey:
              'inline.plan297.human_tests.visual_memory.color.gold.699bf687cc',
        ),
        _VisualMemoryColorToken(
          color: Color(0xFFD36F8A),
          labelKey:
              'inline.plan297.human_tests.visual_memory.color.rose.402e9a448b',
        ),
        _VisualMemoryColorToken(
          color: Color(0xFF55B8B0),
          labelKey:
              'inline.plan297.human_tests.visual_memory.color.cyan.8279051865',
        ),
        _VisualMemoryColorToken(
          color: Color(0xFFC48A56),
          labelKey:
              'inline.plan297.human_tests.visual_memory.color.amber.5ac21bda23',
        ),
        _VisualMemoryColorToken(
          color: Color(0xFF8796DF),
          labelKey:
              'inline.plan297.human_tests.visual_memory.color.indigo.d8998128e2',
        ),
      ],
    ),
    _VisualMemoryPalette.vivid: _VisualMemoryPaletteSpec(
      labelKey:
          'inline.plan297.human_tests.visual_memory.palette.vivid.9aac0a0083',
      colors: <_VisualMemoryColorToken>[
        _VisualMemoryColorToken(
          color: Color(0xFFE84F5F),
          labelKey:
              'inline.plan297.human_tests.visual_memory.color.red.7e084893e3',
        ),
        _VisualMemoryColorToken(
          color: Color(0xFF1E88E5),
          labelKey:
              'inline.plan297.human_tests.visual_memory.color.blue.85b01c6ba6',
        ),
        _VisualMemoryColorToken(
          color: Color(0xFF23A455),
          labelKey:
              'inline.plan297.human_tests.visual_memory.color.green.739286824e',
        ),
        _VisualMemoryColorToken(
          color: Color(0xFFF6B72F),
          labelKey:
              'inline.plan297.human_tests.visual_memory.color.yellow.8454ae43be',
        ),
        _VisualMemoryColorToken(
          color: Color(0xFF9B55E6),
          labelKey:
              'inline.plan297.human_tests.visual_memory.color.purple.ea3dd45f39',
        ),
        _VisualMemoryColorToken(
          color: Color(0xFF00A6A6),
          labelKey:
              'inline.plan297.human_tests.visual_memory.color.cyan.3b368133f6',
        ),
        _VisualMemoryColorToken(
          color: Color(0xFFFF7A3D),
          labelKey:
              'inline.plan297.human_tests.visual_memory.color.orange.621c3ae28d',
        ),
        _VisualMemoryColorToken(
          color: Color(0xFF6072E8),
          labelKey:
              'inline.plan297.human_tests.visual_memory.color.indigo.b276e2400e',
        ),
      ],
    ),
    _VisualMemoryPalette.contrast: _VisualMemoryPaletteSpec(
      labelKey:
          'inline.plan297.human_tests.visual_memory.palette.contrast.f3e85187e2',
      colors: <_VisualMemoryColorToken>[
        _VisualMemoryColorToken(
          color: Color(0xFF005BBB),
          labelKey:
              'inline.plan297.human_tests.visual_memory.color.deep_blue.01eaa57ff7',
        ),
        _VisualMemoryColorToken(
          color: Color(0xFFFFB000),
          labelKey:
              'inline.plan297.human_tests.visual_memory.color.bright_yellow.f4425bc1d3',
        ),
        _VisualMemoryColorToken(
          color: Color(0xFFDC267F),
          labelKey:
              'inline.plan297.human_tests.visual_memory.color.magenta.dca0201e64',
        ),
        _VisualMemoryColorToken(
          color: Color(0xFF009E73),
          labelKey:
              'inline.plan297.human_tests.visual_memory.color.emerald.443ccf5b2d',
        ),
        _VisualMemoryColorToken(
          color: Color(0xFFFE6100),
          labelKey:
              'inline.plan297.human_tests.visual_memory.color.orange.fb1d7431b3',
        ),
        _VisualMemoryColorToken(
          color: Color(0xFF785EF0),
          labelKey:
              'inline.plan297.human_tests.visual_memory.color.purple.776d2a93a8',
        ),
        _VisualMemoryColorToken(
          color: Color(0xFF648FFF),
          labelKey:
              'inline.plan297.human_tests.visual_memory.color.sky_blue.35c206fd92',
        ),
        _VisualMemoryColorToken(
          color: Color(0xFF7A7A7A),
          labelKey:
              'inline.plan297.human_tests.visual_memory.color.gray.4bc562bf7e',
        ),
      ],
    ),
  };

  final math.Random _random = math.Random();
  Timer? _timer;
  int _roundToken = 0;

  _VisualMemoryDifficulty _difficulty = _VisualMemoryDifficulty.standard;
  _VisualMemoryMode _mode = _VisualMemoryMode.positions;
  _VisualMemoryPalette _palette = _VisualMemoryPalette.soft;
  int _observeMilliseconds = 1200;
  int _colorCount = 4;
  bool _distractorsEnabled = false;
  int _distractorIntensity = 3;
  int _customMaxGridSize = 6;
  int _customBaseTargets = 3;
  int _customMissLimit = 3;
  int _customLives = 3;

  int _level = 1;
  int _lives = 3;
  int _roundMistakes = 0;
  int _activeGridSize = _minGridSize;
  Set<int> _targets = <int>{};
  Set<int> _picked = <int>{};
  Set<int> _wrong = <int>{};
  Map<int, _VisualMemoryCellMark> _marks = <int, _VisualMemoryCellMark>{};
  _VisualMemoryColorToken? _targetColorToken;
  bool _showing = false;
  bool _input = false;
  bool _gameOver = false;
  bool _roundFailed = false;
  bool _reportDialogOpen = false;
  DateTime? _sessionStartedAt;
  int _roundsStarted = 0;
  int _completedRounds = 0;
  int _failedRounds = 0;
  int _bestLevel = 1;
  int _totalTargetsShown = 0;
  int _totalCorrectTaps = 0;
  int _totalWrongTaps = 0;
  int _colorWrongTaps = 0;
  int _distractorWrongTaps = 0;
  int _blankWrongTaps = 0;
  final List<_VisualMemoryRoundResult> _roundResults =
      <_VisualMemoryRoundResult>[];

  @override
  void dispose() {
    _timer?.cancel();
    _roundToken += 1;
    super.dispose();
  }

  _VisualMemoryDifficultySpec get _difficultySpec {
    if (_difficulty != _VisualMemoryDifficulty.custom) {
      return _difficultySpecs[_difficulty]!;
    }
    return _VisualMemoryDifficultySpec(
      startGrid: _minGridSize,
      maxGrid: _customMaxGridSize,
      gridStep: 4,
      baseTargets: _customBaseTargets,
      targetEvery: 1,
      targetCap: math.max(_customBaseTargets, 22),
      missLimit: _customMissLimit,
      lives: _customLives,
      observeMilliseconds: _observeMilliseconds,
    );
  }

  List<_VisualMemoryColorToken> get _activePalette {
    final colors = _paletteSpecs[_palette]!.colors;
    return colors
        .take(_colorCount.clamp(3, colors.length))
        .toList(growable: false);
  }

  bool get _roundBusy => _showing || _input;

  int get _lifeLimit => _difficultySpec.lives;

  int get _missLimit => _difficultySpec.missLimit;

  bool get _usesTargetColorRule =>
      _mode == _VisualMemoryMode.colorTargets ||
      _mode == _VisualMemoryMode.targetColor;

  double get _colorPressure {
    final difficultyBase = switch (_difficulty) {
      _VisualMemoryDifficulty.relaxed => 0.08,
      _VisualMemoryDifficulty.standard => 0.20,
      _VisualMemoryDifficulty.challenge => 0.34,
      _VisualMemoryDifficulty.custom => 0.24,
    };
    final levelGrowth = ((_level - 1) * 0.045).clamp(0.0, 0.32);
    final intensityGrowth =
        ((_distractorIntensity - 1) / 9).clamp(0.0, 1.0) *
        (_distractorsEnabled ? 0.18 : 0.08);
    final modeGrowth = _mode == _VisualMemoryMode.targetColor ? 0.06 : 0.0;
    return (difficultyBase + levelGrowth + intensityGrowth + modeGrowth)
        .clamp(0.0, 0.78)
        .toDouble();
  }

  int get _plannedGridSize {
    final spec = _difficultySpec;
    final step = math.max(1, spec.gridStep);
    return (spec.startGrid + ((_level - 1) ~/ step))
        .clamp(_minGridSize, spec.maxGrid)
        .toInt();
  }

  int get _plannedTargetCount => _targetCountForGrid(_plannedGridSize);

  int _targetCountForGrid(int gridSize) {
    final spec = _difficultySpec;
    final cellCount = gridSize * gridSize;
    final modeBonus = _mode == _VisualMemoryMode.colorTargets ? 1 : 0;
    final raw =
        spec.baseTargets +
        ((_level - 1) ~/ math.max(1, spec.targetEvery)) +
        modeBonus;
    final ratio = _mode == _VisualMemoryMode.targetColor ? 0.36 : 0.60;
    final cap = math.min(
      spec.targetCap,
      math.max(2, (cellCount * ratio).floor()),
    );
    return raw.clamp(2, cap).toInt();
  }

  int _decoyCountFor(int availableCells, int targetCount) {
    if (!_usesTargetColorRule || availableCells <= 0) {
      return 0;
    }
    if (_mode == _VisualMemoryMode.colorTargets) {
      final desired = math.max(2, math.min(_colorCount, targetCount + 1));
      return desired.clamp(0, availableCells).toInt();
    }
    final desired = math.max(
      2,
      math.min(_colorCount + ((_level - 1) ~/ 3), targetCount + 4),
    );
    return desired.clamp(0, availableCells).toInt();
  }

  int _distractorCountFor(int availableCells) {
    if (!_distractorsEnabled || availableCells <= 0) {
      return 0;
    }
    final desired = _distractorIntensity + ((_level - 1) ~/ 4);
    return desired.clamp(0, availableCells).toInt();
  }

  double _lerpValue(double start, double end, double t) {
    final amount = t.clamp(0.0, 1.0).toDouble();
    return start + (end - start) * amount;
  }

  double _wrapHue(double hue) {
    final value = hue % 360;
    return value < 0 ? value + 360 : value;
  }

  Color _nearTargetDecoyColor(
    Color targetColor,
    List<_VisualMemoryColorToken> decoyColors,
  ) {
    final pressure = _colorPressure;
    final targetHsl = HSLColor.fromColor(targetColor);
    final hueRange = _lerpValue(68, 10, pressure);
    final minHueShift = _lerpValue(18, 4, pressure);
    final direction = _random.nextDouble() < 0.5 ? -1.0 : 1.0;
    final hueShift =
        direction *
        (minHueShift + _random.nextDouble() * math.max(1.0, hueRange));
    final saturationRange = _lerpValue(0.22, 0.05, pressure);
    final lightnessRange = _lerpValue(0.18, 0.04, pressure);
    final saturation =
        (targetHsl.saturation +
                (_random.nextDouble() * 2 - 1) * saturationRange)
            .clamp(0.28, 0.92)
            .toDouble();
    final lightness =
        (targetHsl.lightness + (_random.nextDouble() * 2 - 1) * lightnessRange)
            .clamp(0.30, 0.78)
            .toDouble();
    final nearColor = targetHsl
        .withHue(_wrapHue(targetHsl.hue + hueShift))
        .withSaturation(saturation)
        .withLightness(lightness)
        .toColor();
    final paletteColor = _sample(_random, decoyColors).color;
    return Color.lerp(paletteColor, nearColor, pressure)!;
  }

  String _interferenceToneLabel(AppI18n i18n, double pressure) {
    if (pressure >= 0.58) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_visual_memory.near_color_decoys_f88dd1',
      );
    }
    if (pressure >= 0.34) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_visual_memory.closer_colors_ba3ddb',
      );
    }
    return i18n.t(
      'inline.ui.pages.toolbox_human_tests_visual_memory.clear_contrast_5030e0',
    );
  }

  String _difficultyLabel(AppI18n i18n, _VisualMemoryDifficulty difficulty) {
    return switch (difficulty) {
      _VisualMemoryDifficulty.relaxed => i18n.t(
        'inline.plan295.daily_choice.relaxed.556d216b95e0',
      ),
      _VisualMemoryDifficulty.standard => i18n.t(
        'inline.ui.pages.toolbox_human_tests_bimanual.standard_b9acb5',
      ),
      _VisualMemoryDifficulty.challenge => i18n.t(
        'inline.ui.pages.toolbox_human_tests_visual_memory_widgets.challenge_dea913',
      ),
      _VisualMemoryDifficulty.custom => i18n.t('toolbox.sound.harp.custom'),
    };
  }

  String _modeLabel(AppI18n i18n, _VisualMemoryMode mode) {
    return switch (mode) {
      _VisualMemoryMode.positions => i18n.t(
        'inline.ui.pages.toolbox_human_tests_visual_memory_widgets.positions_bb6d32',
      ),
      _VisualMemoryMode.colorTargets => i18n.t(
        'inline.ui.pages.toolbox_human_tests_visual_memory_widgets.color_targets_124d6a',
      ),
      _VisualMemoryMode.targetColor => i18n.t(
        'inline.ui.pages.toolbox_human_tests_visual_memory_widgets.target_color_07c19b',
      ),
    };
  }

  String _paletteLabel(AppI18n i18n, _VisualMemoryPalette palette) {
    final spec = _paletteSpecs[palette]!;
    return spec.label(i18n);
  }

  String _colorName(AppI18n i18n, _VisualMemoryColorToken token) {
    return token.label(i18n);
  }

  String _targetPrompt(AppI18n i18n) {
    final token = _targetColorToken;
    if (!_usesTargetColorRule || token == null) {
      return _modeLabel(i18n, _mode);
    }
    return i18n.t(
      'inline.ui.pages.toolbox_human_tests_visual_memory.target_color_colorname_i18n_token_b194d9',
      params: <String, Object?>{'colorNameToken': _colorName(i18n, token)},
    );
  }

  String _stageHint(AppI18n i18n) {
    if (_gameOver) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_visual_memory.test_finished_your_report_is_ready_ac5414',
      );
    }
    if (_roundFailed) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_visual_memory.miss_limit_reached_one_life_lost_this_level_is_restartin_6c7e32',
      );
    }
    if (_showing) {
      if (_usesTargetColorRule && _targetColorToken != null) {
        final colorName = _colorName(i18n, _targetColorToken!);
        return i18n.t(
          'inline.ui.pages.toolbox_human_tests_visual_memory.memorize_every_colorname_cell_similar_colors_and_gray_ce_d73906',
          params: <String, Object?>{'colorName': colorName},
        );
      }
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_visual_memory.memorize_the_highlighted_targets_then_tap_them_back_cb0e94',
      );
    }
    if (_input) {
      if (_usesTargetColorRule && _targetColorToken != null) {
        final colorName = _colorName(i18n, _targetColorToken!);
        return i18n.t(
          'inline.ui.pages.toolbox_human_tests_visual_memory.now_tap_only_colorname_cells_similar_colors_gray_cells_a_514cb0',
          params: <String, Object?>{'colorName': colorName},
        );
      }
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_visual_memory.tap_the_highlighted_targets_misses_allowed_misslimit_d07a2c',
        params: <String, Object?>{'missLimit': _missLimit},
      );
    }
    return i18n.t(
      'inline.ui.pages.toolbox_human_tests_visual_memory.press_start_observe_the_targets_then_reproduce_them_afte_3074c8',
    );
  }

  void _applySetting(VoidCallback updater) {
    if (_roundBusy) {
      return;
    }
    _timer?.cancel();
    setState(() {
      updater();
      _resetState(keepSettings: true);
    });
  }

  void _resetState({required bool keepSettings}) {
    _roundToken += 1;
    _level = 1;
    _lives = _lifeLimit;
    _roundMistakes = 0;
    _activeGridSize = _plannedGridSize;
    _targets = <int>{};
    _picked = <int>{};
    _wrong = <int>{};
    _marks = <int, _VisualMemoryCellMark>{};
    _targetColorToken = null;
    _showing = false;
    _input = false;
    _gameOver = false;
    _roundFailed = false;
    _sessionStartedAt = null;
    _roundsStarted = 0;
    _completedRounds = 0;
    _failedRounds = 0;
    _bestLevel = 1;
    _totalTargetsShown = 0;
    _totalCorrectTaps = 0;
    _totalWrongTaps = 0;
    _colorWrongTaps = 0;
    _distractorWrongTaps = 0;
    _blankWrongTaps = 0;
    _roundResults.clear();
  }

  void _ensureSessionStarted() {
    _sessionStartedAt ??= DateTime.now();
  }

  void _recordRoundResult({required bool success}) {
    _roundResults.add(
      _VisualMemoryRoundResult(
        level: _level,
        gridSize: _activeGridSize,
        targets: _targets.length,
        mistakes: _roundMistakes,
        success: success,
        mode: _mode,
        targetColor: _targetColorToken,
      ),
    );
    if (success) {
      _completedRounds += 1;
    } else {
      _failedRounds += 1;
    }
  }

  _VisualMemoryReportData _buildReportData() {
    final startedAt = _sessionStartedAt;
    return _VisualMemoryReportData(
      roundsStarted: _roundsStarted,
      completedRounds: _completedRounds,
      failedRounds: _failedRounds,
      bestLevel: _bestLevel,
      correctTaps: _totalCorrectTaps,
      wrongTaps: _totalWrongTaps,
      colorWrongTaps: _colorWrongTaps,
      distractorWrongTaps: _distractorWrongTaps,
      blankWrongTaps: _blankWrongTaps,
      totalTargetsShown: _totalTargetsShown,
      duration: startedAt == null
          ? Duration.zero
          : DateTime.now().difference(startedAt),
      mode: _mode,
      difficulty: _difficulty,
      colorPressure: _colorPressure,
      rounds: List<_VisualMemoryRoundResult>.unmodifiable(_roundResults),
    );
  }

  void _showCompletionReport() {
    if (!mounted || _reportDialogOpen || _roundsStarted == 0) {
      return;
    }
    final reportData = _buildReportData();
    _reportDialogOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _reportDialogOpen = false;
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (_) =>
            _VisualMemoryReportDialog(data: reportData, accent: accent),
      );
      _reportDialogOpen = false;
    });
  }

  void _startRound() {
    if (_gameOver) {
      return;
    }
    _ensureSessionStarted();
    _timer?.cancel();
    final token = ++_roundToken;
    final gridSize = _plannedGridSize;
    final cellCount = gridSize * gridSize;
    final targetCount = _targetCountForGrid(gridSize);
    final cells = List<int>.generate(cellCount, (index) => index)
      ..shuffle(_random);
    var cursor = 0;
    final targetCells = cells.skip(cursor).take(targetCount).toSet();
    cursor += targetCells.length;
    final activePalette = _activePalette;
    final marks = <int, _VisualMemoryCellMark>{};
    _VisualMemoryColorToken? targetToken;

    if (_usesTargetColorRule) {
      final _VisualMemoryColorToken resolvedTargetToken = _sample(
        _random,
        activePalette,
      );
      targetToken = resolvedTargetToken;
      for (final cell in targetCells) {
        marks[cell] = _VisualMemoryCellMark(
          kind: _VisualMemoryMarkKind.target,
          color: resolvedTargetToken.color,
        );
      }
      final decoyCount = _decoyCountFor(cellCount - marks.length, targetCount);
      final decoyCells = cells.skip(cursor).take(decoyCount);
      cursor += decoyCount;
      final decoyColors = activePalette
          .where((token) => token.color != resolvedTargetToken.color)
          .toList(growable: false);
      for (final cell in decoyCells) {
        marks[cell] = _VisualMemoryCellMark(
          kind: _VisualMemoryMarkKind.decoy,
          color: _nearTargetDecoyColor(resolvedTargetToken.color, decoyColors),
        );
      }
    } else {
      for (final cell in targetCells) {
        final color = _mode == _VisualMemoryMode.colorTargets
            ? _sample(_random, activePalette).color
            : accent;
        marks[cell] = _VisualMemoryCellMark(
          kind: _VisualMemoryMarkKind.target,
          color: color,
        );
      }
    }

    final distractorCount = _distractorCountFor(cellCount - marks.length);
    final distractorCells = cells.skip(cursor).take(distractorCount);
    for (final cell in distractorCells) {
      marks[cell] = const _VisualMemoryCellMark(
        kind: _VisualMemoryMarkKind.distractor,
        color: distractorColor,
      );
    }

    setState(() {
      _activeGridSize = gridSize;
      _targets = targetCells;
      _picked = <int>{};
      _wrong = <int>{};
      _marks = marks;
      _targetColorToken = targetToken;
      _roundMistakes = 0;
      _roundsStarted += 1;
      _totalTargetsShown += targetCells.length;
      _bestLevel = math.max(_bestLevel, _level);
      _showing = true;
      _input = false;
      _roundFailed = false;
    });

    _timer = Timer(Duration(milliseconds: _observeMilliseconds), () {
      if (!mounted || token != _roundToken) {
        return;
      }
      setState(() {
        _showing = false;
        _input = true;
      });
    });
  }

  void _loseLife() {
    final remain = _lives - 1;
    _timer?.cancel();
    final token = ++_roundToken;
    setState(() {
      _recordRoundResult(success: false);
      _lives = remain;
      _input = false;
      _showing = true;
      _roundFailed = true;
      _gameOver = remain <= 0;
    });
    if (remain <= 0) {
      _showCompletionReport();
      return;
    }
    _timer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted || token != _roundToken) {
        return;
      }
      _startRound();
    });
  }

  void _tap(int index) {
    if (!_input || _gameOver) {
      return;
    }
    if (_targets.contains(index)) {
      if (_picked.contains(index)) {
        return;
      }
      setState(() {
        _picked.add(index);
        _totalCorrectTaps += 1;
      });
      if (_picked.length >= _targets.length) {
        setState(() {
          _recordRoundResult(success: true);
          _level += 1;
          _bestLevel = math.max(_bestLevel, _level);
          _input = false;
        });
        _startRound();
      }
      return;
    }
    if (_wrong.contains(index)) {
      return;
    }
    setState(() {
      _wrong.add(index);
      _roundMistakes += 1;
      _totalWrongTaps += 1;
      final mark = _marks[index];
      if (mark == null) {
        _blankWrongTaps += 1;
      } else if (mark.kind == _VisualMemoryMarkKind.distractor) {
        _distractorWrongTaps += 1;
      } else {
        _colorWrongTaps += 1;
      }
    });
    if (_roundMistakes >= _missLimit) {
      _loseLife();
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() => _resetState(keepSettings: true));
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final modeLabel = _modeLabel(i18n, _mode);
    final targetMetric = _targets.isEmpty
        ? _plannedTargetCount
        : _targets.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (i18n.t('toolbox.sound.pickup.level'), '$_level'),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_visual_memory.grid_39884f',
              ),
              '${_targets.isEmpty ? _plannedGridSize : _activeGridSize} x ${_targets.isEmpty ? _plannedGridSize : _activeGridSize}',
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_aim_widgets.targets_d13c96',
              ),
              '$targetMetric',
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_cognition.lives_1176de',
              ),
              '$_lives',
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_auditory.misses_bcc2a1',
              ),
              '$_roundMistakes/$_missLimit',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _HumanSettingsSection(
          title: i18n.t(
            'inline.ui.pages.toolbox_human_tests_visual_memory.visual_memory_settings_82d48a',
          ),
          subtitle: i18n.t(
            'inline.ui.pages.toolbox_human_tests_visual_memory.difficulty_mode_color_and_distractor_settings_apply_to_t_26d969',
          ),
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
                  _HumanPill(text: modeLabel, accent: accent),
                  if (_usesTargetColorRule && _targetColorToken != null)
                    _VisualMemoryColorPill(
                      text: _targetPrompt(i18n),
                      color: _targetColorToken!.color,
                    ),
                  _HumanPill(
                    text: i18n.t(
                      'inline.ui.pages.toolbox_human_tests_visual_memory.observemilliseconds_ms_view_b89008',
                      params: <String, Object?>{
                        'observeMilliseconds': _observeMilliseconds,
                      },
                    ),
                    accent: Theme.of(context).colorScheme.primary,
                  ),
                  if (_usesTargetColorRule)
                    _HumanPill(
                      text: _interferenceToneLabel(i18n, _colorPressure),
                      accent: Theme.of(context).colorScheme.tertiary,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: 1,
                child: _VisualMemoryGrid(
                  gridSize: _targets.isEmpty
                      ? _plannedGridSize
                      : _activeGridSize,
                  marks: _marks,
                  targets: _targets,
                  picked: _picked,
                  wrong: _wrong,
                  showing: _showing,
                  inputEnabled: _input,
                  onTap: _tap,
                ),
              ),
              const SizedBox(height: 12),
              _VisualMemoryLegend(
                i18n: i18n,
                showDistractor:
                    _distractorsEnabled ||
                    _marks.values.any(
                      (mark) => mark.kind == _VisualMemoryMarkKind.distractor,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                _stageHint(i18n),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  _HumanActionButton(
                    label: _targets.isEmpty
                        ? i18n.t('toolbox.breathing.start')
                        : i18n.t(
                            'inline.ui.pages.toolbox_human_tests_visual_memory.restart_level_4990e1',
                          ),
                    icon: Icons.play_arrow_rounded,
                    onPressed: _gameOver ? null : _startRound,
                  ),
                  OutlinedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: Text(i18n.t('appearanceReset')),
                  ),
                  if (_roundsStarted > 0)
                    OutlinedButton.icon(
                      onPressed: _showCompletionReport,
                      icon: const Icon(Icons.query_stats_rounded),
                      label: Text(
                        i18n.t(
                          'inline.ui.pages.toolbox_human_tests_aim.view_report_05b6eb',
                        ),
                      ),
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
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          i18n.t(
            'inline.ui.pages.toolbox_human_tests_visual_memory.difficulty_ladder_f95d81',
          ),
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _VisualMemoryDifficulty.values
              .map(
                (difficulty) => ChoiceChip(
                  label: Text(_difficultyLabel(i18n, difficulty)),
                  selected: _difficulty == difficulty,
                  onSelected: _roundBusy
                      ? null
                      : (_) => _applySetting(() {
                          _difficulty = difficulty;
                          _observeMilliseconds =
                              _difficultySpec.observeMilliseconds;
                        }),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 14),
        Text(
          i18n.t(
            'inline.ui.pages.toolbox_human_tests_visual_memory.memory_mode_6f72ba',
          ),
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _VisualMemoryMode.values
              .map(
                (mode) => ChoiceChip(
                  label: Text(_modeLabel(i18n, mode)),
                  selected: _mode == mode,
                  onSelected: _roundBusy
                      ? null
                      : (_) => _applySetting(() => _mode = mode),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 14),
        Text(
          i18n.t(
            'inline.ui.pages.toolbox_human_tests_visual_memory.color_theme_5b9eeb',
          ),
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _VisualMemoryPalette.values
              .map(
                (palette) => ChoiceChip(
                  avatar: _VisualMemoryPaletteDots(
                    colors: _paletteSpecs[palette]!.colors,
                  ),
                  label: Text(_paletteLabel(i18n, palette)),
                  selected: _palette == palette,
                  onSelected: _roundBusy
                      ? null
                      : (_) => _applySetting(() => _palette = palette),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 12),
        _VisualMemorySliderLabel(
          label: i18n.t(
            'inline.ui.pages.toolbox_human_tests_verbal_memory_view.view_time_2c724b',
          ),
          value: '$_observeMilliseconds ms',
        ),
        Slider(
          value: _observeMilliseconds.toDouble(),
          min: 700,
          max: 2500,
          divisions: 18,
          label: '$_observeMilliseconds ms',
          onChanged: _roundBusy
              ? null
              : (value) =>
                    _applySetting(() => _observeMilliseconds = value.round()),
        ),
        if (_mode != _VisualMemoryMode.positions) ...<Widget>[
          _VisualMemorySliderLabel(
            label: i18n.t(
              'inline.ui.pages.toolbox_human_tests_visual_memory.active_colors_620298',
            ),
            value: '$_colorCount',
          ),
          Slider(
            value: _colorCount.toDouble(),
            min: 3,
            max: 8,
            divisions: 5,
            label: '$_colorCount',
            onChanged: _roundBusy
                ? null
                : (value) => _applySetting(() => _colorCount = value.round()),
          ),
        ],
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: _distractorsEnabled,
          onChanged: _roundBusy
              ? null
              : (value) => _applySetting(() => _distractorsEnabled = value),
          title: Text(
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_visual_memory.distractor_cells_90e7ad',
            ),
          ),
          subtitle: Text(
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_visual_memory.adds_gray_non_target_cells_during_view_time_in_color_mod_f7357e',
            ),
          ),
        ),
        if (_distractorsEnabled) ...<Widget>[
          _VisualMemorySliderLabel(
            label: i18n.t(
              'inline.ui.pages.toolbox_human_tests_visual_memory.distractor_intensity_3d82c1',
            ),
            value: '$_distractorIntensity',
          ),
          Slider(
            value: _distractorIntensity.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            label: '$_distractorIntensity',
            onChanged: _roundBusy
                ? null
                : (value) =>
                      _applySetting(() => _distractorIntensity = value.round()),
          ),
        ],
        if (_difficulty == _VisualMemoryDifficulty.custom) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_visual_memory.custom_ladder_0d9870',
            ),
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          _VisualMemorySliderLabel(
            label: i18n.t(
              'inline.ui.pages.toolbox_human_tests_visual_memory.max_grid_edac72',
            ),
            value: '$_customMaxGridSize x $_customMaxGridSize',
          ),
          Slider(
            value: _customMaxGridSize.toDouble(),
            min: 4,
            max: _maxGridSize.toDouble(),
            divisions: 2,
            label: '$_customMaxGridSize',
            onChanged: _roundBusy
                ? null
                : (value) =>
                      _applySetting(() => _customMaxGridSize = value.round()),
          ),
          _VisualMemorySliderLabel(
            label: i18n.t(
              'inline.ui.pages.toolbox_human_tests_visual_memory.base_targets_79396f',
            ),
            value: '$_customBaseTargets',
          ),
          Slider(
            value: _customBaseTargets.toDouble(),
            min: 3,
            max: 18,
            divisions: 15,
            label: '$_customBaseTargets',
            onChanged: _roundBusy
                ? null
                : (value) =>
                      _applySetting(() => _customBaseTargets = value.round()),
          ),
          _VisualMemorySliderLabel(
            label: i18n.t(
              'inline.ui.pages.toolbox_human_tests_visual_memory.miss_limit_f8f56c',
            ),
            value: '$_customMissLimit',
          ),
          Slider(
            value: _customMissLimit.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: '$_customMissLimit',
            onChanged: _roundBusy
                ? null
                : (value) =>
                      _applySetting(() => _customMissLimit = value.round()),
          ),
          _VisualMemorySliderLabel(
            label: i18n.t(
              'inline.ui.pages.toolbox_human_tests_cognition.lives_1176de',
            ),
            value: '$_customLives',
          ),
          Slider(
            value: _customLives.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: '$_customLives',
            onChanged: _roundBusy
                ? null
                : (value) => _applySetting(() => _customLives = value.round()),
          ),
        ],
      ],
    );
  }
}
