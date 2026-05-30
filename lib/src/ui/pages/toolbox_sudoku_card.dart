import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../i18n/app_i18n.dart';
import 'toolbox_sudoku_engine.dart';
import 'toolbox_tool_shell.dart';

class SudokuGameCard extends StatefulWidget {
  const SudokuGameCard({super.key});

  @override
  State<SudokuGameCard> createState() => _SudokuGameCardState();
}

class _SudokuGameCardState extends State<SudokuGameCard> {
  SudokuVariant _variant = SudokuVariant.classic;
  SudokuDifficulty _difficulty = SudokuDifficulty.easy;
  List<int> _solution = List<int>.filled(81, 0);
  List<int> _board = List<int>.filled(81, 0);
  Set<int> _fixed = <int>{};
  List<Set<int>> _notes = List<Set<int>>.generate(81, (_) => <int>{});
  Map<int, Set<int>> _candidates = const <int, Set<int>>{};
  Set<int> _conflicts = <int>{};
  Set<int> _highlightZone = <int>{};
  Set<int> _matchingCells = <int>{};
  int? _selected;
  int? _focusedDigit;
  bool _solved = false;
  bool _generating = false;
  bool _showCandidates = false;
  bool _noteMode = false;
  bool _autoNoteBadge = false;
  bool _detailsExpanded = false;
  bool _completionDialogOpen = false;
  final TextEditingController _directInputController = TextEditingController();
  final FocusNode _directInputFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  @override
  void dispose() {
    _directInputController.dispose();
    _directInputFocusNode.dispose();
    super.dispose();
  }

  Future<void> _newGame({
    SudokuVariant? variant,
    SudokuDifficulty? difficulty,
  }) async {
    final nextVariant = variant ?? _variant;
    final nextDifficulty = difficulty ?? _difficulty;
    setState(() {
      _variant = nextVariant;
      _difficulty = nextDifficulty;
      _selected = null;
      _focusedDigit = null;
      _solved = false;
      _generating = true;
      _autoNoteBadge = false;
      _directInputController.clear();
    });
    await Future<void>.delayed(Duration.zero);
    final puzzle = generateSudokuPuzzle(
      variant: nextVariant,
      difficulty: nextDifficulty,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _solution = puzzle.solution;
      _board = puzzle.puzzle;
      _fixed = <int>{
        for (var index = 0; index < puzzle.puzzle.length; index += 1)
          if (puzzle.puzzle[index] != 0) index,
      };
      _notes = List<Set<int>>.generate(81, (_) => <int>{});
      _selected = null;
      _focusedDigit = null;
      _generating = false;
      _refreshBoardDerivedState();
    });
  }

  void _refreshBoardDerivedState() {
    _conflicts = sudokuConflicts(_board, _variant);
    _candidates = buildSudokuCandidateMap(_board, _variant);
    _solved = sudokuIsSolved(_board, _solution, _variant);
    _refreshHighlightState();
  }

  void _refreshHighlightState() {
    _highlightZone = _selected == null
        ? <int>{}
        : sudokuHighlightZone(_selected!, _variant);
    final focusedDigit = _resolvedFocusDigit();
    _matchingCells = focusedDigit == null
        ? <int>{}
        : <int>{
            for (var index = 0; index < _board.length; index += 1)
              if (_board[index] == focusedDigit) index,
          };
  }

  int? _resolvedFocusDigit() {
    final selected = _selected;
    if (selected != null && _board[selected] != 0) {
      return _board[selected];
    }
    return _focusedDigit;
  }

  bool get _canEditSelection =>
      !_generating &&
      !_solved &&
      _selected != null &&
      !_fixed.contains(_selected);

  bool _isCompactLayout(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 720;

  void _syncDirectInputFocus() {
    if (!mounted) {
      return;
    }
    _directInputController.clear();
    if (_isCompactLayout(context) && _canEditSelection) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_canEditSelection) {
          return;
        }
        _directInputFocusNode.requestFocus();
      });
      return;
    }
    _directInputFocusNode.unfocus();
  }

  void _applyCellValue(int index, int value) {
    _board[index] = value;
    _notes[index] = <int>{};
    if (value != 0) {
      for (final peer in sudokuPeerIndices(index, _variant)) {
        if (_notes[peer].contains(value)) {
          _notes[peer] = <int>{..._notes[peer]}..remove(value);
        }
      }
    }
    _refreshBoardDerivedState();
  }

  void _handleDirectInputChanged(String raw) {
    final text = raw.trim();
    if (text.isEmpty) {
      return;
    }
    _directInputController.clear();
    final value = int.tryParse(text.substring(text.length - 1));
    if (value == null) {
      return;
    }
    if (value == 0) {
      _clearSelection();
      return;
    }
    if (value >= 1 && value <= 9) {
      _handleDigitTap(value);
    }
  }

  Future<void> _showSolvedDialog() async {
    if (!mounted || _completionDialogOpen) {
      return;
    }
    _completionDialogOpen = true;
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_cognition.congratulations_ec9727',
            ),
          ),
          content: Text(
            i18n.t(
              'inline.ui.pages.toolbox_sudoku_card.you_completed_this_difficultylabel_i18n_difficulty_varia_474ffc',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(i18n.t('inline.plan295.life.close.370fb8697deb')),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _newGame();
              },
              child: Text(
                i18n.t('inline.ui.pages.toolbox_sudoku_card.new_game_2a5e2a'),
              ),
            ),
          ],
        );
      },
    );
    _completionDialogOpen = false;
  }

  void _handleSolvedBoard({bool celebrate = true}) {
    _directInputFocusNode.unfocus();
    if (!celebrate) {
      return;
    }
    unawaited(_showSolvedDialog());
  }

  void _fillHintCell() {
    if (_generating || _solved) {
      return;
    }
    final unresolved = <int>[
      for (var index = 0; index < _board.length; index += 1)
        if (!_fixed.contains(index) && _board[index] != _solution[index]) index,
    ];
    if (unresolved.isEmpty) {
      return;
    }
    final selected = _selected;
    final target =
        selected != null &&
            !_fixed.contains(selected) &&
            _board[selected] != _solution[selected]
        ? selected
        : unresolved[math.Random().nextInt(unresolved.length)];
    final row = target ~/ 9 + 1;
    final col = target % 9 + 1;
    setState(() {
      _selected = target;
      _focusedDigit = null;
      _autoNoteBadge = false;
      _applyCellValue(target, _solution[target]);
    });
    _syncDirectInputFocus();
    if (_solved) {
      _handleSolvedBoard();
      return;
    }
    if (!mounted) {
      return;
    }
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          i18n.t(
            'inline.ui.pages.toolbox_sudoku_card.revealed_the_correct_digit_for_row_row_column_col_543c10',
          ),
        ),
      ),
    );
  }

  Future<void> _showAnswer() async {
    if (_generating) {
      return;
    }
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_memory.show_answer_611b2f',
            ),
          ),
          content: Text(
            i18n.t(
              'inline.ui.pages.toolbox_sudoku_card.this_will_fill_the_full_solution_and_end_the_current_puz_79a3b3',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(i18n.t('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                i18n.t('inline.ui.pages.toolbox_sudoku_card.confirm_6250db'),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() {
      _board = List<int>.from(_solution);
      _notes = List<Set<int>>.generate(81, (_) => <int>{});
      _selected = null;
      _focusedDigit = null;
      _noteMode = false;
      _autoNoteBadge = false;
      _refreshBoardDerivedState();
    });
    _handleSolvedBoard(celebrate: false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          i18n.t(
            'inline.ui.pages.toolbox_sudoku_card.the_full_solution_is_now_visible_529686',
          ),
        ),
      ),
    );
  }

  void _selectCell(int index) {
    if (_generating) {
      return;
    }
    setState(() {
      _selected = index;
      final editableFilled = _board[index] != 0 && !_fixed.contains(index);
      if (editableFilled) {
        _noteMode = true;
        _autoNoteBadge = true;
      } else if (_board[index] == 0) {
        _autoNoteBadge = false;
      }
      if (_board[index] != 0) {
        _focusedDigit = null;
      }
      _refreshHighlightState();
    });
    _syncDirectInputFocus();
  }

  void _handleDigitTap(int value) {
    final selected = _selected;
    if (selected == null ||
        _fixed.contains(selected) ||
        _solved ||
        _generating) {
      setState(() {
        _focusedDigit = _focusedDigit == value ? null : value;
        _refreshHighlightState();
      });
      return;
    }
    if (_noteMode) {
      _toggleNote(value);
      return;
    }
    _writeValue(value);
  }

  void _toggleNote(int value) {
    final selected = _selected;
    if (selected == null ||
        _fixed.contains(selected) ||
        _solved ||
        _generating ||
        _board[selected] != 0) {
      return;
    }
    setState(() {
      final nextNotes = <int>{..._notes[selected]};
      if (!nextNotes.remove(value)) {
        nextNotes.add(value);
      }
      _notes[selected] = nextNotes;
      _focusedDigit = value;
      _refreshHighlightState();
    });
  }

  void _writeValue(int value) {
    final selected = _selected;
    if (selected == null ||
        _fixed.contains(selected) ||
        _solved ||
        _generating) {
      return;
    }
    setState(() {
      _applyCellValue(selected, value);
      if (value != 0) {
        _focusedDigit = null;
      }
    });
    if (_solved) {
      _handleSolvedBoard();
    }
  }

  void _clearSelection() {
    final selected = _selected;
    if (selected == null ||
        _fixed.contains(selected) ||
        _solved ||
        _generating) {
      return;
    }
    setState(() {
      if (_board[selected] != 0) {
        _applyCellValue(selected, 0);
      } else {
        _notes[selected] = <int>{};
        _refreshBoardDerivedState();
      }
    });
  }

  String _difficultyLabel(AppI18n i18n, SudokuDifficulty difficulty) {
    return switch (difficulty) {
      SudokuDifficulty.easy => i18n.t(
        'inline.ui.pages.toolbox_human_tests_cognition.easy_b3ae90',
      ),
      SudokuDifficulty.medium => i18n.t('appearanceWeightMedium'),
      SudokuDifficulty.hard => i18n.t(
        'inline.ui.pages.toolbox_human_tests_bimanual.hard_8e809b',
      ),
    };
  }

  String _variantLabel(AppI18n i18n, SudokuVariant variant) {
    return switch (variant) {
      SudokuVariant.classic => i18n.t(
        'inline.ui.pages.toolbox_human_tests_action.classic_3e1072',
      ),
      SudokuVariant.diagonal => i18n.t(
        'inline.ui.pages.toolbox_human_tests_dynamic_vision.diagonal_c5a023',
      ),
      SudokuVariant.hyper => i18n.t(
        'inline.ui.pages.toolbox_sudoku_card.hyper_fc7a0c',
      ),
      SudokuVariant.disjoint => i18n.t(
        'inline.ui.pages.toolbox_sudoku_card.disjoint_b9ac71',
      ),
    };
  }

  String _variantRuleText(AppI18n i18n) {
    return switch (_variant) {
      SudokuVariant.classic => i18n.t(
        'inline.ui.pages.toolbox_sudoku_card.rule_each_row_column_and_3x3_box_must_contain_1_9_e680f3',
      ),
      SudokuVariant.diagonal => i18n.t(
        'inline.ui.pages.toolbox_sudoku_card.rule_both_main_diagonals_must_also_contain_1_9_e31c20',
      ),
      SudokuVariant.hyper => i18n.t(
        'inline.ui.pages.toolbox_sudoku_card.rule_the_four_extra_inner_3x3_regions_must_also_contain_915fd2',
      ),
      SudokuVariant.disjoint => i18n.t(
        'inline.ui.pages.toolbox_sudoku_card.rule_for_each_relative_box_position_the_nine_matching_ce_2969e7',
      ),
    };
  }

  String _statusLabel(AppI18n i18n) {
    if (_generating) {
      return i18n.t('inline.ui.pages.toolbox_sudoku_card.generating_18669d');
    }
    if (_solved) {
      return i18n.t('inline.ui.pages.toolbox_sudoku_card.solved_001b7e');
    }
    if (_noteMode) {
      return i18n.t('todoNotes');
    }
    return i18n.t('toolbox.sound.focus.stagePulseMoving');
  }

  String _selectionSummary(AppI18n i18n) {
    final selected = _selected;
    if (selected == null) {
      return i18n.t(
        'inline.ui.pages.toolbox_sudoku_card.tap_any_cell_to_begin_tapping_a_filled_digit_highlights_551ca1',
      );
    }
    final row = selected ~/ 9 + 1;
    final col = selected % 9 + 1;
    final value = _board[selected];
    if (_fixed.contains(selected)) {
      return i18n.t(
        'inline.ui.pages.toolbox_sudoku_card.selected_row_row_column_col_this_is_a_given_clue_for_loc_deaf92',
      );
    }
    if (value != 0) {
      return i18n.t(
        'inline.ui.pages.toolbox_sudoku_card.selected_row_row_column_col_with_value_value_conflicts_h_16d2bd',
      );
    }
    final marks = _notes[selected].isNotEmpty
        ? _notes[selected]
        : (_candidates[selected] ?? const <int>{});
    final candidateText = marks.isEmpty ? '--' : marks.join(' ');
    return _noteMode
        ? i18n.t(
            'inline.ui.pages.toolbox_sudoku_card.selected_row_row_column_col_notes_mode_is_on_current_mar_9397ba',
          )
        : i18n.t(
            'inline.ui.pages.toolbox_sudoku_card.selected_row_row_column_col_candidate_guide_candidatetex_38001e',
          );
  }

  Color _cellBackground(ColorScheme colors, int index) {
    final row = index ~/ 9;
    final col = index % 9;
    var color = ((row ~/ 3) + (col ~/ 3)).isEven
        ? colors.surfaceContainerLowest
        : colors.surfaceContainerLow;
    if (_fixed.contains(index)) {
      color = Color.alphaBlend(
        colors.secondaryContainer.withValues(alpha: 0.52),
        color,
      );
    }
    if (_highlightZone.contains(index)) {
      color = Color.alphaBlend(
        const Color(0xFFFFF1A8).withValues(alpha: 0.72),
        color,
      );
    }
    if (_matchingCells.contains(index)) {
      color = Color.alphaBlend(
        const Color(0xFFFFB6D9).withValues(alpha: 0.66),
        color,
      );
    }
    if (_conflicts.contains(index)) {
      color = Color.alphaBlend(
        colors.errorContainer.withValues(alpha: 0.82),
        color,
      );
    }
    if (_selected == index) {
      color = Color.alphaBlend(
        const Color(0xFFFF7FB8).withValues(alpha: 0.26),
        color,
      );
    }
    return color;
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final compact = _isCompactLayout(context);
    final filled = _board.where((value) => value != 0).length;
    final colors = Theme.of(context).colorScheme;
    final summary = i18n.t(
      'inline.ui.pages.toolbox_sudoku_card.progress_filled_81_conflicts_conflicts_length_statuslabe_38fbf7',
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              i18n.t(
                                'inline.ui.pages.toolbox_sudoku_card.board_info_settings_443a1d',
                              ),
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              summary,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _detailsExpanded = !_detailsExpanded;
                          });
                        },
                        icon: Icon(
                          _detailsExpanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                        ),
                        label: Text(
                          i18n.t(
                            _detailsExpanded
                                ? 'toolbox.sudoku.details.hide'
                                : 'toolbox.sudoku.details.show',
                          ),
                        ),
                      ),
                    ],
                  ),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 180),
                    crossFadeState: _detailsExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: const SizedBox.shrink(),
                    secondChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: <Widget>[
                            ToolboxMetricCard(
                              label: i18n.t('progress'),
                              value: '$filled / 81',
                            ),
                            ToolboxMetricCard(
                              label: i18n.t(
                                'inline.ui.pages.toolbox_sudoku_card.conflicts_102401',
                              ),
                              value: '${_conflicts.length}',
                            ),
                            ToolboxMetricCard(
                              label: i18n.t(
                                'inline.ui.pages.toolbox_sudoku_card.givens_ba535b',
                              ),
                              value: '${_fixed.length}',
                            ),
                            ToolboxMetricCard(
                              label: i18n.t(
                                'inline.ui.pages.focus_page_workspace_editor.status_cc59cb',
                              ),
                              value: _statusLabel(i18n),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _variantRuleText(i18n),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: SudokuDifficulty.values
                              .map(
                                (difficulty) => ChoiceChip(
                                  label: Text(
                                    _difficultyLabel(i18n, difficulty),
                                  ),
                                  selected: _difficulty == difficulty,
                                  onSelected: _generating
                                      ? null
                                      : (_) => _newGame(difficulty: difficulty),
                                ),
                              )
                              .toList(growable: false),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: SudokuVariant.values
                              .map(
                                (variant) => ChoiceChip(
                                  label: Text(_variantLabel(i18n, variant)),
                                  selected: _variant == variant,
                                  onSelected: _generating
                                      ? null
                                      : (_) => _newGame(variant: variant),
                                ),
                              )
                              .toList(growable: false),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            FilterChip(
                              label: Text(
                                i18n.t(
                                  'inline.ui.pages.toolbox_sudoku_card.candidates_d63515',
                                ),
                              ),
                              selected: _showCandidates,
                              onSelected: (value) {
                                setState(() {
                                  _showCandidates = value;
                                });
                              },
                            ),
                            FilterChip(
                              label: Text(
                                i18n.t(
                                  'inline.ui.pages.toolbox_sudoku_card.notes_mode_349613',
                                ),
                              ),
                              selected: _noteMode,
                              onSelected: (value) {
                                setState(() {
                                  _noteMode = value;
                                  if (!value) {
                                    _autoNoteBadge = false;
                                  }
                                });
                              },
                            ),
                            if (_autoNoteBadge)
                              Chip(label: Text(i18n.t('asrLanguageAuto'))),
                            if (_generating)
                              Chip(
                                avatar: const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                label: Text(
                                  i18n.t(
                                    'inline.ui.pages.toolbox_sudoku_card.building_puzzle_5b5726',
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final boardSize = math.min(468.0, constraints.maxWidth);
                return Center(
                  child: SizedBox(
                    width: boardSize,
                    height: boardSize,
                    child: Stack(
                      children: <Widget>[
                        IgnorePointer(
                          ignoring: _generating,
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: 81,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 9,
                                ),
                            itemBuilder: (context, index) {
                              final row = index ~/ 9;
                              final col = index % 9;
                              final value = _board[index];
                              final fixed = _fixed.contains(index);
                              final conflict = _conflicts.contains(index);
                              final marks = _notes[index].isNotEmpty
                                  ? _notes[index]
                                  : (_showCandidates
                                        ? (_candidates[index] ?? const <int>{})
                                        : const <int>{});
                              return GestureDetector(
                                key: ValueKey<String>('sudoku-cell-$index'),
                                onTap: () => _selectCell(index),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 140),
                                  decoration: BoxDecoration(
                                    color: _cellBackground(colors, index),
                                    border: Border(
                                      top: BorderSide(
                                        width: row % 3 == 0 ? 2.1 : 0.72,
                                        color: colors.outlineVariant,
                                      ),
                                      left: BorderSide(
                                        width: col % 3 == 0 ? 2.1 : 0.72,
                                        color: colors.outlineVariant,
                                      ),
                                      right: BorderSide(
                                        width: col == 8 ? 2.1 : 0.72,
                                        color: colors.outlineVariant,
                                      ),
                                      bottom: BorderSide(
                                        width: row == 8 ? 2.1 : 0.72,
                                        color: colors.outlineVariant,
                                      ),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: value == 0
                                      ? _SudokuCandidateMarks(
                                          marks: marks,
                                          focusDigit: _resolvedFocusDigit(),
                                          colorScheme: colors,
                                        )
                                      : Text(
                                          '$value',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                fontWeight: fixed
                                                    ? FontWeight.w900
                                                    : FontWeight.w800,
                                                color: conflict
                                                    ? colors.onErrorContainer
                                                    : fixed
                                                    ? colors
                                                          .onSecondaryContainer
                                                    : colors.onSurface,
                                              ),
                                        ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (_generating)
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: colors.surface.withValues(alpha: 0.72),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.6,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      i18n.t(
                                        'inline.ui.pages.toolbox_sudoku_card.preparing_a_new_board_6843bc',
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Text(
                _selectionSummary(i18n),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 12),
            if (compact) ...<Widget>[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      i18n.t(
                        'inline.ui.pages.toolbox_sudoku_card.number_keypad_input_25b9bc',
                      ),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _directInputController,
                      focusNode: _directInputFocusNode,
                      enabled: _canEditSelection,
                      keyboardType: const TextInputType.numberWithOptions(),
                      textInputAction: TextInputAction.done,
                      textAlign: TextAlign.center,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(1),
                      ],
                      onChanged: _handleDirectInputChanged,
                      decoration: InputDecoration(
                        hintText: i18n.t(
                          _canEditSelection
                              ? 'toolbox.sudoku.directInput.editableHint'
                              : 'toolbox.sudoku.directInput.selectCellHint',
                        ),
                        prefixIcon: const Icon(Icons.dialpad_rounded),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      i18n.t(
                        'inline.ui.pages.toolbox_sudoku_card.on_phones_tapping_an_editable_cell_opens_the_number_keyb_6ec7f5',
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ] else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (var value = 1; value <= 9; value += 1)
                    FilledButton.tonal(
                      key: ValueKey<String>('sudoku-digit-$value'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _resolvedFocusDigit() == value
                            ? colors.primaryContainer
                            : null,
                      ),
                      onPressed: () => _handleDigitTap(value),
                      child: Text('$value'),
                    ),
                ],
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: _canEditSelection ? _clearSelection : null,
                  icon: const Icon(Icons.backspace_outlined),
                  label: Text(
                    i18n.t(
                      'inline.ui.pages.toolbox_sudoku_card.clear_cell_def0b1',
                    ),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: _generating || _solved ? null : _fillHintCell,
                  icon: const Icon(Icons.lightbulb_outline_rounded),
                  label: Text(
                    i18n.t(
                      'inline.ui.pages.toolbox_human_tests_visual.hint_972a23',
                    ),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: _generating ? null : _showAnswer,
                  icon: const Icon(Icons.visibility_rounded),
                  label: Text(
                    i18n.t(
                      'inline.ui.pages.toolbox_human_tests_memory.show_answer_611b2f',
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _newGame,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(
                    i18n.t(
                      'inline.ui.pages.toolbox_sudoku_card.new_game_2a5e2a',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SudokuCandidateMarks extends StatelessWidget {
  const _SudokuCandidateMarks({
    required this.marks,
    required this.focusDigit,
    required this.colorScheme,
  });

  final Set<int> marks;
  final int? focusDigit;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    if (marks.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Column(
        children: <Widget>[
          for (var row = 0; row < 3; row += 1)
            Expanded(
              child: Row(
                children: <Widget>[
                  for (var col = 0; col < 3; col += 1)
                    Expanded(
                      child: Center(
                        child: Builder(
                          builder: (context) {
                            final digit = row * 3 + col + 1;
                            final active = marks.contains(digit);
                            final emphasized = focusDigit == digit;
                            return Text(
                              active ? '$digit' : '',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontSize: 9.5,
                                    height: 1,
                                    fontWeight: emphasized
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: emphasized
                                        ? colorScheme.primary
                                        : colorScheme.onSurfaceVariant
                                              .withValues(alpha: 0.92),
                                  ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
