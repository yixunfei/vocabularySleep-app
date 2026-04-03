import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../i18n/app_i18n.dart';
import '../../services/toolbox_schulte_engine.dart';
import '../../services/toolbox_schulte_prefs_service.dart';
import '../ui_copy.dart';
import 'toolbox_tool_shell.dart';

class SchulteGridTrainingCard extends StatefulWidget {
  const SchulteGridTrainingCard({super.key});

  @override
  State<SchulteGridTrainingCard> createState() =>
      _SchulteGridTrainingCardState();
}

enum _RunState { idle, running, cleared, timeout, jumpEnded }

typedef _SchulteContentStats = ({
  int total,
  int visible,
  int unique,
  int duplicateKinds,
  int hidden,
  int boardSize,
});

class _SchulteGridTrainingCardState extends State<SchulteGridTrainingCard> {
  final TextEditingController _contentController = TextEditingController();
  final math.Random _random = math.Random();
  Timer? _ticker;

  bool _restoringPrefs = false;
  bool _prefsReady = false;

  int _boardSize = 5;
  SchulteBoardShape _shape = SchulteBoardShape.square;
  SchultePlayMode _mode = SchultePlayMode.timer;
  SchulteSourceMode _sourceMode = SchulteSourceMode.numbers;
  SchulteContentSplitMode _splitMode = SchulteContentSplitMode.character;
  bool _stripWhitespace = true;
  bool _ignorePunctuation = false;
  int _countdownSeconds = 45;
  int _jumpSeconds = 60;
  bool _highlightNextTarget = true;
  bool _showMemoryHint = true;
  bool _hapticsEnabled = true;
  bool _wrongTapPenaltyEnabled = false;

  Map<String, int> _bestTimeMsByKey = <String, int>{};
  Map<String, SchulteJumpBestRecord> _bestJumpRecordByKey =
      <String, SchulteJumpBestRecord>{};

  late SchulteBoardData _board;
  Set<int> _clearedSlots = <int>{};
  int _nextIndex = 0;
  int _elapsedMs = 0;
  int _remainingMs = 0;
  int _mistakes = 0;
  int _penaltyMs = 0;
  int _jumpScore = 0;
  int _jumpBoards = 0;
  _RunState _runState = _RunState.idle;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(_handleContentChanged);
    _board = _makeBoard();
    _resetSession();
    unawaited(_restorePrefs());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _contentController
      ..removeListener(_handleContentChanged)
      ..dispose();
    super.dispose();
  }

  AppI18n get _i18n => AppI18n(Localizations.localeOf(context).languageCode);
  String _t(String zh, String en) => pickUiText(_i18n, zh: zh, en: en);

  int get _sessionDurationMs => switch (_mode) {
    SchultePlayMode.timer => 0,
    SchultePlayMode.countdown => _countdownSeconds * 1000,
    SchultePlayMode.jump => _jumpSeconds * 1000,
  };

  int get _customTokenLimit => schulteVisibleCustomTokenLimit(shape: _shape);

  List<String> get _allCustomTokens => buildSchulteContentTokens(
    _contentController.text,
    splitMode: _splitMode,
    stripWhitespace: _stripWhitespace,
    ignorePunctuation: _ignorePunctuation,
  );

  List<String> get _visibleCustomTokens => buildSchulteContentTokens(
    _contentController.text,
    splitMode: _splitMode,
    stripWhitespace: _stripWhitespace,
    ignorePunctuation: _ignorePunctuation,
    maxTokens: _customTokenLimit,
  );

  int get _resolvedBoardSize => _sourceMode == SchulteSourceMode.custom
      ? resolveSchulteCustomBoardSize(
          tokenCount: _visibleCustomTokens.length,
          shape: _shape,
        )
      : _boardSize;

  int get _effectiveElapsedMs => _elapsedMs + _penaltyMs;

  String get _recordKey => buildSchulteRecordKey(
    mode: _mode,
    shape: _shape,
    size: _resolvedBoardSize,
    durationSeconds: switch (_mode) {
      SchultePlayMode.timer => 0,
      SchultePlayMode.countdown => _countdownSeconds,
      SchultePlayMode.jump => _jumpSeconds,
    },
    sourceMode: _sourceMode,
    contentSignature: buildSchulteContentSignature(
      sourceMode: _sourceMode,
      customText: _contentController.text,
      splitMode: _splitMode,
      stripWhitespace: _stripWhitespace,
      ignorePunctuation: _ignorePunctuation,
      maxTokens: _customTokenLimit,
    ),
  );

  String? get _nextTarget =>
      _nextIndex < _board.sequence.length ? _board.sequence[_nextIndex] : null;

  Future<void> _restorePrefs() async {
    final prefs = await ToolboxSchultePrefsService.load();
    if (!mounted) return;
    _restoringPrefs = true;
    _contentController.text = prefs.customText;
    setState(() {
      _boardSize = prefs.boardSize;
      _shape = SchulteBoardShape.fromId(prefs.shapeId);
      _mode = SchultePlayMode.fromId(prefs.modeId);
      _sourceMode = SchulteSourceMode.fromId(prefs.sourceModeId);
      _splitMode = SchulteContentSplitMode.fromId(prefs.contentSplitModeId);
      _stripWhitespace = prefs.stripWhitespace;
      _ignorePunctuation = prefs.ignorePunctuation;
      _countdownSeconds = prefs.countdownSeconds;
      _jumpSeconds = prefs.jumpSeconds;
      _highlightNextTarget = prefs.highlightNextTarget;
      _showMemoryHint = prefs.showMemoryHint;
      _hapticsEnabled = prefs.hapticsEnabled;
      _wrongTapPenaltyEnabled = prefs.wrongTapPenaltyEnabled;
      _bestTimeMsByKey = Map<String, int>.from(prefs.bestTimeMsByKey);
      _bestJumpRecordByKey = Map<String, SchulteJumpBestRecord>.from(
        prefs.bestJumpRecordByKey,
      );
      _board = _makeBoard();
      _resetSession();
      _prefsReady = true;
    });
    _restoringPrefs = false;
  }

  SchulteBoardData _makeBoard() {
    return buildSchulteBoard(
      size: _boardSize,
      shape: _shape,
      sourceMode: _sourceMode,
      customText: _contentController.text,
      splitMode: _splitMode,
      stripWhitespace: _stripWhitespace,
      ignorePunctuation: _ignorePunctuation,
      maxCustomTokenCount: _customTokenLimit,
      random: _random,
    );
  }

  void _persist() {
    if (!_prefsReady || _restoringPrefs) return;
    unawaited(
      ToolboxSchultePrefsService.save(
        SchulteGridPrefsState(
          boardSize: _boardSize,
          shapeId: _shape.id,
          modeId: _mode.id,
          sourceModeId: _sourceMode.id,
          customText: _contentController.text,
          contentSplitModeId: _splitMode.id,
          stripWhitespace: _stripWhitespace,
          ignorePunctuation: _ignorePunctuation,
          countdownSeconds: _countdownSeconds,
          jumpSeconds: _jumpSeconds,
          highlightNextTarget: _highlightNextTarget,
          showMemoryHint: _showMemoryHint,
          hapticsEnabled: _hapticsEnabled,
          wrongTapPenaltyEnabled: _wrongTapPenaltyEnabled,
          bestTimeMsByKey: Map<String, int>.from(_bestTimeMsByKey),
          bestJumpRecordByKey: Map<String, SchulteJumpBestRecord>.from(
            _bestJumpRecordByKey,
          ),
        ),
      ),
    );
  }

  void _resetSession() {
    _ticker?.cancel();
    _ticker = null;
    _clearedSlots = <int>{};
    _nextIndex = 0;
    _elapsedMs = 0;
    _remainingMs = _mode.isTimed ? _sessionDurationMs : 0;
    _mistakes = 0;
    _penaltyMs = 0;
    _jumpScore = 0;
    _jumpBoards = 0;
    _runState = _RunState.idle;
  }

  void _handleContentChanged() {
    if (_restoringPrefs) return;
    setState(() {
      _board = _makeBoard();
      _resetSession();
    });
    _persist();
  }

  void _updateConfig(VoidCallback change) {
    setState(() {
      change();
      _board = _makeBoard();
      _resetSession();
    });
    _persist();
  }

  void _toggle(VoidCallback change) {
    setState(change);
    _persist();
  }

  void _restartRound() {
    setState(() {
      _board = _makeBoard();
      _resetSession();
    });
  }

  void _reshuffleBoard() {
    setState(() {
      _board = _makeBoard();
      _clearedSlots = <int>{};
      _nextIndex = 0;
      if (_runState == _RunState.cleared ||
          _runState == _RunState.timeout ||
          _runState == _RunState.jumpEnded) {
        _runState = _RunState.idle;
        _elapsedMs = 0;
        _remainingMs = _mode.isTimed ? _sessionDurationMs : 0;
      }
    });
  }

  void _safeHaptic(Future<void> future) {
    if (!_hapticsEnabled) return;
    unawaited(future.catchError((_) {}));
  }

  void _startRunIfNeeded() {
    if (_runState == _RunState.running || _board.sequence.isEmpty) return;
    _runState = _RunState.running;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
  }

  void _tick() {
    if (!mounted || _runState != _RunState.running) return;
    final nextElapsed = _elapsedMs + 100;
    if (_mode == SchultePlayMode.timer) {
      setState(() => _elapsedMs = nextElapsed);
      return;
    }
    final remaining = _sessionDurationMs - (nextElapsed + _penaltyMs);
    if (remaining <= 0) {
      setState(() {
        _elapsedMs = nextElapsed;
        _remainingMs = 0;
      });
      _finishTimedRun();
      return;
    }
    setState(() {
      _elapsedMs = nextElapsed;
      _remainingMs = remaining;
    });
  }

  void _finishTimedRun() {
    _ticker?.cancel();
    _ticker = null;
    if (_mode == SchultePlayMode.jump) {
      final candidate = SchulteJumpBestRecord(
        score: _jumpScore,
        rounds: _jumpBoards,
      );
      final current = _bestJumpRecordByKey[_recordKey];
      setState(() {
        _elapsedMs = _effectiveElapsedMs;
        _remainingMs = 0;
        _runState = _RunState.jumpEnded;
        if (candidate.isBetterThan(current)) {
          _bestJumpRecordByKey = <String, SchulteJumpBestRecord>{
            ..._bestJumpRecordByKey,
            _recordKey: candidate,
          };
        }
      });
    } else {
      setState(() {
        _elapsedMs = _effectiveElapsedMs;
        _remainingMs = 0;
        _runState = _RunState.timeout;
      });
    }
    _persist();
  }

  void _recordBestTime(int milliseconds) {
    final current = _bestTimeMsByKey[_recordKey];
    if (current != null && current <= milliseconds) return;
    _bestTimeMsByKey = <String, int>{
      ..._bestTimeMsByKey,
      _recordKey: milliseconds,
    };
    _persist();
  }

  void _handleWrongTap() {
    _safeHaptic(HapticFeedback.mediumImpact());
    setState(() {
      _mistakes += 1;
      if (_wrongTapPenaltyEnabled && _runState == _RunState.running) {
        if (_mode == SchultePlayMode.jump) {
          _jumpScore = math.max(0, _jumpScore - 1);
        } else {
          _penaltyMs += 1000;
          _elapsedMs = _effectiveElapsedMs;
          _remainingMs = math.max(0, _sessionDurationMs - _elapsedMs);
        }
      }
    });
    if (_mode.isTimed && _runState == _RunState.running && _remainingMs <= 0) {
      _finishTimedRun();
    }
  }

  void _tapCell(SchulteBoardCell cell) {
    if (_clearedSlots.contains(cell.slotIndex) || _nextTarget == null) return;
    if (cell.token != _nextTarget) {
      _handleWrongTap();
      return;
    }

    setState(() {
      _startRunIfNeeded();
      _safeHaptic(HapticFeedback.selectionClick());
      _clearedSlots = <int>{..._clearedSlots, cell.slotIndex};
      _nextIndex += 1;
      if (_mode == SchultePlayMode.jump) _jumpScore += 1;
    });

    if (_nextIndex < _board.sequence.length) return;

    if (_mode == SchultePlayMode.jump) {
      setState(() {
        _jumpBoards += 1;
        _board = _makeBoard();
        _clearedSlots = <int>{};
        _nextIndex = 0;
      });
      return;
    }

    _ticker?.cancel();
    _ticker = null;
    final elapsed = _effectiveElapsedMs;
    setState(() {
      _elapsedMs = elapsed;
      if (_mode == SchultePlayMode.countdown) {
        _remainingMs = math.max(0, _sessionDurationMs - elapsed);
      }
      _runState = _RunState.cleared;
    });
    _recordBestTime(elapsed);
  }

  void _clearCurrentRecord() {
    setState(() {
      final times = Map<String, int>.from(_bestTimeMsByKey);
      final jumps = Map<String, SchulteJumpBestRecord>.from(
        _bestJumpRecordByKey,
      );
      times.remove(_recordKey);
      jumps.remove(_recordKey);
      _bestTimeMsByKey = times;
      _bestJumpRecordByKey = jumps;
    });
    _persist();
  }

  void _clearAllRecords() {
    setState(() {
      _bestTimeMsByKey = <String, int>{};
      _bestJumpRecordByKey = <String, SchulteJumpBestRecord>{};
    });
    _persist();
  }

  Set<int> _highlightedSlots() {
    if (!_highlightNextTarget || _nextTarget == null) return const <int>{};
    return _board.cells
        .where(
          (cell) =>
              !_clearedSlots.contains(cell.slotIndex) &&
              cell.token == _nextTarget,
        )
        .map((cell) => cell.slotIndex)
        .toSet();
  }

  _SchulteContentStats _contentStats() {
    final total = _allCustomTokens;
    final visible = _visibleCustomTokens;
    final effective = visible.isEmpty ? total : visible;
    final counts = <String, int>{};
    for (final token in effective) {
      counts[token] = (counts[token] ?? 0) + 1;
    }
    return (
      total: total.length,
      visible: effective.length,
      unique: counts.length,
      duplicateKinds: counts.values.where((value) => value > 1).length,
      hidden: math.max(0, total.length - effective.length),
      boardSize: _sourceMode == SchulteSourceMode.custom
          ? resolveSchulteCustomBoardSize(
              tokenCount: effective.length,
              shape: _shape,
            )
          : _boardSize,
    );
  }

  String _memoryHint() {
    final tokens = _visibleCustomTokens;
    if (tokens.isEmpty) return '';
    final chunk = _splitMode == SchulteContentSplitMode.word ? 3 : 4;
    final joiner = _splitMode == SchulteContentSplitMode.word ? ' / ' : '';
    final groups = <String>[];
    for (var i = 0; i < tokens.length && groups.length < 6; i += chunk) {
      groups.add(tokens.skip(i).take(chunk).join(joiner));
    }
    final consumed = groups.length * chunk;
    return '${groups.join('   ')}${tokens.length > consumed ? ' ...' : ''}';
  }

  String _statusTitle() {
    if (_sourceMode == SchulteSourceMode.custom && _board.sequence.isEmpty) {
      return _t('请先输入内容', 'Add content first');
    }
    return switch (_runState) {
      _RunState.idle => _t('准备开始', 'Ready'),
      _RunState.running => switch (_mode) {
        SchultePlayMode.timer => _t('继续', 'Keep going'),
        SchultePlayMode.countdown => _t('倒计时进行中', 'Countdown running'),
        SchultePlayMode.jump => _t('跳转训练进行中', 'Jump session running'),
      },
      _RunState.cleared => _t('本轮完成', 'Board cleared'),
      _RunState.timeout => _t('时间到了', 'Time is up'),
      _RunState.jumpEnded => _t('跳转训练结束', 'Jump session ended'),
    };
  }

  String _statusBody() {
    if (_sourceMode == SchulteSourceMode.custom && _board.sequence.isEmpty) {
      return _t(
        '粘贴字符、句子或词组后，就可以按顺序开始训练。',
        'Paste custom text, then train with characters or words in sequence.',
      );
    }
    if (_runState == _RunState.cleared) {
      return _t(
        '完成时间：${_formatDuration(_elapsedMs)}',
        'Finish time: ${_formatDuration(_elapsedMs)}',
      );
    }
    if (_runState == _RunState.timeout) {
      return _t('重新开始后再试一次倒计时轮次。', 'Restart to try the countdown again.');
    }
    if (_runState == _RunState.jumpEnded) {
      return _t(
        '最终成绩：$_jumpScore 次正确点击，完成 $_jumpBoards 盘。',
        'Final score: $_jumpScore correct taps across $_jumpBoards boards.',
      );
    }
    if (_nextTarget != null) {
      return _t('当前目标：$_nextTarget', 'Current target: $_nextTarget');
    }
    return switch (_mode) {
      SchultePlayMode.timer => _t(
        '点击第一个目标后自动开始计时。',
        'Tap the first target to start timing.',
      ),
      SchultePlayMode.countdown => _t(
        '点击第一个目标后启动本轮倒计时。',
        'Tap the first target to begin this countdown run.',
      ),
      SchultePlayMode.jump => _t(
        '点击第一个目标后开始限时连续训练。',
        'Tap the first target to start the jump session.',
      ),
    };
  }

  String _formatDuration(int milliseconds) {
    final safe = math.max(0, milliseconds);
    final minutes = safe ~/ 60000;
    final seconds = (safe % 60000) ~/ 1000;
    final tenths = (safe % 1000) ~/ 100;
    if (minutes > 0) {
      return '$minutes:${seconds.toString().padLeft(2, '0')}.$tenths';
    }
    return '$seconds.$tenths s';
  }

  String _bestValue() {
    if (_mode == SchultePlayMode.jump) {
      final record = _bestJumpRecordByKey[_recordKey];
      return record == null ? '--' : '${record.score}';
    }
    final best = _bestTimeMsByKey[_recordKey];
    return best == null ? '--' : _formatDuration(best);
  }

  String _bestDescription() {
    if (_mode == SchultePlayMode.jump) {
      final record = _bestJumpRecordByKey[_recordKey];
      if (record == null) {
        return _t(
          '当前模式、棋盘和内容组合还没有记录。',
          'No record yet for this mode, size, shape, and content combination.',
        );
      }
      return _t(
        '最佳成绩：${record.score} 次正确点击，完成 ${record.rounds} 盘。',
        'Best result: ${record.score} correct taps across ${record.rounds} completed boards.',
      );
    }
    final best = _bestTimeMsByKey[_recordKey];
    if (best == null) {
      return _t(
        '当前模式、棋盘和内容组合还没有记录。',
        'No record yet for this mode, size, shape, and content combination.',
      );
    }
    return _t(
      '最佳完成时间：${_formatDuration(best)}',
      'Best completion time: ${_formatDuration(best)}.',
    );
  }

  Widget _panel(String title, Widget child) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _chips<T>({
    required String title,
    required List<T> values,
    required T selected,
    required Key Function(T value) keyBuilder,
    required String Function(T value) labelBuilder,
    required ValueChanged<T> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values
              .map(
                (value) => ChoiceChip(
                  key: keyBuilder(value),
                  selected: value == selected,
                  label: Text(labelBuilder(value)),
                  onSelected: (_) => onSelected(value),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _buildBoard() {
    final theme = Theme.of(context);
    if (_board.sequence.isEmpty) {
      return Container(
        height: 340,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: theme.colorScheme.surfaceContainerLow,
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Text(
          _t(
            '输入自定义内容后，这里会生成新的方格。',
            'Add content to generate a custom Schulte board.',
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final cellBySlot = <int, SchulteBoardCell>{
      for (final cell in _board.cells) cell.slotIndex: cell,
    };
    final counts = <String, int>{};
    for (final token in _board.sequence) {
      counts[token] = (counts[token] ?? 0) + 1;
    }
    final highlighted = _highlightedSlots();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: theme.colorScheme.surfaceContainerLowest,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(14),
      child: AspectRatio(
        aspectRatio: 1,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _board.slotTokens.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _board.size,
            crossAxisSpacing: _board.size >= 8 ? 6 : 10,
            mainAxisSpacing: _board.size >= 8 ? 6 : 10,
          ),
          itemBuilder: (context, index) {
            final cell = cellBySlot[index];
            if (cell == null) {
              return DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.35,
                  ),
                ),
              );
            }

            final cleared = _clearedSlots.contains(cell.slotIndex);
            final active = highlighted.contains(cell.slotIndex);
            final key = counts[cell.token] == 1
                ? Key('schulte-cell-${cell.token}')
                : Key('schulte-cell-${cell.token}-${cell.slotIndex}');

            return InkWell(
              key: key,
              onTap:
                  _runState == _RunState.cleared ||
                      _runState == _RunState.timeout ||
                      _runState == _RunState.jumpEnded
                  ? null
                  : () => _tapCell(cell),
              borderRadius: BorderRadius.circular(18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: cleared
                      ? theme.colorScheme.primaryContainer
                      : active
                      ? theme.colorScheme.secondaryContainer
                      : theme.colorScheme.surface,
                  border: Border.all(
                    color: cleared
                        ? theme.colorScheme.primary
                        : active
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.outlineVariant,
                    width: active ? 1.8 : 1,
                  ),
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        cell.token,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = _contentStats();
    final hint = _memoryHint();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                theme.colorScheme.primaryContainer,
                theme.colorScheme.surfaceContainerHighest,
              ],
            ),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _t('舒尔特方格', 'Schulte Grid'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _t(
                  '训练视觉搜索、注意稳定和顺序跟踪。',
                  'Train visual search, steady attention, and sequence tracking.',
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _statusTitle(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(_statusBody()),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  ToolboxMetricCard(
                    label: _t('目标', 'Next'),
                    value: _nextTarget ?? '--',
                  ),
                  ToolboxMetricCard(
                    label: _t('进度', 'Progress'),
                    value: '$_nextIndex / ${_board.sequence.length}',
                  ),
                  ToolboxMetricCard(
                    label: _t('时间', 'Time'),
                    value: _mode == SchultePlayMode.timer
                        ? _formatDuration(_elapsedMs)
                        : _formatDuration(_remainingMs),
                  ),
                  ToolboxMetricCard(
                    label: _t('最佳', 'Best'),
                    value: _bestValue(),
                  ),
                  if (_mode == SchultePlayMode.jump)
                    ToolboxMetricCard(
                      label: _t('得分', 'Score'),
                      value: '$_jumpScore',
                    )
                  else
                    ToolboxMetricCard(
                      label: _t('失误', 'Mistakes'),
                      value: '$_mistakes',
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _panel(
          _t('训练面板', 'Training Board'),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: _board.sequence.isEmpty ? null : _restartRound,
                    icon: Icon(
                      _runState == _RunState.idle
                          ? Icons.play_arrow_rounded
                          : Icons.refresh_rounded,
                    ),
                    label: Text(
                      _runState == _RunState.idle
                          ? _t('开始', 'Start')
                          : _t('重新开始', 'Restart'),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _board.sequence.isEmpty ? null : _reshuffleBoard,
                    icon: const Icon(Icons.shuffle_rounded),
                    label: Text(_t('重新洗牌', 'Reshuffle')),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildBoard(),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _panel(
          _t('模式与棋盘', 'Mode and Board'),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _chips<SchultePlayMode>(
                title: _t('训练模式', 'Training mode'),
                values: SchultePlayMode.values,
                selected: _mode,
                keyBuilder: (value) => Key('schulte-mode-${value.id}'),
                labelBuilder: (value) => switch (value) {
                  SchultePlayMode.timer => _t('标准计时', 'Timer'),
                  SchultePlayMode.countdown => _t('倒计时', 'Countdown'),
                  SchultePlayMode.jump => _t('连续跳转', 'Jump'),
                },
                onSelected: (value) => _updateConfig(() => _mode = value),
              ),
              const SizedBox(height: 14),
              _chips<int>(
                title: _t('棋盘尺寸', 'Board size'),
                values: schulteBoardSizes,
                selected: _boardSize,
                keyBuilder: (value) => Key('schulte-size-$value'),
                labelBuilder: (value) => '$value x $value',
                onSelected: (value) => _updateConfig(() => _boardSize = value),
              ),
              const SizedBox(height: 14),
              _chips<SchulteBoardShape>(
                title: _t('形状', 'Shape'),
                values: SchulteBoardShape.values,
                selected: _shape,
                keyBuilder: (value) => Key('schulte-shape-${value.id}'),
                labelBuilder: (value) => switch (value) {
                  SchulteBoardShape.square => _t('方形', 'Square'),
                  SchulteBoardShape.triangle => _t('三角', 'Triangle'),
                  SchulteBoardShape.cross => _t('十字', 'Cross'),
                  SchulteBoardShape.diamond => _t('菱形', 'Diamond'),
                  SchulteBoardShape.ring => _t('环形', 'Ring'),
                },
                onSelected: (value) => _updateConfig(() => _shape = value),
              ),
              if (_mode == SchultePlayMode.countdown) ...<Widget>[
                const SizedBox(height: 14),
                _chips<int>(
                  title: _t('倒计时', 'Countdown'),
                  values: schulteCountdownOptions,
                  selected: _countdownSeconds,
                  keyBuilder: (value) => Key('schulte-countdown-$value'),
                  labelBuilder: (value) => _t('$value 秒', '$value s'),
                  onSelected: (value) =>
                      _updateConfig(() => _countdownSeconds = value),
                ),
              ],
              if (_mode == SchultePlayMode.jump) ...<Widget>[
                const SizedBox(height: 14),
                _chips<int>(
                  title: _t('单轮时长', 'Jump window'),
                  values: schulteJumpOptions,
                  selected: _jumpSeconds,
                  keyBuilder: (value) => Key('schulte-jump-$value'),
                  labelBuilder: (value) => _t('$value 秒', '$value s'),
                  onSelected: (value) =>
                      _updateConfig(() => _jumpSeconds = value),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        _panel(
          _t('内容工作台', 'Custom Content'),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _chips<SchulteSourceMode>(
                title: _t('内容来源', 'Source'),
                values: SchulteSourceMode.values,
                selected: _sourceMode,
                keyBuilder: (value) => Key('schulte-source-${value.id}'),
                labelBuilder: (value) => switch (value) {
                  SchulteSourceMode.numbers => _t('数字', 'Numbers'),
                  SchulteSourceMode.custom => _t('自定义', 'Custom'),
                },
                onSelected: (value) => _updateConfig(() => _sourceMode = value),
              ),
              const SizedBox(height: 14),
              if (_sourceMode == SchulteSourceMode.custom) ...<Widget>[
                _chips<SchulteContentSplitMode>(
                  title: _t('拆分方式', 'Split mode'),
                  values: SchulteContentSplitMode.values,
                  selected: _splitMode,
                  keyBuilder: (value) => Key('schulte-split-${value.id}'),
                  labelBuilder: (value) => switch (value) {
                    SchulteContentSplitMode.character => _t(
                      '按字符',
                      'Characters',
                    ),
                    SchulteContentSplitMode.word => _t('按词语', 'Words'),
                  },
                  onSelected: (value) =>
                      _updateConfig(() => _splitMode = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('schulte-content-input'),
                  controller: _contentController,
                  minLines: 5,
                  maxLines: 8,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: _t(
                      '输入句子、字符、短词表，或直接粘贴一段内容。',
                      'Paste a sentence, letters, characters, or a short word list.',
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    FilterChip(
                      key: const Key('schulte-strip-whitespace'),
                      selected: _stripWhitespace,
                      label: Text(_t('去掉首尾空白', 'Trim spaces')),
                      onSelected: (_) => _updateConfig(
                        () => _stripWhitespace = !_stripWhitespace,
                      ),
                    ),
                    FilterChip(
                      key: const Key('schulte-ignore-punctuation'),
                      selected: _ignorePunctuation,
                      label: Text(_t('忽略标点', 'Ignore punctuation')),
                      onSelected: (_) => _updateConfig(
                        () => _ignorePunctuation = !_ignorePunctuation,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  child: Text(
                    _t(
                      '共有 ${stats.total} 个元素，唯一值 ${stats.unique} 个，重复组 ${stats.duplicateKinds} 个。',
                      'Tokens ${stats.total}, unique ${stats.unique}, duplicate groups ${stats.duplicateKinds}.',
                    ),
                    key: const Key('schulte-content-stats'),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _t(
                    '当前屏幕使用 ${stats.visible}/${stats.total} 个元素，棋盘 ${stats.boardSize} x ${stats.boardSize}。',
                    'Using ${stats.visible} of ${stats.total} tokens on this screen. Board: ${stats.boardSize} x ${stats.boardSize}.',
                  ),
                  style: theme.textTheme.bodySmall,
                ),
                if (stats.hidden > 0) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    _t(
                      '为保证格子可点击性，额外隐藏了 ${stats.hidden} 个元素。',
                      '${stats.hidden} extra tokens are hidden on this screen to keep tiles tappable.',
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ] else
                Text(
                  _t(
                    '切换到自定义模式后，可以用文字、字母、汉字或词组训练。',
                    'Switch to custom to paste your own characters, letters, or words.',
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _panel(
          _t('辅助与记录', 'Assist and Records'),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SwitchListTile(
                key: const Key('schulte-highlight-next-switch'),
                contentPadding: EdgeInsets.zero,
                value: _highlightNextTarget,
                title: Text(_t('高亮下一目标', 'Highlight next target')),
                subtitle: Text(
                  _t(
                    '当内容重复时，会同时高亮所有符合当前顺序的格子。',
                    'All valid matching cells are highlighted in duplicate-content runs.',
                  ),
                ),
                onChanged: (_) =>
                    _toggle(() => _highlightNextTarget = !_highlightNextTarget),
              ),
              if (_sourceMode == SchulteSourceMode.custom) ...<Widget>[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _showMemoryHint,
                  title: Text(_t('显示记忆提示', 'Show memory hint')),
                  onChanged: (_) =>
                      _toggle(() => _showMemoryHint = !_showMemoryHint),
                ),
                if (_showMemoryHint) ...<Widget>[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                    child: Text(
                      hint.isEmpty
                          ? _t(
                              '输入自定义内容后，这里会生成一段短记忆提示。',
                              'Add custom content to generate a memory hint.',
                            )
                          : hint,
                      key: const Key('schulte-memory-hint'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _wrongTapPenaltyEnabled,
                title: Text(_t('错误点击惩罚', 'Wrong tap penalty')),
                subtitle: Text(
                  _t(
                    '计时模式增加 1 秒，跳转模式扣 1 分。',
                    'Adds time in timer modes and subtracts one score in jump mode.',
                  ),
                ),
                onChanged: (_) => _toggle(
                  () => _wrongTapPenaltyEnabled = !_wrongTapPenaltyEnabled,
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _hapticsEnabled,
                title: Text(_t('触感反馈', 'Haptics')),
                onChanged: (_) =>
                    _toggle(() => _hapticsEnabled = !_hapticsEnabled),
              ),
              const SizedBox(height: 8),
              Text(
                _t('当前最佳记录', 'Current Best Record'),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _bestDescription(),
                key: const Key('schulte-best-record-text'),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  OutlinedButton.icon(
                    key: const Key('schulte-clear-current-record'),
                    onPressed: _clearCurrentRecord,
                    icon: const Icon(Icons.cleaning_services_outlined),
                    label: Text(_t('清除当前', 'Clear current')),
                  ),
                  OutlinedButton.icon(
                    key: const Key('schulte-clear-all-records'),
                    onPressed: _clearAllRecords,
                    icon: const Icon(Icons.delete_sweep_outlined),
                    label: Text(_t('清除全部', 'Clear all')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
