import 'package:flutter/material.dart';

import '../i18n/app_i18n.dart';
import '../ui/ui_copy.dart';

@immutable
class BreathingCopy {
  const BreathingCopy(this.zh, this.en);

  final String zh;
  final String en;

  String resolve(AppI18n i18n) => pickUiText(i18n, zh: zh, en: en);
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

  static const String remotePrefix = 'follow_this_breath/follow_this_breath';

  static const List<BreathingThemeSpec> themes = <BreathingThemeSpec>[
    BreathingThemeSpec(
      id: 'ocean',
      name: BreathingCopy('潮汐蓝光', 'Ocean glow'),
      mood: BreathingCopy(
        '像潮水一样慢慢把呼气拉长。',
        'Stretch the exhale like a slow tide.',
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
      name: BreathingCopy('林雾绿意', 'Forest mist'),
      mood: BreathingCopy(
        '让吸气和呼气像走进安静树林那样稳定。',
        'Steady inhale and exhale like entering a quiet forest.',
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
      name: BreathingCopy('余烬安定', 'Ember calm'),
      mood: BreathingCopy(
        '把身体里的热和急一点点放出去。',
        'Let emotional heat leave a little at a time.',
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
      name: BreathingCopy('高山气流', 'Alpine air'),
      mood: BreathingCopy(
        '让节拍更克制，把注意力收回到呼吸效率。',
        'A more disciplined pace focused on efficiency and recovery.',
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
      name: BreathingCopy('极光专注', 'Aurora focus'),
      mood: BreathingCopy(
        '把注意力带回一进一出的稳定脉冲。',
        'Pull attention back into the pulse of breathing.',
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
      name: BreathingCopy('吸气提示', 'Inhale cue'),
      remoteFileNames: <String>['吸气.wav'],
      approxDurationMs: 1200,
      assetPath: 'follow_this_breath/吸气.wav',
    ),
    'exhale_soft': BreathingCueSpec(
      id: 'exhale_soft',
      name: BreathingCopy('呼气提示', 'Exhale cue'),
      remoteFileNames: <String>['呼气.wav'],
      approxDurationMs: 2400,
      assetPath: 'follow_this_breath/呼气.wav',
    ),
    'hold_soft': BreathingCueSpec(
      id: 'hold_soft',
      name: BreathingCopy('屏息提示', 'Hold cue'),
      remoteFileNames: <String>['屏息.wav'],
      approxDurationMs: 2160,
      assetPath: 'follow_this_breath/屏息.wav',
    ),
    'nose_inhale': BreathingCueSpec(
      id: 'nose_inhale',
      name: BreathingCopy('鼻吸提示', 'Nasal inhale cue'),
      remoteFileNames: <String>['鼻子吸气.wav'],
      approxDurationMs: 3760,
      assetPath: 'follow_this_breath/鼻子吸气.wav',
    ),
    'nose_exhale': BreathingCueSpec(
      id: 'nose_exhale',
      name: BreathingCopy('鼻呼提示', 'Nasal exhale cue'),
      remoteFileNames: <String>['鼻子呼气.wav'],
      approxDurationMs: 3360,
      assetPath: 'follow_this_breath/鼻子呼气.wav',
    ),
    'mouth_inhale': BreathingCueSpec(
      id: 'mouth_inhale',
      name: BreathingCopy('口吸提示', 'Mouth inhale cue'),
      remoteFileNames: <String>['嘴吸气.wav'],
      approxDurationMs: 2960,
      assetPath: 'follow_this_breath/嘴吸气.wav',
    ),
    'mouth_exhale': BreathingCueSpec(
      id: 'mouth_exhale',
      name: BreathingCopy('口呼提示', 'Mouth exhale cue'),
      remoteFileNames: <String>['嘴呼气.wav'],
      approxDurationMs: 3760,
      assetPath: 'follow_this_breath/嘴呼气.wav',
    ),
    'preview_relax': BreathingCueSpec(
      id: 'preview_relax',
      name: BreathingCopy('放松引导', 'Relax guidance'),
      remoteFileNames: <String>['放松.wav'],
      approxDurationMs: 29040,
      assetPath: 'follow_this_breath/放松.wav',
    ),
    'preview_intro_1': BreathingCueSpec(
      id: 'preview_intro_1',
      name: BreathingCopy('呼吸引导 1', 'Breath guide 1'),
      remoteFileNames: <String>['呼吸引导1.wav'],
      approxDurationMs: 24986,
      assetPath: 'follow_this_breath/呼吸引导1.wav',
    ),
    'preview_intro_2': BreathingCueSpec(
      id: 'preview_intro_2',
      name: BreathingCopy('呼吸引导 2', 'Breath guide 2'),
      remoteFileNames: <String>['呼吸引导2.wav'],
      approxDurationMs: 33841,
      assetPath: 'follow_this_breath/呼吸引导2.wav',
    ),
    'preview_nose_slow': BreathingCueSpec(
      id: 'preview_nose_slow',
      name: BreathingCopy('鼻吸示范', 'Nasal inhale demo'),
      remoteFileNames: <String>['开始用鼻子缓缓吸气.wav'],
      approxDurationMs: 3120,
      assetPath: 'follow_this_breath/开始用鼻子缓缓吸气.wav',
    ),
    'preview_parasym': BreathingCueSpec(
      id: 'preview_parasym',
      name: BreathingCopy('副交感切换引导', 'Parasympathetic guide'),
      remoteFileNames: <String>['副交感交替.wav'],
      approxDurationMs: 13360,
      assetPath: 'follow_this_breath/副交感交替.wav',
    ),
    'preview_altitude': BreathingCueSpec(
      id: 'preview_altitude',
      name: BreathingCopy('快速叹息引导', 'Cyclic sigh guide'),
      remoteFileNames: <String>['快速嘴吸气屏气.wav'],
      approxDurationMs: 4000,
      assetPath: 'follow_this_breath/快速嘴吸气屏气.wav',
    ),
  };

  static const List<BreathingScenario> scenarios = <BreathingScenario>[
    BreathingScenario(
      id: 'diaphragm_4262',
      name: BreathingCopy('腹式基础 4-2-6-2', 'Diaphragm 4-2-6-2'),
      scene: BreathingCopy(
        '建立腹式呼吸手感的默认训练。',
        'Default mode for learning diaphragmatic breathing.',
      ),
      description: BreathingCopy(
        '用鼻吸鼻呼，吸气时腹部向外，呼气时腹部回落。适合作为日常基础练习。',
        'Nasal inhale and exhale with a belly expansion on inhale and release on exhale.',
      ),
      bodyFocus: BreathingCopy(
        '肩颈保持放松，胸口不过度抬起，让腹部带动节奏。',
        'Keep the shoulders soft and let the belly, not the chest, drive the motion.',
      ),
      whenToUse: BreathingCopy(
        '适合早晨启动、久坐后重新调整呼吸，或学习间隙做基础稳态练习。',
        'Use at the start of the day, after long sitting, or between study blocks.',
      ),
      researchBasis: BreathingCopy(
        '腹式呼吸在健康成年人研究中与压力下降、注意力改善相关，适合作为入门训练。',
        'Diaphragmatic breathing has been linked to lower stress and better attention in healthy adults.',
      ),
      mechanism: BreathingCopy(
        '降低辅助呼吸肌紧张，提升膈肌参与度，让呼吸更深、更稳。',
        'It shifts work toward the diaphragm and away from unnecessary upper-body tension.',
      ),
      themeId: 'ocean',
      previewCueId: 'preview_nose_slow',
      recommendedMinutes: 5,
      tags: <BreathingCopy>[
        BreathingCopy('入门', 'Starter'),
        BreathingCopy('腹式', 'Diaphragm'),
        BreathingCopy('日常', 'Daily'),
      ],
      stages: <BreathingStagePlan>[
        BreathingStagePlan(
          kind: BreathingStageKind.inhale,
          seconds: 4,
          label: BreathingCopy('鼻吸', 'Nasal inhale'),
          prompt: BreathingCopy('让腹部轻轻鼓起', 'Expand the belly'),
          cueId: 'nose_inhale',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.hold,
          seconds: 2,
          label: BreathingCopy('停留', 'Hold'),
          prompt: BreathingCopy('轻停，不要硬憋', 'Pause lightly without straining'),
          cueId: 'hold_soft',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.exhale,
          seconds: 6,
          label: BreathingCopy('鼻呼', 'Nasal exhale'),
          prompt: BreathingCopy('缓缓把气放长', 'Lengthen the exhale'),
          cueId: 'nose_exhale',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.rest,
          seconds: 2,
          label: BreathingCopy('回稳', 'Settle'),
          prompt: BreathingCopy('让身体自然回落', 'Let the body settle'),
        ),
      ],
    ),
    BreathingScenario(
      id: 'focus_nasal_44',
      name: BreathingCopy('鼻吸聚焦 4-4', 'Nasal focus 4-4'),
      scene: BreathingCopy(
        '开工前、阅读前、任务切换时的安静聚焦。',
        'A quiet focusing rhythm before deep work, reading, or task switching.',
      ),
      description: BreathingCopy(
        '全程鼻吸鼻呼，不加屏息，让注意力稳定贴住呼吸。',
        'Nasal-only breathing without holds keeps attention anchored without overstimulating.',
      ),
      bodyFocus: BreathingCopy(
        '吸气和呼气一样长，不追求大口，避免把自己吹得发飘。',
        'Keep inhale and exhale equal and avoid over-breathing.',
      ),
      whenToUse: BreathingCopy(
        '适合进入深度工作前、阅读前，或想把视线和心绪收回来时。',
        'Use before focused work or any time you want to gather your attention back in.',
      ),
      researchBasis: BreathingCopy(
        '鼻呼吸与认知网络和情绪线路同步研究有关，适合需要清醒又不想过度激活的人。',
        'Nasal breathing has been linked to limbic and cognitive timing, making it useful for calm alertness.',
      ),
      mechanism: BreathingCopy(
        '保留平稳节拍和鼻呼吸的感觉输入，把专注建立在稳定而不是刺激上。',
        'It combines a steady rhythm with the sensory pattern of nasal breathing to support stable focus.',
      ),
      themeId: 'aurora',
      previewCueId: 'preview_intro_1',
      recommendedMinutes: 4,
      tags: <BreathingCopy>[
        BreathingCopy('专注', 'Focus'),
        BreathingCopy('鼻吸', 'Nasal'),
        BreathingCopy('清醒', 'Alert'),
      ],
      stages: <BreathingStagePlan>[
        BreathingStagePlan(
          kind: BreathingStageKind.inhale,
          seconds: 4,
          label: BreathingCopy('鼻吸', 'Nasal inhale'),
          prompt: BreathingCopy('平稳吸满四拍', 'Inhale evenly for four'),
          cueId: 'nose_inhale',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.exhale,
          seconds: 4,
          label: BreathingCopy('鼻呼', 'Nasal exhale'),
          prompt: BreathingCopy('平稳呼出四拍', 'Exhale evenly for four'),
          cueId: 'nose_exhale',
        ),
      ],
    ),
    BreathingScenario(
      id: 'box_4444',
      name: BreathingCopy('方块稳定 4-4-4-4', 'Box 4-4-4-4'),
      scene: BreathingCopy(
        '会前、演讲前、任务启动前的节拍稳定。',
        'Steady your rhythm before meetings, talks, or demanding tasks.',
      ),
      description: BreathingCopy(
        '四段等长，像在心里画一个正方形，把注意力从外部压力拉回到可控节拍。',
        'Four equal sides create a square rhythm that pulls attention back from pressure.',
      ),
      bodyFocus: BreathingCopy(
        '每一段都保持同样长度，遇到紧张时先守住节拍，不追求更深。',
        'Keep each side the same length and prioritize consistency over depth.',
      ),
      whenToUse: BreathingCopy(
        '适合高压任务前做 2-5 分钟的稳定化；如果屏息不舒服，改用共振 5-5。',
        'Best for a 2-5 minute reset before a demanding task; switch to 5-5 if the holds feel uncomfortable.',
      ),
      researchBasis: BreathingCopy(
        '它更偏向节拍控制和注意力锚定，而不是强刺激；适合作为压力前的呼吸校准。',
        'It works best as a pacing and attention anchor rather than a high-intensity technique.',
      ),
      mechanism: BreathingCopy(
        '规则计数降低呼吸漂移，让身体和注意力一起回到可预测节奏。',
        'The regular counting pattern reduces drift and brings attention back to a predictable cycle.',
      ),
      themeId: 'aurora',
      previewCueId: 'preview_intro_1',
      recommendedMinutes: 3,
      caution: BreathingCopy(
        '如果屏息让你更紧张，请改用“共振慢呼 5-5”或“平息长呼 3-6”。',
        'If breath holding makes you more tense, switch to Coherent 5-5 or Calm 3-6.',
      ),
      tags: <BreathingCopy>[
        BreathingCopy('会前', 'Pre-task'),
        BreathingCopy('节拍', 'Pacing'),
        BreathingCopy('稳定', 'Steady'),
      ],
      stages: <BreathingStagePlan>[
        BreathingStagePlan(
          kind: BreathingStageKind.inhale,
          seconds: 4,
          label: BreathingCopy('吸气', 'Inhale'),
          prompt: BreathingCopy('吸满四拍', 'Fill for four beats'),
          cueId: 'inhale_soft',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.hold,
          seconds: 4,
          label: BreathingCopy('停住', 'Hold'),
          prompt: BreathingCopy('保持稳定', 'Stay steady'),
          cueId: 'hold_soft',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.exhale,
          seconds: 4,
          label: BreathingCopy('呼气', 'Exhale'),
          prompt: BreathingCopy('按同样节拍放掉', 'Release on the same count'),
          cueId: 'exhale_soft',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.rest,
          seconds: 4,
          label: BreathingCopy('停顿', 'Pause'),
          prompt: BreathingCopy('准备下一轮', 'Prepare the next cycle'),
        ),
      ],
    ),
    BreathingScenario(
      id: 'coherent_55',
      name: BreathingCopy('共振慢呼 5-5', 'Coherent 5-5'),
      scene: BreathingCopy(
        '任务切换、情绪波动后、想回到稳态时的核心模式。',
        'Balanced breathing for transitions and longer regulation sessions.',
      ),
      description: BreathingCopy(
        '均匀吸、均匀呼，适合做 5-10 分钟的稳态练习。',
        'Equal inhale and exhale are ideal for longer steady-state regulation sessions.',
      ),
      bodyFocus: BreathingCopy(
        '让吸气和呼气都保持圆润，不额外加屏息。',
        'Keep both directions smooth and rounded without extra holds.',
      ),
      whenToUse: BreathingCopy(
        '适合番茄钟之间、情绪恢复期、工作和休息转换时。',
        'Use between focus blocks or during transitions between work and recovery.',
      ),
      researchBasis: BreathingCopy(
        '接近每分钟 5-6 次的慢呼吸，是 HRV 和压力调节研究中最常见的训练区间。',
        'Slow breathing near 5-6 breaths per minute is the most studied range for HRV and regulation.',
      ),
      mechanism: BreathingCopy(
        '更容易进入呼吸和心率同步的节奏，帮助稳定注意力与恢复感。',
        'It supports a rhythm that more readily synchronizes breathing and heart-rate dynamics.',
      ),
      themeId: 'forest',
      previewCueId: 'preview_intro_1',
      recommendedMinutes: 8,
      tags: <BreathingCopy>[
        BreathingCopy('稳态', 'Steady state'),
        BreathingCopy('恢复', 'Recovery'),
        BreathingCopy('HRV', 'HRV'),
      ],
      stages: <BreathingStagePlan>[
        BreathingStagePlan(
          kind: BreathingStageKind.inhale,
          seconds: 5,
          label: BreathingCopy('吸气', 'Inhale'),
          prompt: BreathingCopy('均匀吸入', 'Inhale evenly'),
          cueId: 'inhale_soft',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.exhale,
          seconds: 5,
          label: BreathingCopy('呼气', 'Exhale'),
          prompt: BreathingCopy('均匀呼出', 'Exhale evenly'),
          cueId: 'exhale_soft',
        ),
      ],
    ),
    BreathingScenario(
      id: 'relax_4262',
      name: BreathingCopy('放松延呼 4-2-6-2', 'Unwind 4-2-6-2'),
      scene: BreathingCopy(
        '下班、运动后、长时间用脑后的降速模式。',
        'A downshift rhythm for after work, exercise, or heavy screen time.',
      ),
      description: BreathingCopy(
        '延长呼气，让身体从高唤醒慢慢回到恢复区。',
        'A longer exhale helps the body come down from a high-alert state.',
      ),
      bodyFocus: BreathingCopy(
        '呼气时下颌放松，肩颈跟着一起往下落。',
        'Relax the jaw and let the shoulders drop with the exhale.',
      ),
      whenToUse: BreathingCopy(
        '适合连续工作 45 分钟后、通勤结束后，或想慢下来时。',
        'Use after long work blocks, after commuting, or whenever you need to slow down.',
      ),
      researchBasis: BreathingCopy(
        '长呼气慢呼吸常被用于帮助身体从高唤醒转向恢复和放松。',
        'Slow breathing with a longer exhale is commonly used to shift from activation toward recovery.',
      ),
      mechanism: BreathingCopy(
        '把呼气拉长到吸气之上，给副交感占优势留出窗口。',
        'Extending the exhale relative to the inhale creates more room for down-regulation.',
      ),
      themeId: 'forest',
      previewCueId: 'preview_relax',
      recommendedMinutes: 5,
      tags: <BreathingCopy>[
        BreathingCopy('放松', 'Relax'),
        BreathingCopy('长呼气', 'Long exhale'),
        BreathingCopy('恢复', 'Recovery'),
      ],
      stages: <BreathingStagePlan>[
        BreathingStagePlan(
          kind: BreathingStageKind.inhale,
          seconds: 4,
          label: BreathingCopy('吸气', 'Inhale'),
          prompt: BreathingCopy('轻柔吸满', 'Inhale softly'),
          cueId: 'inhale_soft',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.hold,
          seconds: 2,
          label: BreathingCopy('停留', 'Hold'),
          prompt: BreathingCopy('只做轻停', 'Keep it light'),
          cueId: 'hold_soft',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.exhale,
          seconds: 6,
          label: BreathingCopy('长呼气', 'Long exhale'),
          prompt: BreathingCopy(
            '慢慢放掉肩颈紧张',
            'Release neck and shoulder tension',
          ),
          cueId: 'exhale_soft',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.rest,
          seconds: 2,
          label: BreathingCopy('回稳', 'Rest'),
          prompt: BreathingCopy('让节拍沉下来', 'Let the pace settle'),
        ),
      ],
    ),
    BreathingScenario(
      id: 'calm_36',
      name: BreathingCopy('平息长呼 3-6', 'Calm 3-6'),
      scene: BreathingCopy(
        '焦躁、争执后、心跳偏快时先降强度。',
        'A simple de-escalation rhythm for agitation or a racing mind.',
      ),
      description: BreathingCopy(
        '短吸长呼，不额外屏息，在紧张时更容易执行。',
        'A short inhale and long exhale are easier to use when you already feel activated.',
      ),
      bodyFocus: BreathingCopy(
        '先把呼气做完整，再让下一次吸气自然回来。',
        'Finish the exhale fully before letting the next inhale arrive.',
      ),
      whenToUse: BreathingCopy(
        '适合临时平息情绪、会议前心跳偏快，或刚从压力消息里出来时。',
        'Use when emotions are elevated and you need a quick downshift.',
      ),
      researchBasis: BreathingCopy(
        '在已经紧张的时候，不带长屏息的长呼气模式通常更容易坚持。',
        'When you are already activated, long-exhale patterns without long holds are often easier to sustain.',
      ),
      mechanism: BreathingCopy(
        '优先做完整呼气，帮助降低呼吸频率和防御性肌肉紧张。',
        'Prioritizing the exhale can help lower breathing frequency and soften defensive tension.',
      ),
      themeId: 'ember',
      previewCueId: 'preview_intro_2',
      recommendedMinutes: 3,
      tags: <BreathingCopy>[
        BreathingCopy('急用', 'Rapid reset'),
        BreathingCopy('低门槛', 'Accessible'),
        BreathingCopy('长呼气', 'Long exhale'),
      ],
      stages: <BreathingStagePlan>[
        BreathingStagePlan(
          kind: BreathingStageKind.inhale,
          seconds: 3,
          label: BreathingCopy('吸气', 'Inhale'),
          prompt: BreathingCopy('轻轻吸入', 'Inhale lightly'),
          cueId: 'inhale_soft',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.exhale,
          seconds: 6,
          label: BreathingCopy('长呼气', 'Long exhale'),
          prompt: BreathingCopy('把气慢慢吐净', 'Empty the breath fully'),
          cueId: 'exhale_soft',
        ),
      ],
    ),
    BreathingScenario(
      id: 'sleep_46',
      name: BreathingCopy('睡前轻缓 4-6', 'Bedtime 4-6'),
      scene: BreathingCopy(
        '准备入睡或夜间醒来后的轻柔节奏。',
        'A gentle bedtime rhythm for settling into sleep or returning to sleep.',
      ),
      description: BreathingCopy(
        '不加屏息，保持轻吸长呼，避免把自己练得更清醒。',
        'No breath hold, just a gentle inhale and longer exhale so you do not wake yourself up more.',
      ),
      bodyFocus: BreathingCopy(
        '吸气不追求深，呼气像慢慢放气，越安静越好。',
        'Do not chase a deep inhale. Think of the exhale as a slow soft release.',
      ),
      whenToUse: BreathingCopy(
        '适合关灯后、半夜醒来后，或想把节奏慢慢带向睡眠时。',
        'Use after lights out, after waking in the night, or whenever you want to drift toward sleep.',
      ),
      researchBasis: BreathingCopy(
        '睡前慢呼吸与放松干预常用于缩短入睡前的高唤醒阶段。',
        'Pre-sleep slow breathing is commonly used to reduce the arousal that blocks sleep onset.',
      ),
      mechanism: BreathingCopy(
        '减少呼吸用力和认知负担，让身体更容易接受“可以睡了”的信号。',
        'It lowers effort and cognitive load so the body can accept a quieter bedtime signal.',
      ),
      themeId: 'ember',
      previewCueId: 'preview_relax',
      recommendedMinutes: 8,
      tags: <BreathingCopy>[
        BreathingCopy('睡前', 'Bedtime'),
        BreathingCopy('轻柔', 'Gentle'),
        BreathingCopy('无屏息', 'No hold'),
      ],
      stages: <BreathingStagePlan>[
        BreathingStagePlan(
          kind: BreathingStageKind.inhale,
          seconds: 4,
          label: BreathingCopy('鼻吸', 'Nasal inhale'),
          prompt: BreathingCopy('轻轻吸满四拍', 'Inhale gently for four'),
          cueId: 'nose_inhale',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.exhale,
          seconds: 6,
          label: BreathingCopy('鼻呼', 'Nasal exhale'),
          prompt: BreathingCopy('慢慢放长呼气', 'Exhale slowly for six'),
          cueId: 'nose_exhale',
        ),
      ],
    ),
    BreathingScenario(
      id: 'sleep_478',
      name: BreathingCopy('经典 4-7-8', 'Classic 4-7-8'),
      scene: BreathingCopy(
        '更慢、更克制的进阶睡前节律。',
        'A slower, more deliberate bedtime rhythm for people already comfortable with slow breathing.',
      ),
      description: BreathingCopy(
        '经典 4-7-8 节律，适合已经能舒适地做慢呼吸的人作为睡前进阶版。',
        'Classic 4-7-8 pacing for bedtime, best used as an advanced option if you already tolerate slow breathing well.',
      ),
      bodyFocus: BreathingCopy(
        '吸气不要过深，重点是安静和耐心地把呼气放长。',
        'Do not overfill the inhale. Quietness and a patient exhale matter more.',
      ),
      whenToUse: BreathingCopy(
        '适合临睡前 3-5 分钟；如果长屏息让你紧张，立刻改用“睡前轻缓 4-6”。',
        'Use for a few minutes right before sleep; switch to Bedtime 4-6 if the long hold feels too strong.',
      ),
      researchBasis: BreathingCopy(
        '它属于更慢、更强的节律呼吸变体，适合已经具备舒适慢呼吸基础的人。',
        'This is a slower and more demanding paced-breathing variant best suited to experienced users.',
      ),
      mechanism: BreathingCopy(
        '较长屏息和长呼气会显著放慢整体节拍，只适合在舒适区内使用。',
        'The long hold and long exhale slow the whole cycle down substantially, so comfort limits matter.',
      ),
      themeId: 'ember',
      previewCueId: 'preview_intro_2',
      recommendedMinutes: 4,
      advanced: true,
      caution: BreathingCopy(
        '如果 7 秒屏息让你不舒服，请改用“睡前轻缓 4-6”或“放松延呼 4-2-6-2”。',
        'If the 7-second hold feels uncomfortable, switch to Bedtime 4-6 or Unwind 4-2-6-2.',
      ),
      tags: <BreathingCopy>[
        BreathingCopy('睡前', 'Bedtime'),
        BreathingCopy('经典', 'Classic'),
        BreathingCopy('进阶', 'Advanced'),
      ],
      stages: <BreathingStagePlan>[
        BreathingStagePlan(
          kind: BreathingStageKind.inhale,
          seconds: 4,
          label: BreathingCopy('鼻吸', 'Nasal inhale'),
          prompt: BreathingCopy('轻轻吸满四拍', 'Inhale gently for four'),
          cueId: 'nose_inhale',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.hold,
          seconds: 7,
          label: BreathingCopy('屏息', 'Hold'),
          prompt: BreathingCopy('只停留在舒适范围', 'Stay within comfort'),
          cueId: 'hold_soft',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.exhale,
          seconds: 8,
          label: BreathingCopy('口呼', 'Mouth exhale'),
          prompt: BreathingCopy('像轻叹一样慢慢呼出', 'Exhale long like a soft sigh'),
          cueId: 'mouth_exhale',
        ),
      ],
    ),
    BreathingScenario(
      id: 'parasym_4462',
      name: BreathingCopy('副交感切换 4-4-6-2', 'Parasym reset 4-4-6-2'),
      scene: BreathingCopy(
        '从工作模式切回恢复模式。',
        'Shift from task mode into recovery mode.',
      ),
      description: BreathingCopy(
        '较长呼气加短恢复停顿，帮助身体从追赶状态切回稳态恢复。',
        'A longer exhale plus a short recovery pause help shift the body away from urgency and back to recovery.',
      ),
      bodyFocus: BreathingCopy(
        '呼气结束后停两拍，感受心率和肩颈一起慢下来。',
        'After the exhale, notice the quiet rest and the body slowing down with it.',
      ),
      whenToUse: BreathingCopy(
        '适合通勤结束后、冥想前、洗漱后，或作为晚间收尾过渡。',
        'Use after commuting, before meditation, or as an evening transition.',
      ),
      researchBasis: BreathingCopy(
        '慢速呼吸和较长呼气常用于恢复段、晚间过渡和冥想前的下行切换。',
        'Slow breathing with a longer exhale is commonly used for evening downshifts and recovery transitions.',
      ),
      mechanism: BreathingCopy(
        '把长呼气和短暂停顿放在一起，让节奏从“追赶”切回“回收”。',
        'The long exhale plus short pause helps the rhythm shift from urgency toward restoration.',
      ),
      themeId: 'ocean',
      previewCueId: 'preview_parasym',
      recommendedMinutes: 8,
      tags: <BreathingCopy>[
        BreathingCopy('副交感', 'Parasym'),
        BreathingCopy('晚间', 'Evening'),
        BreathingCopy('恢复', 'Recovery'),
      ],
      stages: <BreathingStagePlan>[
        BreathingStagePlan(
          kind: BreathingStageKind.inhale,
          seconds: 4,
          label: BreathingCopy('鼻吸', 'Nasal inhale'),
          prompt: BreathingCopy('平稳吸入', 'Inhale steadily'),
          cueId: 'nose_inhale',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.hold,
          seconds: 4,
          label: BreathingCopy('停留', 'Hold'),
          prompt: BreathingCopy('只保留轻微张力', 'Keep only a gentle tone'),
          cueId: 'hold_soft',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.exhale,
          seconds: 6,
          label: BreathingCopy('长呼气', 'Long exhale'),
          prompt: BreathingCopy(
            '让心跳跟着一起慢下来',
            'Let the pulse follow the exhale',
          ),
          cueId: 'nose_exhale',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.rest,
          seconds: 2,
          label: BreathingCopy('恢复', 'Rest'),
          prompt: BreathingCopy('感受身体回落', 'Feel the settling'),
        ),
      ],
    ),
    BreathingScenario(
      id: 'physiological_sigh_216',
      name: BreathingCopy('生理性叹息 2-1-6', 'Physiological sigh 2-1-6'),
      scene: BreathingCopy(
        '突发紧张、屏幕压迫感、胸口发紧时的短练习。',
        'A short drill for acute stress, screen-pressure fatigue, or chest tightness before a task.',
      ),
      description: BreathingCopy(
        '两段吸气后接一段更长的呼气，适合做 1-2 分钟短练，不建议长时间连续做。',
        'Two inhales followed by a longer exhale work best as a brief 1-2 minute practice rather than a long session.',
      ),
      bodyFocus: BreathingCopy(
        '第一次吸气把肺底装满，第二次只补一小口，不要耸肩。',
        'Let the first inhale fill low into the ribs, then take only a small top-up inhale without shrugging.',
      ),
      whenToUse: BreathingCopy(
        '适合收到压力消息后、会议前胸口发紧、连续工作后呼吸变浅时。',
        'Use after stressful messages, before tense meetings, or when long screen time makes your breathing shallow.',
      ),
      researchBasis: BreathingCopy(
        '随机对照研究中，cyclic sighing 在数种短时呼吸练习里对改善情绪和降低呼吸频率表现最好之一。',
        'In a randomized trial, cyclic sighing was among the strongest brief breath practices for mood and respiratory-rate reduction.',
      ),
      mechanism: BreathingCopy(
        '双吸气帮助重新张开部分肺泡，长呼气负责把整体唤醒往下拉。',
        'The double inhale helps reopen underused air sacs, while the long exhale drives the downshift.',
      ),
      themeId: 'ocean',
      previewCueId: 'preview_altitude',
      recommendedMinutes: 2,
      caution: BreathingCopy(
        '如果出现头晕，立刻停下并恢复自然呼吸；它适合短练，不适合连做很多分钟。',
        'Stop immediately if you feel dizzy and return to natural breathing. This works best as a short practice.',
      ),
      tags: <BreathingCopy>[
        BreathingCopy('急性压力', 'Acute stress'),
        BreathingCopy('短练', 'Brief'),
        BreathingCopy('研究支持', 'Research-backed'),
      ],
      stages: <BreathingStagePlan>[
        BreathingStagePlan(
          kind: BreathingStageKind.inhale,
          seconds: 2,
          label: BreathingCopy('第一口吸气', 'First inhale'),
          prompt: BreathingCopy('先吸到肋骨两侧', 'Fill low into the ribs'),
          cueId: 'inhale_soft',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.inhale,
          seconds: 1,
          label: BreathingCopy('补一小口', 'Top-up inhale'),
          prompt: BreathingCopy('只补一点，不要耸肩', 'Add a small sip of air'),
          cueId: 'inhale_soft',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.exhale,
          seconds: 6,
          label: BreathingCopy('长呼气', 'Long exhale'),
          prompt: BreathingCopy('像叹气一样慢慢放掉', 'Let it out like a long sigh'),
          cueId: 'mouth_exhale',
        ),
      ],
    ),

    BreathingScenario(
      id: 'altitude_sim_3663',
      name: BreathingCopy('高海拔模拟 3-6-6-3', 'Altitude sim 3-6-6-3'),
      scene: BreathingCopy(
        '给已经能舒适鼻呼吸的人做的短时低氧耐受练习。',
        'A short hypoxic-tolerance drill for users who already handle nasal breathing comfortably.',
      ),
      description: BreathingCopy(
        '先慢慢呼出，再做短时间屏息，模拟“空气更稀薄、呼吸更克制”的节律。只建议短练，不建议长时间连续做。',
        'A slower exhale followed by a short hold simulates a thinner-air, lower-volume rhythm. Keep it brief rather than turning it into a long session.',
      ),
      bodyFocus: BreathingCopy(
        '全程保持肩颈松开、嘴唇轻闭，恢复吸气时不要猛吸，只让下一口气安静回来。',
        'Keep the neck and jaw soft, lips lightly closed, and let the recovery inhale return quietly instead of gasping.',
      ),
      whenToUse: BreathingCopy(
        '只适合白天、静坐或安全站立时短练；更适合已经完成过 BOLT 测试且知道自己余量的人。',
        'Use only as a brief daytime drill while seated or standing safely, ideally after a recent BOLT check so you know your margin.',
      ),
      researchBasis: BreathingCopy(
        '《学会呼吸》将屏息训练归类为低海拔下模拟高海拔刺激的方法，但强调要按健康状况和 BOLT 余量循序渐进。',
        'The Oxygen Advantage frames breath-hold work as a way to simulate altitude stress at low altitude, while emphasizing progression by health status and BOLT margin.',
      ),
      mechanism: BreathingCopy(
        '较长呼气加短时间屏息会提高对空气饥饿的耐受度，把注意力拉回到更安静、更节制的呼吸效率上。',
        'The longer exhale and short hold raise tolerance to air hunger and redirect attention toward quieter, more efficient breathing.',
      ),
      themeId: 'alpine',
      previewCueId: 'preview_altitude',
      recommendedMinutes: 2,
      advanced: true,
      caution: BreathingCopy(
        '如果你有头晕、胸闷、孕期、心血管不适，或最近状态不稳，请不要练。出现明显不适时立刻停止并恢复自然呼吸。',
        'Skip this if you feel dizzy, tight-chested, pregnant, cardiovascularly unwell, or generally unstable. Stop immediately and return to natural breathing if symptoms appear.',
      ),
      tags: <BreathingCopy>[
        BreathingCopy('高海拔模拟', 'Altitude sim'),
        BreathingCopy('空气饥饿', 'Air hunger'),
        BreathingCopy('进阶', 'Advanced'),
      ],
      stages: <BreathingStagePlan>[
        BreathingStagePlan(
          kind: BreathingStageKind.inhale,
          seconds: 3,
          label: BreathingCopy('鼻吸', 'Nasal inhale'),
          prompt: BreathingCopy(
            '只吸到七成满，不追求大口',
            'Inhale only to about seventy percent',
          ),
          cueId: 'nose_inhale',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.exhale,
          seconds: 6,
          label: BreathingCopy('长呼', 'Long exhale'),
          prompt: BreathingCopy('慢慢把气送出去，保持安静', 'Exhale slowly and quietly'),
          cueId: 'nose_exhale',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.hold,
          seconds: 6,
          label: BreathingCopy('呼后屏息', 'Exhale hold'),
          prompt: BreathingCopy(
            '停在第一次明确呼吸欲望前后，不要硬扛',
            'Pause around the first clear urge, not beyond',
          ),
          cueId: 'hold_soft',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.rest,
          seconds: 3,
          label: BreathingCopy('恢复', 'Recover'),
          prompt: BreathingCopy(
            '让下一口气安静回来',
            'Let the next inhale return quietly',
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
