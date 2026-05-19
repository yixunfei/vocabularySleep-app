part of 'toolbox_human_tests.dart';

enum _ReactionPhase { idle, waiting, ready, feedback, done }

enum _ReactionMode { release, direction, colorMatch }

enum _ReactionPace { standard, sprint, variable }

enum _ReactionDirection { up, right, down, left }

class ReactionTestPage extends StatelessWidget {
  const ReactionTestPage({super.key});

  static const Color _accent = Color(0xFF2F8D8E);

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: pickUiText(
        i18n,
        zh: '反应测试',
        en: 'Reaction test',
        ja: 'Reaction test',
        de: 'Reaction test',
        fr: 'Essai de réaction',
        es: 'Prueba de reacción',
        ru: 'Реакционный тест',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '经典松手、方向滑动与颜色匹配三种模式，观察速度、准确率和连击。',
        en: 'Release, direction-swipe, and color-match modes with speed, accuracy, and streak feedback.',
        ja: 'Release, direction-swipe, and color-match modes with speed, accuracy, and streak feedback.',
        de: 'Release, direction-swipe, and color-match modes with speed, accuracy, and streak feedback.',
        fr: 'Release, direction-swipe, et color-match modes avec vitesse, précision, et retour de stries.',
        es: 'Modos de liberación, giro de dirección y captura de color con velocidad, precisión y retroalimentación.',
        ru: 'Режимы выпуска, направления и цветового соответствия со скоростью, точностью и полосовой обратной связью.',
      ),
      accent: _accent,
      icon: Icons.flash_on_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：选择模式并完成一组反应挑战',
        en: 'Next: choose a mode and finish a reaction set',
        ja: 'Next: choose a mode and finish a reaction set',
        de: 'Next: choose a mode and finish a reaction set',
        fr: 'Suivant : choisissez un mode et terminez un jeu de réactions',
        es: 'Siguiente: elegir un modo y terminar un conjunto de reacción',
        ru: 'Далее: выберите режим и закончите набор реакций',
      ),
      child: const _ReactionTestCard(),
    );
  }
}

class _ReactionAttempt {
  const _ReactionAttempt({
    required this.success,
    this.milliseconds,
    this.falseStart = false,
    this.wrongDirection = false,
    this.wrongColor = false,
  });

  final bool success;
  final int? milliseconds;
  final bool falseStart;
  final bool wrongDirection;
  final bool wrongColor;
}

class _ReactionModeSpec {
  const _ReactionModeSpec({
    required this.label,
    required this.description,
    required this.icon,
  });

  final String label;
  final String description;
  final IconData icon;
}

class _ReactionColorTarget {
  const _ReactionColorTarget({
    required this.zhLabel,
    required this.enLabel,
    required this.jaLabel,
    required this.deLabel,
    required this.frLabel,
    required this.esLabel,
    required this.ruLabel,
    required this.color,
  });

  final String zhLabel;
  final String enLabel;
  final String jaLabel;
  final String deLabel;
  final String frLabel;
  final String esLabel;
  final String ruLabel;
  final Color color;

  String label(AppI18n i18n) => pickUiText(
    i18n,
    zh: zhLabel,
    en: enLabel,
    ja: jaLabel,
    de: deLabel,
    fr: frLabel,
    es: esLabel,
    ru: ruLabel,
  );
}

class _ReactionTestCard extends StatefulWidget {
  const _ReactionTestCard();

  @override
  State<_ReactionTestCard> createState() => _ReactionTestCardState();
}

class _ReactionTestCardState extends State<_ReactionTestCard> {
  static const Color _accent = ReactionTestPage._accent;
  static const double _directionSwipeThreshold = 34;

  static const List<_ReactionColorTarget> _colorTargets =
      <_ReactionColorTarget>[
        _ReactionColorTarget(
          zhLabel: '红色',
          enLabel: 'Red',
          jaLabel: '赤',
          deLabel: 'Rot',
          frLabel: 'Rouge',
          esLabel: 'Rojo',
          ruLabel: 'Красный',
          color: Color(0xFFD94B4B),
        ),
        _ReactionColorTarget(
          zhLabel: '蓝色',
          enLabel: 'Blue',
          jaLabel: '青',
          deLabel: 'Blau',
          frLabel: 'Bleu',
          esLabel: 'Azul',
          ruLabel: 'Синий',
          color: Color(0xFF3D6FD8),
        ),
        _ReactionColorTarget(
          zhLabel: '绿色',
          enLabel: 'Green',
          jaLabel: '緑',
          deLabel: 'Grün',
          frLabel: 'Vert',
          esLabel: 'Verde',
          ruLabel: 'Зеленый',
          color: Color(0xFF2F9E68),
        ),
        _ReactionColorTarget(
          zhLabel: '黄色',
          enLabel: 'Yellow',
          jaLabel: '黄色',
          deLabel: 'Gelb',
          frLabel: 'Jaune',
          esLabel: 'Amarillo',
          ruLabel: 'Желтый',
          color: Color(0xFFE0B43A),
        ),
        _ReactionColorTarget(
          zhLabel: '紫色',
          enLabel: 'Purple',
          jaLabel: '紫',
          deLabel: 'Violett',
          frLabel: 'Violet',
          esLabel: 'Morado',
          ruLabel: 'Фиолетовый',
          color: Color(0xFF8367C7),
        ),
      ];

  final math.Random _random = math.Random();
  final Stopwatch _stopwatch = Stopwatch();
  final List<_ReactionAttempt> _attempts = <_ReactionAttempt>[];

  Timer? _signalTimer;
  _ReactionPhase _phase = _ReactionPhase.idle;
  _ReactionMode _mode = _ReactionMode.release;
  _ReactionPace _pace = _ReactionPace.standard;
  _ReactionDirection? _direction;
  _ReactionColorTarget? _colorTarget;
  bool _pressed = false;
  int _roundTarget = 5;
  int _roundToken = 0;
  Offset? _directionPointerOrigin;
  bool _directionPointerActive = false;
  bool _reportDialogOpen = false;

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }

  void _cancelTimers() {
    _roundToken += 1;
    _signalTimer?.cancel();
    _signalTimer = null;
    _stopwatch
      ..stop()
      ..reset();
  }

  void _reset() {
    _cancelTimers();
    setState(() {
      _attempts.clear();
      _phase = _ReactionPhase.idle;
      _direction = null;
      _colorTarget = null;
      _pressed = false;
      _clearDirectionPointer();
      _reportDialogOpen = false;
    });
  }

  void _setMode(_ReactionMode mode) {
    if (_mode == mode) {
      return;
    }
    _cancelTimers();
    setState(() {
      _mode = mode;
      _attempts.clear();
      _phase = _ReactionPhase.idle;
      _direction = null;
      _colorTarget = null;
      _pressed = false;
      _clearDirectionPointer();
      _reportDialogOpen = false;
    });
  }

  void _setPace(_ReactionPace pace) {
    if (_pace == pace) {
      return;
    }
    _cancelTimers();
    setState(() {
      _pace = pace;
      _attempts.clear();
      _phase = _ReactionPhase.idle;
      _direction = null;
      _colorTarget = null;
      _pressed = false;
      _clearDirectionPointer();
      _reportDialogOpen = false;
    });
  }

  void _setRoundTarget(int value) {
    if (_roundTarget == value) {
      return;
    }
    _cancelTimers();
    setState(() {
      _roundTarget = value;
      _attempts.clear();
      _phase = _ReactionPhase.idle;
      _direction = null;
      _colorTarget = null;
      _pressed = false;
      _clearDirectionPointer();
      _reportDialogOpen = false;
    });
  }

  Duration _randomDelay() {
    final range = switch (_pace) {
      _ReactionPace.standard => (900, 2600),
      _ReactionPace.sprint => (420, 1350),
      _ReactionPace.variable => (350, 3600),
    };
    final span = range.$2 - range.$1 + 1;
    return Duration(milliseconds: range.$1 + _random.nextInt(span));
  }

  void _startRound({bool holding = false}) {
    final wasDone = _phase == _ReactionPhase.done;
    _cancelTimers();
    _pressed = holding;
    final token = _roundToken;
    setState(() {
      if (wasDone) {
        _attempts.clear();
      }
      _phase = _ReactionPhase.waiting;
      _direction = null;
      _colorTarget = null;
    });
    _signalTimer = Timer(_randomDelay(), () {
      if (!mounted ||
          token != _roundToken ||
          _phase != _ReactionPhase.waiting) {
        return;
      }
      if (_mode == _ReactionMode.release && !_pressed) {
        return;
      }
      _showSignal();
    });
  }

  void _showSignal() {
    _stopwatch
      ..reset()
      ..start();
    setState(() {
      _phase = _ReactionPhase.ready;
      _direction = _mode == _ReactionMode.direction
          ? _sample(_random, _ReactionDirection.values)
          : null;
      _colorTarget = _mode == _ReactionMode.colorMatch
          ? _sample(_random, _colorTargets)
          : null;
    });
    HapticFeedback.selectionClick();
  }

  void _record(_ReactionAttempt attempt) {
    _signalTimer?.cancel();
    _stopwatch.stop();
    final nextAttempts = <_ReactionAttempt>[..._attempts, attempt];
    final completed = nextAttempts.length >= _roundTarget;
    setState(() {
      _attempts
        ..clear()
        ..addAll(nextAttempts);
      _phase = completed ? _ReactionPhase.done : _ReactionPhase.feedback;
      _direction = null;
      _colorTarget = null;
      _pressed = false;
      _clearDirectionPointer();
    });
    if (attempt.success) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
    if (completed) {
      _showCompletionReport();
    }
  }

  void _showCompletionReport() {
    if (!mounted || _reportDialogOpen || _attempts.length < _roundTarget) {
      return;
    }
    final reportAttempts = List<_ReactionAttempt>.unmodifiable(_attempts);
    final successCount = reportAttempts
        .where((attempt) => attempt.success)
        .length;
    final falseStarts = reportAttempts
        .where((attempt) => attempt.falseStart)
        .length;
    final wrongDirections = reportAttempts
        .where((attempt) => attempt.wrongDirection)
        .length;
    final wrongColors = reportAttempts
        .where((attempt) => attempt.wrongColor)
        .length;
    final accuracy = reportAttempts.isEmpty
        ? null
        : successCount / reportAttempts.length;
    final averageMs = _averageMs;
    final bestMs = _bestMs;
    final beat = _beatPercentile();
    final streak = _streak;
    final mode = _mode;
    final pace = _pace;
    final roundTarget = _roundTarget;
    _reportDialogOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _reportDialogOpen = false;
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => _ReactionCompletionReportDialog(
          attempts: reportAttempts,
          roundTarget: roundTarget,
          successCount: successCount,
          falseStarts: falseStarts,
          wrongDirections: wrongDirections,
          wrongColors: wrongColors,
          accuracy: accuracy,
          averageMs: averageMs,
          bestMs: bestMs,
          beatPercentile: beat,
          modeLabel: _modeSpec(
            AppI18n(Localizations.localeOf(dialogContext).languageCode),
            mode,
          ).label,
          paceLabel: _paceLabel(
            AppI18n(Localizations.localeOf(dialogContext).languageCode),
            pace,
          ),
          streak: streak,
          accent: _accent,
        ),
      );
      _reportDialogOpen = false;
    });
  }

  void _falseStart() {
    _record(const _ReactionAttempt(success: false, falseStart: true));
  }

  void _handleStageDown() {
    if (_mode != _ReactionMode.release) {
      return;
    }
    if (_phase == _ReactionPhase.waiting || _phase == _ReactionPhase.ready) {
      return;
    }
    _pressed = true;
    _startRound(holding: true);
  }

  void _handleStageUp() {
    if (_mode == _ReactionMode.release) {
      _handleRelease();
      return;
    }
    _handleStageTap();
  }

  void _handleStageTap() {
    if (_phase == _ReactionPhase.idle ||
        _phase == _ReactionPhase.feedback ||
        _phase == _ReactionPhase.done) {
      _startRound();
      return;
    }
    if (_phase == _ReactionPhase.waiting) {
      _falseStart();
    }
  }

  void _handleRelease() {
    if (!_pressed) {
      return;
    }
    _pressed = false;
    if (_phase == _ReactionPhase.waiting) {
      _falseStart();
      return;
    }
    if (_phase == _ReactionPhase.ready) {
      _record(
        _ReactionAttempt(
          success: true,
          milliseconds: _stopwatch.elapsedMilliseconds,
        ),
      );
    }
  }

  void _handleDirectionTap(_ReactionDirection direction) {
    if (_mode != _ReactionMode.direction) {
      return;
    }
    if (_phase == _ReactionPhase.idle ||
        _phase == _ReactionPhase.feedback ||
        _phase == _ReactionPhase.done) {
      _startRound();
      return;
    }
    if (_phase == _ReactionPhase.waiting) {
      _falseStart();
      return;
    }
    if (_phase != _ReactionPhase.ready) {
      return;
    }
    _recordDirectionChoice(direction);
  }

  void _recordDirectionChoice(_ReactionDirection direction) {
    final correct = direction == _direction;
    _record(
      _ReactionAttempt(
        success: correct,
        milliseconds: correct ? _stopwatch.elapsedMilliseconds : null,
        wrongDirection: !correct,
      ),
    );
  }

  void _handleColorTap(_ReactionColorTarget target) {
    if (_mode != _ReactionMode.colorMatch) {
      return;
    }
    if (_phase == _ReactionPhase.idle ||
        _phase == _ReactionPhase.feedback ||
        _phase == _ReactionPhase.done) {
      _startRound();
      return;
    }
    if (_phase == _ReactionPhase.waiting) {
      _falseStart();
      return;
    }
    if (_phase != _ReactionPhase.ready) {
      return;
    }
    final correct = target == _colorTarget;
    _record(
      _ReactionAttempt(
        success: correct,
        milliseconds: correct ? _stopwatch.elapsedMilliseconds : null,
        wrongColor: !correct,
      ),
    );
  }

  void _handleDirectionPointerDown(PointerDownEvent event) {
    _startDirectionGesture(event.position);
  }

  void _handleDirectionPointerMove(PointerMoveEvent event) {
    _updateDirectionGesture(event.position);
  }

  void _handleDirectionPointerUp(PointerUpEvent event) {
    _endDirectionGesture(event.position);
  }

  void _handleDirectionPointerCancel(PointerCancelEvent event) {
    _clearDirectionPointer();
  }

  void _startDirectionGesture(Offset position) {
    if (_mode != _ReactionMode.direction) {
      return;
    }
    _directionPointerOrigin = position;
    _directionPointerActive = true;
    if (_phase == _ReactionPhase.idle ||
        _phase == _ReactionPhase.feedback ||
        _phase == _ReactionPhase.done) {
      _startRound(holding: true);
    }
  }

  void _updateDirectionGesture(Offset position) {
    if (!_directionPointerActive || _mode != _ReactionMode.direction) {
      return;
    }
    final origin = _directionPointerOrigin;
    if (origin == null) {
      return;
    }
    final direction = _directionFromDelta(position - origin);
    if (direction == null) {
      return;
    }
    if (_phase == _ReactionPhase.waiting) {
      _falseStart();
      return;
    }
    if (_phase == _ReactionPhase.ready) {
      _recordDirectionChoice(direction);
    }
  }

  void _endDirectionGesture(Offset? position) {
    if (!_directionPointerActive || _mode != _ReactionMode.direction) {
      return;
    }
    final origin = _directionPointerOrigin;
    final direction = origin == null || position == null
        ? null
        : _directionFromDelta(position - origin);
    if (_phase == _ReactionPhase.waiting) {
      _falseStart();
      return;
    }
    if (_phase == _ReactionPhase.ready) {
      if (direction == null) {
        _record(const _ReactionAttempt(success: false, wrongDirection: true));
      } else {
        _recordDirectionChoice(direction);
      }
      return;
    }
    _clearDirectionPointer();
  }

  void _clearDirectionPointer() {
    _directionPointerOrigin = null;
    _directionPointerActive = false;
  }

  _ReactionDirection? _directionFromDelta(Offset delta) {
    if (delta.distance < _directionSwipeThreshold) {
      return null;
    }
    if (delta.dx.abs() > delta.dy.abs()) {
      return delta.dx > 0 ? _ReactionDirection.right : _ReactionDirection.left;
    }
    return delta.dy > 0 ? _ReactionDirection.down : _ReactionDirection.up;
  }

  int get _successCount => _attempts.where((attempt) => attempt.success).length;

  int get _streak {
    var value = 0;
    for (final attempt in _attempts.reversed) {
      if (!attempt.success) {
        break;
      }
      value += 1;
    }
    return value;
  }

  List<int> get _times => _attempts
      .where((attempt) => attempt.success && attempt.milliseconds != null)
      .map((attempt) => attempt.milliseconds!)
      .toList(growable: false);

  int? get _averageMs {
    if (_times.isEmpty) {
      return null;
    }
    return (_times.reduce((a, b) => a + b) / _times.length).round();
  }

  int? get _bestMs {
    if (_times.isEmpty) {
      return null;
    }
    return _times.reduce(math.min);
  }

  int? _beatPercentile() {
    final average = _averageMs;
    if (average == null) {
      return null;
    }
    if (average <= 160) {
      return 99;
    }
    if (average <= 210) {
      return 90;
    }
    if (average <= 250) {
      return 75;
    }
    if (average <= 300) {
      return 50;
    }
    if (average <= 360) {
      return 25;
    }
    return 10;
  }

  _ReactionModeSpec _modeSpec(AppI18n i18n, _ReactionMode mode) {
    return switch (mode) {
      _ReactionMode.release => _ReactionModeSpec(
        label: pickUiText(
          i18n,
          zh: '经典松手',
          en: 'Release',
          ja: 'Release',
          de: 'Release',
          fr: 'Libération',
          es: 'Liberación',
          ru: 'Выпуск',
        ),
        description: pickUiText(
          i18n,
          zh: '按住等待变绿，立刻松手。',
          en: 'Hold, wait for green, then release.',
          ja: 'Hold, wait for green, then release.',
          de: 'Hold, wait for green, then release.',
          fr: 'Attendez, attendez le vert, puis relâchez.',
          es: 'Espera, espera a verde, luego suelta.',
          ru: 'Держись, жди зелени, потом отпусти.',
        ),
        icon: Icons.front_hand_rounded,
      ),
      _ReactionMode.direction => _ReactionModeSpec(
        label: pickUiText(
          i18n,
          zh: '方向滑动',
          en: 'Direction',
          ja: 'Direction',
          de: 'Direction',
          fr: 'Direction',
          es: 'Dirección',
          ru: 'направление',
        ),
        description: pickUiText(
          i18n,
          zh: '按住中心，看到箭头后滑向对应方向；也可点 D-pad 方向键。',
          en: 'Hold center, then slide toward the arrow; D-pad taps also work.',
          ja: 'Hold center, then slide toward the arrow; D-pad taps also work.',
          de: 'Hold center, then slide toward the arrow; D-pad taps also work.',
          fr: 'Maintenez le centre, puis glissez vers la flèche ; les touches D-pad fonctionnent également.',
          es: 'Mantener el centro, luego deslizarse hacia la flecha; los grifos D-pad también funcionan.',
          ru: 'Держите центр, затем скользите к стрелке; краны D-pad также работают.',
        ),
        icon: Icons.open_with_rounded,
      ),
      _ReactionMode.colorMatch => _ReactionModeSpec(
        label: pickUiText(
          i18n,
          zh: '颜色匹配',
          en: 'Color match',
          ja: 'カラーマッチ',
          de: 'Color match',
          fr: 'Couleur correspondante',
          es: 'Color partido',
          ru: 'Цветовой матч',
        ),
        description: pickUiText(
          i18n,
          zh: '舞台变色后，点击下方对应颜色。',
          en: 'When the stage changes color, tap the matching color below.',
          ja: 'When the stage changes color, tap the matching color below.',
          de: 'When the stage changes color, tap the matching color below.',
          fr: 'Lorsque l\'étape change de couleur, appuyez sur la couleur correspondante ci-dessous.',
          es: 'Cuando el escenario cambie de color, toque el color que coincide a continuación.',
          ru: 'Когда сцена меняет цвет, нажмите соответствующий цвет ниже.',
        ),
        icon: Icons.palette_rounded,
      ),
    };
  }

  String _paceLabel(AppI18n i18n, _ReactionPace pace) {
    return switch (pace) {
      _ReactionPace.standard => pickUiText(
        i18n,
        zh: '标准',
        en: 'Standard',
        ja: 'Standard',
        de: 'Standard',
        fr: 'Norme',
        es: 'Estándar',
        ru: 'Стандарт',
      ),
      _ReactionPace.sprint => pickUiText(
        i18n,
        zh: '冲刺',
        en: 'Sprint',
        ja: 'Sprint',
        de: 'Sprint',
        fr: 'Sprint',
        es: 'Sprint',
        ru: 'Спринт',
      ),
      _ReactionPace.variable => pickUiText(
        i18n,
        zh: '迷惑',
        en: 'Variable',
        ja: 'Variable',
        de: 'Variable',
        fr: 'Variable',
        es: 'Variable',
        ru: 'переменный',
      ),
    };
  }

  String _directionGlyph(_ReactionDirection direction) {
    return switch (direction) {
      _ReactionDirection.up => '↑',
      _ReactionDirection.right => '→',
      _ReactionDirection.down => '↓',
      _ReactionDirection.left => '←',
    };
  }

  String _stageText(AppI18n i18n) {
    if (_phase == _ReactionPhase.ready &&
        _mode == _ReactionMode.direction &&
        _direction != null) {
      return _directionGlyph(_direction!);
    }
    if (_phase == _ReactionPhase.ready &&
        _mode == _ReactionMode.colorMatch &&
        _colorTarget != null) {
      return _colorTarget!.label(i18n);
    }
    return switch (_phase) {
      _ReactionPhase.idle =>
        _mode == _ReactionMode.release
            ? pickUiText(
                i18n,
                zh: '按住开始',
                en: 'Hold to start',
                ja: 'Hold to start',
                de: 'Hold to start',
                fr: 'Attendez pour commencer',
                es: 'Espera a empezar',
                ru: 'Держись, чтобы начать',
              )
            : _mode == _ReactionMode.direction
            ? pickUiText(
                i18n,
                zh: '按中心或点方向开始',
                en: 'Hold center or tap arrow',
                ja: 'Hold center or tap arrow',
                de: 'Hold center or tap arrow',
                fr: 'Maintenez le centre ou appuyez sur la flèche',
                es: 'Tener centro o pulsar flecha',
                ru: 'Держите центр или нажмите стрелку',
              )
            : pickUiText(
                i18n,
                zh: '点击颜色开始',
                en: 'Tap a color to start',
                ja: 'Tap a color to start',
                de: 'Tap a color to start',
                fr: 'Appuyez sur une couleur pour démarrer',
                es: 'Pulsa un color para empezar',
                ru: 'Нажмите цвет, чтобы начать',
              ),
      _ReactionPhase.waiting =>
        _mode == _ReactionMode.release
            ? pickUiText(
                i18n,
                zh: '继续按住',
                en: 'Keep holding',
                ja: 'Keep holding',
                de: 'Keep holding',
                fr: 'Continuez à tenir',
                es: 'Manténganse.',
                ru: 'Держись.',
              )
            : _mode == _ReactionMode.direction
            ? pickUiText(
                i18n,
                zh: '等待箭头',
                en: 'Wait for arrow',
                ja: 'Wait for arrow',
                de: 'Wait for arrow',
                fr: 'Attendez la flèche',
                es: 'Espera una flecha',
                ru: 'Дождись стрелы',
              )
            : pickUiText(
                i18n,
                zh: '等待颜色',
                en: 'Wait for color',
                ja: 'Wait for color',
                de: 'Wait for color',
                fr: 'Attendez la couleur',
                es: 'Espera a color',
                ru: 'Ждать цвета',
              ),
      _ReactionPhase.ready =>
        _mode == _ReactionMode.release
            ? pickUiText(
                i18n,
                zh: '松手',
                en: 'Release',
                ja: 'Release',
                de: 'Release',
                fr: 'Libération',
                es: 'Liberación',
                ru: 'Выпуск',
              )
            : _mode == _ReactionMode.direction
            ? pickUiText(
                i18n,
                zh: '滑动方向',
                en: 'Slide direction',
                ja: 'Slide direction',
                de: 'Slide direction',
                fr: 'Direction de la diapositive',
                es: 'Dirección de diapositivas',
                ru: 'Направление скольжения',
              )
            : pickUiText(
                i18n,
                zh: '选颜色',
                en: 'Pick color',
                ja: 'Pick color',
                de: 'Pick color',
                fr: 'Choisir la couleur',
                es: 'Elija color',
                ru: 'Выберите цвет',
              ),
      _ReactionPhase.feedback => _latestFeedbackText(i18n),
      _ReactionPhase.done => pickUiText(
        i18n,
        zh: '本组完成',
        en: 'Set complete',
        ja: 'Set complete',
        de: 'Set complete',
        fr: 'Ensemble terminé',
        es: 'Conjunto completo',
        ru: 'Полный комплект',
      ),
    };
  }

  String _stageHint(AppI18n i18n) {
    if (_phase == _ReactionPhase.feedback) {
      return pickUiText(
        i18n,
        zh: '继续操作进入下一轮',
        en: 'Repeat the action for the next round',
        ja: 'Repeat the action for the next round',
        de: 'Repeat the action for the next round',
        fr: 'Répéter l\'action pour le prochain tour',
        es: 'Repita la acción para la próxima ronda',
        ru: 'Повторите действие для следующего раунда',
      );
    }
    if (_phase == _ReactionPhase.done) {
      return pickUiText(
        i18n,
        zh: '可重置，或切换模式开始新挑战',
        en: 'Reset or switch mode for a fresh challenge',
        ja: 'Reset or switch mode for a fresh challenge',
        de: 'Reset or switch mode for a fresh challenge',
        fr: 'Réinitialisation ou changement de mode pour un nouveau défi',
        es: 'Reiniciar o cambiar el modo para un nuevo desafío',
        ru: 'Режим сброса или переключения для нового вызова',
      );
    }
    return _modeSpec(i18n, _mode).description;
  }

  String _latestFeedbackText(AppI18n i18n) {
    if (_attempts.isEmpty) {
      return pickUiText(
        i18n,
        zh: '准备好',
        en: 'Ready',
        ja: 'Ready',
        de: 'Ready',
        fr: 'Prêt',
        es: 'Listo',
        ru: 'Готовы',
      );
    }
    final latest = _attempts.last;
    if (latest.success && latest.milliseconds != null) {
      final ms = latest.milliseconds!;
      final rank = ms <= 180
          ? pickUiText(
              i18n,
              zh: '闪电',
              en: 'Lightning',
              ja: 'Lightning',
              de: 'Lightning',
              fr: 'Lumière',
              es: 'Rayos',
              ru: 'Молния',
            )
          : ms <= 260
          ? pickUiText(
              i18n,
              zh: '很快',
              en: 'Sharp',
              ja: 'Sharp',
              de: 'Sharp',
              fr: 'Aiguë',
              es: 'Sharp',
              ru: 'острый',
            )
          : pickUiText(
              i18n,
              zh: '已记录',
              en: 'Saved',
              ja: 'Saved',
              de: 'Saved',
              fr: 'Enregistrer',
              es: 'Guardado',
              ru: 'Спасенный',
            );
      return '$rank · ${_formatMilliseconds(ms)}';
    }
    if (latest.falseStart) {
      return pickUiText(
        i18n,
        zh: '抢跑了',
        en: 'False start',
        ja: 'False start',
        de: 'False start',
        fr: 'Faux départ',
        es: 'Falso comienzo',
        ru: 'Ложный старт',
      );
    }
    if (latest.wrongDirection) {
      return pickUiText(
        i18n,
        zh: '方向错了',
        en: 'Wrong direction',
        ja: 'Wrong direction',
        de: 'Wrong direction',
        fr: 'Mauvaise direction',
        es: 'Dirección incorrecta',
        ru: 'Неправильное направление',
      );
    }
    if (latest.wrongColor) {
      return pickUiText(
        i18n,
        zh: '颜色错了',
        en: 'Wrong color',
        ja: 'Wrong color',
        de: 'Wrong color',
        fr: 'Mauvaise couleur',
        es: 'Color equivocado',
        ru: 'Неправильный цвет',
      );
    }
    return pickUiText(
      i18n,
      zh: '未命中',
      en: 'Missed',
      ja: 'Missed',
      de: 'Missed',
      fr: 'Manque',
      es: 'Desaparecido',
      ru: 'Пропавший',
    );
  }

  Color _stageColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (_phase) {
      _ReactionPhase.ready =>
        _mode == _ReactionMode.colorMatch && _colorTarget != null
            ? _colorTarget!.color
            : const Color(0xFF3FA76B),
      _ReactionPhase.waiting => const Color(0xFFC2614E),
      _ReactionPhase.feedback =>
        _attempts.isNotEmpty && _attempts.last.success
            ? const Color(0xFF3FA76B).withValues(alpha: 0.22)
            : colorScheme.errorContainer,
      _ReactionPhase.done => colorScheme.primaryContainer,
      _ReactionPhase.idle => colorScheme.surfaceContainerHigh,
    };
  }

  Color _foregroundFor(Color color) {
    return color.computeLuminance() > 0.45
        ? const Color(0xFF17201E)
        : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final accuracy = _attempts.isEmpty
        ? null
        : (_successCount / _attempts.length * 100).round();
    final beat = _beatPercentile();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (
              pickUiText(
                i18n,
                zh: '轮次',
                en: 'Rounds',
                ja: 'Rounds',
                de: 'Rounds',
                fr: 'Rondes',
                es: 'Rondas',
                ru: 'Круги',
              ),
              '${_attempts.length}/$_roundTarget',
            ),
            (
              pickUiText(
                i18n,
                zh: '平均',
                en: 'Average',
                ja: '平均',
                de: 'Average',
                fr: 'Moyenne',
                es: 'Promedio',
                ru: 'средний',
              ),
              _averageMs == null ? '-' : _formatMilliseconds(_averageMs!),
            ),
            (
              pickUiText(
                i18n,
                zh: '最快',
                en: 'Best',
                ja: 'ベスト',
                de: 'Best',
                fr: 'Meilleur',
                es: 'Mejor',
                ru: 'Лучший',
              ),
              _bestMs == null ? '-' : _formatMilliseconds(_bestMs!),
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
              accuracy == null ? '-' : '$accuracy%',
            ),
            (
              pickUiText(
                i18n,
                zh: '连击',
                en: 'Streak',
                ja: 'Streak',
                de: 'Streak',
                fr: 'Streak',
                es: 'Streak',
                ru: 'полоса',
              ),
              '$_streak',
            ),
            (
              pickUiText(
                i18n,
                zh: '超越',
                en: 'Beat',
                ja: 'を倒す',
                de: 'Beat',
                fr: 'Combattre',
                es: 'Beat',
                ru: 'бить',
              ),
              beat == null ? '-' : '$beat%',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildModes(context, i18n),
        const SizedBox(height: 12),
        _buildStage(context, i18n),
        const SizedBox(height: 12),
        if (_mode == _ReactionMode.direction)
          _buildDirectionControls(context, i18n)
        else if (_mode == _ReactionMode.colorMatch)
          _buildColorControls(context, i18n)
        else
          _buildPrimaryControls(context, i18n),
        const SizedBox(height: 12),
        _buildSettings(context, i18n),
        const SizedBox(height: 12),
        _buildTrail(context, i18n),
      ],
    );
  }

  Widget _buildModes(BuildContext context, AppI18n i18n) {
    return _HumanPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            pickUiText(
              i18n,
              zh: '模式',
              en: 'Modes',
              ja: 'Modes',
              de: 'Modes',
              fr: 'Modes',
              es: 'Modos',
              ru: 'режимы',
            ),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _ReactionMode.values
                .map((mode) {
                  final spec = _modeSpec(i18n, mode);
                  return ChoiceChip(
                    selected: _mode == mode,
                    avatar: Icon(spec.icon, size: 18),
                    label: Text(spec.label),
                    onSelected: (_) => _setMode(mode),
                  );
                })
                .toList(growable: false),
          ),
          const SizedBox(height: 10),
          Text(
            _modeSpec(i18n, _mode).description,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildStage(BuildContext context, AppI18n i18n) {
    final theme = Theme.of(context);
    final stageColor = _stageColor(context);
    final foreground = _foregroundFor(stageColor);
    final stage = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      height: 260,
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: stageColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (_phase == _ReactionPhase.ready &&
              _mode == _ReactionMode.colorMatch &&
              _colorTarget != null) ...<Widget>[
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _colorTarget!.color,
                border: Border.all(
                  color: foreground.withValues(alpha: 0.72),
                  width: 3,
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Text(
            _stageText(i18n),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _stageHint(i18n),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: foreground.withValues(alpha: 0.86),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
    if (_mode == _ReactionMode.direction) {
      return _buildDirectionPointerRegion(
        key: const ValueKey<String>('reaction_stage'),
        child: stage,
      );
    }
    return GestureDetector(
      key: const ValueKey<String>('reaction_stage'),
      onTapDown: (_) => _handleStageDown(),
      onTapUp: (_) => _handleStageUp(),
      onTapCancel: () {
        if (_mode == _ReactionMode.release) {
          _handleRelease();
        }
      },
      child: stage,
    );
  }

  Widget _buildDirectionPointerRegion({Key? key, required Widget child}) {
    return _HumanPointerDragBoundary(
      key: key,
      onPointerDown: _handleDirectionPointerDown,
      onPointerMove: _handleDirectionPointerMove,
      onPointerUp: _handleDirectionPointerUp,
      onPointerCancel: _handleDirectionPointerCancel,
      child: child,
    );
  }

  Widget _buildPrimaryControls(BuildContext context, AppI18n i18n) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _HumanActionButton(
            label: _primaryActionLabel(i18n),
            icon: _phase == _ReactionPhase.done
                ? Icons.restart_alt_rounded
                : Icons.play_arrow_rounded,
            onPressed: _mode == _ReactionMode.release
                ? null
                : () => _handleStageTap(),
          ),
        ),
        const SizedBox(width: 10),
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
          style: OutlinedButton.styleFrom(minimumSize: const Size(104, 48)),
        ),
      ],
    );
  }

  String _primaryActionLabel(AppI18n i18n) {
    if (_mode == _ReactionMode.release) {
      return pickUiText(
        i18n,
        zh: '使用舞台按住',
        en: 'Hold the stage',
        ja: 'Hold the stage',
        de: 'Hold the stage',
        fr: 'Tenez la scène',
        es: 'Mantenga el escenario',
        ru: 'Держите сцену',
      );
    }
    if (_phase == _ReactionPhase.done) {
      return pickUiText(
        i18n,
        zh: '重开一组',
        en: 'Restart set',
        ja: 'Restart set',
        de: 'Restart set',
        fr: 'Redémarrer',
        es: 'Set de reinicio',
        ru: 'Перезагрузить',
      );
    }
    return _phase == _ReactionPhase.waiting
        ? pickUiText(
            i18n,
            zh: '抢跑判定',
            en: 'False start',
            ja: 'False start',
            de: 'False start',
            fr: 'Faux départ',
            es: 'Falso comienzo',
            ru: 'Ложный старт',
          )
        : pickUiText(
            i18n,
            zh: '开始/下一轮',
            en: 'Start/next',
            ja: 'Start/next',
            de: 'Start/next',
            fr: 'Début/suivant',
            es: 'Inicio/next',
            ru: 'Начало/следующее',
          );
  }

  Widget _buildDirectionControls(BuildContext context, AppI18n i18n) {
    final theme = Theme.of(context);
    return _HumanPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            pickUiText(
              i18n,
              zh: '方向 D-pad',
              en: 'Direction D-pad',
              ja: 'Direction D-pad',
              de: 'Direction D-pad',
              fr: 'Ligne D',
              es: 'Dirección D-pad',
              ru: 'Направление D-pad',
            ),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            pickUiText(
              i18n,
              zh: '中心按住等待，信号出现后滑向上、下、左、右。',
              en: 'Hold the center, then slide up, down, left, or right after the signal.',
              ja: 'Hold the center, then slide up, down, left, or right after the signal.',
              de: 'Hold the center, then slide up, down, left, or right after the signal.',
              fr: 'Tenez le centre, puis glissez vers le haut, vers le bas, à gauche, ou juste après le signal.',
              es: 'Mantenga el centro, luego deslice hacia arriba, hacia abajo, izquierda o derecha después de la señal.',
              ru: 'Держите центр, затем скользите вверх, вниз, влево или вправо после сигнала.',
            ),
            style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
          ),
          const SizedBox(height: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildDirectionButton(_ReactionDirection.up),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _buildDirectionButton(_ReactionDirection.left),
                  const SizedBox(width: 8),
                  _buildDirectionCenter(context, i18n),
                  const SizedBox(width: 8),
                  _buildDirectionButton(_ReactionDirection.right),
                ],
              ),
              const SizedBox(height: 8),
              _buildDirectionButton(_ReactionDirection.down),
            ],
          ),
          const SizedBox(height: 12),
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
            style: OutlinedButton.styleFrom(minimumSize: const Size(104, 48)),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionButton(_ReactionDirection direction) {
    return SizedBox(
      width: 68,
      height: 56,
      child: FilledButton(
        onPressed: () => _handleDirectionTap(direction),
        child: Text(
          _directionGlyph(direction),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _buildDirectionCenter(BuildContext context, AppI18n i18n) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return _buildDirectionPointerRegion(
      key: const ValueKey<String>('reaction_direction_center'),
      child: Container(
        width: 92,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: _accent.withValues(alpha: 0.14),
          border: Border.all(color: _accent.withValues(alpha: 0.34)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              '●',
              style: theme.textTheme.titleLarge?.copyWith(
                color: _accent,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              pickUiText(
                i18n,
                zh: '按住',
                en: 'Hold center',
                ja: 'Hold center',
                de: 'Hold center',
                fr: 'Centre de retenue',
                es: 'Centro de retención',
                ru: 'Центр управления',
              ),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorControls(BuildContext context, AppI18n i18n) {
    final theme = Theme.of(context);
    return _HumanPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            pickUiText(
              i18n,
              zh: '颜色按钮',
              en: 'Color buttons',
              ja: 'ブーストカラーカラーボタン',
              de: 'Color buttons',
              fr: 'Boutons de couleur',
              es: 'Botones de color',
              ru: 'Цветные кнопки',
            ),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            pickUiText(
              i18n,
              zh: '先点任意颜色开始，等待舞台变色后再点匹配颜色。',
              en: 'Tap any color to start, then tap the matching color after the stage changes.',
              ja: 'Tap any color to start, then tap the matching color after the stage changes.',
              de: 'Tap any color to start, then tap the matching color after the stage changes.',
              fr: 'Appuyez sur n\'importe quelle couleur pour démarrer, puis appuyez sur la couleur correspondante après les changements d\'étape.',
              es: 'Toque cualquier color para empezar, luego toque el color que coincida después de los cambios de escenario.',
              ru: 'Нажмите любой цвет, чтобы начать, а затем нажмите соответствующий цвет после изменения сцены.',
            ),
            style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: _colorTargets
                .map((target) => _buildColorButton(i18n, target))
                .toList(growable: false),
          ),
          const SizedBox(height: 12),
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
            style: OutlinedButton.styleFrom(minimumSize: const Size(104, 48)),
          ),
        ],
      ),
    );
  }

  Widget _buildColorButton(AppI18n i18n, _ReactionColorTarget target) {
    return SizedBox(
      width: 116,
      height: 52,
      child: FilledButton(
        onPressed: () => _handleColorTap(target),
        style: FilledButton.styleFrom(
          backgroundColor: target.color,
          foregroundColor: _foregroundFor(target.color),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
        child: Text(target.label(i18n)),
      ),
    );
  }

  Widget _buildSettings(BuildContext context, AppI18n i18n) {
    return _HumanSettingsSection(
      title: pickUiText(
        i18n,
        zh: '反应设置',
        en: 'Reaction settings',
        ja: 'Reaction settings',
        de: 'Reaction settings',
        fr: 'Paramètres de réaction',
        es: 'Ajustes de reacción',
        ru: 'Настройки реакции',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '切换轮次和信号节奏会重置当前成绩。',
        en: 'Changing rounds or signal pace resets the current set.',
        ja: 'ラウンドまたはシグナルペースを変更すると、現在のセットがリセットされます。',
        de: 'Changing rounds or signal pace resets the current set.',
        fr: 'Changer les tours ou le rythme du signal réinitialise l\'ensemble courant.',
        es: 'Cambiar las rondas o el ritmo de señal reajusta el conjunto actual.',
        ru: 'Изменение раундов или скорости сигнала сбрасывает текущий набор.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            pickUiText(
              i18n,
              zh: '轮次数',
              en: 'Round count',
              ja: 'Round count',
              de: 'Round count',
              fr: 'Nombre de cycles',
              es: 'Cuenta redonda',
              ru: 'Круглый счет',
            ),
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <int>[5, 8, 12]
                .map((value) {
                  return ChoiceChip(
                    selected: _roundTarget == value,
                    label: Text('$value'),
                    onSelected: (_) => _setRoundTarget(value),
                  );
                })
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
          Text(
            pickUiText(
              i18n,
              zh: '信号节奏',
              en: 'Signal pace',
              ja: 'Signal pace',
              de: 'Signal pace',
              fr: 'Vitesse du signal',
              es: 'Paso de señalización',
              ru: 'Скорость сигнала',
            ),
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _ReactionPace.values
                .map((pace) {
                  return ChoiceChip(
                    selected: _pace == pace,
                    label: Text(_paceLabel(i18n, pace)),
                    onSelected: (_) => _setPace(pace),
                  );
                })
                .toList(growable: false),
          ),
        ],
      ),
    );
  }

  Widget _buildTrail(BuildContext context, AppI18n i18n) {
    final colorScheme = Theme.of(context).colorScheme;
    return _HumanPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  pickUiText(
                    i18n,
                    zh: '本组轨迹',
                    en: 'Set trail',
                    ja: 'Set trail',
                    de: 'Set trail',
                    fr: 'Définir la piste',
                    es: 'Establecer sendero',
                    ru: 'Проследить',
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              _HumanPill(
                text: '$_successCount/${_attempts.length}',
                accent: _accent,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_attempts.isEmpty)
            Text(
              pickUiText(
                i18n,
                zh: '完成第一轮后，这里会显示每次反应的结果。',
                en: 'Results from each reaction will appear here after the first round.',
                ja: 'Results from each reaction will appear here after the first round.',
                de: 'Results from each reaction will appear here after the first round.',
                fr: 'Les résultats de chaque réaction apparaîtront ici après le premier tour.',
                es: 'Los resultados de cada reacción aparecerán aquí después de la primera ronda.',
                ru: 'Результаты каждой реакции будут появляться после первого раунда.',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _attempts
                  .map((attempt) {
                    final success = attempt.success;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: success
                            ? _accent.withValues(alpha: 0.12)
                            : colorScheme.errorContainer.withValues(
                                alpha: 0.76,
                              ),
                        border: Border.all(
                          color: success
                              ? _accent.withValues(alpha: 0.22)
                              : colorScheme.error.withValues(alpha: 0.24),
                        ),
                      ),
                      child: Text(
                        _attemptLabel(i18n, attempt),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }

  String _attemptLabel(AppI18n i18n, _ReactionAttempt attempt) {
    if (attempt.success && attempt.milliseconds != null) {
      return _formatMilliseconds(attempt.milliseconds!);
    }
    if (attempt.falseStart) {
      return pickUiText(
        i18n,
        zh: '抢跑',
        en: 'Early',
        ja: 'Early',
        de: 'Early',
        fr: 'Début',
        es: 'Principios',
        ru: 'ранний',
      );
    }
    if (attempt.wrongDirection) {
      return pickUiText(
        i18n,
        zh: '错向',
        en: 'Wrong',
        ja: 'Wrong',
        de: 'Wrong',
        fr: 'Faux',
        es: 'Wrong',
        ru: 'неправильно',
      );
    }
    if (attempt.wrongColor) {
      return pickUiText(
        i18n,
        zh: '错色',
        en: 'Wrong color',
        ja: 'Wrong color',
        de: 'Wrong color',
        fr: 'Mauvaise couleur',
        es: 'Color equivocado',
        ru: 'Неправильный цвет',
      );
    }
    return pickUiText(
      i18n,
      zh: '未中',
      en: 'Miss',
      ja: 'Miss',
      de: 'Miss',
      fr: 'Mlle',
      es: 'Miss',
      ru: 'Мисс.',
    );
  }
}

class _ReactionCompletionReportDialog extends StatelessWidget {
  const _ReactionCompletionReportDialog({
    required this.attempts,
    required this.roundTarget,
    required this.successCount,
    required this.falseStarts,
    required this.wrongDirections,
    required this.wrongColors,
    required this.accuracy,
    required this.averageMs,
    required this.bestMs,
    required this.beatPercentile,
    required this.modeLabel,
    required this.paceLabel,
    required this.streak,
    required this.accent,
  });

  final List<_ReactionAttempt> attempts;
  final int roundTarget;
  final int successCount;
  final int falseStarts;
  final int wrongDirections;
  final int wrongColors;
  final double? accuracy;
  final int? averageMs;
  final int? bestMs;
  final int? beatPercentile;
  final String modeLabel;
  final String paceLabel;
  final int streak;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final accuracyText = accuracy == null
        ? '-'
        : '${(accuracy! * 100).round()}%';
    final averageText = averageMs == null
        ? '-'
        : _formatMilliseconds(averageMs!);
    final bestText = bestMs == null ? '-' : _formatMilliseconds(bestMs!);
    final beatText = beatPercentile == null ? '-' : '$beatPercentile%';
    final analysis = _analysisText(i18n);
    return _HumanReportDialogFrame(
      title: Text(
        pickUiText(
          i18n,
          zh: '反应测试报告',
          en: 'Reaction test report',
          ja: 'Reaction test report',
          de: 'Reaction test report',
          fr: 'Procès-verbal d\'essai de réaction',
          es: 'Informe de la prueba de reacción',
          ru: 'Отчет об испытаниях на реакцию',
        ),
      ),
      accent: accent,
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
              modeLabel,
            ),
            (
              pickUiText(
                i18n,
                zh: '节奏',
                en: 'Pace',
                ja: 'Pace',
                de: 'Pace',
                fr: 'Pace',
                es: 'Pace',
                ru: 'темп',
              ),
              paceLabel,
            ),
            (
              pickUiText(
                i18n,
                zh: '轮次',
                en: 'Rounds',
                ja: 'Rounds',
                de: 'Rounds',
                fr: 'Rondes',
                es: 'Rondas',
                ru: 'Круги',
              ),
              '$successCount/$roundTarget',
            ),
            (
              pickUiText(
                i18n,
                zh: '成功',
                en: 'Successes',
                ja: 'Successes',
                de: 'Successes',
                fr: 'Succès',
                es: 'Éxitos',
                ru: 'Успехи',
              ),
              '$successCount',
            ),
            (
              pickUiText(
                i18n,
                zh: '抢跑',
                en: 'False starts',
                ja: 'False starts',
                de: 'False starts',
                fr: 'Faux départs',
                es: 'False comienza',
                ru: 'Ложные старты',
              ),
              '$falseStarts',
            ),
            (
              pickUiText(
                i18n,
                zh: '判向错误',
                en: 'Wrong direction',
                ja: 'Wrong direction',
                de: 'Wrong direction',
                fr: 'Mauvaise direction',
                es: 'Dirección incorrecta',
                ru: 'Неправильное направление',
              ),
              '$wrongDirections',
            ),
            (
              pickUiText(
                i18n,
                zh: '配色错误',
                en: 'Wrong color',
                ja: 'Wrong color',
                de: 'Wrong color',
                fr: 'Mauvaise couleur',
                es: 'Color equivocado',
                ru: 'Неправильный цвет',
              ),
              '$wrongColors',
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
              accuracyText,
            ),
            (
              pickUiText(
                i18n,
                zh: '平均',
                en: 'Average',
                ja: '平均',
                de: 'Average',
                fr: 'Moyenne',
                es: 'Promedio',
                ru: 'средний',
              ),
              averageText,
            ),
            (
              pickUiText(
                i18n,
                zh: '最快',
                en: 'Best',
                ja: 'ベスト',
                de: 'Best',
                fr: 'Meilleur',
                es: 'Mejor',
                ru: 'Лучший',
              ),
              bestText,
            ),
            (
              pickUiText(
                i18n,
                zh: '超越',
                en: 'Beat',
                ja: 'を倒す',
                de: 'Beat',
                fr: 'Combattre',
                es: 'Beat',
                ru: 'бить',
              ),
              beatText,
            ),
            (
              pickUiText(
                i18n,
                zh: '连击',
                en: 'Streak',
                ja: 'Streak',
                de: 'Streak',
                fr: 'Streak',
                es: 'Streak',
                ru: 'полоса',
              ),
              '$streak',
            ),
          ],
        ),
        const SizedBox(height: 14),
        _HumanPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                pickUiText(
                  i18n,
                  zh: '分析',
                  en: 'Analysis',
                  ja: '分析',
                  de: 'Analysis',
                  fr: 'Analyse',
                  es: 'Análisis',
                  ru: 'Анализ',
                ),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                analysis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _HumanPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                pickUiText(
                  i18n,
                  zh: '本组轨迹',
                  en: 'Set trail',
                  ja: 'Set trail',
                  de: 'Set trail',
                  fr: 'Définir la piste',
                  es: 'Establecer sendero',
                  ru: 'Проследить',
                ),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: attempts
                    .map(
                      (attempt) => Chip(
                        label: Text(_attemptLabel(i18n, attempt)),
                        avatar: Icon(
                          attempt.success
                              ? Icons.check_circle_rounded
                              : Icons.close_rounded,
                          size: 18,
                          color: attempt.success
                              ? accent
                              : Theme.of(context).colorScheme.error,
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _analysisText(AppI18n i18n) {
    if (falseStarts > 0 && falseStarts >= wrongDirections + wrongColors) {
      return pickUiText(
        i18n,
        zh: '主要问题是抢跑，先稳住节奏再追速度。',
        en: 'False starts are the main issue. Stabilize timing before chasing pace.',
        ja: 'False starts are the main issue. Stabilize timing before chasing pace.',
        de: 'False starts are the main issue. Stabilize timing before chasing pace.',
        fr: 'Les faux départs sont le problème principal. Stabiliser le timing avant de poursuivre le rythme.',
        es: 'Los comienzos falsos son el problema principal. Estabilizar el tiempo antes de perseguir el ritmo.',
        ru: 'Ложные старты – главная проблема. Стабилизировать время перед погоней за темпом.',
      );
    }
    if (accuracy != null && accuracy! < 0.7) {
      return pickUiText(
        i18n,
        zh: '准确率还偏低，先把动作做准，再去缩短反应时间。',
        en: 'Accuracy is still low. Make the action clean first, then reduce latency.',
        ja: '精度はまだ低い。最初にアクションをクリーンにしてから、レイテンシを減らします。',
        de: 'Accuracy is still low. Make the action clean first, then reduce latency.',
        fr: 'Accuracy is still low. Make the action clean first, then reduce latency.',
        es: 'La precisión sigue siendo baja. Hacer la acción limpia primero, luego reducir la latencia.',
        ru: 'Точность остается низкой. Сначала сделайте действие чистым, затем уменьшите задержку.',
      );
    }
    if ((averageMs ?? 9999) <= 240 && (accuracy ?? 0) >= 0.85) {
      return pickUiText(
        i18n,
        zh: '节奏已经稳定，可以切到更快的节拍继续压缩时间。',
        en: 'The rhythm is steady. Move to a faster pace to keep trimming latency.',
        ja: 'The rhythm is steady. Move to a faster pace to keep trimming latency.',
        de: 'The rhythm is steady. Move to a faster pace to keep trimming latency.',
        fr: 'Le rythme est stable. Déplacez-vous à un rythme plus rapide pour réduire la latence.',
        es: 'El ritmo es estable. Muévete a un ritmo más rápido para seguir recortando latencia.',
        ru: 'Ритм стабилен. Перейдите к более быстрому темпу, чтобы сохранить задержку обрезки.',
      );
    }
    if (wrongDirections > 0 || wrongColors > 0) {
      return pickUiText(
        i18n,
        zh: '错误多半来自判向或配色，下一轮先固定单一模式再提速。',
        en: 'Most misses come from direction or color choice. Practice one mode cleanly before speeding up.',
        ja: 'Most misses come from direction or color choice. Practice one mode cleanly before speeding up.',
        de: 'Most misses come from direction or color choice. Practice one mode cleanly before speeding up.',
        fr: 'La plupart des erreurs proviennent de la direction ou du choix de couleur. Pratiquez un mode proprement avant d\'accélérer.',
        es: 'La mayoría de las faltas provienen de la dirección o elección de color. Practica un modo limpiamente antes de acelerar.',
        ru: 'Большинство промахов приходят из направления или выбора цвета. Практикуйте один режим чисто перед ускорением.',
      );
    }
    return pickUiText(
      i18n,
      zh: '整体表现平稳，继续保持当前模式即可。',
      en: 'Overall performance is steady. Keep the current mode and build consistency.',
      ja: 'Overall performance is steady. Keep the current mode and build consistency.',
      de: 'Overall performance is steady. Keep the current mode and build consistency.',
      fr: 'La performance globale est stable. Gardez le mode actuel et créez la cohérence.',
      es: 'El rendimiento general es constante. Mantenga el modo actual y construya la coherencia.',
      ru: 'Общая производительность стабильна. Сохраните текущий режим и создайте последовательность.',
    );
  }

  String _attemptLabel(AppI18n i18n, _ReactionAttempt attempt) {
    if (attempt.success && attempt.milliseconds != null) {
      return _formatMilliseconds(attempt.milliseconds!);
    }
    if (attempt.falseStart) {
      return pickUiText(
        i18n,
        zh: '抢跑',
        en: 'Early',
        ja: 'Early',
        de: 'Early',
        fr: 'Début',
        es: 'Principios',
        ru: 'ранний',
      );
    }
    if (attempt.wrongDirection) {
      return pickUiText(
        i18n,
        zh: '错向',
        en: 'Wrong',
        ja: 'Wrong',
        de: 'Wrong',
        fr: 'Faux',
        es: 'Wrong',
        ru: 'неправильно',
      );
    }
    if (attempt.wrongColor) {
      return pickUiText(
        i18n,
        zh: '错色',
        en: 'Wrong color',
        ja: 'Wrong color',
        de: 'Wrong color',
        fr: 'Mauvaise couleur',
        es: 'Color equivocado',
        ru: 'Неправильный цвет',
      );
    }
    return pickUiText(
      i18n,
      zh: '未中',
      en: 'Miss',
      ja: 'Miss',
      de: 'Miss',
      fr: 'Mlle',
      es: 'Miss',
      ru: 'Мисс.',
    );
  }
}
