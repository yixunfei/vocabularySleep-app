part of '../toolbox_sound_tools.dart';

extension _HarpSettingsSheet on _HarpToolState {
  Widget buildHarpSettingsSheetContentV2(
    BuildContext context,
    AppI18n i18n, {
    required void Function(VoidCallback mutation) applySettings,
  }) {
    final theme = Theme.of(context);
    TextStyle? titleStyle() =>
        theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            i18n.t('toolbox.sound.harp.high_realism_presets'),
            style: titleStyle(),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _HarpToolState._realismPresets
                .map(
                  (preset) => ChoiceChip(
                    label: Text(_realismLabel(i18n, preset)),
                    selected: _activeRealismPresetId == preset.id,
                    tooltip: _realismDescription(i18n, preset),
                    onSelected: (_) {
                      _applyRealismPreset(preset);
                      applySettings(() {});
                    },
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 20),
          Text(i18n.t('toolbox.sound.harp.theme_timbre'), style: titleStyle()),
          const SizedBox(height: 8),
          Text(
            i18n.t('toolbox.sound.harp.timbre'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _HarpToolState._pluckPresets
                .map(
                  (preset) => ChoiceChip(
                    label: Text(_pluckLabel(i18n, preset)),
                    selected: _pluckStyleId == preset.id,
                    tooltip: _pluckDescription(i18n, preset),
                    onSelected: (_) {
                      if (_pluckStyleId == preset.id) return;
                      applySettings(() {
                        _pluckStyleId = preset.id;
                        _markRealismCustom();
                      });
                      _invalidateAudioPlayers();
                    },
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
          Text(
            i18n.t('toolbox.sound.harp.palette'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _HarpToolState._palettePresets
                .map(
                  (preset) => ChoiceChip(
                    label: Text(_paletteLabel(i18n, preset)),
                    selected: _paletteId == preset.id,
                    onSelected: (_) {
                      if (_paletteId == preset.id) return;
                      applySettings(() {
                        _paletteId = preset.id;
                        _markRealismCustom();
                      });
                    },
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
          Text(
            i18n.t(
              'toolbox.sound.harp.reverb_2',
              params: <String, Object?>{'value': (_reverbUi * 100).round()},
            ),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _reverbUi,
            min: 0.0,
            max: 0.8,
            divisions: 16,
            onChanged: (value) {
              applySettings(() {
                _reverbUi = value;
                _markRealismCustom();
              });
            },
            onChangeEnd: (value) {
              final quantized = (value * 20).round() / 20;
              applySettings(() {
                _reverbUi = quantized;
                _reverbForAudio = quantized;
                _markRealismCustom();
              });
              _invalidateAudioPlayers();
            },
          ),
          const SizedBox(height: 20),
          Text(i18n.t('toolbox.sound.harp.scale_harmony'), style: titleStyle()),
          const SizedBox(height: 8),
          Text(
            i18n.t('toolbox.sound.flute.scale'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _HarpToolState._scalePresets
                .map(
                  (preset) => ChoiceChip(
                    label: Text(_scaleLabel(i18n, preset)),
                    selected: _scaleId == preset.id,
                    onSelected: (_) {
                      if (_scaleId == preset.id) return;
                      applySettings(() {
                        _scaleId = preset.id;
                        _markRealismCustom();
                      });
                    },
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
          Text(
            i18n.t('toolbox.sound.harp.chord'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _HarpToolState._chordPresets
                .map(
                  (preset) => ChoiceChip(
                    label: Text(_chordLabel(i18n, preset)),
                    selected: _chordId == preset.id,
                    onSelected: (_) {
                      if (_chordId == preset.id) return;
                      applySettings(() {
                        _chordId = preset.id;
                        _markRealismCustom();
                      });
                    },
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
          Text(
            i18n.t('toolbox.sound.harp.arpeggio'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _HarpToolState._patternPresets
                .map(
                  (preset) => ChoiceChip(
                    label: Text(_patternLabel(i18n, preset)),
                    selected: _patternId == preset.id,
                    tooltip: _patternDescription(i18n, preset),
                    onSelected: (_) {
                      if (_patternId == preset.id) return;
                      applySettings(() {
                        _patternId = preset.id;
                        _markRealismCustom();
                      });
                    },
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 8),
          FilterChip(
            label: Text(i18n.t('toolbox.sound.harp.chord_resonance')),
            selected: _chordResonanceEnabled,
            onSelected: (selected) {
              applySettings(() {
                _chordResonanceEnabled = selected;
                _markRealismCustom();
              });
            },
          ),
          const SizedBox(height: 20),
          Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              initiallyExpanded: _advancedSettingsExpanded,
              onExpansionChanged: (expanded) {
                applySettings(() {
                  _advancedSettingsExpanded = expanded;
                });
              },
              title: Text(
                i18n.t('toolbox.sound.harp.advanced'),
                style: titleStyle(),
              ),
              subtitle: Text(
                i18n.t('toolbox.sound.harp.damping_sweep_deadzone_and_chord'),
              ),
              childrenPadding: const EdgeInsets.only(bottom: 8),
              children: <Widget>[
                Text(
                  i18n.t(
                    'toolbox.sound.harp.chord_root',
                    params: <String, Object?>{
                      'current': _chordRootIndex + 1,
                      'total': _HarpToolState._stringCount,
                    },
                  ),
                ),
                Slider(
                  value: _chordRootIndex.toDouble(),
                  min: 0,
                  max: (_HarpToolState._stringCount - 1).toDouble(),
                  divisions: _HarpToolState._stringCount - 1,
                  onChanged: (value) {
                    applySettings(() {
                      _chordRootIndex = value.round();
                      _markRealismCustom();
                    });
                  },
                ),
                Text(
                  i18n.t(
                    'toolbox.sound.harp.damping',
                    params: <String, Object?>{
                      'value': _damping.toStringAsFixed(1),
                    },
                  ),
                ),
                Slider(
                  value: _damping,
                  min: 4,
                  max: 18,
                  divisions: 28,
                  onChanged: (value) {
                    applySettings(() {
                      _damping = value;
                      _markRealismCustom();
                    });
                  },
                  onChangeEnd: (value) {
                    final quantized = (value * 10).round() / 10;
                    applySettings(() {
                      _damping = quantized;
                      _markRealismCustom();
                    });
                    _invalidateAudioPlayers();
                  },
                ),
                Text(
                  i18n.t(
                    'toolbox.sound.harp.sweep_deadzone_px',
                    params: <String, Object?>{
                      'value': _swipeThreshold.toStringAsFixed(1),
                    },
                  ),
                ),
                Slider(
                  value: _swipeThreshold,
                  min: 0.4,
                  max: 8,
                  divisions: 38,
                  onChanged: (value) {
                    applySettings(() {
                      _swipeThreshold = value;
                      _markRealismCustom();
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
