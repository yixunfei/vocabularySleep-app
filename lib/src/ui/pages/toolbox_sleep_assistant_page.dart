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
                title: i18n.t('toolbox.sleep.assist.locatorPlan'),
                subtitle: i18n.t('toolbox.sleep.assist.locatorPlanHint'),
                icon: Icons.route_rounded,
                onTap: () => jump(_planKey),
              ),
              _SleepLocatorItem(
                title: i18n.t('toolbox.sleep.assist.locatorLoop'),
                subtitle: i18n.t('toolbox.sleep.assist.locatorLoopHint'),
                icon: Icons.account_tree_rounded,
                onTap: () => jump(_loopKey),
              ),
              _SleepLocatorItem(
                title: i18n.t('toolbox.sleep.assist.locatorMore'),
                subtitle: i18n.t('toolbox.sleep.assist.locatorMoreHint'),
                icon: Icons.apps_rounded,
                onTap: () => jump(_moreKey),
              ),
              _SleepLocatorItem(
                title: i18n.t('toolbox.sleep.assist.locatorAdvice'),
                subtitle: i18n.t('toolbox.sleep.assist.locatorAdviceHint'),
                icon: Icons.tips_and_updates_rounded,
                onTap: () => jump(_adviceKey),
              ),
              _SleepLocatorItem(
                title: i18n.t('toolbox.sleep.assist.locatorTrend'),
                subtitle: i18n.t('toolbox.sleep.assist.locatorTrendHint'),
                icon: Icons.show_chart_rounded,
                onTap: () => jump(_trendKey),
              ),
              _SleepLocatorItem(
                title: i18n.t('toolbox.sleep.assist.locatorScience'),
                subtitle: i18n.t('toolbox.sleep.assist.locatorScienceHint'),
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
      SleepMorningQuickMood.same => i18n.t('toolbox.sleep.assist.morningSame'),
      SleepMorningQuickMood.worse => i18n.t('toolbox.sleep.assist.morningWorse'),
      SleepMorningQuickMood.better => i18n.t('toolbox.sleep.assist.morningBetter'),
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
      SleepMorningQuickMood.same => i18n.t('toolbox.sleep.assist.morningSavedSame'),
      SleepMorningQuickMood.worse => i18n.t('toolbox.sleep.assist.morningSavedWorse'),
      SleepMorningQuickMood.better => i18n.t('toolbox.sleep.assist.morningSavedBetter'),
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
          i18n.t('toolbox.sleep.assist.recentRescue'),
        );
        if (event.returnedToBedAt != null) {
          hints.add(i18n.t('toolbox.sleep.assist.leftBedRecorded'));
        }
      }
    }
    final routine = appState.sleepRoutineRunnerState;
    if (routine.activeTemplateId == 'minimum_energy_shutdown') {
      hints.add(i18n.t('toolbox.sleep.assist.tinyRoutineUsed'));
    }
    final latest = appState.latestSleepDailyLog;
    if (latest?.lateScreenExposure == true) {
      hints.add(i18n.t('toolbox.sleep.assist.lateScreenClue'));
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
        title: i18n.t('toolbox.sleep.core.title'),
        subtitle: i18n.t('toolbox.sleep.assist.subtitle'),
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
                    shortVersionLabel: i18n.t('toolbox.sleep.assist.shorterVersion'),
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
                        label: i18n.t('toolbox.sleep.assist.avgSleep'),
                        value: sleepMinutesLabel(avgSleep),
                      ),
                      ToolboxMetricCard(
                        label: i18n.t('toolbox.sleep.assist.avgEfficiency'),
                        value: sleepPercentLabel(avgEfficiency),
                      ),
                      ToolboxMetricCard(
                        label: i18n.t('toolbox.sleep.assist.morningEnergy'),
                        value: sleepScoreLabel(avgEnergy),
                      ),
                      if (appState.sleepCurrentPlan != null)
                        ToolboxMetricCard(
                          label: i18n.t('toolbox.sleep.assist.track'),
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
                    i18n.t('toolbox.sleep.assist.darkMode'),
                  ),
                  subtitle: Text(
                    i18n.t('toolbox.sleep.assist.darkModeHint'),
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
                  title: i18n.t('toolbox.sleep.assist.currentPlan'),
                  subtitle: i18n.t('toolbox.sleep.assist.currentPlanHint'),
                  icon: Icons.route_rounded,
                  child: const _CurrentPlanCard(),
                ),
              ),
              const SizedBox(height: 12),
              KeyedSubtree(
                key: _loopKey,
                child: _SleepCompactSection(
                  title: i18n.t('toolbox.sleep.assist.sleepLoop'),
                  subtitle: i18n.t('toolbox.sleep.assist.sleepLoopSub'),
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
                  title: i18n.t('toolbox.sleep.assist.moreActions'),
                  subtitle: i18n.t('toolbox.sleep.assist.moreActionsHint'),
                  icon: Icons.apps_rounded,
                  child: _SleepMoreActionsPanel(
                    i18n: i18n,
                    actions: _buildMoreSleepActions(context, appState, i18n),
                    tools: <Widget>[
                      SleepQuickToolButton(
                        title: i18n.t('toolbox.sleep.assist.whiteNoise'),
                        icon: Icons.graphic_eq_rounded,
                        onTap: () => showSleepWhiteNoiseSheet(context),
                      ),
                      SleepQuickToolButton(
                        title: i18n.t('toolbox.sleep.assist.morningLightTimer'),
                        icon: Icons.wb_sunny_rounded,
                        onTap: () => showMorningLightTimerSheet(context),
                      ),
                      SleepQuickToolButton(
                        title: i18n.t('toolbox.sleep.assist.caffeineCutoff'),
                        icon: Icons.local_cafe_rounded,
                        onTap: () => showCaffeineCutoffCalculatorSheet(context),
                      ),
                      SleepQuickToolButton(
                        title: i18n.t('toolbox.sleep.assist.min90'),
                        icon: Icons.more_time_rounded,
                        onTap: () => showSleepCyclePlannerSheet(context),
                      ),
                      SleepQuickToolButton(
                        title: i18n.t('toolbox.sleep.assist.breathing'),
                        icon: Icons.air_rounded,
                        onTap: () => _openToolboxModule(
                          context,
                          appState,
                          moduleId: ModuleIds.toolboxBreathing,
                          page: const BreathingToolPage(),
                        ),
                      ),
                      SleepQuickToolButton(
                        title: i18n.t('toolbox.sleep.assist.music'),
                        icon: Icons.spa_rounded,
                        onTap: () => _openToolboxModule(
                          context,
                          appState,
                          moduleId: ModuleIds.toolboxSoothingMusic,
                          page: const SoothingMusicV2Page(),
                        ),
                      ),
                      SleepQuickToolButton(
                        title: i18n.t('toolbox.sleep.assist.bowls'),
                        icon: Icons.blur_circular_rounded,
                        onTap: () => _openToolboxModule(
                          context,
                          appState,
                          moduleId: ModuleIds.toolboxSingingBowls,
                          page: const SingingBowlsToolPage(),
                        ),
                      ),
                      SleepQuickToolButton(
                        title: i18n.t('toolbox.sleep.assist.zenSand'),
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
                  title: i18n.t('toolbox.sleep.assist.directAdvice'),
                  subtitle: i18n.t('toolbox.sleep.assist.directAdviceSub'),
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
                  title: i18n.t('toolbox.sleep.assist.trend7'),
                  subtitle: i18n.t('toolbox.sleep.assist.trend7Sub'),
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
        title: i18n.t('toolbox.sleep.assist.setDirection'),
        body: i18n.t('toolbox.sleep.assist.setDirectionHint'),
        icon: Icons.fact_check_rounded,
        accent: const Color(0xFF517D6E),
        onTap: () => _open(context, appState, const SleepAssessmentPage()),
      ),
      _SleepLoopStep(
        label: '02',
        title: i18n.t('toolbox.sleep.assist.windDown'),
        body: i18n.t('toolbox.sleep.assist.windDownHint'),
        icon: Icons.nights_stay_rounded,
        accent: const Color(0xFF805C92),
        onTap: () => _open(context, appState, const SleepWindDownPage()),
      ),
      _SleepLoopStep(
        label: '03',
        title: i18n.t('toolbox.sleep.assist.nightRescue'),
        body: i18n.t('toolbox.sleep.assist.nightRescueHint'),
        icon: Icons.self_improvement_rounded,
        accent: const Color(0xFF9A6A52),
        onTap: () => _open(context, appState, const SleepNightRescuePage()),
      ),
      _SleepLoopStep(
        label: '04',
        title: i18n.t('toolbox.sleep.assist.dayAnchor'),
        body: i18n.t('toolbox.sleep.assist.dayAnchorHint'),
        icon: Icons.wb_sunny_rounded,
        accent: const Color(0xFFB08B33),
        onTap: () => _open(context, appState, const SleepDayRhythmPage()),
      ),
      _SleepLoopStep(
        label: '05',
        title: i18n.t('toolbox.sleep.assist.tinyLog'),
        body: i18n.t('toolbox.sleep.assist.tinyLogHint'),
        icon: Icons.edit_note_rounded,
        accent: const Color(0xFF4E74A8),
        onTap: () => _open(context, appState, const SleepDailyLogPage()),
      ),
      _SleepLoopStep(
        label: '06',
        title: i18n.t('toolbox.sleep.assist.weeklyReview'),
        body: i18n.t('toolbox.sleep.assist.weeklyReviewHint'),
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
        title: i18n.t('toolbox.sleep.assist.scienceCard'),
        subtitle: i18n.t('toolbox.sleep.assist.scienceCardSub'),
        icon: Icons.menu_book_rounded,
        accent: const Color(0xFF5D8F8B),
        onTap: () => _open(context, appState, const SleepSciencePage()),
      ),
      _SleepQuickActionCard(
        title: i18n.t('toolbox.sleep.assist.assessmentCard'),
        subtitle: i18n.t('toolbox.sleep.assist.assessmentCardSub'),
        icon: Icons.fact_check_rounded,
        accent: const Color(0xFF517D6E),
        onTap: () => _open(context, appState, const SleepAssessmentPage()),
      ),
      _SleepQuickActionCard(
        title: i18n.t('toolbox.sleep.assist.logCard'),
        subtitle: i18n.t('toolbox.sleep.assist.logCardSub'),
        icon: Icons.bedtime_rounded,
        accent: const Color(0xFF4E74A8),
        onTap: () => _open(context, appState, const SleepDailyLogPage()),
      ),
      _SleepQuickActionCard(
        title: i18n.t('toolbox.sleep.assist.routineCard'),
        subtitle: i18n.t('toolbox.sleep.assist.routineCardSub'),
        icon: Icons.nights_stay_rounded,
        accent: const Color(0xFF805C92),
        onTap: () => _open(context, appState, const SleepWindDownPage()),
      ),
      _SleepQuickActionCard(
        title: i18n.t('toolbox.sleep.assist.rescueCard'),
        subtitle: i18n.t('toolbox.sleep.assist.rescueCardSub'),
        icon: Icons.self_improvement_rounded,
        accent: const Color(0xFF9A6A52),
        onTap: () => _open(context, appState, const SleepNightRescuePage()),
      ),
      _SleepQuickActionCard(
        title: i18n.t('toolbox.sleep.assist.rhythmCard'),
        subtitle: i18n.t('toolbox.sleep.assist.rhythmCardSub'),
        icon: Icons.wb_sunny_rounded,
        accent: const Color(0xFFB08B33),
        onTap: () => _open(context, appState, const SleepDayRhythmPage()),
      ),
      _SleepQuickActionCard(
        title: i18n.t('toolbox.sleep.assist.reportCard'),
        subtitle: i18n.t('toolbox.sleep.assist.reportCardSub'),
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
        i18n.t('toolbox.sleep.assist.collect3'),
      if (profile?.hasRacingThoughts == true)
        i18n.t('toolbox.sleep.assist.busyMind'),
      if (latestLog?.lateScreenExposure == true)
        i18n.t('toolbox.sleep.assist.lateScreensTag'),
    ];

    if (profile == null) {
      return _SleepHomeNextStep(
        eyebrow: i18n.t('toolbox.sleep.assist.setDirectionBtn'),
        title: i18n.t('toolbox.sleep.assist.assessment2min'),
        body: i18n.t('toolbox.sleep.assist.assessmentIntro'),
        icon: Icons.fact_check_rounded,
        accent: const Color(0xFF517D6E),
        primaryLabel: i18n.t('toolbox.sleep.assist.startAssessment'),
        onPrimary: () => _open(context, appState, const SleepAssessmentPage()),
        secondaryLabel: i18n.t('toolbox.sleep.assist.rescueFirst'),
        onSecondary: () =>
            _open(context, appState, const SleepNightRescuePage()),
        signals: <String>[
          i18n.t('toolbox.sleep.assist.smallFirst'),
          i18n.t('toolbox.sleep.assist.autoPlan'),
        ],
      );
    }

    if (routine.isRunning || routine.isPaused) {
      return _SleepHomeNextStep(
        eyebrow: i18n.t('toolbox.sleep.assist.inProgress'),
        title: i18n.t('toolbox.sleep.assist.continueRoutine'),
        body: i18n.t('toolbox.sleep.assist.continueRoutineHint'),
        icon: Icons.play_circle_fill_rounded,
        accent: const Color(0xFF805C92),
        primaryLabel: i18n.t('toolbox.sleep.assist.backToRoutine'),
        onPrimary: () => _open(context, appState, const SleepWindDownPage()),
        secondaryLabel: i18n.t('toolbox.sleep.assist.nightRescue'),
        onSecondary: () =>
            _open(context, appState, const SleepNightRescuePage()),
        signals: <String>[
          sleepSecondsLabel(routine.remainingSeconds, i18n: i18n),
          i18n.t('toolbox.sleep.assist.noNewTask'),
        ],
      );
    }

    if (hour < 5) {
      return _SleepHomeNextStep(
        eyebrow: i18n.t('toolbox.sleep.assist.nightMode'),
        title: i18n.t('toolbox.sleep.assist.nightModeHint'),
        body: i18n.t('toolbox.sleep.assist.nightModeDesc'),
        icon: Icons.self_improvement_rounded,
        accent: const Color(0xFF9A6A52),
        primaryLabel: i18n.t('toolbox.sleep.assist.openRescue'),
        onPrimary: () => _open(context, appState, const SleepNightRescuePage()),
        secondaryLabel: i18n.t('toolbox.sleep.assist.leaveBedAid'),
        onSecondary: () => showSleepinessDecisionSheet(context),
        signals: <String>[
          i18n.t('toolbox.sleep.assist.lowStim'),
          i18n.t('toolbox.sleep.assist.noClock'),
        ],
      );
    }

    if (hour >= 20) {
      return _SleepHomeNextStep(
        eyebrow: i18n.t('toolbox.sleep.assist.tonightStep'),
        title: i18n.t('toolbox.sleep.assist.startTinyRoutine'),
        body: i18n.t('toolbox.sleep.assist.startTinyRoutineHint'),
        icon: Icons.bedtime_rounded,
        accent: const Color(0xFF805C92),
        primaryLabel: i18n.t('toolbox.sleep.assist.oneTapStart'),
        onPrimary: () => _startTinyRoutine(context, appState),
        secondaryLabel: i18n.t('toolbox.sleep.assist.min90Guide'),
        onSecondary: () => showSleepCyclePlannerSheet(context),
        signals: lowEnergySignals.isEmpty
            ? <String>[i18n.t('toolbox.sleep.assist.min8')]
            : lowEnergySignals,
      );
    }

    if (hour < 11 && latestLog?.morningLightDone != true) {
      return _SleepHomeNextStep(
        eyebrow: i18n.t('toolbox.sleep.assist.dayAnchorTitle'),
        title: i18n.t('toolbox.sleep.assist.dayAnchorDesc'),
        body: i18n.t('toolbox.sleep.assist.dayAnchorScenarioHint'),
        icon: Icons.wb_sunny_rounded,
        accent: const Color(0xFFB08B33),
        primaryLabel: i18n.t('toolbox.sleep.assist.startLightTimer'),
        onPrimary: () => showMorningLightTimerSheet(context),
        secondaryLabel: i18n.t('toolbox.sleep.assist.logLastNight'),
        onSecondary: () => _open(context, appState, const SleepDailyLogPage()),
        signals: <String>[
          i18n.t('toolbox.sleep.assist.min10to20'),
          if (!latestIsToday)
            i18n.t('toolbox.sleep.assist.logPending'),
        ],
      );
    }

    if (latestLog == null || !latestIsToday) {
      return _SleepHomeNextStep(
        eyebrow: i18n.t('toolbox.sleep.assist.minimalLog'),
        title: i18n.t('toolbox.sleep.assist.minimalLogHint'),
        body: i18n.t('toolbox.sleep.assist.minimalLogDesc'),
        icon: Icons.edit_note_rounded,
        accent: const Color(0xFF4E74A8),
        primaryLabel: i18n.t('toolbox.sleep.assist.logNow'),
        onPrimary: () => _open(context, appState, const SleepDailyLogPage()),
        secondaryLabel: i18n.t('toolbox.sleep.assist.caffeineLine'),
        onSecondary: () => showCaffeineCutoffCalculatorSheet(context),
        signals: <String>[
          i18n.t('toolbox.sleep.assist.lowEffort'),
          i18n.t('toolbox.sleep.assist.trendFirst'),
        ],
      );
    }

    if (latestLog.caffeineAfterCutoff ||
        (profile.caffeineSensitive && hour >= 11 && hour < 17)) {
      return _SleepHomeNextStep(
        eyebrow: i18n.t('toolbox.sleep.assist.controlOneVar'),
        title: i18n.t('toolbox.sleep.assist.controlOneVarHint'),
        body: i18n.t('toolbox.sleep.assist.controlOneVarDesc'),
        icon: Icons.local_cafe_rounded,
        accent: const Color(0xFF7E6A3A),
        primaryLabel: i18n.t('toolbox.sleep.assist.calcCutoff'),
        onPrimary: () => showCaffeineCutoffCalculatorSheet(context),
        secondaryLabel: i18n.t('toolbox.sleep.assist.dayRhythm'),
        onSecondary: () => _open(context, appState, const SleepDayRhythmPage()),
        signals: <String>[
          if (latestLog.caffeineAfterCutoff)
            i18n.t('toolbox.sleep.assist.lateYesterday'),
          if (profile.caffeineSensitive)
            i18n.t('toolbox.sleep.assist.caffeineSensitive'),
        ],
      );
    }

    return _SleepHomeNextStep(
      eyebrow: i18n.t('toolbox.sleep.assist.nextCycle'),
      title: i18n.t('toolbox.sleep.assist.nextCycleHint'),
      body: i18n.t('toolbox.sleep.assist.nextCycleDesc'),
      icon: Icons.insights_rounded,
      accent: const Color(0xFF6A7F9E),
      primaryLabel: i18n.t('toolbox.sleep.assist.openReport'),
      onPrimary: () => _open(context, appState, const SleepReportPage()),
      secondaryLabel: i18n.t('toolbox.sleep.assist.tonightRoutine'),
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
                i18n.t('toolbox.sleep.assist.snoringRisk'),
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
                    i18n.t('toolbox.sleep.assist.quickLocate'),
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
                    i18n.t('toolbox.sleep.assist.openDrawer'),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onScience,
                  icon: const Icon(Icons.menu_book_rounded),
                  label: Text(
                    i18n.t('toolbox.sleep.assist.scienceCard'),
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
          i18n.t('toolbox.sleep.assist.instantTools'),
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
        title: i18n.t('toolbox.sleep.assist.noLogsYet'),
        message: i18n.t('toolbox.sleep.assist.noLogsHint'),
        actionLabel: i18n.t('toolbox.sleep.assist.startLogging'),
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
              label: i18n.t('toolbox.sleep.assist.lateCaffeine'),
              value:
                  '${recentLogs.where((item) => item.caffeineAfterCutoff).length}/${recentLogs.length}',
            ),
            ToolboxMetricCard(
              label: i18n.t('toolbox.sleep.assist.lateScreens'),
              value:
                  '${recentLogs.where((item) => item.lateScreenExposure).length}/${recentLogs.length}',
            ),
            ToolboxMetricCard(
              label: i18n.t('toolbox.sleep.assist.morningLightDone'),
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
            i18n.t('toolbox.sleep.assist.jumpTitle'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            i18n.t('toolbox.sleep.assist.jumpDesc'),
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
                        i18n.t('toolbox.sleep.assist.noInputStarts'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        i18n.t('toolbox.sleep.assist.noInputStartsHint'),
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
                          i18n.t('toolbox.sleep.assist.imTired'),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: buttonWidth,
                      child: OutlinedButton.icon(
                        onPressed: onBedtimeScene,
                        icon: const Icon(Icons.nights_stay_rounded),
                        label: Text(
                          i18n.t('toolbox.sleep.assist.bedtimeScene'),
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
                      title: i18n.t('toolbox.sleep.assist.sleepNow'),
                      subtitle: i18n.t('toolbox.sleep.assist.tiny8min'),
                      icon: Icons.bedtime_rounded,
                      accent: const Color(0xFF805C92),
                      onTap: onSleepNow,
                    ),
                    _SleepSceneActionTile(
                      width: tileWidth,
                      title: i18n.t('toolbox.sleep.assist.awakeNow'),
                      subtitle: i18n.t('toolbox.sleep.assist.lowStimRescue'),
                      icon: Icons.self_improvement_rounded,
                      accent: const Color(0xFF9A6A52),
                      onTap: onNightWake,
                    ),
                    _SleepSceneActionTile(
                      width: tileWidth,
                      title: i18n.t('toolbox.sleep.assist.audioBed'),
                      subtitle: i18n.t('toolbox.sleep.assist.noiseOrRain'),
                      icon: Icons.graphic_eq_rounded,
                      accent: const Color(0xFF4F7F8F),
                      onTap: onWhiteNoise,
                    ),
                    _SleepSceneActionTile(
                      width: tileWidth,
                      title: i18n.t('toolbox.sleep.assist.logLater'),
                      subtitle: i18n.t('toolbox.sleep.assist.log30sec'),
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
            i18n.t('toolbox.sleep.assist.nightWakeBranches'),
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
              i18n.t('toolbox.sleep.core.loading'),
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
                i18n.t('toolbox.sleep.assist.noPlanYet'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                i18n.t('toolbox.sleep.assist.noPlanHint'),
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
                  i18n.t('toolbox.sleep.assist.startAssessment'),
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
            '${i18n.t('toolbox.sleep.assist.latestNight')} · ${sleepDateLabel(log.dateKey)}',
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
                  '${i18n.t('toolbox.sleep.assist.sleep')} ${sleepMinutesLabel(log.estimatedTotalSleepMinutes)}',
                ),
              ),
              Chip(
                label: Text(
                  '${i18n.t('toolbox.sleep.assist.efficiency')} ${sleepPercentLabel(log.sleepEfficiency)}',
                ),
              ),
              Chip(
                label: Text(
                  '${i18n.t('toolbox.sleep.assist.wakeUps')} ${log.nightWakeCount}',
                ),
              ),
              Chip(
                label: Text(
                  '${i18n.t('toolbox.sleep.assist.energy')} ${sleepScoreLabel(log.morningEnergy)}',
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
