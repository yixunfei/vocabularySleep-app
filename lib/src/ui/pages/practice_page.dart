import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/module_system/module_id.dart';
import '../../i18n/app_i18n.dart';
import '../../models/settings_dto.dart';
import '../../models/practice_session_record.dart';
import '../../models/word_entry.dart';
import '../../state/app_state.dart';
import '../../state/app_state_provider.dart';
import '../module/module_access.dart';
import '../wordbook_localization.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/page_header.dart';
import '../widgets/setting_tile.dart';
import '../widgets/study_wordbook_status.dart';
import 'follow_along_page.dart';
import 'practice_notebook_page.dart';
import 'practice_review_page.dart';
import 'practice_support.dart';
import 'practice_session_page.dart';
import 'review_session_page.dart';

part 'practice_page_helpers.dart';
part 'practice_page_sections.dart';

class PracticePage extends ConsumerWidget {
  const PracticePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(appStateProvider.select(_PracticePageRebuildToken.fromState));
    final state = ref.read(appStateProvider);
    final i18n = AppI18n(state.uiLanguage);
    if (!state.isModuleEnabled(ModuleIds.practice)) {
      return ModuleDisabledView(i18n: i18n, moduleId: ModuleIds.practice);
    }
    final current = state.currentWord;
    if (state.selectedWordbook == null || current == null) {
      final selectedWordbook = state.selectedWordbook;
      if (selectedWordbook != null && studyWordbookNeedsExplicitLoad(state)) {
        return _PracticeWordbookLoadState(
          i18n: i18n,
          state: state,
          onLoad: state.loadSelectedWordbook,
          onSwitchWordbook: () =>
              _openPracticeWordbookSheet(context, state, i18n),
        );
      }
      return EmptyStateView(
        icon: Icons.fitness_center_rounded,
        title: i18n.t('study.practice.empty.title'),
        message: selectedWordbook == null
            ? i18n.t('noWordbookYet')
            : i18n.t('study.practice.empty.selected_empty'),
        actionLabel: i18n.t('study.wordbook.action.choose'),
        onAction: () => _openPracticeWordbookSheet(context, state, i18n),
      );
    }

    final wordbookWords = state.words;
    final scopedWords = state.visibleWords;
    final buckets = _PracticeWordBuckets.build(
      state: state,
      wordbookWords: wordbookWords,
      scopedWords: scopedWords,
      current: current,
    );
    final taskWords = buckets.taskWords;
    final favoriteWords = buckets.favoriteWords;
    final rememberedWords = state.recentRememberedWordEntries;
    final weakWords = state.recentWeakWordEntries;
    final wrongNotebookWords = state.practiceWrongNotebookEntries;
    final needsReviewCount =
        (state.practiceTodayReviewed - state.practiceTodayRemembered).clamp(
          0,
          state.practiceTodayReviewed,
        );
    final stableWords = _mergeWordCollections(rememberedWords, favoriteWords);
    final recoveryWords = _mergeWordCollections(weakWords, taskWords);
    final todayAccuracy = (state.practiceTodayAccuracy * 100).round();
    final totalAccuracy = (state.practiceTotalAccuracy * 100).round();
    final hasWeakWords = weakWords.isNotEmpty;
    final hasStableWords = stableWords.isNotEmpty;
    final noPracticeToday = state.practiceTodaySessions == 0;
    final needsReinforce =
        !hasWeakWords && !noPracticeToday && state.practiceTodayAccuracy < 0.75;
    final warmupWords = buckets.warmupWords;
    final currentSprintSourceWords = buckets.currentSprintSourceWords;
    final recentHistory = state.practiceSessionHistory;
    final now = DateTime.now();
    final notebookDueCount = wrongNotebookWords.where((word) {
      final nextReview = state.memoryProgressForWordEntry(word)?.nextReview;
      return nextReview == null || !nextReview.isAfter(now);
    }).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: <Widget>[
        PageHeader(
          eyebrow: i18n.t('inline.ui.module.module_access.practice_edc3b5'),
          title: i18n.t(
            'inline.ui.pages.practice_notebook_page.practice_hub_68dce9',
          ),
          subtitle: i18n.t(
            'inline.ui.pages.practice_page.move_from_single_word_tools_to_session_based_practice_wi_10cf4e',
          ),
        ),
        const SizedBox(height: 16),
        StudyWordbookStatusBar(
          state: state,
          i18n: i18n,
          visibleCount: scopedWords.length,
          searching: state.searchQuery.trim().isNotEmpty,
          currentWordbookEmpty: wordbookWords.isEmpty,
          onTap: () => _openPracticeWordbookSheet(context, state, i18n),
          onLoadCurrent: state.loadSelectedWordbook,
        ),
        const SizedBox(height: 16),
        _buildNextPracticeCard(
          context,
          i18n: i18n,
          state: state,
          current: current,
          hasWeakWords: hasWeakWords,
          weakWords: weakWords,
          noPracticeToday: noPracticeToday,
          needsReinforce: needsReinforce,
          scopedWords: scopedWords,
          wordbookWords: wordbookWords,
        ),
        const SizedBox(height: 16),
        _buildPracticeRoundSetupCard(
          context,
          i18n: i18n,
          state: state,
          current: current,
          wordbookWords: wordbookWords,
          scopedWords: scopedWords,
          taskWords: taskWords,
          favoriteWords: favoriteWords,
          weakWords: weakWords,
          wrongNotebookWords: wrongNotebookWords,
        ),
        const SizedBox(height: 16),
        _buildMemoryLanesCard(
          context,
          i18n: i18n,
          state: state,
          stableWords: stableWords,
          recoveryWords: recoveryWords,
          rememberedToday: state.practiceTodayRemembered,
          needsReviewToday: needsReviewCount,
          hasStableWords: hasStableWords,
        ),
        const SizedBox(height: 16),
        _buildWrongNotebookCard(
          context,
          i18n: i18n,
          state: state,
          notebookWords: wrongNotebookWords,
          dueCount: notebookDueCount,
        ),
        const SizedBox(height: 16),
        _buildRecentHistoryCard(context, i18n: i18n, history: recentHistory),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  i18n.t(
                    'inline.ui.pages.practice_page.current_practice_snapshot_283461',
                  ),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  i18n.t(
                    'inline.ui.pages.practice_page.current_word_current_word_bab62a',
                    params: <String, Object?>{'word': current.word},
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  i18n.t(
                    'inline.ui.pages.practice_page.wordbook_localizedwordbookname_i18n_state_selectedwordbo_6292f6',
                    params: <String, Object?>{
                      'wordbook': localizedWordbookName(
                        i18n,
                        state.selectedWordbook,
                      ),
                    },
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  i18n.t(
                    'inline.ui.pages.practice_page.scope_scopedwords_length_task_taskwords_length_favorite_7e91f1',
                    params: <String, Object?>{
                      'scope': scopedWords.length,
                      'task': taskWords.length,
                      'favorite': favoriteWords.length,
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  i18n.t(
                    'inline.ui.pages.practice_page.today_state_practicetodaysessions_sessions_state_practic_0b1062',
                    params: <String, Object?>{
                      'sessions': state.practiceTodaySessions,
                      'reviewed': state.practiceTodayReviewed,
                      'accuracy': todayAccuracy,
                    },
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  i18n.t(
                    'inline.ui.pages.practice_page.all_time_state_practicetotalsessions_sessions_totalaccur_e9fd7e',
                    params: <String, Object?>{
                      'sessions': state.practiceTotalSessions,
                      'accuracy': totalAccuracy,
                    },
                  ),
                ),
                if (state.practiceLastSessionTitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    i18n.t(
                      'inline.ui.pages.practice_page.last_session_state_practicelastsessiontitle_0cbec4',
                      params: <String, Object?>{
                        'title': state.practiceLastSessionTitle,
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    _buildStatBadge(
                      context,
                      icon: Icons.local_fire_department_rounded,
                      value: '${state.practiceTodayReviewed}',
                      label: i18n.t(
                        'inline.ui.pages.practice_page.reviewed_today_c8598e',
                      ),
                    ),
                    _buildStatBadge(
                      context,
                      icon: Icons.psychology_alt_outlined,
                      value: '${weakWords.length}',
                      label: i18n.t(
                        'inline.ui.pages.practice_page.weak_words_f19247',
                      ),
                    ),
                    _buildStatBadge(
                      context,
                      icon: Icons.task_alt_rounded,
                      value: '${taskWords.length}',
                      label: i18n.t(
                        'inline.ui.pages.practice_page_helpers.task_words_75fdf1',
                      ),
                    ),
                    _buildStatBadge(
                      context,
                      icon: Icons.favorite_rounded,
                      value: '${favoriteWords.length}',
                      label: i18n.t(
                        'toolbox.sound.soothing.mode_filter_favorites',
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
                  i18n.t('inline.ui.pages.practice_page.quick_start_c5b829'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  i18n.t(
                    'inline.ui.pages.practice_page.keep_warmups_shuffled_sprints_and_pronunciation_drills_t_54bd03',
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    _buildQuickLaunchCard(
                      context,
                      icon: Icons.flash_on_rounded,
                      title: i18n.t(
                        'inline.ui.pages.practice_page.current_word_sprint_5c2877',
                      ),
                      subtitle: i18n.t(
                        'inline.ui.pages.practice_page.1_card_warmup_f2bf20',
                      ),
                      onTap: () => _openPracticeSession(
                        context,
                        title: i18n.t(
                          'inline.ui.pages.practice_page.current_word_sprint_5c2877',
                        ),
                        subtitle: i18n.t(
                          'inline.ui.pages.practice_page.single_item_mini_session_424690',
                        ),
                        words: <WordEntry>[current],
                        shuffle: false,
                        rotationKey: _buildPracticeScopeRotationKey(
                          state,
                          slot: 'current-word',
                        ),
                        rotationSourceWords: currentSprintSourceWords,
                        rotationBatchSize: 1,
                        rotationAnchorWord: current,
                      ),
                    ),
                    _buildQuickLaunchCard(
                      context,
                      icon: Icons.local_fire_department_rounded,
                      title: i18n.t(
                        'inline.ui.pages.practice_page.7_word_warmup_5e2367',
                      ),
                      subtitle: i18n.t(
                        'inline.ui.pages.practice_page.start_fast_from_current_scope_662ffa',
                      ),
                      onTap: warmupWords.isEmpty
                          ? () => _showNoWordsSnack(context, i18n)
                          : () => _openPracticeSession(
                              context,
                              title: i18n.t(
                                'inline.ui.pages.practice_page.7_word_warmup_5e2367',
                              ),
                              subtitle: i18n.t(
                                'inline.ui.pages.practice_page.warmupwords_length_words_494b66',
                                params: <String, Object?>{
                                  'warmupWords': warmupWords.length,
                                },
                              ),
                              words: scopedWords,
                              shuffle: false,
                              rotationKey: _buildPracticeScopeRotationKey(
                                state,
                                slot: 'warmup-7',
                              ),
                              rotationSourceWords: scopedWords,
                              rotationBatchSize: 7,
                            ),
                    ),
                    _buildQuickLaunchCard(
                      context,
                      icon: Icons.shuffle_rounded,
                      title: i18n.t(
                        'inline.ui.pages.practice_page.shuffle_sprint_3f3cb5',
                      ),
                      subtitle: i18n.t(
                        'inline.ui.pages.practice_page.shuffle_the_current_scope_11281f',
                      ),
                      onTap: scopedWords.isEmpty
                          ? () => _showNoWordsSnack(context, i18n)
                          : () => _openPracticeSession(
                              context,
                              title: i18n.t(
                                'inline.ui.pages.practice_page.shuffle_sprint_3f3cb5',
                              ),
                              subtitle: i18n.t(
                                'inline.ui.pages.practice_page.scopedwords_length_words_33fa4f',
                                params: <String, Object?>{
                                  'scope': scopedWords.length,
                                },
                              ),
                              words: scopedWords,
                              shuffle: true,
                            ),
                    ),
                    _buildQuickLaunchCard(
                      context,
                      icon: Icons.mic_external_on_rounded,
                      title: i18n.t(
                        'inline.ui.pages.practice_page.pronunciation_drill_cb58bf',
                      ),
                      subtitle: i18n.t(
                        'inline.ui.pages.practice_page.follow_along_with_current_word_3b5d8d',
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => FollowAlongPage(word: current),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (!state.practiceRoundSettings.collapsed) ...<Widget>[
          const SizedBox(height: 12),
          SettingTile(
            icon: Icons.flash_on_rounded,
            title: i18n.t(
              'inline.ui.pages.practice_page.current_word_sprint_5c2877',
            ),
            subtitle: i18n.t(
              'inline.ui.pages.practice_page.quick_one_item_session_for_the_current_word_936277',
            ),
            onTap: () => _openPracticeSession(
              context,
              title: i18n.t(
                'inline.ui.pages.practice_page.current_word_sprint_5c2877',
              ),
              subtitle: i18n.t(
                'inline.ui.pages.practice_page.single_item_mini_session_424690',
              ),
              words: <WordEntry>[current],
              shuffle: false,
              rotationKey: _buildPracticeScopeRotationKey(
                state,
                slot: 'current-word',
              ),
              rotationSourceWords: currentSprintSourceWords,
              rotationBatchSize: 1,
              rotationAnchorWord: current,
            ),
          ),
          const SizedBox(height: 12),
          SettingTile(
            icon: Icons.view_list_rounded,
            title: i18n.t(
              'inline.ui.pages.practice_page_sections.current_scope_session_a26a55',
            ),
            subtitle: i18n.t(
              'inline.ui.pages.practice_page.practice_continuously_within_current_filtered_scope_07ce51',
            ),
            onTap: () {
              if (scopedWords.isEmpty) {
                _showNoWordsSnack(context, i18n);
                return;
              }
              _openPracticeSession(
                context,
                title: i18n.t(
                  'inline.ui.pages.practice_page_sections.current_scope_session_a26a55',
                ),
                subtitle: i18n.t(
                  'inline.ui.pages.practice_page.scopedwords_length_words_33fa4f',
                  params: <String, Object?>{'scope': scopedWords.length},
                ),
                words: scopedWords,
                shuffle: false,
                rotationKey: _buildPracticeScopeRotationKey(
                  state,
                  slot: 'scope-session',
                ),
                rotationSourceWords: scopedWords,
                rotationBatchSize: scopedWords.length,
                rotationCursorAdvance: 1,
              );
            },
          ),
          const SizedBox(height: 12),
          SettingTile(
            icon: Icons.library_books_rounded,
            title: i18n.t(
              'inline.ui.pages.practice_page.whole_wordbook_session_43154c',
            ),
            subtitle: i18n.t(
              'inline.ui.pages.practice_page.cover_the_whole_wordbook_with_optional_shuffle_b62837',
            ),
            onTap: () => _openPracticeSession(
              context,
              title: i18n.t(
                'inline.ui.pages.practice_page.whole_wordbook_session_43154c',
              ),
              subtitle: i18n.t(
                'inline.ui.pages.practice_page.wordbookwords_length_words_320caa',
                params: <String, Object?>{
                  'wordbookWords': wordbookWords.length,
                },
              ),
              words: wordbookWords,
              shuffle: true,
            ),
          ),
          const SizedBox(height: 12),
          SettingTile(
            icon: Icons.task_alt_rounded,
            title: i18n.t(
              'inline.ui.pages.practice_page.task_word_review_b855a4',
            ),
            subtitle: i18n.t(
              'inline.ui.pages.practice_page.review_session_focused_on_task_words_3a77a3',
            ),
            onTap: () => _openReviewSession(
              context,
              i18n,
              title: i18n.t(
                'inline.ui.pages.practice_page.task_word_review_b855a4',
              ),
              subtitle: i18n.t(
                'inline.ui.pages.practice_page.taskwords_length_task_words_7d8908',
                params: <String, Object?>{'task': taskWords.length},
              ),
              words: taskWords,
            ),
          ),
          const SizedBox(height: 12),
          SettingTile(
            icon: Icons.favorite_rounded,
            title: i18n.t(
              'inline.ui.pages.practice_page.favorite_word_review_23c057',
            ),
            subtitle: i18n.t(
              'inline.ui.pages.practice_page.review_favorite_words_and_start_a_session_quickly_d4b44c',
            ),
            onTap: () => _openReviewSession(
              context,
              i18n,
              title: i18n.t(
                'inline.ui.pages.practice_page.favorite_word_review_23c057',
              ),
              subtitle: i18n.t(
                'inline.ui.pages.practice_page.favoritewords_length_favorite_words_474f92',
                params: <String, Object?>{'favorite': favoriteWords.length},
              ),
              words: favoriteWords,
            ),
          ),
          if (weakWords.isNotEmpty) ...[
            const SizedBox(height: 12),
            SettingTile(
              icon: Icons.psychology_alt_outlined,
              title: i18n.t(
                'inline.ui.pages.practice_page_helpers.recent_weak_words_9759a1',
              ),
              subtitle: i18n.t(
                'inline.ui.pages.practice_page.auto_collected_from_session_history_recommended_next_ste_f52de3',
              ),
              onTap: () => _openReviewSession(
                context,
                i18n,
                title: i18n.t(
                  'inline.ui.pages.practice_page_helpers.recent_weak_words_9759a1',
                ),
                subtitle: i18n.t(
                  'inline.ui.pages.practice_page.weakwords_length_weak_words_26454f',
                  params: <String, Object?>{'weakWords': weakWords.length},
                ),
                words: weakWords,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SettingTile(
            icon: Icons.mic_external_on_rounded,
            title: i18n.t('inline.ui.pages.practice_page.follow_along_16958e'),
            subtitle: i18n.t(
              'inline.ui.pages.practice_page.record_transcribe_and_score_pronunciation_for_current_wo_1c37a7',
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => FollowAlongPage(word: current),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildNextPracticeCard(
    BuildContext context, {
    required AppI18n i18n,
    required AppState state,
    required WordEntry current,
    required bool hasWeakWords,
    required List<WordEntry> weakWords,
    required bool noPracticeToday,
    required bool needsReinforce,
    required List<WordEntry> scopedWords,
    required List<WordEntry> wordbookWords,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              i18n.t('study.practice.next.title'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text(
              hasWeakWords
                  ? i18n.t(
                      'inline.ui.pages.practice_page.review_recent_weak_words_first_then_do_a_full_wordbook_s_42b4a4',
                    )
                  : noPracticeToday
                  ? i18n.t(
                      'inline.ui.pages.practice_page.no_practice_yet_today_start_with_current_scope_session_38aa01',
                    )
                  : needsReinforce
                  ? i18n.t(
                      'inline.ui.pages.practice_page.today_accuracy_is_lower_than_expected_try_full_wordbook_4d82e3',
                    )
                  : i18n.t(
                      'inline.ui.pages.practice_page.you_are_doing_well_today_continue_with_follow_along_for_edd637',
                    ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                if (hasWeakWords)
                  FilledButton.icon(
                    onPressed: () => _openReviewSession(
                      context,
                      i18n,
                      title: i18n.t(
                        'inline.ui.pages.practice_page_helpers.recent_weak_words_9759a1',
                      ),
                      subtitle: i18n.t(
                        'inline.ui.pages.practice_page.weakwords_length_weak_words_26454f',
                        params: <String, Object?>{
                          'weakWords': weakWords.length,
                        },
                      ),
                      words: weakWords,
                    ),
                    icon: const Icon(Icons.psychology_alt_outlined),
                    label: Text(
                      i18n.t(
                        'inline.ui.pages.practice_page.start_weak_word_review_23a89b',
                      ),
                    ),
                  )
                else if (noPracticeToday)
                  FilledButton.icon(
                    onPressed: () => _openPracticeSession(
                      context,
                      title: i18n.t(
                        'inline.ui.pages.practice_page_sections.current_scope_session_a26a55',
                      ),
                      subtitle: i18n.t(
                        'inline.ui.pages.practice_page.scopedwords_length_words_33fa4f',
                        params: <String, Object?>{'scope': scopedWords.length},
                      ),
                      words: scopedWords,
                      shuffle: false,
                      rotationKey: _buildPracticeScopeRotationKey(
                        state,
                        slot: 'scope-session',
                      ),
                      rotationSourceWords: scopedWords,
                      rotationBatchSize: scopedWords.length,
                      rotationCursorAdvance: 1,
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      i18n.t(
                        'inline.ui.pages.practice_page_sections.start_now_c4829b',
                      ),
                    ),
                  )
                else if (needsReinforce)
                  FilledButton.icon(
                    onPressed: () => _openPracticeSession(
                      context,
                      title: i18n.t(
                        'inline.ui.pages.practice_page.whole_wordbook_session_43154c',
                      ),
                      subtitle: i18n.t(
                        'inline.ui.pages.practice_page.wordbookwords_length_words_320caa',
                        params: <String, Object?>{
                          'wordbookWords': wordbookWords.length,
                        },
                      ),
                      words: wordbookWords,
                      shuffle: true,
                    ),
                    icon: const Icon(Icons.library_books_rounded),
                    label: Text(
                      i18n.t(
                        'inline.ui.pages.practice_page.start_reinforcement_1b31b4',
                      ),
                    ),
                  )
                else
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => FollowAlongPage(word: current),
                        ),
                      );
                    },
                    icon: const Icon(Icons.mic_external_on_rounded),
                    label: Text(
                      i18n.t(
                        'inline.ui.pages.practice_page.go_follow_along_3af418',
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
}

class _PracticePageRebuildToken {
  const _PracticePageRebuildToken({
    required this.uiLanguage,
    required this.practiceEnabled,
    required this.selectedWordbookId,
    required this.selectedWordbookName,
    required this.selectedWordbookPath,
    required this.selectedWordbookWordCount,
    required this.selectedWordbookLoaded,
    required this.selectedWordbookRequiresOnDemandLoad,
    required this.wordsVersion,
    required this.wordsLength,
    required this.currentWordIndex,
    required this.searchQuery,
    required this.searchMode,
    required this.favoritesIdentity,
    required this.favoritesCount,
    required this.taskWordsIdentity,
    required this.taskWordsCount,
    required this.todaySessions,
    required this.todayReviewed,
    required this.todayRemembered,
    required this.totalSessions,
    required this.totalReviewed,
    required this.totalRemembered,
    required this.lastSessionTitle,
    required this.rememberedWordCount,
    required this.weakWordCount,
    required this.sessionHistoryCount,
    required this.latestSessionAt,
    required this.roundSource,
    required this.roundStartMode,
    required this.roundSize,
    required this.roundShuffle,
    required this.roundCollapsed,
  });

  factory _PracticePageRebuildToken.fromState(AppState state) {
    final selected = state.selectedWordbook;
    final round = state.practiceRoundSettings;
    return _PracticePageRebuildToken(
      uiLanguage: state.uiLanguage,
      practiceEnabled: state.isModuleEnabled(ModuleIds.practice),
      selectedWordbookId: selected?.id,
      selectedWordbookName: selected?.name ?? '',
      selectedWordbookPath: selected?.path ?? '',
      selectedWordbookWordCount: selected?.wordCount ?? 0,
      selectedWordbookLoaded: state.selectedWordbookLoaded,
      selectedWordbookRequiresOnDemandLoad:
          state.selectedWordbookRequiresOnDemandLoad,
      wordsVersion: state.wordsVersion,
      wordsLength: state.words.length,
      currentWordIndex: state.currentWordIndex,
      searchQuery: state.searchQuery,
      searchMode: state.searchMode,
      favoritesIdentity: identityHashCode(state.favorites),
      favoritesCount: state.favorites.length,
      taskWordsIdentity: identityHashCode(state.taskWords),
      taskWordsCount: state.taskWords.length,
      todaySessions: state.practiceTodaySessions,
      todayReviewed: state.practiceTodayReviewed,
      todayRemembered: state.practiceTodayRemembered,
      totalSessions: state.practiceTotalSessions,
      totalReviewed: state.practiceTotalReviewed,
      totalRemembered: state.practiceTotalRemembered,
      lastSessionTitle: state.practiceLastSessionTitle,
      rememberedWordCount: state.practiceRememberedWordCount,
      weakWordCount: state.practiceWeakWordCount,
      sessionHistoryCount: state.practiceSessionHistoryCount,
      latestSessionAt: state.practiceLatestSessionAt,
      roundSource: round.source,
      roundStartMode: round.startMode,
      roundSize: round.roundSize,
      roundShuffle: round.shuffle,
      roundCollapsed: round.collapsed,
    );
  }

  final String uiLanguage;
  final bool practiceEnabled;
  final int? selectedWordbookId;
  final String selectedWordbookName;
  final String selectedWordbookPath;
  final int selectedWordbookWordCount;
  final bool selectedWordbookLoaded;
  final bool selectedWordbookRequiresOnDemandLoad;
  final int wordsVersion;
  final int wordsLength;
  final int currentWordIndex;
  final String searchQuery;
  final SearchMode searchMode;
  final int favoritesIdentity;
  final int favoritesCount;
  final int taskWordsIdentity;
  final int taskWordsCount;
  final int todaySessions;
  final int todayReviewed;
  final int todayRemembered;
  final int totalSessions;
  final int totalReviewed;
  final int totalRemembered;
  final String lastSessionTitle;
  final int rememberedWordCount;
  final int weakWordCount;
  final int sessionHistoryCount;
  final DateTime? latestSessionAt;
  final PracticeRoundSource roundSource;
  final PracticeRoundStartMode roundStartMode;
  final int roundSize;
  final bool roundShuffle;
  final bool roundCollapsed;

  @override
  bool operator ==(Object other) {
    return other is _PracticePageRebuildToken &&
        other.uiLanguage == uiLanguage &&
        other.practiceEnabled == practiceEnabled &&
        other.selectedWordbookId == selectedWordbookId &&
        other.selectedWordbookName == selectedWordbookName &&
        other.selectedWordbookPath == selectedWordbookPath &&
        other.selectedWordbookWordCount == selectedWordbookWordCount &&
        other.selectedWordbookLoaded == selectedWordbookLoaded &&
        other.selectedWordbookRequiresOnDemandLoad ==
            selectedWordbookRequiresOnDemandLoad &&
        other.wordsVersion == wordsVersion &&
        other.wordsLength == wordsLength &&
        other.currentWordIndex == currentWordIndex &&
        other.searchQuery == searchQuery &&
        other.searchMode == searchMode &&
        other.favoritesIdentity == favoritesIdentity &&
        other.favoritesCount == favoritesCount &&
        other.taskWordsIdentity == taskWordsIdentity &&
        other.taskWordsCount == taskWordsCount &&
        other.todaySessions == todaySessions &&
        other.todayReviewed == todayReviewed &&
        other.todayRemembered == todayRemembered &&
        other.totalSessions == totalSessions &&
        other.totalReviewed == totalReviewed &&
        other.totalRemembered == totalRemembered &&
        other.lastSessionTitle == lastSessionTitle &&
        other.rememberedWordCount == rememberedWordCount &&
        other.weakWordCount == weakWordCount &&
        other.sessionHistoryCount == sessionHistoryCount &&
        other.latestSessionAt == latestSessionAt &&
        other.roundSource == roundSource &&
        other.roundStartMode == roundStartMode &&
        other.roundSize == roundSize &&
        other.roundShuffle == roundShuffle &&
        other.roundCollapsed == roundCollapsed;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    uiLanguage,
    practiceEnabled,
    selectedWordbookId,
    selectedWordbookName,
    selectedWordbookPath,
    selectedWordbookWordCount,
    selectedWordbookLoaded,
    selectedWordbookRequiresOnDemandLoad,
    wordsVersion,
    wordsLength,
    currentWordIndex,
    searchQuery,
    searchMode,
    favoritesIdentity,
    favoritesCount,
    taskWordsIdentity,
    taskWordsCount,
    todaySessions,
    todayReviewed,
    todayRemembered,
    totalSessions,
    totalReviewed,
    totalRemembered,
    lastSessionTitle,
    rememberedWordCount,
    weakWordCount,
    sessionHistoryCount,
    latestSessionAt,
    roundSource,
    roundStartMode,
    roundSize,
    roundShuffle,
    roundCollapsed,
  ]);
}

class _PracticeWordbookLoadState extends StatelessWidget {
  const _PracticeWordbookLoadState({
    required this.i18n,
    required this.state,
    required this.onLoad,
    required this.onSwitchWordbook,
  });

  final AppI18n i18n;
  final AppState state;
  final Future<bool> Function() onLoad;
  final VoidCallback onSwitchWordbook;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                StudyWordbookStatusBar(
                  state: state,
                  i18n: i18n,
                  visibleCount: state.visibleWordCount,
                  onTap: onSwitchWordbook,
                  onLoadCurrent: onLoad,
                ),
                const SizedBox(height: 18),
                Icon(
                  Icons.library_books_rounded,
                  size: 38,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  i18n.t('study.wordbook.deferred.practice_title'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  studyWordbookStatusMessage(
                    state,
                    i18n,
                    visibleCount: state.visibleWordCount,
                  ),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: () => onLoad(),
                      icon: const Icon(Icons.download_done_rounded),
                      label: Text(i18n.t('study.wordbook.action.load_current')),
                    ),
                    OutlinedButton.icon(
                      onPressed: onSwitchWordbook,
                      icon: const Icon(Icons.menu_book_rounded),
                      label: Text(i18n.t('study.wordbook.action.switch')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
