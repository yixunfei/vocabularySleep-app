import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../models/play_config.dart';
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
    state.selectWordEntry(visibleWords[target]);
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
    state.selectWordEntry(visibleWords[target]);
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
                      await state.selectWordbook(book);
                      if (context.mounted) Navigator.of(context).pop();
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
      );
    }

    final visibleWords = state.visibleWords;
    final index = _indexOfWord(visibleWords, current);
    final position = visibleWords.isEmpty
        ? 0.0
        : ((index + 1) / visibleWords.length);
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
                  title: pickUiText(
                    i18n,
                    zh: '下一步建议',
                    en: 'Suggested next step',
                  ),
                  subtitle: pickUiText(
                    i18n,
                    zh: '把播放、练习和模式策略串联成连续路径。',
                    en: 'Connect playback, practice, and mode strategy.',
                  ),
                ),
                const SizedBox(height: 12),
                if (weakCount > 0)
                  Text(
                    pickUiText(
                      i18n,
                      zh: '你有 $weakCount 个最近薄弱词，建议先进入练习中心复习。',
                      en: 'You have $weakCount recent weak words. Practice is recommended first.',
                    ),
                  )
                else if (showModeSuggestion)
                  Text(
                    mode == AppExperienceMode.sleep
                        ? pickUiText(
                            i18n,
                            zh: '当前是 Sleep 模式，建议关闭文本以减少视觉刺激。',
                            en: 'Sleep mode is active. Hiding text can reduce visual stimulation.',
                          )
                        : pickUiText(
                            i18n,
                            zh: '当前是 Focus 模式，建议开启文本以提高复习效率。',
                            en: 'Focus mode works better with text shown.',
                          ),
                  )
                else
                  Text(
                    pickUiText(
                      i18n,
                      zh: state.practiceTodaySessions > 0
                          ? '你今天已完成 ${state.practiceTodaySessions} 次练习，当前正确率 $todayAccuracy%。可继续播放巩固。'
                          : '建议先播放一轮当前范围，再进入练习中心做巩固。',
                      en: state.practiceTodaySessions > 0
                          ? 'You finished ${state.practiceTodaySessions} sessions today at $todayAccuracy% accuracy. Keep reinforcing with playback.'
                          : 'Start with one playback cycle, then reinforce in Practice.',
                    ),
                  ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    if (weakCount > 0)
                      FilledButton.icon(
                        onPressed: widget.onOpenPractice,
                        icon: const Icon(Icons.fitness_center_rounded),
                        label: Text(
                          pickUiText(
                            i18n,
                            zh: '去复习薄弱词',
                            en: 'Review weak words',
                          ),
                        ),
                      )
                    else if (showModeSuggestion)
                      FilledButton.tonalIcon(
                        onPressed: () {
                          state.updateConfig(
                            state.config.copyWith(
                              showText: mode == AppExperienceMode.focus,
                            ),
                          );
                        },
                        icon: const Icon(Icons.auto_fix_high_rounded),
                        label: Text(
                          mode == AppExperienceMode.sleep
                              ? pickUiText(
                                  i18n,
                                  zh: '一键关闭文本',
                                  en: 'Hide text now',
                                )
                              : pickUiText(
                                  i18n,
                                  zh: '一键显示文本',
                                  en: 'Show text now',
                                ),
                        ),
                      ),
                    OutlinedButton.icon(
                      onPressed: widget.onOpenPractice,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: Text(
                        pickUiText(i18n, zh: '打开练习中心', en: 'Open practice'),
                      ),
                    ),
                  ],
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
                  zh: '当前位置 ${index + 1}/${visibleWords.length}',
                  en: 'Current position ${index + 1}/${visibleWords.length}',
                ),
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(value: position.clamp(0, 1)),
              const SizedBox(height: 10),
              Slider(
                value: index < 0 ? 0 : index.toDouble(),
                min: 0,
                max: visibleWords.isEmpty
                    ? 0
                    : (visibleWords.length - 1).toDouble(),
                divisions: visibleWords.length > 1
                    ? visibleWords.length - 1
                    : null,
                onChanged: visibleWords.length <= 1
                    ? null
                    : (value) {
                        final target = value.round();
                        final direction = target >= (index < 0 ? 0 : index)
                            ? 1
                            : -1;
                        _setTransitionDirection(direction);
                        state.selectWordEntry(visibleWords[target]);
                      },
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
    final title =
        snapshot?.city ?? pickUiText(i18n, zh: '天气获取中', en: 'Loading weather');
    final subtitle = snapshot == null
        ? pickUiText(
            i18n,
            zh: state.weatherLoading ? '正在更新当前城市天气' : '点击刷新天气',
            en: state.weatherLoading
                ? 'Refreshing current city weather'
                : 'Tap to refresh weather',
          )
        : '${snapshot.temperatureCelsius.round()}°C · ${weatherCodeLabel(i18n, snapshot.weatherCode, isDay: snapshot.isDay)}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => state.refreshWeather(force: true),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 152, maxWidth: 220),
          child: Ink(
            key: const ValueKey<String>('play-weather-badge'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge,
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (state.weatherLoading) ...<Widget>[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
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
