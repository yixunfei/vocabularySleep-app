import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../models/sleep_daily_log.dart';
import '../../models/sleep_guidance.dart';
import '../../models/sleep_profile.dart';
import '../../state/app_state.dart';
import 'sleep_assistant_ui_support.dart';

const String sleepTopicMorningLight = 'morning_light';
const String sleepTopicCaffeineCutoff = 'caffeine_cutoff';
const String sleepTopicDigitalSunset = 'digital_sunset';
const String sleepTopicStimulusControl = 'stimulus_control';
const String sleepTopicWorryUnload = 'worry_unload';
const String sleepTopicBedroomSanctuary = 'bedroom_sanctuary';
const String sleepTopicBodyTemperature = 'body_temperature';
const String sleepTopicNapStrategy = 'nap_strategy';
const String sleepTopicWhiteNoise = 'white_noise';
const String sleepTopicRiskFlags = 'risk_flags';
const String sleepTopicSleepDiary = 'sleep_diary';
const String sleepTopicSleepCycles = 'sleep_cycles';

List<SleepResearchTopic> buildSleepResearchTopics(AppI18n i18n) {
  final topics = <SleepResearchTopic>[
    SleepResearchTopic(
      id: sleepTopicMorningLight,
      title: i18n.t('toolbox.sleep.library.topic.light.title'),
      summary: i18n.t('toolbox.sleep.library.topic.light.summary'),
      detail: i18n.t('toolbox.sleep.library.topic.light.detail'),
      actionHint: i18n.t('toolbox.sleep.library.topic.light.action_hint'),
      sources: <SleepResearchSource>[
        SleepResearchSource(
          bookTitle: '《这本书能让你睡得好》',
          relevance: i18n.t('toolbox.sleep.library.source.light_1'),
        ),
        SleepResearchSource(
          bookTitle: '《斯坦福的高效睡眠法》',
          relevance: i18n.t('toolbox.sleep.library.source.light_2'),
        ),
        SleepResearchSource(
          bookTitle: '《好好休息：精力充沛的科学管理方法》',
          relevance: i18n.t('toolbox.sleep.library.source.light_3'),
        ),
      ],
    ),
    SleepResearchTopic(
      id: sleepTopicCaffeineCutoff,
      title: i18n.t('toolbox.sleep.library.topic.caffeine.title'),
      summary: i18n.t('toolbox.sleep.library.topic.caffeine.summary'),
      detail: i18n.t('toolbox.sleep.library.topic.caffeine.detail'),
      actionHint: i18n.t('toolbox.sleep.library.topic.caffeine.action_hint'),
      sources: <SleepResearchSource>[
        SleepResearchSource(
          bookTitle: '《这本书能让你睡得好》',
          relevance: i18n.t('toolbox.sleep.library.source.caffeine_1'),
        ),
        SleepResearchSource(
          bookTitle: '《斯坦福的高效睡眠法》',
          relevance: i18n.t('toolbox.sleep.library.source.caffeine_2'),
        ),
        SleepResearchSource(
          bookTitle: '《好好休息：精力充沛的科学管理方法》',
          relevance: i18n.t('toolbox.sleep.library.source.caffeine_3'),
        ),
      ],
    ),
    SleepResearchTopic(
      id: sleepTopicDigitalSunset,
      title: i18n.t('toolbox.sleep.library.topic.digital_sunset.title'),
      summary: i18n.t('toolbox.sleep.library.topic.digital_sunset.summary'),
      detail: i18n.t('toolbox.sleep.library.topic.digital_sunset.detail'),
      actionHint: i18n.t('toolbox.sleep.library.topic.digital_sunset.action_hint'),
      sources: <SleepResearchSource>[
        SleepResearchSource(
          bookTitle: '《这本书能让你睡得好》',
          relevance: i18n.t('toolbox.sleep.library.source.digital_sunset_1'),
        ),
        SleepResearchSource(
          bookTitle: '《浓缩睡眠法：如何睡少又睡好》',
          relevance: i18n.t('toolbox.sleep.library.source.digital_sunset_2'),
        ),
        SleepResearchSource(
          bookTitle: '《干掉失眠：让你睡个好觉的心理疗法》',
          relevance: i18n.t('toolbox.sleep.library.source.digital_sunset_3'),
        ),
      ],
    ),
    SleepResearchTopic(
      id: sleepTopicStimulusControl,
      title: i18n.t('toolbox.sleep.library.topic.stimulus_control.title'),
      summary: i18n.t('toolbox.sleep.library.topic.stimulus_control.summary'),
      detail: i18n.t('toolbox.sleep.library.topic.stimulus_control.detail'),
      actionHint: i18n.t('toolbox.sleep.library.topic.stimulus_control.action_hint'),
      sources: <SleepResearchSource>[
        SleepResearchSource(
          bookTitle: '《干掉失眠：让你睡个好觉的心理疗法》',
          relevance: i18n.t('toolbox.sleep.library.source.stimulus_control_1'),
        ),
        SleepResearchSource(
          bookTitle: '《这本书能让你睡得好》',
          relevance: i18n.t('toolbox.sleep.library.source.stimulus_control_2'),
        ),
      ],
    ),
  ];
  topics.addAll(<SleepResearchTopic>[
    SleepResearchTopic(
      id: sleepTopicSleepDiary,
      title: i18n.t('toolbox.sleep.library.topic.diary_trends.title'),
      summary: i18n.t('toolbox.sleep.library.topic.diary_trends.summary'),
      detail: i18n.t('toolbox.sleep.library.topic.diary_trends.detail'),
      actionHint: i18n.t('toolbox.sleep.library.topic.diary_trends.action_hint'),
      sources: <SleepResearchSource>[
        SleepResearchSource(
          bookTitle: '《睡眠红宝书》',
          relevance: i18n.t('toolbox.sleep.library.source.diary_trends_1'),
        ),
        SleepResearchSource(
          bookTitle: '《干掉失眠：让你睡个好觉的心理疗法》',
          relevance: i18n.t('toolbox.sleep.library.source.diary_trends_2'),
        ),
        SleepResearchSource(
          bookTitle: '《关灯就睡觉：哈佛医学院高效睡眠指南》',
          relevance: i18n.t('toolbox.sleep.library.source.diary_trends_3'),
        ),
      ],
    ),
    SleepResearchTopic(
      id: sleepTopicSleepCycles,
      title: i18n.t('toolbox.sleep.library.topic.sleep_cycles.title'),
      summary: i18n.t('toolbox.sleep.library.topic.sleep_cycles.summary'),
      detail: i18n.t('toolbox.sleep.library.topic.sleep_cycles.detail'),
      actionHint: i18n.t('toolbox.sleep.library.topic.sleep_cycles.action_hint'),
      sources: <SleepResearchSource>[
        SleepResearchSource(
          bookTitle: '《世界第一的 R90 高效睡眠法》',
          relevance: i18n.t('toolbox.sleep.library.source.sleep_cycles_1'),
        ),
        SleepResearchSource(
          bookTitle: '《睡眠的秘密世界》',
          relevance: i18n.t('toolbox.sleep.library.source.sleep_cycles_2'),
        ),
        SleepResearchSource(
          bookTitle: '《睡眠红宝书》',
          relevance: i18n.t('toolbox.sleep.library.source.sleep_cycles_3'),
        ),
      ],
    ),
    SleepResearchTopic(
      id: sleepTopicWorryUnload,
      title: i18n.t('toolbox.sleep.library.topic.worry_unload.title'),
      summary: i18n.t('toolbox.sleep.library.topic.worry_unload.summary'),
      detail: i18n.t('toolbox.sleep.library.topic.worry_unload.detail'),
      actionHint: i18n.t('toolbox.sleep.library.topic.worry_unload.action_hint'),
      sources: <SleepResearchSource>[
        SleepResearchSource(
          bookTitle: '《干掉失眠：让你睡个好觉的心理疗法》',
          relevance: i18n.t('toolbox.sleep.library.source.worry_unload_1'),
        ),
        SleepResearchSource(
          bookTitle: '《浓缩睡眠法：如何睡少又睡好》',
          relevance: i18n.t('toolbox.sleep.library.source.worry_unload_2'),
        ),
      ],
    ),
    SleepResearchTopic(
      id: sleepTopicBedroomSanctuary,
      title: i18n.t('toolbox.sleep.library.topic.bedroom.title'),
      summary: i18n.t('toolbox.sleep.library.topic.bedroom.summary'),
      detail: i18n.t('toolbox.sleep.library.topic.bedroom.detail'),
      actionHint: i18n.t('toolbox.sleep.library.topic.bedroom.action_hint'),
      sources: <SleepResearchSource>[
        SleepResearchSource(
          bookTitle: '《这本书能让你睡得好》',
          relevance: i18n.t('toolbox.sleep.library.source.bedroom_1'),
        ),
        SleepResearchSource(
          bookTitle: '《斯坦福的高效睡眠法》',
          relevance: i18n.t('toolbox.sleep.library.source.bedroom_2'),
        ),
        SleepResearchSource(
          bookTitle: '《浓缩睡眠法：如何睡少又睡好》',
          relevance: i18n.t('toolbox.sleep.library.source.bedroom_3'),
        ),
      ],
    ),
    SleepResearchTopic(
      id: sleepTopicBodyTemperature,
      title: i18n.t('toolbox.sleep.library.topic.temperature.title'),
      summary: i18n.t('toolbox.sleep.library.topic.temperature.summary'),
      detail: i18n.t('toolbox.sleep.library.topic.temperature.detail'),
      actionHint: i18n.t('toolbox.sleep.library.topic.temperature.action_hint'),
      sources: <SleepResearchSource>[
        SleepResearchSource(
          bookTitle: '《斯坦福的高效睡眠法》',
          relevance: i18n.t('toolbox.sleep.library.source.temperature_1'),
        ),
        SleepResearchSource(
          bookTitle: '《浓缩睡眠法：如何睡少又睡好》',
          relevance: i18n.t('toolbox.sleep.library.source.temperature_2'),
        ),
      ],
    ),
    SleepResearchTopic(
      id: sleepTopicNapStrategy,
      title: i18n.t('toolbox.sleep.library.topic.nap.title'),
      summary: i18n.t('toolbox.sleep.library.topic.nap.summary'),
      detail: i18n.t('toolbox.sleep.library.topic.nap.detail'),
      actionHint: i18n.t('toolbox.sleep.library.topic.nap.action_hint'),
      sources: <SleepResearchSource>[
        SleepResearchSource(
          bookTitle: '《浓缩睡眠法：如何睡少又睡好》',
          relevance: i18n.t('toolbox.sleep.library.source.nap_1'),
        ),
        SleepResearchSource(
          bookTitle: '《斯坦福的高效睡眠法》',
          relevance: i18n.t('toolbox.sleep.library.source.nap_2'),
        ),
      ],
    ),
    SleepResearchTopic(
      id: sleepTopicWhiteNoise,
      title: i18n.t('toolbox.sleep.library.topic.white_noise.title'),
      summary: i18n.t('toolbox.sleep.library.topic.white_noise.summary'),
      detail: i18n.t('toolbox.sleep.library.topic.white_noise.detail'),
      actionHint: i18n.t('toolbox.sleep.library.topic.white_noise.action_hint'),
      sources: <SleepResearchSource>[
        SleepResearchSource(
          bookTitle: '《这本书能让你睡得好》',
          relevance: i18n.t('toolbox.sleep.library.source.white_noise_1'),
        ),
        SleepResearchSource(
          bookTitle: '《斯坦福的高效睡眠法》',
          relevance: i18n.t('toolbox.sleep.library.source.white_noise_2'),
        ),
      ],
    ),
    SleepResearchTopic(
      id: sleepTopicRiskFlags,
      title: i18n.t('toolbox.sleep.library.topic.red_flags.title'),
      summary: i18n.t('toolbox.sleep.library.topic.red_flags.summary'),
      detail: i18n.t('toolbox.sleep.library.topic.red_flags.detail'),
      actionHint: i18n.t('toolbox.sleep.library.topic.red_flags.action_hint'),
      sources: <SleepResearchSource>[
        SleepResearchSource(
          bookTitle: '《斯坦福的高效睡眠法》',
          relevance: i18n.t('toolbox.sleep.library.source.red_flags_1'),
        ),
        SleepResearchSource(
          bookTitle: '《好好休息：精力充沛的科学管理方法》',
          relevance: i18n.t('toolbox.sleep.library.source.red_flags_2'),
        ),
        SleepResearchSource(
          bookTitle: '《干掉失眠：让你睡个好觉的心理疗法》',
          relevance: i18n.t('toolbox.sleep.library.source.red_flags_3'),
        ),
      ],
    ),
  ]);
  return topics;
}

SleepResearchTopic? sleepResearchTopicById(AppI18n i18n, String topicId) {
  for (final topic in buildSleepResearchTopics(i18n)) {
    if (topic.id == topicId) {
      return topic;
    }
  }
  return null;
}

Future<void> showSleepResearchTopicSheet(
  BuildContext context, {
  required SleepResearchTopic topic,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final appState = context.watch<AppState>();
      return sleepModuleTheme(
        context: context,
        enabled: appState.sleepDashboardState.sleepDarkModeEnabled,
        child: Builder(
          builder: (context) {
            final theme = Theme.of(context);
            final i18n = AppI18n(Localizations.localeOf(context).languageCode);
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.82,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: <Widget>[
                    Text(
                      topic.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(topic.summary, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 16),
                    Text(topic.detail, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        topic.actionHint,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      i18n.t('toolbox.sleep.library.topic.references'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...topic.sources.map(
                      (source) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: theme.colorScheme.surfaceContainerHighest,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                source.bookTitle,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(source.relevance),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

void showSleepResearchTopicById(
  BuildContext context,
  AppI18n i18n,
  String topicId,
) {
  final topic = sleepResearchTopicById(i18n, topicId);
  if (topic == null) {
    return;
  }
  showSleepResearchTopicSheet(context, topic: topic);
}

List<SleepAdviceItem> buildSleepAssessmentAdvice(
  AppI18n i18n, {
  required SleepAssessmentDraftState draft,
}) {
  final items = <SleepAdviceItem>[];

  if (draft.shiftWorkOrJetLag ||
      draft.selectedIssues.contains(SleepIssueType.irregularSchedule)) {
    items.add(
      SleepAdviceItem(
        id: 'assessment_rhythm',
        topicId: sleepTopicMorningLight,
        title: i18n.t('toolbox.sleep.library.advice_assessment_rhythm.title'),
        body: i18n.t('toolbox.sleep.library.advice_assessment_rhythm.body'),
        reason: i18n.t('toolbox.sleep.library.advice_assessment_rhythm.reason'),
        tag: i18n.t('toolbox.sleep.library.tag.rhythm'),
        isPriority: true,
      ),
    );
  }

  if (draft.hasRacingThoughts ||
      draft.stressLoadLevel >= 3 ||
      draft.screenDependenceLevel >= 3 ||
      draft.lateWorkFrequency >= 3) {
    items.add(
      SleepAdviceItem(
        id: 'assessment_wind_down',
        topicId: sleepTopicWorryUnload,
        title: i18n.t('toolbox.sleep.library.advice_assessment_wind_down.title'),
        body: i18n.t('toolbox.sleep.library.advice_assessment_wind_down.body'),
        reason: i18n.t('toolbox.sleep.library.advice_assessment_wind_down.reason'),
        tag: i18n.t('toolbox.sleep.library.tag.wind_down'),
        isPriority: items.isEmpty,
      ),
    );
  }

  if (draft.caffeineSensitive) {
    items.add(
      SleepAdviceItem(
        id: 'assessment_caffeine',
        topicId: sleepTopicCaffeineCutoff,
        title: i18n.t('toolbox.sleep.library.advice_assessment_caffeine.title'),
        body: i18n.t('toolbox.sleep.library.advice_assessment_caffeine.body'),
        reason: i18n.t('toolbox.sleep.library.advice_assessment_caffeine.reason'),
        tag: i18n.t('toolbox.sleep.library.tag.behavior'),
      ),
    );
  }

  if (draft.bedroomLightIssue ||
      draft.bedroomNoiseIssue ||
      draft.bedroomTempIssue ||
      draft.refluxOrDigestiveDiscomfort) {
    items.add(
      SleepAdviceItem(
        id: 'assessment_environment',
        topicId: sleepTopicBedroomSanctuary,
        title: i18n.t('toolbox.sleep.library.advice_assessment_environment.title'),
        body: i18n.t('toolbox.sleep.library.advice_assessment_environment.body'),
        reason: i18n.t('toolbox.sleep.library.advice_assessment_environment.reason'),
        tag: i18n.t('toolbox.sleep.library.tag.environment'),
      ),
    );
  }

  if (draft.exerciseLateFrequency >= 3) {
    items.add(
      SleepAdviceItem(
        id: 'assessment_temp',
        topicId: sleepTopicBodyTemperature,
        title: i18n.t('toolbox.sleep.library.advice_assessment_temp.title'),
        body: i18n.t('toolbox.sleep.library.advice_assessment_temp.body'),
        reason: i18n.t('toolbox.sleep.library.advice_assessment_temp.reason'),
        tag: i18n.t('toolbox.sleep.library.tag.temperature'),
      ),
    );
  }

  if (draft.snoringRisk == SleepRiskLevel.medium ||
      draft.snoringRisk == SleepRiskLevel.high) {
    items.add(
      SleepAdviceItem(
        id: 'assessment_risk',
        topicId: sleepTopicRiskFlags,
        title: i18n.t('toolbox.sleep.library.advice_assessment_risk.title'),
        body: i18n.t('toolbox.sleep.library.advice_assessment_risk.body'),
        reason: i18n.t('toolbox.sleep.library.advice_assessment_risk.reason'),
        tag: i18n.t('toolbox.sleep.library.tag.risk'),
        isPriority: true,
      ),
    );
  }

  return items;
}

List<SleepAdviceItem> buildSleepDailyAdvice(
  AppI18n i18n, {
  SleepProfile? profile,
  SleepDailyLog? log,
}) {
  if (log == null) {
    return const <SleepAdviceItem>[];
  }

  final items = <SleepAdviceItem>[];
  if (log.estimatedTotalSleepMinutes == null &&
      log.sleepLatencyMinutes == null &&
      log.nightWakeCount == 0 &&
      log.nightWakeTotalMinutes == 0 &&
      (log.notes ?? '').trim().isEmpty) {
    items.add(
      SleepAdviceItem(
        id: 'daily_minimal_log',
        topicId: sleepTopicSleepDiary,
        title: i18n.t('toolbox.sleep.library.advice_daily_minimal_log.title'),
        body: i18n.t('toolbox.sleep.library.advice_daily_minimal_log.body'),
        reason: i18n.t('toolbox.sleep.library.advice_daily_minimal_log.reason'),
        tag: i18n.t('toolbox.sleep.library.tag.log'),
        isPriority: true,
      ),
    );
  }

  if (log.caffeineAfterCutoff) {
    items.add(
      SleepAdviceItem(
        id: 'daily_caffeine',
        topicId: sleepTopicCaffeineCutoff,
        title: i18n.t('toolbox.sleep.library.advice_daily_caffeine.title'),
        body: i18n.t('toolbox.sleep.library.advice_daily_caffeine.body'),
        reason: i18n.t('toolbox.sleep.library.advice_daily_caffeine.reason'),
        tag: i18n.t('toolbox.sleep.library.tag.behavior'),
        isPriority: true,
      ),
    );
  }

  if (!log.morningLightDone) {
    items.add(
      SleepAdviceItem(
        id: 'daily_light',
        topicId: sleepTopicMorningLight,
        title: i18n.t('toolbox.sleep.library.advice_daily_light.title'),
        body: i18n.t('toolbox.sleep.library.advice_daily_light.body'),
        reason: i18n.t('toolbox.sleep.library.advice_daily_light.reason'),
        tag: i18n.t('toolbox.sleep.library.tag.rhythm'),
      ),
    );
  }

  if (log.lateScreenExposure || (log.windDownMinutes ?? 0) < 20) {
    items.add(
      SleepAdviceItem(
        id: 'daily_screen',
        topicId: sleepTopicDigitalSunset,
        title: i18n.t('toolbox.sleep.library.advice_daily_screen.title'),
        body: i18n.t('toolbox.sleep.library.advice_daily_screen.body'),
        reason: i18n.t('toolbox.sleep.library.advice_daily_screen.reason'),
        tag: i18n.t('toolbox.sleep.library.tag.wind_down'),
        isPriority: items.isEmpty,
      ),
    );
  }

  if ((log.worryLoadLevel ?? 0) >= 4 ||
      (log.stressPeakLevel ?? 0) >= 4 ||
      profile?.hasRacingThoughts == true) {
    items.add(
      SleepAdviceItem(
        id: 'daily_worry',
        topicId: sleepTopicWorryUnload,
        title: i18n.t('toolbox.sleep.library.advice_daily_worry.title'),
        body: i18n.t('toolbox.sleep.library.advice_daily_worry.body'),
        reason: i18n.t('toolbox.sleep.library.advice_daily_worry.reason'),
        tag: i18n.t('toolbox.sleep.library.tag.cognitive'),
      ),
    );
  }

  if (log.nightWakeCount >= 2 ||
      log.nightWakeTotalMinutes >= 30 ||
      log.clockChecking) {
    items.add(
      SleepAdviceItem(
        id: 'daily_rescue',
        topicId: sleepTopicStimulusControl,
        title: i18n.t('toolbox.sleep.library.advice_daily_rescue.title'),
        body: i18n.t('toolbox.sleep.library.advice_daily_rescue.body'),
        reason: i18n.t('toolbox.sleep.library.advice_daily_rescue.reason'),
        tag: i18n.t('toolbox.sleep.library.tag.rescue'),
      ),
    );
  }

  if (log.bedroomTooHot || log.bedroomTooBright || log.bedroomTooNoisy) {
    items.add(
      SleepAdviceItem(
        id: 'daily_environment',
        topicId: log.bedroomTooNoisy
            ? sleepTopicWhiteNoise
            : sleepTopicBedroomSanctuary,
        title: i18n.t('toolbox.sleep.library.advice_daily_environment.title'),
        body: i18n.t('toolbox.sleep.library.advice_daily_environment.body'),
        reason: i18n.t('toolbox.sleep.library.advice_daily_environment.reason'),
        tag: i18n.t('toolbox.sleep.library.tag.environment'),
      ),
    );
  }

  if (log.napMinutes > 30) {
    items.add(
      SleepAdviceItem(
        id: 'daily_nap',
        topicId: sleepTopicNapStrategy,
        title: i18n.t('toolbox.sleep.library.advice_daily_nap.title'),
        body: i18n.t('toolbox.sleep.library.advice_daily_nap.body'),
        reason: i18n.t('toolbox.sleep.library.advice_daily_nap.reason'),
        tag: i18n.t('toolbox.sleep.library.tag.recovery'),
      ),
    );
  }

  return items;
}

List<SleepAdviceItem> buildSleepWeeklyAdvice(
  AppI18n i18n, {
  required List<SleepDailyLog> logs,
  SleepProfile? profile,
}) {
  if (logs.isEmpty) {
    return const <SleepAdviceItem>[];
  }
  final items = <SleepAdviceItem>[];
  final averageSleep = averageSleepInt(
    logs.map((item) => item.estimatedTotalSleepMinutes),
  );
  final averageEfficiency = averageSleepDouble(
    logs.map((item) => item.sleepEfficiency),
  );
  final lateScreenDays = logs.where((item) => item.lateScreenExposure).length;
  final lateCaffeineDays = logs
      .where((item) => item.caffeineAfterCutoff)
      .length;
  final missingMorningLightDays = logs
      .where((item) => !item.morningLightDone)
      .length;
  final noisyDays = logs
      .where(
        (item) =>
            item.bedroomTooNoisy || item.bedroomTooBright || item.bedroomTooHot,
      )
      .length;
  final highWorryDays = logs
      .where(
        (item) =>
            (item.worryLoadLevel ?? 0) >= 4 || (item.stressPeakLevel ?? 0) >= 4,
      )
      .length;
  final heavyWakeDays = logs
      .where(
        (item) => item.nightWakeCount >= 2 || item.nightWakeTotalMinutes >= 30,
      )
      .length;

  if (missingMorningLightDays >= (logs.length / 2).ceil()) {
    items.add(
      SleepAdviceItem(
        id: 'weekly_light',
        topicId: sleepTopicMorningLight,
        title: i18n.t('toolbox.sleep.library.advice_weekly_light.title'),
        body: i18n.t('toolbox.sleep.library.advice_weekly_light.body'),
        reason: i18n.t('toolbox.sleep.library.advice_weekly_light.reason'),
        tag: i18n.t('toolbox.sleep.library.tag.rhythm'),
        isPriority: true,
      ),
    );
  }

  if (lateCaffeineDays >= 2) {
    items.add(
      SleepAdviceItem(
        id: 'weekly_caffeine',
        topicId: sleepTopicCaffeineCutoff,
        title: i18n.t('toolbox.sleep.library.advice_weekly_caffeine.title'),
        body: i18n.t('toolbox.sleep.library.advice_weekly_caffeine.body'),
        reason: i18n.t('toolbox.sleep.library.advice_weekly_caffeine.reason'),
        tag: i18n.t('toolbox.sleep.library.tag.behavior'),
        isPriority: items.isEmpty,
      ),
    );
  }

  if (lateScreenDays >= 3) {
    items.add(
      SleepAdviceItem(
        id: 'weekly_screen',
        topicId: sleepTopicDigitalSunset,
        title: i18n.t('toolbox.sleep.library.advice_weekly_screen.title'),
        body: i18n.t('toolbox.sleep.library.advice_weekly_screen.body'),
        reason: i18n.t('toolbox.sleep.library.advice_weekly_screen.reason'),
        tag: i18n.t('toolbox.sleep.library.tag.wind_down'),
      ),
    );
  }

  if (heavyWakeDays >= 2 ||
      ((averageEfficiency ?? 1) < 0.85 && logs.length >= 4)) {
    items.add(
      SleepAdviceItem(
        id: 'weekly_rescue',
        topicId: sleepTopicStimulusControl,
        title: i18n.t('toolbox.sleep.library.advice_weekly_rescue.title'),
        body: i18n.t('toolbox.sleep.library.advice_weekly_rescue.body'),
        reason: i18n.t('toolbox.sleep.library.advice_weekly_rescue.reason'),
        tag: i18n.t('toolbox.sleep.library.tag.rescue'),
      ),
    );
  }

  if (highWorryDays >= 2 || profile?.hasRacingThoughts == true) {
    items.add(
      SleepAdviceItem(
        id: 'weekly_worry',
        topicId: sleepTopicWorryUnload,
        title: i18n.t('toolbox.sleep.library.advice_weekly_worry.title'),
        body: i18n.t('toolbox.sleep.library.advice_weekly_worry.body'),
        reason: i18n.t('toolbox.sleep.library.advice_weekly_worry.reason'),
        tag: i18n.t('toolbox.sleep.library.tag.cognitive'),
      ),
    );
  }

  if (noisyDays >= 2) {
    items.add(
      SleepAdviceItem(
        id: 'weekly_environment',
        topicId: sleepTopicBedroomSanctuary,
        title: i18n.t('toolbox.sleep.library.advice_weekly_environment.title'),
        body: i18n.t('toolbox.sleep.library.advice_weekly_environment.body'),
        reason: i18n.t('toolbox.sleep.library.advice_weekly_environment.reason'),
        tag: i18n.t('toolbox.sleep.library.tag.environment'),
      ),
    );
  }

  if ((averageSleep ?? 0) < 360) {
    items.add(
      SleepAdviceItem(
        id: 'weekly_sleep_amount',
        topicId: sleepTopicMorningLight,
        title: i18n.t('toolbox.sleep.library.advice_weekly_sleep_amount.title'),
        body: i18n.t('toolbox.sleep.library.advice_weekly_sleep_amount.body'),
        reason: i18n.t('toolbox.sleep.library.advice_weekly_sleep_amount.reason'),
        tag: i18n.t('toolbox.sleep.library.tag.sleep_amount'),
      ),
    );
  }

  return items;
}

class SleepAdviceList extends StatelessWidget {
  const SleepAdviceList({
    super.key,
    required this.items,
    required this.i18n,
    this.emptyTitle,
    this.emptyMessage,
  });

  final List<SleepAdviceItem> items;
  final AppI18n i18n;
  final String? emptyTitle;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      final title =
          emptyTitle ??
          i18n.t('toolbox.sleep.library.empty.no_advice');
      final message =
          emptyMessage ??
          i18n.t('toolbox.sleep.library.empty.no_advice_hint');
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Theme.of(context).colorScheme.surfaceContainerLow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(message),
          ],
        ),
      );
    }

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SleepAdviceCard(item: item, i18n: i18n),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _SleepAdviceCard extends StatelessWidget {
  const _SleepAdviceCard({required this.item, required this.i18n});

  final SleepAdviceItem item;
  final AppI18n i18n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topic = sleepResearchTopicById(i18n, item.topicId);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: item.isPriority
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.78)
            : theme.colorScheme.surfaceContainerLow,
        border: Border.all(
          color: item.isPriority
              ? theme.colorScheme.primary.withValues(alpha: 0.32)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: theme.colorScheme.surface,
                ),
                child: Text(
                  item.tag,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              if (topic != null)
                IconButton(
                  tooltip: i18n.t('toolbox.sleep.library.research_detail'),
                  onPressed: () {
                    showSleepResearchTopicSheet(context, topic: topic);
                  },
                  icon: const Icon(Icons.info_outline_rounded),
                ),
            ],
          ),
          Text(
            item.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(item.body),
          const SizedBox(height: 8),
          Text(item.reason, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
