import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../i18n/app_i18n.dart';
import '../../../models/sleep_daily_log.dart';
import '../../../state/app_state.dart';
import '../sleep_assistant_ui_support.dart';

class SleepThoughtLibraryPanel extends StatefulWidget {
  const SleepThoughtLibraryPanel({super.key, required this.i18n});

  final AppI18n i18n;

  @override
  State<SleepThoughtLibraryPanel> createState() =>
      _SleepThoughtLibraryPanelState();
}

class _SleepThoughtLibraryPanelState extends State<SleepThoughtLibraryPanel> {
  final _thought = TextEditingController();
  final _reframe = TextEditingController();
  int _intensity = 3;

  @override
  void dispose() {
    _thought.dispose();
    _reframe.dispose();
    super.dispose();
  }

  void _save() {
    final content = _thought.text.trim();
    if (content.isEmpty) return;
    context.read<AppState>().saveSleepThoughtEntry(
      SleepThoughtEntry(
        dateKey: todaySleepDateKey(),
        entryType: 'worry_unload',
        content: content,
        reframedContent: _reframe.text.trim().isEmpty
            ? null
            : _reframe.text.trim(),
        intensity: _intensity,
        createdAt: DateTime.now(),
      ),
    );
    _thought.clear();
    _reframe.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.i18n.t('toolbox.sleep.winddown.unloadSaved')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = widget.i18n;
    final entries = context.select<AppState, List<SleepThoughtEntry>>(
      (s) => s.sleepThoughtEntries,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _thought,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: i18n.t('toolbox.sleep.winddown.topThought'),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _reframe,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: i18n.t('toolbox.sleep.winddown.gentlerReframe'),
          ),
        ),
        const SizedBox(height: 16),
        Text(i18n.t('toolbox.sleep.winddown.intensity')),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var value = 1; value <= 5; value++)
              ChoiceChip(
                label: Text('$value'),
                selected: _intensity == value,
                materialTapTargetSize: MaterialTapTargetSize.padded,
                onSelected: (_) => setState(() => _intensity = value),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _thought,
          builder: (context, value, _) => FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: value.text.trim().isEmpty ? null : _save,
            icon: const Icon(Icons.edit_note_rounded),
            label: Text(i18n.t('toolbox.sleep.winddown.saveUnload')),
          ),
        ),
        if (entries.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(i18n.t('toolbox.sleep.winddown.recentUnload')),
          for (final entry in entries.take(4)) _recentEntry(context, entry),
        ],
      ],
    );
  }

  Widget _recentEntry(BuildContext context, SleepThoughtEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry.content),
          if (entry.reframedContent?.trim().isNotEmpty == true)
            Text(
              entry.reframedContent!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}
