part of '../toolbox_life_tools.dart';

typedef _CalculatorRequestCallback =
    Future<void> Function(
      ToolboxCalculatorRequest request,
      String expressionLabel,
    );

typedef _CalculatorNumericCallback =
    void Function(
      ToolboxCalculatorOperation operation,
      String expressionLabel,
      num value,
    );

class _CalculatorToolSheet extends StatefulWidget {
  const _CalculatorToolSheet({
    required this.expression,
    required this.draft,
    required this.onExpressionChanged,
    required this.onSubmit,
    required this.onNumericResult,
    this.initialCategory = _CalculatorToolCategory.algebra,
    this.initialOperation,
  });

  final String expression;
  final _CalculatorToolDraft draft;
  final ValueChanged<String> onExpressionChanged;
  final _CalculatorRequestCallback onSubmit;
  final _CalculatorNumericCallback onNumericResult;
  final _CalculatorToolCategory initialCategory;
  final ToolboxCalculatorOperation? initialOperation;

  @override
  State<_CalculatorToolSheet> createState() => _CalculatorToolSheetState();
}

class _CalculatorToolSheetState extends State<_CalculatorToolSheet> {
  late final TextEditingController _expressionController;
  late _CalculatorToolCategory _category;
  bool _draftError = false;

  _CalculatorToolDraft get draft => widget.draft;
  String get expression => _expressionController.text.trim();

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    _expressionController = TextEditingController(text: widget.expression);
    _expressionController.addListener(_syncExpression);
  }

  @override
  void dispose() {
    _expressionController.removeListener(_syncExpression);
    _expressionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedPadding(
      duration: AppDurations.quick,
      curve: AppEasing.snappy,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Material(
        color: theme.colorScheme.surface,
        child: Column(
          children: <Widget>[
            const SizedBox(height: 8),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _lifeI18nText(
                        context,
                        'toolbox.life.advanced_calculator.tool_sheet_title',
                      ),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _CalculatorCategorySelector(
                value: _category,
                onChanged: (value) => setState(() {
                  _category = value;
                  _draftError = false;
                }),
              ),
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _buildExpressionField(context),
                    const SizedBox(height: 16),
                    AnimatedSwitcher(
                      duration: AppDurations.standard,
                      switchInCurve: AppEasing.snappy,
                      switchOutCurve: AppEasing.gentle,
                      child: KeyedSubtree(
                        key: ValueKey<_CalculatorToolCategory>(_category),
                        child: switch (_category) {
                          _CalculatorToolCategory.algebra => _buildAlgebraTools(
                            context,
                          ),
                          _CalculatorToolCategory.calculus =>
                            _buildCalculusTools(context),
                          _CalculatorToolCategory.linearAlgebra =>
                            _buildLinearTools(context),
                          _CalculatorToolCategory.complex => _buildComplexTools(
                            context,
                          ),
                          _CalculatorToolCategory.probability =>
                            _buildProbabilityTools(context),
                        },
                      ),
                    ),
                    if (_draftError) ...<Widget>[
                      const SizedBox(height: 12),
                      const _CalculatorInlineError(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpressionField(BuildContext context) {
    return TextField(
      key: const ValueKey<String>('advanced_calculator_tool_expression'),
      controller: _expressionController,
      minLines: 1,
      maxLines: 3,
      autocorrect: false,
      enableSuggestions: false,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontFamily: 'monospace',
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: _lifeI18nText(
          context,
          'toolbox.life.advanced_calculator.current_expression',
        ),
        hintText: _lifeI18nText(
          context,
          'toolbox.life.advanced_calculator.expression_hint',
        ),
        border: const OutlineInputBorder(),
      ),
    );
  }

  void _syncExpression() {
    widget.onExpressionChanged(_expressionController.text);
  }

  void runRequest(ToolboxCalculatorRequest request, {String? detail}) {
    final label = _operationLabel(context, request.operation, detail);
    Navigator.pop(context);
    unawaited(widget.onSubmit(request, label));
  }

  void runNumeric(
    ToolboxCalculatorOperation operation,
    String label,
    num value,
  ) {
    Navigator.pop(context);
    widget.onNumericResult(operation, label, value);
  }

  void showDraftError() {
    setState(() => _draftError = true);
  }

  String _operationLabel(
    BuildContext context,
    ToolboxCalculatorOperation operation,
    String? detail,
  ) {
    final name = _lifeI18nText(context, _calculatorOperationKey(operation));
    final value = detail?.trim();
    if (value != null && value.isNotEmpty) return '$name · $value';
    if (expression.isNotEmpty) return '$name · $expression';
    return name;
  }
}

extension _CalculatorToolSheetLauncher on _AdvancedCalculatorToolPageState {
  void _openToolSheet({
    _CalculatorToolCategory? category,
    ToolboxCalculatorOperation? operation,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.94,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: _CalculatorToolSheet(
              expression: _expressionController.text,
              draft: _toolDraft,
              initialCategory: category ?? _CalculatorToolCategory.algebra,
              initialOperation: operation,
              onExpressionChanged: (value) {
                _replaceExpression(value, focus: false);
              },
              onSubmit: _submitToolRequest,
              onNumericResult: _acceptNumericToolResult,
            ),
          ),
        );
      },
    );
  }
}
