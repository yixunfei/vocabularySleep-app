part of '../toolbox_life_tools.dart';

class _AdvancedCalculatorToolPage extends StatefulWidget {
  const _AdvancedCalculatorToolPage({
    this.engineFactory,
    this.sessionStoreFactory,
  });

  final ToolboxCalculatorEngine Function()? engineFactory;
  final ToolboxCalculatorSessionStore Function()? sessionStoreFactory;

  @override
  State<_AdvancedCalculatorToolPage> createState() =>
      _AdvancedCalculatorToolPageState();
}

class _AdvancedCalculatorToolPageState
    extends State<_AdvancedCalculatorToolPage> {
  final TextEditingController _expressionController = TextEditingController();
  final FocusNode _expressionFocusNode = FocusNode();
  final UndoHistoryController _undoController = UndoHistoryController();
  final ToolboxScientificCalculatorService _numericCalculator =
      const ToolboxScientificCalculatorService();

  late final ToolboxCalculatorSessionController _session;
  late final _CalculatorToolDraft _toolDraft;

  _CalculatorKeypadPage _keypadPage = _CalculatorKeypadPage.basic;
  bool _programmaticExpressionEdit = false;
  bool _resultCommitted = false;

  @override
  void initState() {
    super.initState();
    _session = ToolboxCalculatorSessionController(
      engine: widget.engineFactory?.call() ?? createToolboxCalculatorEngine(),
      numericCalculator: _numericCalculator,
      sessionStore:
          widget.sessionStoreFactory?.call() ??
          createToolboxCalculatorSessionStore(),
    );
    _toolDraft = _CalculatorToolDraft();
    _expressionController.addListener(_handleExpressionChanged);
    unawaited(_session.restore());
  }

  @override
  void dispose() {
    _expressionController.removeListener(_handleExpressionChanged);
    _expressionController.dispose();
    _expressionFocusNode.dispose();
    _undoController.dispose();
    _toolDraft.dispose();
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeI18nText(context, 'toolbox.life.advanced_calculator.title'),
      subtitle: _lifeI18nText(
        context,
        'toolbox.life.advanced_calculator.subtitle',
      ),
      showPageHeader: false,
      appBarActions: <Widget>[
        IconButton(
          key: const ValueKey<String>('advanced_calculator_catalog_action'),
          tooltip: _lifeI18nText(
            context,
            'toolbox.life.advanced_calculator.catalog.title',
          ),
          onPressed: _openCatalogSheet,
          icon: const Icon(Icons.menu_book_rounded),
        ),
        IconButton(
          key: const ValueKey<String>('advanced_calculator_history_action'),
          tooltip: _lifeI18nText(
            context,
            'toolbox.life.advanced_calculator.history.group',
          ),
          onPressed: _openHistorySheet,
          icon: const Icon(Icons.history_rounded),
        ),
        IconButton(
          key: const ValueKey<String>('advanced_calculator_tools_action'),
          tooltip: _lifeI18nText(
            context,
            'toolbox.life.advanced_calculator.tools',
          ),
          onPressed: _openToolSheet,
          icon: const Icon(Icons.functions_rounded),
        ),
      ],
      child: AnimatedBuilder(
        animation: _session,
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _CalculatorWorkspacePanel(
                expressionController: _expressionController,
                expressionFocusNode: _expressionFocusNode,
                undoController: _undoController,
                session: _session,
                onEvaluate: _submitExpression,
                onContinue: _continueWithResult,
                onCopyPlain: (part) => _copyResult(latex: false, part: part),
                onCopyLatex: (part) => _copyResult(latex: true, part: part),
                onInsertMemory: _insertMemory,
              ),
              const SizedBox(height: 12),
              _CalculatorKeypad(
                page: _keypadPage,
                calculating: _session.isCalculating,
                onPageChanged: (value) => setState(() => _keypadPage = value),
                onKeyPressed: _handleKeyPress,
              ),
              const SizedBox(height: 12),
              _CalculatorCommandBar(
                onOpenDefinitions: _openDefinitionsSheet,
                onOpenCatalog: _openCatalogSheet,
                onOpenTools: _openToolSheet,
                onOpenHistory: _openHistorySheet,
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleExpressionChanged() {
    if (!_programmaticExpressionEdit) _session.markUserInteraction();
    if (_programmaticExpressionEdit || !_resultCommitted) return;
    setState(() => _resultCommitted = false);
  }

  void _setResultCommitted(bool value) {
    if (!mounted || _resultCommitted == value) return;
    setState(() => _resultCommitted = value);
  }

  bool get _canSubmitExpression =>
      _expressionController.text.trim().isNotEmpty && !_session.isCalculating;

  Future<void> _submitExpression() async {
    if (!_canSubmitExpression) return;
    final expression = _expressionController.text.trim();
    await _session.evaluate(expression);
    if (!mounted) return;
    setState(() {
      _resultCommitted =
          _session.status == ToolboxCalculatorSessionStatus.success;
    });
  }

  Future<void> _submitToolRequest(
    ToolboxCalculatorRequest request,
    String expressionLabel,
  ) async {
    await _session.submit(
      request,
      expressionLabel: _historySourceForRequest(request, expressionLabel),
    );
    if (!mounted) return;
    setState(() {
      _resultCommitted =
          _session.status == ToolboxCalculatorSessionStatus.success;
    });
  }

  void _acceptNumericToolResult(
    ToolboxCalculatorOperation operation,
    String expressionLabel,
    num value,
  ) {
    _session.acceptNumericResult(
      operation: operation,
      expressionLabel: expressionLabel,
      value: value,
    );
    setState(() {
      _resultCommitted =
          _session.status == ToolboxCalculatorSessionStatus.success;
    });
  }

  void _replaceExpression(String value, {bool focus = true}) {
    if (_expressionController.text != value) _session.markUserInteraction();
    _programmaticExpressionEdit = true;
    _expressionController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    _programmaticExpressionEdit = false;
    if (focus) _expressionFocusNode.requestFocus();
  }

  void _clearWorkspace() {
    _session.clearResult();
    _replaceExpression('');
    _setResultCommitted(false);
  }

  void _insertMemory() {
    if (_session.memoryExpression != null) _insertText('mem');
  }

  void _restoreHistoryEntry(ToolboxCalculatorHistoryEntry entry) {
    _replaceExpression(entry.expression);
    setState(() => _resultCommitted = false);
  }

  String _historySourceForRequest(
    ToolboxCalculatorRequest request,
    String fallback,
  ) {
    final expression = request.expression?.trim();
    if (expression != null && expression.isNotEmpty) return expression;
    if (request.equations.isNotEmpty) return request.equations.join('; ');
    final matrix = request.matrix;
    if (matrix != null) {
      return '[${matrix.map((row) => '[${row.join(',')}]').join(',')}]';
    }
    final vector = request.vector;
    if (vector != null) return '[${vector.join(',')}]';
    return fallback;
  }
}
