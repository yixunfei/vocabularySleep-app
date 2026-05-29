import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/module_system/module_id.dart';
import '../../i18n/app_i18n.dart';
import '../../models/sleep_plan.dart';
import '../../state/app_state.dart';
import '../module/module_access.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/setting_tile.dart';
import 'sleep_assistant_ui_support.dart';
import 'sleep_quick_tools.dart';
import 'sleep_research_library.dart';
import 'toolbox_tool_shell.dart';

class SleepDayRhythmPage extends StatelessWidget {
  const SleepDayRhythmPage({super.key});

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
    final latest = appState.latestSleepDailyLog;
    final progress = appState.sleepProgramProgress;
    final advice = buildSleepDailyAdvice(
      i18n,
      profile: appState.sleepProfile,
      log: latest,
    );

    return themed(
      ToolboxToolPage(
        title: i18n.t('toolbox.sleep.rhythm.title'),
        subtitle: i18n.t('toolbox.sleep.rhythm.intro'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (progress != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        sleepProgramLabel(i18n, progress.programType),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(sleepProgramBody(i18n, progress.programType)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          ToolboxMetricCard(
                            label: i18n.t('toolbox.sleep.rhythm.currentDay'),
                            value: '${progress.currentDay}',
                          ),
                          ToolboxMetricCard(
                            label: i18n.t('toolbox.sleep.rhythm.completed'),
                            value: '${progress.completedDays.length}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: progress.isCompleted
                            ? null
                            : () => context
                                  .read<AppState>()
                                  .completeSleepProgramDay(progress.currentDay),
                        icon: const Icon(Icons.check_circle_rounded),
                        label: Text(
                          progress.isCompleted
                              ? i18n.t('toolbox.sleep.rhythm.programDone')
                              : i18n.t('toolbox.sleep.rhythm.completeToday'),
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
                    Text(
                      i18n.t('toolbox.sleep.rhythm.tools'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        SleepQuickToolButton(
                          title: i18n.t('toolbox.sleep.rhythm.lightTimer'),
                          icon: Icons.wb_sunny_rounded,
                          onTap: () => showMorningLightTimerSheet(context),
                        ),
                        SleepQuickToolButton(
                          title: i18n.t('toolbox.sleep.rhythm.caffeineCutoff'),
                          icon: Icons.local_cafe_rounded,
                          onTap: () =>
                              showCaffeineCutoffCalculatorSheet(context),
                        ),
                        SleepQuickToolButton(
                          title: i18n.t('toolbox.sleep.rhythm.leaveBedAid'),
                          icon: Icons.self_improvement_rounded,
                          onTap: () => showSleepinessDecisionSheet(context),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      i18n.t('toolbox.sleep.rhythm.startProgram'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    ...SleepProgramType.values.map(
                      (type) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ProgramCard(type: type),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (latest == null)
              EmptyStateView(
                icon: Icons.wb_sunny_rounded,
                title: i18n.t('toolbox.sleep.rhythm.logOneNight'),
                message: i18n.t('toolbox.sleep.rhythm.needOneLog'),
              )
            else
              Column(
                children: <Widget>[
                  SettingTile(
                    icon: Icons.wb_sunny_rounded,
                    title: i18n.t('toolbox.sleep.rhythm.morningLight'),
                    subtitle: latest.morningLightDone
                        ? i18n.t('toolbox.sleep.rhythm.morningLightDone')
                        : i18n.t('toolbox.sleep.rhythm.morningLightMissed'),
                    trailing: Text(
                      latest.morningLightDone
                          ? i18n.t('toolbox.sleep.rhythm.done')
                          : i18n.t('toolbox.sleep.rhythm.missed'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SettingTile(
                    icon: Icons.free_breakfast_rounded,
                    title: i18n.t('toolbox.sleep.rhythm.caffeineCutoff'),
                    subtitle: latest.caffeineAfterCutoff
                        ? i18n.t('toolbox.sleep.rhythm.lateCaffeine')
                        : i18n.t('toolbox.sleep.rhythm.noLateCaffeine'),
                    trailing: Text(
                      latest.caffeineAfterCutoff
                          ? i18n.t('toolbox.sleep.rhythm.late')
                          : i18n.t('toolbox.sleep.rhythm.stable'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SettingTile(
                    icon: Icons.hotel_rounded,
                    title: i18n.t('toolbox.sleep.rhythm.napMgmt'),
                    subtitle: latest.napMinutes > 30
                        ? i18n.t('toolbox.sleep.rhythm.napLong')
                        : i18n.t('toolbox.sleep.rhythm.napOk'),
                    trailing: Text('${latest.napMinutes}m'),
                  ),
                  const SizedBox(height: 8),
                  SettingTile(
                    icon: Icons.phone_android_rounded,
                    title: i18n.t('toolbox.sleep.rhythm.eveningStim'),
                    subtitle: latest.lateScreenExposure
                        ? i18n.t('toolbox.sleep.rhythm.eveningStimHigh')
                        : i18n.t('toolbox.sleep.rhythm.eveningStimOk'),
                    trailing: Text(
                      latest.lateScreenExposure
                          ? i18n.t('toolbox.sleep.rhythm.high')
                          : i18n.t('toolbox.sleep.rhythm.ok'),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      i18n.t('toolbox.sleep.rhythm.directAdvice'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    SleepAdviceList(items: advice, i18n: i18n),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({required this.type});

  final SleepProgramType type;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final i18n = AppI18n(appState.uiLanguage);
    final active =
        appState.sleepProgramProgress?.programType == type &&
        !(appState.sleepProgramProgress?.isCompleted ?? false);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  sleepProgramLabel(i18n, type),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(sleepProgramBody(i18n, type)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.tonal(
            onPressed: active
                ? null
                : () => context.read<AppState>().startSleepProgram(type),
            child: Text(
              active
                  ? i18n.t('toolbox.sleep.rhythm.active')
                  : i18n.t('toolbox.sleep.core.start'),
            ),
          ),
        ],
      ),
    );
  }
}
