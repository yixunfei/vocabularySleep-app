import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../../../i18n/app_i18n.dart';
import '../../motion/app_motion.dart';
import '../../ui_copy.dart';
import '../toolbox/toolbox_ui_components.dart';
import '../toolbox/toolbox_ui_tokens.dart';
import 'daily_choice_eat_library_store.dart';
import 'daily_choice_eat_support.dart';
import 'daily_choice_models.dart';
import 'daily_choice_seed_data.dart';

part 'daily_choice_detail_sheets.dart';
part 'daily_choice_editor_sheet.dart';
part 'daily_choice_manager_sheet.dart';
part 'daily_choice_manager_query_helpers.dart';
part 'daily_choice_manager_section_widgets.dart';
part 'daily_choice_manager_collection_io.dart';
part 'daily_choice_manager_dialogs.dart';

class DailyChoiceHeroPanel extends StatelessWidget {
  const DailyChoiceHeroPanel({
    super.key,
    required this.i18n,
    required this.accent,
  });
  final AppI18n i18n;
  final Color accent;
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
          theme.colorScheme.secondaryContainer.withValues(alpha: 0.34),
        ],
      ),
      borderColor: accent.withValues(alpha: 0.22),
      shadowColor: accent,
      shadowOpacity: 0.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ToolboxInfoPill(
                text: pickUiText(i18n, zh: '五模块基础版', en: 'Five modules'),
                accent: accent,
                backgroundColor: Colors.white.withValues(alpha: 0.64),
              ),
              ToolboxInfoPill(
                text: pickUiText(i18n, zh: '本地自定义', en: 'Local custom'),
                accent: accent,
                backgroundColor: Colors.white.withValues(alpha: 0.64),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            pickUiText(i18n, zh: '先让选择动起来', en: 'Let the choice start moving'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            pickUiText(
              i18n,
              zh: '吃什么、穿什么、去哪儿、干什么和决策助手都在同一套轻量交互里：选条件、开始随机、停止选中，再按需查看详情或管理自己的条目。',
              en: 'Eat, wear, go, do, and decision tools share one light flow: choose conditions, randomize, stop, then inspect or manage your own entries.',
            ),
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}

class DailyChoiceModuleSwitcher extends StatelessWidget {
  const DailyChoiceModuleSwitcher({
    super.key,
    required this.i18n,
    required this.modules,
    required this.selectedId,
    required this.onSelected,
  });
  final AppI18n i18n;
  final List<DailyChoiceModuleConfig> modules;
  final String selectedId;
  final ValueChanged<String> onSelected;
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: modules
          .map((module) {
            return ToolboxSelectablePill(
              selected: selectedId == module.id,
              tint: module.accent,
              onTap: () => onSelected(module.id),
              leading: Icon(module.icon, size: 18),
              label: Text(module.title(i18n)),
            );
          })
          .toList(growable: false),
    );
  }
}

class DailyChoiceCategorySelector extends StatelessWidget {
  const DailyChoiceCategorySelector({
    super.key,
    required this.i18n,
    required this.title,
    required this.categories,
    required this.selectedId,
    required this.accent,
    required this.onSelected,
    this.compactUnselected = false,
  });
  final AppI18n i18n;
  final String title;
  final List<DailyChoiceCategory> categories;
  final String selectedId;
  final Color accent;
  final ValueChanged<String> onSelected;
  final bool compactUnselected;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: compactUnselected ? 6 : 8,
          runSpacing: compactUnselected ? 6 : 8,
          children: categories
              .map((category) {
                final selected = selectedId == category.id;
                return ToolboxSelectablePill(
                  selected: selected,
                  tint: accent,
                  onTap: () => onSelected(category.id),
                  leading: Icon(category.icon, size: 18),
                  showLabel: !compactUnselected || selected,
                  tooltip: compactUnselected ? category.title(i18n) : null,
                  padding: compactUnselected && !selected
                      ? const EdgeInsets.all(12)
                      : const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                  label: Text(category.title(i18n)),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }
}

class DailyChoiceRandomPanel extends StatefulWidget {
  const DailyChoiceRandomPanel({
    super.key,
    required this.i18n,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.options,
    required this.emptyText,
    required this.onDetail,
    required this.onManage,
    required this.onGuide,
    this.onPickRandomOption,
  });
  final AppI18n i18n;
  final Color accent;
  final String title;
  final String subtitle;
  final List<DailyChoiceOption> options;
  final String emptyText;
  final ValueChanged<DailyChoiceOption> onDetail;
  final VoidCallback onManage;
  final VoidCallback onGuide;
  final Future<DailyChoiceOption?> Function()? onPickRandomOption;
  @override
  State<DailyChoiceRandomPanel> createState() => _DailyChoiceRandomPanelState();
}

class _DailyChoiceRandomPanelState extends State<DailyChoiceRandomPanel> {
  static const Duration _finalPickTimeout = Duration(milliseconds: 1200);
  static const double _randomStageHeight = 224;
  final math.Random _random = math.Random();
  Timer? _timer;
  DailyChoiceOption? _current;
  DailyChoiceOption? _locked;
  bool _finalizingPick = false;
  int _pickGeneration = 0;
  bool get _running => _timer != null;
  @override
  void initState() {
    super.initState();
    _syncCurrentWithOptions();
  }

  @override
  void didUpdateWidget(covariant DailyChoiceRandomPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.options != widget.options) {
      _pickGeneration += 1;
      _finalizingPick = false;
      _syncCurrentWithOptions();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _syncCurrentWithOptions() {
    if (widget.options.isEmpty) {
      _timer?.cancel();
      _timer = null;
      _current = null;
      _locked = null;
      return;
    }
    if (_current == null || !_containsOptionId(_current!.id)) {
      _current = widget.options.first;
    }
    if (_locked != null && !_containsOptionId(_locked!.id)) {
      _locked = null;
    }
  }

  bool _containsOptionId(String optionId) {
    for (final option in widget.options) {
      if (option.id == optionId) {
        return true;
      }
    }
    return false;
  }

  void _toggleRandom() {
    if (widget.options.isEmpty) {
      return;
    }
    if (_running) {
      _timer?.cancel();
      _timer = null;
      _pickGeneration += 1;
      final generation = _pickGeneration;
      setState(() {
        _locked = _current ?? widget.options.first;
        _finalizingPick = widget.onPickRandomOption != null;
      });
      final picker = widget.onPickRandomOption;
      if (picker != null) {
        unawaited(_finalizeRandomPick(picker, generation));
      }
      return;
    }
    _pickGeneration += 1;
    setState(() {
      _finalizingPick = false;
      _locked = null;
      _current = widget.options[_random.nextInt(widget.options.length)];
    });
    _timer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (!mounted) {
        return;
      }
      if (widget.options.isEmpty) {
        _timer?.cancel();
        _timer = null;
        setState(() {
          _current = null;
          _locked = null;
        });
        return;
      }
      setState(() {
        _current = widget.options[_random.nextInt(widget.options.length)];
      });
    });
  }

  Future<void> _finalizeRandomPick(
    Future<DailyChoiceOption?> Function() picker,
    int generation,
  ) async {
    try {
      final picked = await picker().timeout(
        _finalPickTimeout,
        onTimeout: () => null,
      );
      if (!mounted || _running || generation != _pickGeneration) {
        return;
      }
      setState(() {
        if (picked != null) {
          _current = picked;
          _locked = picked;
        }
        _finalizingPick = false;
      });
    } catch (_) {
      if (!mounted || _running || generation != _pickGeneration) {
        return;
      }
      setState(() {
        _finalizingPick = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final display = _locked ?? _current;
    return ToolboxSurfaceCard(
      padding: const EdgeInsets.all(18),
      radius: ToolboxUiTokens.panelRadius,
      borderColor: widget.accent.withValues(alpha: 0.22),
      shadowColor: widget.accent,
      shadowOpacity: 0.08,
      child: Column(
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
                      widget.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              ToolboxIconPillButton(
                icon: Icons.help_outline_rounded,
                active: false,
                tint: widget.accent,
                tooltip: pickUiText(widget.i18n, zh: '指南', en: 'Guide'),
                onTap: widget.onGuide,
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: _randomStageHeight,
            child: AnimatedSwitcher(
              duration: _running ? Duration.zero : AppDurations.standard,
              switchInCurve: AppEasing.standard,
              switchOutCurve: AppEasing.conceal,
              child: display == null
                  ? _EmptyRandomStage(
                      key: const ValueKey<String>('empty'),
                      text: widget.emptyText,
                      accent: widget.accent,
                    )
                  : _OptionStage(
                      key: ValueKey<String>(
                        _running
                            ? 'running-option-stage'
                            : 'option-${display.id}-${_locked != null}',
                      ),
                      i18n: widget.i18n,
                      option: display,
                      accent: widget.accent,
                      locked: _locked != null,
                      running: _running,
                      onTap: () => widget.onDetail(display),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.icon(
                onPressed: widget.options.isEmpty || _finalizingPick
                    ? null
                    : _toggleRandom,
                icon: Icon(
                  _running ? Icons.stop_circle_rounded : Icons.casino_rounded,
                ),
                label: Text(
                  _finalizingPick
                      ? pickUiText(widget.i18n, zh: '选中中', en: 'Picking')
                      : (_running
                            ? pickUiText(widget.i18n, zh: '停止并选中', en: 'Stop')
                            : pickUiText(
                                widget.i18n,
                                zh: '开始随机',
                                en: 'Randomize',
                              )),
                ),
              ),
              OutlinedButton.icon(
                onPressed: display == null
                    ? null
                    : () => widget.onDetail(display),
                icon: const Icon(Icons.receipt_long_rounded),
                label: Text(pickUiText(widget.i18n, zh: '详情', en: 'Details')),
              ),
              OutlinedButton.icon(
                onPressed: widget.onManage,
                icon: const Icon(Icons.tune_rounded),
                label: Text(pickUiText(widget.i18n, zh: '管理', en: 'Manage')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyRandomStage extends StatelessWidget {
  const _EmptyRandomStage({
    super.key,
    required this.text,
    required this.accent,
  });
  final String text;
  final Color accent;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(ToolboxUiTokens.sectionPanelRadius),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _OptionStage extends StatelessWidget {
  const _OptionStage({
    super.key,
    required this.i18n,
    required this.option,
    required this.accent,
    required this.locked,
    required this.running,
    required this.onTap,
  });
  final AppI18n i18n;
  final DailyChoiceOption option;
  final Color accent;
  final bool locked;
  final bool running;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tags = option
        .tags(i18n)
        .take(running ? 2 : 3)
        .toList(growable: false);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(ToolboxUiTokens.sectionPanelRadius),
        onTap: onTap,
        child: Ink(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                accent.withValues(alpha: locked ? 0.2 : 0.13),
                theme.colorScheme.surface,
                theme.colorScheme.surfaceContainerLow,
              ],
            ),
            borderRadius: BorderRadius.circular(
              ToolboxUiTokens.sectionPanelRadius,
            ),
            border: Border.all(
              color: accent.withValues(alpha: locked ? 0.52 : 0.26),
            ),
            boxShadow: <BoxShadow>[
              toolboxPanelShadow(
                accent,
                opacity: locked ? 0.15 : 0.08,
                blurRadius: locked ? 22 : 16,
                offsetY: locked ? 12 : 8,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: accent.withValues(alpha: 0.22)),
                    ),
                    child: Icon(
                      locked
                          ? Icons.check_circle_rounded
                          : (running
                                ? Icons.autorenew_rounded
                                : Icons.casino_rounded),
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          locked
                              ? pickUiText(i18n, zh: '已选中', en: 'Selected')
                              : (running
                                    ? pickUiText(
                                        i18n,
                                        zh: '正在随机',
                                        en: 'Randomizing',
                                      )
                                    : pickUiText(
                                        i18n,
                                        zh: '当前候选',
                                        en: 'Current',
                                      )),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          option.title(i18n),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                option.subtitle(i18n),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
              if (tags.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags
                      .map(
                        (tag) => ToolboxInfoPill(
                          text: tag,
                          accent: accent,
                          backgroundColor: Colors.white.withValues(alpha: 0.62),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
