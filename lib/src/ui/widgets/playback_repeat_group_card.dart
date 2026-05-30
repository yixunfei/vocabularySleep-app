import 'package:flutter/material.dart';

import '../../i18n/app_i18n.dart';
import '../ui_copy.dart';
import 'section_header.dart';

typedef PlaybackFieldLabelBuilder = String Function(String key);
typedef PlaybackRepeatValueChanged = void Function(String key, int value);
typedef PlaybackBatchApply = void Function(int value);

class PlaybackRepeatFieldGroup {
  const PlaybackRepeatFieldGroup({
    required this.title,
    required this.subtitle,
    required this.keys,
    this.quickValues = const <int>[],
  });

  final String title;
  final String subtitle;
  final List<String> keys;
  final List<int> quickValues;
}

class PlaybackRepeatGroupCard extends StatelessWidget {
  const PlaybackRepeatGroupCard({
    super.key,
    required this.i18n,
    required this.group,
    required this.repeats,
    required this.labelBuilder,
    required this.onChanged,
    required this.onApplyBatch,
  });

  final AppI18n i18n;
  final PlaybackRepeatFieldGroup group;
  final Map<String, int> repeats;
  final PlaybackFieldLabelBuilder labelBuilder;
  final PlaybackRepeatValueChanged onChanged;
  final PlaybackBatchApply onApplyBatch;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SectionHeader(title: group.title, subtitle: group.subtitle),
            if (group.quickValues.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: group.quickValues
                    .map(
                      (value) => FilledButton.tonal(
                        onPressed: () => onApplyBatch(value),
                        child: Text(_quickValueLabel(i18n, value)),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
            const SizedBox(height: 12),
            for (final key in group.keys) ...<Widget>[
              RepeatSlider(
                label: labelBuilder(key),
                value: repeats[key] ?? 0,
                onChanged: (value) => onChanged(key, value),
              ),
              if (key != group.keys.last) const SizedBox(height: 6),
            ],
          ],
        ),
      ),
    );
  }

  String _quickValueLabel(AppI18n i18n, int value) {
    return switch (value) {
      0 => i18n.t(
        'inline.ui.widgets.playback_repeat_group_card.set_all_to_0_7181f1',
      ),
      1 => i18n.t(
        'inline.ui.widgets.playback_repeat_group_card.set_all_to_1_1bb9a7',
      ),
      2 => i18n.t(
        'inline.ui.widgets.playback_repeat_group_card.set_all_to_2_bfd4bd',
      ),
      _ => i18n.t(
        'inline.ui.widgets.playback_repeat_group_card.set_all_to_value_774c60',
      ),
    };
  }
}

class RepeatSlider extends StatelessWidget {
  const RepeatSlider({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('$label: $value'),
        Slider(
          min: 0,
          max: 5,
          divisions: 5,
          value: value.toDouble(),
          onChanged: (next) => onChanged(next.round()),
        ),
      ],
    );
  }
}
