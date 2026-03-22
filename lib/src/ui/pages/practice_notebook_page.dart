import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../models/practice_export_format.dart';
import '../../models/word_entry.dart';
import '../../models/word_memory_progress.dart';
import '../../state/app_state.dart';
import '../modal_helpers.dart';
import '../ui_copy.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/page_header.dart';
import '../widgets/word_row.dart';
import 'follow_along_page.dart';
import 'practice_session_page.dart';
import 'practice_support.dart';

enum _PracticeNotebookOrder { notebook, dueFirst, weakFirst, alphabetical }

enum _PracticeNotebookStatusFilter { all, due, mastered }

class PracticeNotebookPage extends StatefulWidget {
  const PracticeNotebookPage({super.key});

  @override
  State<PracticeNotebookPage> createState() => _PracticeNotebookPageState();
}

class _PracticeNotebookPageState extends State<PracticeNotebookPage> {
  final TextEditingController _queryController = TextEditingController();
  _PracticeNotebookOrder _order = _PracticeNotebookOrder.notebook;
  _PracticeNotebookStatusFilter _statusFilter =
      _PracticeNotebookStatusFilter.all;
  String _query = '';
  String _reasonFilter = '';
  int? _wordbookFilterId;
  bool _selectionMode = false;
  final Set<String> _selectedEntryKeys = <String>{};

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final i18n = AppI18n(state.uiLanguage);
    final now = DateTime.now();
    final notebookWords = state.practiceWrongNotebookEntries;
    final filteredWords = _filteredWords(state, notebookWords, now: now);
    final orderedWords = _orderedWords(state, filteredWords, now: now);
    final dueCount = orderedWords
        .where((entry) => _isDue(state.memoryProgressForWordEntry(entry), now))
        .length;
    final masteredCount = orderedWords
        .where((entry) => _isMastered(state, entry, now))
        .length;
    final wordbookCount = orderedWords
        .map((entry) => entry.wordbookId)
        .toSet()
        .length;
    final notebookWordbookIds =
        notebookWords
            .map((entry) => entry.wordbookId)
            .toSet()
            .toList(growable: false)
          ..sort();
    final selectedEntries = orderedWords
        .where((entry) => _selectedEntryKeys.contains(_entryKey(entry)))
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(pickUiText(i18n, zh: '错题本', en: 'Wrong notebook')),
        actions: notebookWords.isEmpty
            ? null
            : <Widget>[
                if (_selectionMode)
                  IconButton(
                    tooltip: pickUiText(i18n, zh: '全选当前结果', en: 'Select all'),
                    onPressed: orderedWords.isEmpty
                        ? null
                        : () {
                            setState(() {
                              _selectedEntryKeys
                                ..clear()
                                ..addAll(orderedWords.map(_entryKey));
                            });
                          },
                    icon: const Icon(Icons.select_all_rounded),
                  ),
                IconButton(
                  tooltip: _selectionMode
                      ? pickUiText(i18n, zh: '退出多选', en: 'Exit multi-select')
                      : pickUiText(i18n, zh: '批量操作', en: 'Batch actions'),
                  onPressed: () {
                    setState(() {
                      _selectionMode = !_selectionMode;
                      if (!_selectionMode) {
                        _selectedEntryKeys.clear();
                      }
                    });
                  },
                  icon: Icon(
                    _selectionMode
                        ? Icons.checklist_rtl_rounded
                        : Icons.playlist_add_check_circle_rounded,
                  ),
                ),
              ],
      ),
      body: notebookWords.isEmpty
          ? EmptyStateView(
              icon: Icons.bookmark_remove_outlined,
              title: pickUiText(
                i18n,
                zh: '错题本还是空的',
                en: 'Wrong notebook is empty',
              ),
              message: pickUiText(
                i18n,
                zh: '在练习会话里点击“没记住”后，单词会自动进入这里，方便后续集中复习。',
                en: 'Words you mark as "Not yet" during practice will collect here for focused review.',
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: <Widget>[
                PageHeader(
                  eyebrow: pickUiText(i18n, zh: '练习中心', en: 'Practice hub'),
                  title: pickUiText(i18n, zh: '错题本', en: 'Wrong notebook'),
                  subtitle: pickUiText(
                    i18n,
                    zh: '集中管理近期没记住的单词，支持错题顺序、到期优先、薄弱优先和随机练习。',
                    en: 'Manage missed words in one place with notebook order, due-first, weak-first, and shuffle review.',
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
                          pickUiText(i18n, zh: '筛选与检索', en: 'Search & filter'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _queryController,
                          onChanged: (value) {
                            setState(() {
                              _query = value;
                            });
                          },
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search_rounded),
                            border: const OutlineInputBorder(),
                            labelText: pickUiText(
                              i18n,
                              zh: '搜索单词或词义',
                              en: 'Search word or meaning',
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            ChoiceChip(
                              label: Text(
                                pickUiText(i18n, zh: '全部状态', en: 'All status'),
                              ),
                              selected:
                                  _statusFilter ==
                                  _PracticeNotebookStatusFilter.all,
                              onSelected: (_) {
                                setState(() {
                                  _statusFilter =
                                      _PracticeNotebookStatusFilter.all;
                                });
                              },
                            ),
                            ChoiceChip(
                              label: Text(
                                pickUiText(i18n, zh: '待复习', en: 'Due now'),
                              ),
                              selected:
                                  _statusFilter ==
                                  _PracticeNotebookStatusFilter.due,
                              onSelected: (_) {
                                setState(() {
                                  _statusFilter =
                                      _PracticeNotebookStatusFilter.due;
                                });
                              },
                            ),
                            ChoiceChip(
                              label: Text(
                                pickUiText(i18n, zh: '已掌握', en: 'Mastered'),
                              ),
                              selected:
                                  _statusFilter ==
                                  _PracticeNotebookStatusFilter.mastered,
                              onSelected: (_) {
                                setState(() {
                                  _statusFilter =
                                      _PracticeNotebookStatusFilter.mastered;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            ChoiceChip(
                              label: Text(
                                pickUiText(i18n, zh: '全部原因', en: 'All reasons'),
                              ),
                              selected: _reasonFilter.isEmpty,
                              onSelected: (_) {
                                setState(() {
                                  _reasonFilter = '';
                                });
                              },
                            ),
                            ...practiceWeakReasonIds.map(
                              (reasonId) => ChoiceChip(
                                label: Text(
                                  practiceWeakReasonLabel(i18n, reasonId),
                                ),
                                selected: _reasonFilter == reasonId,
                                onSelected: (_) {
                                  setState(() {
                                    _reasonFilter = reasonId;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        if (notebookWordbookIds.length > 1) ...<Widget>[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int?>(
                            value: _wordbookFilterId,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: pickUiText(
                                i18n,
                                zh: '词库筛选',
                                en: 'Wordbook filter',
                              ),
                            ),
                            items: <DropdownMenuItem<int?>>[
                              DropdownMenuItem<int?>(
                                value: null,
                                child: Text(
                                  pickUiText(
                                    i18n,
                                    zh: '全部词库',
                                    en: 'All wordbooks',
                                  ),
                                ),
                              ),
                              ...notebookWordbookIds.map(
                                (wordbookId) => DropdownMenuItem<int?>(
                                  value: wordbookId,
                                  child: Text(
                                    _wordbookNameById(state, wordbookId),
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _wordbookFilterId = value;
                              });
                            },
                          ),
                        ],
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
                          pickUiText(i18n, zh: '错题本概览', en: 'Notebook summary'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: <Widget>[
                            _buildStatChip(
                              context,
                              icon: Icons.bookmarks_rounded,
                              value: '${orderedWords.length}',
                              label: pickUiText(
                                i18n,
                                zh: '错题数',
                                en: 'Notebook words',
                              ),
                            ),
                            _buildStatChip(
                              context,
                              icon: Icons.schedule_rounded,
                              value: '$dueCount',
                              label: pickUiText(i18n, zh: '待复习', en: 'Due now'),
                            ),
                            _buildStatChip(
                              context,
                              icon: Icons.task_alt_rounded,
                              value: '$masteredCount',
                              label: pickUiText(
                                i18n,
                                zh: '可清理',
                                en: 'Ready to clear',
                              ),
                            ),
                            _buildStatChip(
                              context,
                              icon: Icons.layers_rounded,
                              value: '$wordbookCount',
                              label: pickUiText(
                                i18n,
                                zh: '涉及词库',
                                en: 'Wordbooks',
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
                          pickUiText(i18n, zh: '练习顺序', en: 'Review order'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _PracticeNotebookOrder.values
                              .map(
                                (order) => ChoiceChip(
                                  label: Text(_orderLabel(i18n, order)),
                                  selected: _order == order,
                                  onSelected: (selected) {
                                    if (!selected) return;
                                    setState(() {
                                      _order = order;
                                    });
                                  },
                                ),
                              )
                              .toList(growable: false),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: <Widget>[
                            FilledButton.icon(
                              onPressed: () => _openPractice(
                                context,
                                i18n,
                                orderedWords,
                                shuffle: false,
                              ),
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: Text(
                                pickUiText(
                                  i18n,
                                  zh: '按当前顺序开始',
                                  en: 'Start review',
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _openPractice(
                                context,
                                i18n,
                                orderedWords,
                                shuffle: true,
                              ),
                              icon: const Icon(Icons.shuffle_rounded),
                              label: Text(
                                pickUiText(
                                  i18n,
                                  zh: '随机练习',
                                  en: 'Shuffle review',
                                ),
                              ),
                            ),
                            if (masteredCount > 0)
                              OutlinedButton.icon(
                                onPressed: () => _clearNotebook(
                                  context,
                                  i18n,
                                  masteredOnly: true,
                                ),
                                icon: const Icon(
                                  Icons.cleaning_services_rounded,
                                ),
                                label: Text(
                                  pickUiText(
                                    i18n,
                                    zh: '清理已掌握',
                                    en: 'Clear mastered',
                                  ),
                                ),
                              ),
                            OutlinedButton.icon(
                              onPressed: () => _clearNotebook(
                                context,
                                i18n,
                                masteredOnly: false,
                              ),
                              icon: const Icon(Icons.delete_sweep_rounded),
                              label: Text(
                                pickUiText(
                                  i18n,
                                  zh: '清空错题本',
                                  en: 'Clear notebook',
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: orderedWords.isEmpty
                                  ? null
                                  : () => _exportFiltered(
                                      context,
                                      i18n,
                                      orderedWords,
                                      PracticeExportFormat.json,
                                    ),
                              icon: const Icon(Icons.data_object_rounded),
                              label: Text(
                                pickUiText(
                                  i18n,
                                  zh: '导出当前筛选(JSON)',
                                  en: 'Export filtered (JSON)',
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: orderedWords.isEmpty
                                  ? null
                                  : () => _exportFiltered(
                                      context,
                                      i18n,
                                      orderedWords,
                                      PracticeExportFormat.csv,
                                    ),
                              icon: const Icon(Icons.table_view_rounded),
                              label: Text(
                                pickUiText(
                                  i18n,
                                  zh: '导出当前筛选(CSV)',
                                  en: 'Export filtered (CSV)',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_selectionMode) ...<Widget>[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            pickUiText(i18n, zh: '批量操作', en: 'Batch actions'),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            pickUiText(
                              i18n,
                              zh: '已选择 ${selectedEntries.length} 项，可批量加入任务本、加入收藏或移出错题本。',
                              en: '${selectedEntries.length} selected. Add to task, favorite, or remove from the notebook in one step.',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: <Widget>[
                              FilledButton.icon(
                                onPressed: selectedEntries.isEmpty
                                    ? null
                                    : () => _applyBatchTask(
                                        context,
                                        i18n,
                                        selectedEntries,
                                      ),
                                icon: const Icon(Icons.task_alt_rounded),
                                label: Text(
                                  pickUiText(
                                    i18n,
                                    zh: '加入任务本',
                                    en: 'Add to task',
                                  ),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: selectedEntries.isEmpty
                                    ? null
                                    : () => _applyBatchFavorite(
                                        context,
                                        i18n,
                                        selectedEntries,
                                      ),
                                icon: const Icon(Icons.favorite_rounded),
                                label: Text(
                                  pickUiText(
                                    i18n,
                                    zh: '加入收藏',
                                    en: 'Add favorite',
                                  ),
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: selectedEntries.isEmpty
                                    ? null
                                    : () => _applyBatchRemove(
                                        context,
                                        i18n,
                                        selectedEntries,
                                      ),
                                icon: const Icon(
                                  Icons.remove_circle_outline_rounded,
                                ),
                                label: Text(
                                  pickUiText(
                                    i18n,
                                    zh: '移出错题本',
                                    en: 'Remove from notebook',
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _selectedEntryKeys.clear();
                                  });
                                },
                                icon: const Icon(Icons.clear_all_rounded),
                                label: Text(
                                  pickUiText(
                                    i18n,
                                    zh: '清空选择',
                                    en: 'Clear selection',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    orderedWords.isEmpty
                        ? pickUiText(
                            i18n,
                            zh: '当前筛选条件下没有匹配项，试试清空搜索或切换筛选。',
                            en: 'No entries match the current filters. Try clearing search or changing the filters.',
                          )
                        : pickUiText(
                            i18n,
                            zh: '向左滑动单条错题可直接移出错题本。',
                            en: 'Swipe a word left to remove it from the notebook.',
                          ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                for (final word in orderedWords)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _selectionMode
                        ? _buildSelectableNotebookItem(
                            context,
                            state,
                            i18n,
                            word,
                            now,
                            selected: _selectedEntryKeys.contains(
                              _entryKey(word),
                            ),
                            showWordbookTag: wordbookCount > 1,
                          )
                        : Dismissible(
                            key: ValueKey<String>(
                              'practice-notebook:${word.wordbookId}:${word.word}',
                            ),
                            direction: DismissDirection.endToStart,
                            background: _buildDismissBackground(context, i18n),
                            onDismissed: (_) {
                              final removed = state.dismissPracticeWeakWord(
                                word,
                              );
                              final message = removed
                                  ? pickUiText(
                                      i18n,
                                      zh: '${word.word} 已移出错题本',
                                      en: '${word.word} removed from notebook',
                                    )
                                  : pickUiText(
                                      i18n,
                                      zh: '错题本未发生变化',
                                      en: 'Notebook was not changed',
                                    );
                              if (!mounted) return;
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text(message)));
                            },
                            child: _buildNotebookItem(
                              context,
                              state,
                              i18n,
                              word,
                              now,
                              showWordbookTag: wordbookCount > 1,
                            ),
                          ),
                  ),
              ],
            ),
    );
  }

  List<WordEntry> _filteredWords(
    AppState state,
    List<WordEntry> source, {
    required DateTime now,
  }) {
    final normalizedQuery = normalizePracticeAnswer(_query);
    return source
        .where((entry) {
          if (_wordbookFilterId != null &&
              entry.wordbookId != _wordbookFilterId) {
            return false;
          }
          if (_statusFilter == _PracticeNotebookStatusFilter.due &&
              !_isDue(state.memoryProgressForWordEntry(entry), now)) {
            return false;
          }
          if (_statusFilter == _PracticeNotebookStatusFilter.mastered &&
              !_isMastered(state, entry, now)) {
            return false;
          }
          if (_reasonFilter.isNotEmpty &&
              !state
                  .practiceWeakReasonsForWord(entry)
                  .contains(_reasonFilter)) {
            return false;
          }
          if (normalizedQuery.isEmpty) {
            return true;
          }
          final haystacks = <String>[
            entry.word,
            practiceMeaningText(entry),
            entry.rawContent,
          ].map(normalizePracticeAnswer);
          return haystacks.any((value) => value.contains(normalizedQuery));
        })
        .toList(growable: false);
  }

  String _wordbookNameById(AppState state, int wordbookId) {
    for (final wordbook in state.wordbooks) {
      if (wordbook.id == wordbookId) {
        return wordbook.name;
      }
    }
    return '#$wordbookId';
  }

  List<WordEntry> _orderedWords(
    AppState state,
    List<WordEntry> source, {
    required DateTime now,
  }) {
    if (source.length <= 1) {
      return source;
    }
    final ordered = List<WordEntry>.from(source);
    final sourceIndex = <String, int>{
      for (var index = 0; index < source.length; index += 1)
        _entryKey(source[index]): index,
    };

    int compareByStoredOrder(WordEntry left, WordEntry right) {
      final leftIndex = sourceIndex[_entryKey(left)] ?? source.length;
      final rightIndex = sourceIndex[_entryKey(right)] ?? source.length;
      return leftIndex.compareTo(rightIndex);
    }

    int compareByDue(WordEntry left, WordEntry right) {
      final leftProgress = state.memoryProgressForWordEntry(left);
      final rightProgress = state.memoryProgressForWordEntry(right);
      final leftDue = _isDue(leftProgress, now);
      final rightDue = _isDue(rightProgress, now);
      if (leftDue != rightDue) {
        return leftDue ? -1 : 1;
      }

      final leftNext = leftProgress?.nextReview;
      final rightNext = rightProgress?.nextReview;
      if (leftNext == null && rightNext != null) {
        return -1;
      }
      if (leftNext != null && rightNext == null) {
        return 1;
      }
      if (leftNext != null && rightNext != null) {
        final nextOrder = leftNext.compareTo(rightNext);
        if (nextOrder != 0) {
          return nextOrder;
        }
      }

      final leftLast = leftProgress?.lastPlayed;
      final rightLast = rightProgress?.lastPlayed;
      if (leftLast != null && rightLast != null) {
        final lastOrder = rightLast.compareTo(leftLast);
        if (lastOrder != 0) {
          return lastOrder;
        }
      } else if (leftLast != null || rightLast != null) {
        return leftLast == null ? 1 : -1;
      }

      return compareByStoredOrder(left, right);
    }

    int compareByWeakness(WordEntry left, WordEntry right) {
      final leftProgress = state.memoryProgressForWordEntry(left);
      final rightProgress = state.memoryProgressForWordEntry(right);
      final accuracyOrder = _accuracy(
        leftProgress,
      ).compareTo(_accuracy(rightProgress));
      if (accuracyOrder != 0) {
        return accuracyOrder;
      }

      final leftPlayed = leftProgress?.timesPlayed ?? 0;
      final rightPlayed = rightProgress?.timesPlayed ?? 0;
      if (leftPlayed != rightPlayed) {
        return rightPlayed.compareTo(leftPlayed);
      }

      final dueOrder = compareByDue(left, right);
      if (dueOrder != 0) {
        return dueOrder;
      }

      return compareByStoredOrder(left, right);
    }

    switch (_order) {
      case _PracticeNotebookOrder.notebook:
        return ordered;
      case _PracticeNotebookOrder.dueFirst:
        ordered.sort(compareByDue);
        return ordered;
      case _PracticeNotebookOrder.weakFirst:
        ordered.sort(compareByWeakness);
        return ordered;
      case _PracticeNotebookOrder.alphabetical:
        ordered.sort(
          (left, right) =>
              left.word.toLowerCase().compareTo(right.word.toLowerCase()),
        );
        return ordered;
    }
  }

  Widget _buildNotebookItem(
    BuildContext context,
    AppState state,
    AppI18n i18n,
    WordEntry word,
    DateTime now, {
    required bool showWordbookTag,
    VoidCallback? onTapOverride,
  }) {
    final progress = state.memoryProgressForWordEntry(word);
    final metadata = <Widget>[
      _buildMetaChip(
        context,
        label: _dueLabel(i18n, progress, now),
        icon: _isDue(progress, now)
            ? Icons.schedule_rounded
            : Icons.event_available_rounded,
      ),
    ];

    final timesPlayed = progress?.timesPlayed ?? 0;
    if (timesPlayed > 0) {
      metadata.add(
        _buildMetaChip(
          context,
          label: pickUiText(
            i18n,
            zh: '正确率 ${(_accuracy(progress) * 100).round()}%',
            en: 'Accuracy ${(_accuracy(progress) * 100).round()}%',
          ),
          icon: Icons.query_stats_rounded,
        ),
      );
    }

    final lastPlayed = progress?.lastPlayed;
    if (lastPlayed != null) {
      metadata.add(
        _buildMetaChip(
          context,
          label: pickUiText(
            i18n,
            zh: '上次 ${_formatMonthDay(lastPlayed)}',
            en: 'Last ${_formatMonthDay(lastPlayed)}',
          ),
          icon: Icons.history_rounded,
        ),
      );
    }

    if (showWordbookTag) {
      metadata.add(
        _buildMetaChip(
          context,
          label: _wordbookName(state, word),
          icon: Icons.library_books_rounded,
        ),
      );
    }
    final weakReasons = state.practiceWeakReasonsForWord(word);
    for (final reason in weakReasons.take(3)) {
      metadata.add(
        _buildMetaChip(
          context,
          label: practiceWeakReasonLabel(i18n, reason),
          icon: practiceWeakReasonIcon(reason),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        WordRow(
          word: word,
          i18n: i18n,
          selected: false,
          showMeaning: state.config.showText,
          showFields: state.config.showText,
          isFavorite: state.favorites.contains(word.word),
          isTaskWord: state.taskWords.contains(word.word),
          onTap: onTapOverride ?? () => state.selectWordEntry(word),
          onPlay: () => state.previewPronunciation(word.word),
          onFollowAlong: () => _openFollowAlong(context, state, word),
          onToggleFavorite: () => state.toggleFavorite(word),
          onToggleTask: () => state.toggleTaskWord(word),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: metadata),
      ],
    );
  }

  Widget _buildSelectableNotebookItem(
    BuildContext context,
    AppState state,
    AppI18n i18n,
    WordEntry word,
    DateTime now, {
    required bool selected,
    required bool showWordbookTag,
  }) {
    return Stack(
      children: <Widget>[
        _buildNotebookItem(
          context,
          state,
          i18n,
          word,
          now,
          showWordbookTag: showWordbookTag,
          onTapOverride: () => _toggleSelection(word),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: Checkbox.adaptive(
            value: selected,
            onChanged: (_) => _toggleSelection(word),
          ),
        ),
      ],
    );
  }

  Widget _buildDismissBackground(BuildContext context, AppI18n i18n) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error),
          const SizedBox(width: 8),
          Text(
            pickUiText(i18n, zh: '移出错题本', en: 'Remove'),
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
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
              mainAxisSize: MainAxisSize.min,
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

  Widget _buildMetaChip(
    BuildContext context, {
    required String label,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }

  Future<void> _openPractice(
    BuildContext context,
    AppI18n i18n,
    List<WordEntry> words, {
    required bool shuffle,
  }) async {
    if (words.isEmpty) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PracticeSessionPage(
          title: pickUiText(i18n, zh: '错题本练习', en: 'Wrong notebook review'),
          subtitle: pickUiText(
            i18n,
            zh: '共 ${words.length} 个错题 · ${_orderLabel(i18n, _order)}',
            en: '${words.length} notebook words · ${_orderLabel(i18n, _order)}',
          ),
          words: words,
          shuffle: shuffle,
        ),
      ),
    );
  }

  Future<void> _exportFiltered(
    BuildContext context,
    AppI18n i18n,
    List<WordEntry> entries,
    PracticeExportFormat format,
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
      initialValue: 'xianyushengxi_wrong_notebook.${format.extension}',
      confirmText: pickUiText(i18n, zh: '导出', en: 'Export'),
    );
    if (fileName == null || fileName.trim().isEmpty) {
      return;
    }
    final path = await state.exportPracticeWrongNotebookData(
      entries: entries,
      format: format,
      fileName: fileName.trim(),
    );
    if (!context.mounted || path == null || path.trim().isEmpty) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          pickUiText(
            i18n,
            zh: '错题本筛选结果已导出到：$path',
            en: 'Filtered notebook results exported to: $path',
          ),
        ),
      ),
    );
  }

  void _toggleSelection(WordEntry word) {
    final key = _entryKey(word);
    setState(() {
      if (_selectedEntryKeys.contains(key)) {
        _selectedEntryKeys.remove(key);
      } else {
        _selectedEntryKeys.add(key);
      }
    });
  }

  Future<void> _applyBatchTask(
    BuildContext context,
    AppI18n i18n,
    List<WordEntry> selectedEntries,
  ) async {
    final added = await context.read<AppState>().addPracticeWordsToTask(
      selectedEntries,
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added <= 0
              ? pickUiText(
                  i18n,
                  zh: '所选单词已全部在任务本中',
                  en: 'All selected words are already in the task list.',
                )
              : pickUiText(
                  i18n,
                  zh: '已加入任务本：$added 项',
                  en: 'Added to task list: $added',
                ),
        ),
      ),
    );
  }

  Future<void> _applyBatchFavorite(
    BuildContext context,
    AppI18n i18n,
    List<WordEntry> selectedEntries,
  ) async {
    final added = await context.read<AppState>().addPracticeWordsToFavorites(
      selectedEntries,
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added <= 0
              ? pickUiText(
                  i18n,
                  zh: '所选单词已全部在收藏中',
                  en: 'All selected words are already favorited.',
                )
              : pickUiText(
                  i18n,
                  zh: '已加入收藏：$added 项',
                  en: 'Added to favorites: $added',
                ),
        ),
      ),
    );
  }

  Future<void> _applyBatchRemove(
    BuildContext context,
    AppI18n i18n,
    List<WordEntry> selectedEntries,
  ) async {
    final removed = context.read<AppState>().dismissPracticeWeakWords(
      selectedEntries,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedEntryKeys.removeAll(selectedEntries.map(_entryKey));
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          removed <= 0
              ? pickUiText(
                  i18n,
                  zh: '所选条目未发生变化',
                  en: 'Selected entries were not changed.',
                )
              : pickUiText(
                  i18n,
                  zh: '已移出错题本：$removed 项',
                  en: 'Removed from notebook: $removed',
                ),
        ),
      ),
    );
  }

  Future<void> _openFollowAlong(
    BuildContext context,
    AppState state,
    WordEntry word,
  ) async {
    state.selectWordEntry(word);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => FollowAlongPage(word: word)),
    );
  }

  Future<void> _clearNotebook(
    BuildContext context,
    AppI18n i18n, {
    required bool masteredOnly,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            masteredOnly
                ? pickUiText(i18n, zh: '清理已掌握错题', en: 'Clear mastered words')
                : pickUiText(i18n, zh: '清空错题本', en: 'Clear notebook'),
          ),
          content: Text(
            masteredOnly
                ? pickUiText(
                    i18n,
                    zh: '会从错题本移除当前已稳定掌握的单词，保留仍需复习的部分。',
                    en: 'This removes words that look stable now and keeps the ones that still need review.',
                  )
                : pickUiText(
                    i18n,
                    zh: '会移除错题本中的全部单词，但不会删除词库本身和历史记忆进度。',
                    en: 'This removes all notebook entries but does not delete the wordbook data or memory history.',
                  ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(pickUiText(i18n, zh: '取消', en: 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(pickUiText(i18n, zh: '继续', en: 'Continue')),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final removed = context.read<AppState>().clearPracticeWeakWords(
      masteredOnly: masteredOnly,
    );
    final message = removed <= 0
        ? pickUiText(
            i18n,
            zh: '错题本没有可清理的内容',
            en: 'There is nothing to clear in the notebook.',
          )
        : masteredOnly
        ? pickUiText(
            i18n,
            zh: '已清理 $removed 个已掌握错题',
            en: 'Cleared $removed mastered notebook words',
          )
        : pickUiText(
            i18n,
            zh: '已清空 $removed 个错题',
            en: 'Cleared $removed notebook words',
          );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _orderLabel(AppI18n i18n, _PracticeNotebookOrder order) {
    return switch (order) {
      _PracticeNotebookOrder.notebook => pickUiText(
        i18n,
        zh: '错题顺序',
        en: 'Notebook order',
      ),
      _PracticeNotebookOrder.dueFirst => pickUiText(
        i18n,
        zh: '到期优先',
        en: 'Due first',
      ),
      _PracticeNotebookOrder.weakFirst => pickUiText(
        i18n,
        zh: '薄弱优先',
        en: 'Weak first',
      ),
      _PracticeNotebookOrder.alphabetical => pickUiText(
        i18n,
        zh: '字母顺序',
        en: 'A-Z',
      ),
    };
  }

  String _dueLabel(AppI18n i18n, WordMemoryProgress? progress, DateTime now) {
    if (_isDue(progress, now)) {
      return pickUiText(i18n, zh: '待复习', en: 'Due now');
    }
    final nextReview = progress?.nextReview;
    if (nextReview == null) {
      return pickUiText(i18n, zh: '待安排', en: 'Need schedule');
    }
    return pickUiText(
      i18n,
      zh: '下次 ${_formatMonthDay(nextReview)}',
      en: 'Next ${_formatMonthDay(nextReview)}',
    );
  }

  bool _isDue(WordMemoryProgress? progress, DateTime now) {
    final nextReview = progress?.nextReview;
    if (nextReview == null) {
      return true;
    }
    return !nextReview.isAfter(now);
  }

  bool _isMastered(AppState state, WordEntry word, DateTime now) {
    final key = word.word.trim().toLowerCase();
    final remembered = state.practiceRememberedWords
        .map((item) => item.trim().toLowerCase())
        .toSet();
    if (remembered.contains(key)) {
      return true;
    }
    final progress = state.memoryProgressForWordEntry(word);
    if (progress == null || !progress.isTracked) {
      return false;
    }
    if (progress.timesCorrect <= 0 || progress.consecutiveCorrect <= 0) {
      return false;
    }
    final nextReview = progress.nextReview;
    if (nextReview == null) {
      return false;
    }
    return nextReview.isAfter(now);
  }

  double _accuracy(WordMemoryProgress? progress) {
    if (progress == null || progress.timesPlayed <= 0) {
      return 0;
    }
    return (progress.timesCorrect / progress.timesPlayed).clamp(0.0, 1.0);
  }

  String _entryKey(WordEntry entry) {
    final id = entry.id;
    if (id != null && id > 0) {
      return 'id:$id';
    }
    return 'wordbook:${entry.wordbookId}:${entry.word.trim().toLowerCase()}';
  }

  String _wordbookName(AppState state, WordEntry entry) {
    for (final wordbook in state.wordbooks) {
      if (wordbook.id == entry.wordbookId) {
        return wordbook.name;
      }
    }
    return '#${entry.wordbookId}';
  }

  String _formatMonthDay(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$month/$day';
  }
}
