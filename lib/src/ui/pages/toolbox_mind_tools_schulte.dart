import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../i18n/app_i18n.dart';
import '../../services/toolbox_schulte_engine.dart';
import '../../services/toolbox_schulte_prefs_service.dart';
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
    SchultePlayMode.timer => _i18n.t(
      'toolbox.mindTools.schulte.timer.25ccf87e',
    ),
    SchultePlayMode.countdown => _i18n.t(
      'toolbox.mindTools.schulte.countdown.002ef82e',
    ),
    SchultePlayMode.jump => _i18n.t('toolbox.mindTools.schulte.jump.a6efc3b2'),
  };

  String _shapeLabel(SchulteBoardShape shape) => switch (shape) {
    SchulteBoardShape.square => _i18n.t(
      'toolbox.mindTools.schulte.square.48ff8d49',
    ),
    SchulteBoardShape.triangle => _i18n.t(
      'toolbox.mindTools.schulte.triangle.c68c4760',
    ),
    SchulteBoardShape.cross => _i18n.t(
      'toolbox.mindTools.schulte.cross.1f1e4596',
    ),
    SchulteBoardShape.diamond => _i18n.t(
      'toolbox.mindTools.schulte.diamond.099db43a',
    ),
    SchulteBoardShape.ring => _i18n.t(
      'toolbox.mindTools.schulte.ring.9ed71cf8',
    ),
  };

  String _sourceLabel(SchulteSourceMode sourceMode) => switch (sourceMode) {
    SchulteSourceMode.numbers => _i18n.t(
      'toolbox.mindTools.schulte.number_sequence.f685d26f',
    ),
    SchulteSourceMode.custom => _i18n.t(
      'toolbox.mindTools.schulte.custom_content.9dd3c9c7',
    ),
  };

  String _splitModeLabel(SchulteContentSplitMode splitMode) =>
      switch (splitMode) {
        SchulteContentSplitMode.character => _i18n.t(
          'toolbox.mindTools.schulte.character_split.4a543a3e',
        ),
        SchulteContentSplitMode.word => _i18n.t(
          'toolbox.mindTools.schulte.word_split.aeae37ff',
        ),
      };

  String _statusTitle() {
    if (_sourceMode == SchulteSourceMode.custom && _board.sequence.isEmpty) {
      return _i18n.t(
        'toolbox.mindTools.schulte.enter_training_content.6a21ad2f',
      );
    }

    return switch (_runState) {
      _RunState.idle => _i18n.t('toolbox.mindTools.schulte.ready.78951216'),
      _RunState.running => switch (_mode) {
        SchultePlayMode.timer => _i18n.t(
          'toolbox.mindTools.schulte.training_in_progress.2475dcfc',
        ),
        SchultePlayMode.countdown => _i18n.t(
          'toolbox.mindTools.schulte.timed_session_in_progress.3b316f8a',
        ),
        SchultePlayMode.jump => _i18n.t(
          'toolbox.mindTools.schulte.continuous_jump_session.0c340b29',
        ),
      },
      _RunState.cleared => _i18n.t(
        'toolbox.mindTools.schulte.round_complete.5f66451a',
      ),
      _RunState.timeout => _i18n.t(
        'toolbox.mindTools.schulte.time_limit_reached.0b5e4c20',
      ),
      _RunState.jumpEnded => _i18n.t(
        'toolbox.mindTools.schulte.jump_session_complete.ab84deee',
      ),
    };
  }

  String _statusBody() {
    if (_sourceMode == SchulteSourceMode.custom && _board.sequence.isEmpty) {
      return _i18n.t(
        'toolbox.mindTools.schulte.enter_or_paste_custom_text_the_grid.e0f81386',
      );
    }

    if (_runState == _RunState.cleared) {
      return _i18n.t(
        'toolbox.mindTools.schulte.completion_time_value.892afec0',
        params: <String, Object?>{'elapsedMs': _formatDuration(_elapsedMs)},
      );
    }

    if (_runState == _RunState.timeout) {
      return _i18n.t(
        'toolbox.mindTools.schulte.the_round_was_not_completed_within_the.1937a2ca',
      );
    }

    if (_runState == _RunState.jumpEnded) {
      return _i18n.t(
        'toolbox.mindTools.schulte.session_result_value_correct_taps_across_value.13f3ac25',
        params: <String, Object?>{
          'jumpScore': _jumpScore,
          'jumpBoards': _jumpBoards,
        },
      );
    }

    if (_nextTarget != null) {
      return _i18n.t(
        'toolbox.mindTools.schulte.current_target_value.18f87cdf',
        params: <String, Object?>{'nextTarget': _nextTarget},
      );
    }

    return switch (_mode) {
      SchultePlayMode.timer => _i18n.t(
        'toolbox.mindTools.schulte.timing_begins_on_the_first_correct_tap.ffbf1fae',
      ),
      SchultePlayMode.countdown => _i18n.t(
        'toolbox.mindTools.schulte.the_countdown_starts_on_the_first_correct.52464731',
      ),
      SchultePlayMode.jump => _i18n.t(
        'toolbox.mindTools.schulte.the_jump_session_starts_on_the_first.2250b707',
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
        return _i18n.t(
          'toolbox.mindTools.schulte.no_record_is_available_for_the_current.46438f53',
        );
      }
      return _i18n.t(
        'toolbox.mindTools.schulte.best_result_value_correct_taps_across_value.ac7232e6',
        params: <String, Object?>{
          'score': record.score,
          'rounds': record.rounds,
        },
      );
    }

    final best = _bestTimeMsByKey[_recordKey];
    if (best == null) {
      return _i18n.t(
        'toolbox.mindTools.schulte.no_record_is_available_for_the_current.46438f53',
      );
    }

    return _i18n.t(
      'toolbox.mindTools.schulte.best_completion_time_value.3fdbb7fa',
      params: <String, Object?>{'best': _formatDuration(best)},
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
      return _i18n.t(
        'toolbox.mindTools.schulte.number_sequence_value_targets.cf761ec7',
        params: <String, Object?>{'sequence': _board.sequence.length},
      );
    }
    if (stats.total == 0) {
      return _i18n.t('toolbox.mindTools.schulte.custom_content_empty.8e428b33');
    }
    return _i18n.t(
      'toolbox.mindTools.schulte.custom_content_value_value_items_in_use.7d4c9d5b',
      params: <String, Object?>{'visible': stats.visible, 'total': stats.total},
    );
  }

  String _assistPanelSummary() {
    final cue = _highlightNextTarget
        ? _i18n.t('toolbox.mindTools.schulte.target_cue_on.b265fe57')
        : _i18n.t('toolbox.mindTools.schulte.target_cue_off.172f81de');
    return '$cue / ${_i18n.t('toolbox.mindTools.schulte.best.4a16ee59')}: ${_bestValue()}';
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
          _i18n.t(
            'toolbox.mindTools.schulte.enter_custom_content_to_generate_the_training.76df1021',
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
          title: _i18n.t('toolbox.mindTools.schulte.training_mode.6da89598'),
          values: SchultePlayMode.values,
          selected: _mode,
          keyBuilder: (value) => Key('schulte-mode-${value.id}'),
          labelBuilder: _modeLabel,
          onSelected: (value) => _updateConfig(() => _mode = value),
        ),
        const SizedBox(height: 16),
        _chips<int>(
          title: _i18n.t('toolbox.mindTools.schulte.board_size.56dba7e2'),
          values: schulteBoardSizes,
          selected: _boardSize,
          keyBuilder: (value) => Key('schulte-size-$value'),
          labelBuilder: (value) => '$value x $value',
          onSelected: (value) => _updateConfig(() => _boardSize = value),
        ),
        const SizedBox(height: 16),
        _chips<SchulteBoardShape>(
          title: _i18n.t('toolbox.mindTools.schulte.board_shape.adcb185e'),
          values: SchulteBoardShape.values,
          selected: _shape,
          keyBuilder: (value) => Key('schulte-shape-${value.id}'),
          labelBuilder: _shapeLabel,
          onSelected: (value) => _updateConfig(() => _shape = value),
        ),
        if (_mode == SchultePlayMode.countdown) ...<Widget>[
          const SizedBox(height: 16),
          _chips<int>(
            title: _i18n.t(
              'toolbox.mindTools.schulte.countdown_duration.3888701c',
            ),
            values: schulteCountdownOptions,
            selected: _countdownSeconds,
            keyBuilder: (value) => Key('schulte-countdown-$value'),
            labelBuilder: (value) => _i18n.t(
              'toolbox.mindTools.schulte.value_s.4ef44407',
              params: <String, Object?>{'value': value},
            ),
            onSelected: (value) =>
                _updateConfig(() => _countdownSeconds = value),
          ),
        ],
        if (_mode == SchultePlayMode.jump) ...<Widget>[
          const SizedBox(height: 16),
          _chips<int>(
            title: _i18n.t('toolbox.mindTools.schulte.jump_duration.01f34276'),
            values: schulteJumpOptions,
            selected: _jumpSeconds,
            keyBuilder: (value) => Key('schulte-jump-$value'),
            labelBuilder: (value) => _i18n.t(
              'toolbox.mindTools.schulte.value_s.4ef44407',
              params: <String, Object?>{'value': value},
            ),
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
          title: _i18n.t('toolbox.mindTools.schulte.content_source.5b6fa8e4'),
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
            title: _i18n.t('toolbox.mindTools.schulte.split_mode.444f1087'),
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
              hintText: _i18n.t(
                'toolbox.mindTools.schulte.enter_sentences_character_sequences_or_short_word.de054a95',
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _i18n.t(
              'toolbox.mindTools.schulte.content_is_consumed_in_order_with_the.aebd9ad2',
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
                label: Text(
                  _i18n.t('toolbox.mindTools.schulte.trim_whitespace.3d4c18e7'),
                ),
                onSelected: (value) =>
                    _updateConfig(() => _stripWhitespace = value),
              ),
              FilterChip(
                key: const Key('schulte-ignore-punctuation'),
                selected: _ignorePunctuation,
                label: Text(
                  _i18n.t(
                    'toolbox.mindTools.schulte.ignore_punctuation.542c2ba0',
                  ),
                ),
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
              _i18n.t(
                'toolbox.mindTools.schulte.entries_value_unique_value_duplicate_groups_value.e7285b91',
                params: <String, Object?>{
                  'total': stats.total,
                  'unique': stats.unique,
                  'duplicateKinds': stats.duplicateKinds,
                },
              ),
              key: const Key('schulte-content-stats'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _i18n.t(
              'toolbox.mindTools.schulte.this_screen_uses_value_of_value_items.a043d07f',
              params: <String, Object?>{
                'visible': stats.visible,
                'total': stats.total,
                'boardSize': stats.boardSize,
              },
            ),
            style: theme.textTheme.bodySmall,
          ),
          if (stats.hidden > 0) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              _i18n.t(
                'toolbox.mindTools.schulte.value_additional_items_are_hidden_on_this.01f27648',
                params: <String, Object?>{'hidden': stats.hidden},
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
              _i18n.t(
                'toolbox.mindTools.schulte.switch_to_custom_content_to_train_with.9b8d8608',
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
          title: Text(
            _i18n.t('toolbox.mindTools.schulte.highlight_next_target.071673e0'),
          ),
          subtitle: Text(
            _i18n.t(
              'toolbox.mindTools.schulte.when_duplicate_content_exists_all_valid_cells.02ec9af7',
            ),
          ),
          onChanged: (value) => _toggle(() => _highlightNextTarget = value),
        ),
        if (_sourceMode == SchulteSourceMode.custom) ...<Widget>[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _showMemoryHint,
            title: Text(
              _i18n.t('toolbox.mindTools.schulte.show_memory_hint.a9c9504d'),
            ),
            subtitle: Text(
              _i18n.t(
                'toolbox.mindTools.schulte.generate_a_compact_prompt_from_the_visible.459aaecb',
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
                    ? _i18n.t(
                        'toolbox.mindTools.schulte.add_custom_content_to_generate_a_memory.c25e6bdd',
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
          title: Text(
            _i18n.t('toolbox.mindTools.schulte.wrong_tap_penalty.1e560f81'),
          ),
          subtitle: Text(
            _i18n.t(
              'toolbox.mindTools.schulte.timed_modes_add_a_1_second_penalty.e300d1a8',
            ),
          ),
          onChanged: (value) => _toggle(() => _wrongTapPenaltyEnabled = value),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _hapticsEnabled,
          title: Text(_i18n.t('toolbox.mindTools.schulte.haptics.7f19ba14')),
          subtitle: Text(
            _i18n.t(
              'toolbox.mindTools.schulte.provide_light_haptic_feedback_for_correct_and.50bbb766',
            ),
          ),
          onChanged: (value) => _toggle(() => _hapticsEnabled = value),
        ),
        const SizedBox(height: 8),
        Text(
          _i18n.t('toolbox.mindTools.schulte.current_best_record.8be6e28a'),
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
              label: Text(
                _i18n.t('toolbox.mindTools.schulte.clear_current.a1706539'),
              ),
            ),
            OutlinedButton.icon(
              key: const Key('schulte-clear-all-records'),
              onPressed: _hasAnyRecord ? _clearAllRecords : null,
              icon: const Icon(Icons.delete_sweep_outlined),
              label: Text(
                _i18n.t('toolbox.mindTools.schulte.clear_all.c44d8cf4'),
              ),
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
            _i18n.t('toolbox.mindTools.schulte.schulte_grid_training.b22cd9c4'),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _i18n.t(
              'toolbox.mindTools.schulte.designed_to_train_visual_search_sustained_attention.f75a0237',
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
                label: _i18n.t('toolbox.mindTools.schulte.next.52d78e26'),
                value: _nextTarget ?? '--',
              ),
              ToolboxMetricCard(
                label: _i18n.t('toolbox.mindTools.schulte.progress.ea452572'),
                value: '$_nextIndex / ${_board.sequence.length}',
              ),
              ToolboxMetricCard(
                label: _mode == SchultePlayMode.timer
                    ? _i18n.t('toolbox.mindTools.schulte.elapsed.590f9127')
                    : _i18n.t('toolbox.mindTools.schulte.remaining.e4f802a9'),
                value: _mode == SchultePlayMode.timer
                    ? _formatDuration(_elapsedMs)
                    : _formatDuration(_remainingMs),
              ),
              ToolboxMetricCard(
                label: _i18n.t('toolbox.mindTools.schulte.best.cc3085e0'),
                value: _bestValue(),
              ),
              if (_mode == SchultePlayMode.jump)
                ToolboxMetricCard(
                  label: _i18n.t('toolbox.mindTools.schulte.score.e88e14ea'),
                  value: '$_jumpScore',
                )
              else
                ToolboxMetricCard(
                  label: _i18n.t('toolbox.mindTools.schulte.mistakes.24aa307d'),
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
        ? _i18n.t(
            'toolbox.mindTools.schulte.enter_content_first_to_generate_the_grid.05703290',
          )
        : _i18n.t(
            'toolbox.mindTools.schulte.timing_begins_on_the_first_correct_tap.e948402c',
          );

    return _panel(
      title: _i18n.t('toolbox.mindTools.schulte.training_board.e36ff4af'),
      subtitle: _i18n.t(
        'toolbox.mindTools.schulte.use_this_area_to_start_a_fresh.33d0a1c3',
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
                      ? _i18n.t(
                          'toolbox.mindTools.schulte.refresh_board.ea7e5e89',
                        )
                      : _i18n.t('toolbox.mindTools.schulte.restart.ad54dd61'),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _board.sequence.isEmpty ? null : _reshuffleBoard,
                icon: const Icon(Icons.shuffle_rounded),
                label: Text(
                  _i18n.t('toolbox.mindTools.schulte.reshuffle.e4cf2fc5'),
                ),
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
          title: _i18n.t('toolbox.mindTools.schulte.mode_and_board.c18e0392'),
          subtitle: _i18n.t(
            'toolbox.mindTools.schulte.configure_the_training_mode_board_size_and.803b8ef0',
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
          title: _i18n.t('toolbox.mindTools.schulte.content.69486526'),
          subtitle: _i18n.t(
            'toolbox.mindTools.schulte.switch_between_number_and_custom_content_and.234802cf',
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
          title: _i18n.t(
            'toolbox.mindTools.schulte.assist_and_records.9f675a0a',
          ),
          subtitle: _i18n.t(
            'toolbox.mindTools.schulte.manage_guidance_cues_haptics_and_performance_records.8aa954f0',
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
