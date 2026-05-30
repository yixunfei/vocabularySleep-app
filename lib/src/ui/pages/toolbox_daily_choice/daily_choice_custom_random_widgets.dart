part of 'daily_choice_hub.dart';

class _CustomRandomHeaderCard extends StatelessWidget {
  const _CustomRandomHeaderCard({
    required this.i18n,
    required this.accent,
    required this.optionCount,
    required this.onGuide,
  });

  final AppI18n i18n;
  final Color accent;
  final int optionCount;
  final VoidCallback onGuide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ToolboxSurfaceCard(
      padding: const EdgeInsets.all(18),
      radius: ToolboxUiTokens.panelRadius,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          accent.withValues(alpha: 0.18),
          theme.colorScheme.surfaceContainerLowest,
          theme.colorScheme.tertiaryContainer.withValues(alpha: 0.24),
        ],
      ),
      borderColor: accent.withValues(alpha: 0.24),
      shadowColor: accent,
      shadowOpacity: 0.08,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    ToolboxInfoPill(
                      text: i18n.t(
                        'inline.ui.pages.toolbox_daily_choice.daily_choice_custom_random_widgets.random_assistant_a5a3a1',
                      ),
                      accent: accent,
                      backgroundColor: Colors.white.withValues(alpha: 0.64),
                    ),
                    ToolboxInfoPill(
                      text: i18n.t(
                        'inline.plan295.daily_choice.optioncount_options.35f063facbc7',
                        params: <String, Object?>{'optionCount': optionCount},
                      ),
                      accent: accent,
                      backgroundColor: Colors.white.withValues(alpha: 0.64),
                    ),
                  ],
                ),
              ),
              ToolboxIconPillButton(
                icon: Icons.help_outline_rounded,
                active: false,
                tint: accent,
                tooltip: i18n.t('toolbox.daily_choice.guide'),
                onTap: onGuide,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            i18n.t(
              'inline.plan295.daily_choice.make_randomness_adjustable.59be01268cbc',
            ),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            i18n.t(
              'inline.plan295.daily_choice.choose_the_method_adjust_options_and.3b986ea80dd2',
            ),
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _CustomRandomPickerCard extends StatelessWidget {
  const _CustomRandomPickerCard({
    required this.i18n,
    required this.accent,
    required this.mode,
    required this.animation,
    required this.onModeChanged,
    required this.onAnimationChanged,
  });

  final AppI18n i18n;
  final Color accent;
  final DailyChoiceCustomRandomMode mode;
  final DailyChoiceCustomRandomAnimation animation;
  final ValueChanged<DailyChoiceCustomRandomMode> onModeChanged;
  final ValueChanged<DailyChoiceCustomRandomAnimation> onAnimationChanged;

  @override
  Widget build(BuildContext context) {
    return ToolboxSurfaceCard(
      padding: const EdgeInsets.all(16),
      radius: ToolboxUiTokens.sectionPanelRadius,
      borderColor: accent.withValues(alpha: 0.16),
      shadowOpacity: 0.04,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SelectorTitle(
            i18n: i18n,
            titleKey: 'inline.plan295.daily_choice.random_method.3866c2125b0d',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DailyChoiceCustomRandomMode.values
                .map(
                  (item) => ToolboxSelectablePill(
                    selected: mode == item,
                    tint: accent,
                    onTap: () => onModeChanged(item),
                    leading: Icon(_modeIcon(item), size: 18),
                    label: Text(_modeLabel(i18n, item)),
                    tooltip: _modeTooltip(i18n, item),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
          _SelectorTitle(
            i18n: i18n,
            titleKey: 'inline.plan295.daily_choice.animation.2b0623764f4e',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DailyChoiceCustomRandomAnimation.values
                .map(
                  (item) => ToolboxSelectablePill(
                    selected: animation == item,
                    tint: accent,
                    onTap: () => onAnimationChanged(item),
                    leading: Icon(_animationIcon(item), size: 18),
                    label: Text(_animationLabel(i18n, item)),
                    tooltip: _animationTooltip(i18n, item),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _CustomRandomStageHeader extends StatelessWidget {
  const _CustomRandomStageHeader({
    required this.i18n,
    required this.accent,
    required this.result,
    required this.probability,
  });

  final AppI18n i18n;
  final Color accent;
  final DailyChoiceCustomRandomResult? result;
  final double? probability;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final winner = result?.winner.label;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          winner == null
              ? i18n.t('inline.plan295.daily_choice.ready_to_draw.52bfde9e6b05')
              : i18n.t(
                  'inline.plan295.daily_choice.picked_winner.c2edd09aaca4',
                  params: <String, Object?>{'winner': winner},
                ),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            ToolboxInfoPill(
              text: result == null
                  ? i18n.t(
                      'inline.plan295.daily_choice.low_stakes_choice.161a004aef8e',
                    )
                  : _resultModeText(i18n, result!),
              accent: accent,
              backgroundColor: theme.colorScheme.surfaceContainerLow,
            ),
            if (probability != null)
              ToolboxInfoPill(
                text: i18n.t(
                  'inline.plan295.daily_choice.chance_probability_100_tostringasfix.e6be7d710fa0',
                  params: <String, Object?>{
                    'probability': (probability! * 100).toStringAsFixed(1),
                  },
                ),
                accent: accent,
                backgroundColor: theme.colorScheme.surfaceContainerLow,
              ),
          ],
        ),
      ],
    );
  }
}

class _CustomRandomParameterCard extends StatelessWidget {
  const _CustomRandomParameterCard({
    required this.i18n,
    required this.accent,
    required this.mode,
    required this.animation,
    required this.optionCount,
    required this.totalCount,
    required this.rounds,
    required this.diceCount,
    required this.coinCount,
    required this.revision,
    required this.items,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onRoundsChanged,
    required this.onDiceCountChanged,
    required this.onCoinCountChanged,
    required this.onOptionChanged,
    required this.onAddOption,
    required this.onDelete,
  });

  final AppI18n i18n;
  final Color accent;
  final DailyChoiceCustomRandomMode mode;
  final DailyChoiceCustomRandomAnimation animation;
  final int optionCount;
  final int totalCount;
  final int rounds;
  final int diceCount;
  final int coinCount;
  final int revision;
  final List<_CustomRandomDraft> items;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final ValueChanged<int> onRoundsChanged;
  final ValueChanged<int> onDiceCountChanged;
  final ValueChanged<int> onCoinCountChanged;
  final VoidCallback onOptionChanged;
  final VoidCallback onAddOption;
  final void Function(_CustomRandomDraft item) onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final closedColor = theme.colorScheme.tertiary;
    return ToolboxSurfaceCard(
      padding: const EdgeInsets.all(16),
      radius: ToolboxUiTokens.sectionPanelRadius,
      borderColor: (expanded ? accent : closedColor).withValues(alpha: 0.18),
      shadowColor: accent,
      shadowOpacity: 0.05,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InkWell(
            borderRadius: BorderRadius.circular(ToolboxUiTokens.cardRadius),
            onTap: onToggleExpanded,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.tune_rounded,
                    color: expanded ? accent : closedColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          i18n.t(
                            'inline.plan295.daily_choice.options_parameters.b274ec6b0ca1',
                          ),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          i18n.t(
                            'inline.plan295.daily_choice.tune_the_pool_before_drawing.201655bcfef2',
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _DecisionExpandIcon(
                    expanded: expanded,
                    openColor: accent,
                    closedColor: closedColor,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ToolboxInfoPill(
                text: i18n.t(
                  'inline.plan295.daily_choice.optioncount_active_totalcount_total.1f956fa63ee7',
                  params: <String, Object?>{
                    'optionCount': optionCount,
                    'totalCount': totalCount,
                  },
                ),
                accent: accent,
                backgroundColor: theme.colorScheme.surfaceContainerLow,
              ),
              ToolboxInfoPill(
                text: _modeLabel(i18n, mode),
                accent: accent,
                backgroundColor: theme.colorScheme.surfaceContainerLow,
              ),
              ToolboxInfoPill(
                text: _animationLabel(i18n, animation),
                accent: accent,
                backgroundColor: theme.colorScheme.surfaceContainerLow,
              ),
            ],
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 14),
                _CustomRandomSettingsCard(
                  i18n: i18n,
                  accent: accent,
                  mode: mode,
                  animation: animation,
                  optionCount: optionCount,
                  rounds: rounds,
                  diceCount: diceCount,
                  coinCount: coinCount,
                  onRoundsChanged: onRoundsChanged,
                  onDiceCountChanged: onDiceCountChanged,
                  onCoinCountChanged: onCoinCountChanged,
                ),
                const SizedBox(height: 14),
                Divider(color: theme.colorScheme.outlineVariant),
                const SizedBox(height: 10),
                _CustomRandomOptionEditorCard(
                  i18n: i18n,
                  accent: accent,
                  mode: mode,
                  revision: revision,
                  items: items,
                  optionCount: optionCount,
                  totalCount: totalCount,
                  onChanged: onOptionChanged,
                  onAddOption: onAddOption,
                  onDelete: onDelete,
                ),
              ],
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: AppDurations.expand,
            firstCurve: AppEasing.conceal,
            secondCurve: AppEasing.standard,
            sizeCurve: AppEasing.standard,
          ),
        ],
      ),
    );
  }
}

class _CustomRandomSettingsCard extends StatelessWidget {
  const _CustomRandomSettingsCard({
    required this.i18n,
    required this.accent,
    required this.mode,
    required this.animation,
    required this.optionCount,
    required this.rounds,
    required this.diceCount,
    required this.coinCount,
    required this.onRoundsChanged,
    required this.onDiceCountChanged,
    required this.onCoinCountChanged,
  });

  final AppI18n i18n;
  final Color accent;
  final DailyChoiceCustomRandomMode mode;
  final DailyChoiceCustomRandomAnimation animation;
  final int optionCount;
  final int rounds;
  final int diceCount;
  final int coinCount;
  final ValueChanged<int> onRoundsChanged;
  final ValueChanged<int> onDiceCountChanged;
  final ValueChanged<int> onCoinCountChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showRounds = mode == DailyChoiceCustomRandomMode.jointDistribution;
    final showDice = animation == DailyChoiceCustomRandomAnimation.dice;
    final showCoin = animation == DailyChoiceCustomRandomAnimation.coin;
    final diceMin = optionCount < 3
        ? 1
        : (optionCount / 12).ceil().clamp(1, optionCount).toInt();
    final diceMax = optionCount < 3
        ? 1
        : (optionCount / 3).floor().clamp(1, optionCount).toInt();
    final normalizedDiceCount = diceCount.clamp(diceMin, diceMax);

    if (!showRounds && !showDice && !showCoin) {
      return Text(
        i18n.t(
          'inline.plan295.daily_choice.the_wheel_uses_the_current_probabili.9556b7c21337',
        ),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.35,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SelectorTitle(
          i18n: i18n,
          titleKey: 'inline.plan295.daily_choice.settings.a971368c41f3',
        ),
        if (showRounds)
          _LabeledSlider(
            accent: accent,
            label: i18n.t(
              'inline.plan295.daily_choice.joint_rounds.e6fcfdd1549f',
            ),
            value: rounds.toDouble(),
            min: 2,
            max: 8,
            divisions: 6,
            displayValue: '$rounds',
            onChanged: (value) => onRoundsChanged(value.round()),
          ),
        if (showDice)
          _LabeledSlider(
            accent: accent,
            label: i18n.t('toolbox.daily_choice.dice_count'),
            value: normalizedDiceCount.toDouble(),
            min: diceMin.toDouble(),
            max: diceMax.toDouble(),
            divisions: math.max(1, diceMax - diceMin),
            displayValue: i18n.t(
              'inline.plan295.daily_choice.normalizeddicecount_dice.01bcc648c3ef',
              params: <String, Object?>{
                'normalizedDiceCount': normalizedDiceCount,
              },
            ),
            onChanged: diceMin == diceMax
                ? null
                : (value) => onDiceCountChanged(value.round()),
          ),
        if (showDice)
          Text(
            i18n.t(
              'inline.plan295.daily_choice.options_are_split_across_dice_with_3.bf350de55295',
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        if (showCoin)
          _LabeledSlider(
            accent: accent,
            label: i18n.t(
              'inline.ui.pages.toolbox_daily_choice.daily_choice_custom_random_widgets.coin_count_a089b2',
            ),
            value: coinCount.toDouble(),
            min: 1,
            max: 9,
            divisions: 8,
            displayValue: i18n.t(
              'inline.plan295.daily_choice.coincount_coins.a049170d5974',
              params: <String, Object?>{'coinCount': coinCount},
            ),
            onChanged: (value) {
              var next = value.round();
              if (next.isEven) {
                next += next >= 9 ? -1 : 1;
              }
              onCoinCountChanged(next);
            },
          ),
        if (showCoin)
          Text(
            i18n.t(
              'inline.plan295.daily_choice.coins_support_exactly_two_uniform_si.23de76602e89',
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
      ],
    );
  }
}

class _CustomRandomOptionEditorCard extends StatelessWidget {
  const _CustomRandomOptionEditorCard({
    required this.i18n,
    required this.accent,
    required this.mode,
    required this.revision,
    required this.items,
    required this.optionCount,
    required this.totalCount,
    required this.onChanged,
    required this.onAddOption,
    required this.onDelete,
  });

  final AppI18n i18n;
  final Color accent;
  final DailyChoiceCustomRandomMode mode;
  final int revision;
  final List<_CustomRandomDraft> items;
  final int optionCount;
  final int totalCount;
  final VoidCallback onChanged;
  final VoidCallback onAddOption;
  final void Function(_CustomRandomDraft item) onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    i18n.t(
                      'inline.plan295.daily_choice.options_and_probability_inputs.50256b3881dd',
                    ),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    i18n.t(
                      'inline.plan295.daily_choice.weights_power_weighted_random_joint.069aaee184fb',
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                ToolboxInfoPill(
                  text: i18n.t(
                    'inline.ui.pages.toolbox_daily_choice.daily_choice_custom_random_widgets.optioncount_totalcount_7b7994',
                    params: <String, Object?>{
                      'optionCount': optionCount,
                      'totalCount': totalCount,
                    },
                  ),
                  accent: accent,
                  backgroundColor: theme.colorScheme.surfaceContainerLow,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: items.length >= 36 ? null : onAddOption,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                    i18n.t(
                      'inline.ui.pages.toolbox_daily_choice.daily_choice_custom_random_widgets.add_d63aeb',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < items.length; index += 1) ...<Widget>[
          _CustomRandomOptionRow(
            key: ValueKey<String>('custom-random-$revision-${items[index].id}'),
            i18n: i18n,
            accent: accent,
            index: index,
            item: items[index],
            mode: mode,
            canDelete: items.length > 2,
            onChanged: onChanged,
            onDelete: () => onDelete(items[index]),
          ),
          if (index != items.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _CustomRandomOptionRow extends StatelessWidget {
  const _CustomRandomOptionRow({
    super.key,
    required this.i18n,
    required this.accent,
    required this.index,
    required this.item,
    required this.mode,
    required this.canDelete,
    required this.onChanged,
    required this.onDelete,
  });

  final AppI18n i18n;
  final Color accent;
  final int index;
  final _CustomRandomDraft item;
  final DailyChoiceCustomRandomMode mode;
  final bool canDelete;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showWeight = mode != DailyChoiceCustomRandomMode.uniform;
    final showProbability =
        mode == DailyChoiceCustomRandomMode.jointDistribution;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(ToolboxUiTokens.cardRadius),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 14,
                backgroundColor: accent.withValues(alpha: 0.14),
                child: Text(
                  '${index + 1}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  initialValue: item.label,
                  decoration: InputDecoration(
                    labelText: i18n.t(
                      'inline.ui.pages.toolbox_daily_choice.daily_choice_custom_random_widgets.option_name_e28e73',
                    ),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    item.label = value;
                    onChanged();
                  },
                ),
              ),
              IconButton(
                tooltip: i18n.t(
                  'inline.ui.pages.toolbox_daily_choice.daily_choice_custom_random_widgets.delete_option_da6945',
                ),
                onPressed: canDelete ? onDelete : null,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          if (showWeight || showProbability) ...<Widget>[
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                if (showWeight)
                  _CompactNumberField(
                    label: i18n.t(
                      'inline.ui.pages.toolbox_daily_choice.daily_choice_custom_random_widgets.weight_0c7d9e',
                    ),
                    value: item.weight,
                    max: 999,
                    onChanged: (value) {
                      item.weight = value;
                      onChanged();
                    },
                  ),
                if (showProbability)
                  _CompactNumberField(
                    label: i18n.t(
                      'inline.plan295.daily_choice.condition_p.216fb52f99d1',
                    ),
                    value: item.conditionProbability,
                    max: 1,
                    fractionDigits: 2,
                    onChanged: (value) {
                      item.conditionProbability = value;
                      onChanged();
                    },
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CompactNumberField extends StatelessWidget {
  const _CompactNumberField({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
    this.fractionDigits = 1,
  });

  final String label;
  final double value;
  final double max;
  final ValueChanged<double> onChanged;
  final int fractionDigits;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      child: TextFormField(
        initialValue: value.toStringAsFixed(fractionDigits),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label, isDense: true),
        onChanged: (raw) {
          final parsed = double.tryParse(raw.trim());
          if (parsed == null) {
            return;
          }
          onChanged(parsed.clamp(0.0, max).toDouble());
        },
      ),
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  const _LabeledSlider({
    required this.accent,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.displayValue,
    required this.onChanged,
  });

  final Color accent;
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String displayValue;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ToolboxInfoPill(
              text: displayValue,
              accent: accent,
              backgroundColor: theme.colorScheme.surfaceContainerLow,
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max).toDouble(),
          min: min,
          max: max,
          divisions: divisions,
          activeColor: accent,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _SelectorTitle extends StatelessWidget {
  const _SelectorTitle({required this.i18n, required this.titleKey});

  final AppI18n i18n;
  final String titleKey;

  @override
  Widget build(BuildContext context) {
    return Text(
      i18n.t(titleKey),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w900,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

IconData _modeIcon(DailyChoiceCustomRandomMode mode) {
  return switch (mode) {
    DailyChoiceCustomRandomMode.uniform => Icons.grid_view_rounded,
    DailyChoiceCustomRandomMode.weighted => Icons.balance_rounded,
    DailyChoiceCustomRandomMode.jointDistribution => Icons.account_tree_rounded,
  };
}

String _modeLabel(AppI18n i18n, DailyChoiceCustomRandomMode mode) {
  return switch (mode) {
    DailyChoiceCustomRandomMode.uniform => i18n.t(
      'inline.ui.pages.toolbox_daily_choice.daily_choice_custom_random_widgets.uniform_4f21a2',
    ),
    DailyChoiceCustomRandomMode.weighted => i18n.t(
      'inline.plan295.daily_choice.weighted.c6764d5354d0',
    ),
    DailyChoiceCustomRandomMode.jointDistribution => i18n.t(
      'inline.plan295.daily_choice.joint_rounds.b02f67c26c9e',
    ),
  };
}

String _modeTooltip(AppI18n i18n, DailyChoiceCustomRandomMode mode) {
  return switch (mode) {
    DailyChoiceCustomRandomMode.uniform => i18n.t(
      'inline.plan295.daily_choice.every_option_has_equal_chance.7e1dc2e1f5cc',
    ),
    DailyChoiceCustomRandomMode.weighted => i18n.t(
      'inline.plan295.daily_choice.chance_follows_weights.9225f9e37b0c',
    ),
    DailyChoiceCustomRandomMode.jointDistribution => i18n.t(
      'inline.plan295.daily_choice.draw_multiple_rounds_by_weight_condi.89c1413f1b32',
    ),
  };
}

IconData _animationIcon(DailyChoiceCustomRandomAnimation animation) {
  return switch (animation) {
    DailyChoiceCustomRandomAnimation.wheel => Icons.motion_photos_on_rounded,
    DailyChoiceCustomRandomAnimation.dice => Icons.casino_rounded,
    DailyChoiceCustomRandomAnimation.coin => Icons.monetization_on_rounded,
  };
}

String _animationLabel(
  AppI18n i18n,
  DailyChoiceCustomRandomAnimation animation,
) {
  return switch (animation) {
    DailyChoiceCustomRandomAnimation.wheel => i18n.t(
      'inline.plan295.daily_choice.wheel.14a2333632de',
    ),
    DailyChoiceCustomRandomAnimation.dice => i18n.t(
      'inline.ui.pages.toolbox_daily_choice.daily_choice_custom_random_widgets.dice_d3eb5d',
    ),
    DailyChoiceCustomRandomAnimation.coin => i18n.t(
      'inline.ui.pages.toolbox_daily_choice.daily_choice_custom_random_widgets.coin_93fd28',
    ),
  };
}

String _animationTooltip(
  AppI18n i18n,
  DailyChoiceCustomRandomAnimation animation,
) {
  return switch (animation) {
    DailyChoiceCustomRandomAnimation.wheel => i18n.t(
      'inline.plan295.daily_choice.supports_uniform_weighted_and_joint.ebc6b50d5ebf',
    ),
    DailyChoiceCustomRandomAnimation.dice => i18n.t(
      'inline.plan295.daily_choice.uniform_random_each_die_has_3_to_12.9deef4845d1a',
    ),
    DailyChoiceCustomRandomAnimation.coin => i18n.t(
      'inline.plan295.daily_choice.two_uniform_sides_with_multiple_coin.cf7bdd7d129e',
    ),
  };
}

String _resultModeText(AppI18n i18n, DailyChoiceCustomRandomResult result) {
  return switch (result.mode) {
    DailyChoiceCustomRandomMode.uniform => i18n.t(
      'toolbox.daily_choice.uniform_random',
    ),
    DailyChoiceCustomRandomMode.weighted => i18n.t(
      'inline.ui.pages.toolbox_daily_choice.daily_choice_custom_random_widgets.weighted_random_28af44',
    ),
    DailyChoiceCustomRandomMode.jointDistribution => i18n.t(
      'inline.plan295.daily_choice.result_roundpicks_length_joint_round.7bdfffffafc9',
      params: <String, Object?>{'resultRoundPicks': result.roundPicks.length},
    ),
  };
}
