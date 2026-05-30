import 'package:flutter/material.dart';

import '../../../i18n/app_i18n.dart';
import 'daily_choice_decision_engine.dart';
import 'daily_choice_models.dart';

class DailyChoiceDecisionMethodSpec {
  const DailyChoiceDecisionMethodSpec({
    required this.method,
    required this.icon,
    required this.titleKey,
    required this.subtitleKey,
    required this.formulaKey,
    required this.cautionKey,
  });

  final DailyChoiceDecisionMethod method;
  final IconData icon;
  final String titleKey;
  final String subtitleKey;
  final String formulaKey;
  final String cautionKey;

  String title(AppI18n i18n) => i18n.t(titleKey);

  String subtitle(AppI18n i18n) => i18n.t(subtitleKey);

  String formula(AppI18n i18n) => i18n.t(formulaKey);

  String caution(AppI18n i18n) => i18n.t(cautionKey);
}

DailyChoiceDecisionMethodSpec decisionMethodSpec(
  DailyChoiceDecisionMethod method,
) {
  return switch (method) {
    DailyChoiceDecisionMethod.random => const DailyChoiceDecisionMethodSpec(
      method: DailyChoiceDecisionMethod.random,
      icon: Icons.casino_rounded,
        titleKey: 'inline.ui.pages.toolbox_daily_choice.daily_choice_custom_random_widgets.uniform_random_851942',
        subtitleKey: 'inline.plan295.daily_choice.best_for_low_stakes_reversible_choic.49b02cca4e88',
        formulaKey: 'inline.plan295.daily_choice.each_option_gets_the_same_chance_the.530c0754efc4',
        cautionKey: 'inline.plan295.daily_choice.do_not_use_random_choice_for_high_st.a4b7bf74d435'),
    DailyChoiceDecisionMethod.weightedFactors =>
      const DailyChoiceDecisionMethodSpec(
        method: DailyChoiceDecisionMethod.weightedFactors,
        icon: Icons.tune_rounded,
        titleKey: 'toolbox.daily_choice.weighted_factors',
        subtitleKey: 'inline.plan295.daily_choice.compare_value_success_odds_reversibi.bb60361dc10d',
        formulaKey: 'inline.plan295.daily_choice.weighted_positives_minus_penalties_f.0a2df1c694a2',
        cautionKey: 'inline.plan295.daily_choice.useful_for_ranking_not_for_claiming.20c9bff74b77'),
    DailyChoiceDecisionMethod.expectedValue =>
      const DailyChoiceDecisionMethodSpec(
        method: DailyChoiceDecisionMethod.expectedValue,
        icon: Icons.functions_rounded,
        titleKey: 'inline.plan295.daily_choice.expected_value.794b96c77f96',
        subtitleKey: 'inline.plan295.daily_choice.best_for_uncertain_outcomes_when_you.7df1ac1849b5',
        formulaKey: 'inline.plan295.daily_choice.success_probability_upside_downside.1121b1821c12',
        cautionKey: 'inline.plan295.daily_choice.your_inputs_are_still_judgments_so_e.6f65d3599cf4'),
    DailyChoiceDecisionMethod.jointProbability => const DailyChoiceDecisionMethodSpec(
      method: DailyChoiceDecisionMethod.jointProbability,
      icon: Icons.account_tree_rounded,
        titleKey: 'toolbox.daily_choice.joint_probability',
        subtitleKey: 'inline.plan295.daily_choice.use_a_conservative_product_when_succ.895ecf0333e3',
        formulaKey: 'inline.plan295.daily_choice.success_probability_execution_probab.b6f2ee76e62e',
        cautionKey: 'inline.plan295.daily_choice.great_for_multi_step_dependence_weak.bb2794167cfc'),
    DailyChoiceDecisionMethod.scenarioBlend => const DailyChoiceDecisionMethodSpec(
      method: DailyChoiceDecisionMethod.scenarioBlend,
      icon: Icons.alt_route_rounded,
        titleKey: 'inline.plan295.daily_choice.scenario_blend.4e8073ad7308',
        subtitleKey: 'inline.plan295.daily_choice.blend_optimistic_base_and_pessimisti.5266aa331e22',
        formulaKey: 'inline.plan295.daily_choice.a_weighted_blend_of_optimistic_base.0c81b385db5b',
        cautionKey: 'inline.plan295.daily_choice.when_uncertainty_is_high_let_the_pes.6cfeb72c81c9'),
    DailyChoiceDecisionMethod.regretBalance => const DailyChoiceDecisionMethodSpec(
      method: DailyChoiceDecisionMethod.regretBalance,
      icon: Icons.history_toggle_off_rounded,
        titleKey: 'inline.plan295.daily_choice.regret_and_opportunity_cost.cfff906e06f8',
        subtitleKey: 'inline.plan295.daily_choice.useful_when_you_are_likely_to_revisi.b683c4218c87',
        formulaKey: 'inline.plan295.daily_choice.realized_upside_plus_reversibility_b.860a2ba330ac',
        cautionKey: 'inline.plan295.daily_choice.this_lens_corrects_emotion_it_does_n.2ed3c8b413ed'),
    DailyChoiceDecisionMethod.thresholdGuardrail =>
      const DailyChoiceDecisionMethodSpec(
        method: DailyChoiceDecisionMethod.thresholdGuardrail,
        icon: Icons.rule_rounded,
        titleKey: 'inline.plan295.daily_choice.guardrails_first.7fb9a9ace5b2',
        subtitleKey: 'inline.plan295.daily_choice.check_minimum_standards_first_then_r.4e024f9b9ef3',
        formulaKey: 'inline.plan295.daily_choice.check_confidence_downside_reversibil.88742b8d959d',
        cautionKey: 'inline.plan295.daily_choice.in_high_stakes_situations_protect_th.2aae39e943dd'),
    DailyChoiceDecisionMethod.calibratedForecast =>
      const DailyChoiceDecisionMethodSpec(
        method: DailyChoiceDecisionMethod.calibratedForecast,
        icon: Icons.show_chart_rounded,
        titleKey: 'inline.plan295.daily_choice.calibrated_forecast.b196f3a7b02e',
        subtitleKey: 'inline.plan295.daily_choice.shrink_extreme_forecasts_back_toward.3d545d855d8d',
        formulaKey: 'inline.plan295.daily_choice.average_score_confidence_raw_forecas.f3588f3f19f9',
        cautionKey: 'inline.plan295.daily_choice.this_is_not_machine_learning_it_is_a.797f23988d39'),
  };
}

const List<DailyChoiceGuideModule>
decisionGuideModules = <DailyChoiceGuideModule>[
  DailyChoiceGuideModule(
    id: 'flow',
    icon: Icons.route_rounded,
    titleKey: 'inline.plan295.daily_choice.classify_before_choosing_a_method.5c362700c026',
    subtitleKey: 'inline.plan295.daily_choice.high_quality_decisions_start_by_iden.1ffc73c266e4',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.low_priority_rounded,
        titleKey: 'inline.plan295.daily_choice.low_stakes_and_reversible_decide_fas.85bd722073ee',
        bodyKey: 'inline.plan295.daily_choice.for_restaurants_weekend_plans_or_lig.51d951b6b143'),
      DailyChoiceGuideEntry(
        icon: Icons.warning_amber_rounded,
        titleKey: 'inline.plan295.daily_choice.high_stakes_or_hard_to_undo_set_guar.2c14a05dd003',
        bodyKey: 'inline.plan295.daily_choice.when_mistakes_are_costly_to_unwind_c.40085046f629'),
      DailyChoiceGuideEntry(
        icon: Icons.cloud_sync_rounded,
        titleKey: 'inline.plan295.daily_choice.high_uncertainty_bring_in_the_pessim.ac8388c60509',
        bodyKey: 'inline.plan295.daily_choice.when_you_know_you_do_not_know_enough.3496dfe685ef'),
    ]),
  DailyChoiceGuideModule(
    id: 'quality',
    icon: Icons.workspace_premium_rounded,
    titleKey: 'inline.plan295.daily_choice.six_elements_of_decision_quality.6b3690164386',
    subtitleKey: 'inline.plan295.daily_choice.taken_from_the_stanford_decision_qua.57e8224220cd',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.filter_center_focus_rounded,
        titleKey: 'inline.plan295.daily_choice.frame_the_question_correctly.e96e0f5385fb',
        bodyKey: 'inline.plan295.daily_choice.clarify_what_is_being_decided_the_ti.8260b12e9cbb'),
      DailyChoiceGuideEntry(
        icon: Icons.auto_fix_high_rounded,
        titleKey: 'inline.plan295.daily_choice.generate_at_least_2_to_3_viable_opti.77fe003553db',
        bodyKey: 'inline.plan295.daily_choice.many_bad_decisions_happen_because_th.7a5fa26bf521'),
      DailyChoiceGuideEntry(
        icon: Icons.fact_check_rounded,
        titleKey: 'inline.plan295.daily_choice.use_relevant_and_reliable_informatio.c45d95e13e7e',
        bodyKey: 'inline.plan295.daily_choice.more_information_is_not_always_bette.acbca3e3404d'),
      DailyChoiceGuideEntry(
        icon: Icons.scale_rounded,
        titleKey: 'inline.plan295.daily_choice.write_down_values_and_tradeoffs.2b68aa8658a3',
        bodyKey: 'inline.plan295.daily_choice.list_what_matters_most_before_you_sc.59480813613b'),
      DailyChoiceGuideEntry(
        icon: Icons.analytics_rounded,
        titleKey: 'inline.plan295.daily_choice.keep_reasoning_transparent_and_revie.b5f8ef586eb9',
        bodyKey: 'inline.plan295.daily_choice.do_not_stop_at_it_feels_right_make_t.937f6c91f6e3'),
      DailyChoiceGuideEntry(
        icon: Icons.playlist_add_check_circle_rounded,
        titleKey: 'inline.plan295.daily_choice.a_decision_must_end_in_action.b641ba205ce6',
        bodyKey: 'inline.plan295.daily_choice.a_decision_with_no_next_action_is_us.e99173a29ce5'),
    ]),
  DailyChoiceGuideModule(
    id: 'probability',
    icon: Icons.functions_rounded,
    titleKey: 'toolbox.daily_choice.probability_uncertainty',
    subtitleKey: 'inline.plan295.daily_choice.translate_emotional_certainty_into_p.3485dc4e2dd1',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.percent_rounded,
        titleKey: 'inline.plan295.daily_choice.assign_probabilities_before_conclusi.1ced45f3f68a',
        bodyKey: 'inline.plan295.daily_choice.replace_i_think_it_will_work_with_so.d1d5df62a4b5'),
      DailyChoiceGuideEntry(
        icon: Icons.merge_type_rounded,
        titleKey: 'inline.plan295.daily_choice.use_multiplication_when_several_cond.e1d6fdddba07',
        bodyKey: 'inline.plan295.daily_choice.when_success_depends_on_several_link.ee5022ccf3e7'),
      DailyChoiceGuideEntry(
        icon: Icons.compare_arrows_rounded,
        titleKey: 'inline.plan295.daily_choice.pull_extreme_forecasts_back_toward_t.cff091d3beef',
        bodyKey: 'inline.plan295.daily_choice.if_evidence_is_thin_but_your_forecas.ec0689f58f72'),
      DailyChoiceGuideEntry(
        icon: Icons.update_rounded,
        titleKey: 'inline.plan295.daily_choice.update_when_evidence_changes.6cfb62a924c5',
        bodyKey: 'inline.plan295.daily_choice.the_core_of_bayesian_thinking_is_not.13b40141ff9a'),
    ]),
  DailyChoiceGuideModule(
    id: 'bias_noise',
    icon: Icons.shield_moon_rounded,
    titleKey: 'inline.plan295.daily_choice.bias_and_noise_control.6e9cd25f9e4f',
    subtitleKey: 'inline.plan295.daily_choice.avoid_getting_dragged_around_by_anch.fbd0e46d0bb3',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.ads_click_rounded,
        titleKey: 'inline.plan295.daily_choice.estimate_independently_before_discus.d65b21718786',
        bodyKey: 'inline.plan295.daily_choice.once_you_see_someone_else_s_number_o.656312fa37d2'),
      DailyChoiceGuideEntry(
        icon: Icons.money_off_csred_rounded,
        titleKey: 'inline.plan295.daily_choice.sunk_cost_is_not_a_reason_to_continu.66fe3cb2d8b0',
        bodyKey: 'inline.plan295.daily_choice.past_time_and_money_that_cannot_be_r.70b6625b0a03'),
      DailyChoiceGuideEntry(
        icon: Icons.grid_view_rounded,
        titleKey: 'inline.plan295.daily_choice.use_a_common_scale_to_reduce_noise.feb14a53dea6',
        bodyKey: 'inline.plan295.daily_choice.using_the_same_fields_scales_and_ord.b6a9eb272102'),
      DailyChoiceGuideEntry(
        icon: Icons.visibility_rounded,
        titleKey: 'inline.plan295.daily_choice.a_good_story_is_not_strong_evidence.00bffbe7f65c',
        bodyKey: 'inline.plan295.daily_choice.confirmation_bias_hindsight_and_surv.da670750c41a'),
    ]),
  DailyChoiceGuideModule(
    id: 'action',
    icon: Icons.task_alt_rounded,
    titleKey: 'inline.plan295.daily_choice.when_to_research_more_and_when_to_mo.21fa41f67222',
    subtitleKey: 'inline.plan295.daily_choice.information_has_value_but_analysis_s.254a6e0edf24',
    entries: <DailyChoiceGuideEntry>[
      DailyChoiceGuideEntry(
        icon: Icons.travel_explore_rounded,
        titleKey: 'inline.plan295.daily_choice.collect_the_one_fact_most_likely_to.c39d89f0a299',
        bodyKey: 'inline.plan295.daily_choice.do_not_just_do_more_research_define.84849f9495a7'),
      DailyChoiceGuideEntry(
        icon: Icons.timer_rounded,
        titleKey: 'inline.plan295.daily_choice.set_a_stopping_rule.65474237847f',
        bodyKey: 'inline.plan295.daily_choice.examples_i_decide_after_three_pieces.c081d51e5679'),
      DailyChoiceGuideEntry(
        icon: Icons.report_problem_rounded,
        titleKey: 'inline.plan295.daily_choice.run_a_premortem_for_high_stakes_choi.53ddd92a3327',
        bodyKey: 'inline.plan295.daily_choice.imagine_the_choice_has_failed_three.ef35f6ffb394'),
      DailyChoiceGuideEntry(
        icon: Icons.health_and_safety_rounded,
        titleKey: 'inline.plan295.daily_choice.medical_legal_and_financial_calls_st.a6dcb3056e25',
        bodyKey: 'inline.plan295.daily_choice.this_module_supports_everyday_and_ge.9735ce4eb775'),
    ]),
];

List<DailyChoiceGuideEntry> buildDecisionHygieneEntries({
  required DailyChoiceDecisionContext context,
  required DailyChoiceDecisionReport report,
}) {
  final entries = <DailyChoiceGuideEntry>[
    const DailyChoiceGuideEntry(
      icon: Icons.ads_click_rounded,
    titleKey: 'inline.plan295.daily_choice.score_independently_first.dc1ee0057f83',
    bodyKey: 'inline.plan295.daily_choice.anchoring_happens_before_the_convers.7d3b5f748eb3'),
    const DailyChoiceGuideEntry(
      icon: Icons.money_off_rounded,
    titleKey: 'inline.plan295.daily_choice.do_not_double_down_on_sunk_cost.81cca2167298',
    bodyKey: 'inline.plan295.daily_choice.past_time_money_or_ego_are_not_reaso.a24babae6353'),
    const DailyChoiceGuideEntry(
      icon: Icons.rule_folder_rounded,
    titleKey: 'inline.plan295.daily_choice.use_the_same_fields_for_every_option.04158e075510',
    bodyKey: 'inline.plan295.daily_choice.noise_often_comes_from_shifting_stan.45961a96a459'),
  ];

  if (context.uncertainty == DailyChoiceDecisionLevel.high) {
    entries.add(
      const DailyChoiceGuideEntry(
        icon: Icons.insights_rounded,
    titleKey: 'inline.plan295.daily_choice.use_base_rates_when_uncertainty_is_h.ecaa309adaa7',
    bodyKey: 'inline.plan295.daily_choice.if_you_do_not_have_enough_evidence_f.31a9f6f2057b'),
    );
  }

  if (report.infoSignal.shouldGatherMoreInfo) {
    entries.add(
      const DailyChoiceGuideEntry(
        icon: Icons.travel_explore_rounded,
    titleKey: 'inline.plan295.daily_choice.research_the_fact_most_likely_to_cha.15f23c677a28',
    bodyKey: 'inline.plan295.daily_choice.if_you_do_more_research_do_not_do_it.7cb48ac7ff8f'),
    );
  }

  if (context.stakes == DailyChoiceDecisionLevel.high) {
    entries.add(
      const DailyChoiceGuideEntry(
        icon: Icons.report_rounded,
    titleKey: 'inline.plan295.daily_choice.run_a_premortem_for_high_stakes.f9344f65b1d7',
    bodyKey: 'inline.plan295.daily_choice.assume_the_decision_fails_where_is_i.f3692e23824c'),
    );
  }

  if (report.consensus.stability < 0.5) {
    entries.add(
      const DailyChoiceGuideEntry(
        icon: Icons.compare_rounded,
    titleKey: 'inline.plan295.daily_choice.return_to_value_ranking_when_methods.be589978df63',
    bodyKey: 'inline.plan295.daily_choice.when_the_methods_disagree_the_proble.a1a2c92c6876'),
    );
  }

  if (context.urgency == DailyChoiceDecisionUrgency.now) {
    entries.add(
      const DailyChoiceGuideEntry(
        icon: Icons.timer_rounded,
    titleKey: 'inline.plan295.daily_choice.if_you_must_decide_now_define_a_stop.25fb18838bf3',
    bodyKey: 'inline.plan295.daily_choice.for_example_once_i_finish_this_ranki.fd765f571ff1'),
    );
  }

  return entries;
}
