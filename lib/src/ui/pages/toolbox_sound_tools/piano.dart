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

  List<int> _windowStartWhiteIndices(int octaveSpan) {
    final whiteKeys = _activeKeyPool
        .where((key) => !key.isSharp)
        .toList(growable: false);
    final windowWhiteCount = octaveSpan * 7 + 1;
    if (whiteKeys.length <= windowWhiteCount) {
      return const <int>[0];
    }
    final maxStartWhite = whiteKeys.length - windowWhiteCount;
    final indices = <int>[0];
    for (var index = 7; index <= maxStartWhite; index += 7) {
      indices.add(index);
    }
    if (indices.last != maxStartWhite) {
      indices.add(maxStartWhite);
    }
    return indices;
  }

  String _windowLabelForIndex(int startIndex, int octaveSpan) {
    final whiteKeys = _activeKeyPool
        .where((key) => !key.isSharp)
        .toList(growable: false);
    if (whiteKeys.isEmpty) {
      return '--';
    }
    final starts = _windowStartWhiteIndices(octaveSpan);
    final normalized = startIndex.clamp(0, starts.length - 1);
    final startWhite = starts[normalized];
    final endWhite = (startWhite + octaveSpan * 7).clamp(
      0,
      whiteKeys.length - 1,
    );
    return '${whiteKeys[startWhite].label}-${whiteKeys[endWhite].label}';
  }

  String _noteLabelForMidi(int midi) {
    for (final key in _allKeys) {
      if (key.midi == midi) {
        return key.label;
      }
    }
    return _allKeys.first.label;
  }

  String _displayKeyLayoutLabel(AppI18n i18n, _PianoKeyLayoutPreset layout) {
    final endMidi = layout.startMidi + layout.keyCount - 1;
    return pickUiText(
      i18n,
      zh: '${layout.keyCount}键 ${_noteLabelForMidi(layout.startMidi)}-${_noteLabelForMidi(endMidi)}',
      en: '${layout.keyCount} keys ${_noteLabelForMidi(layout.startMidi)}-${_noteLabelForMidi(endMidi)}',
    );
  }

  String _displayPresetLabel(AppI18n i18n, _PianoPreset preset) {
    return switch (preset.id) {
      'upright_studio' => pickUiText(i18n, zh: '录音室立式', en: 'Studio upright'),
      'bright_stage' => pickUiText(i18n, zh: '明亮舞台', en: 'Bright stage'),
      'felt_room' => pickUiText(i18n, zh: '毛毡房间', en: 'Felt room'),
      _ => pickUiText(i18n, zh: '音乐厅', en: 'Concert hall'),
    };
  }

  String _displayPresetSubtitleFixed(AppI18n i18n, _PianoPreset preset) {
    return switch (preset.id) {
      'upright_studio' => pickUiText(
        i18n,
        zh: '更接近真实立式钢琴的木质共鸣与干净起音，适合日常练习。',
        en: 'Dryer wood resonance and cleaner attacks, closer to a real upright piano.',
      ),
      'bright_stage' => pickUiText(
        i18n,
        zh: '更锋利的击弦边缘，适合突出旋律和明亮起音。',
        en: 'Sharper hammer edge for lead lines and brighter attacks.',
      ),
      'felt_room' => pickUiText(
        i18n,
        zh: '毛毡包裹感更强，适合安静和亲密的演奏氛围。',
        en: 'Softer felt body for intimate and quiet playing.',
      ),
      _ => pickUiText(
        i18n,
        zh: '延音与空间感更均衡，适合通用演奏和编配。',
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
      'midnight' => pickUiText(i18n, zh: '午夜', en: 'Midnight'),
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

  String _displayGestureThresholdLabelFixed(AppI18n i18n) {
    return pickUiText(
      i18n,
      zh: '双指切窗灵敏度 ${(_gestureThresholdScale * 100).round()}%',
      en: 'Two-finger range sensitivity ${(_gestureThresholdScale * 100).round()}%',
    );
  }

  void _applyKeyLayoutById(String layoutId) {
    if (_keyLayoutId == layoutId) {
      return;
    }
    _keyLayoutId = layoutId;
    _rangeStartOctave = 0;
    _dualKeyboardMode = false;
    _compactDualFocus = _PianoCompactDeckFocus.low;
    _invalidatePlayers();
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

  void _toggleCompactKeyboardMode() {
    setState(() {
      _compactKeyboardMode = !_compactKeyboardMode;
    });
  }

  bool _isCompactPhoneWidth(double width) {
    return width < (widget.fullScreen ? 480 : 430);
  }

  bool _isUltraCompactPhoneWidth(double width) {
    return width < 380;
  }

  bool _isAggressiveOneHandWidth(double width) {
    return width >= 320 && width <= 390;
  }

  List<int> _quickRangeStarts(int octaveSpan) {
    final maxStart = _maxRangeStart(octaveSpan);
    final starts = <int>{0, (maxStart / 2).round(), maxStart};
    return starts.toList()..sort();
  }

  void _maybeApplyResponsiveDefaults(double width) {
    if (_didApplyResponsiveDefaults) {
      return;
    }
    _didApplyResponsiveDefaults = true;
    if (!_isCompactPhoneWidth(width)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _dualKeyboardMode = false;
        _compactKeyboardMode = true;
        _aggressiveOneHandMode = _isAggressiveOneHandWidth(width);
        if (_aggressiveOneHandMode) {
          _gestureThresholdScale = 0.9;
        }
        _compactDualFocus = _PianoCompactDeckFocus.low;
      });
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
    return math.max(0, _windowStartWhiteIndices(octaveSpan).length - 1);
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

  double _activePointerSpread() {
    final values = _activePointers.values.toList(growable: false);
    if (values.length < 2) {
      return 0.0;
    }
    var minX = values.first.dx;
    var maxX = values.first.dx;
    var minY = values.first.dy;
    var maxY = values.first.dy;
    for (final offset in values.skip(1)) {
      if (offset.dx < minX) {
        minX = offset.dx;
      }
      if (offset.dx > maxX) {
        maxX = offset.dx;
      }
      if (offset.dy < minY) {
        minY = offset.dy;
      }
      if (offset.dy > maxY) {
        maxY = offset.dy;
      }
    }
    final deltaX = maxX - minX;
    final deltaY = maxY - minY;
    return math.sqrt(deltaX * deltaX + deltaY * deltaY);
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
      for (final candidate in _activeKeyPool) {
        if (candidate.midi == midi) {
          key = candidate;
          break;
        }
      }
      for (final candidate in _allKeys) {
        if (key != null) {
          break;
        }
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
      final stageWidth = metrics.size.width;
      final aggressiveOneHand =
          _aggressiveOneHandMode && _isAggressiveOneHandWidth(stageWidth);
      final spread = _activePointerSpread();
      final minSpread = aggressiveOneHand ? 18.0 : 24.0;
      if (spread < minSpread) {
        return;
      }
      final centroid = _activePointerCentroid();
      final origin = _twoFingerOrigin ?? centroid;
      final delta = centroid - origin;
      final thresholdScale = _gestureThresholdScale.clamp(0.78, 1.28);
      final verticalThreshold = widget.fullScreen
          ? (aggressiveOneHand ? 22.0 : 28.0) * thresholdScale
          : (aggressiveOneHand ? 26.0 : 40.0) * thresholdScale;
      final horizontalThreshold = widget.fullScreen
          ? (aggressiveOneHand ? 34.0 : 42.0) *
                thresholdScale *
                (aggressiveOneHand ? 0.9 : 1.0)
          : (aggressiveOneHand ? 42.0 : 56.0) *
                thresholdScale *
                (aggressiveOneHand ? 0.9 : 1.0);
      final axisBias =
          ((aggressiveOneHand ? 0.76 : 0.9) +
                  (_gestureThresholdScale - 1.0) * 0.08)
              .clamp(0.7, 1.04)
              .toDouble();
      final rangeSwitchCooldownMs = aggressiveOneHand ? 68 : 86;
      bool allowSwitch() {
        final now = DateTime.now();
        final last = _lastRangeGestureAt;
        if (last != null &&
            now.difference(last).inMilliseconds < rangeSwitchCooldownMs) {
          return false;
        }
        _lastRangeGestureAt = now;
        return true;
      }

      if (delta.dy.abs() >= verticalThreshold &&
          delta.dy.abs() >= delta.dx.abs() * axisBias) {
        final stepCount = (delta.dy.abs() / verticalThreshold).floor();
        if (stepCount <= 0 || !allowSwitch()) {
          return;
        }
        final direction = delta.dy < 0 ? 1 : -1;
        _updateRangeStart(
          _rangeStartOctave + direction * stepCount,
          octaveSpan,
        );
        _twoFingerOrigin = centroid;
      } else if (delta.dx.abs() >= horizontalThreshold) {
        final stepCount = (delta.dx.abs() / horizontalThreshold).floor();
        if (stepCount <= 0 || !allowSwitch()) {
          return;
        }
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
      _lastRangeGestureAt = null;
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

  String _compactFocusLabel(AppI18n i18n, _PianoCompactDeckFocus focus) {
    return switch (focus) {
      _PianoCompactDeckFocus.high => pickUiText(i18n, zh: '高音', en: 'High'),
      _ => pickUiText(i18n, zh: '低音', en: 'Low'),
    };
  }

  _PianoKeyboardSlice _sliceFor(int startOctave, int octaveSpan) {
    final chromaticPool = _activeKeyPool;
    final whitePool = chromaticPool
        .where((key) => !key.isSharp)
        .toList(growable: false);
    if (whitePool.isEmpty) {
      return const _PianoKeyboardSlice(
        whiteKeys: <_PianoKey>[],
        blackKeys: <_PianoBlackKeyPlacement>[],
        label: '--',
      );
    }
    final starts = _windowStartWhiteIndices(octaveSpan);
    final normalizedStart = startOctave.clamp(0, starts.length - 1);
    final startWhite = starts[normalizedStart];
    final endWhite = (startWhite + octaveSpan * 7).clamp(
      0,
      whitePool.length - 1,
    );
    final startMidi = whitePool[startWhite].midi;
    final endMidi = whitePool[endWhite].midi;
    final chromatic = chromaticPool
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
      label: '${whitePool[startWhite].label}-${whitePool[endWhite].label}',
    );
  }

  _PianoViewportSpec _viewportFor(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final width = constraints.maxWidth;
    final aggressiveOneHand =
        _aggressiveOneHandMode && _isAggressiveOneHandWidth(width);
    final compactWidth = _isCompactPhoneWidth(width);
    final denseMode =
        (_compactKeyboardMode || (compactWidth && widget.fullScreen)) &&
        !aggressiveOneHand;
    final targetHeight = widget.fullScreen
        ? math.max(420.0, screenHeight - viewPadding.vertical - 40)
        : aggressiveOneHand
        ? math.min(math.max(360.0, screenHeight * 0.52), 560.0)
        : math.min(math.max(320.0, screenHeight * 0.46), 520.0);
    var octaveSpan = widget.fullScreen
        ? width >= 940
              ? 5
              : width >= 680
              ? 4
              : 3
        : denseMode
        ? (width >= 940
              ? 5
              : width >= 680
              ? 4
              : 3)
        : (width >= 940
              ? 4
              : width >= 680
              ? 3
              : 2);
    if (aggressiveOneHand) {
      octaveSpan = math.min(octaveSpan, 2);
    }
    final minWhiteExtent = widget.fullScreen
        ? (denseMode ? 28.0 : 34.0)
        : aggressiveOneHand
        ? 46.0
        : (denseMode ? 28.0 : 40.0);
    while (octaveSpan > 1) {
      final whiteCount = octaveSpan * 7 + 1;
      if (targetHeight / whiteCount >= minWhiteExtent) {
        break;
      }
      octaveSpan -= 1;
    }
    final whiteCount = octaveSpan * 7 + 1;
    final scaledKeyHeight = _keyHeightScale * (denseMode ? 0.88 : 1.0);
    final whiteKeyExtent = ((targetHeight / whiteCount) * scaledKeyHeight)
        .clamp(minWhiteExtent, widget.fullScreen ? 72.0 : 64.0);
    final ultraCompact = _isUltraCompactPhoneWidth(width);
    return _PianoViewportSpec(
      octaveSpan: octaveSpan,
      whiteKeyExtent: whiteKeyExtent.toDouble(),
      stageHeight: whiteKeyExtent * whiteCount,
      compactLabels: ultraCompact || width < 360 || whiteKeyExtent < 44,
    );
  }

  String _displayLabelForKey(_PianoKey key, _PianoViewportSpec viewport) {
    if (viewport.compactLabels && key.pitchClass != 'C') {
      return key.pitchClass;
    }
    return key.label;
  }

  Widget _buildKeyLayoutPickerButton(
    BuildContext context,
    AppI18n i18n, {
    bool immersive = false,
    bool compact = false,
  }) {
    final theme = Theme.of(context);
    final foregroundColor = immersive
        ? Colors.white
        : theme.colorScheme.onSurface;
    final borderColor = immersive
        ? Colors.white.withValues(alpha: 0.24)
        : theme.colorScheme.outlineVariant;
    final backgroundColor = immersive
        ? Colors.white.withValues(alpha: 0.08)
        : theme.colorScheme.surfaceContainerHighest;
    return PopupMenuButton<String>(
      tooltip: pickUiText(i18n, zh: '切换键盘键数', en: 'Change key layout'),
      onSelected: (layoutId) {
        setState(() {
          _applyKeyLayoutById(layoutId);
        });
      },
      itemBuilder: (menuContext) {
        return _keyLayouts
            .map(
              (layout) => PopupMenuItem<String>(
                value: layout.id,
                child: Text(_displayKeyLayoutLabel(i18n, layout)),
              ),
            )
            .toList(growable: false);
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          color: backgroundColor,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 9 : 11,
            vertical: compact ? 7 : 9,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.piano_rounded,
                size: compact ? 16 : 18,
                color: foregroundColor,
              ),
              const SizedBox(width: 6),
              Text(
                pickUiText(
                  i18n,
                  zh: '${_activeKeyLayout.keyCount}键',
                  en: '${_activeKeyLayout.keyCount} keys',
                ),
                style:
                    (compact
                            ? theme.textTheme.labelLarge
                            : theme.textTheme.bodyMedium)
                        ?.copyWith(
                          color: foregroundColor,
                          fontWeight: FontWeight.w700,
                        ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_drop_down_rounded,
                color: foregroundColor,
                size: compact ? 18 : 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRangeNavigator(
    BuildContext context,
    AppI18n i18n, {
    required int octaveSpan,
    required int rangeStart,
    required _PianoKeyboardSlice slice,
    required bool immersive,
    bool aggressiveOneHand = false,
  }) {
    final ultraCompact = _isUltraCompactPhoneWidth(
      MediaQuery.sizeOf(context).width,
    );
    final theme = Theme.of(context);
    final maxStart = _maxRangeStart(octaveSpan);
    final quickStarts = _quickRangeStarts(octaveSpan);
    final starts = List<int>.generate(maxStart + 1, (index) => index);
    final labelColor = immersive ? Colors.white70 : null;
    final pickerTextColor = immersive
        ? Colors.white
        : theme.colorScheme.onSurface;
    final pickerBorderColor = immersive
        ? Colors.white.withValues(alpha: 0.24)
        : theme.colorScheme.outlineVariant;
    final pickerBackgroundColor = immersive
        ? Colors.white.withValues(alpha: 0.08)
        : theme.colorScheme.surfaceContainerHighest;
    final chipChildren = starts
        .map(
          (start) => Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 8),
            child: ChoiceChip(
              label: Text(_windowLabelForIndex(start, octaveSpan)),
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
                    pickUiText(i18n, zh: '当前窗口', en: 'Current window'),
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: labelColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ultraCompact
                        ? slice.label
                        : '${slice.label} · ${rangeStart + 1}/${maxStart + 1}',
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
              onPressed: rangeStart < maxStart
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
        if (maxStart > 0) ...<Widget>[
          const SizedBox(height: 6),
          if (aggressiveOneHand)
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    pickUiText(i18n, zh: '快速跳转', en: 'Quick jump'),
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: labelColor),
                  ),
                ),
                PopupMenuButton<int>(
                  onSelected: (value) => _updateRangeStart(value, octaveSpan),
                  itemBuilder: (menuContext) {
                    return starts
                        .map(
                          (start) => PopupMenuItem<int>(
                            value: start,
                            child: Text(
                              _windowLabelForIndex(start, octaveSpan),
                            ),
                          ),
                        )
                        .toList(growable: false);
                  },
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: pickerBorderColor),
                      color: pickerBackgroundColor,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.swap_vert_rounded,
                            size: 18,
                            color: pickerTextColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            pickUiText(i18n, zh: '选择窗口', en: 'Choose window'),
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: pickerTextColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: <Widget>[
                Text(
                  pickUiText(i18n, zh: '快速跳转', en: 'Quick jump'),
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: labelColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Slider(
                    value: rangeStart.toDouble(),
                    min: 0,
                    max: maxStart.toDouble(),
                    divisions: maxStart,
                    label: slice.label,
                    onChanged: (value) =>
                        _updateRangeStart(value.round(), octaveSpan),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 2),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: quickStarts
                .map(
                  (start) => ChoiceChip(
                    label: Text(_windowLabelForIndex(start, octaveSpan)),
                    selected: start == rangeStart,
                    onSelected: (_) => _updateRangeStart(start, octaveSpan),
                  ),
                )
                .toList(growable: false),
          ),
        ],
        if (!aggressiveOneHand) ...<Widget>[
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
      ],
    );
  }

  Widget _buildKeyboardStage(
    BuildContext context,
    _PianoKeyboardSlice slice, {
    required _PianoViewportSpec viewport,
    required bool immersive,
    bool hideWhiteLabels = false,
    bool hideBlackLabels = false,
    double shellOpacity = 1.0,
    bool highlightFrame = false,
    bool isDualMode = false,
    bool aggressiveOneHand = false,
  }) {
    final style = _activeKeyboardStyle;
    final highlightedPitchClasses = _highlightedPitchClasses();
    final theme = Theme.of(context);
    final compactPhone = _isCompactPhoneWidth(MediaQuery.sizeOf(context).width);

    final shellGradientColors = isDualMode
        ? <Color>[Colors.transparent, Colors.transparent]
        : <Color>[
            style.shellTop.withValues(alpha: shellOpacity),
            style.shellBottom.withValues(alpha: shellOpacity),
          ];

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          widget.fullScreen ? 28 : (isDualMode ? 20 : 24),
        ),
        border: highlightFrame
            ? Border.all(color: const Color(0xFFBFD6FF), width: 1.6)
            : Border.all(
                color: Colors.white.withValues(alpha: isDualMode ? 0.20 : 0.10),
                width: isDualMode ? 1.0 : 1.0,
              ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: shellGradientColors,
        ),
        boxShadow: isDualMode
            ? null
            : <BoxShadow>[
                BoxShadow(
                  color: style.sideGlow.withValues(alpha: shellOpacity * 0.9),
                  blurRadius: immersive ? 28 : 18,
                  offset: const Offset(0, 12),
                ),
              ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          widget.fullScreen ? 8 : (isDualMode ? 8 : 10),
          widget.fullScreen ? 10 : (isDualMode ? 8 : 12),
          widget.fullScreen ? 8 : (isDualMode ? 8 : 10),
          widget.fullScreen ? 10 : (isDualMode ? 8 : 12),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrowStage = _isCompactPhoneWidth(constraints.maxWidth);
            final adaptiveBlackWidthRatio = isDualMode
                ? (narrowStage ? 0.30 : _blackKeyWidthRatio.clamp(0.30, 0.40))
                : aggressiveOneHand
                ? _blackKeyWidthRatio.clamp(0.38, 0.46)
                : _blackKeyWidthRatio;
            final adaptiveBlackHeightRatio = (isDualMode && narrowStage)
                ? (_blackKeyHeightRatio * 0.90).clamp(0.44, 0.70)
                : aggressiveOneHand
                ? _blackKeyHeightRatio.clamp(0.72, 0.86)
                : _blackKeyHeightRatio;
            final metrics = _PianoStageMetrics(
              size: Size(constraints.maxWidth, viewport.stageHeight),
              whiteKeyExtent: viewport.whiteKeyExtent,
              blackKeyWidth: (constraints.maxWidth * adaptiveBlackWidthRatio)
                  .clamp(
                    aggressiveOneHand ? 58.0 : (narrowStage ? 44.0 : 54.0),
                    aggressiveOneHand ? 132.0 : (narrowStage ? 86.0 : 108.0),
                  ),
              blackKeyHeight:
                  (viewport.whiteKeyExtent * adaptiveBlackHeightRatio).clamp(
                    16.0,
                    viewport.whiteKeyExtent,
                  ),
              blackKeyInset: aggressiveOneHand
                  ? 2.0
                  : narrowStage
                  ? 3.0
                  : math.max(4.0, constraints.maxWidth * 0.018),
              blackKeyHitPadding: aggressiveOneHand
                  ? 16
                  : narrowStage
                  ? 12
                  : 6,
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
                        final keyBorderRadius = isDualMode ? 14.0 : 18.0;
                        final keyMargin = isDualMode
                            ? (compactPhone ? 0.35 : 0.5)
                            : 1.0;
                        final labelPadding = EdgeInsets.fromLTRB(
                          isDualMode ? (compactPhone ? 8 : 10) : 14,
                          widget.fullScreen ? 10 : (isDualMode ? 6 : 8),
                          math.max(
                            isDualMode ? 52 : 84,
                            metrics.blackKeyWidth +
                                (isDualMode
                                    ? (compactPhone ? 8 : 10)
                                    : (aggressiveOneHand ? 20 : 14)),
                          ),
                          widget.fullScreen ? 10 : (isDualMode ? 6 : 8),
                        );

                        return Positioned(
                          left: 0,
                          right: 0,
                          top: metrics.whiteTopFor(index),
                          height: metrics.whiteKeyExtent,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            curve: Curves.easeOutCubic,
                            margin: EdgeInsets.only(bottom: keyMargin),
                            padding: labelPadding,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                keyBorderRadius,
                              ),
                              border: Border.all(
                                color: Colors.black.withValues(
                                  alpha: isDualMode ? 0.08 : 0.10,
                                ),
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
                              boxShadow: isActive
                                  ? <BoxShadow>[
                                      BoxShadow(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              children: <Widget>[
                                Container(
                                  width: isDualMode
                                      ? (compactPhone ? 2.5 : 3)
                                      : 5,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? theme.colorScheme.primary
                                        : isHighlighted
                                        ? style.blackAccentTop
                                        : Colors.black.withValues(
                                            alpha: isDualMode ? 0.08 : 0.12,
                                          ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                SizedBox(width: isDualMode ? 6 : 10),
                                Expanded(
                                  child: hideWhiteLabels
                                      ? const SizedBox.shrink()
                                      : Text(
                                          _displayLabelForKey(key, viewport),
                                          style:
                                              (isDualMode
                                                      ? theme
                                                            .textTheme
                                                            .bodySmall
                                                      : theme
                                                            .textTheme
                                                            .titleSmall)
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                    color: const Color(
                                                      0xFF0F172A,
                                                    ),
                                                    fontSize: isDualMode
                                                        ? 11
                                                        : null,
                                                  ),
                                        ),
                                ),
                                if (!viewport.compactLabels && !hideWhiteLabels)
                                  Text(
                                    key.pitchClass,
                                    style:
                                        (isDualMode
                                                ? theme.textTheme.labelSmall
                                                : theme.textTheme.labelMedium)
                                            ?.copyWith(
                                              color: const Color(0xFF475569),
                                              fontWeight: FontWeight.w700,
                                              fontSize: isDualMode ? 10 : null,
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
                        final blackKeyRadius = isDualMode ? 12.0 : 16.0;
                        final blackKeyPadding = EdgeInsets.symmetric(
                          horizontal: isDualMode ? 8 : 12,
                        );

                        return Positioned(
                          right: metrics.blackKeyInset,
                          top: metrics.blackTopFor(placement.slot),
                          width: metrics.blackKeyWidth,
                          height: metrics.blackKeyHeight,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            curve: Curves.easeOutCubic,
                            padding: blackKeyPadding,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                blackKeyRadius,
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(
                                  alpha: isDualMode ? 0.15 : 0.10,
                                ),
                                width: isDualMode ? 0.8 : 1.0,
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
                                  color: Colors.black.withValues(
                                    alpha: isDualMode ? 0.35 : 0.28,
                                  ),
                                  blurRadius: isDualMode ? 8 : 10,
                                  offset: Offset(0, isDualMode ? 3 : 5),
                                ),
                                if (isActive)
                                  BoxShadow(
                                    color: const Color(
                                      0xFF2F56A6,
                                    ).withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 2),
                                  ),
                              ],
                            ),
                            alignment: Alignment.centerLeft,
                            child: hideBlackLabels
                                ? const SizedBox.shrink()
                                : Text(
                                    viewport.compactLabels
                                        ? key.pitchClass
                                        : key.label,
                                    style:
                                        (isDualMode
                                                ? theme.textTheme.labelSmall
                                                : theme.textTheme.labelLarge)
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: isDualMode ? 10 : null,
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
        final compactSwitcher = _isCompactPhoneWidth(constraints.maxWidth);
        final keyboardWidth = compactSwitcher
            ? constraints.maxWidth
            : (constraints.maxWidth - 8) / 2;
        final dualViewport = _PianoViewportSpec(
          octaveSpan: viewport.octaveSpan,
          whiteKeyExtent: viewport.whiteKeyExtent,
          stageHeight: viewport.stageHeight,
          compactLabels: viewport.compactLabels || keyboardWidth < 140,
        );
        if (compactSwitcher) {
          final compactWhiteExtent = (viewport.whiteKeyExtent * 0.90).clamp(
            26.0,
            viewport.whiteKeyExtent,
          );
          final compactViewport = _PianoViewportSpec(
            octaveSpan: viewport.octaveSpan,
            whiteKeyExtent: compactWhiteExtent.toDouble(),
            stageHeight: compactWhiteExtent * (viewport.octaveSpan * 7 + 1),
            compactLabels: true,
          );
          Widget buildLane(
            _PianoKeyboardSlice laneSlice, {
            required _PianoCompactDeckFocus focus,
            required bool active,
          }) {
            return Column(
              key: ValueKey<String>('compact-lane-${focus.name}'),
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    _compactFocusLabel(i18n, focus),
                    style: TextStyle(
                      color: immersive ? Colors.white70 : null,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _buildKeyboardStage(
                  context,
                  laneSlice,
                  viewport: compactViewport,
                  immersive: immersive,
                  hideWhiteLabels: !active,
                  hideBlackLabels: !active,
                  shellOpacity: active ? 1.0 : 0.70,
                  highlightFrame: active,
                  isDualMode: true,
                ),
              ],
            );
          }

          final activeFocus = _compactDualFocus;
          final activeSlice = activeFocus == _PianoCompactDeckFocus.high
              ? upperSlice
              : lowerSlice;
          final inactiveFocus = activeFocus == _PianoCompactDeckFocus.high
              ? _PianoCompactDeckFocus.low
              : _PianoCompactDeckFocus.high;
          final inactiveSlice = activeFocus == _PianoCompactDeckFocus.high
              ? lowerSlice
              : upperSlice;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: _buildCompactDualToggle(
                      context,
                      i18n,
                      focus: _PianoCompactDeckFocus.low,
                      slice: lowerSlice,
                      selected: _compactDualFocus == _PianoCompactDeckFocus.low,
                      immersive: immersive,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCompactDualToggle(
                      context,
                      i18n,
                      focus: _PianoCompactDeckFocus.high,
                      slice: upperSlice,
                      selected:
                          _compactDualFocus == _PianoCompactDeckFocus.high,
                      immersive: immersive,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: buildLane(activeSlice, focus: activeFocus, active: true),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _compactDualFocus = inactiveFocus;
                  });
                },
                icon: const Icon(Icons.swap_vert_rounded),
                label: Text(
                  pickUiText(
                    i18n,
                    zh: '切换到另一组键盘',
                    en: 'Switch to ${inactiveFocus == _PianoCompactDeckFocus.high ? 'high' : 'low'} (${inactiveSlice.label})',
                  ),
                ),
              ),
            ],
          );
        }

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
                      pickUiText(i18n, zh: '高音', en: 'High'),
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
                      isDualMode: true,
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
                      pickUiText(i18n, zh: '低音', en: 'Low'),
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
                      isDualMode: true,
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

  Widget _buildCompactDualToggle(
    BuildContext context,
    AppI18n i18n, {
    required _PianoCompactDeckFocus focus,
    required _PianoKeyboardSlice slice,
    required bool selected,
    required bool immersive,
  }) {
    final theme = Theme.of(context);
    final foregroundColor = selected
        ? immersive
              ? Colors.white
              : theme.colorScheme.onPrimaryContainer
        : immersive
        ? Colors.white
        : theme.colorScheme.onSurface;
    final borderColor = immersive
        ? Colors.white.withValues(alpha: selected ? 0.28 : 0.14)
        : selected
        ? theme.colorScheme.primary.withValues(alpha: 0.28)
        : theme.colorScheme.outlineVariant;
    final backgroundColor = immersive
        ? Colors.white.withValues(alpha: selected ? 0.16 : 0.08)
        : selected
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            _compactDualFocus = focus;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _compactFocusLabel(i18n, focus),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                slice.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: foregroundColor.withValues(alpha: 0.78),
                ),
              ),
            ],
          ),
        ),
      ),
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
            ToolboxMetricCard(
              label: pickUiText(i18n, zh: '键盘规格', en: 'Layout'),
              value: _displayKeyLayoutLabel(i18n, _activeKeyLayout),
            ),
            ToolboxMetricCard(
              label: pickUiText(i18n, zh: '音域', en: 'Range'),
              value: slice.label,
            ),
            ToolboxMetricCard(
              label: pickUiText(i18n, zh: '调式', en: 'Scale'),
              value: _displayScaleLabelFixed(i18n, _scaleId),
            ),
            ToolboxMetricCard(
              label: pickUiText(i18n, zh: '和声', en: 'Harmony'),
              value: _displayChordLabelFixed(i18n, _chordId),
            ),
            ToolboxMetricCard(
              label: pickUiText(i18n, zh: '风格', en: 'Style'),
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
          pickUiText(i18n, zh: '键盘键数', en: 'Key layout'),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _keyLayouts
              .map(
                (layout) => ChoiceChip(
                  label: Text('${layout.keyCount}'),
                  selected: layout.id == _keyLayoutId,
                  onSelected: (_) => applySettings(() {
                    _applyKeyLayoutById(layout.id);
                  }),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 8),
        Text(
          _displayKeyLayoutLabel(i18n, _activeKeyLayout),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        _buildSettingsSectionTitle(
          context,
          pickUiText(i18n, zh: '预设音色包', en: 'Preset pack'),
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
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: _compactKeyboardMode,
          onChanged: (value) => applySettings(() {
            _compactKeyboardMode = value;
          }),
          title: Text(
            pickUiText(i18n, zh: '紧凑键盘模式', en: 'Compact keyboard mode'),
          ),
          subtitle: Text(
            pickUiText(
              i18n,
              zh: '缩小键位并尽量显示更多八度，减少频繁切换音域。',
              en: 'Shrink key height and show more octaves to reduce frequent range switching.',
            ),
          ),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: _aggressiveOneHandMode,
          onChanged: (value) => applySettings(() {
            _aggressiveOneHandMode = value;
            if (value) {
              _dualKeyboardMode = false;
            }
          }),
          title: Text(
            pickUiText(
              i18n,
              zh: '激进单手模式（320-390dp）',
              en: 'Aggressive one-hand mode (320-390dp)',
            ),
          ),
          subtitle: Text(
            pickUiText(
              i18n,
              zh: '窄屏自动放大黑键触控区、减少控件干扰，并优先单键盘演奏。',
              en: 'On narrow phones, enlarge black-key hit zones, reduce control density, and prefer a single keyboard.',
            ),
          ),
        ),
        Text(
          _displayGestureThresholdLabelFixed(i18n),
          style: theme.textTheme.labelLarge,
        ),
        Slider(
          value: _gestureThresholdScale,
          min: 0.8,
          max: 1.25,
          divisions: 9,
          onChanged: (value) => applySettings(() {
            _gestureThresholdScale = value;
          }),
        ),
        Text(
          pickUiText(
            i18n,
            zh: '值越小越灵敏，越大越稳。建议真机按手势习惯微调。',
            en: 'Lower values are more sensitive, higher values are steadier. Fine-tune on a real device.',
          ),
          style: theme.textTheme.bodySmall,
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _rootPitchClasses
              .map(
                (pitchClass) => ChoiceChip(
                  label: Text(pitchClass),
                  selected: pitchClass == _rootPitchClass,
                  onSelected: (_) => applySettings(() {
                    _rootPitchClass = pitchClass;
                  }),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 20),
        _buildSettingsSectionTitle(
          context,
          pickUiText(i18n, zh: '音域窗口', en: 'Range window'),
        ),
        Text(
          pickUiText(
            i18n,
            zh: '当前纵向舞台一次显示 ${viewport.octaveSpan} 个八度，支持快速切换音域与分行展示窗口。',
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
          aggressiveOneHand:
              _aggressiveOneHandMode &&
              _isAggressiveOneHandWidth(MediaQuery.sizeOf(context).width),
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
    final width = MediaQuery.sizeOf(context).width;
    final aggressiveOneHand =
        _aggressiveOneHandMode && _isAggressiveOneHandWidth(width);
    final effectiveDualMode = _dualKeyboardMode && !aggressiveOneHand;
    final topInset = MediaQuery.viewPaddingOf(context).top;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final compactTopBar = width < 430;
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
                bottomInset + 110,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: effectiveDualMode
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
                        aggressiveOneHand: aggressiveOneHand,
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
                      onPressed: aggressiveOneHand
                          ? null
                          : _toggleDualKeyboardMode,
                      style: overlayButtonStyle,
                      child: Icon(
                        effectiveDualMode
                            ? Icons.view_day_rounded
                            : Icons.view_stream_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!compactTopBar)
                      FilledButton.tonal(
                        onPressed: _toggleCompactKeyboardMode,
                        style: overlayButtonStyle,
                        child: Icon(
                          _compactKeyboardMode
                              ? Icons.compress_rounded
                              : Icons.expand_rounded,
                        ),
                      ),
                    if (compactTopBar)
                      PopupMenuButton<_PianoTopBarAction>(
                        tooltip: pickUiText(
                          i18n,
                          zh: '更多操作',
                          en: 'More actions',
                        ),
                        color: Colors.black.withValues(alpha: 0.92),
                        onSelected: (action) {
                          switch (action) {
                            case _PianoTopBarAction.toggleCompact:
                              _toggleCompactKeyboardMode();
                            case _PianoTopBarAction.openSettings:
                              _openPianoSettingsSheet(
                                context,
                                i18n,
                                viewport: viewport,
                                slice: slice,
                              );
                          }
                        },
                        itemBuilder: (menuContext) {
                          return <PopupMenuEntry<_PianoTopBarAction>>[
                            PopupMenuItem<_PianoTopBarAction>(
                              value: _PianoTopBarAction.toggleCompact,
                              child: Text(
                                _compactKeyboardMode
                                    ? pickUiText(
                                        i18n,
                                        zh: '关闭紧凑键盘',
                                        en: 'Disable compact keys',
                                      )
                                    : pickUiText(
                                        i18n,
                                        zh: '开启紧凑键盘',
                                        en: 'Enable compact keys',
                                      ),
                              ),
                            ),
                            PopupMenuItem<_PianoTopBarAction>(
                              value: _PianoTopBarAction.openSettings,
                              child: Text(
                                pickUiText(
                                  i18n,
                                  zh: '键盘设置',
                                  en: 'Keyboard settings',
                                ),
                              ),
                            ),
                          ];
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.58),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.24),
                            ),
                          ),
                          child: const Icon(
                            Icons.more_horiz_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    const Spacer(),
                    if (!compactTopBar)
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
          Positioned(
            left: 12,
            right: 12,
            bottom: bottomInset + 10,
            child: _buildFullScreenBottomBar(
              context,
              i18n,
              viewport: viewport,
              rangeStart: rangeStart,
              slice: slice,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullScreenBottomBar(
    BuildContext context,
    AppI18n i18n, {
    required _PianoViewportSpec viewport,
    required int rangeStart,
    required _PianoKeyboardSlice slice,
  }) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final compactPhone = _isCompactPhoneWidth(width);
    final aggressiveOneHand =
        _aggressiveOneHandMode && _isAggressiveOneHandWidth(width);
    final effectiveDualMode = _dualKeyboardMode && !aggressiveOneHand;
    final overlayButtonStyle = FilledButton.styleFrom(
      backgroundColor: Colors.black.withValues(alpha: 0.56),
      foregroundColor: Colors.white,
      elevation: 0,
      side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
    final activeCompactSlice = _compactDualFocus == _PianoCompactDeckFocus.high
        ? pickUiText(i18n, zh: '高音', en: 'High')
        : pickUiText(i18n, zh: '低音', en: 'Low');
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  _PianoOverlayChip(
                    label: pickUiText(i18n, zh: '窗口', en: 'Window'),
                    value: slice.label,
                  ),
                  const SizedBox(width: 8),
                  _PianoOverlayChip(
                    label: pickUiText(i18n, zh: '和声', en: 'Harmony'),
                    value: _displayChordLabelFixed(i18n, _chordId),
                  ),
                  const SizedBox(width: 8),
                  _PianoOverlayChip(
                    label: pickUiText(i18n, zh: '模式', en: 'Mode'),
                    value: effectiveDualMode
                        ? compactPhone
                              ? '${pickUiText(i18n, zh: '双键盘', en: 'Dual')} · $activeCompactSlice'
                              : pickUiText(i18n, zh: '双键盘', en: 'Dual')
                        : pickUiText(i18n, zh: '单键盘', en: 'Single'),
                  ),
                  const SizedBox(width: 8),
                  _buildKeyLayoutPickerButton(
                    context,
                    i18n,
                    immersive: true,
                    compact: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                FilledButton.tonal(
                  onPressed: rangeStart > 0
                      ? () => _updateRangeStart(
                          rangeStart - 1,
                          viewport.octaveSpan,
                        )
                      : null,
                  style: overlayButtonStyle,
                  child: const Icon(Icons.keyboard_arrow_up_rounded),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    compactPhone
                        ? pickUiText(
                            i18n,
                            zh: '单指滑奏，双指切换音域。',
                            en: 'Gliss with one finger; shift range with two.',
                          )
                        : pickUiText(
                            i18n,
                            zh: '单指滑奏，双指上下或左右切换音域。',
                            en: 'Gliss with one finger; use two fingers to shift range.',
                          ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: rangeStart < _maxRangeStart(viewport.octaveSpan)
                      ? () => _updateRangeStart(
                          rangeStart + 1,
                          viewport.octaveSpan,
                        )
                      : null,
                  style: overlayButtonStyle,
                  child: const Icon(Icons.keyboard_arrow_down_rounded),
                ),
              ],
            ),
          ],
        ),
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
        _maybeApplyResponsiveDefaults(constraints.maxWidth);
        final compactPhone = _isCompactPhoneWidth(constraints.maxWidth);
        final ultraCompactPhone = _isUltraCompactPhoneWidth(
          constraints.maxWidth,
        );
        final aggressiveOneHand =
            _aggressiveOneHandMode &&
            _isAggressiveOneHandWidth(constraints.maxWidth);
        final effectiveDualMode = _dualKeyboardMode && !aggressiveOneHand;
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
                  ToolboxMetricCard(
                    label: pickUiText(i18n, zh: '键数', en: 'Keys'),
                    value: '${_activeKeyLayout.keyCount}',
                  ),
                  ToolboxMetricCard(
                    label: pickUiText(i18n, zh: '总音域', en: 'Total range'),
                    value:
                        '${_noteLabelForMidi(_activeKeyLayout.startMidi)}-${_noteLabelForMidi(_activeKeyLayout.startMidi + _activeKeyLayout.keyCount - 1)}',
                  ),
                  ToolboxMetricCard(
                    label: pickUiText(i18n, zh: '当前窗口', en: 'Window'),
                    value: slice.label,
                  ),
                  ToolboxMetricCard(
                    label: pickUiText(i18n, zh: '预设', en: 'Preset'),
                    value: _displayPresetLabel(i18n, _activePreset),
                  ),
                  ToolboxMetricCard(
                    label: pickUiText(i18n, zh: '和声', en: 'Harmony'),
                    value: _displayChordLabelFixed(i18n, _chordId),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (compactPhone) ...<Widget>[
                SectionHeader(
                  title: pickUiText(i18n, zh: '纵向键盘', en: 'Vertical keyboard'),
                  subtitle: pickUiText(
                    i18n,
                    zh: '手机布局优先保证单手点击和滑奏，再按需切换双键盘。',
                    en: 'Phone layout prioritizes one-hand taps and glissando before exposing the dual keyboard.',
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: () => _openPianoSettingsSheet(
                      context,
                      i18n,
                      viewport: viewport,
                      slice: slice,
                    ),
                    icon: const Icon(Icons.tune_rounded),
                    label: Text(
                      pickUiText(i18n, zh: '键盘设置', en: 'Keyboard settings'),
                    ),
                  ),
                ),
              ] else
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
                          zh: '键盘沿屏幕高度展开，避免横向压缩。',
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _buildKeyLayoutPickerButton(
                    context,
                    i18n,
                    compact: ultraCompactPhone,
                  ),
                  OutlinedButton.icon(
                    onPressed: _toggleRangeNavigatorLayout,
                    icon: Icon(
                      _rangeNavigatorExpanded
                          ? Icons.view_stream_rounded
                          : Icons.view_day_rounded,
                    ),
                    label: Text(
                      pickUiText(
                        i18n,
                        zh: ultraCompactPhone ? '窗口' : '窗口列表',
                        en: ultraCompactPhone ? 'Window' : 'Window list',
                      ),
                    ),
                  ),
                  if (!aggressiveOneHand)
                    OutlinedButton.icon(
                      onPressed: _toggleDualKeyboardMode,
                      icon: Icon(
                        effectiveDualMode
                            ? Icons.view_stream_rounded
                            : Icons.view_day_rounded,
                      ),
                      label: Text(
                        pickUiText(
                          i18n,
                          zh: ultraCompactPhone ? '双键盘' : '双键盘',
                          en: ultraCompactPhone ? 'Dual' : 'Dual keyboard',
                        ),
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => _openFullScreen(context),
                    icon: const Icon(Icons.open_in_full_rounded),
                    label: Text(
                      pickUiText(
                        i18n,
                        zh: ultraCompactPhone ? '全屏' : '全屏',
                        en: ultraCompactPhone ? 'Full' : 'Full screen',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildRangeNavigator(
                context,
                i18n,
                octaveSpan: viewport.octaveSpan,
                rangeStart: rangeStart,
                slice: slice,
                immersive: false,
                aggressiveOneHand: aggressiveOneHand,
              ),
              const SizedBox(height: 12),
              effectiveDualMode
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
                      aggressiveOneHand: aggressiveOneHand,
                    ),
              const SizedBox(height: 10),
              Text(
                pickUiText(
                  i18n,
                  zh: compactPhone
                      ? '单指可连续滑奏；双指上下或左右滑动可切换音域窗口；窄屏优先单键盘。'
                      : '单指可连续滑奏；双指上下滑动可跳转音域，双指左右滑动可快速切窗。',
                  en: compactPhone
                      ? 'Use one finger for glissando, two fingers to change range, and tap once to switch high or low rows in phone dual mode.'
                      : 'Single-finger glissando is supported, while two-finger vertical drags jump registers and horizontal drags switch windows.',
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

class _PianoKeyLayoutPreset {
  const _PianoKeyLayoutPreset({
    required this.id,
    required this.keyCount,
    required this.startMidi,
  });

  final String id;
  final int keyCount;
  final int startMidi;
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
    required this.blackKeyHitPadding,
  });

  final Size size;
  final double whiteKeyExtent;
  final double blackKeyWidth;
  final double blackKeyHeight;
  final double blackKeyInset;
  final double blackKeyHitPadding;

  double whiteTopFor(int index) => index * whiteKeyExtent;

  double blackTopFor(int slot) {
    final top = whiteKeyExtent * (slot + 1) - blackKeyHeight / 2;
    return top.clamp(4.0, math.max(4.0, size.height - blackKeyHeight - 4.0));
  }

  Rect _blackRectForSlot(int slot, {bool expanded = false}) {
    final left = size.width - blackKeyWidth - blackKeyInset;
    final top = blackTopFor(slot);
    if (!expanded) {
      return Rect.fromLTWH(left, top, blackKeyWidth, blackKeyHeight);
    }
    final expandedLeft = math.max(0.0, left - blackKeyHitPadding);
    final expandedTop = math.max(0.0, top - blackKeyHitPadding * 0.5);
    final expandedRight = math.min(
      size.width,
      left + blackKeyWidth + math.min(blackKeyInset + blackKeyHitPadding, 14.0),
    );
    final expandedBottom = math.min(
      size.height,
      top + blackKeyHeight + blackKeyHitPadding * 0.5,
    );
    return Rect.fromLTRB(
      expandedLeft,
      expandedTop,
      expandedRight,
      expandedBottom,
    );
  }

  Rect? rectForKey(_PianoKeyboardSlice slice, _PianoKey key) {
    if (key.isSharp) {
      for (final placement in slice.blackKeys) {
        if (placement.key.id != key.id) continue;
        return _blackRectForSlot(placement.slot);
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
      final rect = _blackRectForSlot(placement.slot, expanded: true);
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

enum _PianoCompactDeckFocus { low, high }

enum _PianoTopBarAction { toggleCompact, openSettings }

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
