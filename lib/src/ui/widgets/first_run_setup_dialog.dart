import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/module_system/module_id.dart';
import '../../i18n/app_i18n.dart';
import '../../models/play_config.dart';
import '../../services/settings_service.dart';
import '../../state/app_state.dart';
import '../../state/app_state_provider.dart';

class FirstRunSetupDialog extends ConsumerStatefulWidget {
  const FirstRunSetupDialog({super.key});

  @override
  ConsumerState<FirstRunSetupDialog> createState() =>
      _FirstRunSetupDialogState();
}

class _FirstRunSetupDialogState extends ConsumerState<FirstRunSetupDialog> {
  static const String _scenarioAll = 'all';
  static const String _scenarioWorkFocus = 'work_focus';
  static const String _scenarioUtilities = 'utilities';
  static const String _scenarioSecurity = 'security';
  static const String _scenarioLearning = 'learning';
  static const String _scenarioFun = 'fun';

  String _languageSelection = SettingsService.uiLanguageSystem;
  String _theme = AppearanceConfig.defaults.theme;
  Set<String> _selectedScenarios = const <String>{_scenarioAll};
  bool _didLoadInitialValues = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    if (!_didLoadInitialValues) {
      _languageSelection = state.uiLanguageSelection;
      _theme = state.config.appearance.normalizedTheme;
      _didLoadInitialValues = true;
    }
    final previewLanguage =
        _languageSelection == SettingsService.uiLanguageSystem
        ? state.uiLanguage
        : _languageSelection;
    final i18n = AppI18n(previewLanguage);

    return PopScope(
      canPop: false,
      child: AlertDialog(
        key: const ValueKey<String>('first-run-setup-dialog'),
        title: Text(i18n.t('onboarding.first_run.title')),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  i18n.t('onboarding.first_run.subtitle'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                _buildBasicSection(i18n),
                const SizedBox(height: 16),
                _buildPermissionsSection(i18n),
                const SizedBox(height: 16),
                _buildPrivacySection(i18n),
                const SizedBox(height: 16),
                _buildScenarioSection(i18n),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          FilledButton.icon(
            onPressed: () => _complete(state),
            icon: const Icon(Icons.check_rounded),
            label: Text(i18n.t('onboarding.first_run.start_button')),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicSection(AppI18n i18n) {
    return _FirstRunSection(
      icon: Icons.tune_rounded,
      title: i18n.t('onboarding.first_run.basic_title'),
      subtitle: i18n.t('onboarding.first_run.basic_subtitle'),
      child: Column(
        children: <Widget>[
          DropdownButtonFormField<String>(
            initialValue: _languageSelection,
            isExpanded: true,
            decoration: InputDecoration(labelText: i18n.t('language')),
            items: <DropdownMenuItem<String>>[
              DropdownMenuItem<String>(
                value: SettingsService.uiLanguageSystem,
                child: Text(i18n.t('onboarding.first_run.language_system')),
              ),
              ...AppI18n.supportedLanguages.map(
                (code) => DropdownMenuItem<String>(
                  value: code,
                  child: Text(i18n.languageName(code)),
                ),
              ),
            ],
            onChanged: (value) {
              if (value == null || value.trim().isEmpty) return;
              setState(() {
                _languageSelection = value;
              });
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _theme,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: i18n.t('appearanceThemeTitle'),
            ),
            items: AppearanceConfig.supportedThemes
                .map(
                  (value) => DropdownMenuItem<String>(
                    value: value,
                    child: Text(_themeLabel(i18n, value)),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value == null || value.trim().isEmpty) return;
              setState(() {
                _theme = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsSection(AppI18n i18n) {
    return _FirstRunSection(
      icon: Icons.privacy_tip_outlined,
      title: i18n.t('onboarding.first_run.permissions_title'),
      subtitle: i18n.t('onboarding.first_run.permissions_subtitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _FirstRunPermissionTile(
            icon: Icons.check_circle_outline_rounded,
            title: i18n.t(
              'onboarding.first_run.permissions_required_none_title',
            ),
            description: i18n.t(
              'onboarding.first_run.permissions_required_none_body',
            ),
            badge: i18n.t('onboarding.first_run.permissions_required_badge'),
          ),
          const SizedBox(height: 8),
          _FirstRunPermissionTile(
            icon: Icons.mic_none_rounded,
            title: i18n.t('onboarding.first_run.permission_microphone_title'),
            description: i18n.t(
              'onboarding.first_run.permission_microphone_body',
            ),
            badge: i18n.t('onboarding.first_run.permissions_optional_badge'),
          ),
          _FirstRunPermissionTile(
            icon: Icons.record_voice_over_outlined,
            title: i18n.t('onboarding.first_run.permission_speech_title'),
            description: i18n.t('onboarding.first_run.permission_speech_body'),
            badge: i18n.t('onboarding.first_run.permissions_optional_badge'),
          ),
          _FirstRunPermissionTile(
            icon: Icons.camera_alt_outlined,
            title: i18n.t('onboarding.first_run.permission_camera_title'),
            description: i18n.t('onboarding.first_run.permission_camera_body'),
            badge: i18n.t('onboarding.first_run.permissions_optional_badge'),
          ),
          _FirstRunPermissionTile(
            icon: Icons.place_outlined,
            title: i18n.t('onboarding.first_run.permission_location_title'),
            description: i18n.t(
              'onboarding.first_run.permission_location_body',
            ),
            badge: i18n.t('onboarding.first_run.permissions_optional_badge'),
          ),
          _FirstRunPermissionTile(
            icon: Icons.event_available_outlined,
            title: i18n.t('onboarding.first_run.permission_calendar_title'),
            description: i18n.t(
              'onboarding.first_run.permission_calendar_body',
            ),
            badge: i18n.t('onboarding.first_run.permissions_optional_badge'),
          ),
          _FirstRunPermissionTile(
            icon: Icons.notifications_none_rounded,
            title: i18n.t('onboarding.first_run.permission_reminders_title'),
            description: i18n.t(
              'onboarding.first_run.permission_reminders_body',
            ),
            badge: i18n.t('onboarding.first_run.permissions_optional_badge'),
          ),
          _FirstRunPermissionTile(
            icon: Icons.folder_open_rounded,
            title: i18n.t('onboarding.first_run.permission_files_title'),
            description: i18n.t('onboarding.first_run.permission_files_body'),
            badge: i18n.t('onboarding.first_run.permissions_optional_badge'),
          ),
          _FirstRunPermissionTile(
            icon: Icons.wifi_tethering_outlined,
            title: i18n.t('onboarding.first_run.permission_network_title'),
            description: i18n.t('onboarding.first_run.permission_network_body'),
            badge: i18n.t('onboarding.first_run.permissions_optional_badge'),
          ),
          _FirstRunPermissionTile(
            icon: Icons.volume_up_outlined,
            title: i18n.t('onboarding.first_run.permission_audio_title'),
            description: i18n.t('onboarding.first_run.permission_audio_body'),
            badge: i18n.t('onboarding.first_run.permissions_optional_badge'),
          ),
          _FirstRunPermissionTile(
            icon: Icons.wallpaper_outlined,
            title: i18n.t('onboarding.first_run.permission_wallpaper_title'),
            description: i18n.t(
              'onboarding.first_run.permission_wallpaper_body',
            ),
            badge: i18n.t('onboarding.first_run.permissions_optional_badge'),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection(AppI18n i18n) {
    return _FirstRunSection(
      icon: Icons.lock_outline_rounded,
      title: i18n.t('onboarding.first_run.privacy_title'),
      subtitle: i18n.t('onboarding.first_run.privacy_subtitle'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(i18n.t('onboarding.first_run.privacy_local_body')),
          const SizedBox(height: 8),
          Text(i18n.t('onboarding.first_run.privacy_online_body')),
        ],
      ),
    );
  }

  Widget _buildScenarioSection(AppI18n i18n) {
    return _FirstRunSection(
      icon: Icons.dashboard_customize_outlined,
      title: i18n.t('onboarding.first_run.scenarios_title'),
      subtitle: i18n.t('onboarding.first_run.scenarios_subtitle'),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _scenarioIds
            .map(
              (id) => FilterChip(
                selected: _selectedScenarios.contains(id),
                avatar: Icon(_scenarioIcon(id), size: 18),
                label: Text(_scenarioLabel(i18n, id)),
                onSelected: (selected) => _toggleScenario(id, selected),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  List<String> get _scenarioIds => const <String>[
    _scenarioAll,
    _scenarioWorkFocus,
    _scenarioUtilities,
    _scenarioSecurity,
    _scenarioLearning,
    _scenarioFun,
  ];

  void _toggleScenario(String id, bool selected) {
    setState(() {
      if (id == _scenarioAll) {
        _selectedScenarios = const <String>{_scenarioAll};
        return;
      }
      final next = <String>{..._selectedScenarios}..remove(_scenarioAll);
      if (selected) {
        next.add(id);
      } else {
        next.remove(id);
      }
      _selectedScenarios = next.isEmpty ? const <String>{_scenarioAll} : next;
    });
  }

  void _complete(AppState state) {
    state.completeFirstRunSetup(
      languageSelection: _languageSelection,
      theme: _theme,
      enabledModuleIds: _enabledModuleIds(),
    );
    Navigator.of(context).pop();
  }

  Set<String> _enabledModuleIds() {
    if (_selectedScenarios.contains(_scenarioAll)) {
      return ModuleIds.allModules.toSet();
    }

    final ids = <String>{ModuleIds.more};
    for (final scenario in _selectedScenarios) {
      ids.addAll(_moduleIdsForScenario(scenario));
    }
    return ids.isEmpty ? ModuleIds.allModules.toSet() : ids;
  }

  Set<String> _moduleIdsForScenario(String scenario) {
    return switch (scenario) {
      _scenarioWorkFocus => <String>{
        ModuleIds.focus,
        ModuleIds.toolbox,
        ModuleIds.toolboxFocusBeats,
        ModuleIds.toolboxSoothingMusic,
        ModuleIds.toolboxBreathing,
        ModuleIds.toolboxDailyDecision,
      },
      _scenarioUtilities => <String>{
        ModuleIds.toolbox,
        ModuleIds.toolboxLifeTools,
        ModuleIds.toolboxDailyDecision,
        ModuleIds.toolboxSleepAssistant,
        ModuleIds.toolboxBreathing,
        ModuleIds.toolboxPrayerBeads,
        ModuleIds.toolboxZenSand,
      },
      _scenarioSecurity => <String>{
        ModuleIds.toolbox,
        ModuleIds.toolboxCryptoSecurity,
      },
      _scenarioLearning => <String>{
        ModuleIds.study,
        ModuleIds.practice,
        ModuleIds.toolbox,
        ModuleIds.toolboxSchulteGrid,
        ModuleIds.toolboxHumanTests,
      },
      _scenarioFun => <String>{
        ModuleIds.toolbox,
        ModuleIds.toolboxMiniGames,
        ModuleIds.toolboxHumanTests,
        ModuleIds.toolboxSoundDeck,
        ModuleIds.toolboxSingingBowls,
        ModuleIds.toolboxWoodfish,
        ModuleIds.toolboxZenSand,
        ModuleIds.toolboxSoothingMusic,
      },
      _ => ModuleIds.allModules.toSet(),
    };
  }

  IconData _scenarioIcon(String scenario) {
    return switch (scenario) {
      _scenarioWorkFocus => Icons.timer_outlined,
      _scenarioUtilities => Icons.handyman_outlined,
      _scenarioSecurity => Icons.security_outlined,
      _scenarioLearning => Icons.school_outlined,
      _scenarioFun => Icons.celebration_outlined,
      _ => Icons.apps_rounded,
    };
  }

  String _scenarioLabel(AppI18n i18n, String scenario) {
    return switch (scenario) {
      _scenarioWorkFocus => i18n.t('onboarding.first_run.scenario_work_focus'),
      _scenarioUtilities => i18n.t('onboarding.first_run.scenario_utilities'),
      _scenarioSecurity => i18n.t('onboarding.first_run.scenario_security'),
      _scenarioLearning => i18n.t('onboarding.first_run.scenario_learning'),
      _scenarioFun => i18n.t('onboarding.first_run.scenario_fun'),
      _ => i18n.t('onboarding.first_run.scenario_all'),
    };
  }

  String _themeLabel(AppI18n i18n, String theme) {
    return switch (theme) {
      'flat' => i18n.t('themeFlat'),
      'tech' => i18n.t('themeTech'),
      'dark' => i18n.t('themeDark'),
      'fantasy' => i18n.t('themeFantasy'),
      'nature' => i18n.t('themeNature'),
      'sunset' => i18n.t('themeSunset'),
      'ocean' => i18n.t('themeOcean'),
      'mono' => i18n.t('themeMono'),
      _ => theme,
    };
  }
}

class _FirstRunSection extends StatelessWidget {
  const _FirstRunSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.52,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(subtitle, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _FirstRunPermissionTile extends StatelessWidget {
  const _FirstRunPermissionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.badge,
  });

  final IconData icon;
  final String title;
  final String description;
  final String badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        child: Text(
                          badge,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(description, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
