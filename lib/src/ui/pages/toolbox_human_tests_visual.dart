part of 'toolbox_human_tests.dart';

class ColorVisionTestPage extends StatelessWidget {
  const ColorVisionTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: pickUiText(i18n, zh: '色觉测试', en: 'Color vision'),
      subtitle: pickUiText(
        i18n,
        zh: '从一组相近色块中找出唯一不同的颜色。',
        en: 'Find the single tile whose color differs from the rest.',
      ),
      accent: const Color(0xFF3F9A6B),
      icon: Icons.palette_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：点击不同色块',
        en: 'Next: tap the different tile',
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

class _ColorVisionCardState extends State<_ColorVisionCard> {
  final math.Random _random = math.Random();
  int _level = 1;
  int _lives = 3;
  int _oddIndex = 0;
  Color _base = const Color(0xFF72B98E);
  Color _odd = const Color(0xFF7AC494);
  bool _gameOver = false;

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  void _newRound() {
    final cellCount = _cellCount;
    final hue = _random.nextDouble() * 360;
    final saturation = 0.36 + _random.nextDouble() * 0.24;
    final lightness = 0.48 + _random.nextDouble() * 0.16;
    final delta = math.max(0.035, 0.16 - _level * 0.006);
    final direction = _random.nextBool() ? 1 : -1;
    _base = HSLColor.fromAHSL(1, hue, saturation, lightness).toColor();
    _odd = HSLColor.fromAHSL(
      1,
      hue,
      saturation,
      (lightness + delta * direction).clamp(0.20, 0.82),
    ).toColor();
    _oddIndex = _random.nextInt(cellCount);
  }

  int get _gridSize => _level < 5
      ? 3
      : _level < 11
      ? 4
      : 5;

  int get _cellCount => _gridSize * _gridSize;

  void _tap(int index) {
    if (_gameOver) {
      return;
    }
    if (index == _oddIndex) {
      setState(() {
        _level += 1;
        _newRound();
      });
    } else {
      setState(() {
        _lives -= 1;
        if (_lives <= 0) {
          _gameOver = true;
        }
      });
    }
  }

  void _reset() {
    setState(() {
      _level = 1;
      _lives = 3;
      _gameOver = false;
      _newRound();
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
            (pickUiText(i18n, zh: '网格', en: 'Grid'), '${_gridSize}x$_gridSize'),
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
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _gridSize,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => _tap(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: index == _oddIndex ? _odd : _base,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              if (_gameOver)
                Text(
                  pickUiText(
                    i18n,
                    zh: '测试结束，可以重置后再试。',
                    en: 'Test over. Reset to try again.',
                  ),
                ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.restart_alt_rounded),
                label: Text(pickUiText(i18n, zh: '重置', en: 'Reset')),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class DynamicVisionTestPage extends StatelessWidget {
  const DynamicVisionTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: pickUiText(i18n, zh: '动态视力测试', en: 'Dynamic vision'),
      subtitle: pickUiText(
        i18n,
        zh: '观察快速移动的字符，结束后选择你看到的内容。',
        en: 'Watch the fast moving symbol, then choose what you saw.',
      ),
      accent: const Color(0xFF407E92),
      icon: Icons.remove_red_eye_rounded,
      status: pickUiText(
        i18n,
        zh: '下一步：开始后盯住移动字符',
        en: 'Next: track the moving symbol',
      ),
      child: const _DynamicVisionCard(),
    );
  }
}

class _DynamicVisionCard extends StatefulWidget {
  const _DynamicVisionCard();

  @override
  State<_DynamicVisionCard> createState() => _DynamicVisionCardState();
}

class _DynamicVisionCardState extends State<_DynamicVisionCard>
    with SingleTickerProviderStateMixin {
  static const int _roundCount = 10;
  final math.Random _random = math.Random();
  late final AnimationController _controller;
  int _round = 0;
  int _correct = 0;
  String _target = '';
  List<String> _options = const <String>[];
  bool _showing = false;
  bool _choosing = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startRound() async {
    final values = <String>['2', '3', '5', '6', '8', '9', 'B', 'E', 'F', 'P'];
    final target = _sample(_random, values);
    final options = <String>{target};
    while (options.length < 4) {
      options.add(_sample(_random, values));
    }
    setState(() {
      _round += 1;
      _target = target;
      _options = options.toList(growable: false)..shuffle(_random);
      _showing = true;
      _choosing = false;
      _done = false;
    });
    _controller
      ..reset()
      ..forward();
    await Future<void>.delayed(_controller.duration!);
    if (!mounted) {
      return;
    }
    setState(() {
      _showing = false;
      _choosing = true;
    });
  }

  void _choose(String value) {
    if (!_choosing) {
      return;
    }
    final correct = value == _target;
    setState(() {
      if (correct) {
        _correct += 1;
      }
      _choosing = false;
      if (_round >= _roundCount) {
        _done = true;
      }
    });
    if (_round < _roundCount) {
      _startRound();
    }
  }

  void _reset() {
    _controller.stop();
    setState(() {
      _round = 0;
      _correct = 0;
      _target = '';
      _options = const <String>[];
      _showing = false;
      _choosing = false;
      _done = false;
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
            (pickUiText(i18n, zh: '轮次', en: 'Round'), '$_round/$_roundCount'),
            (pickUiText(i18n, zh: '正确', en: 'Correct'), '$_correct'),
          ],
        ),
        const SizedBox(height: 12),
        _HumanPanel(
          padding: EdgeInsets.zero,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(
                constraints.maxWidth,
                math.min(300.0, constraints.maxWidth * 0.58),
              );
              return SizedBox(
                width: size.width,
                height: size.height,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final x = 24 + _controller.value * (size.width - 72);
                    final y =
                        size.height *
                        (0.48 +
                            math.sin(
                                  (_controller.value + _round * 0.13) *
                                      math.pi *
                                      2,
                                ) *
                                0.18);
                    return Stack(
                      children: <Widget>[
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              color: Theme.of(context).colorScheme.surface,
                            ),
                          ),
                        ),
                        if (_showing)
                          Positioned(
                            left: x,
                            top: y - 20,
                            child: Text(
                              _target,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          )
                        else
                          Center(
                            child: _done
                                ? Text(
                                    pickUiText(i18n, zh: '完成', en: 'Done'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  )
                                : _HumanActionButton(
                                    label: pickUiText(
                                      i18n,
                                      zh: '开始',
                                      en: 'Start',
                                    ),
                                    icon: Icons.play_arrow_rounded,
                                    onPressed: _startRound,
                                  ),
                          ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        if (_choosing)
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _options
                .map(
                  (value) => OutlinedButton(
                    onPressed: () => _choose(value),
                    child: Text(value),
                  ),
                )
                .toList(growable: false),
          ),
        if (_done)
          OutlinedButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.restart_alt_rounded),
            label: Text(pickUiText(i18n, zh: '重置', en: 'Reset')),
          ),
      ],
    );
  }
}
