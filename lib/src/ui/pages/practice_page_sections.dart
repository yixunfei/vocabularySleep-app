part of 'practice_page.dart';

Widget _buildPracticeRoundSetupCard(
  BuildContext context, {
  required AppI18n i18n,
  required AppState state,
  required WordEntry current,
  required List<WordEntry> wordbookWords,
  required List<WordEntry> scopedWords,
  required List<WordEntry> taskWords,
  required List<WordEntry> favoriteWords,
  required List<WordEntry> weakWords,
  required List<WordEntry> wrongNotebookWords,
}) {
  final settings = state.practiceRoundSettings;
  final sourceWords = _resolvePracticeRoundSourceWords(
    settings.source,
    wordbookWords: wordbookWords,
    scopedWords: scopedWords,
    taskWords: taskWords,
    favoriteWords: favoriteWords,
    weakWords: weakWords,
    wrongNotebookWords: wrongNotebookWords,
  );
  final effectiveRoundSize = sourceWords.isEmpty
      ? settings.roundSize
      : settings.roundSize.clamp(1, sourceWords.length);
  final sourceLabel = _practiceRoundSourceLabel(i18n, settings.source);
  final rotationKey = _buildPracticeRoundRotationKey(
    state,
    source: settings.source,
  );
  final anchorWord = _resolvePracticeRoundAnchorWord(
    settings.startMode,
    sourceWords: sourceWords,
    current: current,
  );
  final previewIndex = state.previewPracticeBatchStartIndex(
    cursorKey: rotationKey,
    sourceWords: sourceWords,
    startMode: settings.startMode,
    anchorWord: anchorWord,
  );
  final previewWord = sourceWords.isEmpty ? '' : sourceWords[previewIndex].word;
  final roundSummary = sourceWords.isEmpty
      ? i18n.t(
          'inline.ui.pages.practice_page_sections.no_words_available_for_this_source_yet_6c6fcd',
        )
      : i18n.t(
          'inline.ui.pages.practice_page_sections.one_round_effectiveroundsize_words_from_sourcelabel_5fdb0b',
          params: <String, Object?>{
            'sourceLabel': sourceLabel,
            'effectiveRoundSize': effectiveRoundSize,
          },
        );
  final startSummary = sourceWords.isEmpty
      ? i18n.t(
          'inline.ui.pages.practice_page_sections.a_starting_point_will_appear_once_words_are_available_023baf',
        )
      : switch (settings.startMode) {
          PracticeRoundStartMode.resumeCursor => i18n.t(
            'inline.ui.pages.practice_page_sections.resume_from_saved_position_previewindex_1_previewword_b60e63',
            params: <String, Object?>{
              'previewIndex': previewIndex + 1,
              'previewWord': previewWord,
            },
          ),
          PracticeRoundStartMode.currentWord => i18n.t(
            'inline.ui.pages.practice_page_sections.start_from_current_word_previewindex_1_previewword_89f95e',
            params: <String, Object?>{
              'previewIndex': previewIndex + 1,
              'previewWord': previewWord,
            },
          ),
          PracticeRoundStartMode.fromStart => i18n.t(
            'inline.ui.pages.practice_page_sections.start_from_the_beginning_previewindex_1_previewword_dcbfcd',
            params: <String, Object?>{
              'previewIndex': previewIndex + 1,
              'previewWord': previewWord,
            },
          ),
        };
  final availableSummary = sourceWords.isEmpty
      ? i18n.t(
          'inline.ui.pages.practice_page_sections.0_words_available_d9cb8f',
        )
      : i18n.t(
          'inline.ui.pages.practice_page_sections.sourcewords_length_words_available_cdf53d',
          params: <String, Object?>{'sourceWords': sourceWords.length},
        );

  return Card(
    key: const ValueKey<String>('practice-round-setup-card'),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      i18n.t(
                        'inline.ui.pages.practice_page_sections.round_setup_a216ad',
                      ),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(roundSummary),
                    const SizedBox(height: 4),
                    Text(
                      startSummary,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                key: const ValueKey<String>('practice-round-toggle'),
                onPressed: () {
                  state.updatePracticeRoundSettings(
                    collapsed: !settings.collapsed,
                  );
                },
                icon: Icon(
                  settings.collapsed
                      ? Icons.expand_more_rounded
                      : Icons.expand_less_rounded,
                ),
              ),
            ],
          ),
          if (!settings.collapsed) ...<Widget>[
            const SizedBox(height: 16),
            DropdownButtonFormField<PracticeRoundSource>(
              key: const ValueKey<String>('practice-round-source'),
              initialValue: settings.source,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: i18n.t(
                  'inline.ui.pages.practice_page_sections.practice_source_a73c09',
                ),
              ),
              items: PracticeRoundSource.values
                  .map(
                    (source) => DropdownMenuItem<PracticeRoundSource>(
                      value: source,
                      child: Text(_practiceRoundSourceLabel(i18n, source)),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                state.updatePracticeRoundSettings(source: value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PracticeRoundStartMode>(
              key: const ValueKey<String>('practice-round-start-mode'),
              initialValue: settings.startMode,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: i18n.t(
                  'inline.ui.pages.practice_page_sections.starting_point_e5916e',
                ),
              ),
              items: PracticeRoundStartMode.values
                  .map(
                    (mode) => DropdownMenuItem<PracticeRoundStartMode>(
                      value: mode,
                      child: Text(_practiceRoundStartModeLabel(i18n, mode)),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                state.updatePracticeRoundSettings(startMode: value);
              },
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    i18n.t(
                      'inline.ui.pages.practice_page_sections.words_per_round_38ed23',
                    ),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      IconButton(
                        onPressed: settings.roundSize <= 1
                            ? null
                            : () {
                                state.updatePracticeRoundSettings(
                                  roundSize: settings.roundSize - 1,
                                );
                              },
                        icon: const Icon(Icons.remove_rounded),
                      ),
                      Expanded(
                        child: Column(
                          children: <Widget>[
                            Text(
                              '$effectiveRoundSize',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              availableSummary,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: sourceWords.isEmpty
                            ? () {
                                state.updatePracticeRoundSettings(
                                  roundSize: settings.roundSize + 1,
                                );
                              }
                            : effectiveRoundSize >= sourceWords.length
                            ? null
                            : () {
                                state.updatePracticeRoundSettings(
                                  roundSize: settings.roundSize + 1,
                                );
                              },
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(
                i18n.t(
                  'inline.ui.pages.practice_page_sections.shuffle_within_round_4bc816',
                ),
              ),
              subtitle: Text(
                i18n.t(
                  'inline.ui.pages.practice_page_sections.keep_the_selected_start_point_but_shuffle_the_order_insi_bde80e',
                ),
              ),
              value: settings.shuffle,
              onChanged: (value) {
                state.updatePracticeRoundSettings(shuffle: value);
              },
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: sourceWords.isEmpty
                  ? null
                  : () => _openPracticeSession(
                      context,
                      title: i18n.t(
                        'inline.ui.pages.practice_page_sections.sourcelabel_round_540f13',
                        params: <String, Object?>{'sourceLabel': sourceLabel},
                      ),
                      subtitle: sourceWords.isEmpty
                          ? i18n.t(
                              'inline.ui.pages.practice_page_sections.no_words_587afb',
                            )
                          : i18n.t(
                              'inline.ui.pages.practice_page_sections.effectiveroundsize_of_sourcewords_length_words_e05728',
                              params: <String, Object?>{
                                'effectiveRoundSize': effectiveRoundSize,
                                'sourceWords': sourceWords.length,
                              },
                            ),
                      words: sourceWords,
                      shuffle: settings.shuffle,
                      rotationKey: rotationKey,
                      rotationSourceWords: sourceWords,
                      rotationBatchSize: effectiveRoundSize,
                      rotationAnchorWord: anchorWord,
                      rotationCursorAdvance: effectiveRoundSize,
                    ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                i18n.t(
                  'inline.ui.pages.practice_page_sections.start_this_round_6ce704',
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

Widget _buildMemoryLanesCard(
  BuildContext context, {
  required AppI18n i18n,
  required AppState state,
  required List<WordEntry> stableWords,
  required List<WordEntry> recoveryWords,
  required int rememberedToday,
  required int needsReviewToday,
  required bool hasStableWords,
}) {
  final scopeWords = state.visibleWords;

  Future<void> openScopeWarmup() async {
    if (scopeWords.isEmpty) {
      _showNoWordsSnack(context, i18n);
      return;
    }
    await _openPracticeSession(
      context,
      title: i18n.t(
        'inline.ui.pages.practice_page_sections.current_scope_session_a26a55',
      ),
      subtitle: i18n.t(
        'inline.ui.pages.practice_page_sections.scopewords_length_words_4a9571',
        params: <String, Object?>{'scopeWords': scopeWords.length},
      ),
      words: scopeWords,
      shuffle: false,
      rotationKey: _buildPracticeScopeRotationKey(state, slot: 'scope-session'),
      rotationSourceWords: scopeWords,
      rotationBatchSize: scopeWords.length,
      rotationCursorAdvance: 1,
    );
  }

  return Card(
    key: const ValueKey<String>('practice-memory-card'),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            i18n.t(
              'inline.ui.pages.practice_page_sections.memory_lanes_9cc2bd',
            ),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            i18n.t(
              'inline.ui.pages.practice_page_sections.split_each_finished_session_into_stable_and_recovery_lan_d59edf',
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _buildStatBadge(
                context,
                icon: Icons.check_circle_outline_rounded,
                value: '$rememberedToday',
                label: i18n.t(
                  'inline.ui.pages.practice_page_sections.remembered_today_fa8872',
                ),
              ),
              _buildStatBadge(
                context,
                icon: Icons.refresh_rounded,
                value: '$needsReviewToday',
                label: i18n.t(
                  'inline.ui.pages.practice_page_sections.need_review_893c05',
                ),
              ),
              _buildStatBadge(
                context,
                icon: Icons.auto_awesome_rounded,
                value: '${stableWords.length}',
                label: i18n.t(
                  'inline.ui.pages.practice_page_sections.stable_queue_1e03b3',
                ),
              ),
              _buildStatBadge(
                context,
                icon: Icons.fitness_center_rounded,
                value: '${recoveryWords.length}',
                label: i18n.t(
                  'inline.ui.pages.practice_page_sections.recovery_queue_8c63b4',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildMemoryLane(
            context,
            key: const ValueKey<String>('practice-memory-stable'),
            i18n: i18n,
            icon: Icons.auto_awesome_rounded,
            title: i18n.t(
              'inline.ui.pages.practice_page_sections.stable_lane_27722e',
            ),
            subtitle: hasStableWords
                ? i18n.t(
                    'inline.ui.pages.practice_page_sections.revisit_words_you_already_know_to_keep_recall_and_pronun_f48cf9',
                  )
                : i18n.t(
                    'inline.ui.pages.practice_page_sections.finish_one_session_and_the_words_you_remember_will_colle_adc0fb',
                  ),
            words: stableWords,
            actionLabel: hasStableWords
                ? i18n.t(
                    'inline.ui.pages.practice_page_sections.review_remembered_a87a77',
                  )
                : i18n.t(
                    'inline.ui.pages.practice_page_sections.start_first_session_0efab9',
                  ),
            onTap: hasStableWords
                ? () => _openReviewSession(
                    context,
                    i18n,
                    title: i18n.t(
                      'inline.ui.pages.practice_page_sections.remembered_word_review_adca85',
                    ),
                    subtitle: i18n.t(
                      'inline.ui.pages.practice_page_sections.stablewords_length_remembered_words_299de1',
                      params: <String, Object?>{
                        'stableWords': stableWords.length,
                      },
                    ),
                    words: stableWords,
                  )
                : openScopeWarmup,
          ),
          const SizedBox(height: 12),
          _buildMemoryLane(
            context,
            key: const ValueKey<String>('practice-memory-recovery'),
            i18n: i18n,
            icon: Icons.fitness_center_rounded,
            title: i18n.t(
              'inline.ui.pages.practice_page_sections.recovery_lane_df0c26',
            ),
            subtitle: recoveryWords.isNotEmpty
                ? i18n.t(
                    'inline.ui.pages.practice_page_sections.mix_weak_and_task_words_into_one_queue_so_you_can_close_79e214',
                  )
                : i18n.t(
                    'inline.ui.pages.practice_page_sections.words_you_miss_will_stay_here_so_you_can_recover_them_in_9ede65',
                  ),
            words: recoveryWords,
            actionLabel: recoveryWords.isNotEmpty
                ? i18n.t(
                    'inline.ui.pages.practice_page_sections.start_recovery_review_b56c92',
                  )
                : i18n.t(
                    'inline.ui.pages.practice_page_sections.start_first_session_0efab9',
                  ),
            onTap: recoveryWords.isNotEmpty
                ? () => _openReviewSession(
                    context,
                    i18n,
                    title: i18n.t(
                      'inline.ui.pages.practice_page_sections.recovery_lane_df0c26',
                    ),
                    subtitle: i18n.t(
                      'inline.ui.pages.practice_page_sections.recoverywords_length_words_to_reinforce_66e959',
                      params: <String, Object?>{
                        'recoveryWords': recoveryWords.length,
                      },
                    ),
                    words: recoveryWords,
                  )
                : openScopeWarmup,
          ),
        ],
      ),
    ),
  );
}

Widget _buildMemoryLane(
  BuildContext context, {
  required Key key,
  required AppI18n i18n,
  required IconData icon,
  required String title,
  required String subtitle,
  required List<WordEntry> words,
  required String actionLabel,
  required VoidCallback onTap,
}) {
  final theme = Theme.of(context);

  return Container(
    key: key,
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: theme.colorScheme.outlineVariant),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
          ],
        ),
        const SizedBox(height: 8),
        Text(subtitle, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 10),
        _buildWordPreviewChips(context, i18n, words),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: onTap,
          icon: const Icon(Icons.play_circle_outline_rounded),
          label: Text(actionLabel),
        ),
      ],
    ),
  );
}

Widget _buildWrongNotebookCard(
  BuildContext context, {
  required AppI18n i18n,
  required AppState state,
  required List<WordEntry> notebookWords,
  required int dueCount,
}) {
  final wordbookCount = notebookWords
      .map((entry) => entry.wordbookId)
      .toSet()
      .length;
  final theme = Theme.of(context);
  final hasNotebookWords = notebookWords.isNotEmpty;

  return Card(
    key: const ValueKey<String>('practice-wrong-notebook-card'),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            i18n.t(
              'inline.ui.pages.practice_notebook_page.wrong_notebook_6c7ca5',
            ),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            hasNotebookWords
                ? i18n.t(
                    'inline.ui.pages.practice_page_sections.keep_missed_words_in_one_place_with_notebook_order_due_f_7d1f3c',
                  )
                : i18n.t(
                    'inline.ui.pages.practice_page_sections.when_you_mark_a_word_as_not_yet_during_practice_it_will_dbb1b0',
                  ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _buildStatBadge(
                context,
                icon: Icons.bookmarks_rounded,
                value: '${notebookWords.length}',
                label: i18n.t(
                  'inline.ui.pages.practice_notebook_page.notebook_words_9adfda',
                ),
              ),
              _buildStatBadge(
                context,
                icon: Icons.schedule_rounded,
                value: '$dueCount',
                label: i18n.t(
                  'inline.ui.pages.practice_notebook_page.due_now_30a228',
                ),
              ),
              _buildStatBadge(
                context,
                icon: Icons.layers_rounded,
                value: '$wordbookCount',
                label: i18n.t('wordbooks'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildWordPreviewChips(context, i18n, notebookWords),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PracticeNotebookPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.menu_book_rounded),
                label: Text(
                  i18n.t(
                    'inline.ui.pages.practice_page_sections.open_notebook_0cd739',
                  ),
                ),
              ),
              if (hasNotebookWords)
                OutlinedButton.icon(
                  onPressed: () => _openPracticeSession(
                    context,
                    title: i18n.t(
                      'inline.ui.pages.practice_notebook_page_actions.wrong_notebook_review_88939c',
                    ),
                    subtitle: i18n.t(
                      'inline.ui.pages.practice_page_sections.notebookwords_length_notebook_words_87aa77',
                      params: <String, Object?>{
                        'notebookWords': notebookWords.length,
                      },
                    ),
                    words: notebookWords,
                    shuffle: false,
                  ),
                  icon: const Icon(Icons.play_circle_outline_rounded),
                  label: Text(
                    i18n.t(
                      'inline.ui.pages.practice_page_sections.start_now_c4829b',
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildRecentHistoryCard(
  BuildContext context, {
  required AppI18n i18n,
  required List<PracticeSessionRecord> history,
}) {
  final theme = Theme.of(context);
  return Card(
    key: const ValueKey<String>('practice-history-card'),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            i18n.t(
              'inline.ui.pages.practice_page_sections.recent_session_history_bc2d00',
            ),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            i18n.t(
              'inline.ui.pages.practice_page_sections.keep_the_latest_sessions_visible_so_you_can_track_accura_fd41e0',
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PracticeReviewPage(),
                  ),
                );
              },
              icon: const Icon(Icons.analytics_outlined),
              label: Text(
                i18n.t(
                  'inline.ui.pages.practice_page_sections.open_review_page_3d0013',
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (history.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                i18n.t(
                  'inline.ui.pages.practice_page_sections.no_session_history_yet_finish_one_session_and_it_will_ap_204206',
                ),
                style: theme.textTheme.bodySmall,
              ),
            )
          else
            ...history.take(5).map((record) {
              final reasonBadges = record.weakReasonCounts.entries.toList(
                growable: false,
              )..sort((left, right) => right.value.compareTo(left.value));
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            record.title.isEmpty
                                ? i18n.t(
                                    'inline.ui.pages.practice_page_sections.practice_session_562029',
                                  )
                                : record.title,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        Text(
                          formatPracticeDateTime(i18n, record.practicedAt),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      i18n.t(
                        'inline.ui.pages.practice_page_sections.accuracy_record_accuracy_100_round_record_remembered_rec_b4a3e4',
                        params: <String, Object?>{
                          'recordAccuracy': (record.accuracy * 100).round(),
                          'recordRemembered': record.remembered,
                          'recordTotal': record.total,
                          'recordWeakCount': record.weakCount,
                        },
                      ),
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (reasonBadges.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: reasonBadges
                            .take(3)
                            .map(
                              (entry) => Chip(
                                visualDensity: VisualDensity.compact,
                                avatar: Icon(
                                  practiceWeakReasonIcon(entry.key),
                                  size: 16,
                                ),
                                label: Text(
                                  '${practiceWeakReasonLabel(i18n, entry.key)} × ${entry.value}',
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    ),
  );
}

Widget _buildWordPreviewChips(
  BuildContext context,
  AppI18n i18n,
  List<WordEntry> words,
) {
  final theme = Theme.of(context);
  if (words.isEmpty) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        i18n.t('inline.ui.pages.practice_page_sections.no_words_yet_06b153'),
        style: theme.textTheme.bodySmall,
      ),
    );
  }

  return Wrap(
    spacing: 8,
    runSpacing: 8,
    children: words
        .take(6)
        .map((word) => Chip(label: Text(word.word)))
        .toList(growable: false),
  );
}

Widget _buildStatBadge(
  BuildContext context, {
  required IconData icon,
  required String value,
  required String label,
}) {
  final theme = Theme.of(context);
  return Container(
    constraints: const BoxConstraints(minWidth: 120),
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

Widget _buildQuickLaunchCard(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  final theme = Theme.of(context);
  return SizedBox(
    width: 160,
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    ),
  );
}
