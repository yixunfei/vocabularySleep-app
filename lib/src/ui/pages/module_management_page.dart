import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/module_system/module_system.dart';
import '../../i18n/app_i18n.dart';
import '../../state/app_state.dart';
import '../../state/app_state_provider.dart';
import '../module/module_access.dart';
import '../ui_copy.dart';

class ModuleManagementPage extends ConsumerWidget {
  const ModuleManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final i18n = AppI18n(state.uiLanguage);
    final guard = ModuleRuntimeGuard(state.moduleToggleState);
    final topLevelModules = ModuleRegistry.descriptorsByGroup(
      ModuleGroup.topLevel,
    );
    final toolboxModules =
        ModuleRegistry.descriptorsByGroup(ModuleGroup.toolbox)
            .where(
              (item) => guard.isEnabled(ModuleIds.toolbox) || item.canDisable,
            )
            .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(pickUiText(i18n, zh: '模块管理', en: 'Module management')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                pickUiText(
                  i18n,
                  zh: '关闭模块会隐藏入口并阻止访问；从工具箱首页移除入口只会隐藏首页卡片，可在这里恢复。“更多”会一直保留，方便你回到设置。',
                  en: 'Disabling a module hides its entry point and blocks access. Removing a Toolbox home entry only hides the card, and you can restore it here. More always stays available for settings access.',
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ModuleGroupCard(
            title: pickUiText(i18n, zh: '主导航模块', en: 'Top-level modules'),
            modules: topLevelModules,
            state: state,
            i18n: i18n,
          ),
          const SizedBox(height: 12),
          _ModuleGroupCard(
            title: pickUiText(i18n, zh: '工具箱工具', en: 'Toolbox tools'),
            modules: toolboxModules,
            state: state,
            i18n: i18n,
          ),
        ],
      ),
    );
  }
}

class _ModuleGroupCard extends StatelessWidget {
  const _ModuleGroupCard({
    required this.title,
    required this.modules,
    required this.state,
    required this.i18n,
  });

  final String title;
  final List<ModuleDescriptor> modules;
  final AppState state;
  final AppI18n i18n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            for (final descriptor in modules)
              _ModuleTile(descriptor: descriptor, state: state, i18n: i18n),
          ],
        ),
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.descriptor,
    required this.state,
    required this.i18n,
  });

  final ModuleDescriptor descriptor;
  final AppState state;
  final AppI18n i18n;

  @override
  Widget build(BuildContext context) {
    final enabled = state.moduleToggleState.isEnabled(descriptor.id);
    final parentId = descriptor.parentId;
    final parentEnabled = parentId == null || state.isModuleEnabled(parentId);
    final isToolboxEntry = ModuleIds.toolboxModules.contains(descriptor.id);
    final hiddenFromToolboxHome =
        isToolboxEntry && state.toolboxLayoutState.isHidden(descriptor.id);
    final switchValue = enabled && !hiddenFromToolboxHome;
    final canToggle = descriptor.canDisable && (parentEnabled || enabled);

    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      isThreeLine: hiddenFromToolboxHome,
      value: switchValue,
      title: Text(_moduleTitle(i18n, descriptor.id)),
      subtitle: _ModuleTileSubtitle(
        text: _moduleSubtitle(
          i18n,
          descriptor.id,
          parentEnabled: parentEnabled,
          hiddenFromToolboxHome: hiddenFromToolboxHome,
        ),
        showRestoreHomeEntry: hiddenFromToolboxHome,
        onRestoreHomeEntry: () => state.restoreToolboxEntry(descriptor.id),
        i18n: i18n,
      ),
      onChanged: canToggle
          ? (value) {
              if (isToolboxEntry) {
                if (value) {
                  state.setModuleEnabled(descriptor.id, true);
                  state.restoreToolboxEntry(descriptor.id);
                } else {
                  state.hideToolboxEntry(descriptor.id);
                }
              } else {
                state.setModuleEnabled(descriptor.id, value);
              }
            }
          : null,
    );
  }

  String _moduleTitle(AppI18n i18n, String moduleId) {
    return localizedModuleLabel(i18n, moduleId);
  }

  String _moduleSubtitle(
    AppI18n i18n,
    String moduleId, {
    required bool parentEnabled,
    required bool hiddenFromToolboxHome,
  }) {
    if (!parentEnabled) {
      return pickUiText(
        i18n,
        zh: '父模块关闭后不可单独启用。',
        en: 'This module cannot be enabled while its parent module is disabled.',
      );
    }
    if (hiddenFromToolboxHome) {
      return pickUiText(
        i18n,
        zh: '已从工具箱首页隐藏。打开开关即可恢复首页入口。',
        en: 'Hidden from the Toolbox home. Turn the switch on to restore the home entry.',
      );
    }
    return switch (moduleId) {
      ModuleIds.more => pickUiText(
        i18n,
        zh: '系统保底入口，始终启用。',
        en: 'Safety entry point. Always enabled.',
      ),
      ModuleIds.toolbox => pickUiText(
        i18n,
        zh: '关闭后，工具箱里的工具都会同步停用。',
        en: 'Disabling this will also disable all Toolbox tools.',
      ),
      _ => pickUiText(
        i18n,
        zh: ModuleIds.toolboxModules.contains(moduleId)
            ? '关闭后只会从工具箱首页隐藏，工具数据不会删除。'
            : '关闭后隐藏入口并阻断访问。',
        en: ModuleIds.toolboxModules.contains(moduleId)
            ? 'Turning this off hides it from the Toolbox home without deleting data.'
            : 'Disabling hides entry points and blocks access.',
      ),
    };
  }
}

class _ModuleTileSubtitle extends StatelessWidget {
  const _ModuleTileSubtitle({
    required this.text,
    required this.showRestoreHomeEntry,
    required this.onRestoreHomeEntry,
    required this.i18n,
  });

  final String text;
  final bool showRestoreHomeEntry;
  final VoidCallback onRestoreHomeEntry;
  final AppI18n i18n;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(text),
        if (showRestoreHomeEntry) ...<Widget>[
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: onRestoreHomeEntry,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              foregroundColor: colorScheme.primary,
            ),
            icon: const Icon(Icons.restore_rounded, size: 16),
            label: Text(
              pickUiText(i18n, zh: '恢复首页入口', en: 'Restore home entry'),
            ),
          ),
        ],
      ],
    );
  }
}
