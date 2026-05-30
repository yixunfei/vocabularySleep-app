import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/module_system/module_id.dart';
import '../../i18n/app_i18n.dart';
import '../../state/app_state.dart';
import '../module/module_access.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/setting_tile.dart';
import 'sleep_chart_widgets.dart';
import 'sleep_research_library.dart';
import 'sleep_assistant_ui_support.dart';
import 'toolbox_tool_shell.dart';

class SleepReportPage extends StatelessWidget {
  const SleepReportPage({super.key});

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
          subtitle: i18n.t('toolbox.sleep.assessment.moduleDisabled'),
          child: ModuleDisabledView(
            i18n: i18n,
            moduleId: ModuleIds.toolboxSleepAssistant,
          ),
        ),
      );
    }
    final rangeDays = appState.sleepDashboardState.lastReportRangeDays;
    final recentLogs = appState.sleepDailyLogs
        .take(rangeDays)
        .toList(growable: false);

    if (recentLogs.isEmpty) {
      return themed(
        ToolboxToolPage(
          title: i18n.t('toolbox.sleep.report.title'),
          subtitle: i18n.t('toolbox.sleep.report.intro'),
          child: EmptyStateView(
            icon: Icons.insights_rounded,
            title: i18n.t('toolbox.sleep.report.noData'),
            message: i18n.t('toolbox.sleep.report.noDataHint'),
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

    return themed(
      ToolboxToolPage(
        title: i18n.t('toolbox.sleep.report.title'),
        subtitle: i18n.t('toolbox.sleep.report.intro'),
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
                          i18n.t('toolbox.sleep.report.range'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        SegmentedButton<int>(
                          segments: <ButtonSegment<int>>[
                            ButtonSegment<int>(
                              value: 7,
                              label: Text(
                                i18n.t('toolbox.sleep.report.range7d'),
                              ),
                            ),
                            ButtonSegment<int>(
                              value: 14,
                              label: Text(
                                i18n.t('toolbox.sleep.report.range14d'),
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
                          label: i18n.t('toolbox.sleep.report.avgSleep'),
                          value: sleepMinutesLabel(avgSleep),
                        ),
                        ToolboxMetricCard(
                          label: i18n.t('toolbox.sleep.report.avgEfficiency'),
                          value: sleepPercentLabel(avgEfficiency),
                        ),
                        ToolboxMetricCard(
                          label: i18n.t('toolbox.sleep.report.morningEnergy'),
                          value: sleepScoreLabel(avgEnergy),
                        ),
                        ToolboxMetricCard(
                          label: i18n.t(
                            'toolbox.sleep.report.daytimeSleepiness',
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
              title: i18n.t('toolbox.sleep.report.sleepDurationTrend'),
              subtitle: i18n.t('toolbox.sleep.report.sleepDurationTrendHint'),
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
              title: i18n.t('toolbox.sleep.report.efficiencyTrend'),
              subtitle: i18n.t('toolbox.sleep.report.efficiencyTrendHint'),
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
              title: i18n.t('toolbox.sleep.report.energyTrend'),
              subtitle: i18n.t('toolbox.sleep.report.energyTrendHint'),
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
              title: i18n.t('toolbox.sleep.report.wakeBurden'),
              subtitle: i18n.t('toolbox.sleep.report.wakeBurdenHint'),
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
              title: i18n.t('toolbox.sleep.report.lateCaffeineDays'),
              subtitle: i18n.t('toolbox.sleep.report.lateCaffeineDaysHint'),
              trailing: Text('$lateCaffeineDays/${recentLogs.length}'),
            ),
            const SizedBox(height: 8),
            SettingTile(
              icon: Icons.phone_android_rounded,
              title: i18n.t('toolbox.sleep.report.lateScreenDays'),
              subtitle: i18n.t('toolbox.sleep.report.lateScreenDaysHint'),
              trailing: Text('$lateScreenDays/${recentLogs.length}'),
            ),
            const SizedBox(height: 8),
            SettingTile(
              icon: Icons.wb_sunny_rounded,
              title: i18n.t('toolbox.sleep.report.morningLightDays'),
              subtitle: i18n.t('toolbox.sleep.report.morningLightDaysHint'),
              trailing: Text('$morningLightDays/${recentLogs.length}'),
            ),
            const SizedBox(height: 8),
            SettingTile(
              icon: Icons.meeting_room_rounded,
              title: i18n.t('toolbox.sleep.report.envIssueDays'),
              subtitle: i18n.t('toolbox.sleep.report.envIssueDaysHint'),
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
                      i18n.t('toolbox.sleep.report.nextCycleAdvice'),
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
