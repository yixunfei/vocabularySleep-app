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
import 'sleep_assessment_page.dart';
import 'sleep_assistant_ui_support.dart';
import 'sleep_daily_log_page.dart';
import 'sleep_day_rhythm_page.dart';
import 'sleep_low_effort_widgets.dart';
import 'sleep_night_rescue_page.dart';
import 'sleep_quick_tools.dart';
import 'sleep_research_library.dart';
import 'sleep_report_page.dart';
import 'sleep_science_page.dart';
import 'sleep_wind_down_page.dart';
import 'toolbox_mind_tools.dart';
import 'toolbox_singing_bowls_tool.dart';
import 'toolbox_soothing_music_v2_page.dart';
import 'toolbox_tool_shell.dart';
import 'toolbox_zen_sand_tool.dart';

class ToolboxSleepAssistantPage extends ConsumerStatefulWidget {
  const ToolboxSleepAssistantPage({super.key});

  @override
  ConsumerState<ToolboxSleepAssistantPage> createState() =>
      _ToolboxSleepAssistantPageState();
}

class _ToolboxSleepAssistantPageState
    extends ConsumerState<ToolboxSleepAssistantPage> {
  final _planKey = GlobalKey();
  final _loopKey = GlobalKey();
  final _moreKey = GlobalKey();
  final _adviceKey = GlobalKey();
  final _trendKey = GlobalKey();

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

  void _scrollToKey(GlobalKey key) {
    final targetContext = key.currentContext;
    if (targetContext == null) {
      return;
    }
    Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  Future<void> _showHomeLocator(AppState appState, AppI18n i18n) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        void jump(GlobalKey key) {
          Navigator.of(sheetContext).pop();
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _scrollToKey(key),
          );
        }

        void open(Widget page) {
          Navigator.of(sheetContext).pop();
          _open(context, appState, page);
        }

        return sleepModuleTheme(
          context: sheetContext,
          enabled: appState.sleepDashboardState.sleepDarkModeEnabled,
          child: _SleepHomeLocatorSheet(
            i18n: i18n,
            items: <_SleepLocatorItem>[
              _SleepLocatorItem(
                title: pickSleepText(i18n, zh: '当前主线', en: 'Current plan'),
                subtitle: pickSleepText(
                  i18n,
                  zh: '查看本周优先方向',
                  en: 'Review this week priority',
                ),
                icon: Icons.route_rounded,
                onTap: () => jump(_planKey),
              ),
              _SleepLocatorItem(
                title: pickSleepText(i18n, zh: '闭环路线', en: 'Sleep loop'),
                subtitle: pickSleepText(
                  i18n,
                  zh: '评估到周报的完整路径',
                  en: 'Assessment to review path',
                ),
                icon: Icons.account_tree_rounded,
                onTap: () => jump(_loopKey),
              ),
              _SleepLocatorItem(
                title: pickSleepText(i18n, zh: '更多入口', en: 'More actions'),
                subtitle: pickSleepText(
                  i18n,
                  zh: '日志、流程、救援、节律',
                  en: 'Logs, routine, rescue, rhythm',
                ),
                icon: Icons.apps_rounded,
                onTap: () => jump(_moreKey),
              ),
              _SleepLocatorItem(
                title: pickSleepText(i18n, zh: '直接建议', en: 'Advice'),
                subtitle: pickSleepText(
                  i18n,
                  zh: '按当前数据给出下一步',
                  en: 'Next move from current data',
                ),
                icon: Icons.tips_and_updates_rounded,
                onTap: () => jump(_adviceKey),
              ),
              _SleepLocatorItem(
                title: pickSleepText(i18n, zh: '7 天趋势', en: '7-day trend'),
                subtitle: pickSleepText(
                  i18n,
                  zh: '快速看日志趋势',
                  en: 'Read log trend quickly',
                ),
                icon: Icons.show_chart_rounded,
                onTap: () => jump(_trendKey),
              ),
              _SleepLocatorItem(
                title: pickSleepText(i18n, zh: '科学睡眠', en: 'Sleep science'),
                subtitle: pickSleepText(
                  i18n,
                  zh: '打开精简手册',
                  en: 'Open the compact handbook',
                ),
                icon: Icons.menu_book_rounded,
                onTap: () => open(const SleepSciencePage()),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showTiredModeSheet(AppState appState, AppI18n i18n) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        void closeThen(VoidCallback action) {
          Navigator.of(sheetContext).pop();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              action();
            }
          });
        }

        return sleepModuleTheme(
          context: sheetContext,
          enabled: appState.sleepDashboardState.sleepDarkModeEnabled,
          child: SleepTiredModeSheet(
            i18n: i18n,
            onTinyRoutine: () =>
                closeThen(() => _startTinyRoutine(context, appState)),
            onNightRescue: () => closeThen(
              () => _open(context, appState, const SleepNightRescuePage()),
            ),
            onWhiteNoise: () =>
                closeThen(() => showSleepWhiteNoiseSheet(context)),
            onClose: () => Navigator.of(sheetContext).pop(),
          ),
        );
      },
    );
  }

  Future<void> _showBedtimeSceneSheet(AppState appState, AppI18n i18n) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        void closeThen(VoidCallback action) {
          Navigator.of(sheetContext).pop();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              action();
            }
          });
        }

        return sleepModuleTheme(
          context: sheetContext,
          enabled: appState.sleepDashboardState.sleepDarkModeEnabled,
          child: SleepBedtimeSceneSheet(
            i18n: i18n,
            onStartScene: () =>
                closeThen(() => _startBedtimeScene(context, appState)),
            onWhiteNoise: () =>
                closeThen(() => showSleepWhiteNoiseSheet(context)),
            onClose: () => Navigator.of(sheetContext).pop(),
          ),
        );
      },
    );
  }

  void _saveMorningQuickMood(
    AppState appState,
    AppI18n i18n,
    SleepMorningQuickMood mood,
  ) {
    final dateKey = todaySleepDateKey();
    final existing = appState.sleepDailyLogByDateKey(dateKey);
    final base = existing ?? SleepDailyLog(dateKey: dateKey);
    final energy = switch (mood) {
      SleepMorningQuickMood.same => 3,
      SleepMorningQuickMood.worse => 2,
      SleepMorningQuickMood.better => 4,
    };
    final sleepiness = switch (mood) {
      SleepMorningQuickMood.same => 3,
      SleepMorningQuickMood.worse => 4,
      SleepMorningQuickMood.better => 2,
    };
    final quickNote = switch (mood) {
      SleepMorningQuickMood.same => pickSleepText(
        i18n,
        zh: '晨间快记：差不多',
        en: 'Morning quick check: about the same',
      ),
      SleepMorningQuickMood.worse => pickSleepText(
        i18n,
        zh: '晨间快记：更差',
        en: 'Morning quick check: worse',
      ),
      SleepMorningQuickMood.better => pickSleepText(
        i18n,
        zh: '晨间快记：更好',
        en: 'Morning quick check: better',
      ),
    };
    final updated = base.copyWith(
      morningEnergy: energy,
      daytimeSleepiness: sleepiness,
      stressPeakLevel: mood == SleepMorningQuickMood.worse
          ? (base.stressPeakLevel ?? 4)
          : base.stressPeakLevel,
      worryLoadLevel: mood == SleepMorningQuickMood.worse
          ? (base.worryLoadLevel ?? 4)
          : base.worryLoadLevel,
      notes: _appendMorningQuickNote(base.notes, quickNote),
    );
    appState.saveSleepDailyLog(updated);
    final message = switch (mood) {
      SleepMorningQuickMood.same => pickSleepText(
        i18n,
        zh: '已记下：差不多。今天先稳住一个锚点就好。',
        en: 'Saved: about the same. Hold one anchor today.',
      ),
      SleepMorningQuickMood.worse => pickSleepText(
        i18n,
        zh: '已记下：更差。今天只做一件温和修复，不追责。',
        en: 'Saved: worse. Choose one gentle repair today.',
      ),
      SleepMorningQuickMood.better => pickSleepText(
        i18n,
        zh: '已记下：更好。保留做对的一件事就够了。',
        en: 'Saved: better. Keep the one thing that helped.',
      ),
    };
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  List<String> _buildMorningQuickContext(AppState appState, AppI18n i18n) {
    final hints = <String>[];
    if (appState.sleepNightEvents.isNotEmpty) {
      final event = appState.sleepNightEvents.first;
      final today = todaySleepDateKey();
      final yesterday = sleepDateKeyFromDateTime(
        DateTime.now().subtract(const Duration(days: 1)),
      );
      if (event.dateKey == today || event.dateKey == yesterday) {
        hints.add(
          pickSleepText(
            i18n,
            zh: '最近夜醒：${sleepNightModeLabel(i18n, event.mode)}',
            en: 'Recent rescue: ${sleepNightModeLabel(i18n, event.mode)}',
          ),
        );
        if (event.returnedToBedAt != null) {
          hints.add(pickSleepText(i18n, zh: '有离床记录', en: 'Left-bed noted'));
        }
      }
    }
    final routine = appState.sleepRoutineRunnerState;
    if (routine.activeTemplateId == 'minimum_energy_shutdown') {
      hints.add(pickSleepText(i18n, zh: '昨晚低能量流程', en: 'Tiny routine used'));
    }
    final latest = appState.latestSleepDailyLog;
    if (latest?.lateScreenExposure == true) {
      hints.add(pickSleepText(i18n, zh: '晚间看屏线索', en: 'Late-screen clue'));
    }
    return hints;
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
    final now = DateTime.now();
    final todayLog = appState.sleepDailyLogByDateKey(todaySleepDateKey());
    final showMorningQuickCheck = now.hour >= 5 && now.hour < 13;
    final morningQuickContext = _buildMorningQuickContext(appState, i18n);

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
                _SleepRiskWarningCard(i18n: i18n),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _SleepNowPanel(
                    step: nextStep,
                    supportGoal: SleepSupportGoalStrip(i18n: i18n),
                    onShortVersion: () => _showTiredModeSheet(appState, i18n),
                    shortVersionLabel: pickSleepText(
                      i18n,
                      zh: '更短版本',
                      en: 'Shorter version',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _SleepFrictionlessStartPanel(
                i18n: i18n,
                onTiredMode: () => _showTiredModeSheet(appState, i18n),
                onBedtimeScene: () => _showBedtimeSceneSheet(appState, i18n),
                onSleepNow: () => _startTinyRoutine(context, appState),
                onNightWake: () =>
                    _open(context, appState, const SleepNightRescuePage()),
                onNightWakeMode: (mode) => _open(
                  context,
                  appState,
                  SleepNightRescuePage(initialMode: mode),
                ),
                onWhiteNoise: () => showSleepWhiteNoiseSheet(context),
                onMinimalLog: () =>
                    _open(context, appState, const SleepDailyLogPage()),
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
              if (showMorningQuickCheck) ...<Widget>[
                const SizedBox(height: 12),
                SleepMorningQuickCheckPanel(
                  i18n: i18n,
                  hasQuickFeedback:
                      todayLog?.morningEnergy != null ||
                      todayLog?.daytimeSleepiness != null,
                  suggestedContext: morningQuickContext,
                  onMoodSelected: (mood) =>
                      _saveMorningQuickMood(appState, i18n, mood),
                  onOpenLog: () =>
                      _open(context, appState, const SleepDailyLogPage()),
                ),
              ],
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
              const SizedBox(height: 12),
              _SleepHomeUtilityPanel(
                i18n: i18n,
                onLocate: () => _showHomeLocator(appState, i18n),
                onScience: () =>
                    _open(context, appState, const SleepSciencePage()),
              ),
              const SizedBox(height: 12),
              KeyedSubtree(
                key: _planKey,
                child: _SleepCompactSection(
                  title: pickSleepText(i18n, zh: '当前主线', en: 'Current plan'),
                  subtitle: pickSleepText(
                    i18n,
                    zh: '本周只优先一件事，避免技巧堆叠。',
                    en: 'Keep only one priority this week.',
                  ),
                  icon: Icons.route_rounded,
                  child: const _CurrentPlanCard(),
                ),
              ),
              const SizedBox(height: 12),
              KeyedSubtree(
                key: _loopKey,
                child: _SleepCompactSection(
                  title: pickSleepText(i18n, zh: '睡眠闭环路线', en: 'Sleep loop'),
                  subtitle: pickSleepText(
                    i18n,
                    zh: '评估、睡前、夜醒、白天、日志、周报。',
                    en: 'Assessment, wind-down, rescue, day, log, review.',
                  ),
                  icon: Icons.account_tree_rounded,
                  child: _SleepLoopPanel(
                    steps: _buildSleepLoopSteps(context, appState, i18n),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              KeyedSubtree(
                key: _moreKey,
                child: _SleepCompactSection(
                  title: pickSleepText(i18n, zh: '更多入口与工具', en: 'More actions'),
                  subtitle: pickSleepText(
                    i18n,
                    zh: '需要时再展开，不挤占首屏。',
                    en: 'Expand only when needed.',
                  ),
                  icon: Icons.apps_rounded,
                  child: _SleepMoreActionsPanel(
                    i18n: i18n,
                    actions: _buildMoreSleepActions(context, appState, i18n),
                    tools: <Widget>[
                      SleepQuickToolButton(
                        title: pickSleepText(
                          i18n,
                          zh: '白噪音',
                          en: 'White noise',
                        ),
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
                      SleepQuickToolButton(
                        title: pickSleepText(i18n, zh: '90 分钟', en: '90 min'),
                        icon: Icons.more_time_rounded,
                        onTap: () => showSleepCyclePlannerSheet(context),
                      ),
                      SleepQuickToolButton(
                        title: pickSleepText(i18n, zh: '呼吸训练', en: 'Breathing'),
                        icon: Icons.air_rounded,
                        onTap: () => _openToolboxModule(
                          context,
                          appState,
                          moduleId: ModuleIds.toolboxBreathing,
                          page: const BreathingToolPage(),
                        ),
                      ),
                      SleepQuickToolButton(
                        title: pickSleepText(i18n, zh: '舒缓音乐', en: 'Music'),
                        icon: Icons.spa_rounded,
                        onTap: () => _openToolboxModule(
                          context,
                          appState,
                          moduleId: ModuleIds.toolboxSoothingMusic,
                          page: const SoothingMusicV2Page(),
                        ),
                      ),
                      SleepQuickToolButton(
                        title: pickSleepText(i18n, zh: '疗愈音钵', en: 'Bowls'),
                        icon: Icons.blur_circular_rounded,
                        onTap: () => _openToolboxModule(
                          context,
                          appState,
                          moduleId: ModuleIds.toolboxSingingBowls,
                          page: const SingingBowlsToolPage(),
                        ),
                      ),
                      SleepQuickToolButton(
                        title: pickSleepText(i18n, zh: '禅意沙盘', en: 'Zen sand'),
                        icon: Icons.landscape_rounded,
                        onTap: () => _openToolboxModule(
                          context,
                          appState,
                          moduleId: ModuleIds.toolboxZenSand,
                          page: const ZenSandStudioPage(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              KeyedSubtree(
                key: _adviceKey,
                child: _SleepCompactSection(
                  title: pickSleepText(i18n, zh: '直接建议', en: 'Direct advice'),
                  subtitle: pickSleepText(
                    i18n,
                    zh: '按当前记录给出少量下一步。',
                    en: 'A few next moves from current records.',
                  ),
                  icon: Icons.tips_and_updates_rounded,
                  child: SleepAdviceList(
                    items: advice.take(4).toList(growable: false),
                    i18n: i18n,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              KeyedSubtree(
                key: _trendKey,
                child: _SleepCompactSection(
                  title: pickSleepText(i18n, zh: '近 7 天趋势', en: '7-day trend'),
                  subtitle: pickSleepText(
                    i18n,
                    zh: '短趋势足够决定下一步。',
                    en: 'Short trend is enough for the next move.',
                  ),
                  icon: Icons.show_chart_rounded,
                  child: _SleepTrendSummary(
                    i18n: i18n,
                    recentLogs: recentLogs,
                    latestLog: latestLog,
                    onLog: () =>
                        _open(context, appState, const SleepDailyLogPage()),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<_SleepLoopStep> _buildSleepLoopSteps(
    BuildContext context,
    AppState appState,
    AppI18n i18n,
  ) {
    return <_SleepLoopStep>[
      _SleepLoopStep(
        label: '01',
        title: pickSleepText(i18n, zh: '定主线', en: 'Direction'),
        body: pickSleepText(
          i18n,
          zh: '用评估决定先改哪一个变量。',
          en: 'Use assessment to choose one variable.',
        ),
        icon: Icons.fact_check_rounded,
        accent: const Color(0xFF517D6E),
        onTap: () => _open(context, appState, const SleepAssessmentPage()),
      ),
      _SleepLoopStep(
        label: '02',
        title: pickSleepText(i18n, zh: '今晚收口', en: 'Wind down'),
        body: pickSleepText(
          i18n,
          zh: '直接进入当前模板或最低能量流程。',
          en: 'Open the routine or tiny flow.',
        ),
        icon: Icons.nights_stay_rounded,
        accent: const Color(0xFF805C92),
        onTap: () => _open(context, appState, const SleepWindDownPage()),
      ),
      _SleepLoopStep(
        label: '03',
        title: pickSleepText(i18n, zh: '夜醒救援', en: 'Rescue'),
        body: pickSleepText(
          i18n,
          zh: '半夜只做留床/离床判断。',
          en: 'Only decide stay or leave bed.',
        ),
        icon: Icons.self_improvement_rounded,
        accent: const Color(0xFF9A6A52),
        onTap: () => _open(context, appState, const SleepNightRescuePage()),
      ),
      _SleepLoopStep(
        label: '04',
        title: pickSleepText(i18n, zh: '白天锚点', en: 'Day anchor'),
        body: pickSleepText(
          i18n,
          zh: '晨光、咖啡因和午睡放一处。',
          en: 'Keep light, caffeine, and naps together.',
        ),
        icon: Icons.wb_sunny_rounded,
        accent: const Color(0xFFB08B33),
        onTap: () => _open(context, appState, const SleepDayRhythmPage()),
      ),
      _SleepLoopStep(
        label: '05',
        title: pickSleepText(i18n, zh: '最小日志', en: 'Tiny log'),
        body: pickSleepText(
          i18n,
          zh: '只补趋势需要的关键值。',
          en: 'Only fill the trend-critical values.',
        ),
        icon: Icons.edit_note_rounded,
        accent: const Color(0xFF4E74A8),
        onTap: () => _open(context, appState, const SleepDailyLogPage()),
      ),
      _SleepLoopStep(
        label: '06',
        title: pickSleepText(i18n, zh: '周报复盘', en: 'Review'),
        body: pickSleepText(
          i18n,
          zh: '下一周仍只选一件事。',
          en: 'Choose only one thing for next week.',
        ),
        icon: Icons.insights_rounded,
        accent: const Color(0xFF6A7F9E),
        onTap: () => _open(context, appState, const SleepReportPage()),
      ),
    ];
  }

  List<Widget> _buildMoreSleepActions(
    BuildContext context,
    AppState appState,
    AppI18n i18n,
  ) {
    return <Widget>[
      _SleepQuickActionCard(
        title: pickSleepText(i18n, zh: '科学睡眠', en: 'Sleep science'),
        subtitle: pickSleepText(
          i18n,
          zh: '精简手册和风险边界。',
          en: 'Compact handbook and safety edges.',
        ),
        icon: Icons.menu_book_rounded,
        accent: const Color(0xFF5D8F8B),
        onTap: () => _open(context, appState, const SleepSciencePage()),
      ),
      _SleepQuickActionCard(
        title: pickSleepText(i18n, zh: '睡眠评估', en: 'Assessment'),
        subtitle: pickSleepText(
          i18n,
          zh: '识别问题类型和风险线索。',
          en: 'Assess issues and risk signals.',
        ),
        icon: Icons.fact_check_rounded,
        accent: const Color(0xFF517D6E),
        onTap: () => _open(context, appState, const SleepAssessmentPage()),
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
        onTap: () => _open(context, appState, const SleepDailyLogPage()),
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
        onTap: () => _open(context, appState, const SleepWindDownPage()),
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
        onTap: () => _open(context, appState, const SleepNightRescuePage()),
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
        onTap: () => _open(context, appState, const SleepDayRhythmPage()),
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
        onTap: () => _open(context, appState, const SleepReportPage()),
      ),
    ];
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

  static String _appendMorningQuickNote(String? notes, String entry) {
    final normalized = notes?.trim();
    if (normalized == null || normalized.isEmpty) {
      return entry;
    }
    if (normalized.contains(entry)) {
      return normalized;
    }
    return '$normalized\n$entry';
  }

  static void _startTinyRoutine(BuildContext context, AppState appState) {
    appState.setSleepActiveRoutineTemplate('minimum_energy_shutdown');
    appState.startSleepRoutine('minimum_energy_shutdown');
    _open(context, appState, const SleepWindDownPage());
  }

  static void _startBedtimeScene(BuildContext context, AppState appState) {
    if (!appState.sleepDashboardState.sleepDarkModeEnabled) {
      appState.updateSleepDashboardState(
        appState.sleepDashboardState.copyWith(sleepDarkModeEnabled: true),
      );
    }
    _startTinyRoutine(context, appState);
  }

  static void _open(BuildContext context, AppState appState, Widget page) {
    pushModuleRoute<void>(
      context,
      state: appState,
      moduleId: ModuleIds.toolboxSleepAssistant,
      builder: (_) => page,
    );
  }

  static void _openToolboxModule(
    BuildContext context,
    AppState appState, {
    required String moduleId,
    required Widget page,
  }) {
    pushModuleRoute<void>(
      context,
      state: appState,
      moduleId: moduleId,
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

class _SleepRiskWarningCard extends StatelessWidget {
  const _SleepRiskWarningCard({required this.i18n});

  final AppI18n i18n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.errorContainer,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.onErrorContainer.withValues(alpha: 0.22),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              Icons.health_and_safety_rounded,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                pickSleepText(
                  i18n,
                  zh: '当前存在中高水平打鼾风险线索。工具可以继续帮你做记录和行为调整，但如果伴随憋醒、巨大鼾声或白天困到影响功能，建议尽快做进一步评估。',
                  en: 'Elevated snoring risk is present. Behavior tools can still help, but loud snoring, gasping, or severe daytime sleepiness should be assessed further.',
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SleepNowPanel extends StatelessWidget {
  const _SleepNowPanel({
    required this.step,
    required this.supportGoal,
    required this.onShortVersion,
    required this.shortVersionLabel,
  });

  final _SleepHomeNextStep step;
  final Widget supportGoal;
  final VoidCallback onShortVersion;
  final String shortVersionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = sleepReadableAccent(context, step.accent);
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
                    accent.withValues(alpha: 0.22),
                    accent.withValues(alpha: 0.08),
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: Icon(step.icon, color: accent),
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
                      color: accent.withValues(alpha: 0.13),
                      border: Border.all(color: accent.withValues(alpha: 0.24)),
                    ),
                    child: Text(
                      step.eyebrow,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: accent,
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
                  Text(
                    step.body,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        supportGoal,
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
            TextButton.icon(
              onPressed: onShortVersion,
              icon: const Icon(Icons.keyboard_double_arrow_down_rounded),
              label: Text(shortVersionLabel),
            ),
          ],
        ),
      ],
    );
  }
}

class _SleepHomeUtilityPanel extends StatelessWidget {
  const _SleepHomeUtilityPanel({
    required this.i18n,
    required this.onLocate,
    required this.onScience,
  });

  final AppI18n i18n;
  final VoidCallback onLocate;
  final VoidCallback onScience;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.near_me_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    pickSleepText(i18n, zh: '快速定位', en: 'Quick locate'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                FilledButton.tonalIcon(
                  onPressed: onLocate,
                  icon: const Icon(Icons.menu_open_rounded),
                  label: Text(
                    pickSleepText(i18n, zh: '打开定位抽屉', en: 'Open drawer'),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onScience,
                  icon: const Icon(Icons.menu_book_rounded),
                  label: Text(
                    pickSleepText(i18n, zh: '科学睡眠', en: 'Sleep science'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SleepCompactSection extends StatelessWidget {
  const _SleepCompactSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          maintainState: true,
          leading: Icon(icon, color: theme.colorScheme.primary),
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          children: <Widget>[child],
        ),
      ),
    );
  }
}

class _SleepMoreActionsPanel extends StatelessWidget {
  const _SleepMoreActionsPanel({
    required this.i18n,
    required this.actions,
    required this.tools,
  });

  final AppI18n i18n;
  final List<Widget> actions;
  final List<Widget> tools;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(spacing: 12, runSpacing: 12, children: actions),
        const SizedBox(height: 14),
        Text(
          pickSleepText(i18n, zh: '即时工具', en: 'Instant tools'),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 10, runSpacing: 10, children: tools),
      ],
    );
  }
}

class _SleepTrendSummary extends StatelessWidget {
  const _SleepTrendSummary({
    required this.i18n,
    required this.recentLogs,
    required this.latestLog,
    required this.onLog,
  });

  final AppI18n i18n;
  final List<SleepDailyLog> recentLogs;
  final SleepDailyLog? latestLog;
  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    if (recentLogs.isEmpty) {
      return EmptyStateView(
        icon: Icons.hotel_rounded,
        title: pickSleepText(i18n, zh: '还没有睡眠日志', en: 'No sleep logs yet'),
        message: pickSleepText(
          i18n,
          zh: '先从连续日志开始，至少记录 3 到 7 天，趋势和建议才会更可靠。',
          en: 'Start the continuous log and collect at least 3 to 7 days first.',
        ),
        actionLabel: pickSleepText(i18n, zh: '去记录', en: 'Start logging'),
        onAction: onLog,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (latestLog != null) _LatestLogRow(),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            ToolboxMetricCard(
              label: pickSleepText(i18n, zh: '晚咖啡因', en: 'Late caffeine'),
              value:
                  '${recentLogs.where((item) => item.caffeineAfterCutoff).length}/${recentLogs.length}',
            ),
            ToolboxMetricCard(
              label: pickSleepText(i18n, zh: '晚间看屏', en: 'Late screens'),
              value:
                  '${recentLogs.where((item) => item.lateScreenExposure).length}/${recentLogs.length}',
            ),
            ToolboxMetricCard(
              label: pickSleepText(i18n, zh: '晨光完成', en: 'Morning light'),
              value:
                  '${recentLogs.where((item) => item.morningLightDone).length}/${recentLogs.length}',
            ),
          ],
        ),
      ],
    );
  }
}

class _SleepLocatorItem {
  const _SleepLocatorItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
}

class _SleepHomeLocatorSheet extends StatelessWidget {
  const _SleepHomeLocatorSheet({required this.i18n, required this.items});

  final AppI18n i18n;
  final List<_SleepLocatorItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
        children: <Widget>[
          Text(
            pickSleepText(i18n, zh: '跳到指定位置', en: 'Jump to'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            pickSleepText(
              i18n,
              zh: '首页内容已压缩为折叠区，需要哪一块就直接跳过去。',
              en: 'The home page is compressed into sections. Jump to what you need.',
            ),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                tileColor: theme.colorScheme.surfaceContainerLow,
                leading: Icon(item.icon, color: theme.colorScheme.primary),
                title: Text(
                  item.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text(item.subtitle),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: item.onTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SleepFrictionlessStartPanel extends StatelessWidget {
  const _SleepFrictionlessStartPanel({
    required this.i18n,
    required this.onTiredMode,
    required this.onBedtimeScene,
    required this.onSleepNow,
    required this.onNightWake,
    required this.onNightWakeMode,
    required this.onWhiteNoise,
    required this.onMinimalLog,
  });

  final AppI18n i18n;
  final VoidCallback onTiredMode;
  final VoidCallback onBedtimeScene;
  final VoidCallback onSleepNow;
  final VoidCallback onNightWake;
  final ValueChanged<SleepNightRescueMode> onNightWakeMode;
  final VoidCallback onWhiteNoise;
  final VoidCallback onMinimalLog;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.bolt_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        pickSleepText(
                          i18n,
                          zh: '免输入场景启动',
                          en: 'No-input starts',
                        ),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pickSleepText(
                          i18n,
                          zh: '疲惫时不做表单，先用场景按钮进入下一步。',
                          en: 'When tired, enter the next step from a scene button.',
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final buttonWidth = constraints.maxWidth < 420
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 10) / 2;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    SizedBox(
                      width: buttonWidth,
                      child: FilledButton.tonalIcon(
                        onPressed: onTiredMode,
                        icon: const Icon(Icons.battery_1_bar_rounded),
                        label: Text(
                          pickSleepText(
                            i18n,
                            zh: '我现在很累',
                            en: 'I am tired now',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: buttonWidth,
                      child: OutlinedButton.icon(
                        onPressed: onBedtimeScene,
                        icon: const Icon(Icons.nights_stay_rounded),
                        label: Text(
                          pickSleepText(
                            i18n,
                            zh: '睡前一键场景',
                            en: 'Bedtime scene',
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            _SleepNightBranchStrip(i18n: i18n, onMode: onNightWakeMode),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final tileWidth = constraints.maxWidth < 440
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 10) / 2;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    _SleepSceneActionTile(
                      width: tileWidth,
                      title: pickSleepText(i18n, zh: '现在就睡', en: 'Sleep now'),
                      subtitle: pickSleepText(
                        i18n,
                        zh: '8 分钟低能量流程',
                        en: '8-minute tiny routine',
                      ),
                      icon: Icons.bedtime_rounded,
                      accent: const Color(0xFF805C92),
                      onTap: onSleepNow,
                    ),
                    _SleepSceneActionTile(
                      width: tileWidth,
                      title: pickSleepText(i18n, zh: '半夜醒了', en: 'Awake now'),
                      subtitle: pickSleepText(
                        i18n,
                        zh: '低刺激救援脚本',
                        en: 'Low-stim rescue',
                      ),
                      icon: Icons.self_improvement_rounded,
                      accent: const Color(0xFF9A6A52),
                      onTap: onNightWake,
                    ),
                    _SleepSceneActionTile(
                      width: tileWidth,
                      title: pickSleepText(i18n, zh: '放背景音', en: 'Audio bed'),
                      subtitle: pickSleepText(
                        i18n,
                        zh: '白噪音或雨声',
                        en: 'Noise or rain',
                      ),
                      icon: Icons.graphic_eq_rounded,
                      accent: const Color(0xFF4F7F8F),
                      onTap: onWhiteNoise,
                    ),
                    _SleepSceneActionTile(
                      width: tileWidth,
                      title: pickSleepText(i18n, zh: '明早补记', en: 'Log later'),
                      subtitle: pickSleepText(
                        i18n,
                        zh: '30 秒最小日志',
                        en: '30-second log',
                      ),
                      icon: Icons.edit_note_rounded,
                      accent: const Color(0xFF4E74A8),
                      onTap: onMinimalLog,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SleepSceneActionTile extends StatelessWidget {
  const _SleepSceneActionTile({
    required this.width,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final double width;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedAccent = sleepReadableAccent(context, accent);
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: resolvedAccent.withValues(alpha: 0.10),
              border: Border.all(color: resolvedAccent.withValues(alpha: 0.24)),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: resolvedAccent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: resolvedAccent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SleepNightBranchStrip extends StatelessWidget {
  const _SleepNightBranchStrip({required this.i18n, required this.onMode});

  final AppI18n i18n;
  final ValueChanged<SleepNightRescueMode> onMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modes = <SleepNightRescueMode>[
      SleepNightRescueMode.fullyAwake,
      SleepNightRescueMode.racingThoughts,
      SleepNightRescueMode.bodyActivated,
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: theme.colorScheme.surfaceContainerLow,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            pickSleepText(i18n, zh: '夜醒分支', en: 'Night-wake branches'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: modes
                .map(
                  (mode) => ActionChip(
                    avatar: Icon(_nightBranchIcon(mode), size: 18),
                    label: Text(sleepNightModeLabel(i18n, mode)),
                    onPressed: () => onMode(mode),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }

  IconData _nightBranchIcon(SleepNightRescueMode mode) {
    return switch (mode) {
      SleepNightRescueMode.racingThoughts => Icons.psychology_alt_rounded,
      SleepNightRescueMode.bodyActivated => Icons.air_rounded,
      SleepNightRescueMode.temperatureDiscomfort => Icons.thermostat_rounded,
      SleepNightRescueMode.briefAwakening => Icons.dark_mode_rounded,
      SleepNightRescueMode.fullyAwake => Icons.self_improvement_rounded,
    };
  }
}

class _SleepLoopStep {
  const _SleepLoopStep({
    required this.label,
    required this.title,
    required this.body,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final String title;
  final String body;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
}

class _SleepLoopPanel extends StatelessWidget {
  const _SleepLoopPanel({required this.steps});

  final List<_SleepLoopStep> steps;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tileWidth = constraints.maxWidth < 520
                ? constraints.maxWidth
                : (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: steps
                  .map(
                    (step) => _SleepLoopStepTile(width: tileWidth, step: step),
                  )
                  .toList(growable: false),
            );
          },
        ),
      ),
    );
  }
}

class _SleepLoopStepTile extends StatelessWidget {
  const _SleepLoopStepTile({required this.width, required this.step});

  final double width;
  final _SleepLoopStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = sleepReadableAccent(context, step.accent);
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: step.onTap,
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: theme.colorScheme.surfaceContainerLow,
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: accent.withValues(alpha: 0.14),
                  ),
                  alignment: Alignment.center,
                  child: Icon(step.icon, color: accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        step.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        step.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
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
    final resolvedAccent = sleepReadableAccent(context, accent);
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
                    color: resolvedAccent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: resolvedAccent),
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
