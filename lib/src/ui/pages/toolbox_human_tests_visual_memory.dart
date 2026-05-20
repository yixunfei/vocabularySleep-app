part of 'toolbox_human_tests.dart';

class VisualMemoryTestPage extends StatelessWidget {
  const VisualMemoryTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: pickUiText(
        i18n,
        zh: '视觉记忆',
        en: 'Visual memory',
        ja: 'Visual memory',
        de: 'Visual memory',
        fr: 'Mémoire visuelle',
        es: 'Memoria visual',
        ru: 'Визуальная память',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '从经典位置到随机目标色，等级越高，干扰色会越接近目标。',
        en: 'From classic positions to random target colors; higher levels use closer decoy colors.',
        ja: 'From classic positions to random target colors; higher levels use closer decoy colors.',
        de: 'From classic positions to random target colors; higher levels use closer decoy colors.',
        fr: 'Des positions classiques aux couleurs cibles aléatoires; des niveaux plus élevés utilisent des couleurs de leurre plus proches.',
        es: 'Desde posiciones clásicas hasta colores de destino al azar; niveles más altos usan colores de decoy más cercanos.',
        ru: 'От классических позиций до случайных целевых цветов; более высокие уровни используют более близкие цвета.',
      ),
      accent: const Color(0xFF8B6BC8),
      icon: Icons.dashboard_customize_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：选择模式后开始观察并复现目标',
        en: 'Next: choose a mode, observe, then reproduce the targets',
        ja: 'Next: choose a mode, observe, then reproduce the targets',
        de: 'Next: choose a mode, observe, then reproduce the targets',
        fr: 'Suivant : choisir un mode, observer, puis reproduire les cibles',
        es: 'Siguiente: elegir un modo, observar, luego reproducir los objetivos',
        ru: 'Далее: выберите режим, наблюдайте, затем воспроизводите цели',
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
  const _VisualMemoryColorToken({
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

class _VisualMemoryPaletteSpec {
  const _VisualMemoryPaletteSpec({
    required this.zh,
    required this.en,
    required this.ja,
    required this.de,
    required this.fr,
    required this.es,
    required this.ru,
    required this.colors,
  });

  final String zh;
  final String en;
  final String ja;
  final String de;
  final String fr;
  final String es;
  final String ru;
  final List<_VisualMemoryColorToken> colors;

  String label(AppI18n i18n) =>
      pickUiText(i18n, zh: zh, en: en, ja: ja, de: de, fr: fr, es: es, ru: ru);
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
      zh: '柔和',
      en: 'Soft',
      ja: 'やわらか',
      de: 'Sanft',
      fr: 'Doux',
      es: 'Suave',
      ru: 'Мягкая',
      colors: <_VisualMemoryColorToken>[
        _VisualMemoryColorToken(
          color: Color(0xFF7C72D9),
          zh: '紫色',
          en: 'Purple',
          ja: '紫',
          de: 'Violett',
          fr: 'Violet',
          es: 'Morado',
          ru: 'Фиолетовый',
        ),
        _VisualMemoryColorToken(
          color: Color(0xFF5C9DDC),
          zh: '蓝色',
          en: 'Blue',
          ja: '青',
          de: 'Blau',
          fr: 'Bleu',
          es: 'Azul',
          ru: 'Синий',
        ),
        _VisualMemoryColorToken(
          color: Color(0xFF5DBA8D),
          zh: '绿色',
          en: 'Green',
          ja: '緑',
          de: 'Grün',
          fr: 'Vert',
          es: 'Verde',
          ru: 'Зеленый',
        ),
        _VisualMemoryColorToken(
          color: Color(0xFFE0A54A),
          zh: '金色',
          en: 'Gold',
          ja: '金色',
          de: 'Gold',
          fr: 'Or',
          es: 'Dorado',
          ru: 'Золотой',
        ),
        _VisualMemoryColorToken(
          color: Color(0xFFD36F8A),
          zh: '玫红',
          en: 'Rose',
          ja: 'ローズ',
          de: 'Rosé',
          fr: 'Rose',
          es: 'Rosa',
          ru: 'Розовый',
        ),
        _VisualMemoryColorToken(
          color: Color(0xFF55B8B0),
          zh: '青色',
          en: 'Cyan',
          ja: 'シアン',
          de: 'Türkis',
          fr: 'Cyan',
          es: 'Cian',
          ru: 'Бирюзовый',
        ),
        _VisualMemoryColorToken(
          color: Color(0xFFC48A56),
          zh: '琥珀',
          en: 'Amber',
          ja: '琥珀',
          de: 'Bernstein',
          fr: 'Ambre',
          es: 'Ámbar',
          ru: 'Янтарный',
        ),
        _VisualMemoryColorToken(
          color: Color(0xFF8796DF),
          zh: '靛蓝',
          en: 'Indigo',
          ja: 'インディゴ',
          de: 'Indigo',
          fr: 'Indigo',
          es: 'Índigo',
          ru: 'Индиго',
        ),
      ],
    ),
    _VisualMemoryPalette.vivid: _VisualMemoryPaletteSpec(
      zh: '鲜明',
      en: 'Vivid',
      ja: '鮮やか',
      de: 'Kräftig',
      fr: 'Vif',
      es: 'Vivo',
      ru: 'Яркая',
      colors: <_VisualMemoryColorToken>[
        _VisualMemoryColorToken(
          color: Color(0xFFE84F5F),
          zh: '红色',
          en: 'Red',
          ja: '赤',
          de: 'Rot',
          fr: 'Rouge',
          es: 'Rojo',
          ru: 'Красный',
        ),
        _VisualMemoryColorToken(
          color: Color(0xFF1E88E5),
          zh: '蓝色',
          en: 'Blue',
          ja: '青',
          de: 'Blau',
          fr: 'Bleu',
          es: 'Azul',
          ru: 'Синий',
        ),
        _VisualMemoryColorToken(
          color: Color(0xFF23A455),
          zh: '绿色',
          en: 'Green',
          ja: '緑',
          de: 'Grün',
          fr: 'Vert',
          es: 'Verde',
          ru: 'Зеленый',
        ),
        _VisualMemoryColorToken(
          color: Color(0xFFF6B72F),
          zh: '黄色',
          en: 'Yellow',
          ja: '黄色',
          de: 'Gelb',
          fr: 'Jaune',
          es: 'Amarillo',
          ru: 'Желтый',
        ),
        _VisualMemoryColorToken(
          color: Color(0xFF9B55E6),
          zh: '紫色',
          en: 'Purple',
          ja: '紫',
          de: 'Violett',
          fr: 'Violet',
          es: 'Morado',
          ru: 'Фиолетовый',
        ),
        _VisualMemoryColorToken(
          color: Color(0xFF00A6A6),
          zh: '青色',
          en: 'Cyan',
          ja: 'シアン',
          de: 'Türkis',
          fr: 'Cyan',
          es: 'Cian',
          ru: 'Бирюзовый',
        ),
        _VisualMemoryColorToken(
          color: Color(0xFFFF7A3D),
          zh: '橙色',
          en: 'Orange',
          ja: 'オレンジ',
          de: 'Orange',
          fr: 'Orange',
          es: 'Naranja',
          ru: 'Оранжевый',
        ),
        _VisualMemoryColorToken(
          color: Color(0xFF6072E8),
          zh: '靛蓝',
          en: 'Indigo',
          ja: 'インディゴ',
          de: 'Indigo',
          fr: 'Indigo',
          es: 'Índigo',
          ru: 'Индиго',
        ),
      ],
    ),
    _VisualMemoryPalette.contrast: _VisualMemoryPaletteSpec(
      zh: '高对比',
      en: 'Contrast',
      ja: '高コントラスト',
      de: 'Kontrast',
      fr: 'Contraste',
      es: 'Contraste',
      ru: 'Контраст',
      colors: <_VisualMemoryColorToken>[
        _VisualMemoryColorToken(
          color: Color(0xFF005BBB),
          zh: '深蓝',
          en: 'Deep blue',
          ja: '濃い青',
          de: 'Dunkelblau',
          fr: 'Bleu profond',
          es: 'Azul oscuro',
          ru: 'Темно-синий',
        ),
        _VisualMemoryColorToken(
          color: Color(0xFFFFB000),
          zh: '亮黄',
          en: 'Bright yellow',
          ja: '明るい黄色',
          de: 'Hellgelb',
          fr: 'Jaune vif',
          es: 'Amarillo vivo',
          ru: 'Ярко-желтый',
        ),
        _VisualMemoryColorToken(
          color: Color(0xFFDC267F),
          zh: '洋红',
          en: 'Magenta',
          ja: 'マゼンタ',
          de: 'Magenta',
          fr: 'Magenta',
          es: 'Magenta',
          ru: 'Пурпурный',
        ),
        _VisualMemoryColorToken(
          color: Color(0xFF009E73),
          zh: '翠绿',
          en: 'Emerald',
          ja: 'エメラルド',
          de: 'Smaragd',
          fr: 'Émeraude',
          es: 'Esmeralda',
          ru: 'Изумрудный',
        ),
        _VisualMemoryColorToken(
          color: Color(0xFFFE6100),
          zh: '橙色',
          en: 'Orange',
          ja: 'オレンジ',
          de: 'Orange',
          fr: 'Orange',
          es: 'Naranja',
          ru: 'Оранжевый',
        ),
        _VisualMemoryColorToken(
          color: Color(0xFF785EF0),
          zh: '紫色',
          en: 'Purple',
          ja: '紫',
          de: 'Violett',
          fr: 'Violet',
          es: 'Morado',
          ru: 'Фиолетовый',
        ),
        _VisualMemoryColorToken(
          color: Color(0xFF648FFF),
          zh: '天蓝',
          en: 'Sky blue',
          ja: '空色',
          de: 'Himmelblau',
          fr: 'Bleu ciel',
          es: 'Azul cielo',
          ru: 'Небесно-голубой',
        ),
        _VisualMemoryColorToken(
          color: Color(0xFF7A7A7A),
          zh: '灰色',
          en: 'Gray',
          ja: '灰色',
          de: 'Grau',
          fr: 'Gris',
          es: 'Gris',
          ru: 'Серый',
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
      return pickUiText(
        i18n,
        zh: '近似色干扰',
        en: 'Near-color decoys',
        ja: 'Near-color decoys',
        de: 'Near-color decoys',
        fr: 'Des leurres de couleur proche',
        es: 'Decoraciones de color cercano',
        ru: 'Цветные приманки',
      );
    }
    if (pressure >= 0.34) {
      return pickUiText(
        i18n,
        zh: '色差接近',
        en: 'Closer colors',
        ja: '近い色',
        de: 'Closer colors',
        fr: 'Couleurs plus proches',
        es: 'Colores más cercanos',
        ru: 'Ближайшие цвета',
      );
    }
    return pickUiText(
      i18n,
      zh: '色差清晰',
      en: 'Clear contrast',
      ja: '明確なコントラスト',
      de: 'Clear contrast',
      fr: 'Contraste clair',
      es: 'contraste claro',
      ru: 'Явный контраст',
    );
  }

  String _difficultyLabel(AppI18n i18n, _VisualMemoryDifficulty difficulty) {
    return switch (difficulty) {
      _VisualMemoryDifficulty.relaxed => pickUiText(
        i18n,
        zh: '轻量',
        en: 'Relaxed',
        ja: 'Relaxed',
        de: 'Relaxed',
        fr: 'Détends-toi',
        es: 'Relajado',
        ru: 'Расслабленный',
      ),
      _VisualMemoryDifficulty.standard => pickUiText(
        i18n,
        zh: '标准',
        en: 'Standard',
        ja: 'Standard',
        de: 'Standard',
        fr: 'Norme',
        es: 'Estándar',
        ru: 'Стандарт',
      ),
      _VisualMemoryDifficulty.challenge => pickUiText(
        i18n,
        zh: '进阶',
        en: 'Challenge',
        ja: 'チャレンジ',
        de: 'Challenge',
        fr: 'Défi',
        es: 'Desafío',
        ru: 'Вызов',
      ),
      _VisualMemoryDifficulty.custom => pickUiText(
        i18n,
        zh: '自定义',
        en: 'Custom',
        ja: 'Custom',
        de: 'Custom',
        fr: 'Personnalisé',
        es: 'Aduanas',
        ru: 'обычай',
      ),
    };
  }

  String _modeLabel(AppI18n i18n, _VisualMemoryMode mode) {
    return switch (mode) {
      _VisualMemoryMode.positions => pickUiText(
        i18n,
        zh: '位置记忆',
        en: 'Positions',
        ja: 'Positions',
        de: 'Positions',
        fr: 'Positions',
        es: 'Posiciones',
        ru: 'Позиции',
      ),
      _VisualMemoryMode.colorTargets => pickUiText(
        i18n,
        zh: '彩色目标',
        en: 'Color targets',
        ja: 'ターゲット',
        de: 'Color targets',
        fr: 'Cibles de couleur',
        es: 'Objetivos de color',
        ru: 'Цветовые цели',
      ),
      _VisualMemoryMode.targetColor => pickUiText(
        i18n,
        zh: '指定颜色',
        en: 'Target color',
        ja: 'Target color',
        de: 'Target color',
        fr: 'Couleur de la cible',
        es: 'Color blanco',
        ru: 'Целевой цвет',
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
    return pickUiText(
      i18n,
      zh: '本轮目标色：${_colorName(i18n, token)}',
      en: 'Target color: ${_colorName(i18n, token)}',
      ja: '今回の目標色：${_colorName(i18n, token)}',
      de: 'Zielfarbe: ${_colorName(i18n, token)}',
      fr: 'Couleur cible : ${_colorName(i18n, token)}',
      es: 'Color objetivo: ${_colorName(i18n, token)}',
      ru: 'Целевой цвет: ${_colorName(i18n, token)}',
    );
  }

  String _stageHint(AppI18n i18n) {
    if (_gameOver) {
      return pickUiText(
        i18n,
        zh: '测试结束，已生成本次统计报告。',
        en: 'Test finished. Your report is ready.',
        ja: 'Test finished. Your report is ready.',
        de: 'Test finished. Your report is ready.',
        fr: 'Essai terminé. Votre rapport est prêt.',
        es: 'Prueba terminada. Su informe está listo.',
        ru: 'Тест закончен. Ваш доклад готов.',
      );
    }
    if (_roundFailed) {
      return pickUiText(
        i18n,
        zh: '误点超限，已扣除生命并准备重开本关。',
        en: 'Miss limit reached. One life lost; this level is restarting.',
        ja: 'Miss limit reached. One life lost; this level is restarting.',
        de: 'Miss limit reached. One life lost; this level is restarting.',
        fr: 'La limite a été atteinte. Une vie perdue ; ce niveau redémarre.',
        es: 'El límite de la señorita llegó. Una vida perdida; este nivel es inquietante.',
        ru: 'Мисс предел достигнут. Одна жизнь потеряна, этот уровень перезапускается.',
      );
    }
    if (_showing) {
      if (_usesTargetColorRule && _targetColorToken != null) {
        final colorName = _colorName(i18n, _targetColorToken!);
        return pickUiText(
          i18n,
          zh: '记住所有 $colorName 方块；相近色和灰色格都是干扰。',
          en: 'Memorize every $colorName cell; similar colors and gray cells are decoys.',
          ja: 'Memorize every $colorName cell; similar colors and gray cells are decoys.',
          de: 'Memorize every $colorName cell; similar colors and gray cells are decoys.',
          fr: 'Mémoriser chaque cellule $colorName; les couleurs et les cellules grises sont semblables.',
          es: 'Memorizar cada célula <v0 / confianza; colores similares y células grises son decoys.',
          ru: 'Запомните каждую ячейку $colorName; похожие цвета и серые ячейки являются приманками.',
        );
      }
      return pickUiText(
        i18n,
        zh: '记住亮起的目标格，稍后直接点选复现。',
        en: 'Memorize the highlighted targets, then tap them back.',
        ja: 'Memorize the highlighted targets, then tap them back.',
        de: 'Memorize the highlighted targets, then tap them back.',
        fr: 'Mémoriser les cibles surlignées, puis les tapoter.',
        es: 'Memorice los objetivos destacados y luego tóquelos de vuelta.',
        ru: 'Запомните выделенные цели, а затем нажмите на них.',
      );
    }
    if (_input) {
      if (_usesTargetColorRule && _targetColorToken != null) {
        final colorName = _colorName(i18n, _targetColorToken!);
        return pickUiText(
          i18n,
          zh: '现在只点 $colorName 方块；相近色、灰色格和空白格都会算误点。',
          en: 'Now tap only $colorName cells; similar colors, gray cells, and blanks count as misses.',
          ja: 'Now tap only $colorName cells; similar colors, gray cells, and blanks count as misses.',
          de: 'Now tap only $colorName cells; similar colors, gray cells, and blanks count as misses.',
          fr: 'N\'appuyez maintenant que sur $colorName cellules; les couleurs semblables, les cellules grises et les blancs comptent comme manquants.',
          es: 'Ahora sólo grifo <v0 / celdas de confianza; colores similares, células grises y espacios en blanco cuentan como faltas.',
          ru: 'Теперь нажмите только $colorName ячейки; похожие цвета, серые ячейки и бланки считаются промахами.',
        );
      }
      return pickUiText(
        i18n,
        zh: '点击刚才亮起的目标格；本关允许误点 $_missLimit 次。',
        en: 'Tap the highlighted targets. Misses allowed: $_missLimit.',
        ja: 'Tap the highlighted targets. Misses allowed: $_missLimit.',
        de: 'Tap the highlighted targets. Misses allowed: $_missLimit.',
        fr: 'Appuyez sur les cibles indiquées. Non autorisé: $_missLimit.',
        es: 'Toque los objetivos destacados. Permisos permitidos: יv0/√≥n.',
        ru: 'Нажмите на выделенные цели. Разрешено: $_missLimit.',
      );
    }
    return pickUiText(
      i18n,
      zh: '点击开始，先观察目标，隐藏后再复现。',
      en: 'Press start, observe the targets, then reproduce them after they hide.',
      ja: 'Press start, observe the targets, then reproduce them after they hide.',
      de: 'Press start, observe the targets, then reproduce them after they hide.',
      fr: 'Appuyez sur Démarrer, observer les cibles, puis les reproduire après qu\'elles se soient cachées.',
      es: 'Comienza a presionar, observa los objetivos, luego reproducirlos después de esconderse.',
      ru: 'Нажмите на старт, наблюдайте за целями, а затем воспроизводите их после того, как они скрываются.',
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
                zh: '网格',
                en: 'Grid',
                ja: 'Grid',
                de: 'Grid',
                fr: 'Grille',
                es: 'Grid',
                ru: 'Сетка',
              ),
              '${_targets.isEmpty ? _plannedGridSize : _activeGridSize} x ${_targets.isEmpty ? _plannedGridSize : _activeGridSize}',
            ),
            (
              pickUiText(
                i18n,
                zh: '目标格',
                en: 'Targets',
                ja: 'Targets',
                de: 'Targets',
                fr: 'Objectifs',
                es: 'Metas',
                ru: 'Цели',
              ),
              '$targetMetric',
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
              '$_lives',
            ),
            (
              pickUiText(
                i18n,
                zh: '误点',
                en: 'Misses',
                ja: 'Misses',
                de: 'Misses',
                fr: 'Mlle',
                es: 'Misses',
                ru: 'Мисс.',
              ),
              '$_roundMistakes/$_missLimit',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _HumanSettingsSection(
          title: pickUiText(
            i18n,
            zh: '视觉记忆设置',
            en: 'Visual memory settings',
            ja: 'Visual memory settings',
            de: 'Visual memory settings',
            fr: 'Paramètres de la mémoire visuelle',
            es: 'Ajustes de memoria visual',
            ru: 'Настройки визуальной памяти',
          ),
          subtitle: pickUiText(
            i18n,
            zh: '难度、模式、颜色和干扰格设置会在下一轮生效',
            en: 'Difficulty, mode, color, and distractor settings apply to the next round',
            ja: 'Difficulty, mode, color, and distractor settings apply to the next round',
            de: 'Difficulty, mode, color, and distractor settings apply to the next round',
            fr: 'Les paramètres de difficulté, de mode, de couleur et de disjoncteur s\'appliquent au tour suivant',
            es: 'Dificultad, modo, color y configuración de distracción se aplican a la siguiente ronda',
            ru: 'Трудности, режим, цвет и настройки отвлекающего устройства применяются к следующему раунду',
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
                    text: pickUiText(
                      i18n,
                      zh: '${_observeMilliseconds}ms 观察',
                      en: '${_observeMilliseconds}ms view',
                      ja: '${_observeMilliseconds}ms view',
                      de: '${_observeMilliseconds}ms view',
                      fr: '${_observeMilliseconds}ms view',
                      es: 'vista',
                      ru: '${_observeMilliseconds}ms просмотр',
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
                            zh: '重开本关',
                            en: 'Restart level',
                            ja: 'Restart level',
                            de: 'Restart level',
                            fr: 'Redémarrer le niveau',
                            es: 'Nivel de reinicio',
                            ru: 'Уровень перезапуска',
                          ),
                    icon: Icons.play_arrow_rounded,
                    onPressed: _gameOver ? null : _startRound,
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
                  if (_roundsStarted > 0)
                    OutlinedButton.icon(
                      onPressed: _showCompletionReport,
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
          pickUiText(
            i18n,
            zh: '难度阶梯',
            en: 'Difficulty ladder',
            ja: 'Difficulty ladder',
            de: 'Difficulty ladder',
            fr: 'Échelle de difficulté',
            es: 'Dificultad de la escalera',
            ru: 'Трудная лестница',
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
          pickUiText(
            i18n,
            zh: '记忆模式',
            en: 'Memory mode',
            ja: 'Memory mode',
            de: 'Memory mode',
            fr: 'Mode mémoire',
            es: 'Modo de memoria',
            ru: 'Режим памяти',
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
          pickUiText(
            i18n,
            zh: '颜色主题',
            en: 'Color theme',
            ja: 'カラーテーマ',
            de: 'Color theme',
            fr: 'Thème couleur',
            es: 'Tema de color',
            ru: 'Цветовая тема',
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
          label: pickUiText(
            i18n,
            zh: '观察时长',
            en: 'View time',
            ja: 'View time',
            de: 'View time',
            fr: 'Afficher l\'heure',
            es: 'Ver tiempo',
            ru: 'Время просмотра',
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
            label: pickUiText(
              i18n,
              zh: '参与颜色数',
              en: 'Active colors',
              ja: 'アクティブカラー',
              de: 'Active colors',
              fr: 'Active colors',
              es: 'Colores activos',
              ru: 'Активные цвета',
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
            pickUiText(
              i18n,
              zh: '启用干扰格',
              en: 'Distractor cells',
              ja: 'Distractor cells',
              de: 'Distractor cells',
              fr: 'Cellules distracteurs',
              es: 'Células Distractor',
              ru: 'Дистрикторные ячейки',
            ),
          ),
          subtitle: Text(
            pickUiText(
              i18n,
              zh: '观察阶段额外闪现灰色非目标格；颜色模式下，强度也会让异色干扰更接近目标色。',
              en: 'Adds gray non-target cells during view time; in color modes, stronger intensity also makes decoy colors closer to the target.',
              ja: '表示時間中に灰色の非ターゲットセルを追加します。カラーモードでは、強度が強くなると、オトリの色がターゲットに近づきます。',
              de: 'Adds gray non-target cells during view time; in color modes, stronger intensity also makes decoy colors closer to the target.',
              fr: 'Adds gray non-target cells during view time; in color modes, stronger intensity also makes decoy colors closer to the target.',
              es: 'Añade células grises no-objetivos durante el tiempo de vista; en modos de color, la intensidad más fuerte también hace que los colores de decoy más cerca del objetivo.',
              ru: 'Добавляет серые нецелевые ячейки во время просмотра; в цветовых режимах более сильная интенсивность также делает приманочные цвета ближе к цели.',
            ),
          ),
        ),
        if (_distractorsEnabled) ...<Widget>[
          _VisualMemorySliderLabel(
            label: pickUiText(
              i18n,
              zh: '干扰强度',
              en: 'Distractor intensity',
              ja: 'Distractor intensity',
              de: 'Distractor intensity',
              fr: 'Intensité du distracteur',
              es: 'Intensidad Distractor',
              ru: 'Интенсивность дифрактора',
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
            pickUiText(
              i18n,
              zh: '自定义阶梯',
              en: 'Custom ladder',
              ja: 'Custom ladder',
              de: 'Custom ladder',
              fr: 'Échelle personnalisée',
              es: 'Escalera personalizada',
              ru: 'Частная лестница',
            ),
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          _VisualMemorySliderLabel(
            label: pickUiText(
              i18n,
              zh: '最大网格',
              en: 'Max grid',
              ja: 'Max grid',
              de: 'Max grid',
              fr: 'Grille maximale',
              es: 'Cuadrícula',
              ru: 'Макс.',
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
            label: pickUiText(
              i18n,
              zh: '初始目标格',
              en: 'Base targets',
              ja: '基本ターゲット',
              de: 'Base targets',
              fr: 'Objectifs de base',
              es: 'Objetivos de base',
              ru: 'Базовые цели',
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
            label: pickUiText(
              i18n,
              zh: '每关误点上限',
              en: 'Miss limit',
              ja: 'Miss limit',
              de: 'Miss limit',
              fr: 'Mlle limite',
              es: 'Límite de la señorita',
              ru: 'Мисс предел',
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
            label: pickUiText(
              i18n,
              zh: '生命数',
              en: 'Lives',
              ja: 'Lives',
              de: 'Lives',
              fr: 'Vies',
              es: 'Vidas',
              ru: 'Жизни',
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
