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
    _PianoPitchSet(id: 'pentatonic', intervals: <int>[0, 2, 4, 7, 9]),
    _PianoPitchSet(
      id: 'chromatic',
      intervals: <int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
    ),
  ];
  static const List<_PianoPitchSet> _chordSets = <_PianoPitchSet>[
    _PianoPitchSet(id: 'off', intervals: <int>[]),
    _PianoPitchSet(id: 'major', intervals: <int>[0, 4, 7]),
    _PianoPitchSet(id: 'minor', intervals: <int>[0, 3, 7]),
    _PianoPitchSet(id: 'sus2', intervals: <int>[0, 2, 7]),
    _PianoPitchSet(id: 'maj7', intervals: <int>[0, 4, 7, 11]),
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
  static final List<_PianoPreset> _presets = <_PianoPreset>[
    _PianoPreset(
      id: 'concert_hall',
      styleId: 'concert',
      touch: 0.92,
      reverb: 0.18,
      decay: 1.15,
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

  final Map<String, ToolboxEffectPlayer> _players =
      <String, ToolboxEffectPlayer>{};
  String? _activeKeyId;
  String _presetId = _presets.first.id;
  double _touch = _presets.first.touch;
  double _reverb = _presets.first.reverb;
  double _decay = _presets.first.decay;
  int _rangeStartOctave = 3;
  String _scaleId = _scaleSets.first.id;
  String _chordId = _chordSets.first.id;
  String _rootPitchClass = 'C';
  final Map<int, Offset> _activePointers = <int, Offset>{};
  double? _twoFingerOriginX;
  bool _twoFingerGestureConsumed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_warmUpActivePreset());
    });
  }

  _PianoPreset get _activePreset {
    return _presets.firstWhere(
      (item) => item.id == _presetId,
      orElse: () => _presets.first,
    );
  }

  String _presetLabel(AppI18n i18n, _PianoPreset preset) {
    return switch (preset.id) {
      'bright_stage' => pickUiText(
        i18n,
        zh: '明亮舞台',
        en: 'Bright stage',
        ja: 'ブライトステージ',
        de: 'Helle Buehne',
        fr: 'Scene brillante',
        es: 'Escenario brillante',
        ru: 'Yarkaya stsena',
      ),
      'felt_room' => pickUiText(
        i18n,
        zh: '毛毡小室',
        en: 'Felt room',
        ja: 'フェルトルーム',
        de: 'Felt-Raum',
        fr: 'Piece feutree',
        es: 'Sala de fieltro',
        ru: 'Felt room',
      ),
      _ => pickUiText(
        i18n,
        zh: '音乐厅',
        en: 'Concert hall',
        ja: 'コンサートホール',
        de: 'Konzertsaal',
        fr: 'Salle de concert',
        es: 'Sala de conciertos',
        ru: 'Kontsertnyy zal',
      ),
    };
  }

  String _presetSubtitle(AppI18n i18n, _PianoPreset preset) {
    return switch (preset.id) {
      'bright_stage' => pickUiText(
        i18n,
        zh: '更强的锤击感和更亮的谐波，适合旋律突出。',
        en: 'Sharper hammer attack and brighter harmonics for lead lines.',
      ),
      'felt_room' => pickUiText(
        i18n,
        zh: '更柔和贴耳的毛毡感，适合夜间和安静演奏。',
        en: 'Softer felt-like body for intimate and quiet playing.',
      ),
      _ => pickUiText(
        i18n,
        zh: '均衡的空间感与延音，适合通用演奏。',
        en: 'Balanced sustain and room feel for all-purpose playing.',
      ),
    };
  }

  void _invalidatePlayers() {
    for (final player in _players.values) {
      unawaited(player.dispose());
    }
    _players.clear();
  }

  void _applyPreset(String presetId) {
    final preset = _presets.firstWhere(
      (item) => item.id == presetId,
      orElse: () => _presets.first,
    );
    if (_presetId == preset.id) return;
    setState(() {
      _presetId = preset.id;
      _touch = preset.touch;
      _reverb = preset.reverb;
      _decay = preset.decay;
    });
    _invalidatePlayers();
    unawaited(_warmUpActivePreset());
  }

  Future<void> _warmUpActivePreset() async {
    for (final key in _allKeys.where(
      (item) => item.octave >= 3 && item.octave <= 5,
    )) {
      await _playerFor(key).warmUp();
    }
  }

  ToolboxEffectPlayer _playerFor(_PianoKey key) {
    final styleId = _activePreset.styleId;
    final cacheKey =
        '${key.id}:$styleId:${_reverb.toStringAsFixed(2)}:${_decay.toStringAsFixed(2)}';
    final existing = _players[cacheKey];
    if (existing != null) return existing;
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

  Future<void> _hitKey(_PianoKey key, {double? volume}) async {
    HapticFeedback.selectionClick();
    unawaited(_playerFor(key).play(volume: volume ?? _touch));
    if (!mounted) return;
    setState(() {
      _activeKeyId = key.id;
    });
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (!mounted || _activeKeyId != key.id) return;
      setState(() {
        _activeKeyId = null;
      });
    });
  }

  int _visibleOctaveSpanForWidth(double width) {
    if (width >= 1180) return 4;
    if (width >= 880) return 3;
    if (width >= 560) return 2;
    return 1;
  }

  int _maxRangeStart(int octaveSpan) {
    return math.max(1, 9 - octaveSpan);
  }

  void _updateRangeStart(int nextStart, int octaveSpan) {
    setState(() {
      _rangeStartOctave = nextStart.clamp(1, _maxRangeStart(octaveSpan));
    });
  }

  _PianoPitchSet get _activeScaleSet {
    return _scaleSets.firstWhere(
      (item) => item.id == _scaleId,
      orElse: () => _scaleSets.first,
    );
  }

  _PianoPitchSet get _activeChordSet {
    return _chordSets.firstWhere(
      (item) => item.id == _chordId,
      orElse: () => _chordSets.first,
    );
  }

  String _scaleLabel(AppI18n i18n, String scaleId) {
    return switch (scaleId) {
      'minor' => pickUiText(i18n, zh: '小调', en: 'Minor'),
      'dorian' => pickUiText(i18n, zh: '多利亚', en: 'Dorian'),
      'pentatonic' => pickUiText(i18n, zh: '五声音阶', en: 'Pentatonic'),
      'chromatic' => pickUiText(i18n, zh: '半音阶', en: 'Chromatic'),
      _ => pickUiText(i18n, zh: '大调', en: 'Major'),
    };
  }

  String _chordLabel(AppI18n i18n, String chordId) {
    return switch (chordId) {
      'major' => pickUiText(i18n, zh: '大三和弦', en: 'Major'),
      'minor' => pickUiText(i18n, zh: '小三和弦', en: 'Minor'),
      'sus2' => pickUiText(i18n, zh: '挂二', en: 'Sus2'),
      'maj7' => pickUiText(i18n, zh: '大七', en: 'Maj7'),
      _ => pickUiText(i18n, zh: '关闭和弦', en: 'No chord'),
    };
  }

  Set<String> _highlightedPitchClasses() {
    final rootIndex = _rootPitchClasses.indexOf(_rootPitchClass);
    final highlights = <String>{};
    for (final interval in _activeScaleSet.intervals) {
      highlights.add(_rootPitchClasses[(rootIndex + interval) % 12]);
    }
    for (final interval in _activeChordSet.intervals) {
      highlights.add(_rootPitchClasses[(rootIndex + interval) % 12]);
    }
    return highlights;
  }

  void _handlePianoPointerDown(PointerDownEvent event) {
    _activePointers[event.pointer] = event.localPosition;
    if (_activePointers.length >= 2) {
      _twoFingerOriginX =
          _activePointers.values
              .map((offset) => offset.dx)
              .reduce((a, b) => a + b) /
          _activePointers.length;
      _twoFingerGestureConsumed = false;
    }
  }

  void _handlePianoPointerMove(
    PointerMoveEvent event, {
    required int octaveSpan,
  }) {
    if (!_activePointers.containsKey(event.pointer)) return;
    _activePointers[event.pointer] = event.localPosition;
    if (_activePointers.length < 2) return;
    final centerX =
        _activePointers.values
            .map((offset) => offset.dx)
            .reduce((a, b) => a + b) /
        _activePointers.length;
    final origin = _twoFingerOriginX ?? centerX;
    final delta = centerX - origin;
    if (_twoFingerGestureConsumed || delta.abs() < 42) return;
    _twoFingerGestureConsumed = true;
    _updateRangeStart(_rangeStartOctave + (delta < 0 ? 1 : -1), octaveSpan);
  }

  void _handlePianoPointerUp(PointerEvent event) {
    _activePointers.remove(event.pointer);
    if (_activePointers.length < 2) {
      _twoFingerOriginX = null;
      _twoFingerGestureConsumed = false;
    }
  }

  _PianoKeyboardSlice _sliceFor(int startOctave, int octaveSpan) {
    final startMidi = _midiForC(startOctave);
    final endMidi = _midiForC(startOctave + octaveSpan);
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
      label: 'C$startOctave-C${startOctave + octaveSpan}',
    );
  }

  String _spaceLabel(AppI18n i18n) {
    return pickUiText(
      i18n,
      zh: '空间 ${(_reverb * 100).round()}%',
      en: 'Space ${(_reverb * 100).round()}%',
      ja: '空間 ${(_reverb * 100).round()}%',
      de: 'Raum ${(_reverb * 100).round()}%',
      fr: 'Espace ${(_reverb * 100).round()}%',
      es: 'Espacio ${(_reverb * 100).round()}%',
      ru: 'Space ${(_reverb * 100).round()}%',
    );
  }

  String _decayLabel(AppI18n i18n) {
    return pickUiText(
      i18n,
      zh: '延音 ${_decay.toStringAsFixed(2)}x',
      en: 'Decay ${_decay.toStringAsFixed(2)}x',
      ja: '余韻 ${_decay.toStringAsFixed(2)}x',
      de: 'Ausklang ${_decay.toStringAsFixed(2)}x',
      fr: 'Sustain ${_decay.toStringAsFixed(2)}x',
      es: 'Sustain ${_decay.toStringAsFixed(2)}x',
      ru: 'Decay ${_decay.toStringAsFixed(2)}x',
    );
  }

  Widget _buildRangeNavigator(
    BuildContext context,
    AppI18n i18n, {
    required int octaveSpan,
    required int rangeStart,
    required _PianoKeyboardSlice slice,
  }) {
    final starts = List<int>.generate(
      _maxRangeStart(octaveSpan),
      (index) => index + 1,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton.filledTonal(
              onPressed: rangeStart > 1
                  ? () => _updateRangeStart(rangeStart - 1, octaveSpan)
                  : null,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                pickUiText(
                  i18n,
                  zh: '当前窗口 ${slice.label}',
                  en: 'Current window ${slice.label}',
                ),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: rangeStart < _maxRangeStart(octaveSpan)
                  ? () => _updateRangeStart(rangeStart + 1, octaveSpan)
                  : null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: starts
                .map(
                  (start) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('C$start-C${start + octaveSpan}'),
                      selected: start == rangeStart,
                      onSelected: (_) => _updateRangeStart(start, octaveSpan),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ],
    );
  }

  Widget _buildKeyboardStage(
    BuildContext context,
    _PianoKeyboardSlice slice, {
    required double maxWidth,
    int? octaveSpan,
  }) {
    final theme = Theme.of(context);
    final highlightedPitchClasses = _highlightedPitchClasses();
    final keyboardHeight = widget.fullScreen ? 320.0 : 250.0;
    const minWhiteWidth = 54.0;
    final totalWidth = math.max(
      maxWidth,
      slice.whiteKeys.length * minWhiteWidth,
    );
    final whiteWidth = totalWidth / slice.whiteKeys.length;
    final blackWidth = whiteWidth * 0.62;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: octaveSpan == null ? null : _handlePianoPointerDown,
      onPointerMove: octaveSpan == null
          ? null
          : (event) => _handlePianoPointerMove(event, octaveSpan: octaveSpan),
      onPointerUp: octaveSpan == null ? null : _handlePianoPointerUp,
      onPointerCancel: octaveSpan == null ? null : _handlePianoPointerUp,
      child: SizedBox(
        height: keyboardHeight,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalWidth,
            child: Stack(
              children: <Widget>[
                Row(
                  children: slice.whiteKeys
                      .map(
                        (key) => SizedBox(
                          width: whiteWidth,
                          child: Listener(
                            behavior: HitTestBehavior.opaque,
                            onPointerDown: (_) => unawaited(_hitKey(key)),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 90),
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(14),
                                ),
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant,
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: <Color>[
                                    _activeKeyId == key.id
                                        ? theme.colorScheme.primaryContainer
                                        : highlightedPitchClasses.contains(
                                            key.pitchClass,
                                          )
                                        ? const Color(0xFFF7E7B6)
                                        : Colors.white,
                                    _activeKeyId == key.id
                                        ? theme.colorScheme.primary.withValues(
                                            alpha: 0.34,
                                          )
                                        : highlightedPitchClasses.contains(
                                            key.pitchClass,
                                          )
                                        ? const Color(0xFFEBCB72)
                                        : const Color(0xFFEFF2F8),
                                  ],
                                ),
                              ),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Text(
                                    key.label,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
                ...slice.blackKeys.map((placement) {
                  final key = placement.key;
                  return Positioned(
                    left: whiteWidth * (placement.slot + 1) - blackWidth / 2,
                    top: 0,
                    child: Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: (_) =>
                          unawaited(_hitKey(key, volume: 0.9)),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 90),
                        width: blackWidth,
                        height: widget.fullScreen ? 192 : 156,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(12),
                          ),
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.38),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[
                              _activeKeyId == key.id
                                  ? const Color(0xFF2F56A6)
                                  : highlightedPitchClasses.contains(
                                      key.pitchClass,
                                    )
                                  ? const Color(0xFF8C6A12)
                                  : const Color(0xFF12141A),
                              _activeKeyId == key.id
                                  ? const Color(0xFF1A2E63)
                                  : highlightedPitchClasses.contains(
                                      key.pitchClass,
                                    )
                                  ? const Color(0xFF584204)
                                  : const Color(0xFF050608),
                            ],
                          ),
                        ),
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            key.label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPianoSettingsContent(
    BuildContext context,
    AppI18n i18n, {
    required _PianoPreset preset,
    required _PianoKeyboardSlice slice,
    required int octaveSpan,
    required int rangeStart,
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
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            ToolboxMetricCard(label: 'Range', value: slice.label),
            ToolboxMetricCard(
              label: 'Scale',
              value: _scaleLabel(i18n, _scaleId),
            ),
            ToolboxMetricCard(
              label: 'Preset',
              value: _presetLabel(i18n, preset),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          pickUiText(i18n, zh: '音色预设', en: 'Preset pack'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presets
              .map(
                (item) => ChoiceChip(
                  label: Text(_presetLabel(i18n, item)),
                  selected: item.id == _presetId,
                  onSelected: (_) => _applyPreset(item.id),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 12),
        Text(_presetSubtitle(i18n, preset), style: theme.textTheme.bodySmall),
        const SizedBox(height: 14),
        Text(
          pickUiText(i18n, zh: '触键力度', en: 'Touch'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Slider(
          value: _touch,
          min: 0.55,
          max: 1.0,
          divisions: 18,
          onChanged: (value) => setState(() => _touch = value),
        ),
        Text(
          _spaceLabel(i18n),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Slider(
          value: _reverb,
          min: 0.0,
          max: 0.55,
          divisions: 11,
          onChanged: (value) => setState(() => _reverb = value),
          onChangeEnd: (_) {
            _invalidatePlayers();
            unawaited(_warmUpActivePreset());
          },
        ),
        Text(
          _decayLabel(i18n),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Slider(
          value: _decay,
          min: 0.7,
          max: 1.8,
          divisions: 22,
          onChanged: (value) => setState(() => _decay = value),
          onChangeEnd: (_) {
            _invalidatePlayers();
            unawaited(_warmUpActivePreset());
          },
        ),
        const SizedBox(height: 14),
        Text(
          pickUiText(i18n, zh: '调式与和弦', en: 'Scale and chord'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _scaleSets
              .map(
                (item) => ChoiceChip(
                  label: Text(_scaleLabel(i18n, item.id)),
                  selected: item.id == _scaleId,
                  onSelected: (_) => setState(() => _scaleId = item.id),
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
                  label: Text(_chordLabel(i18n, item.id)),
                  selected: item.id == _chordId,
                  onSelected: (_) => setState(() => _chordId = item.id),
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
                      onSelected: (_) =>
                          setState(() => _rootPitchClass = pitchClass),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          pickUiText(i18n, zh: '音域窗口', en: 'Range window'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        _buildRangeNavigator(
          context,
          i18n,
          octaveSpan: octaveSpan,
          rangeStart: rangeStart,
          slice: slice,
        ),
      ],
    );
  }

  Future<void> _openPianoSettingsSheet(
    BuildContext context,
    AppI18n i18n, {
    required _PianoPreset preset,
    required _PianoKeyboardSlice slice,
    required int octaveSpan,
    required int rangeStart,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
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
                  preset: _activePreset,
                  slice: _sliceFor(
                    _rangeStartOctave.clamp(1, _maxRangeStart(octaveSpan)),
                    octaveSpan,
                  ),
                  octaveSpan: octaveSpan,
                  rangeStart: _rangeStartOctave.clamp(
                    1,
                    _maxRangeStart(octaveSpan),
                  ),
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
    AppI18n i18n,
    ThemeData theme, {
    required _PianoPreset preset,
    required _PianoKeyboardSlice slice,
    required int octaveSpan,
    required int rangeStart,
  }) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF020617), Color(0xFF111827)],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox.expand(
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 54, 16, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: <Widget>[
                              _PianoOverlayChip(
                                label: 'Range',
                                value: slice.label,
                              ),
                              _PianoOverlayChip(
                                label: 'Scale',
                                value: _scaleLabel(i18n, _scaleId),
                              ),
                              _PianoOverlayChip(
                                label: 'Preset',
                                value: _presetLabel(i18n, preset),
                              ),
                              _PianoOverlayChip(
                                label: 'Gesture',
                                value: '2-finger swipe',
                              ),
                            ],
                          ),
                          const Spacer(),
                          _buildKeyboardStage(
                            context,
                            slice,
                            maxWidth: constraints.maxWidth - 32,
                            octaveSpan: octaveSpan,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: 58,
                    child: Text(
                      pickUiText(
                        i18n,
                        zh: '双指横滑切换音域窗口',
                        en: 'Two-finger swipe shifts the range window',
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: 8,
                    child: FilledButton.tonal(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.38),
                        foregroundColor: Colors.white,
                      ),
                      child: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                  Positioned(
                    right: 16,
                    top: 8,
                    child: FilledButton.tonalIcon(
                      onPressed: () => _openPianoSettingsSheet(
                        context,
                        i18n,
                        preset: preset,
                        slice: slice,
                        octaveSpan: octaveSpan,
                        rangeStart: rangeStart,
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.38),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.tune_rounded),
                      label: Text(pickUiText(i18n, zh: '设置', en: 'Settings')),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 22,
                    child: IconButton.filledTonal(
                      onPressed: rangeStart > 1
                          ? () => _updateRangeStart(rangeStart - 1, octaveSpan)
                          : null,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.34),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                  ),
                  Positioned(
                    right: 16,
                    bottom: 22,
                    child: IconButton.filledTonal(
                      onPressed: rangeStart < _maxRangeStart(octaveSpan)
                          ? () => _updateRangeStart(rangeStart + 1, octaveSpan)
                          : null,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.34),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _invalidatePlayers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    final theme = Theme.of(context);
    final preset = _activePreset;
    return LayoutBuilder(
      builder: (context, constraints) {
        final octaveSpan = _visibleOctaveSpanForWidth(constraints.maxWidth);
        final rangeStart = _rangeStartOctave.clamp(
          1,
          _maxRangeStart(octaveSpan),
        );
        final slice = _sliceFor(rangeStart, octaveSpan);
        if (widget.fullScreen) {
          return _buildPianoFullScreen(
            context,
            i18n,
            theme,
            preset: preset,
            slice: slice,
            octaveSpan: octaveSpan,
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
                    label: pickUiText(
                      i18n,
                      zh: '总键数',
                      en: 'Keys',
                      ja: '鍵数',
                      de: 'Tasten',
                      fr: 'Touches',
                      es: 'Teclas',
                      ru: 'Keys',
                    ),
                    value: '${_allKeys.length}',
                  ),
                  ToolboxMetricCard(
                    label: pickUiText(
                      i18n,
                      zh: '总音域',
                      en: 'Total range',
                      ja: '全音域',
                      de: 'Gesamtumfang',
                      fr: 'Etendue',
                      es: 'Rango total',
                      ru: 'Range',
                    ),
                    value: 'C1-C9',
                  ),
                  ToolboxMetricCard(
                    label: pickUiText(
                      i18n,
                      zh: '当前窗口',
                      en: 'Window',
                      ja: '現在窓',
                      de: 'Fenster',
                      fr: 'Fenetre',
                      es: 'Ventana',
                      ru: 'Window',
                    ),
                    value: slice.label,
                  ),
                  ToolboxMetricCard(
                    label: pickUiText(i18n, zh: '调式', en: 'Scale'),
                    value: _scaleLabel(i18n, _scaleId),
                  ),
                  ToolboxMetricCard(
                    label: pickUiText(
                      i18n,
                      zh: '预设',
                      en: 'Preset',
                      ja: 'プリセット',
                      de: 'Preset',
                      fr: 'Prereg.',
                      es: 'Preset',
                      ru: 'Preset',
                    ),
                    value: _presetLabel(i18n, preset),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SectionHeader(
                title: pickUiText(
                  i18n,
                  zh: '预设包',
                  en: 'Preset pack',
                  ja: 'プリセットパック',
                  de: 'Preset-Paket',
                  fr: 'Pack de prereglages',
                  es: 'Paquete de presets',
                  ru: 'Preset pack',
                ),
                subtitle: pickUiText(
                  i18n,
                  zh: '同步切换音色、空间感与默认触键力度。',
                  en: 'Switch timbre, room feel, and default touch together.',
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presets
                    .map(
                      (item) => ChoiceChip(
                        label: Text(_presetLabel(i18n, item)),
                        selected: item.id == _presetId,
                        onSelected: (_) => _applyPreset(item.id),
                      ),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: 8),
              Text(
                _presetSubtitle(i18n, preset),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 14),
              SectionHeader(
                title: pickUiText(
                  i18n,
                  zh: '触感与空间',
                  en: 'Touch and space',
                  ja: 'タッチと空間',
                  de: 'Touch und Raum',
                  fr: 'Toucher et espace',
                  es: 'Toque y espacio',
                  ru: 'Touch and space',
                ),
                subtitle: pickUiText(
                  i18n,
                  zh: '像竖琴一样独立调整触键、残响和延音，保持键盘区域不被挤压。',
                  en: 'Tune touch, reverb, and sustain without compressing the keyboard stage.',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                pickUiText(
                  i18n,
                  zh: '触键力度 ${(_touch * 100).round()}%',
                  en: 'Touch ${(_touch * 100).round()}%',
                  ja: 'タッチ ${(_touch * 100).round()}%',
                  de: 'Anschlag ${(_touch * 100).round()}%',
                  fr: 'Toucher ${(_touch * 100).round()}%',
                  es: 'Toque ${(_touch * 100).round()}%',
                  ru: 'Touch ${(_touch * 100).round()}%',
                ),
                style: theme.textTheme.labelLarge,
              ),
              Slider(
                value: _touch,
                min: 0.55,
                max: 1.0,
                divisions: 18,
                onChanged: (value) => setState(() => _touch = value),
              ),
              Text(_spaceLabel(i18n), style: theme.textTheme.labelLarge),
              Slider(
                value: _reverb,
                min: 0.0,
                max: 0.55,
                divisions: 11,
                onChanged: (value) => setState(() => _reverb = value),
                onChangeEnd: (_) {
                  _invalidatePlayers();
                  unawaited(_warmUpActivePreset());
                },
              ),
              Text(_decayLabel(i18n), style: theme.textTheme.labelLarge),
              Slider(
                value: _decay,
                min: 0.7,
                max: 1.8,
                divisions: 22,
                onChanged: (value) => setState(() => _decay = value),
                onChangeEnd: (_) {
                  _invalidatePlayers();
                  unawaited(_warmUpActivePreset());
                },
              ),
              const SizedBox(height: 8),
              SectionHeader(
                title: pickUiText(i18n, zh: '调式与和弦', en: 'Scale and chord'),
                subtitle: pickUiText(
                  i18n,
                  zh: '按根音高亮常用调式和和弦，便于手机上分区观察。',
                  en: 'Highlight common scales and chords by root note for compact mobile viewing.',
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _scaleSets
                    .map(
                      (item) => ChoiceChip(
                        label: Text(_scaleLabel(i18n, item.id)),
                        selected: item.id == _scaleId,
                        onSelected: (_) => setState(() => _scaleId = item.id),
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
                        label: Text(_chordLabel(i18n, item.id)),
                        selected: item.id == _chordId,
                        onSelected: (_) => setState(() => _chordId = item.id),
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
                            onSelected: (_) =>
                                setState(() => _rootPitchClass = pitchClass),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
              const SizedBox(height: 8),
              SectionHeader(
                title: pickUiText(
                  i18n,
                  zh: '音域窗口',
                  en: 'Range window',
                  ja: '音域ウィンドウ',
                  de: 'Tonfenster',
                  fr: 'Fenetre de registre',
                  es: 'Ventana de registro',
                  ru: 'Range window',
                ),
                subtitle: pickUiText(
                  i18n,
                  zh: '基于 C1-C9 分段显示，屏幕不足时自动缩小窗口并保留切换。',
                  en: 'Segment the keyboard from C1 to C9 and switch windows when screen space is limited.',
                ),
              ),
              const SizedBox(height: 10),
              _buildRangeNavigator(
                context,
                i18n,
                octaveSpan: octaveSpan,
                rangeStart: rangeStart,
                slice: slice,
              ),
              const SizedBox(height: 12),
              SectionHeader(
                title: pickUiText(
                  i18n,
                  zh: '键盘',
                  en: 'Keyboard',
                  ja: '鍵盤',
                  de: 'Klaviatur',
                  fr: 'Clavier',
                  es: 'Teclado',
                  ru: 'Keyboard',
                ),
                subtitle: pickUiText(
                  i18n,
                  zh: '优先保证演奏区域，宽度不足时只切换窗口，不压缩琴键。',
                  en: 'Prioritize playable key width by switching windows instead of crushing the keyboard.',
                ),
              ),
              const SizedBox(height: 8),
              _buildKeyboardStage(
                context,
                slice,
                maxWidth: constraints.maxWidth,
                octaveSpan: octaveSpan,
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

class _PianoBlackKeyPlacement {
  const _PianoBlackKeyPlacement({required this.key, required this.slot});

  final _PianoKey key;
  final int slot;
}

class _PianoPitchSet {
  const _PianoPitchSet({required this.id, required this.intervals});

  final String id;
  final List<int> intervals;
}

class _PianoOverlayChip extends StatelessWidget {
  const _PianoOverlayChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.34),
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
  for (var octave = 1; octave <= 8; octave += 1) {
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
      id: 'C9',
      label: 'C9',
      frequency: (440 * math.pow(2, (_midiFromParts('C', 9) - 69) / 12))
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
