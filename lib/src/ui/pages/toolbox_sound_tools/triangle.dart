part of '../toolbox_sound_tools.dart';

class _TriangleTool extends StatefulWidget {
  const _TriangleTool({this.fullScreen = false});

  final bool fullScreen;

  @override
  State<_TriangleTool> createState() => _TriangleToolState();
}

class _TriangleToolState extends State<_TriangleTool> {
  static const List<_TrianglePreset> _presets = <_TrianglePreset>[
    _TrianglePreset(
      id: 'orchestral_ring',
      styleId: 'orchestral',
      ring: 0.86,
      material: 'steel',
      strike: 0.62,
      damping: 0.22,
    ),
    _TrianglePreset(
      id: 'soft_ring',
      styleId: 'soft',
      ring: 0.74,
      material: 'brass',
      strike: 0.42,
      damping: 0.36,
    ),
    _TrianglePreset(
      id: 'bright_ring',
      styleId: 'bright',
      ring: 0.96,
      material: 'aluminum',
      strike: 0.82,
      damping: 0.14,
    ),
  ];
  final Map<String, ToolboxEffectPlayer> _players =
      <String, ToolboxEffectPlayer>{};
  String _presetId = _presets.first.id;
  int _hits = 0;
  double _ring = _presets.first.ring;
  double _flash = 0;
  String _material = _presets.first.material;
  double _strikePoint = _presets.first.strike;
  double _damping = _presets.first.damping;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_warmUpActivePreset());
    });
  }

  _TrianglePreset get _activePreset {
    return _presets.firstWhere(
      (item) => item.id == _presetId,
      orElse: () => _presets.first,
    );
  }

  String _presetLabel(AppI18n i18n, _TrianglePreset preset) {
    return switch (preset.id) {
      'soft_ring' => pickUiText(
        i18n,
        zh: '柔和振铃',
        en: 'Soft ring',
        ja: 'ソフトリング',
        de: 'Sanfter Ring',
        fr: 'Résonance douce',
        es: 'Resonancia suave',
        ru: 'Мягкий звон',
      ),
      'bright_ring' => pickUiText(
        i18n,
        zh: '明亮振铃',
        en: 'Bright ring',
        ja: 'ブライトリング',
        de: 'Heller Ring',
        fr: 'Résonance brillante',
        es: 'Resonancia brillante',
        ru: 'Яркий звон',
      ),
      _ => pickUiText(
        i18n,
        zh: '管弦振铃',
        en: 'Orchestral ring',
        ja: 'オーケストラリング',
        de: 'Orchestraler Ring',
        fr: 'Résonance orchestrale',
        es: 'Resonancia orquestal',
        ru: 'Оркестровый звон',
      ),
    };
  }

  String _presetSubtitle(AppI18n i18n, _TrianglePreset preset) {
    return switch (preset.id) {
      'soft_ring' => pickUiText(
        i18n,
        zh: '更柔和的高频和更短的余音，适合轻节奏。',
        en: 'Softer highs and shorter tail for gentle rhythm support.',
        ja: '高域を抑えた短めの余韻で、軽いリズム向け。',
        de: 'Sanftere Höhen und kürzeres Ausklingen für leichte Patterns.',
        fr: 'Aigus adoucis et queue plus courte pour un rythme léger.',
        es: 'Agudos suaves y cola corta para ritmos ligeros.',
        ru: 'Мягкие верха и короткий хвост для лёгкого ритма.',
      ),
      'bright_ring' => pickUiText(
        i18n,
        zh: '更亮更脆，余音更明显，适合强调节拍。',
        en: 'Brighter attack and stronger ring to mark accents.',
        ja: '明るく鋭いアタックで、アクセントを強調。',
        de: 'Hellerer Anschlag und stärkerer Ring für Akzente.',
        fr: 'Attaque plus brillante et résonance marquée.',
        es: 'Ataque brillante y resonancia más marcada para acentos.',
        ru: 'Более яркая атака и выраженный звон для акцентов.',
      ),
      _ => pickUiText(
        i18n,
        zh: '均衡明亮与延音，接近管弦乐中的三角铁表现。',
        en: 'Balanced brightness and decay close to orchestral behavior.',
        ja: '明るさと余韻のバランスが良い標準オーケストラ音。',
        de: 'Ausgewogene Helligkeit und Decay wie im Orchester.',
        fr: 'Équilibre entre brillance et décroissance orchestral.',
        es: 'Equilibrio entre brillo y decaimiento de estilo orquestal.',
        ru: 'Сбалансированная яркость и затухание в оркестровом стиле.',
      ),
    };
  }

  String _materialLabel(AppI18n i18n, String material) {
    return switch (material) {
      'brass' => pickUiText(i18n, zh: '黄铜', en: 'Brass'),
      'aluminum' => pickUiText(i18n, zh: '铝制', en: 'Aluminum'),
      _ => pickUiText(i18n, zh: '钢制', en: 'Steel'),
    };
  }

  ToolboxEffectPlayer _playerFor(String styleId) {
    final cacheKey =
        '$styleId:$_material:${_strikePoint.toStringAsFixed(2)}:${_damping.toStringAsFixed(2)}';
    final existing = _players[cacheKey];
    if (existing != null) return existing;
    final created = ToolboxEffectPlayer(
      ToolboxAudioBank.triangleHit(
        style: styleId,
        material: _material,
        strike: _strikePoint,
        damping: _damping,
      ),
      maxPlayers: 6,
    );
    _players[cacheKey] = created;
    return created;
  }

  void _disposePlayers() {
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
      _ring = preset.ring;
      _material = preset.material;
      _strikePoint = preset.strike;
      _damping = preset.damping;
    });
    _disposePlayers();
    unawaited(_warmUpActivePreset());
  }

  Future<void> _warmUpActivePreset() async {
    await _playerFor(_activePreset.styleId).warmUp();
  }

  @override
  void dispose() {
    _disposePlayers();
    super.dispose();
  }

  Future<void> _strike() async {
    HapticFeedback.lightImpact();
    unawaited(
      _playerFor(_activePreset.styleId).play(volume: _ring.clamp(0.2, 1.0)),
    );
    if (!mounted) return;
    setState(() {
      _hits += 1;
      _flash = 1;
    });
    Future<void>.delayed(const Duration(milliseconds: 160), () {
      if (!mounted) return;
      setState(() => _flash = 0);
    });
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
                  zh: '击打',
                  en: 'Hits',
                  ja: 'ヒット',
                  de: 'Treffer',
                  fr: 'Coups',
                  es: 'Golpes',
                  ru: 'Удары',
                ),
                value: '$_hits',
              ),
              ToolboxMetricCard(
                label: pickUiText(
                  i18n,
                  zh: '振铃',
                  en: 'Ring',
                  ja: 'リング',
                  de: 'Ring',
                  fr: 'Résonance',
                  es: 'Resonancia',
                  ru: 'Звон',
                ),
                value: '${(_ring * 100).round()}%',
              ),
              ToolboxMetricCard(
                label: pickUiText(
                  i18n,
                  zh: '材质',
                  en: 'Material',
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
              zh: '预设会同步调整三角铁音色与默认振铃长度。',
              en: 'Presets change triangle tone and default ring length together.',
              ja: 'プリセットで音色と余韻長を同時に切り替えます。',
              de: 'Presets ändern Klangfarbe und Nachklanglänge gemeinsam.',
              fr: 'Les presets ajustent timbre et longueur de résonance.',
              es: 'Los presets ajustan timbre y longitud de resonancia.',
              ru: 'Пресеты одновременно меняют тембр и длину звона.',
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
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => unawaited(_strike()),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              height: widget.fullScreen ? 260 : 210,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    const Color(0xFFE6EEF9),
                    Color.lerp(
                      const Color(0xFFC9DDF8),
                      const Color(0xFFEAB308),
                      _flash * 0.24,
                    )!,
                  ],
                ),
                border: Border.all(color: const Color(0xFF98B6DE)),
              ),
              child: CustomPaint(
                painter: _TriangleInstrumentPainter(intensity: _flash),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            pickUiText(
              i18n,
              zh: '振铃 ${(_ring * 100).round()}%',
              en: 'Ring ${(_ring * 100).round()}%',
              ja: 'リング ${(_ring * 100).round()}%',
              de: 'Ring ${(_ring * 100).round()}%',
              fr: 'Résonance ${(_ring * 100).round()}%',
              es: 'Resonancia ${(_ring * 100).round()}%',
              ru: 'Звон ${(_ring * 100).round()}%',
            ),
          ),
          Slider(
            value: _ring,
            min: 0.2,
            max: 1,
            divisions: 16,
            onChanged: (value) => setState(() => _ring = value),
          ),
          const SizedBox(height: 8),
          SectionHeader(
            title: pickUiText(i18n, zh: '音色与残响', en: 'Tone and decay'),
            subtitle: pickUiText(
              i18n,
              zh: '开放材质、敲击点和阻尼，让全屏时依然保持沉浸式演奏。',
              en: 'Expose material, strike point, and damping while keeping fullscreen play immersive.',
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <String>['steel', 'brass', 'aluminum']
                .map(
                  (item) => ChoiceChip(
                    label: Text(_materialLabel(i18n, item)),
                    selected: item == _material,
                    onSelected: (_) {
                      if (item == _material) return;
                      setState(() => _material = item);
                      _disposePlayers();
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
              zh: '敲击点 ${(_strikePoint * 100).round()}%',
              en: 'Strike ${(_strikePoint * 100).round()}%',
            ),
          ),
          Slider(
            value: _strikePoint,
            min: 0.1,
            max: 1.0,
            divisions: 18,
            onChanged: (value) => setState(() => _strikePoint = value),
            onChangeEnd: (_) {
              _disposePlayers();
              unawaited(_warmUpActivePreset());
            },
          ),
          Text(
            pickUiText(
              i18n,
              zh: '阻尼 ${(_damping * 100).round()}%',
              en: 'Damping ${(_damping * 100).round()}%',
            ),
          ),
          Slider(
            value: _damping,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            onChanged: (value) => setState(() => _damping = value),
            onChangeEnd: (_) {
              _disposePlayers();
              unawaited(_warmUpActivePreset());
            },
          ),
          const SizedBox(height: 4),
          FilledButton.icon(
            onPressed: () => unawaited(_strike()),
            icon: const Icon(Icons.music_video_rounded),
            label: Text(
              pickUiText(
                i18n,
                zh: '敲击三角铁',
                en: 'Strike triangle',
                ja: 'トライアングルを鳴らす',
                de: 'Triangel anschlagen',
                fr: 'Frapper le triangle',
                es: 'Golpear triángulo',
                ru: 'Ударить треугольник',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TriangleInstrumentPainter extends CustomPainter {
  const _TriangleInstrumentPainter({required this.intensity});

  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final top = Offset(size.width * 0.5, size.height * 0.18);
    final left = Offset(size.width * 0.24, size.height * 0.8);
    final right = Offset(size.width * 0.76, size.height * 0.8);
    final path = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();

    final glow = Paint()
      ..color = const Color(
        0xFFF59E0B,
      ).withValues(alpha: 0.18 + intensity * 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path, glow);

    final stroke = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color(0xFF6B7D99),
          Color(0xFF314255),
          Color(0xFF1C2937),
        ],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, stroke);

    final striker = Paint()
      ..color = const Color(0xFF243447)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final strikerX = size.width * 0.78;
    final strikerY = size.height * (0.28 + intensity * 0.02);
    canvas.drawLine(
      Offset(strikerX, strikerY),
      Offset(strikerX + 34, strikerY + 50),
      striker,
    );
    canvas.drawCircle(
      Offset(strikerX + 34, strikerY + 50),
      5,
      Paint()..color = const Color(0xFFF59E0B).withValues(alpha: 0.8),
    );
  }

  @override
  bool shouldRepaint(covariant _TriangleInstrumentPainter oldDelegate) {
    return oldDelegate.intensity != intensity;
  }
}
