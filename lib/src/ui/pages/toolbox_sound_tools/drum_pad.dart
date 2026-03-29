part of '../toolbox_sound_tools.dart';

class _DrumPad {
  const _DrumPad({required this.id, required this.color});

  final String id;
  final Color color;
}

class _DrumPadTool extends StatefulWidget {
  const _DrumPadTool({this.fullScreen = false});

  final bool fullScreen;

  @override
  State<_DrumPadTool> createState() => _DrumPadToolState();
}

class _DrumPadToolState extends State<_DrumPadTool> {
  static const List<_DrumPad> _pads = <_DrumPad>[
    _DrumPad(id: 'kick', color: Color(0xFF2563EB)),
    _DrumPad(id: 'snare', color: Color(0xFFEF4444)),
    _DrumPad(id: 'hihat', color: Color(0xFFF59E0B)),
    _DrumPad(id: 'tom', color: Color(0xFF10B981)),
  ];
  static const List<_DrumKitPreset> _presets = <_DrumKitPreset>[
    _DrumKitPreset(
      id: 'acoustic_kit',
      kitId: 'acoustic',
      drive: 1.0,
      tone: 0.52,
      tail: 0.4,
      material: 'wood',
    ),
    _DrumKitPreset(
      id: 'electro_kit',
      kitId: 'electro',
      drive: 0.96,
      tone: 0.72,
      tail: 0.34,
      material: 'hybrid',
    ),
    _DrumKitPreset(
      id: 'lofi_kit',
      kitId: 'lofi',
      drive: 0.88,
      tone: 0.44,
      tail: 0.58,
      material: 'wood',
    ),
  ];

  final Map<String, ToolboxEffectPlayer> _players =
      <String, ToolboxEffectPlayer>{};
  String? _activePadId;
  String? _lastHitId;
  int _hits = 0;
  String _presetId = _presets.first.id;
  String _kit = _presets.first.kitId;
  double _drive = _presets.first.drive;
  double _tone = _presets.first.tone;
  double _tail = _presets.first.tail;
  String _material = _presets.first.material;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_warmUpActivePreset());
    });
  }

  _DrumKitPreset get _activePreset {
    return _presets.firstWhere(
      (item) => item.id == _presetId,
      orElse: () => _presets.first,
    );
  }

  String _presetLabel(AppI18n i18n, _DrumKitPreset preset) {
    return switch (preset.id) {
      'electro_kit' => pickUiText(
        i18n,
        zh: '电子套件',
        en: 'Electro kit',
        ja: 'エレクトロキット',
        de: 'Elektro-Kit',
        fr: 'Kit électro',
        es: 'Kit electro',
        ru: 'Электро-набор',
      ),
      'lofi_kit' => pickUiText(
        i18n,
        zh: '低保真套件',
        en: 'Lo-fi kit',
        ja: 'ローファイキット',
        de: 'Lo-fi-Kit',
        fr: 'Kit lo-fi',
        es: 'Kit lo-fi',
        ru: 'Lo-fi набор',
      ),
      _ => pickUiText(
        i18n,
        zh: '原声套件',
        en: 'Acoustic kit',
        ja: 'アコースティックキット',
        de: 'Akustik-Kit',
        fr: 'Kit acoustique',
        es: 'Kit acústico',
        ru: 'Акустический набор',
      ),
    };
  }

  String _presetSubtitle(AppI18n i18n, _DrumKitPreset preset) {
    return switch (preset.id) {
      'electro_kit' => pickUiText(
        i18n,
        zh: '更利落的瞬态与电子感打击纹理。',
        en: 'Sharper transients and synthetic drum character.',
        ja: 'アタックが強く、電子的な質感を持つキット。',
        de: 'Klarere Transienten mit elektronischem Drum-Charakter.',
        fr: 'Transitoires plus nettes et caractère électronique.',
        es: 'Transitorios más marcados y carácter electrónico.',
        ru: 'Более резкая атака и электронный характер ударов.',
      ),
      'lofi_kit' => pickUiText(
        i18n,
        zh: '更松弛的质感与轻微低保真尾音。',
        en: 'Relaxed impact with slightly dusty lo-fi tail.',
        ja: '柔らかいアタックと少しざらついたローファイ感。',
        de: 'Entspannter Anschlag mit leicht staubigem Lo-fi-Ausklang.',
        fr: 'Impact plus doux avec une légère queue lo-fi.',
        es: 'Impacto relajado con una cola lo-fi ligera.',
        ru: 'Более мягкий удар с лёгким lo-fi хвостом.',
      ),
      _ => pickUiText(
        i18n,
        zh: '更接近原声鼓组的自然敲击感。',
        en: 'Natural punch closer to an acoustic drum set.',
        ja: 'アコースティック寄りの自然な打撃感。',
        de: 'Natürlicher Punch wie bei einem akustischen Drumset.',
        fr: 'Impact naturel proche d’une batterie acoustique.',
        es: 'Golpe natural cercano a una batería acústica.',
        ru: 'Естественный панч, близкий к акустической установке.',
      ),
    };
  }

  String _padLabel(AppI18n i18n, String id) {
    return switch (id) {
      'snare' => pickUiText(
        i18n,
        zh: '军鼓',
        en: 'Snare',
        ja: 'スネア',
        de: 'Snare',
        fr: 'Caisse claire',
        es: 'Caja',
        ru: 'Малый',
      ),
      'hihat' => pickUiText(
        i18n,
        zh: '踩镲',
        en: 'Hi-hat',
        ja: 'ハイハット',
        de: 'Hi-Hat',
        fr: 'Charleston',
        es: 'Hi-hat',
        ru: 'Хай-хэт',
      ),
      'tom' => pickUiText(
        i18n,
        zh: '嗵鼓',
        en: 'Tom',
        ja: 'タム',
        de: 'Tom',
        fr: 'Tom',
        es: 'Tom',
        ru: 'Том',
      ),
      _ => pickUiText(
        i18n,
        zh: '底鼓',
        en: 'Kick',
        ja: 'キック',
        de: 'Kick',
        fr: 'Kick',
        es: 'Bombo',
        ru: 'Бочка',
      ),
    };
  }

  String _materialLabel(AppI18n i18n, String material) {
    return switch (material) {
      'metal' => pickUiText(i18n, zh: '金属', en: 'Metal'),
      'hybrid' => pickUiText(i18n, zh: '混合', en: 'Hybrid'),
      _ => pickUiText(i18n, zh: '木质', en: 'Wood'),
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
    setState(() {
      _presetId = preset.id;
      _kit = preset.kitId;
      _drive = preset.drive;
      _tone = preset.tone;
      _tail = preset.tail;
      _material = preset.material;
    });
    _invalidatePlayers();
    unawaited(_warmUpActivePreset());
  }

  Future<void> _warmUpActivePreset() async {
    for (final pad in _pads) {
      await _playerFor(pad.id).warmUp();
    }
  }

  ToolboxEffectPlayer _playerFor(String id) {
    final cacheKey =
        '$id:$_kit:${_tone.toStringAsFixed(2)}:${_tail.toStringAsFixed(2)}:$_material';
    final existing = _players[cacheKey];
    if (existing != null) return existing;
    final created = ToolboxEffectPlayer(
      ToolboxAudioBank.drumHit(
        id,
        kit: _kit,
        tone: _tone,
        tail: _tail,
        material: _material,
      ),
      maxPlayers: 8,
    );
    _players[cacheKey] = created;
    return created;
  }

  Future<void> _hit(_DrumPad pad) async {
    HapticFeedback.heavyImpact();
    unawaited(_playerFor(pad.id).play(volume: _drive.clamp(0.2, 1.0)));
    if (!mounted) return;
    setState(() {
      _activePadId = pad.id;
      _lastHitId = pad.id;
      _hits += 1;
    });
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (!mounted || _activePadId != pad.id) return;
      setState(() => _activePadId = null);
    });
  }

  @override
  void dispose() {
    _invalidatePlayers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
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
                  zh: '鼓垫',
                  en: 'Pads',
                  ja: 'パッド',
                  de: 'Pads',
                  fr: 'Pads',
                  es: 'Pads',
                  ru: 'Пэды',
                ),
                value: '${_pads.length}',
              ),
              ToolboxMetricCard(
                label: pickUiText(
                  i18n,
                  zh: '最近击打',
                  en: 'Last hit',
                  ja: '直前ヒット',
                  de: 'Letzter Schlag',
                  fr: 'Dernier coup',
                  es: 'Último golpe',
                  ru: 'Последний удар',
                ),
                value: _lastHitId == null ? '--' : _padLabel(i18n, _lastHitId!),
              ),
              ToolboxMetricCard(
                label: pickUiText(
                  i18n,
                  zh: '次数',
                  en: 'Count',
                  ja: '回数',
                  de: 'Anzahl',
                  fr: 'Compteur',
                  es: 'Conteo',
                  ru: 'Счёт',
                ),
                value: '$_hits',
              ),
              ToolboxMetricCard(
                label: pickUiText(
                  i18n,
                  zh: '材质',
                  en: 'Body',
                  ja: 'プリセット',
                  de: 'Preset',
                  fr: 'Préréglage',
                  es: 'Preajuste',
                  ru: 'Пресет',
                ),
                value: _materialLabel(i18n, _material),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
              zh: '切换鼓组类型，并同步设置默认冲击力度。',
              en: 'Switch kit type and default impact drive together.',
              ja: 'キット種類と標準の打撃ドライブをまとめて切り替えます。',
              de: 'Wechselt Kit-Typ und Standard-Drive gemeinsam.',
              fr: 'Changez le type de kit et le drive d’impact par défaut.',
              es: 'Cambia el kit y el nivel de impacto por defecto.',
              ru: 'Переключает тип набора и силу удара по умолчанию.',
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
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Text(
            pickUiText(
              i18n,
              zh: '冲击力度 ${(_drive * 100).round()}%',
              en: 'Drive ${(_drive * 100).round()}%',
              ja: 'ドライブ ${(_drive * 100).round()}%',
              de: 'Drive ${(_drive * 100).round()}%',
              fr: 'Drive ${(_drive * 100).round()}%',
              es: 'Drive ${(_drive * 100).round()}%',
              ru: 'Драйв ${(_drive * 100).round()}%',
            ),
          ),
          Slider(
            value: _drive,
            min: 0.45,
            max: 1.0,
            divisions: 11,
            onChanged: (value) => setState(() => _drive = value),
          ),
          const SizedBox(height: 8),
          SectionHeader(
            title: pickUiText(i18n, zh: '音色与尾音', en: 'Tone and tail'),
            subtitle: pickUiText(
              i18n,
              zh: '像竖琴一样开放鼓皮亮度、尾音长度和打击材质。',
              en: 'Expose brightness, decay tail, and shell material like the harp module.',
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <String>['wood', 'hybrid', 'metal']
                .map(
                  (item) => ChoiceChip(
                    label: Text(_materialLabel(i18n, item)),
                    selected: item == _material,
                    onSelected: (_) {
                      if (item == _material) return;
                      setState(() => _material = item);
                      _invalidatePlayers();
                      unawaited(_warmUpActivePreset());
                    },
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: 10),
          Text(
            pickUiText(
              i18n,
              zh: '亮度 ${(_tone * 100).round()}%',
              en: 'Tone ${(_tone * 100).round()}%',
            ),
          ),
          Slider(
            value: _tone,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            onChanged: (value) => setState(() => _tone = value),
            onChangeEnd: (_) {
              _invalidatePlayers();
              unawaited(_warmUpActivePreset());
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
            min: 0.0,
            max: 1.0,
            divisions: 20,
            onChanged: (value) => setState(() => _tail = value),
            onChangeEnd: (_) {
              _invalidatePlayers();
              unawaited(_warmUpActivePreset());
            },
          ),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: widget.fullScreen ? 1.35 : 1.1,
            child: GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: _pads
                  .map((pad) {
                    final active = _activePadId == pad.id;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => unawaited(_hit(pad)),
                        child: Ink(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: <Color>[
                                pad.color.withValues(
                                  alpha: active ? 0.95 : 0.74,
                                ),
                                pad.color.withValues(
                                  alpha: active ? 0.7 : 0.52,
                                ),
                              ],
                            ),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: pad.color.withValues(
                                  alpha: active ? 0.42 : 0.24,
                                ),
                                blurRadius: active ? 18 : 12,
                                spreadRadius: active ? 2 : 0,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _padLabel(i18n, pad.id),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }
}
