part of '../toolbox_life_tools.dart';

extension _AdvancedCalculatorToolPageUi on _AdvancedCalculatorToolPageState {
  Widget _buildExpressionWorkspace(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final resultText = _errorKey == null
        ? _formatNumber(_result)
        : _lifeI18nText(context, _errorKey!);

    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'toolbox.life.advanced_calculator.workspace',
      ),
      subtitle: _lifeI18nText(
        context,
        'toolbox.life.advanced_calculator.workspace_subtitle',
      ),
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                colorScheme.primaryContainer.withValues(alpha: 0.78),
                colorScheme.tertiaryContainer.withValues(alpha: 0.42),
              ],
            ),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.14),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _CalculatorStatusPill(
                    icon: Icons.straighten_rounded,
                    label: _degreeMode
                        ? _lifeI18nText(
                            context,
                            'toolbox.life.advanced_calculator.angle_degree',
                          )
                        : _lifeI18nText(
                            context,
                            'toolbox.life.advanced_calculator.angle_radian',
                          ),
                  ),
                  _CalculatorStatusPill(
                    icon: Icons.keyboard_return_rounded,
                    label: 'ans ${_formatNumber(_lastAnswer)}',
                  ),
                  _CalculatorStatusPill(
                    icon: Icons.memory_rounded,
                    label: 'mem ${_formatNumber(_memory)}',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 3,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFeatures: const <ui.FontFeature>[
                    ui.FontFeature.tabularFigures(),
                  ],
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: colorScheme.surface.withValues(alpha: 0.66),
                  labelText: _lifeI18nText(
                    context,
                    'toolbox.life.advanced_calculator.expression',
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  suffixIcon: IconButton(
                    tooltip: _lifeI18nText(
                      context,
                      'toolbox.life.common.clear',
                    ),
                    onPressed: () => _controller.clear(),
                    icon: const Icon(Icons.clear_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _lifeI18nText(
                  context,
                  'toolbox.life.advanced_calculator.result',
                ),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.76),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              AnimatedSwitcher(
                duration: AppDurations.standard,
                switchInCurve: AppEasing.snappy,
                switchOutCurve: AppEasing.gentle,
                child: Align(
                  key: ValueKey<String>(resultText),
                  alignment: AlignmentDirectional.centerStart,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      resultText,
                      maxLines: 1,
                      softWrap: false,
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: _errorKey == null
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.error,
                        fontFeatures: const <ui.FontFeature>[
                          ui.FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            ChoiceChip(
              selected: _degreeMode,
              label: Text(
                _lifeI18nText(
                  context,
                  'toolbox.life.advanced_calculator.angle_degree',
                ),
              ),
              onSelected: (_) => applyState(() {
                _degreeMode = true;
                _evaluate();
              }),
            ),
            ChoiceChip(
              selected: !_degreeMode,
              label: Text(
                _lifeI18nText(
                  context,
                  'toolbox.life.advanced_calculator.angle_radian',
                ),
              ),
              onSelected: (_) => applyState(() {
                _degreeMode = false;
                _evaluate();
              }),
            ),
            FilledButton.tonalIcon(
              onPressed: _backspace,
              icon: const Icon(Icons.backspace_rounded),
              label: Text(
                _lifeI18nText(
                  context,
                  'toolbox.life.advanced_calculator.backspace',
                ),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: _result == null ? null : _commitResult,
              icon: const Icon(Icons.keyboard_return_rounded),
              label: Text(
                _lifeI18nText(
                  context,
                  'toolbox.life.advanced_calculator.use_result',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypad(BuildContext context) {
    const basicRows = <List<String>>[
      <String>['7', '8', '9', '/'],
      <String>['4', '5', '6', '*'],
      <String>['1', '2', '3', '-'],
      <String>['0', '.', ',', '+'],
      <String>['(', ')', '!', '√'],
    ];
    const scientificRows = <List<String>>[
      <String>['sin(', 'cos(', 'tan(', 'log('],
      <String>['asin(', 'acos(', 'atan(', 'ln('],
      <String>['sinh(', 'cosh(', 'tanh(', 'sqrt('],
      <String>['sec(', 'csc(', 'cot(', 'root('],
      <String>['gcd(', 'lcm(', 'nCr(', 'nPr('],
      <String>['abs(', 'exp(', 'pow(', '^'],
    ];
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'toolbox.life.advanced_calculator.keypad'),
      children: <Widget>[
        _CalculatorCollapsibleGroup(
          titleKey: 'toolbox.life.advanced_calculator.keypad.basic',
          initiallyExpanded: true,
          children: <Widget>[
            _buildTokenRows(basicRows),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.tonalIcon(
                  onPressed: _backspace,
                  icon: const Icon(Icons.backspace_rounded),
                  label: Text(
                    _lifeI18nText(
                      context,
                      'toolbox.life.advanced_calculator.backspace',
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _result == null ? null : _addHistory,
                  icon: const Icon(Icons.done_rounded),
                  label: Text(
                    _lifeI18nText(
                      context,
                      'toolbox.life.advanced_calculator.record',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        _CalculatorCollapsibleGroup(
          titleKey: 'toolbox.life.advanced_calculator.keypad.scientific',
          children: <Widget>[_buildTokenRows(scientificRows)],
        ),
        _CalculatorCollapsibleGroup(
          titleKey:
              'toolbox.life.advanced_calculator.keypad.constants_variables',
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.tonalIcon(
                  onPressed: () => _insert('pi'),
                  icon: const Icon(Icons.functions_rounded),
                  label: const Text('pi'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _insert('tau'),
                  icon: const Icon(Icons.functions_rounded),
                  label: const Text('tau'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _insert('phi'),
                  icon: const Icon(Icons.functions_rounded),
                  label: const Text('phi'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _insert('e'),
                  icon: const Icon(Icons.functions_rounded),
                  label: const Text('e'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _insert('x'),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('x'),
                ),
                FilledButton.tonalIcon(
                  onPressed: _lastAnswer == null ? null : () => _insert('ans'),
                  icon: const Icon(Icons.keyboard_return_rounded),
                  label: const Text('ans'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _insert('mem'),
                  icon: const Icon(Icons.memory_rounded),
                  label: const Text('mem'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTokenRows(List<List<String>> rows) {
    return Column(
      children: <Widget>[
        for (final row in rows) ...<Widget>[
          Row(
            children: <Widget>[
              for (final token in row)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: SizedBox(
                      height: 52,
                      child: FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          backgroundColor: _calculatorTokenBackground(
                            context,
                            token,
                          ),
                          foregroundColor: _calculatorTokenForeground(
                            context,
                            token,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          minimumSize: const Size(48, 48),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => _insert(token),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            token,
                            maxLines: 1,
                            softWrap: false,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Color? _calculatorTokenBackground(BuildContext context, String token) {
    final colorScheme = Theme.of(context).colorScheme;
    if (_isOperatorToken(token)) {
      return colorScheme.primaryContainer.withValues(alpha: 0.78);
    }
    if (_isFunctionToken(token)) {
      return colorScheme.secondaryContainer.withValues(alpha: 0.62);
    }
    return null;
  }

  Color? _calculatorTokenForeground(BuildContext context, String token) {
    final colorScheme = Theme.of(context).colorScheme;
    if (_isOperatorToken(token)) {
      return colorScheme.onPrimaryContainer;
    }
    if (_isFunctionToken(token)) {
      return colorScheme.onSecondaryContainer;
    }
    return null;
  }

  bool _isOperatorToken(String token) {
    return const <String>{
      '/',
      '*',
      '-',
      '+',
      '^',
      '√',
      '!',
      '(',
      ')',
      ',',
    }.contains(token);
  }

  bool _isFunctionToken(String token) {
    return token.endsWith('(') || token == 'nCr(' || token == 'nPr(';
  }

  Widget _buildProfessionalWorkspace(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'toolbox.life.advanced_calculator.pro_workspace',
      ),
      subtitle: _lifeI18nText(
        context,
        'toolbox.life.advanced_calculator.pro_workspace_subtitle',
      ),
      children: <Widget>[
        _LifeSegmentedField<_AdvancedCalculatorPanel>(
          label: _lifeI18nText(
            context,
            'toolbox.life.advanced_calculator.pro_panel',
          ),
          value: _panel,
          options: const <_LifeOption<_AdvancedCalculatorPanel>>[
            _LifeOption<_AdvancedCalculatorPanel>(
              value: _AdvancedCalculatorPanel.analysis,
              labelKey: 'toolbox.life.advanced_calculator.panel.analysis',
            ),
            _LifeOption<_AdvancedCalculatorPanel>(
              value: _AdvancedCalculatorPanel.linearAlgebra,
              labelKey: 'toolbox.life.advanced_calculator.panel.linear',
            ),
            _LifeOption<_AdvancedCalculatorPanel>(
              value: _AdvancedCalculatorPanel.probability,
              labelKey: 'toolbox.life.advanced_calculator.panel.probability',
            ),
          ],
          onChanged: (value) => applyState(() => _panel = value),
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: AppDurations.standard,
          switchInCurve: AppEasing.snappy,
          switchOutCurve: AppEasing.gentle,
          child: KeyedSubtree(
            key: ValueKey<_AdvancedCalculatorPanel>(_panel),
            child: switch (_panel) {
              _AdvancedCalculatorPanel.analysis => _buildAnalysisPanel(context),
              _AdvancedCalculatorPanel.linearAlgebra => _buildLinearPanel(
                context,
              ),
              _AdvancedCalculatorPanel.probability => _buildProbabilityPanel(
                context,
              ),
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisPanel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextField(
          controller: _analysisController,
          decoration: InputDecoration(
            labelText: _lifeI18nText(
              context,
              'toolbox.life.advanced_calculator.function_fx',
            ),
            helperText: _lifeI18nText(
              context,
              'toolbox.life.advanced_calculator.function_helper',
            ),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _smallField(
              context,
              _lowerController,
              'toolbox.life.advanced_calculator.lower',
            ),
            _smallField(
              context,
              _upperController,
              'toolbox.life.advanced_calculator.upper',
            ),
            _smallField(
              context,
              _pointController,
              'toolbox.life.advanced_calculator.point',
            ),
            _smallField(
              context,
              _rootLeftController,
              'toolbox.life.advanced_calculator.root_left',
            ),
            _smallField(
              context,
              _rootRightController,
              'toolbox.life.advanced_calculator.root_right',
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            FilledButton.tonalIcon(
              onPressed: _calculateIntegral,
              icon: const Icon(Icons.area_chart_rounded),
              label: Text(
                _lifeI18nText(
                  context,
                  'toolbox.life.advanced_calculator.integral',
                ),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: _calculateDerivative,
              icon: const Icon(Icons.show_chart_rounded),
              label: Text(
                _lifeI18nText(
                  context,
                  'toolbox.life.advanced_calculator.derivative',
                ),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: _calculateLimit,
              icon: const Icon(Icons.keyboard_double_arrow_right_rounded),
              label: Text(
                _lifeI18nText(
                  context,
                  'toolbox.life.advanced_calculator.limit',
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: _solveRoot,
              icon: const Icon(Icons.functions_rounded),
              label: Text(
                _lifeI18nText(
                  context,
                  'toolbox.life.advanced_calculator.solve_root',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _CalculatorResultBox(text: _analysisResult),
      ],
    );
  }

  Widget _buildLinearPanel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextField(
          controller: _matrixController,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: _lifeI18nText(
              context,
              'toolbox.life.advanced_calculator.matrix',
            ),
            helperText: _lifeI18nText(
              context,
              'toolbox.life.advanced_calculator.matrix_helper',
            ),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _vectorController,
          decoration: InputDecoration(
            labelText: _lifeI18nText(
              context,
              'toolbox.life.advanced_calculator.vector',
            ),
            helperText: _lifeI18nText(
              context,
              'toolbox.life.advanced_calculator.vector_helper',
            ),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            FilledButton.tonalIcon(
              onPressed: _calculateDeterminant,
              icon: const Icon(Icons.grid_on_rounded),
              label: Text(
                _lifeI18nText(
                  context,
                  'toolbox.life.advanced_calculator.determinant',
                ),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: _calculateInverse,
              icon: const Icon(Icons.flip_to_back_rounded),
              label: Text(
                _lifeI18nText(
                  context,
                  'toolbox.life.advanced_calculator.inverse',
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: _solveLinearSystem,
              icon: const Icon(Icons.rule_rounded),
              label: Text(
                _lifeI18nText(
                  context,
                  'toolbox.life.advanced_calculator.solve_linear',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _CalculatorResultBox(text: _matrixResult),
      ],
    );
  }

  Widget _buildProbabilityPanel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _CalculatorCollapsibleGroup(
          titleKey:
              'toolbox.life.advanced_calculator.probability.binomial_group',
          initiallyExpanded: true,
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _smallField(
                  context,
                  _probNController,
                  'toolbox.life.advanced_calculator.prob_n',
                ),
                _smallField(
                  context,
                  _probKController,
                  'toolbox.life.advanced_calculator.prob_k',
                ),
                _smallField(
                  context,
                  _probPController,
                  'toolbox.life.advanced_calculator.prob_p',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.tonal(
                  onPressed: _calculateCombination,
                  child: const Text('nCr'),
                ),
                FilledButton.tonal(
                  onPressed: _calculatePermutation,
                  child: const Text('nPr'),
                ),
                FilledButton.tonal(
                  onPressed: _calculateBinomialPmf,
                  child: Text(
                    _lifeI18nText(
                      context,
                      'toolbox.life.advanced_calculator.binomial_pmf',
                    ),
                  ),
                ),
                FilledButton.tonal(
                  onPressed: _calculateBinomialCdf,
                  child: Text(
                    _lifeI18nText(
                      context,
                      'toolbox.life.advanced_calculator.binomial_cdf',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        _CalculatorCollapsibleGroup(
          titleKey: 'toolbox.life.advanced_calculator.probability.normal_group',
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _smallField(
                  context,
                  _normalMeanController,
                  'toolbox.life.advanced_calculator.normal_mean',
                ),
                _smallField(
                  context,
                  _normalSdController,
                  'toolbox.life.advanced_calculator.normal_sd',
                ),
                _smallField(
                  context,
                  _normalXController,
                  'toolbox.life.advanced_calculator.normal_x',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.tonalIcon(
                  onPressed: _calculateNormalPdf,
                  icon: const Icon(Icons.stacked_line_chart_rounded),
                  label: Text(
                    _lifeI18nText(
                      context,
                      'toolbox.life.advanced_calculator.normal_pdf',
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _calculateNormalCdf,
                  icon: const Icon(Icons.ssid_chart_rounded),
                  label: Text(
                    _lifeI18nText(
                      context,
                      'toolbox.life.advanced_calculator.normal_cdf',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        _CalculatorResultBox(text: _probabilityResult),
      ],
    );
  }

  Widget _smallField(
    BuildContext context,
    TextEditingController controller,
    String labelKey,
  ) {
    return SizedBox(
      width: 132,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(
          signed: true,
          decimal: true,
        ),
        decoration: InputDecoration(
          labelText: _lifeI18nText(context, labelKey),
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildMemoryAndHistory(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'toolbox.life.advanced_calculator.memory_history',
      ),
      subtitle: _lifeI18nText(
        context,
        'toolbox.life.advanced_calculator.memory_history_subtitle',
      ),
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'toolbox.life.advanced_calculator.memory',
              ),
              value: _formatNumber(_memory),
            ),
            FilledButton.tonal(
              onPressed: _result == null
                  ? null
                  : () => applyState(() => _memory = _result!),
              child: const Text('MS'),
            ),
            FilledButton.tonal(
              onPressed: () => _insert(_formatNumber(_memory)),
              child: const Text('MR'),
            ),
            FilledButton.tonal(
              onPressed: () => applyState(() => _memory = 0),
              child: const Text('MC'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _CalculatorCollapsibleGroup(
          titleKey: 'toolbox.life.advanced_calculator.history.group',
          children: <Widget>[
            if (_history.isEmpty)
              Text(
                _lifeI18nText(
                  context,
                  'toolbox.life.advanced_calculator.history_empty',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              Column(
                children: _history
                    .take(6)
                    .map((item) {
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.expression),
                        subtitle: Text(_formatNumber(item.value)),
                        trailing: IconButton(
                          tooltip: _lifeI18nText(
                            context,
                            'toolbox.life.advanced_calculator.reuse',
                          ),
                          onPressed: () => _setExpression(item.value),
                          icon: const Icon(Icons.north_west_rounded),
                        ),
                      );
                    })
                    .toList(growable: false),
              ),
          ],
        ),
      ],
    );
  }
}

class _CalculatorCollapsibleGroup extends StatelessWidget {
  const _CalculatorCollapsibleGroup({
    required this.titleKey,
    required this.children,
    this.initiallyExpanded = false,
  });

  final String titleKey;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.62),
        ),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          initiallyExpanded: initiallyExpanded,
          maintainState: true,
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          iconColor: colorScheme.primary,
          collapsedIconColor: colorScheme.onSurfaceVariant,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            _lifeI18nText(context, titleKey),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          children: <Widget>[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalculatorStatusPill extends StatelessWidget {
  const _CalculatorStatusPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: theme.colorScheme.surface.withValues(alpha: 0.58),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
              fontFeatures: const <ui.FontFeature>[
                ui.FontFeature.tabularFigures(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
