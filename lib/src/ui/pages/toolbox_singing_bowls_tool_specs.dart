part of 'toolbox_singing_bowls_tool.dart';

// ============ 自然舒适色系（PLAN_045） ============
// [歧义] 为保留脉轮语义锚点，id / note / frequency / 文案维持不变；
// 仅 accent / glow / gradient 重写为自然低饱和色系（苔藓/晨雾/藕荷/陶土/檀褐…）。
// 未来视觉迭代若再次改色，应在此表中统一调整，不要散落到页面文件。
// =======================================================

enum _SingingBowlGroup { chakra, resonance }

class _SingingBowlFrequencySpec {
  const _SingingBowlFrequencySpec({
    required this.id,
    required this.group,
    required this.note,
    required this.frequency,
    required this.nameKey,
    required this.subtitleKey,
    required this.descriptionKey,
    required this.accent,
    required this.glow,
    required this.gradient,
  });

  final String id;
  final _SingingBowlGroup group;
  final String note;
  final double frequency;
  final String nameKey;
  final String subtitleKey;
  final String descriptionKey;
  final Color accent;
  final Color glow;
  final List<Color> gradient;

  String name(AppI18n i18n) => i18n.t(nameKey);

  String subtitle(AppI18n i18n) => i18n.t(subtitleKey);

  String description(AppI18n i18n) => i18n.t(descriptionKey);
}

class _SingingBowlVoiceSpec {
  const _SingingBowlVoiceSpec({
    required this.id,
    required this.icon,
    required this.nameKey,
    required this.descriptionKey,
    required this.baseVolume,
  });

  final String id;
  final IconData icon;
  final String nameKey;
  final String descriptionKey;
  final double baseVolume;

  String name(AppI18n i18n) => i18n.t(nameKey);

  String description(AppI18n i18n) => i18n.t(descriptionKey);
}

class _SpectrumBurst {
  const _SpectrumBurst({required this.id, required this.seed});

  final int id;
  final double seed;
}

const List<_SingingBowlFrequencySpec>
_bowlFrequencySpecs = <_SingingBowlFrequencySpec>[
  _SingingBowlFrequencySpec(
    id: 'root',
    group: _SingingBowlGroup.chakra,
    note: 'C',
    frequency: 396,
    nameKey: 'inline.plan294.singing_bowls.stability_9087ce97',
    subtitleKey: 'inline.plan294.singing_bowls.root_chakra_6b362625',
    descriptionKey:
        'inline.plan294.singing_bowls.releases_anxious_tension_and_helps_the_body_sett_b2861c96',
    accent: Color(0xFFB87A6A),
    glow: Color(0xFFE1B0A0),
    gradient: <Color>[Color(0xFFF5ECE7), Color(0xFFEADAD0), Color(0xFFD8BCAD)],
  ),
  _SingingBowlFrequencySpec(
    id: 'sacral',
    group: _SingingBowlGroup.chakra,
    note: 'D',
    frequency: 417,
    nameKey: 'inline.plan294.singing_bowls.vitality_a5df012d',
    subtitleKey: 'inline.plan294.singing_bowls.sacral_flow_0136acc4',
    descriptionKey:
        'inline.plan294.singing_bowls.loosens_emotional_heaviness_and_restores_warmth__d8433d85',
    accent: Color(0xFFC89070),
    glow: Color(0xFFE9BDA2),
    gradient: <Color>[Color(0xFFF7ECE3), Color(0xFFECD7C4), Color(0xFFDDBCA1)],
  ),
  _SingingBowlFrequencySpec(
    id: 'solar',
    group: _SingingBowlGroup.chakra,
    note: 'E',
    frequency: 528,
    nameKey: 'inline.plan294.singing_bowls.confidence_a1f3fb38',
    subtitleKey: 'inline.plan294.singing_bowls.solar_plexus_db0f8860',
    descriptionKey:
        'inline.plan294.singing_bowls.the_well_known_miracle_tone_that_brightens_the_c_32a689b9',
    accent: Color(0xFFC9A668),
    glow: Color(0xFFE2CD96),
    gradient: <Color>[Color(0xFFF6EFDD), Color(0xFFEEDFB7), Color(0xFFE0CB96)],
  ),
  _SingingBowlFrequencySpec(
    id: 'heart',
    group: _SingingBowlGroup.chakra,
    note: 'F',
    frequency: 639,
    nameKey: 'inline.plan294.singing_bowls.harmony_1e0b785d',
    subtitleKey: 'inline.plan294.singing_bowls.heart_chakra_c20761fb',
    descriptionKey:
        'inline.plan294.singing_bowls.softens_inner_and_outer_connection_making_it_esp_8dd96ffa',
    accent: Color(0xFF7FA58A),
    glow: Color(0xFFB4D1B8),
    gradient: <Color>[Color(0xFFEEF3ED), Color(0xFFDFE9DF), Color(0xFFC9D9CA)],
  ),
  _SingingBowlFrequencySpec(
    id: 'throat',
    group: _SingingBowlGroup.chakra,
    note: 'G',
    frequency: 741,
    nameKey: 'inline.plan294.singing_bowls.expression_fdd7d139',
    subtitleKey: 'inline.plan294.singing_bowls.throat_chakra_306d966f',
    descriptionKey:
        'inline.plan294.singing_bowls.clears_mental_noise_and_encourages_a_lighter_fre_f39f2b31',
    accent: Color(0xFF7BA1B0),
    glow: Color(0xFFB2CAD4),
    gradient: <Color>[Color(0xFFEDF2F5), Color(0xFFDCE6EC), Color(0xFFC6D5DE)],
  ),
  _SingingBowlFrequencySpec(
    id: 'third_eye',
    group: _SingingBowlGroup.chakra,
    note: 'A',
    frequency: 852,
    nameKey: 'inline.plan294.singing_bowls.insight_875905fc',
    subtitleKey: 'inline.plan294.singing_bowls.third_eye_c766b186',
    descriptionKey:
        'inline.plan294.singing_bowls.draws_attention_inward_and_supports_calm_lucid_o_f26562cf',
    accent: Color(0xFF8A8AB4),
    glow: Color(0xFFBBBBD5),
    gradient: <Color>[Color(0xFFEFEFF5), Color(0xFFE0E0EC), Color(0xFFCCCDE1)],
  ),
  _SingingBowlFrequencySpec(
    id: 'crown',
    group: _SingingBowlGroup.chakra,
    note: 'B',
    frequency: 963,
    nameKey: 'inline.plan294.singing_bowls.transcendence_51fa8018',
    subtitleKey: 'inline.plan294.singing_bowls.crown_chakra_5dac3b43',
    descriptionKey:
        'inline.plan294.singing_bowls.invites_a_more_spacious_meditative_stillness_wit_236bc98a',
    accent: Color(0xFFA091B8),
    glow: Color(0xFFCCBCDA),
    gradient: <Color>[Color(0xFFF1EEF3), Color(0xFFE3DCE8), Color(0xFFCEC4DA)],
  ),
  _SingingBowlFrequencySpec(
    id: '174',
    group: _SingingBowlGroup.resonance,
    note: 'F3',
    frequency: 174,
    nameKey: 'inline.plan294.singing_bowls.pain_relief_afbac6b7',
    subtitleKey: 'inline.plan294.singing_bowls.low_resonance_ce12f6d8',
    descriptionKey:
        'inline.plan294.singing_bowls.a_lower_denser_resonance_for_heavy_tired_moments_d81dcc49',
    accent: Color(0xFF8F8279),
    glow: Color(0xFFBFB4A8),
    gradient: <Color>[Color(0xFFF1EEE9), Color(0xFFE3DED5), Color(0xFFD0C9BC)],
  ),
  _SingingBowlFrequencySpec(
    id: '285',
    group: _SingingBowlGroup.resonance,
    note: 'D4',
    frequency: 285,
    nameKey: 'inline.plan294.singing_bowls.restoration_d61d54f5',
    subtitleKey: 'inline.plan294.singing_bowls.restoration_78c349d5',
    descriptionKey:
        'inline.plan294.singing_bowls.feels_like_a_restorative_bridge_between_the_lowe_95edb65f',
    accent: Color(0xFF7DA3A0),
    glow: Color(0xFFB2CDCA),
    gradient: <Color>[Color(0xFFEDF3F2), Color(0xFFDBE7E5), Color(0xFFC5D8D5)],
  ),
  _SingingBowlFrequencySpec(
    id: 'om',
    group: _SingingBowlGroup.resonance,
    note: 'C#',
    frequency: 136.1,
    nameKey: 'inline.plan294.singing_bowls.om_earth_23ddf060',
    subtitleKey: 'inline.plan294.singing_bowls.earth_tone_95754c2b',
    descriptionKey:
        'inline.plan294.singing_bowls.a_slower_deeper_meditative_bed_that_feels_ground_f0b6305a',
    accent: Color(0xFF6F9080),
    glow: Color(0xFFA4C3B2),
    gradient: <Color>[Color(0xFFEDF3EF), Color(0xFFDBE8DF), Color(0xFFC5D7C9)],
  ),
  _SingingBowlFrequencySpec(
    id: '432',
    group: _SingingBowlGroup.resonance,
    note: 'A4',
    frequency: 432,
    nameKey: 'inline.plan294.singing_bowls.universal_91f00e91',
    subtitleKey: 'inline.plan294.singing_bowls.432_hz_6b386efd',
    descriptionKey:
        'inline.plan294.singing_bowls.a_more_natural_feeling_tuning_that_settles_into__735a05b6',
    accent: Color(0xFF7A9DB4),
    glow: Color(0xFFADC6D5),
    gradient: <Color>[Color(0xFFEDF2F5), Color(0xFFDBE6EC), Color(0xFFC4D5DF)],
  ),
];

const List<_SingingBowlVoiceSpec> _bowlVoiceSpecs = <_SingingBowlVoiceSpec>[
  _SingingBowlVoiceSpec(
    id: 'crystal',
    icon: Icons.auto_awesome_rounded,
    nameKey: 'ref.toolbox.sound.harp.crystal',
    descriptionKey:
        'inline.plan294.singing_bowls.airy_and_bright_with_a_clearer_crystalline_overt_82d0cd4f',
    baseVolume: 0.76,
  ),
  _SingingBowlVoiceSpec(
    id: 'brass',
    icon: Icons.album_rounded,
    nameKey: 'inline.plan294.singing_bowls.brass_aa2d6119',
    descriptionKey:
        'inline.plan294.singing_bowls.fuller_metallic_overtones_with_a_broader_steadie_3548be22',
    baseVolume: 0.84,
  ),
  _SingingBowlVoiceSpec(
    id: 'deep',
    icon: Icons.nights_stay_rounded,
    nameKey: 'inline.plan294.singing_bowls.deep_2de4c68c',
    descriptionKey:
        'inline.plan294.singing_bowls.lower_and_weightier_suited_to_night_listening_an_5eb4db07',
    baseVolume: 0.88,
  ),
  _SingingBowlVoiceSpec(
    id: 'pure',
    icon: Icons.circle_outlined,
    nameKey: 'inline.plan294.singing_bowls.pure_2519936c',
    descriptionKey:
        'inline.plan294.singing_bowls.minimal_and_pure_focused_almost_entirely_on_the__cccd30be',
    baseVolume: 0.7,
  ),
];

final Map<String, _SingingBowlFrequencySpec> _bowlFrequencyById =
    <String, _SingingBowlFrequencySpec>{
      for (final spec in _bowlFrequencySpecs) spec.id: spec,
    };

final Map<String, _SingingBowlVoiceSpec> _bowlVoiceById =
    <String, _SingingBowlVoiceSpec>{
      for (final spec in _bowlVoiceSpecs) spec.id: spec,
    };
