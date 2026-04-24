import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/module_system/module_id.dart';
import '../../i18n/app_i18n.dart';
import '../../models/sleep_daily_log.dart';
import '../../models/sleep_plan.dart';
import '../../models/sleep_profile.dart';
import '../../state/app_state.dart';
import '../../state/app_state_provider.dart';
import '../module/module_access.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/section_header.dart';
import 'sleep_assessment_page.dart';
import 'sleep_assistant_ui_support.dart';
import 'sleep_daily_log_page.dart';
import 'sleep_day_rhythm_page.dart';
import 'sleep_night_rescue_page.dart';
import 'sleep_quick_tools.dart';
import 'sleep_research_library.dart';
import 'sleep_report_page.dart';
import 'sleep_wind_down_page.dart';
import 'toolbox_tool_shell.dart';

class ToolboxSleepAssistantPage extends ConsumerStatefulWidget {
  const ToolboxSleepAssistantPage({super.key});

  @override
  ConsumerState<ToolboxSleepAssistantPage> createState() =>
      _ToolboxSleepAssistantPageState();
}

class _ToolboxSleepAssistantPageState
    extends ConsumerState<ToolboxSleepAssistantPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final appState = ref.read(appStateProvider);
      if (!appState.isModuleEnabled(ModuleIds.toolboxSleepAssistant)) {
        return;
      }
      if (!_hasLoadedSleepData(appState)) {
        appState.loadSleepAssistantData();
      }
      final today = todaySleepDateKey();
      if (appState.sleepDashboardState.lastOpenedDateKey != today) {
        appState.updateSleepDashboardState(
          appState.sleepDashboardState.copyWith(lastOpenedDateKey: today),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final i18n = AppI18n(appState.uiLanguage);
    if (!appState.isModuleEnabled(ModuleIds.toolboxSleepAssistant)) {
      return ModuleDisabledView(
        i18n: i18n,
        moduleId: ModuleIds.toolboxSleepAssistant,
      );
    }
    final recentLogs = appState.sleepDailyLogs.take(7).toList(growable: false);
    final latestLog = appState.latestSleepDailyLog;
    final profile = appState.sleepProfile;
    final avgSleep = averageSleepInt(
      recentLogs.map((item) => item.estimatedTotalSleepMinutes),
    );
    final avgEfficiency = averageSleepDouble(
      recentLogs.map((item) => item.sleepEfficiency),
    );
    final avgEnergy = averageSleepInt(
      recentLogs.map((item) => item.morningEnergy),
    );
    final advice = latestLog != null
        ? buildSleepDailyAdvice(i18n, profile: profile, log: latestLog)
        : buildSleepAssessmentAdvice(
            i18n,
            draft: appState.sleepAssessmentDraft,
          );
    final nextStep = _buildNextStep(
      context: context,
      appState: appState,
      i18n: i18n,
      latestLog: latestLog,
      profile: profile,
    );

    return sleepModuleTheme(
      context: context,
      enabled: appState.sleepDashboardState.sleepDarkModeEnabled,
      child: ToolboxToolPage(
        title: pickSleepText(i18n, zh: '睡眠助手', en: 'Sleep assistant'),
        subtitle: pickSleepText(
          i18n,
          zh: '把评估、连续日志、夜醒救援、睡前流程、节律和周报放进一个闭环入口。',
          en: 'One loop for assessment, continuous logs, rescue, routines, rhythm, and reports.',
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (appState.sleepLoading && !_hasLoadedSleepData(appState))
              const Card(child: _SleepAssistantLoadingState())
            else ...<Widget>[
              if (profile?.snoringRisk == SleepRiskLevel.medium ||
                  profile?.snoringRisk == SleepRiskLevel.high)
                Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(
                          Icons.health_and_safety_rounded,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            pickSleepText(
                              i18n,
                              zh: '当前存在中高水平打鼾风险线索。工具可以继续帮你做记录和行为调整，但如果伴随憋醒、巨大鼾声或白天困到影响功能，建议尽快做进一步评估。',
                              en: 'Elevated snoring risk is present. Behavior tools can still help, but loud snoring, gasping, or severe daytime sleepiness should be assessed further.',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _SleepNowPanel(step: nextStep),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
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
                      if (appState.sleepCurrentPlan != null)
                        ToolboxMetricCard(
                          label: pickSleepText(i18n, zh: '主线', en: 'Track'),
                          value: sleepTrackLabel(
                            i18n,
                            appState.sleepCurrentPlan!.track,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_rounded),
                  title: Text(
                    pickSleepText(i18n, zh: '睡眠暗色模式', en: 'Sleep dark mode'),
                  ),
                  subtitle: Text(
                    pickSleepText(
                      i18n,
                      zh: '只在睡眠助手内部生效，适合夜间查看和执行流程。',
                      en: 'Applies only inside the sleep assistant for nighttime use.',
                    ),
                  ),
                  value: appState.sleepDashboardState.sleepDarkModeEnabled,
                  onChanged: (value) => appState.updateSleepDashboardState(
                    appState.sleepDashboardState.copyWith(
                      sleepDarkModeEnabled: value,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SectionHeader(
                title: pickSleepText(
                  i18n,
                  zh: '低能量快速开始',
                  en: 'Low-energy start',
                ),
                subtitle: pickSleepText(
                  i18n,
                  zh: '只放最常用的一步工具：睡前、夜醒、晨光、咖啡因和 90 分钟周期。',
                  en: 'Only the one-step tools: wind-down, rescue, light, caffeine, and 90-minute cycles.',
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  SleepQuickToolButton(
                    title: pickSleepText(
                      i18n,
                      zh: '最低能量睡前',
                      en: 'Tiny wind-down',
                    ),
                    icon: Icons.bedtime_rounded,
                    onTap: () => _startTinyRoutine(context, appState),
                  ),
                  SleepQuickToolButton(
                    title: pickSleepText(i18n, zh: '夜醒救援', en: 'Night rescue'),
                    icon: Icons.self_improvement_rounded,
                    onTap: () =>
                        _open(context, appState, const SleepNightRescuePage()),
                  ),
                  SleepQuickToolButton(
                    title: pickSleepText(i18n, zh: '晨光', en: 'Morning light'),
                    icon: Icons.wb_sunny_rounded,
                    onTap: () => showMorningLightTimerSheet(context),
                  ),
                  SleepQuickToolButton(
                    title: pickSleepText(i18n, zh: '咖啡因线', en: 'Caffeine'),
                    icon: Icons.local_cafe_rounded,
                    onTap: () => showCaffeineCutoffCalculatorSheet(context),
                  ),
                  SleepQuickToolButton(
                    title: pickSleepText(i18n, zh: '90 分钟', en: '90 min'),
                    icon: Icons.more_time_rounded,
                    onTap: () => showSleepCyclePlannerSheet(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SectionHeader(
                title: pickSleepText(i18n, zh: '当前主线', en: 'Current plan'),
                subtitle: pickSleepText(
                  i18n,
                  zh: '先给自己一个最值得先做的方向，而不是同时堆很多睡眠技巧。',
                  en: 'Choose one priority direction instead of stacking too many tactics.',
                ),
              ),
              const SizedBox(height: 12),
              const _CurrentPlanCard(),
              const SizedBox(height: 20),
              SectionHeader(
                title: pickSleepText(i18n, zh: '快速入口', en: 'Quick actions'),
                subtitle: pickSleepText(
                  i18n,
                  zh: '从评估、日志、今晚流程、夜醒救援、白天节律和周报进入。',
                  en: 'Jump into assessment, logs, tonight routine, rescue, rhythm, and reports.',
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  _SleepQuickActionCard(
                    title: pickSleepText(i18n, zh: '睡眠评估', en: 'Assessment'),
                    subtitle: pickSleepText(
                      i18n,
                      zh: '识别问题类型和风险线索。',
                      en: 'Assess issues and risk signals.',
                    ),
                    icon: Icons.fact_check_rounded,
                    accent: const Color(0xFF517D6E),
                    onTap: () =>
                        _open(context, appState, const SleepAssessmentPage()),
                  ),
                  _SleepQuickActionCard(
                    title: pickSleepText(
                      i18n,
                      zh: '连续日志',
                      en: 'Continuous log',
                    ),
                    subtitle: pickSleepText(
                      i18n,
                      zh: '按日期持续编辑睡眠日志。',
                      en: 'Continuously edit sleep logs by date.',
                    ),
                    icon: Icons.bedtime_rounded,
                    accent: const Color(0xFF4E74A8),
                    onTap: () =>
                        _open(context, appState, const SleepDailyLogPage()),
                  ),
                  _SleepQuickActionCard(
                    title: pickSleepText(
                      i18n,
                      zh: '今晚流程',
                      en: 'Tonight routine',
                    ),
                    subtitle: pickSleepText(
                      i18n,
                      zh: '模板、执行器和担忧卸载。',
                      en: 'Templates, runner, and thought unload.',
                    ),
                    icon: Icons.nights_stay_rounded,
                    accent: const Color(0xFF805C92),
                    onTap: () =>
                        _open(context, appState, const SleepWindDownPage()),
                  ),
                  _SleepQuickActionCard(
                    title: pickSleepText(i18n, zh: '夜醒救援', en: 'Night rescue'),
                    subtitle: pickSleepText(
                      i18n,
                      zh: '按夜醒类型走低刺激脚本。',
                      en: 'Use low-stim scripts for awakenings.',
                    ),
                    icon: Icons.self_improvement_rounded,
                    accent: const Color(0xFF9A6A52),
                    onTap: () =>
                        _open(context, appState, const SleepNightRescuePage()),
                  ),
                  _SleepQuickActionCard(
                    title: pickSleepText(i18n, zh: '白天节律', en: 'Day rhythm'),
                    subtitle: pickSleepText(
                      i18n,
                      zh: '晨光、咖啡因、午睡和计划。',
                      en: 'Light, caffeine, naps, and structured plans.',
                    ),
                    icon: Icons.wb_sunny_rounded,
                    accent: const Color(0xFFB08B33),
                    onTap: () =>
                        _open(context, appState, const SleepDayRhythmPage()),
                  ),
                  _SleepQuickActionCard(
                    title: pickSleepText(i18n, zh: '睡眠周报', en: 'Sleep report'),
                    subtitle: pickSleepText(
                      i18n,
                      zh: '看图表、影响因子和下周建议。',
                      en: 'Review charts, factors, and next-cycle advice.',
                    ),
                    icon: Icons.insights_rounded,
                    accent: const Color(0xFF6A7F9E),
                    onTap: () =>
                        _open(context, appState, const SleepReportPage()),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SectionHeader(
                title: pickSleepText(i18n, zh: '实用工具', en: 'Practical tools'),
                subtitle: pickSleepText(
                  i18n,
                  zh: '这类小工具更适合做即时辅助，而不是单独变成复杂页面。',
                  en: 'These tools work best as lightweight helpers instead of heavy standalone pages.',
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  SleepQuickToolButton(
                    title: pickSleepText(i18n, zh: '白噪音', en: 'White noise'),
                    icon: Icons.graphic_eq_rounded,
                    onTap: () => showSleepWhiteNoiseSheet(context),
                  ),
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
                ],
              ),
              const SizedBox(height: 20),
              SectionHeader(
                title: pickSleepText(i18n, zh: '直接建议', en: 'Direct advice'),
                subtitle: pickSleepText(
                  i18n,
                  zh: '点击卡片右上角说明，可查看对应研究解释和参考书依据。',
                  en: 'Use the info button on each card for research detail and book context.',
                ),
              ),
              const SizedBox(height: 12),
              SleepAdviceList(
                items: advice.take(4).toList(growable: false),
                i18n: i18n,
              ),
              const SizedBox(height: 20),
              SectionHeader(
                title: pickSleepText(i18n, zh: '近 7 天趋势', en: '7-day trend'),
                subtitle: pickSleepText(
                  i18n,
                  zh: '先看短趋势，再决定是否要切换主线。',
                  en: 'Read the short trend before switching tracks.',
                ),
              ),
              const SizedBox(height: 12),
              if (recentLogs.isEmpty)
                EmptyStateView(
                  icon: Icons.hotel_rounded,
                  title: pickSleepText(
                    i18n,
                    zh: '还没有睡眠日志',
                    en: 'No sleep logs yet',
                  ),
                  message: pickSleepText(
                    i18n,
                    zh: '先从连续日志开始，至少记录 3 到 7 天，趋势和建议才会更可靠。',
                    en: 'Start the continuous log and collect at least 3 to 7 days first.',
                  ),
                  actionLabel: pickSleepText(
                    i18n,
                    zh: '去记录',
                    en: 'Start logging',
                  ),
                  onAction: () =>
                      _open(context, appState, const SleepDailyLogPage()),
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (latestLog != null) _LatestLogRow(),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: <Widget>[
                            ToolboxMetricCard(
                              label: pickSleepText(
                                i18n,
                                zh: '晚咖啡因',
                                en: 'Late caffeine',
                              ),
                              value:
                                  '${recentLogs.where((item) => item.caffeineAfterCutoff).length}/${recentLogs.length}',
                            ),
                            ToolboxMetricCard(
                              label: pickSleepText(
                                i18n,
                                zh: '晚间看屏',
                                en: 'Late screens',
                              ),
                              value:
                                  '${recentLogs.where((item) => item.lateScreenExposure).length}/${recentLogs.length}',
                            ),
                            ToolboxMetricCard(
                              label: pickSleepText(
                                i18n,
                                zh: '晨光完成',
                                en: 'Morning light',
                              ),
                              value:
                                  '${recentLogs.where((item) => item.morningLightDone).length}/${recentLogs.length}',
                            ),
                          ],
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

  static _SleepHomeNextStep _buildNextStep({
    required BuildContext context,
    required AppState appState,
    required AppI18n i18n,
    required SleepDailyLog? latestLog,
    required SleepProfile? profile,
  }) {
    final now = DateTime.now();
    final hour = now.hour;
    final routine = appState.sleepRoutineRunnerState;
    final latestIsToday = latestLog?.dateKey == todaySleepDateKey();
    final lowEnergySignals = <String>[
      if (appState.sleepDailyLogs.length < 3)
        pickSleepText(i18n, zh: '先收集 3 晚', en: 'Collect 3 nights'),
      if (profile?.hasRacingThoughts == true)
        pickSleepText(i18n, zh: '思绪偏活跃', en: 'Busy mind'),
      if (latestLog?.lateScreenExposure == true)
        pickSleepText(i18n, zh: '昨晚看屏', en: 'Late screens'),
    ];

    if (profile == null) {
      return _SleepHomeNextStep(
        eyebrow: pickSleepText(i18n, zh: '先定主线', en: 'Set direction'),
        title: pickSleepText(
          i18n,
          zh: '用 2 分钟做一次睡眠评估',
          en: 'Take a 2-minute assessment',
        ),
        body: pickSleepText(
          i18n,
          zh: '先识别你更像是节律、压力、夜醒、环境还是白天恢复问题，系统才不会一次塞给你太多技巧。',
          en: 'Identify whether rhythm, stress, awakenings, environment, or recovery should come first.',
        ),
        icon: Icons.fact_check_rounded,
        accent: const Color(0xFF517D6E),
        primaryLabel: pickSleepText(i18n, zh: '开始评估', en: 'Start'),
        onPrimary: () => _open(context, appState, const SleepAssessmentPage()),
        secondaryLabel: pickSleepText(i18n, zh: '先看夜醒救援', en: 'Rescue first'),
        onSecondary: () =>
            _open(context, appState, const SleepNightRescuePage()),
        signals: <String>[
          pickSleepText(i18n, zh: '先少后多', en: 'Small first'),
          pickSleepText(i18n, zh: '自动生成主线', en: 'Auto plan'),
        ],
      );
    }

    if (routine.isRunning || routine.isPaused) {
      return _SleepHomeNextStep(
        eyebrow: pickSleepText(i18n, zh: '正在进行', en: 'In progress'),
        title: pickSleepText(
          i18n,
          zh: '继续今晚流程',
          en: 'Continue tonight routine',
        ),
        body: pickSleepText(
          i18n,
          zh: '不要重新选择，也不要再加任务。回到当前步骤，把它做完就够了。',
          en: 'Do not re-plan or add tasks. Return to the current step and finish it.',
        ),
        icon: Icons.play_circle_fill_rounded,
        accent: const Color(0xFF805C92),
        primaryLabel: pickSleepText(i18n, zh: '回到流程', en: 'Open routine'),
        onPrimary: () => _open(context, appState, const SleepWindDownPage()),
        secondaryLabel: pickSleepText(i18n, zh: '夜醒救援', en: 'Night rescue'),
        onSecondary: () =>
            _open(context, appState, const SleepNightRescuePage()),
        signals: <String>[
          sleepSecondsLabel(routine.remainingSeconds, i18n: i18n),
          pickSleepText(i18n, zh: '不加新任务', en: 'No extra task'),
        ],
      );
    }

    if (hour < 5) {
      return _SleepHomeNextStep(
        eyebrow: pickSleepText(i18n, zh: '夜里模式', en: 'Night mode'),
        title: pickSleepText(
          i18n,
          zh: '只判断：留床还是离床',
          en: 'Only decide: stay or leave bed',
        ),
        body: pickSleepText(
          i18n,
          zh: '夜里不做复盘，不追求立刻睡着。先按当前状态走一个低刺激脚本。',
          en: 'Do not analyze at night. Use one low-stimulation script for the current state.',
        ),
        icon: Icons.self_improvement_rounded,
        accent: const Color(0xFF9A6A52),
        primaryLabel: pickSleepText(i18n, zh: '打开夜醒救援', en: 'Open rescue'),
        onPrimary: () => _open(context, appState, const SleepNightRescuePage()),
        secondaryLabel: pickSleepText(i18n, zh: '离床判断', en: 'Leave-bed aid'),
        onSecondary: () => showSleepinessDecisionSheet(context),
        signals: <String>[
          pickSleepText(i18n, zh: '低刺激', en: 'Low stimulation'),
          pickSleepText(i18n, zh: '不看时间', en: 'No clock checking'),
        ],
      );
    }

    if (hour >= 20) {
      return _SleepHomeNextStep(
        eyebrow: pickSleepText(i18n, zh: '今晚一步', en: 'Tonight step'),
        title: pickSleepText(
          i18n,
          zh: '启动 8 分钟最低能量流程',
          en: 'Start the 8-minute tiny routine',
        ),
        body: pickSleepText(
          i18n,
          zh: '已经累的时候，不需要完整仪式。调暗、放下屏幕、停放一个念头，然后进床。',
          en: 'When you are already tired, skip the full ritual. Dim, park one thought, and get into bed.',
        ),
        icon: Icons.bedtime_rounded,
        accent: const Color(0xFF805C92),
        primaryLabel: pickSleepText(i18n, zh: '一键开始', en: 'Start tiny routine'),
        onPrimary: () => _startTinyRoutine(context, appState),
        secondaryLabel: pickSleepText(i18n, zh: '90 分钟参考', en: '90-min guide'),
        onSecondary: () => showSleepCyclePlannerSheet(context),
        signals: lowEnergySignals.isEmpty
            ? <String>[pickSleepText(i18n, zh: '8 分钟', en: '8 min')]
            : lowEnergySignals,
      );
    }

    if (hour < 11 && latestLog?.morningLightDone != true) {
      return _SleepHomeNextStep(
        eyebrow: pickSleepText(i18n, zh: '白天锚点', en: 'Day anchor'),
        title: pickSleepText(
          i18n,
          zh: '先补晨光，不纠结昨晚',
          en: 'Get morning light before replaying last night',
        ),
        body: pickSleepText(
          i18n,
          zh: '晨光和固定起床是最稳的节律锚点之一。先做这个，再决定要不要记录昨晚。',
          en: 'Morning light and stable wake time are strong rhythm anchors. Do this before overthinking last night.',
        ),
        icon: Icons.wb_sunny_rounded,
        accent: const Color(0xFFB08B33),
        primaryLabel: pickSleepText(
          i18n,
          zh: '开始晨光计时',
          en: 'Start light timer',
        ),
        onPrimary: () => showMorningLightTimerSheet(context),
        secondaryLabel: pickSleepText(i18n, zh: '记录昨晚', en: 'Log last night'),
        onSecondary: () => _open(context, appState, const SleepDailyLogPage()),
        signals: <String>[
          pickSleepText(i18n, zh: '10-20 分钟', en: '10-20 min'),
          if (!latestIsToday)
            pickSleepText(i18n, zh: '日志待补', en: 'Log pending'),
        ],
      );
    }

    if (latestLog == null || !latestIsToday) {
      return _SleepHomeNextStep(
        eyebrow: pickSleepText(i18n, zh: '补最小日志', en: 'Minimal log'),
        title: pickSleepText(
          i18n,
          zh: '只记 4 个数就够开始',
          en: 'Start with only four values',
        ),
        body: pickSleepText(
          i18n,
          zh: '先记录睡了多久、夜醒、晨间精神和关键因子。完整时间轴可以以后再补。',
          en: 'Log sleep time, awakenings, morning energy, and key factors first. Fill the full timeline later.',
        ),
        icon: Icons.edit_note_rounded,
        accent: const Color(0xFF4E74A8),
        primaryLabel: pickSleepText(i18n, zh: '去记录', en: 'Log now'),
        onPrimary: () => _open(context, appState, const SleepDailyLogPage()),
        secondaryLabel: pickSleepText(i18n, zh: '咖啡因线', en: 'Caffeine cutoff'),
        onSecondary: () => showCaffeineCutoffCalculatorSheet(context),
        signals: <String>[
          pickSleepText(i18n, zh: '低负担', en: 'Low effort'),
          pickSleepText(i18n, zh: '趋势优先', en: 'Trend first'),
        ],
      );
    }

    if (latestLog.caffeineAfterCutoff ||
        (profile.caffeineSensitive && hour >= 11 && hour < 17)) {
      return _SleepHomeNextStep(
        eyebrow: pickSleepText(i18n, zh: '今天先控变量', en: 'Control one variable'),
        title: pickSleepText(
          i18n,
          zh: '把最后一杯往前挪',
          en: 'Move the last caffeine earlier',
        ),
        body: pickSleepText(
          i18n,
          zh: '咖啡因是最容易先收紧的变量之一。先定今天的截止线，不等晚上再补救。',
          en: 'Caffeine is one of the cleanest variables to tighten. Set today’s cutoff before nighttime.',
        ),
        icon: Icons.local_cafe_rounded,
        accent: const Color(0xFF7E6A3A),
        primaryLabel: pickSleepText(i18n, zh: '计算截止线', en: 'Calculate cutoff'),
        onPrimary: () => showCaffeineCutoffCalculatorSheet(context),
        secondaryLabel: pickSleepText(i18n, zh: '白天节律', en: 'Day rhythm'),
        onSecondary: () => _open(context, appState, const SleepDayRhythmPage()),
        signals: <String>[
          if (latestLog.caffeineAfterCutoff)
            pickSleepText(i18n, zh: '昨晚超线', en: 'Late yesterday'),
          if (profile.caffeineSensitive)
            pickSleepText(i18n, zh: '咖啡因敏感', en: 'Sensitive'),
        ],
      );
    }

    return _SleepHomeNextStep(
      eyebrow: pickSleepText(i18n, zh: '下一周期', en: 'Next cycle'),
      title: pickSleepText(
        i18n,
        zh: '只选一件事维持到下周',
        en: 'Choose one thing to hold until next week',
      ),
      body: pickSleepText(
        i18n,
        zh: '睡眠改善最怕同时改太多。看一眼趋势，再决定下一周优先晨光、咖啡因、夜醒还是卧室。',
        en: 'Sleep work breaks down when everything changes at once. Check the trend and pick one next variable.',
      ),
      icon: Icons.insights_rounded,
      accent: const Color(0xFF6A7F9E),
      primaryLabel: pickSleepText(i18n, zh: '查看周报', en: 'Open report'),
      onPrimary: () => _open(context, appState, const SleepReportPage()),
      secondaryLabel: pickSleepText(i18n, zh: '今晚流程', en: 'Tonight routine'),
      onSecondary: () => _open(context, appState, const SleepWindDownPage()),
      signals: <String>[
        '${appState.sleepDailyLogs.length}/7',
        sleepTrackLabel(
          i18n,
          appState.sleepCurrentPlan?.track ?? SleepPlanTrack.observation,
        ),
      ],
    );
  }

  static bool _hasLoadedSleepData(AppState appState) {
    return appState.sleepProfile != null ||
        appState.sleepCurrentPlan != null ||
        appState.sleepDailyLogs.isNotEmpty ||
        appState.sleepThoughtEntries.isNotEmpty ||
        appState.sleepNightEvents.isNotEmpty ||
        appState.sleepRoutineTemplates.isNotEmpty ||
        appState.sleepProgramProgress != null;
  }

  static void _startTinyRoutine(BuildContext context, AppState appState) {
    appState.setSleepActiveRoutineTemplate('minimum_energy_shutdown');
    appState.startSleepRoutine('minimum_energy_shutdown');
    _open(context, appState, const SleepWindDownPage());
  }

  static void _open(BuildContext context, AppState appState, Widget page) {
    pushModuleRoute<void>(
      context,
      state: appState,
      moduleId: ModuleIds.toolboxSleepAssistant,
      builder: (_) => page,
    );
  }
}

class _SleepHomeNextStep {
  const _SleepHomeNextStep({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.icon,
    required this.accent,
    required this.primaryLabel,
    required this.onPrimary,
    required this.signals,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String eyebrow;
  final String title;
  final String body;
  final IconData icon;
  final Color accent;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final List<String> signals;
}

class _SleepNowPanel extends StatelessWidget {
  const _SleepNowPanel({required this.step});

  final _SleepHomeNextStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: <Color>[
                    step.accent.withValues(alpha: 0.20),
                    step.accent.withValues(alpha: 0.08),
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: Icon(step.icon, color: step.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: step.accent.withValues(alpha: 0.12),
                      border: Border.all(
                        color: step.accent.withValues(alpha: 0.20),
                      ),
                    ),
                    child: Text(
                      step.eyebrow,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: step.accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    step.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(step.body),
                ],
              ),
            ),
          ],
        ),
        if (step.signals.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: step.signals
                .where((item) => item.trim().isNotEmpty)
                .map(
                  (item) => Chip(
                    label: Text(item),
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(growable: false),
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            FilledButton.icon(
              onPressed: step.onPrimary,
              icon: Icon(step.icon),
              label: Text(step.primaryLabel),
            ),
            if (step.secondaryLabel != null && step.onSecondary != null)
              OutlinedButton(
                onPressed: step.onSecondary,
                child: Text(step.secondaryLabel!),
              ),
          ],
        ),
      ],
    );
  }
}

class _SleepAssistantLoadingState extends ConsumerWidget {
  const _SleepAssistantLoadingState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final i18n = AppI18n(appState.uiLanguage);
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: <Widget>[
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              pickSleepText(
                i18n,
                zh: '正在加载睡眠助手...',
                en: 'Loading sleep assistant...',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentPlanCard extends ConsumerWidget {
  const _CurrentPlanCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final i18n = AppI18n(appState.uiLanguage);
    final plan = appState.sleepCurrentPlan;
    final profile = appState.sleepProfile;

    if (plan == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                pickSleepText(i18n, zh: '还没有主线', en: 'No plan yet'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                pickSleepText(
                  i18n,
                  zh: '先做一次睡眠评估，系统会给出当前最值得先改的方向。',
                  en: 'Complete the assessment first to get a recommended direction.',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SleepAssessmentPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.fact_check_rounded),
                label: Text(
                  pickSleepText(i18n, zh: '开始评估', en: 'Start assessment'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              plan.title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(plan.summary),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                Chip(label: Text(sleepTrackLabel(i18n, plan.track))),
                if ((profile?.goal ?? '').trim().isNotEmpty)
                  Chip(label: Text(profile!.goal.trim())),
              ],
            ),
            const SizedBox(height: 12),
            ...plan.primaryActions.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.check_circle_outline_rounded, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item)),
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

class _LatestLogRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final i18n = AppI18n(appState.uiLanguage);
    final log = appState.latestSleepDailyLog;
    if (log == null) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surfaceContainerLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${pickSleepText(i18n, zh: '最近一晚', en: 'Latest night')} · ${sleepDateLabel(log.dateKey)}',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              Chip(
                label: Text(
                  '${pickSleepText(i18n, zh: '睡眠', en: 'Sleep')} ${sleepMinutesLabel(log.estimatedTotalSleepMinutes)}',
                ),
              ),
              Chip(
                label: Text(
                  '${pickSleepText(i18n, zh: '效率', en: 'Efficiency')} ${sleepPercentLabel(log.sleepEfficiency)}',
                ),
              ),
              Chip(
                label: Text(
                  '${pickSleepText(i18n, zh: '夜醒', en: 'Wake-ups')} ${log.nightWakeCount}',
                ),
              ),
              Chip(
                label: Text(
                  '${pickSleepText(i18n, zh: '精神', en: 'Energy')} ${sleepScoreLabel(log.morningEnergy)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SleepQuickActionCard extends StatelessWidget {
  const _SleepQuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = width < 760 ? width - 32 : 280.0;
    return SizedBox(
      width: cardWidth,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: accent),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
