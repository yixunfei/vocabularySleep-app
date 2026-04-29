part of 'toolbox_human_tests.dart';

class TypingTestPage extends StatelessWidget {
  const TypingTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: pickUiText(i18n, zh: '打字测试', en: 'Typing test'),
      subtitle: pickUiText(
        i18n,
        zh: '输入给定短句，完成后显示速度和准确率。',
        en: 'Type the given passage. Speed and accuracy appear when you finish.',
      ),
      accent: const Color(0xFFC27A37),
      icon: Icons.keyboard_alt_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：点击输入框开始',
        en: 'Next: focus the text field',
      ),
      child: const _TypingTestCard(),
    );
  }
}

class _TypingTestCard extends StatefulWidget {
  const _TypingTestCard();

  @override
  State<_TypingTestCard> createState() => _TypingTestCardState();
}

class _TypingTestCardState extends State<_TypingTestCard> {
  final TextEditingController _controller = TextEditingController();
  final Stopwatch _stopwatch = Stopwatch();
  String? _passage;
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _selectPassage(AppI18n i18n) {
    final passages = pickUiText(
      i18n,
      zh: '清醒的注意力来自稳定的呼吸和温柔的节奏。|今晚把单词放慢一点，记忆会自己留下痕迹。|工具箱里的小测试适合用来做一次轻量复盘。',
      en: 'A calm mind can move quickly without feeling rushed.|Memory improves when attention has a gentle rhythm.|Small tests can turn a short break into useful feedback.',
    ).split('|');
    return passages[DateTime.now().millisecondsSinceEpoch % passages.length];
  }

  void _ensurePassage(AppI18n i18n) {
    _passage ??= _selectPassage(i18n);
  }

  void _onChanged(String value) {
    if (!_stopwatch.isRunning && value.isNotEmpty && !_done) {
      _stopwatch.start();
    }
    if (value == _passage && !_done) {
      _stopwatch.stop();
      setState(() => _done = true);
    } else {
      setState(() {});
    }
  }

  void _reset(AppI18n i18n) {
    _controller.clear();
    _stopwatch
      ..stop()
      ..reset();
    setState(() {
      _passage = _selectPassage(i18n);
      _done = false;
    });
  }

  double _accuracy(String input, String target) {
    if (input.isEmpty) {
      return 0;
    }
    var correct = 0;
    final length = math.min(input.length, target.length);
    for (var i = 0; i < length; i += 1) {
      if (input[i] == target[i]) {
        correct += 1;
      }
    }
    return correct / input.length * 100;
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    _ensurePassage(i18n);
    final passage = _passage!;
    final input = _controller.text;
    final elapsedMinutes = _stopwatch.elapsedMilliseconds / 60000;
    final wpm = _done && elapsedMinutes > 0
        ? (passage.characters.length / 5) / elapsedMinutes
        : 0.0;
    final accuracy = _accuracy(input, passage);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (
              pickUiText(i18n, zh: '速度', en: 'Speed'),
              _done ? '${wpm.round()} WPM' : '-',
            ),
            (
              pickUiText(i18n, zh: '准确率', en: 'Accuracy'),
              input.isEmpty ? '-' : '${accuracy.round()}%',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _HumanPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                passage,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _controller,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: pickUiText(
                    i18n,
                    zh: '输入上方文字',
                    en: 'Type the text above',
                  ),
                  border: const OutlineInputBorder(),
                ),
                onChanged: _onChanged,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _reset(i18n),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(pickUiText(i18n, zh: '换一句', en: 'New passage')),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class StroopTestPage extends StatelessWidget {
  const StroopTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: pickUiText(i18n, zh: '斯特鲁普', en: 'Stroop test'),
      subtitle: pickUiText(
        i18n,
        zh: '判断文字含义和显示颜色是否一致，抵抗自动阅读干扰。',
        en: 'Judge whether word meaning and ink color match, resisting the reading reflex.',
      ),
      accent: const Color(0xFF5B82C2),
      icon: Icons.contrast_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：判断是否一致',
        en: 'Next: decide match or mismatch',
      ),
      child: const _StroopTestCard(),
    );
  }
}

class _StroopItem {
  const _StroopItem({required this.zh, required this.en, required this.color});

  final String zh;
  final String en;
  final Color color;
}

class _StroopTestCard extends StatefulWidget {
  const _StroopTestCard();

  @override
  State<_StroopTestCard> createState() => _StroopTestCardState();
}

class _StroopTestCardState extends State<_StroopTestCard> {
  final math.Random _random = math.Random();
  final List<_StroopItem> _items = const <_StroopItem>[
    _StroopItem(zh: '红色', en: 'Red', color: Color(0xFFC24D4D)),
    _StroopItem(zh: '蓝色', en: 'Blue', color: Color(0xFF4D73C2)),
    _StroopItem(zh: '绿色', en: 'Green', color: Color(0xFF3F9A6B)),
    _StroopItem(zh: '黄色', en: 'Yellow', color: Color(0xFFD39B35)),
  ];
  late _StroopItem _word;
  late _StroopItem _ink;
  int _score = 0;
  int _round = 0;
  int _lives = 3;

  @override
  void initState() {
    super.initState();
    _next();
  }

  void _next() {
    _word = _sample(_random, _items);
    _ink = _random.nextDouble() < 0.45 ? _word : _sample(_random, _items);
    _round += 1;
  }

  void _answer(bool match) {
    if (_lives <= 0) {
      return;
    }
    final correct = (_word == _ink) == match;
    setState(() {
      if (correct) {
        _score += 1;
      } else {
        _lives -= 1;
      }
      if (_lives > 0) {
        _next();
      }
    });
  }

  void _reset() {
    setState(() {
      _score = 0;
      _round = 0;
      _lives = 3;
      _next();
    });
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final wordLabel = pickUiText(i18n, zh: _word.zh, en: _word.en);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (pickUiText(i18n, zh: '得分', en: 'Score'), '$_score'),
            (pickUiText(i18n, zh: '轮次', en: 'Round'), '$_round'),
            (pickUiText(i18n, zh: '生命', en: 'Lives'), '$_lives'),
          ],
        ),
        const SizedBox(height: 12),
        _HumanPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                height: 150,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: Text(
                  wordLabel,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: _ink.color,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  _HumanActionButton(
                    label: pickUiText(i18n, zh: '一致', en: 'Match'),
                    icon: Icons.check_rounded,
                    onPressed: _lives <= 0 ? null : () => _answer(true),
                  ),
                  OutlinedButton.icon(
                    onPressed: _lives <= 0 ? null : () => _answer(false),
                    icon: const Icon(Icons.close_rounded),
                    label: Text(pickUiText(i18n, zh: '不一致', en: 'Mismatch')),
                  ),
                  OutlinedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: Text(pickUiText(i18n, zh: '重置', en: 'Reset')),
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

class VerbalMemoryTestPage extends StatelessWidget {
  const VerbalMemoryTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: pickUiText(i18n, zh: '词汇记忆', en: 'Verbal memory'),
      subtitle: pickUiText(
        i18n,
        zh: '判断当前词是新词，还是已经出现过。',
        en: 'Decide whether the current word is new or has appeared before.',
      ),
      accent: const Color(0xFF8F6C45),
      icon: Icons.menu_book_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：选择新词或见过',
        en: 'Next: choose new or seen',
      ),
      child: const _VerbalMemoryCard(),
    );
  }
}

class _VerbalMemoryCard extends StatefulWidget {
  const _VerbalMemoryCard();

  @override
  State<_VerbalMemoryCard> createState() => _VerbalMemoryCardState();
}

class _VerbalMemoryCardState extends State<_VerbalMemoryCard> {
  final math.Random _random = math.Random();
  final Set<String> _seen = <String>{};
  String _current = '';
  bool _currentWasSeen = false;
  int _score = 0;
  int _lives = 3;

  List<String> _words(AppI18n i18n) {
    return pickUiText(
      i18n,
      zh: '月光|河流|纸张|钟声|树影|地图|火车|窗台|薄荷|山谷|记忆|灯塔|琥珀|海盐|回声|晨雾',
      en: 'river|paper|signal|window|garden|memory|harbor|amber|summit|echo|planet|silver|candle|forest|letter|puzzle',
    ).split('|');
  }

  void _next(AppI18n i18n) {
    final words = _words(i18n);
    final shouldRepeat = _seen.isNotEmpty && _random.nextDouble() < 0.42;
    if (shouldRepeat || _seen.length >= words.length) {
      _current = _sample(_random, _seen.toList(growable: false));
      _currentWasSeen = true;
      return;
    }
    final unseen = words.where((word) => !_seen.contains(word)).toList();
    _current = _sample(_random, unseen);
    _currentWasSeen = false;
  }

  void _start(AppI18n i18n) {
    setState(() {
      _seen.clear();
      _score = 0;
      _lives = 3;
      _next(i18n);
    });
  }

  void _answer(AppI18n i18n, bool seen) {
    if (_current.isEmpty || _lives <= 0) {
      return;
    }
    final correct = seen == _currentWasSeen;
    setState(() {
      if (correct) {
        _score += 1;
      } else {
        _lives -= 1;
      }
      _seen.add(_current);
      if (_lives > 0) {
        _next(i18n);
      }
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
            (pickUiText(i18n, zh: '得分', en: 'Score'), '$_score'),
            (pickUiText(i18n, zh: '生命', en: 'Lives'), '$_lives'),
            (pickUiText(i18n, zh: '已见', en: 'Seen'), '${_seen.length}'),
          ],
        ),
        const SizedBox(height: 12),
        _HumanPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                height: 150,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: Text(
                  _current.isEmpty
                      ? pickUiText(i18n, zh: '点击开始', en: 'Tap start')
                      : _current,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  _HumanActionButton(
                    label: pickUiText(i18n, zh: '新词', en: 'New'),
                    icon: Icons.fiber_new_rounded,
                    onPressed: _current.isEmpty
                        ? null
                        : () => _answer(i18n, false),
                  ),
                  OutlinedButton.icon(
                    onPressed: _current.isEmpty
                        ? null
                        : () => _answer(i18n, true),
                    icon: const Icon(Icons.history_rounded),
                    label: Text(pickUiText(i18n, zh: '见过', en: 'Seen')),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _start(i18n),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(pickUiText(i18n, zh: '开始', en: 'Start')),
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

class LuckTestPage extends StatelessWidget {
  const LuckTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: pickUiText(i18n, zh: '运气测试', en: 'Luck test'),
      subtitle: pickUiText(
        i18n,
        zh: '猜下一次结果在左边还是右边，看看连中纪录。',
        en: 'Guess whether the next result lands left or right and track your streak.',
      ),
      accent: const Color(0xFFD0923A),
      icon: Icons.casino_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：选择左或右',
        en: 'Next: choose left or right',
      ),
      child: const _LuckTestCard(),
    );
  }
}

class _LuckTestCard extends StatefulWidget {
  const _LuckTestCard();

  @override
  State<_LuckTestCard> createState() => _LuckTestCardState();
}

class _LuckTestCardState extends State<_LuckTestCard> {
  final math.Random _random = math.Random();
  int _attempts = 0;
  int _streak = 0;
  int _best = 0;
  bool? _lastCorrect;

  void _guess(bool left) {
    final resultLeft = _random.nextBool();
    final correct = left == resultLeft;
    setState(() {
      _attempts += 1;
      _lastCorrect = correct;
      _streak = correct ? _streak + 1 : 0;
      _best = math.max(_best, _streak);
    });
  }

  void _reset() {
    setState(() {
      _attempts = 0;
      _streak = 0;
      _best = 0;
      _lastCorrect = null;
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
            (pickUiText(i18n, zh: '次数', en: 'Attempts'), '$_attempts'),
            (pickUiText(i18n, zh: '连中', en: 'Streak'), '$_streak'),
            (pickUiText(i18n, zh: '最佳', en: 'Best'), '$_best'),
          ],
        ),
        const SizedBox(height: 12),
        _HumanPanel(
          child: Column(
            children: <Widget>[
              Text(
                _lastCorrect == null
                    ? pickUiText(
                        i18n,
                        zh: '猜结果会落在哪一边',
                        en: 'Guess which side wins',
                      )
                    : _lastCorrect!
                    ? pickUiText(i18n, zh: '命中', en: 'Hit')
                    : pickUiText(i18n, zh: '没中', en: 'Miss'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  _HumanActionButton(
                    label: pickUiText(i18n, zh: '左', en: 'Left'),
                    icon: Icons.keyboard_arrow_left_rounded,
                    onPressed: () => _guess(true),
                  ),
                  _HumanActionButton(
                    label: pickUiText(i18n, zh: '右', en: 'Right'),
                    icon: Icons.keyboard_arrow_right_rounded,
                    onPressed: () => _guess(false),
                  ),
                  OutlinedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: Text(pickUiText(i18n, zh: '重置', en: 'Reset')),
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

class CalculationTestPage extends StatelessWidget {
  const CalculationTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: pickUiText(i18n, zh: '计算能力测试', en: 'Calculation test'),
      subtitle: pickUiText(
        i18n,
        zh: '连续完成 10 道口算题，统计正确数量。',
        en: 'Solve 10 quick arithmetic prompts and count correct answers.',
      ),
      accent: const Color(0xFF6178B8),
      icon: Icons.calculate_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：输入答案并提交',
        en: 'Next: type answers and submit',
      ),
      child: const _CalculationTestCard(),
    );
  }
}

class _CalculationTestCard extends StatefulWidget {
  const _CalculationTestCard();

  @override
  State<_CalculationTestCard> createState() => _CalculationTestCardState();
}

class _CalculationTestCardState extends State<_CalculationTestCard> {
  static const int _roundCount = 10;
  final math.Random _random = math.Random();
  final TextEditingController _controller = TextEditingController();
  int _round = 0;
  int _score = 0;
  int _a = 0;
  int _b = 0;
  String _op = '+';
  int _answer = 0;
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _newProblem({bool reset = false}) {
    final op = _sample(_random, <String>['+', '-', 'x']);
    var a = 2 + _random.nextInt(18);
    var b = 2 + _random.nextInt(12);
    if (op == '-' && b > a) {
      final tmp = a;
      a = b;
      b = tmp;
    }
    final answer = switch (op) {
      '+' => a + b,
      '-' => a - b,
      _ => a * b,
    };
    setState(() {
      if (reset) {
        _round = 1;
        _score = 0;
        _done = false;
      } else {
        _round += 1;
      }
      _a = a;
      _b = b;
      _op = op;
      _answer = answer;
      _controller.clear();
    });
  }

  void _submit() {
    if (_round == 0 || _done) {
      return;
    }
    final value = int.tryParse(_controller.text.trim());
    setState(() {
      if (value == _answer) {
        _score += 1;
      }
    });
    if (_round >= _roundCount) {
      setState(() => _done = true);
    } else {
      _newProblem();
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (pickUiText(i18n, zh: '题目', en: 'Round'), '$_round/$_roundCount'),
            (pickUiText(i18n, zh: '正确', en: 'Correct'), '$_score'),
          ],
        ),
        const SizedBox(height: 12),
        _HumanPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                height: 132,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: Text(
                  _round == 0
                      ? pickUiText(i18n, zh: '点击开始', en: 'Tap start')
                      : '$_a $_op $_b = ?',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _controller,
                enabled: _round > 0 && !_done,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: pickUiText(i18n, zh: '答案', en: 'Answer'),
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
                    label: _round == 0 || _done
                        ? pickUiText(i18n, zh: '开始', en: 'Start')
                        : pickUiText(i18n, zh: '提交', en: 'Submit'),
                    icon: _round == 0 || _done
                        ? Icons.play_arrow_rounded
                        : Icons.check_rounded,
                    onPressed: _round == 0 || _done
                        ? () => _newProblem(reset: true)
                        : _submit,
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

class SustainedAttentionTestPage extends StatelessWidget {
  const SustainedAttentionTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: pickUiText(i18n, zh: '持续注意力测试', en: 'Sustained attention'),
      subtitle: pickUiText(
        i18n,
        zh: '连续观察字符流，只在目标 X 出现时点击。',
        en: 'Watch the character stream and tap only when target X appears.',
      ),
      accent: const Color(0xFF6D8657),
      icon: Icons.track_changes_rounded,
      status: pickUiText(i18n, zh: '下一步：看到 X 才点击', en: 'Next: tap only on X'),
      child: const _SustainedAttentionCard(),
    );
  }
}

class _SustainedAttentionCard extends StatefulWidget {
  const _SustainedAttentionCard();

  @override
  State<_SustainedAttentionCard> createState() =>
      _SustainedAttentionCardState();
}

class _SustainedAttentionCardState extends State<_SustainedAttentionCard> {
  static const int _stimulusCount = 30;
  final math.Random _random = math.Random();
  Timer? _timer;
  int _step = 0;
  int _hits = 0;
  int _misses = 0;
  int _falseAlarms = 0;
  String _current = '-';
  bool _running = false;
  bool _target = false;
  bool _tappedThisStimulus = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    setState(() {
      _step = 0;
      _hits = 0;
      _misses = 0;
      _falseAlarms = 0;
      _running = true;
      _current = '-';
      _target = false;
      _tappedThisStimulus = false;
    });
    _advance();
    _timer = Timer.periodic(
      const Duration(milliseconds: 820),
      (_) => _advance(),
    );
  }

  void _advance() {
    if (!mounted || !_running) {
      return;
    }
    if (_step >= _stimulusCount) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    if (_target && !_tappedThisStimulus) {
      _misses += 1;
    }
    final nextTarget = _random.nextDouble() < 0.24;
    final letters = <String>['A', 'H', 'K', 'M', 'N', 'S', 'T', 'Y'];
    setState(() {
      _step += 1;
      _target = nextTarget;
      _current = nextTarget ? 'X' : _sample(_random, letters);
      _tappedThisStimulus = false;
    });
  }

  void _tap() {
    if (!_running) {
      return;
    }
    setState(() {
      if (_target && !_tappedThisStimulus) {
        _hits += 1;
        _tappedThisStimulus = true;
      } else {
        _falseAlarms += 1;
      }
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
              pickUiText(i18n, zh: '进度', en: 'Progress'),
              '$_step/$_stimulusCount',
            ),
            (pickUiText(i18n, zh: '命中', en: 'Hits'), '$_hits'),
            (pickUiText(i18n, zh: '漏点', en: 'Misses'), '$_misses'),
            (pickUiText(i18n, zh: '误点', en: 'False taps'), '$_falseAlarms'),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _running ? _tap : _start,
          child: Container(
            height: 240,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: _target
                  ? const Color(0xFF6D8657).withValues(alpha: 0.18)
                  : Theme.of(context).colorScheme.surfaceContainerLow,
              border: Border.all(
                color: const Color(0xFF6D8657).withValues(alpha: 0.22),
              ),
            ),
            child: Text(
              _running
                  ? _current
                  : pickUiText(i18n, zh: '点击开始', en: 'Tap to start'),
              style: Theme.of(
                context,
              ).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }
}
