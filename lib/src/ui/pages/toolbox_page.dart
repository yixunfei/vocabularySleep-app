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
import 'toolbox/toolbox_ui_components.dart';
import 'toolbox/toolbox_ui_tokens.dart';

class ToolboxPage extends ConsumerStatefulWidget {
  const ToolboxPage({super.key});

  @override
  ConsumerState<ToolboxPage> createState() => _ToolboxPageState();
}

class _ToolboxPageState extends ConsumerState<ToolboxPage> {
  bool _editing = false;

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
    final hiddenEntries =
        orderedToolboxEntries(
              allSections,
              layoutState: state.toolboxLayoutState,
              isModuleEnabled: isEnabled,
              includeHidden: true,
            )
            .where((entry) => state.toolboxLayoutState.isHidden(entry.moduleId))
            .toList(growable: false);
    final homeSection = ToolboxSectionData(
      title: pickUiText(i18n, zh: '我的工具箱', en: 'My toolbox'),
      subtitle: pickUiText(
        i18n,
        zh: '按你的自定义顺序展示。长按任意卡片可调整位置或移除首页入口。',
        en: 'Shown in your custom order. Long-press any card to reorder or hide it from the home page.',
      ),
      entries: visibleEntries,
    );

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
                PageHeader(
                  eyebrow: pageLabelToolbox(i18n),
                  title: pickUiText(
                    i18n,
                    zh: '多功能工具箱',
                    en: 'Multi-tool toolbox',
                  ),
                  subtitle: pickUiText(
                    i18n,
                    zh: '把声音、专注、放松、决策和趣味测试整理成一套适合移动端使用的本地工具集。',
                    en: 'A calmer, clearer local toolbox for sound, focus, decompression, and small everyday rituals.',
                  ),
                  action: _ToolboxEditToggle(
                    i18n: i18n,
                    editing: _editing,
                    onTap: () {
                      setState(() {
                        _editing = !_editing;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 18),
                ToolboxIntroPanel(
                  title: pickUiText(
                    i18n,
                    zh: _editing ? '正在编辑工具箱首页' : '入口已按使用场景整理',
                    en: _editing
                        ? 'Toolbox home is in edit mode'
                        : 'The toolbox is regrouped by use case',
                  ),
                  subtitle: pickUiText(
                    i18n,
                    zh: _editing
                        ? '拖动卡片调整顺序，点减号可从首页移除。移除只影响工具箱首页，不会关闭模块本身。'
                        : '长按任意工具卡片即可进入编辑模式，自定义排序、隐藏不常用入口或恢复默认布局。',
                    en: _editing
                        ? 'Drag cards to reorder them. Remove only hides an entry from this page and does not disable the module.'
                        : 'Long-press any tool card to edit the home layout, hide less-used entries, or restore the default arrangement.',
                  ),
                  highlights: <String>[
                    pickUiText(i18n, zh: '长按编辑', en: 'Long press'),
                    pickUiText(i18n, zh: '拖拽排序', en: 'Drag reorder'),
                    pickUiText(i18n, zh: '首页隐藏', en: 'Hide entries'),
                    pickUiText(i18n, zh: '随时恢复', en: 'Restore'),
                  ],
                ),
                const SizedBox(height: ToolboxUiTokens.sectionSpacing),
                if (_editing)
                  _ToolboxLayoutEditor(
                    i18n: i18n,
                    state: state,
                    visibleEntries: visibleEntries,
                    hiddenEntries: hiddenEntries,
                    onExit: () {
                      setState(() {
                        _editing = false;
                      });
                    },
                  )
                else ...<Widget>[
                  if (visibleEntries.isEmpty)
                    _EmptyToolboxLayoutPanel(
                      i18n: i18n,
                      hiddenEntries: hiddenEntries,
                      onEdit: () {
                        setState(() {
                          _editing = true;
                        });
                      },
                    )
                  else
                    ToolboxSection(
                      section: homeSection,
                      onEntryLongPress: (_) {
                        setState(() {
                          _editing = true;
                        });
                      },
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
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
        en: editing ? 'Done editing' : 'Edit toolbox layout',
      ),
      leading: Icon(
        editing ? Icons.check_rounded : Icons.dashboard_customize_rounded,
        size: 18,
      ),
      label: Text(
        pickUiText(
          i18n,
          zh: editing ? '完成' : '编辑布局',
          en: editing ? 'Done' : 'Edit layout',
        ),
      ),
    );
  }
}

class _ToolboxLayoutEditor extends StatelessWidget {
  const _ToolboxLayoutEditor({
    required this.i18n,
    required this.state,
    required this.visibleEntries,
    required this.hiddenEntries,
    required this.onExit,
  });

  final AppI18n i18n;
  final AppState state;
  final List<ToolboxEntryData> visibleEntries;
  final List<ToolboxEntryData> hiddenEntries;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ToolboxSurfaceCard(
          padding: const EdgeInsets.all(14),
          radius: ToolboxUiTokens.sectionPanelRadius,
          color: colorScheme.surfaceContainerLowest,
          borderColor: colorScheme.outlineVariant.withValues(alpha: 0.78),
          shadowOpacity: 0.05,
          child: Row(
            children: <Widget>[
              Icon(Icons.tune_rounded, color: colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _layoutCountText(
                    i18n,
                    visibleEntries.length,
                    hiddenEntries.length,
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (visibleEntries.isEmpty)
          _EmptyToolboxLayoutPanel(i18n: i18n, hiddenEntries: hiddenEntries)
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  final elevation = 2 + animation.value * 8;
                  return Material(
                    color: Colors.transparent,
                    elevation: elevation,
                    borderRadius: BorderRadius.circular(
                      ToolboxUiTokens.cardRadius,
                    ),
                    child: child,
                  );
                },
                child: child,
              );
            },
            itemCount: visibleEntries.length,
            onReorder: (oldIndex, newIndex) {
              final nextEntries = List<ToolboxEntryData>.from(visibleEntries);
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }
              final moved = nextEntries.removeAt(oldIndex);
              nextEntries.insert(newIndex, moved);
              state.setToolboxEntryOrder(
                nextEntries.map((entry) => entry.moduleId).toList(),
              );
            },
            itemBuilder: (context, index) {
              final entry = visibleEntries[index];
              return Padding(
                key: ValueKey<String>('toolbox_layout_${entry.moduleId}'),
                padding: const EdgeInsets.only(
                  bottom: ToolboxUiTokens.cardSpacing,
                ),
                child: ToolboxEntryCard(
                  entry: entry,
                  editing: true,
                  dragTooltip: pickUiText(
                    i18n,
                    zh: '拖动排序',
                    en: 'Drag to reorder',
                  ),
                  removeTooltip: pickUiText(
                    i18n,
                    zh: '从首页移除',
                    en: 'Remove from home',
                  ),
                  onRemove: () => state.hideToolboxEntry(entry.moduleId),
                  dragHandle: ReorderableDragStartListener(
                    index: index,
                    child: Icon(
                      Icons.drag_handle_rounded,
                      color: entry.accent,
                      size: 26,
                    ),
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            FilledButton.icon(
              onPressed: onExit,
              icon: const Icon(Icons.check_rounded),
              label: Text(pickUiText(i18n, zh: '完成编辑', en: 'Done')),
            ),
            OutlinedButton.icon(
              key: const ValueKey<String>('toolbox_restore_entries_button'),
              onPressed: hiddenEntries.isEmpty
                  ? null
                  : () =>
                        _showRestoreSheet(context, i18n, state, hiddenEntries),
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: Text(
                pickUiText(i18n, zh: '恢复隐藏入口', en: 'Restore entries'),
              ),
            ),
            TextButton.icon(
              onPressed: () => state.resetToolboxLayout(),
              icon: const Icon(Icons.restart_alt_rounded),
              label: Text(pickUiText(i18n, zh: '重置默认', en: 'Reset default')),
            ),
          ],
        ),
      ],
    );
  }
}

String _layoutCountText(AppI18n i18n, int visibleCount, int hiddenCount) {
  return pickUiText(
    i18n,
    zh: '当前显示 $visibleCount 个入口，已隐藏 $hiddenCount 个。',
    en: '$visibleCount entries visible, $hiddenCount hidden.',
  );
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
                  ? '可以到模块管理中重新启用工具箱子模块。'
                  : '进入编辑模式后可恢复已隐藏的工具入口。',
              en: hiddenEntries.isEmpty
                  ? 'Re-enable Toolbox submodules from module management.'
                  : 'Enter edit mode to restore hidden tool entries.',
            ),
          ),
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
            Text(
              pickUiText(
                i18n,
                zh: '恢复后入口会回到工具箱首页，模块启停状态不会改变。',
                en: 'Restored entries return to the Toolbox home without changing module enablement.',
              ),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            for (final entry in hiddenEntries)
              ListTile(
                contentPadding: EdgeInsets.zero,
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
          ],
        ),
      );
    },
  );
}
