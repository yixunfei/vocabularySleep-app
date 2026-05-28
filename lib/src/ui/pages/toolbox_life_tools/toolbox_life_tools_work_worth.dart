part of '../toolbox_life_tools.dart';

class _WorkWorthPage extends StatefulWidget {
  const _WorkWorthPage();

  @override
  State<_WorkWorthPage> createState() => _WorkWorthPageState();
}

class _WorkWorthPageState extends State<_WorkWorthPage> {
  final TextEditingController _monthlySalary = TextEditingController(
    text: '20000',
  );
  final TextEditingController _salaryMonths = TextEditingController(text: '13');
  final TextEditingController _annualBonus = TextEditingController(text: '0');
  final TextEditingController _monthlyBenefit = TextEditingController(
    text: '0',
  );
  final TextEditingController _monthlyOvertimePay = TextEditingController(
    text: '0',
  );
  final TextEditingController _monthlyTax = TextEditingController(text: '1200');
  final TextEditingController _insuranceFund = TextEditingController(
    text: '3500',
  );
  final TextEditingController _housingCost = TextEditingController(
    text: '4500',
  );
  final TextEditingController _livingCost = TextEditingController(text: '4500');
  final TextEditingController _workDaysPerWeek = TextEditingController(
    text: '5',
  );
  final TextEditingController _wfhDaysPerWeek = TextEditingController(
    text: '0',
  );
  final TextEditingController _annualLeave = TextEditingController(text: '5');
  final TextEditingController _publicHolidays = TextEditingController(
    text: '13',
  );
  final TextEditingController _paidSickLeave = TextEditingController(text: '3');
  final TextEditingController _workHours = TextEditingController(text: '10');
  final TextEditingController _commuteHours = TextEditingController(text: '2');
  final TextEditingController _restHours = TextEditingController(text: '2');
  final TextEditingController _unpaidOvertimeHours = TextEditingController(
    text: '0',
  );
  final TextEditingController _workYears = TextEditingController(text: '0');

  String _country = 'CN';
  double _bonusCertainty = 1.0;
  double _cityFactor = 1.0;
  double _leadershipFactor = 1.0;
  double _teamworkFactor = 1.0;
  double _growthFactor = 1.0;
  double _boundaryFactor = 1.0;
  double _psychologicalSafetyFactor = 1.0;
  double _autonomyFactor = 1.0;
  WorkWorthEnvironment _environment = WorkWorthEnvironment.normal;
  WorkWorthJobStability _stability = WorkWorthJobStability.privateCompany;
  WorkWorthEducation _education = WorkWorthEducation.bachelor;
  bool _hasShuttle = false;
  double _shuttleFactor = 1.0;
  bool _hasCanteen = false;
  double _canteenFactor = 1.0;

  final ToolboxWorkWorthService _service = ToolboxWorkWorthService();

  @override
  void dispose() {
    _monthlySalary.dispose();
    _salaryMonths.dispose();
    _annualBonus.dispose();
    _monthlyBenefit.dispose();
    _monthlyOvertimePay.dispose();
    _monthlyTax.dispose();
    _insuranceFund.dispose();
    _housingCost.dispose();
    _livingCost.dispose();
    _workDaysPerWeek.dispose();
    _wfhDaysPerWeek.dispose();
    _annualLeave.dispose();
    _publicHolidays.dispose();
    _paidSickLeave.dispose();
    _workHours.dispose();
    _commuteHours.dispose();
    _restHours.dispose();
    _unpaidOvertimeHours.dispose();
    _workYears.dispose();
    super.dispose();
  }

  WorkWorthResult get _result => _service.calculate(_input);

  WorkWorthInput get _input {
    return WorkWorthInput(
      monthlySalary: _number(_monthlySalary),
      salaryMonths: _number(_salaryMonths, fallback: 12),
      annualBonus: _number(_annualBonus),
      monthlyBenefitValue: _number(_monthlyBenefit),
      monthlyOvertimePay: _number(_monthlyOvertimePay),
      monthlyTax: _number(_monthlyTax),
      monthlyInsuranceFund: _number(_insuranceFund),
      monthlyHousingCost: _number(_housingCost),
      monthlyLivingCost: _number(_livingCost),
      workDaysPerWeek: _number(_workDaysPerWeek, fallback: 5),
      workFromHomeDaysPerWeek: _number(_wfhDaysPerWeek),
      annualLeaveDays: _number(_annualLeave),
      publicHolidayDays: _number(_publicHolidays),
      paidSickLeaveDays: _number(_paidSickLeave),
      workHoursPerDay: _number(_workHours, fallback: 8),
      commuteHoursPerDay: _number(_commuteHours),
      restHoursPerDay: _number(_restHours),
      unpaidOvertimeHoursPerMonth: _number(_unpaidOvertimeHours),
      pppFactor:
          ToolboxWorkWorthService.pppFactors[_country] ??
          ToolboxWorkWorthService.chinaPppFactor,
      cityFactor: _cityFactor,
      environment: _environment,
      leadershipFactor: _leadershipFactor,
      teamworkFactor: _teamworkFactor,
      annualBonusCertainty: _bonusCertainty,
      growthFactor: _growthFactor,
      boundaryFactor: _boundaryFactor,
      psychologicalSafetyFactor: _psychologicalSafetyFactor,
      autonomyFactor: _autonomyFactor,
      jobStability: _stability,
      education: _education,
      workYears: _number(_workYears),
      hasShuttle: _hasShuttle,
      shuttleFactor: _shuttleFactor,
      hasCanteen: _hasCanteen,
      canteenFactor: _canteenFactor,
    );
  }

  double _number(TextEditingController controller, {double fallback = 0}) {
    return double.tryParse(controller.text.trim()) ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return ToolboxToolPage(
      title: _lifeText(context, zh: '工作性价比计算器', en: 'Work value calculator'),
      subtitle: _lifeText(
        context,
        zh: '参考 worth-calculator 的工时与环境评估，并补入生活开销、五险一金和健康损耗。',
        en: 'Worth-calculator style score with living cost, deductions, and health load.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _WorkWorthStage(result: result),
          const SizedBox(height: 14),
          _incomePanel(context),
          const SizedBox(height: 12),
          _timePanel(context),
          const SizedBox(height: 12),
          _environmentPanel(context),
          const SizedBox(height: 12),
          _referencePanel(context),
          const SizedBox(height: 12),
          _explainPanel(context, result),
        ],
      ),
    );
  }

  Widget _incomePanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '收入、开销与扣款', en: 'Income and costs'),
      subtitle: _lifeText(
        context,
        zh: '先估算每月真实能留下多少钱，再把它放回工作分数里。',
        en: 'Estimate real monthly surplus, then feed it into the score.',
      ),
      children: <Widget>[
        _WorkWorthFieldGrid(
          children: <Widget>[
            _moneyField(context, _monthlySalary, '月薪税前', 'Monthly salary'),
            _moneyField(context, _salaryMonths, '薪资月数', 'Salary months'),
            _moneyField(context, _annualBonus, '年终/其他奖金', 'Annual bonus'),
            _moneyField(
              context,
              _monthlyBenefit,
              '福利现金值/月',
              'Monthly benefits',
            ),
            _moneyField(
              context,
              _monthlyOvertimePay,
              '加班补偿/月',
              'Overtime pay/month',
            ),
            _moneyField(context, _monthlyTax, '月税费', 'Monthly tax'),
            _moneyField(
              context,
              _insuranceFund,
              '五险一金/月',
              'Insurance and fund',
            ),
            _moneyField(context, _housingCost, '房租房贷/月', 'Housing cost'),
            _moneyField(context, _livingCost, '生活开销/月', 'Living cost'),
            DropdownButtonFormField<String>(
              initialValue: _country,
              decoration: InputDecoration(
                labelText: _lifeText(context, zh: 'PPP 地区', en: 'PPP region'),
                border: const OutlineInputBorder(),
              ),
              items: const <DropdownMenuItem<String>>[
                DropdownMenuItem(value: 'CN', child: Text('CN')),
                DropdownMenuItem(value: 'US', child: Text('US')),
                DropdownMenuItem(value: 'JP', child: Text('JP')),
                DropdownMenuItem(value: 'SG', child: Text('SG')),
                DropdownMenuItem(value: 'HK', child: Text('HK')),
                DropdownMenuItem(value: 'GB', child: Text('GB')),
                DropdownMenuItem(value: 'DE', child: Text('DE')),
              ],
              onChanged: (value) => setState(() => _country = value ?? 'CN'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _LifeSliderField(
          label: _lifeText(context, zh: '奖金确定性', en: 'Bonus certainty'),
          valueText: '${(_bonusCertainty * 100).round()}%',
          value: _bonusCertainty,
          min: 0,
          max: 1,
          divisions: 10,
          onChanged: (value) => setState(() => _bonusCertainty = value),
        ),
      ],
    );
  }

  Widget _timePanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '时间成本', en: 'Time cost'),
      subtitle: _lifeText(
        context,
        zh: '工作日越少、通勤越短、休息越可恢复，分母越轻。',
        en: 'Fewer workdays, shorter commute, and recoverable breaks reduce the denominator.',
      ),
      children: <Widget>[
        _WorkWorthFieldGrid(
          children: <Widget>[
            _numberField(context, _workDaysPerWeek, '每周工作天', 'Workdays/week'),
            _numberField(context, _wfhDaysPerWeek, '每周居家天', 'WFH days/week'),
            _numberField(context, _workHours, '日工作小时', 'Work hours/day'),
            _numberField(context, _commuteHours, '日通勤小时', 'Commute hours/day'),
            _numberField(context, _restHours, '可恢复休息小时', 'Rest hours/day'),
            _numberField(
              context,
              _unpaidOvertimeHours,
              '无偿加班/月',
              'Unpaid overtime/month',
            ),
            _numberField(context, _annualLeave, '年假天数', 'Annual leave'),
            _numberField(context, _publicHolidays, '公共假期', 'Public holidays'),
            _numberField(context, _paidSickLeave, '带薪病假', 'Paid sick leave'),
          ],
        ),
      ],
    );
  }

  Widget _environmentPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '环境、稳定性与背景', en: 'Environment and context'),
      subtitle: _lifeText(
        context,
        zh: '这里会影响健康损耗、环境加成，以及不同经验阶段的薪资预期。',
        en: 'These affect health reserve, environment multiplier, and career-stage expectation.',
      ),
      children: <Widget>[
        _LifeSegmentedField<WorkWorthEnvironment>(
          label: _lifeText(context, zh: '工作环境健康层级', en: 'Work environment'),
          value: _environment,
          options: const <_LifeOption<WorkWorthEnvironment>>[
            _LifeOption(
              value: WorkWorthEnvironment.lifeTrade,
              labelZh: '拿命换',
              labelEn: 'Life trade',
            ),
            _LifeOption(
              value: WorkWorthEnvironment.harmful,
              labelZh: '有害健康',
              labelEn: 'Harmful',
            ),
            _LifeOption(
              value: WorkWorthEnvironment.highPressure,
              labelZh: '高压消耗',
              labelEn: 'High pressure',
            ),
            _LifeOption(
              value: WorkWorthEnvironment.normal,
              labelZh: '普通办公',
              labelEn: 'Normal',
            ),
            _LifeOption(
              value: WorkWorthEnvironment.balanced,
              labelZh: '平衡友好',
              labelEn: 'Balanced',
            ),
            _LifeOption(
              value: WorkWorthEnvironment.freeComfort,
              labelZh: '自由舒适',
              labelEn: 'Free comfort',
            ),
          ],
          onChanged: (value) => setState(() => _environment = value),
        ),
        const SizedBox(height: 14),
        _LifeSliderField(
          label: _lifeText(context, zh: '城市成本系数', en: 'City factor'),
          valueText: _cityFactor.toStringAsFixed(2),
          value: _cityFactor,
          min: 0.7,
          max: 1.5,
          divisions: 8,
          onChanged: (value) => setState(() => _cityFactor = value),
        ),
        _LifeSliderField(
          label: _lifeText(context, zh: '领导/管理体验', en: 'Leadership'),
          valueText: _leadershipFactor.toStringAsFixed(2),
          value: _leadershipFactor,
          min: 0.7,
          max: 1.3,
          divisions: 6,
          onChanged: (value) => setState(() => _leadershipFactor = value),
        ),
        _LifeSliderField(
          label: _lifeText(context, zh: '团队协作体验', en: 'Teamwork'),
          valueText: _teamworkFactor.toStringAsFixed(2),
          value: _teamworkFactor,
          min: 0.8,
          max: 1.2,
          divisions: 4,
          onChanged: (value) => setState(() => _teamworkFactor = value),
        ),
        _LifeSliderField(
          label: _lifeText(context, zh: '成长性/技能复利', en: 'Growth potential'),
          valueText: _growthFactor.toStringAsFixed(2),
          value: _growthFactor,
          min: 0.8,
          max: 1.3,
          divisions: 5,
          onChanged: (value) => setState(() => _growthFactor = value),
        ),
        _LifeSliderField(
          label: _lifeText(context, zh: '下班边界/待命压力', en: 'Boundary quality'),
          valueText: _boundaryFactor.toStringAsFixed(2),
          value: _boundaryFactor,
          min: 0.7,
          max: 1.15,
          divisions: 9,
          onChanged: (value) => setState(() => _boundaryFactor = value),
        ),
        _LifeSliderField(
          label: _lifeText(context, zh: '心理安全感', en: 'Psychological safety'),
          valueText: _psychologicalSafetyFactor.toStringAsFixed(2),
          value: _psychologicalSafetyFactor,
          min: 0.75,
          max: 1.2,
          divisions: 9,
          onChanged: (value) =>
              setState(() => _psychologicalSafetyFactor = value),
        ),
        _LifeSliderField(
          label: _lifeText(context, zh: '自主权/灵活度', en: 'Autonomy'),
          valueText: _autonomyFactor.toStringAsFixed(2),
          value: _autonomyFactor,
          min: 0.85,
          max: 1.2,
          divisions: 7,
          onChanged: (value) => setState(() => _autonomyFactor = value),
        ),
        const SizedBox(height: 8),
        _LifeSegmentedField<WorkWorthJobStability>(
          label: _lifeText(context, zh: '工作类型/稳定性', en: 'Job stability'),
          value: _stability,
          options: const <_LifeOption<WorkWorthJobStability>>[
            _LifeOption(
              value: WorkWorthJobStability.government,
              labelZh: '体制内',
              labelEn: 'Government',
            ),
            _LifeOption(
              value: WorkWorthJobStability.stateOwned,
              labelZh: '国企',
              labelEn: 'State owned',
            ),
            _LifeOption(
              value: WorkWorthJobStability.foreignCompany,
              labelZh: '外企',
              labelEn: 'Foreign',
            ),
            _LifeOption(
              value: WorkWorthJobStability.privateCompany,
              labelZh: '私企',
              labelEn: 'Private',
            ),
            _LifeOption(
              value: WorkWorthJobStability.dispatch,
              labelZh: '外包派遣',
              labelEn: 'Dispatch',
            ),
            _LifeOption(
              value: WorkWorthJobStability.freelance,
              labelZh: '自由职业',
              labelEn: 'Freelance',
            ),
          ],
          onChanged: (value) => setState(() => _stability = value),
        ),
        const SizedBox(height: 14),
        _numberField(context, _workYears, '工作年限', 'Work years'),
        const SizedBox(height: 10),
        DropdownButtonFormField<WorkWorthEducation>(
          initialValue: _education,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: _lifeText(context, zh: '学历背景', en: 'Education'),
            border: const OutlineInputBorder(),
          ),
          items: <DropdownMenuItem<WorkWorthEducation>>[
            DropdownMenuItem(
              value: WorkWorthEducation.belowBachelor,
              child: Text(_lifeText(context, zh: '本科以下', en: 'Below bachelor')),
            ),
            DropdownMenuItem(
              value: WorkWorthEducation.bachelor,
              child: Text(_lifeText(context, zh: '本科', en: 'Bachelor')),
            ),
            DropdownMenuItem(
              value: WorkWorthEducation.master,
              child: Text(_lifeText(context, zh: '硕士', en: 'Master')),
            ),
            DropdownMenuItem(
              value: WorkWorthEducation.phd,
              child: Text(_lifeText(context, zh: '博士', en: 'PhD')),
            ),
          ],
          onChanged: (value) =>
              setState(() => _education = value ?? WorkWorthEducation.bachelor),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          value: _hasShuttle,
          contentPadding: EdgeInsets.zero,
          title: Text(
            _lifeText(context, zh: '有班车/通勤减压', en: 'Shuttle or commute relief'),
          ),
          onChanged: (value) => setState(() => _hasShuttle = value),
        ),
        if (_hasShuttle)
          _LifeSliderField(
            label: _lifeText(context, zh: '通勤折减系数', en: 'Commute multiplier'),
            valueText: _shuttleFactor.toStringAsFixed(2),
            value: _shuttleFactor,
            min: 0.5,
            max: 1.0,
            divisions: 5,
            onChanged: (value) => setState(() => _shuttleFactor = value),
          ),
        SwitchListTile(
          value: _hasCanteen,
          contentPadding: EdgeInsets.zero,
          title: Text(
            _lifeText(context, zh: '食堂/餐补体验加成', en: 'Canteen or meal benefit'),
          ),
          onChanged: (value) => setState(() => _hasCanteen = value),
        ),
        if (_hasCanteen)
          _LifeSliderField(
            label: _lifeText(context, zh: '餐食体验系数', en: 'Meal multiplier'),
            valueText: _canteenFactor.toStringAsFixed(2),
            value: _canteenFactor,
            min: 1.0,
            max: 1.15,
            divisions: 3,
            onChanged: (value) => setState(() => _canteenFactor = value),
          ),
      ],
    );
  }

  Widget _explainPanel(BuildContext context, WorkWorthResult result) {
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '口径说明', en: 'Formula notes'),
      subtitle: _lifeText(
        context,
        zh: '分数适合横向比较 offer，不是财务、医疗或职业建议。',
        en: 'Use the score to compare offers, not as financial, medical, or career advice.',
      ),
      children: <Widget>[
        _WorkWorthBreakdownRow(
          label: _lifeText(context, zh: '工作日/年', en: 'Workdays/year'),
          value: '${result.workingDaysPerYear.toStringAsFixed(1)} d',
        ),
        _WorkWorthBreakdownRow(
          label: _lifeText(context, zh: '有效通勤/天', en: 'Effective commute/day'),
          value: '${result.effectiveCommuteHours.toStringAsFixed(1)} h',
        ),
        _WorkWorthBreakdownRow(
          label: _lifeText(context, zh: '时间成本/天', en: 'Time cost/day'),
          value: '${result.effectiveTimeCostHours.toStringAsFixed(1)} h',
        ),
        _WorkWorthBreakdownRow(
          label: _lifeText(context, zh: '环境综合系数', en: 'Environment factor'),
          value: result.environmentFactor.toStringAsFixed(2),
        ),
        _WorkWorthBreakdownRow(
          label: _lifeText(context, zh: '生活现金系数', en: 'Cashflow factor'),
          value: result.costFactor.toStringAsFixed(2),
        ),
        _WorkWorthBreakdownRow(
          label: _lifeText(context, zh: '成长/边界综合', en: 'Context factor'),
          value: result.contextFactor.toStringAsFixed(2),
        ),
        _WorkWorthBreakdownRow(
          label: _lifeText(context, zh: '期望年终奖', en: 'Expected bonus'),
          value: _money(result.expectedAnnualBonus),
        ),
        _WorkWorthBreakdownRow(
          label: _lifeText(context, zh: '福利现金值/年', en: 'Benefits/year'),
          value: _money(result.annualBenefitValue),
        ),
        _WorkWorthBreakdownRow(
          label: _lifeText(context, zh: '加班补偿/年', en: 'Overtime pay/year'),
          value: _money(result.annualOvertimePay),
        ),
        const SizedBox(height: 10),
        Text(
          _lifeText(
            context,
            zh: '核心口径：标准化日薪 × 环境系数 × 生活现金系数 ÷（35 × 时间成本 × 学历/经验预期）。健康层级会额外估算每月健康损耗预算。',
            en: 'Core formula: standardized daily income x environment x cashflow factor / (35 x time cost x education/career expectation). Health tier also reserves monthly health load.',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _moneyField(
    BuildContext context,
    TextEditingController controller,
    String zh,
    String en,
  ) {
    return _numberField(context, controller, zh, en, prefixText: '¥ ');
  }

  Widget _numberField(
    BuildContext context,
    TextEditingController controller,
    String zh,
    String en, {
    String? prefixText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: _lifeText(context, zh: zh, en: en),
        prefixText: prefixText,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

Widget _referencePanel(BuildContext context) {
  return _LifeSettingsPanel(
    title: _lifeText(context, zh: '参考标准值', en: 'Reference standards'),
    subtitle: _lifeText(
      context,
      zh: '这些值不是强制标准，只是帮助你快速校准输入。',
      en: 'These are calibration hints, not mandatory standards.',
    ),
    children: <Widget>[
      for (final standard in ToolboxWorkWorthService.referenceStandards)
        _WorkWorthReferenceTile(standard: standard),
    ],
  );
}

class _WorkWorthStage extends StatelessWidget {
  const _WorkWorthStage({required this.result});

  final WorkWorthResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreColor = _scoreColor(result.valueScore);
    return Container(
      key: const ValueKey<String>('work-worth-stage'),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            const Color(0xFF14342F).withValues(alpha: 0.94),
            const Color(0xFF335C47).withValues(alpha: 0.90),
            const Color(0xFFB9823A).withValues(alpha: 0.72),
          ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF14342F).withValues(alpha: 0.22),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  _lifeText(context, zh: '综合价值分', en: 'Job value score'),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                Icons.work_history_rounded,
                color: Colors.white.withValues(alpha: 0.78),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            result.valueScore.toStringAsFixed(2),
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: scoreColor.withValues(alpha: 0.45)),
            ),
            child: Text(
              _lifeText(context, zh: result.rating.zh, en: result.rating.en),
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _WorkWorthMetricPill(
                label: _lifeText(context, zh: '月可支配', en: 'Monthly surplus'),
                value: _money(result.monthlyDisposableIncome),
              ),
              _WorkWorthMetricPill(
                label: _lifeText(context, zh: '标准化日薪', en: 'PPP daily'),
                value: _money(result.standardizedDailyIncome),
              ),
              _WorkWorthMetricPill(
                label: _lifeText(context, zh: '健康损耗/月', en: 'Health reserve'),
                value: _money(result.monthlyHealthReserve),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Color _scoreColor(double score) {
    if (score < 0.6) {
      return const Color(0xFFE67B90);
    }
    if (score < 1.0) {
      return const Color(0xFFE99A52);
    }
    if (score <= 1.8) {
      return const Color(0xFFF0C96A);
    }
    if (score <= 2.5) {
      return const Color(0xFF88C7A6);
    }
    return const Color(0xFF8FD8D2);
  }
}

class _WorkWorthMetricPill extends StatelessWidget {
  const _WorkWorthMetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 132),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkWorthFieldGrid extends StatelessWidget {
  const _WorkWorthFieldGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 520 ? 2 : 1;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: children
              .map(
                (child) => SizedBox(
                  width: (constraints.maxWidth - (columns - 1) * 10) / columns,
                  child: child,
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _WorkWorthBreakdownRow extends StatelessWidget {
  const _WorkWorthBreakdownRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkWorthReferenceTile extends StatelessWidget {
  const _WorkWorthReferenceTile({required this.standard});

  final WorkWorthReferenceStandard standard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.55,
        ),
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
                  _lifeText(context, zh: standard.zh, en: standard.en),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                standard.value,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _lifeText(context, zh: standard.noteZh, en: standard.noteEn),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

String _money(double value) {
  final sign = value < 0 ? '-' : '';
  return '$sign¥${value.abs().toStringAsFixed(0)}';
}
