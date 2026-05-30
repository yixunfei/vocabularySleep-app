part of '../toolbox_life_tools.dart';

class _MortgageProPage extends StatefulWidget {
  const _MortgageProPage();

  @override
  State<_MortgageProPage> createState() => _MortgageProPageState();
}

class _MortgageProPageState extends State<_MortgageProPage> {
  static const ToolboxMortgageService _service = ToolboxMortgageService();

  final TextEditingController _loanAmountController = TextEditingController(
    text: '1000000',
  );
  final TextEditingController _rateController = TextEditingController(
    text: '3.6',
  );
  final TextEditingController _yearsController = TextEditingController(
    text: '30',
  );
  final TextEditingController _areaController = TextEditingController(
    text: '100',
  );
  final TextEditingController _unitPriceController = TextEditingController(
    text: '30000',
  );
  final TextEditingController _downPaymentAmountController =
      TextEditingController();
  final TextEditingController _paidMonthsController = TextEditingController(
    text: '0',
  );
  final TextEditingController _extraPrincipalController = TextEditingController(
    text: '0',
  );
  final TextEditingController _monthlyFeeController = TextEditingController(
    text: '0',
  );
  final TextEditingController _oneTimeFeeController = TextEditingController(
    text: '0',
  );

  MortgageRepaymentMethod _method = MortgageRepaymentMethod.equalInstallment;
  MortgageCalculationMode _mode = MortgageCalculationMode.loanAmount;
  MortgageExtraPaymentStrategy _extraStrategy =
      MortgageExtraPaymentStrategy.reduceMonthlyPayment;
  double _downPaymentRatio = 0.3;
  late DateTime _firstPaymentDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _firstPaymentDate = DateTime(now.year, now.month + 1, 1);
  }

  @override
  void dispose() {
    _loanAmountController.dispose();
    _rateController.dispose();
    _yearsController.dispose();
    _areaController.dispose();
    _unitPriceController.dispose();
    _downPaymentAmountController.dispose();
    _paidMonthsController.dispose();
    _extraPrincipalController.dispose();
    _monthlyFeeController.dispose();
    _oneTimeFeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MortgageResult? result;
    String? error;
    try {
      result = _service.calculate(_input());
    } on Object {
      error = _lifeI18nText(
        context,
        'inline.plan295.life.check_loan_amount_area_unit_price_ra.ff9be74fea01',
      );
    }

    return ToolboxToolPage(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.mortgage_calculator.3e4f4dddc3e6',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.calculate_equal_installment_or_equal.c783ac6feb3d',
      ),
      child: Column(
        key: const ValueKey<String>('life-mortgage-page'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _hero(context, result, error),
          const SizedBox(height: 14),
          _loanPanel(context),
          const SizedBox(height: 12),
          _progressPanel(context, result),
          const SizedBox(height: 12),
          if (result != null) ...<Widget>[
            _detailPanel(context, result),
            const SizedBox(height: 12),
            _schedulePanel(context, result),
            const SizedBox(height: 12),
          ],
          _riskPanel(context),
        ],
      ),
    );
  }

  MortgageInput _input() {
    return MortgageInput(
      repaymentMethod: _method,
      calculationMode: _mode,
      termYears: _parseInt(_yearsController),
      annualRatePercent: _parseNumber(_rateController),
      firstPaymentDate: _firstPaymentDate,
      loanAmountYuan: _parseNumber(_loanAmountController),
      houseAreaSqm: _parseNumber(_areaController),
      unitPriceYuanPerSqm: _parseNumber(_unitPriceController),
      downPaymentRatio: _downPaymentRatio,
      downPaymentAmountYuan: _parseOptionalNumber(_downPaymentAmountController),
      paidMonths: _parseInt(_paidMonthsController),
      extraPrincipalPaidYuan: _parseNumber(_extraPrincipalController),
      extraPaymentStrategy: _extraStrategy,
      monthlyFeeYuan: _parseNumber(_monthlyFeeController),
      oneTimeFeeYuan: _parseNumber(_oneTimeFeeController),
    );
  }

  Widget _hero(BuildContext context, MortgageResult? result, String? error) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final nextPayment = result == null || result.remainingSchedule.isEmpty
        ? 0.0
        : result.remainingSchedule.first.totalCashOut;
    final headline = result == null
        ? _lifeI18nText(
            context,
            'inline.plan295.life.waiting_for_input.85833e6e2257',
          )
        : result.remainingSchedule.isEmpty
        ? _lifeI18nText(
            context,
            'inline.plan295.life.loan_paid_off.0d96440d6f0e',
          )
        : _money(nextPayment);
    final headlineLabel = result == null
        ? _lifeI18nText(context, 'inline.plan295.life.status.75268cb9d1d8')
        : _lifeI18nText(
            context,
            'inline.plan295.life.next_payment.b6f30757d2f4',
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            scheme.primaryContainer.withValues(alpha: 0.95),
            scheme.secondaryContainer.withValues(alpha: 0.7),
            scheme.surfaceContainerHighest,
          ],
        ),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
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
              _statusChip(
                context,
                _method == MortgageRepaymentMethod.equalInstallment
                    ? _lifeI18nText(
                        context,
                        'inline.plan295.life.equal_installment.df0603e21433',
                      )
                    : _lifeI18nText(
                        context,
                        'inline.plan295.life.equal_principal.6c3fcbc21497',
                      ),
              ),
              _statusChip(
                context,
                _mode == MortgageCalculationMode.loanAmount
                    ? _lifeI18nText(
                        context,
                        'inline.plan295.life.by_loan_amount.c2502a6a7efa',
                      )
                    : _lifeI18nText(
                        context,
                        'inline.plan295.life.by_housing_area.ba2d0623d181',
                      ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(headlineLabel, style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(
            headline,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          if (error != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
          ],
          if (result != null) ...<Widget>[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                ToolboxMetricCard(
                  label: _lifeI18nText(
                    context,
                    'inline.plan295.life.principal.b2f9f322ff64',
                  ),
                  value: _money(result.principal),
                ),
                ToolboxMetricCard(
                  label: _lifeI18nText(
                    context,
                    'inline.plan295.life.contract_interest.b50f2128884d',
                  ),
                  value: _money(result.contractTotalInterest),
                ),
                ToolboxMetricCard(
                  label: _lifeI18nText(
                    context,
                    'inline.plan295.life.remaining_principal.e52b52addb06',
                  ),
                  value: _money(result.remainingPrincipal),
                ),
                ToolboxMetricCard(
                  label: _lifeI18nText(
                    context,
                    'inline.plan295.life.time_left.b66df1df0814',
                  ),
                  value: _monthsText(context, result.remainingMonths),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _loanPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.loan_setup.05855aa97a74',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.choose_repayment_and_calculation_mod.6d5b33cbdc86',
      ),
      children: <Widget>[
        _LifeSegmentedField<MortgageRepaymentMethod>(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.repayment_method.fb54f6d819f0',
          ),
          value: _method,
          options: const <_LifeOption<MortgageRepaymentMethod>>[
            _LifeOption(
              value: MortgageRepaymentMethod.equalInstallment,
              labelKey: 'inline.plan295.life.equal_installment.df0603e21433',
            ),
            _LifeOption(
              value: MortgageRepaymentMethod.equalPrincipal,
              labelKey: 'inline.plan295.life.equal_principal.6c3fcbc21497',
            ),
          ],
          onChanged: (value) => setState(() => _method = value),
        ),
        const SizedBox(height: 14),
        _LifeSegmentedField<MortgageCalculationMode>(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.calculation_mode.54d1d3cd5df9',
          ),
          value: _mode,
          options: const <_LifeOption<MortgageCalculationMode>>[
            _LifeOption(
              value: MortgageCalculationMode.loanAmount,
              labelKey: 'inline.plan295.life.loan_amount.63ea87de3c18',
            ),
            _LifeOption(
              value: MortgageCalculationMode.housingArea,
              labelKey: 'inline.plan295.life.housing_area.4582fef79724',
            ),
          ],
          onChanged: (value) => setState(() => _mode = value),
        ),
        const SizedBox(height: 14),
        _WorkWorthFieldGrid(
          children: <Widget>[
            if (_mode == MortgageCalculationMode.loanAmount)
              _numberField(
                key: const ValueKey<String>('mortgage-loan-amount'),
                controller: _loanAmountController,
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.loan_amount.63ea87de3c18',
                ),
                prefixText: '¥ ',
              )
            else ...<Widget>[
              _numberField(
                controller: _areaController,
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.housing_area_m.2f0cca3470cd',
                ),
                suffixText: ' m²',
              ),
              _numberField(
                controller: _unitPriceController,
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.unit_price.ce7f54ca6ef4',
                ),
                prefixText: '¥ ',
              ),
              _numberField(
                controller: _downPaymentAmountController,
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.down_payment_amount_optional.c3c7d0f457fb',
                ),
                prefixText: '¥ ',
              ),
            ],
            _numberField(
              key: const ValueKey<String>('mortgage-rate'),
              controller: _rateController,
              label: _lifeI18nText(
                context,
                'inline.plan295.life.annual_rate.c17df6f9fd3f',
              ),
              suffixText: '%',
            ),
            _numberField(
              key: const ValueKey<String>('mortgage-years'),
              controller: _yearsController,
              label: _lifeI18nText(
                context,
                'inline.plan295.life.loan_term.a43ba990427a',
              ),
              suffixText: _lifeI18nText(
                context,
                'inline.plan295.life.years.24b659b2963e',
              ),
              decimal: false,
            ),
            FilledButton.tonalIcon(
              onPressed: _pickFirstPaymentDate,
              icon: const Icon(Icons.event_rounded),
              label: Text(
                _lifeI18nText(
                  context,
                  'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.mortgage.first_payment.2b587166c3',
                  params: <String, Object?>{'p0': _dateText(_firstPaymentDate)},
                ),
              ),
            ),
          ],
        ),
        if (_mode == MortgageCalculationMode.housingArea) ...<Widget>[
          const SizedBox(height: 14),
          _LifeSliderField(
            label: _lifeI18nText(
              context,
              'inline.plan295.life.down_payment_ratio.9290b65f1ba4',
            ),
            valueText: '${(_downPaymentRatio * 100).toStringAsFixed(0)}%',
            value: _downPaymentRatio,
            min: 0,
            max: 0.9,
            divisions: 18,
            onChanged: (value) => setState(() => _downPaymentRatio = value),
          ),
        ],
      ],
    );
  }

  Widget _progressPanel(BuildContext context, MortgageResult? result) {
    final maxMonths = result?.totalMonths ?? 0;
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.progress_and_fees.e331751003ee',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.use_paid_periods_and_prepayment_to_e.51db2c7c2d9f',
      ),
      children: <Widget>[
        _LifeSegmentedField<MortgageExtraPaymentStrategy>(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.prepayment_handling.0bf88ed29a39',
          ),
          value: _extraStrategy,
          options: const <_LifeOption<MortgageExtraPaymentStrategy>>[
            _LifeOption(
              value: MortgageExtraPaymentStrategy.reduceMonthlyPayment,
              labelKey: 'inline.plan295.life.lower_payment.a3e217c6d9a6',
            ),
            _LifeOption(
              value: MortgageExtraPaymentStrategy.shortenTerm,
              labelKey: 'inline.plan295.life.shorten_term.4fad6946a25e',
            ),
          ],
          onChanged: (value) => setState(() => _extraStrategy = value),
        ),
        const SizedBox(height: 14),
        _WorkWorthFieldGrid(
          children: <Widget>[
            _numberField(
              controller: _paidMonthsController,
              label: _lifeI18nText(
                context,
                'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.mortgage.paid_periods.34008aaa6e',
                params: <String, Object?>{
                  'p0': maxMonths > 0 ? ' / $maxMonths' : '',
                },
              ),
              decimal: false,
            ),
            _numberField(
              controller: _extraPrincipalController,
              label: _lifeI18nText(
                context,
                'inline.plan295.life.extra_principal_paid.0934304ce97e',
              ),
              prefixText: '¥ ',
            ),
            _numberField(
              controller: _monthlyFeeController,
              label: _lifeI18nText(
                context,
                'inline.plan295.life.monthly_fee.e6d5c74a085a',
              ),
              prefixText: '¥ ',
            ),
            _numberField(
              controller: _oneTimeFeeController,
              label: _lifeI18nText(
                context,
                'inline.plan295.life.one_time_fee.4f61937cb44d',
              ),
              prefixText: '¥ ',
            ),
          ],
        ),
      ],
    );
  }

  Widget _detailPanel(BuildContext context, MortgageResult result) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.detailed_result.35245b269441',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.contract_totals_paid_progress_remain.ed4d47727285',
      ),
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.first_payment.3d7f1953f20f',
              ),
              value: _money(result.firstMonthlyPayment),
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.last_payment.a7c6c5f153e9',
              ),
              value: _money(result.lastMonthlyPayment),
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.average_payment.bb662576fd8c',
              ),
              value: _money(result.averageMonthlyPayment),
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.contract_term.4733aebe56ad',
              ),
              value: _monthsText(context, result.totalMonths),
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.contract_cost.0eb49263d36d',
              ),
              value: _money(result.contractTotalCost),
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.remaining_interest.3959f5785b77',
              ),
              value: _money(result.remainingInterest),
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.remaining_cost.7acf85e2b3d2',
              ),
              value: _money(result.remainingTotalCost),
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.payoff_date.3fdc1e7dea97',
              ),
              value: result.finalPaymentDate == null
                  ? _lifeI18nText(
                      context,
                      'inline.plan295.life.paid_off.d5429e9001fa',
                    )
                  : _dateText(result.finalPaymentDate!),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _breakdownRow(
          context,
          _lifeI18nText(
            context,
            'inline.plan295.life.property_total.e026071e26aa',
          ),
          result.propertyTotal <= 0
              ? _lifeI18nText(
                  context,
                  'inline.plan295.life.not_set.1c12913fc41f',
                )
              : _money(result.propertyTotal),
        ),
        _breakdownRow(
          context,
          _lifeI18nText(
            context,
            'inline.plan295.life.down_payment.5bf51dc016cd',
          ),
          result.downPayment <= 0
              ? _lifeI18nText(
                  context,
                  'inline.plan295.life.not_included.30015cb3cae4',
                )
              : _money(result.downPayment),
        ),
        _breakdownRow(
          context,
          _lifeI18nText(
            context,
            'inline.plan295.life.principal_paid.b32e74e268b9',
          ),
          _money(result.paidPrincipal),
        ),
        _breakdownRow(
          context,
          _lifeI18nText(
            context,
            'inline.plan295.life.interest_paid.2fefd3046c47',
          ),
          _money(result.paidInterest),
        ),
        _breakdownRow(
          context,
          _lifeI18nText(context, 'inline.plan295.life.fees_paid.f6dad8db0006'),
          _money(result.paidFees),
        ),
        _breakdownRow(
          context,
          _lifeI18nText(
            context,
            'inline.plan295.life.extra_principal_applied.3e203a298d99',
          ),
          _money(result.extraPrincipalApplied),
        ),
      ],
    );
  }

  Widget _schedulePanel(BuildContext context, MortgageResult result) {
    final schedule = result.remainingSchedule.take(12).toList(growable: false);
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.upcoming_schedule.27f18e20f3c8',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.shows_the_next_12_periods_equal_prin.31f305c3a43f',
      ),
      children: <Widget>[
        if (schedule.isEmpty)
          Text(
            _lifeI18nText(
              context,
              'inline.plan295.life.no_remaining_payments.911a0800ca44',
            ),
          )
        else
          for (final payment in schedule)
            _MortgagePaymentTile(payment: payment, formatter: _money),
      ],
    );
  }

  Widget _riskPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.usage_boundary.5b4e7180375d',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.this_tool_is_for_local_estimation_an.bde8d992bca6',
      ),
      children: <Widget>[
        Text(
          _lifeI18nText(
            context,
            'inline.plan295.life.the_formulas_use_monthly_compounding.284aaf8e4bcd',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _numberField({
    Key? key,
    required TextEditingController controller,
    required String label,
    String? prefixText,
    String? suffixText,
    bool decimal = true,
  }) {
    return TextField(
      key: key,
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        suffixText: suffixText,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _statusChip(BuildContext context, String label) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _breakdownRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFirstPaymentDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
      initialDate: _firstPaymentDate,
    );
    if (date != null && mounted) {
      setState(() => _firstPaymentDate = date);
    }
  }

  double _parseNumber(TextEditingController controller) {
    final normalized = controller.text.trim().replaceAll(',', '');
    if (normalized.isEmpty) {
      return 0;
    }
    return double.tryParse(normalized) ?? 0;
  }

  double? _parseOptionalNumber(TextEditingController controller) {
    final normalized = controller.text.trim().replaceAll(',', '');
    if (normalized.isEmpty) {
      return null;
    }
    return double.tryParse(normalized);
  }

  int _parseInt(TextEditingController controller) {
    final normalized = controller.text.trim().replaceAll(',', '');
    return int.tryParse(normalized) ??
        double.tryParse(normalized)?.round() ??
        0;
  }

  String _money(double value) {
    final abs = value.abs();
    if (abs >= 100000000) {
      return '¥${(value / 100000000).toStringAsFixed(2)}亿';
    }
    if (abs >= 10000) {
      return '¥${(value / 10000).toStringAsFixed(2)}万';
    }
    return '¥${value.toStringAsFixed(0)}';
  }

  String _monthsText(BuildContext context, int months) {
    if (months <= 0) {
      return _lifeI18nText(
        context,
        'inline.plan295.life.0_months.675e7c4b0b23',
      );
    }
    final years = months ~/ 12;
    final rest = months % 12;
    if (years == 0) {
      return _lifeI18nText(
        context,
        'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.mortgage.months.0cf3168e08',
        params: <String, Object?>{'rest': rest},
      );
    }
    if (rest == 0) {
      return _lifeI18nText(
        context,
        'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.mortgage.years.0b8d36650d',
        params: <String, Object?>{'years': years},
      );
    }
    return _lifeI18nText(
      context,
      'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.mortgage.years_months.fe86338e06',
      params: <String, Object?>{'years': years, 'rest': rest},
    );
  }

  String _dateText(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _MortgagePaymentTile extends StatelessWidget {
  const _MortgagePaymentTile({required this.payment, required this.formatter});

  final MortgagePayment payment;
  final String Function(double value) formatter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date =
        '${payment.dueDate.year}-${payment.dueDate.month.toString().padLeft(2, '0')}-${payment.dueDate.day.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '#${payment.period}  $date',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                formatter(payment.totalCashOut),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ToolboxMetricCard(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.principal.0205175d6cc8',
                ),
                value: formatter(payment.principal),
              ),
              ToolboxMetricCard(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.interest.823504667e37',
                ),
                value: formatter(payment.interest),
              ),
              ToolboxMetricCard(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.fee.06cbbd8aae55',
                ),
                value: formatter(payment.fee),
              ),
              ToolboxMetricCard(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.balance.8438767a1d0c',
                ),
                value: formatter(payment.remainingPrincipal),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
