import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../i18n/app_i18n.dart';
import '../ui_copy.dart';
import '../widgets/section_header.dart';
import 'toolbox_tool_shell.dart';

class SchulteGridToolPage extends StatelessWidget {
  const SchulteGridToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return ToolboxToolPage(
      title: pickUiText(i18n, zh: '舒尔特方格', en: 'Schulte grid'),
      subtitle: pickUiText(
        i18n,
        zh: '按顺序寻找数字，训练注意稳定度与视觉检索速度。',
        en: 'Find numbers in order to train steady attention and visual search speed.',
      ),
      child: const _SchulteGridTool(),
    );
  }
}

class PrayerBeadsToolPage extends StatelessWidget {
  const PrayerBeadsToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return ToolboxToolPage(
      title: pickUiText(i18n, zh: '静心念珠', en: 'Prayer beads'),
      subtitle: pickUiText(
        i18n,
        zh: '一颗一颗拨动，保持节律，给自己一个安静的计数动作。',
        en: 'Advance bead by bead to keep a steady rhythm and a quiet counting gesture.',
      ),
      child: const _PrayerBeadsTool(),
    );
  }
}

class BreathingToolPage extends StatelessWidget {
  const BreathingToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return ToolboxToolPage(
      title: pickUiText(i18n, zh: '呼吸练习', en: 'Breathing practice'),
      subtitle: pickUiText(
        i18n,
        zh: '用简单节奏带你进入吸气、停留、呼气的循环。',
        en: 'A guided loop for inhale, hold, and exhale with simple pacing patterns.',
      ),
      child: const _BreathingTool(),
    );
  }
}

class ZenSandToolPage extends StatelessWidget {
  const ZenSandToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return ToolboxToolPage(
      title: pickUiText(i18n, zh: '禅意沙盘', en: 'Zen sand tray'),
      subtitle: pickUiText(
        i18n,
        zh: '拖动耙纹、落下一枚石子，把注意力放回手指和当下。',
        en: 'Draw rake lines, drop a stone, and bring attention back to your fingertips and the present.',
      ),
      child: const _ZenSandTool(),
    );
  }
}

class _SchulteGridTool extends StatefulWidget {
  const _SchulteGridTool();

  @override
  State<_SchulteGridTool> createState() => _SchulteGridToolState();
}

class _SchulteGridToolState extends State<_SchulteGridTool> {
  final math.Random _random = math.Random();
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;

  int _size = 5;
  late List<int> _values;
  int _nextTarget = 1;
  Duration _elapsed = Duration.zero;
  Duration? _best;

  @override
  void initState() {
    super.initState();
    _reshuffle();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _reshuffle() {
    _ticker?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    _elapsed = Duration.zero;
    _nextTarget = 1;
    _values = List<int>.generate(_size * _size, (index) => index + 1)
      ..shuffle(_random);
    setState(() {});
  }

  void _setSize(int size) {
    if (_size == size) return;
    _size = size;
    _reshuffle();
  }

  void _onTap(int value) {
    if (value != _nextTarget) return;
    if (!_stopwatch.isRunning) {
      _stopwatch.start();
      _ticker = Timer.periodic(const Duration(milliseconds: 80), (_) {
        if (!mounted) return;
        setState(() {
          _elapsed = _stopwatch.elapsed;
        });
      });
    }

    if (_nextTarget == _size * _size) {
      _stopwatch.stop();
      _ticker?.cancel();
      final finalElapsed = _stopwatch.elapsed;
      setState(() {
        _elapsed = finalElapsed;
        _best = _best == null || finalElapsed < _best! ? finalElapsed : _best;
        _nextTarget += 1;
      });
      return;
    }

    setState(() {
      _nextTarget += 1;
    });
  }

  String _formatDuration(Duration value) {
    final minutes = value.inMinutes.toString().padLeft(2, '0');
    final seconds = (value.inSeconds % 60).toString().padLeft(2, '0');
    final centiseconds = ((value.inMilliseconds % 1000) / 10)
        .floor()
        .toString()
        .padLeft(2, '0');
    return '$minutes:$seconds.$centiseconds';
  }

  @override
  Widget build(BuildContext context) {
    final done = _nextTarget > _size * _size;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SectionHeader(
              title: 'Grid size',
              subtitle:
                  'Use a larger grid when you want a denser scan challenge.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: <int>[4, 5, 6]
                  .map(
                    (size) => ChoiceChip(
                      label: Text('$size × $size'),
                      selected: _size == size,
                      onSelected: (_) => _setSize(size),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                ToolboxMetricCard(
                  label: 'Target',
                  value: done ? 'Done' : '$_nextTarget',
                ),
                ToolboxMetricCard(
                  label: 'Time',
                  value: _formatDuration(_elapsed),
                ),
                ToolboxMetricCard(
                  label: 'Best',
                  value: _best == null ? '--' : _formatDuration(_best!),
                ),
              ],
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _values.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _size,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final value = _values[index];
                final completed = value < _nextTarget;
                final target = value == _nextTarget && !done;
                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _onTap(value),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: completed
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.12)
                          : target
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: target
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        completed ? 'OK' : '$value',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _reshuffle,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Shuffle again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerBeadsTool extends StatefulWidget {
  const _PrayerBeadsTool();

  @override
  State<_PrayerBeadsTool> createState() => _PrayerBeadsToolState();
}

class _PrayerBeadsToolState extends State<_PrayerBeadsTool> {
  int _beadCount = 27;
  int _currentIndex = 0;
  int _total = 0;
  int _rounds = 0;

  void _advance() {
    HapticFeedback.selectionClick();
    setState(() {
      _total += 1;
      _currentIndex = (_currentIndex + 1) % _beadCount;
      if (_currentIndex == 0) {
        _rounds += 1;
      }
    });
  }

  void _reset() {
    setState(() {
      _currentIndex = 0;
      _total = 0;
      _rounds = 0;
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
            const SectionHeader(
              title: 'Bead cycle',
              subtitle:
                  'Tap the circle to advance one bead and keep a steady internal count.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: <int>[18, 27, 54]
                  .map(
                    (count) => ChoiceChip(
                      label: Text('$count beads'),
                      selected: _beadCount == count,
                      onSelected: (_) {
                        setState(() {
                          _beadCount = count;
                          _currentIndex = 0;
                          _total = 0;
                          _rounds = 0;
                        });
                      },
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _advance,
              child: AspectRatio(
                aspectRatio: 1,
                child: CustomPaint(
                  painter: _BeadsPainter(
                    beadCount: _beadCount,
                    currentIndex: _currentIndex,
                    colorScheme: Theme.of(context).colorScheme,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          '$_total',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Round $_rounds',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: _advance,
                  icon: const Icon(Icons.touch_app_rounded),
                  label: const Text('Advance one bead'),
                ),
                OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BreathingPreset {
  const _BreathingPreset({required this.name, required this.stages});

  final String name;
  final List<_BreathingStage> stages;
}

class _BreathingStage {
  const _BreathingStage(this.label, this.durationSeconds, this.kind);

  final String label;
  final int durationSeconds;
  final _BreathingStageKind kind;
}

enum _BreathingStageKind { inhale, holdHigh, exhale, holdLow }

class _BreathingTool extends StatefulWidget {
  const _BreathingTool();

  @override
  State<_BreathingTool> createState() => _BreathingToolState();
}

class _BreathingToolState extends State<_BreathingTool>
    with SingleTickerProviderStateMixin {
  static const List<_BreathingPreset> _presets = <_BreathingPreset>[
    _BreathingPreset(
      name: 'Box 4-4-4-4',
      stages: <_BreathingStage>[
        _BreathingStage('Inhale', 4, _BreathingStageKind.inhale),
        _BreathingStage('Hold', 4, _BreathingStageKind.holdHigh),
        _BreathingStage('Exhale', 4, _BreathingStageKind.exhale),
        _BreathingStage('Hold', 4, _BreathingStageKind.holdLow),
      ],
    ),
    _BreathingPreset(
      name: '4-7-8',
      stages: <_BreathingStage>[
        _BreathingStage('Inhale', 4, _BreathingStageKind.inhale),
        _BreathingStage('Hold', 7, _BreathingStageKind.holdHigh),
        _BreathingStage('Exhale', 8, _BreathingStageKind.exhale),
      ],
    ),
    _BreathingPreset(
      name: 'Unwind 4-2-6',
      stages: <_BreathingStage>[
        _BreathingStage('Inhale', 4, _BreathingStageKind.inhale),
        _BreathingStage('Pause', 2, _BreathingStageKind.holdHigh),
        _BreathingStage('Exhale', 6, _BreathingStageKind.exhale),
        _BreathingStage('Rest', 2, _BreathingStageKind.holdLow),
      ],
    ),
  ];

  late final AnimationController _controller;

  _BreathingPreset _preset = _presets.first;
  bool _running = false;
  int _stageIndex = 0;
  int _rounds = 0;

  _BreathingStage get _stage => _preset.stages[_stageIndex];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && _running) {
          _advanceStage();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _beginStage() {
    _controller.duration = Duration(seconds: _stage.durationSeconds);
    _controller.forward(from: 0);
  }

  void _advanceStage() {
    final nextIndex = (_stageIndex + 1) % _preset.stages.length;
    setState(() {
      _stageIndex = nextIndex;
      if (nextIndex == 0) {
        _rounds += 1;
      }
    });
    _beginStage();
  }

  void _toggle() {
    if (_running) {
      _controller.stop();
      setState(() {
        _running = false;
      });
      return;
    }
    setState(() {
      _running = true;
    });
    _beginStage();
  }

  void _selectPreset(_BreathingPreset preset) {
    if (identical(_preset, preset)) return;
    setState(() {
      _preset = preset;
      _stageIndex = 0;
      _rounds = 0;
      _running = false;
    });
    _controller.stop();
    _controller.value = 0;
  }

  double _orbScale() {
    final progress = _running ? _controller.value : 0.0;
    return switch (_stage.kind) {
      _BreathingStageKind.inhale => 0.72 + progress * 0.28,
      _BreathingStageKind.holdHigh => 1.0,
      _BreathingStageKind.exhale => 1.0 - progress * 0.28,
      _BreathingStageKind.holdLow => 0.72,
    };
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
              spacing: 8,
              runSpacing: 8,
              children: _presets
                  .map(
                    (preset) => ChoiceChip(
                      label: Text(preset.name),
                      selected: identical(_preset, preset),
                      onSelected: (_) => _selectPreset(preset),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 18),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final scale = _orbScale();
                return Center(
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: <Color>[
                            Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.26),
                            Theme.of(context).colorScheme.primaryContainer
                                .withValues(alpha: 0.94),
                            Theme.of(context).colorScheme.surfaceContainerHigh,
                          ],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            _stage.label,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_stage.durationSeconds}s · round $_rounds',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            LinearProgressIndicator(value: _running ? _controller.value : 0),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _toggle,
              icon: Icon(
                _running
                    ? Icons.pause_circle_rounded
                    : Icons.play_circle_rounded,
              ),
              label: Text(_running ? 'Pause cycle' : 'Start cycle'),
            ),
          ],
        ),
      ),
    );
  }
}

enum _ZenSandMode { draw, stone }

class _ZenSandTool extends StatefulWidget {
  const _ZenSandTool();

  @override
  State<_ZenSandTool> createState() => _ZenSandToolState();
}

class _ZenSandToolState extends State<_ZenSandTool> {
  _ZenSandMode _mode = _ZenSandMode.draw;
  List<List<Offset>> _strokes = <List<Offset>>[];
  List<Offset> _currentStroke = <Offset>[];
  List<Offset> _stones = const <Offset>[Offset(0.28, 0.42), Offset(0.68, 0.56)];

  Offset _normalize(Offset local, Size size) {
    return Offset(
      (local.dx / size.width).clamp(0.0, 1.0),
      (local.dy / size.height).clamp(0.0, 1.0),
    );
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
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                ChoiceChip(
                  label: const Text('Rake'),
                  selected: _mode == _ZenSandMode.draw,
                  onSelected: (_) => setState(() => _mode = _ZenSandMode.draw),
                ),
                ChoiceChip(
                  label: const Text('Stone'),
                  selected: _mode == _ZenSandMode.stone,
                  onSelected: (_) => setState(() => _mode = _ZenSandMode.stone),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(
                  constraints.maxWidth,
                  constraints.maxWidth * 0.72,
                );
                return GestureDetector(
                  onTapDown: _mode == _ZenSandMode.stone
                      ? (details) {
                          setState(() {
                            _stones = <Offset>[
                              ..._stones,
                              _normalize(details.localPosition, size),
                            ];
                          });
                        }
                      : null,
                  onPanStart: _mode == _ZenSandMode.draw
                      ? (details) {
                          setState(() {
                            _currentStroke = <Offset>[
                              _normalize(details.localPosition, size),
                            ];
                          });
                        }
                      : null,
                  onPanUpdate: _mode == _ZenSandMode.draw
                      ? (details) {
                          setState(() {
                            _currentStroke = <Offset>[
                              ..._currentStroke,
                              _normalize(details.localPosition, size),
                            ];
                          });
                        }
                      : null,
                  onPanEnd: _mode == _ZenSandMode.draw
                      ? (_) {
                          if (_currentStroke.length < 2) {
                            _currentStroke = <Offset>[];
                            return;
                          }
                          setState(() {
                            _strokes = <List<Offset>>[
                              ..._strokes,
                              _currentStroke,
                            ];
                            _currentStroke = <Offset>[];
                          });
                        }
                      : null,
                  child: SizedBox(
                    width: size.width,
                    height: size.height,
                    child: CustomPaint(
                      painter: _ZenSandPainter(
                        colorScheme: Theme.of(context).colorScheme,
                        strokes: _strokes,
                        currentStroke: _currentStroke,
                        stones: _stones,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: () => setState(() => _strokes = <List<Offset>>[]),
                  icon: const Icon(Icons.layers_clear_rounded),
                  label: const Text('Smooth sand'),
                ),
                OutlinedButton.icon(
                  onPressed: () => setState(() {
                    _strokes = <List<Offset>>[];
                    _stones = const <Offset>[];
                  }),
                  icon: const Icon(Icons.delete_sweep_rounded),
                  label: const Text('Clear all'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BeadsPainter extends CustomPainter {
  const _BeadsPainter({
    required this.beadCount,
    required this.currentIndex,
    required this.colorScheme,
  });

  final int beadCount;
  final int currentIndex;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.36;
    final beadRadius = math.max(6.0, size.shortestSide * 0.028);

    final ringPaint = Paint()
      ..color = colorScheme.surfaceContainerLow
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius + beadRadius * 1.8, ringPaint);

    for (var index = 0; index < beadCount; index += 1) {
      final angle = -math.pi / 2 + (math.pi * 2 * index / beadCount);
      final position = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      final active = index == currentIndex;
      final completed = index < currentIndex;
      final paint = Paint()
        ..color = active
            ? colorScheme.primary
            : completed
            ? colorScheme.primary.withValues(alpha: 0.3)
            : colorScheme.surface;
      canvas.drawCircle(position, beadRadius, paint);
      canvas.drawCircle(
        position,
        beadRadius,
        Paint()
          ..color = colorScheme.outlineVariant
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BeadsPainter oldDelegate) {
    return oldDelegate.currentIndex != currentIndex ||
        oldDelegate.beadCount != beadCount;
  }
}

class _ZenSandPainter extends CustomPainter {
  const _ZenSandPainter({
    required this.colorScheme,
    required this.strokes,
    required this.currentStroke,
    required this.stones,
  });

  final ColorScheme colorScheme;
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final List<Offset> stones;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[Color(0xFFF7E8C8), Color(0xFFF2DDAF)],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(24)),
      background,
    );

    final rakePaint = Paint()
      ..color = const Color(0xFFCCB37F).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    for (double y = 16; y < size.height; y += 18) {
      final path = Path()..moveTo(10, y);
      for (double x = 10; x < size.width - 10; x += 18) {
        path.quadraticBezierTo(
          x + 9,
          y + math.sin((x + y) / 32) * 2.4,
          x + 18,
          y,
        );
      }
      canvas.drawPath(path, rakePaint);
    }

    final strokePaint = Paint()
      ..color = const Color(0xFFA68853)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3;
    for (final stroke in <List<Offset>>[...strokes, currentStroke]) {
      if (stroke.length < 2) continue;
      final path = Path()
        ..moveTo(stroke.first.dx * size.width, stroke.first.dy * size.height);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx * size.width, point.dy * size.height);
      }
      canvas.drawPath(path, strokePaint);
    }

    for (final stone in stones) {
      final center = Offset(stone.dx * size.width, stone.dy * size.height);
      final stoneRect = Rect.fromCenter(center: center, width: 28, height: 22);
      canvas.drawOval(
        stoneRect,
        Paint()
          ..color = const Color(0xFF6B6254)
          ..style = PaintingStyle.fill,
      );
      canvas.drawOval(
        stoneRect.shift(const Offset(2, 2)),
        Paint()..color = Colors.white.withValues(alpha: 0.08),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ZenSandPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.currentStroke != currentStroke ||
        oldDelegate.stones != stones;
  }
}
