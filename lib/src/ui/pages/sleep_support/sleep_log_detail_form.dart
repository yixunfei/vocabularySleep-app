import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../i18n/app_i18n.dart';
import '../../../services/sleep/sleep_log_draft.dart';
import '../sleep_assistant_ui_support.dart';
import 'sleep_day_form_widgets.dart';

class SleepLogDetailForm extends StatefulWidget {
  const SleepLogDetailForm({
    super.key,
    required this.draft,
    required this.dateKey,
    required this.i18n,
    required this.onChanged,
  });
  final SleepLogDraft draft;
  final String dateKey;
  final AppI18n i18n;
  final VoidCallback onChanged;

  @override
  State<SleepLogDetailForm> createState() => _SleepLogDetailFormState();
}

class _SleepLogDetailFormState extends State<SleepLogDetailForm> {
  late final TextEditingController _notes;
  late final Map<String, TextEditingController> _numberControllers;
  static const _numbers = <(String, String)>[
    ('estimated_total_sleep_minutes', 'estimatedSleepMinutes'),
    ('sleep_latency_minutes', 'sleepLatency'),
    ('night_wake_count', 'wakeCount'),
    ('night_wake_total_minutes', 'wakeTotal'),
    ('nap_minutes', 'napMinutes'),
    ('wind_down_minutes', 'windDownMinutes'),
  ];
  static const _times = <(String, String, bool)>[
    ('bedtime_at', 'bedtime', true),
    ('lights_off_at', 'lightsOff', true),
    ('sleep_onset_at', 'sleepOnset', true),
    ('final_wake_at', 'finalWake', false),
    ('out_of_bed_at', 'outOfBed', false),
  ];
  static const _factors = <(String, String)>[
    ('caffeine_after_cutoff', 'caffeineAfterCutoff'),
    ('alcohol_at_night', 'alcoholAtNight'),
    ('late_screen_exposure', 'lateScreenExposure'),
    ('morning_light_done', 'morningLightDone'),
    ('heavy_dinner', 'heavyDinner'),
    ('intense_exercise_late', 'intenseExerciseLate'),
    ('hot_bath_done', 'hotBathDone'),
    ('stretching_done', 'stretchingDone'),
    ('white_noise_used', 'whiteNoiseUsed'),
    ('bedroom_too_hot', 'bedroomTooHot'),
    ('bedroom_too_bright', 'bedroomTooBright'),
    ('bedroom_too_noisy', 'bedroomTooNoisy'),
    ('clock_checking', 'clockChecking'),
  ];

  @override
  void initState() {
    super.initState();
    _notes = TextEditingController(
      text: widget.draft.value('notes') as String?,
    );
    _numberControllers = {
      for (final field in _numbers)
        field.$1: TextEditingController(
          text: widget.draft.value(field.$1)?.toString() ?? '',
        ),
    };
  }

  @override
  void didUpdateWidget(covariant SleepLogDetailForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Quick answers and detailed fields edit the same draft.
    for (final entry in _numberControllers.entries) {
      final value = widget.draft.value(entry.key);
      if (int.tryParse(entry.value.text) != value) {
        entry.value.text = value?.toString() ?? '';
      }
    }
  }

  @override
  void dispose() {
    _notes.dispose();
    for (final controller in _numberControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _set(String key, Object? value) {
    setState(() => widget.draft.set(key, value));
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SleepDayPanel(
        title: widget.i18n.t('toolbox.sleep.log.timeline'),
        children: [for (final item in _times) _time(item.$1, item.$2, item.$3)],
      ),
      SleepDayPanel(
        title: widget.i18n.t('toolbox.sleep.log.commonValues'),
        children: [
          for (final item in _numbers) _number(item.$1, item.$2),
          for (final item in <(String, String, int)>[
            ('morning_energy', 'morningEnergy', 1),
            ('daytime_sleepiness', 'daytimeSleepiness', 1),
            ('stress_peak_level', 'stressPeak', 0),
            ('worry_load_level', 'worryLoad', 0),
          ])
            _score(item.$1, item.$2, item.$3),
        ],
      ),
      SleepDayPanel(
        title: widget.i18n.t('toolbox.sleep.log.behaviorEnv'),
        children: [
          for (final item in _factors)
            SleepDayBoolField(
              title: sleepDailyFactorTitle(widget.i18n, item.$2),
              value: widget.draft.value(item.$1) as bool?,
              i18n: widget.i18n,
              onChanged: (value) => _set(item.$1, value),
            ),
        ],
      ),
      _notesPanel(),
    ],
  );

  Widget _time(String key, String label, bool bedtimeSide) {
    final stored = widget.draft.value(key) as String?;
    final time = timeOfDayFromDateTime(
      stored == null ? null : DateTime.tryParse(stored),
    );
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(widget.i18n.t('toolbox.sleep.log.$label')),
      subtitle: Text(
        time == null
            ? widget.i18n.t('toolbox.sleep.day.unknown')
            : sleepTimeOfDayLabel(time),
      ),
      trailing: time == null
          ? const Icon(Icons.schedule_rounded)
          : IconButton(
              tooltip: widget.i18n.t('toolbox.sleep.day.clear'),
              icon: const Icon(Icons.close_rounded),
              onPressed: () => _set(key, null),
            ),
      onTap: () async {
        final selected = await showTimePicker(
          context: context,
          initialTime: time ?? const TimeOfDay(hour: 8, minute: 0),
        );
        if (selected == null || !mounted) return;
        _set(
          key,
          sleepDateTimeFromTimeOfDay(
            widget.dateKey,
            selected,
            bedtimeSide: bedtimeSide,
          )?.toIso8601String(),
        );
      },
    );
  }

  Widget _number(String key, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      key: ValueKey(key),
      controller: _numberControllers[key],
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      decoration: InputDecoration(
        labelText: widget.i18n.t('toolbox.sleep.log.$label'),
        hintText: widget.i18n.t('toolbox.sleep.day.unknown'),
      ),
      onChanged: (value) => _set(key, int.tryParse(value)),
    ),
  );

  Widget _score(String key, String label, int minimum) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.i18n.t('toolbox.sleep.log.$label')),
        Wrap(
          spacing: 8,
          children: [
            for (var value = minimum; value <= 5; value++)
              ChoiceChip(
                label: Text('$value'),
                selected: widget.draft.value(key) == value,
                onSelected: (_) => _set(key, value),
              ),
            ActionChip(
              label: Text(widget.i18n.t('toolbox.sleep.day.clear')),
              onPressed: () => _set(key, null),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _notesPanel() => SleepDayPanel(
    title: widget.i18n.t('toolbox.sleep.log.contextNotes'),
    children: [
      TextField(
        controller: _notes,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: widget.i18n.t('toolbox.sleep.log.notesHint'),
        ),
        onChanged: (value) =>
            _set('notes', value.trim().isEmpty ? null : value.trim()),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final key in [
            'overtime',
            'roomHot',
            'noise',
            'travel',
            'reflux',
            'tagDreams',
          ])
            ActionChip(
              label: Text(widget.i18n.t('toolbox.sleep.log.$key')),
              onPressed: () {
                _notes.text = SleepLogDraft.appendNoteTag(
                  _notes.text,
                  widget.i18n.t('toolbox.sleep.log.$key'),
                );
                _set('notes', _notes.text);
              },
            ),
        ],
      ),
    ],
  );
}
