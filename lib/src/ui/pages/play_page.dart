import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../models/play_config.dart';
import '../../models/weather_snapshot.dart';
import '../../models/word_entry.dart';
import '../../models/wordbook.dart';
import '../../state/app_state.dart';
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

class PlayPage extends StatefulWidget {
  const PlayPage({
    super.key,
    required this.onOpenPractice,
    required this.onOpenLibrary,
  });

  final VoidCallback onOpenPractice;
  final VoidCallback onOpenLibrary;

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  int _transitionDirection = 1;
  double? _progressDragValue;
  bool _continuousPathExpanded = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().refreshWeatherIfStale();
    });
  }

  void _setTransitionDirection(int direction) {
    if (_transitionDirection == direction) return;
    setState(() {
      _transitionDirection = direction;
    });
  }

  int _indexOfWord(List<WordEntry> words, WordEntry target) {
    for (var index = 0; index < words.length; index += 1) {
      final item = words[index];
      if (item.id != null && target.id != null && item.id == target.id) {
        return index;
      }
      if (item.word == target.word && item.wordbookId == target.wordbookId) {
        return index;
      }
    }
    return words.indexWhere((item) => item.word == target.word);
  }

  Future<void> _moveToPreviousWord(
    AppState state, {
    required List<WordEntry> visibleWords,
    required int currentIndex,
  }) async {
    _setTransitionDirection(-1);
    if (state.isPlaying) {
      await state.movePlaybackPreviousWord();
      return;
    }
    if (visibleWords.isEmpty) return;
    final base = currentIndex < 0 ? 0 : currentIndex;
    final target = (base - 1 + visibleWords.length) % visibleWords.length;
    final targetWord = visibleWords[target];
    state.selectWordEntry(targetWord);
    state.rememberPlaybackProgress(targetWord);
  }

  Future<void> _moveToNextWord(
    AppState state, {
    required List<WordEntry> visibleWords,
    required int currentIndex,
  }) async {
    _setTransitionDirection(1);
    if (state.isPlaying) {
      await state.movePlaybackNextWord();
      return;
    }
    if (visibleWords.isEmpty) return;
    final base = currentIndex < 0 ? 0 : currentIndex;
    final target = (base + 1) % visibleWords.length;
    final targetWord = visibleWords[target];
    state.selectWordEntry(targetWord);
    state.rememberPlaybackProgress(targetWord);
  }

  int _resolveTargetIndex(double value, int totalWords) {
    if (totalWords <= 1) {
      return 0;
    }
    final clamped = value.clamp(0.0, 1.0);
    return (clamped * (totalWords - 1)).round().clamp(0, totalWords - 1);
  }

  double _resolveSliderValue(int index, int totalWords) {
    if (totalWords <= 1) {
      return 0;
    }
    return (index.clamp(0, totalWords - 1) / (totalWords - 1)).toDouble();
  }

  int _progressJumpStep(int totalWords) {
    if (totalWords >= 10000) return 500;
    if (totalWords >= 5000) return 250;
    if (totalWords >= 2000) return 100;
    if (totalWords >= 500) return 25;
    if (totalWords >= 200) return 10;
    return 5;
  }

  void _jumpToIndex(
    AppState state, {
    required List<WordEntry> visibleWords,
    required int currentIndex,
    required int targetIndex,
  }) {
    if (visibleWords.isEmpty) {
      return;
    }
    final normalizedTarget = targetIndex.clamp(0, visibleWords.length - 1);
    final normalizedCurrent = currentIndex < 0 ? 0 : currentIndex;
    _setTransitionDirection(normalizedTarget >= normalizedCurrent ? 1 : -1);
    final targetWord = visibleWords[normalizedTarget];
    state.selectWordEntry(targetWord);
    state.rememberPlaybackProgress(targetWord);
  }

  Future<void> _openExactJumpDialog(
    BuildContext context,
    AppState state,
    AppI18n i18n, {
    required List<WordEntry> visibleWords,
    required int currentIndex,
  }) async {
    if (visibleWords.length <= 1) {
      return;
    }
    final raw = await showTextPromptDialog(
      context: context,
      title: pickUiText(i18n, zh: '精确跳转', en: 'Exact jump'),
      subtitle: pickUiText(
        i18n,
        zh: '输入 1 到 ${visibleWords.length} 之间的位置编号。',
        en: 'Enter a position between 1 and ${visibleWords.length}.',
      ),
      hintText: pickUiText(i18n, zh: '例如 256', en: 'e.g. 256'),
      confirmText: pickUiText(i18n, zh: '跳转', en: 'Jump'),
    );
    if (!mounted || !context.mounted || raw == null) {
      return;
    }
    final target = int.tryParse(raw.trim());
    if (target == null || target < 1 || target > visibleWords.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            pickUiText(
              i18n,
              zh: '请输入 1 到 ${visibleWords.length} 之间的编号。',
              en: 'Enter a number between 1 and ${visibleWords.length}.',
            ),
          ),
        ),
      );
      return;
    }
    _jumpToIndex(
      state,
      visibleWords: visibleWords,
      currentIndex: currentIndex,
      targetIndex: target - 1,
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

  Future<void> _openWordbookSheet(
    BuildContext context,
    AppState state,
    AppI18n i18n,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: <Widget>[
              Text(
                pickUiText(i18n, zh: '切换词本', en: 'Switch wordbook'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              for (final book in state.wordbooks) ...<Widget>[
                Card(
                  child: ListTile(
                    selected: state.selectedWordbook?.id == book.id,
                    title: Text(localizedWordbookName(i18n, book)),
                    subtitle: Text(
                      pickUiText(
                        i18n,
                        zh: '${book.wordCount} 个词',
                        en: '${book.wordCount} words',
                      ),
                    ),
                    onTap: () async {
                      final confirmed = await _confirmWordbookLoadIfNeeded(
                        state,
                        i18n,
                        book,
                      );
                      if (!confirmed) return;
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                      await state.selectWordbook(book);
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final i18n = AppI18n(state.uiLanguage);
    final current = state.currentWord;
    if (state.selectedWordbook == null || current == null) {
      return EmptyStateView(
        icon: Icons.play_circle_outline_rounded,
        title: pickUiText(i18n, zh: '还没有播放内容', en: 'Nothing to play yet'),
        message: i18n.t('noWordbookYet'),
        actionLabel: pickUiText(
          i18n,
          zh: '去词库选择词本',
          en: 'Choose wordbook in Library',
        ),
        onAction: widget.onOpenLibrary,
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
          title: pickUiText(
            i18n,
            zh: '今晚想怎么听',
            en: 'How do you want to play today',
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
                  title: pickUiText(i18n, zh: '连续路径', en: 'Continuous path'),
                  subtitle: pickUiText(
                    i18n,
                    zh: '先播放一轮，再进入练习巩固，最后按当前模式微调展示策略。',
                    en: 'Move from playback into practice, then fine-tune the current mode strategy.',
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
                          ? pickUiText(i18n, zh: '收起', en: 'Collapse')
                          : pickUiText(i18n, zh: '展开', en: 'Expand'),
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
                      pickUiText(
                        i18n,
                        zh: '路径已折叠，需要时再展开查看播放、练习和策略调整建议。',
                        en: 'The path is hidden. Expand it whenever you want the playback, practice, and tuning suggestions.',
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
                        title: pickUiText(
                          i18n,
                          zh: '1. 播放当前范围',
                          en: '1. Play this scope',
                        ),
                        description: isPlaybackPaused
                            ? pickUiText(
                                i18n,
                                zh: '从上次停下的位置继续听，保持节奏不断。',
                                en: 'Resume from where you paused and keep the rhythm going.',
                              )
                            : pickUiText(
                                i18n,
                                zh: '围绕当前单词继续听一轮，先把输入打满。',
                                en: 'Continue one focused pass around the current word to saturate input first.',
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
                                ? pickUiText(i18n, zh: '继续播放', en: 'Resume')
                                : pickUiText(
                                    i18n,
                                    zh: '开始一轮播放',
                                    en: 'Start playback',
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _FlowStepCard(
                        icon: weakCount > 0
                            ? Icons.fitness_center_rounded
                            : Icons.school_rounded,
                        title: pickUiText(
                          i18n,
                          zh: '2. 进入练习巩固',
                          en: '2. Reinforce in practice',
                        ),
                        description: weakCount > 0
                            ? pickUiText(
                                i18n,
                                zh: '你有 $weakCount 个最近薄弱词，优先回收这些不稳定项。',
                                en: 'You have $weakCount recent weak words. Recover the unstable items first.',
                              )
                            : pickUiText(
                                i18n,
                                zh: state.practiceTodaySessions > 0
                                    ? '今天已完成 ${state.practiceTodaySessions} 次练习，当前正确率 $todayAccuracy%。可以继续巩固。'
                                    : '听完一轮后立刻进入练习，会更容易把短时记忆压实。',
                                en: state.practiceTodaySessions > 0
                                    ? 'You finished ${state.practiceTodaySessions} sessions today at $todayAccuracy% accuracy. Keep reinforcing.'
                                    : 'Practice immediately after one pass to lock short-term memory in place.',
                              ),
                        action: FilledButton.tonalIcon(
                          onPressed: widget.onOpenPractice,
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: Text(
                            weakCount > 0
                                ? pickUiText(
                                    i18n,
                                    zh: '复习薄弱词',
                                    en: 'Review weak words',
                                  )
                                : pickUiText(
                                    i18n,
                                    zh: '打开练习中心',
                                    en: 'Open practice',
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _FlowStepCard(
                        icon: Icons.tune_rounded,
                        title: pickUiText(
                          i18n,
                          zh: '3. 调整模式策略',
                          en: '3. Tune mode strategy',
                        ),
                        description: showModeSuggestion
                            ? (mode == AppExperienceMode.sleep
                                  ? pickUiText(
                                      i18n,
                                      zh: '当前是 Sleep 模式，建议切到纯听，减少视觉刺激。',
                                      en: 'Sleep mode works better as a listening-first experience with less visual stimulation.',
                                    )
                                  : pickUiText(
                                      i18n,
                                      zh: '当前是 Focus 模式，建议显示文本，提高复习密度。',
                                      en: 'Focus mode works better with text visible for denser review.',
                                    ))
                            : pickUiText(
                                i18n,
                                zh: '当前展示策略已经和模式匹配，可以直接保持。',
                                en: 'Your current presentation strategy already matches the active mode.',
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
                                      ? pickUiText(
                                          i18n,
                                          zh: '切到纯听模式',
                                          en: 'Hide text now',
                                        )
                                      : pickUiText(
                                          i18n,
                                          zh: '显示文本提示',
                                          en: 'Show text now',
                                        ))
                                : pickUiText(
                                    i18n,
                                    zh: '策略已匹配',
                                    en: 'Already aligned',
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
          subtitle: pickUiText(
            i18n,
            zh: '${state.visibleWords.length} 个词可播放',
            en: '${state.visibleWords.length} words in scope',
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
          isFavorite: state.favorites.contains(current.word),
          isTaskWord: state.taskWords.contains(current.word),
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
                title: pickUiText(i18n, zh: '播放进度', en: 'Playback progress'),
                subtitle: pickUiText(
                  i18n,
                  zh: _progressDragValue == null
                      ? '当前位置 ${index + 1}/${visibleWords.length}'
                      : '预览位置 ${previewIndex + 1}/${visibleWords.length}',
                  en: _progressDragValue == null
                      ? 'Current position ${index + 1}/${visibleWords.length}'
                      : 'Preview position ${previewIndex + 1}/${visibleWords.length}',
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
                    label: Text(pickUiText(i18n, zh: '精确跳转', en: 'Exact jump')),
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
                  title: pickUiText(i18n, zh: '播放模式', en: 'Playback mode'),
                  subtitle: pickUiText(
                    i18n,
                    zh: '把高频控制收在主场景里',
                    en: 'Keep high-frequency controls close to the listening flow.',
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
                    pickUiText(
                      i18n,
                      zh: '睡眠场景可关闭释义，只保留语音输入',
                      en: 'Hide text when you want a lower-visual listening mode.',
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
                    label: Text(pickUiText(i18n, zh: '环境音', en: 'Ambient')),
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

  Widget _buildHeaderAction(
    BuildContext context,
    AppI18n i18n,
    AppState state, {
    required bool isPlaybackPaused,
  }) {
    final statusBadge = StatusBadge(
      label: isPlaybackPaused
          ? pickUiText(i18n, zh: '已暂停', en: 'Paused')
          : state.isPlaying
          ? pickUiText(i18n, zh: '播放中', en: 'Playing')
          : pickUiText(i18n, zh: '待播放', en: 'Ready'),
      icon: isPlaybackPaused
          ? Icons.pause_circle_filled_rounded
          : state.isPlaying
          ? Icons.graphic_eq_rounded
          : Icons.play_circle_outline_rounded,
    );
    if (!state.weatherEnabled) {
      return statusBadge;
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[_buildWeatherBadge(context, i18n, state), statusBadge],
    );
  }

  Widget _buildWeatherBadge(
    BuildContext context,
    AppI18n i18n,
    AppState state,
  ) {
    final snapshot = state.weatherSnapshot;
    final theme = Theme.of(context);
    final icon = snapshot == null
        ? Icons.cloud_sync_rounded
        : weatherCodeIcon(snapshot.weatherCode, isDay: snapshot.isDay);
    final tooltip = snapshot == null
        ? pickUiText(
            i18n,
            zh: state.weatherLoading ? '正在更新天气' : '点击查看天气详情',
            en: state.weatherLoading
                ? 'Refreshing weather'
                : 'Open weather details',
          )
        : '${snapshot.city} · ${snapshot.temperatureCelsius.round()}°C · ${weatherCodeLabel(i18n, snapshot.weatherCode, isDay: snapshot.isDay)}';
    final temperatureLabel = snapshot == null
        ? '--'
        : '${snapshot.temperatureCelsius.round()}°';

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey<String>('play-weather-badge'),
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showWeatherDetails(context, i18n),
          child: Ink(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.88),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Icon(icon, size: 24, color: theme.colorScheme.primary),
                Positioned(
                  bottom: 5,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      child: Text(
                        temperatureLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                if (state.weatherLoading)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showWeatherDetails(BuildContext context, AppI18n i18n) async {
    final state = context.read<AppState>();
    if (!state.weatherLoading && state.weatherSnapshot == null) {
      unawaited(state.refreshWeather(force: true));
    }

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Consumer<AppState>(
          builder: (sheetContext, state, _) {
            final snapshot = state.weatherSnapshot;
            final theme = Theme.of(sheetContext);
            final todayHigh = snapshot?.todayMaxTemperatureCelsius;
            final todayLow = snapshot?.todayMinTemperatureCelsius;
            final forecastDays =
                snapshot?.forecastDays ?? const <WeatherForecastDay>[];
            final upcomingDays = forecastDays.length <= 1
                ? const <WeatherForecastDay>[]
                : forecastDays.skip(1).toList(growable: false);
            final currentCondition = snapshot == null
                ? pickUiText(i18n, zh: '天气获取中', en: 'Loading weather')
                : weatherCodeLabel(
                    i18n,
                    snapshot.weatherCode,
                    isDay: snapshot.isDay,
                  );
            final currentIcon = snapshot == null
                ? Icons.cloud_sync_rounded
                : weatherCodeIcon(snapshot.weatherCode, isDay: snapshot.isDay);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          currentIcon,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              snapshot == null
                                  ? pickUiText(
                                      i18n,
                                      zh: '当前城市天气',
                                      en: 'Local weather',
                                    )
                                  : '${snapshot.city}, ${snapshot.countryCode}',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentCondition,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: pickUiText(i18n, zh: '刷新天气', en: 'Refresh'),
                        onPressed: state.weatherLoading
                            ? null
                            : () => state.refreshWeather(force: true),
                        icon: state.weatherLoading
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.colorScheme.primary,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                  if (state.weatherLoading) ...<Widget>[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                  const SizedBox(height: 18),
                  if (snapshot == null)
                    Text(
                      pickUiText(
                        i18n,
                        zh: '正在获取当前位置天气，稍后可下拉刷新查看更完整信息。',
                        en: 'Fetching local weather. Refresh in a moment for more details.',
                      ),
                      style: theme.textTheme.bodyMedium,
                    )
                  else ...<Widget>[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  '${snapshot.temperatureCelsius.round()}°C',
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  pickUiText(
                                    i18n,
                                    zh: '体感 ${snapshot.apparentTemperatureCelsius.round()}°C',
                                    en: 'Feels like ${snapshot.apparentTemperatureCelsius.round()}°C',
                                  ),
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          if (todayHigh != null && todayLow != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                                Text(
                                  pickUiText(
                                    i18n,
                                    zh: '今日高/低',
                                    en: 'Today H/L',
                                  ),
                                  style: theme.textTheme.labelMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${todayHigh.round()}° / ${todayLow.round()}°',
                                  style: theme.textTheme.titleMedium,
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        _buildWeatherMetricChip(
                          context: sheetContext,
                          label: pickUiText(i18n, zh: '风速', en: 'Wind'),
                          value: '${snapshot.windSpeedKph.round()} km/h',
                        ),
                        _buildWeatherMetricChip(
                          context: sheetContext,
                          label: pickUiText(i18n, zh: '天气', en: 'Condition'),
                          value: currentCondition,
                        ),
                        if (todayHigh != null && todayLow != null)
                          _buildWeatherMetricChip(
                            context: sheetContext,
                            label: pickUiText(
                              i18n,
                              zh: '最高/最低',
                              en: 'High / Low',
                            ),
                            value:
                                '${todayHigh.round()}° / ${todayLow.round()}°',
                          ),
                      ],
                    ),
                    if (upcomingDays.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 18),
                      Text(
                        pickUiText(i18n, zh: '未来天气', en: 'Upcoming forecast'),
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      for (final day in upcomingDays.take(3))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildWeatherForecastRow(
                            context: sheetContext,
                            i18n: i18n,
                            day: day,
                          ),
                        ),
                    ],
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWeatherMetricChip({
    required BuildContext context,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }

  Widget _buildWeatherForecastRow({
    required BuildContext context,
    required AppI18n i18n,
    required WeatherForecastDay day,
  }) {
    final theme = Theme.of(context);
    final label = _weatherDayLabel(context, i18n, day.date);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            weatherCodeIcon(day.weatherCode, isDay: true),
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  weatherCodeLabel(i18n, day.weatherCode, isDay: true),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            '${day.maxTemperatureCelsius.round()}° / ${day.minTemperatureCelsius.round()}°',
            style: theme.textTheme.titleSmall,
          ),
        ],
      ),
    );
  }

  String _weatherDayLabel(BuildContext context, AppI18n i18n, DateTime date) {
    final today = DateTime.now();
    if (DateUtils.isSameDay(date, today)) {
      return pickUiText(i18n, zh: '今天', en: 'Today');
    }
    final tomorrow = today.add(const Duration(days: 1));
    if (DateUtils.isSameDay(date, tomorrow)) {
      return pickUiText(i18n, zh: '明天', en: 'Tomorrow');
    }
    return MaterialLocalizations.of(context).formatShortDate(date);
  }

  Future<bool> _confirmWordbookLoadIfNeeded(
    AppState state,
    AppI18n i18n,
    Wordbook book,
  ) {
    if (!state.requiresWordbookLoadConfirmation(book)) {
      return Future<bool>.value(true);
    }
    return showConfirmDialog(
      context: context,
      title: pickUiText(i18n, zh: '初始化单词本', en: 'Initialize wordbook'),
      message: pickUiText(
        i18n,
        zh: '${localizedWordbookName(i18n, book)} 可能较大，首次加载会初始化内容并需要一些时间。确认后继续，请耐心等待。',
        en: '${localizedWordbookName(i18n, book)} may be large. The first load will initialize its contents and may take a while. Continue and please wait patiently.',
      ),
      confirmText: pickUiText(i18n, zh: '继续', en: 'Continue'),
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
