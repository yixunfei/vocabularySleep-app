import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/module_system/module_id.dart';
import '../../i18n/app_i18n.dart';
import '../../models/practice_question_type.dart';
import '../../models/word_entry.dart';
import '../../services/app_log_service.dart';
import '../../state/app_state.dart';
import '../../state/app_state_provider.dart';
import '../module/module_access.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/section_header.dart';
import '../widgets/word_card.dart';
import 'practice_support.dart';

part 'practice_session_page_models.dart';

const int _practiceAnswerTransitionWarnThresholdMs = 120;
const int _practiceTaskWordSyncWarnThresholdMs = 120;

class PracticeSessionPage extends ConsumerStatefulWidget {
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
  ConsumerState<PracticeSessionPage> createState() =>
      _PracticeSessionPageState();
}

class _PracticeSessionPageState extends ConsumerState<PracticeSessionPage> {
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
    final state = ref.read(appStateProvider);
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
    final state = ref.watch(appStateProvider);
    final i18n = AppI18n(state.uiLanguage);
    if (!state.isModuleEnabled(ModuleIds.practice)) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: ModuleDisabledView(i18n: i18n, moduleId: ModuleIds.practice),
      );
    }
    if (_sessionWords.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: EmptyStateView(
          icon: Icons.fitness_center_rounded,
          title: i18n.t(
            'inline.ui.pages.practice_session_page.no_words_to_practice_8771b7',
          ),
          message: i18n.t(
            'inline.ui.pages.practice_session_page.prepare_some_words_in_your_library_before_starting_a_ses_bb3330',
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
                title: i18n.t(
                  'inline.ui.pages.practice_session_page.session_completed_363753',
                ),
                subtitle: i18n.t(
                  'inline.ui.pages.practice_session_page.you_have_completed_this_practice_session_1c65da',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                i18n.t(
                  'inline.ui.pages.practice_session_page.accuracy_accuracy_5e2b02',
                  params: <String, Object?>{'accuracy': accuracy},
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                i18n.t(
                  'inline.ui.pages.practice_session_page.remembered_remembered_weak_weakcount_total_total_97ec42',
                  params: <String, Object?>{
                    'remembered': remembered,
                    'weakCount': weakCount,
                    'total': total,
                  },
                ),
              ),
              if (_rememberedWords.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  i18n.t(
                    'inline.ui.pages.practice_session_page.remembered_words_7a959b',
                  ),
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
                  i18n.t('inline.ui.pages.practice_page.weak_words_f19247'),
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
                  i18n.t(
                    'inline.ui.pages.practice_session_page.main_weak_reasons_4d3507',
                  ),
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
            onPressed: () => _handlePrimaryAction(ref.read(appStateProvider)),
            icon: Icon(_primaryActionIcon),
            label: Text(_primaryActionLabel(i18n)),
          ),
          if (rememberedWords > 0)
            OutlinedButton.icon(
              onPressed: () => _restart(_rememberedWords, shuffle: true),
              icon: const Icon(Icons.auto_awesome_rounded),
              label: Text(
                i18n.t(
                  'inline.ui.pages.practice_page_sections.review_remembered_a87a77',
                ),
              ),
            ),
          if (_weakWords.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () => _restart(_weakWords),
              icon: const Icon(Icons.fitness_center_rounded),
              label: Text(
                i18n.t(
                  'inline.ui.pages.practice_session_page.retry_weak_words_c930e2',
                ),
              ),
            ),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
            label: Text(
              i18n.t('inline.ui.pages.practice_session_page.finish_10bd36'),
            ),
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
              title: i18n.t(
                'inline.ui.pages.practice_session_page.session_progress_3fa31c',
              ),
              subtitle:
                  widget.subtitle ??
                  i18n.t(
                    'inline.ui.pages.practice_session_page.item_index_1_of_total_d48de9',
                    params: <String, Object?>{
                      'index': _index + 1,
                      'total': total,
                    },
                  ),
            ),
            const SizedBox(height: 12),
            Semantics(
              label: i18n.t(
                'inline.ui.pages.practice_session_page.session_progress_3fa31c',
              ),
              value: i18n.t(
                'inline.ui.pages.practice_session_page.item_index_1_of_total_d48de9',
                params: <String, Object?>{'index': _index + 1, 'total': total},
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
                        i18n.t(
                          'inline.ui.pages.practice_session_page.session_settings_35f8c2',
                        ),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        i18n.t(
                          'inline.ui.pages.practice_session_page.question_mode_automation_toggles_and_answer_popup_behavi_4a6189',
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
                      i18n.t(
                        'inline.ui.pages.practice_session_page.auto_task_sync_e022a9',
                      ),
                    ),
                  ),
                if (_autoPlayPronunciation)
                  Chip(
                    avatar: const Icon(Icons.volume_up_rounded, size: 16),
                    label: Text(
                      i18n.t(
                        'inline.ui.pages.practice_session_page.auto_pronunciation_88fe0a',
                      ),
                    ),
                  ),
                if (_hintRevealed)
                  Chip(
                    avatar: const Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 16,
                    ),
                    label: Text(
                      i18n.t(
                        'inline.ui.pages.practice_session_page.hints_open_cd49e0',
                      ),
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
                        ? i18n.t(
                            'inline.ui.pages.practice_session_page.answer_popup_on_a723da',
                          )
                        : i18n.t(
                            'inline.ui.pages.practice_session_page.answer_popup_off_3cbd34',
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
                  i18n.t(
                    'inline.ui.pages.practice_session_page.auto_add_missed_words_to_task_list_c14c46',
                  ),
                ),
                subtitle: Text(
                  i18n.t(
                    'inline.ui.pages.practice_session_page.when_enabled_tapping_not_yet_also_adds_the_current_word_19b1a7',
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
                  i18n.t(
                    'inline.ui.pages.practice_session_page.auto_play_pronunciation_753fca',
                  ),
                ),
                subtitle: Text(
                  i18n.t(
                    'inline.ui.pages.practice_session_page.automatically_play_the_current_word_pronunciation_when_a_deffde',
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
                  i18n.t(
                    'inline.ui.pages.practice_session_page.show_hints_by_default_244613',
                  ),
                ),
                subtitle: Text(
                  i18n.t(
                    'inline.ui.pages.practice_session_page.keep_field_hints_expanded_when_a_new_card_opens_useful_f_449fbd',
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
                  i18n.t(
                    'inline.ui.pages.practice_session_page.show_answer_popup_ea92f3',
                  ),
                ),
                subtitle: Text(
                  i18n.t(
                    'inline.ui.pages.practice_session_page.show_the_encouraging_answer_popup_and_let_you_decide_whe_aacd6b',
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
                    ? i18n.t(
                        'inline.ui.pages.practice_session_page.hide_hint_cb9853',
                      )
                    : i18n.t(
                        'inline.ui.pages.practice_session_page.show_hint_ce8f2a',
                      ),
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
                    ? i18n.t(
                        'inline.ui.pages.practice_session_page.hide_answer_484a2b',
                      )
                    : i18n.t(
                        'inline.ui.pages.practice_session_page.reveal_answer_1acf1b',
                      ),
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
              label: Text(
                i18n.t('inline.ui.pages.practice_session_page.not_yet_b8d1a5'),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: pendingFeedback == null
                  ? () => _markResult(state, true)
                  : null,
              icon: const Icon(Icons.check_rounded),
              label: Text(
                i18n.t(
                  'inline.ui.pages.practice_session_page.remembered_09b693',
                ),
              ),
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
                    ? i18n.t(
                        'inline.ui.pages.practice_session_page.choose_the_correct_meaning_for_the_word_ae2c33',
                      )
                    : i18n.t(
                        'inline.ui.pages.practice_session_page.type_the_correct_spelling_from_the_meaning_8184d0',
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
                ? i18n.t('toolbox.breathing.continue_select')
                : i18n.t(
                    'inline.ui.pages.practice_session_page.continue_as_weak_89da0c',
                  ),
          ),
        )
      else if (_resolvedQuestionType == PracticeQuestionType.spelling)
        FilledButton.icon(
          onPressed: _submitSpelling,
          icon: const Icon(Icons.task_alt_rounded),
          label: Text(
            i18n.t('inline.ui.pages.practice_session_page.submit_4bdd5b'),
          ),
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
                    ? i18n.t(
                        'inline.ui.pages.practice_session_page.nice_work_02e5d7',
                      )
                    : i18n.t(
                        'inline.ui.pages.practice_session_page.keep_going_0195da',
                      ),
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                feedback.remembered
                    ? i18n.t(
                        'inline.ui.pages.practice_session_page.you_have_this_one_keep_the_momentum_going_0b3817',
                      )
                    : i18n.t(
                        'inline.ui.pages.practice_session_page.tag_the_blocker_and_the_next_round_will_be_more_focused_69a2af',
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
                    i18n.t(
                      'inline.ui.pages.practice_session_page.add_to_wrong_notebook_9e04fa',
                    ),
                  ),
                  subtitle: Text(
                    i18n.t(
                      'inline.ui.pages.practice_session_page.this_will_persist_to_the_wrong_notebook_and_memory_lanes_54f971',
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
                  i18n.t(
                    'inline.ui.pages.practice_session_page.main_blocker_600ac9',
                  ),
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
                    i18n.t(
                      'inline.ui.pages.practice_session_page.this_word_will_also_be_added_to_your_task_list_for_follo_12a6c7',
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
                    child: Text(
                      i18n.t(
                        'inline.ui.pages.practice_session_page.back_1b5005',
                      ),
                    ),
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
                          ? i18n.t(
                              'inline.ui.pages.practice_session_page.finish_round_231443',
                            )
                          : i18n.t(
                              'inline.ui.pages.practice_session_page.next_word_21fddc',
                            ),
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
              tooltip: i18n.t('playPronunciation'),
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
                ? i18n.t('inline.ui.pages.practice_session_page.correct_c3dccf')
                : i18n.t(
                    'inline.ui.pages.practice_session_page.not_quite_correct_answer_correctmeaning_766850',
                    params: <String, Object?>{'correctMeaning': correctMeaning},
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
              tooltip: i18n.t('playPronunciation'),
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
            labelText: i18n.t(
              'inline.ui.pages.practice_session_page.type_the_word_48e7a0',
            ),
          ),
        ),
        if (_objectiveAnswered) ...<Widget>[
          const SizedBox(height: 12),
          Text(
            _objectiveCorrect
                ? i18n.t(
                    'inline.ui.pages.practice_session_page.correct_spelling_80e1f8',
                  )
                : i18n.t(
                    'inline.ui.pages.practice_session_page.not_quite_correct_spelling_current_word_96d345',
                    params: <String, Object?>{'word': current.word},
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
              i18n.t(
                'inline.ui.pages.practice_session_page.if_missed_what_was_the_main_blocker_9b55cd',
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              i18n.t(
                'inline.ui.pages.practice_session_page.multiple_choices_are_allowed_reasons_sync_to_the_wrong_n_b1e871',
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
      _hintRevealed = ref.read(appStateProvider).practiceShowHintsByDefault;
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
        return i18n.t('inline.ui.pages.practice_session_page.new_round_d12512');
      }
      return i18n.t('inline.ui.pages.practice_session_page.next_batch_b677f3');
    }
    if (_showsNewRoundPrimaryAction) {
      return i18n.t('inline.ui.pages.practice_session_page.new_round_d12512');
    }
    return i18n.t('inline.ui.pages.practice_session_page.restart_8b7fcc');
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
    ref
        .read(appStateProvider)
        .finishPracticeSession(
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
                    ? i18n.t(
                        'inline.ui.pages.practice_session_page.nice_work_02e5d7',
                      )
                    : i18n.t(
                        'inline.ui.pages.practice_session_page.keep_going_0195da',
                      ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      remembered
                          ? i18n.t(
                              'inline.ui.pages.practice_session_page.you_have_this_one_keep_the_momentum_going_0b3817',
                            )
                          : i18n.t(
                              'inline.ui.pages.practice_session_page.tag_the_blocker_and_the_next_round_will_be_more_focused_69a2af',
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
                          i18n.t(
                            'inline.ui.pages.practice_session_page.add_to_wrong_notebook_9e04fa',
                          ),
                        ),
                        subtitle: Text(
                          i18n.t(
                            'inline.ui.pages.practice_session_page.this_will_persist_to_the_wrong_notebook_and_memory_lanes_54f971',
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
                        i18n.t(
                          'inline.ui.pages.practice_session_page.main_blocker_600ac9',
                        ),
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
                          i18n.t(
                            'inline.ui.pages.practice_session_page.this_word_will_also_be_added_to_your_task_list_for_follo_12a6c7',
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
                  child: Text(
                    i18n.t('inline.ui.pages.practice_session_page.back_1b5005'),
                  ),
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
                        ? i18n.t(
                            'inline.ui.pages.practice_session_page.finish_round_231443',
                          )
                        : i18n.t(
                            'inline.ui.pages.practice_session_page.next_word_21fddc',
                          ),
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
    _maybeAutoPlayCurrentWord(ref.read(appStateProvider));
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
