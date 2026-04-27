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
    required this.nameZh,
    required this.nameEn,
    required this.subtitleZh,
    required this.subtitleEn,
    required this.descriptionZh,
    required this.descriptionEn,
    required this.accent,
    required this.glow,
    required this.gradient,
  });

  final String id;
  final _SingingBowlGroup group;
  final String note;
  final double frequency;
  final String nameZh;
  final String nameEn;
  final String subtitleZh;
  final String subtitleEn;
  final String descriptionZh;
  final String descriptionEn;
  final Color accent;
  final Color glow;
  final List<Color> gradient;

  String name(bool isZh) => isZh ? nameZh : nameEn;

  String subtitle(bool isZh) => isZh ? subtitleZh : subtitleEn;

  String description(bool isZh) => isZh ? descriptionZh : descriptionEn;
}

class _SingingBowlVoiceSpec {
  const _SingingBowlVoiceSpec({
    required this.id,
    required this.icon,
    required this.nameZh,
    required this.nameEn,
    required this.descriptionZh,
    required this.descriptionEn,
    required this.baseVolume,
  });

  final String id;
  final IconData icon;
  final String nameZh;
  final String nameEn;
  final String descriptionZh;
  final String descriptionEn;
  final double baseVolume;

  String name(bool isZh) => isZh ? nameZh : nameEn;

  String description(bool isZh) => isZh ? descriptionZh : descriptionEn;
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
    nameZh: '安定',
    nameEn: 'Stability',
    subtitleZh: '根轮共振',
    subtitleEn: 'Root chakra',
    descriptionZh: '释放焦虑与恐惧，让呼吸和身体重新落地，回到稳稳托住自己的根基。',
    descriptionEn:
        'Releases anxious tension and helps the body settle into grounded stability.',
    accent: Color(0xFFB87A6A),
    glow: Color(0xFFE1B0A0),
    gradient: <Color>[Color(0xFFF5ECE7), Color(0xFFEADAD0), Color(0xFFD8BCAD)],
  ),
  _SingingBowlFrequencySpec(
    id: 'sacral',
    group: _SingingBowlGroup.chakra,
    note: 'D',
    frequency: 417,
    nameZh: '活力',
    nameEn: 'Vitality',
    subtitleZh: '脐轮流动',
    subtitleEn: 'Sacral flow',
    descriptionZh: '松开压抑的情绪结块，让能量重新流动，带回温暖、柔软和生机。',
    descriptionEn:
        'Loosens emotional heaviness and restores warmth, softness, and flow.',
    accent: Color(0xFFC89070),
    glow: Color(0xFFE9BDA2),
    gradient: <Color>[Color(0xFFF7ECE3), Color(0xFFECD7C4), Color(0xFFDDBCA1)],
  ),
  _SingingBowlFrequencySpec(
    id: 'solar',
    group: _SingingBowlGroup.chakra,
    note: 'E',
    frequency: 528,
    nameZh: '自信',
    nameEn: 'Confidence',
    subtitleZh: '太阳神经丛',
    subtitleEn: 'Solar plexus',
    descriptionZh: '著名的"奇迹频率"，带来更清晰的内在中心感，扶起行动力与自信。',
    descriptionEn:
        'The well-known miracle tone that brightens the center and lifts confidence.',
    accent: Color(0xFFC9A668),
    glow: Color(0xFFE2CD96),
    gradient: <Color>[Color(0xFFF6EFDD), Color(0xFFEEDFB7), Color(0xFFE0CB96)],
  ),
  _SingingBowlFrequencySpec(
    id: 'heart',
    group: _SingingBowlGroup.chakra,
    note: 'F',
    frequency: 639,
    nameZh: '和谐',
    nameEn: 'Harmony',
    subtitleZh: '心轮开阔',
    subtitleEn: 'Heart chakra',
    descriptionZh: '促进人与自己、人与外界之间更柔和的联结，适合久听与沉静放松。',
    descriptionEn:
        'Softens inner and outer connection, making it especially suited to longer listening.',
    accent: Color(0xFF7FA58A),
    glow: Color(0xFFB4D1B8),
    gradient: <Color>[Color(0xFFEEF3ED), Color(0xFFDFE9DF), Color(0xFFC9D9CA)],
  ),
  _SingingBowlFrequencySpec(
    id: 'throat',
    group: _SingingBowlGroup.chakra,
    note: 'G',
    frequency: 741,
    nameZh: '表达',
    nameEn: 'Expression',
    subtitleZh: '喉轮澄明',
    subtitleEn: 'Throat chakra',
    descriptionZh: '清理纷乱思绪，带来通透与轻盈，更自由地表达真实的感受与声音。',
    descriptionEn:
        'Clears mental noise and encourages a lighter, freer sense of expression.',
    accent: Color(0xFF7BA1B0),
    glow: Color(0xFFB2CAD4),
    gradient: <Color>[Color(0xFFEDF2F5), Color(0xFFDCE6EC), Color(0xFFC6D5DE)],
  ),
  _SingingBowlFrequencySpec(
    id: 'third_eye',
    group: _SingingBowlGroup.chakra,
    note: 'A',
    frequency: 852,
    nameZh: '洞察',
    nameEn: 'Insight',
    subtitleZh: '眉心观照',
    subtitleEn: 'Third eye',
    descriptionZh: '让注意力从外界收回到内在，保持冷静、清澈的观察感与直觉。',
    descriptionEn:
        'Draws attention inward and supports calm, lucid observation and intuition.',
    accent: Color(0xFF8A8AB4),
    glow: Color(0xFFBBBBD5),
    gradient: <Color>[Color(0xFFEFEFF5), Color(0xFFE0E0EC), Color(0xFFCCCDE1)],
  ),
  _SingingBowlFrequencySpec(
    id: 'crown',
    group: _SingingBowlGroup.chakra,
    note: 'B',
    frequency: 963,
    nameZh: '升华',
    nameEn: 'Transcendence',
    subtitleZh: '顶轮宁静',
    subtitleEn: 'Crown chakra',
    descriptionZh: '收束杂音、回到纯净的精神秩序，适合更冥想、更空灵的停留。',
    descriptionEn:
        'Invites a more spacious, meditative stillness with a lighter and more transcendental halo.',
    accent: Color(0xFFA091B8),
    glow: Color(0xFFCCBCDA),
    gradient: <Color>[Color(0xFFF1EEF3), Color(0xFFE3DCE8), Color(0xFFCEC4DA)],
  ),
  _SingingBowlFrequencySpec(
    id: '174',
    group: _SingingBowlGroup.resonance,
    note: 'F3',
    frequency: 174,
    nameZh: '镇痛',
    nameEn: 'Pain Relief',
    subtitleZh: '低频安抚',
    subtitleEn: 'Low resonance',
    descriptionZh: '更低、更厚、更靠近身体感，适合夜里、疲惫时或压力沉重的时候。',
    descriptionEn:
        'A lower, denser resonance for heavy, tired moments that need deeper grounding.',
    accent: Color(0xFF8F8279),
    glow: Color(0xFFBFB4A8),
    gradient: <Color>[Color(0xFFF1EEE9), Color(0xFFE3DED5), Color(0xFFD0C9BC)],
  ),
  _SingingBowlFrequencySpec(
    id: '285',
    group: _SingingBowlGroup.resonance,
    note: 'D4',
    frequency: 285,
    nameZh: '修复',
    nameEn: 'Restoration',
    subtitleZh: '修复频带',
    subtitleEn: 'Restoration',
    descriptionZh: '像一条柔和的修复带，在低频和中心频率之间架起更平衡的过渡。',
    descriptionEn:
        'Feels like a restorative bridge between the lower field and the more centered tones.',
    accent: Color(0xFF7DA3A0),
    glow: Color(0xFFB2CDCA),
    gradient: <Color>[Color(0xFFEDF3F2), Color(0xFFDBE7E5), Color(0xFFC5D8D5)],
  ),
  _SingingBowlFrequencySpec(
    id: 'om',
    group: _SingingBowlGroup.resonance,
    note: 'C#',
    frequency: 136.1,
    nameZh: '地球',
    nameEn: 'Om / Earth',
    subtitleZh: '地球原音',
    subtitleEn: 'Earth tone',
    descriptionZh: '像更慢、更深的一层冥想底床，接地、安静，带着沉稳的归属感。',
    descriptionEn:
        'A slower, deeper meditative bed that feels grounded, calm, and belonging.',
    accent: Color(0xFF6F9080),
    glow: Color(0xFFA4C3B2),
    gradient: <Color>[Color(0xFFEDF3EF), Color(0xFFDBE8DF), Color(0xFFC5D7C9)],
  ),
  _SingingBowlFrequencySpec(
    id: '432',
    group: _SingingBowlGroup.resonance,
    note: 'A4',
    frequency: 432,
    nameZh: '自然',
    nameEn: 'Universal',
    subtitleZh: '自然调谐',
    subtitleEn: '432 Hz',
    descriptionZh: '与更自然的呼吸和节律贴近，适合当作长时间背景共振慢慢陪伴。',
    descriptionEn:
        'A more natural-feeling tuning that settles into longer, softer background resonance.',
    accent: Color(0xFF7A9DB4),
    glow: Color(0xFFADC6D5),
    gradient: <Color>[Color(0xFFEDF2F5), Color(0xFFDBE6EC), Color(0xFFC4D5DF)],
  ),
];

const List<_SingingBowlVoiceSpec> _bowlVoiceSpecs = <_SingingBowlVoiceSpec>[
  _SingingBowlVoiceSpec(
    id: 'crystal',
    icon: Icons.auto_awesome_rounded,
    nameZh: '水晶',
    nameEn: 'Crystal',
    descriptionZh: '空灵清脆，带着更明亮、更通透的泛音边缘。',
    descriptionEn: 'Airy and bright, with a clearer crystalline overtone edge.',
    baseVolume: 0.76,
  ),
  _SingingBowlVoiceSpec(
    id: 'brass',
    icon: Icons.album_rounded,
    nameZh: '铜钵',
    nameEn: 'Brass',
    descriptionZh: '泛音饱满，金属体感更厚，尾音更稳、更宽。',
    descriptionEn: 'Fuller metallic overtones with a broader, steadier tail.',
    baseVolume: 0.84,
  ),
  _SingingBowlVoiceSpec(
    id: 'deep',
    icon: Icons.nights_stay_rounded,
    nameZh: '深邃',
    nameEn: 'Deep',
    descriptionZh: '低沉厚重，下潜感更强，更适合夜晚与深度放松。',
    descriptionEn:
        'Lower and weightier, suited to night listening and deep unwinding.',
    baseVolume: 0.88,
  ),
  _SingingBowlVoiceSpec(
    id: 'pure',
    icon: Icons.circle_outlined,
    nameZh: '纯净',
    nameEn: 'Pure',
    descriptionZh: '极简正弦，只保留最核心的频率与朴素的回响。',
    descriptionEn:
        'Minimal and pure, focused almost entirely on the core tone.',
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
