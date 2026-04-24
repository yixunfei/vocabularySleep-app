import 'package:flutter/material.dart';

import '../../i18n/app_i18n.dart';
import 'sleep_assistant_ui_support.dart';

enum SleepMorningQuickMood { same, worse, better }

class SleepSupportGoalStrip extends StatelessWidget {
  const SleepSupportGoalStrip({super.key, required this.i18n});

  final AppI18n i18n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: scheme.surfaceContainerHigh,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: scheme.primaryContainer,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.volunteer_activism_rounded,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    pickSleepText(i18n, zh: '今晚目标', en: 'Tonight goal'),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    pickSleepText(
                      i18n,
                      zh: '不是把睡眠做完美，而是在最累的时候少做一个选择、少责备自己一点。你只需要完成一个小动作，剩下的交给身体慢慢接住。',
                      en: 'The goal is not perfect sleep. Make one less decision, blame yourself a little less, and let one small action carry you toward rest.',
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SleepMorningQuickCheckPanel extends StatelessWidget {
  const SleepMorningQuickCheckPanel({
    super.key,
    required this.i18n,
    required this.hasQuickFeedback,
    required this.suggestedContext,
    required this.onMoodSelected,
    required this.onOpenLog,
  });

  final AppI18n i18n;
  final bool hasQuickFeedback;
  final List<String> suggestedContext;
  final ValueChanged<SleepMorningQuickMood> onMoodSelected;
  final VoidCallback onOpenLog;

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
                Icon(Icons.touch_app_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        pickSleepText(
                          i18n,
                          zh: '醒来只点一下',
                          en: 'One-tap wake check',
                        ),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pickSleepText(
                          i18n,
                          zh: hasQuickFeedback
                              ? '今早已经记过，需要时可以直接覆盖。'
                              : '不用回忆时间轴，先留下今天的体感趋势。',
                          en: hasQuickFeedback
                              ? 'Saved this morning. Tap again to replace it.'
                              : 'Skip the timeline and capture the trend first.',
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
            if (suggestedContext.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: suggestedContext
                    .take(3)
                    .map((item) => _SleepContextPill(label: item))
                    .toList(growable: false),
              ),
            ],
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final fullWidth = constraints.maxWidth < 340;
                final buttonWidth = fullWidth
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 16) / 3;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _SleepMorningMoodButton(
                      width: buttonWidth,
                      icon: Icons.drag_handle_rounded,
                      label: pickSleepText(i18n, zh: '差不多', en: 'Same'),
                      onPressed: () =>
                          onMoodSelected(SleepMorningQuickMood.same),
                    ),
                    _SleepMorningMoodButton(
                      width: buttonWidth,
                      icon: Icons.trending_down_rounded,
                      label: pickSleepText(i18n, zh: '更差', en: 'Worse'),
                      onPressed: () =>
                          onMoodSelected(SleepMorningQuickMood.worse),
                    ),
                    _SleepMorningMoodButton(
                      width: buttonWidth,
                      icon: Icons.trending_up_rounded,
                      label: pickSleepText(i18n, zh: '更好', en: 'Better'),
                      onPressed: () =>
                          onMoodSelected(SleepMorningQuickMood.better),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onOpenLog,
                icon: const Icon(Icons.edit_note_rounded),
                label: Text(
                  pickSleepText(i18n, zh: '补详细日志', en: 'Open full log'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SleepBedtimeSceneSheet extends StatelessWidget {
  const SleepBedtimeSceneSheet({
    super.key,
    required this.i18n,
    required this.onStartScene,
    required this.onWhiteNoise,
    required this.onClose,
  });

  final AppI18n i18n;
  final VoidCallback onStartScene;
  final VoidCallback onWhiteNoise;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: <Widget>[
          Text(
            pickSleepText(i18n, zh: '睡前一键场景', en: 'One-tap bedtime scene'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            pickSleepText(
              i18n,
              zh: '一次确认后，帮你打开睡眠暗色模式并启动最低能量流程。背景音和其他工具仍由你主动选择。',
              en: 'After confirmation, sleep dark mode turns on and the tiny routine starts. Audio and other tools stay opt-in.',
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: theme.colorScheme.surfaceContainerLow,
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _SleepTiredStep(
                  label: '1',
                  text: pickSleepText(
                    i18n,
                    zh: '切换睡眠暗色',
                    en: 'Switch sleep dark mode',
                  ),
                ),
                _SleepTiredStep(
                  label: '2',
                  text: pickSleepText(
                    i18n,
                    zh: '选中最低能量流程',
                    en: 'Select the tiny routine',
                  ),
                ),
                _SleepTiredStep(
                  label: '3',
                  text: pickSleepText(
                    i18n,
                    zh: '进入今晚执行页',
                    en: 'Open tonight runner',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onStartScene,
            icon: const Icon(Icons.nights_stay_rounded),
            label: Text(pickSleepText(i18n, zh: '确认启动', en: 'Start scene')),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onWhiteNoise,
            icon: const Icon(Icons.graphic_eq_rounded),
            label: Text(
              pickSleepText(i18n, zh: '先选背景音', en: 'Choose audio first'),
            ),
          ),
          TextButton(
            onPressed: onClose,
            child: Text(pickSleepText(i18n, zh: '先不启动', en: 'Not now')),
          ),
        ],
      ),
    );
  }
}

class _SleepContextPill extends StatelessWidget {
  const _SleepContextPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: theme.colorScheme.surfaceContainerHigh,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class SleepTiredModeSheet extends StatelessWidget {
  const SleepTiredModeSheet({
    super.key,
    required this.i18n,
    required this.onTinyRoutine,
    required this.onNightRescue,
    required this.onWhiteNoise,
    required this.onClose,
  });

  final AppI18n i18n;
  final VoidCallback onTinyRoutine;
  final VoidCallback onNightRescue;
  final VoidCallback onWhiteNoise;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: <Widget>[
          Text(
            pickSleepText(i18n, zh: '我现在很累', en: 'I am tired now'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            pickSleepText(
              i18n,
              zh: '先不复盘，也不重新计划。今晚只需要选一个最小动作。',
              en: 'No review and no replanning. Choose one tiny action for tonight.',
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: theme.colorScheme.surfaceContainerLow,
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _SleepTiredStep(
                  label: '1',
                  text: pickSleepText(i18n, zh: '把灯调暗', en: 'Dim the lights'),
                ),
                _SleepTiredStep(
                  label: '2',
                  text: pickSleepText(
                    i18n,
                    zh: '把手机放远一点',
                    en: 'Move the phone away',
                  ),
                ),
                _SleepTiredStep(
                  label: '3',
                  text: pickSleepText(
                    i18n,
                    zh: '把一个担心留到明天',
                    en: 'Park one worry for tomorrow',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onTinyRoutine,
            icon: const Icon(Icons.bedtime_rounded),
            label: Text(
              pickSleepText(i18n, zh: '开始 8 分钟', en: 'Start 8 minutes'),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onWhiteNoise,
            icon: const Icon(Icons.graphic_eq_rounded),
            label: Text(
              pickSleepText(i18n, zh: '只放背景音', en: 'Play background sound'),
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onNightRescue,
            icon: const Icon(Icons.self_improvement_rounded),
            label: Text(
              pickSleepText(i18n, zh: '我是半夜醒了', en: 'I woke up at night'),
            ),
          ),
          TextButton(
            onPressed: onClose,
            child: Text(
              pickSleepText(i18n, zh: '只做上面 3 步', en: 'I will do the 3 steps'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SleepMorningMoodButton extends StatelessWidget {
  const _SleepMorningMoodButton({
    required this.width,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final double width;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _SleepTiredStep extends StatelessWidget {
  const _SleepTiredStep({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: <Widget>[
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primaryContainer,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
