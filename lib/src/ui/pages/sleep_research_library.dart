import 'package:flutter/material.dart';

import '../../i18n/app_i18n.dart';
import '../../models/sleep_daily_log.dart';
import '../../models/sleep_guidance.dart';
import '../../models/sleep_profile.dart';
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

List<SleepResearchTopic> buildSleepResearchTopics(AppI18n i18n) {
  final topics = <SleepResearchTopic>[
    SleepResearchTopic(
      id: sleepTopicMorningLight,
      title: pickSleepText(i18n, zh: '晨光与固定起床', en: 'Morning Light and Fixed Wake'),
      summary: pickSleepText(
        i18n,
        zh: '醒后尽快接触自然光，并把起床时间尽量拉直，是重建节律的核心。',
        en: 'Outdoor light soon after waking plus a stable wake time is a core rhythm anchor.',
      ),
      detail: pickSleepText(
        i18n,
        zh: '多份参考都把“晨起尽快见光”和“先固定起床时间”放在靠前优先级。晨光会给生物钟一个清晰锚点，帮助夜间困意回到更稳定的时间窗。对作息漂移、时差、轮班后恢复尤其关键。',
        en: 'Multiple references prioritize early morning light and a fixed wake time. Morning light gives the circadian system a strong anchor and helps nighttime sleepiness return at a steadier window.',
      ),
      actionHint: pickSleepText(
        i18n,
        zh: '先做到起床后 30 分钟内接触自然光 10 到 20 分钟。',
        en: 'Start with 10 to 20 minutes of outdoor light within 30 minutes of waking.',
      ),
      sources: <SleepResearchSource>[
        SleepResearchSource(
          bookTitle: '《这本书能让你睡得好》',
          relevance: pickSleepText(i18n, zh: '强调晨光、数字日落和卧室环境整理。', en: 'Strong emphasis on morning light and rhythm anchors.'),
        ),
        SleepResearchSource(
          bookTitle: '《斯坦福的高效睡眠法》',
          relevance: pickSleepText(i18n, zh: '把清醒与睡眠视作同一系统，晨间锚点很关键。', en: 'Frames wakefulness and sleep as one system; morning anchor matters.'),
        ),
        SleepResearchSource(
          bookTitle: '《好好休息：精力充沛的科学管理方法》',
          relevance: pickSleepText(i18n, zh: '强调节律、褪黑素与足量睡眠。', en: 'Highlights circadian rhythm and melatonin timing.'),
        ),
      ],
    ),
    SleepResearchTopic(
      id: sleepTopicCaffeineCutoff,
      title: pickSleepText(i18n, zh: '咖啡因截止线', en: 'Caffeine Cutoff'),
      summary: pickSleepText(
        i18n,
        zh: '临睡前太近的咖啡因会拖慢困意积累，并让夜间睡眠更浅。',
        en: 'Caffeine too close to bedtime can delay sleepiness and lighten sleep.',
      ),
      detail: pickSleepText(
        i18n,
        zh: '参考资料对咖啡因的观点高度一致：它不是只影响“能不能睡着”，也会影响入睡潜伏期、睡眠连续性和主观恢复感。实际产品中不需要做复杂代谢算法，先给出一个可执行截止线，再结合日志观察是否还要前移。',
        en: 'The references are aligned: caffeine affects not only sleep onset but also continuity and subjective recovery. A practical cutoff is more valuable than an overly complex metabolism model.',
      ),
      actionHint: pickSleepText(
        i18n,
        zh: '先把截止线设为计划上床前约 8 小时，敏感者再前移。',
        en: 'Start with a cutoff around eight hours before bedtime, then move earlier if needed.',
      ),
      sources: <SleepResearchSource>[
        SleepResearchSource(
          bookTitle: '《这本书能让你睡得好》',
          relevance: pickSleepText(i18n, zh: '直接提出咖啡因截止线策略。', en: 'Directly recommends a caffeine cutoff strategy.'),
        ),
        SleepResearchSource(
          bookTitle: '《斯坦福的高效睡眠法》',
          relevance: pickSleepText(i18n, zh: '将觉醒系统管理作为睡眠管理的一部分。', en: 'Treats arousal management as part of sleep management.'),
        ),
        SleepResearchSource(
          bookTitle: '《好好休息：精力充沛的科学管理方法》',
          relevance: pickSleepText(i18n, zh: '强调咖啡因、褪黑素和节律交互。', en: 'Explains caffeine and circadian interactions.'),
        ),
      ],
    ),
    SleepResearchTopic(
      id: sleepTopicDigitalSunset,
      title: pickSleepText(i18n, zh: '数字日落与降刺激', en: 'Digital Sunset'),
      summary: pickSleepText(
        i18n,
        zh: '问题不只是蓝光，更多是内容刺激、工作输入和停不下来的唤醒。',
        en: 'The issue is not only blue light, but also stimulating content and cognitive activation.',
      ),
      detail: pickSleepText(
        i18n,
        zh: '多本书都不建议把睡前最后一小时继续留给高刺激内容。产品上最值得落地的是“最后一小时降低输入强度”而不是机械禁用手机。把工作、短视频、争论型内容先移开，比追求绝对零屏幕更可执行。',
        en: 'Several references recommend lowering stimulation in the final hour before bed. A practical product strategy is reducing activating input, rather than forcing total zero-screen behavior.',
      ),
      actionHint: pickSleepText(
        i18n,
        zh: '先把睡前最后 60 分钟换成低刺激流程。',
        en: 'Convert the final 60 minutes before bed into a lower-stimulation routine.',
      ),
      sources: <SleepResearchSource>[
        SleepResearchSource(
          bookTitle: '《这本书能让你睡得好》',
          relevance: pickSleepText(i18n, zh: '强调数字日落和把设备移出卧室。', en: 'Emphasizes digital sunset and device removal.'),
        ),
        SleepResearchSource(
          bookTitle: '《浓缩睡眠法：如何睡少又睡好》',
          relevance: pickSleepText(i18n, zh: '提倡用阅读等低刺激活动替代刷屏。', en: 'Suggests reading and lower-stimulation alternatives.'),
        ),
        SleepResearchSource(
          bookTitle: '《干掉失眠：让你睡个好觉的心理疗法》',
          relevance: pickSleepText(i18n, zh: '强调减少床上解决问题与认知激活。', en: 'Stresses reducing problem-solving activation in bed.'),
        ),
      ],
    ),
    SleepResearchTopic(
      id: sleepTopicStimulusControl,
      title: pickSleepText(i18n, zh: '夜醒应对与刺激控制', en: 'Stimulus Control'),
      summary: pickSleepText(
        i18n,
        zh: '如果在床上越来越清醒，不要继续硬熬，先离床做低刺激活动。',
        en: 'If you are getting more awake in bed, do not keep forcing it. Leave bed for something low-stim.',
      ),
      detail: pickSleepText(
        i18n,
        zh: 'CBT-I 相关资料反复强调，床应尽量和睡意重新绑定，而不是与“挣扎着必须睡着”绑定。产品上最关键的是：夜醒时先判断是短暂醒、完全清醒还是脑内高唤醒，再给单步行为脚本，而不是给复杂分析。',
        en: 'CBT-I based references repeatedly emphasize re-associating bed with sleepiness, not with struggling to force sleep. The product value is giving one next low-stim step, not complex nighttime analysis.',
      ),
      actionHint: pickSleepText(
        i18n,
        zh: '如果明显越躺越醒，先离床，等困意回来再回床。',
        en: 'If you are clearly getting more awake, leave bed and return only when sleepiness comes back.',
      ),
      sources: <SleepResearchSource>[
        SleepResearchSource(
          bookTitle: '《干掉失眠：让你睡个好觉的心理疗法》',
          relevance: pickSleepText(i18n, zh: '核心方法之一就是刺激控制和离床策略。', en: 'Stimulus control and leave-bed strategy are core methods.'),
        ),
        SleepResearchSource(
          bookTitle: '《这本书能让你睡得好》',
          relevance: pickSleepText(i18n, zh: '支持夜间替代活动和卧室环境整理。', en: 'Supports night alternatives and bedroom cleanup.'),
        ),
      ],
    ),
  ];
  topics.addAll(<SleepResearchTopic>[
    SleepResearchTopic(
      id: sleepTopicWorryUnload,
      title: pickSleepText(i18n, zh: '担忧卸载与认知停放', en: 'Worry Unload'),
      summary: pickSleepText(
        i18n,
        zh: '在床上继续想明天，只会继续提高清醒度；先停放，再明天处理。',
        en: 'Trying to solve tomorrow in bed usually raises activation; park it first, then revisit tomorrow.',
      ),
      detail: pickSleepText(
        i18n,
        zh: '《干掉失眠》与《浓缩睡眠法》都强调把担忧、计划和待办从睡前和夜醒时段挪出去。实用落地点不是“想法必须消失”，而是先把内容写下、归位、设定明天再处理，减少睡前性能压力。',
        en: 'The references emphasize moving worries and unfinished planning out of bedtime and night awakenings. The goal is not to erase thoughts, but to offload and defer them so bedtime is no longer a performance arena.',
      ),
      actionHint: pickSleepText(
        i18n,
        zh: '把此刻最吵的念头写下，再写一句更温和的替代表述。',
        en: 'Write down the loudest thought, then add one gentler reframe.',
      ),
      sources: <SleepResearchSource>[
        SleepResearchSource(
          bookTitle: '《干掉失眠：让你睡个好觉的心理疗法》',
          relevance: pickSleepText(i18n, zh: '指定担忧时间、认知重构和接纳是关键线索。', en: 'Scheduled worry time and cognitive work are key ideas.'),
        ),
        SleepResearchSource(
          bookTitle: '《浓缩睡眠法：如何睡少又睡好》',
          relevance: pickSleepText(i18n, zh: '主张把不安写出来、换成低刺激输入。', en: 'Suggests writing worries out and switching to lower stimulation.'),
        ),
      ],
    ),
    SleepResearchTopic(
      id: sleepTopicBedroomSanctuary,
      title: pickSleepText(i18n, zh: '卧室环境与睡眠庇护所', en: 'Bedroom Sanctuary'),
      summary: pickSleepText(
        i18n,
        zh: '先把亮、热、吵、工作痕迹和设备刺激清掉，再谈更细致优化。',
        en: 'Fix brightness, heat, noise, work cues, and device stimulation before finer optimizations.',
      ),
      detail: pickSleepText(
        i18n,
        zh: '多份参考对卧室环境的共识非常稳定：黑暗、较凉、安静、少设备、少工作痕迹。产品上应优先做检查单、问题标记和小步实验，而不是一次性给太多“玄学助眠物”。',
        en: 'The references consistently prioritize a darker, cooler, quieter room with fewer devices and work cues. Product-wise, checklists and small experiments are more useful than overselling sleep gadgets.',
      ),
      actionHint: pickSleepText(
        i18n,
        zh: '今晚只改最明显的一项环境干扰，例如亮度、噪声或温度。',
        en: 'Change only the most obvious bedroom stressor tonight, such as light, noise, or temperature.',
      ),
      sources: <SleepResearchSource>[
        SleepResearchSource(
          bookTitle: '《这本书能让你睡得好》',
          relevance: pickSleepText(i18n, zh: '提出卧室是睡眠庇护所，设备应尽量移出。', en: 'Frames the bedroom as a sleep sanctuary.'),
        ),
        SleepResearchSource(
          bookTitle: '《斯坦福的高效睡眠法》',
          relevance: pickSleepText(i18n, zh: '强调体温、恢复和环境条件。', en: 'Highlights environment and body recovery conditions.'),
        ),
        SleepResearchSource(
          bookTitle: '《浓缩睡眠法：如何睡少又睡好》',
          relevance: pickSleepText(i18n, zh: '支持低刺激空间和替代活动。', en: 'Supports low-stimulation spaces and calming alternatives.'),
        ),
      ],
    ),
    SleepResearchTopic(
      id: sleepTopicBodyTemperature,
      title: pickSleepText(i18n, zh: '体温下降窗口', en: 'Body Temperature Window'),
      summary: pickSleepText(
        i18n,
        zh: '睡前热水澡、泡脚或降低卧室温度，常能帮助身体更顺利进入睡眠。',
        en: 'Warm bathing and a cooler room can help the body move into sleep more smoothly.',
      ),
      detail: pickSleepText(
        i18n,
        zh: '《斯坦福的高效睡眠法》对体温与入睡关系讲得很清楚。产品上不必把它神秘化，落成“睡前 60 到 90 分钟热水澡/泡脚”和“卧室偏凉”两个可执行提示就足够实用。',
        en: 'Stanford sleep guidance clearly explains the relationship between body temperature and sleep onset. In-product, simple, actionable prompts are more useful than overcomplicated biohacking claims.',
      ),
      actionHint: pickSleepText(
        i18n,
        zh: '如果你总觉得“身体还没降下来”，优先试体温路径。',
        en: 'If your body still feels activated, try the temperature path first.',
      ),
      sources: <SleepResearchSource>[
        SleepResearchSource(
          bookTitle: '《斯坦福的高效睡眠法》',
          relevance: pickSleepText(i18n, zh: '体温与黄金 90 分钟是高频主题。', en: 'Temperature and the first sleep phase are central themes.'),
        ),
        SleepResearchSource(
          bookTitle: '《浓缩睡眠法：如何睡少又睡好》',
          relevance: pickSleepText(i18n, zh: '支持泡脚、放松和低刺激过渡。', en: 'Supports warm transitions and gentle downshifting.'),
        ),
      ],
    ),
    SleepResearchTopic(
      id: sleepTopicNapStrategy,
      title: pickSleepText(i18n, zh: '午睡与白天恢复', en: 'Naps and Daytime Recovery'),
      summary: pickSleepText(
        i18n,
        zh: '白天太困时可以短暂恢复，但午睡太长会吞掉夜间困意。',
        en: 'Short daytime recovery can help, but long naps often reduce nighttime sleep pressure.',
      ),
      detail: pickSleepText(
        i18n,
        zh: '《浓缩睡眠法》对短午睡和微恢复很重视。《斯坦福的高效睡眠法》也支持把白天恢复看成系统的一部分。产品上应该强调“短、小、早”，而不是鼓励靠长午睡补债。',
        en: 'The references value short naps and micro-recovery, but not using long naps as a substitute for stable nighttime sleep. The most useful practical guidance is short, small, and earlier in the day.',
      ),
      actionHint: pickSleepText(
        i18n,
        zh: '如果必须午睡，先把目标压到 15 到 25 分钟。',
        en: 'If a nap is necessary, start by keeping it around 15 to 25 minutes.',
      ),
      sources: <SleepResearchSource>[
        SleepResearchSource(
          bookTitle: '《浓缩睡眠法：如何睡少又睡好》',
          relevance: pickSleepText(i18n, zh: '支持短午睡和工作日微恢复。', en: 'Strong on short naps and micro-recovery.'),
        ),
        SleepResearchSource(
          bookTitle: '《斯坦福的高效睡眠法》',
          relevance: pickSleepText(i18n, zh: '强调恢复质量与白天状态管理。', en: 'Frames recovery quality and daytime management together.'),
        ),
      ],
    ),
    SleepResearchTopic(
      id: sleepTopicWhiteNoise,
      title: pickSleepText(i18n, zh: '白噪音与声音遮蔽', en: 'White Noise and Sound Masking'),
      summary: pickSleepText(
        i18n,
        zh: '白噪音更适合处理不稳定噪声，不是万能助眠剂。',
        en: 'White noise is mainly for masking unstable noise, not a universal sleep solution.',
      ),
      detail: pickSleepText(
        i18n,
        zh: '参考书更常强调环境稳定、卧室安静和低刺激。对白噪音最稳妥的产品表达是：当卧室噪声不稳定、容易被外界声音拉醒时，它可以是一个实用遮蔽工具；如果房间本身已经安静，不必强行使用。',
        en: 'The references mostly emphasize environmental stability and low stimulation. A careful product interpretation is to use white noise as a practical masking tool when inconsistent external noise is the problem, not as a universal must-have.',
      ),
      actionHint: pickSleepText(
        i18n,
        zh: '只有在“噪声不稳定”是真问题时再启用白噪音。',
        en: 'Use white noise when inconsistent noise is the actual problem.',
      ),
      sources: <SleepResearchSource>[
        SleepResearchSource(
          bookTitle: '《这本书能让你睡得好》',
          relevance: pickSleepText(i18n, zh: '环境整理和卧室安静是优先级更高的共识。', en: 'Bedroom quiet and cleanup are higher-priority ideas.'),
        ),
        SleepResearchSource(
          bookTitle: '《斯坦福的高效睡眠法》',
          relevance: pickSleepText(i18n, zh: '睡眠恢复依赖稳定环境条件。', en: 'Sleep recovery depends on stable environmental conditions.'),
        ),
      ],
    ),
    SleepResearchTopic(
      id: sleepTopicRiskFlags,
      title: pickSleepText(i18n, zh: '红旗风险与就医提示', en: 'Risk Flags'),
      summary: pickSleepText(
        i18n,
        zh: '如果有明显打鼾、憋醒、极端白天嗜睡或长期严重失眠，单靠工具通常不够。',
        en: 'Loud snoring, gasping, severe daytime sleepiness, or persistent insomnia often need more than self-help tools.',
      ),
      detail: pickSleepText(
        i18n,
        zh: '多份资料都提示了边界条件。睡眠工具很适合做行为记录、节律调整和心理减压，但不适合替代对睡眠呼吸暂停、严重情绪问题或长期失眠的进一步评估。产品上应该清晰地给出风险提示，但不要用它阻断基础功能。',
        en: 'The references make the boundary conditions clear. Sleep tools are useful for behavior tracking and rhythm work, but they do not replace evaluation for sleep apnea, serious mood problems, or long-standing insomnia.',
      ),
      actionHint: pickSleepText(
        i18n,
        zh: '出现憋醒、巨大鼾声或白天困到影响功能时，不要只靠自我调整。',
        en: 'Do not rely only on self-adjustment when snoring, gasping, or severe sleepiness is prominent.',
      ),
      sources: <SleepResearchSource>[
        SleepResearchSource(
          bookTitle: '《斯坦福的高效睡眠法》',
          relevance: pickSleepText(i18n, zh: '提示睡眠呼吸暂停相关风险。', en: 'Highlights sleep apnea related risks.'),
        ),
        SleepResearchSource(
          bookTitle: '《好好休息：精力充沛的科学管理方法》',
          relevance: pickSleepText(i18n, zh: '强调足量睡眠与长期健康边界。', en: 'Emphasizes sufficient sleep and health consequences.'),
        ),
        SleepResearchSource(
          bookTitle: '《干掉失眠：让你睡个好觉的心理疗法》',
          relevance: pickSleepText(i18n, zh: '强调长期失眠需要系统化支持。', en: 'Stresses systematic support for persistent insomnia.'),
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
                pickSleepText(i18n, zh: '参考来源', en: 'Reference sources'),
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
        title: pickSleepText(i18n, zh: '先重建节律锚点', en: 'Rebuild rhythm anchors first'),
        body: pickSleepText(
          i18n,
          zh: '你的核心矛盾更像节律漂移。先固定起床时间、做晨光暴露，再看入睡问题是否跟着改善。',
          en: 'Your pattern looks rhythm-shifted. Fix wake time and morning light before chasing bedtime.',
        ),
        reason: pickSleepText(i18n, zh: '存在作息不规律、轮班或时差线索。', en: 'Irregular schedule, shift work, or jet lag is present.'),
        tag: pickSleepText(i18n, zh: '节律', en: 'Rhythm'),
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
        title: pickSleepText(i18n, zh: '优先处理睡前高唤醒', en: 'Reduce bedtime activation'),
        body: pickSleepText(
          i18n,
          zh: '先不要继续把床留给工作、刷屏和反复思考。你的第一条主线应该是卸载思绪和低刺激流程。',
          en: 'Do not keep the bed linked to work, scrolling, and repetitive thinking. Start with a softer pre-bed routine.',
        ),
        reason: pickSleepText(i18n, zh: '压力、屏幕依赖或晚间工作负荷偏高。', en: 'Stress, screen dependence, or late work is elevated.'),
        tag: pickSleepText(i18n, zh: '减压', en: 'Wind-down'),
        isPriority: items.isEmpty,
      ),
    );
  }

  if (draft.caffeineSensitive) {
    items.add(
      SleepAdviceItem(
        id: 'assessment_caffeine',
        topicId: sleepTopicCaffeineCutoff,
        title: pickSleepText(i18n, zh: '咖啡因要更早停', en: 'Use an earlier caffeine cutoff'),
        body: pickSleepText(
          i18n,
          zh: '如果你自觉对咖啡因更敏感，就不要等日志已经明显变坏再处理，先把截止线前移。',
          en: 'If you are caffeine-sensitive, move the cutoff earlier before waiting for larger deterioration.',
        ),
        reason: pickSleepText(i18n, zh: '已勾选咖啡因敏感。', en: 'Caffeine sensitivity is flagged.'),
        tag: pickSleepText(i18n, zh: '行为', en: 'Behavior'),
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
        title: pickSleepText(i18n, zh: '先清掉最明显的环境干扰', en: 'Fix the obvious environment issues'),
        body: pickSleepText(
          i18n,
          zh: '如果亮、吵、热、反酸或身体不适本身就在打断睡眠，先别急着堆太多技巧，先改掉最明显的一项。',
          en: 'If light, noise, heat, reflux, or discomfort is already breaking sleep, solve that first before stacking more techniques.',
        ),
        reason: pickSleepText(i18n, zh: '环境或消化不适线索明显。', en: 'Environment or digestive discomfort is prominent.'),
        tag: pickSleepText(i18n, zh: '环境', en: 'Environment'),
      ),
    );
  }

  if (draft.exerciseLateFrequency >= 3) {
    items.add(
      SleepAdviceItem(
        id: 'assessment_temp',
        topicId: sleepTopicBodyTemperature,
        title: pickSleepText(i18n, zh: '注意太晚运动后的降温', en: 'Manage late exercise downshift'),
        body: pickSleepText(
          i18n,
          zh: '如果运动常常拖到很晚，重点不是“不能运动”，而是给身体留出降温和回落的过渡。',
          en: 'If intense exercise often runs late, the key is allowing body temperature and activation to come down.',
        ),
        reason: pickSleepText(i18n, zh: '晚间剧烈运动频率偏高。', en: 'Late intense exercise frequency is elevated.'),
        tag: pickSleepText(i18n, zh: '体温', en: 'Temperature'),
      ),
    );
  }

  if (draft.snoringRisk == SleepRiskLevel.medium ||
      draft.snoringRisk == SleepRiskLevel.high) {
    items.add(
      SleepAdviceItem(
        id: 'assessment_risk',
        topicId: sleepTopicRiskFlags,
        title: pickSleepText(i18n, zh: '把风险提示放在边上，但别忽视', en: 'Keep risk flags visible'),
        body: pickSleepText(
          i18n,
          zh: '行为调整可以继续做，但如果打鼾、憋醒或白天困到明显影响功能，不要只依赖工具。',
          en: 'Behavior work can continue, but loud snoring or gasping should not be handled only with self-help tools.',
        ),
        reason: pickSleepText(i18n, zh: '打鼾风险达到中高水平。', en: 'Snoring risk is medium or high.'),
        tag: pickSleepText(i18n, zh: '风险', en: 'Risk'),
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
  if (log.caffeineAfterCutoff) {
    items.add(
      SleepAdviceItem(
        id: 'daily_caffeine',
        topicId: sleepTopicCaffeineCutoff,
        title: pickSleepText(i18n, zh: '今天先改咖啡因时间', en: 'Move caffeine earlier today'),
        body: pickSleepText(
          i18n,
          zh: '昨晚已记录晚咖啡因。如果今晚还想改善，最优先就是把今天的最后一杯往前挪。',
          en: 'Late caffeine was logged. The cleanest same-day improvement is moving the last cup earlier.',
        ),
        reason: pickSleepText(i18n, zh: '已出现咖啡因超线。', en: 'Late caffeine was logged.'),
        tag: pickSleepText(i18n, zh: '行为', en: 'Behavior'),
        isPriority: true,
      ),
    );
  }

  if (!log.morningLightDone) {
    items.add(
      SleepAdviceItem(
        id: 'daily_light',
        topicId: sleepTopicMorningLight,
        title: pickSleepText(i18n, zh: '今天优先补晨光', en: 'Prioritize morning light today'),
        body: pickSleepText(
          i18n,
          zh: '如果晨光没做，白天先把这件事补上。它比继续纠结昨晚更能帮助拉回节律。',
          en: 'If morning light was missed, make that the first correction today.',
        ),
        reason: pickSleepText(i18n, zh: '晨光暴露缺失。', en: 'Morning light was missed.'),
        tag: pickSleepText(i18n, zh: '节律', en: 'Rhythm'),
      ),
    );
  }

  if (log.lateScreenExposure || (log.windDownMinutes ?? 0) < 20) {
    items.add(
      SleepAdviceItem(
        id: 'daily_screen',
        topicId: sleepTopicDigitalSunset,
        title: pickSleepText(i18n, zh: '今晚最后一小时降刺激', en: 'Lower stimulation in the final hour'),
        body: pickSleepText(
          i18n,
          zh: '相比继续找更多技巧，你今晚更值得先把最后一小时收干净，减少刷屏、工作和争论型内容。',
          en: 'Before adding more techniques, clean up the final hour tonight and reduce stimulating input.',
        ),
        reason: pickSleepText(
          i18n,
          zh: '存在临睡前看屏或减压时间偏短。',
          en: 'Late screens or insufficient wind-down time was logged.',
        ),
        tag: pickSleepText(i18n, zh: '减压', en: 'Wind-down'),
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
        title: pickSleepText(i18n, zh: '今晚先卸载思绪', en: 'Unload thoughts tonight'),
        body: pickSleepText(
          i18n,
          zh: '如果压力和担忧都高，今晚不要再依赖“硬熬到睡着”，而是先写下来、再离开问题。',
          en: 'When stress and worry are high, stop trying to force sleep. Offload the content first.',
        ),
        reason: pickSleepText(i18n, zh: '担忧或压力评分偏高。', en: 'Stress or worry was elevated.'),
        tag: pickSleepText(i18n, zh: '心理', en: 'Cognitive'),
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
        title: pickSleepText(i18n, zh: '夜醒时别在床上硬耗', en: 'Do not wrestle in bed during awakenings'),
        body: pickSleepText(
          i18n,
          zh: '如果今晚再夜醒，不要反复看时间或继续躺着解决问题。先判断是否已经完全清醒，再决定离床。',
          en: 'If you wake again tonight, avoid clock checking and problem-solving in bed. Judge wakefulness first, then leave bed if needed.',
        ),
        reason: pickSleepText(
          i18n,
          zh: '夜醒负担偏高或存在反复看时间。',
          en: 'Wake burden is elevated or clock checking was logged.',
        ),
        tag: pickSleepText(i18n, zh: '夜醒', en: 'Rescue'),
      ),
    );
  }

  if (log.bedroomTooHot || log.bedroomTooBright || log.bedroomTooNoisy) {
    items.add(
      SleepAdviceItem(
        id: 'daily_environment',
        topicId: log.bedroomTooNoisy ? sleepTopicWhiteNoise : sleepTopicBedroomSanctuary,
        title: pickSleepText(i18n, zh: '今晚只修一项卧室问题', en: 'Fix one bedroom issue tonight'),
        body: pickSleepText(
          i18n,
          zh: '如果卧室已经在打断睡眠，先针对最明显的一项处理。噪声不稳定时可尝试白噪音做遮蔽。',
          en: 'If the bedroom is already disrupting sleep, fix the most obvious issue first. White noise can help when noise is inconsistent.',
        ),
        reason: pickSleepText(i18n, zh: '已记录亮、热或吵的环境线索。', en: 'Brightness, heat, or noise issues were logged.'),
        tag: pickSleepText(i18n, zh: '环境', en: 'Environment'),
      ),
    );
  }

  if (log.napMinutes > 30) {
    items.add(
      SleepAdviceItem(
        id: 'daily_nap',
        topicId: sleepTopicNapStrategy,
        title: pickSleepText(i18n, zh: '今天把午睡压短', en: 'Keep naps shorter today'),
        body: pickSleepText(
          i18n,
          zh: '如果昨晚已经睡不稳，今天再午睡过长，晚上的困意可能会被继续稀释。',
          en: 'After a rough night, a long nap can further dilute nighttime sleep pressure.',
        ),
        reason: pickSleepText(i18n, zh: '午睡时长超过 30 分钟。', en: 'Nap length exceeded 30 minutes.'),
        tag: pickSleepText(i18n, zh: '恢复', en: 'Recovery'),
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
  final averageSleep = averageSleepInt(logs.map((item) => item.estimatedTotalSleepMinutes));
  final averageEfficiency = averageSleepDouble(logs.map((item) => item.sleepEfficiency));
  final lateScreenDays = logs.where((item) => item.lateScreenExposure).length;
  final lateCaffeineDays = logs.where((item) => item.caffeineAfterCutoff).length;
  final missingMorningLightDays = logs.where((item) => !item.morningLightDone).length;
  final noisyDays = logs.where((item) => item.bedroomTooNoisy || item.bedroomTooBright || item.bedroomTooHot).length;
  final highWorryDays = logs.where((item) => (item.worryLoadLevel ?? 0) >= 4 || (item.stressPeakLevel ?? 0) >= 4).length;
  final heavyWakeDays = logs.where((item) => item.nightWakeCount >= 2 || item.nightWakeTotalMinutes >= 30).length;

  if (missingMorningLightDays >= (logs.length / 2).ceil()) {
    items.add(
      SleepAdviceItem(
        id: 'weekly_light',
        topicId: sleepTopicMorningLight,
        title: pickSleepText(i18n, zh: '下周先把晨光做稳', en: 'Make morning light consistent next week'),
        body: pickSleepText(
          i18n,
          zh: '最近多数天都没有完成晨光暴露。与其同时改很多项，不如下周先把晨光和起床时间做稳。',
          en: 'Morning light was missed on many days. Next week, stabilize morning light and wake time before chasing too many variables.',
        ),
        reason: pickSleepText(i18n, zh: '晨光完成率偏低。', en: 'Morning light completion is low.'),
        tag: pickSleepText(i18n, zh: '节律', en: 'Rhythm'),
        isPriority: true,
      ),
    );
  }

  if (lateCaffeineDays >= 2) {
    items.add(
      SleepAdviceItem(
        id: 'weekly_caffeine',
        topicId: sleepTopicCaffeineCutoff,
        title: pickSleepText(i18n, zh: '下周先收紧咖啡因截止线', en: 'Tighten the caffeine cutoff next week'),
        body: pickSleepText(
          i18n,
          zh: '如果晚咖啡因一周出现了多次，先处理这个变量最划算，因为它会同时影响入睡和夜间连续性。',
          en: 'If late caffeine showed up multiple times, it is usually the cleanest high-leverage variable to fix first.',
        ),
        reason: pickSleepText(i18n, zh: '一周内多次出现咖啡因超线。', en: 'Late caffeine appeared on multiple days.'),
        tag: pickSleepText(i18n, zh: '行为', en: 'Behavior'),
        isPriority: items.isEmpty,
      ),
    );
  }

  if (lateScreenDays >= 3) {
    items.add(
      SleepAdviceItem(
        id: 'weekly_screen',
        topicId: sleepTopicDigitalSunset,
        title: pickSleepText(i18n, zh: '把最后一小时收干净', en: 'Clean up the final pre-bed hour'),
        body: pickSleepText(
          i18n,
          zh: '睡前高刺激输入出现得比较频繁，下周最值得做的是让最后一小时更固定、更单调、更少工作内容。',
          en: 'Pre-bed high stimulation is recurring. Next week, make the final hour more predictable, quieter, and less work-heavy.',
        ),
        reason: pickSleepText(i18n, zh: '看屏频率偏高。', en: 'Late screen exposure is frequent.'),
        tag: pickSleepText(i18n, zh: '减压', en: 'Wind-down'),
      ),
    );
  }

  if (heavyWakeDays >= 2 || ((averageEfficiency ?? 1) < 0.85 && logs.length >= 4)) {
    items.add(
      SleepAdviceItem(
        id: 'weekly_rescue',
        topicId: sleepTopicStimulusControl,
        title: pickSleepText(i18n, zh: '下周重点练夜醒脚本', en: 'Practice night-wake rescue next week'),
        body: pickSleepText(
          i18n,
          zh: '你最近更需要一个稳定的夜醒应对脚本，而不是继续在床上硬耗。周报层面看，先练夜醒流程往往比继续堆助眠小技巧更有效。',
          en: 'You likely need a repeatable night-wake script more than more “sleep hacks”. Practicing rescue behavior is a higher-value move.',
        ),
        reason: pickSleepText(i18n, zh: '夜醒负担或睡眠效率提示这一点。', en: 'Wake burden or sleep efficiency points in this direction.'),
        tag: pickSleepText(i18n, zh: '夜醒', en: 'Rescue'),
      ),
    );
  }

  if (highWorryDays >= 2 || profile?.hasRacingThoughts == true) {
    items.add(
      SleepAdviceItem(
        id: 'weekly_worry',
        topicId: sleepTopicWorryUnload,
        title: pickSleepText(i18n, zh: '给担忧一个白天出口', en: 'Give worry a daytime container'),
        body: pickSleepText(
          i18n,
          zh: '这一周压力或担忧反复偏高。下周不要把改动做得太散，先把“担忧卸载”稳定成固定动作。',
          en: 'Stress or worry stayed elevated across the week. Next week, stabilize worry unload as a fixed action.',
        ),
        reason: pickSleepText(i18n, zh: '担忧或压力多次偏高。', en: 'Stress or worry was elevated on multiple days.'),
        tag: pickSleepText(i18n, zh: '心理', en: 'Cognitive'),
      ),
    );
  }

  if (noisyDays >= 2) {
    items.add(
      SleepAdviceItem(
        id: 'weekly_environment',
        topicId: sleepTopicBedroomSanctuary,
        title: pickSleepText(i18n, zh: '下周先改卧室，而不是加更多技巧', en: 'Fix the bedroom before adding more tricks'),
        body: pickSleepText(
          i18n,
          zh: '环境问题在一周里反复出现。与其叠加更多流程，不如下周先把卧室亮度、噪声或温度修到更稳定。',
          en: 'Bedroom issues repeated across the week. Before adding more routines, make the room itself more stable.',
        ),
        reason: pickSleepText(i18n, zh: '环境问题重复出现。', en: 'Bedroom problems repeated.'),
        tag: pickSleepText(i18n, zh: '环境', en: 'Environment'),
      ),
    );
  }

  if ((averageSleep ?? 0) < 360) {
    items.add(
      SleepAdviceItem(
        id: 'weekly_sleep_amount',
        topicId: sleepTopicMorningLight,
        title: pickSleepText(i18n, zh: '先别追求“补回来”，先拉直节律', en: 'Do not chase compensation first'),
        body: pickSleepText(
          i18n,
          zh: '最近平均睡眠时长偏低。下周先拉直作息和白天锚点，比把周末当成补觉工具更稳。',
          en: 'Average sleep time is low. Stabilizing rhythm and anchors is usually more reliable than weekend compensation.',
        ),
        reason: pickSleepText(i18n, zh: '平均睡眠时长偏低。', en: 'Average sleep duration is low.'),
        tag: pickSleepText(i18n, zh: '总量', en: 'Sleep amount'),
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
      final title = emptyTitle ?? pickSleepText(i18n, zh: '暂时没有直接建议', en: 'No direct advice yet');
      final message = emptyMessage ??
          pickSleepText(
            i18n,
            zh: '先继续记录几天，系统会根据更多模式给出更具体建议。',
            en: 'Keep logging for a few more days to unlock more specific advice.',
          );
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
            Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
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
  const _SleepAdviceCard({
    required this.item,
    required this.i18n,
  });

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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: theme.colorScheme.surface,
                ),
                child: Text(item.tag, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              if (topic != null)
                IconButton(
                  tooltip: pickSleepText(i18n, zh: '研究说明', en: 'Research detail'),
                  onPressed: () {
                    showSleepResearchTopicSheet(context, topic: topic);
                  },
                  icon: const Icon(Icons.info_outline_rounded),
                ),
            ],
          ),
          Text(item.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(item.body),
          const SizedBox(height: 8),
          Text(item.reason, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
