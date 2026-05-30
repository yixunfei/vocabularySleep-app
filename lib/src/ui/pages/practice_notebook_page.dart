import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/module_system/module_id.dart';
import '../../i18n/app_i18n.dart';
import '../../models/practice_export_format.dart';
import '../../models/word_entry.dart';
import '../../models/word_memory_progress.dart';
import '../../state/app_state.dart';
import '../../state/app_state_provider.dart';
import '../module/module_access.dart';
import '../modal_helpers.dart';
import '../ui_copy.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/page_header.dart';
import '../widgets/word_row.dart';
import 'follow_along_page.dart';
import 'practice_session_page.dart';
import 'practice_support.dart';

part 'practice_notebook_page_actions.dart';

enum _PracticeNotebookOrder { notebook, dueFirst, weakFirst, alphabetical }

enum _PracticeNotebookStatusFilter { all, due, mastered }

class PracticeNotebookPage extends ConsumerStatefulWidget {
  const PracticeNotebookPage({super.key});

  @override
  ConsumerState<PracticeNotebookPage> createState() =>
      _PracticeNotebookPageState();
}

class _PracticeNotebookPageState extends ConsumerState<PracticeNotebookPage> {
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
    final state = ref.watch(appStateProvider);
    final i18n = AppI18n(state.uiLanguage);
    if (!state.isModuleEnabled(ModuleIds.practice)) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            i18n.t(
              'inline.ui.pages.practice_notebook_page.wrong_notebook_6c7ca5',
            ),
          ),
        ),
        body: ModuleDisabledView(i18n: i18n, moduleId: ModuleIds.practice),
      );
    }
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
        title: Text(
          i18n.t(
            'inline.ui.pages.practice_notebook_page.wrong_notebook_6c7ca5',
          ),
        ),
        actions: notebookWords.isEmpty
            ? null
            : <Widget>[
                if (_selectionMode)
                  IconButton(
                    tooltip: i18n.t(
                      'inline.ui.pages.practice_notebook_page.select_all_93a881',
                    ),
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
                      ? i18n.t(
                          'inline.ui.pages.practice_notebook_page.exit_multi_select_b97450',
                        )
                      : i18n.t(
                          'inline.ui.pages.practice_notebook_page.batch_actions_1bae02',
                        ),
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
              title: i18n.t(
                'inline.ui.pages.practice_notebook_page.wrong_notebook_is_empty_6289ab',
              ),
              message: i18n.t(
                'inline.ui.pages.practice_notebook_page.words_you_mark_as_not_yet_during_practice_will_collect_h_3e96c6',
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: <Widget>[
                PageHeader(
                  eyebrow: i18n.t(
                    'inline.ui.pages.practice_notebook_page.practice_hub_68dce9',
                  ),
                  title: i18n.t(
                    'inline.ui.pages.practice_notebook_page.wrong_notebook_6c7ca5',
                  ),
                  subtitle: i18n.t(
                    'inline.ui.pages.practice_notebook_page.manage_missed_words_in_one_place_with_notebook_order_due_d1af3a',
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
                          i18n.t(
                            'inline.ui.pages.practice_notebook_page.search_filter_d85f23',
                          ),
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
                            labelText: i18n.t(
                              'inline.ui.pages.practice_notebook_page.search_word_or_meaning_3cf7c6',
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
                                i18n.t(
                                  'inline.ui.pages.practice_notebook_page.all_status_5509b6',
                                ),
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
                                i18n.t(
                                  'inline.ui.pages.practice_notebook_page.due_now_30a228',
                                ),
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
                                i18n.t(
                                  'inline.ui.pages.practice_notebook_page.mastered_4419ab',
                                ),
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
                                i18n.t(
                                  'inline.ui.pages.practice_notebook_page.all_reasons_12a4ba',
                                ),
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
                            initialValue: _wordbookFilterId,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: i18n.t(
                                'inline.ui.pages.practice_notebook_page.wordbook_filter_9a4e1a',
                              ),
                            ),
                            items: <DropdownMenuItem<int?>>[
                              DropdownMenuItem<int?>(
                                value: null,
                                child: Text(
                                  i18n.t(
                                    'inline.ui.pages.practice_notebook_page.all_wordbooks_00e652',
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
                          i18n.t(
                            'inline.ui.pages.practice_notebook_page.notebook_summary_0dc2da',
                          ),
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
                              label: i18n.t(
                                'inline.ui.pages.practice_notebook_page.notebook_words_9adfda',
                              ),
                            ),
                            _buildStatChip(
                              context,
                              icon: Icons.schedule_rounded,
                              value: '$dueCount',
                              label: i18n.t(
                                'inline.ui.pages.practice_notebook_page.due_now_30a228',
                              ),
                            ),
                            _buildStatChip(
                              context,
                              icon: Icons.task_alt_rounded,
                              value: '$masteredCount',
                              label: i18n.t(
                                'inline.ui.pages.practice_notebook_page.ready_to_clear_cda958',
                              ),
                            ),
                            _buildStatChip(
                              context,
                              icon: Icons.layers_rounded,
                              value: '$wordbookCount',
                              label: i18n.t('wordbooks'),
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
                          i18n.t(
                            'inline.ui.pages.practice_notebook_page.review_order_334a92',
                          ),
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
                                i18n.t(
                                  'inline.ui.pages.practice_notebook_page.start_review_36dd6d',
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
                                i18n.t(
                                  'inline.ui.pages.practice_notebook_page.shuffle_review_0ec189',
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
                                  i18n.t(
                                    'inline.ui.pages.practice_notebook_page.clear_mastered_f0399c',
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
                                i18n.t(
                                  'inline.ui.pages.practice_notebook_page_actions.clear_notebook_3e08fc',
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
                                i18n.t(
                                  'inline.ui.pages.practice_notebook_page.export_filtered_json_9aca5b',
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
                                i18n.t(
                                  'inline.ui.pages.practice_notebook_page.export_filtered_csv_57b898',
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
                            i18n.t(
                              'inline.ui.pages.practice_notebook_page.batch_actions_1bae02',
                            ),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            i18n.t(
                              'inline.ui.pages.practice_notebook_page.selectedentries_length_selected_add_to_task_favorite_or_4a63f1',
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
                                  i18n.t(
                                    'inline.ui.pages.practice_notebook_page.add_to_task_935808',
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
                                  i18n.t(
                                    'inline.ui.pages.practice_notebook_page.add_favorite_278d4a',
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
                                  i18n.t(
                                    'inline.ui.pages.practice_notebook_page.remove_from_notebook_373cd3',
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
                                  i18n.t(
                                    'inline.ui.pages.practice_notebook_page.clear_selection_b9a937',
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
                        ? i18n.t(
                            'inline.ui.pages.practice_notebook_page.no_entries_match_the_current_filters_try_clearing_search_6b83a1',
                          )
                        : i18n.t(
                            'inline.ui.pages.practice_notebook_page.swipe_a_word_left_to_remove_it_from_the_notebook_a36014',
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
                                  ? i18n.t(
                                      'inline.ui.pages.practice_notebook_page.word_word_removed_from_notebook_c57eb1',
                                    )
                                  : i18n.t(
                                      'inline.ui.pages.practice_notebook_page.notebook_was_not_changed_d68576',
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
          label: i18n.t(
            'inline.ui.pages.practice_notebook_page.accuracy_accuracy_progress_100_round_160c10',
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
          label: i18n.t(
            'inline.ui.pages.practice_notebook_page.last_formatmonthday_lastplayed_d82f1f',
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
          isFavorite: state.isFavoriteEntry(word),
          isTaskWord: state.isTaskEntry(word),
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
            i18n.t('inline.plan295.life.remove.756734973755'),
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

  Future<void> _applyBatchRemove(
    BuildContext context,
    AppI18n i18n,
    List<WordEntry> selectedEntries,
  ) async {
    final removed = ref
        .read(appStateProvider)
        .dismissPracticeWeakWords(selectedEntries);
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
              ? i18n.t(
                  'inline.ui.pages.practice_notebook_page.selected_entries_were_not_changed_ca22e1',
                )
              : i18n.t(
                  'inline.ui.pages.practice_notebook_page.removed_from_notebook_removed_a43dfc',
                ),
        ),
      ),
    );
  }

  String _orderLabel(AppI18n i18n, _PracticeNotebookOrder order) {
    return switch (order) {
      _PracticeNotebookOrder.notebook => i18n.t(
        'inline.ui.pages.practice_notebook_page.notebook_order_f1b302',
      ),
      _PracticeNotebookOrder.dueFirst => i18n.t(
        'inline.ui.pages.practice_notebook_page.due_first_f4f1fa',
      ),
      _PracticeNotebookOrder.weakFirst => i18n.t(
        'inline.ui.pages.practice_notebook_page.weak_first_220485',
      ),
      _PracticeNotebookOrder.alphabetical => i18n.t(
        'inline.ui.pages.practice_notebook_page.a_z_db02f0',
      ),
    };
  }

  String _dueLabel(AppI18n i18n, WordMemoryProgress? progress, DateTime now) {
    if (_isDue(progress, now)) {
      return i18n.t('inline.ui.pages.practice_notebook_page.due_now_30a228');
    }
    final nextReview = progress?.nextReview;
    if (nextReview == null) {
      return i18n.t(
        'inline.ui.pages.practice_notebook_page.need_schedule_366d6a',
      );
    }
    return i18n.t(
      'inline.ui.pages.practice_notebook_page.next_formatmonthday_nextreview_e74448',
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
