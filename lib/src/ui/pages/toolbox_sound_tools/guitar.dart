part of '../toolbox_sound_tools.dart';

class _GuitarTool extends StatefulWidget {
  const _GuitarTool({this.fullScreen = false});

  final bool fullScreen;

  @override
  State<_GuitarTool> createState() => _GuitarToolState();
}

class _GuitarToolState extends State<_GuitarTool> {
  static const List<_PianoKey> _strings = <_PianoKey>[
    _PianoKey(id: 'E2', label: 'E2', frequency: 82.41),
    _PianoKey(id: 'A2', label: 'A2', frequency: 110.0),
    _PianoKey(id: 'D3', label: 'D3', frequency: 146.83),
    _PianoKey(id: 'G3', label: 'G3', frequency: 196.0),
    _PianoKey(id: 'B3', label: 'B3', frequency: 246.94),
    _PianoKey(id: 'E4', label: 'E4', frequency: 329.63),
  ];

  final Map<String, ToolboxEffectPlayer> _players =
      <String, ToolboxEffectPlayer>{};
  static const List<_GuitarPreset> _presets = <_GuitarPreset>[
    _GuitarPreset(
      id: 'steel_strum',
      styleId: 'steel',
      pluckVolume: 0.9,
      strumVolume: 0.84,
      strumDelayMs: 34,
      resonance: 0.56,
      pickPosition: 0.62,
    ),
    _GuitarPreset(
      id: 'nylon_finger',
      styleId: 'nylon',
      pluckVolume: 0.84,
      strumVolume: 0.78,
      strumDelayMs: 42,
      resonance: 0.66,
      pickPosition: 0.48,
    ),
    _GuitarPreset(
      id: 'ambient_chime',
      styleId: 'ambient',
      pluckVolume: 0.78,
      strumVolume: 0.72,
      strumDelayMs: 52,
      resonance: 0.82,
      pickPosition: 0.34,
    ),
  ];
  String _presetId = _presets.first.id;
  int? _activeString;
  double _resonance = _presets.first.resonance;
  double _pickPosition = _presets.first.pickPosition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_warmUpActivePreset());
    });
  }

  _GuitarPreset get _activePreset {
    return _presets.firstWhere(
      (item) => item.id == _presetId,
      orElse: () => _presets.first,
    );
  }

  String _presetLabel(AppI18n i18n, _GuitarPreset preset) {
    return switch (preset.id) {
      'nylon_finger' => pickUiText(
        i18n,
        zh: '尼龙指弹',
        en: 'Nylon finger',
        ja: 'ナイロン指弾き',
        de: 'Nylon Fingerstyle',
        fr: 'Nylon finger',
        es: 'Nailon finger',
        ru: 'Нейлон фингер',
      ),
      'ambient_chime' => pickUiText(
        i18n,
        zh: '氛围铃音',
        en: 'Ambient chime',
        ja: 'アンビエントチャイム',
        de: 'Ambient Chime',
        fr: 'Ambient chime',
        es: 'Ambient chime',
        ru: 'Ambient chime',
      ),
      _ => pickUiText(
        i18n,
        zh: '钢弦扫弦',
        en: 'Steel strum',
        ja: 'スチールストラム',
        de: 'Steel Strum',
        fr: 'Steel strum',
        es: 'Steel strum',
        ru: 'Steel strum',
      ),
    };
  }

  String _presetSubtitle(AppI18n i18n, _GuitarPreset preset) {
    return switch (preset.id) {
      'nylon_finger' => pickUiText(
        i18n,
        zh: '圆润柔和，适合慢速分解和指弹。',
        en: 'Round and soft tone for slow arpeggios and finger picking.',
        ja: '丸く柔らかい音で、ゆっくりした分散和音に最適。',
        de: 'Runder, weicher Klang für langsame Arpeggios und Fingerpicking.',
        fr: 'Timbre rond et doux pour arpèges lents et fingerstyle.',
        es: 'Tono redondo y suave para arpegios lentos y fingerpicking.',
        ru: 'Мягкий округлый тембр для медленных арпеджио и фингерстайла.',
      ),
      'ambient_chime' => pickUiText(
        i18n,
        zh: '更空灵的泛音尾音，适合氛围铺底。',
        en: 'Airier overtones and longer shimmer for ambient layers.',
        ja: '倍音を強めた余韻で、アンビエント層に向くサウンド。',
        de: 'Luftigere Obertöne mit längerem Schimmer für Ambient-Flächen.',
        fr: 'Harmoniques aériennes et résonance longue pour l’ambient.',
        es: 'Armónicos más aéreos y cola larga para capas ambient.',
        ru: 'Более воздушные обертоны и длинный шимер для ambient-подложки.',
      ),
      _ => pickUiText(
        i18n,
        zh: '清晰有力的钢弦核心，适合节奏扫弦。',
        en: 'Clear steel-core tone tuned for rhythmic strumming.',
        ja: '明瞭なスチール芯で、リズムストラム向け。',
        de: 'Klarer Steel-Kernklang für rhythmisches Strumming.',
        fr: 'Noyau acier net, idéal pour le strumming rythmique.',
        es: 'Núcleo claro de acero, ideal para rasgueo rítmico.',
        ru: 'Чёткий стальной тон, настроенный под ритмический бой.',
      ),
    };
  }

  void _applyPreset(String presetId) {
    if (_presetId == presetId) return;
    final preset = _presets.firstWhere(
      (item) => item.id == presetId,
      orElse: () => _presets.first,
    );
    setState(() {
      _presetId = presetId;
      _resonance = preset.resonance;
      _pickPosition = preset.pickPosition;
    });
    _invalidatePlayers();
    unawaited(_warmUpActivePreset());
  }

  Future<void> _warmUpActivePreset() async {
    for (final note in _strings) {
      await _playerFor(note).warmUp();
    }
  }

  ToolboxEffectPlayer _playerFor(_PianoKey note) {
    final key =
        '${note.id}:${_activePreset.styleId}:${_resonance.toStringAsFixed(2)}:${_pickPosition.toStringAsFixed(2)}';
    final existing = _players[key];
    if (existing != null) return existing;
    final created = ToolboxEffectPlayer(
      ToolboxAudioBank.guitarNote(
        note.frequency,
        style: _activePreset.styleId,
        resonance: _resonance,
        pickPosition: _pickPosition,
      ),
      maxPlayers: 8,
    );
    _players[key] = created;
    return created;
  }

  Future<void> _pluck(int index, {double? volume}) async {
    if (index < 0 || index >= _strings.length) return;
    HapticFeedback.selectionClick();
    final note = _strings[index];
    unawaited(
      _playerFor(note).play(volume: volume ?? _activePreset.pluckVolume),
    );
    if (!mounted) return;
    setState(() => _activeString = index);
    Future<void>.delayed(const Duration(milliseconds: 100), () {
      if (!mounted || _activeString != index) return;
      setState(() => _activeString = null);
    });
  }

  Future<void> _strum({required bool down}) async {
    final preset = _activePreset;
    final indexes = down
        ? List<int>.generate(_strings.length, (i) => i)
        : List<int>.generate(_strings.length, (i) => _strings.length - 1 - i);
    for (final index in indexes) {
      await _pluck(index, volume: preset.strumVolume);
      await Future<void>.delayed(Duration(milliseconds: preset.strumDelayMs));
    }
  }

  void _invalidatePlayers() {
    for (final player in _players.values) {
      unawaited(player.dispose());
    }
    _players.clear();
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
                  zh: '琴弦',
                  en: 'Strings',
                  ja: '弦',
                  de: 'Saiten',
                  fr: 'Cordes',
                  es: 'Cuerdas',
                  ru: 'Струны',
                ),
                value: '6',
              ),
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
                  zh: '共鸣',
                  en: 'Resonance',
                  ja: '音色',
                  de: 'Klang',
                  fr: 'Timbre',
                  es: 'Timbre',
                  ru: 'Тембр',
                ),
                value: '${(_resonance * 100).round()}%',
              ),
            ],
          ),
          const SizedBox(height: 10),
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
              zh: '预设同时控制琴弦材质、拨弦力度和扫弦速度。',
              en: 'Presets control string material, pluck volume, and strum speed.',
              ja: 'プリセットで弦素材、ピッキング強度、ストラム速度を一括制御。',
              de: 'Presets steuern Saitenmaterial, Zupf-Lautstärke und Strum-Tempo.',
              fr: 'Les presets pilotent matériau, attaque et vitesse de strum.',
              es: 'Los presets controlan material, ataque y velocidad de rasgueo.',
              ru: 'Пресеты управляют материалом струн, атакой и скоростью боя.',
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
                    selected: _presetId == item.id,
                    onSelected: (_) => _applyPreset(item.id),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 8),
          Text(_presetSubtitle(i18n, preset), style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          SectionHeader(
            title: pickUiText(i18n, zh: '音色整形', en: 'Tone shaping'),
            subtitle: pickUiText(
              i18n,
              zh: '开放琴体共鸣和拨弦位置，保证演奏区依旧完整。',
              en: 'Expose body resonance and pick position while keeping the playing area intact.',
            ),
          ),
          const SizedBox(height: 10),
          Text(
            pickUiText(
              i18n,
              zh: '共鸣 ${(_resonance * 100).round()}%',
              en: 'Resonance ${(_resonance * 100).round()}%',
            ),
          ),
          Slider(
            value: _resonance,
            min: 0.1,
            max: 1.0,
            divisions: 18,
            onChanged: (value) => setState(() => _resonance = value),
            onChangeEnd: (_) {
              _invalidatePlayers();
              unawaited(_warmUpActivePreset());
            },
          ),
          Text(
            pickUiText(
              i18n,
              zh: '拨弦位置 ${(_pickPosition * 100).round()}%',
              en: 'Pick position ${(_pickPosition * 100).round()}%',
            ),
          ),
          Slider(
            value: _pickPosition,
            min: 0.1,
            max: 0.9,
            divisions: 16,
            onChanged: (value) => setState(() => _pickPosition = value),
            onChangeEnd: (_) {
              _invalidatePlayers();
              unawaited(_warmUpActivePreset());
            },
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Color(0xFFF6E7C8), Color(0xFFEBCF9A)],
              ),
            ),
            child: Column(
              children: List<Widget>.generate(_strings.length, (index) {
                final active = _activeString == index;
                final note = _strings[index];
                return Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (_) => unawaited(_pluck(index)),
                  child: Container(
                    height: widget.fullScreen ? 40 : 34,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: <Widget>[
                        SizedBox(
                          width: 28,
                          child: Text(
                            note.label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF5A3818),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 90),
                            height: active ? 3.4 : 2.2,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: active
                                  ? const Color(0xFFFB923C)
                                  : const Color(0xFF7C5A3A),
                              boxShadow: active
                                  ? <BoxShadow>[
                                      BoxShadow(
                                        color: const Color(
                                          0xFFFB923C,
                                        ).withValues(alpha: 0.35),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : const <BoxShadow>[],
                            ),
                          ),
                        ),
                      ],
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
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: () => unawaited(_strum(down: true)),
                icon: const Icon(Icons.south_rounded),
                label: Text(
                  pickUiText(
                    i18n,
                    zh: '下扫弦',
                    en: 'Strum down',
                    ja: 'ダウンストラム',
                    de: 'Abschlag',
                    fr: 'Strum vers le bas',
                    es: 'Rasgueo abajo',
                    ru: 'Бой вниз',
                  ),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: () => unawaited(_strum(down: false)),
                icon: const Icon(Icons.north_rounded),
                label: Text(
                  pickUiText(
                    i18n,
                    zh: '上扫弦',
                    en: 'Strum up',
                    ja: 'アップストラム',
                    de: 'Aufschlag',
                    fr: 'Strum vers le haut',
                    es: 'Rasgueo arriba',
                    ru: 'Бой вверх',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
