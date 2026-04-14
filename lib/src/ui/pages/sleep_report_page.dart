import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/module_system/module_id.dart';
import '../../i18n/app_i18n.dart';
import '../../state/app_state.dart';
import '../module/module_access.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/setting_tile.dart';
import 'sleep_assistant_ui_support.dart';
import 'sleep_chart_widgets.dart';
import 'sleep_research_library.dart';
import 'toolbox_tool_shell.dart';

class SleepReportPage extends StatelessWidget {
  const SleepReportPage({super.key});

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
    final rangeDays = appState.sleepDashboardState.lastReportRangeDays;
    final recentLogs = appState.sleepDailyLogs
        .take(rangeDays)
        .toList(growable: false);

    if (recentLogs.isEmpty) {
      return ToolboxToolPage(
        title: pickSleepText(i18n, zh: '睡眠周报', en: 'Sleep report'),
        subtitle: pickSleepText(
          i18n,
          zh: '当日志积累起来后，这里会给你趋势、影响因子和下一步建议。',
          en: 'As logs accumulate, this page summarizes trends, factors, and next moves.',
        ),
        child: EmptyStateView(
          icon: Icons.insights_rounded,
          title: pickSleepText(i18n, zh: '还没有足够数据', en: 'No report data yet'),
          message: pickSleepText(
            i18n,
            zh: '先连续记录几晚，趋势图和建议才会更可靠。',
            en: 'Log a few nights first so the trends and advice become more reliable.',
          ),
        ),
      );
    }

    final chartLogs = recentLogs.reversed.toList(growable: false);
    final avgSleep = averageSleepInt(
      recentLogs.map((item) => item.estimatedTotalSleepMinutes),
    );
    final avgEfficiency = averageSleepDouble(
      recentLogs.map((item) => item.sleepEfficiency),
    );
    final avgEnergy = averageSleepInt(
      recentLogs.map((item) => item.morningEnergy),
    );
    final avgSleepiness = averageSleepInt(
      recentLogs.map((item) => item.daytimeSleepiness),
    );
    final lateCaffeineDays = recentLogs
        .where((item) => item.caffeineAfterCutoff)
        .length;
    final lateScreenDays = recentLogs
        .where((item) => item.lateScreenExposure)
        .length;
    final noisyDays = recentLogs
        .where(
          (item) =>
              item.bedroomTooNoisy ||
              item.bedroomTooBright ||
              item.bedroomTooHot,
        )
        .length;
    final morningLightDays = recentLogs
        .where((item) => item.morningLightDone)
        .length;
    final advice = buildSleepWeeklyAdvice(
      i18n,
      logs: recentLogs,
      profile: appState.sleepProfile,
    );

    return ToolboxToolPage(
      title: pickSleepText(i18n, zh: '睡眠周报', en: 'Sleep report'),
      subtitle: pickSleepText(
        i18n,
        zh: '先看连续趋势，再决定下一个周期只改哪一件事。',
        en: 'Read the pattern first, then choose one thing to change next.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        pickSleepText(i18n, zh: '报告范围', en: 'Range'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      SegmentedButton<int>(
                        segments: <ButtonSegment<int>>[
                          ButtonSegment<int>(
                            value: 7,
                            label: Text(
                              pickSleepText(i18n, zh: '7天', en: '7d'),
                            ),
                          ),
                          ButtonSegment<int>(
                            value: 14,
                            label: Text(
                              pickSleepText(i18n, zh: '14天', en: '14d'),
                            ),
                          ),
                        ],
                        selected: <int>{rangeDays},
                        onSelectionChanged: (selection) {
                          final value = selection.first;
                          appState.updateSleepDashboardState(
                            appState.sleepDashboardState.copyWith(
                              lastReportRangeDays: value,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      ToolboxMetricCard(
                        label: pickSleepText(i18n, zh: '平均睡眠', en: 'Avg sleep'),
                        value: sleepMinutesLabel(avgSleep),
                      ),
                      ToolboxMetricCard(
                        label: pickSleepText(
                          i18n,
                          zh: '平均效率',
                          en: 'Avg efficiency',
                        ),
                        value: sleepPercentLabel(avgEfficiency),
                      ),
                      ToolboxMetricCard(
                        label: pickSleepText(
                          i18n,
                          zh: '晨间精神',
                          en: 'Morning energy',
                        ),
                        value: sleepScoreLabel(avgEnergy),
                      ),
                      ToolboxMetricCard(
                        label: pickSleepText(
                          i18n,
                          zh: '白天困倦',
                          en: 'Daytime sleepiness',
                        ),
                        value: sleepScoreLabel(avgSleepiness),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SleepMetricChartCard(
            title: pickSleepText(
              i18n,
              zh: '睡眠时长趋势',
              en: 'Sleep duration trend',
            ),
            subtitle: pickSleepText(
              i18n,
              zh: '看总量是否在回升或继续缩水。',
              en: 'Check whether total sleep is recovering or shrinking.',
            ),
            i18n: i18n,
            points: chartLogs
                .map(
                  (log) => SleepChartPoint(
                    label: sleepDateLabel(log.dateKey).substring(5),
                    value: log.estimatedTotalSleepMinutes?.toDouble(),
                    valueLabel: sleepMinutesLabel(
                      log.estimatedTotalSleepMinutes,
                    ),
                  ),
                )
                .toList(growable: false),
            color: const Color(0xFF4976AA),
          ),
          const SizedBox(height: 12),
          SleepMetricChartCard(
            title: pickSleepText(
              i18n,
              zh: '睡眠效率趋势',
              en: 'Sleep efficiency trend',
            ),
            subtitle: pickSleepText(
              i18n,
              zh: '看在床上的时间有多少真的转成了睡眠。',
              en: 'Track how much time in bed turns into actual sleep.',
            ),
            i18n: i18n,
            points: chartLogs
                .map(
                  (log) => SleepChartPoint(
                    label: sleepDateLabel(log.dateKey).substring(5),
                    value: log.sleepEfficiency == null
                        ? null
                        : log.sleepEfficiency! * 100,
                    valueLabel: sleepPercentLabel(log.sleepEfficiency),
                  ),
                )
                .toList(growable: false),
            color: const Color(0xFF58805B),
          ),
          const SizedBox(height: 12),
          SleepMetricChartCard(
            title: pickSleepText(
              i18n,
              zh: '晨间精神趋势',
              en: 'Morning energy trend',
            ),
            subtitle: pickSleepText(
              i18n,
              zh: '比单次睡得长不长，更值得看恢复感有没有稳住。',
              en: 'Recovery stability often matters more than a single long night.',
            ),
            i18n: i18n,
            points: chartLogs
                .map(
                  (log) => SleepChartPoint(
                    label: sleepDateLabel(log.dateKey).substring(5),
                    value: log.morningEnergy?.toDouble(),
                    valueLabel: sleepScoreLabel(log.morningEnergy),
                  ),
                )
                .toList(growable: false),
            color: const Color(0xFFB4882D),
          ),
          const SizedBox(height: 12),
          SleepMetricChartCard(
            title: pickSleepText(i18n, zh: '夜醒负担趋势', en: 'Wake burden trend'),
            subtitle: pickSleepText(
              i18n,
              zh: '综合夜醒次数和总时长，判断是否该优先练夜醒脚本。',
              en: 'Combine wake count and wake minutes to see if rescue work should come first.',
            ),
            i18n: i18n,
            points: chartLogs
                .map(
                  (log) => SleepChartPoint(
                    label: sleepDateLabel(log.dateKey).substring(5),
                    value: sleepWakeBurdenValue(log).toDouble(),
                    valueLabel: sleepWakeBurdenLabel(i18n, log),
                  ),
                )
                .toList(growable: false),
            color: const Color(0xFF9C6652),
          ),
          const SizedBox(height: 12),
          SettingTile(
            icon: Icons.local_cafe_rounded,
            title: pickSleepText(i18n, zh: '晚咖啡因天数', en: 'Late caffeine days'),
            subtitle: pickSleepText(
              i18n,
              zh: '这个数偏高时，通常是最值得先改的变量。',
              en: 'A high count often signals the cleanest variable to fix first.',
            ),
            trailing: Text('$lateCaffeineDays/${recentLogs.length}'),
          ),
          const SizedBox(height: 8),
          SettingTile(
            icon: Icons.phone_android_rounded,
            title: pickSleepText(i18n, zh: '晚间看屏天数', en: 'Late screen days'),
            subtitle: pickSleepText(
              i18n,
              zh: '如果接近一半以上，优先整理最后一小时。',
              en: 'If this approaches half the range, clean up the final pre-bed hour first.',
            ),
            trailing: Text('$lateScreenDays/${recentLogs.length}'),
          ),
          const SizedBox(height: 8),
          SettingTile(
            icon: Icons.wb_sunny_rounded,
            title: pickSleepText(i18n, zh: '完成晨光天数', en: 'Morning light days'),
            subtitle: pickSleepText(
              i18n,
              zh: '节律想稳，晨光完成率通常比单次晚睡更关键。',
              en: 'For rhythm stability, morning light consistency often matters more than a single late night.',
            ),
            trailing: Text('$morningLightDays/${recentLogs.length}'),
          ),
          const SizedBox(height: 8),
          SettingTile(
            icon: Icons.meeting_room_rounded,
            title: pickSleepText(
              i18n,
              zh: '环境干扰天数',
              en: 'Environment issue days',
            ),
            subtitle: pickSleepText(
              i18n,
              zh: '亮、热、吵反复出现时，要先改卧室再谈技巧。',
              en: 'When light, heat, or noise repeat, fix the bedroom before adding more tricks.',
            ),
            trailing: Text('$noisyDays/${recentLogs.length}'),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    pickSleepText(i18n, zh: '下一个周期建议', en: 'Next-cycle advice'),
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
