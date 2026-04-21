part of '../toolbox_sound_tools.dart';

class _HarpConfig {
  const _HarpConfig({
    this.scaleId = 'c_major',
    this.chordId = 'major',
    this.pluckStyleId = 'silk',
    this.patternId = 'glide',
    this.paletteId = 'ivory_wood',
    this.chordRootIndex = 0,
    this.chordResonanceEnabled = false,
    this.reverb = 0.24,
    this.damping = 10,
    this.swipeThreshold = 1.2,
    this.activeRealismPresetId,
  });

  final String scaleId;
  final String chordId;
  final String pluckStyleId;
  final String patternId;
  final String paletteId;
  final int chordRootIndex;
  final bool chordResonanceEnabled;
  final double reverb;
  final double damping;
  final double swipeThreshold;
  final String? activeRealismPresetId;

  _HarpConfig copyWith({
    String? scaleId,
    String? chordId,
    String? pluckStyleId,
    String? patternId,
    String? paletteId,
    int? chordRootIndex,
    bool? chordResonanceEnabled,
    double? reverb,
    double? damping,
    double? swipeThreshold,
    String? activeRealismPresetId,
  }) {
    return _HarpConfig(
      scaleId: scaleId ?? this.scaleId,
      chordId: chordId ?? this.chordId,
      pluckStyleId: pluckStyleId ?? this.pluckStyleId,
      patternId: patternId ?? this.patternId,
      paletteId: paletteId ?? this.paletteId,
      chordRootIndex: chordRootIndex ?? this.chordRootIndex,
      chordResonanceEnabled:
          chordResonanceEnabled ?? this.chordResonanceEnabled,
      reverb: reverb ?? this.reverb,
      damping: damping ?? this.damping,
      swipeThreshold: swipeThreshold ?? this.swipeThreshold,
      activeRealismPresetId:
          activeRealismPresetId ?? this.activeRealismPresetId,
    );
  }
}

class _HarpScalePreset {
  const _HarpScalePreset({
    required this.id,
    required this.label,
    required this.notes,
  });

  final String id;
  final String label;
  final List<double> notes;
}

class _HarpChordPreset {
  const _HarpChordPreset({
    required this.id,
    required this.label,
    required this.intervals,
  });

  final String id;
  final String label;
  final List<int> intervals;
}

class _HarpPalettePreset {
  const _HarpPalettePreset({
    required this.id,
    required this.label,
    required this.colors,
  });

  final String id;
  final String label;
  final List<Color> colors;
}

class _HarpPluckPreset {
  const _HarpPluckPreset({
    required this.id,
    required this.label,
    required this.description,
  });

  final String id;
  final String label;
  final String description;
}

class _HarpPatternPreset {
  const _HarpPatternPreset({
    required this.id,
    required this.label,
    required this.description,
  });

  final String id;
  final String label;
  final String description;
}

class _HarpRealismPreset {
  const _HarpRealismPreset({
    required this.id,
    required this.label,
    required this.description,
    required this.scaleId,
    required this.chordId,
    required this.pluckStyleId,
    required this.patternId,
    required this.paletteId,
    required this.reverb,
    required this.damping,
    required this.swipeThreshold,
    required this.chordResonanceEnabled,
  });

  final String id;
  final String label;
  final String description;
  final String scaleId;
  final String chordId;
  final String pluckStyleId;
  final String patternId;
  final String paletteId;
  final double reverb;
  final double damping;
  final double swipeThreshold;
  final bool chordResonanceEnabled;
}
