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
  static const List<_PianoKey> _minorNotes = <_PianoKey>[
    _PianoKey(id: 'C5', label: 'C', frequency: 523.25),
    _PianoKey(id: 'D5', label: 'D', frequency: 587.33),
    _PianoKey(id: 'Eb5', label: 'Eb', frequency: 622.25),
    _PianoKey(id: 'F5', label: 'F', frequency: 698.46),
    _PianoKey(id: 'G5', label: 'G', frequency: 783.99),
    _PianoKey(id: 'Ab5', label: 'Ab', frequency: 830.61),
    _PianoKey(id: 'Bb5', label: 'Bb', frequency: 932.33),
  ];
  static const List<_PianoKey> _mixolydianNotes = <_PianoKey>[
    _PianoKey(id: 'C5', label: 'C', frequency: 523.25),
    _PianoKey(id: 'D5', label: 'D', frequency: 587.33),
    _PianoKey(id: 'E5', label: 'E', frequency: 659.25),
    _PianoKey(id: 'F5', label: 'F', frequency: 698.46),
    _PianoKey(id: 'G5', label: 'G', frequency: 783.99),
    _PianoKey(id: 'A5', label: 'A', frequency: 880.0),
    _PianoKey(id: 'Bb5', label: 'Bb', frequency: 932.33),
  ];
  static const List<_PianoKey> _lydianNotes = <_PianoKey>[
    _PianoKey(id: 'C5', label: 'C', frequency: 523.25),
    _PianoKey(id: 'D5', label: 'D', frequency: 587.33),
    _PianoKey(id: 'E5', label: 'E', frequency: 659.25),
    _PianoKey(id: 'F#5', label: 'F#', frequency: 739.99),
    _PianoKey(id: 'G5', label: 'G', frequency: 783.99),
    _PianoKey(id: 'A5', label: 'A', frequency: 880.0),
    _PianoKey(id: 'B5', label: 'B', frequency: 987.77),
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
  final Map<int, int> _holePressCounts = <int, int>{};
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
  double _ambientNoiseFloor = 0;
  double _breathConfidence = 0;
  double _blowThreshold = 0.34;
  int? _sustainedNoteIndex;
  String? _sustainSignature;
  String? _lastNote;
  int _warmUpSerial = 0;
  int _sustainSyncSerial = 0;

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
      'minor' => _minorNotes,
      'mixolydian' => _mixolydianNotes,
      'lydian' => _lydianNotes,
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

  // ignore: unused_element
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

  // ignore: unused_element
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

  String _displayScaleLabel(AppI18n i18n, String scaleId) {
    return switch (scaleId) {
      'pentatonic' => pickUiText(i18n, zh: '五声音阶', en: 'Pentatonic'),
      'dorian' => pickUiText(i18n, zh: '多利亚', en: 'Dorian'),
      'minor' => pickUiText(i18n, zh: '自然小调', en: 'Natural minor'),
      'mixolydian' => pickUiText(i18n, zh: '混合利底亚', en: 'Mixolydian'),
      'lydian' => pickUiText(i18n, zh: '利底亚', en: 'Lydian'),
      _ => pickUiText(i18n, zh: '大调', en: 'Major'),
    };
  }

  String _displayStyleLabel(AppI18n i18n, String styleId) {
    return switch (styleId) {
      'lead' => pickUiText(i18n, zh: '领奏', en: 'Lead'),
      'alto' => pickUiText(i18n, zh: '中音', en: 'Alto'),
      'velvet' => pickUiText(i18n, zh: '绒感', en: 'Velvet'),
      'hollow' => pickUiText(i18n, zh: '空腔', en: 'Hollow'),
      'bamboo' => pickUiText(i18n, zh: '竹感', en: 'Bamboo'),
      _ => pickUiText(i18n, zh: '空气', en: 'Airy'),
    };
  }

  double get _manualBreathLevel {
    return (_breath * 0.78 + 0.18).clamp(0.18, 1.0).toDouble();
  }

  double get _performanceBreathLevel {
    final materialFactor = switch (_material) {
      'metal_short' => 1.08,
      'metal_long' => 1.04,
      'jade' => 0.96,
      'clay' => 0.92,
      _ => 1.0,
    };
    final manualLevel = _manualBreathLevel;
    final sensedLevel =
        (_micLevel * (0.76 + _breath * 0.18) + _breathConfidence * 0.14)
            .clamp(0.0, 1.0)
            .toDouble();
    final combined = _blowSensorEnabled
        ? (_isBlowing
              ? sensedLevel * 0.82 + manualLevel * 0.18
              : manualLevel * 0.42 + sensedLevel * 0.18)
        : manualLevel;
    final minimum = _blowSensorEnabled && !_isBlowing ? 0.0 : 0.14;
    return (combined * materialFactor).clamp(minimum, 1.0).toDouble();
  }

  double get _oneShotBreathLevel {
    if (!_blowSensorEnabled) {
      return _manualBreathLevel;
    }
    return math
        .max(_manualBreathLevel * 0.74, _performanceBreathLevel)
        .clamp(0.18, 1.0)
        .toDouble();
  }

  double _sustainFrequencyFor(_PianoKey note) {
    final breathLevel = _performanceBreathLevel;
    final baseCents = switch (_material) {
      'metal_short' => 3.2,
      'metal_long' => -2.0,
      'jade' => 1.5,
      'clay' => -3.5,
      _ => 0.8,
    };
    final styleShift = switch (_style) {
      'lead' => 1.2,
      'alto' => -0.8,
      'bamboo' => -0.5,
      'velvet' => -0.9,
      'hollow' => -1.15,
      _ => 0.0,
    };
    final dynamicLift = (breathLevel - 0.5) * (baseCents + styleShift);
    final overblowThreshold = switch (_material) {
      'metal_short' => 0.90,
      'metal_long' => 0.92,
      'jade' => 0.95,
      'clay' => 0.96,
      _ => 0.93,
    };
    final holeFactor = switch (_pressedHoles.length) {
      <= 1 => 1.0,
      2 => 0.45,
      _ => 0.0,
    };
    final breathOverThreshold =
        (breathLevel - overblowThreshold) / (1.0 - overblowThreshold);
    final overblowBlend = math
        .pow((breathOverThreshold * holeFactor).clamp(0.0, 1.0), 1.35)
        .toDouble();
    final overblow =
        overblowBlend *
        (switch (_material) {
          'metal_short' => 5.0,
          'metal_long' => 4.2,
          'jade' => 2.8,
          'clay' => 2.2,
          _ => 3.6,
        });
    final shifted = note.frequency * math.pow(2, overblow / 12).toDouble();
    return shifted * math.pow(2, dynamicLift / 1200).toDouble();
  }

  String _sustainSignatureFor(_PianoKey note) {
    final breathLevel = _performanceBreathLevel;
    final overblowThreshold = switch (_material) {
      'metal_short' => 0.90,
      'metal_long' => 0.92,
      'jade' => 0.95,
      'clay' => 0.96,
      _ => 0.93,
    };
    final holeFactor = switch (_pressedHoles.length) {
      <= 1 => 1.0,
      2 => 0.45,
      _ => 0.0,
    };
    final overblowBlend =
        ((breathLevel - overblowThreshold) / (1.0 - overblowThreshold)).clamp(
          0.0,
          1.0,
        ) *
        holeFactor;
    final overblowRegister = switch (overblowBlend) {
      >= 0.72 => 2,
      >= 0.24 => 1,
      _ => 0,
    };
    return '${note.id}:$_style:$_material:$overblowRegister';
  }

  ({double core, double air, double edge}) _sustainLayerMix() {
    final breathLevel = _performanceBreathLevel;
    final styleFactor = switch (_style) {
      'lead' => 1.15,
      'alto' => 0.92,
      'bamboo' => 0.88,
      'velvet' => 0.82,
      'hollow' => 0.9,
      _ => 1.0,
    };
    final core = ((0.22 + breathLevel * 0.48) * styleFactor)
        .clamp(0.15, 0.95)
        .toDouble();
    final air = switch (_material) {
      'metal_short' =>
        ((0.06 + breathLevel * 0.18) * styleFactor)
            .clamp(0.02, 0.45)
            .toDouble(),
      'metal_long' =>
        ((0.05 + breathLevel * 0.16) * styleFactor)
            .clamp(0.02, 0.42)
            .toDouble(),
      'jade' =>
        ((0.04 + breathLevel * 0.12) * styleFactor)
            .clamp(0.01, 0.32)
            .toDouble(),
      'clay' =>
        ((0.03 + breathLevel * 0.1) * styleFactor).clamp(0.01, 0.28).toDouble(),
      _ =>
        ((0.07 + breathLevel * 0.22) * styleFactor).clamp(0.03, 0.5).toDouble(),
    };
    final edge = switch (_material) {
      'metal_short' =>
        ((0.1 + breathLevel * 0.28) * styleFactor).clamp(0.04, 0.55).toDouble(),
      'metal_long' =>
        ((0.08 + breathLevel * 0.24) * styleFactor)
            .clamp(0.03, 0.48)
            .toDouble(),
      'jade' =>
        ((0.04 + breathLevel * 0.14) * styleFactor)
            .clamp(0.02, 0.32)
            .toDouble(),
      'clay' =>
        ((0.03 + breathLevel * 0.1) * styleFactor).clamp(0.01, 0.24).toDouble(),
      _ =>
        ((0.06 + breathLevel * 0.18) * styleFactor)
            .clamp(0.02, 0.38)
            .toDouble(),
    };
    return (core: core, air: air, edge: edge);
  }

  Future<void> _setSustainLayerVolumes() async {
    final mix = _sustainLayerMix();
    await _sustainCoreLoop.setVolume(mix.core);
    await _sustainAirLoop.setVolume(mix.air);
    await _sustainEdgeLoop.setVolume(mix.edge);
  }

  Future<void> _stopSustainLayers() async {
    await _sustainCoreLoop.stop();
    await _sustainAirLoop.stop();
    await _sustainEdgeLoop.stop();
  }

  void _invalidateSustainSync() {
    _sustainSyncSerial += 1;
  }

  bool _isLatestSustainSync(int serial) {
    return serial == _sustainSyncSerial;
  }

  double _normalizedMicLevel(Amplitude amplitude) {
    final value = amplitude.current;
    if (value.isNaN || value.isInfinite) return 0;
    if (value >= 0 && value <= 1.2) {
      return value.clamp(0.0, 1.0).toDouble();
    }
    return ((value + 60) / 60).clamp(0.0, 1.0).toDouble();
  }

  double _filteredBreathLevel(double rawLevel, {double? noiseFloor}) {
    final floor =
        ((noiseFloor ?? _ambientNoiseFloor) + 0.018 + _blowThreshold * 0.12)
            .clamp(0.02, 0.88)
            .toDouble();
    if (rawLevel <= floor) {
      return 0;
    }
    final normalized = ((rawLevel - floor) / (1.0 - floor)).clamp(0.0, 1.0);
    return math.pow(normalized, 1.12).toDouble();
  }

  String _fingeringSignature(Set<int> holes) {
    final ordered = holes.toList()..sort();
    return ordered.join('-');
  }

  List<_FluteFingering> get _activeFingerings {
    if (_scale == 'pentatonic') {
      return const <_FluteFingering>[
        _FluteFingering(signature: '1-2-3-4-5-6', noteIndex: 0),
        _FluteFingering(signature: '1-2-3-4-5', noteIndex: 1),
        _FluteFingering(signature: '1-2-3-4', noteIndex: 2),
        _FluteFingering(signature: '1-2', noteIndex: 3),
        _FluteFingering(signature: '1', noteIndex: 4),
        _FluteFingering(signature: '', noteIndex: 5),
      ];
    }
    return const <_FluteFingering>[
      _FluteFingering(signature: '1-2-3-4-5-6', noteIndex: 0),
      _FluteFingering(signature: '1-2-3-4-5', noteIndex: 1),
      _FluteFingering(signature: '1-2-3-4', noteIndex: 2),
      _FluteFingering(signature: '1-2-3', noteIndex: 3),
      _FluteFingering(signature: '1-2', noteIndex: 4),
      _FluteFingering(signature: '1', noteIndex: 5),
      _FluteFingering(signature: '', noteIndex: 6),
    ];
  }

  int? _noteIndexFromHoles() {
    final notes = _activeNotes;
    final fingerings = _activeFingerings;
    if (notes.isEmpty || fingerings.isEmpty || _pressedHoles.isEmpty) {
      return null;
    }
    final signature = _fingeringSignature(_pressedHoles);
    for (final fingering in fingerings) {
      if (fingering.signature == signature) {
        return fingering.noteIndex.clamp(0, notes.length - 1);
      }
    }
    return null;
  }

  Future<void> _syncBreathSustain() async {
    final serial = ++_sustainSyncSerial;
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
    final notes = _activeNotes;
    if (nextIndex < 0 || nextIndex >= notes.length) {
      return;
    }
    final note = notes[nextIndex];
    final nextSignature = _sustainSignatureFor(note);
    final needsRefresh =
        _sustainedNoteIndex != nextIndex || _sustainSignature != nextSignature;
    _sustainedNoteIndex = nextIndex;
    _sustainSignature = nextSignature;
    if (_lastNote != note.label) {
      _lastNote = note.label;
      if (mounted) {
        setState(() {});
      }
    }
    if (!needsRefresh) {
      await _setSustainLayerVolumes();
      return;
    }
    await _stopSustainLayers();
    if (!_isLatestSustainSync(serial)) {
      return;
    }
    final sustainFrequency = _sustainFrequencyFor(note);
    final mix = _sustainLayerMix();
    await _sustainCoreLoop.play(
      ToolboxAudioBank.fluteSustainCore(
        sustainFrequency,
        style: _style,
        material: _material,
      ),
      volume: mix.core,
    );
    if (!_isLatestSustainSync(serial)) {
      await _stopSustainLayers();
      return;
    }
    await _sustainAirLoop.play(
      ToolboxAudioBank.fluteSustainAir(
        sustainFrequency,
        style: _style,
        material: _material,
      ),
      volume: mix.air,
    );
    if (!_isLatestSustainSync(serial)) {
      await _stopSustainLayers();
      return;
    }
    await _sustainEdgeLoop.play(
      ToolboxAudioBank.fluteSustainEdge(
        sustainFrequency,
        style: _style,
        material: _material,
      ),
      volume: mix.edge,
    );
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
    if (_blowSensorEnabled && _isBlowing) {
      HapticFeedback.lightImpact();
      unawaited(_syncBreathSustain());
    }
  }

  void _bindHolePointer(int holeNumber, PointerDownEvent event) {
    final previousHole = _activeHolePointers[event.pointer];
    if (previousHole == holeNumber) {
      return;
    }
    if (previousHole != null) {
      _releaseHolePress(previousHole);
    }
    _activeHolePointers[event.pointer] = holeNumber;
    final nextCount = (_holePressCounts[holeNumber] ?? 0) + 1;
    _holePressCounts[holeNumber] = nextCount;
    if (nextCount == 1) {
      _setHolePressed(holeNumber, true);
    }
  }

  void _releaseHolePress(int holeNumber) {
    final currentCount = _holePressCounts[holeNumber];
    if (currentCount == null) {
      return;
    }
    if (currentCount <= 1) {
      _holePressCounts.remove(holeNumber);
      _setHolePressed(holeNumber, false);
      return;
    }
    _holePressCounts[holeNumber] = currentCount - 1;
  }

  void _releaseHolePointer(PointerEvent event) {
    final boundHole = _activeHolePointers.remove(event.pointer);
    if (boundHole == null) {
      return;
    }
    _releaseHolePress(boundHole);
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
            _ambientNoiseFloor = 0;
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
      _invalidateSustainSync();
      await _stopSustainLayers();
      _amplitudeSub = _micRecorder
          .onAmplitudeChanged(const Duration(milliseconds: 50))
          .listen((amplitude) {
            final rawLevel = _normalizedMicLevel(amplitude);
            final ambientTarget = _isBlowing
                ? math.min(rawLevel, _ambientNoiseFloor + 0.02)
                : rawLevel;
            final ambientSmoothing = _isBlowing ? 0.985 : 0.92;
            final ambientFloor =
                (_ambientNoiseFloor * ambientSmoothing +
                        ambientTarget * (1.0 - ambientSmoothing))
                    .clamp(0.0, 0.45)
                    .toDouble();
            final filtered = _filteredBreathLevel(
              rawLevel,
              noiseFloor: ambientFloor,
            );
            final smoothing = filtered > _micLevel ? 0.42 : 0.78;
            final level = (_micLevel * smoothing + filtered * (1.0 - smoothing))
                .clamp(0.0, 1.0);
            final onsetEnergy = math.max(0.0, filtered - _micLevel);
            final startThreshold =
                (_blowThreshold * 0.74 + ambientFloor * 0.9 + 0.04)
                    .clamp(0.08, 0.92)
                    .toDouble();
            final holdThreshold = math
                .max(0.04, startThreshold - 0.08)
                .toDouble();
            final onsetCandidate =
                level >= startThreshold || onsetEnergy >= 0.06;
            final confidence =
                (_breathConfidence * 0.7 + (onsetCandidate ? 1.0 : 0.0) * 0.3)
                    .clamp(0.0, 1.0);
            final blowing = _isBlowing
                ? level >= holdThreshold ||
                      (confidence >= 0.36 && level >= holdThreshold * 0.85)
                : level >= startThreshold &&
                      (confidence >= 0.48 || onsetEnergy >= 0.08);
            var shouldRefresh = false;
            final levelChanged = (_micLevel - level).abs() > 0.015;
            if ((_ambientNoiseFloor - ambientFloor).abs() > 0.004) {
              _ambientNoiseFloor = ambientFloor;
            }
            if (levelChanged) {
              _micLevel = level;
              shouldRefresh = true;
            }
            if ((_breathConfidence - confidence).abs() > 0.025) {
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
          _ambientNoiseFloor = 0;
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
          _ambientNoiseFloor = 0;
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
      _ambientNoiseFloor = 0;
      _breathConfidence = 0;
    }
    _invalidateSustainSync();
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
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted || serial != _warmUpSerial) {
      return;
    }
    for (final note in _activeNotes.take(3)) {
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
    _invalidateSustainSync();
    unawaited(_stopSustainLayers());
    _sustainedNoteIndex = null;
    _sustainSignature = null;
    _lastNote = null;
    unawaited(_warmUpActivePreset());
  }

  ToolboxEffectPlayer _playerFor(_PianoKey key) {
    final breathLevel = _oneShotBreathLevel;
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
    if (!mounted) return;
    HapticFeedback.selectionClick();
    final player = _playerFor(key);
    await player.warmUp();
    await player.play(volume: _oneShotBreathLevel.clamp(0.18, 1.0));
    if (mounted) {
      setState(() {
        _lastNote = key.label;
      });
    }
  }

  void _refreshSound() {
    _warmUpSerial += 1;
    _invalidatePlayers();
    _invalidateSustainSync();
    unawaited(_stopSustainLayers());
    _sustainedNoteIndex = null;
    _sustainSignature = null;
    if (_blowSensorEnabled && _isBlowing) {
      unawaited(_syncBreathSustain());
    }
    unawaited(_warmUpActivePreset());
  }

  void _setScale(String value) {
    if (_scale == value) return;
    setState(() {
      _scale = value;
    });
    _sustainedNoteIndex = null;
    _sustainSignature = null;
    _refreshSound();
  }

  void _setStyle(String value) {
    if (_style == value) return;
    setState(() {
      _style = value;
    });
    _sustainedNoteIndex = null;
    _sustainSignature = null;
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
      onPointerUp: _releaseHolePointer,
      onPointerCancel: _releaseHolePointer,
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
    final theme = Theme.of(context);
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => unawaited(_play(note)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 110),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: active
              ? const Color(0xFFDBEAFE)
              : Colors.white.withValues(alpha: immersive ? 0.12 : 0.94),
          border: Border.all(
            color: active
                ? const Color(0xFF60A5FA)
                : Colors.white.withValues(alpha: immersive ? 0.18 : 0.66),
          ),
          boxShadow: active
              ? <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xFF60A5FA).withValues(alpha: 0.24),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : const <BoxShadow>[],
        ),
        child: Text(
          note.label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: active
                ? const Color(0xFF1D4ED8)
                : (immersive ? Colors.white : const Color(0xFF0F172A)),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
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
    return _ToolboxScrollLockSurface(
      child: Container(
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
      ),
    );
  }

  Widget _buildFluteSettingsContent(
    BuildContext context,
    AppI18n i18n, {
    required VoidCallback refreshSheet,
    required void Function(VoidCallback mutation) applySettings,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          pickUiText(i18n, zh: '长笛设置', en: 'Flute settings'),
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
              label: 'Preset',
              value: _presetLabel(i18n, _activePreset),
            ),
            ToolboxMetricCard(
              label: 'Scale',
              value: _displayScaleLabel(i18n, _scale),
            ),
            ToolboxMetricCard(
              label: 'Tone',
              value: _displayStyleLabel(i18n, _style),
            ),
            ToolboxMetricCard(
              label: 'Material',
              value: _materialLabel(i18n, _material),
            ),
            ToolboxMetricCard(label: 'Last', value: _lastNote ?? '--'),
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
                  label: Text(_presetLabel(i18n, item)),
                  selected: item.id == _presetId,
                  onSelected: (_) {
                    _applyPreset(item.id);
                    refreshSheet();
                  },
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 8),
        Text(
          _presetSubtitle(i18n, _activePreset),
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        _buildSettingsSectionTitle(
          context,
          pickUiText(i18n, zh: '调式', en: 'Scale'),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              <String>[
                    'major',
                    'pentatonic',
                    'dorian',
                    'minor',
                    'mixolydian',
                    'lydian',
                  ]
                  .map(
                    (item) => ChoiceChip(
                      label: Text(_displayScaleLabel(i18n, item)),
                      selected: _scale == item,
                      onSelected: (_) {
                        _setScale(item);
                        refreshSheet();
                      },
                    ),
                  )
                  .toList(growable: false),
        ),
        const SizedBox(height: 20),
        _buildSettingsSectionTitle(
          context,
          pickUiText(i18n, zh: '音色拟真', en: 'Timbre'),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              <String>['airy', 'lead', 'alto', 'velvet', 'hollow', 'bamboo']
                  .map(
                    (item) => ChoiceChip(
                      label: Text(_displayStyleLabel(i18n, item)),
                      selected: _style == item,
                      onSelected: (_) {
                        _setStyle(item);
                        refreshSheet();
                      },
                    ),
                  )
                  .toList(growable: false),
        ),
        const SizedBox(height: 20),
        _buildSettingsSectionTitle(
          context,
          pickUiText(i18n, zh: '材质音色', en: 'Material'),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              <String>['wood', 'metal_short', 'metal_long', 'jade', 'clay']
                  .map(
                    (item) => ChoiceChip(
                      label: Text(_materialLabel(i18n, item)),
                      selected: _material == item,
                      onSelected: (_) {
                        if (_material == item) return;
                        applySettings(() {
                          _material = item;
                        });
                        _refreshSound();
                        refreshSheet();
                      },
                    ),
                  )
                  .toList(growable: false),
        ),
        const SizedBox(height: 20),
        _buildSettingsSectionTitle(
          context,
          pickUiText(i18n, zh: '气息与空间', en: 'Breath and space'),
        ),
        Text(
          pickUiText(
            i18n,
            zh: '气息 ${(_breath * 100).round()}%',
            en: 'Breath ${(_breath * 100).round()}%',
          ),
          style: theme.textTheme.labelLarge,
        ),
        Slider(
          value: _breath,
          min: 0.2,
          max: 1.0,
          divisions: 16,
          onChanged: (value) {
            applySettings(() => _breath = value);
            unawaited(_syncBreathSustain());
          },
        ),
        Text(
          pickUiText(
            i18n,
            zh: '空间 ${(_airSpace * 100).round()}%',
            en: 'Space ${(_airSpace * 100).round()}%',
          ),
          style: theme.textTheme.labelLarge,
        ),
        Slider(
          value: _airSpace,
          min: 0.0,
          max: 0.5,
          divisions: 10,
          onChanged: (value) {
            applySettings(() => _airSpace = value);
            _invalidatePlayers();
          },
          onChangeEnd: (_) {
            _refreshSound();
            refreshSheet();
          },
        ),
        Text(
          pickUiText(
            i18n,
            zh: '尾音 ${(_tail * 100).round()}%',
            en: 'Tail ${(_tail * 100).round()}%',
          ),
          style: theme.textTheme.labelLarge,
        ),
        Slider(
          value: _tail,
          min: 0.15,
          max: 1.0,
          divisions: 17,
          onChanged: (value) {
            applySettings(() => _tail = value);
            _invalidatePlayers();
          },
          onChangeEnd: (_) {
            _refreshSound();
            refreshSheet();
          },
        ),
        const SizedBox(height: 20),
        _buildSettingsSectionTitle(
          context,
          pickUiText(i18n, zh: '吹气检测', en: 'Blow sensor'),
        ),
        FilledButton.tonalIcon(
          onPressed: () async {
            await _toggleBlowSensor();
            refreshSheet();
          },
          icon: Icon(
            _blowSensorEnabled ? Icons.mic_rounded : Icons.mic_off_rounded,
          ),
          label: Text(
            _blowSensorEnabled
                ? pickUiText(i18n, zh: '关闭吹气检测', en: 'Disable blow sensor')
                : pickUiText(i18n, zh: '开启吹气检测', en: 'Enable blow sensor'),
          ),
        ),
        if (_blowPermissionDenied) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            pickUiText(
              i18n,
              zh: '麦克风权限不可用',
              en: 'Microphone permission unavailable',
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
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
          onChanged: (value) {
            applySettings(() => _blowThreshold = value);
            unawaited(_syncBreathSustain());
          },
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
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            void applySettings(VoidCallback mutation) {
              if (!mounted) {
                return;
              }
              setState(mutation);
              setSheetState(() {});
            }

            void refreshSheet() {
              if (!mounted) {
                return;
              }
              setSheetState(() {});
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                4,
                16,
                16 + MediaQuery.viewInsetsOf(sheetContext).bottom,
              ),
              child: SingleChildScrollView(
                child: _buildFluteSettingsContent(
                  sheetContext,
                  i18n,
                  refreshSheet: refreshSheet,
                  applySettings: applySettings,
                ),
              ),
            );
          },
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
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
    _invalidateSustainSync();
    unawaited(_disposeMicRecorder());
    unawaited(_sustainCoreLoop.dispose());
    unawaited(_sustainAirLoop.dispose());
    unawaited(_sustainEdgeLoop.dispose());
    _activeHolePointers.clear();
    _holePressCounts.clear();
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
              ToolboxMetricCard(
                label: 'Preset',
                value: _presetLabel(i18n, preset),
              ),
              ToolboxMetricCard(
                label: 'Scale',
                value: _displayScaleLabel(i18n, _scale),
              ),
              ToolboxMetricCard(
                label: 'Tone',
                value: _displayStyleLabel(i18n, _style),
              ),
              ToolboxMetricCard(
                label: 'Material',
                value: _materialLabel(i18n, _material),
              ),
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
                  icon: Icon(
                    _blowSensorEnabled
                        ? Icons.mic_rounded
                        : Icons.mic_off_rounded,
                  ),
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
              pickUiText(
                i18n,
                zh: '麦克风权限不可用，当前仅可使用触控演奏。',
                en: 'Microphone permission unavailable. Touch play is still available.',
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(_presetSubtitle(i18n, preset), style: theme.textTheme.bodySmall),
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
