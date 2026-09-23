part of 'toolbox_mini_games.dart';

extension _MatchThreeView on _MatchThreeGameState {
  String _reportResultLabel(AppI18n i18n, _MatchThreeStatus status) {
    return switch (status) {
      _MatchThreeStatus.won => i18n.t('toolbox.miniGames.match3.report.won'),
      _MatchThreeStatus.timeUp => i18n.t(
        'toolbox.miniGames.match3.report.time_up',
      ),
      _ => _statusLabel(i18n),
    };
  }

  Map<String, Object?> _resultReportDiagnostics(
    _MatchThreeStatus resultStatus,
  ) {
    return <String, Object?>{
      ..._boardDiagnostics(reason: 'end_report'),
      'result': resultStatus.name,
      'maxChain': _maxChain,
      'totalCleared': _totalCleared,
      'totalTimeBonus': _totalTimeBonus,
      'blockersCleared': _blockersCleared,
      'invalidSwaps': _invalidSwaps,
      'autoReshuffles': _autoReshuffles,
    };
  }

  void _showResultReportIfNeeded() {
    if (!mounted || !_gameFinished || _resultDialogOpen) {
      return;
    }
    _resultDialogOpen = true;
    final resultStatus = _status;
    _MatchThreeGameState._log.i(
      _MatchThreeGameState._logTag,
      'match3.end_report',
      data: _resultReportDiagnostics(resultStatus),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_gameFinished) {
        _resultDialogOpen = false;
        return;
      }
      final i18n = AppI18n(Localizations.localeOf(context).languageCode);
      unawaited(
        showDialog<void>(
          context: context,
          builder: (dialogContext) =>
              _buildResultDialog(dialogContext, i18n, resultStatus),
        ).whenComplete(() {
          _resultDialogOpen = false;
        }),
      );
    });
  }

  Widget _buildResultDialog(
    BuildContext dialogContext,
    AppI18n i18n,
    _MatchThreeStatus resultStatus,
  ) {
    Widget reportRow(String label, String value) {
      final theme = Theme.of(dialogContext);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: <Widget>[
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
            const SizedBox(width: 12),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    return AlertDialog(
      title: Text(i18n.t('toolbox.miniGames.match3.report.title')),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            reportRow(
              i18n.t('toolbox.miniGames.match3.report.result'),
              _reportResultLabel(i18n, resultStatus),
            ),
            reportRow(
              i18n.t('toolbox.miniGames.match3.report.score'),
              '$_score',
            ),
            reportRow(
              i18n.t('toolbox.miniGames.match3.report.target'),
              '${_MatchThreeGameState._targetScore}',
            ),
            reportRow(
              i18n.t('toolbox.miniGames.match3.report.moves'),
              '$_moves',
            ),
            reportRow(
              i18n.t('toolbox.miniGames.match3.report.max_chain'),
              '${_maxChain}x',
            ),
            reportRow(
              i18n.t('toolbox.miniGames.match3.report.cleared'),
              '$_totalCleared',
            ),
            reportRow(
              i18n.t('toolbox.miniGames.match3.report.time_bonus_seconds'),
              '$_totalTimeBonus',
            ),
            reportRow(
              i18n.t('toolbox.miniGames.match3.report.blockers_cleared'),
              '$_blockersCleared',
            ),
            reportRow(
              i18n.t('toolbox.miniGames.match3.report.invalid_swaps'),
              '$_invalidSwaps',
            ),
            reportRow(
              i18n.t('toolbox.miniGames.match3.report.auto_reshuffles'),
              '$_autoReshuffles',
            ),
            reportRow(
              i18n.t('toolbox.miniGames.match3.report.remaining_time'),
              _formatTime(_remainingSeconds),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(i18n.t('close')),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            _newGame();
          },
          child: Text(i18n.t('toolbox.miniGames.match3.action.new')),
        ),
      ],
    );
  }

  String _statusLabel(AppI18n i18n) {
    return switch (_status) {
      _MatchThreeStatus.ready => i18n.t(
        'toolbox.miniGames.match3.status.ready',
      ),
      _MatchThreeStatus.selected => i18n.t(
        'toolbox.miniGames.match3.status.selected',
      ),
      _MatchThreeStatus.invalid => i18n.t(
        'toolbox.miniGames.match3.status.invalid',
      ),
      _MatchThreeStatus.clearing => i18n.t(
        'toolbox.miniGames.match3.status.clearing',
        params: <String, Object?>{
          'count': _lastCleared,
          'chain': _chain,
          'seconds': _lastTimeBonus,
        },
      ),
      _MatchThreeStatus.reshuffled => i18n.t(
        'toolbox.miniGames.match3.status.reshuffled',
      ),
      _MatchThreeStatus.won => i18n.t('toolbox.miniGames.match3.status.won'),
      _MatchThreeStatus.timeUp => i18n.t(
        'toolbox.miniGames.match3.status.time_up',
      ),
    };
  }

  String _powerLabel(AppI18n i18n, _MatchThreePower power) {
    return switch (power) {
      _MatchThreePower.row => i18n.t('toolbox.miniGames.match3.power.row'),
      _MatchThreePower.column => i18n.t(
        'toolbox.miniGames.match3.power.column',
      ),
      _MatchThreePower.bomb => i18n.t('toolbox.miniGames.match3.power.bomb'),
      _MatchThreePower.rainbow => i18n.t(
        'toolbox.miniGames.match3.power.rainbow',
      ),
      _MatchThreePower.none => '',
    };
  }

  IconData _powerIcon(_MatchThreePower power) {
    return switch (power) {
      _MatchThreePower.row => Icons.swap_horiz_rounded,
      _MatchThreePower.column => Icons.swap_vert_rounded,
      _MatchThreePower.bomb => Icons.blur_circular_rounded,
      _MatchThreePower.rainbow => Icons.auto_awesome_rounded,
      _MatchThreePower.none => Icons.circle_outlined,
    };
  }

  String _blockerLabel(AppI18n i18n) {
    return i18n.t('toolbox.miniGames.match3.obstacle.blocker');
  }

  Widget _buildPowerLegend(BuildContext context, AppI18n i18n) {
    final colors = Theme.of(context).colorScheme;
    Widget legendChip({
      required IconData icon,
      required String label,
      required Color iconColor,
    }) {
      return Tooltip(
        message: label,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(label, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final power in _matchThreeLegendPowers)
          legendChip(
            icon: _powerIcon(power),
            label: _powerLabel(i18n, power),
            iconColor: colors.primary,
          ),
        legendChip(
          icon: Icons.block_rounded,
          label: _blockerLabel(i18n),
          iconColor: colors.error,
        ),
      ],
    );
  }

  Widget _buildTileFace(int value, double cellSize) {
    final kind = _kindOf(value);
    final power = _powerOf(value);
    final baseIcon = Icon(
      _matchThreeIcons[kind],
      size: power == _MatchThreePower.none ? cellSize * 0.42 : cellSize * 0.34,
      color: Colors.white.withValues(
        alpha: power == _MatchThreePower.none ? 1 : 0.5,
      ),
    );
    if (power == _MatchThreePower.none) {
      return baseIcon;
    }
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        baseIcon,
        Container(
          width: cellSize * 0.58,
          height: cellSize * 0.58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
          ),
          child: Icon(
            _powerIcon(power),
            size: cellSize * 0.34,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildBlockerFace(BuildContext context, double cellSize) {
    final colors = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Icon(
          Icons.grid_4x4_rounded,
          size: cellSize * 0.48,
          color: colors.onSurfaceVariant.withValues(alpha: 0.42),
        ),
        Icon(
          Icons.block_rounded,
          size: cellSize * 0.34,
          color: colors.error.withValues(alpha: 0.92),
        ),
      ],
    );
  }

  Widget _buildBoardCell(BuildContext context, int index, double cellSize) {
    final colors = Theme.of(context).colorScheme;

    final value = _tiles[index];
    final selected = _selected == index;
    final kind = _kindOf(value);
    final power = _powerOf(value);
    final blocker = value == _MatchThreeGameState._blockerTile;
    final clearing = _clearingTiles.contains(index);
    final specialClearing = clearing && power != _MatchThreePower.none;
    final color = value >= 0
        ? _matchThreeColors[kind]
        : blocker
        ? colors.surfaceContainerHighest
        : colors.surfaceContainerLowest;
    final rainbow = power == _MatchThreePower.rainbow;
    return GestureDetector(
      onTap: () => _handleTileTap(index),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        scale: specialClearing
            ? 1.12
            : clearing
            ? 0.72
            : selected
            ? 1.08
            : 1,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 140),
          opacity: clearing && !specialClearing ? 0.34 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            margin: EdgeInsets.all(cellSize <= 42 ? 2 : 3),
            decoration: _boardCellDecoration(
              colors,
              color,
              value,
              power,
              selected,
              clearing,
              specialClearing,
              blocker,
              rainbow,
            ),
            child: value >= 0
                ? _buildTileFace(value, cellSize)
                : blocker
                ? _buildBlockerFace(context, cellSize)
                : null,
          ),
        ),
      ),
    );
  }

  BoxDecoration _boardCellDecoration(
    ColorScheme colors,
    Color color,
    int value,
    _MatchThreePower power,
    bool selected,
    bool clearing,
    bool specialClearing,
    bool blocker,
    bool rainbow,
  ) => BoxDecoration(
    color: rainbow
        ? null
        : color.withValues(alpha: value >= 0 || blocker ? 1 : 0.18),
    gradient: rainbow
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFFE95D7B),
              Color(0xFFF0B949),
              Color(0xFF43A971),
              Color(0xFF4D8FD6),
              Color(0xFF8B66D9),
            ],
          )
        : null,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(
      color: selected || clearing
          ? colors.primary
          : blocker
          ? colors.error.withValues(alpha: 0.66)
          : Colors.white.withValues(
              alpha: power == _MatchThreePower.none ? 0.55 : 0.82,
            ),
      width: selected || specialClearing
          ? 2.2
          : clearing || power != _MatchThreePower.none
          ? 1.2
          : 0.8,
    ),
    boxShadow: value >= 0 || blocker
        ? <BoxShadow>[
            BoxShadow(
              color:
                  (clearing
                          ? colors.primary
                          : blocker
                          ? colors.error
                          : color)
                      .withValues(alpha: clearing ? 0.34 : 0.2),
              blurRadius: clearing ? 14 : 8,
              offset: const Offset(0, 3),
            ),
          ]
        : null,
  );

  Widget _buildBoard(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = math.min(420.0, constraints.maxWidth);
        final cellSize = boardSize / _MatchThreeGameState._cols;
        return Center(
          child: _MiniGameScrollLockSurface(
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (event) =>
                  _handleBoardDragStart(event.localPosition, boardSize),
              onPointerMove: (event) =>
                  _handleBoardDragUpdate(event.localPosition, cellSize),
              onPointerUp: (_) => _handleBoardDragEnd(),
              onPointerCancel: (_) => _handleBoardDragEnd(),
              child: SizedBox(
                width: boardSize,
                height: boardSize,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount:
                      _MatchThreeGameState._rows * _MatchThreeGameState._cols,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _MatchThreeGameState._cols,
                  ),
                  itemBuilder: (context, index) =>
                      _buildBoardCell(context, index, cellSize),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    return '$minutes:${rest.toString().padLeft(2, '0')}';
  }

  Widget _buildGameView(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                ToolboxMetricCard(
                  label: i18n.t('toolbox.miniGames.match3.metric.score'),
                  value: '$_score',
                ),
                ToolboxMetricCard(
                  label: i18n.t('toolbox.miniGames.match3.metric.time'),
                  value: _formatTime(_remainingSeconds),
                ),
                ToolboxMetricCard(
                  label: i18n.t('toolbox.miniGames.match3.metric.moves'),
                  value: '$_moves',
                ),
                ToolboxMetricCard(
                  label: i18n.t('toolbox.miniGames.match3.metric.target'),
                  value: '${_MatchThreeGameState._targetScore}',
                ),
                ToolboxMetricCard(
                  label: i18n.t('toolbox.miniGames.match3.metric.chain'),
                  value: _chain <= 1 ? '1' : '${_chain}x',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Text(
                _statusLabel(i18n),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 12),
            _buildPowerLegend(context, i18n),
            const SizedBox(height: 12),
            _buildBoard(context),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.tonalIcon(
                  onPressed: _newGame,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(i18n.t('toolbox.miniGames.match3.action.new')),
                ),
                OutlinedButton.icon(
                  onPressed: _reshuffle,
                  icon: const Icon(Icons.shuffle_rounded),
                  label: Text(
                    i18n.t('toolbox.miniGames.match3.action.reshuffle'),
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

const List<Color> _matchThreeColors = <Color>[
  Color(0xFFE95D7B),
  Color(0xFFF0B949),
  Color(0xFF43A971),
  Color(0xFF4D8FD6),
  Color(0xFF8B66D9),
  Color(0xFFDB7A45),
];

const List<IconData> _matchThreeIcons = <IconData>[
  Icons.favorite_rounded,
  Icons.star_rounded,
  Icons.eco_rounded,
  Icons.water_drop_rounded,
  Icons.hexagon_rounded,
  Icons.brightness_5_rounded,
];

const List<_MatchThreePower> _matchThreeLegendPowers = <_MatchThreePower>[
  _MatchThreePower.row,
  _MatchThreePower.column,
  _MatchThreePower.bomb,
  _MatchThreePower.rainbow,
];
