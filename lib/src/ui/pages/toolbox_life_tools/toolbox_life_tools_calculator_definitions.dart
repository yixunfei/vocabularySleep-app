part of '../toolbox_life_tools.dart';

extension _CalculatorDefinitionActions on _AdvancedCalculatorToolPageState {
  Future<void> _openDefinitionsSheet() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => _CalculatorDefinitionsSheet(
        session: _session,
        onInsert: (definition) {
          Navigator.pop(sheetContext);
          if (definition.isFunction) {
            _insertText('${definition.name}()', cursorBack: 1);
          } else {
            _insertText(definition.name);
          }
        },
      ),
    );
  }
}

class _CalculatorDefinitionsSheet extends StatelessWidget {
  const _CalculatorDefinitionsSheet({
    required this.session,
    required this.onInsert,
  });

  final ToolboxCalculatorSessionController session;
  final ValueChanged<ToolboxCalculatorDefinition> onInsert;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
        return AnimatedBuilder(
          animation: session,
          builder: (context, _) {
            final definitions = session.definitions;
            return Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 12, 10),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              _lifeI18nText(
                                context,
                                'toolbox.life.advanced_calculator.definition.title',
                              ),
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              _lifeI18nText(
                                context,
                                'toolbox.life.advanced_calculator.definition.subtitle',
                              ),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        key: const ValueKey<String>(
                          'advanced_calculator_add_definition',
                        ),
                        tooltip: _lifeI18nText(
                          context,
                          'toolbox.life.advanced_calculator.definition.add',
                        ),
                        onPressed:
                            definitions.length >=
                                ToolboxCalculatorDefinitionValidator
                                    .maxDefinitions
                            ? null
                            : () => _openEditor(context),
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: definitions.isEmpty
                      ? _CalculatorDefinitionEmptyState(
                          onAdd: () => _openEditor(context),
                        )
                      : ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                          itemCount: definitions.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final definition = definitions[index];
                            return ListTile(
                              minTileHeight: 64,
                              leading: Icon(
                                definition.isFunction
                                    ? Icons.functions_rounded
                                    : Icons.data_object_rounded,
                              ),
                              title: Text(
                                _definitionSignature(definition),
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                definition.expression,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => onInsert(definition),
                              trailing: Wrap(
                                spacing: 0,
                                children: <Widget>[
                                  IconButton(
                                    tooltip: _lifeI18nText(
                                      context,
                                      'toolbox.life.advanced_calculator.definition.edit',
                                    ),
                                    onPressed: () =>
                                        _openEditor(context, definition),
                                    icon: const Icon(Icons.edit_rounded),
                                  ),
                                  IconButton(
                                    tooltip: _lifeI18nText(
                                      context,
                                      'toolbox.life.advanced_calculator.definition.delete',
                                    ),
                                    onPressed: () => session.removeDefinition(
                                      definition.name,
                                    ),
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openEditor(
    BuildContext context, [
    ToolboxCalculatorDefinition? definition,
  ]) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _CalculatorDefinitionEditor(
        initialValue: definition,
        onSave: (next) {
          session.upsertDefinition(next, replacingName: definition?.name);
        },
      ),
    );
  }
}

class _CalculatorDefinitionEmptyState extends StatelessWidget {
  const _CalculatorDefinitionEmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.data_object_rounded,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              _lifeI18nText(
                context,
                'toolbox.life.advanced_calculator.definition.empty',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                _lifeI18nText(
                  context,
                  'toolbox.life.advanced_calculator.definition.add',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalculatorDefinitionEditor extends StatefulWidget {
  const _CalculatorDefinitionEditor({
    required this.initialValue,
    required this.onSave,
  });

  final ToolboxCalculatorDefinition? initialValue;
  final ValueChanged<ToolboxCalculatorDefinition> onSave;

  @override
  State<_CalculatorDefinitionEditor> createState() =>
      _CalculatorDefinitionEditorState();
}

class _CalculatorDefinitionEditorState
    extends State<_CalculatorDefinitionEditor> {
  late final TextEditingController _nameController;
  late final TextEditingController _parametersController;
  late final TextEditingController _expressionController;
  late bool _functionMode;
  String? _errorKey;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialValue;
    _nameController = TextEditingController(text: initial?.name);
    _parametersController = TextEditingController(
      text: initial?.parameters.join(','),
    );
    _expressionController = TextEditingController(text: initial?.expression);
    _functionMode = initial?.isFunction ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _parametersController.dispose();
    _expressionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              _lifeI18nText(
                context,
                widget.initialValue == null
                    ? 'toolbox.life.advanced_calculator.definition.add_title'
                    : 'toolbox.life.advanced_calculator.definition.edit_title',
              ),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: <ButtonSegment<bool>>[
                ButtonSegment<bool>(
                  value: false,
                  icon: const Icon(Icons.data_object_rounded),
                  label: Text(
                    _lifeI18nText(
                      context,
                      'toolbox.life.advanced_calculator.definition.variable',
                    ),
                  ),
                ),
                ButtonSegment<bool>(
                  value: true,
                  icon: const Icon(Icons.functions_rounded),
                  label: Text(
                    _lifeI18nText(
                      context,
                      'toolbox.life.advanced_calculator.definition.function',
                    ),
                  ),
                ),
              ],
              selected: <bool>{_functionMode},
              onSelectionChanged: (selection) {
                setState(() {
                  _functionMode = selection.first;
                  _errorKey = null;
                });
              },
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey<String>('calculator_definition_name'),
              controller: _nameController,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: _lifeI18nText(
                  context,
                  'toolbox.life.advanced_calculator.definition.name',
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            if (_functionMode) ...<Widget>[
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey<String>('calculator_definition_parameters'),
                controller: _parametersController,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: _lifeI18nText(
                    context,
                    'toolbox.life.advanced_calculator.definition.parameters',
                  ),
                  helperText: _lifeI18nText(
                    context,
                    'toolbox.life.advanced_calculator.definition.parameters_help',
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey<String>('calculator_definition_expression'),
              controller: _expressionController,
              minLines: 2,
              maxLines: 4,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: _lifeI18nText(
                  context,
                  'toolbox.life.advanced_calculator.definition.expression',
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            if (_errorKey != null) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                _lifeI18nText(context, _errorKey!),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const ValueKey<String>('calculator_definition_save'),
              onPressed: _save,
              icon: const Icon(Icons.check_rounded),
              label: Text(
                _lifeI18nText(
                  context,
                  'toolbox.life.advanced_calculator.definition.save',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    try {
      final parameters = _functionMode
          ? _parametersController.text
                .split(',')
                .map((value) => value.trim())
                .where((value) => value.isNotEmpty)
                .toList(growable: false)
          : const <String>[];
      if (_functionMode && parameters.isEmpty) {
        throw const ToolboxCalculatorDefinitionException(
          ToolboxCalculatorDefinitionFailure.invalidParameters,
        );
      }
      widget.onSave(
        ToolboxCalculatorDefinition(
          name: _nameController.text.trim(),
          expression: _expressionController.text.trim(),
          parameters: parameters,
        ),
      );
      Navigator.pop(context);
    } on ToolboxCalculatorDefinitionException catch (error) {
      setState(() => _errorKey = error.i18nKey);
    }
  }
}

String _definitionSignature(ToolboxCalculatorDefinition definition) {
  if (!definition.isFunction) return definition.name;
  return '${definition.name}(${definition.parameters.join(', ')})';
}
