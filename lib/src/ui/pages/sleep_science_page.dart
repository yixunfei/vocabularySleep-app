import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/module_system/module_id.dart';
import '../../i18n/app_i18n.dart';
import '../../state/app_state.dart';
import '../module/module_access.dart';
import 'sleep_assistant_ui_support.dart';
import 'toolbox_tool_shell.dart';

class SleepSciencePage extends StatelessWidget {
  const SleepSciencePage({super.key});

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
        ),
      );
    }

    return themed(
      ToolboxToolPage(
        title: pickSleepText(i18n, zh: '科学睡眠', en: 'Sleep science'),
        subtitle: pickSleepText(
          i18n,
          zh: '把本地睡眠参考资料压缩成可执行手册：先看风险，再做少量高杠杆动作。',
          en: 'A compact handbook distilled from local sleep references: check risk first, then act on a few high-leverage moves.',
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _ScienceNotice(i18n: i18n),
            const SizedBox(height: 12),
            _SciencePrinciples(i18n: i18n),
            const SizedBox(height: 12),
            ..._manualSections(i18n).map(
              (section) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ScienceExpansion(section: section),
              ),
            ),
            const SizedBox(height: 2),
            _ScienceReferenceIndex(i18n: i18n),
          ],
        ),
      ),
    );
  }
}

class _ScienceNotice extends StatelessWidget {
  const _ScienceNotice({required this.i18n});

  final AppI18n i18n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              Icons.health_and_safety_rounded,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                pickSleepText(
                  i18n,
                  zh: '本页用于健康教育和行为辅助，不替代诊断。出现憋醒、明显打鼾伴白天极困、胸痛、严重情绪问题、长期失眠或用药疑问时，优先寻求专业评估。',
                  en: 'This page is health education, not diagnosis. Gasping, loud snoring with severe sleepiness, chest pain, serious mood symptoms, persistent insomnia, or medication questions should be assessed professionally.',
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
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

class _SciencePrinciples extends StatelessWidget {
  const _SciencePrinciples({required this.i18n});

  final AppI18n i18n;

  @override
  Widget build(BuildContext context) {
    final cards = <_SciencePrinciple>[
      _SciencePrinciple(
        icon: Icons.wb_sunny_rounded,
        title: pickSleepText(i18n, zh: '先稳节律', en: 'Anchor rhythm'),
        body: pickSleepText(
          i18n,
          zh: '固定起床和晨光通常比追求完美入睡时间更稳。',
          en: 'Wake time and morning light are usually steadier than chasing a perfect bedtime.',
        ),
        accent: const Color(0xFFB08B33),
      ),
      _SciencePrinciple(
        icon: Icons.hotel_rounded,
        title: pickSleepText(i18n, zh: '床只留给睡', en: 'Keep bed for sleep'),
        body: pickSleepText(
          i18n,
          zh: '越在床上清醒挣扎，床越容易变成焦虑线索。',
          en: 'The longer you struggle awake in bed, the more bed becomes an anxiety cue.',
        ),
        accent: const Color(0xFF517D6E),
      ),
      _SciencePrinciple(
        icon: Icons.edit_note_rounded,
        title: pickSleepText(i18n, zh: '记录要极简', en: 'Log lightly'),
        body: pickSleepText(
          i18n,
          zh: '趋势需要少量稳定数据，不需要半夜填写长表。',
          en: 'Trends need a few stable data points, not long forms at night.',
        ),
        accent: const Color(0xFF4E74A8),
      ),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: cards
          .map((item) => _SciencePrincipleCard(item: item))
          .toList(growable: false),
    );
  }
}

class _SciencePrinciple {
  const _SciencePrinciple({
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color accent;
}

class _SciencePrincipleCard extends StatelessWidget {
  const _SciencePrincipleCard({required this.item});

  final _SciencePrinciple item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = width < 760 ? width - 32 : 186.0;
    final accent = sleepReadableAccent(context, item.accent);
    return SizedBox(
      width: cardWidth,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(item.icon, color: accent),
              const SizedBox(height: 10),
              Text(
                item.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(item.body, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScienceManualSection {
  const _ScienceManualSection({
    required this.title,
    required this.summary,
    required this.icon,
    required this.bullets,
  });

  final String title;
  final String summary;
  final IconData icon;
  final List<String> bullets;
}

class _ScienceExpansion extends StatelessWidget {
  const _ScienceExpansion({required this.section});

  final _ScienceManualSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          maintainState: true,
          leading: Icon(section.icon, color: theme.colorScheme.primary),
          title: Text(
            section.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: Text(section.summary),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          children: section.bullets
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Icon(
                          Icons.check_circle_outline_rounded,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(item)),
                    ],
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _ScienceReferenceIndex extends StatelessWidget {
  const _ScienceReferenceIndex({required this.i18n});

  final AppI18n i18n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(Icons.source_rounded, color: theme.colorScheme.primary),
          title: Text(
            pickSleepText(i18n, zh: '参考资料索引', en: 'Reference index'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: Text(
            pickSleepText(
              i18n,
              zh: '来自本地“睡眠参考”目录，已转写为应用内精简手册。',
              en: 'Distilled from the local sleep reference folder into this compact handbook.',
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          children: <Widget>[
            _ReferenceGroup(
              title: pickSleepText(
                i18n,
                zh: 'CBT-I 与失眠行为疗法',
                en: 'CBT-I and insomnia work',
              ),
              body: pickSleepText(
                i18n,
                zh: '《关灯就睡觉》《干掉失眠》强调刺激控制、睡眠限制、认知重构、担忧时间和睡眠日记；本页把它压成“床只留给睡、夜醒不挣扎、早上补最小日志”。',
                en: 'The CBT-I oriented books emphasize stimulus control, sleep restriction, cognitive reframing, worry time, and diaries; this page compresses them into bed-for-sleep, no night struggle, and light morning logging.',
              ),
            ),
            _ReferenceGroup(
              title: pickSleepText(
                i18n,
                zh: '节律、90 分钟周期与运动睡眠',
                en: 'Rhythm, cycles, and performance sleep',
              ),
              body: pickSleepText(
                i18n,
                zh: '《R90高效睡眠法》《浓缩睡眠法》提示周期、晨间/睡前仪式和恢复节奏有价值；应用内只把 90 分钟当规划参考，不当硬性规则。',
                en: 'R90 and compact-sleep references value cycles and routines; the app treats 90 minutes as planning support, not a rigid rule.',
              ),
            ),
            _ReferenceGroup(
              title: pickSleepText(
                i18n,
                zh: '生命周期、记忆和睡眠医学边界',
                en: 'Lifespan, memory, and medical boundaries',
              ),
              body: pickSleepText(
                i18n,
                zh: '《伴你一生的睡眠指导书》《睡眠的秘密世界》《睡眠医学——理论与实践》《睡眠障碍国际分类》用于风险边界、不同年龄睡眠差异、白天嗜睡和呼吸暂停等医学提示。',
                en: 'Lifespan, brain and sleep-medicine references support the risk boundaries, age differences, daytime sleepiness, and apnea warnings.',
              ),
            ),
            _ReferenceGroup(
              title: pickSleepText(
                i18n,
                zh: '大众技巧资料的取舍',
                en: 'How popular tips are handled',
              ),
              body: pickSleepText(
                i18n,
                zh: '《这本书能让你睡得好》《为什么他可以睡得那么好》《睡眠红宝书》提供大量生活建议；本页只保留晨光、咖啡因、屏幕、酒精、午睡、环境和记录这些可执行项。',
                en: 'Popular-tip references provide many lifestyle ideas; this page keeps only actionable items: light, caffeine, screens, alcohol, naps, room, and logging.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferenceGroup extends StatelessWidget {
  const _ReferenceGroup({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(body, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

List<_ScienceManualSection> _manualSections(AppI18n i18n) {
  return <_ScienceManualSection>[
    _ScienceManualSection(
      icon: Icons.warning_amber_rounded,
      title: pickSleepText(
        i18n,
        zh: '先排风险，不先堆技巧',
        en: 'Risk first, tips second',
      ),
      summary: pickSleepText(
        i18n,
        zh: '有些睡眠问题不该只靠习惯调整。',
        en: 'Some sleep problems should not be handled with habits alone.',
      ),
      bullets: <String>[
        pickSleepText(
          i18n,
          zh: '打鼾很响、憋醒、晨起头痛或白天困到影响驾驶/工作，要优先评估呼吸相关睡眠问题。',
          en: 'Loud snoring, gasping, morning headaches, or sleepiness that affects driving or work should be assessed for breathing-related sleep issues.',
        ),
        pickSleepText(
          i18n,
          zh: '抑郁、焦虑、创伤、惊恐或自伤想法伴随失眠时，优先找专业帮助。',
          en: 'Insomnia with depression, anxiety, trauma, panic, or self-harm thoughts needs professional support first.',
        ),
        pickSleepText(
          i18n,
          zh: '腿部不适、疼痛、反酸、频繁夜尿、药物影响等要先处理来源，不要只责怪自己睡不好。',
          en: 'Leg discomfort, pain, reflux, frequent urination, or medication effects should be addressed at the source.',
        ),
      ],
    ),
    _ScienceManualSection(
      icon: Icons.wb_sunny_rounded,
      title: pickSleepText(
        i18n,
        zh: '白天锚点：先把时钟拉直',
        en: 'Day anchors: straighten the clock',
      ),
      summary: pickSleepText(
        i18n,
        zh: '节律稳定比“今晚一定睡着”更可控。',
        en: 'Rhythm stability is more controllable than forcing sleep tonight.',
      ),
      bullets: <String>[
        pickSleepText(
          i18n,
          zh: '先固定起床时间，再尽快接触户外自然光；睡晚了也尽量不大幅补觉。',
          en: 'Fix wake time first, then get outdoor light soon after waking; avoid large catch-up swings.',
        ),
        pickSleepText(
          i18n,
          zh: '咖啡因先从上床前约 8 小时设截止线，敏感者再提前。',
          en: 'Start with a caffeine cutoff around eight hours before bed, earlier if sensitive.',
        ),
        pickSleepText(
          i18n,
          zh: '午睡控制在 20 到 30 分钟，尽量不要太晚；它是补能，不是补偿整晚。',
          en: 'Keep naps around 20 to 30 minutes and not too late; they are a boost, not a full-night replacement.',
        ),
      ],
    ),
    _ScienceManualSection(
      icon: Icons.nights_stay_rounded,
      title: pickSleepText(
        i18n,
        zh: '睡前收口：少而稳定',
        en: 'Wind down: small and steady',
      ),
      summary: pickSleepText(
        i18n,
        zh: '疲惫时只做最低能量流程。',
        en: 'When tired, use the tiny routine.',
      ),
      bullets: <String>[
        pickSleepText(
          i18n,
          zh: '最后一小时把光、屏幕内容和工作问题逐步降下来；重点是降低唤醒度，不是制造仪式感。',
          en: 'In the final hour, reduce light, stimulating content, and work problems; lower activation rather than creating ceremony.',
        ),
        pickSleepText(
          i18n,
          zh: '担忧很多时，把最吵的一个念头停放到明天固定时间处理。',
          en: 'When worry is loud, park the loudest thought for a fixed time tomorrow.',
        ),
        pickSleepText(
          i18n,
          zh: '酒精、重晚餐和临睡剧烈运动会让后半夜更碎，尽量不要把它们当助眠方案。',
          en: 'Alcohol, heavy dinners, and intense late exercise can fragment the second half of the night; do not treat them as sleep aids.',
        ),
      ],
    ),
    _ScienceManualSection(
      icon: Icons.self_improvement_rounded,
      title: pickSleepText(
        i18n,
        zh: '夜醒处理：不在床上硬扛',
        en: 'Night waking: do not battle in bed',
      ),
      summary: pickSleepText(
        i18n,
        zh: '半夜只做下一步，不做复盘。',
        en: 'At night, choose only the next step; do not review.',
      ),
      bullets: <String>[
        pickSleepText(
          i18n,
          zh: '醒来先不看时间，保持暗、安静、低刺激，观察困意是否回来。',
          en: 'Do not check the clock first. Keep things dark, quiet, and low-stim while sleepiness returns.',
        ),
        pickSleepText(
          i18n,
          zh: '如果越躺越清醒，短暂离床做单调安静的事，困意回来再回床。',
          en: 'If you become more awake, leave bed briefly for something calm and boring, then return when sleepy.',
        ),
        pickSleepText(
          i18n,
          zh: '第二天早上只补最小日志，别在半夜写长记录。',
          en: 'Fill only a minimal log in the morning; avoid long forms at night.',
        ),
      ],
    ),
    _ScienceManualSection(
      icon: Icons.rule_rounded,
      title: pickSleepText(
        i18n,
        zh: '几个容易误用的规则',
        en: 'Rules that are easy to misuse',
      ),
      summary: pickSleepText(
        i18n,
        zh: '这些只作为参考，不当压力源。',
        en: 'Use these as references, not pressure.',
      ),
      bullets: <String>[
        pickSleepText(
          i18n,
          zh: '8 小时不是每个人每晚的硬指标；更值得看白天功能、规律性和趋势。',
          en: 'Eight hours is not a rigid target for every night; daytime function, regularity, and trend matter more.',
        ),
        pickSleepText(
          i18n,
          zh: '90 分钟周期可用来规划起床/关灯时间，但不要为了卡周期而焦虑。',
          en: 'Ninety-minute cycles can help planning, but do not become anxious about landing perfectly.',
        ),
        pickSleepText(
          i18n,
          zh: '睡眠卫生有帮助，但慢性失眠常需要刺激控制、睡眠窗口和认知策略，而不只是换枕头。',
          en: 'Sleep hygiene helps, but chronic insomnia often needs stimulus control, sleep window work, and cognitive strategies, not just a better pillow.',
        ),
      ],
    ),
  ];
}
