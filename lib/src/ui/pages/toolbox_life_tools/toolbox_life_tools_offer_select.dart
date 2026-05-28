part of '../toolbox_life_tools.dart';

class _OfferSelectToolPage extends StatefulWidget {
  const _OfferSelectToolPage();

  @override
  State<_OfferSelectToolPage> createState() => _OfferSelectToolPageState();
}

class _OfferSelectToolPageState extends State<_OfferSelectToolPage> {
  final ToolboxOfferSelectService _service = ToolboxOfferSelectService();
  final TextEditingController _title = TextEditingController(
    text: ToolboxOfferSelectService.defaultProfile.title,
  );
  final TextEditingController _background = TextEditingController(
    text: ToolboxOfferSelectService.defaultProfile.background,
  );
  final TextEditingController _major = TextEditingController(
    text: ToolboxOfferSelectService.defaultProfile.major,
  );
  final TextEditingController _experience = TextEditingController(
    text: ToolboxOfferSelectService.defaultProfile.experience,
  );

  List<OfferSelectCandidate> _candidates = ToolboxOfferSelectService
      .defaultCandidates
      .toList();
  OfferSelectWeights _weights = OfferSelectWeights.balanced;
  int _selectedIndex = 0;

  @override
  void dispose() {
    _title.dispose();
    _background.dispose();
    _major.dispose();
    _experience.dispose();
    super.dispose();
  }

  OfferSelectProfile get _profile => OfferSelectProfile(
    title: _title.text.trim().isEmpty ? 'Offer 选择' : _title.text.trim(),
    background: _background.text.trim(),
    major: _major.text.trim(),
    experience: _experience.text.trim(),
  );

  OfferSelectResult get _result => _service.compare(
    profile: _profile,
    candidates: _candidates,
    weights: _weights,
  );

  OfferSelectCandidate get _selectedCandidate {
    final index = _selectedIndex.clamp(0, _candidates.length - 1).toInt();
    return _candidates[index];
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return ToolboxToolPage(
      title: _lifeText(context, zh: 'Offer 选择助手', en: 'Offer selector'),
      subtitle: _lifeText(
        context,
        zh: '参考 OfferSelect 的机会录入形态，在本地完成多 Offer 评分、风险拆解和谈薪锚点。',
        en: 'Local multi-offer scoring, risk breakdown, and negotiation anchors inspired by OfferSelect.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _OfferSelectStage(result: result, onCopy: () => _copySummary(result)),
          const SizedBox(height: 14),
          _profilePanel(context),
          const SizedBox(height: 12),
          _offerSelectorPanel(context, result),
          const SizedBox(height: 12),
          _candidateEditorPanel(context),
          const SizedBox(height: 12),
          _weightsPanel(context),
          const SizedBox(height: 12),
          _comparisonPanel(context, result),
          const SizedBox(height: 12),
          _decisionPanel(context, result),
          const SizedBox(height: 12),
          _referencePanel(context),
        ],
      ),
    );
  }

  Widget _profilePanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '个人履历', en: 'Profile'),
      subtitle: _lifeText(
        context,
        zh: '保留参考页的标题、背景、专业和经历字段，用于生成可复制的决策摘要。',
        en: 'Keeps the reference page profile fields for the shareable decision summary.',
      ),
      children: <Widget>[
        _WorkWorthFieldGrid(
          children: <Widget>[
            _profileField(
              context,
              controller: _title,
              keyName: 'title',
              zh: '标题',
              en: 'Title',
            ),
            _profileField(
              context,
              controller: _background,
              keyName: 'background',
              zh: '背景',
              en: 'Background',
            ),
            _profileField(
              context,
              controller: _major,
              keyName: 'major',
              zh: '专业',
              en: 'Major',
            ),
            _profileField(
              context,
              controller: _experience,
              keyName: 'experience',
              zh: '经历',
              en: 'Experience',
            ),
          ],
        ),
      ],
    );
  }

  Widget _offerSelectorPanel(BuildContext context, OfferSelectResult result) {
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '工作机会', en: 'Offers'),
      subtitle: _lifeText(
        context,
        zh: '已婉拒的机会会保留作对照，但不参与首选排序。',
        en: 'Rejected offers remain visible for reference but are excluded from the leader ranking.',
      ),
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (var index = 0; index < _candidates.length; index += 1)
              ChoiceChip(
                selected: index == _selectedIndex,
                label: Text(
                  _candidates[index].rejected
                      ? '${_candidates[index].company} · ${_lifeText(context, zh: '已婉拒', en: 'Rejected')}'
                      : _candidates[index].company,
                ),
                onSelected: (_) => setState(() => _selectedIndex = index),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            FilledButton.tonalIcon(
              key: const ValueKey<String>('offer-select-add-offer'),
              onPressed: _addOffer,
              icon: const Icon(Icons.add_rounded),
              label: Text(_lifeText(context, zh: '添加', en: 'Add')),
            ),
            OutlinedButton.icon(
              onPressed: _toggleRejected,
              icon: Icon(
                _selectedCandidate.rejected
                    ? Icons.undo_rounded
                    : Icons.block_rounded,
              ),
              label: Text(
                _selectedCandidate.rejected
                    ? _lifeText(context, zh: '取消婉拒', en: 'Un-reject')
                    : _lifeText(context, zh: '标记婉拒', en: 'Reject'),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _candidates.length <= 1 ? null : _removeSelectedOffer,
              icon: const Icon(Icons.delete_outline_rounded),
              label: Text(_lifeText(context, zh: '删除', en: 'Delete')),
            ),
            OutlinedButton.icon(
              onPressed: _resetOffers,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(_lifeText(context, zh: '重置示例', en: 'Reset sample')),
            ),
          ],
        ),
        if (result.rejectedEvaluations.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Text(
            _lifeText(
              context,
              zh: '已婉拒: ${result.rejectedEvaluations.length}',
              en: 'Rejected: ${result.rejectedEvaluations.length}',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  Widget _candidateEditorPanel(BuildContext context) {
    final candidate = _selectedCandidate;
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '当前机会编辑', en: 'Edit selected offer'),
      subtitle: _lifeText(
        context,
        zh: '字段对应参考页里的公司、薪资、福利、社保、强度、地点、优缺点，并补充本地评分所需的扣款和成本。',
        en: 'Fields map to company, salary, benefits, insurance, intensity, location, pros, and cons, with extra local scoring inputs.',
      ),
      children: <Widget>[
        _WorkWorthFieldGrid(
          children: <Widget>[
            _candidateTextField(
              context,
              candidate: candidate,
              field: 'company',
              value: candidate.company,
              zh: '公司名称',
              en: 'Company',
              onChanged: (value) =>
                  _updateSelected((item) => item.copyWith(company: value)),
            ),
            _candidateTextField(
              context,
              candidate: candidate,
              field: 'role',
              value: candidate.role,
              zh: '岗位方向',
              en: 'Role',
              onChanged: (value) =>
                  _updateSelected((item) => item.copyWith(role: value)),
            ),
            _candidateTextField(
              context,
              candidate: candidate,
              field: 'city',
              value: candidate.city,
              zh: '工作地点',
              en: 'Location',
              onChanged: (value) =>
                  _updateSelected((item) => item.copyWith(city: value)),
            ),
            _candidateTextField(
              context,
              candidate: candidate,
              field: 'schedule',
              value: candidate.workSchedule,
              zh: '工作强度',
              en: 'Schedule',
              onChanged: (value) =>
                  _updateSelected((item) => item.copyWith(workSchedule: value)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          _lifeText(context, zh: '薪资信息', en: 'Salary'),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        _WorkWorthFieldGrid(
          children: <Widget>[
            _candidateNumberField(
              context,
              candidate: candidate,
              field: 'monthly-base',
              value: candidate.monthlyBase,
              zh: '月基本工资',
              en: 'Monthly base',
              prefixText: '¥ ',
              onChanged: (value) =>
                  _updateSelected((item) => item.copyWith(monthlyBase: value)),
            ),
            _candidateNumberField(
              context,
              candidate: candidate,
              field: 'months',
              value: candidate.salaryMonths,
              zh: '发薪月数',
              en: 'Months/year',
              onChanged: (value) =>
                  _updateSelected((item) => item.copyWith(salaryMonths: value)),
            ),
            _candidateNumberField(
              context,
              candidate: candidate,
              field: 'bonus',
              value: candidate.otherBonus,
              zh: '其他奖金/股票',
              en: 'Other bonus/equity',
              prefixText: '¥ ',
              onChanged: (value) =>
                  _updateSelected((item) => item.copyWith(otherBonus: value)),
            ),
            _candidateNumberField(
              context,
              candidate: candidate,
              field: 'tax',
              value: candidate.monthlyTax,
              zh: '月税费',
              en: 'Monthly tax',
              prefixText: '¥ ',
              onChanged: (value) =>
                  _updateSelected((item) => item.copyWith(monthlyTax: value)),
            ),
            _candidateNumberField(
              context,
              candidate: candidate,
              field: 'insurance-fund',
              value: candidate.monthlyInsuranceFund,
              zh: '五险一金/月',
              en: 'Insurance and fund',
              prefixText: '¥ ',
              onChanged: (value) => _updateSelected(
                (item) => item.copyWith(monthlyInsuranceFund: value),
              ),
            ),
            _candidateNumberField(
              context,
              candidate: candidate,
              field: 'benefit',
              value: candidate.monthlyBenefitValue,
              zh: '福利现金值/月',
              en: 'Monthly benefits',
              prefixText: '¥ ',
              onChanged: (value) => _updateSelected(
                (item) => item.copyWith(monthlyBenefitValue: value),
              ),
            ),
            _candidateNumberField(
              context,
              candidate: candidate,
              field: 'housing',
              value: candidate.monthlyHousingCost,
              zh: '住房成本/月',
              en: 'Housing cost',
              prefixText: '¥ ',
              onChanged: (value) => _updateSelected(
                (item) => item.copyWith(monthlyHousingCost: value),
              ),
            ),
            _candidateNumberField(
              context,
              candidate: candidate,
              field: 'living',
              value: candidate.monthlyLivingCost,
              zh: '生活开销/月',
              en: 'Living cost',
              prefixText: '¥ ',
              onChanged: (value) => _updateSelected(
                (item) => item.copyWith(monthlyLivingCost: value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _LifeSliderField(
          label: _lifeText(context, zh: '奖金兑现概率', en: 'Bonus certainty'),
          valueText: '${(candidate.bonusCertainty * 100).round()}%',
          value: candidate.bonusCertainty,
          min: 0,
          max: 1,
          divisions: 10,
          onChanged: (value) =>
              _updateSelected((item) => item.copyWith(bonusCertainty: value)),
        ),
        _LifeSliderField(
          label: _lifeText(context, zh: '薪资评级', en: 'Salary rating'),
          valueText: candidate.salaryRating.toStringAsFixed(1),
          value: candidate.salaryRating,
          min: 1,
          max: 5,
          divisions: 8,
          onChanged: (value) =>
              _updateSelected((item) => item.copyWith(salaryRating: value)),
        ),
        const SizedBox(height: 12),
        Text(
          _lifeText(context, zh: '时间与生活', en: 'Time and WLB'),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        _WorkWorthFieldGrid(
          children: <Widget>[
            _candidateNumberField(
              context,
              candidate: candidate,
              field: 'work-days',
              value: candidate.workDaysPerWeek,
              zh: '每周工作天',
              en: 'Workdays/week',
              onChanged: (value) => _updateSelected(
                (item) => item.copyWith(workDaysPerWeek: value),
              ),
            ),
            _candidateNumberField(
              context,
              candidate: candidate,
              field: 'wfh-days',
              value: candidate.workFromHomeDaysPerWeek,
              zh: '每周居家天',
              en: 'WFH days/week',
              onChanged: (value) => _updateSelected(
                (item) => item.copyWith(workFromHomeDaysPerWeek: value),
              ),
            ),
            _candidateNumberField(
              context,
              candidate: candidate,
              field: 'work-hours',
              value: candidate.workHoursPerDay,
              zh: '日工作小时',
              en: 'Work hours/day',
              onChanged: (value) => _updateSelected(
                (item) => item.copyWith(workHoursPerDay: value),
              ),
            ),
            _candidateNumberField(
              context,
              candidate: candidate,
              field: 'commute-hours',
              value: candidate.commuteHoursPerDay,
              zh: '日通勤小时',
              en: 'Commute hours/day',
              onChanged: (value) => _updateSelected(
                (item) => item.copyWith(commuteHoursPerDay: value),
              ),
            ),
            _candidateNumberField(
              context,
              candidate: candidate,
              field: 'rest-hours',
              value: candidate.restHoursPerDay,
              zh: '可恢复休息小时',
              en: 'Rest hours/day',
              onChanged: (value) => _updateSelected(
                (item) => item.copyWith(restHoursPerDay: value),
              ),
            ),
            _candidateNumberField(
              context,
              candidate: candidate,
              field: 'unpaid-overtime',
              value: candidate.unpaidOvertimeHoursPerMonth,
              zh: '无偿加班/月',
              en: 'Unpaid overtime/month',
              onChanged: (value) => _updateSelected(
                (item) => item.copyWith(unpaidOvertimeHoursPerMonth: value),
              ),
            ),
            _candidateNumberField(
              context,
              candidate: candidate,
              field: 'annual-leave',
              value: candidate.annualLeaveDays,
              zh: '年假天数',
              en: 'Annual leave',
              onChanged: (value) => _updateSelected(
                (item) => item.copyWith(annualLeaveDays: value),
              ),
            ),
            _candidateNumberField(
              context,
              candidate: candidate,
              field: 'paid-sick',
              value: candidate.paidSickLeaveDays,
              zh: '带薪病假',
              en: 'Paid sick leave',
              onChanged: (value) => _updateSelected(
                (item) => item.copyWith(paidSickLeaveDays: value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _LifeSliderField(
          label: _lifeText(context, zh: '工作生活平衡度', en: 'WLB rating'),
          valueText: candidate.wlbRating.toStringAsFixed(1),
          value: candidate.wlbRating,
          min: 1,
          max: 5,
          divisions: 8,
          onChanged: (value) =>
              _updateSelected((item) => item.copyWith(wlbRating: value)),
        ),
        const SizedBox(height: 12),
        _environmentEditor(context, candidate),
        const SizedBox(height: 14),
        _WorkWorthFieldGrid(
          children: <Widget>[
            _candidateTextField(
              context,
              candidate: candidate,
              field: 'benefits',
              value: candidate.benefits,
              zh: '福利',
              en: 'Benefits',
              maxLines: 2,
              onChanged: (value) =>
                  _updateSelected((item) => item.copyWith(benefits: value)),
            ),
            _candidateTextField(
              context,
              candidate: candidate,
              field: 'social-insurance',
              value: candidate.socialInsurance,
              zh: '社保',
              en: 'Social insurance',
              maxLines: 2,
              onChanged: (value) => _updateSelected(
                (item) => item.copyWith(socialInsurance: value),
              ),
            ),
            _candidateTextField(
              context,
              candidate: candidate,
              field: 'pros',
              value: candidate.pros,
              zh: '优点',
              en: 'Pros',
              maxLines: 3,
              onChanged: (value) =>
                  _updateSelected((item) => item.copyWith(pros: value)),
            ),
            _candidateTextField(
              context,
              candidate: candidate,
              field: 'cons',
              value: candidate.cons,
              zh: '缺点',
              en: 'Cons',
              maxLines: 3,
              onChanged: (value) =>
                  _updateSelected((item) => item.copyWith(cons: value)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _environmentEditor(
    BuildContext context,
    OfferSelectCandidate candidate,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _LifeSegmentedField<WorkWorthEnvironment>(
          label: _lifeText(context, zh: '工作环境健康层级', en: 'Work environment'),
          value: candidate.environment,
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
          onChanged: (value) =>
              _updateSelected((item) => item.copyWith(environment: value)),
        ),
        const SizedBox(height: 14),
        _LifeSegmentedField<WorkWorthJobStability>(
          label: _lifeText(context, zh: '工作类型/稳定性', en: 'Job stability'),
          value: candidate.stability,
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
          onChanged: (value) =>
              _updateSelected((item) => item.copyWith(stability: value)),
        ),
        const SizedBox(height: 10),
        _LifeSliderField(
          label: _lifeText(context, zh: 'Offer 确定性', en: 'Offer certainty'),
          valueText: '${(candidate.offerCertainty * 100).round()}%',
          value: candidate.offerCertainty,
          min: 0,
          max: 1,
          divisions: 10,
          onChanged: (value) =>
              _updateSelected((item) => item.copyWith(offerCertainty: value)),
        ),
        _LifeSliderField(
          label: _lifeText(context, zh: '城市适配', en: 'City fit'),
          valueText: candidate.cityFitFactor.toStringAsFixed(2),
          value: candidate.cityFitFactor,
          min: 0.7,
          max: 1.35,
          divisions: 13,
          onChanged: (value) =>
              _updateSelected((item) => item.copyWith(cityFitFactor: value)),
        ),
        _LifeSliderField(
          label: _lifeText(context, zh: '岗位匹配', en: 'Role fit'),
          valueText: candidate.roleMatchFactor.toStringAsFixed(2),
          value: candidate.roleMatchFactor,
          min: 0.75,
          max: 1.35,
          divisions: 12,
          onChanged: (value) =>
              _updateSelected((item) => item.copyWith(roleMatchFactor: value)),
        ),
        _LifeSliderField(
          label: _lifeText(context, zh: '成长性/技能复利', en: 'Growth potential'),
          valueText: candidate.growthFactor.toStringAsFixed(2),
          value: candidate.growthFactor,
          min: 0.75,
          max: 1.35,
          divisions: 12,
          onChanged: (value) =>
              _updateSelected((item) => item.copyWith(growthFactor: value)),
        ),
        _LifeSliderField(
          label: _lifeText(context, zh: '下班边界', en: 'Boundary quality'),
          valueText: candidate.boundaryFactor.toStringAsFixed(2),
          value: candidate.boundaryFactor,
          min: 0.7,
          max: 1.2,
          divisions: 10,
          onChanged: (value) =>
              _updateSelected((item) => item.copyWith(boundaryFactor: value)),
        ),
        _LifeSliderField(
          label: _lifeText(context, zh: '心理安全感', en: 'Psychological safety'),
          valueText: candidate.psychologicalSafetyFactor.toStringAsFixed(2),
          value: candidate.psychologicalSafetyFactor,
          min: 0.7,
          max: 1.2,
          divisions: 10,
          onChanged: (value) => _updateSelected(
            (item) => item.copyWith(psychologicalSafetyFactor: value),
          ),
        ),
        _LifeSliderField(
          label: _lifeText(context, zh: '自主权/灵活度', en: 'Autonomy'),
          valueText: candidate.autonomyFactor.toStringAsFixed(2),
          value: candidate.autonomyFactor,
          min: 0.75,
          max: 1.2,
          divisions: 9,
          onChanged: (value) =>
              _updateSelected((item) => item.copyWith(autonomyFactor: value)),
        ),
      ],
    );
  }

  Widget _weightsPanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '决策权重', en: 'Decision weights'),
      subtitle: _lifeText(
        context,
        zh: '权重越高，该维度越能影响排序；适合模拟“缺钱优先”“健康优先”“成长优先”等场景。',
        en: 'Higher weight means that dimension affects ranking more.',
      ),
      children: <Widget>[
        _weightSlider(
          context,
          zh: '现金流',
          en: 'Cashflow',
          value: _weights.cashflow,
          onChanged: (value) =>
              setState(() => _weights = _weights.copyWith(cashflow: value)),
        ),
        _weightSlider(
          context,
          zh: '时间成本',
          en: 'Time',
          value: _weights.time,
          onChanged: (value) =>
              setState(() => _weights = _weights.copyWith(time: value)),
        ),
        _weightSlider(
          context,
          zh: '健康边界',
          en: 'Health',
          value: _weights.health,
          onChanged: (value) =>
              setState(() => _weights = _weights.copyWith(health: value)),
        ),
        _weightSlider(
          context,
          zh: '成长匹配',
          en: 'Growth',
          value: _weights.growth,
          onChanged: (value) =>
              setState(() => _weights = _weights.copyWith(growth: value)),
        ),
        _weightSlider(
          context,
          zh: '稳定性',
          en: 'Stability',
          value: _weights.stability,
          onChanged: (value) =>
              setState(() => _weights = _weights.copyWith(stability: value)),
        ),
        _weightSlider(
          context,
          zh: '城市适配',
          en: 'City fit',
          value: _weights.cityFit,
          onChanged: (value) =>
              setState(() => _weights = _weights.copyWith(cityFit: value)),
        ),
      ],
    );
  }

  Widget _comparisonPanel(BuildContext context, OfferSelectResult result) {
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '排序与拆解', en: 'Ranking breakdown'),
      subtitle: _lifeText(
        context,
        zh: '分数来自现金、时间、健康、成长、稳定和城市适配六个维度，已婉拒项放在末尾。',
        en: 'Scores combine cash, time, health, growth, stability, and city fit.',
      ),
      children: <Widget>[
        if (result.activeEvaluations.isEmpty)
          Text(
            _lifeText(
              context,
              zh: '暂无未婉拒的 Offer。',
              en: 'No active offers yet.',
            ),
          )
        else
          for (
            var index = 0;
            index < result.activeEvaluations.length;
            index += 1
          )
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OfferEvaluationCard(
                evaluation: result.activeEvaluations[index],
                rank: index + 1,
              ),
            ),
        if (result.rejectedEvaluations.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            _lifeText(context, zh: '已婉拒对照', en: 'Rejected reference'),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          for (final evaluation in result.rejectedEvaluations)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OfferEvaluationCard(evaluation: evaluation),
            ),
        ],
      ],
    );
  }

  Widget _decisionPanel(BuildContext context, OfferSelectResult result) {
    final leader = result.leader;
    final runnerUp = result.runnerUp;
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '决策报告', en: 'Decision report'),
      subtitle: _lifeText(
        context,
        zh: '把优势、风险和谈薪追平金额摊开看，避免只盯一个总分。',
        en: 'Review strengths, risks, and negotiation anchors instead of only one score.',
      ),
      children: <Widget>[
        Text(
          _lifeText(context, zh: result.summaryZh, en: result.summaryEn),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (leader != null) ...<Widget>[
          const SizedBox(height: 12),
          _WorkWorthBreakdownRow(
            label: _lifeText(context, zh: '当前首选', en: 'Current leader'),
            value: leader.candidate.company,
          ),
          _WorkWorthBreakdownRow(
            label: _lifeText(context, zh: '综合分', en: 'Weighted score'),
            value: leader.weightedScore.toStringAsFixed(1),
          ),
          _WorkWorthBreakdownRow(
            label: _lifeText(context, zh: '月可支配', en: 'Monthly surplus'),
            value: _money(leader.workWorth.monthlyDisposableIncome),
          ),
          _WorkWorthBreakdownRow(
            label: _lifeText(context, zh: '工作性价比', en: 'Work value'),
            value: leader.workWorth.valueScore.toStringAsFixed(2),
          ),
          if (runnerUp != null)
            _WorkWorthBreakdownRow(
              label: _lifeText(
                context,
                zh: '${runnerUp.candidate.company} 追平需加',
                en: '${runnerUp.candidate.company} raise to match',
              ),
              value: runnerUp.monthlyBaseRaiseToLeader == null
                  ? _lifeText(context, zh: '难以仅靠薪资追平', en: 'Not salary-only')
                  : _money(runnerUp.monthlyBaseRaiseToLeader!),
            ),
          const SizedBox(height: 12),
          _OfferReportGroup(
            title: _lifeText(context, zh: '主要优势', en: 'Strengths'),
            children: leader.strengths
                .map(
                  (item) => _OfferReportTile(
                    title: _lifeText(
                      context,
                      zh: item.titleZh,
                      en: item.titleEn,
                    ),
                    body: _lifeText(context, zh: item.bodyZh, en: item.bodyEn),
                    icon: Icons.thumb_up_alt_rounded,
                    color: const Color(0xFF4F9D69),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 10),
          _OfferReportGroup(
            title: _lifeText(context, zh: '需要核对', en: 'Risks to verify'),
            children: leader.flags.isEmpty
                ? <Widget>[
                    _OfferReportTile(
                      title: _lifeText(
                        context,
                        zh: '暂无明显红旗',
                        en: 'No major flag',
                      ),
                      body: _lifeText(
                        context,
                        zh: '仍建议核对合同主体、试用期、年终奖和社保缴纳口径。',
                        en: 'Still verify contract entity, probation terms, bonus rules, and social insurance.',
                      ),
                      icon: Icons.fact_check_rounded,
                      color: const Color(0xFF5586A3),
                    ),
                  ]
                : leader.flags
                      .map(
                        (flag) => _OfferReportTile(
                          title: _lifeText(
                            context,
                            zh: flag.titleZh,
                            en: flag.titleEn,
                          ),
                          body: _lifeText(
                            context,
                            zh: flag.bodyZh,
                            en: flag.bodyEn,
                          ),
                          icon: _flagIcon(flag.level),
                          color: _flagColor(flag.level),
                        ),
                      )
                      .toList(growable: false),
          ),
        ],
      ],
    );
  }

  Widget _referencePanel(BuildContext context) {
    return _LifeSettingsPanel(
      title: _lifeText(context, zh: '参考工具链', en: 'Reference toolchain'),
      subtitle: _lifeText(
        context,
        zh: '占位页底部保留了 Offer 打分、城市对比和 AI 笔试入口，本地页也保留外部来源和内部替代入口。',
        en: 'The placeholder keeps Offer scoring, city comparison, and AI interview links; this page keeps external and local alternatives.',
      ),
      children: <Widget>[
        _OfferReferenceAction(
          icon: Icons.star_rounded,
          title: _lifeText(context, zh: 'Offer 打分', en: 'Offer scoring'),
          body: _lifeText(
            context,
            zh: '外部参考 worthjob；本地可进入工作性价比计算器继续细算。',
            en: 'External worthjob reference; local work value calculator is available.',
          ),
          externalLabel: 'worthjob.zippland.com',
          onOpenExternal: () =>
              _openExternal(context, 'https://worthjob.zippland.com/'),
          onOpenLocal: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const _WorkWorthPage()),
          ),
        ),
        const SizedBox(height: 10),
        _OfferReferenceAction(
          icon: Icons.location_city_rounded,
          title: _lifeText(context, zh: '城市对比', en: 'City comparison'),
          body: _lifeText(
            context,
            zh: '外部参考 citycompare；本地可进入城市薪资对比工具核对生活成本。',
            en: 'External citycompare reference; local city salary compare can verify costs.',
          ),
          externalLabel: 'citycompare.zippland.com',
          onOpenExternal: () =>
              _openExternal(context, 'https://citycompare.zippland.com/'),
          onOpenLocal: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const _CitySalaryComparePage(),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _OfferReferenceAction(
          icon: Icons.record_voice_over_rounded,
          title: _lifeText(context, zh: 'AI 笔试/面试', en: 'AI interview'),
          body: _lifeText(
            context,
            zh: '外部参考 Snap-Solver；面试或笔试风险需结合岗位流程单独判断。',
            en: 'External Snap-Solver reference; interview or assessment risk should be judged separately.',
          ),
          externalLabel: 'snapsolver.zippland.com',
          onOpenExternal: () =>
              _openExternal(context, 'https://snapsolver.zippland.com/'),
        ),
        const SizedBox(height: 12),
        Text(
          _lifeText(
            context,
            zh: '本页不上传 Offer 数据，也不替代职业、法律、税务或财务建议；请用合同、HR 书面口径和真实工资条继续核验。',
            en: 'This page does not upload offer data and is not career, legal, tax, or financial advice. Verify with contracts, written HR terms, and real payroll details.',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _profileField(
    BuildContext context, {
    required TextEditingController controller,
    required String keyName,
    required String zh,
    required String en,
  }) {
    return TextField(
      key: ValueKey<String>('offer-select-profile-$keyName'),
      controller: controller,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: _lifeText(context, zh: zh, en: en),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _candidateTextField(
    BuildContext context, {
    required OfferSelectCandidate candidate,
    required String field,
    required String value,
    required String zh,
    required String en,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
  }) {
    return TextFormField(
      key: ValueKey<String>('offer-select-${candidate.id}-$field'),
      initialValue: value,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: _lifeText(context, zh: zh, en: en),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _candidateNumberField(
    BuildContext context, {
    required OfferSelectCandidate candidate,
    required String field,
    required double value,
    required String zh,
    required String en,
    required ValueChanged<double> onChanged,
    String? prefixText,
  }) {
    return TextFormField(
      key: ValueKey<String>('offer-select-${candidate.id}-$field'),
      initialValue: _formatNumber(value),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (text) {
        final parsed = double.tryParse(text.trim());
        if (parsed != null) {
          onChanged(parsed);
        }
      },
      decoration: InputDecoration(
        labelText: _lifeText(context, zh: zh, en: en),
        prefixText: prefixText,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _weightSlider(
    BuildContext context, {
    required String zh,
    required String en,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return _LifeSliderField(
      label: _lifeText(context, zh: zh, en: en),
      valueText: value.toStringAsFixed(2),
      value: value,
      min: 0,
      max: 3,
      divisions: 12,
      onChanged: onChanged,
    );
  }

  void _updateSelected(
    OfferSelectCandidate Function(OfferSelectCandidate candidate) update,
  ) {
    final index = _selectedIndex.clamp(0, _candidates.length - 1).toInt();
    setState(() {
      _candidates = <OfferSelectCandidate>[
        for (var i = 0; i < _candidates.length; i += 1)
          i == index ? update(_candidates[i]) : _candidates[i],
      ];
    });
  }

  void _addOffer() {
    final source = _selectedCandidate;
    final next = source.copyWith(
      id: 'offer_${DateTime.now().microsecondsSinceEpoch}',
      company: _lifeText(context, zh: '新 Offer', en: 'New offer'),
      role: '',
      city: '',
      rejected: false,
      pros: '',
      cons: '',
    );
    setState(() {
      _candidates = <OfferSelectCandidate>[..._candidates, next];
      _selectedIndex = _candidates.length - 1;
    });
  }

  void _removeSelectedOffer() {
    if (_candidates.length <= 1) {
      return;
    }
    final index = _selectedIndex.clamp(0, _candidates.length - 1).toInt();
    setState(() {
      _candidates = <OfferSelectCandidate>[
        for (var i = 0; i < _candidates.length; i += 1)
          if (i != index) _candidates[i],
      ];
      _selectedIndex = math.min(index, _candidates.length - 1);
    });
  }

  void _toggleRejected() {
    _updateSelected(
      (candidate) => candidate.copyWith(rejected: !candidate.rejected),
    );
  }

  void _resetOffers() {
    setState(() {
      _candidates = ToolboxOfferSelectService.defaultCandidates.toList();
      _weights = OfferSelectWeights.balanced;
      _selectedIndex = 0;
    });
  }

  Future<void> _copySummary(OfferSelectResult result) async {
    final leader = result.leader;
    final lines = <String>[
      result.profile.title,
      result.summaryZh,
      if (leader != null) ...<String>[
        '首选: ${leader.candidate.company} / ${leader.candidate.role}',
        '综合分: ${leader.weightedScore.toStringAsFixed(1)}',
        '月可支配: ${_money(leader.workWorth.monthlyDisposableIncome)}',
        '风险: ${leader.flags.isEmpty ? '暂无明显红旗' : leader.flags.map((flag) => flag.titleZh).join('、')}',
      ],
    ];
    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _lifeText(context, zh: '已复制 Offer 决策摘要', en: 'Offer summary copied'),
        ),
      ),
    );
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }
}

class _OfferSelectStage extends StatelessWidget {
  const _OfferSelectStage({required this.result, required this.onCopy});

  final OfferSelectResult result;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final leader = result.leader;
    final runnerUp = result.runnerUp;
    return Container(
      key: const ValueKey<String>('offer-select-stage'),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF16453E),
            Color(0xFF3E6D58),
            Color(0xFFD39353),
          ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF16453E).withValues(alpha: 0.22),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _lifeText(context, zh: '当前推荐', en: 'Current pick'),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      leader?.candidate.company ??
                          _lifeText(context, zh: '等待 Offer', en: 'Waiting'),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      leader == null
                          ? _lifeText(
                              context,
                              zh: '添加或取消婉拒后开始比较。',
                              en: 'Add or un-reject offers to compare.',
                            )
                          : '${leader.candidate.role} · ${leader.candidate.city}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.84),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: _lifeText(context, zh: '复制摘要', en: 'Copy summary'),
                onPressed: leader == null ? null : onCopy,
                icon: const Icon(Icons.copy_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _lifeText(context, zh: result.summaryZh, en: result.summaryEn),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _OfferStagePill(
                label: _lifeText(context, zh: '综合分', en: 'Score'),
                value: leader == null
                    ? '--'
                    : leader.weightedScore.toStringAsFixed(1),
              ),
              _OfferStagePill(
                label: _lifeText(context, zh: '月可支配', en: 'Monthly surplus'),
                value: leader == null
                    ? '--'
                    : _money(leader.workWorth.monthlyDisposableIncome),
              ),
              _OfferStagePill(
                label: _lifeText(context, zh: '工作性价比', en: 'Work value'),
                value: leader == null
                    ? '--'
                    : leader.workWorth.valueScore.toStringAsFixed(2),
              ),
              _OfferStagePill(
                label: _lifeText(context, zh: '领先差距', en: 'Lead gap'),
                value: runnerUp == null
                    ? '--'
                    : result.leaderGap.toStringAsFixed(1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OfferStagePill extends StatelessWidget {
  const _OfferStagePill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 126),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
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

class _OfferEvaluationCard extends StatelessWidget {
  const _OfferEvaluationCard({required this.evaluation, this.rank});

  final OfferSelectEvaluation evaluation;
  final int? rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final candidate = evaluation.candidate;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: candidate.rejected
            ? theme.colorScheme.surfaceContainerLowest
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: candidate.rejected
              ? theme.colorScheme.outlineVariant
              : _offerScoreColor(
                  evaluation.weightedScore,
                ).withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 18,
                backgroundColor: _offerScoreColor(
                  evaluation.weightedScore,
                ).withValues(alpha: 0.18),
                foregroundColor: _offerScoreColor(evaluation.weightedScore),
                child: Text(rank == null ? '-' : '$rank'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      candidate.company,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${candidate.role} · ${candidate.city}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                evaluation.weightedScore.toStringAsFixed(1),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: _offerScoreColor(evaluation.weightedScore),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _OfferSmallPill(
                label: _lifeText(context, zh: '年包', en: 'Annual'),
                value: _money(candidate.annualGrossIncome),
              ),
              _OfferSmallPill(
                label: _lifeText(context, zh: '月可支配', en: 'Surplus'),
                value: _money(evaluation.workWorth.monthlyDisposableIncome),
              ),
              _OfferSmallPill(
                label: _lifeText(context, zh: '时间成本', en: 'Time'),
                value:
                    '${evaluation.workWorth.effectiveTimeCostHours.toStringAsFixed(1)}h',
              ),
              _OfferSmallPill(
                label: _lifeText(context, zh: '追平加薪', en: 'Raise'),
                value: evaluation.monthlyBaseRaiseToLeader == null
                    ? '--'
                    : _money(evaluation.monthlyBaseRaiseToLeader!),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _OfferDimensionBar(
            label: _lifeText(context, zh: '现金', en: 'Cash'),
            score: evaluation.cashScore,
          ),
          _OfferDimensionBar(
            label: _lifeText(context, zh: '时间', en: 'Time'),
            score: evaluation.timeScore,
          ),
          _OfferDimensionBar(
            label: _lifeText(context, zh: '健康', en: 'Health'),
            score: evaluation.healthScore,
          ),
          _OfferDimensionBar(
            label: _lifeText(context, zh: '成长', en: 'Growth'),
            score: evaluation.growthScore,
          ),
          _OfferDimensionBar(
            label: _lifeText(context, zh: '稳定', en: 'Stable'),
            score: evaluation.stabilityScore,
          ),
          _OfferDimensionBar(
            label: _lifeText(context, zh: '城市', en: 'City'),
            score: evaluation.cityFitScore,
          ),
          if (evaluation.flags.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: evaluation.flags
                  .map(
                    (flag) => Chip(
                      visualDensity: VisualDensity.compact,
                      avatar: Icon(
                        _flagIcon(flag.level),
                        size: 16,
                        color: _flagColor(flag.level),
                      ),
                      label: Text(
                        _lifeText(context, zh: flag.titleZh, en: flag.titleEn),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}

class _OfferSmallPill extends StatelessWidget {
  const _OfferSmallPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.62,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label $value',
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _OfferDimensionBar extends StatelessWidget {
  const _OfferDimensionBar({required this.label, required this.score});

  final String label;
  final double score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _dimensionColor(score);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 54,
            child: Text(label, style: theme.textTheme.labelMedium),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (score / 100).clamp(0.0, 1.0).toDouble(),
                minHeight: 8,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 38,
            child: Text(
              score.toStringAsFixed(0),
              textAlign: TextAlign.end,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferReportGroup extends StatelessWidget {
  const _OfferReportGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

class _OfferReportTile extends StatelessWidget {
  const _OfferReportTile({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(body, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferReferenceAction extends StatelessWidget {
  const _OfferReferenceAction({
    required this.icon,
    required this.title,
    required this.body,
    required this.externalLabel,
    required this.onOpenExternal,
    this.onOpenLocal,
  });

  final IconData icon;
  final String title;
  final String body;
  final String externalLabel;
  final VoidCallback onOpenExternal;
  final VoidCallback? onOpenLocal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(body, style: theme.textTheme.bodySmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: onOpenExternal,
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(externalLabel),
              ),
              if (onOpenLocal != null)
                FilledButton.tonalIcon(
                  onPressed: onOpenLocal,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(_lifeText(context, zh: '本地工具', en: 'Local tool')),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

Color _offerScoreColor(double score) {
  if (score < 45) {
    return const Color(0xFFD46666);
  }
  if (score < 62) {
    return const Color(0xFFD58A3D);
  }
  if (score < 76) {
    return const Color(0xFF4F9D69);
  }
  return const Color(0xFF2C8C8C);
}

Color _dimensionColor(double score) {
  if (score < 45) {
    return const Color(0xFFD46666);
  }
  if (score < 65) {
    return const Color(0xFFD99B42);
  }
  if (score < 80) {
    return const Color(0xFF6AA66A);
  }
  return const Color(0xFF2C8C8C);
}

IconData _flagIcon(OfferSelectFlagLevel level) {
  return switch (level) {
    OfferSelectFlagLevel.info => Icons.info_outline_rounded,
    OfferSelectFlagLevel.warning => Icons.warning_amber_rounded,
    OfferSelectFlagLevel.danger => Icons.error_outline_rounded,
  };
}

Color _flagColor(OfferSelectFlagLevel level) {
  return switch (level) {
    OfferSelectFlagLevel.info => const Color(0xFF5586A3),
    OfferSelectFlagLevel.warning => const Color(0xFFD58A3D),
    OfferSelectFlagLevel.danger => const Color(0xFFD46666),
  };
}
