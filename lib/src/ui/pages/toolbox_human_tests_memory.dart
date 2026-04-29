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
        zh: '数字会短暂出现，隐藏后输入你记住的内容。',
        en: 'A number appears briefly. Type it back after it disappears.',
      ),
      accent: const Color(0xFF536CC7),
      icon: Icons.pin_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：开始后记住数字',
        en: 'Next: start and memorize',
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
  final math.Random _random = math.Random();
  final TextEditingController _controller = TextEditingController();
  Timer? _timer;
  int _level = 1;
  String _value = '';
  bool _showing = false;
  bool _input = false;
  bool _failed = false;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startRound() {
    _timer?.cancel();
    _controller.clear();
    final length = _level + 2;
    final buffer = StringBuffer();
    for (var i = 0; i < length; i += 1) {
      buffer.write(_random.nextInt(10));
    }
    setState(() {
      _value = buffer.toString();
      _showing = true;
      _input = false;
      _failed = false;
    });
    final duration = Duration(milliseconds: math.min(2600, 850 + length * 260));
    _timer = Timer(duration, () {
      if (!mounted) {
        return;
      }
      setState(() {
        _showing = false;
        _input = true;
      });
    });
  }

  void _submit() {
    if (!_input) {
      return;
    }
    final answer = _controller.text.trim();
    if (answer == _value) {
      setState(() {
        _level += 1;
        _input = false;
      });
      _startRound();
    } else {
      setState(() {
        _failed = true;
        _input = false;
      });
    }
  }

  void _reset() {
    _timer?.cancel();
    _controller.clear();
    setState(() {
      _level = 1;
      _value = '';
      _showing = false;
      _input = false;
      _failed = false;
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
            (pickUiText(i18n, zh: '等级', en: 'Level'), '$_level'),
            (pickUiText(i18n, zh: '位数', en: 'Digits'), '${_level + 2}'),
          ],
        ),
        const SizedBox(height: 12),
        _HumanPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 150,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: Text(
                  _showing
                      ? _value
                      : _failed
                      ? pickUiText(
                          i18n,
                          zh: '答案：$_value',
                          en: 'Answer: $_value',
                        )
                      : pickUiText(i18n, zh: '准备', en: 'Ready'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _controller,
                enabled: _input,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: pickUiText(
                    i18n,
                    zh: '输入数字',
                    en: 'Type the number',
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
                    onPressed: _input ? _submit : _startRound,
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

class ChimpTestPage extends StatelessWidget {
  const ChimpTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: pickUiText(i18n, zh: '黑猩猩测试', en: 'Chimp test'),
      subtitle: pickUiText(
        i18n,
        zh: '记住数字所在位置，第一次点击后数字会隐藏。',
        en: 'Memorize the numbered positions. Numbers hide after your first tap.',
      ),
      accent: const Color(0xFF6C8D42),
      icon: Icons.grid_view_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：按 1 到 N 的顺序点击',
        en: 'Next: tap from 1 to N',
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

class _ChimpTestCardState extends State<_ChimpTestCard> {
  static const int _gridCount = 25;
  final math.Random _random = math.Random();
  int _level = 4;
  List<int> _positions = const <int>[];
  int _next = 1;
  bool _hidden = false;
  bool _failed = false;
  bool _complete = false;

  void _startRound() {
    final cells = List<int>.generate(_gridCount, (index) => index)
      ..shuffle(_random);
    setState(() {
      _positions = cells.take(_level).toList(growable: false);
      _next = 1;
      _hidden = false;
      _failed = false;
      _complete = false;
    });
  }

  void _tapCell(int cell) {
    if (_failed || _complete || _positions.isEmpty) {
      return;
    }
    final number = _positions.indexOf(cell) + 1;
    if (number <= 0) {
      setState(() {
        _hidden = true;
        _failed = true;
      });
      return;
    }
    if (number == _next) {
      setState(() {
        _hidden = true;
        _next += 1;
        if (_next > _level) {
          _complete = true;
          _level = math.min(12, _level + 1);
        }
      });
    } else {
      setState(() {
        _hidden = true;
        _failed = true;
      });
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
            (pickUiText(i18n, zh: '目标数', en: 'Targets'), '$_level'),
            (
              pickUiText(i18n, zh: '下一个', en: 'Next'),
              _positions.isEmpty || _complete ? '-' : '$_next',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _HumanPanel(
          child: Column(
            children: <Widget>[
              AspectRatio(
                aspectRatio: 1,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _gridCount,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    final number = _positions.indexOf(index) + 1;
                    final solved = number > 0 && number < _next;
                    final showNumber = number > 0 && !_hidden && !solved;
                    return _MemoryGridCell(
                      label: showNumber ? '$number' : '',
                      active: showNumber || solved,
                      solved: solved,
                      onTap: () => _tapCell(index),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              if (_failed)
                Text(
                  pickUiText(
                    i18n,
                    zh: '顺序错了，重新开始本轮。',
                    en: 'Wrong order. Restart this round.',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else if (_complete)
                Text(
                  pickUiText(
                    i18n,
                    zh: '完成，目标数已提升。',
                    en: 'Complete. Target count increased.',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              const SizedBox(height: 10),
              _HumanActionButton(
                label: _positions.isEmpty
                    ? pickUiText(i18n, zh: '开始', en: 'Start')
                    : pickUiText(i18n, zh: '下一轮', en: 'Next round'),
                icon: Icons.play_arrow_rounded,
                onPressed: _startRound,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class VisualMemoryTestPage extends StatelessWidget {
  const VisualMemoryTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: pickUiText(i18n, zh: '视觉记忆', en: 'Visual memory'),
      subtitle: pickUiText(
        i18n,
        zh: '先观察高亮格子，再在隐藏后点回相同位置。',
        en: 'Watch highlighted cells, then select the same positions after they hide.',
      ),
      accent: const Color(0xFF8B6BC8),
      icon: Icons.dashboard_customize_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：开始后记住亮起格子',
        en: 'Next: memorize highlighted cells',
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

class _VisualMemoryCardState extends State<_VisualMemoryCard> {
  static const int _gridSize = 4;
  static const int _cellCount = _gridSize * _gridSize;
  final math.Random _random = math.Random();
  int _level = 1;
  int _lives = 3;
  Set<int> _targets = <int>{};
  Set<int> _selected = <int>{};
  bool _showing = false;
  bool _input = false;
  bool _gameOver = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startRound() {
    _timer?.cancel();
    final count = math.min(10, _level + 2);
    final cells = List<int>.generate(_cellCount, (index) => index)
      ..shuffle(_random);
    setState(() {
      _targets = cells.take(count).toSet();
      _selected = <int>{};
      _showing = true;
      _input = false;
      _gameOver = false;
    });
    _timer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _showing = false;
        _input = true;
      });
    });
  }

  void _toggle(int index) {
    if (!_input) {
      return;
    }
    setState(() {
      if (_selected.contains(index)) {
        _selected.remove(index);
      } else {
        _selected.add(index);
      }
    });
  }

  void _submit() {
    if (!_input) {
      return;
    }
    if (_selected.length == _targets.length &&
        _selected.containsAll(_targets)) {
      setState(() {
        _level += 1;
        _input = false;
      });
      _startRound();
      return;
    }
    setState(() {
      _lives -= 1;
      _input = false;
      _showing = true;
      if (_lives <= 0) {
        _gameOver = true;
      }
    });
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _level = 1;
      _lives = 3;
      _targets = <int>{};
      _selected = <int>{};
      _showing = false;
      _input = false;
      _gameOver = false;
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
            (pickUiText(i18n, zh: '等级', en: 'Level'), '$_level'),
            (pickUiText(i18n, zh: '生命', en: 'Lives'), '$_lives'),
            (pickUiText(i18n, zh: '格子', en: 'Cells'), '${_targets.length}'),
          ],
        ),
        const SizedBox(height: 12),
        _HumanPanel(
          child: Column(
            children: <Widget>[
              AspectRatio(
                aspectRatio: 1,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _cellCount,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _gridSize,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    final active =
                        (_showing && _targets.contains(index)) ||
                        (_input && _selected.contains(index));
                    return _MemoryGridCell(
                      label: '',
                      active: active,
                      solved: false,
                      onTap: () => _toggle(index),
                    );
                  },
                ),
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
                    onPressed: _gameOver
                        ? null
                        : _input
                        ? _submit
                        : _startRound,
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

class SequenceMemoryTestPage extends StatelessWidget {
  const SequenceMemoryTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: pickUiText(i18n, zh: '序列记忆', en: 'Sequence memory'),
      subtitle: pickUiText(
        i18n,
        zh: '观察亮起顺序，然后按同样顺序点击色块。',
        en: 'Watch the light sequence, then tap the panels in the same order.',
      ),
      accent: const Color(0xFF7C6BC8),
      icon: Icons.auto_awesome_motion_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：播放序列后复现',
        en: 'Next: replay the sequence',
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
  int _level = 1;
  List<int> _sequence = <int>[];
  int _inputIndex = 0;
  int? _lit;
  bool _showing = false;
  bool _input = false;
  bool _failed = false;

  Future<void> _startRound() async {
    final sequence = List<int>.generate(_level, (_) => _random.nextInt(4));
    setState(() {
      _sequence = sequence;
      _inputIndex = 0;
      _lit = null;
      _showing = true;
      _input = false;
      _failed = false;
    });
    await Future<void>.delayed(const Duration(milliseconds: 300));
    for (final item in sequence) {
      if (!mounted) {
        return;
      }
      setState(() => _lit = item);
      await Future<void>.delayed(const Duration(milliseconds: 420));
      if (!mounted) {
        return;
      }
      setState(() => _lit = null);
      await Future<void>.delayed(const Duration(milliseconds: 140));
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _showing = false;
      _input = true;
    });
  }

  void _tap(int index) {
    if (!_input) {
      return;
    }
    if (_sequence[_inputIndex] != index) {
      setState(() {
        _failed = true;
        _input = false;
      });
      return;
    }
    if (_inputIndex + 1 >= _sequence.length) {
      setState(() {
        _level += 1;
        _input = false;
      });
      _startRound();
      return;
    }
    setState(() => _inputIndex += 1);
  }

  void _reset() {
    setState(() {
      _level = 1;
      _sequence = <int>[];
      _inputIndex = 0;
      _lit = null;
      _showing = false;
      _input = false;
      _failed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final colors = <Color>[
      const Color(0xFF4F8BC9),
      const Color(0xFF57A76A),
      const Color(0xFFD0913D),
      const Color(0xFFC15A72),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (pickUiText(i18n, zh: '等级', en: 'Level'), '$_level'),
            (
              pickUiText(i18n, zh: '进度', en: 'Progress'),
              _input ? '$_inputIndex/${_sequence.length}' : '-',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _HumanPanel(
          child: Column(
            children: <Widget>[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.45,
                ),
                itemBuilder: (context, index) {
                  final active = _lit == index;
                  return GestureDetector(
                    onTap: () => _tap(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: colors[index].withValues(
                          alpha: active ? 0.82 : 0.22,
                        ),
                        border: Border.all(
                          color: colors[index].withValues(
                            alpha: active ? 0.95 : 0.32,
                          ),
                          width: active ? 3 : 1,
                        ),
                      ),
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
                  ),
                )
              else if (_showing)
                Text(pickUiText(i18n, zh: '正在播放序列', en: 'Playing sequence')),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  _HumanActionButton(
                    label: pickUiText(i18n, zh: '开始', en: 'Start'),
                    icon: Icons.play_arrow_rounded,
                    onPressed: _showing ? null : _startRound,
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

class _MemoryGridCell extends StatelessWidget {
  const _MemoryGridCell({
    required this.label,
    required this.active,
    required this.solved,
    required this.onTap,
  });

  final String label;
  final bool active;
  final bool solved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: active
                ? colorScheme.primaryContainer
                : solved
                ? colorScheme.secondaryContainer
                : colorScheme.surface,
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Center(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
  }
}
