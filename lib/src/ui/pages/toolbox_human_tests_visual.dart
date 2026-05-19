part of 'toolbox_human_tests.dart';

class ColorVisionTestPage extends StatelessWidget {
  const ColorVisionTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: pickUiText(
        i18n,
        zh: '色觉测试',
        en: 'Color vision',
        ja: 'Color vision',
        de: 'Color vision',
        fr: 'Vision des couleurs',
        es: 'Visión de color',
        ru: 'Цветовое зрение',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '支持经典找不同与混色匹配，记录不同色差和色相方向的识别表现。',
        en: 'Classic odd-tile and mixed-color matching with per-hue and color-difference analysis.',
        ja: '色相ごとの色差分析による古典的な奇数タイルと混合色のマッチング。',
        de: 'Classic odd-tile and mixed-color matching with per-hue and color-difference analysis.',
        fr: 'Classic impair-tile et mixte-couleur assorti avec la couleur-couleur-différence analyse.',
        es: 'Clásico extraño-til y mezcla-color coincide con el análisis de per-hue y color-diferencia.',
        ru: 'Классический нечетный и смешанный цвет, соответствующий анализу на оттенок и цветовую разницу.',
      ),
      accent: _ColorVisionCardState.accent,
      icon: Icons.palette_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：选择模式并点击目标色块',
        en: 'Next: choose a mode and tap the target color',
        ja: 'Next: choose a mode and tap the target color',
        de: 'Next: choose a mode and tap the target color',
        fr: 'Suivant : choisissez un mode et appuyez sur la couleur cible',
        es: 'Siguiente: elegir un modo y pulsar el color de destino',
        ru: 'Далее: выберите режим и нажмите целевой цвет',
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
            (
              pickUiText(
                i18n,
                zh: '等级',
                en: 'Level',
                ja: 'Level',
                de: 'Level',
                fr: 'Niveau',
                es: 'Nivel',
                ru: 'Уровень',
              ),
              '$_level',
            ),
            (
              pickUiText(
                i18n,
                zh: '生命',
                en: 'Lives',
                ja: 'Lives',
                de: 'Lives',
                fr: 'Vies',
                es: 'Vidas',
                ru: 'Жизни',
              ),
              _livesLabel(i18n),
            ),
            (
              pickUiText(
                i18n,
                zh: '网格',
                en: 'Grid',
                ja: 'Grid',
                de: 'Grid',
                fr: 'Grille',
                es: 'Grid',
                ru: 'Сетка',
              ),
              '${_currentGridSize}x$_currentGridSize',
            ),
            (
              pickUiText(
                i18n,
                zh: '正确率',
                en: 'Accuracy',
                ja: '精度',
                de: 'Accuracy',
                fr: 'Accuracy',
                es: 'Precisión',
                ru: 'точность',
              ),
              _rounds <= 0
                  ? '0%'
                  : '${((_correctRounds / _rounds) * 100).round()}%',
            ),
          ],
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
                    text: pickUiText(
                      i18n,
                      zh: '色差 ${(_currentDelta * 100).toStringAsFixed(1)}',
                      en: 'Delta ${(_currentDelta * 100).toStringAsFixed(1)}',
                      ja: 'Delta ${(_currentDelta * 100).toStringAsFixed(1)}',
                      de: 'Delta ${(_currentDelta * 100).toStringAsFixed(1)}',
                      fr: 'Delta ${(_currentDelta * 100).toStringAsFixed(1)}',
                      es: 'Delta',
                      ru: 'Дельта ${(_currentDelta * 100).toStringAsFixed(1)}',
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
                  pickUiText(
                    i18n,
                    zh: '测试已结束，可以查看报告或重置后再试。',
                    en: 'Test over. Review the report or reset to try again.',
                    ja: 'Test over. Review the report or reset to try again.',
                    de: 'Test over. Review the report or reset to try again.',
                    fr: 'Testez-le. Revoir le rapport ou réinitialiser pour essayer à nouveau.',
                    es: 'Prueba. Revise el informe o reajuste para intentarlo de nuevo.',
                    ru: 'Тест окончен. Просмотрите отчет или перезагрузите, чтобы попробовать еще раз.',
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
                    label: pickUiText(
                      i18n,
                      zh: '提示',
                      en: 'Hint',
                      ja: 'Hint',
                      de: 'Hint',
                      fr: 'Conseil',
                      es: 'Hint',
                      ru: 'подсказка',
                    ),
                    icon: Icons.tips_and_updates_rounded,
                    onPressed: _gameOver ? null : _showHint,
                  ),
                  OutlinedButton.icon(
                    onPressed: _finishNow,
                    icon: const Icon(Icons.analytics_rounded),
                    label: Text(
                      pickUiText(
                        i18n,
                        zh: '结束并分析',
                        en: 'End and analyze',
                        ja: 'End and analyze',
                        de: 'End and analyze',
                        fr: 'Terminer et analyser',
                        es: 'Fin y análisis',
                        ru: 'Конец и анализ',
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _rounds <= 0 ? null : _showCompletionReport,
                    icon: const Icon(Icons.query_stats_rounded),
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
                  OutlinedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.restart_alt_rounded),
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
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _HumanSettingsSection(
          title: pickUiText(
            i18n,
            zh: '色觉测试设置',
            en: 'Color vision settings',
            ja: 'カラービジョン設定',
            de: 'Color vision settings',
            fr: 'Paramètres de vision couleur',
            es: 'Ajustes de la visión de color',
            ru: 'Цветовое зрение',
          ),
          subtitle: pickUiText(
            i18n,
            zh: '模式、色系排除、生命和网格会立即重开当前测试',
            en: 'Mode, color filter, lives, and grid settings restart the current test',
            ja: 'Mode, color filter, lives, and grid settings restart the current test',
            de: 'Mode, color filter, lives, and grid settings restart the current test',
            fr: 'Mode, filtre couleur, vies et paramètres de grille redémarrent le test actuel',
            es: 'Modo, filtro de color, vidas y configuración de la cuadrícula reiniciar la prueba actual',
            ru: 'Режим, цветовой фильтр, жизнь и настройки сетки перезапускают текущий тест',
          ),
          initiallyExpanded: true,
          child: _buildSettings(context, i18n),
        ),
      ],
    );
  }

  Widget _buildSettings(BuildContext context, AppI18n i18n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
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
          pickUiText(
            i18n,
            zh: '色系排除',
            en: 'Color filter',
            ja: 'カラーフィルター',
            de: 'Color filter',
            fr: 'Filtre couleur',
            es: 'Filtro de color',
            ru: 'Цветной фильтр',
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
          pickUiText(
            i18n,
            zh: '最大生命',
            en: 'Maximum lives',
            ja: 'Maximum lives',
            de: 'Maximum lives',
            fr: 'Durée de vie maximale',
            es: 'Vidas máximas',
            ru: 'Максимум жизней',
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
          label: pickUiText(
            i18n,
            zh: '初始网格',
            en: 'Initial grid',
            ja: 'Initial grid',
            de: 'Initial grid',
            fr: 'Grille initiale',
            es: 'Cuadrícula inicial',
            ru: 'Начальная сетка',
          ),
          valueText: '${_initialGrid}x$_initialGrid',
          value: _initialGrid.toDouble(),
          min: _minGridSize.toDouble(),
          max: _maxGridSize.toDouble(),
          divisions: _maxGridSize - _minGridSize,
          onChanged: _setInitialGrid,
        ),
        _ColorVisionSettingSlider(
          label: pickUiText(
            i18n,
            zh: '最大网格',
            en: 'Maximum grid',
            ja: 'Maximum grid',
            de: 'Maximum grid',
            fr: 'Grille maximale',
            es: 'Cuadrícula máxima',
            ru: 'Максимальная сетка',
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
            label: pickUiText(
              i18n,
              zh: '目标同色块',
              en: 'Matching targets',
              ja: 'Matching targets',
              de: 'Matching targets',
              fr: 'Objectifs correspondants',
              es: 'Objetivos de coincidencia',
              ru: 'Соответствие целей',
            ),
            valueText: _randomTargetCount
                ? pickUiText(
                    i18n,
                    zh: '随机 1-$_sameTargetCount',
                    en: 'Random 1-$_sameTargetCount',
                    ja: 'Random 1-$_sameTargetCount',
                    de: 'Random 1-$_sameTargetCount',
                    fr: 'Aléatoire 1-$_sameTargetCount',
                    es: 'Aleatorio 1-Seguidov0/',
                    ru: 'Случайность 1-$_sameTargetCount',
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
              pickUiText(
                i18n,
                zh: '目标数量随机',
                en: 'Random target count',
                ja: 'Random target count',
                de: 'Random target count',
                fr: 'Nombre de cibles aléatoires',
                es: 'Conteo de objetivos aleatorios',
                ru: 'Случайное количество целей',
              ),
            ),
            subtitle: Text(
              pickUiText(
                i18n,
                zh: '每轮在 1 到设置上限之间抽取同色目标数。',
                en: 'Each round samples the matching target count between 1 and the configured cap.',
                ja: 'Each round samples the matching target count between 1 and the configured cap.',
                de: 'Each round samples the matching target count between 1 and the configured cap.',
                fr: 'Chaque ronde échantillonne le nombre de cibles correspondant entre 1 et le bouchon configuré.',
                es: 'Cada ronda muestra el objetivo que coincide entre 1 y la tapa configurada.',
                ru: 'Каждый раунд отбирает совпадающее количество целей между 1 и сконфигурированной шапкой.',
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
      return pickUiText(
        i18n,
        zh: '找出唯一不同的色块。提示会给目标加边框，并计入最终报告。',
        en: 'Find the only different tile. Hints add a target border and are counted in the report.',
        ja: 'Find the only different tile. Hints add a target border and are counted in the report.',
        de: 'Find the only different tile. Hints add a target border and are counted in the report.',
        fr: 'Trouvez la seule tuile différente. Les conseils ajoutent une frontière cible et sont comptés dans le rapport.',
        es: 'Encuentra la única ficha diferente. Las hormigas agregan una frontera objetivo y se cuentan en el informe.',
        ru: 'Найдите только разные плитки. Подсказки добавляют целевую границу и учитываются в отчете.',
      );
    }
    return pickUiText(
      i18n,
      zh: '先看上方目标色，再点击网格中与它完全相同的色块。',
      en: 'Match the target swatch above, then tap a tile with the exact same color.',
      ja: 'Match the target swatch above, then tap a tile with the exact same color.',
      de: 'Match the target swatch above, then tap a tile with the exact same color.',
      fr: 'Correspondez à la cible swatch ci-dessus, puis appuyez sur une tuile de la même couleur exacte.',
      es: 'Coincide con el objetivo swatch arriba, luego toque una baldosa con el mismo color exacto.',
      ru: 'Сопоставьте целевой образец выше, а затем нажмите на плитку того же цвета.',
    );
  }

  String _modeLabel(AppI18n i18n, _ColorVisionMode mode) {
    return switch (mode) {
      _ColorVisionMode.oddTile => pickUiText(
        i18n,
        zh: '经典找不同',
        en: 'Odd tile',
        ja: 'Odd tile',
        de: 'Odd tile',
        fr: 'Carreaux bizarres',
        es: 'Odd Tile',
        ru: 'Странная плитка',
      ),
      _ColorVisionMode.mixedMatch => pickUiText(
        i18n,
        zh: '混色匹配',
        en: 'Mixed match',
        ja: 'Mixed match',
        de: 'Mixed match',
        fr: 'Match mixte',
        es: 'Combinación mixta',
        ru: 'Смешанный матч',
      ),
    };
  }

  String _filterLabel(AppI18n i18n, _ColorVisionFilter filter) {
    return switch (filter) {
      _ColorVisionFilter.full => pickUiText(
        i18n,
        zh: '完整色系',
        en: 'Full spectrum',
        ja: 'Full spectrum',
        de: 'Full spectrum',
        fr: 'Plein spectre',
        es: 'espectro completo',
        ru: 'Полный спектр',
      ),
      _ColorVisionFilter.avoidRedGreen => pickUiText(
        i18n,
        zh: '排除红绿',
        en: 'Avoid red-green',
        ja: '赤緑色を避ける',
        de: 'Avoid red-green',
        fr: 'Évitez le rouge-vert',
        es: 'Evite el verde rojo',
        ru: 'Избегайте красно-зеленых',
      ),
      _ColorVisionFilter.avoidBlueYellow => pickUiText(
        i18n,
        zh: '排除蓝黄',
        en: 'Avoid blue-yellow',
        ja: '青黄色を避ける',
        de: 'Avoid blue-yellow',
        fr: 'Éviter les jaunes bleus',
        es: 'Evite el amarillo azul',
        ru: 'Избегайте сине-желтого',
      ),
      _ColorVisionFilter.grayscale => pickUiText(
        i18n,
        zh: '低饱和',
        en: 'Low saturation',
        ja: 'Low saturation',
        de: 'Low saturation',
        fr: 'Basse saturation',
        es: 'Baja saturación',
        ru: 'Низкая насыщенность',
      ),
    };
  }

  String _livesPresetLabel(AppI18n i18n, _ColorVisionLivesPreset preset) {
    return switch (preset) {
      _ColorVisionLivesPreset.one => pickUiText(
        i18n,
        zh: '1 次',
        en: '1 life',
        ja: '1ライフ',
        de: '1 life',
        fr: '1 life',
        es: '1 vida',
        ru: '1 жизнь',
      ),
      _ColorVisionLivesPreset.three => pickUiText(
        i18n,
        zh: '3 次',
        en: '3 lives',
        ja: 'ライフを3',
        de: '3 lives',
        fr: '3 lives',
        es: '3 vidas',
        ru: '3 жизни',
      ),
      _ColorVisionLivesPreset.five => pickUiText(
        i18n,
        zh: '5 次',
        en: '5 lives',
        ja: '5人暮らし',
        de: '5 lives',
        fr: '5 lives',
        es: '5 vidas',
        ru: '5 жизней',
      ),
      _ColorVisionLivesPreset.unlimited => pickUiText(
        i18n,
        zh: '无限',
        en: 'Unlimited',
        ja: 'Unlimited',
        de: 'Unlimited',
        fr: 'Illimité',
        es: 'Ilimitados',
        ru: 'неограниченный',
      ),
    };
  }

  String _livesLabel(AppI18n i18n) {
    if (_unlimitedLives) {
      return pickUiText(
        i18n,
        zh: '无限',
        en: 'Unlimited',
        ja: 'Unlimited',
        de: 'Unlimited',
        fr: 'Illimité',
        es: 'Ilimitados',
        ru: 'неограниченный',
      );
    }
    return '$_lives';
  }

  String _hueBandLabel(AppI18n i18n, _ColorVisionHueBand band) {
    return switch (band) {
      _ColorVisionHueBand.red => pickUiText(
        i18n,
        zh: '红色区',
        en: 'Red',
        ja: 'Red',
        de: 'Red',
        fr: 'Rouge',
        es: 'Rojo',
        ru: 'красный',
      ),
      _ColorVisionHueBand.orange => pickUiText(
        i18n,
        zh: '橙色区',
        en: 'Orange',
        ja: 'Orange',
        de: 'Orange',
        fr: 'Orange',
        es: 'Orange',
        ru: 'Оранжевый',
      ),
      _ColorVisionHueBand.yellow => pickUiText(
        i18n,
        zh: '黄色区',
        en: 'Yellow',
        ja: 'Yellow',
        de: 'Yellow',
        fr: 'Jaune',
        es: 'Amarillo',
        ru: 'желтый',
      ),
      _ColorVisionHueBand.green => pickUiText(
        i18n,
        zh: '绿色区',
        en: 'Green',
        ja: 'Green',
        de: 'Green',
        fr: 'Vert',
        es: 'Verde',
        ru: 'зеленый',
      ),
      _ColorVisionHueBand.cyan => pickUiText(
        i18n,
        zh: '青色区',
        en: 'Cyan',
        ja: 'Cyan',
        de: 'Cyan',
        fr: 'Cyan',
        es: 'Cyan',
        ru: 'Циан',
      ),
      _ColorVisionHueBand.blue => pickUiText(
        i18n,
        zh: '蓝色区',
        en: 'Blue',
        ja: '青',
        de: 'Blue',
        fr: 'Bleu',
        es: 'Azul',
        ru: 'голубой',
      ),
      _ColorVisionHueBand.purple => pickUiText(
        i18n,
        zh: '紫色区',
        en: 'Purple',
        ja: 'Purple',
        de: 'Purple',
        fr: 'Pourpre',
        es: 'Púrpura',
        ru: 'фиолетовый',
      ),
    };
  }

  String _axisLabel(AppI18n i18n, _ColorVisionDeltaAxis axis) {
    return switch (axis) {
      _ColorVisionDeltaAxis.hue => pickUiText(
        i18n,
        zh: '色相差',
        en: 'Hue shift',
        ja: 'Hue shift',
        de: 'Hue shift',
        fr: 'Groupe Hue',
        es: 'Cambio de rumbo',
        ru: 'Смена',
      ),
      _ColorVisionDeltaAxis.saturation => pickUiText(
        i18n,
        zh: '饱和度差',
        en: 'Saturation shift',
        ja: 'Saturation shift',
        de: 'Saturation shift',
        fr: 'Changement de saturation',
        es: 'Cambio de saturación',
        ru: 'Сдвиг насыщения',
      ),
      _ColorVisionDeltaAxis.lightness => pickUiText(
        i18n,
        zh: '明度差',
        en: 'Lightness shift',
        ja: 'Lightness shift',
        de: 'Lightness shift',
        fr: 'Changement de légèreté',
        es: 'Cambio de iluminación',
        ru: 'Сдвиг света',
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
