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
    if (current == null) {
      final deferredLoad = state.selectedWordbookRequiresOnDemandLoad;
      return EmptyStateView(
        icon: deferredLoad
            ? Icons.library_books_rounded
            : Icons.play_circle_outline_rounded,
        title: deferredLoad
            ? pickUiText(
                i18n,
                zh: '当前词本待加载',
                en: 'Wordbook ready to load',
                ja: '単語帳を読み込む準備ができました',
                de: 'Wortbuch kann geladen werden',
                fr: 'Le carnet est prêt à être chargé',
                es: 'El cuaderno está listo para cargarse',
              )
            : pickUiText(
                i18n,
                zh: '还没有播放内容',
                en: 'Nothing to play yet',
                ja: 'まだ再生できる内容がありません',
                de: 'Noch nichts zum Abspielen',
                fr: 'Rien à lire pour le moment',
                es: 'Todavía no hay contenido para reproducir',
              ),
        message: deferredLoad
            ? pickUiText(
                i18n,
                zh: '${localizedWordbookName(i18n, selectedWordbook)} 共有 ${state.visibleWordCount} 个词条。为保证大词库在手机上进入更稳定，请先按需加载，再由你决定何时开始播放。',
                en: '${localizedWordbookName(i18n, selectedWordbook)} has ${state.visibleWordCount} words. To keep large wordbooks stable on mobile, load it first and start playback only when you are ready.',
                ja: '${localizedWordbookName(i18n, selectedWordbook)} には ${state.visibleWordCount} 件の単語があります。モバイルで安定して使えるよう、まず必要分だけ読み込み、その後に好きなタイミングで再生を始められます。',
                de: '${localizedWordbookName(i18n, selectedWordbook)} enthält ${state.visibleWordCount} Wörter. Damit große Wortbücher mobil stabil bleiben, laden Sie es zuerst und starten die Wiedergabe erst dann, wenn Sie bereit sind.',
                fr: '${localizedWordbookName(i18n, selectedWordbook)} contient ${state.visibleWordCount} mots. Pour garder les grands carnets stables sur mobile, chargez-les d’abord puis lancez la lecture quand vous le souhaitez.',
                es: '${localizedWordbookName(i18n, selectedWordbook)} contiene ${state.visibleWordCount} palabras. Para mantener estables los cuadernos grandes en móvil, primero cárgalo y empieza la reproducción solo cuando quieras.',
              )
            : i18n.t('noWordbookYet'),
        actionLabel: deferredLoad
            ? pickUiText(
                i18n,
                zh: '加载',
                en: 'Load',
                ja: '読み込む',
                de: 'Laden',
                fr: 'Charger',
                es: 'Cargar',
              )
            : pickUiText(
                i18n,
                zh: '去词库选择词本',
                en: 'Choose wordbook in Library',
                ja: 'ライブラリで単語帳を選択',
                de: 'Wortbuch in der Bibliothek wählen',
                fr: 'Choisir un carnet dans la bibliothèque',
                es: 'Elegir cuaderno en la biblioteca',
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
