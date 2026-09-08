part of '../toolbox_life_tools.dart';

extension _CalculatorComplexToolViews on _CalculatorToolSheetState {
  Widget _buildComplexTools(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _CalculatorSheetSectionTitle(
          titleKey: 'toolbox.life.advanced_calculator.section.complex',
          subtitleKey: 'toolbox.life.advanced_calculator.section.complex_hint',
          icon: Icons.blur_circular_rounded,
        ),
        const SizedBox(height: 12),
        _CalculatorActionGrid<ToolboxCalculatorOperation>(
          highlighted: widget.initialOperation,
          actions: <ToolboxCalculatorOperation>[
            ToolboxCalculatorOperation.complexRealPart,
            ToolboxCalculatorOperation.complexImaginaryPart,
            ToolboxCalculatorOperation.complexConjugate,
            ToolboxCalculatorOperation.complexMagnitude,
            ToolboxCalculatorOperation.complexArgument,
            ToolboxCalculatorOperation.complexPolarForm,
            ToolboxCalculatorOperation.complexRectangularForm,
          ].map(_calculatorEngineAction).toList(growable: false),
          onSelected: _runComplexOperation,
        ),
        const SizedBox(height: 22),
        const _CalculatorSheetSectionTitle(
          titleKey: 'toolbox.life.advanced_calculator.section.polar_input',
          subtitleKey:
              'toolbox.life.advanced_calculator.section.polar_input_hint',
          icon: Icons.radar_rounded,
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _CalculatorToolField(
                controller: draft.complexRadius,
                labelKey: 'toolbox.life.advanced_calculator.complex_radius',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CalculatorToolField(
                controller: draft.complexAngle,
                labelKey: 'toolbox.life.advanced_calculator.complex_angle',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 48,
          child: FilledButton.tonalIcon(
            key: const ValueKey<String>('advanced_calculator_from_polar'),
            onPressed: () => _runComplexOperation(
              ToolboxCalculatorOperation.complexFromPolar,
            ),
            icon: const Icon(Icons.my_location_rounded),
            label: Text(
              _lifeI18nText(
                context,
                _calculatorOperationKey(
                  ToolboxCalculatorOperation.complexFromPolar,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _runComplexOperation(ToolboxCalculatorOperation operation) {
    try {
      if (operation != ToolboxCalculatorOperation.complexFromPolar &&
          expression.isEmpty) {
        throw const FormatException('Complex expression is empty');
      }
      final fromPolar =
          operation == ToolboxCalculatorOperation.complexFromPolar;
      final radius = draft.complexRadius.text.trim();
      final angle = draft.complexAngle.text.trim();
      if (fromPolar && (radius.isEmpty || angle.isEmpty)) {
        throw const FormatException('Polar coordinates are incomplete');
      }
      runRequest(
        ToolboxCalculatorRequest(
          operation: operation,
          expression: fromPolar ? null : expression,
          radius: fromPolar ? radius : null,
          angle: fromPolar ? angle : null,
        ),
        detail: fromPolar ? 'r=$radius, θ=$angle' : expression,
      );
    } on FormatException {
      showDraftError();
    }
  }
}
