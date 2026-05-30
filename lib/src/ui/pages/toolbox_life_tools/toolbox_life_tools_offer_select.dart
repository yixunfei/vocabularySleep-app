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
      title: _lifeI18nText(
        context,
        'inline.plan295.life.offer_selector.f837d5d3336b',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.local_multi_offer_scoring_risk_break.a820cddf9d5c',
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
      title: _lifeI18nText(context, 'inline.plan295.life.profile.c64fca252d00'),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.keeps_the_reference_page_profile_fie.2ad4a62a7ae5',
      ),
      children: <Widget>[
        _WorkWorthFieldGrid(
          children: <Widget>[
            _profileField(
              context,
              controller: _title,
              keyName: 'title',
              labelKey: 'life.offer_select.field.title',
            ),
            _profileField(
              context,
              controller: _background,
              keyName: 'background',
              labelKey: 'life.offer_select.field.background',
            ),
            _profileField(
              context,
              controller: _major,
              keyName: 'major',
              labelKey: 'life.offer_select.field.major',
            ),
            _profileField(
              context,
              controller: _experience,
              keyName: 'experience',
              labelKey: 'life.offer_select.field.experience',
            ),
          ],
        ),
      ],
    );
  }

  Widget _offerSelectorPanel(BuildContext context, OfferSelectResult result) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(context, 'inline.plan295.life.offers.02524fb1c5d5'),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.rejected_offers_remain_visible_for_r.2acec057de23',
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
                      ? '${_candidates[index].company} · ${_lifeI18nText(context, 'inline.plan295.life.rejected.27e29e9e26de')}'
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
              label: Text(
                _lifeI18nText(context, 'inline.plan295.life.add.d800ae076568'),
              ),
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
                    ? _lifeI18nText(
                        context,
                        'inline.plan295.life.un_reject.4e0373513b3e',
                      )
                    : _lifeI18nText(
                        context,
                        'inline.plan295.life.reject.5e08baa15c65',
                      ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _candidates.length <= 1 ? null : _removeSelectedOffer,
              icon: const Icon(Icons.delete_outline_rounded),
              label: Text(_lifeI18nText(context, 'delete')),
            ),
            OutlinedButton.icon(
              onPressed: _resetOffers,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                _lifeI18nText(
                  context,
                  'inline.plan295.life.reset_sample.da2f6b5e893c',
                ),
              ),
            ),
          ],
        ),
        if (result.rejectedEvaluations.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Text(
            _lifeI18nText(
              context,
              'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.offer.select.rejected.2af7780d38',
              params: <String, Object?>{
                'length': result.rejectedEvaluations.length,
              },
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
      title: _lifeI18nText(
        context,
        'inline.plan295.life.edit_selected_offer.660ee8a8a879',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.fields_map_to_company_salary_benefit.901a292c7b78',
      ),
      children: <Widget>[
        _WorkWorthFieldGrid(
          children: <Widget>[
            _candidateTextField(
              context,
              candidate: candidate,
              field: 'company',
              value: candidate.company,
              labelKey: 'life.offer_select.field.company',
              onChanged: (value) =>
                  _updateSelected((item) => item.copyWith(company: value)),
            ),
            _candidateTextField(
              context,
              candidate: candidate,
              field: 'role',
              value: candidate.role,
              labelKey: 'life.offer_select.field.role',
              onChanged: (value) =>
                  _updateSelected((item) => item.copyWith(role: value)),
            ),
            _candidateTextField(
              context,
              candidate: candidate,
              field: 'city',
              value: candidate.city,
              labelKey: 'life.offer_select.field.location',
              onChanged: (value) =>
                  _updateSelected((item) => item.copyWith(city: value)),
            ),
            _candidateTextField(
              context,
              candidate: candidate,
              field: 'schedule',
              value: candidate.workSchedule,
              labelKey: 'life.offer_select.field.schedule',
              onChanged: (value) =>
                  _updateSelected((item) => item.copyWith(workSchedule: value)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          _lifeI18nText(context, 'inline.plan295.life.salary.5e92cc278c7f'),
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
              labelKey: 'life.offer_select.field.monthly_base',
              prefixText: '¥ ',
              onChanged: (value) =>
                  _updateSelected((item) => item.copyWith(monthlyBase: value)),
            ),
            _candidateNumberField(
              context,
              candidate: candidate,
              field: 'months',
              value: candidate.salaryMonths,
              labelKey: 'life.offer_select.field.salary_months',
              onChanged: (value) =>
                  _updateSelected((item) => item.copyWith(salaryMonths: value)),
            ),
            _candidateNumberField(
              context,
              candidate: candidate,
              field: 'bonus',
              value: candidate.otherBonus,
              labelKey: 'life.offer_select.field.other_bonus_equity',
              prefixText: '¥ ',
              onChanged: (value) =>
                  _updateSelected((item) => item.copyWith(otherBonus: value)),
            ),
            _candidateNumberField(
              context,
              candidate: candidate,
              field: 'tax',
              value: candidate.monthlyTax,
              labelKey: 'life.work_worth.field.monthly_tax',
              prefixText: '¥ ',
              onChanged: (value) =>
                  _updateSelected((item) => item.copyWith(monthlyTax: value)),
            ),
            _candidateNumberField(
              context,
              candidate: candidate,
              field: 'insurance-fund',
              value: candidate.monthlyInsuranceFund,
              labelKey: 'life.work_worth.field.insurance_fund',
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
              labelKey: 'life.work_worth.field.monthly_benefits',
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
              labelKey: 'life.offer_select.field.housing_cost',
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
              labelKey: 'life.work_worth.field.living_cost',
              prefixText: '¥ ',
              onChanged: (value) => _updateSelected(
                (item) => item.copyWith(monthlyLivingCost: value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _LifeSliderField(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.bonus_certainty.af7ff432a0d1',
          ),
          valueText: '${(candidate.bonusCertainty * 100).round()}%',
          value: candidate.bonusCertainty,
          min: 0,
          max: 1,
          divisions: 10,
          onChanged: (value) =>
              _updateSelected((item) => item.copyWith(bonusCertainty: value)),
        ),
        _LifeSliderField(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.salary_rating.360649d132d5',
          ),
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
          _lifeI18nText(
            context,
            'inline.plan295.life.time_and_wlb.ba28354c6420',
          ),
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
              labelKey: 'life.work_worth.field.workdays_week',
              onChanged: (value) => _updateSelected(
                (item) => item.copyWith(workDaysPerWeek: value),
              ),
            ),
            _candidateNumberField(
              context,
              candidate: candidate,
              field: 'wfh-days',
              value: candidate.workFromHomeDaysPerWeek,
              labelKey: 'life.work_worth.field.wfh_days_week',
              onChanged: (value) => _updateSelected(
                (item) => item.copyWith(workFromHomeDaysPerWeek: value),
              ),
            ),
            _candidateNumberField(
              context,
              candidate: candidate,
              field: 'work-hours',
              value: candidate.workHoursPerDay,
              labelKey: 'life.work_worth.field.work_hours_day',
              onChanged: (value) => _updateSelected(
                (item) => item.copyWith(workHoursPerDay: value),
              ),
            ),
            _candidateNumberField(
              context,
              candidate: candidate,
              field: 'commute-hours',
              value: candidate.commuteHoursPerDay,
              labelKey: 'life.work_worth.field.commute_hours_day',
              onChanged: (value) => _updateSelected(
                (item) => item.copyWith(commuteHoursPerDay: value),
              ),
            ),
            _candidateNumberField(
              context,
              candidate: candidate,
              field: 'rest-hours',
              value: candidate.restHoursPerDay,
              labelKey: 'life.work_worth.field.rest_hours_day',
              onChanged: (value) => _updateSelected(
                (item) => item.copyWith(restHoursPerDay: value),
              ),
            ),
            _candidateNumberField(
              context,
              candidate: candidate,
              field: 'unpaid-overtime',
              value: candidate.unpaidOvertimeHoursPerMonth,
              labelKey: 'life.work_worth.field.unpaid_overtime_month',
              onChanged: (value) => _updateSelected(
                (item) => item.copyWith(unpaidOvertimeHoursPerMonth: value),
              ),
            ),
            _candidateNumberField(
              context,
              candidate: candidate,
              field: 'annual-leave',
              value: candidate.annualLeaveDays,
              labelKey: 'life.work_worth.field.annual_leave',
              onChanged: (value) => _updateSelected(
                (item) => item.copyWith(annualLeaveDays: value),
              ),
            ),
            _candidateNumberField(
              context,
              candidate: candidate,
              field: 'paid-sick',
              value: candidate.paidSickLeaveDays,
              labelKey: 'life.work_worth.field.paid_sick_leave',
              onChanged: (value) => _updateSelected(
                (item) => item.copyWith(paidSickLeaveDays: value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _LifeSliderField(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.wlb_rating.f377a58ecf55',
          ),
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
              labelKey: 'life.offer_select.field.benefits',
              maxLines: 2,
              onChanged: (value) =>
                  _updateSelected((item) => item.copyWith(benefits: value)),
            ),
            _candidateTextField(
              context,
              candidate: candidate,
              field: 'social-insurance',
              value: candidate.socialInsurance,
              labelKey: 'life.offer_select.field.social_insurance',
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
              labelKey: 'life.offer_select.field.pros',
              maxLines: 3,
              onChanged: (value) =>
                  _updateSelected((item) => item.copyWith(pros: value)),
            ),
            _candidateTextField(
              context,
              candidate: candidate,
              field: 'cons',
              value: candidate.cons,
              labelKey: 'life.offer_select.field.cons',
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
          label: _lifeI18nText(
            context,
            'inline.plan295.life.work_environment.f0cbd11a8ea6',
          ),
          value: candidate.environment,
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
          onChanged: (value) =>
              _updateSelected((item) => item.copyWith(environment: value)),
        ),
        const SizedBox(height: 14),
        _LifeSegmentedField<WorkWorthJobStability>(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.job_stability.1f5a665df6e2',
          ),
          value: candidate.stability,
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
          onChanged: (value) =>
              _updateSelected((item) => item.copyWith(stability: value)),
        ),
        const SizedBox(height: 10),
        _LifeSliderField(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.offer_certainty.2d2abf45a9db',
          ),
          valueText: '${(candidate.offerCertainty * 100).round()}%',
          value: candidate.offerCertainty,
          min: 0,
          max: 1,
          divisions: 10,
          onChanged: (value) =>
              _updateSelected((item) => item.copyWith(offerCertainty: value)),
        ),
        _LifeSliderField(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.city_fit.d501f6f05591',
          ),
          valueText: candidate.cityFitFactor.toStringAsFixed(2),
          value: candidate.cityFitFactor,
          min: 0.7,
          max: 1.35,
          divisions: 13,
          onChanged: (value) =>
              _updateSelected((item) => item.copyWith(cityFitFactor: value)),
        ),
        _LifeSliderField(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.role_fit.db0376021b71',
          ),
          valueText: candidate.roleMatchFactor.toStringAsFixed(2),
          value: candidate.roleMatchFactor,
          min: 0.75,
          max: 1.35,
          divisions: 12,
          onChanged: (value) =>
              _updateSelected((item) => item.copyWith(roleMatchFactor: value)),
        ),
        _LifeSliderField(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.growth_potential.88b829804ac5',
          ),
          valueText: candidate.growthFactor.toStringAsFixed(2),
          value: candidate.growthFactor,
          min: 0.75,
          max: 1.35,
          divisions: 12,
          onChanged: (value) =>
              _updateSelected((item) => item.copyWith(growthFactor: value)),
        ),
        _LifeSliderField(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.boundary_quality.ab74932885fc',
          ),
          valueText: candidate.boundaryFactor.toStringAsFixed(2),
          value: candidate.boundaryFactor,
          min: 0.7,
          max: 1.2,
          divisions: 10,
          onChanged: (value) =>
              _updateSelected((item) => item.copyWith(boundaryFactor: value)),
        ),
        _LifeSliderField(
          label: _lifeI18nText(
            context,
            'inline.plan295.life.psychological_safety.10a0bcbdc985',
          ),
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
          label: _lifeI18nText(
            context,
            'inline.plan295.life.autonomy.a46fa9b788ab',
          ),
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
      title: _lifeI18nText(
        context,
        'inline.plan295.life.decision_weights.7255c60ea566',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.higher_weight_means_that_dimension_a.2bc7c82cb979',
      ),
      children: <Widget>[
        _weightSlider(
          context,
          labelKey: 'life.offer_select.weight.cashflow',
          value: _weights.cashflow,
          onChanged: (value) =>
              setState(() => _weights = _weights.copyWith(cashflow: value)),
        ),
        _weightSlider(
          context,
          labelKey: 'life.offer_select.weight.time',
          value: _weights.time,
          onChanged: (value) =>
              setState(() => _weights = _weights.copyWith(time: value)),
        ),
        _weightSlider(
          context,
          labelKey: 'life.offer_select.weight.health',
          value: _weights.health,
          onChanged: (value) =>
              setState(() => _weights = _weights.copyWith(health: value)),
        ),
        _weightSlider(
          context,
          labelKey: 'life.offer_select.weight.growth',
          value: _weights.growth,
          onChanged: (value) =>
              setState(() => _weights = _weights.copyWith(growth: value)),
        ),
        _weightSlider(
          context,
          labelKey: 'life.offer_select.weight.stability',
          value: _weights.stability,
          onChanged: (value) =>
              setState(() => _weights = _weights.copyWith(stability: value)),
        ),
        _weightSlider(
          context,
          labelKey: 'life.offer_select.weight.city_fit',
          value: _weights.cityFit,
          onChanged: (value) =>
              setState(() => _weights = _weights.copyWith(cityFit: value)),
        ),
      ],
    );
  }

  Widget _comparisonPanel(BuildContext context, OfferSelectResult result) {
    return _LifeSettingsPanel(
      title: _lifeI18nText(
        context,
        'inline.plan295.life.ranking_breakdown.c320ef5aa9da',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.scores_combine_cash_time_health_grow.dd9b514e4aaf',
      ),
      children: <Widget>[
        if (result.activeEvaluations.isEmpty)
          Text(
            _lifeI18nText(
              context,
              'inline.plan295.life.no_active_offers_yet.b957efaee91e',
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
            _lifeI18nText(
              context,
              'inline.plan295.life.rejected_reference.76e61b02beec',
            ),
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
      title: _lifeI18nText(
        context,
        'inline.plan295.life.decision_report.ae3d59cf851b',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.review_strengths_risks_and_negotiati.14f6fb01cff6',
      ),
      children: <Widget>[
        Text(
          _lifeI18nRefText(context, result.summary),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (leader != null) ...<Widget>[
          const SizedBox(height: 12),
          _WorkWorthBreakdownRow(
            label: _lifeI18nText(
              context,
              'inline.plan295.life.current_leader.09a39be74d8b',
            ),
            value: leader.candidate.company,
          ),
          _WorkWorthBreakdownRow(
            label: _lifeI18nText(
              context,
              'inline.plan295.life.weighted_score.f1db81085d06',
            ),
            value: leader.weightedScore.toStringAsFixed(1),
          ),
          _WorkWorthBreakdownRow(
            label: _lifeI18nText(
              context,
              'inline.plan295.life.monthly_surplus.f916fcdabd72',
            ),
            value: _money(leader.workWorth.monthlyDisposableIncome),
          ),
          _WorkWorthBreakdownRow(
            label: _lifeI18nText(
              context,
              'inline.plan295.life.work_value.ef23a7f39470',
            ),
            value: leader.workWorth.valueScore.toStringAsFixed(2),
          ),
          if (runnerUp != null)
            _WorkWorthBreakdownRow(
              label: _lifeI18nText(
                context,
                'inline.plan296.ui.pages.toolbox.life.tools.toolbox.life.tools.offer.select.raise_to_match.637a3c4320',
                params: <String, Object?>{
                  'company': runnerUp.candidate.company,
                },
              ),
              value: runnerUp.monthlyBaseRaiseToLeader == null
                  ? _lifeI18nText(
                      context,
                      'inline.plan295.life.not_salary_only.6a8f4ba6a76f',
                    )
                  : _money(runnerUp.monthlyBaseRaiseToLeader!),
            ),
          const SizedBox(height: 12),
          _OfferReportGroup(
            title: _lifeI18nText(
              context,
              'inline.plan295.life.strengths.79a777f9f3f2',
            ),
            children: leader.strengths
                .map(
                  (item) => _OfferReportTile(
                    title: _lifeI18nText(context, item.titleKey),
                    body: _lifeI18nRefText(context, item.body),
                    icon: Icons.thumb_up_alt_rounded,
                    color: const Color(0xFF4F9D69),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 10),
          _OfferReportGroup(
            title: _lifeI18nText(
              context,
              'inline.plan295.life.risks_to_verify.9dd36c544784',
            ),
            children: leader.flags.isEmpty
                ? <Widget>[
                    _OfferReportTile(
                      title: _lifeI18nText(
                        context,
                        'inline.plan295.life.no_major_flag.1aa15daef044',
                      ),
                      body: _lifeI18nText(
                        context,
                        'inline.plan295.life.still_verify_contract_entity_probati.36981722a092',
                      ),
                      icon: Icons.fact_check_rounded,
                      color: const Color(0xFF5586A3),
                    ),
                  ]
                : leader.flags
                      .map(
                        (flag) => _OfferReportTile(
                          title: _lifeI18nText(context, flag.titleKey),
                          body: _lifeI18nRefText(context, flag.body),
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
      title: _lifeI18nText(
        context,
        'inline.plan295.life.reference_toolchain.518c3d00dd40',
      ),
      subtitle: _lifeI18nText(
        context,
        'inline.plan295.life.the_placeholder_keeps_offer_scoring.e8af46f5b68a',
      ),
      children: <Widget>[
        _OfferReferenceAction(
          icon: Icons.star_rounded,
          title: _lifeI18nText(
            context,
            'inline.plan295.life.offer_scoring.c8986066e42a',
          ),
          body: _lifeI18nText(
            context,
            'inline.plan295.life.external_worthjob_reference_local_wo.4423bfa88da8',
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
          title: _lifeI18nText(
            context,
            'inline.plan295.life.city_comparison.31f81b0fe684',
          ),
          body: _lifeI18nText(
            context,
            'inline.plan295.life.external_citycompare_reference_local.1d38526b411a',
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
          title: _lifeI18nText(
            context,
            'inline.plan295.life.ai_interview.11548fe27ba1',
          ),
          body: _lifeI18nText(
            context,
            'inline.plan295.life.external_snap_solver_reference_inter.d1ea66d33a86',
          ),
          externalLabel: 'snapsolver.zippland.com',
          onOpenExternal: () =>
              _openExternal(context, 'https://snapsolver.zippland.com/'),
        ),
        const SizedBox(height: 12),
        Text(
          _lifeI18nText(
            context,
            'inline.plan295.life.this_page_does_not_upload_offer_data.8431099903fe',
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
    required String labelKey,
  }) {
    return TextField(
      key: ValueKey<String>('offer-select-profile-$keyName'),
      controller: controller,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: _lifeI18nText(context, labelKey),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _candidateTextField(
    BuildContext context, {
    required OfferSelectCandidate candidate,
    required String field,
    required String value,
    required String labelKey,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
  }) {
    return TextFormField(
      key: ValueKey<String>('offer-select-${candidate.id}-$field'),
      initialValue: value,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: _lifeI18nText(context, labelKey),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _candidateNumberField(
    BuildContext context, {
    required OfferSelectCandidate candidate,
    required String field,
    required double value,
    required String labelKey,
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
        labelText: _lifeI18nText(context, labelKey),
        prefixText: prefixText,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _weightSlider(
    BuildContext context, {
    required String labelKey,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return _LifeSliderField(
      label: _lifeI18nText(context, labelKey),
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
      company: _lifeI18nText(
        context,
        'inline.plan295.life.new_offer.fdb1f3970e7d',
      ),
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
      _lifeI18nRefText(context, result.summary),
      if (leader != null) ...<String>[
        _lifeI18nText(
          context,
          'life.offer_select.copy.line_leader',
          params: <String, Object?>{
            'company': leader.candidate.company,
            'role': leader.candidate.role,
          },
        ),
        _lifeI18nText(
          context,
          'life.offer_select.copy.line_score',
          params: <String, Object?>{
            'score': leader.weightedScore.toStringAsFixed(1),
          },
        ),
        _lifeI18nText(
          context,
          'life.offer_select.copy.line_surplus',
          params: <String, Object?>{
            'amount': _money(leader.workWorth.monthlyDisposableIncome),
          },
        ),
        _lifeI18nText(
          context,
          'life.offer_select.copy.line_risks',
          params: <String, Object?>{
            'risks': leader.flags.isEmpty
                ? _lifeI18nText(
                    context,
                    'life.offer_select.copy.no_major_flags',
                  )
                : leader.flags
                      .map((flag) => _lifeI18nText(context, flag.titleKey))
                      .join(
                        _lifeI18nText(context, 'life.offer_select.copy.joiner'),
                      ),
          },
        ),
      ],
    ];
    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _lifeI18nText(
            context,
            'inline.plan295.life.offer_summary_copied.6410ba779412',
          ),
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
                      _lifeI18nText(
                        context,
                        'inline.plan295.life.current_pick.1b1b8383ca11',
                      ),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      leader?.candidate.company ??
                          _lifeI18nText(
                            context,
                            'inline.plan295.life.waiting.22b93486ae77',
                          ),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      leader == null
                          ? _lifeI18nText(
                              context,
                              'inline.plan295.life.add_or_un_reject_offers_to_compare.7b7d743789c4',
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
                tooltip: _lifeI18nText(
                  context,
                  'inline.plan295.life.copy_summary.ee52d3a03cb9',
                ),
                onPressed: leader == null ? null : onCopy,
                icon: const Icon(Icons.copy_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _lifeI18nRefText(context, result.summary),
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
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.score.e58eff17f23d',
                ),
                value: leader == null
                    ? '--'
                    : leader.weightedScore.toStringAsFixed(1),
              ),
              _OfferStagePill(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.monthly_surplus.f916fcdabd72',
                ),
                value: leader == null
                    ? '--'
                    : _money(leader.workWorth.monthlyDisposableIncome),
              ),
              _OfferStagePill(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.work_value.ef23a7f39470',
                ),
                value: leader == null
                    ? '--'
                    : leader.workWorth.valueScore.toStringAsFixed(2),
              ),
              _OfferStagePill(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.lead_gap.9e841c691786',
                ),
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
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.annual.d66f4216f8e5',
                ),
                value: _money(candidate.annualGrossIncome),
              ),
              _OfferSmallPill(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.surplus.81af185157be',
                ),
                value: _money(evaluation.workWorth.monthlyDisposableIncome),
              ),
              _OfferSmallPill(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.time.bf469a617001',
                ),
                value:
                    '${evaluation.workWorth.effectiveTimeCostHours.toStringAsFixed(1)}h',
              ),
              _OfferSmallPill(
                label: _lifeI18nText(
                  context,
                  'inline.plan295.life.raise.51399a81a759',
                ),
                value: evaluation.monthlyBaseRaiseToLeader == null
                    ? '--'
                    : _money(evaluation.monthlyBaseRaiseToLeader!),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _OfferDimensionBar(
            label: _lifeI18nText(
              context,
              'inline.plan295.life.cash.66a79d2bb5cd',
            ),
            score: evaluation.cashScore,
          ),
          _OfferDimensionBar(
            label: _lifeI18nText(
              context,
              'inline.ui.pages.toolbox_human_tests_typing.time_b4685a',
            ),
            score: evaluation.timeScore,
          ),
          _OfferDimensionBar(
            label: _lifeI18nText(context, 'ref.toolbox.sleep.library.tag.risk'),
            score: evaluation.healthScore,
          ),
          _OfferDimensionBar(
            label: _lifeI18nText(
              context,
              'inline.plan295.life.growth.724aea94f308',
            ),
            score: evaluation.growthScore,
          ),
          _OfferDimensionBar(
            label: _lifeI18nText(
              context,
              'inline.ui.pages.toolbox_human_tests_typing_copy.stable_a3445e',
            ),
            score: evaluation.stabilityScore,
          ),
          _OfferDimensionBar(
            label: _lifeI18nText(
              context,
              'inline.plan295.life.city.cf347ec437c3',
            ),
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
                      label: Text(_lifeI18nText(context, flag.titleKey)),
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
                  label: Text(
                    _lifeI18nText(
                      context,
                      'inline.plan295.life.local_tool.f3ddb606921a',
                    ),
                  ),
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
