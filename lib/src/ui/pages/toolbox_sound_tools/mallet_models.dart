part of '../toolbox_sound_tools.dart';

class _MalletInstrumentSpec {
  const _MalletInstrumentSpec({
    required this.id,
    required this.patch,
    required this.midis,
    required this.defaultTail,
    required this.defaultReverb,
    required this.volume,
    required this.bodyColor,
    required this.resonatorColor,
  });

  final String id;
  final ToolboxInstrumentPatch patch;
  final List<int> midis;
  final double defaultTail;
  final double defaultReverb;
  final double volume;
  final Color bodyColor;
  final Color resonatorColor;
}

class _MalletMaterialSpec {
  const _MalletMaterialSpec({
    required this.id,
    required this.tailBias,
    required this.reverbBias,
    required this.volumeBias,
    required this.tint,
    required this.resonatorColor,
  });

  final String id;
  final double tailBias;
  final double reverbBias;
  final double volumeBias;
  final Color tint;
  final Color resonatorColor;
}

class _MalletCavitySpec {
  const _MalletCavitySpec({
    required this.id,
    required this.tailBias,
    required this.reverbBias,
    required this.resonatorScale,
  });

  final String id;
  final double tailBias;
  final double reverbBias;
  final double resonatorScale;
}

const List<Color> _malletRainbowColors = <Color>[
  Color(0xFFE95F8D),
  Color(0xFFF28A2E),
  Color(0xFFF2D33B),
  Color(0xFF7CCB4C),
  Color(0xFF39B9D5),
  Color(0xFF255CA8),
  Color(0xFF7B4BC4),
  Color(0xFFE95F8D),
  Color(0xFFF28A2E),
  Color(0xFFF2D33B),
  Color(0xFF7CCB4C),
  Color(0xFF39B9D5),
  Color(0xFF255CA8),
  Color(0xFF7B4BC4),
  Color(0xFFE95F8D),
  Color(0xFFF28A2E),
];

const List<_MalletInstrumentSpec> _malletInstrumentSpecs =
    <_MalletInstrumentSpec>[
      _MalletInstrumentSpec(
        id: 'xylophone',
        patch: ToolboxInstrumentBankCatalog.xylophone,
        midis: <int>[60, 62, 64, 65, 67, 69, 71, 72, 74, 76, 77, 79],
        defaultTail: 0.46,
        defaultReverb: 0.16,
        volume: 0.88,
        bodyColor: Color(0xFFD49A56),
        resonatorColor: Color(0xFFD8B27A),
      ),
      _MalletInstrumentSpec(
        id: 'chimes',
        patch: ToolboxInstrumentBankCatalog.tubularBells,
        midis: <int>[60, 62, 64, 65, 67, 69, 71, 72, 74, 76, 77, 79],
        defaultTail: 0.74,
        defaultReverb: 0.34,
        volume: 0.82,
        bodyColor: Color(0xFF64748B),
        resonatorColor: Color(0xFFCBD5E1),
      ),
      _MalletInstrumentSpec(
        id: 'vibraphone',
        patch: ToolboxInstrumentBankCatalog.vibraphone,
        midis: <int>[
          57,
          59,
          60,
          62,
          64,
          65,
          67,
          69,
          71,
          72,
          74,
          76,
          77,
          79,
          81,
        ],
        defaultTail: 0.64,
        defaultReverb: 0.3,
        volume: 0.82,
        bodyColor: Color(0xFF7CA7B8),
        resonatorColor: Color(0xFFB8D7E0),
      ),
      _MalletInstrumentSpec(
        id: 'marimba',
        patch: ToolboxInstrumentBankCatalog.marimba,
        midis: <int>[
          48,
          50,
          52,
          53,
          55,
          57,
          59,
          60,
          62,
          64,
          65,
          67,
          69,
          71,
          72,
          74,
        ],
        defaultTail: 0.56,
        defaultReverb: 0.22,
        volume: 0.86,
        bodyColor: Color(0xFFA45E32),
        resonatorColor: Color(0xFF9B6A3B),
      ),
      _MalletInstrumentSpec(
        id: 'glockenspiel',
        patch: ToolboxInstrumentBankCatalog.glockenspiel,
        midis: <int>[72, 74, 76, 77, 79, 81, 83, 84, 86, 88, 89, 91],
        defaultTail: 0.52,
        defaultReverb: 0.26,
        volume: 0.78,
        bodyColor: Color(0xFFD6DEE8),
        resonatorColor: Color(0xFFE8EEF4),
      ),
    ];

const List<_MalletMaterialSpec> _malletMaterialSpecs = <_MalletMaterialSpec>[
  _MalletMaterialSpec(
    id: 'wood',
    tailBias: 0,
    reverbBias: -0.02,
    volumeBias: 0,
    tint: Color(0xFFD89A4B),
    resonatorColor: Color(0xFFC08A4B),
  ),
  _MalletMaterialSpec(
    id: 'iron',
    tailBias: 0.14,
    reverbBias: 0.08,
    volumeBias: -0.02,
    tint: Color(0xFFB9C3CC),
    resonatorColor: Color(0xFF9AA6B2),
  ),
  _MalletMaterialSpec(
    id: 'copper',
    tailBias: 0.1,
    reverbBias: 0.06,
    volumeBias: 0,
    tint: Color(0xFFD5894C),
    resonatorColor: Color(0xFFC9783E),
  ),
  _MalletMaterialSpec(
    id: 'glass',
    tailBias: 0.2,
    reverbBias: 0.12,
    volumeBias: -0.06,
    tint: Color(0xFFAEE4F5),
    resonatorColor: Color(0xFFBEEAF5),
  ),
  _MalletMaterialSpec(
    id: 'ceramic',
    tailBias: 0.08,
    reverbBias: 0.04,
    volumeBias: -0.04,
    tint: Color(0xFFE6DDD0),
    resonatorColor: Color(0xFFD7C7B6),
  ),
  _MalletMaterialSpec(
    id: 'plastic',
    tailBias: -0.12,
    reverbBias: -0.06,
    volumeBias: 0.02,
    tint: Color(0xFFEAC6D4),
    resonatorColor: Color(0xFFD7B4C4),
  ),
];

const List<_MalletCavitySpec> _malletCavitySpecs = <_MalletCavitySpec>[
  _MalletCavitySpec(
    id: 'open_box',
    tailBias: 0,
    reverbBias: 0,
    resonatorScale: 0.72,
  ),
  _MalletCavitySpec(
    id: 'shallow',
    tailBias: -0.12,
    reverbBias: -0.05,
    resonatorScale: 0.48,
  ),
  _MalletCavitySpec(
    id: 'long_tubes',
    tailBias: 0.2,
    reverbBias: 0.1,
    resonatorScale: 0.95,
  ),
  _MalletCavitySpec(
    id: 'closed_box',
    tailBias: -0.04,
    reverbBias: 0.04,
    resonatorScale: 0.64,
  ),
];

_MalletInstrumentSpec _malletInstrumentById(String id) {
  return _malletInstrumentSpecs.firstWhere(
    (item) => item.id == id,
    orElse: () => _malletInstrumentSpecs.first,
  );
}

_MalletMaterialSpec _malletMaterialById(String id) {
  return _malletMaterialSpecs.firstWhere(
    (item) => item.id == id,
    orElse: () => _malletMaterialSpecs.first,
  );
}

_MalletCavitySpec _malletCavityById(String id) {
  return _malletCavitySpecs.firstWhere(
    (item) => item.id == id,
    orElse: () => _malletCavitySpecs.first,
  );
}
