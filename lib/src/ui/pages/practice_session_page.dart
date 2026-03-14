import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../models/word_entry.dart';
import '../../state/app_state.dart';
import '../ui_copy.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/section_header.dart';
import '../widgets/word_card.dart';

class PracticeSessionPage extends StatefulWidget {
  const PracticeSessionPage({
    super.key,
    required this.title,
    required this.words,
    this.subtitle,
    this.shuffle = false,
  });

  final String title;
  final List<WordEntry> words;
  final String? subtitle;
  final bool shuffle;

  @override
  State<PracticeSessionPage> createState() => _PracticeSessionPageState();
}

class _PracticeSessionPageState extends State<PracticeSessionPage> {
  late List<WordEntry> _sessionWords;
  final List<WordEntry> _rememberedWords = <WordEntry>[];
  final List<WordEntry> _weakWords = <WordEntry>[];
  int _index = 0;
  int _remembered = 0;
  bool _revealed = false;
  bool _hintRevealed = false;
  bool _reported = false;

  bool get _isCompleted => _index >= _sessionWords.length;

  WordEntry? get _currentWord {
    if (_sessionWords.isEmpty || _isCompleted) return null;
    return _sessionWords[_index];
  }

  @override
  void initState() {
    super.initState();
    _sessionWords = List<WordEntry>.from(widget.words);
    if (widget.shuffle) {
      _sessionWords.shuffle();
    }
  }

  void _markResult(bool remembered) {
    final current = _currentWord;
    if (current == null) return;
    var nextRemembered = _remembered;
    final nextRememberedWords = List<WordEntry>.from(_rememberedWords);
    final nextWeakWords = List<WordEntry>.from(_weakWords);
    if (remembered) {
      nextRemembered += 1;
      if (nextRememberedWords.every((item) => !_isSameWord(item, current))) {
        nextRememberedWords.add(current);
      }
    } else if (nextWeakWords.every((item) => !_isSameWord(item, current))) {
      nextWeakWords.add(current);
    }
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
      _hintRevealed = false;
    });

    if (nextIndex >= _sessionWords.length) {
      _reportSession(
        total: _sessionWords.length,
        remembered: nextRemembered,
        rememberedWords: nextRememberedWords.map((item) => item.word).toList(),
        weakWords: nextWeakWords.map((item) => item.word).toList(),
      );
    }
  }

  bool _isSameWord(WordEntry a, WordEntry b) {
    final aId = a.id;
    final bId = b.id;
    if (aId != null && bId != null) {
      return aId == bId;
    }
    return a.wordbookId == b.wordbookId && a.word == b.word;
  }

  void _restart(List<WordEntry> words, {bool shuffle = false}) {
    if (words.isEmpty) return;
    setState(() {
      _sessionWords = List<WordEntry>.from(words);
      if (shuffle) {
        _sessionWords.shuffle();
      }
      _rememberedWords.clear();
      _weakWords.clear();
      _index = 0;
      _remembered = 0;
      _revealed = false;
      _hintRevealed = false;
      _reported = false;
    });
  }

  void _reportSession({
    required int total,
    required int remembered,
    required List<String> rememberedWords,
    required List<String> weakWords,
  }) {
    if (_reported) return;
    _reported = true;
    context.read<AppState>().recordPracticeSession(
      title: widget.title,
      total: total,
      remembered: remembered,
      rememberedWords: rememberedWords,
      weakWords: weakWords,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final i18n = AppI18n(state.uiLanguage);
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

  List<Widget> _buildSession(
    BuildContext context,
    AppState state,
    AppI18n i18n,
    WordEntry current,
    int total,
    double progress,
  ) {
    return <Widget>[
      Card(
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
              LinearProgressIndicator(value: progress),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      WordCard(
        word: current,
        i18n: i18n,
        density: WordCardDensity.practice,
        revealPracticeAnswer: _revealed,
        showFields: _hintRevealed,
        isFavorite: state.favorites.contains(current.word),
        isTaskWord: state.taskWords.contains(current.word),
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
      Row(
        children: <Widget>[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _markResult(false),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(pickUiText(i18n, zh: '没记住', en: 'Not yet')),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _markResult(true),
              icon: const Icon(Icons.check_rounded),
              label: Text(pickUiText(i18n, zh: '记住了', en: 'Remembered')),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildResult(BuildContext context, AppI18n i18n) {
    final total = _sessionWords.length;
    final weakCount = _weakWords.length;
    final rememberedWords = _rememberedWords.length;
    final remembered = _remembered.clamp(0, total);
    final accuracy = total == 0 ? 0 : ((remembered / total) * 100).round();

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
              if (_rememberedWords.isNotEmpty) ...[
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
              if (_weakWords.isNotEmpty) ...[
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
            onPressed: () => _restart(widget.words, shuffle: widget.shuffle),
            icon: const Icon(Icons.replay_rounded),
            label: Text(pickUiText(i18n, zh: '再来一轮', en: 'Restart')),
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
}
