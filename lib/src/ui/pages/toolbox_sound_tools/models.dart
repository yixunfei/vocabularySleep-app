part of '../toolbox_sound_tools.dart';

class _PianoKey {
  const _PianoKey({
    required this.id,
    required this.label,
    required this.frequency,
    this.blackAfter = false,
  });

  final String id;
  final String label;
  final double frequency;
  final bool blackAfter;

  bool get isSharp => id.contains('#');

  int get octave {
    final match = RegExp(r'(-?\d+)$').firstMatch(id);
    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }

  String get pitchClass => id.replaceAll(RegExp(r'-?\d+$'), '');

  int get midi {
    const pitchClasses = <String, int>{
      'C': 0,
      'C#': 1,
      'D': 2,
      'D#': 3,
      'E': 4,
      'F': 5,
      'F#': 6,
      'G': 7,
      'G#': 8,
      'A': 9,
      'A#': 10,
      'B': 11,
    };
    return (octave + 1) * 12 + (pitchClasses[pitchClass] ?? 0);
  }
}

class _PianoPreset {
  const _PianoPreset({
    required this.id,
    required this.styleId,
    required this.touch,
    required this.reverb,
    required this.decay,
  });

  final String id;
  final String styleId;
  final double touch;
  final double reverb;
  final double decay;
}

class _FlutePreset {
  const _FlutePreset({
    required this.id,
    required this.styleId,
    required this.materialId,
    required this.scaleId,
    required this.breath,
    required this.reverb,
    required this.tail,
  });

  final String id;
  final String styleId;
  final String materialId;
  final String scaleId;
  final double breath;
  final double reverb;
  final double tail;
}

class _DrumKitPreset {
  const _DrumKitPreset({
    required this.id,
    required this.kitId,
    required this.drive,
    required this.tone,
    required this.tail,
    required this.material,
  });

  final String id;
  final String kitId;
  final double drive;
  final double tone;
  final double tail;
  final String material;
}

class _GuitarPreset {
  const _GuitarPreset({
    required this.id,
    required this.styleId,
    required this.pluckVolume,
    required this.strumVolume,
    required this.strumDelayMs,
    required this.resonance,
    required this.pickPosition,
  });

  final String id;
  final String styleId;
  final double pluckVolume;
  final double strumVolume;
  final int strumDelayMs;
  final double resonance;
  final double pickPosition;
}

class _TrianglePreset {
  const _TrianglePreset({
    required this.id,
    required this.styleId,
    required this.ring,
    required this.material,
    required this.strike,
    required this.damping,
  });

  final String id;
  final String styleId;
  final double ring;
  final String material;
  final double strike;
  final double damping;
}
