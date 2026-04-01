part of '../toolbox_sound_tools.dart';

class _PianoTool extends StatefulWidget {
  const _PianoTool({this.fullScreen = false});

  final bool fullScreen;

  @override
  State<_PianoTool> createState() => _PianoToolState();
}

class _PianoToolState extends State<_PianoTool> {
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

  final Map<String, ToolboxEffectPlayer> _players =
      <String, ToolboxEffectPlayer>{};
  final Map<int, Offset> _activePointers = <int, Offset>{};
  final Map<int, String> _activePointerKeyIds = <int, String>{};
  final Map<String, int> _activeKeyPulseCounts = <String, int>{};

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
  int _rangeStartOctave = 2;
  String _scaleId = _scaleSets.first.id;
  String _chordId = _chordSets.first.id;
  String _rootPitchClass = 'C';
  Offset? _twoFingerOrigin;
  bool _rangeNavigatorExpanded = false;
  bool _dualKeyboardMode = true;

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

  String _displayPresetLabel(AppI18n i18n, _PianoPreset preset) {
    return switch (preset.id) {
      'upright_studio' => pickUiText(i18n, zh: '录音室立式钢琴', en: 'Studio upright'),
      'bright_stage' => pickUiText(i18n, zh: '明亮舞台', en: 'Bright stage'),
      'felt_room' => pickUiText(i18n, zh: '毛毡房间', en: 'Felt room'),
      _ => pickUiText(i18n, zh: '音乐厅', en: 'Concert hall'),
    };
  }

  // ignore: unused_element
  String _displayPresetSubtitle(AppI18n i18n, _PianoPreset preset) {
    return switch (preset.id) {
      'bright_stage' => pickUiText(
        i18n,
        zh: '更清晰的击弦边缘，适合突出旋律和明亮起音。',
        en: 'Sharper hammer edge for lead lines and brighter attacks.',
      ),
      'felt_room' => pickUiText(
        i18n,
        zh: '毛毡包裹感更强，适合亲密和安静的演奏。',
        en: 'Softer felt body for intimate and quiet playing.',
      ),
      _ => pickUiText(
        i18n,
        zh: '延音与空间感更均衡，适合日常练习与编配。',
        en: 'Balanced sustain and room feel for all-purpose playing.',
      ),
    };
  }

  // ignore: unused_element
  String _displayScaleLabel(AppI18n i18n, String scaleId) {
    return switch (scaleId) {
      'minor' => pickUiText(i18n, zh: '灏忚皟', en: 'Minor'),
      'dorian' => pickUiText(i18n, zh: '多利亚', en: 'Dorian'),
      'lydian' => pickUiText(i18n, zh: '利底亚', en: 'Lydian'),
      'harmonic_minor' => pickUiText(i18n, zh: '鍜屽０灏忚皟', en: 'Harmonic minor'),
      'pentatonic' => pickUiText(i18n, zh: '浜斿０闊抽樁', en: 'Pentatonic'),
      'chromatic' => pickUiText(i18n, zh: '半音阶', en: 'Chromatic'),
      _ => pickUiText(i18n, zh: '澶ц皟', en: 'Major'),
    };
  }

  // ignore: unused_element
  String _displayChordLabel(AppI18n i18n, String chordId) {
    return switch (chordId) {
      'major' => pickUiText(i18n, zh: '澶т笁鍜屽鸡', en: 'Major'),
      'minor' => pickUiText(i18n, zh: '灏忎笁鍜屽鸡', en: 'Minor'),
      'sus2' => pickUiText(i18n, zh: '鎸備簩', en: 'Sus2'),
      'maj7' => pickUiText(i18n, zh: '澶т竷', en: 'Maj7'),
      'm7' => pickUiText(i18n, zh: '灏忎竷', en: 'm7'),
      'add9' => pickUiText(i18n, zh: '鍔犱節', en: 'Add9'),
      _ => pickUiText(i18n, zh: '鍗曢煶', en: 'Single note'),
    };
  }

  // ignore: unused_element
  String _displayKeyboardStyleLabel(AppI18n i18n, _PianoKeyboardStyle style) {
    return switch (style.id) {
      'classic_bw' => pickUiText(
        i18n,
        zh: '缁忓吀榛戠櫧',
        en: 'Classic black & white',
      ),
      'midnight' => pickUiText(i18n, zh: '娣卞', en: 'Midnight'),
      'mist' => pickUiText(i18n, zh: '钖勯浘', en: 'Mist'),
      _ => pickUiText(i18n, zh: '璞＄墮', en: 'Ivory'),
    };
  }

  // ignore: unused_element
  String _displayTouchLabel(AppI18n i18n) {
    return pickUiText(
      i18n,
      zh: '瑙﹂敭 ${(100 * _touch).round()}%',
      en: 'Touch ${(100 * _touch).round()}%',
    );
  }

  // ignore: unused_element
  String _displaySpaceLabel(AppI18n i18n) {
    return pickUiText(
      i18n,
      zh: '绌洪棿 ${(_reverb * 100).round()}%',
      en: 'Space ${(_reverb * 100).round()}%',
    );
  }

  // ignore: unused_element
  String _displayDecayLabel(AppI18n i18n) {
    return pickUiText(
      i18n,
      zh: '寤堕煶 ${_decay.toStringAsFixed(2)}x',
      en: 'Decay ${_decay.toStringAsFixed(2)}x',
    );
  }

  String _displayPresetSubtitleFixed(AppI18n i18n, _PianoPreset preset) {
    return switch (preset.id) {
      'upright_studio' => pickUiText(
        i18n,
        zh: '更贴近真实立式钢琴的木质共鸣与干净起音，适合日常练习。',
        en: 'Dryer wood resonance and cleaner attacks, closer to a real upright piano.',
      ),
      'bright_stage' => pickUiText(
        i18n,
        zh: '更锐利的击弦边缘，适合突出旋律和清晰起音。',
        en: 'Sharper hammer edge for lead lines and brighter attacks.',
      ),
      'felt_room' => pickUiText(
        i18n,
        zh: '毛毡包裹感更强，适合亲密和安静的演奏。',
        en: 'Softer felt body for intimate and quiet playing.',
      ),
      _ => pickUiText(
        i18n,
        zh: '延音与空间感更均衡，适合日常练习与编配。',
        en: 'Balanced sustain and room feel for all-purpose playing.',
      ),
    };
  }

  String _displayScaleLabelFixed(AppI18n i18n, String scaleId) {
    return switch (scaleId) {
      'minor' => pickUiText(i18n, zh: '小调', en: 'Minor'),
      'dorian' => pickUiText(i18n, zh: '多利亚', en: 'Dorian'),
      'lydian' => pickUiText(i18n, zh: '利底亚', en: 'Lydian'),
      'harmonic_minor' => pickUiText(i18n, zh: '和声小调', en: 'Harmonic minor'),
      'pentatonic' => pickUiText(i18n, zh: '五声音阶', en: 'Pentatonic'),
      'chromatic' => pickUiText(i18n, zh: '半音阶', en: 'Chromatic'),
      _ => pickUiText(i18n, zh: '大调', en: 'Major'),
    };
  }

  String _displayChordLabelFixed(AppI18n i18n, String chordId) {
    return switch (chordId) {
      'major' => pickUiText(i18n, zh: '大三和弦', en: 'Major'),
      'minor' => pickUiText(i18n, zh: '小三和弦', en: 'Minor'),
      'sus2' => pickUiText(i18n, zh: '挂二', en: 'Sus2'),
      'maj7' => pickUiText(i18n, zh: '大七', en: 'Maj7'),
      'm7' => pickUiText(i18n, zh: '小七', en: 'm7'),
      'add9' => pickUiText(i18n, zh: '加九', en: 'Add9'),
      _ => pickUiText(i18n, zh: '单音', en: 'Single note'),
    };
  }

  String _displayKeyboardStyleLabelFixed(
    AppI18n i18n,
    _PianoKeyboardStyle style,
  ) {
    return switch (style.id) {
      'classic_bw' => pickUiText(i18n, zh: '经典黑白', en: 'Classic black & white'),
      'midnight' => pickUiText(i18n, zh: '深夜', en: 'Midnight'),
      'mist' => pickUiText(i18n, zh: '薄雾', en: 'Mist'),
      _ => pickUiText(i18n, zh: '象牙', en: 'Ivory'),
    };
  }

  String _displayTouchLabelFixed(AppI18n i18n) {
    return pickUiText(
      i18n,
      zh: '触键 ${(100 * _touch).round()}%',
      en: 'Touch ${(100 * _touch).round()}%',
    );
  }

  String _displaySpaceLabelFixed(AppI18n i18n) {
    return pickUiText(
      i18n,
      zh: '空间 ${(_reverb * 100).round()}%',
      en: 'Space ${(_reverb * 100).round()}%',
    );
  }

  String _displayDecayLabelFixed(AppI18n i18n) {
    return pickUiText(
      i18n,
      zh: '延音 ${_decay.toStringAsFixed(2)}x',
      en: 'Decay ${_decay.toStringAsFixed(2)}x',
    );
  }

  String _rangeRegisterNameFixed(
    AppI18n i18n,
    int startOctave,
    int octaveSpan,
  ) {
    final endOctave = startOctave + octaveSpan;
    if (endOctave <= 2) {
      return pickUiText(i18n, zh: '低音区', en: 'Bass');
    }
    if (startOctave <= 1 && endOctave <= 4) {
      return pickUiText(i18n, zh: '次中音区', en: 'Baritone');
    }
    if (startOctave <= 3 && endOctave <= 5) {
      return pickUiText(i18n, zh: '中音区', en: 'Tenor');
    }
    if (startOctave <= 4 && endOctave <= 6) {
      return pickUiText(i18n, zh: '次高音区', en: 'Alto');
    }
    return pickUiText(i18n, zh: '高音区', en: 'Soprano');
  }

  String _rangeWindowLabelFixed(AppI18n i18n, int startOctave, int octaveSpan) {
    return '${_rangeRegisterNameFixed(i18n, startOctave, octaveSpan)} · '
        '${_rangeLeadingLabel(startOctave)}-${_rangeTrailingLabel(startOctave, octaveSpan)}';
  }

  String _rangeLeadingLabel(int startOctave) {
    if (startOctave <= 0) {
      return 'A0';
    }
    return 'C$startOctave';
  }

  String _rangeTrailingLabel(int startOctave, int octaveSpan) {
    final endOctave = (startOctave + octaveSpan).clamp(0, 8);
    return 'C$endOctave';
  }

  // ignore: unused_element
  String _rangeRegisterName(AppI18n i18n, int startOctave, int octaveSpan) {
    final endOctave = startOctave + octaveSpan;
    if (endOctave <= 2) {
      return pickUiText(i18n, zh: '低音区', en: 'Bass');
    }
    if (startOctave <= 1 && endOctave <= 4) {
      return pickUiText(i18n, zh: '娆′腑闊冲尯', en: 'Baritone');
    }
    if (startOctave <= 3 && endOctave <= 5) {
      return pickUiText(i18n, zh: '中音区', en: 'Tenor');
    }
    if (startOctave <= 4 && endOctave <= 6) {
      return pickUiText(i18n, zh: '娆￠珮闊冲尯', en: 'Alto');
    }
    return pickUiText(i18n, zh: '高音区', en: 'Soprano');
  }

  // ignore: unused_element
  String _rangeWindowLabel(AppI18n i18n, int startOctave, int octaveSpan) {
    return '${_rangeRegisterNameFixed(i18n, startOctave, octaveSpan)} · '
        '${_rangeLeadingLabel(startOctave)}-${_rangeTrailingLabel(startOctave, octaveSpan)}';
  }

  String _rangeWindowLabelPlain(int startOctave, int octaveSpan) {
    return '${_rangeLeadingLabel(startOctave)}-${_rangeTrailingLabel(startOctave, octaveSpan)}';
  }

  void _invalidatePlayers({bool warmUp = true}) {
    for (final player in _players.values) {
      unawaited(player.dispose());
    }
    _players.clear();
    if (warmUp) {
      unawaited(_warmUpVisibleWindow());
    }
  }

  void _applyPreset(String presetId) {
    final preset = _presets.firstWhere(
      (item) => item.id == presetId,
      orElse: () => _presets.first,
    );
    if (_presetId == preset.id) {
      return;
    }
    setState(() {
      _presetId = preset.id;
      _touch = preset.touch;
      _reverb = preset.reverb;
      _decay = preset.decay;
    });
    _invalidatePlayers();
  }

  void _toggleRangeNavigatorLayout() {
    setState(() {
      _rangeNavigatorExpanded = !_rangeNavigatorExpanded;
    });
  }

  void _toggleDualKeyboardMode() {
    setState(() {
      _dualKeyboardMode = !_dualKeyboardMode;
    });
  }

  void _openFullScreen(BuildContext context) {
    if (widget.fullScreen) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(
          backgroundColor: Colors.black,
          body: _PianoTool(fullScreen: true),
        ),
      ),
    );
  }

  Future<void> _warmUpVisibleWindow({int? octaveSpan, int? rangeStart}) async {
    final span = octaveSpan ?? 1;
    final start = (rangeStart ?? _rangeStartOctave).clamp(
      0,
      _maxRangeStart(span),
    );
    final slice = _sliceFor(start, span);
    final candidates = <_PianoKey>[
      if (slice.whiteKeys.isNotEmpty) slice.whiteKeys.first,
      if (slice.whiteKeys.isNotEmpty)
        slice.whiteKeys[slice.whiteKeys.length ~/ 2],
      if (slice.blackKeys.isNotEmpty)
        slice.blackKeys[slice.blackKeys.length ~/ 2].key,
      if (slice.whiteKeys.isNotEmpty) slice.whiteKeys.last,
    ];
    final visited = <String>{};
    for (final key in candidates) {
      if (!visited.add(key.id)) {
        continue;
      }
      await _playerFor(key).warmUp();
    }
  }

  ToolboxEffectPlayer _playerFor(_PianoKey key) {
    final styleId = _activePreset.styleId;
    final cacheKey =
        '${key.id}:$styleId:${_reverb.toStringAsFixed(2)}:${_decay.toStringAsFixed(2)}';
    final existing = _players[cacheKey];
    if (existing != null) {
      return existing;
    }
    final created = ToolboxEffectPlayer(
      ToolboxAudioBank.pianoNote(
        key.frequency,
        style: styleId,
        reverb: _reverb,
        decay: _decay,
      ),
      maxPlayers: 8,
    );
    _players[cacheKey] = created;
    return created;
  }

  int _maxRangeStart(int octaveSpan) {
    return math.max(0, 8 - octaveSpan);
  }

  void _updateRangeStart(int nextStart, int octaveSpan) {
    final normalized = nextStart.clamp(0, _maxRangeStart(octaveSpan));
    if (_rangeStartOctave == normalized) {
      return;
    }
    setState(() {
      _rangeStartOctave = normalized;
    });
    unawaited(
      _warmUpVisibleWindow(octaveSpan: octaveSpan, rangeStart: normalized),
    );
  }

  Offset _activePointerCentroid() {
    final values = _activePointers.values.toList(growable: false);
    if (values.isEmpty) {
      return Offset.zero;
    }
    var sumX = 0.0;
    var sumY = 0.0;
    for (final offset in values) {
      sumX += offset.dx;
      sumY += offset.dy;
    }
    return Offset(sumX / values.length, sumY / values.length);
  }

  Set<String> _highlightedPitchClasses() {
    final rootIndex = _rootPitchClasses.indexOf(_rootPitchClass);
    final highlights = <String>{};
    for (final interval in _activeScaleSet.intervals) {
      highlights.add(_rootPitchClasses[(rootIndex + interval) % 12]);
    }
    for (final interval in _activeChordSpec.highlightIntervals) {
      highlights.add(_rootPitchClasses[(rootIndex + interval) % 12]);
    }
    return highlights;
  }

  List<_PianoKey> _voicedKeysFor(_PianoKey rootKey) {
    final voiced = <_PianoKey>[];
    final seen = <String>{};
    for (final interval in _activeChordSpec.voicedIntervals) {
      final midi = rootKey.midi + interval;
      _PianoKey? key;
      for (final candidate in _allKeys) {
        if (candidate.midi == midi) {
          key = candidate;
          break;
        }
      }
      if (key == null || !seen.add(key.id)) {
        continue;
      }
      voiced.add(key);
    }
    if (voiced.isEmpty) {
      voiced.add(rootKey);
    }
    return voiced;
  }

  double _volumeForVoicedIndex(int index, int total, double baseVolume) {
    if (total <= 1) {
      return baseVolume.clamp(0.0, 1.0);
    }
    final attenuation = index == 0
        ? 1.0
        : math.max(0.54, 0.92 - index * _chordFalloff);
    return (baseVolume * attenuation).clamp(0.0, 1.0).toDouble();
  }

  Future<void> _playKey(_PianoKey key, {double? volume}) async {
    final voicedKeys = _voicedKeysFor(key);
    final baseVolume = volume ?? _touch;
    HapticFeedback.selectionClick();
    for (var index = 0; index < voicedKeys.length; index += 1) {
      final note = voicedKeys[index];
      final waitMs = (_activeChordSpec.staggerMs * _chordSpreadScale * index)
          .round();
      final noteVolume = _volumeForVoicedIndex(
        index,
        voicedKeys.length,
        baseVolume,
      );
      unawaited(
        Future<void>.delayed(Duration(milliseconds: waitMs), () async {
          await _playerFor(note).play(volume: noteVolume);
        }),
      );
    }
    if (!mounted) {
      return;
    }
    setState(() {
      for (final note in voicedKeys) {
        _activeKeyPulseCounts.update(
          note.id,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
      _activeKeyIds = _activeKeyPulseCounts.keys.toSet();
    });
    Future<void>.delayed(const Duration(milliseconds: 170), () {
      if (!mounted) {
        return;
      }
      setState(() {
        for (final note in voicedKeys) {
          final count = _activeKeyPulseCounts[note.id];
          if (count == null) {
            continue;
          }
          if (count <= 1) {
            _activeKeyPulseCounts.remove(note.id);
          } else {
            _activeKeyPulseCounts[note.id] = count - 1;
          }
        }
        _activeKeyIds = _activeKeyPulseCounts.keys.toSet();
      });
    });
  }

  void _handleStagePointerDown(
    PointerDownEvent event, {
    required _PianoStageMetrics metrics,
    required _PianoKeyboardSlice slice,
    required int octaveSpan,
  }) {
    _activePointers[event.pointer] = event.localPosition;
    final key = metrics.hitTest(slice, event.localPosition);
    if (key != null) {
      _activePointerKeyIds[event.pointer] = key.id;
      unawaited(
        _playKey(
          key,
          volume: _touchVolumeForPosition(
            key,
            event.localPosition,
            metrics,
            slice,
          ),
        ),
      );
    }
    if (_activePointers.length >= 2) {
      _twoFingerOrigin = _activePointerCentroid();
    }
  }

  void _handleStagePointerMove(
    PointerMoveEvent event, {
    required _PianoStageMetrics metrics,
    required _PianoKeyboardSlice slice,
    required int octaveSpan,
  }) {
    if (!_activePointers.containsKey(event.pointer)) {
      return;
    }
    _activePointers[event.pointer] = event.localPosition;
    if (_activePointers.length >= 2) {
      final centroid = _activePointerCentroid();
      final origin = _twoFingerOrigin ?? centroid;
      final delta = centroid - origin;
      final verticalThreshold = widget.fullScreen ? 34.0 : 54.0;
      final horizontalThreshold = widget.fullScreen ? 56.0 : 72.0;
      if (delta.dy.abs() >= verticalThreshold &&
          delta.dy.abs() >= delta.dx.abs() * 0.9) {
        final stepCount = (delta.dy.abs() / verticalThreshold).floor();
        final direction = delta.dy < 0 ? 1 : -1;
        _updateRangeStart(
          _rangeStartOctave + direction * stepCount,
          octaveSpan,
        );
        _twoFingerOrigin = centroid;
      } else if (delta.dx.abs() >= horizontalThreshold) {
        final stepCount = (delta.dx.abs() / horizontalThreshold).floor();
        final direction = delta.dx < 0 ? 1 : -1;
        _updateRangeStart(
          _rangeStartOctave + direction * stepCount,
          octaveSpan,
        );
        _twoFingerOrigin = centroid;
      }
      return;
    }
    final key = metrics.hitTest(slice, event.localPosition);
    final lastKeyId = _activePointerKeyIds[event.pointer];
    if (key == null || key.id == lastKeyId) {
      return;
    }
    _activePointerKeyIds[event.pointer] = key.id;
    unawaited(
      _playKey(
        key,
        volume: _touchVolumeForPosition(
          key,
          event.localPosition,
          metrics,
          slice,
          glissando: true,
        ),
      ),
    );
  }

  void _handleStagePointerUp(PointerEvent event) {
    _activePointers.remove(event.pointer);
    _activePointerKeyIds.remove(event.pointer);
    if (_activePointers.length < 2) {
      _twoFingerOrigin = null;
    }
  }

  double _touchVolumeForPosition(
    _PianoKey key,
    Offset localPosition,
    _PianoStageMetrics metrics,
    _PianoKeyboardSlice slice, {
    bool glissando = false,
  }) {
    final rect = metrics.rectForKey(slice, key);
    if (rect == null || rect.width <= 0 || rect.height <= 0) {
      return (glissando ? _touch * 0.92 : _touch).clamp(0.18, 1.0).toDouble();
    }
    final depth = ((localPosition.dx - rect.left) / rect.width)
        .clamp(0.0, 1.0)
        .toDouble();
    final heightRatio = ((localPosition.dy - rect.top) / rect.height)
        .clamp(0.0, 1.0)
        .toDouble();
    final depthEnergy = key.isSharp ? 0.82 + depth * 0.18 : 0.62 + depth * 0.34;
    final centerControl = 1 - (heightRatio - 0.5).abs() * 0.18;
    final glideMul = glissando ? 0.92 : 1.0;
    return (_touch * depthEnergy * centerControl * glideMul)
        .clamp(0.18, 1.0)
        .toDouble();
  }

  _PianoKeyboardSlice _sliceFor(int startOctave, int octaveSpan) {
    final normalizedStart = startOctave.clamp(0, _maxRangeStart(octaveSpan));
    final startMidi = normalizedStart <= 0 ? 21 : _midiForC(normalizedStart);
    final endOctave = normalizedStart + octaveSpan;
    final endMidi = endOctave >= 8 ? 108 : _midiForC(endOctave);
    final chromatic = _allKeys
        .where((key) => key.midi >= startMidi && key.midi <= endMidi)
        .toList(growable: false);
    final whiteKeys = chromatic
        .where((key) => !key.isSharp)
        .toList(growable: false);
    final blackKeys = <_PianoBlackKeyPlacement>[];
    var whiteIndex = -1;
    for (final key in chromatic) {
      if (!key.isSharp) {
        whiteIndex += 1;
        continue;
      }
      if (whiteIndex >= 0 && whiteIndex < whiteKeys.length) {
        blackKeys.add(_PianoBlackKeyPlacement(key: key, slot: whiteIndex));
      }
    }
    return _PianoKeyboardSlice(
      whiteKeys: whiteKeys,
      blackKeys: blackKeys,
      label: _rangeWindowLabelPlain(normalizedStart, octaveSpan),
    );
  }

  _PianoViewportSpec _viewportFor(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final width = constraints.maxWidth;
    final targetHeight = widget.fullScreen
        ? math.max(420.0, screenHeight - viewPadding.vertical - 40)
        : math.min(math.max(320.0, screenHeight * 0.46), 520.0);
    var octaveSpan = widget.fullScreen
        ? width >= 940
              ? 5
              : width >= 680
              ? 4
              : 3
        : width >= 940
        ? 4
        : width >= 680
        ? 3
        : 2;
    final minWhiteExtent = widget.fullScreen ? 34.0 : 40.0;
    while (octaveSpan > 1) {
      final whiteCount = octaveSpan * 7 + 1;
      if (targetHeight / whiteCount >= minWhiteExtent) {
        break;
      }
      octaveSpan -= 1;
    }
    final whiteCount = octaveSpan * 7 + 1;
    final whiteKeyExtent = ((targetHeight / whiteCount) * _keyHeightScale)
        .clamp(minWhiteExtent, widget.fullScreen ? 76.0 : 64.0);
    return _PianoViewportSpec(
      octaveSpan: octaveSpan,
      whiteKeyExtent: whiteKeyExtent.toDouble(),
      stageHeight: whiteKeyExtent * whiteCount,
      compactLabels: width < 360 || whiteKeyExtent < 44,
    );
  }

  String _displayLabelForKey(_PianoKey key, _PianoViewportSpec viewport) {
    if (viewport.compactLabels && key.pitchClass != 'C') {
      return key.pitchClass;
    }
    return key.label;
  }

  Widget _buildRangeNavigator(
    BuildContext context,
    AppI18n i18n, {
    required int octaveSpan,
    required int rangeStart,
    required _PianoKeyboardSlice slice,
    required bool immersive,
  }) {
    final starts = List<int>.generate(
      _maxRangeStart(octaveSpan) + 1,
      (index) => index,
    );
    final labelColor = immersive ? Colors.white70 : null;
    final chipChildren = starts
        .map(
          (start) => Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 8),
            child: ChoiceChip(
              label: Text(_rangeWindowLabelFixed(i18n, start, octaveSpan)),
              selected: start == rangeStart,
              onSelected: (_) => _updateRangeStart(start, octaveSpan),
            ),
          ),
        )
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton.filledTonal(
              onPressed: rangeStart > 0
                  ? () => _updateRangeStart(rangeStart - 1, octaveSpan)
                  : null,
              style: immersive
                  ? IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.10),
                      foregroundColor: Colors.white,
                    )
                  : null,
              icon: const Icon(Icons.keyboard_arrow_up_rounded),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    pickUiText(i18n, zh: '褰撳墠闊冲煙', en: 'Current window'),
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: labelColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_rangeRegisterNameFixed(i18n, rangeStart, octaveSpan)} · ${slice.label}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: immersive ? Colors.white : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              onPressed: rangeStart < _maxRangeStart(octaveSpan)
                  ? () => _updateRangeStart(rangeStart + 1, octaveSpan)
                  : null,
              style: immersive
                  ? IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.10),
                      foregroundColor: Colors.white,
                    )
                  : null,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: _toggleRangeNavigatorLayout,
              style: immersive
                  ? IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.10),
                      foregroundColor: Colors.white,
                    )
                  : null,
              icon: Icon(
                _rangeNavigatorExpanded
                    ? Icons.view_stream_rounded
                    : Icons.view_day_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _rangeNavigatorExpanded
              ? Wrap(
                  key: const ValueKey<String>('range-wrap'),
                  children: chipChildren,
                )
              : SingleChildScrollView(
                  key: const ValueKey<String>('range-scroll'),
                  scrollDirection: Axis.horizontal,
                  child: Row(children: chipChildren),
                ),
        ),
      ],
    );
  }

  Widget _buildKeyboardStage(
    BuildContext context,
    _PianoKeyboardSlice slice, {
    required _PianoViewportSpec viewport,
    required bool immersive,
  }) {
    final style = _activeKeyboardStyle;
    final highlightedPitchClasses = _highlightedPitchClasses();
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.fullScreen ? 28 : 24),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[style.shellTop, style.shellBottom],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: style.sideGlow,
            blurRadius: immersive ? 28 : 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          widget.fullScreen ? 8 : 10,
          widget.fullScreen ? 10 : 12,
          widget.fullScreen ? 8 : 10,
          widget.fullScreen ? 10 : 12,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final metrics = _PianoStageMetrics(
              size: Size(constraints.maxWidth, viewport.stageHeight),
              whiteKeyExtent: viewport.whiteKeyExtent,
              blackKeyWidth: math.max(
                62.0,
                constraints.maxWidth * _blackKeyWidthRatio,
              ),
              blackKeyHeight: viewport.whiteKeyExtent * _blackKeyHeightRatio,
              blackKeyInset: math.max(4.0, constraints.maxWidth * 0.018),
            );
            return SizedBox(
              height: viewport.stageHeight,
              child: _ToolboxScrollLockSurface(
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (event) => _handleStagePointerDown(
                    event,
                    metrics: metrics,
                    slice: slice,
                    octaveSpan: viewport.octaveSpan,
                  ),
                  onPointerMove: (event) => _handleStagePointerMove(
                    event,
                    metrics: metrics,
                    slice: slice,
                    octaveSpan: viewport.octaveSpan,
                  ),
                  onPointerUp: _handleStagePointerUp,
                  onPointerCancel: _handleStagePointerUp,
                  child: Stack(
                    children: <Widget>[
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              widget.fullScreen ? 20 : 18,
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.10),
                            ),
                          ),
                        ),
                      ),
                      ...slice.whiteKeys.asMap().entries.map((entry) {
                        final index = entry.key;
                        final key = entry.value;
                        final isActive = _activeKeyIds.contains(key.id);
                        final isHighlighted = highlightedPitchClasses.contains(
                          key.pitchClass,
                        );
                        return Positioned(
                          left: 0,
                          right: 0,
                          top: metrics.whiteTopFor(index),
                          height: metrics.whiteKeyExtent,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.only(bottom: 1),
                            padding: EdgeInsets.fromLTRB(
                              14,
                              widget.fullScreen ? 10 : 8,
                              math.max(84, metrics.blackKeyWidth + 14),
                              widget.fullScreen ? 10 : 8,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.black.withValues(alpha: 0.10),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: <Color>[
                                  isActive
                                      ? theme.colorScheme.primaryContainer
                                      : isHighlighted
                                      ? style.whiteAccentTop
                                      : style.whiteTop,
                                  isActive
                                      ? theme.colorScheme.primary.withValues(
                                          alpha: 0.32,
                                        )
                                      : isHighlighted
                                      ? style.whiteAccentBottom
                                      : style.whiteBottom,
                                ],
                              ),
                            ),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  width: 5,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? theme.colorScheme.primary
                                        : isHighlighted
                                        ? style.blackAccentTop
                                        : Colors.black.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _displayLabelForKey(key, viewport),
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                if (!viewport.compactLabels)
                                  Text(
                                    key.pitchClass,
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: const Color(0xFF475569),
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                      ...slice.blackKeys.map((placement) {
                        final key = placement.key;
                        final isActive = _activeKeyIds.contains(key.id);
                        final isHighlighted = highlightedPitchClasses.contains(
                          key.pitchClass,
                        );
                        return Positioned(
                          right: metrics.blackKeyInset,
                          top: metrics.blackTopFor(placement.slot),
                          width: metrics.blackKeyWidth,
                          height: metrics.blackKeyHeight,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.10),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: <Color>[
                                  isActive
                                      ? const Color(0xFF2F56A6)
                                      : isHighlighted
                                      ? style.blackAccentTop
                                      : style.blackTop,
                                  isActive
                                      ? const Color(0xFF1A2E63)
                                      : isHighlighted
                                      ? style.blackAccentBottom
                                      : style.blackBottom,
                                ],
                              ),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.28),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              viewport.compactLabels
                                  ? key.pitchClass
                                  : key.label,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        );
                      }),
                      Positioned(
                        left: 6,
                        top: 6,
                        bottom: 6,
                        child: Container(
                          width: 2,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: style.railColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDualKeyboardStage(
    BuildContext context, {
    required _PianoViewportSpec viewport,
    required bool immersive,
  }) {
    final i18n = _toolboxI18n(context);
    final lowerOctaveSpan = viewport.octaveSpan;
    final lowerStart = _rangeStartOctave;
    final upperStart = math.min(
      lowerStart + lowerOctaveSpan,
      _maxRangeStart(lowerOctaveSpan),
    );

    final lowerSlice = _sliceFor(lowerStart, lowerOctaveSpan);
    final upperSlice = _sliceFor(upperStart, lowerOctaveSpan);

    return LayoutBuilder(
      builder: (context, constraints) {
        final keyboardWidth = (constraints.maxWidth - 8) / 2;
        final dualViewport = _PianoViewportSpec(
          octaveSpan: viewport.octaveSpan,
          whiteKeyExtent: viewport.whiteKeyExtent,
          stageHeight: viewport.stageHeight,
          compactLabels: viewport.compactLabels || keyboardWidth < 140,
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      pickUiText(i18n, zh: '高音区', en: 'High'),
                      style: TextStyle(
                        color: immersive ? Colors.white70 : null,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Flexible(
                    child: _buildKeyboardStage(
                      context,
                      upperSlice,
                      viewport: dualViewport,
                      immersive: immersive,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      pickUiText(i18n, zh: '低音区', en: 'Low'),
                      style: TextStyle(
                        color: immersive ? Colors.white70 : null,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Flexible(
                    child: _buildKeyboardStage(
                      context,
                      lowerSlice,
                      viewport: dualViewport,
                      immersive: immersive,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettingsSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildPianoSettingsContent(
    BuildContext context,
    AppI18n i18n, {
    required _PianoViewportSpec viewport,
    required _PianoKeyboardSlice slice,
    required void Function(VoidCallback mutation) applySettings,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          pickUiText(i18n, zh: '钢琴设置', en: 'Piano settings'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            ToolboxMetricCard(label: 'Range', value: slice.label),
            ToolboxMetricCard(
              label: 'Scale',
              value: _displayScaleLabelFixed(i18n, _scaleId),
            ),
            ToolboxMetricCard(
              label: 'Harmony',
              value: _displayChordLabelFixed(i18n, _chordId),
            ),
            ToolboxMetricCard(
              label: 'Style',
              value: _displayKeyboardStyleLabelFixed(
                i18n,
                _activeKeyboardStyle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildSettingsSectionTitle(
          context,
          pickUiText(i18n, zh: '预设包', en: 'Preset pack'),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presets
              .map(
                (item) => ChoiceChip(
                  label: Text(_displayPresetLabel(i18n, item)),
                  selected: item.id == _presetId,
                  onSelected: (_) => applySettings(() => _applyPreset(item.id)),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 10),
        Text(
          _displayPresetSubtitleFixed(i18n, _activePreset),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        _buildSettingsSectionTitle(
          context,
          pickUiText(i18n, zh: '键盘风格', en: 'Keyboard style'),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _keyboardStyles
              .map(
                (item) => ChoiceChip(
                  label: Text(_displayKeyboardStyleLabelFixed(i18n, item)),
                  selected: item.id == _keyboardStyleId,
                  onSelected: (_) => applySettings(() {
                    _keyboardStyleId = item.id;
                  }),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 20),
        _buildSettingsSectionTitle(
          context,
          pickUiText(i18n, zh: '触键与空间', en: 'Touch and space'),
        ),
        Text(_displayTouchLabelFixed(i18n), style: theme.textTheme.labelLarge),
        Slider(
          value: _touch,
          min: 0.55,
          max: 1.0,
          divisions: 18,
          onChanged: (value) => applySettings(() {
            _touch = value;
          }),
        ),
        Text(_displaySpaceLabelFixed(i18n), style: theme.textTheme.labelLarge),
        Slider(
          value: _reverb,
          min: 0.0,
          max: 0.55,
          divisions: 11,
          onChanged: (value) => applySettings(() {
            _reverb = value;
          }),
          onChangeEnd: (_) => _invalidatePlayers(),
        ),
        Text(_displayDecayLabelFixed(i18n), style: theme.textTheme.labelLarge),
        Slider(
          value: _decay,
          min: 0.7,
          max: 1.8,
          divisions: 22,
          onChanged: (value) => applySettings(() {
            _decay = value;
          }),
          onChangeEnd: (_) => _invalidatePlayers(),
        ),
        const SizedBox(height: 20),
        _buildSettingsSectionTitle(
          context,
          pickUiText(i18n, zh: '手机适配', en: 'Phone tuning'),
        ),
        Text(
          pickUiText(
            i18n,
            zh: '白键高度 ${(_keyHeightScale * 100).round()}%',
            en: 'Key height ${(_keyHeightScale * 100).round()}%',
          ),
          style: theme.textTheme.labelLarge,
        ),
        Slider(
          value: _keyHeightScale,
          min: 0.9,
          max: 1.12,
          divisions: 11,
          onChanged: (value) => applySettings(() {
            _keyHeightScale = value;
          }),
        ),
        Text(
          pickUiText(
            i18n,
            zh: '黑键宽度 ${(_blackKeyWidthRatio * 100).round()}%',
            en: 'Black key width ${(_blackKeyWidthRatio * 100).round()}%',
          ),
          style: theme.textTheme.labelLarge,
        ),
        Slider(
          value: _blackKeyWidthRatio,
          min: 0.28,
          max: 0.40,
          divisions: 12,
          onChanged: (value) => applySettings(() {
            _blackKeyWidthRatio = value;
          }),
        ),
        Text(
          pickUiText(
            i18n,
            zh: '黑键高度 ${(_blackKeyHeightRatio * 100).round()}%',
            en: 'Black key height ${(_blackKeyHeightRatio * 100).round()}%',
          ),
          style: theme.textTheme.labelLarge,
        ),
        Slider(
          value: _blackKeyHeightRatio,
          min: 0.58,
          max: 0.76,
          divisions: 9,
          onChanged: (value) => applySettings(() {
            _blackKeyHeightRatio = value;
          }),
        ),
        Text(
          pickUiText(
            i18n,
            zh: '和弦延迟 ${(_chordSpreadScale * 100).round()}%',
            en: 'Chord delay ${(_chordSpreadScale * 100).round()}%',
          ),
          style: theme.textTheme.labelLarge,
        ),
        Slider(
          value: _chordSpreadScale,
          min: 0.8,
          max: 1.6,
          divisions: 16,
          onChanged: (value) => applySettings(() {
            _chordSpreadScale = value;
          }),
        ),
        Text(
          pickUiText(
            i18n,
            zh: '和弦衰减 ${(_chordFalloff * 100).round()}%',
            en: 'Chord falloff ${(_chordFalloff * 100).round()}%',
          ),
          style: theme.textTheme.labelLarge,
        ),
        Slider(
          value: _chordFalloff,
          min: 0.08,
          max: 0.18,
          divisions: 10,
          onChanged: (value) => applySettings(() {
            _chordFalloff = value;
          }),
        ),
        const SizedBox(height: 20),
        _buildSettingsSectionTitle(
          context,
          pickUiText(i18n, zh: '调式与和声', en: 'Scale and harmony'),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _scaleSets
              .map(
                (item) => ChoiceChip(
                  label: Text(_displayScaleLabelFixed(i18n, item.id)),
                  selected: item.id == _scaleId,
                  onSelected: (_) => applySettings(() {
                    _scaleId = item.id;
                  }),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _chordSets
              .map(
                (item) => ChoiceChip(
                  label: Text(_displayChordLabelFixed(i18n, item.id)),
                  selected: item.id == _chordId,
                  onSelected: (_) => applySettings(() {
                    _chordId = item.id;
                  }),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _rootPitchClasses
                .map(
                  (pitchClass) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(pitchClass),
                      selected: pitchClass == _rootPitchClass,
                      onSelected: (_) => applySettings(() {
                        _rootPitchClass = pitchClass;
                      }),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        const SizedBox(height: 20),
        _buildSettingsSectionTitle(
          context,
          pickUiText(i18n, zh: '音域窗口', en: 'Range window'),
        ),
        Text(
          pickUiText(
            i18n,
            zh: '当前竖向舞台一次显示 ${viewport.octaveSpan} 个八度，支持快速切换音域，也支持分行展示全部窗口。',
            en: 'The vertical stage currently shows ${viewport.octaveSpan} octaves and supports quick range switching and wrapped rows.',
          ),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        _buildRangeNavigator(
          context,
          i18n,
          octaveSpan: viewport.octaveSpan,
          rangeStart: _rangeStartOctave.clamp(
            0,
            _maxRangeStart(viewport.octaveSpan),
          ),
          slice: slice,
          immersive: false,
        ),
      ],
    );
  }

  Future<void> _openPianoSettingsSheet(
    BuildContext context,
    AppI18n i18n, {
    required _PianoViewportSpec viewport,
    required _PianoKeyboardSlice slice,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            void applySettings(VoidCallback mutation) {
              if (!mounted) {
                return;
              }
              setState(mutation);
              setSheetState(() {});
            }

            final refreshedViewport = _viewportFor(
              context,
              BoxConstraints(
                maxWidth: MediaQuery.sizeOf(sheetContext).width - 32,
              ),
            );
            final refreshedRangeStart = _rangeStartOctave.clamp(
              0,
              _maxRangeStart(refreshedViewport.octaveSpan),
            );
            final refreshedSlice = _sliceFor(
              refreshedRangeStart,
              refreshedViewport.octaveSpan,
            );
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                4,
                16,
                16 + MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: SingleChildScrollView(
                child: _buildPianoSettingsContent(
                  sheetContext,
                  i18n,
                  viewport: refreshedViewport,
                  slice: refreshedSlice,
                  applySettings: applySettings,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPianoFullScreen(
    BuildContext context,
    AppI18n i18n, {
    required _PianoViewportSpec viewport,
    required _PianoKeyboardSlice slice,
    required int rangeStart,
  }) {
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final overlayButtonStyle = FilledButton.styleFrom(
      backgroundColor: Colors.black.withValues(alpha: 0.58),
      foregroundColor: Colors.white,
      elevation: 0,
      side: BorderSide(color: Colors.white.withValues(alpha: 0.24)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      visualDensity: VisualDensity.compact,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            _activeKeyboardStyle.shellTop,
            _activeKeyboardStyle.shellBottom,
            const Color(0xFF020617),
          ],
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                12,
                topInset + 56,
                12,
                bottomInset + 8,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: _dualKeyboardMode
                    ? _buildDualKeyboardStage(
                        context,
                        viewport: viewport,
                        immersive: true,
                      )
                    : _buildKeyboardStage(
                        context,
                        slice,
                        viewport: viewport,
                        immersive: true,
                      ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            top: topInset + 10,
            right: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.32),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.34),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: <Widget>[
                    FilledButton.tonal(
                      onPressed: () => Navigator.of(context).pop(),
                      style: overlayButtonStyle,
                      child: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: _toggleDualKeyboardMode,
                      style: overlayButtonStyle,
                      child: Icon(
                        _dualKeyboardMode
                            ? Icons.view_day_rounded
                            : Icons.view_stream_rounded,
                      ),
                    ),
                    const Spacer(),
                    FilledButton.tonalIcon(
                      onPressed: () => _openPianoSettingsSheet(
                        context,
                        i18n,
                        viewport: viewport,
                        slice: slice,
                      ),
                      style: overlayButtonStyle,
                      icon: const Icon(Icons.tune_rounded),
                      label: Text(pickUiText(i18n, zh: '设置', en: 'Settings')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _invalidatePlayers(warmUp: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = _viewportFor(context, constraints);
        final rangeStart = _rangeStartOctave.clamp(
          0,
          _maxRangeStart(viewport.octaveSpan),
        );
        final slice = _sliceFor(rangeStart, viewport.octaveSpan);
        if (widget.fullScreen) {
          return _buildPianoFullScreen(
            context,
            i18n,
            viewport: viewport,
            slice: slice,
            rangeStart: rangeStart,
          );
        }
        return _buildInstrumentPanelShell(
          context,
          fullScreen: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  ToolboxMetricCard(label: 'Keys', value: '${_allKeys.length}'),
                  const ToolboxMetricCard(label: 'Total range', value: 'A0-C8'),
                  ToolboxMetricCard(label: 'Window', value: slice.label),
                  ToolboxMetricCard(
                    label: 'Preset',
                    value: _displayPresetLabel(i18n, _activePreset),
                  ),
                  ToolboxMetricCard(
                    label: 'Harmony',
                    value: _displayChordLabelFixed(i18n, _chordId),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: SectionHeader(
                      title: pickUiText(
                        i18n,
                        zh: '纵向键盘',
                        en: 'Vertical keyboard',
                      ),
                      subtitle: pickUiText(
                        i18n,
                        zh: '键盘按手机竖屏高度展开，不再横向压缩，音域按真实阶位分段显示。',
                        en: 'The keyboard now expands down the phone height instead of being crushed horizontally.',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.tonalIcon(
                    onPressed: () => _openPianoSettingsSheet(
                      context,
                      i18n,
                      viewport: viewport,
                      slice: slice,
                    ),
                    icon: const Icon(Icons.tune_rounded),
                    label: Text(pickUiText(i18n, zh: '设置', en: 'Settings')),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: _toggleRangeNavigatorLayout,
                      icon: Icon(
                        _rangeNavigatorExpanded
                            ? Icons.view_stream_rounded
                            : Icons.view_day_rounded,
                      ),
                      label: Text(pickUiText(i18n, zh: '分行显示', en: 'Rows')),
                    ),
                    OutlinedButton.icon(
                      onPressed: _toggleDualKeyboardMode,
                      icon: Icon(
                        _dualKeyboardMode
                            ? Icons.view_stream_rounded
                            : Icons.view_day_rounded,
                      ),
                      label: Text(pickUiText(i18n, zh: '双键盘', en: 'Dual')),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _openFullScreen(context),
                      icon: const Icon(Icons.open_in_full_rounded),
                      label: Text(
                        pickUiText(i18n, zh: '全屏', en: 'Full screen'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _buildRangeNavigator(
                context,
                i18n,
                octaveSpan: viewport.octaveSpan,
                rangeStart: rangeStart,
                slice: slice,
                immersive: false,
              ),
              const SizedBox(height: 12),
              _dualKeyboardMode
                  ? _buildDualKeyboardStage(
                      context,
                      viewport: viewport,
                      immersive: false,
                    )
                  : _buildKeyboardStage(
                      context,
                      slice,
                      viewport: viewport,
                      immersive: false,
                    ),
              const SizedBox(height: 10),
              Text(
                pickUiText(
                  i18n,
                  zh: '单指可连续滑奏，双指上下滑动可跳转音域，双指左右滑动可快速切窗；开启分行显示后，可更快在手机上扫视全部音域选项。',
                  en: 'Single-finger glissando is supported, while two-finger vertical drags jump registers and horizontal drags switch windows.',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PianoKeyboardSlice {
  const _PianoKeyboardSlice({
    required this.whiteKeys,
    required this.blackKeys,
    required this.label,
  });

  final List<_PianoKey> whiteKeys;
  final List<_PianoBlackKeyPlacement> blackKeys;
  final String label;
}

class _PianoPitchSet {
  const _PianoPitchSet({required this.id, required this.intervals});

  final String id;
  final List<int> intervals;
}

class _PianoBlackKeyPlacement {
  const _PianoBlackKeyPlacement({required this.key, required this.slot});

  final _PianoKey key;
  final int slot;
}

class _PianoChordSpec {
  const _PianoChordSpec({
    required this.id,
    required this.highlightIntervals,
    required this.voicedIntervals,
    required this.staggerMs,
  });

  final String id;
  final List<int> highlightIntervals;
  final List<int> voicedIntervals;
  final int staggerMs;
}

class _PianoKeyboardStyle {
  const _PianoKeyboardStyle({
    required this.id,
    required this.whiteTop,
    required this.whiteBottom,
    required this.whiteAccentTop,
    required this.whiteAccentBottom,
    required this.blackTop,
    required this.blackBottom,
    required this.blackAccentTop,
    required this.blackAccentBottom,
    required this.shellTop,
    required this.shellBottom,
    required this.railColor,
    required this.sideGlow,
  });

  final String id;
  final Color whiteTop;
  final Color whiteBottom;
  final Color whiteAccentTop;
  final Color whiteAccentBottom;
  final Color blackTop;
  final Color blackBottom;
  final Color blackAccentTop;
  final Color blackAccentBottom;
  final Color shellTop;
  final Color shellBottom;
  final Color railColor;
  final Color sideGlow;
}

class _PianoViewportSpec {
  const _PianoViewportSpec({
    required this.octaveSpan,
    required this.whiteKeyExtent,
    required this.stageHeight,
    required this.compactLabels,
  });

  final int octaveSpan;
  final double whiteKeyExtent;
  final double stageHeight;
  final bool compactLabels;
}

class _PianoStageMetrics {
  const _PianoStageMetrics({
    required this.size,
    required this.whiteKeyExtent,
    required this.blackKeyWidth,
    required this.blackKeyHeight,
    required this.blackKeyInset,
  });

  final Size size;
  final double whiteKeyExtent;
  final double blackKeyWidth;
  final double blackKeyHeight;
  final double blackKeyInset;

  double whiteTopFor(int index) => index * whiteKeyExtent;

  double blackTopFor(int slot) {
    final top = whiteKeyExtent * (slot + 1) - blackKeyHeight / 2;
    return top.clamp(4.0, math.max(4.0, size.height - blackKeyHeight - 4.0));
  }

  Rect? rectForKey(_PianoKeyboardSlice slice, _PianoKey key) {
    if (key.isSharp) {
      for (final placement in slice.blackKeys) {
        if (placement.key.id != key.id) continue;
        return Rect.fromLTWH(
          size.width - blackKeyWidth - blackKeyInset,
          blackTopFor(placement.slot),
          blackKeyWidth,
          blackKeyHeight,
        );
      }
      return null;
    }
    final index = slice.whiteKeys.indexWhere((item) => item.id == key.id);
    if (index < 0) {
      return null;
    }
    return Rect.fromLTWH(0, whiteTopFor(index), size.width, whiteKeyExtent);
  }

  _PianoKey? hitTest(_PianoKeyboardSlice slice, Offset position) {
    if (position.dx < 0 ||
        position.dy < 0 ||
        position.dx > size.width ||
        position.dy > size.height) {
      return null;
    }
    for (final placement in slice.blackKeys.reversed) {
      final rect = Rect.fromLTWH(
        size.width - blackKeyWidth - blackKeyInset,
        blackTopFor(placement.slot),
        blackKeyWidth,
        blackKeyHeight,
      );
      if (rect.contains(position)) {
        return placement.key;
      }
    }
    final index = (position.dy / whiteKeyExtent).floor().clamp(
      0,
      slice.whiteKeys.length - 1,
    );
    return slice.whiteKeys[index];
  }
}

class _PianoOverlayChip extends StatelessWidget {
  const _PianoOverlayChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

int _midiForC(int octave) => _midiFromParts('C', octave);

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
