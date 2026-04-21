part of '../toolbox_sound_tools.dart';

List<_PianoKey> _buildChromaticKeys() {
  const pitchClasses = <String>[
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];
  const blackAfterWhite = <String>{'C', 'D', 'F', 'G', 'A'};
  final keys = <_PianoKey>[];
  for (final pitchClass in <String>['A', 'A#', 'B']) {
    final label = '$pitchClass${0}';
    keys.add(
      _PianoKey(
        id: label,
        label: label,
        frequency:
            (440 * math.pow(2, (_midiFromParts(pitchClass, 0) - 69) / 12))
                .toDouble(),
        blackAfter: blackAfterWhite.contains(pitchClass),
      ),
    );
  }
  for (var octave = 1; octave <= 7; octave += 1) {
    for (final pitchClass in pitchClasses) {
      final label = '$pitchClass$octave';
      keys.add(
        _PianoKey(
          id: label,
          label: label,
          frequency:
              (440 *
                      math.pow(
                        2,
                        (_midiFromParts(pitchClass, octave) - 69) / 12,
                      ))
                  .toDouble(),
          blackAfter: blackAfterWhite.contains(pitchClass),
        ),
      );
    }
  }
  keys.add(
    _PianoKey(
      id: 'C8',
      label: 'C8',
      frequency: (440 * math.pow(2, (_midiFromParts('C', 8) - 69) / 12))
          .toDouble(),
      blackAfter: false,
    ),
  );
  return keys;
}

int _midiFromParts(String pitchClass, int octave) {
  const offsets = <String, int>{
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
  return (octave + 1) * 12 + (offsets[pitchClass] ?? 0);
}
