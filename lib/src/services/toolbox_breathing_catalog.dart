import 'package:flutter/material.dart';

import '../i18n/app_i18n.dart';

@immutable
class BreathingCopy {
  const BreathingCopy(this.key);

  final String key;

  String resolve(AppI18n i18n) => i18n.t(key);
}

enum BreathingStageKind { inhale, hold, exhale, rest }

@immutable
class BreathingStagePlan {
  const BreathingStagePlan({
    required this.kind,
    required this.seconds,
    required this.label,
    required this.prompt,
    this.cueId,
  });

  final BreathingStageKind kind;
  final int seconds;
  final BreathingCopy label;
  final BreathingCopy prompt;
  final String? cueId;
}

@immutable
class BreathingCueSpec {
  const BreathingCueSpec({
    required this.id,
    required this.name,
    required this.remoteFileNames,
    required this.approxDurationMs,
    this.assetPath,
  });

  final String id;
  final BreathingCopy name;
  final List<String> remoteFileNames;
  final int approxDurationMs;
  final String? assetPath;
}

@immutable
class BreathingThemeSpec {
  const BreathingThemeSpec({
    required this.id,
    required this.name,
    required this.mood,
    required this.bgStart,
    required this.bgEnd,
    required this.orbStart,
    required this.orbEnd,
    required this.accent,
    required this.icon,
  });

  final String id;
  final BreathingCopy name;
  final BreathingCopy mood;
  final Color bgStart;
  final Color bgEnd;
  final Color orbStart;
  final Color orbEnd;
  final Color accent;
  final IconData icon;
}

@immutable
class BreathingScenario {
  const BreathingScenario({
    required this.id,
    required this.name,
    required this.scene,
    required this.description,
    required this.bodyFocus,
    required this.whenToUse,
    required this.researchBasis,
    required this.mechanism,
    required this.themeId,
    required this.stages,
    required this.tags,
    required this.recommendedMinutes,
    this.previewCueId,
    this.caution,
    this.advanced = false,
  });

  final String id;
  final BreathingCopy name;
  final BreathingCopy scene;
  final BreathingCopy description;
  final BreathingCopy bodyFocus;
  final BreathingCopy whenToUse;
  final BreathingCopy researchBasis;
  final BreathingCopy mechanism;
  final String themeId;
  final List<BreathingStagePlan> stages;
  final List<BreathingCopy> tags;
  final int recommendedMinutes;
  final String? previewCueId;
  final BreathingCopy? caution;
  final bool advanced;

  int get cycleSeconds =>
      stages.fold<int>(0, (sum, stage) => sum + stage.seconds);

  double get cyclesPerMinute {
    if (cycleSeconds <= 0) {
      return 0;
    }
    return 60 / cycleSeconds;
  }
}

class BreathingExperienceCatalog {
  const BreathingExperienceCatalog._();

  static const String remotePrefix = '音效：呼吸引导';

  static const List<BreathingThemeSpec> themes = <BreathingThemeSpec>[
    BreathingThemeSpec(
      id: 'ocean',
      name: BreathingCopy('inline.plan295.breathing.ocean_glow.ddede1e99f58'),
      mood: BreathingCopy(
        'inline.plan295.breathing.stretch_the_exhale_like_a_slow_tide.e6707e6642a9',
      ),
      bgStart: Color(0xFF081C34),
      bgEnd: Color(0xFF154D79),
      orbStart: Color(0xFF85E5FF),
      orbEnd: Color(0xFF47BFE8),
      accent: Color(0xFFB7F4FF),
      icon: Icons.water_rounded,
    ),
    BreathingThemeSpec(
      id: 'forest',
      name: BreathingCopy('inline.plan295.breathing.forest_mist.f46361223bac'),
      mood: BreathingCopy(
        'inline.plan295.breathing.steady_inhale_and_exhale_like_enteri.034aa47a9195',
      ),
      bgStart: Color(0xFF10261F),
      bgEnd: Color(0xFF2B6747),
      orbStart: Color(0xFFB8EDB6),
      orbEnd: Color(0xFF68C69A),
      accent: Color(0xFFE5FFD5),
      icon: Icons.park_rounded,
    ),
    BreathingThemeSpec(
      id: 'ember',
      name: BreathingCopy('inline.plan295.breathing.ember_calm.3062047f2b08'),
      mood: BreathingCopy(
        'inline.plan295.breathing.let_emotional_heat_leave_a_little_at.1bc3cb1f3815',
      ),
      bgStart: Color(0xFF3A1F26),
      bgEnd: Color(0xFF814142),
      orbStart: Color(0xFFFFD59B),
      orbEnd: Color(0xFFFF9F73),
      accent: Color(0xFFFFF1C2),
      icon: Icons.local_fire_department_rounded,
    ),
    BreathingThemeSpec(
      id: 'alpine',
      name: BreathingCopy('inline.plan295.breathing.alpine_air.8f8403d18455'),
      mood: BreathingCopy(
        'inline.plan295.breathing.a_more_disciplined_pace_focused_on_e.ba76d6503a79',
      ),
      bgStart: Color(0xFF0D2033),
      bgEnd: Color(0xFF5A7CA7),
      orbStart: Color(0xFFD8F2FF),
      orbEnd: Color(0xFF86C1F2),
      accent: Color(0xFFEAF7FF),
      icon: Icons.terrain_rounded,
    ),
    BreathingThemeSpec(
      id: 'aurora',
      name: BreathingCopy('inline.plan295.breathing.aurora_focus.311dd33ca40b'),
      mood: BreathingCopy(
        'inline.plan295.breathing.pull_attention_back_into_the_pulse_o.02ed4d214d14',
      ),
      bgStart: Color(0xFF111A3A),
      bgEnd: Color(0xFF2B5B72),
      orbStart: Color(0xFF8EF7E0),
      orbEnd: Color(0xFF67C0FF),
      accent: Color(0xFFD8FFF7),
      icon: Icons.auto_awesome_rounded,
    ),
  ];

  static const Map<String, BreathingCueSpec> cues = <String, BreathingCueSpec>{
    'inhale_soft': BreathingCueSpec(
      id: 'inhale_soft',
      name: BreathingCopy('inline.plan295.breathing.inhale_cue.c28aca9ce0dc'),
      remoteFileNames: <String>['吸气.wav'],
      approxDurationMs: 1200,
    ),
    'exhale_soft': BreathingCueSpec(
      id: 'exhale_soft',
      name: BreathingCopy('inline.plan295.breathing.exhale_cue.b610259e51b5'),
      remoteFileNames: <String>['呼气.wav'],
      approxDurationMs: 2400,
    ),
    'hold_soft': BreathingCueSpec(
      id: 'hold_soft',
      name: BreathingCopy('inline.plan295.breathing.hold_cue.dee35815d745'),
      remoteFileNames: <String>['屏息.wav'],
      approxDurationMs: 2160,
    ),
    'nose_inhale': BreathingCueSpec(
      id: 'nose_inhale',
      name: BreathingCopy(
        'inline.plan295.breathing.nasal_inhale_cue.05ee5c6750cb',
      ),
      remoteFileNames: <String>['鼻子吸气.wav'],
      approxDurationMs: 3760,
    ),
    'nose_exhale': BreathingCueSpec(
      id: 'nose_exhale',
      name: BreathingCopy(
        'inline.plan295.breathing.nasal_exhale_cue.47f1174f13fb',
      ),
      remoteFileNames: <String>['鼻子呼气.wav'],
      approxDurationMs: 3360,
    ),
    'mouth_inhale': BreathingCueSpec(
      id: 'mouth_inhale',
      name: BreathingCopy(
        'inline.plan295.breathing.mouth_inhale_cue.ea0a8cd0573d',
      ),
      remoteFileNames: <String>['嘴吸气.wav'],
      approxDurationMs: 2960,
    ),
    'mouth_exhale': BreathingCueSpec(
      id: 'mouth_exhale',
      name: BreathingCopy(
        'inline.plan295.breathing.mouth_exhale_cue.75644d9b357a',
      ),
      remoteFileNames: <String>['嘴呼气.wav'],
      approxDurationMs: 3760,
    ),
    'preview_relax': BreathingCueSpec(
      id: 'preview_relax',
      name: BreathingCopy(
        'inline.plan295.breathing.relax_guidance.7b6323e73735',
      ),
      remoteFileNames: <String>['放松.wav'],
      approxDurationMs: 29040,
    ),
    'preview_intro_1': BreathingCueSpec(
      id: 'preview_intro_1',
      name: BreathingCopy(
        'inline.plan295.breathing.breath_guide_1.90e61d8ee32f',
      ),
      remoteFileNames: <String>['呼吸引导1.wav'],
      approxDurationMs: 24986,
    ),
    'preview_intro_2': BreathingCueSpec(
      id: 'preview_intro_2',
      name: BreathingCopy(
        'inline.plan295.breathing.breath_guide_2.7b22c39266f5',
      ),
      remoteFileNames: <String>['呼吸引导2.wav'],
      approxDurationMs: 33841,
    ),
    'preview_nose_slow': BreathingCueSpec(
      id: 'preview_nose_slow',
      name: BreathingCopy(
        'inline.plan295.breathing.nasal_inhale_demo.888839f7b2d7',
      ),
      remoteFileNames: <String>['开始用鼻子缓缓吸气.wav'],
      approxDurationMs: 3120,
    ),
    'preview_parasym': BreathingCueSpec(
      id: 'preview_parasym',
      name: BreathingCopy(
        'inline.plan295.breathing.parasympathetic_guide.2aa93ae30623',
      ),
      remoteFileNames: <String>['副交感交替.wav'],
      approxDurationMs: 13360,
    ),
    'preview_altitude': BreathingCueSpec(
      id: 'preview_altitude',
      name: BreathingCopy(
        'inline.plan295.breathing.cyclic_sigh_guide.a75408b33e93',
      ),
      remoteFileNames: <String>['快速嘴吸气屏气.wav'],
      approxDurationMs: 4000,
    ),
    'bolt_prepare': BreathingCueSpec(
      id: 'bolt_prepare',
      name: BreathingCopy('inline.plan295.breathing.bolt_prepare.6b99e55650e2'),
      remoteFileNames: <String>['breathing_bolt_prepare.wav'],
      approxDurationMs: 2320,
    ),
    'bolt_start': BreathingCueSpec(
      id: 'bolt_start',
      name: BreathingCopy('inline.plan295.breathing.bolt_start.b5c0fa7290ca'),
      remoteFileNames: <String>['breathing_bolt_start.wav'],
      approxDurationMs: 2960,
    ),
    'bolt_stop': BreathingCueSpec(
      id: 'bolt_stop',
      name: BreathingCopy('inline.plan295.breathing.bolt_stop.434631a9bbf1'),
      remoteFileNames: <String>['breathing_bolt_stop.wav'],
      approxDurationMs: 2480,
    ),
    'bolt_recover': BreathingCueSpec(
      id: 'bolt_recover',
      name: BreathingCopy('inline.plan295.breathing.bolt_recover.e979fe00f372'),
      remoteFileNames: <String>['breathing_bolt_recover.wav'],
      approxDurationMs: 2560,
    ),
    'session_start': BreathingCueSpec(
      id: 'session_start',
      name: BreathingCopy(
        'inline.plan295.breathing.session_start.d7429407b9c8',
      ),
      remoteFileNames: <String>['breathing_session_start.wav'],
      approxDurationMs: 1840,
    ),
    'session_complete': BreathingCueSpec(
      id: 'session_complete',
      name: BreathingCopy(
        'inline.plan295.breathing.session_complete.cbc1ebbbe314',
      ),
      remoteFileNames: <String>['breathing_session_complete.wav'],
      approxDurationMs: 2480,
    ),
    'altitude_warning_short': BreathingCueSpec(
      id: 'altitude_warning_short',
      name: BreathingCopy(
        'inline.plan295.breathing.altitude_warning.4a49da75a115',
      ),
      remoteFileNames: <String>['breathing_altitude_warning_short.wav'],
      approxDurationMs: 4160,
    ),
  };

  static const List<BreathingScenario> scenarios = <BreathingScenario>[
    BreathingScenario(
      id: 'diaphragm_4262',
      name: BreathingCopy(
        'inline.plan295.breathing.diaphragm_4_2_6_2.ea51085add91',
      ),
      scene: BreathingCopy(
        'inline.plan295.breathing.default_mode_for_learning_diaphragma.133819f527d1',
      ),
      description: BreathingCopy(
        'inline.plan295.breathing.nasal_inhale_and_exhale_with_a_belly.1613169fa55b',
      ),
      bodyFocus: BreathingCopy(
        'inline.plan295.breathing.keep_the_shoulders_soft_and_let_the.2559b200901d',
      ),
      whenToUse: BreathingCopy(
        'inline.plan295.breathing.use_at_the_start_of_the_day_after_lo.140a8ed1eac9',
      ),
      researchBasis: BreathingCopy(
        'inline.plan295.breathing.diaphragmatic_breathing_has_been_lin.98aabccfea88',
      ),
      mechanism: BreathingCopy(
        'inline.plan295.breathing.it_shifts_work_toward_the_diaphragm.38ad4fe5ea18',
      ),
      themeId: 'ocean',
      previewCueId: 'preview_nose_slow',
      recommendedMinutes: 5,
      tags: <BreathingCopy>[
        BreathingCopy('inline.plan295.breathing.starter.deea5fd4a70e'),
        BreathingCopy('inline.plan295.breathing.diaphragm.d0ad99ceb2e4'),
        BreathingCopy('inline.plan295.breathing.daily.53975da54192'),
      ],
      stages: <BreathingStagePlan>[
        BreathingStagePlan(
          kind: BreathingStageKind.inhale,
          seconds: 4,
          label: BreathingCopy(
            'inline.plan295.breathing.nasal_inhale.3d196ba5f8b1',
          ),
          prompt: BreathingCopy(
            'inline.plan295.breathing.expand_the_belly.c332cc561d5c',
          ),
          cueId: 'nose_inhale',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.hold,
          seconds: 2,
          label: BreathingCopy('inline.plan295.breathing.hold.655746dd3985'),
          prompt: BreathingCopy(
            'inline.plan295.breathing.pause_lightly_without_straining.a5595e84328e',
          ),
          cueId: 'hold_soft',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.exhale,
          seconds: 6,
          label: BreathingCopy(
            'inline.plan295.breathing.nasal_exhale.cc4ea738e420',
          ),
          prompt: BreathingCopy(
            'inline.plan295.breathing.lengthen_the_exhale.1aa01ee7016a',
          ),
          cueId: 'nose_exhale',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.rest,
          seconds: 2,
          label: BreathingCopy('inline.plan295.breathing.settle.2d327b6bc666'),
          prompt: BreathingCopy(
            'inline.plan295.breathing.let_the_body_settle.6212c513cdbc',
          ),
        ),
      ],
    ),
    BreathingScenario(
      id: 'focus_nasal_44',
      name: BreathingCopy(
        'inline.plan295.breathing.nasal_focus_4_4.800b5b8132a0',
      ),
      scene: BreathingCopy(
        'inline.plan295.breathing.a_quiet_focusing_rhythm_before_deep.4a7dbe03e74b',
      ),
      description: BreathingCopy(
        'inline.plan295.breathing.nasal_only_breathing_without_holds_k.f5cdca906793',
      ),
      bodyFocus: BreathingCopy(
        'inline.plan295.breathing.keep_inhale_and_exhale_equal_and_avo.cead64d2885d',
      ),
      whenToUse: BreathingCopy(
        'inline.plan295.breathing.use_before_focused_work_or_any_time.002b43087cb9',
      ),
      researchBasis: BreathingCopy(
        'inline.plan295.breathing.nasal_breathing_has_been_linked_to_l.b823b2712b93',
      ),
      mechanism: BreathingCopy(
        'inline.plan295.breathing.it_combines_a_steady_rhythm_with_the.e72efac6b16e',
      ),
      themeId: 'aurora',
      previewCueId: 'preview_intro_1',
      recommendedMinutes: 4,
      tags: <BreathingCopy>[
        BreathingCopy('ref.focusPhase'),
        BreathingCopy('inline.plan295.breathing.nasal.b6c1017fb223'),
        BreathingCopy('inline.plan295.breathing.alert.d80d0fc4a90b'),
      ],
      stages: <BreathingStagePlan>[
        BreathingStagePlan(
          kind: BreathingStageKind.inhale,
          seconds: 4,
          label: BreathingCopy(
            'inline.plan295.breathing.nasal_inhale.3d196ba5f8b1',
          ),
          prompt: BreathingCopy(
            'inline.plan295.breathing.inhale_evenly_for_four.0992fb55ce57',
          ),
          cueId: 'nose_inhale',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.exhale,
          seconds: 4,
          label: BreathingCopy(
            'inline.plan295.breathing.nasal_exhale.cc4ea738e420',
          ),
          prompt: BreathingCopy(
            'inline.plan295.breathing.exhale_evenly_for_four.e77d81de5ac7',
          ),
          cueId: 'nose_exhale',
        ),
      ],
    ),
    BreathingScenario(
      id: 'box_4444',
      name: BreathingCopy('inline.plan295.breathing.box_4_4_4_4.d7d3456fb79b'),
      scene: BreathingCopy(
        'inline.plan295.breathing.steady_your_rhythm_before_meetings_t.3ff3db9c50a2',
      ),
      description: BreathingCopy(
        'inline.plan295.breathing.four_equal_sides_create_a_square_rhy.b68e5bbbab17',
      ),
      bodyFocus: BreathingCopy(
        'inline.plan295.breathing.keep_each_side_the_same_length_and_p.834589b10e21',
      ),
      whenToUse: BreathingCopy(
        'inline.plan295.breathing.best_for_a_2_5_minute_reset_before_a.ba53d1ea21f8',
      ),
      researchBasis: BreathingCopy(
        'inline.plan295.breathing.it_works_best_as_a_pacing_and_attent.7559f0b6b658',
      ),
      mechanism: BreathingCopy(
        'inline.plan295.breathing.the_regular_counting_pattern_reduces.c5153d643eeb',
      ),
      themeId: 'aurora',
      previewCueId: 'preview_intro_1',
      recommendedMinutes: 3,
      caution: BreathingCopy(
        'inline.plan295.breathing.if_breath_holding_makes_you_more_ten.e6498eb99e85',
      ),
      tags: <BreathingCopy>[
        BreathingCopy('inline.plan295.breathing.pre_task.7e3cca5f29ce'),
        BreathingCopy('inline.plan295.breathing.pacing.a0a4d39960b7'),
        BreathingCopy(
          'inline.ui.pages.toolbox_human_tests_auditory.steady_73508d',
        ),
      ],
      stages: <BreathingStagePlan>[
        BreathingStagePlan(
          kind: BreathingStageKind.inhale,
          seconds: 4,
          label: BreathingCopy('inline.plan295.breathing.inhale.5dcc34d57e6f'),
          prompt: BreathingCopy(
            'inline.plan295.breathing.fill_for_four_beats.da920ec2c312',
          ),
          cueId: 'inhale_soft',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.hold,
          seconds: 4,
          label: BreathingCopy('inline.plan295.breathing.hold.9ecbd299f2b0'),
          prompt: BreathingCopy(
            'inline.plan295.breathing.stay_steady.7be1b0f1b8f1',
          ),
          cueId: 'hold_soft',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.exhale,
          seconds: 4,
          label: BreathingCopy('inline.plan295.breathing.exhale.13ff86dd86ea'),
          prompt: BreathingCopy(
            'inline.plan295.breathing.release_on_the_same_count.0957f0e82e71',
          ),
          cueId: 'exhale_soft',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.rest,
          seconds: 4,
          label: BreathingCopy('toolbox.sleep.core.pause'),
          prompt: BreathingCopy(
            'inline.plan295.breathing.prepare_the_next_cycle.3787697019e6',
          ),
        ),
      ],
    ),
    BreathingScenario(
      id: 'coherent_55',
      name: BreathingCopy('inline.plan295.breathing.coherent_5_5.fb33eb5bdd99'),
      scene: BreathingCopy(
        'inline.plan295.breathing.balanced_breathing_for_transitions_a.4fa64a24914b',
      ),
      description: BreathingCopy(
        'inline.plan295.breathing.equal_inhale_and_exhale_are_ideal_fo.2997ab55f2fe',
      ),
      bodyFocus: BreathingCopy(
        'inline.plan295.breathing.keep_both_directions_smooth_and_roun.9e178faba77f',
      ),
      whenToUse: BreathingCopy(
        'inline.plan295.breathing.use_between_focus_blocks_or_during_t.7ead68798783',
      ),
      researchBasis: BreathingCopy(
        'inline.plan295.breathing.slow_breathing_near_5_6_breaths_per.ad23f7cfc607',
      ),
      mechanism: BreathingCopy(
        'inline.plan295.breathing.it_supports_a_rhythm_that_more_readi.5f1bc9c01e11',
      ),
      themeId: 'forest',
      previewCueId: 'preview_intro_1',
      recommendedMinutes: 8,
      tags: <BreathingCopy>[
        BreathingCopy('inline.plan295.breathing.steady_state.a868cc761184'),
        BreathingCopy('toolbox.sleep.library.tag.recovery'),
        BreathingCopy('literal.services.toolbox_breathing_catalog.hrv_1d7dd2'),
      ],
      stages: <BreathingStagePlan>[
        BreathingStagePlan(
          kind: BreathingStageKind.inhale,
          seconds: 5,
          label: BreathingCopy('inline.plan295.breathing.inhale.5dcc34d57e6f'),
          prompt: BreathingCopy(
            'inline.plan295.breathing.inhale_evenly.f069220c4d67',
          ),
          cueId: 'inhale_soft',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.exhale,
          seconds: 5,
          label: BreathingCopy('inline.plan295.breathing.exhale.13ff86dd86ea'),
          prompt: BreathingCopy(
            'inline.plan295.breathing.exhale_evenly.a8d46c2dc3b3',
          ),
          cueId: 'exhale_soft',
        ),
      ],
    ),
    BreathingScenario(
      id: 'relax_4262',
      name: BreathingCopy(
        'inline.plan295.breathing.unwind_4_2_6_2.f0d9ad700138',
      ),
      scene: BreathingCopy(
        'inline.plan295.breathing.a_downshift_rhythm_for_after_work_ex.130ca67b1742',
      ),
      description: BreathingCopy(
        'inline.plan295.breathing.a_longer_exhale_helps_the_body_come.fb4418b312b7',
      ),
      bodyFocus: BreathingCopy(
        'inline.plan295.breathing.relax_the_jaw_and_let_the_shoulders.eb546951c8cf',
      ),
      whenToUse: BreathingCopy(
        'inline.plan295.breathing.use_after_long_work_blocks_after_com.46c890712eef',
      ),
      researchBasis: BreathingCopy(
        'inline.plan295.breathing.slow_breathing_with_a_longer_exhale.53b858ed47bb',
      ),
      mechanism: BreathingCopy(
        'inline.plan295.breathing.extending_the_exhale_relative_to_the.377190d80c6f',
      ),
      themeId: 'forest',
      previewCueId: 'preview_relax',
      recommendedMinutes: 5,
      tags: <BreathingCopy>[
        BreathingCopy('ref.breakPhase'),
        BreathingCopy('inline.plan295.breathing.long_exhale.3917e43be1c7'),
        BreathingCopy('toolbox.sleep.library.tag.recovery'),
      ],
      stages: <BreathingStagePlan>[
        BreathingStagePlan(
          kind: BreathingStageKind.inhale,
          seconds: 4,
          label: BreathingCopy('inline.plan295.breathing.inhale.5dcc34d57e6f'),
          prompt: BreathingCopy(
            'inline.plan295.breathing.inhale_softly.c49c48306489',
          ),
          cueId: 'inhale_soft',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.hold,
          seconds: 2,
          label: BreathingCopy('inline.plan295.breathing.hold.655746dd3985'),
          prompt: BreathingCopy(
            'inline.plan295.breathing.keep_it_light.d1075629439f',
          ),
          cueId: 'hold_soft',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.exhale,
          seconds: 6,
          label: BreathingCopy(
            'inline.plan295.breathing.long_exhale.3917e43be1c7',
          ),
          prompt: BreathingCopy(
            'inline.plan295.breathing.release_neck_and_shoulder_tension.6bb9a7ef795f',
          ),
          cueId: 'exhale_soft',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.rest,
          seconds: 2,
          label: BreathingCopy('inline.plan295.breathing.rest.f2c7f9979490'),
          prompt: BreathingCopy(
            'inline.plan295.breathing.let_the_pace_settle.a7017bb263e5',
          ),
        ),
      ],
    ),
    BreathingScenario(
      id: 'calm_36',
      name: BreathingCopy('inline.plan295.breathing.calm_3_6.3abdc007c2c7'),
      scene: BreathingCopy(
        'inline.plan295.breathing.a_simple_de_escalation_rhythm_for_ag.c93c3f52b61e',
      ),
      description: BreathingCopy(
        'inline.plan295.breathing.a_short_inhale_and_long_exhale_are_e.2c6cce5fb86a',
      ),
      bodyFocus: BreathingCopy(
        'inline.plan295.breathing.finish_the_exhale_fully_before_letti.ceccfe74497d',
      ),
      whenToUse: BreathingCopy(
        'inline.plan295.breathing.use_when_emotions_are_elevated_and_y.5643801e4267',
      ),
      researchBasis: BreathingCopy(
        'inline.plan295.breathing.when_you_are_already_activated_long.cd0f386c4646',
      ),
      mechanism: BreathingCopy(
        'inline.plan295.breathing.prioritizing_the_exhale_can_help_low.840adb221547',
      ),
      themeId: 'ember',
      previewCueId: 'preview_intro_2',
      recommendedMinutes: 3,
      tags: <BreathingCopy>[
        BreathingCopy('inline.plan295.breathing.rapid_reset.48b2f55186bb'),
        BreathingCopy('inline.plan295.breathing.accessible.64462732b8c7'),
        BreathingCopy('inline.plan295.breathing.long_exhale.3917e43be1c7'),
      ],
      stages: <BreathingStagePlan>[
        BreathingStagePlan(
          kind: BreathingStageKind.inhale,
          seconds: 3,
          label: BreathingCopy('inline.plan295.breathing.inhale.5dcc34d57e6f'),
          prompt: BreathingCopy(
            'inline.plan295.breathing.inhale_lightly.732b8760ed80',
          ),
          cueId: 'inhale_soft',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.exhale,
          seconds: 6,
          label: BreathingCopy(
            'inline.plan295.breathing.long_exhale.3917e43be1c7',
          ),
          prompt: BreathingCopy(
            'inline.plan295.breathing.empty_the_breath_fully.4b75fc989c4f',
          ),
          cueId: 'exhale_soft',
        ),
      ],
    ),
    BreathingScenario(
      id: 'sleep_46',
      name: BreathingCopy('inline.plan295.breathing.bedtime_4_6.fb48d2bc116a'),
      scene: BreathingCopy(
        'inline.plan295.breathing.a_gentle_bedtime_rhythm_for_settling.4113ed6090ed',
      ),
      description: BreathingCopy(
        'inline.plan295.breathing.no_breath_hold_just_a_gentle_inhale.5046ecd8efa0',
      ),
      bodyFocus: BreathingCopy(
        'inline.plan295.breathing.do_not_chase_a_deep_inhale_think_of.c0f77eaca87d',
      ),
      whenToUse: BreathingCopy(
        'inline.plan295.breathing.use_after_lights_out_after_waking_in.ee93886f3cae',
      ),
      researchBasis: BreathingCopy(
        'inline.plan295.breathing.pre_sleep_slow_breathing_is_commonly.31b3902b6dc4',
      ),
      mechanism: BreathingCopy(
        'inline.plan295.breathing.it_lowers_effort_and_cognitive_load.66dce5ab014d',
      ),
      themeId: 'ember',
      previewCueId: 'preview_relax',
      recommendedMinutes: 8,
      tags: <BreathingCopy>[
        BreathingCopy('inline.plan295.breathing.bedtime.048acdfbeddd'),
        BreathingCopy('inline.plan295.breathing.gentle.26bb0cd9fc59'),
        BreathingCopy('inline.plan295.breathing.no_hold.84fe920e5021'),
      ],
      stages: <BreathingStagePlan>[
        BreathingStagePlan(
          kind: BreathingStageKind.inhale,
          seconds: 4,
          label: BreathingCopy(
            'inline.plan295.breathing.nasal_inhale.3d196ba5f8b1',
          ),
          prompt: BreathingCopy(
            'inline.plan295.breathing.inhale_gently_for_four.e64d4aeeb473',
          ),
          cueId: 'nose_inhale',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.exhale,
          seconds: 6,
          label: BreathingCopy(
            'inline.plan295.breathing.nasal_exhale.cc4ea738e420',
          ),
          prompt: BreathingCopy(
            'inline.plan295.breathing.exhale_slowly_for_six.549a92df44a0',
          ),
          cueId: 'nose_exhale',
        ),
      ],
    ),
    BreathingScenario(
      id: 'sleep_478',
      name: BreathingCopy(
        'inline.plan295.breathing.classic_4_7_8.7cd82cf27451',
      ),
      scene: BreathingCopy(
        'inline.plan295.breathing.a_slower_more_deliberate_bedtime_rhy.6d1875483918',
      ),
      description: BreathingCopy(
        'inline.plan295.breathing.classic_4_7_8_pacing_for_bedtime_bes.eb47dccaabfb',
      ),
      bodyFocus: BreathingCopy(
        'inline.plan295.breathing.do_not_overfill_the_inhale_quietness.82f3e72ce102',
      ),
      whenToUse: BreathingCopy(
        'inline.plan295.breathing.use_for_a_few_minutes_right_before_s.715aa34974f8',
      ),
      researchBasis: BreathingCopy(
        'inline.plan295.breathing.this_is_a_slower_and_more_demanding.2deb650e39c8',
      ),
      mechanism: BreathingCopy(
        'inline.plan295.breathing.the_long_hold_and_long_exhale_slow_t.ca659db5b2dc',
      ),
      themeId: 'ember',
      previewCueId: 'preview_intro_2',
      recommendedMinutes: 4,
      advanced: true,
      caution: BreathingCopy(
        'inline.plan295.breathing.if_the_7_second_hold_feels_uncomfort.28d5b37bcaa8',
      ),
      tags: <BreathingCopy>[
        BreathingCopy('inline.plan295.breathing.bedtime.048acdfbeddd'),
        BreathingCopy('inline.ui.pages.toolbox_sudoku_card.classic_d331fe'),
        BreathingCopy('inline.plan294.breathing.advanced_5895a1d0'),
      ],
      stages: <BreathingStagePlan>[
        BreathingStagePlan(
          kind: BreathingStageKind.inhale,
          seconds: 4,
          label: BreathingCopy(
            'inline.plan295.breathing.nasal_inhale.3d196ba5f8b1',
          ),
          prompt: BreathingCopy(
            'inline.plan295.breathing.inhale_gently_for_four.e64d4aeeb473',
          ),
          cueId: 'nose_inhale',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.hold,
          seconds: 7,
          label: BreathingCopy('inline.plan295.breathing.hold.575df08fdfe6'),
          prompt: BreathingCopy(
            'inline.plan295.breathing.stay_within_comfort.b54ee80b13bd',
          ),
          cueId: 'hold_soft',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.exhale,
          seconds: 8,
          label: BreathingCopy(
            'inline.plan295.breathing.mouth_exhale.14894980b6da',
          ),
          prompt: BreathingCopy(
            'inline.plan295.breathing.exhale_long_like_a_soft_sigh.9b9c5aacdafe',
          ),
          cueId: 'mouth_exhale',
        ),
      ],
    ),
    BreathingScenario(
      id: 'parasym_4462',
      name: BreathingCopy(
        'inline.plan295.breathing.parasym_reset_4_4_6_2.89634c4e7dfa',
      ),
      scene: BreathingCopy(
        'inline.plan295.breathing.shift_from_task_mode_into_recovery_m.bea4c7c02f49',
      ),
      description: BreathingCopy(
        'inline.plan295.breathing.a_longer_exhale_plus_a_short_recover.dc245ade0d07',
      ),
      bodyFocus: BreathingCopy(
        'inline.plan295.breathing.after_the_exhale_notice_the_quiet_re.1a894dab9c94',
      ),
      whenToUse: BreathingCopy(
        'inline.plan295.breathing.use_after_commuting_before_meditatio.eeb4b400a295',
      ),
      researchBasis: BreathingCopy(
        'inline.plan295.breathing.slow_breathing_with_a_longer_exhale.bf3d5acc8822',
      ),
      mechanism: BreathingCopy(
        'inline.plan295.breathing.the_long_exhale_plus_short_pause_hel.533c39aa7074',
      ),
      themeId: 'ocean',
      previewCueId: 'preview_parasym',
      recommendedMinutes: 8,
      tags: <BreathingCopy>[
        BreathingCopy('inline.plan295.breathing.parasym.4c2c7d34b3a8'),
        BreathingCopy('inline.plan295.breathing.evening.f84bcb33a6e1'),
        BreathingCopy('toolbox.sleep.library.tag.recovery'),
      ],
      stages: <BreathingStagePlan>[
        BreathingStagePlan(
          kind: BreathingStageKind.inhale,
          seconds: 4,
          label: BreathingCopy(
            'inline.plan295.breathing.nasal_inhale.3d196ba5f8b1',
          ),
          prompt: BreathingCopy(
            'inline.plan295.breathing.inhale_steadily.0beab8ca1fe5',
          ),
          cueId: 'nose_inhale',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.hold,
          seconds: 4,
          label: BreathingCopy('inline.plan295.breathing.hold.655746dd3985'),
          prompt: BreathingCopy(
            'inline.plan295.breathing.keep_only_a_gentle_tone.575739e1a693',
          ),
          cueId: 'hold_soft',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.exhale,
          seconds: 6,
          label: BreathingCopy(
            'inline.plan295.breathing.long_exhale.3917e43be1c7',
          ),
          prompt: BreathingCopy(
            'inline.plan295.breathing.let_the_pulse_follow_the_exhale.f3c851398657',
          ),
          cueId: 'nose_exhale',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.rest,
          seconds: 2,
          label: BreathingCopy('inline.plan295.breathing.rest.782a5ba7dee8'),
          prompt: BreathingCopy(
            'inline.plan295.breathing.feel_the_settling.fad5518f0183',
          ),
        ),
      ],
    ),
    BreathingScenario(
      id: 'physiological_sigh_216',
      name: BreathingCopy(
        'inline.plan295.breathing.physiological_sigh_2_1_6.f0ffad20e78e',
      ),
      scene: BreathingCopy(
        'inline.plan295.breathing.a_short_drill_for_acute_stress_scree.6f9ccf091437',
      ),
      description: BreathingCopy(
        'inline.plan295.breathing.two_inhales_followed_by_a_longer_exh.88cf253d04b3',
      ),
      bodyFocus: BreathingCopy(
        'inline.plan295.breathing.let_the_first_inhale_fill_low_into_t.f925bcd1bfd0',
      ),
      whenToUse: BreathingCopy(
        'inline.plan295.breathing.use_after_stressful_messages_before.c39cb894b0bd',
      ),
      researchBasis: BreathingCopy(
        'inline.plan295.breathing.in_a_randomized_trial_cyclic_sighing.7197fd540de9',
      ),
      mechanism: BreathingCopy(
        'inline.plan295.breathing.the_double_inhale_helps_reopen_under.3fbc0df60464',
      ),
      themeId: 'ocean',
      previewCueId: 'preview_altitude',
      recommendedMinutes: 2,
      caution: BreathingCopy(
        'inline.plan295.breathing.stop_immediately_if_you_feel_dizzy_a.3a13a9519f35',
      ),
      tags: <BreathingCopy>[
        BreathingCopy('inline.plan295.breathing.acute_stress.f543a1e81e52'),
        BreathingCopy('inline.plan295.breathing.brief.937a246846ea'),
        BreathingCopy('inline.plan295.breathing.research_backed.10336756cf09'),
      ],
      stages: <BreathingStagePlan>[
        BreathingStagePlan(
          kind: BreathingStageKind.inhale,
          seconds: 2,
          label: BreathingCopy(
            'inline.plan295.breathing.first_inhale.b119b0d3d265',
          ),
          prompt: BreathingCopy(
            'inline.plan295.breathing.fill_low_into_the_ribs.db11b1617381',
          ),
          cueId: 'inhale_soft',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.inhale,
          seconds: 1,
          label: BreathingCopy(
            'inline.plan295.breathing.top_up_inhale.ec713aebe3be',
          ),
          prompt: BreathingCopy(
            'inline.plan295.breathing.add_a_small_sip_of_air.94b811a7c84f',
          ),
          cueId: 'inhale_soft',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.exhale,
          seconds: 6,
          label: BreathingCopy(
            'inline.plan295.breathing.long_exhale.3917e43be1c7',
          ),
          prompt: BreathingCopy(
            'inline.plan295.breathing.let_it_out_like_a_long_sigh.880246adf67c',
          ),
          cueId: 'mouth_exhale',
        ),
      ],
    ),

    BreathingScenario(
      id: 'altitude_sim_3663',
      name: BreathingCopy(
        'inline.plan295.breathing.altitude_sim_3_6_6_3.2569eb5e47ba',
      ),
      scene: BreathingCopy(
        'inline.plan295.breathing.a_short_hypoxic_tolerance_drill_for.a6e10c1442e4',
      ),
      description: BreathingCopy(
        'inline.plan295.breathing.a_slower_exhale_followed_by_a_short.216e0decf0f7',
      ),
      bodyFocus: BreathingCopy(
        'inline.plan295.breathing.keep_the_neck_and_jaw_soft_lips_ligh.a2a52f410ac1',
      ),
      whenToUse: BreathingCopy(
        'inline.plan295.breathing.use_only_as_a_brief_daytime_drill_wh.a52fc7649a54',
      ),
      researchBasis: BreathingCopy(
        'inline.plan295.breathing.the_oxygen_advantage_frames_breath_h.262ebe92f7d3',
      ),
      mechanism: BreathingCopy(
        'inline.plan295.breathing.the_longer_exhale_and_short_hold_rai.8ab8713113ee',
      ),
      themeId: 'alpine',
      previewCueId: 'preview_altitude',
      recommendedMinutes: 2,
      advanced: true,
      caution: BreathingCopy(
        'inline.plan295.breathing.skip_this_if_you_feel_dizzy_tight_ch.75e9bce4cdd0',
      ),
      tags: <BreathingCopy>[
        BreathingCopy('inline.plan295.breathing.altitude_sim.be9c3032fe4f'),
        BreathingCopy('inline.plan295.breathing.air_hunger.dcd958bf79ec'),
        BreathingCopy('inline.plan294.breathing.advanced_5895a1d0'),
      ],
      stages: <BreathingStagePlan>[
        BreathingStagePlan(
          kind: BreathingStageKind.inhale,
          seconds: 3,
          label: BreathingCopy(
            'inline.plan295.breathing.nasal_inhale.3d196ba5f8b1',
          ),
          prompt: BreathingCopy(
            'inline.plan295.breathing.inhale_only_to_about_seventy_percent.edc11e385142',
          ),
          cueId: 'nose_inhale',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.exhale,
          seconds: 6,
          label: BreathingCopy(
            'inline.plan295.breathing.long_exhale.7c078b45d261',
          ),
          prompt: BreathingCopy(
            'inline.plan295.breathing.exhale_slowly_and_quietly.e8f859f61a6f',
          ),
          cueId: 'nose_exhale',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.hold,
          seconds: 6,
          label: BreathingCopy(
            'inline.plan295.breathing.exhale_hold.d59976af4598',
          ),
          prompt: BreathingCopy(
            'inline.plan295.breathing.pause_around_the_first_clear_urge_no.3fdd55bf44da',
          ),
          cueId: 'hold_soft',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.rest,
          seconds: 3,
          label: BreathingCopy('inline.plan295.breathing.recover.989c0a69989f'),
          prompt: BreathingCopy(
            'inline.plan295.breathing.let_the_next_inhale_return_quietly.83b149346f76',
          ),
        ),
      ],
    ),
  ];

  static BreathingScenario scenarioById(String id) {
    return scenarios.firstWhere(
      (item) => item.id == id,
      orElse: () => scenarios.first,
    );
  }

  static BreathingThemeSpec themeById(String id) {
    return themes.firstWhere(
      (item) => item.id == id,
      orElse: () => themes.first,
    );
  }
}
