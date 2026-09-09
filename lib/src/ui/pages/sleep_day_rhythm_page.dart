import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/module_system/module_id.dart';
import '../../i18n/app_i18n.dart';
import '../../models/sleep_plan.dart';
import '../../services/sleep/sleep_day_program.dart';
import '../../state/app_state.dart';
import '../module/module_access.dart';
import 'sleep_assistant_ui_support.dart';
import 'sleep_quick_tools.dart';
import 'sleep_research_library.dart';
import 'sleep_support/sleep_day_form_widgets.dart';
import 'toolbox_tool_shell.dart';

class SleepDayRhythmPage extends StatelessWidget {
  const SleepDayRhythmPage({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.select(
      (AppState s) => (
        s.uiLanguage,
        s.sleepProgramProgress,
        s.latestSleepDailyLog,
        s.sleepProfile,
        s.sleepDashboardState.sleepDarkModeEnabled,
        s.isModuleEnabled(ModuleIds.toolboxSleepAssistant),
      ),
    );
    final i18n = AppI18n(data.$1);
    return sleepModuleTheme(
      context: context,
      enabled: data.$5,
      child: Builder(
        builder: (context) => ToolboxToolPage(
          title: i18n.t('toolbox.sleep.rhythm.title'),
          subtitle: i18n.t('toolbox.sleep.rhythm.intro'),
          showPageHeader: false,
          child: data.$6
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _today(context, i18n, data.$2),
                    _tools(context, i18n),
                    _programs(i18n),
                    ExpansionTile(
                      title: Text(i18n.t('toolbox.sleep.rhythm.directAdvice')),
                      childrenPadding: const EdgeInsets.all(16),
                      children: [
                        SleepAdviceList(
                          items: buildSleepDailyAdvice(
                            i18n,
                            profile: data.$4,
                            log: data.$3,
                          ),
                          i18n: i18n,
                        ),
                      ],
                    ),
                  ],
                )
              : ModuleDisabledView(
                  i18n: i18n,
                  moduleId: ModuleIds.toolboxSleepAssistant,
                ),
        ),
      ),
    );
  }

  Widget _today(
    BuildContext context,
    AppI18n i18n,
    SleepProgramProgress? progress,
  ) {
    final now = DateTime.now();
    final day = progress == null
        ? 1
        : SleepDayProgram.todayDay(progress, now: now);
    final total = progress == null
        ? 7
        : SleepDayProgram.duration(progress.programType);
    final ended = progress != null && (progress.isCompleted || day > total);
    final done = progress?.completedDays.contains(day) ?? false;
    final canComplete =
        progress != null &&
        SleepDayProgram.canComplete(progress, day, now: now);
    final type = progress?.programType ?? SleepProgramType.sevenDayRhythmReset;
    return SleepDayPanel(
      title: i18n.t('toolbox.sleep.day.today_action'),
      children: [
        if (progress != null) ...[
          Text(sleepProgramLabel(i18n, type)),
          const SizedBox(height: 12),
        ],
        Text(
          i18n.t(
            ended
                ? 'toolbox.sleep.day.cycle_finished'
                : day < 1
                ? 'toolbox.sleep.day.not_started'
                : SleepDayProgram.actionKey(type, day),
          ),
        ),
        const SizedBox(height: 20),
        if (progress == null)
          FilledButton(
            onPressed: () => context.read<AppState>().startSleepProgram(type),
            child: Text(i18n.t('toolbox.sleep.day.start_gently')),
          )
        else if (!ended && day >= 1)
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: canComplete
                ? () => context.read<AppState>().completeSleepProgramDay(day)
                : null,
            icon: Icon(done ? Icons.check_rounded : Icons.check_circle_outline),
            label: Text(
              i18n.t(
                done
                    ? 'toolbox.sleep.day.done_today'
                    : 'toolbox.sleep.rhythm.completeToday',
              ),
            ),
          ),
        if (done && !ended) ...[
          const SizedBox(height: 12),
          Text(i18n.t('toolbox.sleep.day.return_tomorrow')),
        ],
      ],
    );
  }

  Widget _tools(BuildContext context, AppI18n i18n) => SleepDayPanel(
    title: i18n.t('toolbox.sleep.rhythm.tools'),
    children: [
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          SleepQuickToolButton(
            title: i18n.t('toolbox.sleep.rhythm.lightTimer'),
            icon: Icons.wb_sunny_rounded,
            onTap: () => showMorningLightTimerSheet(context),
          ),
          SleepQuickToolButton(
            title: i18n.t('toolbox.sleep.rhythm.caffeineCutoff'),
            icon: Icons.local_cafe_rounded,
            onTap: () => showCaffeineCutoffCalculatorSheet(context),
          ),
          SleepQuickToolButton(
            title: i18n.t('toolbox.sleep.rhythm.leaveBedAid'),
            icon: Icons.self_improvement_rounded,
            onTap: () => showSleepinessDecisionSheet(context),
          ),
        ],
      ),
    ],
  );

  Widget _programs(AppI18n i18n) => ExpansionTile(
    title: Text(i18n.t('toolbox.sleep.rhythm.startProgram')),
    children: [
      for (final type in SleepProgramType.values) _ProgramCard(type: type),
    ],
  );
}

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({required this.type});
  final SleepProgramType type;

  @override
  Widget build(BuildContext context) {
    final data = context.select(
      (AppState s) => (s.uiLanguage, s.sleepProgramProgress),
    );
    final i18n = AppI18n(data.$1);
    final progress = data.$2;
    final active =
        progress != null &&
        progress.programType == type &&
        !progress.isCompleted &&
        SleepDayProgram.todayDay(progress, now: DateTime.now()) <=
            SleepDayProgram.duration(type);
    return SleepDayPanel(
      title: sleepProgramLabel(i18n, type),
      children: [
        Text(sleepProgramBody(i18n, type)),
        const SizedBox(height: 12),
        FilledButton.tonal(
          onPressed: active ? null : () => _start(context, i18n, progress),
          child: Text(
            i18n.t(
              active
                  ? 'toolbox.sleep.rhythm.active'
                  : 'toolbox.sleep.core.start',
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _start(
    BuildContext context,
    AppI18n i18n,
    SleepProgramProgress? current,
  ) async {
    if (current != null &&
        !current.isCompleted &&
        SleepDayProgram.todayDay(current, now: DateTime.now()) <=
            SleepDayProgram.duration(current.programType)) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(i18n.t('toolbox.sleep.day.replace_program')),
          content: Text(i18n.t('toolbox.sleep.day.replace_program_hint')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(i18n.t('toolbox.sleep.day.back')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(i18n.t('toolbox.sleep.core.start')),
            ),
          ],
        ),
      );
      if (replace != true || !context.mounted) return;
    }
    context.read<AppState>().startSleepProgram(type);
  }
}
