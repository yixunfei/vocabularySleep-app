import 'package:flutter/material.dart';

import '../../../i18n/app_i18n.dart';
import '../../../models/sleep_support_session.dart';
import 'sleep_night_sound_panel.dart';

class SleepNightStage extends StatelessWidget {
  const SleepNightStage({
    super.key,
    required this.i18n,
    required this.session,
    required this.onChoice,
    required this.onSkip,
    required this.onChangeMethod,
    required this.onRest,
    required this.onResume,
    required this.onFinish,
    this.soundPanel = const SleepNightSoundPanel(),
  });

  final AppI18n i18n;
  final SleepSupportSession session;
  final ValueChanged<SleepSupportChoice> onChoice;
  final VoidCallback onSkip;
  final VoidCallback onChangeMethod;
  final VoidCallback onRest;
  final VoidCallback onResume;
  final VoidCallback onFinish;
  final Widget soundPanel;

  @override
  Widget build(BuildContext context) {
    if (session.isResting) return _resting(context);
    return _NightViewport(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NightInstruction(
            title: i18n.t(session.titleKey),
            body: i18n.t(session.bodyKey),
          ),
          const SizedBox(height: 24),
          for (final choice in session.choices) ...[
            SleepNightButton(
              key: ValueKey('sleep-choice-${choice.name}'),
              label: i18n.t(choice.labelKey),
              primary: choice == session.choices.first,
              onPressed: () => onChoice(choice),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              _textButton('toolbox.sleep.night.skip', onSkip),
              if (session.step != SleepSupportStep.chooseMethod)
                _textButton(
                  'toolbox.sleep.night.change_method',
                  onChangeMethod,
                ),
              if (!session.choices.contains(SleepSupportChoice.rest) &&
                  !session.choices.contains(SleepSupportChoice.sleepy))
                _textButton('toolbox.sleep.night.rest', onRest),
            ],
          ),
          const SizedBox(height: 16),
          soundPanel,
        ],
      ),
    );
  }

  Widget _resting(BuildContext context) {
    return _NightViewport(
      center: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.nights_stay_outlined,
            size: 36,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 24),
          Text(
            i18n.t('toolbox.sleep.night.rest_title'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 14),
          Text(
            i18n.t('toolbox.sleep.night.rest_body'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 40),
          SleepNightButton(
            key: const ValueKey('sleep-resume-guide'),
            label: i18n.t('toolbox.sleep.night.resume'),
            onPressed: onResume,
          ),
          const SizedBox(height: 12),
          _textButton('toolbox.sleep.night.exit', onFinish),
          const SizedBox(height: 12),
          soundPanel,
        ],
      ),
    );
  }

  Widget _textButton(String key, VoidCallback onPressed) {
    return TextButton(
      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      onPressed: onPressed,
      child: Text(i18n.t(key), textAlign: TextAlign.center),
    );
  }
}

class _NightInstruction extends StatelessWidget {
  const _NightInstruction({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.bedtime_outlined, color: theme.colorScheme.primary),
            const SizedBox(height: 20),
            Text(title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 14),
            Text(body, style: theme.textTheme.bodyLarge?.copyWith(height: 1.6)),
          ],
        ),
      ),
    );
  }
}

class SleepNightButton extends StatelessWidget {
  const SleepNightButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(56)),
      padding: const WidgetStatePropertyAll(EdgeInsets.all(16)),
      textStyle: WidgetStatePropertyAll(
        Theme.of(context).textTheme.titleMedium,
      ),
    );
    final text = Text(label, textAlign: TextAlign.center);
    return primary
        ? FilledButton(style: style, onPressed: onPressed, child: text)
        : OutlinedButton(style: style, onPressed: onPressed, child: text);
  }
}

class _NightViewport extends StatelessWidget {
  const _NightViewport({required this.child, this.center = false});

  final Widget child;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (constraints.maxHeight - 44).clamp(0, double.infinity),
          ),
          child: Align(
            alignment: center ? Alignment.center : Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SizedBox(width: double.infinity, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class SleepNightSaveStatus extends StatelessWidget {
  const SleepNightSaveStatus({
    super.key,
    required this.i18n,
    required this.saving,
    required this.failed,
    required this.onRetry,
    required this.onLeave,
    required this.onDone,
  });

  final AppI18n i18n;
  final bool saving;
  final bool failed;
  final VoidCallback onRetry;
  final VoidCallback onLeave;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return _NightViewport(
      center: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (saving) const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 16),
          Text(
            i18n.t(
              failed
                  ? 'toolbox.sleep.night.save_failed'
                  : saving
                  ? 'toolbox.sleep.night.saving'
                  : 'toolbox.sleep.night.finished',
            ),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          if (failed) ...[
            SleepNightButton(
              label: i18n.t('toolbox.sleep.night.retry_save'),
              primary: true,
              onPressed: onRetry,
            ),
            const SizedBox(height: 12),
            SleepNightButton(
              label: i18n.t('toolbox.sleep.night.leave_unsaved'),
              onPressed: onLeave,
            ),
          ] else if (!saving)
            SleepNightButton(
              label: i18n.t('toolbox.sleep.night.exit'),
              onPressed: onDone,
            ),
        ],
      ),
    );
  }
}

class SleepPreviousSession extends StatelessWidget {
  const SleepPreviousSession({
    super.key,
    required this.i18n,
    required this.onResume,
    required this.onReplace,
  });

  final AppI18n i18n;
  final VoidCallback onResume;
  final VoidCallback onReplace;

  @override
  Widget build(BuildContext context) {
    return _NightViewport(
      center: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NightInstruction(
            title: i18n.t('toolbox.sleep.night.previous_title'),
            body: i18n.t('toolbox.sleep.night.previous_body'),
          ),
          const SizedBox(height: 24),
          SleepNightButton(
            label: i18n.t('toolbox.sleep.night.resume'),
            primary: true,
            onPressed: onResume,
          ),
          const SizedBox(height: 12),
          SleepNightButton(
            label: i18n.t('toolbox.sleep.night.start_new'),
            onPressed: onReplace,
          ),
        ],
      ),
    );
  }
}
