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
      title: _lifeI18nText(
        context,
        'inline.plan295.life.city_salary_compare.0924c6268506',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.compare_city_costs_locally_and_estim.68cba0a5dcba',
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
      title: _lifeI18nText(
        context,
        'inline.plan295.life.cities_and_salary.f2da6544261a',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.pick_the_current_city_target_city_an.d98cdfea6f5d',
      ),
      children: <Widget>[
        _WorkWorthFieldGrid(
          children: <Widget>[
            DropdownButtonFormField<String>(
              initialValue: _currentCity,
              decoration: InputDecoration(
                labelText: _lifeI18nText(
                  context,
                  'inline.plan295.life.current_city.1a84f8481b8e',
                ),
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
                labelText: _lifeI18nText(
                  context,
                  'inline.plan295.life.target_city.9372e59c35c8',
                ),
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
                labelText: _lifeI18nText(
                  context,
                  'inline.plan295.life.gross_monthly_salary.363b958ea3d2',
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
              label: Text(
                _lifeI18nText(
                  context,
                  'inline.plan295.life.swap_cities.77f39f18f487',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _profilePanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.lifestyle_profile.41321c9b50c6',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.this_defines_what_same_lifestyle_mea.9b74b6f94ee5',
      ),
      children: <Widget>[
        _LifeSegmentedField<CityCompareHousingType>(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.housing.f9f28032fb67',
          ),
          value: _housingType,
          options: const <_LifeOption<CityCompareHousingType>>[
            _LifeOption(
              value: CityCompareHousingType.suburbOneBedroom,
              labelKey: 'inline.plan295.life.suburb_1br.106aed735a08',
            ),
            _LifeOption(
              value: CityCompareHousingType.centerOneBedroom,
              labelKey: 'inline.plan295.life.center_1br.2d6e036225ad',
            ),
            _LifeOption(
              value: CityCompareHousingType.suburbThreeBedroom,
              labelKey: 'inline.plan295.life.suburb_3br.dff6d1c03818',
            ),
            _LifeOption(
              value: CityCompareHousingType.centerThreeBedroom,
              labelKey: 'inline.plan295.life.center_3br.8018b18239e8',
            ),
          ],
          onChanged: (value) => setState(() => _housingType = value),
        ),
        const SizedBox(height: 14),
        _LifeSegmentedField<CityCompareDiningType>(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.dining.2ce463ab63e3',
          ),
          value: _diningType,
          options: const <_LifeOption<CityCompareDiningType>>[
            _LifeOption(
              value: CityCompareDiningType.homeFocused,
              labelKey: 'inline.plan295.life.mostly_home.0f56eb8b1918',
            ),
            _LifeOption(
              value: CityCompareDiningType.balanced,
              labelKey: 'inline.plan295.life.balanced.bdebbbec386a',
            ),
            _LifeOption(
              value: CityCompareDiningType.dineOutOften,
              labelKey: 'inline.plan295.life.often_dine_out.f4f0660f95c8',
            ),
          ],
          onChanged: (value) => setState(() => _diningType = value),
        ),
        const SizedBox(height: 14),
        _LifeSegmentedField<CityCompareTransportType>(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.transport.c1302229b46d',
          ),
          value: _transportType,
          options: const <_LifeOption<CityCompareTransportType>>[
            _LifeOption(
              value: CityCompareTransportType.publicTransit,
              labelKey: 'inline.plan295.life.transit.a80e822f1f76',
            ),
            _LifeOption(
              value: CityCompareTransportType.car,
              labelKey: 'inline.plan295.life.car.7c28b4038fd2',
            ),
          ],
          onChanged: (value) => setState(() => _transportType = value),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<CityCompareEducationType>(
          initialValue: _educationType,
          decoration: InputDecoration(
            labelText: _lifeI18nText(
              context,
              'inline.plan295.life.education_cost.1f5d6ca42779',
            ),
            border: const OutlineInputBorder(),
          ),
          items: <DropdownMenuItem<CityCompareEducationType>>[
            DropdownMenuItem(
              value: CityCompareEducationType.none,
              child: Text(
                _lifeI18nText(context, 'ref.wordTransitionStyleNone'),
              ),
            ),
            DropdownMenuItem(
              value: CityCompareEducationType.kindergarten,
              child: Text(
                _lifeI18nText(
                  context,
                  'inline.plan295.life.kindergarten.79adf55e9cf6',
                ),
              ),
            ),
            DropdownMenuItem(
              value: CityCompareEducationType.primary,
              child: Text(
                _lifeI18nText(
                  context,
                  'inline.plan295.life.primary.f7a396f42a27',
                ),
              ),
            ),
            DropdownMenuItem(
              value: CityCompareEducationType.middle,
              child: Text(
                _lifeI18nText(
                  context,
                  'inline.plan295.life.middle.adebe9ee472a',
                ),
              ),
            ),
            DropdownMenuItem(
              value: CityCompareEducationType.high,
              child: Text(
                _lifeI18nText(
                  context,
                  'inline.plan295.life.high_school.9b59e396e988',
                ),
              ),
            ),
            DropdownMenuItem(
              value: CityCompareEducationType.international,
              child: Text(
                _lifeI18nText(
                  context,
                  'inline.plan295.life.international.409e3d99d2bd',
                ),
              ),
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
          title: Text(
            _lifeI18nText(
              context,
              'inline.plan295.life.include_fitness.da9416e5e222',
            ),
          ),
          onChanged: (value) => setState(() => _includeFitness = value),
        ),
        _LifeSliderField(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.cinema_trips_month.3e509d3505e8',
          ),
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
      title: _lifeI18nText(
        context,
        'inline.plan295.life.comparison_breakdown.7cfbcde0e42c',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.see_current_city_same_salary_in_targ.5a561272d747',
      ),
      children: <Widget>[
        _CityCompareScenarioCard(
          title: _lifeI18nText(
            context,
            'inline.plan295.life.current_city_now.8eebf3e8ad64',
          ),
          cityName: result.currentCity.city,
          snapshot: result.currentSnapshot,
          breakdown: result.currentBreakdown,
        ),
        const SizedBox(height: 12),
        _CityCompareScenarioCard(
          title: _lifeI18nText(
            context,
            'inline.plan295.life.same_salary_in_target_city.4f7afaf80d50',
          ),
          cityName: result.targetCity.city,
          snapshot: result.sameSalaryTargetSnapshot,
          breakdown: result.targetBreakdown,
        ),
        const SizedBox(height: 12),
        _CityCompareScenarioCard(
          key: const ValueKey<String>('city-compare-required-card'),
          title: _lifeI18nText(
            context,
            'inline.plan295.life.target_salary_to_match.12810bb41e4b',
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
      title: _lifeI18nText(
        context,
        'inline.plan295.life.adjustments_and_custom_expenses.f4acdef49b57',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.fine_tune_baseline_costs_by_category.414d6e866849',
      ),
      children: <Widget>[
        _LifeSliderField(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.housing_multiplier.88a47ed25e56',
          ),
          valueText: _housingAdjustment.toStringAsFixed(2),
          value: _housingAdjustment,
          min: 0.5,
          max: 1.8,
          divisions: 13,
          onChanged: (value) => setState(() => _housingAdjustment = value),
        ),
        _LifeSliderField(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.dining_multiplier.a6cbdd7de6e7',
          ),
          valueText: _diningAdjustment.toStringAsFixed(2),
          value: _diningAdjustment,
          min: 0.5,
          max: 1.8,
          divisions: 13,
          onChanged: (value) => setState(() => _diningAdjustment = value),
        ),
        _LifeSliderField(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.transport_multiplier.ed1f22539621',
          ),
          valueText: _transportAdjustment.toStringAsFixed(2),
          value: _transportAdjustment,
          min: 0.5,
          max: 1.8,
          divisions: 13,
          onChanged: (value) => setState(() => _transportAdjustment = value),
        ),
        _LifeSliderField(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.education_multiplier.30cee32e755a',
          ),
          valueText: _educationAdjustment.toStringAsFixed(2),
          value: _educationAdjustment,
          min: 0.5,
          max: 1.8,
          divisions: 13,
          onChanged: (value) => setState(() => _educationAdjustment = value),
        ),
        _LifeSliderField(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.utility_multiplier.b3ed3afa191d',
          ),
          valueText: _utilitiesAdjustment.toStringAsFixed(2),
          value: _utilitiesAdjustment,
          min: 0.5,
          max: 1.8,
          divisions: 13,
          onChanged: (value) => setState(() => _utilitiesAdjustment = value),
        ),
        _LifeSliderField(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.fitness_multiplier.f5eee05c2d1c',
          ),
          valueText: _fitnessAdjustment.toStringAsFixed(2),
          value: _fitnessAdjustment,
          min: 0.5,
          max: 2.0,
          divisions: 15,
          onChanged: (value) => setState(() => _fitnessAdjustment = value),
        ),
        _LifeSliderField(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.leisure_multiplier.04a23598c382',
          ),
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
                labelText: _lifeI18nText(
                  context,
                  'inline.plan295.life.fitness_override.a5bed820937f',
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
                labelText: _lifeI18nText(
                  context,
                  'inline.plan295.life.cinema_ticket_override.3e92fe35e41c',
                ),
                prefixText: '¥ ',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          _lifeI18nText(
            context,
            'inline.plan295.life.custom_monthly_expenses.a30f0c5bdbe6',
          ),
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
                labelText: _lifeI18nText(
                  context,
                  'inline.plan295.life.expense_label.6020c4dc0f0a',
                ),
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
                labelText: _lifeI18nText(
                  context,
                  'inline.plan295.life.monthly_amount.580db4ee7eac',
                ),
                prefixText: '¥ ',
                border: const OutlineInputBorder(),
              ),
            ),
            DropdownButtonFormField<CityCompareCustomExpenseCategory>(
              initialValue: _customExpenseCategory,
              decoration: InputDecoration(
                labelText: _lifeI18nText(
                  context,
                  'inline.plan295.daily_choice.category.c3134f512d8c',
                ),
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
              label: Text(
                _lifeI18nText(
                  context,
                  'inline.plan295.life.add_expense.899addbc9ca8',
                ),
              ),
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
            tooltip: _lifeI18nText(
              context,
              'inline.plan295.life.remove.756734973755',
            ),
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
      CityCompareCustomExpenseCategory.lifestyle => _lifeI18nText(
        context,
        'inline.plan295.life.lifestyle.c19f79d1a1bb',
      ),
      CityCompareCustomExpenseCategory.family => _lifeI18nText(
        context,
        'inline.plan295.life.family.696ce7797c7f',
      ),
      CityCompareCustomExpenseCategory.commute => _lifeI18nText(
        context,
        'inline.plan295.daily_choice.commute.4799a6b90d47',
      ),
      CityCompareCustomExpenseCategory.health => _lifeI18nText(
        context,
        'ref.toolbox.sleep.library.tag.risk',
      ),
      CityCompareCustomExpenseCategory.debt => _lifeI18nText(
        context,
        'inline.plan295.life.debt.87850964f2dc',
      ),
      CityCompareCustomExpenseCategory.other => _lifeI18nText(
        context,
        'inline.plan295.life.other.f0099311cd4a',
      ),
    };
  }

  Widget _notesPanel(BuildContext context, CityCompareResult result) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.method_and_limits.733a7ee3a825',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.use_this_for_side_by_side_offer_esti.d50e085dae55',
      ),
      children: <Widget>[
        _WorkWorthBreakdownRow(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.target_cost_ratio.1d84442f522f',
          ),
          value: '${result.costRatio.toStringAsFixed(2)}x',
        ),
        _WorkWorthBreakdownRow(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.target_break_even_gross.c616964edbc1',
          ),
          value: _money(result.breakEvenTargetSnapshot.grossMonthlySalary),
        ),
        const SizedBox(height: 10),
        Text(
          _lifeI18nText(
            context,
            'inline.plan295.life.the_raw_fields_come_from_the_zipplan.d73fa8ee9f07',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _insightPanel(BuildContext context, CityCompareResult result) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.comparison_insights.8da50bbbaf2d',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.not_just_the_result_this_also_summar.171c43bae39e',
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
      title: _lifeI18nText(
        context,
        'inline.plan295.life.reference_detail_items.652135324191',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.these_are_the_raw_reference_items_be.af0ccb2986d1',
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
      'salary' => _lifeI18nText(
        context,
        'inline.plan295.life.salary_and_contribution_baseline.b91e5acbfc35',
      ),
      'housing' => _lifeI18nText(
        context,
        'inline.plan295.life.housing_and_home_prices.a83790926b86',
      ),
      'daily' => _lifeI18nText(
        context,
        'inline.plan295.life.daily_spending.58219e24b7d8',
      ),
      'transport' => _lifeI18nText(
        context,
        'inline.plan295.life.transport.2a361d321b12',
      ),
      'family' => _lifeI18nText(
        context,
        'inline.plan295.life.education_and_family.15d0f85d5fe8',
      ),
      'leisure' => _lifeI18nText(
        context,
        'inline.plan295.life.leisure.da82b8744156',
      ),
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
            _lifeI18nText(
              context,
              'inline.plan295.life.equivalent_target_salary.468ec855db46',
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
            _lifeI18nText(
              context,
              'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.city.compare.to_keep_the_same_lifestyle_and.db6853b616',
              params: <String, Object?>{
                'city': result.targetCity.city,
                'city1': result.currentCity.city,
              },
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
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.current_buffer.6ada0630740f',
                ),
                value: _money(result.currentSnapshot.monthlyBuffer),
              ),
              _WorkWorthMetricPill(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.same_salary_buffer.699aaaf693d9',
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
                      _lifeI18nText(
                        context,
                        'inline.plan295.life.salary_delta.986b30ee0f0c',
                      ),
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
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.gross.a3de9e0dcb3a',
                ),
                value: _money(snapshot.grossMonthlySalary),
              ),
              _CityCompareStat(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.net.cd65c198c7ff',
                ),
                value: _money(snapshot.netSalary),
              ),
              _CityCompareStat(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.monthly_cost.6bee2e4513fe',
                ),
                value: _money(snapshot.monthlyCost),
              ),
              _CityCompareStat(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.buffer.07a3d0f903ea',
                ),
                value: _money(snapshot.monthlyBuffer),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _WorkWorthBreakdownRow(
            label: _lifeI18nText(
              context,
              'inline.plan295.life.social_security.9ce6f8b792d8',
            ),
            value: _money(snapshot.socialSecurityContribution),
          ),
          _WorkWorthBreakdownRow(
            label: _lifeI18nText(
              context,
              'inline.plan295.life.income_tax.eadbcafd719b',
            ),
            value: _money(snapshot.tax),
          ),
          _WorkWorthBreakdownRow(
            label: _lifeI18nText(
              context,
              'inline.plan295.life.housing.f9ec7596039d',
            ),
            value: _money(breakdown.housing),
          ),
          _WorkWorthBreakdownRow(
            label: _lifeI18nText(
              context,
              'inline.plan295.life.dining.bc72cf150c43',
            ),
            value: _money(breakdown.dining),
          ),
          _WorkWorthBreakdownRow(
            label: _lifeI18nText(context, 'ambientCategoryTransport'),
            value: _money(breakdown.transport),
          ),
          _WorkWorthBreakdownRow(
            label: _lifeI18nText(
              context,
              'inline.plan295.life.education.720fa00fa59f',
            ),
            value: _money(breakdown.education),
          ),
          _WorkWorthBreakdownRow(
            label: _lifeI18nText(
              context,
              'inline.plan295.life.utilities_digital.7feb6dfce7b9',
            ),
            value: _money(breakdown.utilities + breakdown.digital),
          ),
          _WorkWorthBreakdownRow(
            label: _lifeI18nText(
              context,
              'inline.plan295.life.fitness_leisure.f082874c40f4',
            ),
            value: _money(breakdown.fitness + breakdown.leisure),
          ),
          _WorkWorthBreakdownRow(
            label: _lifeI18nText(
              context,
              'inline.plan295.life.custom_expenses.e62db0d3eba5',
            ),
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
            _lifeI18nText(context, insight.titleKey),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _lifeI18nRefText(context, insight.body),
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
      key: ValueKey<String>('city-compare-reference-${item.labelKey}'),
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
            _lifeI18nText(context, item.labelKey),
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
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.current.4d1c39c95186',
                ),
                value: _referenceValue(
                  context,
                  item.currentValue,
                  item.unitKey,
                ),
              ),
              _CityCompareStat(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.target.8794449b2b9a',
                ),
                value: _referenceValue(context, item.targetValue, item.unitKey),
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
                      _lifeI18nText(
                        context,
                        'inline.plan295.life.delta_ratio.4bceb51fb41f',
                      ),
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

  String _referenceValue(BuildContext context, double value, String unitKey) {
    final unit = _lifeI18nText(context, unitKey);
    return '${value.toStringAsFixed(0)} $unit';
  }
}
