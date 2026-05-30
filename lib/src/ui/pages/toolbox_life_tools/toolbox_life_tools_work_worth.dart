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
      title: _lifeI18nText(
        context,
        'inline.plan295.life.work_value_calculator.766dbe3047f2',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.a_work_value_assessment_combining_ho.4695d057b1e2',
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
      title: _lifeI18nText(
        context,
        'inline.plan295.life.income_and_costs.d2bf617045e2',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.estimate_real_monthly_surplus_then_f.5685c2154221',
      ),
      children: <Widget>[
        _WorkWorthFieldGrid(
          children: <Widget>[
            _moneyField(
              context,
              _monthlySalary,
              'life.work_worth.field.monthly_salary',
            ),
            _moneyField(
              context,
              _salaryMonths,
              'life.work_worth.field.salary_months',
            ),
            _moneyField(
              context,
              _annualBonus,
              'life.work_worth.field.annual_bonus',
            ),
            _moneyField(
              context,
              _monthlyBenefit,
              'life.work_worth.field.monthly_benefits',
            ),
            _moneyField(
              context,
              _monthlyOvertimePay,
              'life.work_worth.field.overtime_pay_month',
            ),
            _moneyField(
              context,
              _monthlyTax,
              'life.work_worth.field.monthly_tax',
            ),
            _moneyField(
              context,
              _insuranceFund,
              'life.work_worth.field.insurance_fund',
            ),
            _moneyField(
              context,
              _housingCost,
              'life.work_worth.field.housing_cost',
            ),
            _moneyField(
              context,
              _livingCost,
              'life.work_worth.field.living_cost',
            ),
            DropdownButtonFormField<String>(
              initialValue: _country,
              decoration: InputDecoration(
                labelText: _lifeI18nText(
                  context,
                  'inline.plan295.life.ppp_region.25efb6f4975b',
                ),
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
          label: _lifeI18nText(
            context,
            'inline.plan295.life.bonus_certainty.1157e6e932eb',
          ),
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
      title: _lifeI18nText(
        context,
        'inline.plan295.life.time_cost.d513fb2830b5',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.fewer_workdays_shorter_commute_and_r.c936196c1388',
      ),
      children: <Widget>[
        _WorkWorthFieldGrid(
          children: <Widget>[
            _numberField(
              context,
              _workDaysPerWeek,
              'life.work_worth.field.workdays_week',
            ),
            _numberField(
              context,
              _wfhDaysPerWeek,
              'life.work_worth.field.wfh_days_week',
            ),
            _numberField(
              context,
              _workHours,
              'life.work_worth.field.work_hours_day',
            ),
            _numberField(
              context,
              _commuteHours,
              'life.work_worth.field.commute_hours_day',
            ),
            _numberField(
              context,
              _restHours,
              'life.work_worth.field.rest_hours_day',
            ),
            _numberField(
              context,
              _unpaidOvertimeHours,
              'life.work_worth.field.unpaid_overtime_month',
            ),
            _numberField(
              context,
              _annualLeave,
              'life.work_worth.field.annual_leave',
            ),
            _numberField(
              context,
              _publicHolidays,
              'life.work_worth.field.public_holidays',
            ),
            _numberField(
              context,
              _paidSickLeave,
              'life.work_worth.field.paid_sick_leave',
            ),
          ],
        ),
      ],
    );
  }

  Widget _environmentPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.environment_and_context.d9acf4c1f1e0',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.these_affect_health_reserve_environm.2fbd524d030c',
      ),
      children: <Widget>[
        _LifeSegmentedField<WorkWorthEnvironment>(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.work_environment.f0cbd11a8ea6',
          ),
          value: _environment,
          options: const <_LifeOption<WorkWorthEnvironment>>[
            _LifeOption(
              value: WorkWorthEnvironment.lifeTrade,
              labelKey: 'inline.plan295.life.life_trade.64669d013a9d',
            ),
            _LifeOption(
              value: WorkWorthEnvironment.harmful,
              labelKey: 'inline.plan295.life.harmful.79cef6fb917c',
            ),
            _LifeOption(
              value: WorkWorthEnvironment.highPressure,
              labelKey: 'inline.plan295.life.high_pressure.0751ff04e768',
            ),
            _LifeOption(
              value: WorkWorthEnvironment.normal,
              labelKey: 'inline.plan295.life.normal.096e2aa2b20e',
            ),
            _LifeOption(
              value: WorkWorthEnvironment.balanced,
              labelKey: 'inline.plan295.life.balanced.9036d445b5c7',
            ),
            _LifeOption(
              value: WorkWorthEnvironment.freeComfort,
              labelKey: 'inline.plan295.life.free_comfort.2614933074c1',
            ),
          ],
          onChanged: (value) => setState(() => _environment = value),
        ),
        const SizedBox(height: 14),
        _LifeSliderField(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.city_factor.bebcbffac27a',
          ),
          valueText: _cityFactor.toStringAsFixed(2),
          value: _cityFactor,
          min: 0.7,
          max: 1.5,
          divisions: 8,
          onChanged: (value) => setState(() => _cityFactor = value),
        ),
        _LifeSliderField(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.leadership.ae08c6cda8f4',
          ),
          valueText: _leadershipFactor.toStringAsFixed(2),
          value: _leadershipFactor,
          min: 0.7,
          max: 1.3,
          divisions: 6,
          onChanged: (value) => setState(() => _leadershipFactor = value),
        ),
        _LifeSliderField(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.teamwork.0efdaa1a4633',
          ),
          valueText: _teamworkFactor.toStringAsFixed(2),
          value: _teamworkFactor,
          min: 0.8,
          max: 1.2,
          divisions: 4,
          onChanged: (value) => setState(() => _teamworkFactor = value),
        ),
        _LifeSliderField(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.growth_potential.88b829804ac5',
          ),
          valueText: _growthFactor.toStringAsFixed(2),
          value: _growthFactor,
          min: 0.8,
          max: 1.3,
          divisions: 5,
          onChanged: (value) => setState(() => _growthFactor = value),
        ),
        _LifeSliderField(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.boundary_quality.670aa3c5f776',
          ),
          valueText: _boundaryFactor.toStringAsFixed(2),
          value: _boundaryFactor,
          min: 0.7,
          max: 1.15,
          divisions: 9,
          onChanged: (value) => setState(() => _boundaryFactor = value),
        ),
        _LifeSliderField(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.psychological_safety.10a0bcbdc985',
          ),
          valueText: _psychologicalSafetyFactor.toStringAsFixed(2),
          value: _psychologicalSafetyFactor,
          min: 0.75,
          max: 1.2,
          divisions: 9,
          onChanged: (value) =>
              setState(() => _psychologicalSafetyFactor = value),
        ),
        _LifeSliderField(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.autonomy.a46fa9b788ab',
          ),
          valueText: _autonomyFactor.toStringAsFixed(2),
          value: _autonomyFactor,
          min: 0.85,
          max: 1.2,
          divisions: 7,
          onChanged: (value) => setState(() => _autonomyFactor = value),
        ),
        const SizedBox(height: 8),
        _LifeSegmentedField<WorkWorthJobStability>(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.job_stability.1f5a665df6e2',
          ),
          value: _stability,
          options: const <_LifeOption<WorkWorthJobStability>>[
            _LifeOption(
              value: WorkWorthJobStability.government,
              labelKey: 'inline.plan295.life.government.1682260d37fe',
            ),
            _LifeOption(
              value: WorkWorthJobStability.stateOwned,
              labelKey: 'inline.plan295.life.state_owned.ed86b04545aa',
            ),
            _LifeOption(
              value: WorkWorthJobStability.foreignCompany,
              labelKey: 'inline.plan295.life.foreign.e41f23231be2',
            ),
            _LifeOption(
              value: WorkWorthJobStability.privateCompany,
              labelKey: 'inline.plan295.life.private.ccfe9d14a5a2',
            ),
            _LifeOption(
              value: WorkWorthJobStability.dispatch,
              labelKey: 'inline.plan295.life.dispatch.ae175af20842',
            ),
            _LifeOption(
              value: WorkWorthJobStability.freelance,
              labelKey: 'inline.plan295.life.freelance.f782aea997c1',
            ),
          ],
          onChanged: (value) => setState(() => _stability = value),
        ),
        const SizedBox(height: 14),
        _numberField(context, _workYears, 'life.work_worth.field.work_years'),
        const SizedBox(height: 10),
        DropdownButtonFormField<WorkWorthEducation>(
          initialValue: _education,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: _lifeI18nText(
              context,
              'inline.plan295.life.education.5d1bfebdb214',
            ),
            border: const OutlineInputBorder(),
          ),
          items: <DropdownMenuItem<WorkWorthEducation>>[
            DropdownMenuItem(
              value: WorkWorthEducation.belowBachelor,
              child: Text(
                _lifeI18nText(
                  context,
                  'inline.plan295.life.below_bachelor.0594789fbfde',
                ),
              ),
            ),
            DropdownMenuItem(
              value: WorkWorthEducation.bachelor,
              child: Text(
                _lifeI18nText(
                  context,
                  'inline.plan295.life.bachelor.036cd0992772',
                ),
              ),
            ),
            DropdownMenuItem(
              value: WorkWorthEducation.master,
              child: Text(
                _lifeI18nText(
                  context,
                  'inline.plan295.life.master.d7f487b2dd00',
                ),
              ),
            ),
            DropdownMenuItem(
              value: WorkWorthEducation.phd,
              child: Text(
                _lifeI18nText(context, 'inline.plan295.life.phd.80c592fa8eea'),
              ),
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
            _lifeI18nText(
              context,
              'inline.plan295.life.shuttle_or_commute_relief.812be1f767ee',
            ),
          ),
          onChanged: (value) => setState(() => _hasShuttle = value),
        ),
        if (_hasShuttle)
          _LifeSliderField(
            label: _lifeI18nText(
              context,
              'inline.plan295.life.commute_multiplier.a0395287010a',
            ),
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
            _lifeI18nText(
              context,
              'inline.plan295.life.canteen_or_meal_benefit.64667bc7e6a0',
            ),
          ),
          onChanged: (value) => setState(() => _hasCanteen = value),
        ),
        if (_hasCanteen)
          _LifeSliderField(
            label: _lifeI18nText(
              context,
              'inline.plan295.life.meal_multiplier.5bbe1b824219',
            ),
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
      title: _lifeI18nText(
        context,
        'inline.plan295.life.formula_notes.50d7356750aa',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.use_the_score_to_compare_offers_not.4fba53d843a2',
      ),
      children: <Widget>[
        _WorkWorthBreakdownRow(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.workdays_year.168de532d1a2',
          ),
          value: '${result.workingDaysPerYear.toStringAsFixed(1)} d',
        ),
        _WorkWorthBreakdownRow(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.effective_commute_day.af728bd954d8',
          ),
          value: '${result.effectiveCommuteHours.toStringAsFixed(1)} h',
        ),
        _WorkWorthBreakdownRow(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.time_cost_day.784315e0a8df',
          ),
          value: '${result.effectiveTimeCostHours.toStringAsFixed(1)} h',
        ),
        _WorkWorthBreakdownRow(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.environment_factor.4830f8519133',
          ),
          value: result.environmentFactor.toStringAsFixed(2),
        ),
        _WorkWorthBreakdownRow(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.cashflow_factor.b4659c3bc197',
          ),
          value: result.costFactor.toStringAsFixed(2),
        ),
        _WorkWorthBreakdownRow(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.context_factor.05d823146a3c',
          ),
          value: result.contextFactor.toStringAsFixed(2),
        ),
        _WorkWorthBreakdownRow(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.expected_bonus.0cd0318d3511',
          ),
          value: _money(result.expectedAnnualBonus),
        ),
        _WorkWorthBreakdownRow(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.benefits_year.be09978e28a6',
          ),
          value: _money(result.annualBenefitValue),
        ),
        _WorkWorthBreakdownRow(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.overtime_pay_year.069d43b67739',
          ),
          value: _money(result.annualOvertimePay),
        ),
        const SizedBox(height: 10),
        Text(
          _lifeI18nText(
            context,
            'inline.plan295.life.core_formula_standardized_daily_inco.4fd49607e310',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _moneyField(
    BuildContext context,
    TextEditingController controller,
    String labelKey,
  ) {
    return _numberField(context, controller, labelKey, prefixText: '¥ ');
  }

  Widget _numberField(
    BuildContext context,
    TextEditingController controller,
    String labelKey, {
    String? prefixText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: _lifeI18nText(context, labelKey),
        prefixText: prefixText,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

Widget _referencePanel(BuildContext context) {
  return _LifeSettingsPanel(
    title: _lifeI18nText(
      context,
      'inline.plan295.life.reference_standards.12ad97b8f16d',
    ),
    subtitle: _lifeI18nText(
      context,
      'inline.plan295.life.these_are_calibration_hints_not_mand.5baa19b2a903',
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
                  _lifeI18nText(
                    context,
                    'inline.plan295.life.job_value_score.9feff7d90a06',
                  ),
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
              _lifeI18nText(context, result.rating.labelKey),
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
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.monthly_surplus.f916fcdabd72',
                ),
                value: _money(result.monthlyDisposableIncome),
              ),
              _WorkWorthMetricPill(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.ppp_daily.85d3b4e88be7',
                ),
                value: _money(result.standardizedDailyIncome),
              ),
              _WorkWorthMetricPill(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.health_reserve.d6773977782d',
                ),
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
                  _lifeI18nText(context, standard.titleKey),
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
            _lifeI18nText(context, standard.noteKey),
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
