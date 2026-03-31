part of '../toolbox_sound_tools.dart';

class _FluteTool extends StatefulWidget {
  const _FluteTool({this.fullScreen = false});

  final bool fullScreen;

  @override
  State<_FluteTool> createState() => _FluteToolState();
}

class _FluteToolState extends State<_FluteTool> {
  static const List<_PianoKey> _majorNotes = <_PianoKey>[
    _PianoKey(id: 'C5', label: 'C', frequency: 523.25),
    _PianoKey(id: 'D5', label: 'D', frequency: 587.33),
    _PianoKey(id: 'E5', label: 'E', frequency: 659.25),
    _PianoKey(id: 'F5', label: 'F', frequency: 698.46),
    _PianoKey(id: 'G5', label: 'G', frequency: 783.99),
    _PianoKey(id: 'A5', label: 'A', frequency: 880.0),
    _PianoKey(id: 'B5', label: 'B', frequency: 987.77),
  ];
  static const List<_PianoKey> _pentatonicNotes = <_PianoKey>[
    _PianoKey(id: 'C5', label: 'C', frequency: 523.25),
    _PianoKey(id: 'D5', label: 'D', frequency: 587.33),
    _PianoKey(id: 'E5', label: 'E', frequency: 659.25),
    _PianoKey(id: 'G5', label: 'G', frequency: 783.99),
    _PianoKey(id: 'A5', label: 'A', frequency: 880.0),
    _PianoKey(id: 'C6', label: 'C6', frequency: 1046.5),
  ];
  static const List<_PianoKey> _dorianNotes = <_PianoKey>[
    _PianoKey(id: 'D5', label: 'D', frequency: 587.33),
    _PianoKey(id: 'E5', label: 'E', frequency: 659.25),
    _PianoKey(id: 'F5', label: 'F', frequency: 698.46),
    _PianoKey(id: 'G5', label: 'G', frequency: 783.99),
    _PianoKey(id: 'A5', label: 'A', frequency: 880.0),
    _PianoKey(id: 'B5', label: 'B', frequency: 987.77),
    _PianoKey(id: 'C6', label: 'C6', frequency: 1046.5),
  ];
  static const List<_FlutePreset> _presets = <_FlutePreset>[
    _FlutePreset(
      id: 'airy_flow',
      styleId: 'airy',
      materialId: 'wood',
      scaleId: 'major',
      breath: 0.76,
      reverb: 0.24,
      tail: 0.64,
    ),
    _FlutePreset(
      id: 'lead_solo',
      styleId: 'lead',
      materialId: 'metal_short',
      scaleId: 'pentatonic',
      breath: 0.86,
      reverb: 0.16,
      tail: 0.42,
    ),
    _FlutePreset(
      id: 'alto_warm',
      styleId: 'alto',
      materialId: 'jade',
      scaleId: 'dorian',
      breath: 0.68,
      reverb: 0.28,
      tail: 0.78,
    ),
  ];

  final Map<String, ToolboxEffectPlayer> _players =
      <String, ToolboxEffectPlayer>{};
  final AudioRecorder _micRecorder = AudioRecorder();
  final ToolboxLoopController _sustainCoreLoop = ToolboxLoopController();
  final ToolboxLoopController _sustainAirLoop = ToolboxLoopController();
  final ToolboxLoopController _sustainEdgeLoop = ToolboxLoopController();
  StreamSubscription<Amplitude>? _amplitudeSub;
  final Set<int> _pressedHoles = <int>{};
  final Map<int, int> _activeHolePointers = <int, int>{};
  String _presetId = _presets.first.id;
  String _scale = _presets.first.scaleId;
  String _style = _presets.first.styleId;
  String _material = _presets.first.materialId;
  double _breath = _presets.first.breath;
  double _airSpace = _presets.first.reverb;
  double _tail = _presets.first.tail;
  bool _blowSensorEnabled = false;
  bool _blowPermissionDenied = false;
  bool _isBlowing = false;
  double _micLevel = 0;
  double _breathConfidence = 0;
  double _blowThreshold = 0.34;
  int? _sustainedNoteIndex;
  String? _sustainSignature;
  String? _lastNote;
  int _warmUpSerial = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_warmUpActivePreset());
    });
  }

  _FlutePreset get _activePreset {
    return _presets.firstWhere(
      (item) => item.id == _presetId,
      orElse: () => _presets.first,
    );
  }

  List<_PianoKey> get _activeNotes {
    return switch (_scale) {
      'pentatonic' => _pentatonicNotes,
      'dorian' => _dorianNotes,
      _ => _majorNotes,
    };
  }

  String _presetLabel(AppI18n i18n, _FlutePreset preset) {
    return switch (preset.id) {
      'lead_solo' => pickUiText(
        i18n,
        zh: '独奏领奏',
        en: 'Lead solo',
        ja: 'リードソロ',
        de: 'Lead-Solo',
        fr: 'Solo lead',
        es: 'Solo lead',
        ru: 'Лид-соло',
      ),
      'alto_warm' => pickUiText(
        i18n,
        zh: '暖音中音',
        en: 'Warm alto',
        ja: 'ウォームアルト',
        de: 'Warmes Alt',
        fr: 'Alto chaud',
        es: 'Alto cálido',
        ru: 'Тёплый альт',
      ),
      _ => pickUiText(
        i18n,
        zh: '空气流',
        en: 'Airy flow',
        ja: 'エアリーフロー',
        de: 'Luftiger Fluss',
        fr: 'Flux aérien',
        es: 'Flujo aéreo',
        ru: 'Воздушный поток',
      ),
    };
  }

  String _presetSubtitle(AppI18n i18n, _FlutePreset preset) {
    return switch (preset.id) {
      'lead_solo' => pickUiText(
        i18n,
        zh: '更亮、更靠前，适合旋律句的突出。',
        en: 'Brighter lead tone with stronger presence for melodic phrases.',
        ja: '明るく前に出る音色で、主旋律を際立たせます。',
        de: 'Hellerer Lead-Sound mit mehr Präsenz für Melodielinien.',
        fr: 'Timbre plus brillant et présent pour les lignes mélodiques.',
        es: 'Tono más brillante y presente para frases melódicas.',
        ru: 'Более яркий и выдвинутый тембр для мелодических фраз.',
      ),
      'alto_warm' => pickUiText(
        i18n,
        zh: '更厚实的中频和更柔和尾音，适合氛围铺底。',
        en: 'Warmer midrange and softer tail for calm backing layers.',
        ja: '中域を厚くし、余韻を柔らかくした落ち着いたトーン。',
        de: 'Wärmere Mitten und weicheres Ausklingen für ruhige Flächen.',
        fr: 'Médiums plus chauds et fin de note douce pour des nappes calmes.',
        es: 'Medios más cálidos y cola suave para capas tranquilas.',
        ru: 'Тёплая середина и мягкий хвост для спокойной подложки.',
      ),
      _ => pickUiText(
        i18n,
        zh: '自然气息感，适合轻柔演奏。',
        en: 'Natural breathy tone for gentle and flowing play.',
        ja: '自然な息づかいで、やわらかな演奏に向きます。',
        de: 'Natürlicher, luftiger Klang für sanftes Spiel.',
        fr: 'Souffle naturel pour un jeu doux et fluide.',
        es: 'Tono de soplo natural para tocar suave y fluido.',
        ru: 'Естественное дыхание тембра для мягкой и плавной игры.',
      ),
    };
  }

  String _scaleLabel(AppI18n i18n, String scaleId) {
    return switch (scaleId) {
      'pentatonic' => pickUiText(
        i18n,
        zh: '五声音阶',
        en: 'Pentatonic',
        ja: 'ペンタトニック',
        de: 'Pentatonik',
        fr: 'Pentatonique',
        es: 'Pentatónica',
        ru: 'Пентатоника',
      ),
      'dorian' => pickUiText(
        i18n,
        zh: '多利亚',
        en: 'Dorian',
        ja: 'ドリアン',
        de: 'Dorisch',
        fr: 'Dorien',
        es: 'Dórico',
        ru: 'Дорийский',
      ),
      _ => pickUiText(
        i18n,
        zh: '大调',
        en: 'Major',
        ja: 'メジャー',
        de: 'Dur',
        fr: 'Majeur',
        es: 'Mayor',
        ru: 'Мажор',
      ),
    };
  }

  String _styleLabel(AppI18n i18n, String styleId) {
    return switch (styleId) {
      'lead' => pickUiText(
        i18n,
        zh: '领奏',
        en: 'Lead',
        ja: 'リード',
        de: 'Lead',
        fr: 'Lead',
        es: 'Lead',
        ru: 'Лид',
      ),
      'alto' => pickUiText(
        i18n,
        zh: '中音',
        en: 'Alto',
        ja: 'アルト',
        de: 'Alt',
        fr: 'Alto',
        es: 'Alto',
        ru: 'Альт',
      ),
      _ => pickUiText(
        i18n,
        zh: '空气',
        en: 'Airy',
        ja: 'エアリー',
        de: 'Luftig',
        fr: 'Aérien',
        es: 'Aéreo',
        ru: 'Воздушный',
      ),
    };
  }

  String _materialLabel(AppI18n i18n, String materialId) {
    return switch (materialId) {
      'metal_short' => pickUiText(i18n, zh: '短铁笛', en: 'Short metal'),
      'metal_long' => pickUiText(i18n, zh: '长铁笛', en: 'Long metal'),
      'jade' => pickUiText(i18n, zh: '玉笛', en: 'Jade flute'),
      'clay' => pickUiText(i18n, zh: '陶笛', en: 'Clay ocarina'),
      _ => pickUiText(i18n, zh: '木笛', en: 'Wood flute'),
    };
  }

  double get _performanceBreathLevel {
    final micContribution = _blowSensorEnabled ? _micLevel * 0.7 : 0.0;
    final baseContribution = _breath * (_blowSensorEnabled ? 0.55 : 1.0);
    return (baseContribution + micContribution).clamp(0.18, 1.0).toDouble();
  }

  double _sustainFrequencyFor(_PianoKey note) {
    final breathLevel = _performanceBreathLevel;
    final cents = switch (_material) {
      'metal_short' => 2.5,
      'metal_long' => -1.5,
      'jade' => 1.2,
      'clay' => -3.0,
      _ => 0.6,
    };
    final dynamicLift = (breathLevel - 0.5) * cents;
    final overblow = breathLevel >= 0.86 && _pressedHoles.length <= 2 ? 12 : 0;
    final shifted = note.frequency * math.pow(2, overblow / 12).toDouble();
    return shifted * math.pow(2, dynamicLift / 1200).toDouble();
  }

  String _sustainSignatureFor(_PianoKey note) {
    final overblowRegister =
        _performanceBreathLevel >= 0.86 && _pressedHoles.length <= 2 ? 1 : 0;
    return '${note.id}:$_style:$_material:$overblowRegister';
  }

  ({double core, double air, double edge}) _sustainLayerMix() {
    final breathLevel = _performanceBreathLevel;
    final core = (0.18 + breathLevel * 0.52).clamp(0.0, 1.0).toDouble();
    final air = switch (_material) {
      'metal_short' => (0.04 + breathLevel * 0.16).clamp(0.0, 0.4).toDouble(),
      'metal_long' => (0.04 + breathLevel * 0.14).clamp(0.0, 0.38).toDouble(),
      'jade' => (0.03 + breathLevel * 0.1).clamp(0.0, 0.28).toDouble(),
      'clay' => (0.02 + breathLevel * 0.08).clamp(0.0, 0.24).toDouble(),
      _ => (0.05 + breathLevel * 0.2).clamp(0.0, 0.44).toDouble(),
    };
    final edge = switch (_material) {
      'metal_short' => (0.08 + breathLevel * 0.24).clamp(0.0, 0.5).toDouble(),
      'metal_long' => (0.06 + breathLevel * 0.2).clamp(0.0, 0.42).toDouble(),
      'jade' => (0.03 + breathLevel * 0.12).clamp(0.0, 0.28).toDouble(),
      'clay' => (0.02 + breathLevel * 0.08).clamp(0.0, 0.2).toDouble(),
      _ => (0.04 + breathLevel * 0.14).clamp(0.0, 0.32).toDouble(),
    };
    return (core: core, air: air, edge: edge);
  }

  Future<void> _setSustainLayerVolumes() async {
    final mix = _sustainLayerMix();
    await Future.wait<void>(<Future<void>>[
      _sustainCoreLoop.setVolume(mix.core),
      _sustainAirLoop.setVolume(mix.air),
      _sustainEdgeLoop.setVolume(mix.edge),
    ]);
  }

  Future<void> _stopSustainLayers() async {
    await Future.wait<void>(<Future<void>>[
      _sustainCoreLoop.stop(),
      _sustainAirLoop.stop(),
      _sustainEdgeLoop.stop(),
    ]);
  }

  double _normalizedMicLevel(Amplitude amplitude) {
    final value = amplitude.current;
    if (value.isNaN || value.isInfinite) return 0;
    if (value >= 0 && value <= 1.2) {
      return value.clamp(0.0, 1.0).toDouble();
    }
    return ((value + 60) / 60).clamp(0.0, 1.0).toDouble();
  }

  double _filteredBreathLevel(double rawLevel) {
    final floor = _blowThreshold * 0.58;
    if (rawLevel <= floor) {
      return 0;
    }
    final normalized = ((rawLevel - floor) / (1 - floor)).clamp(0.0, 1.0);
    return math.pow(normalized, 1.35).toDouble();
  }

  String _fingeringSignature(Set<int> holes) {
    final ordered = holes.toList()..sort();
    return ordered.join('-');
  }

  List<_FluteFingering> get _activeFingerings {
    return switch (_scale) {
      'pentatonic' => const <_FluteFingering>[
        _FluteFingering(signature: '1-2-3-4-5-6', noteIndex: 0),
        _FluteFingering(signature: '1-2-3-4-5', noteIndex: 1),
        _FluteFingering(signature: '1-2-3-4', noteIndex: 2),
        _FluteFingering(signature: '1-2', noteIndex: 3),
        _FluteFingering(signature: '1', noteIndex: 4),
        _FluteFingering(signature: '', noteIndex: 5),
      ],
      'dorian' => const <_FluteFingering>[
        _FluteFingering(signature: '1-2-3-4-5-6', noteIndex: 0),
        _FluteFingering(signature: '1-2-3-4-5', noteIndex: 1),
        _FluteFingering(signature: '1-2-3-4', noteIndex: 2),
        _FluteFingering(signature: '1-2-3', noteIndex: 3),
        _FluteFingering(signature: '1-2', noteIndex: 4),
        _FluteFingering(signature: '1', noteIndex: 5),
        _FluteFingering(signature: '', noteIndex: 6),
      ],
      _ => const <_FluteFingering>[
        _FluteFingering(signature: '1-2-3-4-5-6', noteIndex: 0),
        _FluteFingering(signature: '1-2-3-4-5', noteIndex: 1),
        _FluteFingering(signature: '1-2-3-4', noteIndex: 2),
        _FluteFingering(signature: '1-2-3', noteIndex: 3),
        _FluteFingering(signature: '1-2', noteIndex: 4),
        _FluteFingering(signature: '1', noteIndex: 5),
        _FluteFingering(signature: '', noteIndex: 6),
      ],
    };
  }

  int? _noteIndexFromHoles() {
    final notes = _activeNotes;
    if (notes.isEmpty) return null;
    final signature = _fingeringSignature(_pressedHoles);
    for (final fingering in _activeFingerings) {
      if (fingering.signature == signature) {
        return fingering.noteIndex.clamp(0, notes.length - 1);
      }
    }
    return null;
  }

  Future<void> _syncBreathSustain() async {
    final nextIndex = (_blowSensorEnabled && _isBlowing)
        ? _noteIndexFromHoles()
        : null;
    if (nextIndex == null) {
      if (_sustainedNoteIndex != null) {
        _sustainedNoteIndex = null;
        _sustainSignature = null;
        await _stopSustainLayers();
      }
      return;
    }
    final note = _activeNotes[nextIndex];
    final nextSignature = _sustainSignatureFor(note);
    if (_sustainedNoteIndex == nextIndex && _sustainSignature == nextSignature) {
      await _setSustainLayerVolumes();
      return;
    }
    _sustainedNoteIndex = nextIndex;
    _sustainSignature = nextSignature;
    _lastNote = note.label;
    final sustainFrequency = _sustainFrequencyFor(note);
    final mix = _sustainLayerMix();
    await Future.wait<void>(<Future<void>>[
      _sustainCoreLoop.play(
        ToolboxAudioBank.fluteSustainCore(
          sustainFrequency,
          style: _style,
          material: _material,
        ),
        volume: mix.core,
      ),
      _sustainAirLoop.play(
        ToolboxAudioBank.fluteSustainAir(
          sustainFrequency,
          style: _style,
          material: _material,
        ),
        volume: mix.air,
      ),
      _sustainEdgeLoop.play(
        ToolboxAudioBank.fluteSustainEdge(
          sustainFrequency,
          style: _style,
          material: _material,
        ),
        volume: mix.edge,
      ),
    ]);
    if (mounted) {
      setState(() {});
    }
  }

  void _setHolePressed(int index, bool pressed) {
    var changed = false;
    if (pressed) {
      changed = _pressedHoles.add(index);
    } else {
      changed = _pressedHoles.remove(index);
    }
    if (!changed) return;
    if (mounted) {
      setState(() {});
    }
    unawaited(_syncBreathSustain());
  }

  void _bindHolePointer(int holeNumber, PointerDownEvent event) {
    _activeHolePointers[event.pointer] = holeNumber;
    _setHolePressed(holeNumber, true);
  }

  void _releaseHolePointer(PointerEvent event, int holeNumber) {
    final boundHole = _activeHolePointers.remove(event.pointer);
    if (boundHole != holeNumber) {
      return;
    }
    _setHolePressed(holeNumber, false);
  }

  Future<void> _startBlowSensor() async {
    if (_blowSensorEnabled) return;
    try {
      final granted = await _micRecorder.hasPermission();
      if (!granted) {
        if (mounted) {
          setState(() {
            _blowPermissionDenied = true;
            _blowSensorEnabled = false;
            _isBlowing = false;
            _micLevel = 0;
          });
        }
        await _syncBreathSustain();
        return;
      }
      await _micRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path:
            '${Directory.systemTemp.path}${Platform.pathSeparator}'
            'flute_blow_meter_${DateTime.now().microsecondsSinceEpoch}.wav',
      );
      await _amplitudeSub?.cancel();
      await _stopSustainLayers();
      _amplitudeSub = _micRecorder
          .onAmplitudeChanged(const Duration(milliseconds: 60))
          .listen((amplitude) {
            final rawLevel = _normalizedMicLevel(amplitude);
            final filtered = _filteredBreathLevel(rawLevel);
            final level = (_micLevel * 0.7 + filtered * 0.3).clamp(0.0, 1.0);
            final onsetCandidate = level >= (_blowThreshold + 0.03);
            final confidence = (_breathConfidence * 0.72 +
                    (onsetCandidate ? 1.0 : 0.0) * 0.28)
                .clamp(0.0, 1.0);
            final hysteresis = 0.05;
            final blowing = _isBlowing
                ? level >= (_blowThreshold - hysteresis) || confidence >= 0.42
                : confidence >= 0.58 && level >= (_blowThreshold - 0.01);
            var shouldRefresh = false;
            final levelChanged = (_micLevel - level).abs() > 0.018;
            if (levelChanged) {
              _micLevel = level;
              shouldRefresh = true;
            }
            if ((_breathConfidence - confidence).abs() > 0.03) {
              _breathConfidence = confidence;
              shouldRefresh = true;
            }
            if (_isBlowing != blowing) {
              _isBlowing = blowing;
              shouldRefresh = true;
              unawaited(_syncBreathSustain());
            } else if (_blowSensorEnabled && _isBlowing && levelChanged) {
              unawaited(_syncBreathSustain());
            }
            if (shouldRefresh && mounted) {
              setState(() {});
            }
          });
      if (mounted) {
        setState(() {
          _blowSensorEnabled = true;
          _blowPermissionDenied = false;
          _isBlowing = false;
          _micLevel = 0;
          _breathConfidence = 0;
        });
      }
      unawaited(_warmUpActivePreset());
    } catch (_) {
      if (mounted) {
        setState(() {
          _blowPermissionDenied = true;
          _blowSensorEnabled = false;
          _isBlowing = false;
          _micLevel = 0;
          _breathConfidence = 0;
        });
      }
      await _syncBreathSustain();
    }
  }

  Future<void> _stopBlowSensor({bool resetUi = true}) async {
    await _amplitudeSub?.cancel();
    _amplitudeSub = null;
    try {
      await _micRecorder.stop();
    } catch (_) {}
    _isBlowing = false;
    _blowSensorEnabled = false;
    if (resetUi) {
      _micLevel = 0;
      _breathConfidence = 0;
    }
    await _syncBreathSustain();
    if (resetUi && mounted) {
      setState(() {});
    }
  }

  Future<void> _toggleBlowSensor() async {
    if (_blowSensorEnabled) {
      await _stopBlowSensor();
      return;
    }
    await _startBlowSensor();
  }

  Future<void> _disposeMicRecorder() async {
    try {
      await _micRecorder.stop();
    } catch (_) {}
    try {
      await _micRecorder.dispose();
    } catch (_) {}
  }

  void _invalidatePlayers() {
    for (final player in _players.values) {
      unawaited(player.dispose());
    }
    _players.clear();
  }

  Future<void> _warmUpActivePreset() async {
    final serial = ++_warmUpSerial;
    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (!mounted || serial != _warmUpSerial) {
      return;
    }
    for (final note in _activeNotes.take(2)) {
      if (!mounted || serial != _warmUpSerial) {
        return;
      }
      await _playerFor(note).warmUp();
    }
  }

  void _applyPreset(String presetId) {
    final preset = _presets.firstWhere(
      (item) => item.id == presetId,
      orElse: () => _presets.first,
    );
    setState(() {
      _presetId = preset.id;
      _style = preset.styleId;
      _material = preset.materialId;
      _scale = preset.scaleId;
      _breath = preset.breath;
      _airSpace = preset.reverb;
      _tail = preset.tail;
    });
    _invalidatePlayers();
    unawaited(_syncBreathSustain());
    unawaited(_warmUpActivePreset());
  }

  ToolboxEffectPlayer _playerFor(_PianoKey key) {
    final breathLevel = _performanceBreathLevel;
    final cacheKey =
        'flute:${key.id}:$_style:$_material:${breathLevel.toStringAsFixed(2)}:${_airSpace.toStringAsFixed(2)}:${_tail.toStringAsFixed(2)}';
    final existing = _players[cacheKey];
    if (existing != null) return existing;
    final created = ToolboxEffectPlayer(
      ToolboxAudioBank.fluteNote(
        key.frequency,
        style: _style,
        material: _material,
        breath: breathLevel,
        reverb: _airSpace,
        tail: _tail,
      ),
      maxPlayers: 6,
    );
    _players[cacheKey] = created;
    return created;
  }

  Future<void> _play(_PianoKey key) async {
    HapticFeedback.selectionClick();
    unawaited(_playerFor(key).play(volume: _performanceBreathLevel.clamp(0.18, 1.0)));
    if (!mounted) return;
    setState(() {
      _lastNote = key.label;
    });
  }

  void _refreshSound() {
    _warmUpSerial += 1;
    _invalidatePlayers();
    unawaited(_stopSustainLayers());
    unawaited(_syncBreathSustain());
    unawaited(_warmUpActivePreset());
  }

  void _setScale(String value) {
    if (_scale == value) return;
    setState(() {
      _scale = value;
    });
    _refreshSound();
  }

  void _setStyle(String value) {
    if (_style == value) return;
    setState(() {
      _style = value;
    });
    _refreshSound();
  }

  void _openFullScreen(BuildContext context) {
    if (widget.fullScreen) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(
          backgroundColor: Colors.black,
          body: _FluteTool(fullScreen: true),
        ),
      ),
    );
  }

  Widget _buildFingerHole(
    BuildContext context,
    int holeNumber, {
    double diameter = 64,
  }) {
    final theme = Theme.of(context);
    final pressed = _pressedHoles.contains(holeNumber);
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) => _bindHolePointer(holeNumber, event),
      onPointerUp: (event) => _releaseHolePointer(event, holeNumber),
      onPointerCancel: (event) => _releaseHolePointer(event, holeNumber),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: pressed ? const Color(0xFF1D4ED8) : const Color(0xFF18314F),
          border: Border.all(
            color: pressed
                ? const Color(0xFF93C5FD)
                : Colors.white.withValues(alpha: 0.22),
            width: 2,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
            if (pressed)
              BoxShadow(
                color: const Color(0xFF60A5FA).withValues(alpha: 0.35),
                blurRadius: 18,
                spreadRadius: 1,
              ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          '$holeNumber',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickNoteChip(
    BuildContext context,
    _PianoKey note, {
    required bool immersive,
  }) {
    final active = _lastNote == note.label;
    return FilledButton.tonal(
      onPressed: () => unawaited(_play(note)),
      style: FilledButton.styleFrom(
        backgroundColor: active
            ? const Color(0xFFDBEAFE)
            : Colors.white.withValues(alpha: immersive ? 0.12 : 1),
        foregroundColor: active ? const Color(0xFF1D4ED8) : null,
        visualDensity: VisualDensity.compact,
      ),
      child: Text(note.label),
    );
  }

  Widget _buildBreathStatusRail(
    BuildContext context,
    AppI18n i18n, {
    required bool immersive,
  }) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 64,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: immersive ? 0.28 : 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: immersive ? 0.14 : 0.36),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                pickUiText(i18n, zh: '吹奏', en: 'Breath'),
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: immersive ? Colors.white70 : const Color(0xFF475569),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              RotatedBox(
                quarterTurns: 3,
                child: SizedBox(
                  width: 112,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: _micLevel.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _blowSensorEnabled
                    ? '${(100 * _blowThreshold).round()}%'
                    : pickUiText(i18n, zh: '关闭', en: 'Off'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: immersive ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _materialLabel(i18n, _material),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: immersive ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFluteStage(
    BuildContext context, {
    required AppI18n i18n,
    required bool immersive,
  }) {
    final theme = Theme.of(context);
    final noteButtons = _activeNotes
        .map(
          (note) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildQuickNoteChip(context, note, immersive: immersive),
          ),
        )
        .toList(growable: false);
    final stageHeight = widget.fullScreen ? null : 620.0;
    return Container(
      width: double.infinity,
      height: stageHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.fullScreen ? 30 : 28),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            widget.fullScreen
                ? const Color(0xFF07111F)
                : const Color(0xFFEAF5FF),
            widget.fullScreen
                ? const Color(0xFF0F2137)
                : const Color(0xFFD8EBFF),
            widget.fullScreen
                ? const Color(0xFF122945)
                : const Color(0xFFC4DFFF),
          ],
        ),
        border: Border.all(
          color: widget.fullScreen
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.72),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: immersive ? 0.32 : 0.12),
            blurRadius: immersive ? 28 : 18,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          widget.fullScreen ? 18 : 16,
          widget.fullScreen ? 18 : 16,
          widget.fullScreen ? 18 : 16,
          widget.fullScreen ? 18 : 16,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tubeWidth = math.min(164.0, constraints.maxWidth * 0.42);
            final holeSize = widget.fullScreen ? 72.0 : 62.0;
            return Stack(
              children: <Widget>[
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: tubeWidth,
                    height: constraints.maxHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[
                          widget.fullScreen
                              ? const Color(0xFFF8FBFF)
                              : const Color(0xFFFFFFFF),
                          widget.fullScreen
                              ? const Color(0xFFD5E3F7)
                              : const Color(0xFFE8F1FB),
                          widget.fullScreen
                              ? const Color(0xFFABC4E5)
                              : const Color(0xFFC9DCF5),
                        ],
                      ),
                    ),
                    child: Column(
                      children: <Widget>[
                        const SizedBox(height: 32),
                        Container(
                          width: tubeWidth * 0.56,
                          height: 18,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: const Color(0xFF274060),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List<Widget>.generate(6, (index) {
                              return _buildFingerHole(
                                context,
                                index + 1,
                                diameter: holeSize,
                              );
                            }),
                          ),
                        ),
                        Container(
                          width: tubeWidth * 0.68,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: const Color(0xFFD8E6F7),
                            border: Border.all(
                              color: const Color(0xFFACC3E0),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _lastNote ?? '--',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: const Color(0xFF0F172A),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: noteButtons,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFluteSettingsContent(BuildContext context, AppI18n i18n) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          pickUiText(i18n, zh: '长笛设置', en: 'Flute settings'),
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            ToolboxMetricCard(label: 'Preset', value: _presetLabel(i18n, _activePreset)),
            ToolboxMetricCard(label: 'Scale', value: _scaleLabel(i18n, _scale)),
            ToolboxMetricCard(label: 'Tone', value: _styleLabel(i18n, _style)),
            ToolboxMetricCard(label: 'Material', value: _materialLabel(i18n, _material)),
            ToolboxMetricCard(label: 'Last', value: _lastNote ?? '--'),
          ],
        ),
        const SizedBox(height: 20),
        _buildSettingsSectionTitle(context, pickUiText(i18n, zh: '预设包', en: 'Preset pack')),
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
        Text(_presetSubtitle(i18n, _activePreset), style: theme.textTheme.bodySmall),
        const SizedBox(height: 20),
        _buildSettingsSectionTitle(context, pickUiText(i18n, zh: '调式', en: 'Scale')),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <String>['major', 'pentatonic', 'dorian']
              .map(
                (item) => ChoiceChip(
                  label: Text(_scaleLabel(i18n, item)),
                  selected: _scale == item,
                  onSelected: (_) => _setScale(item),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 20),
        _buildSettingsSectionTitle(context, pickUiText(i18n, zh: '音色拟真', en: 'Timbre')),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <String>['airy', 'lead', 'alto', 'bamboo']
              .map(
                (item) => ChoiceChip(
                  label: Text(_styleLabel(i18n, item)),
                  selected: _style == item,
                  onSelected: (_) => _setStyle(item),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 20),
        _buildSettingsSectionTitle(context, pickUiText(i18n, zh: '材质音色', en: 'Material')),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <String>['wood', 'metal_short', 'metal_long', 'jade', 'clay']
              .map(
                (item) => ChoiceChip(
                  label: Text(_materialLabel(i18n, item)),
                  selected: _material == item,
                  onSelected: (_) {
                    if (_material == item) return;
                    setState(() {
                      _material = item;
                    });
                    _refreshSound();
                  },
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 20),
        _buildSettingsSectionTitle(context, pickUiText(i18n, zh: '气息与空间', en: 'Breath and space')),
        Text(
          pickUiText(i18n, zh: '气息 ${(_breath * 100).round()}%', en: 'Breath ${(_breath * 100).round()}%'),
          style: theme.textTheme.labelLarge,
        ),
        Slider(
          value: _breath,
          min: 0.2,
          max: 1.0,
          divisions: 16,
          onChanged: (value) {
            setState(() => _breath = value);
            unawaited(_syncBreathSustain());
          },
        ),
        Text(
          pickUiText(i18n, zh: '空间 ${(_airSpace * 100).round()}%', en: 'Space ${(_airSpace * 100).round()}%'),
          style: theme.textTheme.labelLarge,
        ),
        Slider(
          value: _airSpace,
          min: 0.0,
          max: 0.5,
          divisions: 10,
          onChanged: (value) => setState(() => _airSpace = value),
          onChangeEnd: (_) => _refreshSound(),
        ),
        Text(
          pickUiText(i18n, zh: '尾音 ${(_tail * 100).round()}%', en: 'Tail ${(_tail * 100).round()}%'),
          style: theme.textTheme.labelLarge,
        ),
        Slider(
          value: _tail,
          min: 0.15,
          max: 1.0,
          divisions: 17,
          onChanged: (value) => setState(() => _tail = value),
          onChangeEnd: (_) => _refreshSound(),
        ),
        const SizedBox(height: 20),
        _buildSettingsSectionTitle(context, pickUiText(i18n, zh: '吹气检测', en: 'Blow sensor')),
        FilledButton.tonalIcon(
          onPressed: _toggleBlowSensor,
          icon: Icon(_blowSensorEnabled ? Icons.mic_rounded : Icons.mic_off_rounded),
          label: Text(
            _blowSensorEnabled
                ? pickUiText(i18n, zh: '关闭吹气检测', en: 'Disable blow sensor')
                : pickUiText(i18n, zh: '开启吹气检测', en: 'Enable blow sensor'),
          ),
        ),
        if (_blowPermissionDenied) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            pickUiText(i18n, zh: '麦克风权限不可用', en: 'Microphone permission unavailable'),
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          pickUiText(
            i18n,
            zh: '吹气阈值 ${(_blowThreshold * 100).round()}% · 当前 ${(_micLevel * 100).round()}%',
            en: 'Threshold ${(_blowThreshold * 100).round()}% · Current ${(_micLevel * 100).round()}%',
          ),
          style: theme.textTheme.labelLarge,
        ),
        Slider(
          value: _blowThreshold,
          min: 0.12,
          max: 0.75,
          divisions: 21,
          onChanged: (value) => setState(() => _blowThreshold = value),
        ),
      ],
    );
  }

  Future<void> _openFluteSettingsSheet(BuildContext context, AppI18n i18n) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            4,
            16,
            16 + MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: SingleChildScrollView(
            child: _buildFluteSettingsContent(sheetContext, i18n),
          ),
        );
      },
    );
  }

  Widget _buildFluteFullScreen(BuildContext context, AppI18n i18n) {
    final topInset = MediaQuery.viewPaddingOf(context).top;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF04101E),
            Color(0xFF0A1B31),
            Color(0xFF102541),
          ],
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.fromLTRB(52, topInset + 8, 12, 12),
              child: _buildFluteStage(context, i18n: i18n, immersive: true),
            ),
          ),
          Positioned(
            left: 10,
            top: topInset + 96,
            bottom: 20,
            child: Align(
              alignment: Alignment.center,
              child: _buildBreathStatusRail(context, i18n, immersive: true),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            top: topInset + 10,
            child: Row(
              children: <Widget>[
                FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.30),
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Icon(Icons.arrow_back_rounded),
                ),
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: () => _openFluteSettingsSheet(context, i18n),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.30),
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.tune_rounded),
                  label: Text(pickUiText(i18n, zh: '设置', en: 'Settings')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  @override
  void dispose() {
    final amplitudeSub = _amplitudeSub;
    _amplitudeSub = null;
    if (amplitudeSub != null) {
      unawaited(amplitudeSub.cancel());
    }
    unawaited(_disposeMicRecorder());
    unawaited(_sustainCoreLoop.dispose());
    unawaited(_sustainAirLoop.dispose());
    unawaited(_sustainEdgeLoop.dispose());
    _invalidatePlayers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    final theme = Theme.of(context);
    final preset = _activePreset;
    const panelStageHeight = 620.0;
    if (widget.fullScreen) {
      return _buildFluteFullScreen(context, i18n);
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
              ToolboxMetricCard(label: 'Preset', value: _presetLabel(i18n, preset)),
              ToolboxMetricCard(label: 'Scale', value: _scaleLabel(i18n, _scale)),
              ToolboxMetricCard(label: 'Tone', value: _styleLabel(i18n, _style)),
              ToolboxMetricCard(label: 'Material', value: _materialLabel(i18n, _material)),
              ToolboxMetricCard(label: 'Last note', value: _lastNote ?? '--'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: SectionHeader(
                  title: pickUiText(i18n, zh: '纵向长笛', en: 'Vertical flute'),
                  subtitle: pickUiText(
                    i18n,
                    zh: '按手机竖屏重排长笛机身、按孔和音阶按钮，保留触控与吹气两种演奏路径。',
                    en: 'Rebuild the flute body, finger holes, and note rail for portrait phones.',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.tonalIcon(
                onPressed: () => _openFluteSettingsSheet(context, i18n),
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
                FilledButton.tonalIcon(
                  onPressed: _toggleBlowSensor,
                  icon: Icon(_blowSensorEnabled ? Icons.mic_rounded : Icons.mic_off_rounded),
                  label: Text(
                    _blowSensorEnabled
                        ? pickUiText(i18n, zh: '吹气开启', en: 'Blow on')
                        : pickUiText(i18n, zh: '吹气关闭', en: 'Blow off'),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _openFullScreen(context),
                  icon: const Icon(Icons.open_in_full_rounded),
                  label: Text(pickUiText(i18n, zh: '全屏', en: 'Full screen')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: panelStageHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildBreathStatusRail(context, i18n, immersive: false),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildFluteStage(
                    context,
                    i18n: i18n,
                    immersive: false,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            pickUiText(
              i18n,
              zh: '吹气阈值 ${(_blowThreshold * 100).round()}% · 当前 ${(_micLevel * 100).round()}% · 按孔 ${_pressedHoles.length}',
              en: 'Threshold ${(_blowThreshold * 100).round()}% · Current ${(_micLevel * 100).round()}% · Holes ${_pressedHoles.length}',
            ),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _micLevel.clamp(0.0, 1.0),
              minHeight: 8,
            ),
          ),
          if (_blowPermissionDenied) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              pickUiText(i18n, zh: '麦克风权限不可用，当前仅可使用触控演奏。', en: 'Microphone permission unavailable. Touch play is still available.'),
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            _presetSubtitle(i18n, preset),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _FluteFingering {
  const _FluteFingering({required this.signature, required this.noteIndex});

  final String signature;
  final int noteIndex;
}
