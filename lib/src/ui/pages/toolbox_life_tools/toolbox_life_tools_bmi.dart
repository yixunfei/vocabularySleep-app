part of '../toolbox_life_tools.dart';

enum _BmiUnitSystem { metric, imperial }

class _BmiToolPage extends StatefulWidget {
  const _BmiToolPage();

  @override
  State<_BmiToolPage> createState() => _BmiToolPageState();
}

class _BmiToolPageState extends State<_BmiToolPage> {
  static const ToolboxBmiService _service = ToolboxBmiService();

  final TextEditingController _heightCmController = TextEditingController(
    text: '170',
  );
  final TextEditingController _weightKgController = TextEditingController(
    text: '65',
  );
  final TextEditingController _feetController = TextEditingController(
    text: '5',
  );
  final TextEditingController _inchController = TextEditingController(
    text: '7',
  );
  final TextEditingController _poundController = TextEditingController(
    text: '143',
  );
  final TextEditingController _ageController = TextEditingController(
    text: '32',
  );
  final TextEditingController _waistController = TextEditingController(
    text: '78',
  );
  final TextEditingController _hipController = TextEditingController(
    text: '95',
  );

  _BmiUnitSystem _unitSystem = _BmiUnitSystem.metric;
  ToolboxBmiSex _sex = ToolboxBmiSex.female;
  ToolboxAdultBmiStandard _adultStandard = ToolboxAdultBmiStandard.china;
  ToolboxBmiActivityLevel _activityLevel = ToolboxBmiActivityLevel.light;
  ToolboxBmiAssessment? _assessment;
  String? _error;

  @override
  void initState() {
    super.initState();
    _compute();
  }

  @override
  void dispose() {
    _heightCmController.dispose();
    _weightKgController.dispose();
    _feetController.dispose();
    _inchController.dispose();
    _poundController.dispose();
    _ageController.dispose();
    _waistController.dispose();
    _hipController.dispose();
    super.dispose();
  }

  double? _parseNumber(String text) {
    final normalized = text.trim().replaceAll(',', '');
    if (normalized.isEmpty) {
      return null;
    }
    return double.tryParse(normalized);
  }

  void _switchUnitSystem(_BmiUnitSystem next) {
    if (next == _unitSystem) {
      return;
    }

    if (_unitSystem == _BmiUnitSystem.metric) {
      final heightCm = _parseNumber(_heightCmController.text);
      final weightKg = _parseNumber(_weightKgController.text);
      if (heightCm != null && heightCm > 0) {
        final totalInches = heightCm / 2.54;
        final feet = totalInches ~/ 12;
        final inches = totalInches - feet * 12;
        _feetController.text = '$feet';
        _inchController.text = _formatNumber(inches);
      }
      if (weightKg != null && weightKg > 0) {
        _poundController.text = _formatNumber(weightKg * 2.2046226218);
      }
    } else {
      final feet = _parseNumber(_feetController.text) ?? 0;
      final inches = _parseNumber(_inchController.text) ?? 0;
      final pounds = _parseNumber(_poundController.text);
      final totalInches = feet * 12 + inches;
      if (totalInches > 0) {
        _heightCmController.text = _formatNumber(totalInches * 2.54);
      }
      if (pounds != null && pounds > 0) {
        _weightKgController.text = _formatNumber(pounds * 0.45359237);
      }
    }

    setState(() => _unitSystem = next);
    _compute();
  }

  void _resetSample() {
    setState(() {
      _unitSystem = _BmiUnitSystem.metric;
      _sex = ToolboxBmiSex.female;
      _adultStandard = ToolboxAdultBmiStandard.china;
      _activityLevel = ToolboxBmiActivityLevel.light;
      _heightCmController.text = '170';
      _weightKgController.text = '65';
      _feetController.text = '5';
      _inchController.text = '7';
      _poundController.text = '143';
      _ageController.text = '32';
      _waistController.text = '78';
      _hipController.text = '95';
    });
    _compute();
  }

  void _compute() {
    final values = _resolveMetricValues();
    final heightCm = values.$1;
    final weightKg = values.$2;
    final ageYears = _parseNumber(_ageController.text);
    final waistCm = _parseNumber(_waistController.text);
    final hipCm = _parseNumber(_hipController.text);

    if (heightCm == null ||
        weightKg == null ||
        ageYears == null ||
        heightCm <= 0 ||
        weightKg <= 0 ||
        ageYears <= 0) {
      setState(() {
        _assessment = null;
        _error = _lifeI18nText(
          context,
          'inline.plan295.life.enter_valid_height_weight_and_age_va.ab4da8a8a07b',
        );
      });
      return;
    }

    try {
      final assessment = _service.assess(
        ToolboxBmiInput(
          heightCm: heightCm,
          weightKg: weightKg,
          ageYears: ageYears,
          sex: _sex,
          adultStandard: _adultStandard,
          activityLevel: _activityLevel,
          waistCm: waistCm,
          hipCm: hipCm,
        ),
      );
      setState(() {
        _assessment = assessment;
        _error = null;
      });
    } on ArgumentError catch (error) {
      setState(() {
        _assessment = null;
        _error = error.message as String?;
      });
    }
  }

  (double?, double?) _resolveMetricValues() {
    if (_unitSystem == _BmiUnitSystem.metric) {
      return (
        _parseNumber(_heightCmController.text),
        _parseNumber(_weightKgController.text),
      );
    }
    final feet = _parseNumber(_feetController.text) ?? 0;
    final inches = _parseNumber(_inchController.text) ?? 0;
    final pounds = _parseNumber(_poundController.text);
    final totalInches = feet * 12 + inches;
    return (
      totalInches <= 0 ? null : totalInches * 2.54,
      pounds == null ? null : pounds * 0.45359237,
    );
  }

  String _formatNumber(double value, {int digits = 1}) {
    return value.toStringAsFixed(digits).replaceFirst(RegExp(r'\.0+$'), '');
  }

  String _formatKg(double? value) {
    return value == null ? '-' : '${_formatNumber(value)} kg';
  }

  String _formatKcal(double? value) {
    return value == null
        ? _lifeI18nText(context, 'inline.plan295.life.15_only.312e80b5b643')
        : '${value.round()} kcal';
  }

  String _categoryLabel(ToolboxBmiAssessment assessment) {
    if (assessment.adultCategory != null) {
      return switch (assessment.adultCategory!) {
        ToolboxAdultBmiCategory.underweight => _lifeI18nText(
          context,
          'inline.plan295.life.underweight.61b7bf870a16',
        ),
        ToolboxAdultBmiCategory.healthy => _lifeI18nText(
          context,
          'inline.plan295.life.healthy.209c9c817b4d',
        ),
        ToolboxAdultBmiCategory.overweight => _lifeI18nText(
          context,
          'inline.plan295.life.overweight.ec2760428635',
        ),
        ToolboxAdultBmiCategory.obesityClass1 =>
          assessment.adultStandard == ToolboxAdultBmiStandard.china
              ? _lifeI18nText(
                  context,
                  'inline.plan295.life.obesity.4f357b4ba36c',
                )
              : _lifeI18nText(
                  context,
                  'inline.plan295.life.obesity_class_i.501708346ad8',
                ),
        ToolboxAdultBmiCategory.obesityClass2 => _lifeI18nText(
          context,
          'inline.plan295.life.obesity_class_ii.9d364fef85fa',
        ),
        ToolboxAdultBmiCategory.obesityClass3 => _lifeI18nText(
          context,
          'inline.plan295.life.obesity_class_iii.35ebadf0b91f',
        ),
      };
    }

    if (assessment.youthCategory != null) {
      return switch (assessment.youthCategory!) {
        ToolboxYouthBmiCategory.underweight => _lifeI18nText(
          context,
          'inline.plan295.life.underweight.61b7bf870a16',
        ),
        ToolboxYouthBmiCategory.healthy => _lifeI18nText(
          context,
          'inline.plan295.life.healthy.03063e5eb73e',
        ),
        ToolboxYouthBmiCategory.overweight => _lifeI18nText(
          context,
          'inline.plan295.life.overweight.ec2760428635',
        ),
        ToolboxYouthBmiCategory.obesity => _lifeI18nText(
          context,
          'inline.plan295.life.obesity.4f357b4ba36c',
        ),
        ToolboxYouthBmiCategory.severeObesity => _lifeI18nText(
          context,
          'inline.plan295.life.severe_obesity_ref.db5b167245e9',
        ),
      };
    }

    return _lifeI18nText(
      context,
      'inline.plan295.life.bmi_for_age_n_a.dcb8f5769a39',
    );
  }

  String _ageBandLabel(ToolboxBmiAssessment assessment) {
    return switch (assessment.ageBand) {
      'infant' => _lifeI18nText(
        context,
        'inline.plan295.life.under_2.51142f91ff98',
      ),
      'child' => _lifeI18nText(
        context,
        'inline.plan295.life.child.129a643afd19',
      ),
      'teen' => _lifeI18nText(context, 'inline.plan295.life.teen.61d5a345cad9'),
      _ => _lifeI18nText(context, 'inline.plan295.life.adult.f7d107f73731'),
    };
  }

  String _adultStandardLabel(ToolboxAdultBmiStandard standard) {
    return switch (standard) {
      ToolboxAdultBmiStandard.china => _lifeI18nText(
        context,
        'inline.plan295.life.china_adult.a5fdbdf5331f',
      ),
      ToolboxAdultBmiStandard.who => _lifeI18nText(
        context,
        'inline.plan295.life.who_global.7eb593cba4bf',
      ),
    };
  }

  String _waistHeightLabel(ToolboxWaistHeightCategory? category) {
    return switch (category) {
      ToolboxWaistHeightCategory.low => _lifeI18nText(
        context,
        'inline.plan295.life.low.d7b3d5ef736d',
      ),
      ToolboxWaistHeightCategory.healthy => _lifeI18nText(
        context,
        'inline.plan295.life.favorable.4ccfe4403736',
      ),
      ToolboxWaistHeightCategory.increased => _lifeI18nText(
        context,
        'inline.plan295.life.increased.cca70a79e6b8',
      ),
      ToolboxWaistHeightCategory.high => _lifeI18nText(
        context,
        'inline.plan295.life.high.af6cdf59a984',
      ),
      null => _lifeI18nText(
        context,
        'inline.plan295.life.not_set.e56ed29d26e6',
      ),
    };
  }

  String _waistHipLabel(ToolboxWaistHipCategory? category) {
    return switch (category) {
      ToolboxWaistHipCategory.low => _lifeI18nText(
        context,
        'inline.plan295.life.lower.d3009191d0e1',
      ),
      ToolboxWaistHipCategory.increased => _lifeI18nText(
        context,
        'inline.plan295.life.increased.cca70a79e6b8',
      ),
      ToolboxWaistHipCategory.high => _lifeI18nText(
        context,
        'inline.plan295.life.high.af6cdf59a984',
      ),
      null => _lifeI18nText(
        context,
        'inline.plan295.life.not_set.e56ed29d26e6',
      ),
    };
  }

  Color _categoryColor(ToolboxBmiAssessment assessment, BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = _categoryLabel(assessment);
    if (label.contains('正常') ||
        label.contains('健康') ||
        label.contains('Healthy')) {
      return scheme.primary;
    }
    if (label.contains('超重') || label.contains('Overweight')) {
      return const Color(0xFFC9791B);
    }
    if (label.contains('肥胖') || label.contains('Obesity')) {
      return scheme.error;
    }
    return scheme.secondary;
  }

  String _summaryText(ToolboxBmiAssessment assessment) {
    if (assessment.isTooYoungForBmiForAge) {
      return _lifeI18nText(
        context,
        'inline.plan295.life.bmi_for_age_categories_are_not_used.fbcb75fc887d',
      );
    }
    if (assessment.isYouth) {
      return _lifeI18nText(
        context,
        'inline.plan295.life.this_uses_cdc_bmi_for_age_for_ages_2.b0411a1b2f20',
      );
    }

    final delta = assessment.weightKg - (assessment.targetMidKg ?? 0);
    if (delta.abs() < 0.25) {
      return _lifeI18nText(
        context,
        'inline.plan295.life.you_are_already_very_close_to_the_mi.361a6ad82522',
      );
    }
    if (delta > 0) {
      return _lifeI18nText(
        context,
        'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.bmi.to_return_near_the_midpoint_of.e730e0c4b6',
        params: <String, Object?>{'p0': _formatNumber(delta)},
      );
    }
    return _lifeI18nText(
      context,
      'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.bmi.to_return_near_the_midpoint_of.8adb82e824',
      params: <String, Object?>{'p0': _formatNumber(delta.abs())},
    );
  }

  String _percentileText(ToolboxBmiAssessment assessment) {
    final percentile = assessment.percentile;
    if (percentile == null) {
      return _lifeI18nText(
        context,
        'inline.plan295.life.adult_bands.4f970de24fcf',
      );
    }
    return 'P${percentile.clamp(0, 99.9).toStringAsFixed(1)}';
  }

  String _ratioText(double? value) {
    return value == null ? '-' : value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final assessment = _assessment;

    return ToolboxToolPage(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.bmi_calculator.9086420041e2',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.uses_age_sex_and_adult_youth_specifi.2f4ca28c0358',
      ),
      child: Column(
        key: const ValueKey<String>('life-bmi-page'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _LifeSettingsPanel(
            title: _lifeI18nText(
              context,
              'inline.plan295.life.summary.12c5faf8adff',
            ),
            subtitle: _lifeI18nText(
              context,
              'inline.plan295.life.start_with_bmi_classification_method.582267f61797',
            ),
            children: <Widget>[
              Text(
                assessment == null
                    ? _lifeI18nText(
                        context,
                        'inline.plan295.life.enter_height_weight_and_age_to_calcu.a78ad2e57bb4',
                      )
                    : 'BMI ${assessment.bmi.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (assessment != null) ...<Widget>[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    ToolboxMetricCard(
                      label: _lifeI18nText(
                        context,
                        'inline.plan295.life.category.90f3927c2616',
                      ),
                      value: _categoryLabel(assessment),
                    ),
                    ToolboxMetricCard(
                      label: _lifeI18nText(
                        context,
                        'inline.plan295.life.age_band.8009bbc01eb7',
                      ),
                      value: _ageBandLabel(assessment),
                    ),
                    ToolboxMetricCard(
                      label: assessment.isYouth
                          ? _lifeI18nText(
                              context,
                              'inline.plan295.life.percentile.55f78aa1157d',
                            )
                          : _lifeI18nText(
                              context,
                              'inline.plan295.life.standard.813df13bd85b',
                            ),
                      value: assessment.isYouth
                          ? _percentileText(assessment)
                          : _adultStandardLabel(assessment.adultStandard),
                    ),
                    ToolboxMetricCard(
                      label: _lifeI18nText(
                        context,
                        'inline.plan295.life.healthy_weight.71a351a65a0c',
                      ),
                      value:
                          '${_formatKg(assessment.healthyMinKg)} - ${_formatKg(assessment.healthyMaxKg)}',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _categoryColor(
                      assessment,
                      context,
                    ).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _categoryColor(
                        assessment,
                        context,
                      ).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    _summaryText(assessment),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _categoryColor(assessment, context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              if (_error != null) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          _buildInputsPanel(context),
          if (assessment != null) ...<Widget>[
            const SizedBox(height: 12),
            _buildProfessionalToolsPanel(context, assessment),
          ],
          const SizedBox(height: 12),
          _buildReferencePanel(context),
        ],
      ),
    );
  }

  Widget _buildInputsPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'inline.plan295.life.inputs.d92817b25e8b'),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.age_selects_adult_fixed_bands_or_you.bd448fe03227',
      ),
      children: <Widget>[
        _LifeSegmentedField<_BmiUnitSystem>(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.unit_system.e0e95207980a',
          ),
          value: _unitSystem,
          options: const <_LifeOption<_BmiUnitSystem>>[
            _LifeOption<_BmiUnitSystem>(
              value: _BmiUnitSystem.metric,
              labelKey: 'inline.plan295.life.metric.0dd4d104cba9',
            ),
            _LifeOption<_BmiUnitSystem>(
              value: _BmiUnitSystem.imperial,
              labelKey: 'inline.plan295.life.imperial.19af27a190e0',
            ),
          ],
          onChanged: _switchUnitSystem,
        ),
        const SizedBox(height: 14),
        _LifeSegmentedField<ToolboxBmiSex>(
          label: _lifeI18nText(context, 'inline.plan295.life.sex.86ed0776d413'),
          value: _sex,
          options: const <_LifeOption<ToolboxBmiSex>>[
            _LifeOption<ToolboxBmiSex>(
              value: ToolboxBmiSex.female,
              labelKey: 'inline.plan295.life.female.1b99cf49303d',
            ),
            _LifeOption<ToolboxBmiSex>(
              value: ToolboxBmiSex.male,
              labelKey: 'inline.plan295.life.male.37c4fe0fd6d1',
            ),
          ],
          onChanged: (value) {
            setState(() => _sex = value);
            _compute();
          },
        ),
        const SizedBox(height: 14),
        _LifeSegmentedField<ToolboxAdultBmiStandard>(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.adult_standard.5362c0ae21ab',
          ),
          value: _adultStandard,
          options: const <_LifeOption<ToolboxAdultBmiStandard>>[
            _LifeOption<ToolboxAdultBmiStandard>(
              value: ToolboxAdultBmiStandard.china,
              labelKey: 'inline.plan295.life.china_adult.a5fdbdf5331f',
            ),
            _LifeOption<ToolboxAdultBmiStandard>(
              value: ToolboxAdultBmiStandard.who,
              labelKey: 'inline.plan295.life.who_global.7eb593cba4bf',
            ),
          ],
          onChanged: (value) {
            setState(() => _adultStandard = value);
            _compute();
          },
        ),
        const SizedBox(height: 14),
        TextField(
          key: const ValueKey<String>('life-bmi-age'),
          controller: _ageController,
          onChanged: (_) => _compute(),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: _lifeI18nText(
              context,
              'inline.plan295.life.age_years.c137ad5977f7',
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (_unitSystem == _BmiUnitSystem.metric)
          Column(
            children: <Widget>[
              TextField(
                key: const ValueKey<String>('life-bmi-height-cm'),
                controller: _heightCmController,
                onChanged: (_) => _compute(),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: _lifeI18nText(
                    context,
                    'inline.plan295.life.height_cm.0c8357e5f04b',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const ValueKey<String>('life-bmi-weight-kg'),
                controller: _weightKgController,
                onChanged: (_) => _compute(),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: _lifeI18nText(
                    context,
                    'inline.plan295.life.weight_kg.ef646ae6445b',
                  ),
                ),
              ),
            ],
          )
        else
          Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      key: const ValueKey<String>('life-bmi-height-ft'),
                      controller: _feetController,
                      onChanged: (_) => _compute(),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: _lifeI18nText(
                          context,
                          'inline.plan295.life.height_ft.e01f2d5a54d7',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      key: const ValueKey<String>('life-bmi-height-in'),
                      controller: _inchController,
                      onChanged: (_) => _compute(),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: _lifeI18nText(
                          context,
                          'inline.plan295.life.height_in.86ac2a496b8e',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                key: const ValueKey<String>('life-bmi-weight-lb'),
                controller: _poundController,
                onChanged: (_) => _compute(),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: _lifeI18nText(
                    context,
                    'inline.plan295.life.weight_lb.dd03c3439475',
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                key: const ValueKey<String>('life-bmi-waist-cm'),
                controller: _waistController,
                onChanged: (_) => _compute(),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: _lifeI18nText(
                    context,
                    'inline.plan295.life.waist_cm.c9b8761c8bac',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                key: const ValueKey<String>('life-bmi-hip-cm'),
                controller: _hipController,
                onChanged: (_) => _compute(),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: _lifeI18nText(
                    context,
                    'inline.plan295.life.hip_cm.45f1df799bae',
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _LifeSegmentedField<ToolboxBmiActivityLevel>(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.activity_level.e733be40f988',
          ),
          value: _activityLevel,
          options: const <_LifeOption<ToolboxBmiActivityLevel>>[
            _LifeOption<ToolboxBmiActivityLevel>(
              value: ToolboxBmiActivityLevel.sedentary,
              labelKey: 'inline.plan295.life.sedentary.a20627eff9a5',
            ),
            _LifeOption<ToolboxBmiActivityLevel>(
              value: ToolboxBmiActivityLevel.light,
              labelKey: 'inline.plan295.life.light.c69f32f5a55d',
            ),
            _LifeOption<ToolboxBmiActivityLevel>(
              value: ToolboxBmiActivityLevel.moderate,
              labelKey:
                  'inline.ui.pages.toolbox_human_tests_auditory_lab.moderate_9b29aa',
            ),
            _LifeOption<ToolboxBmiActivityLevel>(
              value: ToolboxBmiActivityLevel.active,
              labelKey:
                  'inline.ui.pages.focus_page_workspace_editor.active_e1209c',
            ),
            _LifeOption<ToolboxBmiActivityLevel>(
              value: ToolboxBmiActivityLevel.veryActive,
              labelKey: 'inline.plan295.life.very_active.f18038e67f21',
            ),
          ],
          onChanged: (value) {
            setState(() => _activityLevel = value);
            _compute();
          },
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            FilledButton.icon(
              key: const ValueKey<String>('life-bmi-calculate'),
              onPressed: _compute,
              icon: const Icon(Icons.monitor_weight_rounded),
              label: Text(
                _lifeI18nText(
                  context,
                  'inline.plan295.life.recalculate.a8068b0023c7',
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _resetSample,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                _lifeI18nText(
                  context,
                  'inline.plan295.daily_choice.reset_sample.27e2114c44ac',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfessionalToolsPanel(
    BuildContext context,
    ToolboxBmiAssessment assessment,
  ) {
    final targetDelta = assessment.targetMidKg == null
        ? null
        : assessment.weightKg - assessment.targetMidKg!;
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.practical_tools.91c92c97e4da',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.waist_and_energy_estimates_are_for_d.d8ad9a7d07ae',
      ),
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.waist_height.c8f51b9d9723',
              ),
              value:
                  '${_ratioText(assessment.waistToHeightRatio)} · ${_waistHeightLabel(assessment.waistHeightCategory)}',
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.waist_hip.1f95ac51355c',
              ),
              value:
                  '${_ratioText(assessment.waistToHipRatio)} · ${_waistHipLabel(assessment.waistHipCategory)}',
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.bmr.658c9f7f778f',
              ),
              value: _formatKcal(assessment.bmrKcal),
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.tdee.ffebc7ef297d',
              ),
              value: _formatKcal(assessment.tdeeKcal),
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.target_gap.cbb5c0058552',
              ),
              value: targetDelta == null
                  ? '-'
                  : '${targetDelta >= 0 ? '-' : '+'}${_formatNumber(targetDelta.abs())} kg',
            ),
            ToolboxMetricCard(
              label: _lifeI18nText(
                context,
                'inline.plan295.life.current_weight.127b51ee9c29',
              ),
              value: _formatKg(assessment.weightKg),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _lifeI18nText(
            context,
            'inline.plan295.life.mifflin_st_jeor_is_an_estimate_for_a.2d0a88057b5c',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildReferencePanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.reference.3f6ba13500cd',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.this_page_is_for_daily_self_checks_a.1ade456429e2',
      ),
      children: <Widget>[
        Text(
          _lifeI18nText(
            context,
            'inline.plan295.life.adults_china_bands_use_18_5_underwei.10be25df0eb5',
          ),
        ),
      ],
    );
  }
}
