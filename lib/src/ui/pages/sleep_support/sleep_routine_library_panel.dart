import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../i18n/app_i18n.dart';
import '../../../models/sleep_routine_template.dart';
import '../../../services/sleep/sleep_routine_controller.dart';
import '../../../state/app_state.dart';
import '../sleep_assistant_ui_support.dart';
import '../sleep_routine_editor_page.dart';

class SleepRoutineLibraryPanel extends StatelessWidget {
  const SleepRoutineLibraryPanel({super.key, required this.i18n});

  final AppI18n i18n;

  @override
  Widget build(BuildContext context) {
    final templates = context.select<AppState, List<SleepRoutineTemplate>>(
      (s) => s.sleepRoutineTemplates,
    );
    final controller = context.read<AppState>().sleepRoutineController;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed: () => _edit(context, null),
          icon: const Icon(Icons.add_rounded),
          label: Text(i18n.t('toolbox.sleep.winddown.new')),
        ),
        const SizedBox(height: 12),
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) =>
              _RoutineRunner(i18n: i18n, controller: controller),
        ),
        const SizedBox(height: 16),
        ...templates.map((template) => _template(context, template)),
      ],
    );
  }

  Widget _template(BuildContext context, SleepRoutineTemplate template) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                sleepRoutineTemplateName(i18n, template),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(sleepMinutesLabel(template.totalMinutes, i18n: i18n)),
              const SizedBox(height: 8),
              for (final step in template.steps)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(sleepRoutineStepLabel(i18n, step)),
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _startButton(context, template),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: () => _edit(context, template),
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(i18n.t('toolbox.sleep.night.edit_routine')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _startButton(BuildContext context, SleepRoutineTemplate template) {
    final appState = context.read<AppState>();
    final controller = appState.sleepRoutineController;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => FilledButton.tonalIcon(
        style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
        onPressed: controller.value.isRunning || controller.value.isPaused
            ? null
            : () => appState.startSleepRoutine(template.id),
        icon: const Icon(Icons.play_arrow_rounded),
        label: Text(i18n.t('toolbox.sleep.winddown.start')),
      ),
    );
  }

  void _edit(BuildContext context, SleepRoutineTemplate? template) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SleepRoutineEditorPage(template: template),
      ),
    );
  }
}

class _RoutineRunner extends StatelessWidget {
  const _RoutineRunner({required this.i18n, required this.controller});

  final AppI18n i18n;
  final SleepRoutineController controller;

  @override
  Widget build(BuildContext context) {
    final state = controller.value;
    final template = controller.activeTemplate;
    if (template == null || (!state.isRunning && !state.isPaused)) {
      return const SizedBox.shrink();
    }
    final currentIndex = state.currentStepIndex;
    final currentStep = template.steps[currentIndex];
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              sleepRoutineTemplateName(i18n, template),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(sleepRoutineStepLabel(i18n, currentStep)),
            const SizedBox(height: 8),
            Text(sleepSecondsLabel(state.remainingSeconds, i18n: i18n)),
            const SizedBox(height: 12),
            _controls(context, state),
          ],
        ),
      ),
    );
  }

  Widget _controls(BuildContext context, SleepRoutineRunnerState state) {
    final appState = context.read<AppState>();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: state.isPaused
              ? appState.resumeSleepRoutine
              : appState.pauseSleepRoutine,
          child: Text(
            i18n.t(
              state.isPaused
                  ? 'toolbox.sleep.core.resume'
                  : 'toolbox.sleep.core.pause',
            ),
          ),
        ),
        OutlinedButton(
          style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: appState.advanceSleepRoutine,
          child: Text(i18n.t('toolbox.sleep.core.next')),
        ),
        OutlinedButton(
          style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
          onPressed: appState.stopSleepRoutine,
          child: Text(i18n.t('toolbox.sleep.core.stop')),
        ),
      ],
    );
  }
}
