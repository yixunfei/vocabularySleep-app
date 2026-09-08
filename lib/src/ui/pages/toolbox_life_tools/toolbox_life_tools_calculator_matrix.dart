part of '../toolbox_life_tools.dart';

class _CalculatorMatrixDraft {
  _CalculatorMatrixDraft({required List<List<String>> values}) {
    _replace(values);
    textController.text = toText();
  }

  final TextEditingController textController = TextEditingController();
  List<List<TextEditingController>> _cells = <List<TextEditingController>>[];
  bool gridMode = true;

  int get rows => _cells.length;
  int get columns => _cells.first.length;
  List<List<TextEditingController>> get cells => _cells;

  void resize({int? rows, int? columns}) {
    final nextRows = (rows ?? this.rows).clamp(1, 6);
    final nextColumns = (columns ?? this.columns).clamp(1, 6);
    final previous = values();
    final next = List<List<String>>.generate(
      nextRows,
      (row) => List<String>.generate(
        nextColumns,
        (column) => row < previous.length && column < previous[row].length
            ? previous[row][column]
            : row == column
            ? '1'
            : '0',
      ),
    );
    _replace(next);
    textController.text = toText();
  }

  bool switchMode(bool useGrid) {
    if (gridMode == useGrid) return true;
    if (!useGrid) {
      textController.text = toText();
      gridMode = false;
      return true;
    }
    final parsed = _parse(textController.text);
    if (parsed.length > 6 || parsed.first.length > 6) return false;
    _replace(parsed);
    gridMode = true;
    return true;
  }

  List<List<String>> values() {
    if (!gridMode) return _parse(textController.text);
    return _cells
        .map(
          (row) => row
              .map((cell) => cell.text.trim().isEmpty ? '0' : cell.text.trim())
              .toList(growable: false),
        )
        .toList(growable: false);
  }

  void replaceValues(List<List<String>> values) {
    if (values.isEmpty ||
        values.first.isEmpty ||
        values.length > 12 ||
        values.first.length > 12 ||
        values.any((row) => row.length != values.first.length)) {
      throw const FormatException('Invalid matrix dimensions');
    }
    _replace(values);
    gridMode = values.length <= 6 && values.first.length <= 6;
    textController.text = _encode(values);
  }

  String toText() {
    return _encode(values());
  }

  String _encode(List<List<String>> values) {
    return '[${values.map((row) => '[${row.join(',')}]').join(',')}]';
  }

  void _replace(List<List<String>> values) {
    for (final row in _cells) {
      for (final controller in row) {
        controller.dispose();
      }
    }
    _cells = values
        .map(
          (row) => row
              .map((value) => TextEditingController(text: value))
              .toList(growable: false),
        )
        .toList(growable: false);
  }

  List<List<String>> _parse(String input) {
    var source = input.trim();
    if (source.startsWith('[[') && source.endsWith(']]')) {
      source = source.substring(2, source.length - 2);
      source = source.replaceAll(RegExp(r'\]\s*,\s*\['), ';');
    }
    source = source.replaceAll('[', '').replaceAll(']', '');
    final rows = source
        .split(RegExp(r'[;\n]+'))
        .map((row) => row.trim())
        .where((row) => row.isNotEmpty)
        .map((row) {
          final parts = row.contains(',')
              ? row.split(',')
              : row.split(RegExp(r'\s+'));
          return parts
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .toList(growable: false);
        })
        .toList(growable: false);
    if (rows.isEmpty || rows.first.isEmpty || rows.length > 12) {
      throw const FormatException('Invalid matrix');
    }
    final width = rows.first.length;
    if (width > 12 || rows.any((row) => row.length != width)) {
      throw const FormatException('Invalid matrix dimensions');
    }
    return rows;
  }

  void dispose() {
    textController.dispose();
    for (final row in _cells) {
      for (final controller in row) {
        controller.dispose();
      }
    }
  }
}

class _CalculatorMatrixEditor extends StatefulWidget {
  const _CalculatorMatrixEditor({required this.label, required this.draft});

  final String label;
  final _CalculatorMatrixDraft draft;

  @override
  State<_CalculatorMatrixEditor> createState() =>
      _CalculatorMatrixEditorState();
}

class _CalculatorMatrixEditorState extends State<_CalculatorMatrixEditor> {
  bool _modeError = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                widget.label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: <ButtonSegment<bool>>[
                ButtonSegment<bool>(
                  value: true,
                  icon: const Icon(Icons.grid_on_rounded, size: 18),
                  tooltip: _lifeI18nText(
                    context,
                    'toolbox.life.advanced_calculator.matrix_mode.grid',
                  ),
                ),
                ButtonSegment<bool>(
                  value: false,
                  icon: const Icon(Icons.data_array_rounded, size: 18),
                  tooltip: _lifeI18nText(
                    context,
                    'toolbox.life.advanced_calculator.matrix_mode.text',
                  ),
                ),
              ],
              selected: <bool>{widget.draft.gridMode},
              onSelectionChanged: (selection) => _switchMode(selection.first),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: AppDurations.standard,
          switchInCurve: AppEasing.snappy,
          switchOutCurve: AppEasing.gentle,
          child: widget.draft.gridMode
              ? _buildGrid(context)
              : _buildTextEditor(context),
        ),
        if (_modeError) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            _lifeI18nText(
              context,
              'toolbox.life.advanced_calculator.matrix_grid_limit',
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGrid(BuildContext context) {
    return Column(
      key: const ValueKey<String>('matrix_grid'),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _MatrixDimensionControl(
                label: _lifeI18nText(
                  context,
                  'toolbox.life.advanced_calculator.matrix_rows',
                ),
                value: widget.draft.rows,
                onChanged: (value) => _resize(rows: value),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MatrixDimensionControl(
                label: _lifeI18nText(
                  context,
                  'toolbox.life.advanced_calculator.matrix_columns',
                ),
                value: widget.draft.columns,
                onChanged: (value) => _resize(columns: value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 4.0;
            final naturalWidth =
                widget.draft.columns * 48 + (widget.draft.columns - 1) * gap;
            final width = math.max(constraints.maxWidth, naturalWidth);
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: width,
                child: Column(
                  children: widget.draft.cells
                      .map((row) => _buildMatrixRow(row, gap))
                      .toList(growable: false),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMatrixRow(List<TextEditingController> row, double gap) {
    return Padding(
      padding: EdgeInsets.only(bottom: gap),
      child: Row(
        children: <Widget>[
          for (var index = 0; index < row.length; index++) ...<Widget>[
            if (index > 0) SizedBox(width: gap),
            Expanded(
              child: SizedBox(
                height: 48,
                child: TextField(
                  controller: row[index],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextEditor(BuildContext context) {
    return TextField(
      key: const ValueKey<String>('matrix_text'),
      controller: widget.draft.textController,
      minLines: 3,
      maxLines: 6,
      autocorrect: false,
      enableSuggestions: false,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
      decoration: InputDecoration(
        helperText: _lifeI18nText(
          context,
          'toolbox.life.advanced_calculator.matrix_text_helper',
        ),
        border: const OutlineInputBorder(),
      ),
    );
  }

  void _switchMode(bool useGrid) {
    try {
      final changed = widget.draft.switchMode(useGrid);
      setState(() => _modeError = !changed);
    } on FormatException {
      setState(() => _modeError = true);
    }
  }

  void _resize({int? rows, int? columns}) {
    setState(() {
      widget.draft.resize(rows: rows, columns: columns);
      _modeError = false;
    });
  }
}

class _MatrixDimensionControl extends StatelessWidget {
  const _MatrixDimensionControl({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        IconButton(
          tooltip: _lifeI18nText(
            context,
            'toolbox.life.advanced_calculator.matrix_decrease_dimension',
          ),
          onPressed: value <= 1 ? null : () => onChanged(value - 1),
          icon: const Icon(Icons.remove_rounded),
        ),
        Expanded(
          child: Text(
            '$label $value',
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          tooltip: _lifeI18nText(
            context,
            'toolbox.life.advanced_calculator.matrix_increase_dimension',
          ),
          onPressed: value >= 6 ? null : () => onChanged(value + 1),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }
}
