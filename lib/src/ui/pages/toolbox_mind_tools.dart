import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../i18n/app_i18n.dart';
import '../ui_copy.dart';
import 'toolbox_breathing_tool.dart';
import 'toolbox_mind_tools_schulte.dart';
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
        zh: '按顺序点击数字或自定义内容，训练视觉搜索、注意稳定和顺序跟踪。',
        en: 'Tap numbers or custom tokens in order to train steady attention, sequence tracking, and visual search speed.',
      ),
      child: const SchulteGridTrainingCard(),
    );
  }
}

class BreathingToolPage extends StatelessWidget {
  const BreathingToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return ToolboxToolPage(
      title: pickUiText(i18n, zh: '呼吸训练', en: 'Breathing practice'),
      subtitle: pickUiText(
        i18n,
        zh: '用移动端友好的节奏指引，做专注、放松、睡前和生理叹息练习。',
        en: 'Mobile-first guided breathing for focus, relaxation, bedtime, and physiological sigh drills.',
      ),
      child: const BreathingPracticeReleaseCard(),
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

class ZenSandToolPage extends StatelessWidget {
  const ZenSandToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return ToolboxToolPage(
      title: pickUiText(i18n, zh: '禅意沙盘', en: 'Zen sand tray'),
      subtitle: pickUiText(
        i18n,
        zh: '画耙痕、落石子，把注意力带回手指和当下。',
        en: 'Draw rake lines, drop a stone, and bring attention back to your fingertips and the present.',
      ),
      child: const _ZenSandTool(),
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
      if (_currentIndex == 0) _rounds += 1;
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
            Text(
              'Bead cycle',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap the circle to advance one bead and keep a steady internal count.',
              style: Theme.of(context).textTheme.bodySmall,
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
                        Text('Round $_rounds'),
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
    canvas.drawCircle(
      center,
      radius + beadRadius * 1.8,
      Paint()..color = colorScheme.surfaceContainerLow,
    );

    for (var index = 0; index < beadCount; index += 1) {
      final angle = -math.pi / 2 + (math.pi * 2 * index / beadCount);
      final position = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      final active = index == currentIndex;
      final completed = index < currentIndex;
      final fill = Paint()
        ..color = active
            ? colorScheme.primary
            : completed
            ? colorScheme.primary.withValues(alpha: 0.3)
            : colorScheme.surface;
      canvas.drawCircle(position, beadRadius, fill);
      canvas.drawCircle(
        position,
        beadRadius,
        Paint()
          ..color = colorScheme.outlineVariant
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BeadsPainter oldDelegate) {
    return oldDelegate.currentIndex != currentIndex ||
        oldDelegate.beadCount != beadCount;
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

class _ZenSandPainter extends CustomPainter {
  const _ZenSandPainter({
    required this.strokes,
    required this.currentStroke,
    required this.stones,
  });

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
      canvas.drawOval(stoneRect, Paint()..color = const Color(0xFF6B6254));
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
