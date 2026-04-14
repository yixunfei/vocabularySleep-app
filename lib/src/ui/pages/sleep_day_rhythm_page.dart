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
    if (!appState.isModuleEnabled(ModuleIds.toolboxSleepAssistant)) {
      return ToolboxToolPage(
        title: pickSleepText(i18n, zh: '睡眠助手', en: 'Sleep assistant'),
        subtitle: pickSleepText(
          i18n,
          zh: '模块已停用，无法继续访问睡眠助手页面。',
          en: 'This module is disabled and unavailable right now.',
        ),
        child: ModuleDisabledView(
          i18n: i18n,
          moduleId: ModuleIds.toolboxSleepAssistant,
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

    return ToolboxToolPage(
      title: pickSleepText(i18n, zh: '白天节律', en: 'Day rhythm'),
      subtitle: pickSleepText(
        i18n,
        zh: '把晨光、起床、咖啡因、午睡和恢复动作放在同一页里连续管理。',
        en: 'Manage light, wake time, caffeine, naps, and recovery on one page.',
      ),
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
                          label: pickSleepText(
                            i18n,
                            zh: '当前天数',
                            en: 'Current day',
                          ),
                          value: '${progress.currentDay}',
                        ),
                        ToolboxMetricCard(
                          label: pickSleepText(
                            i18n,
                            zh: '已完成',
                            en: 'Completed',
                          ),
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
                            ? pickSleepText(
                                i18n,
                                zh: '计划已完成',
                                en: 'Program completed',
                              )
                            : pickSleepText(
                                i18n,
                                zh: '完成今天',
                                en: 'Complete today',
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
                  Text(
                    pickSleepText(i18n, zh: '节律工具', en: 'Rhythm tools'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      SleepQuickToolButton(
                        title: pickSleepText(
                          i18n,
                          zh: '晨光计时器',
                          en: 'Morning light timer',
                        ),
                        icon: Icons.wb_sunny_rounded,
                        onTap: () => showMorningLightTimerSheet(context),
                      ),
                      SleepQuickToolButton(
                        title: pickSleepText(
                          i18n,
                          zh: '咖啡因截止线',
                          en: 'Caffeine cutoff',
                        ),
                        icon: Icons.local_cafe_rounded,
                        onTap: () => showCaffeineCutoffCalculatorSheet(context),
                      ),
                      SleepQuickToolButton(
                        title: pickSleepText(
                          i18n,
                          zh: '离床判断',
                          en: 'Leave-bed aid',
                        ),
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
                    pickSleepText(
                      i18n,
                      zh: '启动连续计划',
                      en: 'Start a structured plan',
                    ),
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
              title: pickSleepText(
                i18n,
                zh: '先记录 1 晚数据',
                en: 'Log one night first',
              ),
              message: pickSleepText(
                i18n,
                zh: '有了昨晚日志后，这一页才能根据晨光、午睡和刺激因子给出更具体建议。',
                en: 'With at least one log, this page can react to morning light, naps, and stimulation patterns.',
              ),
            )
          else
            Column(
              children: <Widget>[
                SettingTile(
                  icon: Icons.wb_sunny_rounded,
                  title: pickSleepText(i18n, zh: '晨光暴露', en: 'Morning light'),
                  subtitle: latest.morningLightDone
                      ? pickSleepText(
                          i18n,
                          zh: '最近一次已完成晨光，继续保持。',
                          en: 'Morning light was completed. Keep it steady.',
                        )
                      : pickSleepText(
                          i18n,
                          zh: '最近一次未完成晨光。今天尽快接触户外自然光。',
                          en: 'Morning light was missed. Get outdoor light early today.',
                        ),
                  trailing: Text(
                    latest.morningLightDone
                        ? pickSleepText(i18n, zh: '已完成', en: 'Done')
                        : pickSleepText(i18n, zh: '待补', en: 'Missed'),
                  ),
                ),
                const SizedBox(height: 8),
                SettingTile(
                  icon: Icons.free_breakfast_rounded,
                  title: pickSleepText(
                    i18n,
                    zh: '咖啡因截止线',
                    en: 'Caffeine cutoff',
                  ),
                  subtitle: latest.caffeineAfterCutoff
                      ? pickSleepText(
                          i18n,
                          zh: '最近一次有晚咖啡因，今天优先提前最后一杯。',
                          en: 'Late caffeine showed up. Move the last cup earlier today.',
                        )
                      : pickSleepText(
                          i18n,
                          zh: '最近一次没有晚咖啡因，继续保持。',
                          en: 'No late caffeine was logged. Keep it steady.',
                        ),
                  trailing: Text(
                    latest.caffeineAfterCutoff
                        ? pickSleepText(i18n, zh: '超线', en: 'Late')
                        : pickSleepText(i18n, zh: '稳定', en: 'Stable'),
                  ),
                ),
                const SizedBox(height: 8),
                SettingTile(
                  icon: Icons.hotel_rounded,
                  title: pickSleepText(i18n, zh: '午睡管理', en: 'Nap management'),
                  subtitle: latest.napMinutes > 30
                      ? pickSleepText(
                          i18n,
                          zh: '最近一次午睡偏长，优先压回 20 到 30 分钟内。',
                          en: 'Recent naps ran long. Pull them back toward 20 to 30 minutes.',
                        )
                      : pickSleepText(
                          i18n,
                          zh: '午睡时长相对可控，继续观察是否影响夜间困意。',
                          en: 'Recent nap length looks manageable. Keep watching its effect on nighttime sleep pressure.',
                        ),
                  trailing: Text('${latest.napMinutes}m'),
                ),
                const SizedBox(height: 8),
                SettingTile(
                  icon: Icons.phone_android_rounded,
                  title: pickSleepText(
                    i18n,
                    zh: '晚间刺激',
                    en: 'Evening stimulation',
                  ),
                  subtitle: latest.lateScreenExposure
                      ? pickSleepText(
                          i18n,
                          zh: '临睡前看屏存在，今晚优先把最后一小时收干净。',
                          en: 'Late screen exposure appeared. Clean up the final hour tonight.',
                        )
                      : pickSleepText(
                          i18n,
                          zh: '最近一次没有明显临睡前看屏。',
                          en: 'No obvious late screen exposure was logged.',
                        ),
                  trailing: Text(
                    latest.lateScreenExposure
                        ? pickSleepText(i18n, zh: '偏高', en: 'High')
                        : pickSleepText(i18n, zh: '正常', en: 'OK'),
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
                    pickSleepText(i18n, zh: '直接建议', en: 'Direct advice'),
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
                  ? pickSleepText(i18n, zh: '进行中', en: 'Active')
                  : pickSleepText(i18n, zh: '开始', en: 'Start'),
            ),
          ),
        ],
      ),
    );
  }
}
