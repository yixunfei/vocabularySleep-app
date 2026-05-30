import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/module_system/module_id.dart';
import '../../i18n/app_i18n.dart';
import '../../models/sleep_daily_log.dart';
import '../../state/app_state.dart';
import '../module/module_access.dart';
import 'sleep_quick_tools.dart';
import 'sleep_assistant_ui_support.dart';
import 'sleep_research_library.dart';
import 'toolbox_tool_shell.dart';

class SleepNightRescuePage extends StatefulWidget {
  const SleepNightRescuePage({super.key, this.initialMode});

  final SleepNightRescueMode? initialMode;

  @override
  State<SleepNightRescuePage> createState() => _SleepNightRescuePageState();
}

class _SleepNightRescuePageState extends State<SleepNightRescuePage> {
  late SleepNightRescueMode _selectedMode;
  late final TextEditingController _triggerController;
  late final TextEditingController _actionController;
  late final TextEditingController _notesController;
  bool _hasLeftBed = false;

  @override
  void initState() {
    super.initState();
    final current = context.read<AppState>().sleepNightRescueState.mode;
    _selectedMode =
        widget.initialMode ?? current ?? SleepNightRescueMode.fullyAwake;
    _triggerController = TextEditingController();
    _actionController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _triggerController.dispose();
    _actionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _startGuide() {
    context.read<AppState>().startSleepNightRescue(_selectedMode);
  }

  void _saveEvent() {
    final appState = context.read<AppState>();
    final rescueState = appState.sleepNightRescueState;
    final startedAt = rescueState.mode == _selectedMode
        ? rescueState.startedAt ?? DateTime.now()
        : DateTime.now();
    final actionText = _actionController.text.trim().isEmpty
        ? rescueState.suggestedAction
        : _actionController.text.trim();
    appState.saveSleepNightEvent(
      SleepNightEvent(
        dateKey: todaySleepDateKey(),
        mode: _selectedMode,
        startedAt: startedAt,
        endedAt: DateTime.now(),
        guessedTrigger: _triggerController.text.trim().isEmpty
            ? null
            : _triggerController.text.trim(),
        actionTaken: actionText,
        returnedToBedAt: _hasLeftBed ? DateTime.now() : null,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      ),
    );
    appState.finishSleepNightRescue(
      suggestedAction: rescueState.suggestedAction,
      hasLeftBed: _hasLeftBed,
    );
    final i18n = AppI18n(appState.uiLanguage);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(i18n.t('toolbox.sleep.rescue.saved'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final i18n = AppI18n(appState.uiLanguage);
    Widget themed(Widget child) {
      return sleepModuleTheme(
        context: context,
        enabled: appState.sleepDashboardState.sleepDarkModeEnabled,
        child: child,
      );
    }

    if (!appState.isModuleEnabled(ModuleIds.toolboxSleepAssistant)) {
      return themed(
        ToolboxToolPage(
          title: i18n.t('toolbox.sleep.core.title'),
          subtitle: i18n.t('toolbox.sleep.core.disabled'),
          child: ModuleDisabledView(
            i18n: i18n,
            moduleId: ModuleIds.toolboxSleepAssistant,
          ),
        ),
      );
    }
    final rescueState = appState.sleepNightRescueState;
    final suggestedAction = rescueState.mode == _selectedMode
        ? rescueState.suggestedAction
        : sleepNightModeBody(i18n, _selectedMode);
    final recentEvents = appState.sleepNightEvents
        .take(4)
        .toList(growable: false);
    final topicId = switch (_selectedMode) {
      SleepNightRescueMode.racingThoughts => sleepTopicWorryUnload,
      SleepNightRescueMode.temperatureDiscomfort => sleepTopicBodyTemperature,
      _ => sleepTopicStimulusControl,
    };

    return themed(
      ToolboxToolPage(
        title: i18n.t('toolbox.sleep.rescue.title'),
        subtitle: i18n.t('toolbox.sleep.rescue.intro'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      i18n.t('toolbox.sleep.rescue.chooseState'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ...SleepNightRescueMode.values.map(
                      (mode) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => setState(() => _selectedMode = mode),
                          child: Ink(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: _selectedMode == mode
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer
                                  : Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerLow,
                              border: Border.all(
                                color: _selectedMode == mode
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        sleepNightModeLabel(i18n, mode),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                    Icon(
                                      _selectedMode == mode
                                          ? Icons.check_circle_rounded
                                          : Icons.circle_outlined,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(sleepNightModeBody(i18n, mode)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            i18n.t('toolbox.sleep.rescue.currentGuidance'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          onPressed: () => showSleepResearchTopicById(
                            context,
                            i18n,
                            topicId,
                          ),
                          icon: const Icon(Icons.info_outline_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      suggestedAction ??
                          i18n.t('toolbox.sleep.rescue.chooseFirst'),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        FilledButton.icon(
                          onPressed: _startGuide,
                          icon: const Icon(Icons.play_circle_outline_rounded),
                          label: Text(
                            i18n.t('toolbox.sleep.rescue.beginGuide'),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => showSleepinessDecisionSheet(context),
                          icon: const Icon(Icons.rule_folder_rounded),
                          label: Text(
                            i18n.t('toolbox.sleep.rescue.leaveBedAid'),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _saveEvent,
                          icon: const Icon(Icons.save_rounded),
                          label: Text(i18n.t('toolbox.sleep.rescue.saveEvent')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: <Widget>[
                    TextField(
                      controller: _triggerController,
                      decoration: InputDecoration(
                        labelText: i18n.t(
                          'toolbox.sleep.rescue.guessedTrigger',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _actionController,
                      decoration: InputDecoration(
                        labelText: i18n.t('toolbox.sleep.rescue.actionTaken'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: i18n.t('toolbox.sleep.rescue.extraNotes'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(i18n.t('toolbox.sleep.rescue.leftBed')),
                      value: _hasLeftBed,
                      onChanged: (value) => setState(() => _hasLeftBed = value),
                    ),
                  ],
                ),
              ),
            ),
            if (recentEvents.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        i18n.t('toolbox.sleep.rescue.recentEvents'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      ...recentEvents.map(
                        (event) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerLow,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  '${sleepDateLabel(event.dateKey)} · ${sleepNightModeLabel(i18n, event.mode)}',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 4),
                                if ((event.actionTaken ?? '').trim().isNotEmpty)
                                  Text(
                                    '${i18n.t('toolbox.sleep.rescue.action')}: ${event.actionTaken}',
                                  ),
                                if ((event.guessedTrigger ?? '')
                                    .trim()
                                    .isNotEmpty)
                                  Text(
                                    '${i18n.t('toolbox.sleep.rescue.trigger')}: ${event.guessedTrigger}',
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
