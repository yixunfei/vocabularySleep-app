part of 'toolbox_human_tests.dart';

class ChimpTestPage extends StatelessWidget {
  const ChimpTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: pickUiText(
        i18n,
        zh: '黑猩猩测试',
        en: 'Chimp test',
        ja: 'CHIMP TEST',
        de: 'Chimp test',
        fr: 'Essai de chimie',
        es: 'Prueba de chimpancé',
        ru: 'шимпанзе',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '保留经典数字模式，并新增顺序数字与颜色顺序模式，支持表格大小、答案辅助与统计报告。',
        en: 'Includes classic, sequential-number, and color-sequence modes with board size, answer assists, and reports.',
        ja: 'Includes classic, sequential-number, and color-sequence modes with board size, answer assists, and reports.',
        de: 'Includes classic, sequential-number, and color-sequence modes with board size, answer assists, and reports.',
        fr: 'Inclut les modes classiques, séquentiels et séquentielle avec la taille du tableau, les aides-réponses et les rapports.',
        es: 'Incluye modos clásicos, número secuencial y secuencia de color con tamaño de la tabla, ayudas de respuesta e informes.',
        ru: 'Включает классические режимы последовательного числа и цветовой последовательности с размером платы, ассистами ответов и отчетами.',
      ),
      accent: const Color(0xFF6C8D42),
      icon: Icons.grid_view_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：播放结束后按顺序点击目标',
        en: 'Next: replay the shown order by tapping targets',
        ja: 'Next: replay the shown order by tapping targets',
        de: 'Next: replay the shown order by tapping targets',
        fr: 'Suivant : rejouer l\'ordre affiché en tapant des cibles',
        es: 'Siguiente: volver a reproducir el orden mostrado mediante el uso de objetivos',
        ru: 'Далее: переиграйте показанный порядок, нажав на цели',
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
  const _ChimpColorToken({
    required this.color,
    required this.zh,
    required this.en,
    required this.ja,
    required this.de,
    required this.fr,
    required this.es,
    required this.ru,
  });

  final Color color;
  final String zh;
  final String en;
  final String ja;
  final String de;
  final String fr;
  final String es;
  final String ru;

  String label(AppI18n i18n) =>
      pickUiText(i18n, zh: zh, en: en, ja: ja, de: de, fr: fr, es: es, ru: ru);
}

class _ChimpTestCardState extends State<_ChimpTestCard> {
  static const int _initialLevel = 4;
  static const int _minGridSize = 4;
  static const int _maxGridSize = 6;
  static const Color _accent = Color(0xFF6C8D42);
  static const List<_ChimpColorToken> _colorPalette = <_ChimpColorToken>[
    _ChimpColorToken(
      color: Color(0xFFE86D6D),
      zh: '红色',
      en: 'Red',
      ja: '赤',
      de: 'Rot',
      fr: 'Rouge',
      es: 'Rojo',
      ru: 'Красный',
    ),
    _ChimpColorToken(
      color: Color(0xFF5AA7E8),
      zh: '蓝色',
      en: 'Blue',
      ja: '青',
      de: 'Blau',
      fr: 'Bleu',
      es: 'Azul',
      ru: 'Синий',
    ),
    _ChimpColorToken(
      color: Color(0xFF69B97E),
      zh: '绿色',
      en: 'Green',
      ja: '緑',
      de: 'Grün',
      fr: 'Vert',
      es: 'Verde',
      ru: 'Зеленый',
    ),
    _ChimpColorToken(
      color: Color(0xFFE8B45A),
      zh: '黄色',
      en: 'Yellow',
      ja: '黄色',
      de: 'Gelb',
      fr: 'Jaune',
      es: 'Amarillo',
      ru: 'Желтый',
    ),
    _ChimpColorToken(
      color: Color(0xFFC283E6),
      zh: '紫色',
      en: 'Purple',
      ja: '紫',
      de: 'Violett',
      fr: 'Violet',
      es: 'Morado',
      ru: 'Фиолетовый',
    ),
    _ChimpColorToken(
      color: Color(0xFF58B5A8),
      zh: '青色',
      en: 'Cyan',
      ja: 'シアン',
      de: 'Türkis',
      fr: 'Cyan',
      es: 'Cian',
      ru: 'Бирюзовый',
    ),
    _ChimpColorToken(
      color: Color(0xFFE69252),
      zh: '橙色',
      en: 'Orange',
      ja: 'オレンジ',
      de: 'Orange',
      fr: 'Orange',
      es: 'Naranja',
      ru: 'Оранжевый',
    ),
    _ChimpColorToken(
      color: Color(0xFF8AA0E8),
      zh: '靛蓝',
      en: 'Indigo',
      ja: 'インディゴ',
      de: 'Indigo',
      fr: 'Indigo',
      es: 'Índigo',
      ru: 'Индиго',
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
      _ChimpMode.classic => pickUiText(
        i18n,
        zh: '经典模式',
        en: 'Classic mode',
        ja: 'クラシックモード',
        de: 'Classic mode',
        fr: 'Mode classique',
        es: 'Modo clásico',
        ru: 'Классический режим',
      ),
      _ChimpMode.sequential => pickUiText(
        i18n,
        zh: '顺序数字模式',
        en: 'Sequential number mode',
        ja: 'Sequential number mode',
        de: 'Sequential number mode',
        fr: 'Mode numéro séquentiel',
        es: 'Modo de número secuencial',
        ru: 'Режим последовательного числа',
      ),
      _ChimpMode.colorSequence => pickUiText(
        i18n,
        zh: '颜色顺序模式',
        en: 'Color sequence mode',
        ja: 'カラーシーケンスモードカラー',
        de: 'Color sequence mode',
        fr: 'Mode séquence couleur',
        es: 'Modo de secuencia de color',
        ru: 'Режим цветовой последовательности',
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
    return pickUiText(
      i18n,
      zh: '目标颜色：$colorName，请按顺序点击 $sequenceLabel',
      en: 'Target color: $colorName. Tap $sequenceLabel in order.',
      ja: 'Target color: $colorName. Tap $sequenceLabel in order.',
      de: 'Target color: $colorName. Tap $sequenceLabel in order.',
      fr: 'Couleur cible : $colorName. Appuyez sur $sequenceLabel dans l\'ordre.',
      es: 'Color de blanco: <v0/ título. Toque en orden.',
      ru: 'Цвет цели: $colorName. Нажмите $sequenceLabel в порядке.',
    );
  }

  String _statusText(AppI18n i18n) {
    if (_showingSequence) {
      return _mode == _ChimpMode.colorSequence
          ? pickUiText(
              i18n,
              zh: '依次显示：${_colorSequenceSummary(i18n)}',
              en: 'Showing sequence: ${_colorSequenceSummary(i18n)}',
              ja: 'Showing sequence: ${_colorSequenceSummary(i18n)}',
              de: 'Showing sequence: ${_colorSequenceSummary(i18n)}',
              fr: 'Affichage de la séquence : ${_colorSequenceSummary(i18n)}',
              es: 'Visualización de la secuencia:',
              ru: 'Показ последовательности: ${_colorSequenceSummary(i18n)}',
            )
          : pickUiText(
              i18n,
              zh: '正在按顺序播放，请记住位置',
              en: 'Playing in order, memorize positions',
              ja: 'Playing in order, memorize positions',
              de: 'Playing in order, memorize positions',
              fr: 'Jouer dans l\'ordre, mémoriser les positions',
              es: 'Jugar en orden, memorizar posiciones',
              ru: 'Играть по порядку, запоминать позиции',
            );
    }
    if (_failed) {
      return pickUiText(
        i18n,
        zh: '顺序错误，本组已结束。',
        en: 'Wrong order. This set has ended.',
        ja: 'Wrong order. This set has ended.',
        de: 'Wrong order. This set has ended.',
        fr: 'Mauvais ordre. Cet ensemble est terminé.',
        es: 'Orden incorrecta. Este set ha terminado.',
        ru: 'Неправильный приказ. Этот набор закончился.',
      );
    }
    if (_complete) {
      return _sessionEnded
          ? pickUiText(
              i18n,
              zh: '完成上限目标，本组已结算。',
              en: 'Target cap cleared. This set is complete.',
              ja: 'Target cap cleared. This set is complete.',
              de: 'Target cap cleared. This set is complete.',
              fr: 'La cible est dégagée. Cet ensemble est terminé.',
              es: 'Gorra de blanco. Este set está completo.',
              ru: 'Цель снята. Этот набор завершен.',
            )
          : pickUiText(
              i18n,
              zh: '完成，本轮目标数量已提升。',
              en: 'Complete. Target count increased.',
              ja: '完了しました。ターゲット数が増加',
              de: 'Complete. Target count increased.',
              fr: 'Complète. Le nombre de cibles a augmenté.',
              es: 'Completa. El recuento de objetivos aumentó.',
              ru: 'Полный. Количество целей увеличилось.',
            );
    }
    if (_showNextHint && _nextExpectedCell != null) {
      return pickUiText(
        i18n,
        zh: '提示：下一格已用描边标出。',
        en: 'Hint: the next cell is outlined.',
        ja: 'Hint: the next cell is outlined.',
        de: 'Hint: the next cell is outlined.',
        fr: 'Conseil : la cellule suivante est décrite.',
        es: 'Hint: se describe la siguiente celda.',
        ru: 'Подсказка: очерчена следующая ячейка.',
      );
    }
    if (_mode == _ChimpMode.colorSequence && _positions.isNotEmpty) {
      return _targetHint(i18n);
    }
    return pickUiText(
      i18n,
      zh: '点击开始后按顺序完成目标。',
      en: 'Press Start, then finish targets in order.',
      ja: 'Press Start, then finish targets in order.',
      de: 'Press Start, then finish targets in order.',
      fr: 'Appuyez sur Démarrer, puis terminez les cibles en ordre.',
      es: 'Presione Inicio, luego termine objetivos en orden.',
      ru: 'Нажмите «Пуск», затем завершите цели по порядку.',
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
              _modeLabel(i18n, _mode),
            ),
            (
              pickUiText(
                i18n,
                zh: '目标数',
                en: 'Targets',
                ja: 'Targets',
                de: 'Targets',
                fr: 'Objectifs',
                es: 'Metas',
                ru: 'Цели',
              ),
              '$_targetCount',
            ),
            (
              pickUiText(
                i18n,
                zh: '表格',
                en: 'Board',
                ja: 'ボード',
                de: 'Board',
                fr: 'Conseil',
                es: 'Junta',
                ru: 'Совет',
              ),
              '$_gridSize x $_gridSize',
            ),
            (
              pickUiText(
                i18n,
                zh: '下一个',
                en: 'Next',
                ja: 'Next',
                de: 'Next',
                fr: 'Suivant',
                es: 'Siguiente',
                ru: 'Следующий',
              ),
              _positions.isEmpty || _complete
                  ? '-'
                  : '$_next/${math.max(1, _targetCount)}',
            ),
            (
              pickUiText(
                i18n,
                zh: '最佳',
                en: 'Best',
                ja: 'ベスト',
                de: 'Best',
                fr: 'Meilleur',
                es: 'Mejor',
                ru: 'Лучший',
              ),
              '$_bestCompletedTargets',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _HumanPanel(
          child: Column(
            children: <Widget>[
              _HumanSettingsSection(
                title: pickUiText(
                  i18n,
                  zh: '设置项',
                  en: 'Settings',
                  ja: 'Settings',
                  de: 'Settings',
                  fr: 'Paramètres',
                  es: 'Ajustes',
                  ru: 'Настройки',
                ),
                subtitle: pickUiText(
                  i18n,
                  zh: '模式、表格大小、难度上限与辅助提示',
                  en: 'Mode, board size, difficulty cap, and assists',
                  ja: 'Mode, board size, difficulty cap, and assists',
                  de: 'Mode, board size, difficulty cap, and assists',
                  fr: 'Mode, taille de la planche, bouchon de difficulté et aides',
                  es: 'Modo, tamaño de la tabla, tapa de dificultad, y ayuda',
                  ru: 'Режим, размер платы, кепка сложности и ассисты',
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
                      pickUiText(
                        i18n,
                        zh: '最大表格大小',
                        en: 'Max board size',
                        ja: 'Max board size',
                        de: 'Max board size',
                        fr: 'Taille maximale du tableau',
                        es: 'Tamaño máximo de la tabla',
                        ru: 'Максимальный размер платы',
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
                      pickUiText(
                        i18n,
                        zh: '本组最大目标数',
                        en: 'Set target cap',
                        ja: 'Set target cap',
                        de: 'Set target cap',
                        fr: 'Définir le plafond cible',
                        es: 'Set target cap',
                        ru: 'Установить целевой предел',
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
                        pickUiText(
                          i18n,
                          zh: '数字/颜色切换速度',
                          en: 'Number/color switch speed',
                          ja: 'Number/color switch speed',
                          de: 'Number/color switch speed',
                          fr: 'Vitesse du commutateur couleur/nombre',
                          es: 'Velocidad de conmutación número/color',
                          ru: 'Скорость цветового переключения',
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
                        pickUiText(
                          i18n,
                          zh: '颜色数量',
                          en: 'Color count',
                          ja: 'カラーカウント',
                          de: 'Color count',
                          fr: 'Nombre de couleurs',
                          es: 'Conteo de color',
                          ru: 'Количество цветов',
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
                        pickUiText(
                          i18n,
                          zh: '显示答案',
                          en: 'Show answer',
                          ja: 'Show answer',
                          de: 'Show answer',
                          fr: 'Afficher la réponse',
                          es: 'Respuesta del programa',
                          ru: 'Показать ответ',
                        ),
                      ),
                      subtitle: Text(
                        pickUiText(
                          i18n,
                          zh: '在输入阶段保留数字、颜色或目标位置。',
                          en: 'Keep numbers, colors, or target positions visible during input.',
                          ja: 'Keep numbers, colors, or target positions visible during input.',
                          de: 'Keep numbers, colors, or target positions visible during input.',
                          fr: 'Gardez les nombres, les couleurs ou les positions cibles visibles lors de l\'entrée.',
                          es: 'Mantenga los números, colores o posiciones de destino visibles durante la entrada.',
                          ru: 'Держите цифры, цвета или целевые позиции видимыми во время ввода.',
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
                        pickUiText(
                          i18n,
                          zh: '下一步提示',
                          en: 'Next-step hint',
                          ja: 'Next-step hint',
                          de: 'Next-step hint',
                          fr: 'Conseil de la prochaine étape',
                          es: 'Insinuación del siguiente paso',
                          ru: 'Следующий шаг намек',
                        ),
                      ),
                      subtitle: Text(
                        pickUiText(
                          i18n,
                          zh: '默认关闭。用轻描边提示下一次应点击的位置。',
                          en: 'Off by default. Outline the next expected cell.',
                          ja: 'Off by default. Outline the next expected cell.',
                          de: 'Off by default. Outline the next expected cell.',
                          fr: 'Arrêt par défaut. Décrivez la prochaine cellule attendue.',
                          es: 'Por defecto. Establezca la siguiente celda esperada.',
                          ru: 'По умолчанию. Опишите следующую ожидаемую ячейку.',
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
                        pickUiText(
                          i18n,
                          zh: '一次错误保护',
                          en: 'One-mistake rescue',
                          ja: 'One-mistake rescue',
                          de: 'One-mistake rescue',
                          fr: 'Une erreur de sauvetage',
                          es: 'Rescate de un solo golpe',
                          ru: 'Спасение с одной ошибкой',
                        ),
                      ),
                      subtitle: Text(
                        pickUiText(
                          i18n,
                          zh: '默认关闭。每轮第一次点错只警告，不立即结束。',
                          en: 'Off by default. The first wrong tap warns instead of ending the round.',
                          ja: 'Off by default. The first wrong tap warns instead of ending the round.',
                          de: 'Off by default. The first wrong tap warns instead of ending the round.',
                          fr: 'Arrêt par défaut. Le premier mauvais robinet avertit au lieu de terminer la ronde.',
                          es: 'Por defecto. El primer golpe equivocado advierte en lugar de terminar la ronda.',
                          ru: 'По умолчанию. Первый неправильный кран предупреждает вместо того, чтобы заканчивать раунд.',
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
                        pickUiText(
                          i18n,
                          zh: '完成后弹出报告',
                          en: 'Auto report',
                          ja: '自動レポート',
                          de: 'Auto report',
                          fr: 'Rapport automatique',
                          es: 'Informe automático',
                          ru: 'Автоотчет',
                        ),
                      ),
                      subtitle: Text(
                        pickUiText(
                          i18n,
                          zh: '测试结束后显示统计分析报告。',
                          en: 'Show the statistical report when the test ends.',
                          ja: 'Show the statistical report when the test ends.',
                          de: 'Show the statistical report when the test ends.',
                          fr: 'Afficher le rapport statistique à la fin du test.',
                          es: 'Mostrar el informe estadístico cuando termine el examen.',
                          ru: 'Показать статистический отчет, когда тест заканчивается.',
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
                        ? pickUiText(
                            i18n,
                            zh: '开始',
                            en: 'Start',
                            ja: 'Start',
                            de: 'Start',
                            fr: 'Démarrer',
                            es: 'Comienzo',
                            ru: 'Начинать',
                          )
                        : pickUiText(
                            i18n,
                            zh: '下一轮',
                            en: 'Next round',
                            ja: 'Next round',
                            de: 'Next round',
                            fr: 'Prochain tour',
                            es: 'Siguiente ronda',
                            ru: 'Следующий раунд',
                          ),
                    icon: Icons.play_arrow_rounded,
                    onPressed: _showingSequence ? null : _startRound,
                  ),
                  OutlinedButton.icon(
                    onPressed: _resetSession,
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
                  OutlinedButton.icon(
                    onPressed: _attemptedRounds == 0 || _reportDialogOpen
                        ? null
                        : () => _showCompletionReport(
                            success: _sessionEnded && !_failed,
                          ),
                    icon: const Icon(Icons.analytics_rounded),
                    label: Text(
                      pickUiText(
                        i18n,
                        zh: '报告',
                        en: 'Report',
                        ja: 'Report',
                        de: 'Report',
                        fr: 'Rapport annuel',
                        es: 'Informe',
                        ru: 'Доклад',
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
        pickUiText(
          i18n,
          zh: '黑猩猩测试统计报告',
          en: 'Chimp test report',
          ja: 'CHIMP TEST REPORT',
          de: 'Chimp test report',
          fr: 'Procès-verbal d\'essai du pompe',
          es: 'Informe de prueba de chimpancés',
          ru: 'Отчет об испытаниях шимпанзе',
        ),
      ),
      accent: accent,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (
              pickUiText(
                i18n,
                zh: '结论',
                en: 'Result',
                ja: 'Result',
                de: 'Result',
                fr: 'Résultat',
                es: 'Resultado',
                ru: 'Результат',
              ),
              success
                  ? pickUiText(
                      i18n,
                      zh: '完成',
                      en: 'Cleared',
                      ja: 'クリア済み',
                      de: 'Cleared',
                      fr: 'Effacé',
                      es: 'Despejado',
                      ru: 'очищенный',
                    )
                  : pickUiText(
                      i18n,
                      zh: '中断',
                      en: 'Stopped',
                      ja: 'Stopped',
                      de: 'Stopped',
                      fr: 'Arrêts',
                      es: 'Detenido',
                      ru: 'остановлен',
                    ),
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
              modeLabel,
            ),
            (
              pickUiText(
                i18n,
                zh: '表格',
                en: 'Board',
                ja: 'ボード',
                de: 'Board',
                fr: 'Conseil',
                es: 'Junta',
                ru: 'Совет',
              ),
              '$gridSize x $gridSize',
            ),
            (
              pickUiText(
                i18n,
                zh: '完成轮次',
                en: 'Rounds',
                ja: 'Rounds',
                de: 'Rounds',
                fr: 'Rondes',
                es: 'Rondas',
                ru: 'Круги',
              ),
              '$completedRounds/$attemptedRounds',
            ),
            (
              pickUiText(
                i18n,
                zh: '失败轮次',
                en: 'Failed',
                ja: 'Failed',
                de: 'Failed',
                fr: 'Échec',
                es: 'Failed',
                ru: 'неудачник',
              ),
              '$failedRounds',
            ),
            (
              pickUiText(
                i18n,
                zh: '最佳目标',
                en: 'Best targets',
                ja: 'ベストターゲット',
                de: 'Best targets',
                fr: 'Meilleures cibles',
                es: 'Mejores objetivos',
                ru: 'Лучшие цели',
              ),
              '$bestCompletedTargets/$maxTargetCount',
            ),
            (
              pickUiText(
                i18n,
                zh: '准确率',
                en: 'Accuracy',
                ja: '精度',
                de: 'Accuracy',
                fr: 'Accuracy',
                es: 'Precisión',
                ru: 'точность',
              ),
              '${accuracy.round()}%',
            ),
            (
              pickUiText(
                i18n,
                zh: '错误',
                en: 'Mistakes',
                ja: 'Mistakes',
                de: 'Mistakes',
                fr: 'Erreurs',
                es: 'Errores',
                ru: 'Ошибки',
              ),
              '$mistakes',
            ),
            (
              pickUiText(
                i18n,
                zh: '平均用时',
                en: 'Avg time',
                ja: '時間平均',
                de: 'Avg time',
                fr: 'Avg temps',
                es: 'Tiempo de entrada',
                ru: 'Время авг',
              ),
              averageDuration == null
                  ? '-'
                  : _formatSeconds(averageDuration.inMilliseconds / 1000),
            ),
            (
              pickUiText(
                i18n,
                zh: '最快用时',
                en: 'Best time',
                ja: 'ベストタイム',
                de: 'Best time',
                fr: 'Meilleur moment',
                es: 'El mejor tiempo',
                ru: 'Лучшее время',
              ),
              bestDuration == null ? '-' : _formatSeconds(bestDuration / 1000),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _ChimpReportBlock(
          title: pickUiText(
            i18n,
            zh: '分析',
            en: 'Analysis',
            ja: '分析',
            de: 'Analysis',
            fr: 'Analyse',
            es: 'Análisis',
            ru: 'Анализ',
          ),
          body: analysis,
          accent: accent,
        ),
        const SizedBox(height: 10),
        _ChimpReportBlock(
          title: pickUiText(
            i18n,
            zh: '辅助状态',
            en: 'Assists',
            ja: 'アシスト',
            de: 'Hilfen',
            fr: 'Aides',
            es: 'Ayudas',
            ru: 'Подсказки',
          ),
          body: assisted
              ? pickUiText(
                  i18n,
                  zh: '本组开启了辅助：${_enabledAssistLabels(i18n).join(' / ')}。报告用于训练反馈，不宜和纯净成绩直接比较。',
                  en: 'Assists enabled: ${_enabledAssistLabels(i18n).join(' / ')}. Treat this as practice feedback, not a clean-score comparison.',
                  ja: 'アシスト有効: ${_enabledAssistLabels(i18n).join(' / ')}。練習用のフィードバックとして見てください。',
                  de: 'Hilfen aktiv: ${_enabledAssistLabels(i18n).join(' / ')}. Das ist Übungsfeedback, kein reiner Vergleichswert.',
                  fr: 'Aides activées : ${_enabledAssistLabels(i18n).join(' / ')}. À lire comme retour d’entraînement, pas comme score pur.',
                  es: 'Ayudas activadas: ${_enabledAssistLabels(i18n).join(' / ')}. Tómalo como práctica, no como puntuación limpia.',
                  ru: 'Подсказки включены: ${_enabledAssistLabels(i18n).join(' / ')}. Это обратная связь для тренировки, не чистый результат.',
                )
              : pickUiText(
                  i18n,
                  zh: '本组未开启答案或提示辅助，成绩更接近纯记忆测试。',
                  en: 'No answer or hint assist was enabled, so the score is closer to a clean memory test.',
                  ja: 'No answer or hint assist was enabled, so the score is closer to a clean memory test.',
                  de: 'No answer or hint assist was enabled, so the score is closer to a clean memory test.',
                  fr: 'Aucune réponse ou indice d\'aide n\'a été activé, de sorte que le score est plus proche d\'un test de mémoire propre.',
                  es: 'No se ha habilitado respuesta ni ayuda indirecta, por lo que la puntuación está más cerca de una prueba de memoria limpia.',
                  ru: 'Никакого ответа или подсказки не было включено, поэтому оценка ближе к чистому тесту памяти.',
                ),
          accent: accent,
        ),
      ],
    );
  }

  List<String> _enabledAssistLabels(AppI18n i18n) {
    return <String>[
      if (showAnswer)
        pickUiText(
          i18n,
          zh: '显示答案',
          en: 'Show answer',
          ja: '答えを表示',
          de: 'Antwort anzeigen',
          fr: 'Afficher la réponse',
          es: 'Mostrar respuesta',
          ru: 'Показать ответ',
        ),
      if (showNextHint)
        pickUiText(
          i18n,
          zh: '下一步提示',
          en: 'Next-step hint',
          ja: '次のヒント',
          de: 'Nächster Hinweis',
          fr: 'Indice suivant',
          es: 'Pista siguiente',
          ru: 'Подсказка следующего шага',
        ),
      if (oneMistakeRescue)
        pickUiText(
          i18n,
          zh: '一次错误保护',
          en: 'One-mistake rescue',
          ja: '1回ミス救済',
          de: 'Ein Fehler frei',
          fr: 'Une erreur tolérée',
          es: 'Un fallo permitido',
          ru: 'Одна ошибка прощается',
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
      return pickUiText(
        i18n,
        zh: '准确率很稳，已经触达本组上限。可以调大目标上限或表格尺寸继续加压。',
        en: 'Accuracy is steady and the cap is cleared. Raise target cap or board size for more pressure.',
        ja: '精度は安定しており、キャップはクリアされています。ターゲットキャップまたはボードのサイズを上げて、より多くの圧力をかけます。',
        de: 'Accuracy is steady and the cap is cleared. Raise target cap or board size for more pressure.',
        fr: 'Accuracy is steady and the cap is cleared. Raise target cap or board size for more pressure.',
        es: 'La precisión es estable y la tapa se limpia. Aumentar el límite objetivo o el tamaño de la tabla para más presión.',
        ru: 'Точность стабильна, а крышка очищена. Увеличьте размер крышки или доски для большего давления.',
      );
    }
    if (accuracy >= 85) {
      return pickUiText(
        i18n,
        zh: '整体表现稳定。下一步可逐步关闭辅助，或降低播放间隔来训练瞬时记忆。',
        en: 'Performance is stable. Next, turn assists off or lower playback delay for instant memory.',
        ja: 'Performance is stable. Next, turn assists off or lower playback delay for instant memory.',
        de: 'Performance is stable. Next, turn assists off or lower playback delay for instant memory.',
        fr: 'La performance est stable. Ensuite, éteignez les aides ou réduisez le délai de lecture pour la mémoire instantanée.',
        es: 'El rendimiento es estable. A continuación, apague ayudas apagado o menor retraso de reproducción para la memoria instantánea.',
        ru: 'Производительность стабильна. Затем выключите ассисты или уменьшите задержку воспроизведения для мгновенной памяти.',
      );
    }
    if (mistakes > 0) {
      return pickUiText(
        i18n,
        zh: '主要损失来自顺序错误。建议先开启下一步提示练路线，再关闭提示测纯记忆。',
        en: 'Most loss comes from order errors. Practice route planning with next-step hints, then test without them.',
        ja: 'Most loss comes from order errors. Practice route planning with next-step hints, then test without them.',
        de: 'Most loss comes from order errors. Practice route planning with next-step hints, then test without them.',
        fr: 'La plupart des pertes proviennent d\'erreurs de commande. Pratiquer la planification de l\'itinéraire avec des conseils de prochaine étape, puis tester sans eux.',
        es: 'La mayoría de la pérdida proviene de errores de orden. Practicar la planificación de la ruta con pistas de próximo paso, luego probar sin ellas.',
        ru: 'Большая часть потерь связана с ошибками заказа. Практикуйте планирование маршрута с подсказками следующего шага, а затем тестируйте без них.',
      );
    }
    if (averageTime != null && averageTime.inMilliseconds > 6000) {
      return pickUiText(
        i18n,
        zh: '准确但节奏偏慢。可以保持当前目标数，尝试更快完成每轮。',
        en: 'Accurate, but pace is slow. Keep the target count and try to finish each round faster.',
        ja: '正確だが、ペースが遅い。ターゲット数を維持し、各ラウンドをより早く終了するようにしてください。',
        de: 'Accurate, but pace is slow. Keep the target count and try to finish each round faster.',
        fr: 'Accurate, but pace is slow. Keep the target count and try to finish each round faster.',
        es: 'Es preciso, pero el ritmo es lento. Mantenga la cuenta del objetivo y trate de terminar cada ronda más rápido.',
        ru: 'Точный, но темп медленный. Держите счет цели и старайтесь закончить каждый раунд быстрее.',
      );
    }
    return pickUiText(
      i18n,
      zh: '先以较小表格和较低目标数建立稳定顺序，再逐步增加难度。',
      en: 'Start with a smaller board and lower target count, then scale difficulty gradually.',
      ja: 'Start with a smaller board and lower target count, then scale difficulty gradually.',
      de: 'Start with a smaller board and lower target count, then scale difficulty gradually.',
      fr: 'Commencez par un tableau plus petit et un compte cible plus bas, puis échellez la difficulté progressivement.',
      es: 'Comience con una tabla más pequeña y conteo de objetivos más bajo, luego escala dificultad gradualmente.',
      ru: 'Начните с меньшей платы и более низкого количества целей, а затем постепенно масштабируйте сложность.',
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
      title: pickUiText(
        i18n,
        zh: '序列记忆',
        en: 'Sequence memory',
        ja: 'Sequence memory',
        de: 'Sequence memory',
        fr: 'Mémoire de séquence',
        es: 'Memoria de secuencias',
        ru: 'память последовательностей',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '观察亮起顺序，然后按同样顺序点击色块。',
        en: 'Watch the light sequence, then tap the panels in the same order.',
        ja: 'Watch the light sequence, then tap the panels in the same order.',
        de: 'Watch the light sequence, then tap the panels in the same order.',
        fr: 'Regardez la séquence lumineuse, puis appuyez sur les panneaux dans le même ordre.',
        es: 'Mira la secuencia de luz, luego toca los paneles en el mismo orden.',
        ru: 'Следите за световой последовательностью, затем нажмите на панели в том же порядке.',
      ),
      accent: const Color(0xFF7C6BC8),
      icon: Icons.auto_awesome_motion_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：播放序列后复现',
        en: 'Next: replay the sequence',
        ja: 'Next: replay the sequence',
        de: 'Next: replay the sequence',
        fr: 'Suivant : rejouer la séquence',
        es: 'Siguiente: reproducir la secuencia',
        ru: 'Next: Повторить последовательность',
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
                zh: '进度',
                en: 'Progress',
                ja: 'Progress',
                de: 'Progress',
                fr: 'Progrès accomplis',
                es: 'Progresos',
                ru: 'Прогресс',
              ),
              _input ? '$_inputIndex/${_sequence.length}' : '-',
            ),
            (
              pickUiText(
                i18n,
                zh: '图标',
                en: 'Icons',
                ja: 'Icons',
                de: 'Icons',
                fr: 'Icônes',
                es: 'Iconos',
                ru: 'Иконы',
              ),
              '$_itemCount',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _HumanSettingsSection(
          title: pickUiText(
            i18n,
            zh: '序列设置',
            en: 'Sequence settings',
            ja: 'Sequence settings',
            de: 'Sequence settings',
            fr: 'Paramètres de séquence',
            es: 'Ajustes de secuencia',
            ru: 'Параметры последовательности',
          ),
          subtitle: pickUiText(
            i18n,
            zh: '开始新一轮前可调整图标数量。',
            en: 'Adjust the icon count before starting a new round.',
            ja: '新しいラウンドを開始する前に、アイコンの数を調整してください。',
            de: 'Adjust the icon count before starting a new round.',
            fr: 'Adjust the icon count before starting a new round.',
            es: 'Ajuste el icono contar antes de comenzar una nueva ronda.',
            ru: 'Отрегулируйте количество иконок перед началом нового раунда.',
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      pickUiText(
                        i18n,
                        zh: '图标数量',
                        en: 'Icon count',
                        ja: 'Icon count',
                        de: 'Icon count',
                        fr: 'Nombre d\'icônes',
                        es: 'Cuenta Icon',
                        ru: 'Счет икон',
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
                  pickUiText(
                    i18n,
                    zh: '顺序错了，重置后再来。',
                    en: 'Wrong sequence. Reset and try again.',
                    ja: 'Wrong sequence. Reset and try again.',
                    de: 'Wrong sequence. Reset and try again.',
                    fr: 'Mauvaise séquence. Réinitialisez et essayez encore.',
                    es: 'Secuencia incorrecta. Reiniciar e intentarlo de nuevo.',
                    ru: 'Ошибочная последовательность. Перезагрузите и попробуйте снова.',
                  ),
                )
              else if (_showing)
                Text(
                  pickUiText(
                    i18n,
                    zh: '正在播放序列',
                    en: 'Playing sequence',
                    ja: 'Playing sequence',
                    de: 'Playing sequence',
                    fr: 'Séquence de lecture',
                    es: 'Secuencia',
                    ru: 'Игровая последовательность',
                  ),
                ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
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
                    onPressed: _showing ? null : _startRound,
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
      ],
    );
  }
}
