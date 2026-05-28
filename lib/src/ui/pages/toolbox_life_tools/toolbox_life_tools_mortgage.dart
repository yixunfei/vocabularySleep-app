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
      error = _lifeText(
        context,
        zh: '请检查贷款金额、面积、单价、利率和年限，所有核心参数都需要为有效正数。',
        en: 'Check loan amount, area, unit price, rate, and term. Core values must be valid positive numbers.',
      );
    }

    return ToolboxToolPage(
      title: _lifeText(context, zh: '房贷计算器', en: 'Mortgage calculator'),
      subtitle: _lifeText(
        context,
        zh: '支持等额本息、等额本金、按贷款额或住房面积测算，并纳入首次还款日、已还期数、提前还款和附加费用。',
        en: 'Calculate equal installment or equal principal loans by amount or housing area, with first payment date, progress, prepayment, and fees.',
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
        ? _lifeText(context, zh: '等待有效参数', en: 'Waiting for input')
        : result.remainingSchedule.isEmpty
        ? _lifeText(context, zh: '贷款已结清', en: 'Loan paid off')
        : _money(nextPayment);
    final headlineLabel = result == null
        ? _lifeText(context, zh: '当前状态', en: 'Status')
        : _lifeText(context, zh: '下期应还', en: 'Next payment');

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
                    ? _lifeText(context, zh: '等额本息', en: 'Equal installment')
                    : _lifeText(context, zh: '等额本金', en: 'Equal principal'),
              ),
              _statusChip(
                context,
                _mode == MortgageCalculationMode.loanAmount
                    ? _lifeText(context, zh: '按贷款金额', en: 'By loan amount')
                    : _lifeText(context, zh: '按住房面积', en: 'By housing area'),
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
                  label: _lifeText(context, zh: '贷款金额', en: 'Principal'),
                  value: _money(result.principal),
                ),
                ToolboxMetricCard(
                  label: _lifeText(
                    context,
                    zh: '原始总利息',
                    en: 'Contract interest',
                  ),
                  value: _money(result.contractTotalInterest),
                ),
                ToolboxMetricCard(
                  label: _lifeText(
                    context,
                    zh: '剩余本金',
                    en: 'Remaining principal',
                  ),
                  value: _money(result.remainingPrincipal),
                ),
                ToolboxMetricCard(
                  label: _lifeText(context, zh: '还要还多久', en: 'Time left'),
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
      title: _lifeText(context, zh: '贷款配置', en: 'Loan setup'),
      subtitle: _lifeText(
        context,
        zh: '先选还款方式和计算方式，再录入贷款、利率、年限和首次还款时间。',
        en: 'Choose repayment and calculation modes, then enter amount, rate, term, and first payment date.',
      ),
      children: <Widget>[
        _LifeSegmentedField<MortgageRepaymentMethod>(
          label: _lifeText(context, zh: '贷款方式', en: 'Repayment method'),
          value: _method,
          options: const <_LifeOption<MortgageRepaymentMethod>>[
            _LifeOption(
              value: MortgageRepaymentMethod.equalInstallment,
              labelZh: '等额本息',
              labelEn: 'Equal installment',
            ),
            _LifeOption(
              value: MortgageRepaymentMethod.equalPrincipal,
              labelZh: '等额本金',
              labelEn: 'Equal principal',
            ),
          ],
          onChanged: (value) => setState(() => _method = value),
        ),
        const SizedBox(height: 14),
        _LifeSegmentedField<MortgageCalculationMode>(
          label: _lifeText(context, zh: '计算方式', en: 'Calculation mode'),
          value: _mode,
          options: const <_LifeOption<MortgageCalculationMode>>[
            _LifeOption(
              value: MortgageCalculationMode.loanAmount,
              labelZh: '贷款金额',
              labelEn: 'Loan amount',
            ),
            _LifeOption(
              value: MortgageCalculationMode.housingArea,
              labelZh: '住房面积',
              labelEn: 'Housing area',
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
                label: _lifeText(context, zh: '贷款金额', en: 'Loan amount'),
                prefixText: '¥ ',
              )
            else ...<Widget>[
              _numberField(
                controller: _areaController,
                label: _lifeText(context, zh: '住房面积 m²', en: 'Housing area m²'),
                suffixText: ' m²',
              ),
              _numberField(
                controller: _unitPriceController,
                label: _lifeText(context, zh: '单价', en: 'Unit price'),
                prefixText: '¥ ',
              ),
              _numberField(
                controller: _downPaymentAmountController,
                label: _lifeText(
                  context,
                  zh: '首付款金额（可选）',
                  en: 'Down payment amount (optional)',
                ),
                prefixText: '¥ ',
              ),
            ],
            _numberField(
              key: const ValueKey<String>('mortgage-rate'),
              controller: _rateController,
              label: _lifeText(context, zh: '贷款利率', en: 'Annual rate'),
              suffixText: '%',
            ),
            _numberField(
              key: const ValueKey<String>('mortgage-years'),
              controller: _yearsController,
              label: _lifeText(context, zh: '贷款年限', en: 'Loan term'),
              suffixText: _lifeText(context, zh: ' 年', en: ' years'),
              decimal: false,
            ),
            FilledButton.tonalIcon(
              onPressed: _pickFirstPaymentDate,
              icon: const Icon(Icons.event_rounded),
              label: Text(
                _lifeText(
                  context,
                  zh: '首次还款 ${_dateText(_firstPaymentDate)}',
                  en: 'First payment ${_dateText(_firstPaymentDate)}',
                ),
              ),
            ),
          ],
        ),
        if (_mode == MortgageCalculationMode.housingArea) ...<Widget>[
          const SizedBox(height: 14),
          _LifeSliderField(
            label: _lifeText(context, zh: '首付比例', en: 'Down payment ratio'),
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
      title: _lifeText(context, zh: '还款进度与费用', en: 'Progress and fees'),
      subtitle: _lifeText(
        context,
        zh: '用已还期数和提前还款模拟当前剩余贷款；月费和一次性费用会进入总费用统计。',
        en: 'Use paid periods and prepayment to estimate remaining debt. Monthly and upfront fees are included in cost totals.',
      ),
      children: <Widget>[
        _LifeSegmentedField<MortgageExtraPaymentStrategy>(
          label: _lifeText(context, zh: '提前还款处理', en: 'Prepayment handling'),
          value: _extraStrategy,
          options: const <_LifeOption<MortgageExtraPaymentStrategy>>[
            _LifeOption(
              value: MortgageExtraPaymentStrategy.reduceMonthlyPayment,
              labelZh: '月供降低',
              labelEn: 'Lower payment',
            ),
            _LifeOption(
              value: MortgageExtraPaymentStrategy.shortenTerm,
              labelZh: '期限缩短',
              labelEn: 'Shorten term',
            ),
          ],
          onChanged: (value) => setState(() => _extraStrategy = value),
        ),
        const SizedBox(height: 14),
        _WorkWorthFieldGrid(
          children: <Widget>[
            _numberField(
              controller: _paidMonthsController,
              label: _lifeText(
                context,
                zh: '已还期数${maxMonths > 0 ? ' / $maxMonths' : ''}',
                en: 'Paid periods${maxMonths > 0 ? ' / $maxMonths' : ''}',
              ),
              decimal: false,
            ),
            _numberField(
              controller: _extraPrincipalController,
              label: _lifeText(
                context,
                zh: '已提前还本金',
                en: 'Extra principal paid',
              ),
              prefixText: '¥ ',
            ),
            _numberField(
              controller: _monthlyFeeController,
              label: _lifeText(context, zh: '每月附加费用', en: 'Monthly fee'),
              prefixText: '¥ ',
            ),
            _numberField(
              controller: _oneTimeFeeController,
              label: _lifeText(context, zh: '一次性费用', en: 'One-time fee'),
              prefixText: '¥ ',
            ),
          ],
        ),
      ],
    );
  }

  Widget _detailPanel(BuildContext context, MortgageResult result) {
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '详细结果', en: 'Detailed result'),
      subtitle: _lifeText(
        context,
        zh: '这里把合同口径、已经还掉的部分、剩余成本和最终日期拆开展示。',
        en: 'Contract totals, paid progress, remaining cost, and final date are separated here.',
      ),
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            ToolboxMetricCard(
              label: _lifeText(context, zh: '首月月供', en: 'First payment'),
              value: _money(result.firstMonthlyPayment),
            ),
            ToolboxMetricCard(
              label: _lifeText(context, zh: '末月月供', en: 'Last payment'),
              value: _money(result.lastMonthlyPayment),
            ),
            ToolboxMetricCard(
              label: _lifeText(context, zh: '平均月供', en: 'Average payment'),
              value: _money(result.averageMonthlyPayment),
            ),
            ToolboxMetricCard(
              label: _lifeText(context, zh: '合同期限', en: 'Contract term'),
              value: _monthsText(context, result.totalMonths),
            ),
            ToolboxMetricCard(
              label: _lifeText(context, zh: '合同总费用', en: 'Contract cost'),
              value: _money(result.contractTotalCost),
            ),
            ToolboxMetricCard(
              label: _lifeText(context, zh: '剩余利息', en: 'Remaining interest'),
              value: _money(result.remainingInterest),
            ),
            ToolboxMetricCard(
              label: _lifeText(context, zh: '剩余总成本', en: 'Remaining cost'),
              value: _money(result.remainingTotalCost),
            ),
            ToolboxMetricCard(
              label: _lifeText(context, zh: '结清日期', en: 'Payoff date'),
              value: result.finalPaymentDate == null
                  ? _lifeText(context, zh: '已结清', en: 'Paid off')
                  : _dateText(result.finalPaymentDate!),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _breakdownRow(
          context,
          _lifeText(context, zh: '房屋总价', en: 'Property total'),
          result.propertyTotal <= 0
              ? _lifeText(context, zh: '未录入', en: 'Not set')
              : _money(result.propertyTotal),
        ),
        _breakdownRow(
          context,
          _lifeText(context, zh: '首付款', en: 'Down payment'),
          result.downPayment <= 0
              ? _lifeText(context, zh: '未计入', en: 'Not included')
              : _money(result.downPayment),
        ),
        _breakdownRow(
          context,
          _lifeText(context, zh: '已还本金', en: 'Principal paid'),
          _money(result.paidPrincipal),
        ),
        _breakdownRow(
          context,
          _lifeText(context, zh: '已还利息', en: 'Interest paid'),
          _money(result.paidInterest),
        ),
        _breakdownRow(
          context,
          _lifeText(context, zh: '已计费用', en: 'Fees paid'),
          _money(result.paidFees),
        ),
        _breakdownRow(
          context,
          _lifeText(context, zh: '提前还款抵扣本金', en: 'Extra principal applied'),
          _money(result.extraPrincipalApplied),
        ),
      ],
    );
  }

  Widget _schedulePanel(BuildContext context, MortgageResult result) {
    final schedule = result.remainingSchedule.take(12).toList(growable: false);
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '后续还款明细', en: 'Upcoming schedule'),
      subtitle: _lifeText(
        context,
        zh: '默认展示从下一期开始的前 12 期，等额本金会自然呈现逐月递减。',
        en: 'Shows the next 12 periods. Equal principal naturally decreases month by month.',
      ),
      children: <Widget>[
        if (schedule.isEmpty)
          Text(
            _lifeText(context, zh: '当前没有剩余还款。', en: 'No remaining payments.'),
          )
        else
          for (final payment in schedule)
            _MortgagePaymentTile(payment: payment, formatter: _money),
      ],
    );
  }

  Widget _riskPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '使用边界', en: 'Usage boundary'),
      subtitle: _lifeText(
        context,
        zh: '本工具用于本地估算和方案比较，不替代银行合同、征信审批、税费政策或提前还款违约金规则。',
        en: 'This tool is for local estimation and comparison only. It does not replace bank contracts, credit approval, tax policy, or prepayment penalty rules.',
      ),
      children: <Widget>[
        Text(
          _lifeText(
            context,
            zh: '公式按月复利和每月固定还款日测算；实际扣款可能受放款日、计息起点、LPR 调整、商贷/公积金组合、保险费、评估费和地区政策影响。',
            en: 'The formulas use monthly compounding and fixed due dates. Real payments may differ because of disbursement date, interest start date, LPR changes, mixed commercial/provident loans, insurance, appraisal fees, and local policy.',
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
      return _lifeText(context, zh: '0 个月', en: '0 months');
    }
    final years = months ~/ 12;
    final rest = months % 12;
    if (years == 0) {
      return _lifeText(context, zh: '$rest 个月', en: '$rest months');
    }
    if (rest == 0) {
      return _lifeText(context, zh: '$years 年', en: '$years years');
    }
    return _lifeText(
      context,
      zh: '$years 年 $rest 个月',
      en: '$years years $rest months',
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
                label: _lifeText(context, zh: '本金', en: 'Principal'),
                value: formatter(payment.principal),
              ),
              ToolboxMetricCard(
                label: _lifeText(context, zh: '利息', en: 'Interest'),
                value: formatter(payment.interest),
              ),
              ToolboxMetricCard(
                label: _lifeText(context, zh: '费用', en: 'Fee'),
                value: formatter(payment.fee),
              ),
              ToolboxMetricCard(
                label: _lifeText(context, zh: '剩余本金', en: 'Balance'),
                value: formatter(payment.remainingPrincipal),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
