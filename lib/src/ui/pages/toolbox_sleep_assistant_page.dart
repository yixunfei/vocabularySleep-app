import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/module_system/module_id.dart';
import '../../i18n/app_i18n.dart';
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

    return ToolboxToolPage(
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
                  title: pickSleepText(i18n, zh: '连续日志', en: 'Continuous log'),
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
                  title: pickSleepText(i18n, zh: '今晚流程', en: 'Tonight routine'),
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

  static void _open(BuildContext context, AppState appState, Widget page) {
    pushModuleRoute<void>(
      context,
      state: appState,
      moduleId: ModuleIds.toolboxSleepAssistant,
      builder: (_) => page,
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
