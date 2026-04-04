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
  bool _modePanelExpanded = true;
  bool _contentPanelExpanded = false;
  bool _assistPanelExpanded = false;

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

  bool get _isRunFinished =>
      _runState == _RunState.cleared ||
      _runState == _RunState.timeout ||
      _runState == _RunState.jumpEnded;

  bool get _hasCurrentRecord => _mode == SchultePlayMode.jump
      ? _bestJumpRecordByKey.containsKey(_recordKey)
      : _bestTimeMsByKey.containsKey(_recordKey);

  bool get _hasAnyRecord =>
      _bestTimeMsByKey.isNotEmpty || _bestJumpRecordByKey.isNotEmpty;

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
      _modePanelExpanded = true;
      _contentPanelExpanded = _sourceMode == SchulteSourceMode.custom;
      _assistPanelExpanded = false;
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
      if (_isRunFinished) {
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
      if (_mode == SchultePlayMode.jump) {
        _jumpScore += 1;
      }
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

  String _modeLabel(SchultePlayMode mode) => switch (mode) {
    SchultePlayMode.timer => _t('标准计时', 'Timer'),
    SchultePlayMode.countdown => _t('限时倒计时', 'Countdown'),
    SchultePlayMode.jump => _t('连续跳转', 'Jump'),
  };

  String _shapeLabel(SchulteBoardShape shape) => switch (shape) {
    SchulteBoardShape.square => _t('方形', 'Square'),
    SchulteBoardShape.triangle => _t('三角', 'Triangle'),
    SchulteBoardShape.cross => _t('十字', 'Cross'),
    SchulteBoardShape.diamond => _t('菱形', 'Diamond'),
    SchulteBoardShape.ring => _t('环形', 'Ring'),
  };

  String _sourceLabel(SchulteSourceMode sourceMode) => switch (sourceMode) {
    SchulteSourceMode.numbers => _t('数字序列', 'Number sequence'),
    SchulteSourceMode.custom => _t('自定义内容', 'Custom content'),
  };

  String _splitModeLabel(SchulteContentSplitMode splitMode) =>
      switch (splitMode) {
        SchulteContentSplitMode.character => _t('按单字符', 'Character split'),
        SchulteContentSplitMode.word => _t('按词组', 'Word split'),
      };

  String _statusTitle() {
    if (_sourceMode == SchulteSourceMode.custom && _board.sequence.isEmpty) {
      return _t('请先录入训练内容', 'Enter training content');
    }

    return switch (_runState) {
      _RunState.idle => _t('准备就绪', 'Ready'),
      _RunState.running => switch (_mode) {
        SchultePlayMode.timer => _t('正在训练', 'Training in progress'),
        SchultePlayMode.countdown => _t('限时训练进行中', 'Timed session in progress'),
        SchultePlayMode.jump => _t('连续跳转训练进行中', 'Continuous jump session'),
      },
      _RunState.cleared => _t('本轮完成', 'Round complete'),
      _RunState.timeout => _t('训练时间结束', 'Time limit reached'),
      _RunState.jumpEnded => _t('连续跳转训练结束', 'Jump session complete'),
    };
  }

  String _statusBody() {
    if (_sourceMode == SchulteSourceMode.custom && _board.sequence.isEmpty) {
      return _t(
        '请输入或粘贴自定义文本，系统将按当前拆分方式生成训练方格。',
        'Enter or paste custom text. The grid will be generated with the current split mode.',
      );
    }

    if (_runState == _RunState.cleared) {
      return _t(
        '本轮完成用时：${_formatDuration(_elapsedMs)}。',
        'Completion time: ${_formatDuration(_elapsedMs)}.',
      );
    }

    if (_runState == _RunState.timeout) {
      return _t(
        '本轮未在规定时间内完成，可重新开始后继续训练。',
        'The round was not completed within the allotted time. Restart to continue.',
      );
    }

    if (_runState == _RunState.jumpEnded) {
      return _t(
        '本次成绩：正确点击 $_jumpScore 次，完成 $_jumpBoards 盘。',
        'Session result: $_jumpScore correct taps across $_jumpBoards completed boards.',
      );
    }

    if (_nextTarget != null) {
      return _t('当前目标：$_nextTarget', 'Current target: $_nextTarget');
    }

    return switch (_mode) {
      SchultePlayMode.timer => _t(
        '点击首个正确目标后将自动开始计时，已完成的格位会立即隐藏。',
        'Timing begins on the first correct tap, and cleared cells are hidden immediately.',
      ),
      SchultePlayMode.countdown => _t(
        '点击首个正确目标后启动本轮倒计时，请在时限内完成全部目标。',
        'The countdown starts on the first correct tap. Clear all targets before time expires.',
      ),
      SchultePlayMode.jump => _t(
        '点击首个正确目标后进入连续跳转训练，请在限定时长内完成尽可能多的目标。',
        'The jump session starts on the first correct tap. Complete as many targets as possible within the time window.',
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
          '当前模式、棋盘与内容组合尚无记录。',
          'No record is available for the current mode, board, and content combination.',
        );
      }
      return _t(
        '最佳成绩：正确点击 ${record.score} 次，完成 ${record.rounds} 盘。',
        'Best result: ${record.score} correct taps across ${record.rounds} completed boards.',
      );
    }

    final best = _bestTimeMsByKey[_recordKey];
    if (best == null) {
      return _t(
        '当前模式、棋盘与内容组合尚无记录。',
        'No record is available for the current mode, board, and content combination.',
      );
    }

    return _t(
      '最佳完成用时：${_formatDuration(best)}。',
      'Best completion time: ${_formatDuration(best)}.',
    );
  }

  String _modePanelSummary() {
    final duration = switch (_mode) {
      SchultePlayMode.timer => '',
      SchultePlayMode.countdown => ' / ${_countdownSeconds}s',
      SchultePlayMode.jump => ' / ${_jumpSeconds}s',
    };
    return '${_modeLabel(_mode)} / $_resolvedBoardSize x $_resolvedBoardSize / ${_shapeLabel(_shape)}$duration';
  }

  String _contentPanelSummary(_SchulteContentStats stats) {
    if (_sourceMode == SchulteSourceMode.numbers) {
      return _t(
        '数字序列 / 共 ${_board.sequence.length} 个目标',
        'Number sequence / ${_board.sequence.length} targets',
      );
    }
    if (stats.total == 0) {
      return _t('自定义内容 / 尚未录入', 'Custom content / empty');
    }
    return _t(
      '自定义内容 / 已使用 ${stats.visible}/${stats.total} 项',
      'Custom content / ${stats.visible}/${stats.total} items in use',
    );
  }

  String _assistPanelSummary() {
    final cue = _highlightNextTarget
        ? _t('目标提示开启', 'Target cue on')
        : _t('目标提示关闭', 'Target cue off');
    return '$cue / ${_t('最佳记录', 'Best')}: ${_bestValue()}';
  }

  Widget _panel({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
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
            '录入自定义内容后，此处将生成训练方格。',
            'Enter custom content to generate the training grid.',
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
              onTap: _isRunFinished ? null : () => _tapCell(cell),
              borderRadius: BorderRadius.circular(18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: cleared
                      ? theme.colorScheme.surfaceContainerHigh.withValues(
                          alpha: 0.65,
                        )
                      : active
                      ? theme.colorScheme.secondaryContainer
                      : theme.colorScheme.surface,
                  border: Border.all(
                    color: cleared
                        ? theme.colorScheme.outlineVariant
                        : active
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.outlineVariant,
                    width: active ? 1.8 : 1,
                  ),
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 140),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: cleared
                        ? SizedBox(
                            key: ValueKey<String>(
                              'schulte-cleared-${cell.slotIndex}',
                            ),
                            width: 20,
                            height: 20,
                          )
                        : FittedBox(
                            key: ValueKey<String>(
                              'schulte-token-${cell.slotIndex}',
                            ),
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
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
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildModePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _chips<SchultePlayMode>(
          title: _t('训练模式', 'Training mode'),
          values: SchultePlayMode.values,
          selected: _mode,
          keyBuilder: (value) => Key('schulte-mode-${value.id}'),
          labelBuilder: _modeLabel,
          onSelected: (value) => _updateConfig(() => _mode = value),
        ),
        const SizedBox(height: 16),
        _chips<int>(
          title: _t('棋盘尺寸', 'Board size'),
          values: schulteBoardSizes,
          selected: _boardSize,
          keyBuilder: (value) => Key('schulte-size-$value'),
          labelBuilder: (value) => '$value x $value',
          onSelected: (value) => _updateConfig(() => _boardSize = value),
        ),
        const SizedBox(height: 16),
        _chips<SchulteBoardShape>(
          title: _t('棋盘版式', 'Board shape'),
          values: SchulteBoardShape.values,
          selected: _shape,
          keyBuilder: (value) => Key('schulte-shape-${value.id}'),
          labelBuilder: _shapeLabel,
          onSelected: (value) => _updateConfig(() => _shape = value),
        ),
        if (_mode == SchultePlayMode.countdown) ...<Widget>[
          const SizedBox(height: 16),
          _chips<int>(
            title: _t('倒计时长度', 'Countdown duration'),
            values: schulteCountdownOptions,
            selected: _countdownSeconds,
            keyBuilder: (value) => Key('schulte-countdown-$value'),
            labelBuilder: (value) => _t('$value 秒', '$value s'),
            onSelected: (value) =>
                _updateConfig(() => _countdownSeconds = value),
          ),
        ],
        if (_mode == SchultePlayMode.jump) ...<Widget>[
          const SizedBox(height: 16),
          _chips<int>(
            title: _t('训练时长', 'Jump duration'),
            values: schulteJumpOptions,
            selected: _jumpSeconds,
            keyBuilder: (value) => Key('schulte-jump-$value'),
            labelBuilder: (value) => _t('$value 秒', '$value s'),
            onSelected: (value) => _updateConfig(() => _jumpSeconds = value),
          ),
        ],
      ],
    );
  }

  Widget _buildContentPanel(_SchulteContentStats stats) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _chips<SchulteSourceMode>(
          title: _t('内容来源', 'Content source'),
          values: SchulteSourceMode.values,
          selected: _sourceMode,
          keyBuilder: (value) => Key('schulte-source-${value.id}'),
          labelBuilder: _sourceLabel,
          onSelected: (value) => _updateConfig(() {
            _sourceMode = value;
            if (value == SchulteSourceMode.custom) {
              _contentPanelExpanded = true;
            }
          }),
        ),
        const SizedBox(height: 16),
        if (_sourceMode == SchulteSourceMode.custom) ...<Widget>[
          _chips<SchulteContentSplitMode>(
            title: _t('拆分方式', 'Split mode'),
            values: SchulteContentSplitMode.values,
            selected: _splitMode,
            keyBuilder: (value) => Key('schulte-split-${value.id}'),
            labelBuilder: _splitModeLabel,
            onSelected: (value) => _updateConfig(() => _splitMode = value),
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
                '请输入句子、字符序列或词组列表；支持直接粘贴整段文本。',
                'Enter sentences, character sequences, or short word lists. Pasting full text is supported.',
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _t(
              '系统将按当前拆分方式顺序取用内容，不会以重复填充的方式补齐缺失项。',
              'Content is consumed in order with the selected split mode. Missing cells are not backfilled by repetition.',
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilterChip(
                key: const Key('schulte-strip-whitespace'),
                selected: _stripWhitespace,
                label: Text(_t('清理空白字符', 'Trim whitespace')),
                onSelected: (value) =>
                    _updateConfig(() => _stripWhitespace = value),
              ),
              FilterChip(
                key: const Key('schulte-ignore-punctuation'),
                selected: _ignorePunctuation,
                label: Text(_t('忽略标点符号', 'Ignore punctuation')),
                onSelected: (value) =>
                    _updateConfig(() => _ignorePunctuation = value),
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
                '当前内容共 ${stats.total} 项，其中唯一项 ${stats.unique} 项，重复类别 ${stats.duplicateKinds} 组。',
                'Entries ${stats.total}, unique ${stats.unique}, duplicate groups ${stats.duplicateKinds}.',
              ),
              key: const Key('schulte-content-stats'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _t(
              '本屏使用 ${stats.visible}/${stats.total} 项内容，自动生成 ${stats.boardSize} x ${stats.boardSize} 棋盘。',
              'This screen uses ${stats.visible} of ${stats.total} items and generates a ${stats.boardSize} x ${stats.boardSize} board.',
            ),
            style: theme.textTheme.bodySmall,
          ),
          if (stats.hidden > 0) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              _t(
                '为保证单格可点击性，本屏暂未显示其余 ${stats.hidden} 项内容。',
                '${stats.hidden} additional items are hidden on this screen to preserve tile tap targets.',
              ),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ] else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            child: Text(
              _t(
                '切换为自定义内容后，可使用字母、汉字、词组或短句进行顺序训练。',
                'Switch to custom content to train with letters, characters, words, or short sentences.',
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAssistPanel(String hint) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SwitchListTile(
          key: const Key('schulte-highlight-next-switch'),
          contentPadding: EdgeInsets.zero,
          value: _highlightNextTarget,
          title: Text(_t('目标高亮提示', 'Highlight next target')),
          subtitle: Text(
            _t(
              '当训练内容存在重复项时，系统将同步高亮当前顺序下所有有效目标。',
              'When duplicate content exists, all valid cells for the current step are highlighted.',
            ),
          ),
          onChanged: (value) => _toggle(() => _highlightNextTarget = value),
        ),
        if (_sourceMode == SchulteSourceMode.custom) ...<Widget>[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _showMemoryHint,
            title: Text(_t('显示记忆提示', 'Show memory hint')),
            subtitle: Text(
              _t(
                '根据当前可见内容生成简要提示，便于快速预览训练素材。',
                'Generate a compact prompt from the visible content for quick review.',
              ),
            ),
            onChanged: (value) => _toggle(() => _showMemoryHint = value),
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
                        '录入自定义内容后，此处将生成简要记忆提示。',
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
              '限时模式追加 1 秒惩罚，连续跳转模式扣减 1 分。',
              'Timed modes add a 1 second penalty, and jump mode deducts 1 point.',
            ),
          ),
          onChanged: (value) => _toggle(() => _wrongTapPenaltyEnabled = value),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _hapticsEnabled,
          title: Text(_t('触觉反馈', 'Haptics')),
          subtitle: Text(
            _t(
              '在正确或错误点击时提供轻量触觉反馈。',
              'Provide light haptic feedback for correct and incorrect taps.',
            ),
          ),
          onChanged: (value) => _toggle(() => _hapticsEnabled = value),
        ),
        const SizedBox(height: 8),
        Text(
          _t('当前最佳记录', 'Current best record'),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          child: Text(
            _bestDescription(),
            key: const Key('schulte-best-record-text'),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            OutlinedButton.icon(
              key: const Key('schulte-clear-current-record'),
              onPressed: _hasCurrentRecord ? _clearCurrentRecord : null,
              icon: const Icon(Icons.cleaning_services_outlined),
              label: Text(_t('清除当前记录', 'Clear current')),
            ),
            OutlinedButton.icon(
              key: const Key('schulte-clear-all-records'),
              onPressed: _hasAnyRecord ? _clearAllRecords : null,
              icon: const Icon(Icons.delete_sweep_outlined),
              label: Text(_t('清除全部记录', 'Clear all')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverview() {
    final theme = Theme.of(context);
    return Container(
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
            _t('舒尔特方格训练', 'Schulte Grid Training'),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _t(
              '用于训练视觉搜索、注意稳定与顺序追踪能力。',
              'Designed to train visual search, sustained attention, and sequential tracking.',
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
                label: _mode == SchultePlayMode.timer
                    ? _t('已用时间', 'Elapsed')
                    : _t('剩余时间', 'Remaining'),
                value: _mode == SchultePlayMode.timer
                    ? _formatDuration(_elapsedMs)
                    : _formatDuration(_remainingMs),
              ),
              ToolboxMetricCard(label: _t('最佳', 'Best'), value: _bestValue()),
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
    );
  }

  Widget _buildTrainingPanel() {
    final theme = Theme.of(context);
    final note =
        _sourceMode == SchulteSourceMode.custom && _board.sequence.isEmpty
        ? _t('请先录入内容以生成棋盘。', 'Enter content first to generate the grid.')
        : _t(
            '点击首个正确目标后将自动开始计时；正确点击的格位会立即隐藏。',
            'Timing begins on the first correct tap, and cleared cells are hidden immediately.',
          );

    return _panel(
      title: _t('训练面板', 'Training Board'),
      subtitle: _t(
        '用于开始新一轮、重排棋盘并完成当前训练。',
        'Use this area to start a fresh round, reshuffle the board, and complete the current session.',
      ),
      child: Column(
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
                      ? Icons.autorenew_rounded
                      : Icons.refresh_rounded,
                ),
                label: Text(
                  _runState == _RunState.idle
                      ? _t('刷新棋盘', 'Refresh board')
                      : _t('重新开始', 'Restart'),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _board.sequence.isEmpty ? null : _reshuffleBoard,
                icon: const Icon(Icons.shuffle_rounded),
                label: Text(_t('随机重排', 'Reshuffle')),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            note,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          _buildBoard(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = _contentStats();
    final hint = _memoryHint();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildOverview(),
        const SizedBox(height: 14),
        _buildTrainingPanel(),
        const SizedBox(height: 14),
        _FoldPanel(
          toggleKey: const Key('schulte-panel-mode-toggle'),
          title: _t('模式与棋盘设置', 'Mode and Board'),
          subtitle: _t(
            '配置训练模式、棋盘尺寸与版式。',
            'Configure the training mode, board size, and layout.',
          ),
          summary: _modePanelSummary(),
          expanded: _modePanelExpanded,
          onToggle: () {
            setState(() {
              _modePanelExpanded = !_modePanelExpanded;
            });
          },
          child: _buildModePanel(),
        ),
        const SizedBox(height: 14),
        _FoldPanel(
          toggleKey: const Key('schulte-panel-content-toggle'),
          title: _t('内容设置', 'Content'),
          subtitle: _t(
            '切换数字或自定义内容，并查看当前内容统计。',
            'Switch between number and custom content, and review content statistics.',
          ),
          summary: _contentPanelSummary(stats),
          expanded: _contentPanelExpanded,
          onToggle: () {
            setState(() {
              _contentPanelExpanded = !_contentPanelExpanded;
            });
          },
          child: _buildContentPanel(stats),
        ),
        const SizedBox(height: 14),
        _FoldPanel(
          toggleKey: const Key('schulte-panel-assist-toggle'),
          title: _t('辅助与记录', 'Assist and Records'),
          subtitle: _t(
            '管理提示方式、触觉反馈与当前成绩记录。',
            'Manage guidance cues, haptics, and performance records.',
          ),
          summary: _assistPanelSummary(),
          expanded: _assistPanelExpanded,
          onToggle: () {
            setState(() {
              _assistPanelExpanded = !_assistPanelExpanded;
            });
          },
          child: _buildAssistPanel(hint),
        ),
      ],
    );
  }
}

class _FoldPanel extends StatelessWidget {
  const _FoldPanel({
    required this.toggleKey,
    required this.title,
    required this.subtitle,
    required this.summary,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  final Key toggleKey;
  final String title;
  final String subtitle;
  final String summary;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          InkWell(
            key: toggleKey,
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: theme.colorScheme.surfaceContainerLow,
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: Text(
                            summary,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            child: expanded
                ? Column(
                    children: <Widget>[
                      Divider(
                        height: 1,
                        color: theme.colorScheme.outlineVariant,
                      ),
                      Padding(padding: const EdgeInsets.all(16), child: child),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
