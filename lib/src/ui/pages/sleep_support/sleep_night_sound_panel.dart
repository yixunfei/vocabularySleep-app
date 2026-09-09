import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../i18n/app_i18n.dart';
import '../../../services/sleep/sleep_sound_controller.dart';
import '../../../state/app_state.dart';
import '../sleep_assistant_ui_support.dart';

class SleepNightSoundPanel extends StatelessWidget {
  const SleepNightSoundPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final language = context.select<AppState, String>((s) => s.uiLanguage);
    final controller = context.read<AppState>().sleepSoundController;
    final i18n = AppI18n(language);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => TextButton.icon(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
        icon: Icon(
          controller.status == SleepSoundStatus.playing
              ? Icons.volume_up_outlined
              : Icons.music_note_outlined,
        ),
        label: Text(
          i18n.t('toolbox.sleep.sound.status.${controller.status.name}'),
        ),
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (sheetContext) => sleepModuleTheme(
            context: sheetContext,
            enabled: true,
            child: _SoundSheet(controller: controller, i18n: i18n),
          ),
        ),
      ),
    );
  }
}

class _SoundSheet extends StatelessWidget {
  const _SoundSheet({required this.controller, required this.i18n});

  final SleepSoundController controller;
  final AppI18n i18n;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                i18n.t('toolbox.sleep.sound.title'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(i18n.t('toolbox.sleep.sound.offline_hint')),
              const SizedBox(height: 16),
              _soundButton(context, null),
              for (final sound in SleepSound.values) ...[
                const SizedBox(height: 8),
                _soundButton(context, sound),
              ],
              if (controller.status == SleepSoundStatus.preparing) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
              ],
              if (controller.status == SleepSoundStatus.failed) ...[
                const SizedBox(height: 12),
                Text(
                  i18n.t('toolbox.sleep.sound.failed_hint'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 20),
              Text(i18n.t('toolbox.sleep.sound.volume')),
              const SizedBox(height: 8),
              _volumeChoices(),
              const SizedBox(height: 16),
              Text(i18n.t('toolbox.sleep.sound.stop_after')),
              const SizedBox(height: 8),
              _durationChoices(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _soundButton(BuildContext context, SleepSound? sound) {
    final selected = sound == null
        ? controller.status == SleepSoundStatus.silent
        : controller.sound == sound &&
              controller.status == SleepSoundStatus.playing;
    return OutlinedButton.icon(
      key: ValueKey('sleep-sound-${sound?.name ?? 'silent'}'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.all(12),
        backgroundColor: selected
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
      ),
      icon: Icon(selected ? Icons.check_circle_outline : Icons.circle_outlined),
      label: Text(i18n.t('toolbox.sleep.sound.${sound?.name ?? 'silent'}')),
      onPressed: () =>
          sound == null ? controller.stop() : controller.play(sound),
    );
  }

  Widget _volumeChoices() => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final entry in const [
        (0.1, 'soft'),
        (0.18, 'gentle'),
        (0.3, 'clear'),
      ])
        ChoiceChip(
          label: Text(i18n.t('toolbox.sleep.sound.volume.${entry.$2}')),
          selected: controller.volume == entry.$1,
          onSelected: (_) => controller.setVolume(entry.$1),
          materialTapTargetSize: MaterialTapTargetSize.padded,
        ),
    ],
  );

  Widget _durationChoices() => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final minutes in const [15, 30, 60])
        ChoiceChip(
          label: Text(
            i18n.t('toolbox.sleep.sound.minutes', params: {'minutes': minutes}),
          ),
          selected: controller.minutes == minutes,
          onSelected: (_) => controller.setMinutes(minutes),
          materialTapTargetSize: MaterialTapTargetSize.padded,
        ),
    ],
  );
}
