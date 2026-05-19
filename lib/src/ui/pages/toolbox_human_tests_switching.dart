part of 'toolbox_human_tests.dart';

enum _SwitchTask { parity, color }

enum _SwitchPace {
  alternateEveryRound,
  alternateEveryTwo,
  alternateEveryThree,
  randomBlocks,
}

class DualTaskSwitchTestPage extends StatelessWidget {
  const DualTaskSwitchTestPage({super.key});

  static const Color _accent = Color(0xFFB05C5C);

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: pickUiText(
        i18n,
        zh: '双任务切换',
        en: 'Dual-task switching',
        ja: 'Dual-task switching',
        de: 'Dual-task switching',
        fr: 'Interrupteur à double tâche',
        es: 'Interruptor de dos discos',
        ru: 'Двойное задание',
      ),
      subtitle: pickUiText(
        i18n,
        zh: '在数字奇偶与颜色冷热判断之间来回切换，并观察切换代价。',
        en: 'Switch between digit parity and warm/cool color judgments while tracking switch cost.',
        ja: 'Switch between digit parity and warm/cool color judgments while tracking switch cost.',
        de: 'Switch between digit parity and warm/cool color judgments while tracking switch cost.',
        fr: 'Passez entre la parité des chiffres et les jugements de couleur chaud/froid tout en suivant le coût du commutateur.',
        es: 'Interruptor entre la paridad de dígitos y los juicios de color cálido / frío mientras el interruptor de seguimiento cuesta.',
        ru: 'Переключитесь между паритетом цифр и теплыми / холодными цветовыми решениями при отслеживании стоимости переключателя.',
      ),
      accent: _accent,
      icon: Icons.swap_horiz_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：选择切换节奏并开始一组交替判断',
        en: 'Next: choose a switch rhythm and start the alternating set',
        ja: 'Next: choose a switch rhythm and start the alternating set',
        de: 'Next: choose a switch rhythm and start the alternating set',
        fr: 'Suivant : choisissez un rythme de commutation et démarrez l\'ensemble alternatif',
        es: 'Siguiente: elegir un ritmo de cambio y comenzar el conjunto de alternancia',
        ru: 'Далее: выберите ритм переключения и запустите переменный набор',
      ),
      child: const _DualTaskSwitchCard(),
    );
  }
}

class _SwitchRoundRecord {
  const _SwitchRoundRecord({
    required this.task,
    required this.correct,
    required this.milliseconds,
    required this.switched,
  });

  final _SwitchTask task;
  final bool correct;
  final int milliseconds;
  final bool switched;
}

class _DualTaskSwitchCard extends StatefulWidget {
  const _DualTaskSwitchCard();

  @override
  State<_DualTaskSwitchCard> createState() => _DualTaskSwitchCardState();
}

class _DualTaskSwitchCardState extends State<_DualTaskSwitchCard> {
  static const Color _accent = DualTaskSwitchTestPage._accent;
  static const List<Color> _warmColors = <Color>[
    Color(0xFFD9723D),
    Color(0xFFC24D5A),
    Color(0xFFE0B43A),
  ];
  static const List<Color> _coolColors = <Color>[
    Color(0xFF3D6FD8),
    Color(0xFF3F9A6B),
    Color(0xFF4D8C9E),
  ];

  final math.Random _random = math.Random();
  final Stopwatch _stopwatch = Stopwatch();
  final List<_SwitchRoundRecord> _records = <_SwitchRoundRecord>[];
  Timer? _transitionTimer;

  _SwitchPace _pace = _SwitchPace.alternateEveryRound;
  int _roundCount = 12;
  int _roundIndex = 0;
  int _correct = 0;
  int _wrong = 0;
  int _switchRounds = 0;
  int _streak = 0;
  int _bestStreak = 0;
  bool _running = false;
  bool _done = false;
  bool? _lastCorrect;
  _SwitchTask _currentTask = _SwitchTask.parity;
  int _currentDigit = 1;
  Color _currentColor = const Color(0xFFD9723D);
  bool _currentWarm = true;
  List<_SwitchTask> _sequence = const <_SwitchTask>[];

  double get _accuracy {
    final total = _correct + _wrong;
    return total == 0 ? 0 : _correct / total;
  }

  int get _avgSwitchMs {
    final items = _records
        .where((item) => item.switched && item.correct)
        .toList(growable: false);
    if (items.isEmpty) {
      return 0;
    }
    final total = items.fold<int>(0, (sum, item) => sum + item.milliseconds);
    return (total / items.length).round();
  }

  int get _avgRepeatMs {
    final items = _records
        .where((item) => !item.switched && item.correct)
        .toList(growable: false);
    if (items.isEmpty) {
      return 0;
    }
    final total = items.fold<int>(0, (sum, item) => sum + item.milliseconds);
    return (total / items.length).round();
  }

  int get _switchCost {
    final switchMs = _avgSwitchMs;
    final repeatMs = _avgRepeatMs;
    if (switchMs == 0 || repeatMs == 0) {
      return 0;
    }
    return switchMs - repeatMs;
  }

  @override
  void initState() {
    super.initState();
    _buildSequence();
  }

  @override
  void dispose() {
    _transitionTimer?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    super.dispose();
  }

  void _setPace(_SwitchPace pace) {
    if (_pace == pace) {
      return;
    }
    setState(() {
      _pace = pace;
    });
    _reset();
  }

  void _buildSequence() {
    final sequence = <_SwitchTask>[];
    var current = _SwitchTask.parity;
    while (sequence.length < _roundCount) {
      final blockSize = switch (_pace) {
        _SwitchPace.alternateEveryRound => 1,
        _SwitchPace.alternateEveryTwo => 2,
        _SwitchPace.alternateEveryThree => 3,
        _SwitchPace.randomBlocks => 1 + _random.nextInt(3),
      };
      for (var i = 0; i < blockSize && sequence.length < _roundCount; i += 1) {
        sequence.add(current);
      }
      current = current == _SwitchTask.parity
          ? _SwitchTask.color
          : _SwitchTask.parity;
    }
    _sequence = sequence;
  }

  void _start() {
    _transitionTimer?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    _buildSequence();
    setState(() {
      _roundIndex = 0;
      _correct = 0;
      _wrong = 0;
      _switchRounds = 0;
      _streak = 0;
      _bestStreak = 0;
      _lastCorrect = null;
      _records.clear();
      _running = true;
      _done = false;
    });
    _beginRound();
  }

  void _reset() {
    _transitionTimer?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    _buildSequence();
    setState(() {
      _roundIndex = 0;
      _correct = 0;
      _wrong = 0;
      _switchRounds = 0;
      _streak = 0;
      _bestStreak = 0;
      _lastCorrect = null;
      _records.clear();
      _running = false;
      _done = false;
    });
  }

  void _beginRound() {
    if (!mounted || !_running) {
      return;
    }
    if (_roundIndex >= _roundCount) {
      _finish();
      return;
    }
    final nextTask = _sequence[_roundIndex];
    final previousTask = _roundIndex == 0 ? null : _sequence[_roundIndex - 1];
    final switched = previousTask != null && previousTask != nextTask;
    setState(() {
      _currentTask = nextTask;
      _currentDigit = 1 + _random.nextInt(9);
      _currentWarm = _random.nextBool();
      _currentColor = _currentWarm
          ? _sample(_random, _warmColors)
          : _sample(_random, _coolColors);
      _lastCorrect = null;
      if (switched) {
        _switchRounds += 1;
      }
      _stopwatch
        ..reset()
        ..start();
    });
  }

  String _taskLabel(AppI18n i18n, _SwitchTask task) {
    return switch (task) {
      _SwitchTask.parity => pickUiText(
        i18n,
        zh: '数字奇偶',
        en: 'Digit parity',
        ja: 'Digit parity',
        de: 'Digit parity',
        fr: 'Parité numérique',
        es: 'Digit parity',
        ru: 'Цифровой паритет',
      ),
      _SwitchTask.color => pickUiText(
        i18n,
        zh: '颜色冷热',
        en: 'Warm or cool',
        ja: 'Warm or cool',
        de: 'Warm or cool',
        fr: 'Chaud ou frais',
        es: 'Caliente o fresco',
        ru: 'Тепло или прохладно',
      ),
    };
  }

  String _taskPrompt(AppI18n i18n) {
    return switch (_currentTask) {
      _SwitchTask.parity => pickUiText(
        i18n,
        zh: '判断当前数字是奇数还是偶数。',
        en: 'Judge whether the current digit is odd or even.',
        ja: 'Judge whether the current digit is odd or even.',
        de: 'Judge whether the current digit is odd or even.',
        fr: 'Jugez si le chiffre actuel est étrange ou même.',
        es: 'Juzgue si el dígito actual es extraño o incluso.',
        ru: 'Оцените, является ли текущая цифра странной или четной.',
      ),
      _SwitchTask.color => pickUiText(
        i18n,
        zh: '判断当前颜色是暖色还是冷色。',
        en: 'Judge whether the current color is warm or cool.',
        ja: 'Judge whether the current color is warm or cool.',
        de: 'Judge whether the current color is warm or cool.',
        fr: 'Juger si la couleur actuelle est chaude ou fraîche.',
        es: 'Juzgue si el color actual es cálido o fresco.',
        ru: 'Определите, является ли текущий цвет теплым или холодным.',
      ),
    };
  }

  void _answer(bool correct) {
    if (!_running || _lastCorrect != null) {
      return;
    }
    _stopwatch.stop();
    final elapsed = math.max(1, _stopwatch.elapsedMilliseconds);
    final switched =
        _roundIndex > 0 && _sequence[_roundIndex] != _sequence[_roundIndex - 1];
    setState(() {
      _lastCorrect = correct;
      _records.add(
        _SwitchRoundRecord(
          task: _currentTask,
          correct: correct,
          milliseconds: elapsed,
          switched: switched,
        ),
      );
      _roundIndex += 1;
      if (correct) {
        _correct += 1;
        _streak += 1;
        _bestStreak = math.max(_bestStreak, _streak);
      } else {
        _wrong += 1;
        _streak = 0;
      }
      _done = _roundIndex >= _roundCount;
      if (_done) {
        _running = false;
      }
    });
    _transitionTimer?.cancel();
    _transitionTimer = Timer(const Duration(milliseconds: 560), () {
      if (!mounted) {
        return;
      }
      if (_done) {
        _finish();
      } else {
        _beginRound();
      }
    });
  }

  void _finish() {
    _transitionTimer?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    setState(() {
      _running = false;
      _done = true;
    });
    unawaited(_showReport());
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
                zh: '进度',
                en: 'Progress',
                ja: 'Progress',
                de: 'Progress',
                fr: 'Progrès accomplis',
                es: 'Progresos',
                ru: 'Прогресс',
              ),
              '$_roundIndex/$_roundCount',
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
              '${(_accuracy * 100).round()}%',
            ),
            (
              pickUiText(
                i18n,
                zh: '切换轮',
                en: 'Switch rounds',
                ja: 'Switch rounds',
                de: 'Switch rounds',
                fr: 'Interrupteurs',
                es: 'Cambio de rondas',
                ru: 'Переключать раунды',
              ),
              '$_switchRounds',
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
              '$_bestStreak',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _HumanPanel(child: _buildStage(context, i18n)),
        const SizedBox(height: 12),
        _HumanSettingsSection(
          title: pickUiText(
            i18n,
            zh: '双任务设置',
            en: 'Dual-task settings',
            ja: 'Dual-task settings',
            de: 'Dual-task settings',
            fr: 'Paramètres à double tâche',
            es: 'Ajustes de doble-tarea',
            ru: 'Параметры двойной задачи',
          ),
          subtitle: pickUiText(
            i18n,
            zh: '调整每轮切换节奏、题量与判断主题。',
            en: 'Adjust the switch rhythm, round count, and judgment theme.',
            ja: 'スイッチリズム、ラウンドカウント、判定テーマを調整します。',
            de: 'Adjust the switch rhythm, round count, and judgment theme.',
            fr: 'Adjust the switch rhythm, round count, and judgment theme.',
            es: 'Ajuste el ritmo de cambio, recuento redondo y el tema del juicio.',
            ru: 'Настройте ритм переключения, круглое количество и тему суждения.',
          ),
          child: _buildSettings(context, i18n),
        ),
      ],
    );
  }

  Widget _buildStage(BuildContext context, AppI18n i18n) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            SegmentedButton<_SwitchPace>(
              segments: <ButtonSegment<_SwitchPace>>[
                ButtonSegment<_SwitchPace>(
                  value: _SwitchPace.alternateEveryRound,
                  label: Text(
                    pickUiText(
                      i18n,
                      zh: '每轮切换',
                      en: 'Every round',
                      ja: 'Every round',
                      de: 'Every round',
                      fr: 'Chaque tour',
                      es: 'Cada ronda',
                      ru: 'Каждый раунд',
                    ),
                  ),
                ),
                ButtonSegment<_SwitchPace>(
                  value: _SwitchPace.alternateEveryTwo,
                  label: Text(
                    pickUiText(
                      i18n,
                      zh: '每两轮',
                      en: 'Every 2',
                      ja: 'Every 2',
                      de: 'Every 2',
                      fr: 'Tous les 2',
                      es: 'Cada 2',
                      ru: 'каждые 2',
                    ),
                  ),
                ),
                ButtonSegment<_SwitchPace>(
                  value: _SwitchPace.alternateEveryThree,
                  label: Text(
                    pickUiText(
                      i18n,
                      zh: '每三轮',
                      en: 'Every 3',
                      ja: 'Every 3',
                      de: 'Every 3',
                      fr: 'Tous les 3',
                      es: 'Cada 3',
                      ru: 'каждые 3',
                    ),
                  ),
                ),
                ButtonSegment<_SwitchPace>(
                  value: _SwitchPace.randomBlocks,
                  label: Text(
                    pickUiText(
                      i18n,
                      zh: '随机块',
                      en: 'Random blocks',
                      ja: 'Random blocks',
                      de: 'Random blocks',
                      fr: 'Blocs aléatoires',
                      es: 'Bloqueos aleatorios',
                      ru: 'Случайные блоки',
                    ),
                  ),
                ),
              ],
              selected: <_SwitchPace>{_pace},
              onSelectionChanged: _running
                  ? null
                  : (values) => _setPace(values.first),
            ),
            _HumanActionButton(
              label: _running
                  ? pickUiText(
                      i18n,
                      zh: '重新开始',
                      en: 'Restart',
                      ja: 'Restart',
                      de: 'Restart',
                      fr: 'Redémarrer',
                      es: 'Restart',
                      ru: 'Перезапустить',
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
              icon: _running ? Icons.replay_rounded : Icons.play_arrow_rounded,
              onPressed: _start,
            ),
            OutlinedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh_rounded),
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
        const SizedBox(height: 14),
        _HumanPanel(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: <Widget>[
              _HumanPill(text: _taskLabel(i18n, _currentTask), accent: _accent),
              const SizedBox(height: 10),
              Text(
                _taskPrompt(i18n),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: _currentTask == _SwitchTask.parity
                      ? _accent.withValues(alpha: 0.08)
                      : _currentColor.withValues(alpha: 0.12),
                  border: Border.all(
                    color: _currentTask == _SwitchTask.parity
                        ? _accent.withValues(alpha: 0.28)
                        : _currentColor.withValues(alpha: 0.34),
                  ),
                ),
                child: Column(
                  children: <Widget>[
                    Icon(
                      _currentTask == _SwitchTask.parity
                          ? Icons.pin_rounded
                          : Icons.palette_rounded,
                      size: 42,
                      color: _currentTask == _SwitchTask.parity
                          ? _accent
                          : _currentColor,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$_currentDigit',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentColor,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: _currentColor.withValues(alpha: 0.24),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (_currentTask == _SwitchTask.parity)
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: _running
                          ? () => _answer(_currentDigit.isOdd)
                          : null,
                      icon: const Icon(Icons.filter_1_rounded),
                      label: Text(
                        pickUiText(
                          i18n,
                          zh: '奇数',
                          en: 'Odd',
                          ja: 'Odd',
                          de: 'Odd',
                          fr: 'Curieuse',
                          es: 'Odd',
                          ru: 'странный',
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _running
                          ? () => _answer(_currentDigit.isEven)
                          : null,
                      icon: const Icon(Icons.filter_2_rounded),
                      label: Text(
                        pickUiText(
                          i18n,
                          zh: '偶数',
                          en: 'Even',
                          ja: 'Even',
                          de: 'Even',
                          fr: 'Même',
                          es: 'Incluso',
                          ru: 'Даже',
                        ),
                      ),
                    ),
                  ],
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: _running ? () => _answer(_currentWarm) : null,
                      icon: const Icon(Icons.wb_sunny_rounded),
                      label: Text(
                        pickUiText(
                          i18n,
                          zh: '暖色',
                          en: 'Warm',
                          ja: 'Warm',
                          de: 'Warm',
                          fr: 'Chaleur',
                          es: 'Warm',
                          ru: 'теплый',
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _running ? () => _answer(!_currentWarm) : null,
                      icon: const Icon(Icons.ac_unit_rounded),
                      label: Text(
                        pickUiText(
                          i18n,
                          zh: '冷色',
                          en: 'Cool',
                          ja: 'クール',
                          de: 'Cool',
                          fr: 'Frais',
                          es: 'Genial.',
                          ru: 'Круто',
                        ),
                      ),
                    ),
                  ],
                ),
              if (_lastCorrect != null) ...<Widget>[
                const SizedBox(height: 12),
                _HumanPill(
                  text: _lastCorrect!
                      ? pickUiText(
                          i18n,
                          zh: '上一轮正确',
                          en: 'Last round correct',
                          ja: 'Last round correct',
                          de: 'Last round correct',
                          fr: 'Dernier round correct',
                          es: 'Última ronda correcta',
                          ru: 'Последний раунд правильный',
                        )
                      : pickUiText(
                          i18n,
                          zh: '上一轮失误',
                          en: 'Last round missed',
                          ja: 'Last round missed',
                          de: 'Last round missed',
                          fr: 'Dernier tour manqué',
                          es: 'Última ronda perdida',
                          ru: 'Последний пропущенный раунд',
                        ),
                  accent: _lastCorrect!
                      ? const Color(0xFF4E8B6B)
                      : Colors.redAccent,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettings(BuildContext context, AppI18n i18n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          pickUiText(
            i18n,
            zh: '轮数',
            en: 'Rounds',
            ja: 'Rounds',
            de: 'Rounds',
            fr: 'Rondes',
            es: 'Rondas',
            ru: 'Круги',
          ),
        ),
        Wrap(
          spacing: 8,
          children: <int>[8, 12, 16, 20]
              .map(
                (value) => ChoiceChip(
                  label: Text('$value'),
                  selected: _roundCount == value,
                  onSelected: _running
                      ? null
                      : (_) => setState(() => _roundCount = value),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 12),
        Text(
          pickUiText(
            i18n,
            zh: '切换主题',
            en: 'Task theme',
            ja: 'Task theme',
            de: 'Task theme',
            fr: 'Thème de tâche',
            es: 'Tema de la tarea',
            ru: 'Тема задания',
          ),
        ),
        Text(
          pickUiText(
            i18n,
            zh: '数字奇偶与颜色冷热交替出现，帮助观察切换代价。',
            en: 'Digit parity and warm/cool color cues alternate to reveal switch cost.',
            ja: 'Digit parity and warm/cool color cues alternate to reveal switch cost.',
            de: 'Digit parity and warm/cool color cues alternate to reveal switch cost.',
            fr: 'La parité numérique et les indices de couleur chaud/froid alternent pour révéler le coût du commutateur.',
            es: 'Digit parity and warm/cool color cues alternan para revelar el coste del interruptor.',
            ru: 'Цифровой паритет и теплые / холодные цветовые сигналы чередуются, чтобы выявить стоимость переключения.',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Future<void> _showReport() async {
    if (!mounted || _records.isEmpty) {
      return;
    }
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            pickUiText(
              i18n,
              zh: '双任务切换报告',
              en: 'Dual-task report',
              ja: 'Dual-task report',
              de: 'Dual-task report',
              fr: 'Rapport à double tâche',
              es: 'Informe de doble análisis',
              ru: 'Отчет о двух задачах',
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _HumanMetricWrap(
                  metrics: <(String, String)>[
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
                      '${(_accuracy * 100).round()}%',
                    ),
                    (
                      pickUiText(
                        i18n,
                        zh: '切换代价',
                        en: 'Switch cost',
                        ja: 'Switch cost',
                        de: 'Switch cost',
                        fr: 'Coût de commutation',
                        es: 'Costo de conmutación',
                        ru: 'Стоимость коммутатора',
                      ),
                      _switchCost == 0 ? '-' : _formatMilliseconds(_switchCost),
                    ),
                    (
                      pickUiText(
                        i18n,
                        zh: '切换轮',
                        en: 'Switch rounds',
                        ja: 'Switch rounds',
                        de: 'Switch rounds',
                        fr: 'Interrupteurs',
                        es: 'Cambio de rondas',
                        ru: 'Переключать раунды',
                      ),
                      '$_switchRounds',
                    ),
                    (
                      pickUiText(
                        i18n,
                        zh: '最佳连击',
                        en: 'Best streak',
                        ja: 'ベストストリーク',
                        de: 'Best streak',
                        fr: 'Meilleure série',
                        es: 'La mejor racha',
                        ru: 'Лучшая полоса',
                      ),
                      '$_bestStreak',
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
                          zh: '重复轮平均',
                          en: 'Repeat average',
                          ja: 'Repeat average',
                          de: 'Repeat average',
                          fr: 'Répéter la moyenne',
                          es: 'Promedio de repetición',
                          ru: 'Повторить средний',
                        ),
                      ),
                      Text(
                        _avgRepeatMs == 0
                            ? '-'
                            : _formatMilliseconds(_avgRepeatMs),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        pickUiText(
                          i18n,
                          zh: '切换轮平均',
                          en: 'Switch average',
                          ja: 'Switch average',
                          de: 'Switch average',
                          fr: 'Moyenne des changements',
                          es: 'Interruptor promedio',
                          ru: 'Средняя коммутация',
                        ),
                      ),
                      Text(
                        _avgSwitchMs == 0
                            ? '-'
                            : _formatMilliseconds(_avgSwitchMs),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                pickUiText(
                  i18n,
                  zh: '关闭',
                  en: 'Close',
                  ja: '閉じる',
                  de: 'Close',
                  fr: 'Fermer',
                  es: 'Cerca',
                  ru: 'Закрыть',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
