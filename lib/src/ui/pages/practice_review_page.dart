import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../models/practice_export_format.dart';
import '../../models/practice_session_record.dart';
import '../../models/word_entry.dart';
import '../../state/app_state.dart';
import '../modal_helpers.dart';
import '../ui_copy.dart';
import 'practice_support.dart';

enum _PracticeReviewRange { today, last7Days, last30Days, all }

class PracticeReviewPage extends StatefulWidget {
  const PracticeReviewPage({super.key});

  @override
  State<PracticeReviewPage> createState() => _PracticeReviewPageState();
}

class _PracticeReviewPageState extends State<PracticeReviewPage> {
  _PracticeReviewRange _range = _PracticeReviewRange.last7Days;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final i18n = AppI18n(state.uiLanguage);
    final now = DateTime.now();
    final filteredHistory = _filterHistory(state.practiceSessionHistory, now);
    final filteredNotebook = _filterNotebook(
      state.practiceWrongNotebookEntries,
      filteredHistory,
    );
    final reasonCounts = <String, int>{};
    for (final record in filteredHistory) {
      for (final entry in record.weakReasonCounts.entries) {
        reasonCounts.update(
          entry.key,
          (value) => value + entry.value,
          ifAbsent: () => entry.value,
        );
      }
    }
    final reviewed = filteredHistory.fold<int>(
      0,
      (sum, record) => sum + record.total,
    );
    final remembered = filteredHistory.fold<int>(
      0,
      (sum, record) => sum + record.remembered,
    );
    final accuracy = reviewed <= 0
        ? 0
        : ((remembered / reviewed) * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: Text(pickUiText(i18n, zh: '练习复盘', en: 'Practice review')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    pickUiText(i18n, zh: '时间范围', en: 'Time range'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _PracticeReviewRange.values
                        .map(
                          (range) => ChoiceChip(
                            label: Text(_rangeLabel(i18n, range)),
                            selected: _range == range,
                            onSelected: (selected) {
                              if (!selected) return;
                              setState(() {
                                _range = range;
                              });
                            },
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    pickUiText(i18n, zh: '练习总览', en: 'Practice overview'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      _StatChip(
                        icon: Icons.history_rounded,
                        value: '${filteredHistory.length}',
                        label: pickUiText(
                          i18n,
                          zh: '范围内会话',
                          en: 'Sessions in range',
                        ),
                      ),
                      _StatChip(
                        icon: Icons.menu_book_rounded,
                        value: '$reviewed',
                        label: pickUiText(i18n, zh: '复习词数', en: 'Reviewed'),
                      ),
                      _StatChip(
                        icon: Icons.query_stats_rounded,
                        value: '$accuracy%',
                        label: pickUiText(i18n, zh: '范围正确率', en: 'Accuracy'),
                      ),
                      _StatChip(
                        icon: Icons.bookmarks_rounded,
                        value: '${filteredNotebook.length}',
                        label: pickUiText(
                          i18n,
                          zh: '范围错题',
                          en: 'Notebook words',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      FilledButton.icon(
                        onPressed: () => _export(
                          context,
                          i18n,
                          PracticeExportFormat.json,
                          filteredHistory,
                          filteredNotebook,
                        ),
                        icon: const Icon(Icons.data_object_rounded),
                        label: Text(
                          pickUiText(i18n, zh: '导出 JSON', en: 'Export JSON'),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _export(
                          context,
                          i18n,
                          PracticeExportFormat.csv,
                          filteredHistory,
                          filteredNotebook,
                        ),
                        icon: const Icon(Icons.table_view_rounded),
                        label: Text(
                          pickUiText(i18n, zh: '导出 CSV', en: 'Export CSV'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    pickUiText(i18n, zh: '薄弱原因分布', en: 'Weak reason breakdown'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (reasonCounts.isEmpty)
                    Text(
                      pickUiText(
                        i18n,
                        zh: '当前时间范围内还没有足够的会话数据。',
                        en: 'There is not enough session data in the selected range yet.',
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          (reasonCounts.entries.toList(growable: false)..sort(
                                (left, right) =>
                                    right.value.compareTo(left.value),
                              ))
                              .map(
                                (entry) => Chip(
                                  avatar: Icon(
                                    practiceWeakReasonIcon(entry.key),
                                    size: 16,
                                  ),
                                  label: Text(
                                    '${practiceWeakReasonLabel(i18n, entry.key)} x ${entry.value}',
                                  ),
                                ),
                              )
                              .toList(growable: false),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    pickUiText(i18n, zh: '范围内会话', en: 'Sessions in range'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (filteredHistory.isEmpty)
                    Text(
                      pickUiText(
                        i18n,
                        zh: '当前时间范围内还没有练习记录。',
                        en: 'No practice sessions in the selected range.',
                      ),
                    )
                  else
                    ...filteredHistory.map(
                      (record) => _HistoryTile(i18n: i18n, record: record),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PracticeSessionRecord> _filterHistory(
    List<PracticeSessionRecord> source,
    DateTime now,
  ) {
    final todayStart = DateTime(now.year, now.month, now.day);
    final rangeStart = switch (_range) {
      _PracticeReviewRange.today => todayStart,
      _PracticeReviewRange.last7Days => todayStart.subtract(
        const Duration(days: 6),
      ),
      _PracticeReviewRange.last30Days => todayStart.subtract(
        const Duration(days: 29),
      ),
      _PracticeReviewRange.all => null,
    };
    if (rangeStart == null) {
      return source;
    }
    return source
        .where((record) => !record.practicedAt.toLocal().isBefore(rangeStart))
        .toList(growable: false);
  }

  List<WordEntry> _filterNotebook(
    List<WordEntry> notebook,
    List<PracticeSessionRecord> history,
  ) {
    if (_range == _PracticeReviewRange.all || history.isEmpty) {
      return notebook;
    }
    final relevantTitles = history.map((record) => record.title).toSet();
    if (relevantTitles.isEmpty) {
      return const <WordEntry>[];
    }
    return notebook;
  }

  String _rangeLabel(AppI18n i18n, _PracticeReviewRange range) {
    return switch (range) {
      _PracticeReviewRange.today => pickUiText(i18n, zh: '今天', en: 'Today'),
      _PracticeReviewRange.last7Days => pickUiText(
        i18n,
        zh: '近 7 天',
        en: 'Last 7 days',
      ),
      _PracticeReviewRange.last30Days => pickUiText(
        i18n,
        zh: '近 30 天',
        en: 'Last 30 days',
      ),
      _PracticeReviewRange.all => pickUiText(i18n, zh: '全部', en: 'All'),
    };
  }

  Future<void> _export(
    BuildContext context,
    AppI18n i18n,
    PracticeExportFormat format,
    List<PracticeSessionRecord> filteredHistory,
    List<WordEntry> filteredNotebook,
  ) async {
    final state = context.read<AppState>();
    final defaultDirectory = await state
        .getDefaultUserDataExportDirectoryPath();
    if (!context.mounted) {
      return;
    }
    final fileName = await showTextPromptDialog(
      context: context,
      title: pickUiText(i18n, zh: '导出文件名', en: 'Export file name'),
      subtitle: pickUiText(
        i18n,
        zh: '文件会默认保存到：$defaultDirectory',
        en: 'The file will be saved to: $defaultDirectory',
      ),
      initialValue: 'xianyushengxi_practice_review.${format.extension}',
      hintText: 'practice_review.${format.extension}',
      confirmText: pickUiText(i18n, zh: '导出', en: 'Export'),
    );
    if (fileName == null || fileName.trim().isEmpty) {
      return;
    }
    final path = await state.exportPracticeReviewData(
      format: format,
      fileName: fileName.trim(),
      records: filteredHistory,
      wrongNotebookEntries: filteredNotebook,
    );
    if (!context.mounted || path == null || path.trim().isEmpty) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          pickUiText(
            i18n,
            zh: '练习复盘已导出到：$path',
            en: 'Practice review exported to: $path',
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 132),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(value, style: theme.textTheme.titleMedium),
                Text(label, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.i18n, required this.record});

  final AppI18n i18n;
  final PracticeSessionRecord record;

  @override
  Widget build(BuildContext context) {
    final reasonEntries = record.weakReasonCounts.entries.toList(
      growable: false,
    )..sort((left, right) => right.value.compareTo(left.value));
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  record.title.isEmpty
                      ? pickUiText(i18n, zh: '练习会话', en: 'Practice session')
                      : record.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                formatPracticeDateTime(i18n, record.practicedAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            pickUiText(
              i18n,
              zh: '正确率 ${(record.accuracy * 100).round()}% · 记住 ${record.remembered}/${record.total} · 错题 ${record.weakCount}',
              en: 'Accuracy ${(record.accuracy * 100).round()}% · ${record.remembered}/${record.total} remembered · ${record.weakCount} weak',
            ),
          ),
          if (reasonEntries.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: reasonEntries
                  .take(4)
                  .map(
                    (entry) => Chip(
                      visualDensity: VisualDensity.compact,
                      avatar: Icon(practiceWeakReasonIcon(entry.key), size: 16),
                      label: Text(
                        '${practiceWeakReasonLabel(i18n, entry.key)} x ${entry.value}',
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}
