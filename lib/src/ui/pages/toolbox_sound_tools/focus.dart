part of '../toolbox_sound_tools.dart';

class _FocusBeatsTool extends StatefulWidget {
  const _FocusBeatsTool();

  @override
  State<_FocusBeatsTool> createState() => _FocusBeatsToolState();
}

class _FocusBeatsToolState extends State<_FocusBeatsTool>
    with SingleTickerProviderStateMixin {
  late final ToolboxEffectPlayer _accentPlayer;
  late final ToolboxEffectPlayer _regularPlayer;
  late final AnimationController _pulseController;

  Timer? _timer;
  int _bpm = 72;
  int _beatsPerBar = 4;
  int _activeBeat = -1;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _accentPlayer = ToolboxEffectPlayer(
      ToolboxAudioBank.metronomeClick(accent: true),
      maxPlayers: 4,
    );
    _regularPlayer = ToolboxEffectPlayer(
      ToolboxAudioBank.metronomeClick(accent: false),
      maxPlayers: 4,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_accentPlayer.warmUp());
      unawaited(_regularPlayer.warmUp());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    unawaited(_accentPlayer.dispose());
    unawaited(_regularPlayer.dispose());
    super.dispose();
  }

  Duration get _interval => Duration(milliseconds: (60000 / _bpm).round());

  void _tick() {
    final nextBeat = (_activeBeat + 1) % _beatsPerBar;
    if (nextBeat == 0) {
      unawaited(_accentPlayer.play(volume: 0.95));
    } else {
      unawaited(_regularPlayer.play(volume: 0.8));
    }
    if (!mounted) return;
    _pulseController
      ..stop()
      ..forward(from: 0);
    setState(() {
      _activeBeat = nextBeat;
    });
  }

  void _start() {
    _timer?.cancel();
    _running = true;
    _tick();
    _timer = Timer.periodic(_interval, (_) {
      _tick();
    });
    setState(() {});
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _running = false;
    _activeBeat = -1;
    setState(() {});
  }

  void _restartIfNeeded() {
    if (_running) {
      _start();
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentBeat = _activeBeat < 0 ? '--' : '${_activeBeat + 1}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                ToolboxMetricCard(label: 'BPM', value: '$_bpm'),
                ToolboxMetricCard(label: 'Bar', value: '$_beatsPerBar beats'),
                ToolboxMetricCard(label: 'Beat', value: currentBeat),
              ],
            ),
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                final pulse = 1 + (1 - _pulseController.value) * 0.08;
                return Center(
                  child: Transform.scale(
                    scale: pulse,
                    child: Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.9),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.16),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        currentBeat,
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _running ? _stop : _start,
              icon: Icon(
                _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
              ),
              label: Text(_running ? 'Stop beats' : 'Start beats'),
            ),
            const SizedBox(height: 14),
            Text('Tempo $_bpm BPM'),
            Slider(
              value: _bpm.toDouble(),
              min: 40,
              max: 160,
              divisions: 120,
              onChanged: (value) {
                _bpm = value.round();
                _restartIfNeeded();
              },
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: <int>[2, 3, 4, 6]
                  .map(
                    (count) => ChoiceChip(
                      label: Text('$count / bar'),
                      selected: _beatsPerBar == count,
                      onSelected: (_) {
                        _beatsPerBar = count;
                        _activeBeat = -1;
                        _restartIfNeeded();
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _WoodfishTool extends StatefulWidget {
  const _WoodfishTool();

  @override
  State<_WoodfishTool> createState() => _WoodfishToolState();
}

class _WoodfishToolState extends State<_WoodfishTool> {
  late final ToolboxEffectPlayer _player;
  int _count = 0;
  int _flashCounter = 0;

  @override
  void initState() {
    super.initState();
    _player = ToolboxEffectPlayer(
      ToolboxAudioBank.woodfishClick(),
      maxPlayers: 6,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_player.warmUp());
    });
  }

  @override
  void dispose() {
    unawaited(_player.dispose());
    super.dispose();
  }

  void _hit() {
    HapticFeedback.mediumImpact();
    unawaited(_player.play(volume: 1.0));
    if (!mounted) return;
    setState(() {
      _count += 1;
      _flashCounter += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                ToolboxMetricCard(label: 'Today', value: '$_count taps'),
                const ToolboxMetricCard(label: 'Mode', value: 'Single strike'),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _hit,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  AspectRatio(
                    aspectRatio: 1.35,
                    child: CustomPaint(
                      painter: _WoodfishPainter(
                        colorScheme: Theme.of(context).colorScheme,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        '$_count',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: Text(
                          '+1',
                          key: ValueKey<int>(_flashCounter),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: _hit,
                  icon: const Icon(Icons.pan_tool_alt_rounded),
                  label: const Text('Strike once'),
                ),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _count = 0),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reset count'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WoodfishPainter extends CustomPainter {
  const _WoodfishPainter({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final bodyRect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: size.width * 0.72,
      height: size.height * 0.44,
    );
    final body = RRect.fromRectAndRadius(bodyRect, const Radius.circular(999));
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[
          Color(0xFFC78743),
          Color(0xFF9C5B21),
          Color(0xFF6E3D18),
        ],
      ).createShader(bodyRect);
    canvas.drawRRect(body, paint);
    canvas.drawRRect(
      body,
      Paint()
        ..color = colorScheme.outline.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    final groovePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawArc(
      Rect.fromCenter(
        center: bodyRect.center,
        width: bodyRect.width * 0.42,
        height: bodyRect.height * 0.35,
      ),
      0.2,
      math.pi - 0.4,
      false,
      groovePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _WoodfishPainter oldDelegate) => false;
}
