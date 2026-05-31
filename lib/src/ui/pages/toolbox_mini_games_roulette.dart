part of 'toolbox_mini_games.dart';

class _ChoiceSpinnerGame extends StatefulWidget {
  const _ChoiceSpinnerGame();

  @override
  State<_ChoiceSpinnerGame> createState() => _ChoiceSpinnerGameState();
}

class _ChoiceSpinnerGameState extends State<_ChoiceSpinnerGame> {
  final math.Random _random = math.Random();
  int _choiceCount = 6;
  int? _result;
  bool _spinning = false;
  bool _hapticsEnabled = true;
  double _turns = 0;

  Future<void> _spin() async {
    if (_spinning) {
      return;
    }
    setState(() {
      _spinning = true;
      _result = null;
      _turns += 2.75 + _random.nextDouble() * 1.4;
    });
    if (_hapticsEnabled) {
      unawaited(HapticFeedback.selectionClick());
    }
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted) {
      return;
    }
    setState(() {
      _result = _random.nextInt(_choiceCount) + 1;
      _spinning = false;
    });
    if (_hapticsEnabled) {
      unawaited(HapticFeedback.lightImpact());
    }
  }

  void _reset() {
    setState(() {
      _result = null;
      _spinning = false;
    });
  }

  String _statusLabel(AppI18n i18n) {
    if (_spinning) {
      return i18n.t('toolbox.miniGames.roulette.preparing.fb8a1fd7');
    }
    if (_result != null) {
      return i18n.t('toolbox.miniGames.roulette.round_over.3a866748');
    }
    return i18n.t('toolbox.miniGames.roulette.idle.c59d4163');
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final colors = Theme.of(context).colorScheme;
    final compact = _miniGameCompactLayout(context);
    final resultText = _result == null ? '-' : '${_result!}';
    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 14 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                ToolboxMetricCard(
                  label: i18n.t('toolbox.miniGames.roulette.metric.current'),
                  value: resultText,
                ),
                ToolboxMetricCard(
                  label: i18n.t('toolbox.miniGames.roulette.roundsLoaded'),
                  value: '$_choiceCount',
                ),
                ToolboxMetricCard(
                  label: i18n.t('toolbox.miniGames.gomoku.status.7c405acf'),
                  value: _statusLabel(i18n),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: _turns),
                duration: const Duration(milliseconds: 520),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.rotate(
                    angle: value * math.pi * 2,
                    child: child,
                  );
                },
                child: Container(
                  width: compact ? 172 : 220,
                  height: compact ? 172 : 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        colors.primaryContainer,
                        colors.secondaryContainer,
                        colors.surfaceContainerHighest,
                      ],
                    ),
                    border: Border.all(color: colors.outlineVariant),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.16),
                        blurRadius: 22,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      for (var index = 0; index < 12; index += 1)
                        Transform.rotate(
                          angle: index * math.pi / 6,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              width: 4,
                              height: compact ? 22 : 28,
                              margin: const EdgeInsets.only(top: 12),
                              decoration: BoxDecoration(
                                color: colors.onPrimaryContainer.withValues(
                                  alpha: 0.22,
                                ),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                        ),
                      Container(
                        width: compact ? 104 : 128,
                        height: compact ? 104 : 128,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.surface.withValues(alpha: 0.88),
                          border: Border.all(color: colors.outlineVariant),
                        ),
                        alignment: Alignment.center,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: Text(
                            resultText,
                            key: ValueKey<String>(resultText),
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    i18n.t('toolbox.miniGames.roulette.settings'),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _choiceCount.toDouble(),
                    min: 2,
                    max: 12,
                    divisions: 10,
                    label: '$_choiceCount',
                    onChanged: _spinning
                        ? null
                        : (value) {
                            setState(() {
                              _choiceCount = value.round();
                              if (_result != null && _result! > _choiceCount) {
                                _result = null;
                              }
                            });
                          },
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      FilledButton.icon(
                        onPressed: _spinning ? null : _spin,
                        icon: const Icon(Icons.shuffle_rounded),
                        label: Text(
                          i18n.t('toolbox.miniGames.roulette.spinCylinder'),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _spinning ? null : _reset,
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(i18n.t('toolbox.miniGames.roulette.reset')),
                      ),
                      FilterChip(
                        label: Text(
                          i18n.t('toolbox.miniGames.roulette.haptics'),
                        ),
                        selected: _hapticsEnabled,
                        onSelected: (value) {
                          setState(() {
                            _hapticsEnabled = value;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
      _RoulettePhase.idle => i18n.t('toolbox.miniGames.roulette.idle.c59d4163'),
      _RoulettePhase.spinning => i18n.t(
        'toolbox.miniGames.roulette.preparing.fb8a1fd7',
      ),
      _RoulettePhase.armed => i18n.t(
        'toolbox.miniGames.roulette.armed.8dc78d94',
      ),
      _RoulettePhase.firing => i18n.t(
        'toolbox.miniGames.roulette.pin_strike.60dad60f',
      ),
      _RoulettePhase.safeClick => i18n.t(
        'toolbox.miniGames.roulette.empty_click.f6df0499',
      ),
      _RoulettePhase.hit => i18n.t(
        'toolbox.miniGames.roulette.direct_hit.2543ad50',
      ),
      _RoulettePhase.exhausted => i18n.t(
        'toolbox.miniGames.roulette.round_over.3a866748',
      ),
    };
  }

  String _stageCopy(AppI18n i18n) {
    return switch (_phase) {
      _RoulettePhase.idle => i18n.t(
        'toolbox.miniGames.roulette.set_load_and_spin_you_hear_a.1aed8ffb',
      ),
      _RoulettePhase.spinning => i18n.t(
        'toolbox.miniGames.roulette.cylinder_spinning_ratchet_settles_then_trigger_is.6ed51b53',
      ),
      _RoulettePhase.armed =>
        _safePullCount > 0
            ? i18n.t(
                'toolbox.miniGames.roulette.after_the_empty_clack_chamber_advanced_pull.8db121cc',
              )
            : i18n.t(
                'toolbox.miniGames.roulette.armed_firing_pin_snaps_before_the_outcome.8f8bdfce',
              ),
      _RoulettePhase.firing => i18n.t(
        'toolbox.miniGames.roulette.firing_pin_lunges_as_trigger_and_hammer.121a3d12',
      ),
      _RoulettePhase.safeClick => i18n.t(
        'toolbox.miniGames.roulette.empty_click_done_cylinder_steps_into_the.efdcb16a',
      ),
      _RoulettePhase.hit => i18n.t(
        'toolbox.miniGames.roulette.hit_triggers_blast_sound_full_screen_flash.c8804571',
      ),
      _RoulettePhase.exhausted => i18n.t(
        'toolbox.miniGames.roulette.all_chambers_consumed_spin_again_for_a.fbfae8b3',
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
