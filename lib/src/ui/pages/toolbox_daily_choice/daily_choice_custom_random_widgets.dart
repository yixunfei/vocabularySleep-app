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
                      text: pickUiText(
                        i18n,
                        zh: '随机助手',
                        en: 'Random assistant',
                      ),
                      accent: accent,
                      backgroundColor: Colors.white.withValues(alpha: 0.64),
                    ),
                    ToolboxInfoPill(
                      text: pickUiText(
                        i18n,
                        zh: '$optionCount 个选项',
                        en: '$optionCount options',
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
                tooltip: pickUiText(i18n, zh: '指南', en: 'Guide'),
                onTap: onGuide,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            pickUiText(
              i18n,
              zh: '把随机变成一个可调助手',
              en: 'Make randomness adjustable',
            ),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            pickUiText(
              i18n,
              zh: '先选随机方式，再就地调整选项、权重、轮次或骰子硬币数量，最后用转盘、骰子或硬币完成低风险选择。',
              en: 'Choose the method, adjust options and parameters in place, then draw with a wheel, dice, or coins for low-stakes choices.',
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
          _SelectorTitle(i18n: i18n, titleZh: '随机方式', titleEn: 'Random method'),
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
          _SelectorTitle(i18n: i18n, titleZh: '动画效果', titleEn: 'Animation'),
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
              ? pickUiText(i18n, zh: '等待抽取', en: 'Ready to draw')
              : pickUiText(i18n, zh: '抽中：$winner', en: 'Picked: $winner'),
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
                  ? pickUiText(i18n, zh: '低风险选择', en: 'Low-stakes choice')
                  : _resultModeText(i18n, result!),
              accent: accent,
              backgroundColor: theme.colorScheme.surfaceContainerLow,
            ),
            if (probability != null)
              ToolboxInfoPill(
                text: pickUiText(
                  i18n,
                  zh: '本轮概率 ${(probability! * 100).toStringAsFixed(1)}%',
                  en: 'Chance ${(probability! * 100).toStringAsFixed(1)}%',
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
                          pickUiText(
                            i18n,
                            zh: '可选项与参数',
                            en: 'Options & parameters',
                          ),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pickUiText(
                            i18n,
                            zh: '先调好候选池，再开始随机。',
                            en: 'Tune the pool before drawing.',
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
                text: pickUiText(
                  i18n,
                  zh: '有效 $optionCount / 总计 $totalCount',
                  en: '$optionCount active / $totalCount total',
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
        pickUiText(
          i18n,
          zh: '当前转盘会直接按所选随机方式计算概率；如果切到加权，扇区面积会跟随权重变化。',
          en: 'The wheel uses the current probability model. In weighted mode, segment size follows weight.',
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
        _SelectorTitle(i18n: i18n, titleZh: '参数设置', titleEn: 'Settings'),
        if (showRounds)
          _LabeledSlider(
            accent: accent,
            label: pickUiText(i18n, zh: '联合分布轮次', en: 'Joint rounds'),
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
            label: pickUiText(i18n, zh: '骰子数量', en: 'Dice count'),
            value: normalizedDiceCount.toDouble(),
            min: diceMin.toDouble(),
            max: diceMax.toDouble(),
            divisions: math.max(1, diceMax - diceMin),
            displayValue: pickUiText(
              i18n,
              zh: '$normalizedDiceCount 颗',
              en: '$normalizedDiceCount dice',
            ),
            onChanged: diceMin == diceMax
                ? null
                : (value) => onDiceCountChanged(value.round()),
          ),
        if (showDice)
          Text(
            pickUiText(
              i18n,
              zh: '选项会均匀分配到骰子上，每颗 3 到 12 面；结果仍在全部选项中均匀抽取。',
              en: 'Options are split across dice with 3 to 12 faces each; the final draw remains uniform across all options.',
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        if (showCoin)
          _LabeledSlider(
            accent: accent,
            label: pickUiText(i18n, zh: '硬币数量', en: 'Coin count'),
            value: coinCount.toDouble(),
            min: 1,
            max: 9,
            divisions: 8,
            displayValue: pickUiText(
              i18n,
              zh: '$coinCount 枚',
              en: '$coinCount coins',
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
            pickUiText(
              i18n,
              zh: '硬币只支持两面均匀；多枚硬币按多数面收口，数量保持奇数以避免平局。',
              en: 'Coins support exactly two uniform sides. Multiple coins use majority, kept odd to avoid ties.',
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
                    pickUiText(
                      i18n,
                      zh: '选项与概率参数',
                      en: 'Options and probability inputs',
                    ),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    pickUiText(
                      i18n,
                      zh: '权重用于加权随机；联合分布会使用“权重 × 条件概率”。空名称不会进入候选池。',
                      en: 'Weights power weighted random. Joint mode uses weight × condition probability. Empty names are ignored.',
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
                  text: pickUiText(
                    i18n,
                    zh: '$optionCount/$totalCount',
                    en: '$optionCount/$totalCount',
                  ),
                  accent: accent,
                  backgroundColor: theme.colorScheme.surfaceContainerLow,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: items.length >= 36 ? null : onAddOption,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(pickUiText(i18n, zh: '新增', en: 'Add')),
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
                    labelText: pickUiText(i18n, zh: '选项名称', en: 'Option name'),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    item.label = value;
                    onChanged();
                  },
                ),
              ),
              IconButton(
                tooltip: pickUiText(i18n, zh: '删除选项', en: 'Delete option'),
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
                    label: pickUiText(i18n, zh: '权重', en: 'Weight'),
                    value: item.weight,
                    max: 999,
                    onChanged: (value) {
                      item.weight = value;
                      onChanged();
                    },
                  ),
                if (showProbability)
                  _CompactNumberField(
                    label: pickUiText(i18n, zh: '条件概率', en: 'Condition P'),
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
  const _SelectorTitle({
    required this.i18n,
    required this.titleZh,
    required this.titleEn,
  });

  final AppI18n i18n;
  final String titleZh;
  final String titleEn;

  @override
  Widget build(BuildContext context) {
    return Text(
      pickUiText(i18n, zh: titleZh, en: titleEn),
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
    DailyChoiceCustomRandomMode.uniform => pickUiText(
      i18n,
      zh: '均匀',
      en: 'Uniform',
    ),
    DailyChoiceCustomRandomMode.weighted => pickUiText(
      i18n,
      zh: '加权',
      en: 'Weighted',
    ),
    DailyChoiceCustomRandomMode.jointDistribution => pickUiText(
      i18n,
      zh: '联合多轮',
      en: 'Joint rounds',
    ),
  };
}

String _modeTooltip(AppI18n i18n, DailyChoiceCustomRandomMode mode) {
  return switch (mode) {
    DailyChoiceCustomRandomMode.uniform => pickUiText(
      i18n,
      zh: '每个选项概率相同',
      en: 'Every option has equal chance',
    ),
    DailyChoiceCustomRandomMode.weighted => pickUiText(
      i18n,
      zh: '按权重分配概率',
      en: 'Chance follows weights',
    ),
    DailyChoiceCustomRandomMode.jointDistribution => pickUiText(
      i18n,
      zh: '按权重 × 条件概率多轮抽取',
      en: 'Draw multiple rounds by weight × condition probability',
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
    DailyChoiceCustomRandomAnimation.wheel => pickUiText(
      i18n,
      zh: '大转盘',
      en: 'Wheel',
    ),
    DailyChoiceCustomRandomAnimation.dice => pickUiText(
      i18n,
      zh: '骰子',
      en: 'Dice',
    ),
    DailyChoiceCustomRandomAnimation.coin => pickUiText(
      i18n,
      zh: '硬币',
      en: 'Coin',
    ),
  };
}

String _animationTooltip(
  AppI18n i18n,
  DailyChoiceCustomRandomAnimation animation,
) {
  return switch (animation) {
    DailyChoiceCustomRandomAnimation.wheel => pickUiText(
      i18n,
      zh: '支持均匀、加权和联合分布',
      en: 'Supports uniform, weighted, and joint modes',
    ),
    DailyChoiceCustomRandomAnimation.dice => pickUiText(
      i18n,
      zh: '均匀随机；每颗 3 到 12 面',
      en: 'Uniform random; each die has 3 to 12 faces',
    ),
    DailyChoiceCustomRandomAnimation.coin => pickUiText(
      i18n,
      zh: '两面均匀，可以抛多枚',
      en: 'Two uniform sides, with multiple coins',
    ),
  };
}

String _resultModeText(AppI18n i18n, DailyChoiceCustomRandomResult result) {
  return switch (result.mode) {
    DailyChoiceCustomRandomMode.uniform => pickUiText(
      i18n,
      zh: '均匀随机',
      en: 'Uniform random',
    ),
    DailyChoiceCustomRandomMode.weighted => pickUiText(
      i18n,
      zh: '加权随机',
      en: 'Weighted random',
    ),
    DailyChoiceCustomRandomMode.jointDistribution => pickUiText(
      i18n,
      zh: '${result.roundPicks.length} 轮联合分布',
      en: '${result.roundPicks.length} joint rounds',
    ),
  };
}
