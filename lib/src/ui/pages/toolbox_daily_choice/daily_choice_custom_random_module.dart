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
        label: widget.i18n.t(
          'inline.plan295.daily_choice.option_a.7bba547b8694',
        ),
        weight: 3,
        conditionProbability: 0.8,
      ),
      _CustomRandomDraft(
        id: 'option_b',
        label: widget.i18n.t(
          'inline.plan295.daily_choice.option_b.d1be692919c6',
        ),
        weight: 2,
        conditionProbability: 0.6,
      ),
      _CustomRandomDraft(
        id: 'option_c',
        label: widget.i18n.t(
          'inline.plan295.daily_choice.option_c.00bbcf55e120',
        ),
        weight: 1,
        conditionProbability: 0.5,
      ),
      _CustomRandomDraft(
        id: 'option_d',
        label: widget.i18n.t(
          'inline.plan295.daily_choice.option_d.6420b447189e',
        ),
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
                      widget.i18n.t(
                        'inline.plan295.daily_choice.draw.db79777c946e',
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _resetDemo,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: Text(
                      widget.i18n.t(
                        'inline.plan295.daily_choice.reset.b544c0676a8a',
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

  IconData get _drawIcon {
    return switch (_animation) {
      DailyChoiceCustomRandomAnimation.wheel => Icons.motion_photos_on_rounded,
      DailyChoiceCustomRandomAnimation.dice => Icons.casino_rounded,
      DailyChoiceCustomRandomAnimation.coin => Icons.monetization_on_rounded,
    };
  }

  String? _validationText(int optionCount) {
    if (optionCount < 2) {
      return widget.i18n.t(
        'inline.plan295.daily_choice.at_least_2_valid_options_are_require.8b87d9104bd0',
      );
    }
    if (_animation == DailyChoiceCustomRandomAnimation.dice &&
        optionCount < 3) {
      return widget.i18n.t(
        'inline.plan295.daily_choice.dice_mode_needs_at_least_3_options_e.332255d2c8ea',
      );
    }
    if (_animation == DailyChoiceCustomRandomAnimation.coin &&
        optionCount != 2) {
      return widget.i18n.t(
        'inline.plan295.daily_choice.coin_mode_has_exactly_two_sides_so_i.cfc1ef58c32b',
      );
    }
    if (_mode == DailyChoiceCustomRandomMode.weighted &&
        _activeOptions.every((item) => item.normalizedWeight <= 0)) {
      return widget.i18n.t(
        'inline.plan295.daily_choice.if_all_weights_are_0_the_draw_falls.4823cd9ef7fd',
      );
    }
    if (_mode == DailyChoiceCustomRandomMode.jointDistribution &&
        _activeOptions.every(
          (item) =>
              item.normalizedWeight * item.normalizedConditionProbability <= 0,
        )) {
      return widget.i18n.t(
        'inline.plan295.daily_choice.if_every_joint_mass_is_0_the_draw_fa.b5fbdbe5c180',
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
          label: widget.i18n.t(
            'inline.plan295.daily_choice.option_nextindex.f477e542fa13',
            params: <String, Object?>{'nextIndex': nextIndex},
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
      title: widget.i18n.t(
        'inline.ui.pages.toolbox_daily_choice.daily_choice_custom_random_module.random_assistant_guide_b259e7',
      ),
      modules: <DailyChoiceGuideModule>[
        const DailyChoiceGuideModule(
          id: 'random_scope',
          icon: Icons.rule_folder_rounded,
          titleKey:
              'inline.plan295.daily_choice.check_the_boundary_first.78f54cbdfafe',
          subtitleKey:
              'inline.plan295.daily_choice.random_choice_fits_low_stakes_revers.6c704dcae087',
          entries: <DailyChoiceGuideEntry>[
            DailyChoiceGuideEntry(
              icon: Icons.low_priority_rounded,
              titleKey:
                  'inline.ui.pages.toolbox_daily_choice.daily_choice_custom_random_widgets.uniform_random_851942',
              bodyKey:
                  'inline.plan295.daily_choice.every_option_has_the_same_chance_use.e989f5341b23',
            ),
            DailyChoiceGuideEntry(
              icon: Icons.balance_rounded,
              titleKey:
                  'inline.ui.pages.toolbox_daily_choice.daily_choice_custom_random_widgets.weighted_random_28af44',
              bodyKey:
                  'inline.plan295.daily_choice.higher_weights_get_more_chances_it_k.3ece5fbe976b',
            ),
            DailyChoiceGuideEntry(
              icon: Icons.account_tree_rounded,
              titleKey:
                  'inline.plan295.daily_choice.joint_multi_round.d854ecdf35d2',
              bodyKey:
                  'inline.plan295.daily_choice.use_weight_condition_probability_as.162d148577a3',
            ),
          ],
        ),
      ],
    );
  }
}
