part of 'toolbox_human_tests.dart';

class NumberMemoryTestPage extends StatelessWidget {
  const NumberMemoryTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: pickUiText(i18n, zh: '数字记忆', en: 'Number memory'),
      subtitle: pickUiText(
        i18n,
        zh: '看数字、认颜色、找目标组，也可以心算；停留时间能精确到毫秒。',
        en: 'Recall numbers, track colors, pick target groups, or solve quick equations; dwell time can be set by the millisecond.',
      ),
      accent: const Color(0xFF536CC7),
      icon: Icons.pin_rounded,
      status: pickUiText(
        i18n,
        zh: '选个玩法，调好停留时间，就可以开始',
        en: 'Pick a mode, set the dwell time, then start',
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
        _NumberMemoryColorSpec(color: Color(0xFFE35D6A), zh: '红色', en: 'Red'),
        _NumberMemoryColorSpec(color: Color(0xFF4F83D1), zh: '蓝色', en: 'Blue'),
        _NumberMemoryColorSpec(color: Color(0xFF43A66E), zh: '绿色', en: 'Green'),
        _NumberMemoryColorSpec(color: Color(0xFFD39A35), zh: '琥珀', en: 'Amber'),
        _NumberMemoryColorSpec(
          color: Color(0xFF8B6AD4),
          zh: '紫色',
          en: 'Purple',
        ),
        _NumberMemoryColorSpec(color: Color(0xFF36A7B2), zh: '青色', en: 'Cyan'),
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
      ),
      _NumberMemoryDifficulty.intermediate => pickUiText(
        i18n,
        zh: '中级',
        en: 'Intermediate',
      ),
      _NumberMemoryDifficulty.advanced => pickUiText(
        i18n,
        zh: '高级',
        en: 'Advanced',
      ),
      _NumberMemoryDifficulty.custom => pickUiText(
        i18n,
        zh: '自定义',
        en: 'Custom',
      ),
    };
  }

  String _modeLabel(AppI18n i18n, _NumberMemoryMode value) {
    return switch (value) {
      _NumberMemoryMode.digits => pickUiText(
        i18n,
        zh: '数字串',
        en: 'Digit string',
      ),
      _NumberMemoryMode.coloredDigits => pickUiText(
        i18n,
        zh: '彩色数字',
        en: 'Colored digits',
      ),
      _NumberMemoryMode.multiTarget => pickUiText(
        i18n,
        zh: '多数字目标',
        en: 'Multi-target',
      ),
      _NumberMemoryMode.equation => pickUiText(i18n, zh: '计算式', en: 'Equation'),
    };
  }

  String _modeDescription(AppI18n i18n, _NumberMemoryMode value) {
    return switch (value) {
      _NumberMemoryMode.digits => pickUiText(
        i18n,
        zh: '看一眼，数字藏起来后原样写回。',
        en: 'Take a look, then type the digits back after they hide.',
      ),
      _NumberMemoryMode.coloredDigits => pickUiText(
        i18n,
        zh: '只记目标颜色上的数字，别被其他颜色带偏。',
        en: 'Remember only the digits in the target color.',
      ),
      _NumberMemoryMode.multiTarget => pickUiText(
        i18n,
        zh: '几组数字一起出现，只写指定那一组。',
        en: 'Several groups appear at once; type the requested one.',
      ),
      _NumberMemoryMode.equation => pickUiText(
        i18n,
        zh: '先看式子并心算，藏起来后写结果。',
        en: 'Read the expression, solve it mentally, then type the result.',
      ),
    };
  }

  String _colorName(AppI18n i18n, _NumberMemoryColorSpec color) {
    return pickUiText(i18n, zh: color.zh, en: color.en);
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
      inputZh: '把整串数字写回',
      inputEn: 'Type the whole string back',
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
    return _NumberMemoryRound(
      mode: _NumberMemoryMode.coloredDigits,
      answer: answer,
      displayText: tokens.map((token) => token.text).join(),
      tokens: List<_NumberMemoryToken>.unmodifiable(tokens),
      groups: const <_NumberMemoryGroup>[],
      targetColor: targetColor,
      targetZh: '这轮只记${targetColor.zh}数字',
      targetEn: 'This round: ${targetColor.en.toLowerCase()} digits',
      inputZh: '只写${targetColor.zh}数字',
      inputEn: 'Type the ${targetColor.en.toLowerCase()} digits',
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
      inputZh: '写下 ${target.label} 组数字',
      inputEn: 'Type group ${target.label}',
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
      inputZh: '写下计算结果',
      inputEn: 'Type the result',
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
        ? pickUiText(i18n, zh: '留空', en: 'Blank')
        : result.answer;
    final title = result.correct
        ? pickUiText(i18n, zh: '本轮通过', en: 'Round passed')
        : pickUiText(i18n, zh: '这轮没对', en: 'Round missed');
    final note = result.correct
        ? pickUiText(
            i18n,
            zh: '已经过了 ${result.level} 级，下一轮从 $_level 级开始。',
            en: 'Level ${result.level} is cleared. The next round starts at level $_level.',
          )
        : pickUiText(
            i18n,
            zh: '先看一眼差在哪里，再决定要不要重来。',
            en: 'Check the gap first, then decide when to retry.',
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
                    label: pickUiText(i18n, zh: '模式', en: 'Mode'),
                    value: _modeLabel(i18n, result.mode),
                  ),
                  _NumberMemoryReportRow(
                    label: pickUiText(i18n, zh: '等级', en: 'Level'),
                    value: '${result.level}',
                  ),
                  _NumberMemoryReportRow(
                    label: pickUiText(i18n, zh: '规模', en: 'Size'),
                    value: result.sizeLabel,
                  ),
                  _NumberMemoryReportRow(
                    label: pickUiText(i18n, zh: '本轮目标', en: 'Prompt'),
                    value: pickUiText(
                      i18n,
                      zh: round.targetZh,
                      en: round.targetEn,
                    ),
                  ),
                  _NumberMemoryReportRow(
                    label: pickUiText(i18n, zh: '停留', en: 'Dwell'),
                    value: _formatMilliseconds(result.dwellMs),
                  ),
                  _NumberMemoryReportRow(
                    label: pickUiText(i18n, zh: '正确答案', en: 'Expected'),
                    value: result.expected,
                    mono: true,
                  ),
                  _NumberMemoryReportRow(
                    label: pickUiText(i18n, zh: '你的输入', en: 'Your answer'),
                    value: answerText,
                    mono: result.answer.isNotEmpty,
                  ),
                  _NumberMemoryReportRow(
                    label: pickUiText(i18n, zh: '累计正确率', en: 'Accuracy'),
                    value: '$_correct/$_attempts · $accuracy%',
                  ),
                  _NumberMemoryReportRow(
                    label: pickUiText(i18n, zh: '最好等级', en: 'Best level'),
                    value: '$_bestLevel',
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(pickUiText(i18n, zh: '先停一下', en: 'Stay here')),
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
                    ? pickUiText(i18n, zh: '下一轮', en: 'Next round')
                    : pickUiText(i18n, zh: '再来一轮', en: 'Try again'),
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
      return pickUiText(i18n, zh: '未开始', en: 'Not started');
    }
    final rate = (_correct / _attempts * 100).round();
    return '$_correct/$_attempts · $rate%';
  }

  String _stageStatus(AppI18n i18n) {
    if (_showing) {
      return pickUiText(i18n, zh: '正在显示', en: 'Showing');
    }
    if (_input) {
      return pickUiText(i18n, zh: '等待输入', en: 'Awaiting input');
    }
    if (_failed) {
      return pickUiText(i18n, zh: '本轮错误', en: 'Missed');
    }
    return pickUiText(i18n, zh: '准备', en: 'Ready');
  }

  String _feedbackText(AppI18n i18n) {
    final round = _round;
    if (round == null) {
      return _modeDescription(i18n, _mode);
    }
    if (_showing) {
      return pickUiText(i18n, zh: round.targetZh, en: round.targetEn);
    }
    if (_input) {
      return pickUiText(i18n, zh: round.inputZh, en: round.inputEn);
    }
    if (_failed) {
      return pickUiText(
        i18n,
        zh: '正确答案：${round.answer}',
        en: 'Answer: ${round.answer}',
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
            (pickUiText(i18n, zh: '等级', en: 'Level'), '$_level'),
            (
              pickUiText(i18n, zh: '规模', en: 'Size'),
              _round?.sizeLabel ?? '$_currentDigits',
            ),
            (
              pickUiText(i18n, zh: '停留', en: 'Dwell'),
              _formatMilliseconds(_lastDwellMs),
            ),
            (pickUiText(i18n, zh: '模式', en: 'Mode'), modeLabel),
            (pickUiText(i18n, zh: '成绩', en: 'Score'), _scoreLabel(i18n)),
          ],
        ),
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
                      ? pickUiText(i18n, zh: '输入答案', en: 'Type answer')
                      : pickUiText(
                          i18n,
                          zh: _round!.inputZh,
                          en: _round!.inputEn,
                        ),
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
                        ? pickUiText(i18n, zh: '提交', en: 'Submit')
                        : pickUiText(i18n, zh: '开始', en: 'Start'),
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
                    label: Text(pickUiText(i18n, zh: '清空', en: 'Reset')),
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
              const SizedBox(height: 12),
              _buildSettings(context, i18n, difficultyLabel),
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
        ? pickUiText(i18n, zh: '答案', en: 'Answer')
        : _input
        ? pickUiText(i18n, zh: '请复现', en: 'Recall now')
        : pickUiText(i18n, zh: '准备', en: 'Ready');
    final value = _failed && round != null
        ? round.answer
        : _input && round != null
        ? pickUiText(i18n, zh: round.inputZh, en: round.inputEn)
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
      title: pickUiText(i18n, zh: '训练设置', en: 'Training settings'),
      subtitle: pickUiText(
        i18n,
        zh: '换玩法、调停留时间，也可以加一点随机性',
        en: 'Change the mode, tune dwell time, or add a little randomness.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            pickUiText(i18n, zh: '模式', en: 'Mode'),
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
            '${pickUiText(i18n, zh: '起始难度', en: 'Starting difficulty')} · $difficultyLabel',
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
              label: pickUiText(i18n, zh: '起步位数', en: 'Base digits'),
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
            label: pickUiText(i18n, zh: '停留时间', en: 'Dwell time'),
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
            label: pickUiText(i18n, zh: '直接输入毫秒', en: 'Exact milliseconds'),
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
            title: pickUiText(i18n, zh: '随机停留时间', en: 'Randomize dwell time'),
            subtitle: pickUiText(
              i18n,
              zh: '每轮在当前时间附近轻微浮动',
              en: 'Each round drifts around the current dwell time.',
            ),
            value: _randomizeDwell,
            onChanged: _roundBusy
                ? null
                : (value) => _applySetting(() => _randomizeDwell = value),
          ),
          if (_randomizeDwell) ...<Widget>[
            const SizedBox(height: 8),
            _NumberMemorySettingSlider(
              label: pickUiText(i18n, zh: '浮动范围', en: 'Dwell jitter'),
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
              label: pickUiText(i18n, zh: '直接输入浮动', en: 'Exact jitter'),
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
            title: pickUiText(i18n, zh: '随机位数', en: 'Randomize length'),
            subtitle: pickUiText(
              i18n,
              zh: '每轮在起步位数和当前等级之间抽一个长度',
              en: 'Each round picks a length between the base and current level.',
            ),
            value: _randomizeLength,
            onChanged: _roundBusy
                ? null
                : (value) => _applySetting(() => _randomizeLength = value),
          ),
          _NumberMemorySwitchTile(
            title: pickUiText(i18n, zh: '允许首位 0', en: 'Allow leading zero'),
            subtitle: pickUiText(
              i18n,
              zh: '关闭后，多位数字不会以 0 开头',
              en: 'When off, multi-digit prompts will not start with 0.',
            ),
            value: _allowLeadingZero,
            onChanged: _roundBusy
                ? null
                : (value) => _applySetting(() => _allowLeadingZero = value),
          ),
          _NumberMemorySwitchTile(
            title: pickUiText(i18n, zh: '避免相邻重复', en: 'Avoid adjacent repeats'),
            subtitle: pickUiText(
              i18n,
              zh: '少出现 11、77 这种挨在一起的重复',
              en: 'Reduces repeated neighbors such as 11 or 77.',
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
