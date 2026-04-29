part of 'daily_choice_widgets.dart';

class _ManagerSearchField extends StatefulWidget {
  const _ManagerSearchField({
    required this.i18n,
    required this.initialText,
    required this.labelZh,
    required this.labelEn,
    required this.hintZh,
    required this.hintEn,
    required this.onDraftChanged,
    required this.onCommitted,
  });

  final AppI18n i18n;
  final String initialText;
  final String labelZh;
  final String labelEn;
  final String hintZh;
  final String hintEn;
  final ValueChanged<String> onDraftChanged;
  final ValueChanged<String> onCommitted;

  @override
  State<_ManagerSearchField> createState() => _ManagerSearchFieldState();
}

class _ManagerSearchFieldState extends State<_ManagerSearchField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  var _lastCommittedText = '';

  @override
  void initState() {
    super.initState();
    _lastCommittedText = widget.initialText;
    _controller = TextEditingController(text: widget.initialText);
    _focusNode = FocusNode()..addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant _ManagerSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialText != oldWidget.initialText &&
        widget.initialText != _controller.text &&
        !_focusNode.hasFocus) {
      _controller.text = widget.initialText;
      _lastCommittedText = widget.initialText;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (!_focusNode.hasFocus) {
      _commit();
    }
  }

  void _commit() {
    final next = _controller.text.trim();
    if (next == _lastCommittedText.trim()) {
      return;
    }
    _lastCommittedText = next;
    widget.onCommitted(next);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        constraints: const BoxConstraints(minHeight: 48),
        prefixIcon: const Icon(Icons.search_rounded),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 42,
          minHeight: 42,
        ),
        labelText: pickUiText(
          widget.i18n,
          zh: widget.labelZh,
          en: widget.labelEn,
        ),
        hintText: pickUiText(widget.i18n, zh: widget.hintZh, en: widget.hintEn),
      ),
      onChanged: widget.onDraftChanged,
      onSubmitted: (_) {
        _commit();
        _focusNode.unfocus();
      },
      onTapOutside: (_) => _focusNode.unfocus(),
    );
  }
}

class _ManagerExpandableSection extends StatelessWidget {
  const _ManagerExpandableSection({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.expanded,
    required this.onToggle,
    required this.child,
    this.countLabel,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;
  final String? countLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ToolboxSurfaceCard(
        padding: const EdgeInsets.all(14),
        borderColor: accent.withValues(alpha: 0.14),
        shadowOpacity: 0.03,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            InkWell(
              borderRadius: BorderRadius.circular(
                ToolboxUiTokens.sectionPanelRadius,
              ),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (countLabel != null) ...<Widget>[
                      const SizedBox(width: 8),
                      ToolboxInfoPill(
                        text: countLabel!,
                        accent: accent,
                        backgroundColor: theme.colorScheme.surfaceContainerLow,
                      ),
                    ],
                    const SizedBox(width: 8),
                    AnimatedContainer(
                      duration: AppDurations.quick,
                      curve: AppEasing.standard,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: expanded ? 0.16 : 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Icon(
                        expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: accent,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (expanded) ...<Widget>[const SizedBox(height: 12), child],
          ],
        ),
      ),
    );
  }
}

class _ManagerHint extends StatelessWidget {
  const _ManagerHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        height: 1.35,
      ),
    );
  }
}

class _ManagerTraitFilterSection extends StatelessWidget {
  const _ManagerTraitFilterSection({
    required this.i18n,
    required this.accent,
    required this.group,
    required this.selectedId,
    required this.onSelected,
  });

  final AppI18n i18n;
  final Color accent;
  final DailyChoiceTraitGroup group;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          pickUiText(
            i18n,
            zh: '只看这个${group.titleZh}',
            en: 'Filter by ${group.titleEn}',
          ),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          group.subtitle(i18n),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            ToolboxSelectablePill(
              selected: selectedId == 'all',
              tint: accent,
              onTap: () => onSelected('all'),
              leading: const Icon(Icons.grid_view_rounded, size: 18),
              showLabel: selectedId == 'all',
              tooltip: pickUiText(i18n, zh: '全部', en: 'All'),
              padding: selectedId == 'all'
                  ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
                  : const EdgeInsets.all(12),
              label: Text(pickUiText(i18n, zh: '全部', en: 'All')),
            ),
            ...group.options.map((option) {
              final selected = selectedId == option.id;
              return ToolboxSelectablePill(
                selected: selected,
                tint: accent,
                onTap: () => onSelected(option.id),
                leading: Icon(option.icon, size: 18),
                showLabel: selected,
                tooltip: option.title(i18n),
                padding: selected
                    ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
                    : const EdgeInsets.all(12),
                label: Text(option.title(i18n)),
              );
            }),
          ],
        ),
      ],
    );
  }
}

class _ManagerTile extends StatelessWidget {
  const _ManagerTile({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.leading,
    required this.actions,
    this.chips = const <String>[],
    this.statusMessage,
    this.statusIsLoading = false,
    this.statusIsError = false,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final IconData leading;
  final List<Widget> actions;
  final List<String> chips;
  final String? statusMessage;
  final bool statusIsLoading;
  final bool statusIsError;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ToolboxSurfaceCard(
        padding: EdgeInsets.zero,
        borderColor: accent.withValues(alpha: 0.14),
        shadowOpacity: 0.03,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(
              ToolboxUiTokens.sectionPanelRadius,
            ),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(leading, color: accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              subtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.3,
                              ),
                            ),
                            if (chips.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: chips
                                    .map(
                                      (chip) => ToolboxInfoPill(
                                        text: chip,
                                        accent: accent,
                                        backgroundColor: theme
                                            .colorScheme
                                            .surfaceContainerLow,
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                            ],
                            if (statusMessage != null) ...<Widget>[
                              const SizedBox(height: 8),
                              _ManagerTileStatus(
                                message: statusMessage!,
                                accent: accent,
                                isLoading: statusIsLoading,
                                isError: statusIsError,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (actions.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, runSpacing: 8, children: actions),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ManagerTileStatus extends StatelessWidget {
  const _ManagerTileStatus({
    required this.message,
    required this.accent,
    required this.isLoading,
    required this.isError,
  });

  final String message;
  final Color accent;
  final bool isLoading;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isError ? theme.colorScheme.error : accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isError
            ? theme.colorScheme.errorContainer.withValues(alpha: 0.42)
            : accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (isLoading)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: accent),
            )
          else
            Icon(
              isError ? Icons.error_outline_rounded : Icons.info_outline,
              size: 16,
              color: color,
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isError ? theme.colorScheme.onErrorContainer : color,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagerProcessingOverlay extends StatelessWidget {
  const _ManagerProcessingOverlay({
    required this.message,
    required this.accent,
  });

  final String message;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.scrim.withValues(alpha: 0.18),
      child: Center(
        child: ToolboxSurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          borderColor: accent.withValues(alpha: 0.18),
          shadowOpacity: 0.08,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: accent),
              ),
              const SizedBox(width: 10),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

int _managerInitialBuiltInLimit(bool isEatModule) => isEatModule ? 80 : 120;

int _managerBuiltInPageSize(bool isEatModule) => isEatModule ? 80 : 120;

const _managerActionInspect = 'inspect';
const _managerActionAdjust = 'adjust';
const _managerActionSaveAs = 'save_as';
const _managerDetailActionIds = <String>[
  _managerActionInspect,
  _managerActionAdjust,
  _managerActionSaveAs,
];

String _managerActionKey(String actionId, String optionId) {
  return '$actionId\u0001$optionId';
}

String _managerActionLoadingText(AppI18n i18n, String actionId) {
  return switch (actionId) {
    _managerActionInspect => pickUiText(
      i18n,
      zh: '正在读取菜谱详情...',
      en: 'Loading recipe details...',
    ),
    _managerActionAdjust => pickUiText(
      i18n,
      zh: '正在准备个人调整...',
      en: 'Preparing adjustment...',
    ),
    _managerActionSaveAs => pickUiText(
      i18n,
      zh: '正在准备另存副本...',
      en: 'Preparing a copy...',
    ),
    _ => pickUiText(i18n, zh: '正在处理...', en: 'Working...'),
  };
}

String _managerActionErrorText(AppI18n i18n, String actionId, Object error) {
  return switch (actionId) {
    _managerActionInspect => pickUiText(
      i18n,
      zh: '详情读取失败：$error',
      en: 'Details could not be loaded: $error',
    ),
    _managerActionAdjust => pickUiText(
      i18n,
      zh: '个人调整准备失败：$error',
      en: 'Adjustment could not be prepared: $error',
    ),
    _managerActionSaveAs => pickUiText(
      i18n,
      zh: '另存前读取失败：$error',
      en: 'Copy could not be prepared: $error',
    ),
    _ => pickUiText(i18n, zh: '操作失败：$error', en: 'Action failed: $error'),
  };
}

Widget _managerAsyncActionButton({
  required AppI18n i18n,
  required IconData icon,
  required String labelZh,
  required String labelEn,
  required bool loading,
  required bool enabled,
  required VoidCallback onPressed,
}) {
  return TextButton.icon(
    onPressed: enabled ? onPressed : null,
    icon: loading
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(icon),
    label: Text(pickUiText(i18n, zh: labelZh, en: labelEn)),
  );
}

List<Widget> _managerCollectionActions({
  required BuildContext context,
  required AppI18n i18n,
  required List<DailyChoiceEatCollection> collections,
  required DailyChoiceEatCollection? selectedCollection,
  required String optionId,
  required ValueChanged<Set<String>> onAddMultiple,
  required ValueChanged<String> onRemove,
}) {
  if (collections.isEmpty) {
    return const <Widget>[];
  }
  final actions = <Widget>[
    TextButton.icon(
      onPressed: () async {
        final selectedIds = await _showEatCollectionPicker(
          context: context,
          i18n: i18n,
          collections: collections,
          optionId: optionId,
        );
        if (selectedIds == null || selectedIds.isEmpty) {
          return;
        }
        onAddMultiple(selectedIds);
      },
      icon: const Icon(Icons.favorite_border_rounded),
      label: Text(pickUiText(i18n, zh: '喜欢/加入', en: 'Like / add')),
    ),
  ];
  if (selectedCollection != null &&
      selectedCollection.containsOption(optionId)) {
    actions.add(
      TextButton.icon(
        onPressed: () => onRemove(selectedCollection.id),
        icon: const Icon(Icons.playlist_remove_rounded),
        label: Text(pickUiText(i18n, zh: '移出当前集合', en: 'Remove from set')),
      ),
    );
  }
  return actions;
}

List<Widget> _managerWearCollectionActions({
  required BuildContext context,
  required AppI18n i18n,
  required List<DailyChoiceWearCollection> collections,
  required DailyChoiceWearCollection? selectedCollection,
  required String optionId,
  required ValueChanged<Set<String>> onAddMultiple,
  required ValueChanged<String> onRemove,
}) {
  if (collections.isEmpty) {
    return const <Widget>[];
  }
  final actions = <Widget>[
    TextButton.icon(
      onPressed: () async {
        final selectedIds = await _showWearCollectionPicker(
          context: context,
          i18n: i18n,
          collections: collections,
          optionId: optionId,
        );
        if (selectedIds == null || selectedIds.isEmpty) {
          return;
        }
        onAddMultiple(selectedIds);
      },
      icon: const Icon(Icons.checkroom_rounded),
      label: Text(pickUiText(i18n, zh: '加入衣橱', en: 'Add to wardrobe')),
    ),
  ];
  if (selectedCollection != null &&
      selectedCollection.containsOption(optionId)) {
    actions.add(
      TextButton.icon(
        onPressed: () => onRemove(selectedCollection.id),
        icon: const Icon(Icons.playlist_remove_rounded),
        label: Text(pickUiText(i18n, zh: '移出当前衣橱', en: 'Remove from wardrobe')),
      ),
    );
  }
  return actions;
}

List<Widget> _managerActivityCollectionActions({
  required BuildContext context,
  required AppI18n i18n,
  required List<DailyChoiceActivityCollection> collections,
  required DailyChoiceActivityCollection? selectedCollection,
  required String optionId,
  required ValueChanged<Set<String>> onAddMultiple,
  required ValueChanged<String> onRemove,
}) {
  if (collections.isEmpty) {
    return const <Widget>[];
  }
  final actions = <Widget>[
    TextButton.icon(
      onPressed: () async {
        final selectedIds = await _showActivityCollectionPicker(
          context: context,
          i18n: i18n,
          collections: collections,
          optionId: optionId,
        );
        if (selectedIds == null || selectedIds.isEmpty) {
          return;
        }
        onAddMultiple(selectedIds);
      },
      icon: const Icon(Icons.playlist_add_check_rounded),
      label: Text(pickUiText(i18n, zh: '加入行动集', en: 'Add to set')),
    ),
  ];
  if (selectedCollection != null &&
      selectedCollection.containsOption(optionId)) {
    actions.add(
      TextButton.icon(
        onPressed: () => onRemove(selectedCollection.id),
        icon: const Icon(Icons.playlist_remove_rounded),
        label: Text(pickUiText(i18n, zh: '移出当前行动集', en: 'Remove from set')),
      ),
    );
  }
  return actions;
}

Future<Set<String>?> _showWearCollectionPicker({
  required BuildContext context,
  required AppI18n i18n,
  required List<DailyChoiceWearCollection> collections,
  required String optionId,
}) {
  final initialSelected = <String>{
    dailyChoiceFavoriteWearCollectionId,
    for (final collection in collections)
      if (collection.containsOption(optionId)) collection.id,
  };
  return showDialog<Set<String>>(
    context: context,
    builder: (context) {
      final selectedIds = initialSelected.toSet();
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(pickUiText(i18n, zh: '加入衣橱', en: 'Add to wardrobe')),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: collections
                      .map(
                        (collection) => CheckboxListTile(
                          value: selectedIds.contains(collection.id),
                          onChanged: (value) {
                            setDialogState(() {
                              if (value == true) {
                                selectedIds.add(collection.id);
                              } else {
                                selectedIds.remove(collection.id);
                              }
                            });
                          },
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(collection.title(i18n)),
                          subtitle: Text(
                            pickUiText(
                              i18n,
                              zh: '${collection.optionIds.length} 套搭配',
                              en: '${collection.optionIds.length} outfits',
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(pickUiText(i18n, zh: '取消', en: 'Cancel')),
              ),
              FilledButton.icon(
                onPressed: selectedIds.isEmpty
                    ? null
                    : () => Navigator.of(context).pop(selectedIds),
                icon: const Icon(Icons.check_rounded),
                label: Text(pickUiText(i18n, zh: '确认加入', en: 'Add')),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<Set<String>?> _showActivityCollectionPicker({
  required BuildContext context,
  required AppI18n i18n,
  required List<DailyChoiceActivityCollection> collections,
  required String optionId,
}) {
  final initialSelected = <String>{
    dailyChoiceFavoriteActivityCollectionId,
    for (final collection in collections)
      if (collection.containsOption(optionId)) collection.id,
  };
  return showDialog<Set<String>>(
    context: context,
    builder: (context) {
      final selectedIds = initialSelected.toSet();
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(pickUiText(i18n, zh: '加入行动集', en: 'Add to action set')),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: collections
                      .map(
                        (collection) => CheckboxListTile(
                          value: selectedIds.contains(collection.id),
                          onChanged: (value) {
                            setDialogState(() {
                              if (value == true) {
                                selectedIds.add(collection.id);
                              } else {
                                selectedIds.remove(collection.id);
                              }
                            });
                          },
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(collection.title(i18n)),
                          subtitle: Text(
                            pickUiText(
                              i18n,
                              zh: '${collection.optionIds.length} 个行动',
                              en: '${collection.optionIds.length} actions',
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(pickUiText(i18n, zh: '取消', en: 'Cancel')),
              ),
              FilledButton.icon(
                onPressed: selectedIds.isEmpty
                    ? null
                    : () => Navigator.of(context).pop(selectedIds),
                icon: const Icon(Icons.check_rounded),
                label: Text(pickUiText(i18n, zh: '确认加入', en: 'Add')),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<Set<String>?> _showEatCollectionPicker({
  required BuildContext context,
  required AppI18n i18n,
  required List<DailyChoiceEatCollection> collections,
  required String optionId,
}) {
  final initialSelected = <String>{
    dailyChoiceFavoriteEatCollectionId,
    for (final collection in collections)
      if (collection.containsOption(optionId)) collection.id,
  };
  return showDialog<Set<String>>(
    context: context,
    builder: (context) {
      final selectedIds = initialSelected.toSet();
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(pickUiText(i18n, zh: '喜欢/加入', en: 'Like / add')),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: collections
                      .map(
                        (collection) => CheckboxListTile(
                          value: selectedIds.contains(collection.id),
                          onChanged: (value) {
                            setDialogState(() {
                              if (value == true) {
                                selectedIds.add(collection.id);
                              } else {
                                selectedIds.remove(collection.id);
                              }
                            });
                          },
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(collection.title(i18n)),
                          subtitle: Text(
                            pickUiText(
                              i18n,
                              zh: '${collection.optionIds.length} 道菜',
                              en: '${collection.optionIds.length} recipes',
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(pickUiText(i18n, zh: '取消', en: 'Cancel')),
              ),
              FilledButton.icon(
                onPressed: selectedIds.isEmpty
                    ? null
                    : () => Navigator.of(context).pop(selectedIds),
                icon: const Icon(Icons.check_rounded),
                label: Text(pickUiText(i18n, zh: '确认加入', en: 'Add')),
              ),
            ],
          );
        },
      );
    },
  );
}
