import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../i18n/app_i18n.dart';
import '../ui_copy.dart';
import 'toolbox_breathing_tool.dart';
import 'toolbox_mind_tools_schulte.dart';
import 'toolbox_prayer_beads_tool.dart';
import 'toolbox_tool_shell.dart';

class SchulteGridToolPage extends StatelessWidget {
  const SchulteGridToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return ToolboxToolPage(
      title: i18n.t('inline.ui.module.module_access.schulte_grid_0e6b45'),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_mind_tools.tap_numbers_or_custom_tokens_in_order_to_train_steady_at_2b3c19',
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
      title: i18n.t('inline.ui.module.module_access.breathing_practice_211f64'),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_mind_tools.mobile_first_breathing_practice_for_focus_relaxation_bed_b9d364',
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
      title: i18n.t('inline.ui.module.module_access.prayer_beads_2fe197'),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_mind_tools.advance_bead_by_bead_to_keep_a_steady_rhythm_and_a_quiet_92c820',
      ),
      child: const PrayerBeadsPracticeCard(),
    );
  }
}

class ZenSandToolPage extends StatelessWidget {
  const ZenSandToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return ToolboxToolPage(
      title: i18n.t('inline.plan294.zen_sand.zen_sand_tray_6452b86e'),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_mind_tools.draw_rake_lines_drop_a_stone_and_bring_attention_back_to_cc1b29',
      ),
      child: const _ZenSandTool(),
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
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
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
                  label: Text(i18n.t('inline.plan294.zen_sand.rake_a4c1efc3')),
                  selected: _mode == _ZenSandMode.draw,
                  onSelected: (_) => setState(() => _mode = _ZenSandMode.draw),
                ),
                ChoiceChip(
                  label: Text(i18n.t('inline.plan295.life.stone.7e89e734d1a3')),
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
                  label: Text(
                    i18n.t(
                      'literal.ui.pages.toolbox_mind_tools.smooth_sand_5a3f9c',
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => setState(() {
                    _strokes = <List<Offset>>[];
                    _stones = const <Offset>[];
                  }),
                  icon: const Icon(Icons.delete_sweep_rounded),
                  label: Text(i18n.t('toolbox.hub.quick.clear')),
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
