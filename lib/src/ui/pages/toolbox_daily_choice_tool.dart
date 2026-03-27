import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../i18n/app_i18n.dart';
import '../ui_copy.dart';
import 'toolbox_tool_shell.dart';

class DailyDecisionToolPage extends StatelessWidget {
  const DailyDecisionToolPage({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return ToolboxToolPage(
      title: pickUiText(i18n, zh: '每日抉择', en: 'Daily decision'),
      subtitle: pickUiText(
        i18n,
        zh: '把犹豫的选项放进转盘，用一个结果帮你继续往前走。',
        en: 'Drop your indecision into a wheel and let one result push you forward.',
      ),
      child: const _DailyDecisionTool(),
    );
  }
}

class _DailyDecisionTool extends StatefulWidget {
  const _DailyDecisionTool();

  @override
  State<_DailyDecisionTool> createState() => _DailyDecisionToolState();
}

class _DailyDecisionToolState extends State<_DailyDecisionTool>
    with SingleTickerProviderStateMixin {
  final List<String> _options = <String>[
    'Keep going',
    'Take a break',
    'Go outside',
    'Review',
  ];
  final TextEditingController _controller = TextEditingController();
  final math.Random _random = math.Random();

  late final AnimationController _spinController;
  Animation<double>? _spinAnimation;
  double _rotation = 0;
  String? _result;

  double get _currentRotation => _spinAnimation?.value ?? _rotation;

  @override
  void initState() {
    super.initState();
    _spinController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 4200),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && _spinAnimation != null) {
            setState(() {
              _rotation = _spinAnimation!.value % (math.pi * 2);
            });
          }
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    _spinController.dispose();
    super.dispose();
  }

  void _addOption() {
    final value = _controller.text.trim();
    if (value.isEmpty || _options.length >= 8) return;
    setState(() {
      _options.add(value);
      _controller.clear();
    });
  }

  void _spin() {
    if (_options.length < 2 || _spinController.isAnimating) return;
    final winner = _random.nextInt(_options.length);
    final segmentAngle = (math.pi * 2) / _options.length;
    final centerAngle = -math.pi / 2 + segmentAngle * (winner + 0.5);
    final desiredRotation = -centerAngle;
    final normalizedCurrent = _rotation % (math.pi * 2);

    var delta = desiredRotation - normalizedCurrent;
    while (delta < 0) {
      delta += math.pi * 2;
    }

    final endRotation =
        _rotation + delta + (6 + _random.nextInt(3)) * math.pi * 2;
    _spinAnimation = Tween<double>(begin: _rotation, end: endRotation).animate(
      CurvedAnimation(parent: _spinController, curve: Curves.easeOutCubic),
    );
    setState(() {
      _result = _options[winner];
    });
    _spinController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AnimatedBuilder(
              animation: _spinController,
              builder: (context, _) {
                return AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      Transform.rotate(
                        angle: _currentRotation,
                        child: CustomPaint(
                          size: const Size.square(280),
                          painter: _DecisionWheelPainter(
                            labels: _options,
                            colorScheme: Theme.of(context).colorScheme,
                          ),
                        ),
                      ),
                      const Positioned(
                        top: 10,
                        child: Icon(Icons.arrow_drop_down_rounded, size: 38),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _options.length < 2 ? null : _spin,
              icon: const Icon(Icons.casino_rounded),
              label: const Text('Spin the wheel'),
            ),
            const SizedBox(height: 12),
            if ((_result ?? '').isNotEmpty)
              ToolboxMetricCard(label: 'Result', value: _result!),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Add option',
                hintText: 'Type an option and press the button',
              ),
              onSubmitted: (_) => _addOption(),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                FilledButton.tonalIcon(
                  onPressed: _addOption,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add option'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    if (_options.length <= 2) return;
                    setState(() {
                      _options.removeLast();
                    });
                  },
                  icon: const Icon(Icons.remove_rounded),
                  label: const Text('Remove last'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _options
                  .map(
                    (item) => InputChip(
                      label: Text(item),
                      onDeleted: _options.length <= 2
                          ? null
                          : () => setState(() => _options.remove(item)),
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

class _DecisionWheelPainter extends CustomPainter {
  const _DecisionWheelPainter({
    required this.labels,
    required this.colorScheme,
  });

  final List<String> labels;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final segmentAngle = (math.pi * 2) / labels.length;
    final colors = <Color>[
      colorScheme.primaryContainer,
      colorScheme.secondaryContainer,
      colorScheme.surfaceContainerHighest,
      colorScheme.tertiaryContainer,
      colorScheme.surfaceContainerHigh,
      colorScheme.primary.withValues(alpha: 0.2),
    ];

    for (var index = 0; index < labels.length; index += 1) {
      final startAngle = -math.pi / 2 + segmentAngle * index;
      canvas.drawArc(
        rect,
        startAngle,
        segmentAngle,
        true,
        Paint()..color = colors[index % colors.length],
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[index],
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: radius * 0.5);

      final angle = startAngle + segmentAngle / 2;
      final labelCenter = Offset(
        center.dx + math.cos(angle) * radius * 0.6,
        center.dy + math.sin(angle) * radius * 0.6,
      );

      canvas.save();
      canvas.translate(labelCenter.dx, labelCenter.dy);
      canvas.rotate(angle + math.pi / 2);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      canvas.restore();
    }

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = colorScheme.outlineVariant
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(center, 18, Paint()..color = colorScheme.surface);
  }

  @override
  bool shouldRepaint(covariant _DecisionWheelPainter oldDelegate) {
    return oldDelegate.labels != labels;
  }
}
