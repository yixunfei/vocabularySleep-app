import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/app_i18n.dart';
import '../../models/play_config.dart';
import '../../models/word_field.dart';
import '../../state/app_state.dart';
import '../../state/app_state_provider.dart';
import '../ui_copy.dart';
import '../widgets/section_header.dart';
import '../widgets/playback_repeat_group_card.dart';

class PlaybackAdvancedPage extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
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
        title: i18n.t(
          'inline.ui.pages.playback_advanced_page.core_repeat_9d9655',
        ),
        subtitle: i18n.t(
          'inline.ui.pages.playback_advanced_page.set_repeat_times_for_word_meaning_chinese_meanings_pronu_56a1aa',
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
        title: i18n.t(
          'inline.ui.pages.playback_advanced_page.usage_field_repeat_7be69f',
        ),
        subtitle: i18n.t(
          'inline.ui.pages.playback_advanced_page.control_repeats_for_collocations_phrases_usage_notes_syn_76e763',
        ),
        keys: _usageKeys,
        quickValues: const <int>[0, 1, 2],
      ),
      PlaybackRepeatFieldGroup(
        title: i18n.t(
          'inline.ui.pages.playback_advanced_page.linguistics_field_repeat_12550e',
        ),
        subtitle: i18n.t(
          'inline.ui.pages.playback_advanced_page.control_repeats_for_etymology_roots_affixes_variations_r_04bcf5',
        ),
        keys: _linguisticsKeys,
        quickValues: const <int>[0, 1],
      ),
      PlaybackRepeatFieldGroup(
        title: i18n.t(
          'inline.ui.pages.playback_advanced_page.memory_field_repeat_d6a1e1',
        ),
        subtitle: i18n.t(
          'inline.ui.pages.playback_advanced_page.control_repeats_for_memory_aids_culture_notes_and_story_232f81',
        ),
        keys: _memoryKeys,
        quickValues: const <int>[0, 1],
      ),
      if (dynamicKeys.isNotEmpty)
        PlaybackRepeatFieldGroup(
          title: i18n.t(
            'inline.ui.pages.playback_advanced_page.dynamic_field_repeat_a41df7',
          ),
          subtitle: i18n.t(
            'inline.ui.pages.playback_advanced_page.these_fields_come_from_the_currently_loaded_wordbook_and_5d5f61',
          ),
          keys: dynamicKeys,
          quickValues: const <int>[0, 1],
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          i18n.t(
            'inline.ui.pages.playback_advanced_page.playback_advanced_9d4699',
          ),
        ),
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
                    title: i18n.t(
                      'inline.ui.pages.playback_advanced_page.usage_presets_8b73b8',
                    ),
                    subtitle: i18n.t(
                      'inline.ui.pages.playback_advanced_page.apply_a_recommended_parameter_set_by_scenario_5bf195',
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
                          i18n.t(
                            'inline.ui.pages.playback_advanced_page.sleep_preset_d6fcd7',
                          ),
                        ),
                      ),
                      FilledButton.tonal(
                        onPressed: () =>
                            _applyPreset(state, config, _Preset.focus),
                        child: Text(
                          i18n.t(
                            'inline.ui.pages.playback_advanced_page.focus_preset_57619a',
                          ),
                        ),
                      ),
                      FilledButton.tonal(
                        onPressed: () =>
                            _applyPreset(state, config, _Preset.review),
                        child: Text(
                          i18n.t(
                            'inline.ui.pages.playback_advanced_page.review_preset_6c70e4',
                          ),
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
                    title: i18n.t(
                      'inline.ui.pages.playback_advanced_page.spelling_and_transitions_c621df',
                    ),
                    subtitle: i18n.t(
                      'inline.ui.pages.playback_advanced_page.control_spelling_playback_and_left_right_word_card_trans_47a527',
                    ),
                  ),
                  const SizedBox(height: 14),
                  RepeatSlider(
                    label: i18n.t(
                      'inline.ui.pages.playback_advanced_page.spelling_repeat_8afb58',
                    ),
                    value: spellingRepeat,
                    onChanged: (value) =>
                        _updateRepeat(state, config, 'spelling', value),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    i18n.t(
                      'inline.ui.pages.playback_advanced_page.spelling_mode_ba945a',
                    ),
                  ),
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
                  Text(
                    i18n.t(
                      'inline.ui.pages.playback_advanced_page.page_transition_9a9a9d',
                    ),
                  ),
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
                    title: i18n.t(
                      'inline.ui.pages.playback_advanced_page.playback_strategy_1fa1fb',
                    ),
                    subtitle: i18n.t(
                      'inline.ui.pages.playback_advanced_page.control_order_text_visibility_and_pacing_1fa0eb',
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
                      i18n.t(
                        'inline.ui.pages.playback_advanced_page.hide_on_screen_text_for_a_lower_visual_listening_flow_5ec0c7',
                      ),
                    ),
                    value: config.showText,
                    onChanged: (value) {
                      state.updateConfig(config.copyWith(showText: value));
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    i18n.t(
                      'inline.ui.pages.playback_advanced_page.delay_between_units_delay_ms_3d39b7',
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
                    i18n.t(
                      'inline.ui.pages.playback_advanced_page.overall_loop_overallrepeat_e237ea',
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
      'meanings_zh' => i18n.t(
        'inline.ui.pages.playback_advanced_page.chinese_meanings_6029e0',
      ),
      'pronunciations' => i18n.t(
        'inline.ui.pages.playback_advanced_page.pronunciations_de7c4f',
      ),
      'parts_of_speech' => i18n.t(
        'inline.ui.pages.playback_advanced_page.parts_of_speech_b53f33',
      ),
      'example' => i18n.t('fieldExamples'),
      'collocations' => i18n.t(
        'inline.ui.pages.playback_advanced_page.collocations_d8364a',
      ),
      'phrases' => i18n.t(
        'inline.ui.pages.playback_advanced_page.phrases_56e468',
      ),
      'usage' => i18n.t('inline.ui.pages.playback_advanced_page.usage_71f840'),
      'confusions' => i18n.t(
        'inline.ui.pages.playback_advanced_page.confusions_75dad4',
      ),
      'synonyms' => i18n.t(
        'inline.ui.pages.playback_advanced_page.synonyms_caefd1',
      ),
      'antonyms' => i18n.t(
        'inline.ui.pages.playback_advanced_page.antonyms_8ee53c',
      ),
      'etymology' => i18n.t('fieldEtymology'),
      'roots' => i18n.t('fieldRoots'),
      'affixes' => i18n.t('fieldAffixes'),
      'morphology' => i18n.t(
        'inline.ui.pages.playback_advanced_page.morphology_fda537',
      ),
      'variations' => i18n.t('fieldVariations'),
      'related' => i18n.t(
        'inline.ui.pages.playback_advanced_page.related_words_44c6cc',
      ),
      'derived' => i18n.t(
        'inline.ui.pages.playback_advanced_page.derived_words_a74249',
      ),
      'similar_words' => i18n.t(
        'inline.ui.pages.playback_advanced_page.similar_words_b1def5',
      ),
      'frequency_rank' => i18n.t(
        'inline.ui.pages.playback_advanced_page.frequency_rank_c1fa82',
      ),
      'memory' => i18n.t('fieldMemory'),
      'culture' => i18n.t(
        'inline.ui.pages.playback_advanced_page.culture_faa85e',
      ),
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
      SpellingPlaybackMode.letters => i18n.t(
        'inline.ui.pages.playback_advanced_page.letters_53e8af',
      ),
      SpellingPlaybackMode.pairs => i18n.t(
        'inline.ui.pages.playback_advanced_page.pairs_65a1c7',
      ),
    };
  }

  String _transitionStyleLabel(AppI18n i18n, WordPageTransitionStyle style) {
    return switch (style) {
      WordPageTransitionStyle.defaultStyle => i18n.t('todoNoColor'),
      WordPageTransitionStyle.smooth => i18n.t(
        'inline.plan294.zen_sand.smooth_a6a61c2c',
      ),
      WordPageTransitionStyle.fade => i18n.t('wordTransitionStyleFade'),
      WordPageTransitionStyle.pageFlip => i18n.t('wordTransitionStylePageFlip'),
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
