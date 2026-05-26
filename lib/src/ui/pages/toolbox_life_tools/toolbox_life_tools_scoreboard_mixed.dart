part of '../toolbox_life_tools.dart';

class _MixedScoreMode extends StatefulWidget {
  const _MixedScoreMode({required this.vsync});

  final TickerProvider vsync;

  @override
  State<_MixedScoreMode> createState() => _MixedScoreModeState();
}

class _MixedScoreModeState extends State<_MixedScoreMode> {
  final List<_PlayerEntry> _entries = <_PlayerEntry>[
    _PlayerEntry(name: '队伍 1', color: _teamColorPresets[0]),
  ];
  final List<String> _columnDefs = <String>['得分'];
  bool _stepEnabled = false;
  int _stepValue = 1;

  @override
  void initState() {
    super.initState();
    for (final entry in _entries) {
      for (final colName in _columnDefs) {
        entry.columns.add(_ScoreColumn(label: colName, score: 0));
      }
    }
  }

  int get _step => _stepEnabled ? _stepValue : 1;

  void _addColumn() {
    setState(() {
      final idx = _columnDefs.length + 1;
      _columnDefs.add('列 $idx');
      for (final entry in _entries) {
        entry.columns.add(_ScoreColumn(label: _columnDefs.last, score: 0));
      }
    });
  }

  void _removeColumn(int colIdx) {
    if (_columnDefs.length <= 1) return;
    setState(() {
      _columnDefs.removeAt(colIdx);
      for (final entry in _entries) {
        entry.columns.removeAt(colIdx);
      }
    });
  }

  void _addEntry() {
    final idx = _entries.length + 1;
    final entry = _PlayerEntry(
      name: '队伍 $idx',
      color: _teamColorPresets[idx % _teamColorPresets.length],
    );
    for (final colName in _columnDefs) {
      entry.columns.add(_ScoreColumn(label: colName, score: 0));
    }
    setState(() => _entries.add(entry));
  }

  void _removeEntry(int idx) {
    if (_entries.length <= 1) return;
    setState(() => _entries.removeAt(idx));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: <Widget>[
        _StepValueSetting(
          enabled: _stepEnabled,
          value: _stepValue,
          onToggle: (v) => setState(() => _stepEnabled = v),
          onValueChanged: (v) => setState(() => _stepValue = v),
        ),
        const SizedBox(height: 8),
        _buildColumnDefsRow(theme),
        const SizedBox(height: 8),
        _buildStandingsTable(theme),
        const SizedBox(height: 8),
        FilledButton.tonalIcon(
          onPressed: _addEntry,
          icon: const Icon(Icons.add_rounded),
          label: Text(_lifeText(context, zh: '新增队伍', en: 'Add team')),
        ),
      ],
    );
  }

  Widget _buildColumnDefsRow(ThemeData theme) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            _lifeText(context, zh: '统计列项', en: 'Stat columns'),
            style: theme.textTheme.labelLarge,
          ),
        ),
        IconButton.filledTonal(
          onPressed: _columnDefs.length > 1
              ? () => _removeColumn(_columnDefs.length - 1)
              : null,
          icon: const Icon(Icons.remove_rounded, size: 18),
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 4),
        IconButton.filledTonal(
          onPressed: _addColumn,
          icon: const Icon(Icons.add_rounded, size: 18),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildStandingsTable(ThemeData theme) {
    final colWidth = 100.0;
    final teamWidth = 120.0;
    final totalWidth = teamWidth + _columnDefs.length * colWidth + 80;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: math.max(totalWidth, MediaQuery.of(context).size.width - 24),
        child: Table(
          border: TableBorder.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
            width: 0.8,
          ),
          columnWidths: <int, TableColumnWidth>{
            0: const FixedColumnWidth(120),
            for (var c = 0; c < _columnDefs.length; c += 1)
              c + 1: FixedColumnWidth(colWidth),
            _columnDefs.length + 1: const FixedColumnWidth(80),
          },
          children: <TableRow>[
            _buildHeaderRow(theme),
            for (var i = 0; i < _entries.length; i += 1)
              _buildDataRow(theme, _entries[i], i),
          ],
        ),
      ),
    );
  }

  TableRow _buildHeaderRow(ThemeData theme) {
    return TableRow(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      children: <Widget>[
        _headerCell(
          _lifeText(context, zh: '队伍', en: 'Team'),
          theme,
          height: 40,
        ),
        for (var c = 0; c < _columnDefs.length; c += 1)
          _headerCellWithEdit(theme, c),
        _headerCell(
          _lifeText(context, zh: '总计', en: 'Total'),
          theme,
          height: 40,
        ),
      ],
    );
  }

  Widget _headerCell(String text, ThemeData theme, {double height = 36}) {
    return Container(
      height: height,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _headerCellWithEdit(ThemeData theme, int colIdx) {
    final ctrl = TextEditingController(text: _columnDefs[colIdx]);
    return Container(
      height: 40,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: TextField(
        controller: ctrl,
        textAlign: TextAlign.center,
        maxLength: 6,
        buildCounter: (
          BuildContext context, {
          required int currentLength,
          required bool isFocused,
          required int? maxLength,
        }) =>
            null,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          border: InputBorder.none,
        ),
        onChanged: (v) {
          final label = v.trim().isEmpty ? '列' : v.trim();
          _columnDefs[colIdx] = label;
          for (final entry in _entries) {
            if (colIdx < entry.columns.length) {
              entry.columns[colIdx].label = label;
            }
          }
        },
      ),
    );
  }

  TableRow _buildDataRow(ThemeData theme, _PlayerEntry entry, int idx) {
    return TableRow(
      children: <Widget>[
        _teamCell(theme, entry, idx),
        for (var c = 0; c < _columnDefs.length; c += 1)
          _scoreCell(theme, entry.columns[c]),
        _totalCell(theme, entry),
      ],
    );
  }

  Widget _teamCell(ThemeData theme, _PlayerEntry entry, int idx) {
    final nameCtrl = TextEditingController(text: entry.name);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: <Widget>[
          GestureDetector(
            onTap: () => _showColorPicker(entry),
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: entry.color,
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: nameCtrl,
              textAlign: TextAlign.center,
              maxLength: 8,
              buildCounter: (
          BuildContext context, {
          required int currentLength,
          required bool isFocused,
          required int? maxLength,
        }) =>
            null,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                border: InputBorder.none,
              ),
              onChanged: (v) {
                entry.name = v.trim().isEmpty ? '队伍' : v.trim();
              },
            ),
          ),
          if (_entries.length > 1)
            GestureDetector(
              onTap: () => _removeEntry(idx),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: theme.colorScheme.error.withValues(alpha: 0.6),
              ),
            ),
        ],
      ),
    );
  }

  Widget _scoreCell(ThemeData theme, _ScoreColumn col) {
    return Container(
      height: 44,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          InkWell(
            onTap: () => setState(() => col.score = math.max(0, col.score - _step)),
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.remove_circle_outline_rounded, size: 16),
            ),
          ),
          const SizedBox(width: 2),
          Text(
            '${col.score}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 2),
          InkWell(
            onTap: () => setState(() => col.score += _step),
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.add_circle_rounded, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalCell(ThemeData theme, _PlayerEntry entry) {
    final total = entry.columns.fold(0, (sum, c) => sum + c.score);
    return Container(
      height: 44,
      alignment: Alignment.center,
      child: Text(
        '$total',
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w900,
          fontFamily: 'monospace',
          color: entry.color,
        ),
      ),
    );
  }

  void _showColorPicker(_PlayerEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                _lifeText(context, zh: '选择颜色', en: 'Pick color'),
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              const SizedBox(height: 14),
              _ColorPicker(
                value: entry.color,
                onChanged: (c) {
                  setState(() => entry.color = c);
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PlayerEntry {
  _PlayerEntry({required this.name, required this.color});

  String name;
  Color color;
  final List<_ScoreColumn> columns = <_ScoreColumn>[];
}

class _ScoreColumn {
  _ScoreColumn({required this.label, required this.score});

  String label;
  int score;
}
