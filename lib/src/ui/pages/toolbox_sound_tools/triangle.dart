part of '../toolbox_sound_tools.dart';

class _TriangleTool extends StatefulWidget {
  const _TriangleTool({this.fullScreen = false});

  final bool fullScreen;

  @override
  State<_TriangleTool> createState() => _TriangleToolState();
}

enum _TrianglePlayMode { single, accent, roll }

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
  _TrianglePlayMode _playMode = _TrianglePlayMode.single;
  String _lastGesture = 'Single';
  bool _rollInFlight = false;

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
      'soft_ring' => pickUiText(i18n, zh: '柔和振铃', en: 'Soft ring'),
      'bright_ring' => pickUiText(i18n, zh: '明亮振铃', en: 'Bright ring'),
      _ => pickUiText(i18n, zh: '管弦振铃', en: 'Orchestral ring'),
    };
  }

  String _presetSubtitle(AppI18n i18n, _TrianglePreset preset) {
    return switch (preset.id) {
      'soft_ring' => pickUiText(
        i18n,
        zh: '更柔和的高频和更短的尾音，适合轻节奏点缀。',
        en: 'Softer highs and a shorter tail for gentle rhythm support.',
      ),
      'bright_ring' => pickUiText(
        i18n,
        zh: '更亮更脆，尾音更明显，适合强调拍点。',
        en: 'Brighter attack and stronger ring to mark accents.',
      ),
      _ => pickUiText(
        i18n,
        zh: '明亮与延音更平衡，更接近管弦语境。',
        en: 'Balanced brightness and decay close to orchestral behavior.',
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

  String _playModeLabel(AppI18n i18n, _TrianglePlayMode mode) {
    return switch (mode) {
      _TrianglePlayMode.accent => pickUiText(i18n, zh: '重击', en: 'Accent'),
      _TrianglePlayMode.roll => pickUiText(i18n, zh: '滚奏', en: 'Roll'),
      _ => pickUiText(i18n, zh: '单击', en: 'Single'),
    };
  }

  ToolboxEffectPlayer _playerFor({double? strike, double? damping}) {
    final resolvedStrike = strike ?? _strikePoint;
    final resolvedDamping = damping ?? _damping;
    final cacheKey =
        '${_activePreset.styleId}:$_material:${resolvedStrike.toStringAsFixed(2)}:${resolvedDamping.toStringAsFixed(2)}';
    final existing = _players[cacheKey];
    if (existing != null) return existing;
    final created = ToolboxEffectPlayer(
      ToolboxAudioBank.triangleHit(
        style: _activePreset.styleId,
        material: _material,
        strike: resolvedStrike,
        damping: resolvedDamping,
      ),
      maxPlayers: 8,
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
    await _playerFor().warmUp();
  }

  Future<void> _performHit({
    double? strike,
    double? damping,
    double? volume,
    required String gesture,
  }) async {
    HapticFeedback.lightImpact();
    unawaited(
      _playerFor(
        strike: strike,
        damping: damping,
      ).play(volume: (volume ?? _ring).clamp(0.2, 1.0)),
    );
    if (!mounted) return;
    setState(() {
      _hits += 1;
      _flash = 1;
      _lastGesture = gesture;
    });
    Future<void>.delayed(const Duration(milliseconds: 160), () {
      if (!mounted) return;
      setState(() => _flash = 0);
    });
  }

  Future<void> _strikeFromStage(Offset localPosition, Size size) async {
    final xRatio = (localPosition.dx / size.width).clamp(0.0, 1.0);
    final yRatio = (localPosition.dy / size.height).clamp(0.0, 1.0);
    switch (_playMode) {
      case _TrianglePlayMode.accent:
        await _performHit(
          strike: (0.45 + xRatio * 0.5).clamp(0.0, 1.0),
          damping: (_damping * 0.72).clamp(0.0, 1.0),
          volume: (_ring + 0.12).clamp(0.0, 1.0),
          gesture: 'Accent',
        );
      case _TrianglePlayMode.roll:
        if (_rollInFlight) return;
        _rollInFlight = true;
        final baseStrike = (0.25 + xRatio * 0.6).clamp(0.0, 1.0);
        final baseDamping = (_damping + yRatio * 0.16).clamp(0.0, 1.0);
        for (var index = 0; index < 7; index += 1) {
          await _performHit(
            strike: (baseStrike + index * 0.02).clamp(0.0, 1.0),
            damping: baseDamping,
            volume: (_ring * (0.72 + index * 0.04)).clamp(0.0, 1.0),
            gesture: 'Roll',
          );
          await Future<void>.delayed(const Duration(milliseconds: 70));
        }
        _rollInFlight = false;
      case _TrianglePlayMode.single:
        await _performHit(
          strike: (0.2 + xRatio * 0.7).clamp(0.0, 1.0),
          damping: (_damping + (yRatio - 0.5).abs() * 0.12).clamp(0.0, 1.0),
          volume: (_ring * (0.88 + xRatio * 0.12)).clamp(0.0, 1.0),
          gesture: 'Single',
        );
    }
  }

  Widget _buildTriangleStage(
    BuildContext context,
    AppI18n i18n, {
    required double height,
    required bool immersive,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, height);
        return GestureDetector(
          onTapDown: (details) =>
              unawaited(_strikeFromStage(details.localPosition, size)),
          onPanStart: (details) =>
              unawaited(_strikeFromStage(details.localPosition, size)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.fullScreen ? 24 : 18),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  immersive ? const Color(0xFF0F172A) : const Color(0xFFE6EEF9),
                  Color.lerp(
                    immersive
                        ? const Color(0xFF172554)
                        : const Color(0xFFC9DDF8),
                    const Color(0xFFEAB308),
                    _flash * 0.24,
                  )!,
                ],
              ),
              border: Border.all(
                color: immersive
                    ? Colors.white.withValues(alpha: 0.14)
                    : const Color(0xFF98B6DE),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: immersive ? 0.30 : 0.14,
                  ),
                  blurRadius: immersive ? 24 : 14,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TriangleInstrumentPainter(intensity: _flash),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        pickUiText(i18n, zh: '左侧更柔', en: 'Left softer'),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: immersive
                              ? Colors.white70
                              : const Color(0xFF334155),
                        ),
                      ),
                      Text(
                        pickUiText(i18n, zh: '右侧更亮', en: 'Right brighter'),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: immersive
                              ? Colors.white70
                              : const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTriangleSettingsContent(
    BuildContext context,
    AppI18n i18n, {
    required VoidCallback refreshSheet,
  }) {
    final theme = Theme.of(context);
    final preset = _activePreset;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          pickUiText(i18n, zh: '三角铁设置', en: 'Triangle settings'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            ToolboxMetricCard(
              label: 'Preset',
              value: _presetLabel(i18n, preset),
            ),
            ToolboxMetricCard(
              label: 'Mode',
              value: _playModeLabel(i18n, _playMode),
            ),
            ToolboxMetricCard(
              label: 'Material',
              value: _materialLabel(i18n, _material),
            ),
          ],
        ),
        const SizedBox(height: 16),
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
        Text(_presetSubtitle(i18n, preset), style: theme.textTheme.bodySmall),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _TrianglePlayMode.values
              .map(
                (mode) => ChoiceChip(
                  label: Text(_playModeLabel(i18n, mode)),
                  selected: _playMode == mode,
                  onSelected: (_) {
                    setState(() => _playMode = mode);
                    refreshSheet();
                  },
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 16),
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
                    refreshSheet();
                  },
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 14),
        Text(
          pickUiText(
            i18n,
            zh: '振铃 ${(_ring * 100).round()}%',
            en: 'Ring ${(_ring * 100).round()}%',
          ),
        ),
        Slider(
          value: _ring,
          min: 0.2,
          max: 1,
          divisions: 16,
          onChanged: (value) {
            _ring = value;
            refreshSheet();
          },
          onChangeEnd: (_) {
            if (mounted) {
              setState(() {});
            }
            refreshSheet();
          },
        ),
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
          onChanged: (value) {
            _strikePoint = value;
            refreshSheet();
          },
          onChangeEnd: (_) {
            if (mounted) {
              setState(() {});
            }
            _disposePlayers();
            unawaited(_warmUpActivePreset());
            refreshSheet();
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
          onChanged: (value) {
            _damping = value;
            refreshSheet();
          },
          onChangeEnd: (_) {
            if (mounted) {
              setState(() {});
            }
            _disposePlayers();
            unawaited(_warmUpActivePreset());
            refreshSheet();
          },
        ),
      ],
    );
  }

  Future<void> _openTriangleSettingsSheet(BuildContext context, AppI18n i18n) {
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
                child: _buildTriangleSettingsContent(
                  sheetContext,
                  i18n,
                  refreshSheet: () => setSheetState(() {}),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickControls(
    BuildContext context,
    AppI18n i18n, {
    required bool immersive,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        FilledButton.tonalIcon(
          onPressed: () => setState(() => _playMode = _TrianglePlayMode.single),
          icon: const Icon(Icons.radio_button_checked_rounded),
          label: Text(_playModeLabel(i18n, _TrianglePlayMode.single)),
        ),
        FilledButton.tonalIcon(
          onPressed: () => setState(() => _playMode = _TrianglePlayMode.accent),
          icon: const Icon(Icons.bolt_rounded),
          label: Text(_playModeLabel(i18n, _TrianglePlayMode.accent)),
        ),
        FilledButton.tonalIcon(
          onPressed: () => setState(() => _playMode = _TrianglePlayMode.roll),
          icon: const Icon(Icons.multitrack_audio_rounded),
          label: Text(_playModeLabel(i18n, _TrianglePlayMode.roll)),
        ),
        if (!immersive)
          OutlinedButton.icon(
            onPressed: () => _openTriangleSettingsSheet(context, i18n),
            icon: const Icon(Icons.tune_rounded),
            label: Text(pickUiText(i18n, zh: '设置', en: 'Settings')),
          ),
      ],
    );
  }

  Widget _buildFullScreen(BuildContext context, AppI18n i18n) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFF020617),
            Color(0xFF172554),
            Color(0xFF0F172A),
          ],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stageHeight = math.min(420.0, constraints.maxHeight - 220);
            return Stack(
              children: <Widget>[
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 54, 16, bottomInset + 114),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: <Widget>[
                            _PianoOverlayChip(
                              label: 'Preset',
                              value: _presetLabel(i18n, _activePreset),
                            ),
                            _PianoOverlayChip(
                              label: 'Mode',
                              value: _playModeLabel(i18n, _playMode),
                            ),
                            _PianoOverlayChip(
                              label: 'Material',
                              value: _materialLabel(i18n, _material),
                            ),
                            _PianoOverlayChip(label: 'Hits', value: '$_hits'),
                          ],
                        ),
                        const Spacer(),
                        _buildTriangleStage(
                          context,
                          i18n,
                          height: stageHeight,
                          immersive: true,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  top: 8,
                  child: Row(
                    children: <Widget>[
                      FilledButton.tonal(
                        onPressed: () => Navigator.of(context).pop(),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.34),
                          foregroundColor: Colors.white,
                        ),
                        child: const Icon(Icons.arrow_back_rounded),
                      ),
                      const Spacer(),
                      FilledButton.tonalIcon(
                        onPressed: () =>
                            _openTriangleSettingsSheet(context, i18n),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.34),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.tune_rounded),
                        label: Text(pickUiText(i18n, zh: '设置', en: 'Settings')),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: bottomInset + 12,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            pickUiText(
                              i18n,
                              zh: '左侧更柔，右侧更亮；滚奏模式适合连续紧凑的强调。',
                              en: 'Left is softer, right is brighter; roll mode creates tight repeated accents.',
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildQuickControls(context, i18n, immersive: true),
                        ],
                      ),
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

  @override
  void dispose() {
    _disposePlayers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = _toolboxI18n(context);
    if (widget.fullScreen) {
      return _buildFullScreen(context, i18n);
    }
    final preset = _activePreset;
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
              ToolboxMetricCard(label: 'Hits', value: '$_hits'),
              ToolboxMetricCard(
                label: 'Mode',
                value: _playModeLabel(i18n, _playMode),
              ),
              ToolboxMetricCard(label: 'Gesture', value: _lastGesture),
              ToolboxMetricCard(
                label: 'Ring',
                value: '${(_ring * 100).round()}%',
              ),
              ToolboxMetricCard(
                label: 'Material',
                value: _materialLabel(i18n, _material),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SectionHeader(
            title: pickUiText(i18n, zh: '预设包', en: 'Preset pack'),
            subtitle: pickUiText(
              i18n,
              zh: '预设会联动音色、默认材质和延音长度。',
              en: 'Presets move tone, material, and default ring length together.',
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
          const SizedBox(height: 14),
          SectionHeader(
            title: pickUiText(i18n, zh: '击打舞台', en: 'Strike stage'),
            subtitle: pickUiText(
              i18n,
              zh: '直接在三角铁画面上点按：左柔右亮，模式决定是单击、重击还是滚奏。',
              en: 'Tap directly on the triangle: left is softer, right is brighter, and the mode changes the gesture output.',
            ),
          ),
          const SizedBox(height: 10),
          _buildTriangleStage(context, i18n, height: 240, immersive: false),
          const SizedBox(height: 12),
          _buildQuickControls(context, i18n, immersive: false),
          const SizedBox(height: 14),
          SectionHeader(
            title: pickUiText(i18n, zh: '音色与衰减', en: 'Tone and decay'),
            subtitle: pickUiText(
              i18n,
              zh: '材质决定泛音质感，敲击点和阻尼决定脆度与尾音长度。',
              en: 'Material shapes overtones while strike point and damping control attack and tail.',
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
              zh: '振铃 ${(_ring * 100).round()}%',
              en: 'Ring ${(_ring * 100).round()}%',
            ),
          ),
          Slider(
            value: _ring,
            min: 0.2,
            max: 1,
            divisions: 16,
            onChanged: (value) => setState(() => _ring = value),
          ),
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
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => unawaited(_performHit(gesture: 'Single')),
            icon: const Icon(Icons.music_video_rounded),
            label: Text(pickUiText(i18n, zh: '立即击打', en: 'Strike now')),
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
