import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/app_i18n.dart';
import '../../models/play_config.dart';
import '../../models/weather_snapshot.dart';
import '../../models/word_entry.dart';
import '../../models/wordbook.dart';
import '../../state/app_state.dart';
import '../../state/app_state_provider.dart';
import '../modal_helpers.dart';
import '../sheets/ambient_sheet.dart';
import '../theme/app_theme.dart';
import '../ui_copy.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/page_header.dart';
import '../widgets/section_header.dart';
import '../widgets/status_badge.dart';
import '../widgets/word_card.dart';
import '../widgets/wordbook_switcher.dart';
import '../wordbook_localization.dart';
import 'follow_along_page.dart';

part 'play_page_navigation.dart';
part 'play_page_weather.dart';

class PlayPage extends ConsumerStatefulWidget {
  const PlayPage({
    super.key,
    required this.onOpenPractice,
    required this.onOpenLibrary,
  });

  final VoidCallback onOpenPractice;
  final VoidCallback onOpenLibrary;

  @override
  ConsumerState<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends ConsumerState<PlayPage> {
  int _transitionDirection = 1;
  double? _progressDragValue;
  bool _continuousPathExpanded = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(appStateProvider).refreshWeatherIfStale();
    });
  }

  void _setTransitionDirection(int direction) {
    if (_transitionDirection == direction) return;
    setState(() {
      _transitionDirection = direction;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final i18n = AppI18n(state.uiLanguage);
    final selectedWordbook = state.selectedWordbook;
    final current = state.currentWord;
    if (selectedWordbook == null) {
      return EmptyStateView(
        icon: Icons.play_circle_outline_rounded,
        title: i18n.t('inline.ui.pages.play_page.nothing_to_play_yet_1a4919'),
        message: i18n.t('noWordbookYet'),
        actionLabel: i18n.t(
          'inline.ui.pages.play_page.choose_wordbook_in_library_c5eef0',
        ),
        onAction: widget.onOpenLibrary,
      );
    }
    if (current == null) {
      final deferredLoad = state.selectedWordbookRequiresOnDemandLoad;
      return EmptyStateView(
        icon: deferredLoad
            ? Icons.library_books_rounded
            : Icons.play_circle_outline_rounded,
        title: deferredLoad
            ? i18n.t('inline.ui.pages.play_page.wordbook_ready_to_load_6c76bb')
            : i18n.t('inline.ui.pages.play_page.nothing_to_play_yet_1a4919'),
        message: deferredLoad
            ? i18n.t(
                'inline.ui.pages.play_page.localizedwordbookname_i18n_selectedwordbook_has_state_vi_c42762',
                params: <String, Object?>{
                  'wordbook': localizedWordbookName(i18n, selectedWordbook),
                  'count': state.visibleWordCount,
                },
              )
            : i18n.t('noWordbookYet'),
        actionLabel: deferredLoad
            ? i18n.t('inline.ui.pages.play_page.load_d7c72d')
            : i18n.t(
                'inline.ui.pages.play_page.choose_wordbook_in_library_c5eef0',
              ),
        onAction: deferredLoad
            ? () => state.playCurrentWordbook()
            : widget.onOpenLibrary,
      );
    }

    final visibleWords = state.visibleWords;
    final index = _indexOfWord(visibleWords, current);
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
    final weakCount = state.recentWeakWordEntries.length;
    final todayAccuracy = (state.practiceTodayAccuracy * 100).round();
    final showModeSuggestion =
        (mode == AppExperienceMode.sleep && state.config.showText) ||
        (mode == AppExperienceMode.focus && !state.config.showText);
    final isPlaybackPaused = state.isPlaying && state.isPaused;
    final headerAction = _buildHeaderAction(
      context,
      i18n,
      state,
      isPlaybackPaused: isPlaybackPaused,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: <Widget>[
        PageHeader(
          eyebrow: experienceModeTitle(i18n, mode),
          title: i18n.t(
            'inline.ui.pages.play_page.how_do_you_want_to_play_today_95f31c',
          ),
          subtitle: experienceModeDescription(i18n, mode),
          action: headerAction,
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SectionHeader(
                  title: i18n.t(
                    'inline.ui.pages.play_page.continuous_path_f22825',
                  ),
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
        ),
        const SizedBox(height: 18),
        WordbookSwitcher(
          wordbook: state.selectedWordbook,
          title: localizedWordbookName(i18n, state.selectedWordbook),
          subtitle: i18n.t(
            'inline.ui.pages.play_page.state_visiblewords_length_words_in_scope_5b655d',
            params: <String, Object?>{'count': state.visibleWords.length},
          ),
          onTap: () => _openWordbookSheet(context, state, i18n),
        ),
        const SizedBox(height: 18),
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
          footer: Column(
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
                        ? index + 1
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
                          currentIndex: index,
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
                            currentIndex: index,
                            targetIndex: (index < 0 ? 0 : index) - progressStep,
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
                            currentIndex: index,
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
                            currentIndex: index,
                            targetIndex: (index < 0 ? 0 : index) + progressStep,
                          ),
                    label: Text('+$progressStep'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SectionHeader(
                  title: i18n.t(
                    'inline.ui.pages.play_page.playback_mode_c376ec',
                  ),
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
                  onChanged: (value) => state.updateConfig(
                    state.config.copyWith(showText: value),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 420;
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
                    label: Text(
                      i18n.t('inline.ui.pages.play_page.ambient_6e3e01'),
                    ),
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

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      SizedBox(width: double.infinity, child: primaryControl),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: secondaryButtons,
                      ),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SizedBox(width: double.infinity, child: primaryControl),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: secondaryButtons,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
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
