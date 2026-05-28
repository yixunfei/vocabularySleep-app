part of '../toolbox_life_tools.dart';

class _CitySalaryComparePage extends StatefulWidget {
  const _CitySalaryComparePage();

  @override
  State<_CitySalaryComparePage> createState() => _CitySalaryComparePageState();
}

class _CitySalaryComparePageState extends State<_CitySalaryComparePage> {
  final ToolboxCityCompareService _service = ToolboxCityCompareService();
  final TextEditingController _salaryController = TextEditingController(
    text: '22000',
  );
  final TextEditingController _customExpenseLabelController =
      TextEditingController();
  final TextEditingController _customExpenseAmountController =
      TextEditingController(text: '500');
  final TextEditingController _fitnessOverrideController =
      TextEditingController();
  final TextEditingController _cinemaOverrideController =
      TextEditingController();

  String _currentCity = ToolboxCityCompareService.cities.first.city;
  String _targetCity = ToolboxCityCompareService.cities[2].city;
  CityCompareHousingType _housingType = CityCompareHousingType.suburbOneBedroom;
  CityCompareDiningType _diningType = CityCompareDiningType.balanced;
  CityCompareTransportType _transportType =
      CityCompareTransportType.publicTransit;
  CityCompareEducationType _educationType = CityCompareEducationType.none;
  bool _includeFitness = false;
  double _monthlyCinemaTrips = 2;
  double _housingAdjustment = 1;
  double _diningAdjustment = 1;
  double _transportAdjustment = 1;
  double _educationAdjustment = 1;
  double _utilitiesAdjustment = 1;
  double _fitnessAdjustment = 1;
  double _leisureAdjustment = 1;
  CityCompareCustomExpenseCategory _customExpenseCategory =
      CityCompareCustomExpenseCategory.lifestyle;
  final List<CityCompareCustomExpense> _customExpenses =
      <CityCompareCustomExpense>[];

  @override
  void dispose() {
    _salaryController.dispose();
    _customExpenseLabelController.dispose();
    _customExpenseAmountController.dispose();
    _fitnessOverrideController.dispose();
    _cinemaOverrideController.dispose();
    super.dispose();
  }

  CityCompareProfile get _profile => CityCompareProfile(
    housingType: _housingType,
    diningType: _diningType,
    transportType: _transportType,
    educationType: _educationType,
    includeFitness: _includeFitness,
    monthlyCinemaTrips: _monthlyCinemaTrips.round(),
    housingAdjustment: _housingAdjustment,
    diningAdjustment: _diningAdjustment,
    transportAdjustment: _transportAdjustment,
    educationAdjustment: _educationAdjustment,
    utilitiesAdjustment: _utilitiesAdjustment,
    fitnessAdjustment: _fitnessAdjustment,
    leisureAdjustment: _leisureAdjustment,
    fitnessOverride: _optionalNumber(_fitnessOverrideController),
    cinemaTicketOverride: _optionalNumber(_cinemaOverrideController),
    customExpenses: List<CityCompareCustomExpense>.unmodifiable(
      _customExpenses,
    ),
  );

  CityCompareResult get _result => _service.compare(
    currentCityName: _currentCity,
    targetCityName: _targetCity,
    currentGrossMonthlySalary: _salaryValue,
    profile: _profile,
  );

  double get _salaryValue =>
      double.tryParse(_salaryController.text.trim()) ?? 0;

  double? _optionalNumber(TextEditingController controller) {
    final text = controller.text.trim();
    if (text.isEmpty) {
      return null;
    }
    return double.tryParse(text);
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return ToolboxToolPage(
      title: _lifeText(context, zh: '城市薪资对比工具', en: 'City salary compare'),
      subtitle: _lifeText(
        context,
        zh: '参考 city_compare 的城市成本口径，在本地估算同等生活方式下的薪资换算与结余变化。',
        en: 'Compare city costs locally and estimate equivalent salary for the same lifestyle.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _CityCompareHero(result: result),
          const SizedBox(height: 14),
          _setupPanel(context),
          const SizedBox(height: 12),
          _profilePanel(context),
          const SizedBox(height: 12),
          _adjustmentPanel(context),
          const SizedBox(height: 12),
          _comparisonPanel(context, result),
          const SizedBox(height: 12),
          _insightPanel(context, result),
          const SizedBox(height: 12),
          _referencePanel(context, result),
          const SizedBox(height: 12),
          _notesPanel(context, result),
        ],
      ),
    );
  }

  Widget _setupPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '城市与薪资输入', en: 'Cities and salary'),
      subtitle: _lifeText(
        context,
        zh: '先选当前城市、目标城市和你手里的月薪税前，再看迁移后的结余变化。',
        en: 'Pick the current city, target city, and your gross monthly salary first.',
      ),
      children: <Widget>[
        _WorkWorthFieldGrid(
          children: <Widget>[
            DropdownButtonFormField<String>(
              initialValue: _currentCity,
              decoration: InputDecoration(
                labelText: _lifeText(context, zh: '当前城市', en: 'Current city'),
                border: const OutlineInputBorder(),
              ),
              items: ToolboxCityCompareService.cities
                  .map(
                    (city) => DropdownMenuItem<String>(
                      value: city.city,
                      child: Text(city.city),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) =>
                  setState(() => _currentCity = value ?? _currentCity),
            ),
            DropdownButtonFormField<String>(
              initialValue: _targetCity,
              decoration: InputDecoration(
                labelText: _lifeText(context, zh: '目标城市', en: 'Target city'),
                border: const OutlineInputBorder(),
              ),
              items: ToolboxCityCompareService.cities
                  .map(
                    (city) => DropdownMenuItem<String>(
                      value: city.city,
                      child: Text(city.city),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) =>
                  setState(() => _targetCity = value ?? _targetCity),
            ),
            TextField(
              key: const ValueKey<String>('city-compare-salary-field'),
              controller: _salaryController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: _lifeText(
                  context,
                  zh: '当前月薪税前',
                  en: 'Gross monthly salary',
                ),
                prefixText: '¥ ',
                border: const OutlineInputBorder(),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: () {
                setState(() {
                  final previous = _currentCity;
                  _currentCity = _targetCity;
                  _targetCity = previous;
                });
              },
              icon: const Icon(Icons.swap_horiz_rounded),
              label: Text(_lifeText(context, zh: '交换城市', en: 'Swap cities')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _profilePanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '生活方式配置', en: 'Lifestyle profile'),
      subtitle: _lifeText(
        context,
        zh: '这里决定了“同等生活水平”的口径：住哪种房、怎么吃、怎么通勤、有没有教育与娱乐支出。',
        en: 'This defines what “same lifestyle” means in the comparison.',
      ),
      children: <Widget>[
        _LifeSegmentedField<CityCompareHousingType>(
          label: _lifeText(context, zh: '住房方案', en: 'Housing'),
          value: _housingType,
          options: const <_LifeOption<CityCompareHousingType>>[
            _LifeOption(
              value: CityCompareHousingType.suburbOneBedroom,
              labelZh: '郊区一居',
              labelEn: 'Suburb 1BR',
            ),
            _LifeOption(
              value: CityCompareHousingType.centerOneBedroom,
              labelZh: '市中心一居',
              labelEn: 'Center 1BR',
            ),
            _LifeOption(
              value: CityCompareHousingType.suburbThreeBedroom,
              labelZh: '郊区三居',
              labelEn: 'Suburb 3BR',
            ),
            _LifeOption(
              value: CityCompareHousingType.centerThreeBedroom,
              labelZh: '市中心三居',
              labelEn: 'Center 3BR',
            ),
          ],
          onChanged: (value) => setState(() => _housingType = value),
        ),
        const SizedBox(height: 14),
        _LifeSegmentedField<CityCompareDiningType>(
          label: _lifeText(context, zh: '餐饮习惯', en: 'Dining'),
          value: _diningType,
          options: const <_LifeOption<CityCompareDiningType>>[
            _LifeOption(
              value: CityCompareDiningType.homeFocused,
              labelZh: '在家为主',
              labelEn: 'Mostly home',
            ),
            _LifeOption(
              value: CityCompareDiningType.balanced,
              labelZh: '均衡',
              labelEn: 'Balanced',
            ),
            _LifeOption(
              value: CityCompareDiningType.dineOutOften,
              labelZh: '常外食',
              labelEn: 'Often dine out',
            ),
          ],
          onChanged: (value) => setState(() => _diningType = value),
        ),
        const SizedBox(height: 14),
        _LifeSegmentedField<CityCompareTransportType>(
          label: _lifeText(context, zh: '通勤方式', en: 'Transport'),
          value: _transportType,
          options: const <_LifeOption<CityCompareTransportType>>[
            _LifeOption(
              value: CityCompareTransportType.publicTransit,
              labelZh: '公共交通',
              labelEn: 'Transit',
            ),
            _LifeOption(
              value: CityCompareTransportType.car,
              labelZh: '私家车',
              labelEn: 'Car',
            ),
          ],
          onChanged: (value) => setState(() => _transportType = value),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<CityCompareEducationType>(
          initialValue: _educationType,
          decoration: InputDecoration(
            labelText: _lifeText(context, zh: '教育支出', en: 'Education cost'),
            border: const OutlineInputBorder(),
          ),
          items: <DropdownMenuItem<CityCompareEducationType>>[
            DropdownMenuItem(
              value: CityCompareEducationType.none,
              child: Text(_lifeText(context, zh: '无', en: 'None')),
            ),
            DropdownMenuItem(
              value: CityCompareEducationType.kindergarten,
              child: Text(_lifeText(context, zh: '幼儿园', en: 'Kindergarten')),
            ),
            DropdownMenuItem(
              value: CityCompareEducationType.primary,
              child: Text(_lifeText(context, zh: '小学', en: 'Primary')),
            ),
            DropdownMenuItem(
              value: CityCompareEducationType.middle,
              child: Text(_lifeText(context, zh: '初中', en: 'Middle')),
            ),
            DropdownMenuItem(
              value: CityCompareEducationType.high,
              child: Text(_lifeText(context, zh: '高中', en: 'High school')),
            ),
            DropdownMenuItem(
              value: CityCompareEducationType.international,
              child: Text(_lifeText(context, zh: '国际学校', en: 'International')),
            ),
          ],
          onChanged: (value) => setState(
            () => _educationType = value ?? CityCompareEducationType.none,
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          value: _includeFitness,
          contentPadding: EdgeInsets.zero,
          title: Text(_lifeText(context, zh: '包含健身支出', en: 'Include fitness')),
          onChanged: (value) => setState(() => _includeFitness = value),
        ),
        _LifeSliderField(
          label: _lifeText(context, zh: '每月观影次数', en: 'Cinema trips / month'),
          valueText: _monthlyCinemaTrips.round().toString(),
          value: _monthlyCinemaTrips,
          min: 0,
          max: 8,
          divisions: 8,
          onChanged: (value) => setState(() => _monthlyCinemaTrips = value),
        ),
      ],
    );
  }

  Widget _comparisonPanel(BuildContext context, CityCompareResult result) {
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '双城拆解', en: 'Comparison breakdown'),
      subtitle: _lifeText(
        context,
        zh: '同一套生活方式下，看当前城市、目标城市同薪资，以及目标城市维持同等结余三种结果。',
        en: 'See current city, same salary in target city, and the salary needed to keep the same buffer.',
      ),
      children: <Widget>[
        _CityCompareScenarioCard(
          title: _lifeText(context, zh: '当前城市现状', en: 'Current city now'),
          cityName: result.currentCity.city,
          snapshot: result.currentSnapshot,
          breakdown: result.currentBreakdown,
        ),
        const SizedBox(height: 12),
        _CityCompareScenarioCard(
          title: _lifeText(
            context,
            zh: '同薪资搬去目标城市',
            en: 'Same salary in target city',
          ),
          cityName: result.targetCity.city,
          snapshot: result.sameSalaryTargetSnapshot,
          breakdown: result.targetBreakdown,
        ),
        const SizedBox(height: 12),
        _CityCompareScenarioCard(
          key: const ValueKey<String>('city-compare-required-card'),
          title: _lifeText(
            context,
            zh: '保持同等结余所需薪资',
            en: 'Target salary to match',
          ),
          cityName: result.targetCity.city,
          snapshot: result.requiredTargetSnapshot,
          breakdown: result.targetBreakdown,
          highlight: true,
        ),
      ],
    );
  }

  Widget _adjustmentPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeText(
        context,
        zh: '费用微调与自定义支出',
        en: 'Adjustments and custom expenses',
      ),
      subtitle: _lifeText(
        context,
        zh: '如果你觉得预设基准不够贴近自己，可以按类别微调，也可以直接新增固定月支出。',
        en: 'Fine-tune baseline costs by category or add your own fixed monthly expenses.',
      ),
      children: <Widget>[
        _LifeSliderField(
          label: _lifeText(context, zh: '住房倍率', en: 'Housing multiplier'),
          valueText: _housingAdjustment.toStringAsFixed(2),
          value: _housingAdjustment,
          min: 0.5,
          max: 1.8,
          divisions: 13,
          onChanged: (value) => setState(() => _housingAdjustment = value),
        ),
        _LifeSliderField(
          label: _lifeText(context, zh: '餐饮倍率', en: 'Dining multiplier'),
          valueText: _diningAdjustment.toStringAsFixed(2),
          value: _diningAdjustment,
          min: 0.5,
          max: 1.8,
          divisions: 13,
          onChanged: (value) => setState(() => _diningAdjustment = value),
        ),
        _LifeSliderField(
          label: _lifeText(context, zh: '交通倍率', en: 'Transport multiplier'),
          valueText: _transportAdjustment.toStringAsFixed(2),
          value: _transportAdjustment,
          min: 0.5,
          max: 1.8,
          divisions: 13,
          onChanged: (value) => setState(() => _transportAdjustment = value),
        ),
        _LifeSliderField(
          label: _lifeText(context, zh: '教育倍率', en: 'Education multiplier'),
          valueText: _educationAdjustment.toStringAsFixed(2),
          value: _educationAdjustment,
          min: 0.5,
          max: 1.8,
          divisions: 13,
          onChanged: (value) => setState(() => _educationAdjustment = value),
        ),
        _LifeSliderField(
          label: _lifeText(context, zh: '水电网话倍率', en: 'Utility multiplier'),
          valueText: _utilitiesAdjustment.toStringAsFixed(2),
          value: _utilitiesAdjustment,
          min: 0.5,
          max: 1.8,
          divisions: 13,
          onChanged: (value) => setState(() => _utilitiesAdjustment = value),
        ),
        _LifeSliderField(
          label: _lifeText(context, zh: '健身倍率', en: 'Fitness multiplier'),
          valueText: _fitnessAdjustment.toStringAsFixed(2),
          value: _fitnessAdjustment,
          min: 0.5,
          max: 2.0,
          divisions: 15,
          onChanged: (value) => setState(() => _fitnessAdjustment = value),
        ),
        _LifeSliderField(
          label: _lifeText(context, zh: '娱乐倍率', en: 'Leisure multiplier'),
          valueText: _leisureAdjustment.toStringAsFixed(2),
          value: _leisureAdjustment,
          min: 0.5,
          max: 2.0,
          divisions: 15,
          onChanged: (value) => setState(() => _leisureAdjustment = value),
        ),
        const SizedBox(height: 10),
        _WorkWorthFieldGrid(
          children: <Widget>[
            TextField(
              controller: _fitnessOverrideController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: _lifeText(
                  context,
                  zh: '健身月费覆写',
                  en: 'Fitness override',
                ),
                prefixText: '¥ ',
                border: const OutlineInputBorder(),
              ),
            ),
            TextField(
              controller: _cinemaOverrideController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: _lifeText(
                  context,
                  zh: '电影票单价覆写',
                  en: 'Cinema ticket override',
                ),
                prefixText: '¥ ',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          _lifeText(context, zh: '自定义月支出', en: 'Custom monthly expenses'),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        _WorkWorthFieldGrid(
          children: <Widget>[
            TextField(
              key: const ValueKey<String>(
                'city-compare-custom-expense-label-field',
              ),
              controller: _customExpenseLabelController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: _lifeText(context, zh: '支出名称', en: 'Expense label'),
                border: const OutlineInputBorder(),
              ),
            ),
            TextField(
              key: const ValueKey<String>(
                'city-compare-custom-expense-amount-field',
              ),
              controller: _customExpenseAmountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: _lifeText(
                  context,
                  zh: '月支出金额',
                  en: 'Monthly amount',
                ),
                prefixText: '¥ ',
                border: const OutlineInputBorder(),
              ),
            ),
            DropdownButtonFormField<CityCompareCustomExpenseCategory>(
              initialValue: _customExpenseCategory,
              decoration: InputDecoration(
                labelText: _lifeText(context, zh: '分类', en: 'Category'),
                border: const OutlineInputBorder(),
              ),
              items: CityCompareCustomExpenseCategory.values
                  .map(
                    (category) =>
                        DropdownMenuItem<CityCompareCustomExpenseCategory>(
                          value: category,
                          child: Text(_customCategoryLabel(context, category)),
                        ),
                  )
                  .toList(growable: false),
              onChanged: (value) => setState(
                () => _customExpenseCategory =
                    value ?? CityCompareCustomExpenseCategory.lifestyle,
              ),
            ),
            FilledButton.tonalIcon(
              key: const ValueKey<String>('city-compare-add-custom-expense'),
              onPressed: _addCustomExpense,
              icon: const Icon(Icons.add_rounded),
              label: Text(_lifeText(context, zh: '添加支出', en: 'Add expense')),
            ),
          ],
        ),
        if (_customExpenses.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          for (var index = 0; index < _customExpenses.length; index += 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _customExpenseTile(context, _customExpenses[index], index),
            ),
        ],
      ],
    );
  }

  void _addCustomExpense() {
    final label = _customExpenseLabelController.text.trim();
    final amount =
        double.tryParse(_customExpenseAmountController.text.trim()) ?? 0;
    if (label.isEmpty || amount <= 0) {
      return;
    }
    setState(() {
      _customExpenses.add(
        CityCompareCustomExpense(
          label: label,
          amount: amount,
          category: _customExpenseCategory,
        ),
      );
      _customExpenseLabelController.clear();
      _customExpenseAmountController.text = '500';
    });
  }

  Widget _customExpenseTile(
    BuildContext context,
    CityCompareCustomExpense expense,
    int index,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  expense.label,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_customCategoryLabel(context, expense.category)} · ${_money(expense.amount)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: _lifeText(context, zh: '删除', en: 'Remove'),
            onPressed: () => setState(() => _customExpenses.removeAt(index)),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }

  String _customCategoryLabel(
    BuildContext context,
    CityCompareCustomExpenseCategory category,
  ) {
    return switch (category) {
      CityCompareCustomExpenseCategory.lifestyle => _lifeText(
        context,
        zh: '生活',
        en: 'Lifestyle',
      ),
      CityCompareCustomExpenseCategory.family => _lifeText(
        context,
        zh: '家庭',
        en: 'Family',
      ),
      CityCompareCustomExpenseCategory.commute => _lifeText(
        context,
        zh: '通勤',
        en: 'Commute',
      ),
      CityCompareCustomExpenseCategory.health => _lifeText(
        context,
        zh: '健康',
        en: 'Health',
      ),
      CityCompareCustomExpenseCategory.debt => _lifeText(
        context,
        zh: '债务',
        en: 'Debt',
      ),
      CityCompareCustomExpenseCategory.other => _lifeText(
        context,
        zh: '其他',
        en: 'Other',
      ),
    };
  }

  Widget _notesPanel(BuildContext context, CityCompareResult result) {
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '口径与边界', en: 'Method and limits'),
      subtitle: _lifeText(
        context,
        zh: '这页适合做 offer、调动和迁居前的横向估算，不是实时房源、税务申报或工资条模拟器。',
        en: 'Use this for side-by-side offer estimates, not as a real-time tax or payroll simulator.',
      ),
      children: <Widget>[
        _WorkWorthBreakdownRow(
          label: _lifeText(context, zh: '目标城市成本倍率', en: 'Target cost ratio'),
          value: '${result.costRatio.toStringAsFixed(2)}x',
        ),
        _WorkWorthBreakdownRow(
          label: _lifeText(
            context,
            zh: '目标城市保本月薪',
            en: 'Target break-even gross',
          ),
          value: _money(result.breakEvenTargetSnapshot.grossMonthlySalary),
        ),
        const SizedBox(height: 10),
        Text(
          _lifeText(
            context,
            zh: '原始字段口径来自 `Zippland/city_compare` README 和 `public/city_data.csv`：包括社保基数、租金、房价、餐饮、通勤、教育、水电网话、健身和电影票等条目；参考项目 README 进一步说明这些数据优先参考 Numbeo 公共数据。当前页面在此基础上做本地估算，并补充简化五险一金与个税模型。',
            en: 'The raw fields come from the Zippland/city_compare README and public/city_data.csv, including social-security bases, rent, home prices, dining, transport, education, utilities, connectivity, fitness, and cinema. The README also states that the source data is primarily referenced from Numbeo public data. This page builds local estimates on top of that and adds a simplified social-security and tax model.',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _insightPanel(BuildContext context, CityCompareResult result) {
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '对比分析', en: 'Comparison insights'),
      subtitle: _lifeText(
        context,
        zh: '不只展示结果，也总结这次城市迁移里最值得盯住的差异项。',
        en: 'Not just the result: this also summarizes the key differences to watch.',
      ),
      children: result.insights
          .map(
            (insight) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _CityCompareInsightCard(insight: insight),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _referencePanel(BuildContext context, CityCompareResult result) {
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '参考细分条目', en: 'Reference detail items'),
      subtitle: _lifeText(
        context,
        zh: '这里列出参考页里的原始成本字段，便于你核对差异到底来自哪类基础价格。',
        en: 'These are the raw reference items behind the comparison.',
      ),
      children: <Widget>[
        for (final category in <String>[
          'salary',
          'housing',
          'daily',
          'transport',
          'family',
          'leisure',
        ]) ...<Widget>[
          _CityCompareReferenceGroup(
            title: _referenceCategoryLabel(context, category),
            items: result.referenceItems
                .where((item) => item.category == category)
                .toList(growable: false),
          ),
          if (category != 'leisure') const SizedBox(height: 12),
        ],
      ],
    );
  }

  String _referenceCategoryLabel(BuildContext context, String category) {
    return switch (category) {
      'salary' => _lifeText(
        context,
        zh: '薪资与缴费基线',
        en: 'Salary and contribution baseline',
      ),
      'housing' => _lifeText(
        context,
        zh: '住房与房价',
        en: 'Housing and home prices',
      ),
      'daily' => _lifeText(context, zh: '日常消费', en: 'Daily spending'),
      'transport' => _lifeText(context, zh: '通勤交通', en: 'Transport'),
      'family' => _lifeText(context, zh: '教育家庭', en: 'Education and family'),
      'leisure' => _lifeText(context, zh: '健身娱乐', en: 'Leisure'),
      _ => category,
    };
  }
}

class _CityCompareHero extends StatelessWidget {
  const _CityCompareHero({required this.result});

  final CityCompareResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final delta =
        result.requiredTargetSnapshot.grossMonthlySalary -
        result.currentSnapshot.grossMonthlySalary;
    final deltaColor = delta <= 0
        ? const Color(0xFF87D4BE)
        : const Color(0xFFFFC979);
    return Container(
      key: const ValueKey<String>('city-compare-stage'),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF17283E),
            Color(0xFF27517B),
            Color(0xFF4D8DA8),
          ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF17283E).withValues(alpha: 0.24),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _lifeText(
              context,
              zh: '同等生活方式目标月薪',
              en: 'Equivalent target salary',
            ),
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _money(result.requiredTargetSnapshot.grossMonthlySalary),
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _lifeText(
              context,
              zh: '想在 ${result.targetCity.city} 维持你现在在 ${result.currentCity.city} 的同等生活方式和月度结余，大致需要这个税前月薪。',
              en: 'To keep the same lifestyle and monthly buffer when moving from ${result.currentCity.city} to ${result.targetCity.city}, this is the rough gross salary you need.',
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _WorkWorthMetricPill(
                label: _lifeText(context, zh: '当前月结余', en: 'Current buffer'),
                value: _money(result.currentSnapshot.monthlyBuffer),
              ),
              _WorkWorthMetricPill(
                label: _lifeText(
                  context,
                  zh: '同薪资到目标城',
                  en: 'Same salary buffer',
                ),
                value: _money(result.sameSalaryTargetSnapshot.monthlyBuffer),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 132),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: deltaColor.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: deltaColor.withValues(alpha: 0.42)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      _lifeText(context, zh: '月薪差额', en: 'Salary delta'),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${delta >= 0 ? '+' : ''}${_money(delta)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CityCompareScenarioCard extends StatelessWidget {
  const _CityCompareScenarioCard({
    super.key,
    required this.title,
    required this.cityName,
    required this.snapshot,
    required this.breakdown,
    this.highlight = false,
  });

  final String title;
  final String cityName;
  final CityCompareSalarySnapshot snapshot;
  final CityCompareCostBreakdown breakdown;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlight
              ? theme.colorScheme.primary.withValues(alpha: 0.35)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                cityName,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: <Widget>[
              _CityCompareStat(
                label: _lifeText(context, zh: '税前月薪', en: 'Gross'),
                value: _money(snapshot.grossMonthlySalary),
              ),
              _CityCompareStat(
                label: _lifeText(context, zh: '到手月薪', en: 'Net'),
                value: _money(snapshot.netSalary),
              ),
              _CityCompareStat(
                label: _lifeText(context, zh: '月成本', en: 'Monthly cost'),
                value: _money(snapshot.monthlyCost),
              ),
              _CityCompareStat(
                label: _lifeText(context, zh: '月结余', en: 'Buffer'),
                value: _money(snapshot.monthlyBuffer),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _WorkWorthBreakdownRow(
            label: _lifeText(context, zh: '社保公积金估算', en: 'Social security'),
            value: _money(snapshot.socialSecurityContribution),
          ),
          _WorkWorthBreakdownRow(
            label: _lifeText(context, zh: '个税估算', en: 'Income tax'),
            value: _money(snapshot.tax),
          ),
          _WorkWorthBreakdownRow(
            label: _lifeText(context, zh: '住房', en: 'Housing'),
            value: _money(breakdown.housing),
          ),
          _WorkWorthBreakdownRow(
            label: _lifeText(context, zh: '餐饮', en: 'Dining'),
            value: _money(breakdown.dining),
          ),
          _WorkWorthBreakdownRow(
            label: _lifeText(context, zh: '交通', en: 'Transport'),
            value: _money(breakdown.transport),
          ),
          _WorkWorthBreakdownRow(
            label: _lifeText(context, zh: '教育', en: 'Education'),
            value: _money(breakdown.education),
          ),
          _WorkWorthBreakdownRow(
            label: _lifeText(context, zh: '水电网话', en: 'Utilities + digital'),
            value: _money(breakdown.utilities + breakdown.digital),
          ),
          _WorkWorthBreakdownRow(
            label: _lifeText(context, zh: '健身与娱乐', en: 'Fitness + leisure'),
            value: _money(breakdown.fitness + breakdown.leisure),
          ),
          _WorkWorthBreakdownRow(
            label: _lifeText(context, zh: '自定义支出', en: 'Custom expenses'),
            value: _money(breakdown.custom),
          ),
        ],
      ),
    );
  }
}

class _CityCompareStat extends StatelessWidget {
  const _CityCompareStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(label, style: theme.textTheme.labelSmall),
          const SizedBox(height: 3),
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

class _CityCompareInsightCard extends StatelessWidget {
  const _CityCompareInsightCard({required this.insight});

  final CityCompareInsight insight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (insight.level) {
      'warning' => const Color(0xFFE99A52),
      'positive' => const Color(0xFF5FBF95),
      _ => theme.colorScheme.primary,
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _lifeText(context, zh: insight.titleZh, en: insight.titleEn),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _lifeText(context, zh: insight.bodyZh, en: insight.bodyEn),
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _CityCompareReferenceGroup extends StatelessWidget {
  const _CityCompareReferenceGroup({required this.title, required this.items});

  final String title;
  final List<CityCompareReferenceItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _CityCompareReferenceRow(item: item),
          ),
      ],
    );
  }
}

class _CityCompareReferenceRow extends StatelessWidget {
  const _CityCompareReferenceRow({required this.item});

  final CityCompareReferenceItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final delta = item.delta;
    final deltaColor = delta >= 0
        ? const Color(0xFFE99A52)
        : const Color(0xFF5FBF95);
    return Container(
      key: ValueKey<String>('city-compare-reference-${item.labelEn}'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _lifeText(context, zh: item.labelZh, en: item.labelEn),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: <Widget>[
              _CityCompareStat(
                label: _lifeText(context, zh: '当前城市', en: 'Current'),
                value: _referenceValue(
                  context,
                  item.currentValue,
                  item.unitZh,
                  item.unitEn,
                ),
              ),
              _CityCompareStat(
                label: _lifeText(context, zh: '目标城市', en: 'Target'),
                value: _referenceValue(
                  context,
                  item.targetValue,
                  item.unitZh,
                  item.unitEn,
                ),
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 120),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: deltaColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      _lifeText(context, zh: '差额 / 倍率', en: 'Delta / ratio'),
                      style: theme.textTheme.labelSmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${delta >= 0 ? '+' : ''}${item.delta.toStringAsFixed(0)} / ${item.ratio.toStringAsFixed(2)}x',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: deltaColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _referenceValue(
    BuildContext context,
    double value,
    String unitZh,
    String unitEn,
  ) {
    final unit = _lifeText(context, zh: unitZh, en: unitEn);
    return '${value.toStringAsFixed(0)} $unit';
  }
}
