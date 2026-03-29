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
      scaleId: 'major',
      breath: 0.76,
      reverb: 0.24,
      tail: 0.64,
    ),
    _FlutePreset(
      id: 'lead_solo',
      styleId: 'lead',
      scaleId: 'pentatonic',
      breath: 0.86,
      reverb: 0.16,
      tail: 0.42,
    ),
    _FlutePreset(
      id: 'alto_warm',
      styleId: 'alto',
      scaleId: 'dorian',
      breath: 0.68,
      reverb: 0.28,
      tail: 0.78,
    ),
  ];

  final Map<String, ToolboxEffectPlayer> _players =
      <String, ToolboxEffectPlayer>{};
  final AudioRecorder _micRecorder = AudioRecorder();
  final ToolboxLoopController _sustainLoop = ToolboxLoopController();
  StreamSubscription<Amplitude>? _amplitudeSub;
  final Set<int> _pressedHoles = <int>{};
  String _presetId = _presets.first.id;
  String _scale = _presets.first.scaleId;
  String _style = _presets.first.styleId;
  double _breath = _presets.first.breath;
  double _airSpace = _presets.first.reverb;
  double _tail = _presets.first.tail;
  bool _blowSensorEnabled = false;
  bool _blowPermissionDenied = false;
  bool _isBlowing = false;
  double _micLevel = 0;
  double _blowThreshold = 0.34;
  int? _sustainedNoteIndex;
  String? _lastNote;

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

  double _normalizedMicLevel(Amplitude amplitude) {
    final value = amplitude.current;
    if (value.isNaN || value.isInfinite) return 0;
    if (value >= 0 && value <= 1.2) {
      return value.clamp(0.0, 1.0).toDouble();
    }
    return ((value + 60) / 60).clamp(0.0, 1.0).toDouble();
  }

  int? _noteIndexFromHoles() {
    if (_pressedHoles.isEmpty) return null;
    final notes = _activeNotes;
    if (notes.isEmpty) return null;
    final closed = _pressedHoles.length.clamp(1, 6);
    return (notes.length - closed).clamp(0, notes.length - 1);
  }

  Future<void> _syncBreathSustain() async {
    final nextIndex = (_blowSensorEnabled && _isBlowing)
        ? _noteIndexFromHoles()
        : null;
    if (nextIndex == null) {
      if (_sustainedNoteIndex != null) {
        _sustainedNoteIndex = null;
        await _sustainLoop.stop();
      }
      return;
    }
    final note = _activeNotes[nextIndex];
    if (_sustainedNoteIndex == nextIndex) {
      await _sustainLoop.setVolume(_breath.clamp(0.2, 1.0));
      return;
    }
    _sustainedNoteIndex = nextIndex;
    _lastNote = note.label;
    await _sustainLoop.play(
      ToolboxAudioBank.fluteNote(
        note.frequency,
        style: _style,
        reverb: _airSpace,
        tail: _tail,
      ),
      volume: _breath.clamp(0.2, 1.0),
    );
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
      _amplitudeSub = _micRecorder
          .onAmplitudeChanged(const Duration(milliseconds: 60))
          .listen((amplitude) {
            final level = _normalizedMicLevel(amplitude);
            final blowing = level >= _blowThreshold;
            var shouldRefresh = false;
            if ((_micLevel - level).abs() > 0.01) {
              _micLevel = level;
              shouldRefresh = true;
            }
            if (_isBlowing != blowing) {
              _isBlowing = blowing;
              shouldRefresh = true;
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
    for (final note in _activeNotes.take(6)) {
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
      _scale = preset.scaleId;
      _breath = preset.breath;
      _airSpace = preset.reverb;
      _tail = preset.tail;
    });
    _invalidatePlayers();
    unawaited(_warmUpActivePreset());
    unawaited(_syncBreathSustain());
  }

  ToolboxEffectPlayer _playerFor(_PianoKey key) {
    final cacheKey =
        'flute:${key.id}:$_style:${_airSpace.toStringAsFixed(2)}:${_tail.toStringAsFixed(2)}';
    final existing = _players[cacheKey];
    if (existing != null) return existing;
    final created = ToolboxEffectPlayer(
      ToolboxAudioBank.fluteNote(
        key.frequency,
        style: _style,
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
    unawaited(_playerFor(key).play(volume: _breath.clamp(0.2, 1.0)));
    if (!mounted) return;
    setState(() {
      _lastNote = key.label;
    });
  }

  @override
  void dispose() {
    final amplitudeSub = _amplitudeSub;
    _amplitudeSub = null;
    if (amplitudeSub != null) {
      unawaited(amplitudeSub.cancel());
    }
    unawaited(_disposeMicRecorder());
    unawaited(_sustainLoop.dispose());
    _invalidatePlayers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    final theme = Theme.of(context);
    final preset = _activePreset;
    return _buildInstrumentPanelShell(
      context,
      fullScreen: widget.fullScreen,
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
                  zh: '预设',
                  en: 'Preset',
                  ja: 'プリセット',
                  de: 'Preset',
                  fr: 'Préréglage',
                  es: 'Preajuste',
                  ru: 'Пресет',
                ),
                value: _presetLabel(i18n, preset),
              ),
              ToolboxMetricCard(
                label: pickUiText(
                  i18n,
                  zh: '调式',
                  en: 'Scale',
                  ja: 'スケール',
                  de: 'Skala',
                  fr: 'Gamme',
                  es: 'Escala',
                  ru: 'Лад',
                ),
                value: _scaleLabel(i18n, _scale),
              ),
              ToolboxMetricCard(
                label: pickUiText(
                  i18n,
                  zh: '空间',
                  en: 'Space',
                  ja: 'ブレス',
                  de: 'Atem',
                  fr: 'Souffle',
                  es: 'Soplo',
                  ru: 'Дыхание',
                ),
                value: '${(_airSpace * 100).round()}%',
              ),
              ToolboxMetricCard(
                label: pickUiText(
                  i18n,
                  zh: '最近音符',
                  en: 'Last note',
                  ja: '直前ノート',
                  de: 'Letzter Ton',
                  fr: 'Dernière note',
                  es: 'Última nota',
                  ru: 'Последняя нота',
                ),
                value: _lastNote ?? '--',
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
              fr: 'Pack de préréglages',
              es: 'Paquete de presets',
              ru: 'Пакет пресетов',
            ),
            subtitle: pickUiText(
              i18n,
              zh: '每个预设同时绑定音色、调式和默认气息强度。',
              en: 'Each preset binds timbre, scale, and default breath intensity.',
              ja: '各プリセットは音色・スケール・ブレス強度をまとめて切り替えます。',
              de: 'Jedes Preset verknüpft Klangfarbe, Skala und Atemintensität.',
              fr: 'Chaque preset relie timbre, gamme et intensité de souffle.',
              es: 'Cada preset combina timbre, escala e intensidad de soplo.',
              ru: 'Каждый пресет связывает тембр, лад и силу дыхания.',
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
          Text(_presetSubtitle(i18n, preset), style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Color(0xFFE7F2FF),
                  Color(0xFFCFE6FF),
                  Color(0xFFBADBFF),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
            ),
            child: Row(
              children: List<Widget>.generate(7, (index) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index.isEven
                          ? const Color(0xFF7A9AC8)
                          : const Color(0xFF5578AB),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <String>['major', 'pentatonic', 'dorian']
                .map(
                  (item) => ChoiceChip(
                    label: Text(_scaleLabel(i18n, item)),
                    selected: _scale == item,
                    onSelected: (_) {
                      if (_scale == item) return;
                      setState(() => _scale = item);
                      _invalidatePlayers();
                      unawaited(_warmUpActivePreset());
                      unawaited(_syncBreathSustain());
                    },
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 12),
          Text(
            pickUiText(
              i18n,
              zh: '气息 ${(_breath * 100).round()}% · 音色 ${_styleLabel(i18n, _style)}',
              en: 'Breath ${(_breath * 100).round()}% · Tone ${_styleLabel(i18n, _style)}',
              ja: 'ブレス ${(_breath * 100).round()}% · 音色 ${_styleLabel(i18n, _style)}',
              de: 'Atem ${(_breath * 100).round()}% · Klang ${_styleLabel(i18n, _style)}',
              fr: 'Souffle ${(_breath * 100).round()}% · Timbre ${_styleLabel(i18n, _style)}',
              es: 'Soplo ${(_breath * 100).round()}% · Timbre ${_styleLabel(i18n, _style)}',
              ru: 'Дыхание ${(_breath * 100).round()}% · Тембр ${_styleLabel(i18n, _style)}',
            ),
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
          const SizedBox(height: 8),
          SectionHeader(
            title: pickUiText(i18n, zh: '音色与尾音', en: 'Tone and tail'),
            subtitle: pickUiText(
              i18n,
              zh: '补齐长笛的空间感和尾音参数，和其他乐器保持一致。',
              en: 'Expose room feel and tail response so flute stays aligned with the other instruments.',
            ),
          ),
          const SizedBox(height: 10),
          Text(
            pickUiText(
              i18n,
              zh: '空间 ${(_airSpace * 100).round()}%',
              en: 'Space ${(_airSpace * 100).round()}%',
            ),
          ),
          Slider(
            value: _airSpace,
            min: 0.0,
            max: 0.5,
            divisions: 10,
            onChanged: (value) => setState(() => _airSpace = value),
            onChangeEnd: (_) {
              _invalidatePlayers();
              unawaited(_warmUpActivePreset());
              unawaited(_syncBreathSustain());
            },
          ),
          Text(
            pickUiText(
              i18n,
              zh: '尾音 ${(_tail * 100).round()}%',
              en: 'Tail ${(_tail * 100).round()}%',
            ),
          ),
          Slider(
            value: _tail,
            min: 0.15,
            max: 1.0,
            divisions: 17,
            onChanged: (value) => setState(() => _tail = value),
            onChangeEnd: (_) {
              _invalidatePlayers();
              unawaited(_warmUpActivePreset());
              unawaited(_syncBreathSustain());
            },
          ),
          const SizedBox(height: 8),
          SectionHeader(
            title: pickUiText(i18n, zh: '模拟吹奏', en: 'Blow Simulation'),
            subtitle: pickUiText(
              i18n,
              zh: '使用麦克风吹气 + 按孔触发持续发音，松手后结束。',
              en: 'Use microphone breath + hole buttons for sustained notes, then stop on release.',
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
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
                      ? pickUiText(
                          i18n,
                          zh: '关闭吹气检测',
                          en: 'Disable blow sensor',
                        )
                      : pickUiText(
                          i18n,
                          zh: '开启吹气检测',
                          en: 'Enable blow sensor',
                        ),
                ),
              ),
              if (_blowPermissionDenied)
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
          ),
          const SizedBox(height: 8),
          Text(
            pickUiText(
              i18n,
              zh: '吹气阈值 ${(_blowThreshold * 100).round()}% · 当前 ${(_micLevel * 100).round()}%',
              en: 'Blow threshold ${(_blowThreshold * 100).round()}% · Current ${(_micLevel * 100).round()}%',
            ),
          ),
          Slider(
            value: _blowThreshold,
            min: 0.12,
            max: 0.75,
            divisions: 21,
            onChanged: (value) {
              setState(() => _blowThreshold = value);
            },
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _micLevel.clamp(0.0, 1.0),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List<Widget>.generate(6, (index) {
              final holeNumber = index + 1;
              final pressed = _pressedHoles.contains(holeNumber);
              return Listener(
                onPointerDown: (_) => _setHolePressed(holeNumber, true),
                onPointerUp: (_) => _setHolePressed(holeNumber, false),
                onPointerCancel: (_) => _setHolePressed(holeNumber, false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 80),
                  width: widget.fullScreen ? 62 : 54,
                  height: widget.fullScreen ? 62 : 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: pressed
                        ? const Color(0xFF2563EB)
                        : theme.colorScheme.surfaceContainerHigh,
                    border: Border.all(
                      color: pressed
                          ? const Color(0xFF1D4ED8)
                          : theme.colorScheme.outlineVariant,
                    ),
                    boxShadow: pressed
                        ? <BoxShadow>[
                            BoxShadow(
                              color: const Color(
                                0xFF2563EB,
                              ).withValues(alpha: 0.28),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ]
                        : const <BoxShadow>[],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'H$holeNumber',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: pressed
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            pickUiText(
              i18n,
              zh: '吹气状态：${_isBlowing ? "进行中" : "未吹气"} · 按孔：${_pressedHoles.length}',
              en: 'Blow: ${_isBlowing ? "active" : "idle"} · Holes pressed: ${_pressedHoles.length}',
            ),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _activeNotes
                .map(
                  (note) => FilledButton.tonal(
                    onPressed: () => unawaited(_play(note)),
                    child: Text(note.label),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}
