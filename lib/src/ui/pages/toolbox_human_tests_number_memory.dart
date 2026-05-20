part of 'toolbox_human_tests.dart';

class NumberMemoryTestPage extends StatelessWidget {
  const NumberMemoryTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: pickUiText(
        i18n,
        zh: '数字记忆',
        en: 'Number memory',
        ja: 'Number memory',
        de: 'Number memory',
        fr: 'Mémoire numérique',
        es: 'Número de memoria',
        ru: 'Номер памяти',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '看数字、认颜色、找目标组，也可以心算；停留时间能精确到毫秒。',
        en: 'Recall numbers, track colors, pick target groups, or solve quick equations; dwell time can be set by the millisecond.',
        ja: 'Recall numbers, track colors, pick target groups, or solve quick equations; dwell time can be set by the millisecond.',
        de: 'Recall numbers, track colors, pick target groups, or solve quick equations; dwell time can be set by the millisecond.',
        fr: 'Numéros de rappel, couleurs de piste, choisir des groupes cibles, ou résoudre des équations rapides; le temps de séjour peut être défini par la milliseconde.',
        es: 'Recordar números, rastrear colores, elegir grupos de destino, o resolver ecuaciones rápidas; tiempo de residencia puede ser fijado por el milisegundo.',
        ru: 'Вспомните числа, отследите цвета, выберите целевые группы или решите быстрые уравнения; время ожидания может быть установлено на миллисекунду.',
      ),
      accent: const Color(0xFF536CC7),
      icon: Icons.pin_rounded,
      status: pickUiText(
        i18n,
        zh: '选个玩法，调好停留时间，就可以开始',
        en: 'Pick a mode, set the dwell time, then start',
        ja: 'Pick a mode, set the dwell time, then start',
        de: 'Pick a mode, set the dwell time, then start',
        fr: 'Choisissez un mode, définissez l\'heure d\'arrêt, puis démarrez',
        es: 'Elige un modo, establece el tiempo de residencia, luego comienza',
        ru: 'Выберите режим, установите время пребывания, затем начните',
      ),
      child: const _NumberMemoryCard(),
    );
  }
}

class _NumberMemoryCard extends StatefulWidget {
  const _NumberMemoryCard();

  @override
  State<_NumberMemoryCard> createState() => _NumberMemoryCardState();
}

class _NumberMemoryCardState extends State<_NumberMemoryCard> {
  static const List<_NumberMemoryColorSpec> _colorPalette =
      <_NumberMemoryColorSpec>[
        _NumberMemoryColorSpec(
          color: Color(0xFFE35D6A),
          zh: '红色',
          en: 'Red',
          ja: '赤',
          de: 'Rot',
          fr: 'Rouge',
          es: 'Rojo',
          ru: 'Красный',
        ),
        _NumberMemoryColorSpec(
          color: Color(0xFF4F83D1),
          zh: '蓝色',
          en: 'Blue',
          ja: '青',
          de: 'Blau',
          fr: 'Bleu',
          es: 'Azul',
          ru: 'Синий',
        ),
        _NumberMemoryColorSpec(
          color: Color(0xFF43A66E),
          zh: '绿色',
          en: 'Green',
          ja: '緑',
          de: 'Grün',
          fr: 'Vert',
          es: 'Verde',
          ru: 'Зеленый',
        ),
        _NumberMemoryColorSpec(
          color: Color(0xFFD39A35),
          zh: '琥珀',
          en: 'Amber',
          ja: '琥珀',
          de: 'Bernstein',
          fr: 'Ambre',
          es: 'Ámbar',
          ru: 'Янтарный',
        ),
        _NumberMemoryColorSpec(
          color: Color(0xFF8B6AD4),
          zh: '紫色',
          en: 'Purple',
          ja: '紫',
          de: 'Violett',
          fr: 'Violet',
          es: 'Morado',
          ru: 'Фиолетовый',
        ),
        _NumberMemoryColorSpec(
          color: Color(0xFF36A7B2),
          zh: '青色',
          en: 'Cyan',
          ja: 'シアン',
          de: 'Türkis',
          fr: 'Cyan',
          es: 'Cian',
          ru: 'Бирюзовый',
        ),
      ];

  final math.Random _random = math.Random();
  final TextEditingController _answerController = TextEditingController();
  final TextEditingController _dwellController = TextEditingController(
    text: '1300',
  );
  final TextEditingController _jitterController = TextEditingController(
    text: '300',
  );
  Timer? _timer;

  _NumberMemoryMode _mode = _NumberMemoryMode.digits;
  _NumberMemoryDifficulty _difficulty = _NumberMemoryDifficulty.beginner;
  _NumberMemoryRound? _round;
  int _customBaseDigits = 6;
  int _displayMilliseconds = 1300;
  int _dwellJitterMs = 300;
  int _lastDwellMs = 1300;
  int _level = 1;
  int _bestLevel = 1;
  int _attempts = 0;
  int _correct = 0;
  int _colorCount = 4;
  int _targetGroupCount = 3;
  int _equationTerms = 2;
  int _roundToken = 0;
  bool _randomizeDwell = false;
  bool _randomizeLength = false;
  bool _allowLeadingZero = true;
  bool _avoidAdjacentRepeat = false;
  bool _includeMultiplication = false;
  bool _showing = false;
  bool _input = false;
  bool _failed = false;
  bool _reportOpen = false;
  List<_NumberMemoryResult> _history = const <_NumberMemoryResult>[];

  @override
  void dispose() {
    _roundToken += 1;
    _timer?.cancel();
    _answerController.dispose();
    _dwellController.dispose();
    _jitterController.dispose();
    super.dispose();
  }

  List<_NumberMemoryColorSpec> get _activeColors =>
      _colorPalette.take(_colorCount).toList(growable: false);

  int _baseDigits() {
    return switch (_difficulty) {
      _NumberMemoryDifficulty.beginner => 3,
      _NumberMemoryDifficulty.intermediate => 4,
      _NumberMemoryDifficulty.advanced => 5,
      _NumberMemoryDifficulty.custom => _customBaseDigits,
    };
  }

  int get _currentDigits => math.min(18, _baseDigits() + _level - 1);

  bool get _roundBusy => _showing || _input || _reportOpen;

  String _difficultyLabel(AppI18n i18n, _NumberMemoryDifficulty value) {
    return switch (value) {
      _NumberMemoryDifficulty.beginner => pickUiText(
        i18n,
        zh: '初级',
        en: 'Beginner',
        ja: 'ビギナー',
        de: 'Beginner',
        fr: 'Débutant',
        es: 'Beginner',
        ru: 'Начинающий',
      ),
      _NumberMemoryDifficulty.intermediate => pickUiText(
        i18n,
        zh: '中级',
        en: 'Intermediate',
        ja: 'Intermediate',
        de: 'Intermediate',
        fr: 'Intermédiaire',
        es: 'Intermedio',
        ru: 'промежуточный',
      ),
      _NumberMemoryDifficulty.advanced => pickUiText(
        i18n,
        zh: '高级',
        en: 'Advanced',
        ja: '高度',
        de: 'Advanced',
        fr: 'Advanced',
        es: 'Avances',
        ru: 'продвинутый',
      ),
      _NumberMemoryDifficulty.custom => pickUiText(
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

  String _modeLabel(AppI18n i18n, _NumberMemoryMode value) {
    return switch (value) {
      _NumberMemoryMode.digits => pickUiText(
        i18n,
        zh: '数字串',
        en: 'Digit string',
        ja: 'Digit string',
        de: 'Digit string',
        fr: 'Chaîne de chiffres',
        es: 'Digit string',
        ru: 'струна gigit',
      ),
      _NumberMemoryMode.coloredDigits => pickUiText(
        i18n,
        zh: '彩色数字',
        en: 'Colored digits',
        ja: 'カラーディジット',
        de: 'Colored digits',
        fr: 'Chiffres colorés',
        es: 'dígitos coloreados',
        ru: 'Цветные цифры',
      ),
      _NumberMemoryMode.multiTarget => pickUiText(
        i18n,
        zh: '多数字目标',
        en: 'Multi-target',
        ja: 'Multi-target',
        de: 'Multi-target',
        fr: 'Multi-cible',
        es: 'Multi-target',
        ru: 'Многоцелевой',
      ),
      _NumberMemoryMode.equation => pickUiText(
        i18n,
        zh: '计算式',
        en: 'Equation',
        ja: 'Equation',
        de: 'Equation',
        fr: 'Équation',
        es: 'Ecuación',
        ru: 'уравнение',
      ),
    };
  }

  String _modeDescription(AppI18n i18n, _NumberMemoryMode value) {
    return switch (value) {
      _NumberMemoryMode.digits => pickUiText(
        i18n,
        zh: '看一眼，数字藏起来后原样写回。',
        en: 'Take a look, then type the digits back after they hide.',
        ja: 'Take a look, then type the digits back after they hide.',
        de: 'Take a look, then type the digits back after they hide.',
        fr: 'Regardez, puis tapez les chiffres après qu\'ils se soient cachés.',
        es: 'Echa un vistazo, luego escribe los dígitos después de esconderse.',
        ru: 'Взгляните, затем введите цифры после того, как они спрячутся.',
      ),
      _NumberMemoryMode.coloredDigits => pickUiText(
        i18n,
        zh: '只记目标颜色上的数字，别被其他颜色带偏。',
        en: 'Remember only the digits in the target color.',
        ja: 'Remember only the digits in the target color.',
        de: 'Remember only the digits in the target color.',
        fr: 'Rappelez-vous seulement les chiffres de la couleur cible.',
        es: 'Recuerde sólo los dígitos en el color de destino.',
        ru: 'Помните только цифры в целевом цвете.',
      ),
      _NumberMemoryMode.multiTarget => pickUiText(
        i18n,
        zh: '几组数字一起出现，只写指定那一组。',
        en: 'Several groups appear at once; type the requested one.',
        ja: 'Several groups appear at once; type the requested one.',
        de: 'Several groups appear at once; type the requested one.',
        fr: 'Plusieurs groupes apparaissent à la fois; tapez celui demandé.',
        es: 'Varios grupos aparecen a la vez; escriba el pedido.',
        ru: 'Появляются сразу несколько групп; введите запрашиваемую.',
      ),
      _NumberMemoryMode.equation => pickUiText(
        i18n,
        zh: '先看式子并心算，藏起来后写结果。',
        en: 'Read the expression, solve it mentally, then type the result.',
        ja: 'Read the expression, solve it mentally, then type the result.',
        de: 'Read the expression, solve it mentally, then type the result.',
        fr: 'Lisez l\'expression, résolvez-la mentalement, puis tapez le résultat.',
        es: 'Lea la expresión, resuelva mentalmente, luego escriba el resultado.',
        ru: 'Прочитайте выражение, разберитесь с ним мысленно, затем введите результат.',
      ),
    };
  }

  String _colorName(AppI18n i18n, _NumberMemoryColorSpec color) {
    return color.label(i18n);
  }

  int _roundDigitCount() {
    if (!_randomizeLength) {
      return _currentDigits;
    }
    final minimum = math.max(1, _baseDigits());
    final maximum = math.max(minimum, _currentDigits);
    return minimum + _random.nextInt(maximum - minimum + 1);
  }

  int _resolvedDwellMs() {
    if (!_randomizeDwell || _dwellJitterMs <= 0) {
      return _displayMilliseconds;
    }
    final spread = _random.nextInt(_dwellJitterMs * 2 + 1) - _dwellJitterMs;
    return (_displayMilliseconds + spread).clamp(50, 60000);
  }

  String _generateDigits(int length) {
    final buffer = StringBuffer();
    int? previous;
    for (var index = 0; index < length; index += 1) {
      var digit = _random.nextInt(10);
      if (index == 0 && !_allowLeadingZero && length > 1) {
        digit = 1 + _random.nextInt(9);
      }
      if (_avoidAdjacentRepeat && previous != null && digit == previous) {
        digit = (digit + 1 + _random.nextInt(9)) % 10;
        if (index == 0 && !_allowLeadingZero && digit == 0) {
          digit = 1 + _random.nextInt(9);
        }
      }
      previous = digit;
      buffer.write(digit);
    }
    return buffer.toString();
  }

  _NumberMemoryRound _generateRound() {
    return switch (_mode) {
      _NumberMemoryMode.digits => _generateDigitRound(),
      _NumberMemoryMode.coloredDigits => _generateColorRound(),
      _NumberMemoryMode.multiTarget => _generateMultiTargetRound(),
      _NumberMemoryMode.equation => _generateEquationRound(),
    };
  }

  _NumberMemoryRound _generateDigitRound() {
    final digitCount = _roundDigitCount();
    final value = _generateDigits(digitCount);
    return _NumberMemoryRound(
      mode: _NumberMemoryMode.digits,
      answer: value,
      displayText: value,
      tokens: const <_NumberMemoryToken>[],
      groups: const <_NumberMemoryGroup>[],
      targetZh: '记住这一串数字',
      targetEn: 'Remember this digit string',
      targetJa: 'この数字列を覚える',
      targetDe: 'Merke dir diese Zahlenfolge',
      targetFr: 'Mémorisez cette suite de chiffres',
      targetEs: 'Recuerda esta serie de números',
      targetRu: 'Запомните эту последовательность цифр',
      inputZh: '把整串数字写回',
      inputEn: 'Type the whole string back',
      inputJa: '数字列をすべて入力',
      inputDe: 'Gib die ganze Folge ein',
      inputFr: 'Saisissez toute la suite',
      inputEs: 'Escribe toda la serie',
      inputRu: 'Введите всю последовательность',
      sizeLabel: '$digitCount',
    );
  }

  _NumberMemoryRound _generateColorRound() {
    final digitCount = _roundDigitCount();
    final colors = _activeColors;
    final targetColor = _sample(_random, colors);
    final forcedTargetIndex = _random.nextInt(digitCount);
    final tokens = <_NumberMemoryToken>[];
    for (var index = 0; index < digitCount; index += 1) {
      final digit = _generateDigits(1);
      final color = index == forcedTargetIndex
          ? targetColor
          : _sample(_random, colors);
      tokens.add(_NumberMemoryToken(text: digit, color: color));
    }
    final answer = tokens
        .where((token) => token.color == targetColor)
        .map((token) => token.text)
        .join();
    final targetColorEn = targetColor.en.toLowerCase();
    return _NumberMemoryRound(
      mode: _NumberMemoryMode.coloredDigits,
      answer: answer,
      displayText: tokens.map((token) => token.text).join(),
      tokens: List<_NumberMemoryToken>.unmodifiable(tokens),
      groups: const <_NumberMemoryGroup>[],
      targetColor: targetColor,
      targetZh: '这轮只记${targetColor.zh}数字',
      targetEn: 'This round: $targetColorEn digits',
      targetJa: '今回は${targetColor.ja}の数字だけ',
      targetDe: 'Diese Runde: ${targetColor.de}-Ziffern',
      targetFr: 'Cette fois : chiffres ${targetColor.fr}',
      targetEs: 'Esta ronda: números ${targetColor.es}',
      targetRu: 'В этом раунде: цифры цвета ${targetColor.ru}',
      inputZh: '只写${targetColor.zh}数字',
      inputEn: 'Type the $targetColorEn digits',
      inputJa: '${targetColor.ja}の数字だけ入力',
      inputDe: 'Gib nur die ${targetColor.de}-Ziffern ein',
      inputFr: 'Saisissez seulement les chiffres ${targetColor.fr}',
      inputEs: 'Escribe solo los números ${targetColor.es}',
      inputRu: 'Введите только цифры цвета ${targetColor.ru}',
      sizeLabel: '$digitCount/${targetColor.en}',
    );
  }

  _NumberMemoryRound _generateMultiTargetRound() {
    final digitCount = math.max(2, math.min(12, _roundDigitCount()));
    final groupCount = _targetGroupCount;
    final colors = _activeColors;
    final targetIndex = _random.nextInt(groupCount);
    final groups = <_NumberMemoryGroup>[];
    for (var index = 0; index < groupCount; index += 1) {
      groups.add(
        _NumberMemoryGroup(
          label: String.fromCharCode(65 + index),
          value: _generateDigits(digitCount),
          color: colors[index % colors.length],
          target: index == targetIndex,
        ),
      );
    }
    final target = groups[targetIndex];
    return _NumberMemoryRound(
      mode: _NumberMemoryMode.multiTarget,
      answer: target.value,
      displayText: groups.map((group) => group.value).join(' / '),
      tokens: const <_NumberMemoryToken>[],
      groups: List<_NumberMemoryGroup>.unmodifiable(groups),
      targetZh: '只记 ${target.label} 组（${target.color.zh}）',
      targetEn: 'Remember group ${target.label} (${target.color.en})',
      targetJa: '${target.label} 組だけ覚える（${target.color.ja}）',
      targetDe: 'Merke dir Gruppe ${target.label} (${target.color.de})',
      targetFr: 'Mémorisez le groupe ${target.label} (${target.color.fr})',
      targetEs: 'Recuerda el grupo ${target.label} (${target.color.es})',
      targetRu: 'Запомните группу ${target.label} (${target.color.ru})',
      inputZh: '写下 ${target.label} 组数字',
      inputEn: 'Type group ${target.label}',
      inputJa: '${target.label} 組を入力',
      inputDe: 'Gib Gruppe ${target.label} ein',
      inputFr: 'Saisissez le groupe ${target.label}',
      inputEs: 'Escribe el grupo ${target.label}',
      inputRu: 'Введите группу ${target.label}',
      sizeLabel: '${groupCount}x$digitCount',
    );
  }

  _NumberMemoryRound _generateEquationRound() {
    final termDigits = math.min(3, math.max(1, (_currentDigits / 2).round()));
    final operators = <String>['+', '-'];
    if (_includeMultiplication) {
      operators.add('x');
    }
    final terms = <int>[];
    final ops = <String>[];
    for (var index = 0; index < _equationTerms; index += 1) {
      final touchesMultiplication =
          index > 0 && ops[index - 1] == 'x' ||
          index < _equationTerms - 1 &&
              _includeMultiplication &&
              _random.nextDouble() < 0.22;
      terms.add(
        touchesMultiplication
            ? 2 + _random.nextInt(8)
            : _randomOperand(termDigits),
      );
      if (index < _equationTerms - 1) {
        ops.add(_sample(_random, operators));
      }
    }
    final expression = StringBuffer('${terms.first}');
    for (var index = 0; index < ops.length; index += 1) {
      expression.write(' ${ops[index]} ${terms[index + 1]}');
    }
    final result = _evaluateExpression(terms, ops);
    return _NumberMemoryRound(
      mode: _NumberMemoryMode.equation,
      answer: '$result',
      displayText: expression.toString(),
      tokens: const <_NumberMemoryToken>[],
      groups: const <_NumberMemoryGroup>[],
      targetZh: '先算出结果',
      targetEn: 'Solve it before it hides',
      targetJa: '隠れる前に計算する',
      targetDe: 'Löse es, bevor es verschwindet',
      targetFr: 'Calculez avant que cela se cache',
      targetEs: 'Resuélvelo antes de que se oculte',
      targetRu: 'Решите пример, пока он не скрылся',
      inputZh: '写下计算结果',
      inputEn: 'Type the result',
      inputJa: '答えを入力',
      inputDe: 'Gib das Ergebnis ein',
      inputFr: 'Saisissez le résultat',
      inputEs: 'Escribe el resultado',
      inputRu: 'Введите результат',
      sizeLabel: '${_equationTerms}T/${termDigits}D',
    );
  }

  int _randomOperand(int digits) {
    if (digits <= 1) {
      return 2 + _random.nextInt(8);
    }
    final minValue = _pow10(digits - 1);
    final maxValue = _pow10(digits) - 1;
    return minValue + _random.nextInt(maxValue - minValue + 1);
  }

  int _evaluateExpression(List<int> terms, List<String> ops) {
    var total = 0;
    var current = terms.first;
    for (var index = 0; index < ops.length; index += 1) {
      final op = ops[index];
      final next = terms[index + 1];
      if (op == 'x') {
        current *= next;
        continue;
      }
      total += current;
      current = op == '+' ? next : -next;
    }
    return total + current;
  }

  int _pow10(int exponent) {
    var value = 1;
    for (var index = 0; index < exponent; index += 1) {
      value *= 10;
    }
    return value;
  }

  void _startRound() {
    _timer?.cancel();
    _answerController.clear();
    final token = ++_roundToken;
    final round = _generateRound();
    final dwellMs = _resolvedDwellMs();
    setState(() {
      _round = round;
      _lastDwellMs = dwellMs;
      _showing = true;
      _input = false;
      _failed = false;
      _reportOpen = false;
    });
    _timer = Timer(Duration(milliseconds: dwellMs), () {
      if (!mounted || token != _roundToken) {
        return;
      }
      setState(() {
        _showing = false;
        _input = true;
      });
    });
  }

  void _submit() {
    final round = _round;
    if (!_input || round == null || _reportOpen) {
      return;
    }
    final answer = _answerController.text.trim();
    final expected = round.answer;
    final correct = answer == expected;
    final result = _NumberMemoryResult(
      mode: _mode,
      expected: expected,
      answer: answer,
      correct: correct,
      level: _level,
      sizeLabel: round.sizeLabel,
      dwellMs: _lastDwellMs,
    );
    setState(() {
      _attempts += 1;
      _history = <_NumberMemoryResult>[result, ..._history.take(5)];
      if (correct) {
        _correct += 1;
        _level += 1;
        _bestLevel = math.max(_bestLevel, _level - 1);
        _input = false;
      } else {
        _failed = true;
        _input = false;
        _reportOpen = true;
      }
    });
    if (!correct) {
      unawaited(_showRoundReport(result, round));
    }
  }

  Future<void> _showRoundReport(
    _NumberMemoryResult result,
    _NumberMemoryRound round,
  ) async {
    if (!mounted) {
      return;
    }
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final accuracy = _attempts == 0 ? 0 : (_correct / _attempts * 100).round();
    final answerText = result.answer.isEmpty
        ? pickUiText(
            i18n,
            zh: '留空',
            en: 'Blank',
            ja: 'ブランク',
            de: 'Blank',
            fr: 'Blanc',
            es: 'Blank',
            ru: 'бледный',
          )
        : result.answer;
    final title = result.correct
        ? pickUiText(
            i18n,
            zh: '本轮通过',
            en: 'Round passed',
            ja: 'Round passed',
            de: 'Round passed',
            fr: 'Cycle passé',
            es: 'Paso',
            ru: 'Круг прошел',
          )
        : pickUiText(
            i18n,
            zh: '这轮没对',
            en: 'Round missed',
            ja: 'Round missed',
            de: 'Round missed',
            fr: 'Cycle manqué',
            es: 'Se perdió la ronda',
            ru: 'Пропущенный раунд',
          );
    final note = result.correct
        ? pickUiText(
            i18n,
            zh: '已经过了 ${result.level} 级，下一轮从 $_level 级开始。',
            en: 'Level ${result.level} is cleared. The next round starts at level $_level.',
            ja: 'Level ${result.level} is cleared. The next round starts at level $_level.',
            de: 'Level ${result.level} is cleared. The next round starts at level $_level.',
            fr: 'Le niveau ${result.level} est effacé. Le tour suivant commence au niveau $_level.',
            es: 'El nivel se aclara. La siguiente ronda comienza en el nivel <v1/ título.',
            ru: 'Уровень ${result.level} проясняется. Следующий раунд начинается на уровне $_level.',
          )
        : pickUiText(
            i18n,
            zh: '先看一眼差在哪里，再决定要不要重来。',
            en: 'Check the gap first, then decide when to retry.',
            ja: '最初にギャップを確認し、再試行するタイミングを決定します。',
            de: 'Check the gap first, then decide when to retry.',
            fr: 'Vérifiez d\'abord l\'écart, puis décidez quand réessayer.',
            es: 'Revisa la brecha primero, luego decide cuándo volver a entrar.',
            ru: 'Сначала проверьте разрыв, а затем решите, когда повторить.',
          );
    final continueNext = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    note,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  _NumberMemoryReportRow(
                    label: pickUiText(
                      i18n,
                      zh: '模式',
                      en: 'Mode',
                      ja: 'Mode',
                      de: 'Mode',
                      fr: 'Mode',
                      es: 'Modo',
                      ru: 'Режим',
                    ),
                    value: _modeLabel(i18n, result.mode),
                  ),
                  _NumberMemoryReportRow(
                    label: pickUiText(
                      i18n,
                      zh: '等级',
                      en: 'Level',
                      ja: 'Level',
                      de: 'Level',
                      fr: 'Niveau',
                      es: 'Nivel',
                      ru: 'Уровень',
                    ),
                    value: '${result.level}',
                  ),
                  _NumberMemoryReportRow(
                    label: pickUiText(
                      i18n,
                      zh: '规模',
                      en: 'Size',
                      ja: 'Size',
                      de: 'Size',
                      fr: 'Taille',
                      es: 'Tamaño',
                      ru: 'Размер',
                    ),
                    value: result.sizeLabel,
                  ),
                  _NumberMemoryReportRow(
                    label: pickUiText(
                      i18n,
                      zh: '本轮目标',
                      en: 'Prompt',
                      ja: 'Prompt',
                      de: 'Prompt',
                      fr: 'Rapide',
                      es: 'Prompt',
                      ru: 'быстро',
                    ),
                    value: round.targetText(i18n),
                  ),
                  _NumberMemoryReportRow(
                    label: pickUiText(
                      i18n,
                      zh: '停留',
                      en: 'Dwell',
                      ja: 'Dwell',
                      de: 'Dwell',
                      fr: 'Bien',
                      es: 'Dwell',
                      ru: 'Ужин',
                    ),
                    value: _formatMilliseconds(result.dwellMs),
                  ),
                  _NumberMemoryReportRow(
                    label: pickUiText(
                      i18n,
                      zh: '正确答案',
                      en: 'Expected',
                      ja: 'Expected',
                      de: 'Expected',
                      fr: 'Montant prévu',
                      es: 'Se prevé',
                      ru: 'Ожидаемый',
                    ),
                    value: result.expected,
                    mono: true,
                  ),
                  _NumberMemoryReportRow(
                    label: pickUiText(
                      i18n,
                      zh: '你的输入',
                      en: 'Your answer',
                      ja: 'Your answer',
                      de: 'Your answer',
                      fr: 'Votre réponse',
                      es: 'Su respuesta',
                      ru: 'Ваш ответ',
                    ),
                    value: answerText,
                    mono: result.answer.isNotEmpty,
                  ),
                  _NumberMemoryReportRow(
                    label: pickUiText(
                      i18n,
                      zh: '累计正确率',
                      en: 'Accuracy',
                      ja: '精度',
                      de: 'Accuracy',
                      fr: 'Accuracy',
                      es: 'Precisión',
                      ru: 'точность',
                    ),
                    value: '$_correct/$_attempts · $accuracy%',
                  ),
                  _NumberMemoryReportRow(
                    label: pickUiText(
                      i18n,
                      zh: '最好等级',
                      en: 'Best level',
                      ja: 'ベストレベル',
                      de: 'Best level',
                      fr: 'Meilleur niveau',
                      es: 'Mejor nivel',
                      ru: 'Лучший уровень',
                    ),
                    value: '$_bestLevel',
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                pickUiText(
                  i18n,
                  zh: '先停一下',
                  en: 'Stay here',
                  ja: 'Stay here',
                  de: 'Stay here',
                  fr: 'Reste ici.',
                  es: 'Quédate aquí.',
                  ru: 'Оставайся здесь.',
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: Icon(
                result.correct
                    ? Icons.arrow_forward_rounded
                    : Icons.refresh_rounded,
              ),
              label: Text(
                result.correct
                    ? pickUiText(
                        i18n,
                        zh: '下一轮',
                        en: 'Next round',
                        ja: 'Next round',
                        de: 'Next round',
                        fr: 'Prochain tour',
                        es: 'Siguiente ronda',
                        ru: 'Следующий раунд',
                      )
                    : pickUiText(
                        i18n,
                        zh: '再来一轮',
                        en: 'Try again',
                        ja: 'Try again',
                        de: 'Try again',
                        fr: 'Essaie encore',
                        es: 'Inténtalo de nuevo.',
                        ru: 'Попробуйте еще раз',
                      ),
              ),
            ),
          ],
        );
      },
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _reportOpen = false;
    });
    if (continueNext == true) {
      _startRound();
    }
  }

  void _applySetting(VoidCallback updater) {
    if (_roundBusy) {
      return;
    }
    _timer?.cancel();
    _roundToken += 1;
    _answerController.clear();
    setState(() {
      updater();
      _level = 1;
      _round = null;
      _showing = false;
      _input = false;
      _failed = false;
      _reportOpen = false;
    });
  }

  void _reset() {
    _timer?.cancel();
    _roundToken += 1;
    _answerController.clear();
    setState(() {
      _level = 1;
      _bestLevel = 1;
      _attempts = 0;
      _correct = 0;
      _round = null;
      _history = const <_NumberMemoryResult>[];
      _showing = false;
      _input = false;
      _failed = false;
      _reportOpen = false;
    });
  }

  void _setDisplayMilliseconds(int value) {
    final next = value.clamp(50, 60000);
    _displayMilliseconds = next;
    _lastDwellMs = next;
    _dwellController.text = '$next';
  }

  void _setJitterMs(int value) {
    final next = value.clamp(0, 30000);
    _dwellJitterMs = next;
    _jitterController.text = '$next';
  }

  void _applyIntInput({
    required TextEditingController controller,
    required int min,
    required int max,
    required ValueChanged<int> apply,
  }) {
    final parsed = int.tryParse(controller.text.trim());
    if (parsed == null) {
      controller.text = '${min.clamp(min, max)}';
      return;
    }
    _applySetting(() => apply(parsed.clamp(min, max)));
  }

  String _scoreLabel(AppI18n i18n) {
    if (_attempts == 0) {
      return pickUiText(
        i18n,
        zh: '未开始',
        en: 'Not started',
        ja: 'Not started',
        de: 'Not started',
        fr: 'Pas commencé',
        es: 'No empezó',
        ru: 'Не начиналось',
      );
    }
    final rate = (_correct / _attempts * 100).round();
    return '$_correct/$_attempts · $rate%';
  }

  String _stageStatus(AppI18n i18n) {
    if (_showing) {
      return pickUiText(
        i18n,
        zh: '正在显示',
        en: 'Showing',
        ja: 'Showing',
        de: 'Showing',
        fr: 'Affichage',
        es: 'Mostrando',
        ru: 'Показывать',
      );
    }
    if (_input) {
      return pickUiText(
        i18n,
        zh: '等待输入',
        en: 'Awaiting input',
        ja: '入力待ち',
        de: 'Awaiting input',
        fr: 'En attente d\'une contribution',
        es: 'Awaiting input',
        ru: 'Ожидающий вклад',
      );
    }
    if (_failed) {
      return pickUiText(
        i18n,
        zh: '本轮错误',
        en: 'Missed',
        ja: 'Missed',
        de: 'Missed',
        fr: 'Manque',
        es: 'Desaparecido',
        ru: 'Пропавший',
      );
    }
    return pickUiText(
      i18n,
      zh: '准备',
      en: 'Ready',
      ja: 'Ready',
      de: 'Ready',
      fr: 'Prêt',
      es: 'Listo',
      ru: 'Готовы',
    );
  }

  String _feedbackText(AppI18n i18n) {
    final round = _round;
    if (round == null) {
      return _modeDescription(i18n, _mode);
    }
    if (_showing) {
      return round.targetText(i18n);
    }
    if (_input) {
      return round.inputText(i18n);
    }
    if (_failed) {
      return pickUiText(
        i18n,
        zh: '正确答案：${round.answer}',
        en: 'Answer: ${round.answer}',
        ja: '回答：${round.answer}',
        de: 'Answer: ${round.answer}',
        fr: 'Réponse : ${round.answer}',
        es: 'Respuesta:',
        ru: 'Ответ: ${round.answer}',
      );
    }
    return _modeDescription(i18n, _mode);
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final modeLabel = _modeLabel(i18n, _mode);
    final difficultyLabel = _difficultyLabel(i18n, _difficulty);
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
                zh: '规模',
                en: 'Size',
                ja: 'Size',
                de: 'Size',
                fr: 'Taille',
                es: 'Tamaño',
                ru: 'Размер',
              ),
              _round?.sizeLabel ?? '$_currentDigits',
            ),
            (
              pickUiText(
                i18n,
                zh: '停留',
                en: 'Dwell',
                ja: 'Dwell',
                de: 'Dwell',
                fr: 'Bien',
                es: 'Dwell',
                ru: 'Ужин',
              ),
              _formatMilliseconds(_lastDwellMs),
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
                zh: '成绩',
                en: 'Score',
                ja: 'Score',
                de: 'Score',
                fr: 'Score',
                es: 'Puntuación',
                ru: 'счет',
              ),
              _scoreLabel(i18n),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildSettings(context, i18n, difficultyLabel),
        const SizedBox(height: 12),
        _HumanPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildStage(context, i18n),
              const SizedBox(height: 12),
              _NumberMemoryFeedback(
                title: _stageStatus(i18n),
                body: _feedbackText(i18n),
                accent: const Color(0xFF536CC7),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey<String>('number-memory-answer-input'),
                controller: _answerController,
                enabled: _input,
                keyboardType: TextInputType.numberWithOptions(
                  signed: _mode == _NumberMemoryMode.equation,
                ),
                inputFormatters: <TextInputFormatter>[
                  _mode == _NumberMemoryMode.equation
                      ? FilteringTextInputFormatter.allow(RegExp('[-0-9]'))
                      : FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  labelText: _round == null
                      ? pickUiText(
                          i18n,
                          zh: '输入答案',
                          en: 'Type answer',
                          ja: 'Type answer',
                          de: 'Type answer',
                          fr: 'Type de réponse',
                          es: 'Respuesta del tipo',
                          ru: 'Тип ответа',
                        )
                      : _round!.inputText(i18n),
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  _HumanActionButton(
                    label: _input
                        ? pickUiText(
                            i18n,
                            zh: '提交',
                            en: 'Submit',
                            ja: 'Submit',
                            de: 'Submit',
                            fr: 'Soumettre',
                            es: 'Submit',
                            ru: 'Представить',
                          )
                        : pickUiText(
                            i18n,
                            zh: '开始',
                            en: 'Start',
                            ja: 'Start',
                            de: 'Start',
                            fr: 'Démarrer',
                            es: 'Comienzo',
                            ru: 'Начинать',
                          ),
                    icon: _input
                        ? Icons.check_rounded
                        : Icons.play_arrow_rounded,
                    onPressed: _input
                        ? _submit
                        : _showing
                        ? null
                        : _startRound,
                  ),
                  OutlinedButton.icon(
                    onPressed: _roundBusy ? null : _reset,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: Text(
                      pickUiText(
                        i18n,
                        zh: '清空',
                        en: 'Reset',
                        ja: 'Reset',
                        de: 'Reset',
                        fr: 'Réinitialiser',
                        es: 'Reset',
                        ru: 'сброс',
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(112, 48),
                      textStyle: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              if (_history.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _buildRecentResults(i18n),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStage(BuildContext context, AppI18n i18n) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final round = _round;
    return AnimatedContainer(
      key: const ValueKey<String>('number-memory-stage'),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      constraints: const BoxConstraints(minHeight: 176),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            const Color(0xFF536CC7).withValues(alpha: _showing ? 0.18 : 0.10),
            colorScheme.surface,
          ],
        ),
        border: Border.all(
          color: _failed
              ? colorScheme.error.withValues(alpha: 0.62)
              : const Color(0xFF536CC7).withValues(alpha: 0.24),
          width: _failed ? 2 : 1,
        ),
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _showing && round != null
              ? _buildRoundDisplay(context, i18n, round)
              : _buildHiddenStage(context, i18n, round),
        ),
      ),
    );
  }

  Widget _buildRoundDisplay(
    BuildContext context,
    AppI18n i18n,
    _NumberMemoryRound round,
  ) {
    return switch (round.mode) {
      _NumberMemoryMode.coloredDigits => _buildColorTokens(
        context,
        i18n,
        round,
      ),
      _NumberMemoryMode.multiTarget => _buildNumberGroups(context, i18n, round),
      _ => Text(
        round.displayText,
        key: ValueKey<String>('display-${round.displayText}'),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: round.mode == _NumberMemoryMode.digits ? 2 : 0,
        ),
      ),
    };
  }

  Widget _buildColorTokens(
    BuildContext context,
    AppI18n i18n,
    _NumberMemoryRound round,
  ) {
    final targetColor = round.targetColor;
    final theme = Theme.of(context);
    return Column(
      key: ValueKey<String>('colors-${round.displayText}'),
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (targetColor != null) ...<Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: targetColor.color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: targetColor.color.withValues(alpha: 0.34),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: targetColor.color,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  pickUiText(
                    i18n,
                    zh: '目标颜色：${targetColor.zh}',
                    en: 'Match ${targetColor.en.toLowerCase()}',
                    ja: 'Match ${targetColor.en.toLowerCase()}',
                    de: 'Match ${targetColor.en.toLowerCase()}',
                    fr: 'Correspond à ${targetColor.en.toLowerCase()}',
                    es: 'Coincidencia:',
                    ru: 'Матч ${targetColor.en.toLowerCase()}',
                  ),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: targetColor.color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: round.tokens
              .map(
                (token) => Container(
                  width: 44,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: token.color.color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: token.color.color.withValues(alpha: 0.55),
                    ),
                  ),
                  child: Text(
                    token.text,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: token.color.color,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _buildNumberGroups(
    BuildContext context,
    AppI18n i18n,
    _NumberMemoryRound round,
  ) {
    return Wrap(
      key: ValueKey<String>('groups-${round.displayText}'),
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: round.groups
          .map(
            (group) => Container(
              width: 142,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: group.color.color.withValues(
                  alpha: group.target ? 0.18 : 0.10,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: group.color.color.withValues(
                    alpha: group.target ? 0.82 : 0.34,
                  ),
                  width: group.target ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    group.target
                        ? pickUiText(
                            i18n,
                            zh: '${group.label} 目标',
                            en: '${group.label} target',
                            ja: '${group.label}ターゲット',
                            de: '${group.label} target',
                            fr: '${group.label} target',
                            es: 'Objetivo',
                            ru: '${group.label} Цель',
                          )
                        : group.label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: group.color.color,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    group.value,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildHiddenStage(
    BuildContext context,
    AppI18n i18n,
    _NumberMemoryRound? round,
  ) {
    final theme = Theme.of(context);
    final targetColor = round?.targetColor;
    final title = _failed && round != null
        ? pickUiText(
            i18n,
            zh: '答案',
            en: 'Answer',
            ja: '回答',
            de: 'Answer',
            fr: 'Réponse',
            es: 'Respuesta',
            ru: 'Ответить',
          )
        : _input
        ? pickUiText(
            i18n,
            zh: '请复现',
            en: 'Recall now',
            ja: 'Recall now',
            de: 'Recall now',
            fr: 'Rappelez-vous maintenant',
            es: 'Ahora',
            ru: 'Вспомнить сейчас',
          )
        : pickUiText(
            i18n,
            zh: '准备',
            en: 'Ready',
            ja: 'Ready',
            de: 'Ready',
            fr: 'Prêt',
            es: 'Listo',
            ru: 'Готовы',
          );
    final value = _failed && round != null
        ? round.answer
        : _input && round != null
        ? round.inputText(i18n)
        : _modeDescription(i18n, _mode);
    return Column(
      key: ValueKey<String>('hidden-$title-$value'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
        ),
        if (_input && targetColor != null) ...<Widget>[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: targetColor.color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: targetColor.color.withValues(alpha: 0.34),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: targetColor.color,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  pickUiText(
                    i18n,
                    zh: '只写${targetColor.zh}数字',
                    en: 'Only ${targetColor.en.toLowerCase()} digits',
                    ja: 'Only ${targetColor.en.toLowerCase()} digits',
                    de: 'Only ${targetColor.en.toLowerCase()} digits',
                    fr: 'Uniquement les chiffres ${targetColor.en.toLowerCase()}',
                    es: 'Sólo los dígitos del título',
                    ru: 'Только ${targetColor.en.toLowerCase()} цифры',
                  ),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: targetColor.color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSettings(
    BuildContext context,
    AppI18n i18n,
    String difficultyLabel,
  ) {
    return _HumanSettingsSection(
      title: pickUiText(
        i18n,
        zh: '训练设置',
        en: 'Training settings',
        ja: 'Training settings',
        de: 'Training settings',
        fr: 'Cadres de formation',
        es: 'Ajustes de capacitación',
        ru: 'Условия обучения',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '换玩法、调停留时间，也可以加一点随机性',
        en: 'Change the mode, tune dwell time, or add a little randomness.',
        ja: 'モードを変更するか、滞留時間を調整するか、または少しランダム性を追加します。',
        de: 'Change the mode, tune dwell time, or add a little randomness.',
        fr: 'Changez le mode, accordez le temps d\'attente, ou ajoutez un peu de hasard.',
        es: 'Cambia el modo, sintoniza el tiempo, o agrega un poco de aleatoriedad.',
        ru: 'Измените режим, настройте время пребывания или добавьте немного случайности.',
      ),
      child: Column(
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
            children: _NumberMemoryMode.values
                .map(
                  (mode) => ChoiceChip(
                    key: ValueKey<String>('number-memory-mode-${mode.name}'),
                    label: Text(_modeLabel(i18n, mode)),
                    selected: _mode == mode,
                    onSelected: _roundBusy
                        ? null
                        : (_) => _applySetting(() => _mode = mode),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 10),
          Text(
            _modeDescription(i18n, _mode),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          Text(
            '${pickUiText(i18n, zh: '起始难度', en: 'Starting difficulty', ja: 'Starting difficulty', de: 'Starting difficulty', fr: 'Difficulté de démarrage', es: 'Dificultad inicial', ru: 'Начало трудностей')} · $difficultyLabel',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _NumberMemoryDifficulty.values
                .map(
                  (difficulty) => ChoiceChip(
                    label: Text(_difficultyLabel(i18n, difficulty)),
                    selected: _difficulty == difficulty,
                    onSelected: _roundBusy
                        ? null
                        : (_) => _applySetting(() => _difficulty = difficulty),
                  ),
                )
                .toList(growable: false),
          ),
          if (_difficulty == _NumberMemoryDifficulty.custom) ...<Widget>[
            const SizedBox(height: 12),
            _NumberMemorySettingSlider(
              label: pickUiText(
                i18n,
                zh: '起步位数',
                en: 'Base digits',
                ja: 'ベースディジット',
                de: 'Base digits',
                fr: 'Chiffres de base',
                es: 'dígitos de base',
                ru: 'Базовые цифры',
              ),
              valueText: '$_customBaseDigits',
              value: _customBaseDigits.toDouble(),
              min: 1,
              max: 18,
              divisions: 17,
              onChanged: _roundBusy
                  ? null
                  : (value) =>
                        _applySetting(() => _customBaseDigits = value.round()),
            ),
          ],
          const SizedBox(height: 12),
          _NumberMemorySettingSlider(
            label: pickUiText(
              i18n,
              zh: '停留时间',
              en: 'Dwell time',
              ja: 'Dwell time',
              de: 'Dwell time',
              fr: 'Temps de repos',
              es: 'Dwell time',
              ru: 'Время ожидания',
            ),
            valueText: _formatMilliseconds(_displayMilliseconds),
            value: _displayMilliseconds.toDouble(),
            min: 100,
            max: 5000,
            divisions: 98,
            onChanged: _roundBusy
                ? null
                : (value) => _applySetting(
                    () => _setDisplayMilliseconds(value.round()),
                  ),
          ),
          _NumberMemoryNumberInput(
            key: const ValueKey<String>('number-memory-dwell-input'),
            label: pickUiText(
              i18n,
              zh: '直接输入毫秒',
              en: 'Exact milliseconds',
              ja: 'Exact milliseconds',
              de: 'Exact milliseconds',
              fr: 'millisecondes exactes',
              es: 'Exact milliseconds',
              ru: 'Точные миллисекунды',
            ),
            controller: _dwellController,
            suffix: 'ms',
            enabled: !_roundBusy,
            onApply: () => _applyIntInput(
              controller: _dwellController,
              min: 50,
              max: 60000,
              apply: _setDisplayMilliseconds,
            ),
          ),
          _NumberMemorySwitchTile(
            title: pickUiText(
              i18n,
              zh: '随机停留时间',
              en: 'Randomize dwell time',
              ja: 'Randomize dwell time',
              de: 'Randomize dwell time',
              fr: 'Randomiser le temps de séjour',
              es: 'Tiempo de residencia aleatorio',
              ru: 'Рандомизированное время пребывания',
            ),
            subtitle: pickUiText(
              i18n,
              zh: '每轮在当前时间附近轻微浮动',
              en: 'Each round drifts around the current dwell time.',
              ja: 'Each round drifts around the current dwell time.',
              de: 'Each round drifts around the current dwell time.',
              fr: 'Chaque tour dérive autour du temps d\'habitation du courant.',
              es: 'Cada ronda se desplaza alrededor del tiempo actual.',
              ru: 'Каждый раунд дрейфует вокруг текущего времени пребывания.',
            ),
            value: _randomizeDwell,
            onChanged: _roundBusy
                ? null
                : (value) => _applySetting(() => _randomizeDwell = value),
          ),
          if (_randomizeDwell) ...<Widget>[
            const SizedBox(height: 8),
            _NumberMemorySettingSlider(
              label: pickUiText(
                i18n,
                zh: '浮动范围',
                en: 'Dwell jitter',
                ja: 'Dwell jitter',
                de: 'Dwell jitter',
                fr: 'Bizarre',
                es: 'Dwell jitter',
                ru: 'Джиттер',
              ),
              valueText: '±$_dwellJitterMs ms',
              value: _dwellJitterMs.toDouble(),
              min: 0,
              max: 3000,
              divisions: 60,
              onChanged: _roundBusy
                  ? null
                  : (value) => _applySetting(() => _setJitterMs(value.round())),
            ),
            _NumberMemoryNumberInput(
              label: pickUiText(
                i18n,
                zh: '直接输入浮动',
                en: 'Exact jitter',
                ja: 'Exact jitter',
                de: 'Exact jitter',
                fr: 'C\'est exact.',
                es: 'Exact jitter',
                ru: 'Точное дрожание',
              ),
              controller: _jitterController,
              suffix: 'ms',
              enabled: !_roundBusy,
              onApply: () => _applyIntInput(
                controller: _jitterController,
                min: 0,
                max: 30000,
                apply: _setJitterMs,
              ),
            ),
          ],
          const SizedBox(height: 8),
          _NumberMemorySwitchTile(
            title: pickUiText(
              i18n,
              zh: '随机位数',
              en: 'Randomize length',
              ja: 'Randomize length',
              de: 'Randomize length',
              fr: 'randomiser la longueur',
              es: 'Longitud aleatoria',
              ru: 'Рандомизированная длина',
            ),
            subtitle: pickUiText(
              i18n,
              zh: '每轮在起步位数和当前等级之间抽一个长度',
              en: 'Each round picks a length between the base and current level.',
              ja: 'Each round picks a length between the base and current level.',
              de: 'Each round picks a length between the base and current level.',
              fr: 'Chaque tour prend une longueur entre la base et le niveau actuel.',
              es: 'Cada ronda elige una longitud entre la base y el nivel actual.',
              ru: 'Каждый раунд выбирает длину между базой и текущим уровнем.',
            ),
            value: _randomizeLength,
            onChanged: _roundBusy
                ? null
                : (value) => _applySetting(() => _randomizeLength = value),
          ),
          _NumberMemorySwitchTile(
            title: pickUiText(
              i18n,
              zh: '允许首位 0',
              en: 'Allow leading zero',
              ja: '先行ゼロを',
              de: 'Allow leading zero',
              fr: 'Allow leading zero',
              es: 'Permitir cero líder',
              ru: 'Позволяет вести ноль',
            ),
            subtitle: pickUiText(
              i18n,
              zh: '关闭后，多位数字不会以 0 开头',
              en: 'When off, multi-digit prompts will not start with 0.',
              ja: 'When off, multi-digit prompts will not start with 0.',
              de: 'When off, multi-digit prompts will not start with 0.',
              fr: 'Une fois éteints, les invites à plusieurs chiffres ne commenceront pas par 0.',
              es: 'Cuando esté apagado, los impulsos de varios dígitos no comenzarán con 0.',
              ru: 'При выключении многозначные подсказки не начнутся с 0.',
            ),
            value: _allowLeadingZero,
            onChanged: _roundBusy
                ? null
                : (value) => _applySetting(() => _allowLeadingZero = value),
          ),
          _NumberMemorySwitchTile(
            title: pickUiText(
              i18n,
              zh: '避免相邻重复',
              en: 'Avoid adjacent repeats',
              ja: '隣接する繰り返しを避ける',
              de: 'Avoid adjacent repeats',
              fr: 'Éviter les répétitions adjacentes',
              es: 'Evite las repeticiones adyacentes',
              ru: 'Избегайте соседних повторов',
            ),
            subtitle: pickUiText(
              i18n,
              zh: '少出现 11、77 这种挨在一起的重复',
              en: 'Reduces repeated neighbors such as 11 or 77.',
              ja: 'Reduces repeated neighbors such as 11 or 77.',
              de: 'Reduces repeated neighbors such as 11 or 77.',
              fr: 'Réduit les voisins répétés comme 11 ou 77.',
              es: 'Reduce los vecinos repetidos como 11 o 77.',
              ru: 'Уменьшает количество повторных соседей, таких как 11 или 77.',
            ),
            value: _avoidAdjacentRepeat,
            onChanged: _roundBusy
                ? null
                : (value) => _applySetting(() => _avoidAdjacentRepeat = value),
          ),
          ..._buildModeDetailSettings(context, i18n),
        ],
      ),
    );
  }
}
