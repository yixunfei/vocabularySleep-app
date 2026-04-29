part of 'daily_choice_hub.dart';

class _CustomRandomDraft {
  _CustomRandomDraft({
    required this.id,
    required this.label,
    this.weight = 1,
    this.conditionProbability = 0.7,
  });

  final String id;
  String label;
  double weight;
  double conditionProbability;

  DailyChoiceCustomRandomOption toOption() {
    return DailyChoiceCustomRandomOption(
      id: id,
      label: label.trim().isEmpty ? id : label.trim(),
      weight: weight,
      conditionProbability: conditionProbability,
    );
  }
}

class _CustomRandomModule extends StatefulWidget {
  const _CustomRandomModule({
    super.key,
    required this.i18n,
    required this.accent,
  });

  final AppI18n i18n;
  final Color accent;

  @override
  State<_CustomRandomModule> createState() => _CustomRandomModuleState();
}

class _CustomRandomModuleState extends State<_CustomRandomModule>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motionController;
  late List<_CustomRandomDraft> _items;
  DailyChoiceCustomRandomMode _mode = DailyChoiceCustomRandomMode.uniform;
  DailyChoiceCustomRandomAnimation _animation =
      DailyChoiceCustomRandomAnimation.wheel;
  DailyChoiceCustomRandomResult? _result;
  int _rounds = 3;
  int _diceCount = 1;
  int _coinCount = 3;
  int _revision = 0;
  bool _parametersExpanded = true;

  @override
  void initState() {
    super.initState();
    _items = _buildDefaultItems();
    _motionController = AnimationController(
      vsync: this,
      duration: AppDurations.celebrate,
    );
  }

  @override
  void dispose() {
    _motionController.dispose();
    super.dispose();
  }

  List<_CustomRandomDraft> _buildDefaultItems() {
    return <_CustomRandomDraft>[
      _CustomRandomDraft(
        id: 'option_a',
        label: pickUiText(widget.i18n, zh: '可选项 A', en: 'Option A'),
        weight: 3,
        conditionProbability: 0.8,
      ),
      _CustomRandomDraft(
        id: 'option_b',
        label: pickUiText(widget.i18n, zh: '可选项 B', en: 'Option B'),
        weight: 2,
        conditionProbability: 0.6,
      ),
      _CustomRandomDraft(
        id: 'option_c',
        label: pickUiText(widget.i18n, zh: '可选项 C', en: 'Option C'),
        weight: 1,
        conditionProbability: 0.5,
      ),
      _CustomRandomDraft(
        id: 'option_d',
        label: pickUiText(widget.i18n, zh: '可选项 D', en: 'Option D'),
        weight: 1,
        conditionProbability: 0.4,
      ),
    ];
  }

  List<DailyChoiceCustomRandomOption> get _activeOptions {
    return _items
        .where((item) => item.label.trim().isNotEmpty)
        .map((item) => item.toOption())
        .toList(growable: false);
  }

  DailyChoiceDiceLayout get _diceLayout {
    return DailyChoiceDiceLayout.forOptions(
      optionCount: _activeOptions.length,
      preferredDiceCount: _diceCount,
    );
  }

  bool get _canDraw {
    final options = _activeOptions;
    if (options.length < 2) {
      return false;
    }
    if (_animation == DailyChoiceCustomRandomAnimation.dice) {
      return options.length >= 3 && _diceLayout.valid;
    }
    if (_animation == DailyChoiceCustomRandomAnimation.coin) {
      return options.length == 2;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = _activeOptions;
    final probabilities = DailyChoiceCustomRandomEngine.probabilitiesFor(
      options: options,
      mode: _mode,
    );
    final validationText = _validationText(options.length);
    final result = _result;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _CustomRandomHeaderCard(
          i18n: widget.i18n,
          accent: widget.accent,
          optionCount: options.length,
          onGuide: _showGuide,
        ),
        const SizedBox(height: ToolboxUiTokens.cardSpacing),
        _CustomRandomPickerCard(
          i18n: widget.i18n,
          accent: widget.accent,
          mode: _mode,
          animation: _animation,
          onModeChanged: _selectMode,
          onAnimationChanged: _selectAnimation,
        ),
        const SizedBox(height: ToolboxUiTokens.cardSpacing),
        _CustomRandomParameterCard(
          i18n: widget.i18n,
          accent: widget.accent,
          mode: _mode,
          animation: _animation,
          optionCount: options.length,
          totalCount: _items.length,
          rounds: _rounds,
          diceCount: _diceCount,
          coinCount: _coinCount,
          revision: _revision,
          items: _items,
          expanded: _parametersExpanded,
          onToggleExpanded: () =>
              setState(() => _parametersExpanded = !_parametersExpanded),
          onRoundsChanged: (value) => setState(() {
            _rounds = value;
            _result = null;
          }),
          onDiceCountChanged: (value) => setState(() {
            _diceCount = value;
            _result = null;
          }),
          onCoinCountChanged: (value) => setState(() {
            _coinCount = value;
            _result = null;
          }),
          onOptionChanged: () => setState(() => _result = null),
          onAddOption: _addItem,
          onDelete: _deleteItem,
        ),
        const SizedBox(height: ToolboxUiTokens.cardSpacing),
        ToolboxSurfaceCard(
          padding: const EdgeInsets.all(16),
          radius: ToolboxUiTokens.panelRadius,
          borderColor: widget.accent.withValues(alpha: 0.22),
          shadowColor: widget.accent,
          shadowOpacity: 0.07,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _CustomRandomStageHeader(
                i18n: widget.i18n,
                accent: widget.accent,
                result: result,
                probability: result == null
                    ? null
                    : probabilities[result.winner.id],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 236,
                child: AnimatedBuilder(
                  animation: _motionController,
                  builder: (context, _) {
                    return _CustomRandomStage(
                      i18n: widget.i18n,
                      accent: widget.accent,
                      options: options,
                      probabilities: probabilities,
                      animation: _animation,
                      result: result,
                      progress: _motionController.value,
                    );
                  },
                ),
              ),
              if (validationText != null) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  validationText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: _canDraw ? _draw : null,
                    icon: Icon(_drawIcon),
                    label: Text(
                      pickUiText(widget.i18n, zh: '抽取一次', en: 'Draw'),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _resetDemo,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: Text(
                      pickUiText(widget.i18n, zh: '恢复示例', en: 'Reset'),
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

  IconData get _drawIcon {
    return switch (_animation) {
      DailyChoiceCustomRandomAnimation.wheel => Icons.motion_photos_on_rounded,
      DailyChoiceCustomRandomAnimation.dice => Icons.casino_rounded,
      DailyChoiceCustomRandomAnimation.coin => Icons.monetization_on_rounded,
    };
  }

  String? _validationText(int optionCount) {
    if (optionCount < 2) {
      return pickUiText(
        widget.i18n,
        zh: '至少需要 2 个有效选项才能随机。',
        en: 'At least 2 valid options are required.',
      );
    }
    if (_animation == DailyChoiceCustomRandomAnimation.dice &&
        optionCount < 3) {
      return pickUiText(
        widget.i18n,
        zh: '骰子模式至少需要 3 个选项；每颗骰子会分配 3 到 12 面。',
        en: 'Dice mode needs at least 3 options; each die gets 3 to 12 faces.',
      );
    }
    if (_animation == DailyChoiceCustomRandomAnimation.coin &&
        optionCount != 2) {
      return pickUiText(
        widget.i18n,
        zh: '硬币模式只使用两面，因此需要正好 2 个有效选项。',
        en: 'Coin mode has exactly two sides, so it needs exactly 2 options.',
      );
    }
    if (_mode == DailyChoiceCustomRandomMode.weighted &&
        _activeOptions.every((item) => item.normalizedWeight <= 0)) {
      return pickUiText(
        widget.i18n,
        zh: '全部权重为 0 时会自动退回均匀随机；建议至少给一个选项正权重。',
        en: 'If all weights are 0, the draw falls back to uniform random.',
      );
    }
    if (_mode == DailyChoiceCustomRandomMode.jointDistribution &&
        _activeOptions.every(
          (item) =>
              item.normalizedWeight * item.normalizedConditionProbability <= 0,
        )) {
      return pickUiText(
        widget.i18n,
        zh: '联合分布的权重 × 条件概率全为 0 时会退回均匀随机。',
        en: 'If every joint mass is 0, the draw falls back to uniform random.',
      );
    }
    return null;
  }

  void _selectMode(DailyChoiceCustomRandomMode mode) {
    setState(() {
      _mode = mode;
      _result = null;
      if (mode != DailyChoiceCustomRandomMode.uniform &&
          _animation != DailyChoiceCustomRandomAnimation.wheel) {
        _animation = DailyChoiceCustomRandomAnimation.wheel;
      }
    });
  }

  void _selectAnimation(DailyChoiceCustomRandomAnimation animation) {
    setState(() {
      _animation = animation;
      _result = null;
      if (animation != DailyChoiceCustomRandomAnimation.wheel) {
        _mode = DailyChoiceCustomRandomMode.uniform;
      }
      if (animation == DailyChoiceCustomRandomAnimation.coin &&
          _coinCount.isEven) {
        _coinCount += 1;
      }
    });
  }

  void _draw() {
    final options = _activeOptions;
    if (!_canDraw) {
      return;
    }
    final result = DailyChoiceCustomRandomEngine.draw(
      options: options,
      mode: _mode,
      animation: _animation,
      rounds: _rounds,
      diceCount: _diceCount,
      coinCount: _coinCount,
    );
    setState(() {
      _result = result;
      _diceCount = result.diceLayout?.diceCount ?? _diceCount;
    });
    _motionController.duration = switch (_animation) {
      DailyChoiceCustomRandomAnimation.wheel => const Duration(
        milliseconds: 2200,
      ),
      DailyChoiceCustomRandomAnimation.dice => const Duration(
        milliseconds: 1400,
      ),
      DailyChoiceCustomRandomAnimation.coin => const Duration(
        milliseconds: 1600,
      ),
    };
    _motionController.forward(from: 0);
  }

  void _addItem() {
    if (_items.length >= 36) {
      return;
    }
    final nextIndex = _items.length + 1;
    setState(() {
      _items = <_CustomRandomDraft>[
        ..._items,
        _CustomRandomDraft(
          id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
          label: pickUiText(
            widget.i18n,
            zh: '可选项 $nextIndex',
            en: 'Option $nextIndex',
          ),
        ),
      ];
      _result = null;
    });
  }

  void _deleteItem(_CustomRandomDraft item) {
    if (_items.length <= 2) {
      return;
    }
    setState(() {
      _items = _items
          .where((candidate) => candidate.id != item.id)
          .toList(growable: false);
      _result = null;
    });
  }

  void _resetDemo() {
    setState(() {
      _items = _buildDefaultItems();
      _mode = DailyChoiceCustomRandomMode.uniform;
      _animation = DailyChoiceCustomRandomAnimation.wheel;
      _result = null;
      _rounds = 3;
      _diceCount = 1;
      _coinCount = 3;
      _revision += 1;
    });
  }

  void _showGuide() {
    showDailyChoiceGuideSheet(
      context: context,
      i18n: widget.i18n,
      accent: widget.accent,
      title: pickUiText(
        widget.i18n,
        zh: '随机助手指南',
        en: 'Random assistant guide',
      ),
      modules: <DailyChoiceGuideModule>[
        const DailyChoiceGuideModule(
          id: 'random_scope',
          icon: Icons.rule_folder_rounded,
          titleZh: '先确认适用边界',
          titleEn: 'Check the boundary first',
          subtitleZh: '随机适合低风险、可回退、差异不大的选择。',
          subtitleEn: 'Random choice fits low-stakes, reversible choices.',
          entries: <DailyChoiceGuideEntry>[
            DailyChoiceGuideEntry(
              icon: Icons.low_priority_rounded,
              titleZh: '均匀随机',
              titleEn: 'Uniform random',
              bodyZh: '每个选项概率相同，适合“都差不多，只想结束犹豫”的场景。',
              bodyEn:
                  'Every option has the same chance. Use it when all choices are close enough.',
            ),
            DailyChoiceGuideEntry(
              icon: Icons.balance_rounded,
              titleZh: '加权随机',
              titleEn: 'Weighted random',
              bodyZh: '权重越高越容易被抽中，适合保留一点偏好但不完全按分数排序。',
              bodyEn:
                  'Higher weights get more chances. It keeps preference without turning the result into a strict ranking.',
            ),
            DailyChoiceGuideEntry(
              icon: Icons.account_tree_rounded,
              titleZh: '联合分布多轮',
              titleEn: 'Joint multi-round',
              bodyZh: '用权重 × 条件概率形成联合质量，多轮抽取后按出现次数收口。',
              bodyEn:
                  'Use weight × condition probability as joint mass, then draw multiple rounds and pick the strongest repeat.',
            ),
          ],
        ),
      ],
    );
  }
}
