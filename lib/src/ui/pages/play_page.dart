import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/app_i18n.dart';
import '../../models/play_config.dart';
import '../../models/weather_snapshot.dart';
import '../../models/word_entry.dart';
import '../../state/app_state.dart';
import '../../state/app_state_provider.dart';
import '../modal_helpers.dart';
import '../sheets/ambient_sheet.dart';
import '../theme/app_theme.dart';
import '../ui_copy.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/section_header.dart';
import '../widgets/status_badge.dart';
import '../widgets/study_wordbook_status.dart';
import '../widgets/study_search_loading_view.dart';
import '../widgets/word_card.dart';
import 'follow_along_page.dart';

part 'play_page_navigation.dart';
part 'play_page_weather.dart';

class PlayPage extends ConsumerStatefulWidget {
  const PlayPage({
    super.key,
    required this.onOpenPractice,
    required this.onOpenLibrary,
    this.isActive = true,
  });

  final VoidCallback onOpenPractice;
  final VoidCallback onOpenLibrary;
  final bool isActive;

  @override
  ConsumerState<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends ConsumerState<PlayPage> {
  int _transitionDirection = 1;
  double? _progressDragValue;
  bool _continuousPathExpanded = false;
  late final AppState _appState;

  void _handlePlaybackRevision() {
    if (!mounted || !widget.isActive) {
      return;
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _appState = ref.read(appStateProvider);
    _appState.playbackRevisionListenable.addListener(_handlePlaybackRevision);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(appStateProvider).refreshWeatherIfStale();
    });
  }

  @override
  void didUpdateWidget(covariant PlayPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _appState.playbackRevisionListenable.removeListener(
      _handlePlaybackRevision,
    );
    super.dispose();
  }

  void _setTransitionDirection(int direction) {
    if (_transitionDirection == direction) return;
    setState(() {
      _transitionDirection = direction;
    });
  }

  @override
  Widget build(BuildContext context) {
    // The parent AppShell retains this tab for navigation, but an inactive
    // playback page should not evaluate its rebuild token or keep its full
    // word-card tree mounted while another module is active.
    if (!widget.isActive) {
      return const SizedBox.shrink();
    }
    final token = ref.watch(
      appStateProvider.select(_PlayPageRebuildToken.fromState),
    );
    final state = ref.read(appStateProvider);
    final i18n = AppI18n(token.uiLanguage);
    final selectedWordbook = state.selectedWordbook;
    final current = state.currentWord;
    if (selectedWordbook == null) {
      return EmptyStateView(
        icon: Icons.play_circle_outline_rounded,
        title: i18n.t('study.play.empty.title'),
        message: i18n.t('noWordbookYet'),
        actionLabel: i18n.t('study.wordbook.action.choose'),
        onAction: () =>
            showStudyWordbookSheet(context: context, state: state, i18n: i18n),
      );
    }
    if (studyWordbookNeedsExplicitLoad(state)) {
      return _PlayWordbookLoadState(
        state: state,
        i18n: i18n,
        onLoadAndPlay: state.playCurrentWordbook,
        onSwitchWordbook: () =>
            showStudyWordbookSheet(context: context, state: state, i18n: i18n),
      );
    }
    if (state.wordbookSearchInProgress) {
      return StudySearchLoadingView(label: i18n.t('processing'));
    }
    if (current == null) {
      final searching = state.searchQuery.trim().isNotEmpty;
      return EmptyStateView(
        icon: searching
            ? Icons.search_off_rounded
            : Icons.play_circle_outline_rounded,
        title: searching
            ? i18n.t('study.play.empty.search_empty.title')
            : i18n.t('study.play.empty.selected_empty.title'),
        message: searching
            ? i18n.t('study.play.empty.search_empty.message')
            : i18n.t('study.play.empty.selected_empty.message'),
        actionLabel: searching
            ? i18n.t('inline.ui.pages.library_page.clear_search_028a7e')
            : pageLabelLibrary(i18n),
        onAction: searching
            ? () => state.setSearchQuery('')
            : widget.onOpenLibrary,
      );
    }

    final visibleWords = state.visibleWords;
    final index = _indexOfWord(state, visibleWords, current);
    final position = visibleWords.isEmpty
        ? 0.0
        : ((index + 1) / visibleWords.length);
    final effectiveSliderValue =
        _progressDragValue ??
        _resolveSliderValue(index < 0 ? 0 : index, visibleWords.length);
    final previewIndex = _resolveTargetIndex(
      effectiveSliderValue,
      visibleWords.length,
    );
    final progressStep = _progressJumpStep(visibleWords.length);
    final mode = experienceModeFromAppearance(state.config.appearance);
    final weakCount = state.practiceWeakWordCount;
    final todayAccuracy = (state.practiceTodayAccuracy * 100).round();
    final isPlaybackPaused = state.isPlaying && state.isPaused;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: <Widget>[
        StudyWordbookStatusBar(
          state: state,
          i18n: i18n,
          visibleCount: visibleWords.length,
          searching: state.searchQuery.trim().isNotEmpty,
          onTap: () => showStudyWordbookSheet(
            context: context,
            state: state,
            i18n: i18n,
          ),
          onLoadCurrent: state.loadSelectedWordbook,
        ),
        const SizedBox(height: 14),
        WordCard(
          word: current,
          i18n: i18n,
          density: WordCardDensity.immersive,
          transitionStyle: state.config.wordPageTransitionStyle,
          transitionDirection: _transitionDirection,
          showMeaning: state.config.showText,
          showFields: mode == AppExperienceMode.focus,
          isFavorite: state.isFavoriteEntry(current),
          isTaskWord: state.isTaskEntry(current),
          onToggleFavorite: () => state.toggleFavorite(current),
          onToggleTask: () => state.toggleTaskWord(current),
          onPlayPronunciation: () => state.previewPronunciation(current.word),
          onFollowAlong: () => _openFollowAlong(context, state, current),
          onPreviousWord: () => _moveToPreviousWord(
            state,
            visibleWords: visibleWords,
            currentIndex: index,
          ),
          onNextWord: () => _moveToNextWord(
            state,
            visibleWords: visibleWords,
            currentIndex: index,
          ),
          onSwipePrevious: () => _moveToPreviousWord(
            state,
            visibleWords: visibleWords,
            currentIndex: index,
          ),
          onSwipeNext: () => _moveToNextWord(
            state,
            visibleWords: visibleWords,
            currentIndex: index,
          ),
        ),
        const SizedBox(height: 16),
        _buildPlaybackControlCard(context, i18n, state),
        const SizedBox(height: 16),
        _buildPlaybackProgressCard(
          context,
          i18n,
          state,
          visibleWords: visibleWords,
          currentIndex: index,
          position: position,
          effectiveSliderValue: effectiveSliderValue,
          previewIndex: previewIndex,
          progressStep: progressStep,
        ),
        const SizedBox(height: 16),
        _buildPlaybackModeCard(context, i18n, state),
        const SizedBox(height: 16),
        _buildContinuousPathCard(
          context,
          i18n,
          state,
          mode: mode,
          isPlaybackPaused: isPlaybackPaused,
          weakCount: weakCount,
          todayAccuracy: todayAccuracy,
        ),
      ],
    );
  }

  Widget _buildPlaybackControlCard(
    BuildContext context,
    AppI18n i18n,
    AppState state,
  ) {
    final statusAction = _buildHeaderAction(
      context,
      i18n,
      state,
      isPlaybackPaused: state.isPlaying && state.isPaused,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final primaryControl = FilledButton.icon(
              onPressed: state.isPlaying
                  ? state.pauseOrResume
                  : state.playCurrentWordbook,
              icon: Icon(
                state.isPlaying && !state.isPaused
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
              ),
              label: Text(
                state.isPlaying && !state.isPaused
                    ? i18n.t('pause')
                    : i18n.t('play'),
              ),
            );
            final secondaryButtons = <Widget>[
              OutlinedButton.icon(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => AmbientSheet(state: state, i18n: i18n),
                ),
                icon: const Icon(Icons.surround_sound_rounded),
                label: Text(i18n.t('inline.ui.pages.play_page.ambient_6e3e01')),
              ),
              OutlinedButton.icon(
                onPressed: widget.onOpenPractice,
                icon: const Icon(Icons.fitness_center_rounded),
                label: Text(pageLabelPractice(i18n)),
              ),
              OutlinedButton.icon(
                onPressed: widget.onOpenLibrary,
                icon: const Icon(Icons.menu_book_rounded),
                label: Text(pageLabelLibrary(i18n)),
              ),
            ];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Align(alignment: Alignment.centerRight, child: statusAction),
                const SizedBox(height: 10),
                SizedBox(width: double.infinity, child: primaryControl),
                const SizedBox(height: 10),
                Wrap(spacing: 10, runSpacing: 10, children: secondaryButtons),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlaybackProgressCard(
    BuildContext context,
    AppI18n i18n,
    AppState state, {
    required List<WordEntry> visibleWords,
    required int currentIndex,
    required double position,
    required double effectiveSliderValue,
    required int previewIndex,
    required int progressStep,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SectionHeader(
              title: i18n.t(
                'inline.ui.pages.play_page.playback_progress_4535e2',
              ),
              subtitle: i18n.t(
                _progressDragValue == null
                    ? 'play.progress.currentPosition'
                    : 'play.progress.previewPosition',
                params: <String, Object?>{
                  'position': _progressDragValue == null
                      ? currentIndex + 1
                      : previewIndex + 1,
                  'total': visibleWords.length,
                },
              ),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: position.clamp(0, 1)),
            const SizedBox(height: 10),
            Slider(
              value: effectiveSliderValue,
              min: 0,
              max: 1,
              onChangeStart: visibleWords.length <= 1
                  ? null
                  : (value) {
                      setState(() {
                        _progressDragValue = value;
                      });
                    },
              onChanged: visibleWords.length <= 1
                  ? null
                  : (value) {
                      setState(() {
                        _progressDragValue = value;
                      });
                    },
              onChangeEnd: visibleWords.length <= 1
                  ? null
                  : (value) {
                      setState(() {
                        _progressDragValue = null;
                      });
                      _jumpToIndex(
                        state,
                        visibleWords: visibleWords,
                        currentIndex: currentIndex,
                        targetIndex: _resolveTargetIndex(
                          value,
                          visibleWords.length,
                        ),
                      );
                    },
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                ActionChip(
                  onPressed: visibleWords.length <= 1
                      ? null
                      : () => _jumpToIndex(
                          state,
                          visibleWords: visibleWords,
                          currentIndex: currentIndex,
                          targetIndex:
                              (currentIndex < 0 ? 0 : currentIndex) -
                              progressStep,
                        ),
                  label: Text('-$progressStep'),
                ),
                ActionChip(
                  onPressed: visibleWords.length <= 1
                      ? null
                      : () => _openExactJumpDialog(
                          context,
                          state,
                          i18n,
                          visibleWords: visibleWords,
                          currentIndex: currentIndex,
                        ),
                  label: Text(
                    i18n.t(
                      'inline.ui.pages.play_page_navigation.exact_jump_8b53eb',
                    ),
                  ),
                ),
                ActionChip(
                  onPressed: visibleWords.length <= 1
                      ? null
                      : () => _jumpToIndex(
                          state,
                          visibleWords: visibleWords,
                          currentIndex: currentIndex,
                          targetIndex:
                              (currentIndex < 0 ? 0 : currentIndex) +
                              progressStep,
                        ),
                  label: Text('+$progressStep'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaybackModeCard(
    BuildContext context,
    AppI18n i18n,
    AppState state,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SectionHeader(
              title: i18n.t('inline.ui.pages.play_page.playback_mode_c376ec'),
              subtitle: i18n.t(
                'inline.ui.pages.play_page.keep_high_frequency_controls_close_to_the_listening_flow_8f61b8',
              ),
            ),
            const SizedBox(height: 14),
            SegmentedButton<PlayOrder>(
              segments: PlayOrder.values
                  .map(
                    (order) => ButtonSegment<PlayOrder>(
                      value: order,
                      label: Text(playOrderLabel(i18n, order)),
                    ),
                  )
                  .toList(growable: false),
              selected: <PlayOrder>{state.config.order},
              onSelectionChanged: (selection) {
                state.updateConfig(
                  state.config.copyWith(order: selection.first),
                );
              },
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(i18n.t('showText')),
              subtitle: Text(
                i18n.t(
                  'inline.ui.pages.play_page.hide_text_when_you_want_a_lower_visual_listening_mode_bdf164',
                ),
              ),
              value: state.config.showText,
              onChanged: (value) =>
                  state.updateConfig(state.config.copyWith(showText: value)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinuousPathCard(
    BuildContext context,
    AppI18n i18n,
    AppState state, {
    required AppExperienceMode mode,
    required bool isPlaybackPaused,
    required int weakCount,
    required int todayAccuracy,
  }) {
    final showModeSuggestion =
        (mode == AppExperienceMode.sleep && state.config.showText) ||
        (mode == AppExperienceMode.focus && !state.config.showText);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SectionHeader(
              title: i18n.t('inline.ui.pages.play_page.continuous_path_f22825'),
              subtitle: i18n.t(
                'inline.ui.pages.play_page.move_from_playback_into_practice_then_fine_tune_the_curr_ef58fe',
              ),
              trailing: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _continuousPathExpanded = !_continuousPathExpanded;
                  });
                },
                icon: Icon(
                  _continuousPathExpanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                ),
                label: Text(
                  _continuousPathExpanded
                      ? i18n.t(
                          'inline.plan295.daily_choice.collapse.ad0db950964e',
                        )
                      : i18n.t('inline.ui.pages.play_page.expand_33fdcb'),
                ),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              crossFadeState: _continuousPathExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  i18n.t(
                    'inline.ui.pages.play_page.the_path_is_hidden_expand_it_whenever_you_want_the_playb_5ff4be',
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 14),
                  _FlowStepCard(
                    icon: isPlaybackPaused
                        ? Icons.play_circle_fill_rounded
                        : Icons.headphones_rounded,
                    title: i18n.t(
                      'inline.ui.pages.play_page.1_play_this_scope_ef8a6d',
                    ),
                    description: isPlaybackPaused
                        ? i18n.t(
                            'inline.ui.pages.play_page.resume_from_where_you_paused_and_keep_the_rhythm_going_1c0033',
                          )
                        : i18n.t(
                            'inline.ui.pages.play_page.continue_one_focused_pass_around_the_current_word_to_sat_31f09b',
                          ),
                    action: FilledButton.icon(
                      onPressed: isPlaybackPaused
                          ? state.pauseOrResume
                          : state.playCurrentWordbook,
                      icon: Icon(
                        isPlaybackPaused
                            ? Icons.play_arrow_rounded
                            : Icons.volume_up_rounded,
                      ),
                      label: Text(
                        isPlaybackPaused
                            ? i18n.t('resume')
                            : i18n.t(
                                'inline.ui.pages.play_page.start_playback_ecb1be',
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _FlowStepCard(
                    icon: weakCount > 0
                        ? Icons.fitness_center_rounded
                        : Icons.school_rounded,
                    title: i18n.t(
                      'inline.ui.pages.play_page.2_reinforce_in_practice_065b8b',
                    ),
                    description: weakCount > 0
                        ? i18n.t(
                            'inline.ui.pages.play_page.you_have_weakcount_recent_weak_words_recover_the_unstabl_b00953',
                            params: <String, Object?>{'count': weakCount},
                          )
                        : state.practiceTodaySessions > 0
                        ? i18n.t(
                            'play.practice.todaySummary',
                            params: <String, Object?>{
                              'sessions': state.practiceTodaySessions,
                              'accuracy': todayAccuracy,
                            },
                          )
                        : i18n.t('play.practice.afterPlaybackHint'),
                    action: FilledButton.tonalIcon(
                      onPressed: widget.onOpenPractice,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: Text(
                        weakCount > 0
                            ? i18n.t(
                                'inline.ui.pages.play_page.review_weak_words_303857',
                              )
                            : i18n.t(
                                'inline.ui.pages.play_page.open_practice_846215',
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _FlowStepCard(
                    icon: Icons.tune_rounded,
                    title: i18n.t(
                      'inline.ui.pages.play_page.3_tune_mode_strategy_9c9945',
                    ),
                    description: showModeSuggestion
                        ? (mode == AppExperienceMode.sleep
                              ? i18n.t(
                                  'inline.ui.pages.play_page.sleep_mode_works_better_as_a_listening_first_experience_ddd97e',
                                )
                              : i18n.t(
                                  'inline.ui.pages.play_page.focus_mode_works_better_with_text_visible_for_denser_rev_d2da30',
                                ))
                        : i18n.t(
                            'inline.ui.pages.play_page.your_current_presentation_strategy_already_matches_the_a_cbe677',
                          ),
                    action: FilledButton.tonalIcon(
                      onPressed: showModeSuggestion
                          ? () {
                              state.updateConfig(
                                state.config.copyWith(
                                  showText: mode == AppExperienceMode.focus,
                                ),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.auto_fix_high_rounded),
                      label: Text(
                        showModeSuggestion
                            ? (mode == AppExperienceMode.sleep
                                  ? i18n.t(
                                      'inline.ui.pages.play_page.hide_text_now_d44c57',
                                    )
                                  : i18n.t(
                                      'inline.ui.pages.play_page.show_text_now_a800ff',
                                    ))
                            : i18n.t(
                                'inline.ui.pages.play_page.already_aligned_224c0f',
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayPageRebuildToken {
  const _PlayPageRebuildToken({
    required this.uiLanguage,
    required this.selectedWordbookId,
    required this.selectedWordbookName,
    required this.selectedWordbookPath,
    required this.selectedWordbookWordCount,
    required this.selectedWordbookLoaded,
    required this.selectedWordbookRequiresOnDemandLoad,
    required this.wordsLength,
    required this.currentWordIndex,
    required this.currentWordIdentity,
    required this.currentWordId,
    required this.currentWordbookId,
    required this.currentWordText,
    required this.currentWordFavorite,
    required this.currentWordTask,
    required this.searchQuery,
    required this.searchMode,
    required this.wordbookSearchRevision,
    required this.isPlaying,
    required this.isPaused,
    required this.playOrder,
    required this.showText,
    required this.wordPageTransitionStyle,
    required this.appearanceTheme,
    required this.weakWordCount,
    required this.practiceTodaySessions,
    required this.practiceTodayReviewed,
    required this.practiceTodayRemembered,
    required this.weatherEnabled,
    required this.weatherLoading,
    required this.weatherSnapshotSignature,
  });

  factory _PlayPageRebuildToken.fromState(AppState state) {
    final selected = state.selectedWordbook;
    final current = state.currentWord;
    final config = state.config;
    return _PlayPageRebuildToken(
      uiLanguage: state.uiLanguage,
      selectedWordbookId: selected?.id,
      selectedWordbookName: selected?.name ?? '',
      selectedWordbookPath: selected?.path ?? '',
      selectedWordbookWordCount: selected?.wordCount ?? 0,
      selectedWordbookLoaded: state.selectedWordbookLoaded,
      selectedWordbookRequiresOnDemandLoad:
          state.selectedWordbookRequiresOnDemandLoad,
      wordsLength: state.words.length,
      currentWordIndex: state.currentWordIndex,
      currentWordIdentity: current == null ? 0 : identityHashCode(current),
      currentWordId: current?.id,
      currentWordbookId: current?.wordbookId ?? 0,
      currentWordText: current?.word ?? '',
      currentWordFavorite: current != null && state.isFavoriteEntry(current),
      currentWordTask: current != null && state.isTaskEntry(current),
      searchQuery: state.searchQuery,
      searchMode: state.searchMode,
      wordbookSearchRevision: state.wordbookSearchRevision,
      isPlaying: state.isPlaying,
      isPaused: state.isPaused,
      playOrder: config.order,
      showText: config.showText,
      wordPageTransitionStyle: config.wordPageTransitionStyle,
      appearanceTheme: config.appearance.normalizedTheme,
      weakWordCount: state.practiceWeakWordCount,
      practiceTodaySessions: state.practiceTodaySessions,
      practiceTodayReviewed: state.practiceTodayReviewed,
      practiceTodayRemembered: state.practiceTodayRemembered,
      weatherEnabled: state.weatherEnabled,
      weatherLoading: state.weatherLoading,
      weatherSnapshotSignature: _weatherSnapshotSignature(
        state.weatherSnapshot,
      ),
    );
  }

  final String uiLanguage;
  final int? selectedWordbookId;
  final String selectedWordbookName;
  final String selectedWordbookPath;
  final int selectedWordbookWordCount;
  final bool selectedWordbookLoaded;
  final bool selectedWordbookRequiresOnDemandLoad;
  final int wordsLength;
  final int currentWordIndex;
  final int currentWordIdentity;
  final int? currentWordId;
  final int currentWordbookId;
  final String currentWordText;
  final bool currentWordFavorite;
  final bool currentWordTask;
  final String searchQuery;
  final SearchMode searchMode;
  final int wordbookSearchRevision;
  final bool isPlaying;
  final bool isPaused;
  final PlayOrder playOrder;
  final bool showText;
  final WordPageTransitionStyle wordPageTransitionStyle;
  final String appearanceTheme;
  final int weakWordCount;
  final int practiceTodaySessions;
  final int practiceTodayReviewed;
  final int practiceTodayRemembered;
  final bool weatherEnabled;
  final bool weatherLoading;
  final String weatherSnapshotSignature;

  int get todayAccuracyPercent {
    if (practiceTodayReviewed <= 0) {
      return 0;
    }
    return ((practiceTodayRemembered / practiceTodayReviewed).clamp(0.0, 1.0) *
            100)
        .round();
  }

  static String _weatherSnapshotSignature(WeatherSnapshot? snapshot) {
    if (snapshot == null) {
      return '';
    }
    final forecastSignature = snapshot.forecastDays
        .take(4)
        .map(
          (day) =>
              '${day.date.toIso8601String()}:${day.weatherCode}:${day.maxTemperatureCelsius.round()}:${day.minTemperatureCelsius.round()}',
        )
        .join('|');
    return [
      snapshot.city,
      snapshot.countryCode,
      snapshot.temperatureCelsius.round(),
      snapshot.apparentTemperatureCelsius.round(),
      snapshot.windSpeedKph.round(),
      snapshot.weatherCode,
      snapshot.isDay,
      snapshot.fetchedAt.toIso8601String(),
      forecastSignature,
    ].join('|');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! _PlayPageRebuildToken) {
      return false;
    }
    return other.uiLanguage == uiLanguage &&
        other.selectedWordbookId == selectedWordbookId &&
        other.selectedWordbookName == selectedWordbookName &&
        other.selectedWordbookPath == selectedWordbookPath &&
        other.selectedWordbookWordCount == selectedWordbookWordCount &&
        other.selectedWordbookLoaded == selectedWordbookLoaded &&
        other.selectedWordbookRequiresOnDemandLoad ==
            selectedWordbookRequiresOnDemandLoad &&
        other.wordsLength == wordsLength &&
        other.currentWordIndex == currentWordIndex &&
        other.currentWordIdentity == currentWordIdentity &&
        other.currentWordId == currentWordId &&
        other.currentWordbookId == currentWordbookId &&
        other.currentWordText == currentWordText &&
        other.currentWordFavorite == currentWordFavorite &&
        other.currentWordTask == currentWordTask &&
        other.searchQuery == searchQuery &&
        other.searchMode == searchMode &&
        other.wordbookSearchRevision == wordbookSearchRevision &&
        other.isPlaying == isPlaying &&
        other.isPaused == isPaused &&
        other.playOrder == playOrder &&
        other.showText == showText &&
        other.wordPageTransitionStyle == wordPageTransitionStyle &&
        other.appearanceTheme == appearanceTheme &&
        other.weakWordCount == weakWordCount &&
        other.practiceTodaySessions == practiceTodaySessions &&
        other.practiceTodayReviewed == practiceTodayReviewed &&
        other.practiceTodayRemembered == practiceTodayRemembered &&
        other.weatherEnabled == weatherEnabled &&
        other.weatherLoading == weatherLoading &&
        other.weatherSnapshotSignature == weatherSnapshotSignature;
  }

  @override
  int get hashCode => Object.hash(
    Object.hash(
      uiLanguage,
      selectedWordbookId,
      selectedWordbookName,
      selectedWordbookPath,
      selectedWordbookWordCount,
      selectedWordbookLoaded,
      selectedWordbookRequiresOnDemandLoad,
      wordsLength,
      currentWordIndex,
      currentWordIdentity,
      currentWordId,
      currentWordbookId,
      currentWordText,
      currentWordFavorite,
      currentWordTask,
      searchQuery,
      searchMode,
      isPlaying,
      isPaused,
      playOrder,
    ),
    Object.hash(
      showText,
      wordPageTransitionStyle,
      appearanceTheme,
      weakWordCount,
      practiceTodaySessions,
      practiceTodayReviewed,
      practiceTodayRemembered,
      weatherEnabled,
      weatherLoading,
      weatherSnapshotSignature,
      wordbookSearchRevision,
    ),
  );
}

class _PlayWordbookLoadState extends StatelessWidget {
  const _PlayWordbookLoadState({
    required this.state,
    required this.i18n,
    required this.onLoadAndPlay,
    required this.onSwitchWordbook,
  });

  final AppState state;
  final AppI18n i18n;
  final Future<void> Function() onLoadAndPlay;
  final VoidCallback onSwitchWordbook;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                StudyWordbookStatusBar(
                  state: state,
                  i18n: i18n,
                  visibleCount: state.visibleWordCount,
                  onTap: onSwitchWordbook,
                  onLoadCurrent: state.loadSelectedWordbook,
                ),
                const SizedBox(height: 18),
                Text(
                  i18n.t('study.play.deferred.title'),
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
                      onPressed: () => onLoadAndPlay(),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(i18n.t('study.play.deferred.action')),
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

class _FlowStepCard extends StatelessWidget {
  const _FlowStepCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.action,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(description, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 10),
                action,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
