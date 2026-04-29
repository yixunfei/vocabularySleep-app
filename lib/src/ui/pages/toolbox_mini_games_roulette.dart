part of 'toolbox_mini_games.dart';

enum _RoulettePhase { setup, loading, ready, hit }

class _RouletteGame extends StatefulWidget {
  const _RouletteGame();

  @override
  State<_RouletteGame> createState() => _RouletteGameState();
}

class _RouletteGameState extends State<_RouletteGame>
    with TickerProviderStateMixin {
  static const int _chambers = 6;
  final math.Random _random = math.Random();
  late final AnimationController _ambientController;
  late final AnimationController _flashController;
  late final AnimationController _cylinderController;
  late final AnimationController _triggerController;
  late final AnimationController _emptyClickController;
  late final AnimationController _shotController;

  int _bulletCount = 1;
  late List<bool> _sequence;
  int _activeChamber = 0;
  int _pullIndex = 0;
  int _safePulls = 0;
  _RoulettePhase _phase = _RoulettePhase.setup;
  OverlayEntry? _flashEntry;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6800),
    )..repeat();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    _cylinderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _triggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _emptyClickController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _shotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1180),
    );
    _sequence = _buildSequence();
  }

  @override
  void dispose() {
    _flashEntry?.remove();
    _flashEntry = null;
    _ambientController.dispose();
    _flashController.dispose();
    _cylinderController.dispose();
    _triggerController.dispose();
    _emptyClickController.dispose();
    _shotController.dispose();
    super.dispose();
  }

  List<bool> _buildSequence() {
    final next = <bool>[
      for (var index = 0; index < _chambers; index += 1) index < _bulletCount,
    ]..shuffle(_random);
    return next;
  }

  String _text(AppI18n i18n, {required String zh, required String en}) {
    return pickUiText(i18n, zh: zh, en: en);
  }

  void _playCue(SystemSoundType type) {
    unawaited(SystemSound.play(type));
  }

  void _resetToSetup({int? bullets}) {
    _cylinderController
      ..stop()
      ..value = 0;
    _triggerController
      ..stop()
      ..value = 0;
    _emptyClickController
      ..stop()
      ..value = 0;
    _shotController
      ..stop()
      ..value = 0;
    _flashController
      ..stop()
      ..value = 0;
    _flashEntry?.remove();
    _flashEntry = null;
    setState(() {
      if (bullets != null) {
        _bulletCount = bullets.clamp(1, _chambers - 1);
      }
      _sequence = _buildSequence();
      _activeChamber = 0;
      _pullIndex = 0;
      _safePulls = 0;
      _phase = _RoulettePhase.setup;
    });
  }

  Future<void> _prepareRound() async {
    if (_phase == _RoulettePhase.loading) {
      return;
    }
    _shotController
      ..stop()
      ..value = 0;
    _emptyClickController
      ..stop()
      ..value = 0;
    setState(() {
      _sequence = _buildSequence();
      _activeChamber = 0;
      _pullIndex = 0;
      _safePulls = 0;
      _phase = _RoulettePhase.loading;
    });
    _playCue(SystemSoundType.click);
    unawaited(HapticFeedback.mediumImpact());
    _cylinderController.repeat(period: const Duration(milliseconds: 460));
    await Future<void>.delayed(const Duration(milliseconds: 1180));
    if (!mounted || _phase != _RoulettePhase.loading) {
      return;
    }
    _cylinderController
      ..stop()
      ..value = 0;
    setState(() {
      _phase = _RoulettePhase.ready;
    });
    unawaited(HapticFeedback.selectionClick());
  }

  Future<void> _pullTrigger() async {
    if (_phase != _RoulettePhase.ready || _pullIndex >= _chambers) {
      return;
    }
    final chamberIndex = _activeChamber;
    final chamberHasBullet = _sequence[chamberIndex];

    _playCue(SystemSoundType.click);
    unawaited(HapticFeedback.selectionClick());
    unawaited(_triggerController.forward(from: 0));

    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!mounted || _phase != _RoulettePhase.ready) {
      return;
    }
    if (chamberHasBullet) {
      setState(() {
        _pullIndex += 1;
        _phase = _RoulettePhase.hit;
      });
      unawaited(_shotController.forward(from: 0));
      _playCue(SystemSoundType.alert);
      unawaited(HapticFeedback.heavyImpact());
      unawaited(HapticFeedback.vibrate());
      _showFlashOverlay();
      return;
    }

    setState(() {
      _pullIndex += 1;
      _safePulls += 1;
      _activeChamber = (_activeChamber + 1) % _chambers;
    });
    unawaited(HapticFeedback.lightImpact());
    unawaited(_emptyClickController.forward(from: 0));
  }

  void _showFlashOverlay() {
    final overlay = Overlay.of(context, rootOverlay: true);
    _flashEntry?.remove();
    final entry = OverlayEntry(
      builder: (context) {
        return IgnorePointer(
          child: AnimatedBuilder(
            animation: _flashController,
            builder: (context, _) {
              final t = _flashController.value.clamp(0.0, 1.0);
              final flash = 1 - Curves.easeOutCubic.transform(t);
              final ember = 1 - Curves.easeInQuad.transform(t);
              return Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Opacity(
                    opacity: (flash * 0.42).clamp(0.0, 0.42),
                    child: const ColoredBox(color: Color(0xFFFFF0C2)),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0.78, -0.08),
                        radius: 0.74 + t * 0.34,
                        colors: <Color>[
                          const Color(
                            0xFFFFD166,
                          ).withValues(alpha: ember * 0.46),
                          const Color(
                            0xFF7A221A,
                          ).withValues(alpha: ember * 0.18),
                          Colors.black.withValues(alpha: 0),
                        ],
                        stops: const <double>[0, 0.38, 1],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
    _flashEntry = entry;
    overlay.insert(entry);
    _flashController
      ..stop()
      ..forward(from: 0).whenComplete(() {
        if (_flashEntry == entry) {
          entry.remove();
          _flashEntry = null;
        }
      });
  }

  String _statusLabel(AppI18n i18n) {
    return switch (_phase) {
      _RoulettePhase.setup => _text(i18n, zh: '待上膛', en: 'Not loaded'),
      _RoulettePhase.loading => _text(i18n, zh: '旋转弹仓', en: 'Spinning'),
      _RoulettePhase.ready => _text(i18n, zh: '已就绪', en: 'Ready'),
      _RoulettePhase.hit => _text(i18n, zh: '击发命中', en: 'Fired'),
    };
  }

  String _stageText(AppI18n i18n) {
    if (_phase == _RoulettePhase.loading) {
      return _text(
        i18n,
        zh: '弹仓高速旋转，金属棘轮正在落位',
        en: 'Cylinder spinning. The ratchet is settling into place.',
      );
    }
    if (_phase == _RoulettePhase.ready && _safePulls > 0) {
      return _text(
        i18n,
        zh: '空膛咔哒，机械落位到下一膛',
        en: 'Empty click. The mechanism steps to the next chamber.',
      );
    }
    if (_phase == _RoulettePhase.hit) {
      return _text(
        i18n,
        zh: '击发瞬间：后坐、火光与烟雾已释放',
        en: 'Fired: recoil, muzzle flash, and smoke are released.',
      );
    }
    return _text(
      i18n,
      zh: '调整装填数量，再旋转弹仓开始',
      en: 'Set the load, then spin the cylinder to begin.',
    );
  }

  Widget _buildRevolverStage(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final accent = const Color(0xFFC2554C);
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[
            _ambientController,
            _cylinderController,
            _triggerController,
            _emptyClickController,
            _shotController,
          ]),
          builder: (context, _) {
            final triggerProgress = math
                .sin(_triggerController.value * math.pi)
                .clamp(0.0, 1.0);
            final cylinderTurn = _phase == _RoulettePhase.loading
                ? _cylinderController.value * math.pi * 9.6
                : 0.0;
            final stageText = _stageText(i18n);
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color.alphaBlend(
                      const Color(0xFF121318).withValues(alpha: 0.88),
                      colors.surfaceContainerHighest,
                    ),
                    Color.alphaBlend(
                      accent.withValues(alpha: 0.18),
                      const Color(0xFF1B1414),
                    ),
                    const Color(0xFF09090B),
                  ],
                ),
                border: Border.all(
                  color: Color.alphaBlend(
                    accent.withValues(alpha: 0.24),
                    colors.outlineVariant,
                  ),
                ),
              ),
              child: CustomPaint(
                painter: _RouletteStageAtmospherePainter(
                  colorScheme: colors,
                  accent: accent,
                  ambientProgress: _ambientController.value,
                  shotProgress: _phase == _RoulettePhase.hit
                      ? _shotController.value
                      : 0,
                  phase: _phase,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                  child: Column(
                    children: <Widget>[
                      AspectRatio(
                        aspectRatio: 1.58,
                        child: CustomPaint(
                          painter: _RouletteRevolverPainter(
                            colorScheme: colors,
                            bulletCount: _bulletCount,
                            sequence: _sequence,
                            activeChamber: _activeChamber,
                            pullIndex: _pullIndex,
                            phase: _phase,
                            cylinderTurn: cylinderTurn,
                            triggerProgress: triggerProgress,
                            ambientProgress: _ambientController.value,
                            emptyClickProgress: _emptyClickController.value,
                            shotProgress: _phase == _RoulettePhase.hit
                                ? _shotController.value
                                : 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: Container(
                          key: ValueKey<String>(stageText),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.black.withValues(alpha: 0.34),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.11),
                            ),
                          ),
                          child: Text(
                            stageText,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
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

  Widget _buildStatusConsole(
    BuildContext context,
    AppI18n i18n, {
    required int remaining,
  }) {
    final colors = Theme.of(context).colorScheme;
    final accent = const Color(0xFFC2554C);
    final tiles = <Widget>[
      _RouletteStatusTile(
        label: _text(i18n, zh: '装填', en: 'Load'),
        value: '$_bulletCount / $_chambers',
        accent: accent,
      ),
      _RouletteStatusTile(
        label: _text(i18n, zh: '空膛', en: 'Empty'),
        value: '$_safePulls',
        accent: const Color(0xFFB8A47A),
      ),
      _RouletteStatusTile(
        label: _text(i18n, zh: '膛位', en: 'Chambers'),
        value: '$remaining',
        accent: const Color(0xFF7FA0B8),
      ),
      _RouletteStatusTile(
        label: _text(i18n, zh: '状态', en: 'Status'),
        value: _statusLabel(i18n),
        accent: _phase == _RoulettePhase.hit ? colors.error : accent,
        emphasized: _phase == _RoulettePhase.ready,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            colors.surfaceContainerHigh,
            Color.alphaBlend(
              accent.withValues(alpha: 0.08),
              colors.surfaceContainerLow,
            ),
          ],
        ),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 460;
          final spacing = 8.0;
          final tileWidth = compact
              ? math.max(120.0, (constraints.maxWidth - spacing) / 2)
              : math.max(120.0, (constraints.maxWidth - spacing * 3) / 4);
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: tiles
                .map((tile) => SizedBox(width: tileWidth, child: tile))
                .toList(growable: false),
          );
        },
      ),
    );
  }

  Widget _buildControlPanel(
    BuildContext context,
    AppI18n i18n, {
    required bool canPrepare,
    required bool canPull,
  }) {
    final colors = Theme.of(context).colorScheme;
    final accent = const Color(0xFFC2554C);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color.alphaBlend(
              accent.withValues(alpha: 0.09),
              colors.surfaceContainerLow,
            ),
            colors.surfaceContainerHigh,
          ],
        ),
        border: Border.all(
          color: Color.alphaBlend(
            accent.withValues(alpha: 0.16),
            colors.outlineVariant,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: <Color>[
                      accent.withValues(alpha: 0.24),
                      accent.withValues(alpha: 0.08),
                    ],
                  ),
                  border: Border.all(color: accent.withValues(alpha: 0.26)),
                ),
                child: Icon(Icons.tune_rounded, color: accent, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _text(i18n, zh: '装填控制', en: 'Load control'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _text(
                        i18n,
                        zh: '设置装填数后旋转弹仓；准备完成后再扣动扳机。',
                        en: 'Set the load, spin the cylinder, then pull.',
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      _text(i18n, zh: '装填数量', en: 'Rounds loaded'),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: accent.withValues(alpha: 0.12),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        '$_bulletCount / $_chambers',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: accent,
                    inactiveTrackColor: accent.withValues(alpha: 0.16),
                    thumbColor: const Color(0xFFFFD166),
                    overlayColor: accent.withValues(alpha: 0.12),
                    valueIndicatorColor: accent,
                  ),
                  child: Slider(
                    value: _bulletCount.toDouble(),
                    min: 1,
                    max: (_chambers - 1).toDouble(),
                    divisions: _chambers - 2,
                    label: '$_bulletCount',
                    onChanged: _phase == _RoulettePhase.loading
                        ? null
                        : (value) => _resetToSetup(bullets: value.round()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.icon(
                onPressed: canPrepare ? _prepareRound : null,
                icon: const Icon(Icons.sync_rounded),
                label: Text(_text(i18n, zh: '旋转弹仓', en: 'Spin cylinder')),
              ),
              FilledButton.icon(
                onPressed: canPull ? _pullTrigger : null,
                icon: const Icon(Icons.touch_app_rounded),
                label: Text(_text(i18n, zh: '扣动扳机', en: 'Pull trigger')),
              ),
              OutlinedButton.icon(
                onPressed: _phase == _RoulettePhase.loading
                    ? null
                    : _resetToSetup,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(_text(i18n, zh: '重置', en: 'Reset')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final remaining = math.max(0, _chambers - _pullIndex);
    final canPrepare =
        _phase == _RoulettePhase.setup || _phase == _RoulettePhase.hit;
    final canPull = _phase == _RoulettePhase.ready;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildStatusConsole(context, i18n, remaining: remaining),
            const SizedBox(height: 14),
            _buildRevolverStage(context),
            const SizedBox(height: 14),
            _buildControlPanel(
              context,
              i18n,
              canPrepare: canPrepare,
              canPull: canPull,
            ),
            const SizedBox(height: 12),
            Text(
              _text(
                i18n,
                zh: '命中效果为短促冲击光、后坐、火光、烟雾和震动；空膛保留金属咔哒与弹仓推进反馈。',
                en: 'A hit uses a brief impact glow, recoil, flash, smoke, and haptics; empty pulls keep the metallic click and chamber step feedback.',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _RouletteStatusTile extends StatelessWidget {
  const _RouletteStatusTile({
    required this.label,
    required this.value,
    required this.accent,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final Color accent;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Color.alphaBlend(
          accent.withValues(alpha: emphasized ? 0.18 : 0.08),
          colors.surfaceContainerLowest,
        ),
        border: Border.all(
          color: accent.withValues(alpha: emphasized ? 0.42 : 0.2),
        ),
        boxShadow: emphasized
            ? <BoxShadow>[
                BoxShadow(
                  color: accent.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouletteStageAtmospherePainter extends CustomPainter {
  const _RouletteStageAtmospherePainter({
    required this.colorScheme,
    required this.accent,
    required this.ambientProgress,
    required this.shotProgress,
    required this.phase,
  });

  final ColorScheme colorScheme;
  final Color accent;
  final double ambientProgress;
  final double shotProgress;
  final _RoulettePhase phase;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final pulse = 0.5 + 0.5 * math.sin(ambientProgress * math.pi * 2);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(size.width, size.height),
          <Color>[
            const Color(0xFF15161B),
            Color.alphaBlend(
              accent.withValues(alpha: 0.10 + pulse * 0.04),
              const Color(0xFF191111),
            ),
            const Color(0xFF070708),
          ],
          const <double>[0, 0.48, 1],
        ),
    );

    final spotlight = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.46, size.height * 0.38),
        size.width * (0.46 + pulse * 0.03),
        <Color>[
          Colors.white.withValues(alpha: 0.12 + pulse * 0.03),
          accent.withValues(alpha: 0.09),
          Colors.transparent,
        ],
        const <double>[0, 0.42, 1],
      );
    canvas.drawRect(rect, spotlight);

    final vignette = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width * 0.5, size.height * 0.44),
        size.width * 0.78,
        <Color>[Colors.transparent, Colors.black.withValues(alpha: 0.54)],
        const <double>[0.46, 1],
      );
    canvas.drawRect(rect, vignette);

    final tableLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1;
    for (var index = 0; index < 9; index += 1) {
      final y = size.height * (0.64 + index * 0.035);
      canvas.drawLine(
        Offset(size.width * -0.1, y),
        Offset(size.width * 1.08, y + size.height * 0.11),
        tableLinePaint,
      );
    }

    final dustPaint = Paint()..style = PaintingStyle.fill;
    for (var index = 0; index < 24; index += 1) {
      final seed = index * 12.9898;
      final drift = math.sin(ambientProgress * math.pi * 2 + seed);
      final x =
          (size.width * ((math.sin(seed) * 0.5 + 0.5) * 0.92 + 0.04)) +
          drift * 2.5;
      final y =
          size.height * ((math.cos(seed * 1.7) * 0.5 + 0.5) * 0.72 + 0.06);
      final alpha =
          0.05 + (math.sin(seed + ambientProgress * math.pi * 4) + 1) * 0.025;
      dustPaint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), 0.7 + index % 3 * 0.25, dustPaint);
    }

    if (phase == _RoulettePhase.hit && shotProgress > 0) {
      final t = shotProgress.clamp(0.0, 1.0);
      final flash = 1 - Curves.easeOutCubic.transform(t);
      final muzzle = Offset(size.width * 0.88, size.height * 0.37);
      canvas.drawCircle(
        muzzle,
        size.width * (0.18 + t * 0.34),
        Paint()
          ..shader = ui.Gradient.radial(
            muzzle,
            size.width * (0.22 + t * 0.32),
            <Color>[
              const Color(0xFFFFD166).withValues(alpha: flash * 0.24),
              const Color(0xFFC2554C).withValues(alpha: flash * 0.10),
              Colors.transparent,
            ],
            const <double>[0, 0.42, 1],
          ),
      );

      final smokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.008
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
      for (var index = 0; index < 4; index += 1) {
        final localT = ((t - 0.10) * 1.18 - index * 0.08).clamp(0.0, 1.0);
        if (localT <= 0) {
          continue;
        }
        final alpha = (1 - localT) * 0.22;
        smokePaint.color = const Color(0xFFD8D0C4).withValues(alpha: alpha);
        final start = muzzle + Offset(size.width * (0.03 + index * 0.018), 0);
        final path = Path()
          ..moveTo(start.dx, start.dy)
          ..cubicTo(
            start.dx + size.width * (0.04 + localT * 0.08),
            start.dy - size.height * (0.06 + index * 0.02),
            start.dx + size.width * (0.12 + localT * 0.12),
            start.dy + size.height * (0.02 - index * 0.03),
            start.dx + size.width * (0.18 + localT * 0.18),
            start.dy - size.height * (0.02 + index * 0.015),
          );
        canvas.drawPath(path, smokePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RouletteStageAtmospherePainter oldDelegate) {
    return oldDelegate.colorScheme != colorScheme ||
        oldDelegate.accent != accent ||
        oldDelegate.ambientProgress != ambientProgress ||
        oldDelegate.shotProgress != shotProgress ||
        oldDelegate.phase != phase;
  }
}

class _RouletteRevolverPainter extends CustomPainter {
  const _RouletteRevolverPainter({
    required this.colorScheme,
    required this.bulletCount,
    required this.sequence,
    required this.activeChamber,
    required this.pullIndex,
    required this.phase,
    required this.cylinderTurn,
    required this.triggerProgress,
    required this.ambientProgress,
    required this.emptyClickProgress,
    required this.shotProgress,
  });

  final ColorScheme colorScheme;
  final int bulletCount;
  final List<bool> sequence;
  final int activeChamber;
  final int pullIndex;
  final _RoulettePhase phase;
  final double cylinderTurn;
  final double triggerProgress;
  final double ambientProgress;
  final double emptyClickProgress;
  final double shotProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final shotT = shotProgress.clamp(0.0, 1.0).toDouble();
    final emptyT = emptyClickProgress.clamp(0.0, 1.0).toDouble();
    final shotKick = math.sin(shotT * math.pi).clamp(0.0, 1.0).toDouble();
    final emptyKick = math.sin(emptyT * math.pi).clamp(0.0, 1.0).toDouble();
    final rattle =
        math.sin(emptyT * math.pi * 5) * (1 - emptyT) * size.width * 0.004;
    final recoil =
        shotKick * size.width * 0.052 + emptyKick * size.width * 0.01;
    final muzzleLift = -(shotKick * 0.045 + emptyKick * 0.008);
    final pulse = 0.5 + 0.5 * math.sin(ambientProgress * math.pi * 2);

    canvas.save();
    canvas.translate(-recoil + rattle, 0);
    canvas.translate(size.width * 0.47, size.height * 0.48);
    canvas.rotate(muzzleLift);
    canvas.translate(-size.width * 0.47, -size.height * 0.48);

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.34)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.49, size.height * 0.78),
        width: size.width * 0.72,
        height: size.height * 0.18,
      ),
      shadowPaint,
    );

    final darkPaint = Paint()
      ..color = const Color(0xFF171A20)
      ..style = PaintingStyle.fill;
    final edgePaint = Paint()
      ..color = const Color(0xFF111318)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.009;
    final steelPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.width * 0.28, size.height * 0.2),
        Offset(size.width * 0.88, size.height * 0.56),
        <Color>[
          const Color(0xFF9DA6B2).withValues(alpha: 0.98),
          const Color(0xFF4D5561),
          const Color(0xFF1E232B),
        ],
        const <double>[0, 0.42, 1],
      );
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18 + pulse * 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.006
      ..strokeCap = StrokeCap.round;

    final barrel = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.49,
        size.height * 0.27,
        size.width * 0.39,
        size.height * 0.18,
      ),
      Radius.circular(size.height * 0.065),
    );
    canvas.drawRRect(barrel.shift(Offset(0, size.height * 0.018)), darkPaint);
    canvas.drawRRect(barrel, steelPaint);
    canvas.drawRRect(barrel, edgePaint);

    final barrelRail = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.55,
        size.height * 0.23,
        size.width * 0.25,
        size.height * 0.055,
      ),
      Radius.circular(size.height * 0.018),
    );
    canvas.drawRRect(barrelRail, Paint()..color = const Color(0xFF313842));
    canvas.drawLine(
      Offset(size.width * 0.55, size.height * 0.255),
      Offset(size.width * 0.79, size.height * 0.255),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.09)
        ..strokeWidth = size.width * 0.004
        ..strokeCap = StrokeCap.round,
    );

    final muzzle = Offset(size.width * 0.875, size.height * 0.36);
    canvas.drawOval(
      Rect.fromCenter(
        center: muzzle,
        width: size.width * 0.1,
        height: size.height * 0.12,
      ),
      Paint()
        ..shader = ui.Gradient.radial(muzzle, size.width * 0.06, const <Color>[
          Color(0xFF707784),
          Color(0xFF15181E),
        ]),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: muzzle,
        width: size.width * 0.058,
        height: size.height * 0.066,
      ),
      Paint()..color = const Color(0xFF07080A),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: muzzle.translate(-size.width * 0.006, -size.height * 0.006),
        width: size.width * 0.026,
        height: size.height * 0.028,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.09),
    );

    final underlug = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.56,
        size.height * 0.4,
        size.width * 0.27,
        size.height * 0.06,
      ),
      Radius.circular(size.height * 0.025),
    );
    canvas.drawRRect(underlug, darkPaint);

    final frame = Path()
      ..moveTo(size.width * 0.21, size.height * 0.36)
      ..quadraticBezierTo(
        size.width * 0.34,
        size.height * 0.23,
        size.width * 0.53,
        size.height * 0.3,
      )
      ..lineTo(size.width * 0.59, size.height * 0.48)
      ..quadraticBezierTo(
        size.width * 0.43,
        size.height * 0.62,
        size.width * 0.22,
        size.height * 0.51,
      )
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height * 0.45,
        size.width * 0.21,
        size.height * 0.36,
      )
      ..close();
    canvas.drawPath(frame.shift(Offset(0, size.height * 0.014)), darkPaint);
    canvas.drawPath(frame, steelPaint);
    canvas.drawPath(frame, edgePaint);

    final cylinderCenter = Offset(size.width * 0.4, size.height * 0.42);
    final radius = size.height * 0.192;
    _drawCylinder(canvas, size, cylinderCenter, radius, pulse);

    final cylinderLatch = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.47,
        size.height * 0.47,
        size.width * 0.08,
        size.height * 0.025,
      ),
      Radius.circular(size.height * 0.01),
    );
    canvas.drawRRect(cylinderLatch, Paint()..color = const Color(0xFF20242B));

    final grip = Path()
      ..moveTo(size.width * 0.27, size.height * 0.52)
      ..lineTo(size.width * 0.43, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.39,
        size.height * 0.82,
        size.width * 0.22,
        size.height * 0.9,
      )
      ..quadraticBezierTo(
        size.width * 0.12,
        size.height * 0.73,
        size.width * 0.2,
        size.height * 0.56,
      )
      ..close();
    canvas.drawPath(
      grip.shift(Offset(0, size.height * 0.014)),
      Paint()..color = Colors.black.withValues(alpha: 0.28),
    );
    canvas.drawPath(
      grip,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(size.width * 0.18, size.height * 0.55),
          Offset(size.width * 0.38, size.height * 0.88),
          const <Color>[
            Color(0xFF8A5636),
            Color(0xFF5A321F),
            Color(0xFF2F1B14),
          ],
          const <double>[0, 0.56, 1],
        ),
    );
    canvas.save();
    canvas.clipPath(grip);
    final grainPaint = Paint()
      ..color = const Color(0xFFD4A06D).withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.004
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 5; index += 1) {
      final y = size.height * (0.6 + index * 0.055);
      canvas.drawPath(
        Path()
          ..moveTo(size.width * 0.18, y)
          ..quadraticBezierTo(
            size.width * (0.28 + index * 0.01),
            y + size.height * 0.03,
            size.width * 0.38,
            y + size.height * 0.015,
          ),
        grainPaint,
      );
    }
    canvas.restore();
    canvas.drawPath(
      grip,
      Paint()
        ..color = const Color(0xFF2A1711)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.009,
    );
    for (final screw in <Offset>[
      Offset(size.width * 0.29, size.height * 0.61),
      Offset(size.width * 0.25, size.height * 0.78),
    ]) {
      canvas.drawCircle(screw, size.width * 0.019, darkPaint);
      canvas.drawCircle(
        screw.translate(-size.width * 0.003, -size.height * 0.003),
        size.width * 0.008,
        Paint()..color = Colors.white.withValues(alpha: 0.14),
      );
    }

    final triggerGuard = Rect.fromLTWH(
      size.width * 0.34,
      size.height * 0.52,
      size.width * 0.16,
      size.height * 0.18,
    );
    canvas.drawOval(
      triggerGuard,
      Paint()
        ..color = const Color(0xFF151820)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.022,
    );
    canvas.drawOval(
      triggerGuard.deflate(size.width * 0.008),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.004,
    );
    final triggerX = size.width * (0.417 + triggerProgress * 0.043);
    canvas.drawArc(
      Rect.fromLTWH(
        triggerX,
        size.height * 0.535,
        size.width * 0.065,
        size.height * 0.13,
      ),
      math.pi * 0.82,
      math.pi * 0.82,
      false,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(triggerX, size.height * 0.54),
          Offset(triggerX + size.width * 0.06, size.height * 0.66),
          const <Color>[Color(0xFF30353D), Color(0xFF0A0B0D)],
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.014
        ..strokeCap = StrokeCap.round,
    );

    final hammerBack = triggerProgress * 0.045 + shotKick * 0.018;
    final hammer = Path()
      ..moveTo(size.width * 0.235, size.height * 0.345)
      ..lineTo(
        size.width * (0.16 - hammerBack),
        size.height * (0.265 - triggerProgress * 0.018),
      )
      ..quadraticBezierTo(
        size.width * (0.17 - hammerBack),
        size.height * 0.205,
        size.width * (0.225 - hammerBack * 0.4),
        size.height * 0.225,
      )
      ..lineTo(size.width * 0.302, size.height * 0.318)
      ..close();
    canvas.drawPath(hammer, darkPaint);
    canvas.drawPath(
      hammer,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.07)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.004,
    );

    canvas.drawLine(
      Offset(size.width * 0.51, size.height * 0.305),
      Offset(size.width * 0.82, size.height * 0.305),
      highlightPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.27, size.height * 0.39),
      Offset(size.width * 0.53, size.height * 0.33),
      highlightPaint..color = Colors.white.withValues(alpha: 0.08),
    );

    if (phase == _RoulettePhase.hit && shotT < 0.62) {
      _drawMuzzleFlash(canvas, size, muzzle, shotT);
    }

    canvas.restore();
  }

  void _drawCylinder(
    Canvas canvas,
    Size size,
    Offset center,
    double radius,
    double pulse,
  ) {
    final outerPaint = Paint()
      ..shader = ui.Gradient.radial(
        center.translate(-radius * 0.22, -radius * 0.22),
        radius * 1.18,
        const <Color>[Color(0xFF9AA2AD), Color(0xFF4E5662), Color(0xFF171A20)],
        const <double>[0, 0.44, 1],
      );
    canvas.drawCircle(
      center.translate(0, radius * 0.08),
      radius * 1.1,
      Paint()..color = Colors.black.withValues(alpha: 0.34),
    );
    canvas.drawCircle(
      center,
      radius * 1.08,
      Paint()..color = const Color(0xFF14171C),
    );
    canvas.drawCircle(center, radius, outerPaint);

    if (phase == _RoulettePhase.loading) {
      final blurPaint = Paint()
        ..color = const Color(0xFFFFD166).withValues(alpha: 0.15 + pulse * 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.008
        ..strokeCap = StrokeCap.round;
      for (var index = 0; index < 4; index += 1) {
        final start = cylinderTurn + index * math.pi * 0.5;
        canvas.drawArc(
          Rect.fromCircle(
            center: center,
            radius: radius * (0.86 - index * 0.06),
          ),
          start,
          math.pi * 0.34,
          false,
          blurPaint,
        );
      }
    }

    final chambers = sequence.length;
    for (var index = 0; index < chambers; index += 1) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(cylinderTurn + index * math.pi * 2 / chambers);
      final flute = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(radius * 0.38, 0),
          width: radius * 0.22,
          height: radius * 0.55,
        ),
        Radius.circular(radius * 0.11),
      );
      canvas.drawRRect(
        flute,
        Paint()..color = Colors.black.withValues(alpha: 0.18),
      );
      canvas.drawRRect(
        flute.deflate(radius * 0.018),
        Paint()..color = Colors.white.withValues(alpha: 0.035),
      );
      canvas.restore();
    }

    canvas.drawCircle(
      center,
      radius * 0.34,
      Paint()
        ..shader = ui.Gradient.radial(
          center.translate(-radius * 0.08, -radius * 0.08),
          radius * 0.34,
          const <Color>[Color(0xFF4E5660), Color(0xFF111419)],
        ),
    );
    canvas.drawCircle(
      center,
      radius * 0.11,
      Paint()..color = const Color(0xFF08090B),
    );

    for (var index = 0; index < chambers; index += 1) {
      final angle = cylinderTurn - math.pi / 2 + index * math.pi * 2 / chambers;
      final chamberCenter =
          center + Offset(math.cos(angle), math.sin(angle)) * radius * 0.58;
      final spent = index < pullIndex;
      final isCurrent = phase == _RoulettePhase.ready && index == activeChamber;
      final hasBullet = index < sequence.length && sequence[index];
      final chamberPaint = Paint()
        ..shader = ui.Gradient.radial(
          chamberCenter.translate(-radius * 0.04, -radius * 0.04),
          radius * 0.24,
          <Color>[
            spent && hasBullet
                ? colorScheme.error.withValues(alpha: 0.86)
                : spent
                ? const Color(0xFF7E8A79)
                : const Color(0xFF3A4049),
            const Color(0xFF08090B),
          ],
        );
      canvas.drawCircle(
        chamberCenter,
        radius * 0.235,
        Paint()..color = const Color(0xFF090B0E),
      );
      canvas.drawCircle(chamberCenter, radius * 0.205, chamberPaint);
      canvas.drawCircle(
        chamberCenter.translate(-radius * 0.035, -radius * 0.04),
        radius * 0.055,
        Paint()..color = Colors.white.withValues(alpha: spent ? 0.04 : 0.09),
      );
      if (phase == _RoulettePhase.setup && index < bulletCount) {
        canvas.drawCircle(
          chamberCenter,
          radius * 0.118,
          Paint()
            ..shader = ui.Gradient.radial(
              chamberCenter.translate(-radius * 0.03, -radius * 0.03),
              radius * 0.14,
              const <Color>[Color(0xFFFFD56A), Color(0xFF9E6421)],
            ),
        );
      }
      if (isCurrent) {
        canvas.drawCircle(
          chamberCenter,
          radius * (0.275 + pulse * 0.015),
          Paint()
            ..color = const Color(0xFFFFD15C)
            ..style = PaintingStyle.stroke
            ..strokeWidth = size.width * 0.006,
        );
        canvas.drawCircle(
          chamberCenter,
          radius * 0.315,
          Paint()
            ..color = const Color(
              0xFFFFD15C,
            ).withValues(alpha: 0.10 + pulse * 0.07)
            ..style = PaintingStyle.stroke
            ..strokeWidth = size.width * 0.012,
        );
      }
    }
  }

  void _drawMuzzleFlash(Canvas canvas, Size size, Offset muzzle, double shotT) {
    final localT = (shotT / 0.62).clamp(0.0, 1.0).toDouble();
    final alpha = 1 - Curves.easeInQuad.transform(localT);
    final length = size.width * (0.11 + (1 - localT) * 0.08);
    final height = size.height * (0.11 + (1 - localT) * 0.05);
    final outer = Path()
      ..moveTo(muzzle.dx + size.width * 0.018, muzzle.dy)
      ..lineTo(muzzle.dx + length * 0.55, muzzle.dy - height * 0.58)
      ..lineTo(muzzle.dx + length * 0.42, muzzle.dy - height * 0.12)
      ..lineTo(muzzle.dx + length, muzzle.dy)
      ..lineTo(muzzle.dx + length * 0.42, muzzle.dy + height * 0.14)
      ..lineTo(muzzle.dx + length * 0.56, muzzle.dy + height * 0.62)
      ..close();
    canvas.drawPath(
      outer,
      Paint()
        ..shader = ui.Gradient.linear(
          muzzle,
          Offset(muzzle.dx + length, muzzle.dy),
          <Color>[
            const Color(0xFFFFF4B8).withValues(alpha: alpha),
            const Color(0xFFFFB02E).withValues(alpha: alpha * 0.82),
            const Color(0xFFC2554C).withValues(alpha: alpha * 0.18),
          ],
          const <double>[0, 0.45, 1],
        ),
    );
    canvas.drawPath(
      outer,
      Paint()
        ..color = const Color(0xFFFFE4A0).withValues(alpha: alpha * 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.006
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_RouletteRevolverPainter oldDelegate) {
    return oldDelegate.bulletCount != bulletCount ||
        oldDelegate.sequence != sequence ||
        oldDelegate.activeChamber != activeChamber ||
        oldDelegate.pullIndex != pullIndex ||
        oldDelegate.phase != phase ||
        oldDelegate.cylinderTurn != cylinderTurn ||
        oldDelegate.triggerProgress != triggerProgress ||
        oldDelegate.ambientProgress != ambientProgress ||
        oldDelegate.emptyClickProgress != emptyClickProgress ||
        oldDelegate.shotProgress != shotProgress ||
        oldDelegate.colorScheme != colorScheme;
  }
}
