import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/module_system/module_system.dart';
import '../../i18n/app_i18n.dart';
import '../../state/app_state.dart';
import '../../state/app_state_provider.dart';
import '../module/module_access.dart';

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
        title: Text(
          i18n.t(
            'inline.ui.pages.module_management_page.module_management_e20d5f',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                i18n.t(
                  'inline.ui.pages.module_management_page.disabling_a_module_hides_its_entry_point_and_blocks_acce_d19c29',
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ModuleGroupCard(
            title: i18n.t(
              'inline.ui.pages.module_management_page.top_level_modules_9f4099',
            ),
            modules: topLevelModules,
            state: state,
            i18n: i18n,
          ),
          const SizedBox(height: 12),
          _ModuleGroupCard(
            title: i18n.t(
              'inline.ui.pages.module_management_page.toolbox_tools_6fde48',
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
      return i18n.t(
        'inline.ui.pages.module_management_page.this_module_cannot_be_enabled_while_its_parent_module_is_0a91f9',
      );
    }
    if (hiddenFromToolboxHome) {
      return i18n.t(
        'inline.ui.pages.module_management_page.hidden_from_the_toolbox_home_turn_the_switch_on_to_resto_d3e09a',
      );
    }
    return switch (moduleId) {
      ModuleIds.more => i18n.t(
        'inline.ui.pages.module_management_page.safety_entry_point_always_enabled_8f59b9',
      ),
      ModuleIds.toolbox => i18n.t(
        'inline.ui.pages.module_management_page.disabling_this_will_also_disable_all_toolbox_tools_65b92b',
      ),
      _ => i18n.t(
        ModuleIds.toolboxModules.contains(moduleId)
            ? 'moduleManagement.subtitle.toolboxModuleHidden'
            : 'moduleManagement.subtitle.moduleDisabled',
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
              i18n.t(
                'inline.ui.pages.module_management_page.restore_home_entry_691727',
              ),
            ),
          ),
        ],
      ],
    );
  }
}
