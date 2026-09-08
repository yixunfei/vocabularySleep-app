part of '../toolbox_life_tools.dart';

const _calculatorBasicKeys = <_CalculatorKeySpec>[
  _CalculatorKeySpec(label: '7', insertion: '7'),
  _CalculatorKeySpec(label: '8', insertion: '8'),
  _CalculatorKeySpec(label: '9', insertion: '9'),
  _CalculatorKeySpec(
    label: '÷',
    insertion: '/',
    kind: _CalculatorKeyKind.operator,
  ),
  _CalculatorKeySpec(
    label: '(',
    insertion: '(',
    kind: _CalculatorKeyKind.operator,
  ),
  _CalculatorKeySpec(label: '4', insertion: '4'),
  _CalculatorKeySpec(label: '5', insertion: '5'),
  _CalculatorKeySpec(label: '6', insertion: '6'),
  _CalculatorKeySpec(
    label: '×',
    insertion: '*',
    kind: _CalculatorKeyKind.operator,
  ),
  _CalculatorKeySpec(
    label: ')',
    insertion: ')',
    kind: _CalculatorKeyKind.operator,
  ),
  _CalculatorKeySpec(label: '1', insertion: '1'),
  _CalculatorKeySpec(label: '2', insertion: '2'),
  _CalculatorKeySpec(label: '3', insertion: '3'),
  _CalculatorKeySpec(
    label: '−',
    insertion: '-',
    kind: _CalculatorKeyKind.operator,
  ),
  _CalculatorKeySpec(
    label: 'xʸ',
    insertion: '^()',
    cursorBack: 1,
    kind: _CalculatorKeyKind.operator,
  ),
  _CalculatorKeySpec(label: '0', insertion: '0'),
  _CalculatorKeySpec(label: '.', insertion: '.'),
  _CalculatorKeySpec(
    label: ',',
    insertion: ',',
    kind: _CalculatorKeyKind.operator,
  ),
  _CalculatorKeySpec(
    label: '+',
    insertion: '+',
    kind: _CalculatorKeyKind.operator,
  ),
  _CalculatorKeySpec(
    label: 'n!',
    insertion: '!',
    kind: _CalculatorKeyKind.operator,
  ),
];

const _calculatorScientificKeys = <_CalculatorKeySpec>[
  _CalculatorKeySpec(
    label: 'sin',
    insertion: 'sin()',
    cursorBack: 1,
    kind: _CalculatorKeyKind.function,
  ),
  _CalculatorKeySpec(
    label: 'cos',
    insertion: 'cos()',
    cursorBack: 1,
    kind: _CalculatorKeyKind.function,
  ),
  _CalculatorKeySpec(
    label: 'tan',
    insertion: 'tan()',
    cursorBack: 1,
    kind: _CalculatorKeyKind.function,
  ),
  _CalculatorKeySpec(
    label: 'sin⁻¹',
    insertion: 'asin()',
    cursorBack: 1,
    kind: _CalculatorKeyKind.function,
  ),
  _CalculatorKeySpec(
    label: 'cos⁻¹',
    insertion: 'acos()',
    cursorBack: 1,
    kind: _CalculatorKeyKind.function,
  ),
  _CalculatorKeySpec(
    label: 'tan⁻¹',
    insertion: 'atan()',
    cursorBack: 1,
    kind: _CalculatorKeyKind.function,
  ),
  _CalculatorKeySpec(
    label: 'sinh',
    insertion: 'sinh()',
    cursorBack: 1,
    kind: _CalculatorKeyKind.function,
  ),
  _CalculatorKeySpec(
    label: 'cosh',
    insertion: 'cosh()',
    cursorBack: 1,
    kind: _CalculatorKeyKind.function,
  ),
  _CalculatorKeySpec(
    label: 'tanh',
    insertion: 'tanh()',
    cursorBack: 1,
    kind: _CalculatorKeyKind.function,
  ),
  _CalculatorKeySpec(
    label: 'ln',
    insertion: 'log()',
    cursorBack: 1,
    kind: _CalculatorKeyKind.function,
  ),
  _CalculatorKeySpec(
    label: 'logₐ',
    insertion: 'log(,)',
    cursorBack: 2,
    kind: _CalculatorKeyKind.function,
  ),
  _CalculatorKeySpec(
    label: 'eˣ',
    insertion: 'exp()',
    cursorBack: 1,
    kind: _CalculatorKeyKind.function,
  ),
  _CalculatorKeySpec(
    label: '10ˣ',
    insertion: '10^()',
    cursorBack: 1,
    kind: _CalculatorKeyKind.function,
  ),
  _CalculatorKeySpec(
    label: 'x²',
    insertion: '^2',
    kind: _CalculatorKeyKind.operator,
  ),
  _CalculatorKeySpec(
    label: '√',
    insertion: 'sqrt()',
    cursorBack: 1,
    kind: _CalculatorKeyKind.function,
  ),
  _CalculatorKeySpec(
    label: '∛',
    insertion: 'cbrt()',
    cursorBack: 1,
    kind: _CalculatorKeyKind.function,
  ),
  _CalculatorKeySpec(
    label: '|x|',
    insertion: 'abs()',
    cursorBack: 1,
    kind: _CalculatorKeyKind.function,
  ),
  _CalculatorKeySpec(
    label: '⌊x⌋',
    insertion: 'floor()',
    cursorBack: 1,
    kind: _CalculatorKeyKind.function,
  ),
  _CalculatorKeySpec(
    label: '⌈x⌉',
    insertion: 'ceil()',
    cursorBack: 1,
    kind: _CalculatorKeyKind.function,
  ),
  _CalculatorKeySpec(
    label: 'round',
    insertion: 'round()',
    cursorBack: 1,
    kind: _CalculatorKeyKind.function,
  ),
  _CalculatorKeySpec(
    label: 'nCr',
    insertion: 'nCr(,)',
    cursorBack: 2,
    kind: _CalculatorKeyKind.function,
  ),
  _CalculatorKeySpec(
    label: 'nPr',
    insertion: 'nPr(,)',
    cursorBack: 2,
    kind: _CalculatorKeyKind.function,
  ),
  _CalculatorKeySpec(
    label: 'gcd',
    insertion: 'gcd(,)',
    cursorBack: 2,
    kind: _CalculatorKeyKind.function,
  ),
  _CalculatorKeySpec(
    label: 'lcm',
    insertion: 'lcm(,)',
    cursorBack: 2,
    kind: _CalculatorKeyKind.function,
  ),
  _CalculatorKeySpec(
    label: 'root',
    insertion: 'root(,)',
    cursorBack: 2,
    kind: _CalculatorKeyKind.function,
  ),
];

const _calculatorSymbolKeys = <_CalculatorKeySpec>[
  _CalculatorKeySpec(
    label: 'π',
    insertion: 'pi',
    kind: _CalculatorKeyKind.constant,
  ),
  _CalculatorKeySpec(
    label: 'e',
    insertion: 'e',
    kind: _CalculatorKeyKind.constant,
  ),
  _CalculatorKeySpec(
    label: 'τ',
    insertion: 'tau',
    kind: _CalculatorKeyKind.constant,
  ),
  _CalculatorKeySpec(
    label: 'φ',
    insertion: 'phi',
    kind: _CalculatorKeyKind.constant,
  ),
  _CalculatorKeySpec(
    label: 'i',
    insertion: 'i',
    kind: _CalculatorKeyKind.constant,
  ),
  _CalculatorKeySpec(label: 'x', insertion: 'x'),
  _CalculatorKeySpec(label: 'y', insertion: 'y'),
  _CalculatorKeySpec(label: 'z', insertion: 'z'),
  _CalculatorKeySpec(label: 'θ', insertion: 'theta'),
  _CalculatorKeySpec(label: 'λ', insertion: 'lambda'),
  _CalculatorKeySpec(
    label: '∞',
    insertion: 'infinity',
    kind: _CalculatorKeyKind.constant,
  ),
  _CalculatorKeySpec(
    label: 'Ans',
    insertion: 'ans',
    kind: _CalculatorKeyKind.constant,
  ),
  _CalculatorKeySpec(
    label: 'Mem',
    insertion: 'mem',
    kind: _CalculatorKeyKind.constant,
  ),
  _CalculatorKeySpec(
    label: 'mod',
    insertion: 'mod(,)',
    cursorBack: 2,
    kind: _CalculatorKeyKind.function,
  ),
  _CalculatorKeySpec(
    label: '√[n]',
    insertion: 'root(,)',
    cursorBack: 2,
    kind: _CalculatorKeyKind.function,
  ),
  _CalculatorKeySpec.tool(
    label: '∫',
    toolCategory: _CalculatorToolCategory.calculus,
    toolOperation: ToolboxCalculatorOperation.integrate,
  ),
  _CalculatorKeySpec.tool(
    label: 'd/dx',
    toolCategory: _CalculatorToolCategory.calculus,
    toolOperation: ToolboxCalculatorOperation.differentiate,
  ),
  _CalculatorKeySpec.tool(
    label: 'lim',
    toolCategory: _CalculatorToolCategory.calculus,
    toolOperation: ToolboxCalculatorOperation.limit,
  ),
  _CalculatorKeySpec.tool(
    label: 'Σ',
    toolCategory: _CalculatorToolCategory.calculus,
    toolOperation: ToolboxCalculatorOperation.summation,
  ),
  _CalculatorKeySpec.tool(
    label: 'Π',
    toolCategory: _CalculatorToolCategory.calculus,
    toolOperation: ToolboxCalculatorOperation.product,
  ),
  _CalculatorKeySpec.tool(
    label: '∂',
    toolCategory: _CalculatorToolCategory.calculus,
    toolOperation: ToolboxCalculatorOperation.differentiate,
  ),
  _CalculatorKeySpec.tool(
    label: '∇',
    toolCategory: _CalculatorToolCategory.calculus,
    toolOperation: ToolboxCalculatorOperation.gradient,
  ),
  _CalculatorKeySpec.tool(
    label: 'det',
    toolCategory: _CalculatorToolCategory.linearAlgebra,
    toolOperation: ToolboxCalculatorOperation.determinant,
  ),
  _CalculatorKeySpec.tool(
    label: 'A⁻¹',
    toolCategory: _CalculatorToolCategory.linearAlgebra,
    toolOperation: ToolboxCalculatorOperation.inverse,
  ),
  _CalculatorKeySpec.tool(
    label: 'rref',
    toolCategory: _CalculatorToolCategory.linearAlgebra,
    toolOperation: ToolboxCalculatorOperation.rref,
  ),
];

class _CalculatorKeypad extends StatelessWidget {
  const _CalculatorKeypad({
    required this.page,
    required this.calculating,
    required this.onPageChanged,
    required this.onKeyPressed,
  });

  final _CalculatorKeypadPage page;
  final bool calculating;
  final ValueChanged<_CalculatorKeypadPage> onPageChanged;
  final ValueChanged<Object> onKeyPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final keys = switch (page) {
      _CalculatorKeypadPage.basic => _calculatorBasicKeys,
      _CalculatorKeypadPage.scientific => _calculatorScientificKeys,
      _CalculatorKeypadPage.symbols => _calculatorSymbolKeys,
    };
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: <Widget>[
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<_CalculatorKeypadPage>(
              showSelectedIcon: false,
              segments: _CalculatorKeypadPage.values
                  .map(
                    (value) => ButtonSegment<_CalculatorKeypadPage>(
                      value: value,
                      label: Text(
                        _lifeI18nText(
                          context,
                          'toolbox.life.advanced_calculator.keypad.${value.name}',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(growable: false),
              selected: <_CalculatorKeypadPage>{page},
              onSelectionChanged: (selection) {
                onPageChanged(selection.first);
              },
            ),
          ),
          const SizedBox(height: 8),
          _CalculatorKeyGrid(keys: keys, onKeyPressed: onKeyPressed),
          const SizedBox(height: 6),
          _CalculatorControlRow(
            calculating: calculating,
            onPressed: onKeyPressed,
          ),
        ],
      ),
    );
  }
}

class _CalculatorKeyGrid extends StatelessWidget {
  const _CalculatorKeyGrid({required this.keys, required this.onKeyPressed});

  final List<_CalculatorKeySpec> keys;
  final ValueChanged<Object> onKeyPressed;

  @override
  Widget build(BuildContext context) {
    const columns = 5;
    const keyHeight = 48.0;
    const spacing = 6.0;
    final rows = (keys.length / columns).ceil();
    return SizedBox(
      height: rows * keyHeight + (rows - 1) * spacing,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: keys.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          mainAxisExtent: keyHeight,
        ),
        itemBuilder: (context, index) {
          final keySpec = keys[index];
          return _CalculatorKeyButton(
            spec: keySpec,
            onPressed: () => onKeyPressed(keySpec),
          );
        },
      ),
    );
  }
}

class _CalculatorKeyButton extends StatelessWidget {
  const _CalculatorKeyButton({required this.spec, required this.onPressed});

  final _CalculatorKeySpec spec;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final (background, foreground) = switch (spec.kind) {
      _CalculatorKeyKind.operator => (
        colors.primaryContainer.withValues(alpha: 0.78),
        colors.onPrimaryContainer,
      ),
      _CalculatorKeyKind.function => (
        colors.secondaryContainer.withValues(alpha: 0.68),
        colors.onSecondaryContainer,
      ),
      _CalculatorKeyKind.constant => (
        colors.tertiaryContainer.withValues(alpha: 0.62),
        colors.onTertiaryContainer,
      ),
      _CalculatorKeyKind.digit => (
        colors.surfaceContainerHigh,
        colors.onSurface,
      ),
    };
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                spec.label,
                maxLines: 1,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CalculatorControlRow extends StatelessWidget {
  const _CalculatorControlRow({
    required this.calculating,
    required this.onPressed,
  });

  final bool calculating;
  final ValueChanged<Object> onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _controlButton(context, _CalculatorControlAction.clear, label: 'AC'),
        const SizedBox(width: 6),
        _controlButton(
          context,
          _CalculatorControlAction.left,
          icon: Icons.chevron_left_rounded,
        ),
        const SizedBox(width: 6),
        _controlButton(
          context,
          _CalculatorControlAction.right,
          icon: Icons.chevron_right_rounded,
        ),
        const SizedBox(width: 6),
        _controlButton(
          context,
          _CalculatorControlAction.backspace,
          icon: Icons.backspace_outlined,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: FilledButton(
            key: const ValueKey<String>('advanced_calculator_equals'),
            onPressed: calculating
                ? null
                : () => onPressed(_CalculatorControlAction.evaluate),
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: calculating
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('='),
          ),
        ),
      ],
    );
  }

  Widget _controlButton(
    BuildContext context,
    _CalculatorControlAction action, {
    String? label,
    IconData? icon,
  }) {
    final tooltipKey = switch (action) {
      _CalculatorControlAction.clear =>
        'toolbox.life.advanced_calculator.clear',
      _CalculatorControlAction.left =>
        'toolbox.life.advanced_calculator.cursor_left',
      _CalculatorControlAction.right =>
        'toolbox.life.advanced_calculator.cursor_right',
      _CalculatorControlAction.backspace =>
        'toolbox.life.advanced_calculator.backspace',
      _CalculatorControlAction.evaluate =>
        'toolbox.life.advanced_calculator.operation.evaluate',
    };
    return Tooltip(
      message: _lifeI18nText(context, tooltipKey),
      child: SizedBox(
        width: 48,
        height: 48,
        child: OutlinedButton(
          onPressed: () => onPressed(action),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: icon == null ? Text(label!) : Icon(icon),
        ),
      ),
    );
  }
}

extension _CalculatorEditingActions on _AdvancedCalculatorToolPageState {
  void _handleKeyPress(Object key) {
    if (key is _CalculatorControlAction) {
      if (key == _CalculatorControlAction.evaluate && !_canSubmitExpression) {
        return;
      }
      _handleControlAction(key);
      _triggerCalculatorSelectionHaptic();
      return;
    }
    _triggerCalculatorSelectionHaptic();
    final spec = key as _CalculatorKeySpec;
    if (spec.toolOperation != null) {
      _openToolSheet(
        category: spec.toolCategory,
        operation: spec.toolOperation,
      );
      return;
    }
    final insertion = spec.insertion;
    if (insertion == null) return;
    final activeResult = _session.result;
    if (_resultCommitted &&
        activeResult != null &&
        !activeResult.isComposite &&
        _startsContinuation(insertion)) {
      _replaceExpression('(${activeResult.exact})$insertion');
      _setResultCommitted(false);
      return;
    }
    if (_resultCommitted) {
      _replaceExpression('', focus: false);
      _setResultCommitted(false);
    }
    _insertText(insertion, cursorBack: spec.cursorBack);
  }

  void _handleControlAction(_CalculatorControlAction action) {
    switch (action) {
      case _CalculatorControlAction.clear:
        _clearWorkspace();
      case _CalculatorControlAction.left:
        _moveCursor(-1);
      case _CalculatorControlAction.right:
        _moveCursor(1);
      case _CalculatorControlAction.backspace:
        _backspace();
      case _CalculatorControlAction.evaluate:
        unawaited(_submitExpression());
    }
  }

  void _insertText(String insertion, {int cursorBack = 0}) {
    final value = _expressionController.value;
    final start = value.selection.isValid
        ? value.selection.start.clamp(0, value.text.length)
        : value.text.length;
    final end = value.selection.isValid
        ? value.selection.end.clamp(start, value.text.length)
        : value.text.length;
    final text = value.text.replaceRange(start, end, insertion);
    final offset = (start + insertion.length - cursorBack).clamp(
      0,
      text.length,
    );
    _session.markUserInteraction();
    _programmaticExpressionEdit = true;
    _expressionController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
    _programmaticExpressionEdit = false;
    _expressionFocusNode.requestFocus();
  }

  void _backspace() {
    final value = _expressionController.value;
    if (value.text.isEmpty) return;
    final selection = value.selection;
    if (selection.isValid && !selection.isCollapsed) {
      _deleteRange(selection.start, selection.end);
      return;
    }
    final offset = selection.isValid
        ? selection.start.clamp(0, value.text.length)
        : value.text.length;
    if (offset > 0) _deleteRange(offset - 1, offset);
  }

  void _deleteRange(int start, int end) {
    final text = _expressionController.text.replaceRange(start, end, '');
    _session.markUserInteraction();
    _programmaticExpressionEdit = true;
    _expressionController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: start),
    );
    _programmaticExpressionEdit = false;
    _expressionFocusNode.requestFocus();
  }

  void _moveCursor(int delta) {
    final value = _expressionController.value;
    final current = value.selection.isValid
        ? value.selection.extentOffset
        : value.text.length;
    final offset = (current + delta).clamp(0, value.text.length);
    _expressionController.selection = TextSelection.collapsed(offset: offset);
    _expressionFocusNode.requestFocus();
  }

  bool _startsContinuation(String insertion) {
    return const <String>{
      '+',
      '-',
      '*',
      '/',
      '^()',
      '^2',
      '!',
    }.contains(insertion);
  }
}

void _triggerCalculatorSelectionHaptic() {
  unawaited(_performCalculatorSelectionHaptic());
}

Future<void> _performCalculatorSelectionHaptic() async {
  try {
    await HapticFeedback.selectionClick();
  } on Object {
    // Haptics are optional and must never interrupt calculator input.
  }
}
