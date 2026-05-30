part of 'toolbox_human_tests.dart';

class NumberMemoryTestPage extends StatelessWidget {
  const NumberMemoryTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_number_memory.number_memory_f515d6',
      ),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests_number_memory.recall_numbers_track_colors_pick_target_groups_or_solve_de8cff',
      ),
      accent: const Color(0xFF536CC7),
      icon: Icons.pin_rounded,
      status: i18n.t(
        'inline.ui.pages.toolbox_human_tests_number_memory.pick_a_mode_set_the_dwell_time_then_start_b371b2',
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
  static const List<_NumberMemoryColorSpec>
  _colorPalette = <_NumberMemoryColorSpec>[
    _NumberMemoryColorSpec(
      color: Color(0xFFE35D6A),
      labelKey: 'inline.plan297.human_tests.number_memory.color.red.5b305b87c4',
    ),
    _NumberMemoryColorSpec(
      color: Color(0xFF4F83D1),
      labelKey:
          'inline.plan297.human_tests.number_memory.color.blue.394c2aeb6b',
    ),
    _NumberMemoryColorSpec(
      color: Color(0xFF43A66E),
      labelKey:
          'inline.plan297.human_tests.number_memory.color.green.da98bd23c6',
    ),
    _NumberMemoryColorSpec(
      color: Color(0xFFD39A35),
      labelKey:
          'inline.plan297.human_tests.number_memory.color.amber.e2b661ccf3',
    ),
    _NumberMemoryColorSpec(
      color: Color(0xFF8B6AD4),
      labelKey:
          'inline.plan297.human_tests.number_memory.color.purple.e954e26275',
    ),
    _NumberMemoryColorSpec(
      color: Color(0xFF36A7B2),
      labelKey:
          'inline.plan297.human_tests.number_memory.color.cyan.9b1b38ce52',
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
      _NumberMemoryDifficulty.beginner => i18n.t(
        'inline.ui.pages.toolbox_human_tests_number_memory.beginner_db4a15',
      ),
      _NumberMemoryDifficulty.intermediate => i18n.t(
        'inline.ui.pages.toolbox_human_tests_number_memory.intermediate_ad2965',
      ),
      _NumberMemoryDifficulty.advanced => i18n.t('toolbox.breathing.advanced'),
      _NumberMemoryDifficulty.custom => i18n.t('toolbox.sound.harp.custom'),
    };
  }

  String _modeLabel(AppI18n i18n, _NumberMemoryMode value) {
    return switch (value) {
      _NumberMemoryMode.digits => i18n.t(
        'inline.ui.pages.toolbox_human_tests_number_memory.digit_string_20866a',
      ),
      _NumberMemoryMode.coloredDigits => i18n.t(
        'inline.ui.pages.toolbox_human_tests_number_memory.colored_digits_b2e742',
      ),
      _NumberMemoryMode.multiTarget => i18n.t(
        'inline.ui.pages.toolbox_human_tests_number_memory.multi_target_483694',
      ),
      _NumberMemoryMode.equation => i18n.t(
        'inline.ui.pages.toolbox_human_tests_number_memory.equation_eafa69',
      ),
    };
  }

  String _modeDescription(AppI18n i18n, _NumberMemoryMode value) {
    return switch (value) {
      _NumberMemoryMode.digits => i18n.t(
        'inline.ui.pages.toolbox_human_tests_number_memory.take_a_look_then_type_the_digits_back_after_they_hide_2b82f0',
      ),
      _NumberMemoryMode.coloredDigits => i18n.t(
        'inline.ui.pages.toolbox_human_tests_number_memory.remember_only_the_digits_in_the_target_color_94d5d2',
      ),
      _NumberMemoryMode.multiTarget => i18n.t(
        'inline.ui.pages.toolbox_human_tests_number_memory.several_groups_appear_at_once_type_the_requested_one_388c92',
      ),
      _NumberMemoryMode.equation => i18n.t(
        'inline.ui.pages.toolbox_human_tests_number_memory.read_the_expression_solve_it_mentally_then_type_the_resu_cc4afc',
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
      targetKey: 'inline.plan297.human_tests.number_memory.target.digits',
      inputKey: 'inline.plan297.human_tests.number_memory.input.digits',

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
      targetKey: 'inline.plan297.human_tests.number_memory.target.color_digits',
      inputKey: 'inline.plan297.human_tests.number_memory.input.color_digits',

      sizeLabel: '$digitCount/${targetColor.sizeToken}',
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
      targetKey: 'inline.plan297.human_tests.number_memory.target.multi_group',
      inputKey: 'inline.plan297.human_tests.number_memory.input.multi_group',
      targetGroupLabel: target.label,
      targetColor: target.color,

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
      targetKey: 'inline.plan297.human_tests.number_memory.target.equation',
      inputKey: 'inline.plan297.human_tests.number_memory.input.equation',

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
        ? i18n.t(
            'inline.ui.pages.toolbox_human_tests_auditory_lab.blank_06d198',
          )
        : result.answer;
    final title = result.correct
        ? i18n.t(
            'inline.ui.pages.toolbox_human_tests_number_memory.round_passed_599d19',
          )
        : i18n.t(
            'inline.ui.pages.toolbox_human_tests_number_memory.round_missed_92b24c',
          );
    final note = result.correct
        ? i18n.t(
            'inline.ui.pages.toolbox_human_tests_number_memory.level_result_level_is_cleared_the_next_round_starts_at_l_14621e',
            params: <String, Object?>{
              'resultLevel': result.level,
              'level': _level,
            },
          )
        : i18n.t(
            'inline.ui.pages.toolbox_human_tests_number_memory.check_the_gap_first_then_decide_when_to_retry_e962de',
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
                    label: i18n.t('toolbox.sound.piano.mode'),
                    value: _modeLabel(i18n, result.mode),
                  ),
                  _NumberMemoryReportRow(
                    label: i18n.t('toolbox.sound.pickup.level'),
                    value: '${result.level}',
                  ),
                  _NumberMemoryReportRow(
                    label: i18n.t('inline.plan295.life.size.5d3d989d937b'),
                    value: result.sizeLabel,
                  ),
                  _NumberMemoryReportRow(
                    label: i18n.t(
                      'inline.ui.pages.toolbox_human_tests_number_memory.prompt_1f7536',
                    ),
                    value: round.targetText(i18n),
                  ),
                  _NumberMemoryReportRow(
                    label: i18n.t(
                      'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.dwell_ab2a6f',
                    ),
                    value: _formatMilliseconds(result.dwellMs),
                  ),
                  _NumberMemoryReportRow(
                    label: i18n.t('inline.plan295.life.expected.46e4595f7ecd'),
                    value: result.expected,
                    mono: true,
                  ),
                  _NumberMemoryReportRow(
                    label: i18n.t(
                      'inline.ui.pages.toolbox_human_tests_cognition.your_answer_bd179d',
                    ),
                    value: answerText,
                    mono: result.answer.isNotEmpty,
                  ),
                  _NumberMemoryReportRow(
                    label: i18n.t(
                      'inline.ui.pages.practice_review_page.accuracy_8cf5a1',
                    ),
                    value: '$_correct/$_attempts · $accuracy%',
                  ),
                  _NumberMemoryReportRow(
                    label: i18n.t(
                      'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.best_level_6b13a1',
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
                i18n.t(
                  'inline.ui.pages.toolbox_human_tests_number_memory.stay_here_36b26c',
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
                    ? i18n.t(
                        'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.next_round_ad9935',
                      )
                    : i18n.t(
                        'inline.ui.pages.toolbox_human_tests_number_memory.try_again_1c03a7',
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
      return i18n.t('toolbox.sleep.winddown.notStarted');
    }
    final rate = (_correct / _attempts * 100).round();
    return '$_correct/$_attempts · $rate%';
  }

  String _stageStatus(AppI18n i18n) {
    if (_showing) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_number_memory.showing_d3e825',
      );
    }
    if (_input) {
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_bimanual.awaiting_input_75ae4b',
      );
    }
    if (_failed) {
      return i18n.t('toolbox.sleep.rhythm.missed');
    }
    return i18n.t('timerIdle');
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
      return i18n.t(
        'inline.ui.pages.toolbox_human_tests_number_memory.answer_round_answer_8967a5',
        params: <String, Object?>{'answer': round.answer},
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
            (i18n.t('toolbox.sound.pickup.level'), '$_level'),
            (
              i18n.t('inline.plan295.life.size.5d3d989d937b'),
              _round?.sizeLabel ?? '$_currentDigits',
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_dynamic_vision_ui.dwell_ab2a6f',
              ),
              _formatMilliseconds(_lastDwellMs),
            ),
            (i18n.t('toolbox.sound.piano.mode'), modeLabel),
            (
              i18n.t('inline.plan295.life.score.e58eff17f23d'),
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
                      ? i18n.t(
                          'inline.ui.pages.toolbox_human_tests_number_memory.type_answer_dcbabd',
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
                        ? i18n.t(
                            'inline.ui.pages.practice_session_page.submit_4bdd5b',
                          )
                        : i18n.t('toolbox.breathing.start'),
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
                      i18n.t('inline.plan295.daily_choice.reset.7b99f32b7636'),
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
                  i18n.t(
                    'inline.ui.pages.toolbox_human_tests_number_memory.match_targetcolor_en_tolowercase_4ba898',
                    params: <String, Object?>{
                      'targetColorEn': _colorName(
                        i18n,
                        targetColor,
                      ).toLowerCase(),
                    },
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
                        ? i18n.t(
                            'inline.ui.pages.toolbox_human_tests_number_memory.group_label_target_32b708',
                            params: <String, Object?>{
                              'groupLabel': group.label,
                            },
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
        ? i18n.t('inline.ui.pages.toolbox_human_tests_cognition.answer_84bc22')
        : _input
        ? i18n.t(
            'inline.ui.pages.toolbox_human_tests_number_memory.recall_now_d62e6b',
          )
        : i18n.t('timerIdle');
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
                  i18n.t(
                    'inline.ui.pages.toolbox_human_tests_number_memory.only_targetcolor_en_tolowercase_digits_b2db7c',
                    params: <String, Object?>{
                      'targetColorEn': _colorName(
                        i18n,
                        targetColor,
                      ).toLowerCase(),
                    },
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
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_number_memory.training_settings_b3bcbb',
      ),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests_number_memory.change_the_mode_tune_dwell_time_or_add_a_little_randomne_8e446d',
      ),
      child: Column(
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
            '${i18n.t('inline.ui.pages.toolbox_human_tests_number_memory.starting_difficulty_8a08c4')} · $difficultyLabel',
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
              label: i18n.t(
                'inline.ui.pages.toolbox_human_tests_number_memory.base_digits_654235',
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
            label: i18n.t(
              'inline.ui.pages.toolbox_human_tests_number_memory.dwell_time_8a8b7b',
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
            label: i18n.t(
              'inline.ui.pages.toolbox_human_tests_number_memory.exact_milliseconds_5d9e82',
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
            title: i18n.t(
              'inline.ui.pages.toolbox_human_tests_number_memory.randomize_dwell_time_5bfd8d',
            ),
            subtitle: i18n.t(
              'inline.ui.pages.toolbox_human_tests_number_memory.each_round_drifts_around_the_current_dwell_time_fd8ae2',
            ),
            value: _randomizeDwell,
            onChanged: _roundBusy
                ? null
                : (value) => _applySetting(() => _randomizeDwell = value),
          ),
          if (_randomizeDwell) ...<Widget>[
            const SizedBox(height: 8),
            _NumberMemorySettingSlider(
              label: i18n.t(
                'inline.ui.pages.toolbox_human_tests_number_memory.dwell_jitter_f4c421',
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
              label: i18n.t(
                'inline.ui.pages.toolbox_human_tests_number_memory.exact_jitter_102788',
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
            title: i18n.t(
              'inline.ui.pages.toolbox_human_tests_number_memory.randomize_length_010e8e',
            ),
            subtitle: i18n.t(
              'inline.ui.pages.toolbox_human_tests_number_memory.each_round_picks_a_length_between_the_base_and_current_l_9e2e92',
            ),
            value: _randomizeLength,
            onChanged: _roundBusy
                ? null
                : (value) => _applySetting(() => _randomizeLength = value),
          ),
          _NumberMemorySwitchTile(
            title: i18n.t(
              'inline.ui.pages.toolbox_human_tests_number_memory.allow_leading_zero_ee558e',
            ),
            subtitle: i18n.t(
              'inline.ui.pages.toolbox_human_tests_number_memory.when_off_multi_digit_prompts_will_not_start_with_0_18c1fa',
            ),
            value: _allowLeadingZero,
            onChanged: _roundBusy
                ? null
                : (value) => _applySetting(() => _allowLeadingZero = value),
          ),
          _NumberMemorySwitchTile(
            title: i18n.t(
              'inline.ui.pages.toolbox_human_tests_number_memory.avoid_adjacent_repeats_1984a8',
            ),
            subtitle: i18n.t(
              'inline.ui.pages.toolbox_human_tests_number_memory.reduces_repeated_neighbors_such_as_11_or_77_0419ec',
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
