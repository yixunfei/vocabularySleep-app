part of '../toolbox_sound_tools.dart';

class _PianoTool extends StatefulWidget {
  const _PianoTool({this.fullScreen = false});

  final bool fullScreen;

  @override
  State<_PianoTool> createState() => _PianoToolState();
}

class _PianoToolState extends State<_PianoTool> {
  static const List<double> _velocityBuckets = <double>[
    0.28,
    0.42,
    0.58,
    0.74,
    0.88,
    1.0,
  ];

  static const List<int> _pianoVariants = <int>[0, 9, 21];
  static final List<_PianoKey> _allKeys = _buildChromaticKeys();
  static const List<_PianoPitchSet> _scaleSets = <_PianoPitchSet>[
    _PianoPitchSet(id: 'major', intervals: <int>[0, 2, 4, 5, 7, 9, 11]),
    _PianoPitchSet(id: 'minor', intervals: <int>[0, 2, 3, 5, 7, 8, 10]),
    _PianoPitchSet(id: 'dorian', intervals: <int>[0, 2, 3, 5, 7, 9, 10]),
    _PianoPitchSet(id: 'lydian', intervals: <int>[0, 2, 4, 6, 7, 9, 11]),
    _PianoPitchSet(
      id: 'harmonic_minor',
      intervals: <int>[0, 2, 3, 5, 7, 8, 11],
    ),
    _PianoPitchSet(id: 'pentatonic', intervals: <int>[0, 2, 4, 7, 9]),
    _PianoPitchSet(
      id: 'chromatic',
      intervals: <int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
    ),
  ];
  static const List<_PianoChordSpec> _chordSets = <_PianoChordSpec>[
    _PianoChordSpec(
      id: 'off',
      highlightIntervals: <int>[],
      voicedIntervals: <int>[0],
      staggerMs: 0,
    ),
    _PianoChordSpec(
      id: 'major',
      highlightIntervals: <int>[0, 4, 7],
      voicedIntervals: <int>[0, 7, 12, 16],
      staggerMs: 14,
    ),
    _PianoChordSpec(
      id: 'minor',
      highlightIntervals: <int>[0, 3, 7],
      voicedIntervals: <int>[0, 7, 12, 15],
      staggerMs: 14,
    ),
    _PianoChordSpec(
      id: 'sus2',
      highlightIntervals: <int>[0, 2, 7],
      voicedIntervals: <int>[0, 7, 12, 14],
      staggerMs: 12,
    ),
    _PianoChordSpec(
      id: 'maj7',
      highlightIntervals: <int>[0, 4, 7, 11],
      voicedIntervals: <int>[0, 7, 11, 16],
      staggerMs: 16,
    ),
    _PianoChordSpec(
      id: 'm7',
      highlightIntervals: <int>[0, 3, 7, 10],
      voicedIntervals: <int>[0, 7, 10, 15],
      staggerMs: 16,
    ),
    _PianoChordSpec(
      id: 'add9',
      highlightIntervals: <int>[0, 4, 7, 2],
      voicedIntervals: <int>[0, 7, 12, 14],
      staggerMs: 18,
    ),
  ];
  static const List<String> _rootPitchClasses = <String>[
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
  static const List<_PianoKeyLayoutPreset> _keyLayouts =
      <_PianoKeyLayoutPreset>[
        _PianoKeyLayoutPreset(id: '25', keyCount: 25, startMidi: 48),
        _PianoKeyLayoutPreset(id: '37', keyCount: 37, startMidi: 36),
        _PianoKeyLayoutPreset(id: '49', keyCount: 49, startMidi: 36),
        _PianoKeyLayoutPreset(id: '61', keyCount: 61, startMidi: 36),
        _PianoKeyLayoutPreset(id: '76', keyCount: 76, startMidi: 28),
        _PianoKeyLayoutPreset(id: '88', keyCount: 88, startMidi: 21),
      ];
  static const List<_PianoPreset> _presets = <_PianoPreset>[
    _PianoPreset(
      id: 'concert_hall',
      styleId: 'concert',
      touch: 0.92,
      reverb: 0.18,
      decay: 1.15,
    ),
    _PianoPreset(
      id: 'upright_studio',
      styleId: 'upright',
      touch: 0.88,
      reverb: 0.1,
      decay: 0.98,
    ),
    _PianoPreset(
      id: 'bright_stage',
      styleId: 'bright',
      touch: 0.96,
      reverb: 0.12,
      decay: 0.92,
    ),
    _PianoPreset(
      id: 'felt_room',
      styleId: 'felt',
      touch: 0.84,
      reverb: 0.24,
      decay: 1.3,
    ),
  ];
  static const List<_PianoKeyboardStyle> _keyboardStyles =
      <_PianoKeyboardStyle>[
        _PianoKeyboardStyle(
          id: 'classic_bw',
          whiteTop: Color(0xFFFDFDFD),
          whiteBottom: Color(0xFFE7E7E7),
          whiteAccentTop: Color(0xFFF8F8F8),
          whiteAccentBottom: Color(0xFFD9D9D9),
          blackTop: Color(0xFF1A1A1A),
          blackBottom: Color(0xFF050505),
          blackAccentTop: Color(0xFF2A2A2A),
          blackAccentBottom: Color(0xFF111111),
          shellTop: Color(0xFF111111),
          shellBottom: Color(0xFF262626),
          railColor: Color(0x22FFFFFF),
          sideGlow: Color(0x22000000),
        ),
        _PianoKeyboardStyle(
          id: 'ivory',
          whiteTop: Color(0xFFFCFCFD),
          whiteBottom: Color(0xFFE8ECF2),
          whiteAccentTop: Color(0xFFF6E8BE),
          whiteAccentBottom: Color(0xFFE7C968),
          blackTop: Color(0xFF151923),
          blackBottom: Color(0xFF070A11),
          blackAccentTop: Color(0xFF8C6A12),
          blackAccentBottom: Color(0xFF5B4304),
          shellTop: Color(0xFF0F172A),
          shellBottom: Color(0xFF1E293B),
          railColor: Color(0x22FFFFFF),
          sideGlow: Color(0x44F6E8BE),
        ),
        _PianoKeyboardStyle(
          id: 'midnight',
          whiteTop: Color(0xFFF7FAFC),
          whiteBottom: Color(0xFFD9E6F5),
          whiteAccentTop: Color(0xFFCBE4FF),
          whiteAccentBottom: Color(0xFF7DB0FF),
          blackTop: Color(0xFF0E1726),
          blackBottom: Color(0xFF03070D),
          blackAccentTop: Color(0xFF4575C9),
          blackAccentBottom: Color(0xFF1D3C75),
          shellTop: Color(0xFF020617),
          shellBottom: Color(0xFF111827),
          railColor: Color(0x26CBE4FF),
          sideGlow: Color(0x4468A8FF),
        ),
        _PianoKeyboardStyle(
          id: 'mist',
          whiteTop: Color(0xFFF8FCFB),
          whiteBottom: Color(0xFFDCEFEA),
          whiteAccentTop: Color(0xFFD9F5EE),
          whiteAccentBottom: Color(0xFF8AD3BD),
          blackTop: Color(0xFF16211E),
          blackBottom: Color(0xFF08100F),
          blackAccentTop: Color(0xFF3D8B78),
          blackAccentBottom: Color(0xFF1D5448),
          shellTop: Color(0xFF0B1B1A),
          shellBottom: Color(0xFF132B28),
          railColor: Color(0x228AD3BD),
          sideGlow: Color(0x448AD3BD),
        ),
      ];

  final Map<String, ToolboxRealisticEffectPlayer> _players =
      <String, ToolboxRealisticEffectPlayer>{};
  final Map<int, Offset> _activePointers = <int, Offset>{};
  final Map<int, String> _activePointerKeyIds = <int, String>{};
  final Map<String, int> _activeKeyPulseCounts = <String, int>{};
  final math.Random _humanizeRandom = math.Random();

  Set<String> _activeKeyIds = <String>{};
  String _presetId = _presets.first.id;
  String _keyboardStyleId = _keyboardStyles.first.id;
  double _touch = _presets.first.touch;
  double _reverb = _presets.first.reverb;
  double _decay = _presets.first.decay;
  double _keyHeightScale = 1.0;
  double _blackKeyWidthRatio = 0.34;
  double _blackKeyHeightRatio = 0.66;
  double _chordSpreadScale = 1.15;
  double _chordFalloff = 0.13;
  double _gestureThresholdScale = 1.0;
  int _rangeStartOctave = 2;
  String _scaleId = _scaleSets.first.id;
  String _chordId = _chordSets.first.id;
  String _rootPitchClass = 'C';
  String _keyLayoutId = '88';
  Offset? _twoFingerOrigin;
  bool _rangeNavigatorExpanded = false;
  bool _dualKeyboardMode = true;
  bool _compactKeyboardMode = false;
  bool _aggressiveOneHandMode = true;
  bool _didApplyResponsiveDefaults = false;
  DateTime? _lastRangeGestureAt;
  Timer? _rangeWarmUpTimer;
  int _rangeWarmUpVersion = 0;
  int _visibleOctaveSpan = 1;
  bool _isRangeWindowPreparing = false;
  _PianoCompactDeckFocus _compactDualFocus = _PianoCompactDeckFocus.low;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_warmUpVisibleWindow(octaveSpan: 1, rangeStart: 2));
    });
  }

  _PianoPreset get _activePreset {
    return _presets.firstWhere(
      (item) => item.id == _presetId,
      orElse: () => _presets.first,
    );
  }

  _PianoPitchSet get _activeScaleSet {
    return _scaleSets.firstWhere(
      (item) => item.id == _scaleId,
      orElse: () => _scaleSets.first,
    );
  }

  _PianoChordSpec get _activeChordSpec {
    return _chordSets.firstWhere(
      (item) => item.id == _chordId,
      orElse: () => _chordSets.first,
    );
  }

  _PianoKeyboardStyle get _activeKeyboardStyle {
    return _keyboardStyles.firstWhere(
      (item) => item.id == _keyboardStyleId,
      orElse: () => _keyboardStyles.first,
    );
  }

  _PianoKeyLayoutPreset get _activeKeyLayout {
    return _keyLayouts.firstWhere(
      (item) => item.id == _keyLayoutId,
      orElse: () => _keyLayouts.last,
    );
  }

  List<_PianoKey> get _activeKeyPool {
    final layout = _activeKeyLayout;
    final endMidi = layout.startMidi + layout.keyCount - 1;
    return _allKeys
        .where((key) => key.midi >= layout.startMidi && key.midi <= endMidi)
        .toList(growable: false);
  }

  void _setViewState(VoidCallback updates) {
    if (!mounted) {
      return;
    }
    setState(updates);
  }

  @override
  void dispose() {
    _disposePianoToolState();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildPianoToolState(context);
  }
}
