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
        ? pickUiText(
            i18n,
            zh: '识别稳定，可以提高速度、增加组合长度或开启弱干扰字符。',
            en: 'Recognition is stable. Raise speed, increase group length, or enable faint distractors.',
            ja: 'Recognition is stable. Raise speed, increase group length, or enable faint distractors.',
            de: 'Recognition is stable. Raise speed, increase group length, or enable faint distractors.',
            fr: 'La reconnaissance est stable. Augmenter la vitesse, augmenter la longueur du groupe ou permettre des disjoncteurs faibles.',
            es: 'El reconocimiento es estable. Aumentar la velocidad, aumentar la longitud del grupo o permitir distracciones débiles.',
            ru: 'Признание стабильное. Повысить скорость, увеличить длину группы или включить слабые отвлекающие факторы.',
          )
        : accuracy >= 0.65
        ? pickUiText(
            i18n,
            zh: '建议保留当前字符集，先把正确率稳定到 85% 后再增加速度。',
            en: 'Keep the current set and stabilize accuracy above 85% before raising speed.',
            ja: 'Keep the current set and stabilize accuracy above 85% before raising speed.',
            de: 'Keep the current set and stabilize accuracy above 85% before raising speed.',
            fr: 'Conserver le réglage du courant et stabiliser la précision au-dessus de 85% avant de soulever la vitesse.',
            es: 'Mantener el conjunto actual y estabilizar la precisión por encima del 85% antes de aumentar la velocidad.',
            ru: 'Поддерживайте ток и стабилизируйте точность выше 85%, прежде чем повышать скорость.',
          )
        : pickUiText(
            i18n,
            zh: '先降低速度或改用数字/字母单一字符集，减少易混淆压力。',
            en: 'Lower speed or use a single digits/letters set to reduce confusable-symbol pressure.',
            ja: 'Lower speed or use a single digits/letters set to reduce confusable-symbol pressure.',
            de: 'Lower speed or use a single digits/letters set to reduce confusable-symbol pressure.',
            fr: 'Abaissez la vitesse ou utilisez un seul chiffre/lettre pour réduire la pression du symbole confusable.',
            es: 'Velocidad inferior o utilizar un solo dígitos/letters para reducir la presión confusable-símbolo.',
            ru: 'Снижение скорости или использование однозначных цифр / букв, установленных для снижения давления конфузионного символа.',
          );
    return AlertDialog(
      title: Text(
        pickUiText(
          i18n,
          zh: '字符识别报告',
          en: 'Symbol recognition report',
          ja: 'Symbol recognition report',
          de: 'Symbol recognition report',
          fr: 'Rapport de reconnaissance des symboles',
          es: 'Informe sobre el reconocimiento de las signaturas',
          ru: 'Отчет о признании символов',
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
                    label: pickUiText(
                      i18n,
                      zh: '正确率',
                      en: 'Accuracy',
                      ja: '精度',
                      de: 'Accuracy',
                      fr: 'Accuracy',
                      es: 'Precisión',
                      ru: 'точность',
                    ),
                    value: '${(accuracy * 100).round()}%',
                  ),
                  _ColorVisionReportMetric(
                    label: pickUiText(
                      i18n,
                      zh: '正确/轮次',
                      en: 'Correct/rounds',
                      ja: '正解/ラウンド',
                      de: 'Correct/rounds',
                      fr: 'Correct/rounds',
                      es: 'Correct/rounds',
                      ru: 'Правильные/круглые',
                    ),
                    value: '$correct/${records.length}',
                  ),
                  _ColorVisionReportMetric(
                    label: pickUiText(
                      i18n,
                      zh: '平均显示',
                      en: 'Avg dwell',
                      ja: '平均滞留',
                      de: 'Avg dwell',
                      fr: 'Avg habite',
                      es: 'Avg habita',
                      ru: 'Авг живет',
                    ),
                    value: _formatMilliseconds(avgDwell),
                  ),
                  _ColorVisionReportMetric(
                    label: pickUiText(
                      i18n,
                      zh: '最快显示',
                      en: 'Fastest dwell',
                      ja: 'Fastest dwell',
                      de: 'Fastest dwell',
                      fr: 'La plus rapide demeure',
                      es: 'Morar más rápido',
                      ru: 'Быстрый дом',
                    ),
                    value: _formatMilliseconds(fastestDwell),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ColorVisionReportSection(
                title: pickUiText(
                  i18n,
                  zh: '本轮配置',
                  en: 'Session setup',
                  ja: 'Session setup',
                  de: 'Session setup',
                  fr: 'Configuration de la session',
                  es: 'Creación del período de sesiones',
                  ru: 'Настройка сеанса',
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    Chip(label: Text(setLabel(records.last.set))),
                    Chip(label: Text(pathLabel(records.last.path))),
                    Chip(
                      label: Text(
                        pickUiText(
                          i18n,
                          zh: '速度 ${records.last.speed.toStringAsFixed(1)}x',
                          en: 'Speed ${records.last.speed.toStringAsFixed(1)}x',
                          ja: 'Speed ${records.last.speed.toStringAsFixed(1)}x',
                          de: 'Speed ${records.last.speed.toStringAsFixed(1)}x',
                          fr: 'Vitesse ${records.last.speed.toStringAsFixed(1)}x',
                          es: 'Velocidad',
                          ru: 'Скорость <v0/x>',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _ColorVisionReportSection(
                title: pickUiText(
                  i18n,
                  zh: '训练建议',
                  en: 'Training note',
                  ja: 'Training note',
                  de: 'Training note',
                  fr: 'Note de formation',
                  es: 'Nota de capacitación',
                  ru: 'Учебная записка',
                ),
                child: Text(
                  recommendation,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                ),
              ),
              if (missed.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                _ColorVisionReportSection(
                  title: pickUiText(
                    i18n,
                    zh: '错认记录',
                    en: 'Missed symbols',
                    ja: 'Missed symbols',
                    de: 'Missed symbols',
                    fr: 'Symboles manquants',
                    es: 'Símbolos perdidos',
                    ru: 'Пропущенные символы',
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
          child: Text(
            pickUiText(
              i18n,
              zh: '关闭',
              en: 'Close',
              ja: '閉じる',
              de: 'Close',
              fr: 'Fermer',
              es: 'Cerca',
              ru: 'Закрыть',
            ),
          ),
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
