import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/module_system/module_id.dart';
import '../../i18n/app_i18n.dart';
import '../../models/sleep_daily_log.dart';
import '../../services/sleep/sleep_day_report.dart';
import '../../state/app_state.dart';
import '../module/module_access.dart';
import 'sleep_assistant_ui_support.dart';
import 'sleep_chart_widgets.dart';
import 'sleep_research_library.dart';
import 'sleep_support/sleep_day_form_widgets.dart';
import 'sleep_support/sleep_day_history.dart';
import 'toolbox_tool_shell.dart';

class SleepReportPage extends StatelessWidget {
  const SleepReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.select(
      (AppState s) => (
        s.uiLanguage,
        s.sleepDailyLogs,
        s.sleepDashboardState.lastReportRangeDays,
        s.sleepDashboardState.sleepDarkModeEnabled,
        s.isModuleEnabled(ModuleIds.toolboxSleepAssistant),
        s.sleepProfile,
        s.sleepNightEvents,
      ),
    );
    final i18n = AppI18n(data.$1);
    final report = SleepDayReport(data.$2, days: data.$3, now: DateTime.now());
    return sleepModuleTheme(
      context: context,
      enabled: data.$4,
      child: Builder(
        builder: (context) => ToolboxToolPage(
          title: i18n.t('toolbox.sleep.report.title'),
          subtitle: i18n.t('toolbox.sleep.report.intro'),
          showPageHeader: false,
          child: data.$5
              ? _content(context, i18n, report)
              : ModuleDisabledView(
                  i18n: i18n,
                  moduleId: ModuleIds.toolboxSleepAssistant,
                ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, AppI18n i18n, SleepDayReport report) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _range(context, i18n, report),
          SleepDayHistory(
            events: context.read<AppState>().sleepNightEvents,
            dates: report.dates,
            i18n: i18n,
          ),
          if (report.recordedLogs.isEmpty)
            SleepDayPanel(
              title: i18n.t('toolbox.sleep.report.noData'),
              children: [Text(i18n.t('toolbox.sleep.report.noDataHint'))],
            )
          else ...[
            _averages(i18n, report.recordedLogs),
            ..._charts(i18n, report),
            _factors(i18n, report.recordedLogs),
            ExpansionTile(
              title: Text(i18n.t('toolbox.sleep.report.nextCycleAdvice')),
              childrenPadding: const EdgeInsets.all(16),
              children: [
                SleepAdviceList(
                  items: buildSleepWeeklyAdvice(
                    i18n,
                    logs: report.recordedLogs,
                    profile: context.read<AppState>().sleepProfile,
                  ),
                  i18n: i18n,
                ),
              ],
            ),
          ],
        ],
      );

  Widget _range(
    BuildContext context,
    AppI18n i18n,
    SleepDayReport report,
  ) => SleepDayPanel(
    title: i18n.t('toolbox.sleep.report.range'),
    children: [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final days in [7, 14])
            ChoiceChip(
              label: Text(
                i18n.t(
                  days == 7
                      ? 'toolbox.sleep.report.range7d'
                      : 'toolbox.sleep.report.range14d',
                ),
              ),
              selected: report.dates.length == days,
              onSelected: (_) {
                final state = context.read<AppState>();
                state.updateSleepDashboardState(
                  state.sleepDashboardState.copyWith(lastReportRangeDays: days),
                );
              },
            ),
        ],
      ),
      const SizedBox(height: 12),
      Text(
        '${SleepDayReport.dateKey(report.dates.first)} – ${SleepDayReport.dateKey(report.dates.last)}',
      ),
      const SizedBox(height: 8),
      Text(
        i18n.t(
          'toolbox.sleep.day.report_window',
          params: {
            'count': report.recordedLogs.length,
            'days': report.dates.length,
          },
        ),
      ),
    ],
  );

  Widget _averages(AppI18n i18n, List<SleepDailyLog> logs) => SleepDayPanel(
    title: i18n.t('toolbox.sleep.day.recorded_summary'),
    children: [
      for (final item in <(String, List<int?>, String Function(int?))>[
        (
          'avgSleep',
          logs.map((l) => l.estimatedTotalSleepMinutes).toList(),
          (value) => sleepMinutesLabel(value, i18n: i18n),
        ),
        (
          'morningEnergy',
          logs.map((l) => l.morningEnergy).toList(),
          sleepScoreLabel,
        ),
        (
          'daytimeSleepiness',
          logs.map((l) => l.daytimeSleepiness).toList(),
          sleepScoreLabel,
        ),
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            '${i18n.t('toolbox.sleep.report.${item.$1}')}: ${item.$3(averageSleepInt(item.$2))}\n'
            '${i18n.t('toolbox.sleep.day.samples', params: {'count': item.$2.whereType<int>().length})}',
          ),
        ),
      Text(
        '${i18n.t('toolbox.sleep.report.avgEfficiency')}: '
        '${sleepPercentLabel(averageSleepDouble(logs.map((l) => l.sleepEfficiency)))}\n'
        '${i18n.t('toolbox.sleep.day.samples', params: {'count': logs.where((l) => l.sleepEfficiency != null).length})}',
      ),
    ],
  );

  List<Widget> _charts(AppI18n i18n, SleepDayReport report) => [
    for (final metric
        in <
          (
            String,
            String,
            double? Function(SleepDailyLog),
            String Function(SleepDailyLog),
          )
        >[
          (
            'sleepDurationTrend',
            'sleepDurationTrendHint',
            (l) => l.estimatedTotalSleepMinutes?.toDouble(),
            (l) => sleepMinutesLabel(l.estimatedTotalSleepMinutes, i18n: i18n),
          ),
          (
            'efficiencyTrend',
            'efficiencyTrendHint',
            (l) => l.sleepEfficiency == null ? null : l.sleepEfficiency! * 100,
            (l) => sleepPercentLabel(l.sleepEfficiency),
          ),
          (
            'energyTrend',
            'energyTrendHint',
            (l) => l.morningEnergy?.toDouble(),
            (l) => sleepScoreLabel(l.morningEnergy),
          ),
          (
            'wakeBurden',
            'wakeBurdenHint',
            (l) => sleepWakeBurdenValue(l)?.toDouble(),
            (l) => sleepWakeBurdenLabel(i18n, l),
          ),
        ])
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SleepMetricChartCard(
          title: i18n.t('toolbox.sleep.report.${metric.$1}'),
          subtitle: i18n.t('toolbox.sleep.report.${metric.$2}'),
          i18n: i18n,
          points: List.generate(report.dates.length, (index) {
            final log = report.logs[index];
            return SleepChartPoint(
              label: '${report.dates[index].month}/${report.dates[index].day}',
              value: log == null ? null : metric.$3(log),
              valueLabel: log == null
                  ? i18n.t('toolbox.sleep.day.unknown')
                  : metric.$4(log),
            );
          }),
        ),
      ),
  ];

  Widget _factors(AppI18n i18n, List<SleepDailyLog> logs) => SleepDayPanel(
    title: i18n.t('toolbox.sleep.log.behaviorEnv'),
    children: [
      for (final factor in <(String, bool? Function(SleepDailyLog))>[
        ('lateCaffeineDays', (l) => l.caffeineAfterCutoff),
        ('lateScreenDays', (l) => l.lateScreenExposure),
        ('morningLightDays', (l) => l.morningLightDone),
        ('envIssueDays', _environmentIssue),
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            '${i18n.t('toolbox.sleep.report.${factor.$1}')}: '
            '${logs.where((l) => factor.$2(l) == true).length}/'
            '${logs.where((l) => factor.$2(l) != null).length}',
          ),
        ),
      Text(i18n.t('toolbox.sleep.day.known_only')),
    ],
  );

  bool? _environmentIssue(SleepDailyLog log) {
    final factors = [
      log.bedroomTooHot,
      log.bedroomTooBright,
      log.bedroomTooNoisy,
    ];
    if (factors.contains(true)) return true;
    return factors.contains(null) ? null : false;
  }
}
