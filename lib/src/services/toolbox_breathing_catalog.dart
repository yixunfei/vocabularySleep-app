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
    this.assetPath,
  });

  final String id;
  final BreathingCopy name;
  final List<String> remoteFileNames;
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
  final String themeId;
  final List<BreathingStagePlan> stages;
  final List<BreathingCopy> tags;
  final int recommendedMinutes;
  final String? previewCueId;
  final BreathingCopy? caution;
  final bool advanced;

  int get cycleSeconds =>
      stages.fold<int>(0, (sum, stage) => sum + stage.seconds);
}

class BreathingExperienceCatalog {
  const BreathingExperienceCatalog._();

  static const String remotePrefix = 'follow_this_breath/follow_this_breath';

  static const List<BreathingThemeSpec> themes = <BreathingThemeSpec>[
    BreathingThemeSpec(
      id: 'ocean',
      name: BreathingCopy('海潮蓝', 'Ocean glow'),
      mood: BreathingCopy(
        '像潮汐一样慢慢拉长呼气。',
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
      name: BreathingCopy('森林雾', 'Forest mist'),
      mood: BreathingCopy(
        '稳定吸呼，像走进潮湿安静的林间。',
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
      name: BreathingCopy('余烬橙', 'Ember calm'),
      mood: BreathingCopy(
        '把情绪热量一点点放出去。',
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
        '节律更克制，专注呼吸效率与恢复。',
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
      name: BreathingCopy('极光绿', 'Aurora focus'),
      mood: BreathingCopy(
        '把注意力收回到一进一出的节拍。',
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
      assetPath: 'follow_this_breath/吸气.wav',
    ),
    'exhale_soft': BreathingCueSpec(
      id: 'exhale_soft',
      name: BreathingCopy('呼气提示', 'Exhale cue'),
      remoteFileNames: <String>['呼气.wav'],
      assetPath: 'follow_this_breath/呼气.wav',
    ),
    'hold_soft': BreathingCueSpec(
      id: 'hold_soft',
      name: BreathingCopy('屏息提示', 'Hold cue'),
      remoteFileNames: <String>['屏息.wav'],
      assetPath: 'follow_this_breath/屏息.wav',
    ),
    'nose_inhale': BreathingCueSpec(
      id: 'nose_inhale',
      name: BreathingCopy('鼻吸气提示', 'Nasal inhale cue'),
      remoteFileNames: <String>['鼻子吸气.wav'],
      assetPath: 'follow_this_breath/鼻子吸气.wav',
    ),
    'nose_exhale': BreathingCueSpec(
      id: 'nose_exhale',
      name: BreathingCopy('鼻呼气提示', 'Nasal exhale cue'),
      remoteFileNames: <String>['鼻子呼气.wav'],
      assetPath: 'follow_this_breath/鼻子呼气.wav',
    ),
    'mouth_inhale': BreathingCueSpec(
      id: 'mouth_inhale',
      name: BreathingCopy('口吸气提示', 'Mouth inhale cue'),
      remoteFileNames: <String>['嘴吸气.wav'],
      assetPath: 'follow_this_breath/嘴吸气.wav',
    ),
    'mouth_exhale': BreathingCueSpec(
      id: 'mouth_exhale',
      name: BreathingCopy('口呼气提示', 'Mouth exhale cue'),
      remoteFileNames: <String>['嘴呼气.wav'],
      assetPath: 'follow_this_breath/嘴呼气.wav',
    ),
    'preview_relax': BreathingCueSpec(
      id: 'preview_relax',
      name: BreathingCopy('放松引导', 'Relax guidance'),
      remoteFileNames: <String>['放松.wav'],
      assetPath: 'follow_this_breath/放松.wav',
    ),
    'preview_intro_1': BreathingCueSpec(
      id: 'preview_intro_1',
      name: BreathingCopy('呼吸引导 1', 'Breath guide 1'),
      remoteFileNames: <String>['呼吸引导1.wav'],
      assetPath: 'follow_this_breath/呼吸引导1.wav',
    ),
    'preview_intro_2': BreathingCueSpec(
      id: 'preview_intro_2',
      name: BreathingCopy('呼吸引导 2', 'Breath guide 2'),
      remoteFileNames: <String>['呼吸引导2.wav'],
      assetPath: 'follow_this_breath/呼吸引导2.wav',
    ),
    'preview_nose_slow': BreathingCueSpec(
      id: 'preview_nose_slow',
      name: BreathingCopy('鼻吸示范', 'Nasal inhale demo'),
      remoteFileNames: <String>['开始用鼻子缓缓吸气.wav'],
      assetPath: 'follow_this_breath/开始用鼻子缓缓吸气.wav',
    ),
    'preview_parasym': BreathingCueSpec(
      id: 'preview_parasym',
      name: BreathingCopy('副交感切换引导', 'Parasympathetic guide'),
      remoteFileNames: <String>['副交感交替.wav'],
      assetPath: 'follow_this_breath/副交感交替.wav',
    ),
    'preview_altitude': BreathingCueSpec(
      id: 'preview_altitude',
      name: BreathingCopy('高海拔模拟引导', 'Altitude prep guide'),
      remoteFileNames: <String>['快速嘴吸气屏气.wav'],
      assetPath: 'follow_this_breath/快速嘴吸气屏气.wav',
    ),
  };

  static const List<BreathingScenario> scenarios = <BreathingScenario>[
    BreathingScenario(
      id: 'diaphragm_4262',
      name: BreathingCopy('标准腹式 4-2-6-2', 'Diaphragm 4-2-6-2'),
      scene: BreathingCopy(
        '建立腹式呼吸手感的默认模式',
        'Default mode for learning diaphragmatic breathing.',
      ),
      description: BreathingCopy(
        '鼻吸鼻呼，吸气时腹部鼓起，呼气时腹部回落。适合作为日常基础练习。',
        'Nasal inhale and exhale with a belly expansion on inhale and release on exhale.',
      ),
      bodyFocus: BreathingCopy(
        '肩膀保持放松，胸口不耸起，注意力放在腹部起伏。',
        'Keep the shoulders soft and let the belly, not the chest, drive the motion.',
      ),
      whenToUse: BreathingCopy(
        '适合早晨开始、久坐后、学习间隙重新找回稳定节奏。',
        'Use at the start of the day, after long sitting, or between study blocks.',
      ),
      themeId: 'ocean',
      previewCueId: 'preview_nose_slow',
      recommendedMinutes: 5,
      tags: <BreathingCopy>[
        BreathingCopy('入门', 'Starter'),
        BreathingCopy('日常', 'Daily'),
        BreathingCopy('腹式', 'Diaphragm'),
      ],
      stages: <BreathingStagePlan>[
        BreathingStagePlan(
          kind: BreathingStageKind.inhale,
          seconds: 4,
          label: BreathingCopy('鼻吸', 'Nasal inhale'),
          prompt: BreathingCopy('腹部向外展开', 'Expand the belly'),
          cueId: 'nose_inhale',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.hold,
          seconds: 2,
          label: BreathingCopy('停留', 'Hold'),
          prompt: BreathingCopy('轻停，不要用力憋住', 'Pause lightly without straining'),
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
          label: BreathingCopy('松开', 'Rest'),
          prompt: BreathingCopy('感受身体回落', 'Let the body settle'),
        ),
      ],
    ),
    BreathingScenario(
      id: 'box_4444',
      name: BreathingCopy('方块稳定 4-4-4-4', 'Box 4-4-4-4'),
      scene: BreathingCopy(
        '开会、演讲、考试前的稳定模式',
        'Steady your rhythm before meetings, talks, or tests.',
      ),
      description: BreathingCopy(
        '四段等长，像在心里画一个正方形，把注意力从压力源收回到内部节拍。',
        'Four equal sides create a square rhythm that pulls attention back from pressure.',
      ),
      bodyFocus: BreathingCopy(
        '每一段都保持同样长度，遇到紧张时优先守住节拍而不是追求深度。',
        'Keep each side the same length and prioritize consistency over depth.',
      ),
      whenToUse: BreathingCopy(
        '适合高压任务前的 2 到 5 分钟快速校准。',
        'Best for a 2-5 minute reset before demanding tasks.',
      ),
      themeId: 'aurora',
      previewCueId: 'preview_intro_1',
      recommendedMinutes: 3,
      tags: <BreathingCopy>[
        BreathingCopy('稳定', 'Steady'),
        BreathingCopy('专注', 'Focus'),
        BreathingCopy('压力前', 'Pre-task'),
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
          prompt: BreathingCopy('保持均匀', 'Stay steady'),
          cueId: 'hold_soft',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.exhale,
          seconds: 4,
          label: BreathingCopy('呼气', 'Exhale'),
          prompt: BreathingCopy('顺着节拍放掉', 'Release on the same count'),
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
      name: BreathingCopy('共振呼吸 5-5', 'Coherent 5-5'),
      scene: BreathingCopy(
        '任务切换与情绪起伏后的稳态呼吸',
        'Balanced breathing for transitions and regulation.',
      ),
      description: BreathingCopy(
        '均匀吸呼，更适合做 5 到 10 分钟的稳定练习，让身体逐渐进入低波动状态。',
        'Equal inhale and exhale are ideal for longer steady-state regulation sessions.',
      ),
      bodyFocus: BreathingCopy(
        '让吸气和呼气都保持圆润，不需要额外屏息。',
        'Keep both directions smooth and rounded without extra breath holding.',
      ),
      whenToUse: BreathingCopy(
        '适合番茄钟之间、情绪恢复期、轻度焦虑后的重整。',
        'Use between focus blocks or after mild emotional activation.',
      ),
      themeId: 'forest',
      previewCueId: 'preview_intro_1',
      recommendedMinutes: 8,
      tags: <BreathingCopy>[
        BreathingCopy('稳态', 'Steady state'),
        BreathingCopy('恢复', 'Recovery'),
        BreathingCopy('切换', 'Transition'),
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
        '下班、运动后、长时间用脑后的降档模式',
        'A downshift rhythm for after work, exercise, or heavy screen time.',
      ),
      description: BreathingCopy(
        '延长呼气，把身体从高唤醒慢慢带回恢复状态。',
        'A longer exhale helps the body come down from a high-alert state.',
      ),
      bodyFocus: BreathingCopy(
        '呼气时下颌放松，肩颈跟着一起落下。',
        'Relax the jaw and let the shoulders drop with the exhale.',
      ),
      whenToUse: BreathingCopy(
        '适合连续工作 45 分钟后、通勤结束后、需要慢下来时。',
        'Use after long work blocks, after commuting, or whenever you need to slow down.',
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
          prompt: BreathingCopy('慢慢松掉肩颈', 'Release the neck and shoulders'),
          cueId: 'exhale_soft',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.rest,
          seconds: 2,
          label: BreathingCopy('停顿', 'Rest'),
          prompt: BreathingCopy('让节奏沉下来', 'Let the pace settle'),
        ),
      ],
    ),
    BreathingScenario(
      id: 'calm_36',
      name: BreathingCopy('平息长呼 3-6', 'Calm 3-6'),
      scene: BreathingCopy(
        '焦躁、争执后、心跳偏快时先降强度',
        'A simple de-escalation rhythm for agitation or a racing mind.',
      ),
      description: BreathingCopy(
        '短吸长呼，不额外屏息，在紧张时更容易执行。',
        'A short inhale and long exhale are easier to use when you already feel activated.',
      ),
      bodyFocus: BreathingCopy(
        '先把呼气做完整，再自然开始下一次吸气。',
        'Finish the exhale fully before letting the next inhale arrive.',
      ),
      whenToUse: BreathingCopy(
        '适合临时平息情绪、开会前心跳过快、需要快速降噪时。',
        'Use when emotions are elevated and you need a quick downshift.',
      ),
      themeId: 'ember',
      previewCueId: 'preview_intro_2',
      recommendedMinutes: 3,
      tags: <BreathingCopy>[
        BreathingCopy('平息', 'Calm'),
        BreathingCopy('应急', 'Rapid reset'),
        BreathingCopy('低门槛', 'Accessible'),
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
          prompt: BreathingCopy('把气吐干净', 'Empty the breath fully'),
          cueId: 'exhale_soft',
        ),
      ],
    ),
    BreathingScenario(
      id: 'sleep_478',
      name: BreathingCopy('入睡 4-7-8', 'Sleep 4-7-8'),
      scene: BreathingCopy(
        '睡前收尾、夜间醒来后的再放松',
        'A classic bedtime pattern for winding down at night.',
      ),
      description: BreathingCopy(
        '经典 4-7-8 节律，适合关灯后放慢节奏。若长屏息不适，请切换到放松延呼模式。',
        'Classic 4-7-8 pacing for bedtime. Switch to a gentler mode if the hold feels too strong.',
      ),
      bodyFocus: BreathingCopy(
        '吸气不要过深，重点是安静和延长呼气。',
        'Do not overfill the inhale. Quietness and a patient exhale matter more.',
      ),
      whenToUse: BreathingCopy(
        '适合入睡前 5 分钟，或夜里醒来时重新安定下来。',
        'Use for five quiet minutes before sleep or when waking in the night.',
      ),
      themeId: 'ember',
      previewCueId: 'preview_intro_2',
      recommendedMinutes: 5,
      caution: BreathingCopy(
        '如果 7 秒屏息让你不舒服，请改用“放松延呼 4-2-6-2”。',
        'If the 7-second hold feels uncomfortable, switch to Unwind 4-2-6-2.',
      ),
      tags: <BreathingCopy>[
        BreathingCopy('睡前', 'Bedtime'),
        BreathingCopy('经典', 'Classic'),
        BreathingCopy('慢节律', 'Slow rhythm'),
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
          prompt: BreathingCopy('只做到舒适范围', 'Stay within comfort'),
          cueId: 'hold_soft',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.exhale,
          seconds: 8,
          label: BreathingCopy('口呼', 'Mouth exhale'),
          prompt: BreathingCopy('慢长呼出，像在叹气', 'Exhale long like a soft sigh'),
          cueId: 'mouth_exhale',
        ),
      ],
    ),
    BreathingScenario(
      id: 'parasym_4462',
      name: BreathingCopy('副交感切换 4-4-6-2', 'Parasym reset 4-4-6-2'),
      scene: BreathingCopy(
        '从任务模式切换到恢复模式',
        'Shift from task mode into recovery mode.',
      ),
      description: BreathingCopy(
        '较长呼气和短恢复段帮助身体从紧绷、追赶、冲刺状态切回稳定恢复节奏。',
        'A long exhale plus a short rest help shift the body away from urgency and back to recovery.',
      ),
      bodyFocus: BreathingCopy(
        '呼气结束后停两拍，感受心率和肩颈一起慢下来。',
        'After the exhale, notice the quiet two-beat rest and the body slowing down.',
      ),
      whenToUse: BreathingCopy(
        '适合晚间通勤结束、冥想前、洗澡后或准备睡前过渡。',
        'Use after commuting, before meditation, or as an evening transition.',
      ),
      themeId: 'ocean',
      previewCueId: 'preview_parasym',
      recommendedMinutes: 8,
      tags: <BreathingCopy>[
        BreathingCopy('副交感', 'Parasym'),
        BreathingCopy('恢复', 'Recovery'),
        BreathingCopy('晚间', 'Evening'),
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
          prompt: BreathingCopy('感受松弛落地', 'Feel the settling'),
        ),
      ],
    ),
    BreathingScenario(
      id: 'altitude_2442',
      name: BreathingCopy('高海拔模拟 2-4-4-2', 'Altitude prep 2-4-4-2'),
      scene: BreathingCopy(
        '轻量进阶的气息耐受演练',
        'A light advanced drill for breath tolerance and mountain prep.',
      ),
      description: BreathingCopy(
        '更短的吸气与短暂屏息，模拟空气稀薄时更克制的节奏感。只建议在坐姿、状态稳定时练习。',
        'Shorter inhales with a brief hold simulate a more constrained mountain-style rhythm. Practice only while seated and stable.',
      ),
      bodyFocus: BreathingCopy(
        '不要追求极限。出现头晕、胸闷、发麻时立刻停止。',
        'Do not chase intensity. Stop immediately if you feel dizzy, numb, or uncomfortable.',
      ),
      whenToUse: BreathingCopy(
        '适合登山前的轻量节律演练，或想提升 CO2 耐受时的短时训练。',
        'Use as a short tolerance drill before mountain activity or as a mild CO2 tolerance practice.',
      ),
      themeId: 'alpine',
      previewCueId: 'preview_altitude',
      recommendedMinutes: 2,
      advanced: true,
      caution: BreathingCopy(
        '孕期、心肺疾病、高血压、近期手术恢复期不要使用本模式。',
        'Skip this mode during pregnancy, with cardiovascular or pulmonary conditions, or during surgical recovery.',
      ),
      tags: <BreathingCopy>[
        BreathingCopy('进阶', 'Advanced'),
        BreathingCopy('高海拔', 'Altitude'),
        BreathingCopy('耐受', 'Tolerance'),
      ],
      stages: <BreathingStagePlan>[
        BreathingStagePlan(
          kind: BreathingStageKind.inhale,
          seconds: 2,
          label: BreathingCopy('口吸', 'Mouth inhale'),
          prompt: BreathingCopy('快速吸入但不过猛', 'Quick but controlled inhale'),
          cueId: 'mouth_inhale',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.hold,
          seconds: 4,
          label: BreathingCopy('屏息', 'Hold'),
          prompt: BreathingCopy('保持放松，不要顶住喉咙', 'Stay relaxed in the throat'),
          cueId: 'hold_soft',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.exhale,
          seconds: 4,
          label: BreathingCopy('口呼', 'Mouth exhale'),
          prompt: BreathingCopy('均匀放掉，不要急冲', 'Release evenly, not explosively'),
          cueId: 'mouth_exhale',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.rest,
          seconds: 2,
          label: BreathingCopy('恢复', 'Rest'),
          prompt: BreathingCopy(
            '确认身体依然舒适',
            'Check that the body still feels okay',
          ),
        ),
      ],
    ),
    BreathingScenario(
      id: 'energize_3131',
      name: BreathingCopy('提神 3-1-3-1', 'Refresh 3-1-3-1'),
      scene: BreathingCopy(
        '午后走神或开始新任务前的短时提神',
        'A quick rhythm for low energy before starting the next task.',
      ),
      description: BreathingCopy(
        '较短的循环让注意力重新黏回到节拍上，适合 2 到 3 分钟短练。',
        'Short cycles help attention latch back onto rhythm without becoming overstimulating.',
      ),
      bodyFocus: BreathingCopy(
        '保持挺拔坐姿，让吸呼轻快但不急促。',
        'Sit upright and keep the rhythm crisp but not frantic.',
      ),
      whenToUse: BreathingCopy(
        '适合番茄钟开始前、午后犯困、准备切入高认知任务时。',
        'Use at the start of a focus block or during an afternoon slump.',
      ),
      themeId: 'aurora',
      previewCueId: 'preview_intro_1',
      recommendedMinutes: 3,
      tags: <BreathingCopy>[
        BreathingCopy('提神', 'Refresh'),
        BreathingCopy('短练', 'Short'),
        BreathingCopy('工作前', 'Pre-focus'),
      ],
      stages: <BreathingStagePlan>[
        BreathingStagePlan(
          kind: BreathingStageKind.inhale,
          seconds: 3,
          label: BreathingCopy('吸气', 'Inhale'),
          prompt: BreathingCopy('快速找回节拍', 'Catch the rhythm'),
          cueId: 'inhale_soft',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.hold,
          seconds: 1,
          label: BreathingCopy('停一拍', 'Hold one beat'),
          prompt: BreathingCopy('只轻停一下', 'Brief pause only'),
          cueId: 'hold_soft',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.exhale,
          seconds: 3,
          label: BreathingCopy('呼气', 'Exhale'),
          prompt: BreathingCopy('顺着动作放出', 'Release with control'),
          cueId: 'exhale_soft',
        ),
        BreathingStagePlan(
          kind: BreathingStageKind.rest,
          seconds: 1,
          label: BreathingCopy('停一拍', 'Rest one beat'),
          prompt: BreathingCopy('准备下一轮', 'Prepare the next cycle'),
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
