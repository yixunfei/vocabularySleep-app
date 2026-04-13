import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../models/play_config.dart';
import '../../models/word_field.dart';
import '../../state/app_state.dart';
import '../ui_copy.dart';
import '../widgets/section_header.dart';
import '../widgets/playback_repeat_group_card.dart';

class PlaybackAdvancedPage extends StatelessWidget {
  const PlaybackAdvancedPage({super.key});

  static const List<String> _usageKeys = <String>[
    'collocations',
    'phrases',
    'usage',
    'confusions',
    'synonyms',
    'antonyms',
  ];

  static const List<String> _linguisticsKeys = <String>[
    'etymology',
    'roots',
    'affixes',
    'morphology',
    'variations',
    'related',
    'derived',
    'similar_words',
    'frequency_rank',
  ];

  static const List<String> _memoryKeys = <String>[
    'memory',
    'culture',
    'story',
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final i18n = AppI18n(state.uiLanguage);
    final config = state.config;
    final repeats = config.repeats;
    final discoveredFieldKeys = <String>{
      for (final word in state.words)
        for (final field in word.fields)
          if (field.asList().isNotEmpty) normalizeFieldKey(field.key),
    };
    final handledKeys = <String>{
      'word',
      'meaning',
      'meanings_zh',
      'pronunciations',
      'parts_of_speech',
      'examples',
      'example',
      'tags',
      'media',
      ..._usageKeys,
      ..._linguisticsKeys,
      ..._memoryKeys,
    };
    final dynamicKeys =
        discoveredFieldKeys
            .where((key) => key.isNotEmpty && !handledKeys.contains(key))
            .toList(growable: false)
          ..sort();

    final delay = config.delayBetweenUnitsMs.clamp(0, 2000).toInt();
    final overallRepeat = config.overallRepeat.clamp(1, 5).toInt();
    final wordRepeat = (repeats['word'] ?? 1).clamp(0, 5).toInt();
    final meaningRepeat = (repeats['meaning'] ?? 1).clamp(0, 5).toInt();
    final meaningsZhRepeat = (repeats['meanings_zh'] ?? 0).clamp(0, 5).toInt();
    final exampleRepeat = (repeats['example'] ?? 1).clamp(0, 5).toInt();
    final spellingRepeat = (repeats['spelling'] ?? 0).clamp(0, 5).toInt();
    final repeatGroups = <PlaybackRepeatFieldGroup>[
      PlaybackRepeatFieldGroup(
        title: pickUiText(i18n, zh: '核心字段重复', en: 'Core repeat'),
        subtitle: pickUiText(
          i18n,
          zh: '控制单词、释义、中文义项、发音、词性与例句的重复次数。',
          en: 'Set repeat times for word, meaning, Chinese meanings, pronunciations, parts of speech, and examples.',
        ),
        keys: const <String>[
          'word',
          'meaning',
          'meanings_zh',
          'pronunciations',
          'parts_of_speech',
          'example',
        ],
      ),
      PlaybackRepeatFieldGroup(
        title: pickUiText(i18n, zh: '用法字段重复', en: 'Usage field repeat'),
        subtitle: pickUiText(
          i18n,
          zh: '控制搭配、短语、用法说明、近反义与易混辨析的播放次数。',
          en: 'Control repeats for collocations, phrases, usage notes, synonyms, antonyms, and confusions.',
        ),
        keys: _usageKeys,
        quickValues: const <int>[0, 1, 2],
      ),
      PlaybackRepeatFieldGroup(
        title: pickUiText(i18n, zh: '语言学字段重复', en: 'Linguistics field repeat'),
        subtitle: pickUiText(
          i18n,
          zh: '控制词源、词根、词缀、变形、相关词和词频等结构化补充信息的播放次数。',
          en: 'Control repeats for etymology, roots, affixes, variations, related words, and frequency information.',
        ),
        keys: _linguisticsKeys,
        quickValues: const <int>[0, 1],
      ),
      PlaybackRepeatFieldGroup(
        title: pickUiText(i18n, zh: '记忆字段重复', en: 'Memory field repeat'),
        subtitle: pickUiText(
          i18n,
          zh: '控制记忆法、文化背景和故事型补充内容的播放次数。',
          en: 'Control repeats for memory aids, culture notes, and story-style context.',
        ),
        keys: _memoryKeys,
        quickValues: const <int>[0, 1],
      ),
      if (dynamicKeys.isNotEmpty)
        PlaybackRepeatFieldGroup(
          title: pickUiText(i18n, zh: '动态字段重复', en: 'Dynamic field repeat'),
          subtitle: pickUiText(
            i18n,
            zh: '这些字段来自当前已加载词本的真实扩展内容，可按需单独设置播放次数。',
            en: 'These fields come from the currently loaded wordbook and can be configured individually.',
          ),
          keys: dynamicKeys,
          quickValues: const <int>[0, 1],
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(pickUiText(i18n, zh: '播放高级设置', en: 'Playback advanced')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SectionHeader(
                    title: pickUiText(i18n, zh: '场景策略', en: 'Usage presets'),
                    subtitle: pickUiText(
                      i18n,
                      zh: '按场景快速应用推荐参数。',
                      en: 'Apply a recommended parameter set by scenario.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      FilledButton.tonal(
                        onPressed: () =>
                            _applyPreset(state, config, _Preset.sleep),
                        child: Text(
                          pickUiText(i18n, zh: '助眠推荐', en: 'Sleep preset'),
                        ),
                      ),
                      FilledButton.tonal(
                        onPressed: () =>
                            _applyPreset(state, config, _Preset.focus),
                        child: Text(
                          pickUiText(i18n, zh: '专注推荐', en: 'Focus preset'),
                        ),
                      ),
                      FilledButton.tonal(
                        onPressed: () =>
                            _applyPreset(state, config, _Preset.review),
                        child: Text(
                          pickUiText(i18n, zh: '复习推荐', en: 'Review preset'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SectionHeader(
                    title: pickUiText(
                      i18n,
                      zh: '拼读与翻页',
                      en: 'Spelling and transitions',
                    ),
                    subtitle: pickUiText(
                      i18n,
                      zh: '控制拼读播放方式，以及单词卡的左右切换动效。',
                      en: 'Control spelling playback and left-right word card transitions.',
                    ),
                  ),
                  const SizedBox(height: 14),
                  RepeatSlider(
                    label: pickUiText(i18n, zh: '拼读重复', en: 'Spelling repeat'),
                    value: spellingRepeat,
                    onChanged: (value) =>
                        _updateRepeat(state, config, 'spelling', value),
                  ),
                  const SizedBox(height: 12),
                  Text(pickUiText(i18n, zh: '拼读模式', en: 'Spelling mode')),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: SpellingPlaybackMode.values
                        .map(
                          (mode) => ChoiceChip(
                            label: Text(_spellingModeLabel(i18n, mode)),
                            selected: config.spellingPlaybackMode == mode,
                            onSelected: (_) {
                              state.updateConfig(
                                config.copyWith(spellingPlaybackMode: mode),
                              );
                            },
                          ),
                        )
                        .toList(growable: false),
                  ),
                  const SizedBox(height: 14),
                  Text(pickUiText(i18n, zh: '翻页效果', en: 'Page transition')),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: WordPageTransitionStyle.values
                        .map(
                          (style) => ChoiceChip(
                            label: Text(_transitionStyleLabel(i18n, style)),
                            selected: config.wordPageTransitionStyle == style,
                            onSelected: (_) {
                              state.updateConfig(
                                config.copyWith(wordPageTransitionStyle: style),
                              );
                            },
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SectionHeader(
                    title: pickUiText(
                      i18n,
                      zh: '播放策略',
                      en: 'Playback strategy',
                    ),
                    subtitle: pickUiText(
                      i18n,
                      zh: '控制顺序、文本可见性和节奏。',
                      en: 'Control order, text visibility, and pacing.',
                    ),
                  ),
                  const SizedBox(height: 14),
                  SegmentedButton<PlayOrder>(
                    segments: PlayOrder.values
                        .map(
                          (item) => ButtonSegment<PlayOrder>(
                            value: item,
                            label: Text(playOrderLabel(i18n, item)),
                          ),
                        )
                        .toList(growable: false),
                    selected: <PlayOrder>{config.order},
                    onSelectionChanged: (selection) {
                      state.updateConfig(
                        config.copyWith(order: selection.first),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(i18n.t('showText')),
                    subtitle: Text(
                      pickUiText(
                        i18n,
                        zh: '关闭后将减少可见文字，保留听词流程。',
                        en: 'Hide on-screen text for a lower-visual listening flow.',
                      ),
                    ),
                    value: config.showText,
                    onChanged: (value) {
                      state.updateConfig(config.copyWith(showText: value));
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pickUiText(
                      i18n,
                      zh: '片段间隔：$delay ms',
                      en: 'Delay between units: $delay ms',
                    ),
                  ),
                  Slider(
                    min: 0,
                    max: 2000,
                    divisions: 20,
                    value: delay.toDouble(),
                    onChanged: (value) {
                      state.updateConfig(
                        config.copyWith(delayBetweenUnitsMs: value.round()),
                      );
                    },
                  ),
                  Text(
                    pickUiText(
                      i18n,
                      zh: '总循环：$overallRepeat',
                      en: 'Overall loop: $overallRepeat',
                    ),
                  ),
                  Slider(
                    min: 1,
                    max: 5,
                    divisions: 4,
                    value: overallRepeat.toDouble(),
                    onChanged: (value) {
                      state.updateConfig(
                        config.copyWith(overallRepeat: value.round()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (final group in repeatGroups) ...<Widget>[
            PlaybackRepeatGroupCard(
              i18n: i18n,
              group: group,
              repeats: _repeatMapForKeys(
                group.keys,
                config,
                wordRepeat: wordRepeat,
                meaningRepeat: meaningRepeat,
                meaningsZhRepeat: meaningsZhRepeat,
                exampleRepeat: exampleRepeat,
              ),
              labelBuilder: (key) => _fieldLabel(i18n, key),
              onChanged: (key, value) =>
                  _updateRepeat(state, config, key, value),
              onApplyBatch: (value) =>
                  _applyBatchRepeat(state, config, group.keys, value),
            ),
            if (group != repeatGroups.last) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  String _fieldLabel(AppI18n i18n, String key) {
    return switch (key) {
      'word' => i18n.t('fieldWord'),
      'meaning' => i18n.t('fieldMeaning'),
      'meanings_zh' => pickUiText(i18n, zh: '中文义项', en: 'Chinese meanings'),
      'pronunciations' => pickUiText(i18n, zh: '发音', en: 'Pronunciations'),
      'parts_of_speech' => pickUiText(i18n, zh: '词性', en: 'Parts of speech'),
      'example' => i18n.t('fieldExamples'),
      'collocations' => pickUiText(i18n, zh: '搭配', en: 'Collocations'),
      'phrases' => pickUiText(i18n, zh: '短语', en: 'Phrases'),
      'usage' => pickUiText(i18n, zh: '用法说明', en: 'Usage'),
      'confusions' => pickUiText(i18n, zh: '易混辨析', en: 'Confusions'),
      'synonyms' => pickUiText(i18n, zh: '近义词', en: 'Synonyms'),
      'antonyms' => pickUiText(i18n, zh: '反义词', en: 'Antonyms'),
      'etymology' => i18n.t('fieldEtymology'),
      'roots' => i18n.t('fieldRoots'),
      'affixes' => i18n.t('fieldAffixes'),
      'morphology' => pickUiText(i18n, zh: '形态信息', en: 'Morphology'),
      'variations' => i18n.t('fieldVariations'),
      'related' => pickUiText(i18n, zh: '相关词', en: 'Related words'),
      'derived' => pickUiText(i18n, zh: '派生词', en: 'Derived words'),
      'similar_words' => pickUiText(i18n, zh: '相近词', en: 'Similar words'),
      'frequency_rank' => pickUiText(i18n, zh: '词频排名', en: 'Frequency rank'),
      'memory' => i18n.t('fieldMemory'),
      'culture' => pickUiText(i18n, zh: '文化背景', en: 'Culture'),
      'story' => i18n.t('fieldStory'),
      _ => legacyFieldLabels[normalizeFieldKey(key)] ?? key,
    };
  }

  Map<String, int> _repeatMapForKeys(
    List<String> keys,
    PlayConfig config, {
    required int wordRepeat,
    required int meaningRepeat,
    required int meaningsZhRepeat,
    required int exampleRepeat,
  }) {
    final repeats = <String, int>{};
    for (final key in keys) {
      repeats[key] = switch (key) {
        'word' => wordRepeat,
        'meaning' => meaningRepeat,
        'meanings_zh' => meaningsZhRepeat,
        'example' => exampleRepeat,
        _ => (config.repeats[key] ?? 0).clamp(0, 5).toInt(),
      };
    }
    return repeats;
  }

  String _spellingModeLabel(AppI18n i18n, SpellingPlaybackMode mode) {
    return switch (mode) {
      SpellingPlaybackMode.letters => pickUiText(
        i18n,
        zh: '逐字母',
        en: 'Letters',
      ),
      SpellingPlaybackMode.pairs => pickUiText(i18n, zh: '字母对', en: 'Pairs'),
    };
  }

  String _transitionStyleLabel(AppI18n i18n, WordPageTransitionStyle style) {
    return switch (style) {
      WordPageTransitionStyle.defaultStyle => pickUiText(
        i18n,
        zh: '默认',
        en: 'Default',
      ),
      WordPageTransitionStyle.smooth => pickUiText(
        i18n,
        zh: '平滑',
        en: 'Smooth',
      ),
      WordPageTransitionStyle.fade => pickUiText(i18n, zh: '淡入', en: 'Fade'),
      WordPageTransitionStyle.pageFlip => pickUiText(
        i18n,
        zh: '仿真翻页',
        en: 'Page flip',
      ),
    };
  }

  void _updateRepeat(AppState state, PlayConfig config, String key, int value) {
    final nextRepeats = Map<String, int>.from(config.repeats);
    nextRepeats[key] = value.clamp(0, 5).toInt();
    state.updateConfig(config.copyWith(repeats: nextRepeats));
  }

  void _applyBatchRepeat(
    AppState state,
    PlayConfig config,
    List<String> keys,
    int value,
  ) {
    final nextRepeats = Map<String, int>.from(config.repeats);
    final normalized = value.clamp(0, 5).toInt();
    for (final key in keys) {
      nextRepeats[key] = normalized;
    }
    state.updateConfig(config.copyWith(repeats: nextRepeats));
  }

  void _applyPreset(AppState state, PlayConfig config, _Preset preset) {
    final nextRepeats = _resetPresetRepeats(config);
    final nextConfig = switch (preset) {
      _Preset.sleep => config.copyWith(
        order: PlayOrder.sequential,
        showText: false,
        delayBetweenUnitsMs: 900,
        overallRepeat: 2,
        repeats: nextRepeats
          ..['word'] = 1
          ..['meaning'] = 1
          ..['example'] = 0,
      ),
      _Preset.focus => config.copyWith(
        order: PlayOrder.sequential,
        showText: true,
        delayBetweenUnitsMs: 420,
        overallRepeat: 1,
        repeats: nextRepeats
          ..['word'] = 1
          ..['meaning'] = 1
          ..['example'] = 1,
      ),
      _Preset.review => config.copyWith(
        order: PlayOrder.random,
        showText: true,
        delayBetweenUnitsMs: 260,
        overallRepeat: 1,
        repeats: nextRepeats
          ..['word'] = 1
          ..['meaning'] = 2
          ..['example'] = 1,
      ),
    };
    state.updateConfig(nextConfig);
  }

  Map<String, int> _resetPresetRepeats(PlayConfig config) {
    final nextRepeats = Map<String, int>.from(config.repeats);
    for (final entry in PlayConfig.defaults.repeats.entries) {
      nextRepeats[entry.key] = entry.value;
    }
    return nextRepeats;
  }
}

enum _Preset { sleep, focus, review }
