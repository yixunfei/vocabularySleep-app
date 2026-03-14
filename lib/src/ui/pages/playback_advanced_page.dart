import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../models/play_config.dart';
import '../../state/app_state.dart';
import '../ui_copy.dart';
import '../widgets/section_header.dart';

class PlaybackAdvancedPage extends StatelessWidget {
  const PlaybackAdvancedPage({super.key});

  static const List<String> _nonCoreKeys = <String>[
    'etymology',
    'roots',
    'affixes',
    'variations',
    'memory',
    'story',
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final i18n = AppI18n(state.uiLanguage);
    final config = state.config;
    final repeats = config.repeats;

    final delay = config.delayBetweenUnitsMs.clamp(0, 2000).toInt();
    final overallRepeat = config.overallRepeat.clamp(1, 5).toInt();
    final wordRepeat = (repeats['word'] ?? 1).clamp(0, 5).toInt();
    final meaningRepeat = (repeats['meaning'] ?? 1).clamp(0, 5).toInt();
    final exampleRepeat = (repeats['example'] ?? 1).clamp(0, 5).toInt();
    final spellingRepeat = (repeats['spelling'] ?? 0).clamp(0, 5).toInt();
    final nonCoreRepeats = <String, int>{
      for (final key in _nonCoreKeys)
        key: (repeats[key] ?? 0).clamp(0, 5).toInt(),
    };

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
                  _RepeatSlider(
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SectionHeader(
                    title: pickUiText(i18n, zh: '核心字段重复', en: 'Core repeat'),
                    subtitle: pickUiText(
                      i18n,
                      zh: '控制单词、释义、例句的重复次数。',
                      en: 'Set repeat times for word, meaning, and examples.',
                    ),
                  ),
                  const SizedBox(height: 14),
                  _RepeatSlider(
                    label: i18n.t('fieldWord'),
                    value: wordRepeat,
                    onChanged: (value) =>
                        _updateRepeat(state, config, 'word', value),
                  ),
                  const SizedBox(height: 6),
                  _RepeatSlider(
                    label: i18n.t('fieldMeaning'),
                    value: meaningRepeat,
                    onChanged: (value) =>
                        _updateRepeat(state, config, 'meaning', value),
                  ),
                  const SizedBox(height: 6),
                  _RepeatSlider(
                    label: i18n.t('fieldExamples'),
                    value: exampleRepeat,
                    onChanged: (value) =>
                        _updateRepeat(state, config, 'example', value),
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
                      zh: '非核心内容重复',
                      en: 'Non-core repeat',
                    ),
                    subtitle: pickUiText(
                      i18n,
                      zh: '恢复词源、词根、词缀等内容的播放控制。',
                      en: 'Control repeat times for etymology and other non-core fields.',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      FilledButton.tonal(
                        onPressed: () => _applyNonCoreRepeat(state, config, 0),
                        child: Text(
                          pickUiText(i18n, zh: '全部设为 0', en: 'Set all to 0'),
                        ),
                      ),
                      FilledButton.tonal(
                        onPressed: () => _applyNonCoreRepeat(state, config, 1),
                        child: Text(
                          pickUiText(i18n, zh: '全部设为 1', en: 'Set all to 1'),
                        ),
                      ),
                      FilledButton.tonal(
                        onPressed: () => _applyNonCoreRepeat(state, config, 2),
                        child: Text(
                          pickUiText(i18n, zh: '全部设为 2', en: 'Set all to 2'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final key in _nonCoreKeys) ...<Widget>[
                    _RepeatSlider(
                      label: _nonCoreLabel(i18n, key),
                      value: nonCoreRepeats[key] ?? 0,
                      onChanged: (value) =>
                          _updateRepeat(state, config, key, value),
                    ),
                    if (key != _nonCoreKeys.last) const SizedBox(height: 6),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _nonCoreLabel(AppI18n i18n, String key) {
    return switch (key) {
      'etymology' => i18n.t('fieldEtymology'),
      'roots' => i18n.t('fieldRoots'),
      'affixes' => i18n.t('fieldAffixes'),
      'variations' => i18n.t('fieldVariations'),
      'memory' => i18n.t('fieldMemory'),
      'story' => i18n.t('fieldStory'),
      _ => key,
    };
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

  void _applyNonCoreRepeat(AppState state, PlayConfig config, int value) {
    final nextRepeats = Map<String, int>.from(config.repeats);
    final normalized = value.clamp(0, 5).toInt();
    for (final key in _nonCoreKeys) {
      nextRepeats[key] = normalized;
    }
    state.updateConfig(config.copyWith(repeats: nextRepeats));
  }

  void _applyPreset(AppState state, PlayConfig config, _Preset preset) {
    final nextRepeats = Map<String, int>.from(config.repeats);
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
}

enum _Preset { sleep, focus, review }

class _RepeatSlider extends StatelessWidget {
  const _RepeatSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('$label: $value'),
        Slider(
          min: 0,
          max: 5,
          divisions: 5,
          value: value.toDouble(),
          onChanged: (next) => onChanged(next.round()),
        ),
      ],
    );
  }
}
