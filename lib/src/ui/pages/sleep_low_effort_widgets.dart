import 'package:flutter/material.dart';

import '../../i18n/app_i18n.dart';

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
                    i18n.t('toolbox.sleep.low.tonightGoal'),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    i18n.t('toolbox.sleep.low.tonightGoalHint'),
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
                        i18n.t('toolbox.sleep.low.wakeTap'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasQuickFeedback
                            ? i18n.t('toolbox.sleep.low.wakeTapDone')
                            : i18n.t('toolbox.sleep.low.wakeTapHint'),
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
                      label: i18n.t('toolbox.sleep.low.same'),
                      onPressed: () =>
                          onMoodSelected(SleepMorningQuickMood.same),
                    ),
                    _SleepMorningMoodButton(
                      width: buttonWidth,
                      icon: Icons.trending_down_rounded,
                      label: i18n.t('toolbox.sleep.low.worse'),
                      onPressed: () =>
                          onMoodSelected(SleepMorningQuickMood.worse),
                    ),
                    _SleepMorningMoodButton(
                      width: buttonWidth,
                      icon: Icons.trending_up_rounded,
                      label: i18n.t('toolbox.sleep.low.better'),
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
                label: Text(i18n.t('toolbox.sleep.low.openFullLog')),
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
            i18n.t('toolbox.sleep.low.bedtimeScene'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            i18n.t('toolbox.sleep.low.bedtimeSceneHint'),
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
                  text: i18n.t('toolbox.sleep.low.switchDark'),
                ),
                _SleepTiredStep(
                  label: '2',
                  text: i18n.t('toolbox.sleep.low.selectTiny'),
                ),
                _SleepTiredStep(
                  label: '3',
                  text: i18n.t('toolbox.sleep.low.enterRunner'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onStartScene,
            icon: const Icon(Icons.nights_stay_rounded),
            label: Text(i18n.t('toolbox.sleep.low.confirmStart')),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onWhiteNoise,
            icon: const Icon(Icons.graphic_eq_rounded),
            label: Text(i18n.t('toolbox.sleep.low.chooseAudio')),
          ),
          TextButton(
            onPressed: onClose,
            child: Text(i18n.t('toolbox.sleep.low.notNow')),
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
            i18n.t('toolbox.sleep.low.imTired'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            i18n.t('toolbox.sleep.low.imTiredHint'),
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
                  text: i18n.t('toolbox.sleep.low.dimLights'),
                ),
                _SleepTiredStep(
                  label: '2',
                  text: i18n.t('toolbox.sleep.low.movePhoneAway'),
                ),
                _SleepTiredStep(
                  label: '3',
                  text: i18n.t('toolbox.sleep.low.parkWorry'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onTinyRoutine,
            icon: const Icon(Icons.bedtime_rounded),
            label: Text(i18n.t('toolbox.sleep.low.start8min')),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onWhiteNoise,
            icon: const Icon(Icons.graphic_eq_rounded),
            label: Text(i18n.t('toolbox.sleep.low.audioOnly')),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onNightRescue,
            icon: const Icon(Icons.self_improvement_rounded),
            label: Text(i18n.t('toolbox.sleep.low.wokeAtNight')),
          ),
          TextButton(
            onPressed: onClose,
            child: Text(i18n.t('toolbox.sleep.low.do3Steps')),
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
