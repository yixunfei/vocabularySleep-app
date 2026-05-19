import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/module_system/module_id.dart';
import '../../i18n/app_i18n.dart';
import '../../state/app_state.dart';
import '../../state/app_state_provider.dart';
import '../module/module_access.dart';
import '../ui_copy.dart';
import '../widgets/page_header.dart';
import 'toolbox/toolbox_page_content.dart';
import 'toolbox/toolbox_page_models.dart';
import 'toolbox/toolbox_page_widgets.dart';
import 'toolbox/toolbox_quick_entries.dart';
import 'toolbox/toolbox_ui_components.dart';
import 'toolbox/toolbox_ui_tokens.dart';

class ToolboxPage extends ConsumerStatefulWidget {
  const ToolboxPage({super.key});

  @override
  ConsumerState<ToolboxPage> createState() => _ToolboxPageState();
}

class _ToolboxPageState extends ConsumerState<ToolboxPage> {
  bool _editing = false;
  bool _layoutDragActive = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final i18n = AppI18n(state.uiLanguage);
    if (!state.isModuleEnabled(ModuleIds.toolbox)) {
      return ModuleDisabledView(i18n: i18n, moduleId: ModuleIds.toolbox);
    }

    final allSections = buildAllToolboxSections(i18n);
    bool isEnabled(String moduleId) => state.isModuleEnabled(moduleId);
    final visibleEntries = orderedToolboxEntries(
      allSections,
      layoutState: state.toolboxLayoutState,
      isModuleEnabled: isEnabled,
    );
    final allEnabledEntries = orderedToolboxEntries(
      allSections,
      layoutState: state.toolboxLayoutState,
      isModuleEnabled: isEnabled,
      includeHidden: true,
    );
    final hiddenEntries = allEnabledEntries
        .where((entry) => state.toolboxLayoutState.isHidden(entry.moduleId))
        .toList(growable: false);
    final homeSection = ToolboxSectionData(
      title: pickUiText(i18n, zh: '我的工具箱', en: 'My toolbox'),
      subtitle: pickUiText(
        i18n,
        zh: '你常用的工具会按自己的顺序显示在这里。',
        en: 'Your tools appear here in the order you choose.',
      ),
      entries: visibleEntries,
    );
    final quickEntries = quickToolboxEntries(
      allSections,
      layoutState: state.toolboxLayoutState,
      isModuleEnabled: isEnabled,
    );

    if (_editing) {
      return _buildEditingView(
        context: context,
        i18n: i18n,
        state: state,
        visibleEntries: visibleEntries,
        hiddenEntries: hiddenEntries,
        quickEntries: quickEntries,
      );
    }

    return _buildHomeView(
      i18n: i18n,
      state: state,
      homeSection: homeSection,
      visibleEntries: visibleEntries,
      hiddenEntries: hiddenEntries,
      quickEntries: quickEntries,
    );
  }

  Widget _buildHomeView({
    required AppI18n i18n,
    required AppState state,
    required ToolboxSectionData homeSection,
    required List<ToolboxEntryData> visibleEntries,
    required List<ToolboxEntryData> hiddenEntries,
    required List<ToolboxEntryData> quickEntries,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        ToolboxUiTokens.pageHorizontalPadding,
        ToolboxUiTokens.pageTopPadding,
        ToolboxUiTokens.pageHorizontalPadding,
        ToolboxUiTokens.pageBottomPadding,
      ),
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: ToolboxUiTokens.contentMaxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildHeader(i18n),
                const SizedBox(height: 18),
                _buildIntroPanel(i18n),
                const SizedBox(height: ToolboxUiTokens.sectionSpacing),
                ToolboxQuickEntryPanel(
                  i18n: i18n,
                  state: state,
                  quickEntries: quickEntries,
                  availableEntries: visibleEntries,
                ),
                const SizedBox(height: ToolboxUiTokens.sectionSpacing),
                if (visibleEntries.isEmpty)
                  _EmptyToolboxLayoutPanel(
                    i18n: i18n,
                    hiddenEntries: hiddenEntries,
                    onEdit: _enterEditMode,
                  )
                else
                  ToolboxSection(
                    section: homeSection,
                    enableQuickDrag: true,
                    onEntryLongPress: (_) => _enterEditMode(),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditingView({
    required BuildContext context,
    required AppI18n i18n,
    required AppState state,
    required List<ToolboxEntryData> visibleEntries,
    required List<ToolboxEntryData> hiddenEntries,
    required List<ToolboxEntryData> quickEntries,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(
        ToolboxUiTokens.pageHorizontalPadding,
        ToolboxUiTokens.pageTopPadding,
        ToolboxUiTokens.pageHorizontalPadding,
        ToolboxUiTokens.pageBottomPadding,
      ),
      buildDefaultDragHandles: false,
      onReorderStart: (_) => _setLayoutDragActive(true),
      onReorderEnd: (_) => _setLayoutDragActive(false),
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final value = Curves.easeOutCubic.transform(animation.value);
            return Transform.translate(
              offset: Offset(0, -4 * value),
              child: Transform.scale(
                scale: 1 + value * 0.03,
                child: Material(
                  color: Colors.transparent,
                  elevation: 2 + value * 8,
                  shadowColor: colorScheme.primary.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(
                    ToolboxUiTokens.cardRadius,
                  ),
                  child: child,
                ),
              ),
            );
          },
          child: child,
        );
      },
      header: _ToolboxPageWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildHeader(i18n),
            const SizedBox(height: 18),
            _buildIntroPanel(i18n),
            const SizedBox(height: ToolboxUiTokens.sectionSpacing),
            ToolboxQuickEntryPanel(
              i18n: i18n,
              state: state,
              quickEntries: quickEntries,
              availableEntries: visibleEntries,
            ),
            const SizedBox(height: ToolboxUiTokens.sectionSpacing),
            _ToolboxLayoutSummaryCard(
              i18n: i18n,
              visibleEntries: visibleEntries,
              hiddenEntries: hiddenEntries,
            ),
            if (visibleEntries.isEmpty) ...<Widget>[
              const SizedBox(height: 12),
              _EmptyToolboxLayoutPanel(
                i18n: i18n,
                hiddenEntries: hiddenEntries,
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
      footer: _ToolboxPageWidth(
        child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: _ToolboxLayoutActions(
            i18n: i18n,
            state: state,
            hiddenEntries: hiddenEntries,
            dragActive: _layoutDragActive,
            onExit: _exitEditMode,
          ),
        ),
      ),
      itemCount: visibleEntries.length,
      onReorder: (oldIndex, newIndex) {
        final nextEntries = List<ToolboxEntryData>.from(visibleEntries);
        if (newIndex > oldIndex) {
          newIndex -= 1;
        }
        final moved = nextEntries.removeAt(oldIndex);
        nextEntries.insert(newIndex, moved);
        state.setToolboxEntryOrder(
          nextEntries.map((entry) => entry.moduleId).toList(growable: false),
        );
      },
      itemBuilder: (context, index) {
        final entry = visibleEntries[index];
        return _ToolboxPageWidth(
          key: ValueKey<String>('toolbox_layout_${entry.moduleId}'),
          child: Padding(
            padding: const EdgeInsets.only(bottom: ToolboxUiTokens.cardSpacing),
            child: _ToolboxQuickEntryDragWrapper(
              entry: entry,
              child: ToolboxEntryCard(
                entry: entry,
                editing: true,
                dragTooltip: pickUiText(
                  i18n,
                  zh: '拖动手柄排序',
                  en: 'Drag the handle to reorder',
                ),
                removeTooltip: pickUiText(
                  i18n,
                  zh: '从首页移除',
                  en: 'Remove from home',
                ),
                onRemove: () =>
                    _confirmRemoveEntry(context, i18n, state, entry),
                dragHandle: ReorderableDragStartListener(
                  index: index,
                  child: Icon(
                    Icons.drag_handle_rounded,
                    color: entry.accent,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(AppI18n i18n) {
    return PageHeader(
      eyebrow: pageLabelToolbox(i18n),
      title: pickUiText(i18n, zh: '多功能工具箱', en: 'Multi-tool toolbox'),
      subtitle: pickUiText(
        i18n,
        zh: '声音、专注、放松、决策和趣味测试都放在一个地方，需要时直接打开。',
        en: 'Sound, focus, calming tools, choices, and small tests are all in one place.',
      ),
      action: _ToolboxEditToggle(
        i18n: i18n,
        editing: _editing,
        onTap: () {
          setState(() {
            _editing = !_editing;
            _layoutDragActive = false;
          });
        },
      ),
    );
  }

  Widget _buildIntroPanel(AppI18n i18n) {
    return ToolboxIntroPanel(
      title: pickUiText(
        i18n,
        zh: _editing ? '正在编辑工具箱首页' : '常用工具随手打开',
        en: _editing ? 'Editing your Toolbox home' : 'Tools ready when needed',
      ),
      subtitle: pickUiText(
        i18n,
        zh: _editing
            ? '拖动手柄调整顺序。长按卡片可拖到快速入口，移除前会再次确认。'
            : '长按任意工具卡片可调整顺序，常用工具也可以放进快速入口。',
        en: _editing
            ? 'Drag handles to reorder. Long-press a card to add it to shortcuts; removing asks first.'
            : 'Long-press any tool card to rearrange it, or keep favorites in shortcuts.',
      ),
      highlights: <String>[
        pickUiText(i18n, zh: '长按编辑', en: 'Long press'),
        pickUiText(i18n, zh: '拖动排序', en: 'Drag to order'),
        pickUiText(i18n, zh: '快速入口', en: 'Shortcuts'),
        pickUiText(i18n, zh: '可恢复', en: 'Restorable'),
      ],
    );
  }

  void _enterEditMode() {
    setState(() {
      _editing = true;
      _layoutDragActive = false;
    });
  }

  void _exitEditMode() {
    setState(() {
      _editing = false;
      _layoutDragActive = false;
    });
  }

  void _setLayoutDragActive(bool value) {
    if (_layoutDragActive == value) {
      return;
    }
    setState(() {
      _layoutDragActive = value;
    });
  }

  Future<void> _confirmRemoveEntry(
    BuildContext context,
    AppI18n i18n,
    AppState state,
    ToolboxEntryData entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            pickUiText(
              i18n,
              zh: '从首页移除 ${entry.title}？',
              en: 'Remove ${entry.title} from home?',
            ),
          ),
          content: Text(
            pickUiText(
              i18n,
              zh: '这只会隐藏工具箱首页入口，不会关闭工具。之后可在“恢复隐藏入口”或设置里的“模块管理”中重新显示。',
              en: 'This only hides the Toolbox home entry. The tool stays enabled, and you can restore it from Restore entries or module management.',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(pickUiText(i18n, zh: '取消', en: 'Cancel')),
            ),
            FilledButton.tonalIcon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.visibility_off_rounded),
              label: Text(pickUiText(i18n, zh: '移除', en: 'Remove')),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(context);
    state.hideToolboxEntry(entry.moduleId);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        dismissDirection: DismissDirection.horizontal,
        behavior: SnackBarBehavior.floating,
        showCloseIcon: true,
        content: Text(
          pickUiText(
            i18n,
            zh: '${entry.title} 已从首页隐藏，可随时恢复。',
            en: '${entry.title} is hidden from home and can be restored anytime.',
          ),
        ),
        action: SnackBarAction(
          label: pickUiText(i18n, zh: '恢复', en: 'Restore'),
          onPressed: () => state.restoreToolboxEntry(entry.moduleId),
        ),
      ),
    );
  }
}

class _ToolboxQuickEntryDragWrapper extends StatelessWidget {
  const _ToolboxQuickEntryDragWrapper({
    required this.entry,
    required this.child,
  });

  final ToolboxEntryData entry;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<ToolboxEntryData>(
      key: ValueKey<String>('toolbox_edit_quick_draggable_${entry.moduleId}'),
      data: entry,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width - 32,
          child: Opacity(opacity: 0.94, child: child),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.55, child: child),
      child: child,
    );
  }
}

class _ToolboxEditToggle extends StatelessWidget {
  const _ToolboxEditToggle({
    required this.i18n,
    required this.editing,
    required this.onTap,
  });

  final AppI18n i18n;
  final bool editing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ToolboxSelectablePill(
      selected: editing,
      tint: colorScheme.primary,
      onTap: onTap,
      tooltip: pickUiText(
        i18n,
        zh: editing ? '完成编辑' : '编辑工具箱布局',
        en: editing ? 'Exit edit mode' : 'Edit toolbox layout',
      ),
      leading: Icon(
        editing ? Icons.close_rounded : Icons.dashboard_customize_rounded,
        size: 18,
      ),
      label: Text(
        pickUiText(
          i18n,
          zh: editing ? '完成' : '编辑布局',
          en: editing ? 'Exit' : 'Edit layout',
        ),
      ),
    );
  }
}

class _ToolboxPageWidth extends StatelessWidget {
  const _ToolboxPageWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: ToolboxUiTokens.contentMaxWidth,
        ),
        child: child,
      ),
    );
  }
}

class _ToolboxLayoutSummaryCard extends StatelessWidget {
  const _ToolboxLayoutSummaryCard({
    required this.i18n,
    required this.visibleEntries,
    required this.hiddenEntries,
  });

  final AppI18n i18n;
  final List<ToolboxEntryData> visibleEntries;
  final List<ToolboxEntryData> hiddenEntries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ToolboxSurfaceCard(
      padding: const EdgeInsets.all(16),
      radius: ToolboxUiTokens.sectionPanelRadius,
      color: colorScheme.surfaceContainerLowest,
      borderColor: colorScheme.outlineVariant.withValues(alpha: 0.78),
      shadowOpacity: 0.05,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.16),
                  ),
                ),
                child: Icon(Icons.tune_rounded, color: colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  pickUiText(i18n, zh: '编辑首页入口', en: 'Edit home entries'),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _ToolboxLayoutStatusChip(
                icon: Icons.visibility_rounded,
                label: pickUiText(i18n, zh: '显示', en: 'Visible'),
                value: '${visibleEntries.length}',
                tint: colorScheme.primary,
              ),
              _ToolboxLayoutStatusChip(
                icon: Icons.visibility_off_rounded,
                label: pickUiText(i18n, zh: '隐藏', en: 'Hidden'),
                value: '${hiddenEntries.length}',
                tint: hiddenEntries.isEmpty
                    ? colorScheme.outline
                    : colorScheme.tertiary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            pickUiText(
              i18n,
              zh: '拖动右侧手柄可调整顺序。长按卡片拖到快速入口可加入常用工具；点减号会先确认。',
              en: 'Drag the handle to reorder. Long-press a card and drop it on shortcuts to add it; the minus button asks first.',
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolboxLayoutActions extends StatelessWidget {
  const _ToolboxLayoutActions({
    required this.i18n,
    required this.state,
    required this.hiddenEntries,
    required this.dragActive,
    required this.onExit,
  });

  final AppI18n i18n;
  final AppState state;
  final List<ToolboxEntryData> hiddenEntries;
  final bool dragActive;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        FilledButton.icon(
          onPressed: dragActive ? null : onExit,
          icon: const Icon(Icons.close_rounded),
          label: Text(pickUiText(i18n, zh: '退出编辑', en: 'Exit edit')),
        ),
        OutlinedButton.icon(
          key: const ValueKey<String>('toolbox_restore_entries_button'),
          onPressed: hiddenEntries.isEmpty
              ? null
              : () => _showRestoreSheet(context, i18n, state, hiddenEntries),
          icon: const Icon(Icons.add_circle_outline_rounded),
          label: Text(pickUiText(i18n, zh: '恢复隐藏入口', en: 'Restore entries')),
        ),
        TextButton.icon(
          onPressed: () => state.resetToolboxLayout(),
          icon: const Icon(Icons.restart_alt_rounded),
          label: Text(pickUiText(i18n, zh: '重置默认', en: 'Reset default')),
        ),
      ],
    );
  }
}

class _ToolboxLayoutStatusChip extends StatelessWidget {
  const _ToolboxLayoutStatusChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Semantics(
      label: '$label $value',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(ToolboxUiTokens.pillRadius),
          border: Border.all(color: tint.withValues(alpha: 0.22)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 16, color: tint),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                value,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: tint,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyToolboxLayoutPanel extends StatelessWidget {
  const _EmptyToolboxLayoutPanel({
    required this.i18n,
    required this.hiddenEntries,
    this.onEdit,
  });

  final AppI18n i18n;
  final List<ToolboxEntryData> hiddenEntries;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ToolboxSurfaceCard(
      color: colorScheme.surfaceContainerLowest,
      borderColor: colorScheme.outlineVariant,
      shadowOpacity: 0.04,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.58),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.inventory_2_outlined, color: colorScheme.primary),
          ),
          const SizedBox(height: 12),
          Text(
            pickUiText(
              i18n,
              zh: '首页暂时没有可显示的工具',
              en: 'No visible tools on this page',
            ),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            pickUiText(
              i18n,
              zh: hiddenEntries.isEmpty
                  ? '可以到模块管理中重新启用工具箱里的工具。'
                  : '进入编辑模式后可恢复已隐藏的工具入口。',
              en: hiddenEntries.isEmpty
                  ? 'Re-enable Toolbox tools from module management.'
                  : 'Enter edit mode to restore hidden tool entries.',
            ),
          ),
          if (hiddenEntries.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            ToolboxInfoPill(
              text: pickUiText(
                i18n,
                zh: '已隐藏 ${hiddenEntries.length} 个首页入口',
                en: '${hiddenEntries.length} home entries hidden',
              ),
              accent: colorScheme.tertiary,
              backgroundColor: colorScheme.tertiaryContainer.withValues(
                alpha: 0.36,
              ),
              textColor: colorScheme.onSurface,
            ),
          ],
          if (onEdit != null) ...<Widget>[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.dashboard_customize_rounded),
              label: Text(pickUiText(i18n, zh: '编辑布局', en: 'Edit layout')),
            ),
          ],
        ],
      ),
    );
  }
}

void _showRestoreSheet(
  BuildContext context,
  AppI18n i18n,
  AppState state,
  List<ToolboxEntryData> hiddenEntries,
) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final theme = Theme.of(context);
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          children: <Widget>[
            Text(
              pickUiText(i18n, zh: '恢复隐藏入口', en: 'Restore hidden entries'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            ToolboxSurfaceCard(
              padding: const EdgeInsets.all(12),
              radius: ToolboxUiTokens.cardRadius,
              color: theme.colorScheme.surfaceContainerLow,
              borderColor: theme.colorScheme.outlineVariant,
              shadowOpacity: 0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      pickUiText(
                        i18n,
                        zh: '恢复后入口会回到工具箱首页；工具是否启用仍在模块管理中控制。',
                        en: 'Restored entries return to the Toolbox home. Whether a tool is enabled is still controlled in module management.',
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (final entry in hiddenEntries)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ToolboxSurfaceCard(
                  padding: EdgeInsets.zero,
                  radius: ToolboxUiTokens.cardRadius,
                  color: theme.colorScheme.surfaceContainerLowest,
                  borderColor: entry.accent.withValues(alpha: 0.2),
                  shadowColor: entry.accent,
                  shadowOpacity: 0.04,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: entry.accent.withValues(alpha: 0.16),
                      foregroundColor: entry.accent,
                      child: Icon(entry.icon),
                    ),
                    title: Text(entry.title),
                    subtitle: Text(entry.subtitle),
                    trailing: FilledButton.tonalIcon(
                      onPressed: () {
                        state.restoreToolboxEntry(entry.moduleId);
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: Text(pickUiText(i18n, zh: '恢复', en: 'Restore')),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}
