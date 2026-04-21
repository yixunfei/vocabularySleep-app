part of '../toolbox_sound_tools.dart';

enum _WoodfishSoundProfile {
  temple,
  sandal,
  bright,
  hollow,
  night;

  String get id => name;

  String get label => switch (this) {
    _WoodfishSoundProfile.temple => 'Temple',
    _WoodfishSoundProfile.sandal => 'Sandal',
    _WoodfishSoundProfile.bright => 'Bright',
    _WoodfishSoundProfile.hollow => 'Hollow',
    _WoodfishSoundProfile.night => 'Night',
  };

  static _WoodfishSoundProfile fromId(String? value) {
    for (final item in _WoodfishSoundProfile.values) {
      if (item.id == value) {
        return item;
      }
    }
    return _WoodfishSoundProfile.temple;
  }
}

enum _WoodfishVisualStyle {
  zenAmber,
  inkSandal,
  nightLantern;

  String get id => switch (this) {
    _WoodfishVisualStyle.zenAmber => 'zen_amber',
    _WoodfishVisualStyle.inkSandal => 'ink_sandal',
    _WoodfishVisualStyle.nightLantern => 'night_lantern',
  };

  static _WoodfishVisualStyle fromId(String? value) {
    return switch (value) {
      'ink_sandal' => _WoodfishVisualStyle.inkSandal,
      'night_lantern' => _WoodfishVisualStyle.nightLantern,
      _ => _WoodfishVisualStyle.zenAmber,
    };
  }
}

enum _WoodfishReboundArcPreset {
  compact,
  wide;

  String get id => switch (this) {
    _WoodfishReboundArcPreset.compact => 'compact',
    _WoodfishReboundArcPreset.wide => 'wide',
  };

  static _WoodfishReboundArcPreset fromId(String? value) {
    return switch (value) {
      'wide' => _WoodfishReboundArcPreset.wide,
      _ => _WoodfishReboundArcPreset.compact,
    };
  }
}

class _WoodfishVisualTokens {
  const _WoodfishVisualTokens({
    required this.primaryAccent,
    required this.secondaryAccent,
    required this.screenGradient,
    required this.immersiveStageGradient,
    required this.normalStageGradient,
    required this.bodyGradient,
    required this.bodyStroke,
    required this.grooveDark,
    required this.grooveLight,
    required this.grain,
    required this.dust,
    required this.accentWarm,
    required this.accentCool,
    required this.malletShaftGradient,
    required this.malletHeadGradient,
    required this.malletBand,
    required this.malletGlow,
  });

  final Color primaryAccent;
  final Color secondaryAccent;
  final List<Color> screenGradient;
  final List<Color> immersiveStageGradient;
  final List<Color> normalStageGradient;
  final List<Color> bodyGradient;
  final Color bodyStroke;
  final Color grooveDark;
  final Color grooveLight;
  final Color grain;
  final Color dust;
  final Color accentWarm;
  final Color accentCool;
  final List<Color> malletShaftGradient;
  final List<Color> malletHeadGradient;
  final Color malletBand;
  final Color malletGlow;
}

_WoodfishVisualTokens _visualTokens(_WoodfishVisualStyle style) {
  return switch (style) {
    _WoodfishVisualStyle.inkSandal => const _WoodfishVisualTokens(
      primaryAccent: Color(0xFF9CB7D1),
      secondaryAccent: Color(0xFF6EA5C8),
      screenGradient: <Color>[
        Color(0xFF090D16),
        Color(0xFF121B2C),
        Color(0xFF0D131F),
      ],
      immersiveStageGradient: <Color>[
        Color(0xFF080D15),
        Color(0xFF121A28),
        Color(0xFF0B1019),
      ],
      normalStageGradient: <Color>[
        Color(0xFFE6E8EB),
        Color(0xFFD7DDE3),
        Color(0xFFC4CCD5),
      ],
      bodyGradient: <Color>[
        Color(0xFFB8A892),
        Color(0xFF8B745B),
        Color(0xFF5B4A39),
      ],
      bodyStroke: Color(0xFF2D2520),
      grooveDark: Color(0xFF25211D),
      grooveLight: Color(0xFFEDE7DE),
      grain: Color(0xFF3A322C),
      dust: Color(0xFFCED7E2),
      accentWarm: Color(0xFFCAA36A),
      accentCool: Color(0xFF7BB3CF),
      malletShaftGradient: <Color>[Color(0xFF8C7A62), Color(0xFF5E5343)],
      malletHeadGradient: <Color>[
        Color(0xFFD2C3AA),
        Color(0xFF9D8769),
        Color(0xFF6D5C48),
      ],
      malletBand: Color(0xFF617489),
      malletGlow: Color(0xFFA9C5DA),
    ),
    _WoodfishVisualStyle.nightLantern => const _WoodfishVisualTokens(
      primaryAccent: Color(0xFFF5B25E),
      secondaryAccent: Color(0xFFE68A7B),
      screenGradient: <Color>[
        Color(0xFF1F102A),
        Color(0xFF3D1F2E),
        Color(0xFF1A1326),
      ],
      immersiveStageGradient: <Color>[
        Color(0xFF160E22),
        Color(0xFF2A1830),
        Color(0xFF130C1C),
      ],
      normalStageGradient: <Color>[
        Color(0xFFF3DACC),
        Color(0xFFE7C2AF),
        Color(0xFFD19F86),
      ],
      bodyGradient: <Color>[
        Color(0xFFDA9C61),
        Color(0xFFA05A37),
        Color(0xFF6A3529),
      ],
      bodyStroke: Color(0xFF3E1F18),
      grooveDark: Color(0xFF2E1814),
      grooveLight: Color(0xFFF8D1B8),
      grain: Color(0xFF4A2921),
      dust: Color(0xFFF7C89E),
      accentWarm: Color(0xFFF59E0B),
      accentCool: Color(0xFFE8796D),
      malletShaftGradient: <Color>[Color(0xFF9A4E37), Color(0xFF6D3326)],
      malletHeadGradient: <Color>[
        Color(0xFFE6A06A),
        Color(0xFFBA653A),
        Color(0xFF7D3A2B),
      ],
      malletBand: Color(0xFFA52B40),
      malletGlow: Color(0xFFF9BE6B),
    ),
    _ => const _WoodfishVisualTokens(
      primaryAccent: Color(0xFFD9A441),
      secondaryAccent: Color(0xFF6BAF92),
      screenGradient: <Color>[
        Color(0xFF050608),
        Color(0xFF0B0F14),
        Color(0xFF090C12),
      ],
      immersiveStageGradient: <Color>[
        Color(0xFF070A0F),
        Color(0xFF121821),
        Color(0xFF0A0E14),
      ],
      normalStageGradient: <Color>[
        Color(0xFFF7EBD8),
        Color(0xFFEBD6B8),
        Color(0xFFD7B98E),
      ],
      bodyGradient: <Color>[
        Color(0xFFEFDFBC),
        Color(0xFFD6BA8D),
        Color(0xFFB58A58),
      ],
      bodyStroke: Color(0xFF4A2A11),
      grooveDark: Color(0xFF3D2414),
      grooveLight: Color(0xFFF8EACB),
      grain: Color(0xFF5A391F),
      dust: Color(0xFFFCEFD2),
      accentWarm: Color(0xFFF2B35B),
      accentCool: Color(0xFF8CBF9C),
      malletShaftGradient: <Color>[Color(0xFFE7C793), Color(0xFFC3945C)],
      malletHeadGradient: <Color>[
        Color(0xFFF5DEB3),
        Color(0xFFD9B27A),
        Color(0xFFB2834E),
      ],
      malletBand: Color(0xFFB45F2B),
      malletGlow: Color(0xFFF7D289),
    ),
  };
}

class _WoodfishRhythmPreset {
  const _WoodfishRhythmPreset({
    required this.id,
    required this.bpm,
    required this.beatsPerCycle,
    required this.subdivision,
    required this.accentEvery,
    required this.targetCount,
  });

  final String id;
  final int bpm;
  final int beatsPerCycle;
  final int subdivision;
  final int accentEvery;
  final int targetCount;
}
