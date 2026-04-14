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
                  zh: '关闭模块后会隐藏入口并阻断模块访问。为保证系统可恢复，“更多”模块始终保持启用。',
                  en: 'Disabling a module hides its entry point and blocks access. The "More" module is always enabled so recovery settings remain reachable.',
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
            title: pickUiText(
              i18n,
              zh: 'Toolbox 子模块',
              en: 'Toolbox submodules',
            ),
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
    final canToggle = descriptor.canDisable && (parentEnabled || enabled);

    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      value: enabled,
      title: Text(_moduleTitle(i18n, descriptor.id)),
      subtitle: Text(
        _moduleSubtitle(i18n, descriptor.id, parentEnabled: parentEnabled),
      ),
      onChanged: canToggle
          ? (value) {
              state.setModuleEnabled(descriptor.id, value);
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
  }) {
    if (!parentEnabled) {
      return pickUiText(
        i18n,
        zh: '父模块关闭后不可单独启用。',
        en: 'This module cannot be enabled while its parent module is disabled.',
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
        zh: '关闭后，所有 Toolbox 子模块都会同步停用。',
        en: 'Disabling this will also disable all Toolbox submodules.',
      ),
      _ => pickUiText(
        i18n,
        zh: '关闭后隐藏入口并阻断访问。',
        en: 'Disabling hides entry points and blocks access.',
      ),
    };
  }
}
