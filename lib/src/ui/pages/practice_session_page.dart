import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../models/practice_question_type.dart';
import '../../models/word_entry.dart';
import '../../services/app_log_service.dart';
import '../../state/app_state.dart';
import '../ui_copy.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/section_header.dart';
import '../widgets/word_card.dart';
import 'practice_support.dart';

const int _practiceAnswerTransitionWarnThresholdMs = 120;
const int _practiceTaskWordSyncWarnThresholdMs = 120;

class PracticeSessionPage extends StatefulWidget {
  const PracticeSessionPage({
    super.key,
    required this.title,
    required this.words,
    this.subtitle,
    this.shuffle = false,
    this.rotationKey,
    this.rotationSourceWords,
    this.rotationBatchSize,
    this.rotationCursorAdvance,
  });

  final String title;
  final List<WordEntry> words;
  final String? subtitle;
  final bool shuffle;
  final String? rotationKey;
  final List<WordEntry>? rotationSourceWords;
  final int? rotationBatchSize;
  final int? rotationCursorAdvance;

  @override
  State<PracticeSessionPage> createState() => _PracticeSessionPageState();
}

class _PracticeAnswerDecision {
  const _PracticeAnswerDecision({
    this.addToWrongNotebook = true,
    this.weakReasonIds = const <String>[],
  });

  final bool addToWrongNotebook;
  final List<String> weakReasonIds;
}

class _PendingPracticeAnswerFeedback {
  const _PendingPracticeAnswerFeedback({
    required this.current,
    required this.remembered,
    required this.addToWrongNotebook,
    required this.weakReasonIds,
  });

  final WordEntry current;
  final bool remembered;
  final bool addToWrongNotebook;
  final List<String> weakReasonIds;

  _PendingPracticeAnswerFeedback copyWith({
    bool? addToWrongNotebook,
    List<String>? weakReasonIds,
  }) {
    return _PendingPracticeAnswerFeedback(
      current: current,
      remembered: remembered,
      addToWrongNotebook: addToWrongNotebook ?? this.addToWrongNotebook,
      weakReasonIds: weakReasonIds ?? this.weakReasonIds,
    );
  }
}

class _PracticeMeaningCandidate {
  const _PracticeMeaningCandidate({
    required this.meaning,
    required this.normalizedMeaning,
  });

  final String meaning;
  final String normalizedMeaning;
}

class _PracticeSessionPageState extends State<PracticeSessionPage> {
  final AppLogService _log = AppLogService.instance;
  late List<WordEntry> _sessionWords;
  Map<String, String> _sessionMeaningByEntryKey = <String, String>{};
  List<_PracticeMeaningCandidate> _sessionMeaningCandidates =
      const <_PracticeMeaningCandidate>[];
  final List<WordEntry> _rememberedWords = <WordEntry>[];
  final List<WordEntry> _weakWords = <WordEntry>[];
  final Map<String, List<String>> _weakReasonIdsByWord =
      <String, List<String>>{};
  final TextEditingController _spellingController = TextEditingController();
  final FocusNode _spellingFocusNode = FocusNode();
  final Set<String> _selectedWeakReasons = <String>{};

  int _index = 0;
  int _remembered = 0;
  bool _revealed = false;
  bool _hintRevealed = false;
  bool _reported = false;
  bool _sessionStarted = false;
  bool _sessionSettingsExpanded = false;
  bool _autoAddWeakWordsToTask = false;
  bool _autoPlayPronunciation = false;
  bool _answerFeedbackDialogEnabled = true;
  bool _sessionPreferencesLoaded = false;

  PracticeQuestionType _questionType = PracticeQuestionType.flashcard;
  List<String> _meaningOptions = const <String>[];
  bool _objectiveAnswered = false;
  bool _objectiveCorrect = false;
  String? _objectiveSubmittedAnswer;
  String? _lastAutoPlayedKey;
  _PendingPracticeAnswerFeedback? _pendingAnswerFeedback;

  bool get _isCompleted => _index >= _sessionWords.length;
  bool get _usesInlineAnswerFeedback =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  WordEntry? get _currentWord {
    if (_sessionWords.isEmpty || _isCompleted) {
      return null;
    }
    return _sessionWords[_index];
  }

  @override
  void initState() {
    super.initState();
    _sessionWords = List<WordEntry>.from(widget.words);
    if (widget.shuffle) {
      _sessionWords.shuffle();
    }
    _rebuildSessionDerivedCaches();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sessionPreferencesLoaded) {
      return;
    }
    final state = context.read<AppState>();
    _autoAddWeakWordsToTask = state.practiceAutoAddWeakWordsToTask;
    _autoPlayPronunciation = state.practiceAutoPlayPronunciation;
    _hintRevealed = state.practiceShowHintsByDefault;
    _answerFeedbackDialogEnabled = state.practiceShowAnswerFeedbackDialog;
    _questionType = state.practiceDefaultQuestionType;
    _sessionPreferencesLoaded = true;
    _prepareCurrentQuestion();
  }

  @override
  void dispose() {
    _spellingController.dispose();
    _spellingFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uiLanguage = context.select<AppState, String>(
      (state) => state.uiLanguage,
    );
    final state = context.read<AppState>();
    final i18n = AppI18n(uiLanguage);
    if (_sessionWords.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: EmptyStateView(
          icon: Icons.fitness_center_rounded,
          title: pickUiText(i18n, zh: '没有可练习内容', en: 'No words to practice'),
          message: pickUiText(
            i18n,
            zh: '请先在词库中准备一些单词，再开始会话练习。',
            en: 'Prepare some words in your library before starting a session.',
          ),
        ),
      );
    }

    final current = _currentWord;
    final total = _sessionWords.length;
    final progress = total == 0 ? 0.0 : (_index / total).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: _isCompleted || current == null
            ? _buildResult(context, i18n)
            : _buildSession(context, state, i18n, current, total, progress),
      ),
    );
  }

  PracticeQuestionType get _resolvedQuestionType {
    final current = _currentWord;
    if (current == null) {
      return PracticeQuestionType.flashcard;
    }
    if (_questionType == PracticeQuestionType.mixed) {
      final supported = _supportedQuestionTypes(current);
      return supported[_index % supported.length];
    }
    final supported = _supportedQuestionTypes(current);
    if (!supported.contains(_questionType)) {
      return PracticeQuestionType.flashcard;
    }
    return _questionType;
  }

  List<PracticeQuestionType> get _sessionAvailableQuestionTypes {
    final available = <PracticeQuestionType>{PracticeQuestionType.flashcard};
    if (_sessionWords.any(_canBuildMeaningChoice)) {
      available.add(PracticeQuestionType.meaningChoice);
    }
    if (_sessionWords.any(
      (word) => _practiceMeaningForEntry(word).isNotEmpty,
    )) {
      available.add(PracticeQuestionType.spelling);
    }
    if (available.length >= 2) {
      available.add(PracticeQuestionType.mixed);
    }
    return PracticeQuestionType.values
        .where((type) => available.contains(type))
        .toList(growable: false);
  }

  List<PracticeQuestionType> _supportedQuestionTypes(WordEntry word) {
    final supported = <PracticeQuestionType>[PracticeQuestionType.flashcard];
    if (_canBuildMeaningChoice(word)) {
      supported.add(PracticeQuestionType.meaningChoice);
    }
    if (_practiceMeaningForEntry(word).isNotEmpty) {
      supported.add(PracticeQuestionType.spelling);
    }
    return supported;
  }

  bool _canBuildMeaningChoice(WordEntry word) {
    final currentMeaning = _practiceMeaningForEntry(word);
    if (currentMeaning.isEmpty) {
      return false;
    }
    final currentNormalizedMeaning = normalizePracticeAnswer(currentMeaning);
    final distractorCount = _sessionMeaningCandidates
        .where(
          (candidate) =>
              candidate.normalizedMeaning != currentNormalizedMeaning,
        )
        .take(2)
        .length;
    return distractorCount >= 2;
  }

  List<Widget> _buildSession(
    BuildContext context,
    AppState state,
    AppI18n i18n,
    WordEntry current,
    int total,
    double progress,
  ) {
    return <Widget>[
      _buildProgressCard(context, state, i18n, total, progress),
      const SizedBox(height: 16),
      ...switch (_resolvedQuestionType) {
        PracticeQuestionType.flashcard => _buildFlashcardQuestion(
          context,
          state,
          i18n,
          current,
        ),
        PracticeQuestionType.meaningChoice || PracticeQuestionType.spelling =>
          _buildObjectiveQuestion(context, state, i18n, current),
        PracticeQuestionType.mixed => const <Widget>[],
      },
    ];
  }

  List<Widget> _buildResult(BuildContext context, AppI18n i18n) {
    final total = _sessionWords.length;
    final weakCount = _weakWords.length;
    final rememberedWords = _rememberedWords.length;
    final remembered = _remembered.clamp(0, total);
    final accuracy = total == 0 ? 0 : ((remembered / total) * 100).round();
    final reasonCounts = <String, int>{};
    for (final reasons in _weakReasonIdsByWord.values) {
      for (final reason in reasons) {
        reasonCounts.update(reason, (value) => value + 1, ifAbsent: () => 1);
      }
    }

    return <Widget>[
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SectionHeader(
                title: pickUiText(i18n, zh: '本轮完成', en: 'Session completed'),
                subtitle: pickUiText(
                  i18n,
                  zh: '你已完成本次练习会话。',
                  en: 'You have completed this practice session.',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                pickUiText(
                  i18n,
                  zh: '正确率：$accuracy%',
                  en: 'Accuracy: $accuracy%',
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                pickUiText(
                  i18n,
                  zh: '记住：$remembered，需加强：$weakCount（共 $total）',
                  en: 'Remembered: $remembered, Weak: $weakCount (Total $total)',
                ),
              ),
              if (_rememberedWords.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  pickUiText(i18n, zh: '已记住单词', en: 'Remembered words'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _rememberedWords
                      .take(8)
                      .map(
                        (item) => Chip(
                          avatar: const Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                          ),
                          label: Text(item.word),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
              if (_weakWords.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  pickUiText(i18n, zh: '薄弱词', en: 'Weak words'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _weakWords
                      .take(8)
                      .map((item) => Chip(label: Text(item.word)))
                      .toList(growable: false),
                ),
              ],
              if (reasonCounts.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  pickUiText(i18n, zh: '主要失分原因', en: 'Main weak reasons'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      (reasonCounts.entries.toList(growable: false)..sort(
                            (left, right) => right.value.compareTo(left.value),
                          ))
                          .map(
                            (entry) => Chip(
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
        ),
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: <Widget>[
          FilledButton.icon(
            onPressed: () => _handlePrimaryAction(context.read<AppState>()),
            icon: Icon(_primaryActionIcon),
            label: Text(_primaryActionLabel(i18n)),
          ),
          if (rememberedWords > 0)
            OutlinedButton.icon(
              onPressed: () => _restart(_rememberedWords, shuffle: true),
              icon: const Icon(Icons.auto_awesome_rounded),
              label: Text(
                pickUiText(i18n, zh: '复习已记住', en: 'Review remembered'),
              ),
            ),
          if (_weakWords.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () => _restart(_weakWords),
              icon: const Icon(Icons.fitness_center_rounded),
              label: Text(
                pickUiText(i18n, zh: '复习薄弱词', en: 'Retry weak words'),
              ),
            ),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
            label: Text(pickUiText(i18n, zh: '结束会话', en: 'Finish')),
          ),
        ],
      ),
    ];
  }

  Widget _buildProgressCard(
    BuildContext context,
    AppState state,
    AppI18n i18n,
    int total,
    double progress,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SectionHeader(
              title: pickUiText(i18n, zh: '练习进度', en: 'Session progress'),
              subtitle:
                  widget.subtitle ??
                  pickUiText(
                    i18n,
                    zh: '第 ${_index + 1} / $total 题',
                    en: 'Item ${_index + 1} of $total',
                  ),
            ),
            const SizedBox(height: 12),
            Semantics(
              label: pickUiText(i18n, zh: '练习进度', en: 'Session progress'),
              value: pickUiText(
                i18n,
                zh: '第 ${_index + 1} 题，共 $total 题',
                en: 'Item ${_index + 1} of $total',
              ),
              child: ExcludeSemantics(
                child: LinearProgressIndicator(value: progress),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        pickUiText(i18n, zh: '会话设置', en: 'Session settings'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pickUiText(
                          i18n,
                          zh: '题型、自动项和答题弹窗都可以在这里统一控制。',
                          en: 'Question mode, automation toggles, and answer popup behavior live here.',
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  key: const ValueKey<String>(
                    'practice-session-settings-toggle',
                  ),
                  onPressed: () {
                    setState(() {
                      _sessionSettingsExpanded = !_sessionSettingsExpanded;
                    });
                  },
                  icon: Icon(
                    _sessionSettingsExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                Chip(
                  avatar: Icon(
                    practiceQuestionTypeIcon(_questionType),
                    size: 16,
                  ),
                  label: Text(practiceQuestionTypeLabel(i18n, _questionType)),
                ),
                if (_autoAddWeakWordsToTask)
                  Chip(
                    avatar: const Icon(
                      Icons.playlist_add_check_rounded,
                      size: 16,
                    ),
                    label: Text(
                      pickUiText(i18n, zh: '自动加入任务词', en: 'Auto task sync'),
                    ),
                  ),
                if (_autoPlayPronunciation)
                  Chip(
                    avatar: const Icon(Icons.volume_up_rounded, size: 16),
                    label: Text(
                      pickUiText(i18n, zh: '自动发音', en: 'Auto pronunciation'),
                    ),
                  ),
                if (_hintRevealed)
                  Chip(
                    avatar: const Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 16,
                    ),
                    label: Text(
                      pickUiText(i18n, zh: '提示已展开', en: 'Hints open'),
                    ),
                  ),
                Chip(
                  avatar: Icon(
                    _answerFeedbackDialogEnabled
                        ? Icons.celebration_rounded
                        : Icons.notifications_off_outlined,
                    size: 16,
                  ),
                  label: Text(
                    _answerFeedbackDialogEnabled
                        ? pickUiText(i18n, zh: '答题弹窗开启', en: 'Answer popup on')
                        : pickUiText(
                            i18n,
                            zh: '答题弹窗关闭',
                            en: 'Answer popup off',
                          ),
                  ),
                ),
              ],
            ),
            if (_sessionSettingsExpanded) ...<Widget>[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _sessionAvailableQuestionTypes
                    .map(
                      (type) => ChoiceChip(
                        selected: _questionType == type,
                        avatar: Icon(practiceQuestionTypeIcon(type), size: 16),
                        label: Text(practiceQuestionTypeLabel(i18n, type)),
                        onSelected: (selected) {
                          if (!selected) {
                            return;
                          }
                          setState(() {
                            _questionType = type;
                          });
                          state.updatePracticeSessionPreferences(
                            defaultQuestionType: type,
                          );
                          _prepareCurrentQuestion();
                        },
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                key: const ValueKey<String>('practice-auto-task-switch'),
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  pickUiText(
                    i18n,
                    zh: '没记住时自动加入任务本',
                    en: 'Auto-add missed words to task list',
                  ),
                ),
                subtitle: Text(
                  pickUiText(
                    i18n,
                    zh: '开启后，点击“没记住”会自动把当前词加入任务本。',
                    en: 'When enabled, tapping "Not yet" also adds the current word to the task list.',
                  ),
                ),
                value: _autoAddWeakWordsToTask,
                onChanged: (value) {
                  setState(() {
                    _autoAddWeakWordsToTask = value;
                  });
                  state.updatePracticeSessionPreferences(
                    autoAddWeakWordsToTask: value,
                  );
                },
              ),
              SwitchListTile.adaptive(
                key: const ValueKey<String>('practice-auto-play-switch'),
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  pickUiText(
                    i18n,
                    zh: '切题时自动播放发音',
                    en: 'Auto-play pronunciation',
                  ),
                ),
                subtitle: Text(
                  pickUiText(
                    i18n,
                    zh: '每次进入新题时自动播放当前单词发音。',
                    en: 'Automatically play the current word pronunciation when a new card appears.',
                  ),
                ),
                value: _autoPlayPronunciation,
                onChanged: (value) {
                  setState(() {
                    _autoPlayPronunciation = value;
                    _lastAutoPlayedKey = null;
                  });
                  state.updatePracticeSessionPreferences(
                    autoPlayPronunciation: value,
                  );
                  if (value) {
                    _maybeAutoPlayCurrentWord(state, force: true);
                  }
                },
              ),
              SwitchListTile.adaptive(
                key: const ValueKey<String>('practice-hint-default-switch'),
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  pickUiText(i18n, zh: '新题默认展开提示', en: 'Show hints by default'),
                ),
                subtitle: Text(
                  pickUiText(
                    i18n,
                    zh: '每次切到新题时默认展开字段提示，适合复习模式。',
                    en: 'Keep field hints expanded when a new card opens, useful for review mode.',
                  ),
                ),
                value: state.practiceShowHintsByDefault,
                onChanged: (value) {
                  setState(() {
                    _hintRevealed = value;
                  });
                  state.updatePracticeSessionPreferences(
                    showHintsByDefault: value,
                  );
                },
              ),
              SwitchListTile.adaptive(
                key: const ValueKey<String>('practice-answer-feedback-switch'),
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  pickUiText(i18n, zh: '答题后弹窗反馈', en: 'Show answer popup'),
                ),
                subtitle: Text(
                  pickUiText(
                    i18n,
                    zh: '答完一题后显示鼓励弹窗，并可直接决定是否加入错题本。',
                    en: 'Show the encouraging answer popup and let you decide whether to add the word to the wrong notebook.',
                  ),
                ),
                value: _answerFeedbackDialogEnabled,
                onChanged: (value) {
                  setState(() {
                    _answerFeedbackDialogEnabled = value;
                  });
                  state.updatePracticeSessionPreferences(
                    showAnswerFeedbackDialog: value,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFlashcardQuestion(
    BuildContext context,
    AppState state,
    AppI18n i18n,
    WordEntry current,
  ) {
    final pendingFeedback = _pendingFeedbackForCurrent(current);
    return <Widget>[
      WordCard(
        word: current,
        i18n: i18n,
        density: WordCardDensity.practice,
        revealPracticeAnswer: _revealed,
        showFields: _hintRevealed,
        isFavorite: state.isFavoriteEntry(current),
        isTaskWord: state.isTaskEntry(current),
        onPlayPronunciation: () => state.previewPronunciation(current.word),
        footer: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _hintRevealed = !_hintRevealed;
                });
              },
              icon: const Icon(Icons.lightbulb_outline_rounded),
              label: Text(
                _hintRevealed
                    ? pickUiText(i18n, zh: '隐藏提示', en: 'Hide hint')
                    : pickUiText(i18n, zh: '显示提示', en: 'Show hint'),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: () {
                setState(() {
                  _revealed = !_revealed;
                });
              },
              icon: const Icon(Icons.visibility_rounded),
              label: Text(
                _revealed
                    ? pickUiText(i18n, zh: '隐藏答案', en: 'Hide answer')
                    : pickUiText(i18n, zh: '显示答案', en: 'Reveal answer'),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      _buildWeakReasonSelector(context, i18n),
      const SizedBox(height: 16),
      Row(
        children: <Widget>[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: pendingFeedback == null
                  ? () => _markResult(state, false)
                  : null,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(pickUiText(i18n, zh: '没记住', en: 'Not yet')),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: pendingFeedback == null
                  ? () => _markResult(state, true)
                  : null,
              icon: const Icon(Icons.check_rounded),
              label: Text(pickUiText(i18n, zh: '记住了', en: 'Remembered')),
            ),
          ),
        ],
      ),
      if (pendingFeedback != null) ...<Widget>[
        const SizedBox(height: 16),
        _buildInlineAnswerFeedbackCard(
          context,
          state: state,
          i18n: i18n,
          feedback: pendingFeedback,
        ),
      ],
    ];
  }

  List<Widget> _buildObjectiveQuestion(
    BuildContext context,
    AppState state,
    AppI18n i18n,
    WordEntry current,
  ) {
    final pendingFeedback = _pendingFeedbackForCurrent(current);
    return <Widget>[
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                practiceQuestionTypeLabel(i18n, _resolvedQuestionType),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _resolvedQuestionType == PracticeQuestionType.meaningChoice
                    ? pickUiText(
                        i18n,
                        zh: '根据单词选择正确词义。',
                        en: 'Choose the correct meaning for the word.',
                      )
                    : pickUiText(
                        i18n,
                        zh: '根据词义输入正确拼写。',
                        en: 'Type the correct spelling from the meaning.',
                      ),
              ),
              const SizedBox(height: 14),
              if (_resolvedQuestionType == PracticeQuestionType.meaningChoice)
                _buildMeaningChoiceBody(context, state, i18n, current)
              else
                _buildSpellingBody(context, state, i18n, current),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      if (pendingFeedback != null)
        _buildInlineAnswerFeedbackCard(
          context,
          state: state,
          i18n: i18n,
          feedback: pendingFeedback,
        )
      else if (_objectiveAnswered)
        FilledButton.icon(
          onPressed: () => _continueObjectiveQuestion(state),
          icon: Icon(
            _objectiveCorrect
                ? Icons.check_circle_rounded
                : Icons.navigate_next_rounded,
          ),
          label: Text(
            _objectiveCorrect
                ? pickUiText(i18n, zh: '继续下一题', en: 'Continue')
                : pickUiText(i18n, zh: '继续并记为薄弱', en: 'Continue as weak'),
          ),
        )
      else if (_resolvedQuestionType == PracticeQuestionType.spelling)
        FilledButton.icon(
          onPressed: _submitSpelling,
          icon: const Icon(Icons.task_alt_rounded),
          label: Text(pickUiText(i18n, zh: '提交答案', en: 'Submit')),
        ),
    ];
  }

  _PendingPracticeAnswerFeedback? _pendingFeedbackForCurrent(
    WordEntry current,
  ) {
    final pending = _pendingAnswerFeedback;
    if (pending == null || !_isSameWord(pending.current, current)) {
      return null;
    }
    return pending;
  }

  Widget _buildInlineAnswerFeedbackCard(
    BuildContext context, {
    required AppState state,
    required AppI18n i18n,
    required _PendingPracticeAnswerFeedback feedback,
  }) {
    final theme = Theme.of(context);
    final meaning = _practiceMeaningForEntry(feedback.current);
    final isLastItem = _index + 1 >= _sessionWords.length;
    final selectedReasons = feedback.weakReasonIds.toSet();

    return Semantics(
      container: true,
      child: Card(
        key: const ValueKey<String>('practice-answer-feedback-card'),
        color: theme.colorScheme.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                feedback.remembered
                    ? pickUiText(i18n, zh: '答得漂亮', en: 'Nice work')
                    : pickUiText(i18n, zh: '没关系，再来一次', en: 'Keep going'),
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                feedback.remembered
                    ? pickUiText(
                        i18n,
                        zh: '这题已经拿下了，继续保持。',
                        en: 'You have this one. Keep the momentum going.',
                      )
                    : pickUiText(
                        i18n,
                        zh: '给这次卡壳补一个原因，下一轮会更准。',
                        en: 'Tag the blocker and the next round will be more focused.',
                      ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      feedback.current.word,
                      style: theme.textTheme.titleLarge,
                    ),
                    if (meaning.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(meaning),
                    ],
                  ],
                ),
              ),
              if (!feedback.remembered) ...<Widget>[
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    pickUiText(i18n, zh: '加入错题本', en: 'Add to wrong notebook'),
                  ),
                  subtitle: Text(
                    pickUiText(
                      i18n,
                      zh: '这一轮结束前也会立刻落地到错题本和记忆轨道。',
                      en: 'This will persist to the wrong notebook and memory lanes right away.',
                    ),
                  ),
                  value: feedback.addToWrongNotebook,
                  onChanged: (value) {
                    setState(() {
                      _pendingAnswerFeedback = feedback.copyWith(
                        addToWrongNotebook: value,
                      );
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  pickUiText(i18n, zh: '没记住的主要原因', en: 'Main blocker'),
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: practiceWeakReasonIds
                      .map(
                        (reasonId) => FilterChip(
                          selected: selectedReasons.contains(reasonId),
                          avatar: Icon(
                            practiceWeakReasonIcon(reasonId),
                            size: 16,
                          ),
                          label: Text(practiceWeakReasonLabel(i18n, reasonId)),
                          onSelected: (selected) {
                            final nextReasons = Set<String>.from(
                              feedback.weakReasonIds,
                            );
                            if (selected) {
                              nextReasons.add(reasonId);
                            } else {
                              nextReasons.remove(reasonId);
                            }
                            setState(() {
                              _pendingAnswerFeedback = feedback.copyWith(
                                weakReasonIds: nextReasons.toList(
                                  growable: false,
                                ),
                              );
                            });
                          },
                        ),
                      )
                      .toList(growable: false),
                ),
                if (_autoAddWeakWordsToTask &&
                    !state.isTaskEntry(feedback.current)) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    pickUiText(
                      i18n,
                      zh: '本题还会同步加入任务词，方便稍后回捞。',
                      en: 'This word will also be added to your task list for follow-up practice.',
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _pendingAnswerFeedback = null;
                      });
                    },
                    child: Text(pickUiText(i18n, zh: '返回', en: 'Back')),
                  ),
                  FilledButton.icon(
                    onPressed: () => _commitInlineAnswerFeedback(state),
                    icon: Icon(
                      isLastItem
                          ? Icons.flag_rounded
                          : Icons.navigate_next_rounded,
                    ),
                    label: Text(
                      isLastItem
                          ? pickUiText(i18n, zh: '完成这一轮', en: 'Finish round')
                          : pickUiText(i18n, zh: '继续下一题', en: 'Next word'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeaningChoiceBody(
    BuildContext context,
    AppState state,
    AppI18n i18n,
    WordEntry current,
  ) {
    final correctMeaning = _practiceMeaningForEntry(current);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                current.word,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            IconButton.filledTonal(
              onPressed: () => state.previewPronunciation(current.word),
              icon: const Icon(Icons.volume_up_rounded),
              tooltip: pickUiText(i18n, zh: '播放发音', en: 'Play pronunciation'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ..._meaningOptions.map((option) {
          final trimmedOption = option.trim();
          final trimmedCorrectMeaning = correctMeaning.trim();
          final selected =
              _objectiveSubmittedAnswer?.trim().isNotEmpty == true &&
              _objectiveSubmittedAnswer!.trim() == trimmedOption;
          final isCorrectOption = trimmedOption == trimmedCorrectMeaning;
          final color = !_objectiveAnswered
              ? null
              : isCorrectOption
              ? Theme.of(context).colorScheme.primaryContainer
              : selected
              ? Theme.of(context).colorScheme.errorContainer
              : null;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 16,
                  ),
                ),
                onPressed: _objectiveAnswered
                    ? null
                    : () => _submitMeaningChoice(option),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(option),
                ),
              ),
            ),
          );
        }),
        if (_objectiveAnswered)
          Text(
            _objectiveCorrect
                ? pickUiText(i18n, zh: '回答正确。', en: 'Correct.')
                : pickUiText(
                    i18n,
                    zh: '回答错误。正确答案：$correctMeaning',
                    en: 'Not quite. Correct answer: $correctMeaning',
                  ),
          ),
      ],
    );
  }

  Widget _buildSpellingBody(
    BuildContext context,
    AppState state,
    AppI18n i18n,
    WordEntry current,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                _practiceMeaningForEntry(current).isEmpty
                    ? current.word
                    : _practiceMeaningForEntry(current),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton.filledTonal(
              onPressed: () => state.previewPronunciation(current.word),
              icon: const Icon(Icons.volume_up_rounded),
              tooltip: pickUiText(i18n, zh: '播放发音', en: 'Play pronunciation'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          key: const ValueKey<String>('practice-spelling-input'),
          controller: _spellingController,
          focusNode: _spellingFocusNode,
          enabled: !_objectiveAnswered,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submitSpelling(),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: pickUiText(i18n, zh: '输入拼写', en: 'Type the word'),
          ),
        ),
        if (_objectiveAnswered) ...<Widget>[
          const SizedBox(height: 12),
          Text(
            _objectiveCorrect
                ? pickUiText(i18n, zh: '拼写正确。', en: 'Correct spelling.')
                : pickUiText(
                    i18n,
                    zh: '拼写错误。正确拼写：${current.word}',
                    en: 'Not quite. Correct spelling: ${current.word}',
                  ),
          ),
        ],
      ],
    );
  }

  Widget _buildWeakReasonSelector(BuildContext context, AppI18n i18n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              pickUiText(
                i18n,
                zh: '如果没记住，主要卡在哪里？',
                en: 'If missed, what was the main blocker?',
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              pickUiText(
                i18n,
                zh: '可多选。记录后会同步到错题本和练习历史。',
                en: 'Multiple choices are allowed. Reasons sync to the wrong notebook and session history.',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: practiceWeakReasonIds
                  .map(
                    (reasonId) => FilterChip(
                      selected: _selectedWeakReasons.contains(reasonId),
                      avatar: Icon(practiceWeakReasonIcon(reasonId), size: 16),
                      label: Text(practiceWeakReasonLabel(i18n, reasonId)),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedWeakReasons.add(reasonId);
                          } else {
                            _selectedWeakReasons.remove(reasonId);
                          }
                        });
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markResult(
    AppState state,
    bool remembered, {
    List<String> weakReasonIds = const <String>[],
  }) async {
    final current = _currentWord;
    if (current == null) {
      return;
    }
    final resolvedWeakReasonIds = remembered
        ? const <String>[]
        : (weakReasonIds.isNotEmpty
              ? weakReasonIds
              : (_selectedWeakReasons.isEmpty
                    ? const <String>['recall']
                    : _selectedWeakReasons.toList(growable: false)));
    if (!_answerFeedbackDialogEnabled) {
      _applyAnswerResult(
        state,
        current: current,
        remembered: remembered,
        weakReasonIds: resolvedWeakReasonIds,
        addToWrongNotebook: !remembered,
      );
      return;
    }
    if (_usesInlineAnswerFeedback) {
      setState(() {
        _pendingAnswerFeedback = _PendingPracticeAnswerFeedback(
          current: current,
          remembered: remembered,
          addToWrongNotebook: !remembered,
          weakReasonIds: resolvedWeakReasonIds,
        );
      });
      return;
    }
    final decision = await _showAnswerFeedbackDialog(
      state,
      current: current,
      remembered: remembered,
      weakReasonIds: resolvedWeakReasonIds,
    );
    if (!mounted || decision == null) {
      return;
    }
    _applyAnswerResult(
      state,
      current: current,
      remembered: remembered,
      weakReasonIds: decision.weakReasonIds,
      addToWrongNotebook: remembered ? false : decision.addToWrongNotebook,
    );
  }

  void _applyAnswerResult(
    AppState state, {
    required WordEntry current,
    required bool remembered,
    required List<String> weakReasonIds,
    required bool addToWrongNotebook,
  }) {
    final transitionWatch = Stopwatch()..start();
    var stateWriteElapsedMs = 0;
    var prepareElapsedMs = 0;
    var nextRemembered = _remembered;
    final nextRememberedWords = List<WordEntry>.from(_rememberedWords);
    final nextWeakWords = List<WordEntry>.from(_weakWords);
    final shouldAddToTask =
        !remembered && _autoAddWeakWordsToTask && !state.isTaskEntry(current);

    if (remembered) {
      nextRemembered += 1;
      if (nextRememberedWords.every((item) => !_isSameWord(item, current))) {
        nextRememberedWords.add(current);
      }
      _weakReasonIdsByWord.remove(_reasonKey(current));
    } else {
      if (nextWeakWords.every((item) => !_isSameWord(item, current))) {
        nextWeakWords.add(current);
      }
      _weakReasonIdsByWord[_reasonKey(current)] = weakReasonIds.isNotEmpty
          ? List<String>.from(weakReasonIds, growable: false)
          : (_selectedWeakReasons.isEmpty
                ? const <String>['recall']
                : List<String>.from(_selectedWeakReasons, growable: false));
    }

    if (!_sessionStarted) {
      _sessionStarted = true;
      state.startPracticeSession(title: widget.title);
    }
    final stateWriteWatch = Stopwatch()..start();
    state.recordPracticeAnswer(
      entry: current,
      remembered: remembered,
      weakReasonIds: weakReasonIds,
      addToWrongNotebook: addToWrongNotebook,
      sessionTitle: widget.title,
    );
    stateWriteElapsedMs = stateWriteWatch.elapsedMilliseconds;

    final nextIndex = _index + 1;
    setState(() {
      _remembered = nextRemembered;
      _rememberedWords
        ..clear()
        ..addAll(nextRememberedWords);
      _weakWords
        ..clear()
        ..addAll(nextWeakWords);
      _index = nextIndex;
      _revealed = false;
      _hintRevealed = state.practiceShowHintsByDefault;
      _pendingAnswerFeedback = null;
    });

    if (shouldAddToTask) {
      _scheduleTaskWordAutoAdd(state, current);
    }

    if (nextIndex >= _sessionWords.length) {
      _reportSession(
        total: _sessionWords.length,
        remembered: nextRemembered,
        weakReasonIdsByWord: Map<String, List<String>>.from(
          _weakReasonIdsByWord,
        ),
      );
      _logAnswerTransitionIfSlow(
        current: current,
        remembered: remembered,
        totalElapsedMs: transitionWatch.elapsedMilliseconds,
        stateWriteElapsedMs: stateWriteElapsedMs,
        prepareElapsedMs: prepareElapsedMs,
      );
      return;
    }
    final prepareWatch = Stopwatch()..start();
    _prepareCurrentQuestion();
    prepareElapsedMs = prepareWatch.elapsedMilliseconds;
    _logAnswerTransitionIfSlow(
      current: current,
      remembered: remembered,
      totalElapsedMs: transitionWatch.elapsedMilliseconds,
      stateWriteElapsedMs: stateWriteElapsedMs,
      prepareElapsedMs: prepareElapsedMs,
    );
  }

  Future<void> _continueObjectiveQuestion(AppState state) async {
    if (!_objectiveAnswered) {
      return;
    }
    final weakReason = switch (_resolvedQuestionType) {
      PracticeQuestionType.meaningChoice => 'meaning',
      PracticeQuestionType.spelling => 'spelling',
      PracticeQuestionType.flashcard || PracticeQuestionType.mixed => 'recall',
    };
    await _markResult(
      state,
      _objectiveCorrect,
      weakReasonIds: _objectiveCorrect
          ? const <String>[]
          : <String>[weakReason],
    );
  }

  bool get _supportsNextBatch =>
      widget.rotationKey != null &&
      widget.rotationSourceWords != null &&
      widget.rotationBatchSize != null &&
      widget.rotationBatchSize! > 0 &&
      widget.rotationSourceWords!.isNotEmpty;

  bool get _rotationCoversWholeSource =>
      _supportsNextBatch &&
      widget.rotationBatchSize! >= widget.rotationSourceWords!.length;

  bool get _showsNewRoundPrimaryAction =>
      _rotationCoversWholeSource || (!_supportsNextBatch && widget.shuffle);

  void _restart(List<WordEntry> words, {bool shuffle = false}) {
    if (words.isEmpty) {
      return;
    }
    setState(() {
      _sessionWords = List<WordEntry>.from(words);
      if (shuffle) {
        _sessionWords.shuffle();
      }
      _rebuildSessionDerivedCaches();
      _rememberedWords.clear();
      _weakWords.clear();
      _weakReasonIdsByWord.clear();
      _index = 0;
      _remembered = 0;
      _revealed = false;
      _hintRevealed = context.read<AppState>().practiceShowHintsByDefault;
      _reported = false;
      _sessionStarted = false;
      _pendingAnswerFeedback = null;
    });
    _prepareCurrentQuestion();
  }

  void _restartFromNextBatch(AppState state) {
    if (!_supportsNextBatch) {
      _restart(widget.words, shuffle: widget.shuffle);
      return;
    }
    final nextWords = state.beginPracticeBatch(
      cursorKey: widget.rotationKey!,
      sourceWords: widget.rotationSourceWords!,
      batchSize: widget.rotationBatchSize!,
      cursorAdvance: widget.rotationCursorAdvance,
    );
    _restart(nextWords, shuffle: widget.shuffle);
  }

  void _handlePrimaryAction(AppState state) {
    if (_supportsNextBatch) {
      _restartFromNextBatch(state);
      return;
    }
    _restart(widget.words, shuffle: widget.shuffle);
  }

  IconData get _primaryActionIcon {
    if (_supportsNextBatch) {
      return _rotationCoversWholeSource
          ? Icons.autorenew_rounded
          : Icons.skip_next_rounded;
    }
    return widget.shuffle ? Icons.autorenew_rounded : Icons.replay_rounded;
  }

  String _primaryActionLabel(AppI18n i18n) {
    if (_supportsNextBatch) {
      if (_showsNewRoundPrimaryAction) {
        return pickUiText(i18n, zh: '新一轮', en: 'New round');
      }
      return pickUiText(i18n, zh: '下一批', en: 'Next batch');
    }
    if (_showsNewRoundPrimaryAction) {
      return pickUiText(i18n, zh: '新一轮', en: 'New round');
    }
    return pickUiText(i18n, zh: '再来一轮', en: 'Restart');
  }

  void _reportSession({
    required int total,
    required int remembered,
    required Map<String, List<String>> weakReasonIdsByWord,
  }) {
    if (_reported) {
      return;
    }
    _reported = true;
    context.read<AppState>().finishPracticeSession(
      title: widget.title,
      total: total,
      remembered: remembered,
      weakReasonIdsByWord: weakReasonIdsByWord,
    );
  }

  Future<_PracticeAnswerDecision?> _showAnswerFeedbackDialog(
    AppState state, {
    required WordEntry current,
    required bool remembered,
    List<String> weakReasonIds = const <String>[],
  }) {
    final i18n = AppI18n(state.uiLanguage);
    final meaning = _practiceMeaningForEntry(current);
    final isLastItem = _index + 1 >= _sessionWords.length;
    final initialReasons = weakReasonIds.isNotEmpty
        ? weakReasonIds
        : (_selectedWeakReasons.isEmpty
              ? const <String>['recall']
              : _selectedWeakReasons.toList(growable: false));
    var addToWrongNotebook = !remembered;
    final selectedReasons = Set<String>.from(initialReasons);

    return showDialog<_PracticeAnswerDecision>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(
                remembered
                    ? pickUiText(i18n, zh: '答得漂亮', en: 'Nice work')
                    : pickUiText(i18n, zh: '没关系，再来一次', en: 'Keep going'),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      remembered
                          ? pickUiText(
                              i18n,
                              zh: '这题已经拿下了，继续保持。',
                              en: 'You have this one. Keep the momentum going.',
                            )
                          : pickUiText(
                              i18n,
                              zh: '给这次卡壳补一个原因，下一轮会更准。',
                              en: 'Tag the blocker and the next round will be more focused.',
                            ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            current.word,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          if (meaning.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 4),
                            Text(meaning),
                          ],
                        ],
                      ),
                    ),
                    if (!remembered) ...<Widget>[
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          pickUiText(
                            i18n,
                            zh: '加入错题本',
                            en: 'Add to wrong notebook',
                          ),
                        ),
                        subtitle: Text(
                          pickUiText(
                            i18n,
                            zh: '这一轮结束前也会立刻落地到错题本和记忆轨道。',
                            en: 'This will persist to the wrong notebook and memory lanes right away.',
                          ),
                        ),
                        value: addToWrongNotebook,
                        onChanged: (value) {
                          setDialogState(() {
                            addToWrongNotebook = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        pickUiText(i18n, zh: '没记住的主要原因', en: 'Main blocker'),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: practiceWeakReasonIds
                            .map(
                              (reasonId) => FilterChip(
                                selected: selectedReasons.contains(reasonId),
                                avatar: Icon(
                                  practiceWeakReasonIcon(reasonId),
                                  size: 16,
                                ),
                                label: Text(
                                  practiceWeakReasonLabel(i18n, reasonId),
                                ),
                                onSelected: (selected) {
                                  setDialogState(() {
                                    if (selected) {
                                      selectedReasons.add(reasonId);
                                    } else {
                                      selectedReasons.remove(reasonId);
                                    }
                                  });
                                },
                              ),
                            )
                            .toList(growable: false),
                      ),
                      if (_autoAddWeakWordsToTask &&
                          !state.isTaskEntry(current)) ...<Widget>[
                        const SizedBox(height: 12),
                        Text(
                          pickUiText(
                            i18n,
                            zh: '本题还会同步加入任务词，方便稍后回捞。',
                            en: 'This word will also be added to your task list for follow-up practice.',
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(pickUiText(i18n, zh: '返回', en: 'Back')),
                ),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(
                      _PracticeAnswerDecision(
                        addToWrongNotebook: addToWrongNotebook,
                        weakReasonIds: remembered
                            ? const <String>[]
                            : (selectedReasons.isEmpty
                                  ? const <String>['recall']
                                  : selectedReasons.toList(growable: false)),
                      ),
                    );
                  },
                  icon: Icon(
                    isLastItem
                        ? Icons.flag_rounded
                        : Icons.navigate_next_rounded,
                  ),
                  label: Text(
                    isLastItem
                        ? pickUiText(i18n, zh: '完成这一轮', en: 'Finish round')
                        : pickUiText(i18n, zh: '继续下一题', en: 'Next word'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _prepareCurrentQuestion() {
    final current = _currentWord;
    _pendingAnswerFeedback = null;
    _selectedWeakReasons.clear();
    _objectiveAnswered = false;
    _objectiveCorrect = false;
    _objectiveSubmittedAnswer = null;
    _lastAutoPlayedKey = null;
    _spellingController.clear();
    _meaningOptions = const <String>[];
    if (current == null) {
      return;
    }
    if (_resolvedQuestionType == PracticeQuestionType.meaningChoice) {
      _meaningOptions = _buildMeaningOptions(current);
    }
    if (_resolvedQuestionType == PracticeQuestionType.spelling) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted ||
            _resolvedQuestionType != PracticeQuestionType.spelling) {
          return;
        }
        _spellingFocusNode.requestFocus();
      });
    }
    _maybeAutoPlayCurrentWord(context.read<AppState>());
  }

  List<String> _buildMeaningOptions(WordEntry current) {
    final currentMeaning = _practiceMeaningForEntry(current);
    if (currentMeaning.isEmpty) {
      return const <String>[];
    }
    final currentNormalizedMeaning = normalizePracticeAnswer(currentMeaning);
    final distractors = _sessionMeaningCandidates
        .where(
          (candidate) =>
              candidate.normalizedMeaning != currentNormalizedMeaning,
        )
        .map((candidate) => candidate.meaning)
        .toList(growable: false);
    distractors.shuffle();
    final options = <String>[currentMeaning, ...distractors.take(3)]..shuffle();
    return options;
  }

  void _submitMeaningChoice(String selectedMeaning) {
    if (_objectiveAnswered) {
      return;
    }
    final current = _currentWord;
    if (current == null) {
      return;
    }
    final isCorrect =
        selectedMeaning.trim() == _practiceMeaningForEntry(current).trim();
    setState(() {
      _objectiveAnswered = true;
      _objectiveCorrect = isCorrect;
      _objectiveSubmittedAnswer = selectedMeaning;
    });
  }

  void _submitSpelling() {
    if (_objectiveAnswered) {
      return;
    }
    final current = _currentWord;
    if (current == null) {
      return;
    }
    setState(() {
      _objectiveAnswered = true;
      _objectiveCorrect =
          normalizePracticeAnswer(_spellingController.text) ==
          normalizePracticeAnswer(current.word);
      _objectiveSubmittedAnswer = _spellingController.text.trim();
    });
  }

  void _commitInlineAnswerFeedback(AppState state) {
    final feedback = _pendingAnswerFeedback;
    if (feedback == null) {
      return;
    }
    _applyAnswerResult(
      state,
      current: feedback.current,
      remembered: feedback.remembered,
      weakReasonIds: feedback.remembered
          ? const <String>[]
          : (feedback.weakReasonIds.isEmpty
                ? const <String>['recall']
                : feedback.weakReasonIds),
      addToWrongNotebook: feedback.remembered
          ? false
          : feedback.addToWrongNotebook,
    );
  }

  void _maybeAutoPlayCurrentWord(AppState state, {bool force = false}) {
    if (!_autoPlayPronunciation) {
      return;
    }
    final current = _currentWord;
    if (current == null) {
      return;
    }
    final currentKey = '${_entryKey(current)}:$_index';
    if (!force && _lastAutoPlayedKey == currentKey) {
      return;
    }
    _lastAutoPlayedKey = currentKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _currentWord == null) {
        return;
      }
      unawaited(state.previewPronunciation(current.word));
    });
  }

  String _entryKey(WordEntry entry) => entry.stableIdentityKey;

  bool _isSameWord(WordEntry a, WordEntry b) {
    return a.sameEntryAs(b);
  }

  void _rebuildSessionDerivedCaches() {
    final nextMeaningsByEntryKey = <String, String>{};
    final nextMeaningCandidates = <_PracticeMeaningCandidate>[];
    final seenNormalizedMeanings = <String>{};

    for (final entry in _sessionWords) {
      final meaning = practiceMeaningText(entry);
      nextMeaningsByEntryKey[_entryKey(entry)] = meaning;
      final normalizedMeaning = normalizePracticeAnswer(meaning);
      if (normalizedMeaning.isEmpty ||
          !seenNormalizedMeanings.add(normalizedMeaning)) {
        continue;
      }
      nextMeaningCandidates.add(
        _PracticeMeaningCandidate(
          meaning: meaning,
          normalizedMeaning: normalizedMeaning,
        ),
      );
    }

    _sessionMeaningByEntryKey = nextMeaningsByEntryKey;
    _sessionMeaningCandidates = nextMeaningCandidates;
  }

  String _practiceMeaningForEntry(WordEntry entry) {
    return _sessionMeaningByEntryKey[_entryKey(entry)] ??
        practiceMeaningText(entry);
  }

  void _scheduleTaskWordAutoAdd(AppState state, WordEntry current) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final watch = Stopwatch()..start();
      final future = state.toggleTaskWord(current);
      unawaited(
        future
            .then((_) {
              if (watch.elapsedMilliseconds <
                  _practiceTaskWordSyncWarnThresholdMs) {
                return;
              }
              _log.w(
                'practice',
                'practice auto-add task word slow',
                data: <String, Object?>{
                  'word': current.word,
                  'elapsedMs': watch.elapsedMilliseconds,
                },
              );
            })
            .catchError((Object error, StackTrace stackTrace) {
              _log.e(
                'practice',
                'practice auto-add task word failed',
                error: error,
                stackTrace: stackTrace,
                data: <String, Object?>{'word': current.word},
              );
            }),
      );
    });
  }

  void _logAnswerTransitionIfSlow({
    required WordEntry current,
    required bool remembered,
    required int totalElapsedMs,
    required int stateWriteElapsedMs,
    required int prepareElapsedMs,
  }) {
    if (totalElapsedMs < _practiceAnswerTransitionWarnThresholdMs) {
      return;
    }
    _log.w(
      'practice',
      'practice answer transition slow',
      data: <String, Object?>{
        'word': current.word,
        'remembered': remembered,
        'questionType': _resolvedQuestionType.name,
        'elapsedMs': totalElapsedMs,
        'stateWriteElapsedMs': stateWriteElapsedMs,
        'prepareElapsedMs': prepareElapsedMs,
        'sessionIndex': _index,
        'sessionSize': _sessionWords.length,
      },
    );
  }

  String _reasonKey(WordEntry entry) => entry.stableIdentityKey;
}
