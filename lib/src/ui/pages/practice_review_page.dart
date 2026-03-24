import 'dart:math' as math;

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

enum _PracticeTrendMetric { accuracy, reviewed, weak }

enum _PracticeTrendGrouping { session, weekly, monthly }

class PracticeReviewPage extends StatefulWidget {
  const PracticeReviewPage({super.key});

  @override
  State<PracticeReviewPage> createState() => _PracticeReviewPageState();
}

class _PracticeReviewPageState extends State<PracticeReviewPage> {
  _PracticeReviewRange _range = _PracticeReviewRange.last7Days;
  _PracticeTrendGrouping _grouping = _PracticeTrendGrouping.session;
  final Set<_PracticeTrendMetric> _trendMetrics = <_PracticeTrendMetric>{
    _PracticeTrendMetric.accuracy,
    _PracticeTrendMetric.reviewed,
  };
  int? _selectedTrendIndex;

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
    final trendBuckets = _buildTrendBuckets(filteredHistory);
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
                                _selectedTrendIndex = null;
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
          _buildTrendCard(context, i18n, trendBuckets),
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
                          metadata: <String, Object?>{
                            'range': _range.name,
                            'grouping': _grouping.name,
                            'metrics': _trendMetrics
                                .map((item) => item.name)
                                .toList(),
                          },
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
                          metadata: <String, Object?>{
                            'range': _range.name,
                            'grouping': _grouping.name,
                            'metrics': _trendMetrics
                                .map((item) => item.name)
                                .toList(),
                          },
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

  Widget _buildTrendCard(
    BuildContext context,
    AppI18n i18n,
    List<_TrendBucket> buckets,
  ) {
    final theme = Theme.of(context);
    final selectedIndex = buckets.isEmpty
        ? null
        : (_selectedTrendIndex == null
              ? buckets.length - 1
              : _selectedTrendIndex!.clamp(0, buckets.length - 1));
    final selectedBucket = selectedIndex == null
        ? null
        : buckets[selectedIndex];

    return Card(
      key: const ValueKey<String>('practice-trend-card'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              pickUiText(i18n, zh: '趋势卡片', en: 'Trend card'),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              pickUiText(
                i18n,
                zh: '支持多指标叠加和按会话/按周/按月聚合。点按节点或横向拖动可查看详细值。',
                en: 'Supports multi-metric overlays and session/weekly/monthly aggregation. Tap points or drag horizontally to inspect details.',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _PracticeTrendGrouping.values
                  .map(
                    (item) => ChoiceChip(
                      label: Text(_groupingLabel(i18n, item)),
                      selected: _grouping == item,
                      onSelected: (selected) {
                        if (!selected) {
                          return;
                        }
                        setState(() {
                          _grouping = item;
                          _selectedTrendIndex = null;
                        });
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _PracticeTrendMetric.values
                  .map(
                    (item) => FilterChip(
                      label: Text(_trendMetricLabel(i18n, item)),
                      selected: _trendMetrics.contains(item),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _trendMetrics.add(item);
                          } else if (_trendMetrics.length > 1) {
                            _trendMetrics.remove(item);
                          }
                        });
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 14),
            if (buckets.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  pickUiText(
                    i18n,
                    zh: '当前时间范围内没有可绘制的趋势数据。',
                    en: 'There is no trend data to plot in this time range.',
                  ),
                ),
              )
            else ...<Widget>[
              LayoutBuilder(
                builder: (context, constraints) {
                  final series = _trendMetrics
                      .map(
                        (metric) => _TrendSeries(
                          metric: metric,
                          color: _trendMetricColor(theme, metric),
                          values: buckets
                              .map(
                                (bucket) => _trendMetricValue(bucket, metric),
                              )
                              .toList(growable: false),
                        ),
                      )
                      .toList(growable: false);
                  return _InteractiveTrendChart(
                    width: constraints.maxWidth,
                    height: 220,
                    series: series,
                    selectedIndex: selectedIndex,
                    onSelect: (index) {
                      setState(() {
                        _selectedTrendIndex = index;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      selectedBucket == null ? '' : selectedBucket.label,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedBucket == null
                          ? ''
                          : _bucketSummary(i18n, selectedBucket),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _trendMetrics
                          .map(
                            (metric) => _MiniBadge(
                              label: _trendMetricLabel(i18n, metric),
                              value: _trendMetricValueLabel(
                                i18n,
                                metric,
                                selectedBucket == null
                                    ? null
                                    : _trendMetricValue(selectedBucket, metric),
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        _MiniBadge(
                          label: pickUiText(i18n, zh: '会话数', en: 'Sessions'),
                          value: '${selectedBucket?.sessionCount ?? 0}',
                        ),
                        _MiniBadge(
                          label: pickUiText(i18n, zh: '总词数', en: 'Reviewed'),
                          value: '${selectedBucket?.total ?? 0}',
                        ),
                        _MiniBadge(
                          label: pickUiText(i18n, zh: '错题', en: 'Weak'),
                          value: '${selectedBucket?.weakCount ?? 0}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<_TrendBucket> _buildTrendBuckets(List<PracticeSessionRecord> history) {
    final sorted = history.toList(growable: false)
      ..sort((left, right) => left.practicedAt.compareTo(right.practicedAt));
    if (sorted.isEmpty) {
      return const <_TrendBucket>[];
    }
    if (_grouping == _PracticeTrendGrouping.session) {
      return sorted
          .map(
            (record) => _TrendBucket(
              label: record.title.isEmpty
                  ? formatPracticeDateTime(AppI18n('en'), record.practicedAt)
                  : record.title,
              startAt: record.practicedAt,
              endAt: record.practicedAt,
              sessionCount: 1,
              total: record.total,
              remembered: record.remembered,
              weakReasonCounts: record.weakReasonCounts,
            ),
          )
          .toList(growable: false);
    }

    final grouped = <DateTime, List<PracticeSessionRecord>>{};
    for (final record in sorted) {
      final local = record.practicedAt.toLocal();
      final bucketKey = switch (_grouping) {
        _PracticeTrendGrouping.weekly => _startOfWeek(local),
        _PracticeTrendGrouping.monthly => DateTime(local.year, local.month),
        _PracticeTrendGrouping.session => local,
      };
      grouped
          .putIfAbsent(bucketKey, () => <PracticeSessionRecord>[])
          .add(record);
    }

    return grouped.entries
        .map((entry) {
          final records = entry.value;
          final total = records.fold<int>(0, (sum, item) => sum + item.total);
          final remembered = records.fold<int>(
            0,
            (sum, item) => sum + item.remembered,
          );
          final reasonCounts = <String, int>{};
          for (final record in records) {
            for (final reason in record.weakReasonCounts.entries) {
              reasonCounts.update(
                reason.key,
                (value) => value + reason.value,
                ifAbsent: () => reason.value,
              );
            }
          }
          final startAt = entry.key;
          final endAt = records.last.practicedAt.toLocal();
          return _TrendBucket(
            label: _grouping == _PracticeTrendGrouping.weekly
                ? _formatWeekLabel(startAt)
                : _formatMonthLabel(startAt),
            startAt: startAt,
            endAt: endAt,
            sessionCount: records.length,
            total: total,
            remembered: remembered,
            weakReasonCounts: reasonCounts,
          );
        })
        .toList(growable: false)
      ..sort((left, right) => left.startAt.compareTo(right.startAt));
  }

  DateTime _startOfWeek(DateTime value) {
    final offset = value.weekday - DateTime.monday;
    return DateTime(
      value.year,
      value.month,
      value.day,
    ).subtract(Duration(days: offset));
  }

  String _formatWeekLabel(DateTime value) {
    final start = _startOfWeek(value);
    final end = start.add(const Duration(days: 6));
    final sm = start.month.toString().padLeft(2, '0');
    final sd = start.day.toString().padLeft(2, '0');
    final em = end.month.toString().padLeft(2, '0');
    final ed = end.day.toString().padLeft(2, '0');
    return '$sm/$sd-$em/$ed';
  }

  String _formatMonthLabel(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    return '${value.year}-$month';
  }

  String _bucketSummary(AppI18n i18n, _TrendBucket bucket) {
    if (_grouping == _PracticeTrendGrouping.session) {
      return formatPracticeDateTime(i18n, bucket.startAt);
    }
    return pickUiText(
      i18n,
      zh: '包含 ${bucket.sessionCount} 次会话',
      en: '${bucket.sessionCount} sessions included',
    );
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

  String _groupingLabel(AppI18n i18n, _PracticeTrendGrouping grouping) {
    return switch (grouping) {
      _PracticeTrendGrouping.session => pickUiText(
        i18n,
        zh: '按会话',
        en: 'Per session',
      ),
      _PracticeTrendGrouping.weekly => pickUiText(i18n, zh: '按周', en: 'Weekly'),
      _PracticeTrendGrouping.monthly => pickUiText(
        i18n,
        zh: '按月',
        en: 'Monthly',
      ),
    };
  }

  String _trendMetricLabel(AppI18n i18n, _PracticeTrendMetric metric) {
    return switch (metric) {
      _PracticeTrendMetric.accuracy => pickUiText(
        i18n,
        zh: '正确率',
        en: 'Accuracy',
      ),
      _PracticeTrendMetric.reviewed => pickUiText(
        i18n,
        zh: '复习词数',
        en: 'Reviewed',
      ),
      _PracticeTrendMetric.weak => pickUiText(i18n, zh: '错题数', en: 'Weak'),
    };
  }

  double _trendMetricValue(_TrendBucket bucket, _PracticeTrendMetric metric) {
    return switch (metric) {
      _PracticeTrendMetric.accuracy => (bucket.accuracy * 100).clamp(
        0.0,
        100.0,
      ),
      _PracticeTrendMetric.reviewed => bucket.total.toDouble(),
      _PracticeTrendMetric.weak => bucket.weakCount.toDouble(),
    };
  }

  String _trendMetricValueLabel(
    AppI18n i18n,
    _PracticeTrendMetric metric,
    double? value,
  ) {
    final safeValue = (value ?? 0).round();
    return switch (metric) {
      _PracticeTrendMetric.accuracy => '$safeValue%',
      _PracticeTrendMetric.reviewed ||
      _PracticeTrendMetric.weak => '$safeValue',
    };
  }

  Color _trendMetricColor(ThemeData theme, _PracticeTrendMetric metric) {
    return switch (metric) {
      _PracticeTrendMetric.accuracy => theme.colorScheme.primary,
      _PracticeTrendMetric.reviewed => theme.colorScheme.tertiary,
      _PracticeTrendMetric.weak => theme.colorScheme.error,
    };
  }

  Future<void> _export(
    BuildContext context,
    AppI18n i18n,
    PracticeExportFormat format,
    List<PracticeSessionRecord> filteredHistory,
    List<WordEntry> filteredNotebook, {
    required Map<String, Object?> metadata,
  }) async {
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
      metadata: metadata,
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

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(value, style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _TrendBucket {
  const _TrendBucket({
    required this.label,
    required this.startAt,
    required this.endAt,
    required this.sessionCount,
    required this.total,
    required this.remembered,
    required this.weakReasonCounts,
  });

  final String label;
  final DateTime startAt;
  final DateTime endAt;
  final int sessionCount;
  final int total;
  final int remembered;
  final Map<String, int> weakReasonCounts;

  int get weakCount => (total - remembered).clamp(0, total);
  double get accuracy => total <= 0 ? 0 : remembered / total;
}

class _TrendSeries {
  const _TrendSeries({
    required this.metric,
    required this.color,
    required this.values,
  });

  final _PracticeTrendMetric metric;
  final Color color;
  final List<double> values;
}

class _InteractiveTrendChart extends StatelessWidget {
  const _InteractiveTrendChart({
    required this.width,
    required this.height,
    required this.series,
    required this.selectedIndex,
    required this.onSelect,
  });

  final double width;
  final double height;
  final List<_TrendSeries> series;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    int nearestIndex(Offset localPosition) {
      final sampleCount = series.isEmpty ? 0 : series.first.values.length;
      if (sampleCount <= 1) {
        return 0;
      }
      final spacing = width / (sampleCount - 1);
      final raw = (localPosition.dx / spacing).round();
      return raw.clamp(0, sampleCount - 1);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) => onSelect(nearestIndex(details.localPosition)),
      onHorizontalDragUpdate: (details) =>
          onSelect(nearestIndex(details.localPosition)),
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size(width, height),
          painter: _TrendChartPainter(
            series: series,
            selectedIndex: selectedIndex,
          ),
        ),
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  const _TrendChartPainter({required this.series, required this.selectedIndex});

  final List<_TrendSeries> series;
  final int? selectedIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final baseColor = series.isEmpty ? Colors.grey : series.first.color;
    final axisPaint = Paint()
      ..color = baseColor.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final gridStep = size.height / 4;
    for (var index = 0; index < 5; index += 1) {
      final y = index * gridStep;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), axisPaint);
    }

    if (series.isEmpty || series.first.values.isEmpty) {
      return;
    }
    if (series.first.values.length == 1) {
      final center = Offset(size.width / 2, size.height / 2);
      for (final item in series) {
        canvas.drawCircle(center, 6, Paint()..color = item.color);
      }
      return;
    }

    final sampleCount = series.first.values.length;
    for (final item in series) {
      final maxValue = item.values.reduce(math.max);
      final minValue = item.values.reduce(math.min);
      final range = (maxValue - minValue).abs() < 0.001
          ? 1.0
          : maxValue - minValue;
      final points = <Offset>[];
      for (var index = 0; index < item.values.length; index += 1) {
        final x = (size.width / (sampleCount - 1)) * index;
        final normalized = (item.values[index] - minValue) / range;
        final y = size.height - (normalized * (size.height - 16)) - 8;
        points.add(Offset(x, y));
      }

      final linePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (var index = 1; index < points.length; index += 1) {
        linePath.lineTo(points[index].dx, points[index].dy);
      }

      final linePaint = Paint()
        ..color = item.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(linePath, linePaint);

      for (var index = 0; index < points.length; index += 1) {
        final isSelected = selectedIndex == index;
        canvas.drawCircle(
          points[index],
          isSelected ? 6 : 4,
          Paint()
            ..color = isSelected
                ? item.color
                : item.color.withValues(alpha: 0.7),
        );
      }
    }

    if (selectedIndex != null &&
        selectedIndex! >= 0 &&
        selectedIndex! < sampleCount) {
      final x = (size.width / (sampleCount - 1)) * selectedIndex!;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = baseColor.withValues(alpha: 0.18)
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) {
    return oldDelegate.series != series ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}
