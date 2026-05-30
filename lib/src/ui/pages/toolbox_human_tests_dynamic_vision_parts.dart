part of 'toolbox_human_tests.dart';

class _DynamicVisionBall {
  _DynamicVisionBall({
    required this.position,
    required this.velocity,
    required this.radius,
    required this.color,
  });

  Offset position;
  Offset velocity;
  final double radius;
  final Color color;
}

class _DynamicBallDifficulty {
  const _DynamicBallDifficulty({required this.count, required this.speed});

  final int count;
  final double speed;
}

class _DynamicIntRange {
  const _DynamicIntRange({required this.min, required this.max});

  final int min;
  final int max;
}

class _DynamicDoubleRange {
  const _DynamicDoubleRange({required this.min, required this.max});

  final double min;
  final double max;
}

class _DynamicVisionBallPainter extends CustomPainter {
  _DynamicVisionBallPainter({
    required this.balls,
    required this.accent,
    required this.surface,
    required this.outline,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final List<_DynamicVisionBall> balls;
  final Color accent;
  final Color surface;
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    final field = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(22),
    );
    canvas.drawRRect(field, Paint()..color = surface);

    final gridPaint = Paint()
      ..color = accent.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    for (var x = 48.0; x < size.width; x += 48) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 48.0; y < size.height; y += 48) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final borderPaint = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(field.deflate(0.5), borderPaint);

    for (final ball in balls) {
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawCircle(
        ball.position + const Offset(1.5, 2.5),
        ball.radius,
        shadowPaint,
      );
      final ballPaint = Paint()
        ..shader =
            RadialGradient(
              center: const Alignment(-0.35, -0.45),
              radius: 0.85,
              colors: <Color>[
                Colors.white.withValues(alpha: 0.92),
                ball.color.withValues(alpha: 0.92),
                ball.color.withValues(alpha: 0.62),
              ],
              stops: const <double>[0.0, 0.42, 1.0],
            ).createShader(
              Rect.fromCircle(center: ball.position, radius: ball.radius),
            );
      canvas.drawCircle(ball.position, ball.radius, ballPaint);
      final rimPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(ball.position, ball.radius - 0.8, rimPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DynamicVisionBallPainter oldDelegate) {
    return oldDelegate.balls != balls ||
        oldDelegate.accent != accent ||
        oldDelegate.surface != surface ||
        oldDelegate.outline != outline;
  }
}

class _DynamicSettingSlider extends StatelessWidget {
  const _DynamicSettingSlider({
    required this.label,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
  });

  final String label;
  final String valueText;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '$label · $valueText',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          label: valueText,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _DynamicCurveSelector extends StatelessWidget {
  const _DynamicCurveSelector({
    required this.label,
    required this.value,
    required this.enabled,
    required this.labelFor,
    required this.onChanged,
  });

  final String label;
  final _DynamicVisionGrowthCurve value;
  final bool enabled;
  final String Function(_DynamicVisionGrowthCurve curve) labelFor;
  final ValueChanged<_DynamicVisionGrowthCurve> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _DynamicVisionGrowthCurve.values
              .map(
                (curve) => ChoiceChip(
                  label: Text(labelFor(curve)),
                  selected: curve == value,
                  onSelected: enabled ? (_) => onChanged(curve) : null,
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _DynamicSymbolReportDialog extends StatelessWidget {
  const _DynamicSymbolReportDialog({
    required this.i18n,
    required this.records,
    required this.setLabel,
    required this.pathLabel,
  });

  final AppI18n i18n;
  final List<_DynamicSymbolRecord> records;
  final String Function(_DynamicSymbolSet set) setLabel;
  final String Function(_DynamicSymbolPath path) pathLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final correct = records.where((record) => record.correct).length;
    final accuracy = records.isEmpty ? 0.0 : correct / records.length;
    final avgDwell = records.isEmpty
        ? 0
        : (records.fold<int>(0, (sum, record) => sum + record.durationMs) /
                  records.length)
              .round();
    final fastestDwell = records.isEmpty
        ? 0
        : records.map((record) => record.durationMs).reduce(math.min);
    final missed = records.where((record) => !record.correct).toList();
    final recommendation = accuracy >= 0.85
        ? i18n.t(
            'inline.ui.pages.toolbox_human_tests_dynamic_vision_parts.recognition_is_stable_raise_speed_increase_group_length_c0cf2b',
          )
        : accuracy >= 0.65
        ? i18n.t(
            'inline.ui.pages.toolbox_human_tests_dynamic_vision_parts.keep_the_current_set_and_stabilize_accuracy_above_85_bef_32747d',
          )
        : i18n.t(
            'inline.ui.pages.toolbox_human_tests_dynamic_vision_parts.lower_speed_or_use_a_single_digits_letters_set_to_reduce_8639f7',
          );
    return AlertDialog(
      title: Text(
        i18n.t(
          'inline.ui.pages.toolbox_human_tests_dynamic_vision_parts.symbol_recognition_report_90675c',
        ),
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  _ColorVisionReportMetric(
                    label: i18n.t(
                      'inline.ui.pages.practice_review_page.accuracy_8cf5a1',
                    ),
                    value: '${(accuracy * 100).round()}%',
                  ),
                  _ColorVisionReportMetric(
                    label: i18n.t(
                      'inline.ui.pages.toolbox_human_tests_dynamic_vision_parts.correct_rounds_ab0678',
                    ),
                    value: '$correct/${records.length}',
                  ),
                  _ColorVisionReportMetric(
                    label: i18n.t(
                      'inline.ui.pages.toolbox_human_tests_dynamic_vision_parts.avg_dwell_801074',
                    ),
                    value: _formatMilliseconds(avgDwell),
                  ),
                  _ColorVisionReportMetric(
                    label: i18n.t(
                      'inline.ui.pages.toolbox_human_tests_dynamic_vision_parts.fastest_dwell_092569',
                    ),
                    value: _formatMilliseconds(fastestDwell),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ColorVisionReportSection(
                title: i18n.t('toolbox.breathing.session_setup'),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    Chip(label: Text(setLabel(records.last.set))),
                    Chip(label: Text(pathLabel(records.last.path))),
                    Chip(
                      label: Text(
                        i18n.t(
                          'inline.ui.pages.toolbox_human_tests_dynamic_vision_parts.speed_records_last_speed_tostringasfixed_1_x_a67a1a',
                          params: <String, Object?>{
                            'recordsLastSpeed': records.last.speed
                                .toStringAsFixed(1),
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _ColorVisionReportSection(
                title: i18n.t(
                  'inline.ui.pages.toolbox_human_tests_action.training_note_0dc151',
                ),
                child: Text(
                  recommendation,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                ),
              ),
              if (missed.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _ColorVisionReportSection(
                  title: i18n.t(
                    'inline.ui.pages.toolbox_human_tests_dynamic_vision_parts.missed_symbols_5a863b',
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: missed
                        .take(8)
                        .map((record) {
                          return Chip(
                            label: Text('${record.target} -> ${record.choice}'),
                          );
                        })
                        .toList(growable: false),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(i18n.t('inline.plan295.life.close.370fb8697deb')),
        ),
      ],
    );
  }
}

class _DynamicEnumChoice<T> extends StatelessWidget {
  const _DynamicEnumChoice({
    required this.label,
    required this.value,
    required this.values,
    required this.labelFor,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T value) labelFor;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values
              .map(
                (item) => ChoiceChip(
                  label: Text(labelFor(item)),
                  selected: item == value,
                  onSelected: (_) => onChanged(item),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _DynamicFeedbackStrip extends StatelessWidget {
  const _DynamicFeedbackStrip({
    required this.accent,
    required this.icon,
    required this.text,
  });

  final Color accent;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: accent.withValues(alpha: 0.11),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: accent, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
