part of 'toolbox_mini_games.dart';

enum _RoulettePhase { idle, spinning, armed, firing, safeClick, hit, exhausted }

class _RouletteGame extends StatefulWidget {
  const _RouletteGame();

  @override
  State<_RouletteGame> createState() => _RouletteGameState();
}

class _RouletteGameState extends State<_RouletteGame>
    with TickerProviderStateMixin {
  static const int _chambers = 6;
  static const String _spinAsset =
      'assets/toolbox/games/roulette/cylinder_spin.wav';
  static const String _clickAsset =
      'assets/toolbox/games/roulette/revolver_click.wav';
  static const String _shotAsset =
      'assets/toolbox/games/roulette/revolver_shot.wav';
  static const String _explosionAsset =
      'assets/toolbox/games/roulette/explosion_blast.wav';

  final math.Random _random = math.Random();

  late final AnimationController _ambientController;
  late final AnimationController _spinController;
  late final AnimationController _chamberStepController;
  late final AnimationController _fireController;
  late final AnimationController _safeKickController;
  late final AnimationController _recoilController;
  late final AnimationController _hitFlashController;
  late final AnimationController _shakeController;

  final List<Timer> _timers = <Timer>[];
  OverlayEntry? _flashEntry;

  ToolboxEffectPlayer? _spinPlayer;
  ToolboxEffectPlayer? _clickPlayer;
  ToolboxEffectPlayer? _shotPlayer;
  ToolboxEffectPlayer? _explosionPlayer;
  bool _audioReady = false;
  bool _audioFailed = false;

  int _bulletCount = 1;
  late List<bool> _sequence;
  int _activeChamber = 0;
  int _pullCount = 0;
  int _safePullCount = 0;
  _RoulettePhase _phase = _RoulettePhase.idle;
  double _cylinderBaseAngle = 0;
  double _spinTurns = 7.0;

  bool _soundEnabled = true;
  bool _hapticsEnabled = true;
  bool _settingsExpanded = false;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8200),
    )..repeat();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1280),
    );
    _chamberStepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fireController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _safeKickController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _recoilController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    );
    _hitFlashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );
    _sequence = _buildSequence();
    _cylinderBaseAngle = _random.nextDouble() * math.pi * 2;
    unawaited(_prepareAudio());
  }

  @override
  void dispose() {
    _cancelTimers();
    _removeFlashOverlay();
    _ambientController.dispose();
    _spinController.dispose();
    _chamberStepController.dispose();
    _fireController.dispose();
    _safeKickController.dispose();
    _recoilController.dispose();
    _hitFlashController.dispose();
    _shakeController.dispose();
    final spin = _spinPlayer;
    final click = _clickPlayer;
    final shot = _shotPlayer;
    final explosion = _explosionPlayer;
    if (spin != null) {
      unawaited(spin.dispose());
    }
    if (click != null) {
      unawaited(click.dispose());
    }
    if (shot != null) {
      unawaited(shot.dispose());
    }
    if (explosion != null) {
      unawaited(explosion.dispose());
    }
    super.dispose();
  }

  String _text(AppI18n i18n, {required String zh, required String en}) {
    return pickUiText(i18n, zh: zh, en: en);
  }

  List<bool> _buildSequence() {
    final next = <bool>[
      for (var index = 0; index < _chambers; index += 1) index < _bulletCount,
    ]..shuffle(_random);
    return next;
  }

  Future<ToolboxEffectPlayer> _createPlayer(
    String assetPath, {
    int maxPlayers = 4,
  }) async {
    final buffer = await rootBundle.load(assetPath);
    final player = ToolboxEffectPlayer(
      buffer.buffer.asUint8List(),
      maxPlayers: maxPlayers,
    );
    await player.warmUp();
    return player;
  }

  Future<void> _prepareAudio() async {
    ToolboxEffectPlayer? spin;
    ToolboxEffectPlayer? click;
    ToolboxEffectPlayer? shot;
    ToolboxEffectPlayer? explosion;
    try {
      spin = await _createPlayer(_spinAsset, maxPlayers: 2);
      click = await _createPlayer(_clickAsset, maxPlayers: 4);
      shot = await _createPlayer(_shotAsset, maxPlayers: 3);
      try {
        explosion = await _createPlayer(_explosionAsset, maxPlayers: 3);
      } catch (_) {
        explosion = await _createPlayer(_shotAsset, maxPlayers: 3);
      }
      if (!mounted) {
        await spin.dispose();
        await click.dispose();
        await shot.dispose();
        await explosion.dispose();
        return;
      }
      final oldSpin = _spinPlayer;
      final oldClick = _clickPlayer;
      final oldShot = _shotPlayer;
      final oldExplosion = _explosionPlayer;
      setState(() {
        _spinPlayer = spin;
        _clickPlayer = click;
        _shotPlayer = shot;
        _explosionPlayer = explosion;
        _audioReady = true;
        _audioFailed = false;
      });
      if (oldSpin != null) {
        unawaited(oldSpin.dispose());
      }
      if (oldClick != null) {
        unawaited(oldClick.dispose());
      }
      if (oldShot != null) {
        unawaited(oldShot.dispose());
      }
      if (oldExplosion != null) {
        unawaited(oldExplosion.dispose());
      }
    } catch (_) {
      if (spin != null) {
        await spin.dispose();
      }
      if (click != null) {
        await click.dispose();
      }
      if (shot != null) {
        await shot.dispose();
      }
      if (explosion != null) {
        await explosion.dispose();
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _audioReady = false;
        _audioFailed = true;
      });
    }
  }

  Future<void> _playEffect(
    ToolboxEffectPlayer? player, {
    required double volume,
    required double playbackRate,
  }) async {
    if (!_soundEnabled || player == null) {
      return;
    }
    try {
      await player.play(volume: volume, playbackRate: playbackRate);
    } catch (_) {}
  }

  double _withRateJitter(double baseRate, {double amount = 0.04}) {
    final jitter = (_random.nextDouble() * 2 - 1) * amount;
    return (baseRate + jitter).clamp(0.88, 1.14);
  }

  double _withVolumeJitter(double baseVolume, {double amount = 0.1}) {
    final jitter = (_random.nextDouble() * 2 - 1) * amount;
    return (baseVolume + jitter).clamp(0.0, 1.0);
  }

  void _playMechanicalClack({
    double baseVolume = 0.8,
    double baseRate = 1.0,
    int secondDelayMs = 34,
    double secondVolumeScale = 0.66,
    double secondRateOffset = -0.1,
  }) {
    unawaited(
      _playEffect(
        _clickPlayer,
        volume: _withVolumeJitter(baseVolume, amount: 0.07),
        playbackRate: _withRateJitter(baseRate, amount: 0.05),
      ),
    );
    _schedule(Duration(milliseconds: secondDelayMs), () {
      unawaited(
        _playEffect(
          _clickPlayer,
          volume: _withVolumeJitter(
            baseVolume * secondVolumeScale,
            amount: 0.06,
          ),
          playbackRate: _withRateJitter(
            baseRate + secondRateOffset,
            amount: 0.04,
          ),
        ),
      );
    });
  }

  void _cancelTimers() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
  }

  void _removeFlashOverlay() {
    _flashEntry?.remove();
    _flashEntry = null;
  }

  void _stopAllEffects() {
    for (final player in <ToolboxEffectPlayer?>[
      _spinPlayer,
      _clickPlayer,
      _shotPlayer,
      _explosionPlayer,
    ]) {
      if (player != null) {
        unawaited(player.stop());
      }
    }
  }

  void _schedule(Duration delay, VoidCallback callback) {
    late final Timer timer;
    timer = Timer(delay, () {
      _timers.remove(timer);
      if (!mounted) {
        return;
      }
      callback();
    });
    _timers.add(timer);
  }

  void _resetTransientControllers() {
    _spinController
      ..stop()
      ..value = 0;
    _chamberStepController
      ..stop()
      ..value = 0;
    _fireController
      ..stop()
      ..value = 0;
    _safeKickController
      ..stop()
      ..value = 0;
    _recoilController
      ..stop()
      ..value = 0;
    _hitFlashController
      ..stop()
      ..value = 0;
    _shakeController
      ..stop()
      ..value = 0;
    _removeFlashOverlay();
  }

  void _resetRound({int? bullets}) {
    _cancelTimers();
    _stopAllEffects();
    _resetTransientControllers();
    setState(() {
      if (bullets != null) {
        _bulletCount = bullets.clamp(1, _chambers - 1);
      }
      _sequence = _buildSequence();
      _activeChamber = 0;
      _pullCount = 0;
      _safePullCount = 0;
      _phase = _RoulettePhase.idle;
      _cylinderBaseAngle = _random.nextDouble() * math.pi * 2;
      _spinTurns = 7.0;
    });
  }

  Future<void> _prepareRound() async {
    if (_phase == _RoulettePhase.spinning) {
      return;
    }
    _cancelTimers();
    _stopAllEffects();
    _resetTransientControllers();
    setState(() {
      _sequence = _buildSequence();
      _activeChamber = 0;
      _pullCount = 0;
      _safePullCount = 0;
      _phase = _RoulettePhase.spinning;
      _spinTurns = 6.5 + _random.nextDouble() * 4.0;
    });
    _playMechanicalClack(
      baseVolume: 0.82,
      baseRate: 0.88,
      secondDelayMs: 38,
      secondVolumeScale: 0.62,
      secondRateOffset: -0.08,
    );
    unawaited(_playEffect(_spinPlayer, volume: 0.86, playbackRate: 0.94));
    if (_hapticsEnabled) {
      unawaited(HapticFeedback.mediumImpact());
    }

    try {
      await _spinController.forward(from: 0);
    } catch (_) {}
    if (!mounted || _phase != _RoulettePhase.spinning) {
      return;
    }
    setState(() {
      _cylinderBaseAngle =
          (_cylinderBaseAngle + _spinTurns * math.pi * 2) % (math.pi * 2);
      _phase = _RoulettePhase.armed;
    });
    _playMechanicalClack(
      baseVolume: 0.68,
      baseRate: 0.86,
      secondDelayMs: 26,
      secondVolumeScale: 0.6,
      secondRateOffset: -0.06,
    );
    if (_hapticsEnabled) {
      unawaited(HapticFeedback.selectionClick());
    }
  }

  void _triggerHitHaptics() {
    if (!_hapticsEnabled) {
      return;
    }
    unawaited(HapticFeedback.heavyImpact());
    _schedule(const Duration(milliseconds: 65), () {
      unawaited(HapticFeedback.vibrate());
    });
    _schedule(const Duration(milliseconds: 150), () {
      unawaited(HapticFeedback.heavyImpact());
    });
    _schedule(const Duration(milliseconds: 250), () {
      unawaited(HapticFeedback.mediumImpact());
    });
  }

  void _showHitFlashOverlay() {
    final overlay = Overlay.of(context, rootOverlay: true);
    _removeFlashOverlay();
    final entry = OverlayEntry(
      builder: (context) {
        return IgnorePointer(
          child: AnimatedBuilder(
            animation: Listenable.merge(<Listenable>[
              _hitFlashController,
              _shakeController,
            ]),
            builder: (context, _) {
              final t = _hitFlashController.value.clamp(0.0, 1.0);
              if (t <= 0) {
                return const SizedBox.shrink();
              }
              final pulseA = t <= 0.42
                  ? 1 - Curves.easeOutQuart.transform(t / 0.42)
                  : 0.0;
              final delayed = ((t - 0.28) / 0.72).clamp(0.0, 1.0);
              final pulseB =
                  (1 - Curves.easeOutCubic.transform(delayed)) * 0.55;
              final flashOpacity = (pulseA * 0.86 + pulseB).clamp(0.0, 1.0);
              final emberOpacity = (1 - Curves.easeInQuad.transform(t)).clamp(
                0.0,
                1.0,
              );
              final bloodOpacity = (emberOpacity * 0.22 + pulseB * 0.18).clamp(
                0.0,
                0.34,
              );
              return Transform.translate(
                offset: Offset(_screenShakeX(), _screenShakeY()),
                child: Transform.scale(
                  scale: 1.04,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      Opacity(
                        opacity: flashOpacity * 0.42,
                        child: const ColoredBox(color: Color(0xFFFFF7CF)),
                      ),
                      Opacity(
                        opacity: bloodOpacity,
                        child: const ColoredBox(color: Color(0xFF7A0508)),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(0.72, -0.06),
                            radius: 0.58 + t * 0.52,
                            colors: <Color>[
                              const Color(
                                0xFFFFC14D,
                              ).withValues(alpha: emberOpacity * 0.42),
                              const Color(
                                0xFF9B2E22,
                              ).withValues(alpha: emberOpacity * 0.32),
                              Colors.transparent,
                            ],
                            stops: const <double>[0, 0.38, 1],
                          ),
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[
                              const Color(
                                0xFF2A0204,
                              ).withValues(alpha: bloodOpacity * 0.4),
                              Colors.transparent,
                              const Color(
                                0xFF2A0204,
                              ).withValues(alpha: bloodOpacity * 0.56),
                            ],
                            stops: const <double>[0, 0.48, 1],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
    _flashEntry = entry;
    overlay.insert(entry);
    _hitFlashController
      ..stop()
      ..forward(from: 0).whenComplete(() {
        if (_flashEntry == entry) {
          entry.remove();
          _flashEntry = null;
        }
      });
  }

  Future<void> _pullTrigger() async {
    if (_phase != _RoulettePhase.armed || _pullCount >= _chambers) {
      return;
    }
    final chamberIndex = _activeChamber;
    final hasBullet = _sequence[chamberIndex];
    setState(() {
      _phase = _RoulettePhase.firing;
    });

    unawaited(_fireController.forward(from: 0));
    _playMechanicalClack(
      baseVolume: 0.9,
      baseRate: 0.96,
      secondDelayMs: 28,
      secondVolumeScale: 0.58,
      secondRateOffset: -0.08,
    );
    if (_hapticsEnabled) {
      unawaited(HapticFeedback.selectionClick());
    }

    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (!mounted || _phase != _RoulettePhase.firing) {
      return;
    }

    if (hasBullet) {
      setState(() {
        _pullCount += 1;
        _phase = _RoulettePhase.hit;
      });
      unawaited(_recoilController.forward(from: 0));
      unawaited(_shakeController.forward(from: 0));
      _showHitFlashOverlay();
      unawaited(_playEffect(_shotPlayer, volume: 0.96, playbackRate: 0.99));
      _schedule(const Duration(milliseconds: 72), () {
        unawaited(
          _playEffect(_explosionPlayer, volume: 0.90, playbackRate: 0.94),
        );
      });
      _triggerHitHaptics();
      return;
    }

    setState(() {
      _pullCount += 1;
      _safePullCount += 1;
      _phase = _RoulettePhase.safeClick;
    });
    unawaited(_safeKickController.forward(from: 0));
    _playMechanicalClack(
      baseVolume: 0.78,
      baseRate: 0.88,
      secondDelayMs: 44,
      secondVolumeScale: 0.68,
      secondRateOffset: -0.06,
    );
    if (_hapticsEnabled) {
      unawaited(HapticFeedback.lightImpact());
    }

    try {
      await _chamberStepController.forward(from: 0);
    } catch (_) {}
    if (!mounted || _phase != _RoulettePhase.safeClick) {
      return;
    }
    setState(() {
      _cylinderBaseAngle =
          (_cylinderBaseAngle + (math.pi * 2 / _chambers)) % (math.pi * 2);
      _activeChamber = (_activeChamber + 1) % _chambers;
      _phase = _pullCount >= _chambers
          ? _RoulettePhase.exhausted
          : _RoulettePhase.armed;
    });
    _chamberStepController.value = 0;
    _safeKickController.value = 0;
  }

  double _stageShakeX() {
    final t = _shakeController.value.clamp(0.0, 1.0);
    if (t <= 0 || t >= 1) {
      return 0;
    }
    final envelope = 1 - Curves.easeOutCubic.transform(t);
    return math.sin(t * math.pi * 20) * envelope * 8.0;
  }

  double _stageShakeY() {
    final t = _shakeController.value.clamp(0.0, 1.0);
    if (t <= 0 || t >= 1) {
      return 0;
    }
    final envelope = 1 - Curves.easeOutQuad.transform(t);
    return math.sin(t * math.pi * 14) * envelope * 2.6;
  }

  double _screenShakeX() {
    final t = _shakeController.value.clamp(0.0, 1.0);
    if (t <= 0 || t >= 1) {
      return 0;
    }
    final envelope = 1 - Curves.easeOutCubic.transform(t);
    final secondary = math.sin(t * math.pi * 37) * 0.36;
    return (math.sin(t * math.pi * 24) + secondary) * envelope * 10.0;
  }

  double _screenShakeY() {
    final t = _shakeController.value.clamp(0.0, 1.0);
    if (t <= 0 || t >= 1) {
      return 0;
    }
    final envelope = 1 - Curves.easeOutQuad.transform(t);
    return math.sin(t * math.pi * 18) * envelope * 4.2;
  }

  double _displayCylinderAngle() {
    var angle = _cylinderBaseAngle;
    if (_phase == _RoulettePhase.spinning) {
      final t = Curves.easeOutCubic.transform(_spinController.value);
      angle += _spinTurns * math.pi * 2 * t;
    } else if (_phase == _RoulettePhase.safeClick) {
      final t = Curves.easeOutCubic.transform(_chamberStepController.value);
      angle += (math.pi * 2 / _chambers) * t;
    }
    return angle;
  }

  String _phaseLabel(AppI18n i18n) {
    return switch (_phase) {
      _RoulettePhase.idle => _text(i18n, zh: '待机', en: 'Idle'),
      _RoulettePhase.spinning => _text(i18n, zh: '准备中', en: 'Preparing'),
      _RoulettePhase.armed => _text(i18n, zh: '可击发', en: 'Armed'),
      _RoulettePhase.firing => _text(i18n, zh: '撞针释放', en: 'Pin strike'),
      _RoulettePhase.safeClick => _text(i18n, zh: '空膛', en: 'Empty click'),
      _RoulettePhase.hit => _text(i18n, zh: '命中爆发', en: 'Direct hit'),
      _RoulettePhase.exhausted => _text(i18n, zh: '本轮结束', en: 'Round over'),
    };
  }

  String _stageCopy(AppI18n i18n) {
    return switch (_phase) {
      _RoulettePhase.idle => _text(
        i18n,
        zh: '设定装填后点击旋转弹仓，先听到准备咔哒再进入待击发状态。',
        en: 'Set load and spin. You hear a prep clack before arming.',
      ),
      _RoulettePhase.spinning => _text(
        i18n,
        zh: '弹仓高速旋转，棘轮回位；落位后即可扣动扳机。',
        en: 'Cylinder spinning. Ratchet settles, then trigger is live.',
      ),
      _RoulettePhase.armed =>
        _safePullCount > 0
            ? _text(
                i18n,
                zh: '空膛咔哒后已推进到下一膛位，继续扣动扳机。',
                en: 'After the empty clack, chamber advanced. Pull again.',
              )
            : _text(
                i18n,
                zh: '已上膛：先撞针咔嚓，再决定是否命中。',
                en: 'Armed: firing pin snaps before the outcome.',
              ),
      _RoulettePhase.firing => _text(
        i18n,
        zh: '撞针前冲，扳机与击锤联动释放。',
        en: 'Firing pin lunges as trigger and hammer release together.',
      ),
      _RoulettePhase.safeClick => _text(
        i18n,
        zh: '空膛反馈完成，弹仓步进落位。',
        en: 'Empty click done. Cylinder steps into the next chamber.',
      ),
      _RoulettePhase.hit => _text(
        i18n,
        zh: '命中触发爆炸声、全屏闪烁与震动。',
        en: 'Hit triggers blast sound, full-screen flash, and vibration.',
      ),
      _RoulettePhase.exhausted => _text(
        i18n,
        zh: '六个膛位已走完，重新旋转可开始下一轮。',
        en: 'All chambers consumed. Spin again for a new round.',
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            children: <Widget>[
              _buildStage(context, i18n),
              const SizedBox(height: 8),
              _buildControlPanel(context, i18n),
            ],
          ),
        ),
      ),
    );
    return AnimatedBuilder(
      animation: _shakeController,
      child: content,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_screenShakeX() * 0.5, _screenShakeY() * 0.5),
          child: child,
        );
      },
    );
  }
}
