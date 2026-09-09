import 'package:flutter/material.dart';

import '../../../i18n/app_i18n.dart';

class SleepDayPanel extends StatelessWidget {
  const SleepDayPanel({super.key, required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    ),
  );
}

class SleepDayChoice<T> extends StatelessWidget {
  const SleepDayChoice({
    super.key,
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });
  final String label;
  final T value;
  final bool selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: selected
            ? Theme.of(context).colorScheme.secondaryContainer
            : null,
      ),
      onPressed: () => onSelected(value),
      child: Text(label, textAlign: TextAlign.center),
    ),
  );
}

class SleepDayBoolField extends StatelessWidget {
  const SleepDayBoolField({
    super.key,
    required this.title,
    required this.value,
    required this.i18n,
    required this.onChanged,
  });
  final String title;
  final bool? value;
  final AppI18n i18n;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in <(bool?, String)>[
              (true, 'toolbox.sleep.day.yes'),
              (false, 'toolbox.sleep.day.no'),
              (null, 'toolbox.sleep.day.unknown'),
            ])
              ChoiceChip(
                label: Text(i18n.t(entry.$2)),
                selected: value == entry.$1,
                materialTapTargetSize: MaterialTapTargetSize.padded,
                onSelected: (_) => onChanged(entry.$1),
              ),
          ],
        ),
      ],
    ),
  );
}
