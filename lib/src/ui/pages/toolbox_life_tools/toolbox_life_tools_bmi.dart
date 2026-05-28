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
        _error = _lifeText(
          context,
          zh: '请输入有效的身高、体重和年龄数值。',
          en: 'Enter valid height, weight, and age values.',
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
        ? _lifeText(context, zh: '15 岁以上估算', en: '15+ only')
        : '${value.round()} kcal';
  }

  String _categoryLabel(ToolboxBmiAssessment assessment) {
    if (assessment.adultCategory != null) {
      return switch (assessment.adultCategory!) {
        ToolboxAdultBmiCategory.underweight => _lifeText(
          context,
          zh: '偏瘦',
          en: 'Underweight',
        ),
        ToolboxAdultBmiCategory.healthy => _lifeText(
          context,
          zh: '正常',
          en: 'Healthy',
        ),
        ToolboxAdultBmiCategory.overweight => _lifeText(
          context,
          zh: '超重',
          en: 'Overweight',
        ),
        ToolboxAdultBmiCategory.obesityClass1 => _lifeText(
          context,
          zh: assessment.adultStandard == ToolboxAdultBmiStandard.china
              ? '肥胖'
              : '肥胖 I 级',
          en: assessment.adultStandard == ToolboxAdultBmiStandard.china
              ? 'Obesity'
              : 'Obesity class I',
        ),
        ToolboxAdultBmiCategory.obesityClass2 => _lifeText(
          context,
          zh: '肥胖 II 级',
          en: 'Obesity class II',
        ),
        ToolboxAdultBmiCategory.obesityClass3 => _lifeText(
          context,
          zh: '肥胖 III 级',
          en: 'Obesity class III',
        ),
      };
    }

    if (assessment.youthCategory != null) {
      return switch (assessment.youthCategory!) {
        ToolboxYouthBmiCategory.underweight => _lifeText(
          context,
          zh: '偏瘦',
          en: 'Underweight',
        ),
        ToolboxYouthBmiCategory.healthy => _lifeText(
          context,
          zh: '健康体重',
          en: 'Healthy',
        ),
        ToolboxYouthBmiCategory.overweight => _lifeText(
          context,
          zh: '超重',
          en: 'Overweight',
        ),
        ToolboxYouthBmiCategory.obesity => _lifeText(
          context,
          zh: '肥胖',
          en: 'Obesity',
        ),
        ToolboxYouthBmiCategory.severeObesity => _lifeText(
          context,
          zh: '严重肥胖参考',
          en: 'Severe obesity ref.',
        ),
      };
    }

    return _lifeText(context, zh: '不适用 BMI-for-age', en: 'BMI-for-age N/A');
  }

  String _ageBandLabel(ToolboxBmiAssessment assessment) {
    return switch (assessment.ageBand) {
      'infant' => _lifeText(context, zh: '2 岁以下', en: 'Under 2'),
      'child' => _lifeText(context, zh: '儿童', en: 'Child'),
      'teen' => _lifeText(context, zh: '青少年', en: 'Teen'),
      _ => _lifeText(context, zh: '成人', en: 'Adult'),
    };
  }

  String _adultStandardLabel(ToolboxAdultBmiStandard standard) {
    return switch (standard) {
      ToolboxAdultBmiStandard.china => _lifeText(
        context,
        zh: '中国成人',
        en: 'China adult',
      ),
      ToolboxAdultBmiStandard.who => _lifeText(
        context,
        zh: 'WHO 国际',
        en: 'WHO global',
      ),
    };
  }

  String _waistHeightLabel(ToolboxWaistHeightCategory? category) {
    return switch (category) {
      ToolboxWaistHeightCategory.low => _lifeText(context, zh: '偏低', en: 'Low'),
      ToolboxWaistHeightCategory.healthy => _lifeText(
        context,
        zh: '较理想',
        en: 'Favorable',
      ),
      ToolboxWaistHeightCategory.increased => _lifeText(
        context,
        zh: '偏高',
        en: 'Increased',
      ),
      ToolboxWaistHeightCategory.high => _lifeText(
        context,
        zh: '较高',
        en: 'High',
      ),
      null => _lifeText(context, zh: '未填写', en: 'Not set'),
    };
  }

  String _waistHipLabel(ToolboxWaistHipCategory? category) {
    return switch (category) {
      ToolboxWaistHipCategory.low => _lifeText(context, zh: '较低', en: 'Lower'),
      ToolboxWaistHipCategory.increased => _lifeText(
        context,
        zh: '偏高',
        en: 'Increased',
      ),
      ToolboxWaistHipCategory.high => _lifeText(context, zh: '较高', en: 'High'),
      null => _lifeText(context, zh: '未填写', en: 'Not set'),
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
      return _lifeText(
        context,
        zh: '2 岁以下通常不使用 BMI-for-age 分类，请优先参考儿保生长曲线和医生评估。',
        en: 'BMI-for-age categories are not used under age 2; use pediatric growth charts and clinician assessment.',
      );
    }
    if (assessment.isYouth) {
      return _lifeText(
        context,
        zh: '当前按 CDC 2-19 岁 BMI-for-age 口径估算，百分位会同时考虑年龄和性别。',
        en: 'This uses CDC BMI-for-age for ages 2-19, so age and sex both affect the percentile.',
      );
    }

    final delta = assessment.weightKg - (assessment.targetMidKg ?? 0);
    if (delta.abs() < 0.25) {
      return _lifeText(
        context,
        zh: '当前已经很接近所选成人健康区间的中位参考值。',
        en: 'You are already very close to the midpoint of the selected adult healthy range.',
      );
    }
    if (delta > 0) {
      return _lifeText(
        context,
        zh: '若以所选成人健康区间中位为目标，约需减重 ${_formatNumber(delta)} kg。',
        en: 'To return near the midpoint of the selected adult healthy range, lose about ${_formatNumber(delta)} kg.',
      );
    }
    return _lifeText(
      context,
      zh: '若以所选成人健康区间中位为目标，约需增重 ${_formatNumber(delta.abs())} kg。',
      en: 'To return near the midpoint of the selected adult healthy range, gain about ${_formatNumber(delta.abs())} kg.',
    );
  }

  String _percentileText(ToolboxBmiAssessment assessment) {
    final percentile = assessment.percentile;
    if (percentile == null) {
      return _lifeText(context, zh: '成人口径', en: 'Adult bands');
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
      title: _lifeText(context, zh: 'BMI 计算器', en: 'BMI calculator'),
      subtitle: _lifeText(
        context,
        zh: '按年龄、性别和成人/儿童青少年不同口径判断，并补充围度、健康体重和日常能量估算。',
        en: 'Uses age, sex, and adult/youth-specific standards, with waist metrics, healthy weight range, and energy estimates.',
      ),
      child: Column(
        key: const ValueKey<String>('life-bmi-page'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _LifeSettingsPanel(
            title: _lifeText(context, zh: '结果摘要', en: 'Summary'),
            subtitle: _lifeText(
              context,
              zh: '先看当前 BMI、分类口径和最关键的下一步参考。',
              en: 'Start with BMI, classification method, and the next reference point.',
            ),
            children: <Widget>[
              Text(
                assessment == null
                    ? _lifeText(
                        context,
                        zh: '输入身高、体重和年龄后即可计算。',
                        en: 'Enter height, weight, and age to calculate.',
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
                      label: _lifeText(context, zh: '当前分类', en: 'Category'),
                      value: _categoryLabel(assessment),
                    ),
                    ToolboxMetricCard(
                      label: _lifeText(context, zh: '年龄口径', en: 'Age band'),
                      value: _ageBandLabel(assessment),
                    ),
                    ToolboxMetricCard(
                      label: assessment.isYouth
                          ? _lifeText(context, zh: '百分位', en: 'Percentile')
                          : _lifeText(context, zh: '参考体系', en: 'Standard'),
                      value: assessment.isYouth
                          ? _percentileText(assessment)
                          : _adultStandardLabel(assessment.adultStandard),
                    ),
                    ToolboxMetricCard(
                      label: _lifeText(
                        context,
                        zh: '健康体重',
                        en: 'Healthy weight',
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
      title: _lifeText(context, zh: '输入参数', en: 'Inputs'),
      subtitle: _lifeText(
        context,
        zh: '年龄会决定成人固定阈值或儿童青少年 BMI-for-age 百分位；腰围和臀围可留空。',
        en: 'Age selects adult fixed bands or youth BMI-for-age percentiles; waist and hip are optional.',
      ),
      children: <Widget>[
        _LifeSegmentedField<_BmiUnitSystem>(
          label: _lifeText(context, zh: '单位体系', en: 'Unit system'),
          value: _unitSystem,
          options: const <_LifeOption<_BmiUnitSystem>>[
            _LifeOption<_BmiUnitSystem>(
              value: _BmiUnitSystem.metric,
              labelZh: '公制',
              labelEn: 'Metric',
            ),
            _LifeOption<_BmiUnitSystem>(
              value: _BmiUnitSystem.imperial,
              labelZh: '英制',
              labelEn: 'Imperial',
            ),
          ],
          onChanged: _switchUnitSystem,
        ),
        const SizedBox(height: 14),
        _LifeSegmentedField<ToolboxBmiSex>(
          label: _lifeText(context, zh: '性别', en: 'Sex'),
          value: _sex,
          options: const <_LifeOption<ToolboxBmiSex>>[
            _LifeOption<ToolboxBmiSex>(
              value: ToolboxBmiSex.female,
              labelZh: '女性',
              labelEn: 'Female',
            ),
            _LifeOption<ToolboxBmiSex>(
              value: ToolboxBmiSex.male,
              labelZh: '男性',
              labelEn: 'Male',
            ),
          ],
          onChanged: (value) {
            setState(() => _sex = value);
            _compute();
          },
        ),
        const SizedBox(height: 14),
        _LifeSegmentedField<ToolboxAdultBmiStandard>(
          label: _lifeText(context, zh: '成人分类口径', en: 'Adult standard'),
          value: _adultStandard,
          options: const <_LifeOption<ToolboxAdultBmiStandard>>[
            _LifeOption<ToolboxAdultBmiStandard>(
              value: ToolboxAdultBmiStandard.china,
              labelZh: '中国成人',
              labelEn: 'China adult',
            ),
            _LifeOption<ToolboxAdultBmiStandard>(
              value: ToolboxAdultBmiStandard.who,
              labelZh: 'WHO 国际',
              labelEn: 'WHO global',
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
            labelText: _lifeText(context, zh: '年龄（岁）', en: 'Age (years)'),
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
                  labelText: _lifeText(
                    context,
                    zh: '身高（cm）',
                    en: 'Height (cm)',
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
                  labelText: _lifeText(
                    context,
                    zh: '体重（kg）',
                    en: 'Weight (kg)',
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
                        labelText: _lifeText(
                          context,
                          zh: '身高（ft）',
                          en: 'Height (ft)',
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
                        labelText: _lifeText(
                          context,
                          zh: '身高（in）',
                          en: 'Height (in)',
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
                  labelText: _lifeText(
                    context,
                    zh: '体重（lb）',
                    en: 'Weight (lb)',
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
                  labelText: _lifeText(context, zh: '腰围（cm）', en: 'Waist (cm)'),
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
                  labelText: _lifeText(context, zh: '臀围（cm）', en: 'Hip (cm)'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _LifeSegmentedField<ToolboxBmiActivityLevel>(
          label: _lifeText(context, zh: '活动水平', en: 'Activity level'),
          value: _activityLevel,
          options: const <_LifeOption<ToolboxBmiActivityLevel>>[
            _LifeOption<ToolboxBmiActivityLevel>(
              value: ToolboxBmiActivityLevel.sedentary,
              labelZh: '久坐',
              labelEn: 'Sedentary',
            ),
            _LifeOption<ToolboxBmiActivityLevel>(
              value: ToolboxBmiActivityLevel.light,
              labelZh: '轻活动',
              labelEn: 'Light',
            ),
            _LifeOption<ToolboxBmiActivityLevel>(
              value: ToolboxBmiActivityLevel.moderate,
              labelZh: '中等',
              labelEn: 'Moderate',
            ),
            _LifeOption<ToolboxBmiActivityLevel>(
              value: ToolboxBmiActivityLevel.active,
              labelZh: '活跃',
              labelEn: 'Active',
            ),
            _LifeOption<ToolboxBmiActivityLevel>(
              value: ToolboxBmiActivityLevel.veryActive,
              labelZh: '高活跃',
              labelEn: 'Very active',
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
              label: Text(_lifeText(context, zh: '重新计算', en: 'Recalculate')),
            ),
            OutlinedButton.icon(
              onPressed: _resetSample,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(_lifeText(context, zh: '恢复示例', en: 'Reset sample')),
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
      title: _lifeText(context, zh: '专业辅助工具', en: 'Practical tools'),
      subtitle: _lifeText(
        context,
        zh: '围度和能量估算用于日常管理，不作为诊断结论。',
        en: 'Waist and energy estimates are for day-to-day tracking, not diagnosis.',
      ),
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            ToolboxMetricCard(
              label: _lifeText(context, zh: '腰高比', en: 'Waist/height'),
              value:
                  '${_ratioText(assessment.waistToHeightRatio)} · ${_waistHeightLabel(assessment.waistHeightCategory)}',
            ),
            ToolboxMetricCard(
              label: _lifeText(context, zh: '腰臀比', en: 'Waist/hip'),
              value:
                  '${_ratioText(assessment.waistToHipRatio)} · ${_waistHipLabel(assessment.waistHipCategory)}',
            ),
            ToolboxMetricCard(
              label: _lifeText(context, zh: '基础代谢', en: 'BMR'),
              value: _formatKcal(assessment.bmrKcal),
            ),
            ToolboxMetricCard(
              label: _lifeText(context, zh: '日常总消耗', en: 'TDEE'),
              value: _formatKcal(assessment.tdeeKcal),
            ),
            ToolboxMetricCard(
              label: _lifeText(context, zh: '目标差量', en: 'Target gap'),
              value: targetDelta == null
                  ? '-'
                  : '${targetDelta >= 0 ? '-' : '+'}${_formatNumber(targetDelta.abs())} kg',
            ),
            ToolboxMetricCard(
              label: _lifeText(context, zh: '当前体重', en: 'Current weight'),
              value: _formatKg(assessment.weightKg),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _lifeText(
            context,
            zh: 'Mifflin-St Jeor 公式更适合成年人和较大青少年静息代谢估算；儿童、孕期、运动员、疾病恢复期或饮食控制前应使用专业评估。',
            en: 'Mifflin-St Jeor is an estimate for adults and older teens. Children, pregnancy, athletes, recovery, or dieting plans need professional assessment.',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildReferencePanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '参考说明', en: 'Reference'),
      subtitle: _lifeText(
        context,
        zh: '本页用于日常自查和趋势管理，不替代医生、营养师或儿保评估。',
        en: 'This page is for daily self-checks and trend tracking, not a substitute for clinical or pediatric assessment.',
      ),
      children: <Widget>[
        Text(
          _lifeText(
            context,
            zh: '成人：中国参考使用 BMI < 18.5 偏瘦，18.5-23.9 正常，24-27.9 超重，28 及以上肥胖；WHO 国际参考使用 18.5、25、30、35、40 分界。儿童青少年：2-19 岁按 CDC BMI-for-age 百分位，低于 P5 偏瘦，P5-P85 健康，P85-P95 超重，P95 及以上肥胖。',
            en: 'Adults: China bands use <18.5 underweight, 18.5-23.9 healthy, 24-27.9 overweight, and >=28 obesity; WHO bands use 18.5, 25, 30, 35, and 40 cut points. Youth: ages 2-19 use CDC BMI-for-age percentiles: <P5 underweight, P5-P85 healthy, P85-P95 overweight, and >=P95 obesity.',
          ),
        ),
      ],
    );
  }
}
