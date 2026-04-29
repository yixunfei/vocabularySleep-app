part of 'daily_choice_hub.dart';

class _CustomRandomStage extends StatelessWidget {
  const _CustomRandomStage({
    required this.i18n,
    required this.accent,
    required this.options,
    required this.probabilities,
    required this.animation,
    required this.result,
    required this.progress,
  });

  final AppI18n i18n;
  final Color accent;
  final List<DailyChoiceCustomRandomOption> options;
  final Map<String, double> probabilities;
  final DailyChoiceCustomRandomAnimation animation;
  final DailyChoiceCustomRandomResult? result;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wheelProgress = _wheelStopProgress(progress);
    final child = switch (animation) {
      DailyChoiceCustomRandomAnimation.wheel => _WheelRandomStage(
        options: options,
        probabilities: probabilities,
        accent: accent,
        rotation: result == null
            ? 0
            : _wheelStopRotation(
                    options: options,
                    probabilities: probabilities,
                    winnerId: result!.winner.id,
                  ) *
                  wheelProgress,
        winnerId: result?.winner.id,
        progress: progress,
      ),
      DailyChoiceCustomRandomAnimation.dice => _DiceRandomStage(
        i18n: i18n,
        accent: accent,
        options: options,
        result: result,
        progress: progress,
      ),
      DailyChoiceCustomRandomAnimation.coin => _CoinRandomStage(
        i18n: i18n,
        accent: accent,
        options: options,
        result: result,
        progress: progress,
      ),
    };
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            theme.colorScheme.surfaceContainerLowest,
            Color.lerp(theme.colorScheme.surfaceContainerLow, accent, 0.08)!,
            theme.colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(ToolboxUiTokens.sectionPanelRadius),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: child,
    );
  }

  double _wheelStopProgress(double value) {
    final clamped = value.clamp(0.0, 1.0).toDouble();
    final base = 1 - math.pow(1 - clamped, 5).toDouble();
    final settle = ((clamped - 0.70) / 0.30).clamp(0.0, 1.0).toDouble();
    final recoil =
        math.sin(settle * math.pi * 2.5) *
        math.pow(1 - settle, 1.7).toDouble() *
        0.012;
    return base + recoil;
  }

  double _wheelStopRotation({
    required List<DailyChoiceCustomRandomOption> options,
    required Map<String, double> probabilities,
    required String winnerId,
  }) {
    var cumulative = 0.0;
    for (final option in options) {
      final sweep =
          math.pi * 2 * (probabilities[option.id] ?? (1 / options.length));
      if (option.id == winnerId) {
        return math.pi * 2 * 8 - cumulative - sweep / 2;
      }
      cumulative += sweep;
    }
    return math.pi * 2 * 8;
  }
}

Offset _customRandomWheelCenter(Size size) {
  return Offset(size.width / 2, size.height / 2 + 8);
}

double _customRandomWheelRadius(Size size) {
  return math.max(70, math.min(size.width, size.height) / 2 - 36);
}

class _WheelRandomStage extends StatelessWidget {
  const _WheelRandomStage({
    required this.options,
    required this.probabilities,
    required this.accent,
    required this.rotation,
    required this.progress,
    this.winnerId,
  });

  final List<DailyChoiceCustomRandomOption> options;
  final Map<String, double> probabilities;
  final Color accent;
  final double rotation;
  final double progress;
  final String? winnerId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spinning = winnerId != null;
    final lift = spinning ? math.sin(progress * math.pi) * 3.5 : 0.0;
    final settle = spinning
        ? Curves.easeOutCubic.transform(progress) * 1.5
        : 0.0;
    final pointerFlex = spinning
        ? math.sin(progress * math.pi * 34) *
              math.pow(1 - progress, 1.55).toDouble() *
              0.13
        : 0.0;

    return RepaintBoundary(
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned.fill(
            child: CustomPaint(
              painter: _WheelStageAtmospherePainter(
                accent: accent,
                surfaceColor: theme.colorScheme.surface,
                outlineColor: theme.colorScheme.outlineVariant,
                progress: progress,
                active: spinning,
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(0, settle - lift),
            child: CustomPaint(
              painter: _CustomRandomWheelPainter(
                options: options,
                probabilities: probabilities,
                accent: accent,
                rotation: rotation,
                winnerId: winnerId,
                progress: progress,
                textColor: theme.colorScheme.onSurface,
                surfaceColor: theme.colorScheme.surface,
                outlineColor: theme.colorScheme.outlineVariant,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _WheelPointerPainter(
                  accent: accent,
                  surfaceColor: theme.colorScheme.surface,
                  outlineColor: theme.colorScheme.outlineVariant,
                  flex: pointerFlex,
                  progress: progress,
                  active: spinning,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WheelStageAtmospherePainter extends CustomPainter {
  _WheelStageAtmospherePainter({
    required this.accent,
    required this.surfaceColor,
    required this.outlineColor,
    required this.progress,
    required this.active,
  });

  final Color accent;
  final Color surfaceColor;
  final Color outlineColor;
  final double progress;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final center = _customRandomWheelCenter(size);
    final radius = _customRandomWheelRadius(size);
    final tableRect = Rect.fromLTWH(
      size.width * 0.06,
      center.dy + radius * 0.60,
      size.width * 0.88,
      radius * 0.42,
    );
    final glow = active ? math.sin(progress * math.pi).abs() : 0.0;

    canvas.drawOval(
      Rect.fromCircle(center: center.translate(0, 4), radius: radius + 34),
      Paint()
        ..shader =
            RadialGradient(
              colors: <Color>[
                Color.lerp(
                  surfaceColor,
                  accent,
                  0.28,
                )!.withValues(alpha: 0.30 + glow * 0.10),
                accent.withValues(alpha: 0.08 + glow * 0.05),
                Colors.transparent,
              ],
              stops: const <double>[0.0, 0.56, 1.0],
            ).createShader(
              Rect.fromCircle(
                center: center.translate(0, 4),
                radius: radius + 34,
              ),
            ),
    );

    canvas.drawOval(
      tableRect.translate(0, 6),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawOval(
      tableRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color.lerp(surfaceColor, accent, 0.10)!.withValues(alpha: 0.74),
            Color.lerp(
              surfaceColor,
              Colors.black,
              0.10,
            )!.withValues(alpha: 0.46),
          ],
        ).createShader(tableRect),
    );
    canvas.drawOval(
      tableRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = outlineColor.withValues(alpha: 0.16),
    );
  }

  @override
  bool shouldRepaint(covariant _WheelStageAtmospherePainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.surfaceColor != surfaceColor ||
        oldDelegate.outlineColor != outlineColor ||
        oldDelegate.progress != progress ||
        oldDelegate.active != active;
  }
}

class _WheelPointerPainter extends CustomPainter {
  _WheelPointerPainter({
    required this.accent,
    required this.surfaceColor,
    required this.outlineColor,
    required this.flex,
    required this.progress,
    required this.active,
  });

  final Color accent;
  final Color surfaceColor;
  final Color outlineColor;
  final double flex;
  final double progress;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final center = _customRandomWheelCenter(size);
    final radius = _customRandomWheelRadius(size);
    final anchor = Offset(center.dx, center.dy - radius - 28);
    final bracketRect = Rect.fromCenter(
      center: anchor.translate(0, 6),
      width: 78,
      height: 24,
    );
    final reveal = active
        ? ((progress - 0.70) / 0.30).clamp(0.0, 1.0).toDouble()
        : 0.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        bracketRect.translate(0, 3),
        const Radius.circular(14),
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bracketRect, const Radius.circular(14)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.92),
            Color.lerp(surfaceColor, accent, 0.30)!,
            Color.lerp(Colors.black, accent, 0.28)!,
          ],
        ).createShader(bracketRect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bracketRect, const Radius.circular(14)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = outlineColor.withValues(alpha: 0.34),
    );

    canvas.save();
    canvas.translate(anchor.dx, anchor.dy + 9);
    canvas.rotate(flex);
    final pointer = ui.Path()
      ..moveTo(0, 51)
      ..cubicTo(-9, 42, -17, 25, -15, 7)
      ..quadraticBezierTo(0, -3, 15, 7)
      ..cubicTo(17, 25, 9, 42, 0, 51)
      ..close();
    final pointerBounds = pointer.getBounds();
    canvas.drawPath(
      pointer.shift(const Offset(0, 3)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawPath(
      pointer,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            const Color(0xFFFFF7DF),
            Color.lerp(const Color(0xFFE4B154), accent, 0.20)!,
            const Color(0xFF8E4F22),
          ],
          stops: const <double>[0.0, 0.50, 1.0],
        ).createShader(pointerBounds),
    );
    canvas.drawPath(
      pointer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.72),
    );
    canvas.drawCircle(
      const Offset(0, 12),
      5.5,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.38, -0.45),
          colors: <Color>[
            Colors.white,
            Color.lerp(surfaceColor, accent, 0.56)!,
            Color.lerp(Colors.black, accent, 0.24)!,
          ],
        ).createShader(Rect.fromCircle(center: const Offset(0, 12), radius: 7)),
    );
    canvas.drawCircle(
      const Offset(0, 48),
      2.5 + reveal * 1.3,
      Paint()..color = Colors.white.withValues(alpha: 0.72 + reveal * 0.20),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WheelPointerPainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.surfaceColor != surfaceColor ||
        oldDelegate.outlineColor != outlineColor ||
        oldDelegate.flex != flex ||
        oldDelegate.progress != progress ||
        oldDelegate.active != active;
  }
}

class _DiceRandomStage extends StatelessWidget {
  const _DiceRandomStage({
    required this.i18n,
    required this.accent,
    required this.options,
    required this.result,
    required this.progress,
  });

  final AppI18n i18n;
  final Color accent;
  final List<DailyChoiceCustomRandomOption> options;
  final DailyChoiceCustomRandomResult? result;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final layout =
        result?.diceLayout ??
        DailyChoiceDiceLayout.forOptions(
          optionCount: options.length,
          preferredDiceCount: 1,
        );
    if (!layout.valid) {
      return Center(
        child: Text(
          pickUiText(
            i18n,
            zh: '至少 3 个选项才能生成骰子。',
            en: 'Need at least 3 options for dice.',
          ),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    final rolling = result != null;
    final diceCount = layout.facesPerDie.length;
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stageHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : 236.0;
          final tableHeight = math.max(148.0, stageHeight - 44);
          final dieSize = _dieSizeFor(
            diceCount: diceCount,
            width: constraints.maxWidth,
            tableHeight: tableHeight,
          );
          final spacing = math.max(6.0, dieSize * 0.10);
          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Positioned.fill(
                child: CustomPaint(
                  painter: _DiceStageAtmospherePainter(
                    accent: accent,
                    surfaceColor: theme.colorScheme.surface,
                    outlineColor: theme.colorScheme.outlineVariant,
                    progress: progress,
                    active: rolling,
                    diceCount: diceCount,
                  ),
                ),
              ),
              Positioned(
                left: 6,
                right: 6,
                top: 8,
                height: tableHeight,
                child: Wrap(
                  spacing: spacing,
                  runSpacing: math.max(4.0, spacing * 0.55),
                  alignment: WrapAlignment.center,
                  runAlignment: WrapAlignment.center,
                  children: <Widget>[
                    for (
                      var index = 0;
                      index < layout.facesPerDie.length;
                      index += 1
                    )
                      _RollingPolyhedralDie(
                        accent: accent,
                        index: index,
                        selected: result?.diceIndex == index,
                        rolling: rolling,
                        progress: progress,
                        label: 'D${index + 1}',
                        faceValue: _faceValueFor(
                          index,
                          layout.facesPerDie[index],
                        ),
                        sides: layout.facesPerDie[index],
                        faceText: pickUiText(
                          i18n,
                          zh: '${layout.facesPerDie[index]} 面',
                          en: '${layout.facesPerDie[index]} sides',
                        ),
                        size: dieSize,
                      ),
                  ],
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 4,
                child: AnimatedDefaultTextStyle(
                  duration: AppDurations.standard,
                  curve: AppEasing.standard,
                  textAlign: TextAlign.center,
                  style:
                      theme.textTheme.bodySmall?.copyWith(
                        color: result == null
                            ? theme.colorScheme.onSurfaceVariant
                            : accent,
                        fontWeight: result == null
                            ? FontWeight.w600
                            : FontWeight.w800,
                      ) ??
                      const TextStyle(),
                  child: Text(
                    result == null
                        ? pickUiText(
                            i18n,
                            zh: '每颗骰子 3 到 12 面，按选项数量自动分配。',
                            en: 'Each die gets 3 to 12 faces based on option count.',
                          )
                        : pickUiText(
                            i18n,
                            zh: '落在 D${(result!.diceIndex ?? 0) + 1} 第 ${(result!.diceFaceIndex ?? 0) + 1} 面',
                            en: 'Landed on D${(result!.diceIndex ?? 0) + 1}, face ${(result!.diceFaceIndex ?? 0) + 1}',
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  double _dieSizeFor({
    required int diceCount,
    required double width,
    required double tableHeight,
  }) {
    const spacing = 8.0;
    final usableWidth = math.max(120.0, width - 16);
    final maxColumns = math
        .min(diceCount, math.max(1, (usableWidth / 48).floor()))
        .toInt();
    var bestSize = 42.0;
    for (var columns = 1; columns <= maxColumns; columns += 1) {
      final rows = (diceCount / columns).ceil();
      final widthSize = (usableWidth - (columns - 1) * spacing) / columns - 8;
      final slotChrome = rows > 2 ? 12.0 : 18.0;
      final heightSize =
          (tableHeight - (rows - 1) * spacing) / rows - slotChrome;
      final cap = diceCount <= 2 ? 98.0 : 86.0;
      final candidate = math.min(cap, math.min(widthSize, heightSize));
      if (candidate > bestSize) {
        bestSize = candidate;
      }
    }
    return bestSize.clamp(42.0, diceCount <= 2 ? 98.0 : 86.0).toDouble();
  }

  int _faceValueFor(int index, int faces) {
    final finalFace = result?.diceIndex == index
        ? (result!.diceFaceIndex ?? 0) + 1
        : math.min(faces, index + 1);
    if (result == null || progress >= 0.98) {
      return finalFace;
    }
    return ((progress * 28).floor() + index * 3) % faces + 1;
  }
}

class _RollingPolyhedralDie extends StatelessWidget {
  const _RollingPolyhedralDie({
    required this.accent,
    required this.index,
    required this.selected,
    required this.rolling,
    required this.progress,
    required this.label,
    required this.faceValue,
    required this.sides,
    required this.faceText,
    required this.size,
  });

  final Color accent;
  final int index;
  final bool selected;
  final bool rolling;
  final double progress;
  final String label;
  final int faceValue;
  final int sides;
  final String faceText;
  final double size;

  @override
  Widget build(BuildContext context) {
    final clamped = rolling ? progress.clamp(0.0, 1.0).toDouble() : 1.0;
    final eased = AppEasing.snappy.transform(clamped);
    final energy = rolling ? math.pow(1 - clamped, 0.72).toDouble() : 0.0;
    final bounceCycle = 4.2 + index * 0.34;
    final bounce = math.sin(clamped * math.pi * bounceCycle).abs();
    final lift = bounce * energy * size * 0.30;
    final impact = rolling ? math.pow(1 - bounce, 8).toDouble() * energy : 0.0;
    final skid =
        math.sin(clamped * math.pi * (2.3 + index * 0.17) + index * 1.4) *
        energy *
        size *
        0.16;
    final settle = ((clamped - 0.72) / 0.28).clamp(0.0, 1.0).toDouble();
    final selectedPulse = selected ? math.sin(settle * math.pi) * 0.035 : 0.0;
    final settleWobble = selected
        ? math.sin(settle * math.pi * 4) *
              math.pow(1 - settle, 2.1).toDouble() *
              0.12
        : 0.0;
    final finalTiltX = -0.20 + (index % 3 - 1) * 0.025;
    final finalTiltY = 0.25 - (index % 2) * 0.08;
    final finalTiltZ = -0.08 + (index % 4 - 1.5) * 0.025;
    final rollLeft = index.isEven ? 1.0 : -1.0;
    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.0012)
      ..rotateX(
        finalTiltX +
            (rolling ? (1 - eased) * math.pi * (3.5 + index * 0.24) : 0) +
            settleWobble,
      )
      ..rotateY(
        finalTiltY +
            (rolling
                ? (1 - eased) * math.pi * (4.7 + index * 0.31) * rollLeft
                : 0),
      )
      ..rotateZ(
        finalTiltZ +
            (rolling
                ? (1 - eased) * math.pi * (1.55 + index * 0.16) * -rollLeft
                : 0) -
            settleWobble * 0.55,
      );
    final squashX = 1 + impact * 0.075 + selectedPulse;
    final squashY = 1 - impact * 0.095 + selectedPulse * 0.4;

    return SizedBox(
      width: size + 10,
      height: size + 18,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            bottom: 0,
            child: CustomPaint(
              size: Size(size * 1.02, math.max(14, size * 0.22)),
              painter: _DieContactShadowPainter(
                accent: accent,
                selected: selected,
                lift: lift,
                impact: impact,
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(skid, -lift + impact * 2.4),
            child: Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.diagonal3Values(squashX, squashY, 1),
              child: Transform(
                alignment: Alignment.center,
                transform: transform,
                child: AnimatedScale(
                  duration: AppDurations.standard,
                  curve: AppEasing.quickBounce,
                  scale: selected ? 1.06 : 1,
                  child: _PolyhedralDie(
                    accent: accent,
                    selected: selected,
                    label: label,
                    faceValue: faceValue,
                    sides: sides,
                    faceText: faceText,
                    size: size,
                    rollProgress: clamped,
                    impact: impact,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DieContactShadowPainter extends CustomPainter {
  const _DieContactShadowPainter({
    required this.accent,
    required this.selected,
    required this.lift,
    required this.impact,
  });

  final Color accent;
  final bool selected;
  final double lift;
  final double impact;

  @override
  void paint(Canvas canvas, Size size) {
    final distance = (lift / math.max(1, size.width)).clamp(0.0, 0.42);
    final width = size.width * (1.0 - distance * 0.34 + impact * 0.18);
    final height = size.height * (0.58 - distance * 0.16 + impact * 0.16);
    final center = Offset(size.width / 2, size.height * 0.56);
    final rect = Rect.fromCenter(center: center, width: width, height: height);
    final alpha = 0.14 + impact * 0.11 + (selected ? 0.04 : 0.0);
    canvas.drawOval(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            Colors.black.withValues(alpha: alpha),
            Colors.black.withValues(alpha: alpha * 0.28),
            Colors.transparent,
          ],
          stops: const <double>[0.0, 0.62, 1.0],
        ).createShader(rect),
    );
    if (selected) {
      canvas.drawOval(
        rect.inflate(3),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = accent.withValues(alpha: 0.20),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DieContactShadowPainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.selected != selected ||
        oldDelegate.lift != lift ||
        oldDelegate.impact != impact;
  }
}

class _DiceStageAtmospherePainter extends CustomPainter {
  const _DiceStageAtmospherePainter({
    required this.accent,
    required this.surfaceColor,
    required this.outlineColor,
    required this.progress,
    required this.active,
    required this.diceCount,
  });

  final Color accent;
  final Color surfaceColor;
  final Color outlineColor;
  final double progress;
  final bool active;
  final int diceCount;

  @override
  void paint(Canvas canvas, Size size) {
    final glow = active ? math.sin(progress * math.pi).abs() : 0.0;
    final tableRect = Rect.fromLTWH(
      size.width * 0.055,
      size.height * 0.14,
      size.width * 0.89,
      size.height * 0.70,
    );
    final tableRRect = RRect.fromRectAndRadius(
      tableRect,
      const Radius.circular(28),
    );
    canvas.drawRRect(
      tableRRect.shift(const Offset(0, 7)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.11)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawRRect(
      tableRRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color.lerp(surfaceColor, accent, 0.18)!.withValues(alpha: 0.82),
            Color.lerp(
              surfaceColor,
              const Color(0xFFB8A58B),
              0.18,
            )!.withValues(alpha: 0.76),
            Color.lerp(
              surfaceColor,
              Colors.black,
              0.10,
            )!.withValues(alpha: 0.72),
          ],
          stops: const <double>[0.0, 0.58, 1.0],
        ).createShader(tableRect),
    );
    canvas.drawRRect(
      tableRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = outlineColor.withValues(alpha: 0.22),
    );

    final glowRect = Rect.fromCircle(
      center: Offset(size.width * 0.50, size.height * 0.42),
      radius: size.width * 0.42,
    );
    canvas.drawOval(
      glowRect,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            Colors.white.withValues(alpha: 0.15 + glow * 0.06),
            accent.withValues(alpha: 0.08 + glow * 0.06),
            Colors.transparent,
          ],
          stops: const <double>[0.0, 0.50, 1.0],
        ).createShader(glowRect),
    );

    final grainPaint = Paint()
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 18; index += 1) {
      final x = tableRect.left + tableRect.width * _hash(index, 0.17);
      final y = tableRect.top + tableRect.height * _hash(index, 0.61);
      final length = 8 + _hash(index, 0.93) * 20;
      final tilt = (_hash(index, 0.41) - 0.5) * 0.35;
      grainPaint.color = (index.isEven ? Colors.white : Colors.black)
          .withValues(alpha: index.isEven ? 0.055 : 0.035);
      canvas.drawLine(
        Offset(x, y),
        Offset(x + math.cos(tilt) * length, y + math.sin(tilt) * length),
        grainPaint,
      );
    }

    if (active) {
      final trailAlpha = math.pow(1 - progress, 0.85).toDouble();
      for (var trail = 0; trail < math.min(3, diceCount); trail += 1) {
        final y =
            tableRect.center.dy +
            (trail - 1) * tableRect.height * 0.13 +
            math.sin(progress * math.pi * 2 + trail) * 6;
        final path = ui.Path()
          ..moveTo(tableRect.left + 22, y)
          ..cubicTo(
            tableRect.left + tableRect.width * 0.28,
            y - 22 + trail * 4,
            tableRect.left + tableRect.width * 0.62,
            y + 20 - trail * 5,
            tableRect.right - 28,
            y - 3,
          );
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4 - trail * 0.35
            ..strokeCap = StrokeCap.round
            ..color = accent.withValues(alpha: 0.10 * trailAlpha),
        );
      }
    }
  }

  double _hash(int index, double salt) {
    return (math.sin(index * 37.719 + salt * 113.17) * 43758.5453)
        .abs()
        .remainder(1.0);
  }

  @override
  bool shouldRepaint(covariant _DiceStageAtmospherePainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.surfaceColor != surfaceColor ||
        oldDelegate.outlineColor != outlineColor ||
        oldDelegate.progress != progress ||
        oldDelegate.active != active ||
        oldDelegate.diceCount != diceCount;
  }
}

class _PolyhedralDie extends StatelessWidget {
  const _PolyhedralDie({
    required this.accent,
    required this.selected,
    required this.label,
    required this.faceValue,
    required this.sides,
    required this.faceText,
    required this.size,
    required this.rollProgress,
    required this.impact,
  });

  final Color accent;
  final bool selected;
  final String label;
  final int faceValue;
  final int sides;
  final String faceText;
  final double size;
  final double rollProgress;
  final double impact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _PolyhedralDiePainter(
            accent: accent,
            selected: selected,
            label: label,
            faceValue: faceValue,
            sides: sides,
            faceText: faceText,
            textColor: theme.colorScheme.onSurface,
            mutedTextColor: theme.colorScheme.onSurfaceVariant,
            surfaceColor: theme.colorScheme.surface,
            outlineColor: theme.colorScheme.outlineVariant,
            rollProgress: rollProgress,
            impact: impact,
          ),
        ),
      ),
    );
  }
}

class _PolyhedralDiePainter extends CustomPainter {
  _PolyhedralDiePainter({
    required this.accent,
    required this.selected,
    required this.label,
    required this.faceValue,
    required this.sides,
    required this.faceText,
    required this.textColor,
    required this.mutedTextColor,
    required this.surfaceColor,
    required this.outlineColor,
    required this.rollProgress,
    required this.impact,
  });

  final Color accent;
  final bool selected;
  final String label;
  final int faceValue;
  final int sides;
  final String faceText;
  final Color textColor;
  final Color mutedTextColor;
  final Color surfaceColor;
  final Color outlineColor;
  final double rollProgress;
  final double impact;

  @override
  void paint(Canvas canvas, Size size) {
    final visualSides = sides.clamp(3, 12).toInt();
    final darkSurface = surfaceColor.computeLuminance() < 0.24;
    final resinLight = darkSurface
        ? const Color(0xFFFFF8E8)
        : const Color(0xFFFFFCF3);
    final motionGlow = math.sin(rollProgress * math.pi).abs();
    final resinMid = Color.lerp(
      const Color(0xFFE8D8BE),
      accent,
      selected ? 0.16 + motionGlow * 0.04 : 0.08 + motionGlow * 0.02,
    )!;
    final resinDeep = Color.lerp(
      const Color(0xFF9C8360),
      accent,
      selected ? 0.24 : 0.10,
    )!;
    final inkColor = Color.lerp(
      const Color(0xFF2B2117),
      accent,
      selected ? 0.34 : 0.04,
    )!;
    final center = Offset(size.width * 0.47, size.height * 0.45);
    final radius = math.min(size.width, size.height) * 0.325;
    final depth = Offset(size.width * 0.115, size.height * 0.12);
    final rotation =
        -math.pi / 2 + (visualSides.isEven ? math.pi / visualSides : 0);
    final front = _polygon(center, radius, visualSides, rotation);
    final back = _polygon(center + depth, radius, visualSides, rotation);
    final frontPath = _roundedPathFor(front, 0.105);
    final backPath = _roundedPathFor(back, 0.085);
    final bounds = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawPath(
      backPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            _mix(resinMid, surfaceColor, 0.12),
            _mix(resinDeep, accent, selected ? 0.22 : 0.08),
            _mix(const Color(0xFF5C4933), accent, selected ? 0.18 : 0.04),
          ],
          stops: const <double>[0.0, 0.58, 1.0],
        ).createShader(bounds),
    );

    for (var index = 0; index < visualSides; index += 1) {
      final next = (index + 1) % visualSides;
      final sidePath = ui.Path()
        ..moveTo(back[index].dx, back[index].dy)
        ..lineTo(back[next].dx, back[next].dy)
        ..lineTo(front[next].dx, front[next].dy)
        ..lineTo(front[index].dx, front[index].dy)
        ..close();
      final mid = (front[index] + front[next]) / 2 - center;
      final light = ((-mid.dx - mid.dy) / (radius * 1.45))
          .clamp(-1.0, 1.0)
          .toDouble();
      final shade = 0.34 + (light + 1) * 0.18;
      canvas.drawPath(
        sidePath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              _mix(
                resinLight,
                resinMid,
                (1 - shade).clamp(0.0, 1.0).toDouble(),
              ),
              _mix(resinMid, accent, selected ? 0.18 : 0.06),
              _mix(resinDeep, const Color(0xFF453625), 0.24),
            ],
            stops: const <double>[0.0, 0.55, 1.0],
          ).createShader(sidePath.getBounds()),
      );
      canvas.drawPath(
        sidePath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.65
          ..color = Colors.white.withValues(alpha: 0.28),
      );
    }

    canvas.drawPath(
      frontPath,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.45, -0.55),
          radius: 1.05,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.98),
            resinLight,
            resinMid,
            _mix(resinDeep, accent, selected ? 0.18 : 0.04),
          ],
          stops: const <double>[0.0, 0.26, 0.68, 1.0],
        ).createShader(frontPath.getBounds()),
    );

    _paintResinGrain(canvas, frontPath, center, radius, resinDeep);
    _paintFrontFacets(canvas, front, center, selected);

    canvas.drawPath(
      frontPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 2.0 : 1.1
        ..color = selected
            ? accent.withValues(alpha: 0.76)
            : resinDeep.withValues(alpha: 0.58),
    );
    canvas.drawPath(
      frontPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = Colors.white.withValues(alpha: 0.72),
    );
    _paintSpecularGlaze(canvas, frontPath, center, radius, selected);

    if (faceValue <= 6) {
      _paintPips(canvas, center, radius, faceValue, inkColor);
    } else {
      _paintCenteredText(
        canvas,
        '$faceValue',
        center,
        TextStyle(
          color: inkColor,
          fontSize: size.shortestSide * 0.26,
          fontWeight: FontWeight.w900,
          shadows: <Shadow>[
            Shadow(
              color: Colors.white.withValues(alpha: 0.34),
              blurRadius: 2,
              offset: const Offset(-0.8, -0.8),
            ),
            Shadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 2,
              offset: const Offset(0.8, 1.0),
            ),
          ],
        ),
        maxWidth: radius * 1.15,
      );
    }

    _paintCornerText(
      canvas,
      label,
      Offset(size.width * 0.15, size.height * 0.13),
      TextStyle(
        color: mutedTextColor,
        fontSize: size.shortestSide * 0.105,
        fontWeight: FontWeight.w900,
      ),
      maxWidth: size.width * 0.34,
    );
    _paintCornerText(
      canvas,
      faceText,
      Offset(size.width * 0.53, size.height * 0.75),
      TextStyle(
        color: mutedTextColor.withValues(alpha: 0.86),
        fontSize: size.shortestSide * 0.095,
        fontWeight: FontWeight.w800,
      ),
      maxWidth: size.width * 0.38,
    );
  }

  List<Offset> _polygon(
    Offset center,
    double radius,
    int sides,
    double rotation,
  ) {
    return List<Offset>.generate(sides, (index) {
      final angle = rotation + math.pi * 2 * index / sides;
      final stretch = 1 + math.sin(angle + math.pi / 5) * 0.035;
      return center +
          Offset(math.cos(angle), math.sin(angle)) * radius * stretch;
    }, growable: false);
  }

  ui.Path _roundedPathFor(List<Offset> points, double corner) {
    final path = ui.Path();
    for (var index = 0; index < points.length; index += 1) {
      final current = points[index];
      final previous = points[(index - 1 + points.length) % points.length];
      final next = points[(index + 1) % points.length];
      final start = Offset.lerp(current, previous, corner)!;
      final end = Offset.lerp(current, next, corner)!;
      if (index == 0) {
        path.moveTo(start.dx, start.dy);
      } else {
        path.lineTo(start.dx, start.dy);
      }
      path.quadraticBezierTo(current.dx, current.dy, end.dx, end.dy);
    }
    return path..close();
  }

  void _paintResinGrain(
    Canvas canvas,
    ui.Path frontPath,
    Offset center,
    double radius,
    Color resinDeep,
  ) {
    canvas.save();
    canvas.clipPath(frontPath);
    for (var index = 0; index < 22; index += 1) {
      final angle = math.pi * 2 * _hash(index, faceValue * 0.37 + sides);
      final distance = radius * 0.72 * _hash(index, faceValue * 0.19 + 7);
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * distance;
      final alpha = 0.025 + _hash(index, 0.71) * 0.035;
      canvas.drawCircle(
        point,
        radius * (0.010 + _hash(index, 0.53) * 0.012),
        Paint()
          ..color = (index.isEven ? resinDeep : Colors.white).withValues(
            alpha: alpha,
          ),
      );
    }
    canvas.restore();
  }

  void _paintSpecularGlaze(
    Canvas canvas,
    ui.Path frontPath,
    Offset center,
    double radius,
    bool selected,
  ) {
    canvas.save();
    canvas.clipPath(frontPath);
    final shine = Rect.fromCenter(
      center: center.translate(-radius * 0.24, -radius * 0.30),
      width: radius * 1.08,
      height: radius * 0.34,
    );
    canvas.drawOval(
      shine,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Colors.white.withValues(alpha: selected ? 0.34 : 0.26),
            Colors.white.withValues(alpha: 0.04),
          ],
        ).createShader(shine),
    );
    if (impact > 0.05) {
      final spark = Rect.fromCircle(
        center: center.translate(radius * 0.26, -radius * 0.20),
        radius: radius * (0.16 + impact * 0.10),
      );
      canvas.drawOval(
        spark,
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[
              Colors.white.withValues(alpha: 0.26 * impact),
              accent.withValues(alpha: 0.10 * impact),
              Colors.transparent,
            ],
          ).createShader(spark),
      );
    }
    canvas.restore();
  }

  void _paintFrontFacets(
    Canvas canvas,
    List<Offset> points,
    Offset center,
    bool selected,
  ) {
    for (var index = 0; index < points.length; index += 1) {
      final next = (index + 1) % points.length;
      final facet = ui.Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(points[index].dx, points[index].dy)
        ..lineTo(points[next].dx, points[next].dy)
        ..close();
      final alpha = index.isEven ? 0.12 : 0.06;
      canvas.drawPath(
        facet,
        Paint()
          ..color = (selected ? accent : Colors.white).withValues(alpha: alpha),
      );
      canvas.drawLine(
        center,
        points[index],
        Paint()
          ..strokeWidth = 0.65
          ..color = Colors.white.withValues(alpha: 0.18),
      );
    }
  }

  void _paintPips(
    Canvas canvas,
    Offset center,
    double radius,
    int value,
    Color color,
  ) {
    final pipOffsets = _pipOffsets(value, radius * 0.46);
    for (final offset in pipOffsets) {
      final pipCenter = center + offset;
      canvas.drawCircle(
        pipCenter.translate(0.8, 1.0),
        radius * 0.088,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6),
      );
      canvas.drawCircle(
        pipCenter,
        radius * 0.088,
        Paint()
          ..shader =
              RadialGradient(
                center: const Alignment(0.28, 0.34),
                colors: <Color>[
                  _mix(Colors.black, color, 0.18),
                  color,
                  _mix(Colors.white, color, 0.26),
                ],
                stops: const <double>[0.0, 0.70, 1.0],
              ).createShader(
                Rect.fromCircle(center: pipCenter, radius: radius * 0.10),
              ),
      );
      canvas.drawCircle(
        pipCenter.translate(-radius * 0.020, -radius * 0.022),
        radius * 0.030,
        Paint()..color = Colors.white.withValues(alpha: 0.18),
      );
    }
  }

  List<Offset> _pipOffsets(int value, double spread) {
    return switch (value.clamp(1, 6)) {
      1 => <Offset>[Offset.zero],
      2 => <Offset>[Offset(-spread, -spread), Offset(spread, spread)],
      3 => <Offset>[
        Offset(-spread, -spread),
        Offset.zero,
        Offset(spread, spread),
      ],
      4 => <Offset>[
        Offset(-spread, -spread),
        Offset(spread, -spread),
        Offset(-spread, spread),
        Offset(spread, spread),
      ],
      5 => <Offset>[
        Offset(-spread, -spread),
        Offset(spread, -spread),
        Offset.zero,
        Offset(-spread, spread),
        Offset(spread, spread),
      ],
      _ => <Offset>[
        Offset(-spread, -spread),
        Offset(-spread, 0),
        Offset(-spread, spread),
        Offset(spread, -spread),
        Offset(spread, 0),
        Offset(spread, spread),
      ],
    };
  }

  void _paintCenteredText(
    Canvas canvas,
    String text,
    Offset center,
    TextStyle style, {
    required double maxWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: maxWidth);
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  void _paintCornerText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style, {
    required double maxWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, offset);
  }

  Color _mix(Color a, Color b, double amount) {
    return Color.lerp(a, b, amount.clamp(0.0, 1.0).toDouble())!;
  }

  double _hash(int index, double salt) {
    return (math.sin(index * 19.713 + salt * 83.911) * 24634.6345)
        .abs()
        .remainder(1.0);
  }

  @override
  bool shouldRepaint(covariant _PolyhedralDiePainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.selected != selected ||
        oldDelegate.label != label ||
        oldDelegate.faceValue != faceValue ||
        oldDelegate.sides != sides ||
        oldDelegate.faceText != faceText ||
        oldDelegate.textColor != textColor ||
        oldDelegate.mutedTextColor != mutedTextColor ||
        oldDelegate.surfaceColor != surfaceColor ||
        oldDelegate.outlineColor != outlineColor ||
        oldDelegate.rollProgress != rollProgress ||
        oldDelegate.impact != impact;
  }
}

class _CoinRandomStage extends StatelessWidget {
  const _CoinRandomStage({
    required this.i18n,
    required this.accent,
    required this.options,
    required this.result,
    required this.progress,
  });

  final AppI18n i18n;
  final Color accent;
  final List<DailyChoiceCustomRandomOption> options;
  final DailyChoiceCustomRandomResult? result;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (options.length != 2) {
      return Center(
        child: Text(
          pickUiText(
            i18n,
            zh: '硬币需要正好 2 个选项。',
            en: 'Coin needs exactly 2 options.',
          ),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    final flips = result?.coinFlips;
    final winnerIsBack = result?.winner.id == options[1].id;
    final finalTurn = winnerIsBack ? math.pi : 0.0;
    final angle = result == null ? 0.0 : progress * (math.pi * 12 + finalTurn);
    final showingBack = math.cos(angle) < 0;
    final visibleOption = options[showingBack ? 1 : 0];
    final lift = result == null ? 0.0 : math.sin(progress * math.pi) * 18;
    final shadowScale = 1.0 - math.sin(progress * math.pi) * 0.22;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          height: 132,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Positioned(
                bottom: 2,
                child: Transform.scale(
                  scaleX: shadowScale,
                  scaleY: 0.72,
                  child: Container(
                    width: 116,
                    height: 22,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: RadialGradient(
                        colors: <Color>[
                          Colors.black.withValues(alpha: 0.18),
                          Colors.black.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, -lift),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateX(math.sin(progress * math.pi) * 0.08)
                    ..rotateY(angle),
                  child: _MetalCoin(
                    accent: accent,
                    label: visibleOption.label,
                    sideLabel: showingBack
                        ? pickUiText(i18n, zh: '反', en: 'B')
                        : pickUiText(i18n, zh: '正', en: 'A'),
                    compressed: (math.cos(angle)).abs() < 0.20,
                    winner: result != null && progress >= 0.96,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: <Widget>[
            if (flips == null)
              for (var index = 0; index < 3; index += 1)
                ToolboxInfoPill(
                  text: '${index + 1}',
                  accent: accent,
                  backgroundColor: theme.colorScheme.surface,
                )
            else
              for (final flip in flips.take(9))
                ToolboxInfoPill(
                  text: flip.option.label,
                  accent: accent,
                  backgroundColor: flip.option.id == result!.winner.id
                      ? accent.withValues(alpha: 0.12)
                      : theme.colorScheme.surface,
                ),
          ],
        ),
      ],
    );
  }
}

class _MetalCoin extends StatelessWidget {
  const _MetalCoin({
    required this.accent,
    required this.label,
    required this.sideLabel,
    required this.compressed,
    required this.winner,
  });

  final Color accent;
  final String label;
  final String sideLabel;
  final bool compressed;
  final bool winner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shortLabel = label.characters.take(2).toString();
    return AnimatedContainer(
      duration: AppDurations.quick,
      curve: AppEasing.snappy,
      width: compressed ? 24 : 116,
      height: 116,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: compressed
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0xFFFFF0AF),
                  Color(0xFFB8772D),
                  Color(0xFF654218),
                ],
                stops: <double>[0.0, 0.48, 1.0],
              )
            : RadialGradient(
                center: const Alignment(-0.35, -0.45),
                radius: 0.95,
                colors: <Color>[
                  const Color(0xFFFFF7C8),
                  const Color(0xFFE7BD62),
                  Color.lerp(const Color(0xFFD59643), accent, 0.28)!,
                  const Color(0xFF6B471C),
                ],
                stops: const <double>[0.0, 0.38, 0.76, 1.0],
              ),
        border: Border.all(color: const Color(0xFFFFE8A1), width: 2.5),
        boxShadow: <BoxShadow>[
          toolboxPanelShadow(
            winner ? accent : Colors.black,
            opacity: winner ? 0.20 : 0.18,
            blurRadius: winner ? 28 : 22,
            offsetY: winner ? 10 : 12,
          ),
          BoxShadow(
            color: const Color(0xFFFFE7A6).withValues(alpha: 0.38),
            blurRadius: 10,
            offset: const Offset(-3, -4),
          ),
        ],
      ),
      child: compressed
          ? CustomPaint(
              painter: _CoinEdgePainter(),
              child: const SizedBox.expand(),
            )
          : Stack(
              alignment: Alignment.center,
              children: <Widget>[
                CustomPaint(
                  painter: _CoinFacePainter(accent: accent, winner: winner),
                  child: const SizedBox(width: 108, height: 108),
                ),
                Positioned(
                  top: 18,
                  child: Text(
                    sideLabel,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF5F4016),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                Text(
                  shortLabel,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFF4E3514),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                    shadows: <Shadow>[
                      Shadow(
                        color: Colors.white.withValues(alpha: 0.42),
                        blurRadius: 4,
                        offset: const Offset(-1, -1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _CoinFacePainter extends CustomPainter {
  const _CoinFacePainter({required this.accent, required this.winner});

  final Color accent;
  final bool winner;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var ring = 0; ring < 4; ring += 1) {
      final inset = 7.0 + ring * 8.0;
      ringPaint
        ..strokeWidth = ring == 0 ? 2.0 : 1.1
        ..color = (ring.isEven ? Colors.white : const Color(0xFF8B5D22))
            .withValues(alpha: ring == 0 ? 0.56 : 0.26);
      canvas.drawCircle(center, radius - inset, ringPaint);
    }

    final tickPaint = Paint()
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF7B531F).withValues(alpha: 0.34);
    for (var tick = 0; tick < 36; tick += 1) {
      final angle = -math.pi / 2 + tick * math.pi * 2 / 36;
      final long = tick % 3 == 0;
      final outer =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius - 8);
      final inner =
          center +
          Offset(math.cos(angle), math.sin(angle)) *
              (radius - (long ? 15 : 12));
      canvas.drawLine(inner, outer, tickPaint);
    }

    if (winner) {
      canvas.drawCircle(
        center,
        radius - 14,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = accent.withValues(alpha: 0.18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CoinFacePainter oldDelegate) {
    return oldDelegate.accent != accent || oldDelegate.winner != winner;
  }
}

class _CoinEdgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.36);
    for (var index = 0; index < 8; index += 1) {
      final y = size.height * (0.12 + index * 0.11);
      canvas.drawLine(
        Offset(size.width * 0.28, y),
        Offset(size.width * 0.72, y + 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CoinEdgePainter oldDelegate) => false;
}

class _CustomRandomWheelPainter extends CustomPainter {
  _CustomRandomWheelPainter({
    required this.options,
    required this.probabilities,
    required this.accent,
    required this.rotation,
    required this.progress,
    required this.textColor,
    required this.surfaceColor,
    required this.outlineColor,
    this.winnerId,
  });

  final List<DailyChoiceCustomRandomOption> options;
  final Map<String, double> probabilities;
  final Color accent;
  final double rotation;
  final double progress;
  final String? winnerId;
  final Color textColor;
  final Color surfaceColor;
  final Color outlineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = _customRandomWheelCenter(size);
    final radius = _customRandomWheelRadius(size);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final outerRect = Rect.fromCircle(center: center, radius: radius + 18);
    final selectedReveal = winnerId == null
        ? 0.0
        : Curves.easeOutCubic.transform(
            ((progress - 0.64) / 0.36).clamp(0.0, 1.0).toDouble(),
          );

    _paintWheelBase(canvas, center, radius, outerRect);
    if (options.isEmpty) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = accent.withValues(alpha: 0.34),
      );
      return;
    }

    var start = -math.pi / 2 + rotation;
    for (var index = 0; index < options.length; index += 1) {
      final option = options[index];
      final probability = probabilities[option.id] ?? (1 / options.length);
      final sweep = math.max(0.01, math.pi * 2 * probability);
      final selected = option.id == winnerId;
      final segmentColor = _segmentColor(index, selected);
      _paintSegment(canvas, center, radius, rect, start, sweep, segmentColor);
      if (selected) {
        _paintSelectedSegment(
          canvas,
          center,
          radius,
          rect,
          start,
          sweep,
          selectedReveal,
        );
      }
      _paintSeparator(canvas, center, radius, start);
      _paintWheelLabel(
        canvas,
        option.label,
        center,
        radius,
        start + sweep / 2,
        selected,
        selectedReveal,
      );
      start += sweep;
    }

    _paintSeparator(canvas, center, radius, start);
    _paintRim(canvas, center, radius);
    _paintRivets(canvas, center, radius);
    _paintTicks(canvas, center, radius);
    _paintCenterCap(canvas, center, radius);
  }

  void _paintWheelBase(
    Canvas canvas,
    Offset center,
    double radius,
    Rect outerRect,
  ) {
    final outerRadius = radius + 18;
    canvas.drawCircle(
      center.translate(0, radius * 0.96),
      radius * 0.78,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
    canvas.drawCircle(
      center.translate(0, 10),
      outerRadius,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            _mix(surfaceColor, accent, 0.22),
            _mix(Colors.black, accent, 0.34),
          ],
          stops: const <double>[0.0, 1.0],
        ).createShader(outerRect.translate(0, 10)),
    );
    canvas.drawCircle(
      center,
      outerRadius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.38, -0.48),
          colors: <Color>[
            Colors.white.withValues(alpha: 0.98),
            _mix(surfaceColor, accent, 0.36),
            _mix(Colors.black, accent, 0.20),
          ],
          stops: const <double>[0.0, 0.58, 1.0],
        ).createShader(outerRect),
    );
    canvas.drawCircle(
      center,
      outerRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.54),
    );
    canvas.drawCircle(
      center.translate(0, 8),
      outerRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = Colors.black.withValues(alpha: 0.10),
    );
  }

  void _paintSegment(
    Canvas canvas,
    Offset center,
    double radius,
    Rect rect,
    double start,
    double sweep,
    Color segmentColor,
  ) {
    canvas.drawArc(
      rect,
      start,
      sweep,
      true,
      Paint()
        ..style = PaintingStyle.fill
        ..shader = RadialGradient(
          center: const Alignment(-0.34, -0.48),
          radius: 1.0,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.64),
            segmentColor,
            _mix(Colors.black, segmentColor, 0.18),
          ],
          stops: const <double>[0.0, 0.55, 1.0],
        ).createShader(rect),
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.82),
      start + 0.012,
      math.max(0, sweep - 0.024),
      true,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.white.withValues(alpha: 0.16),
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      start + 0.012,
      math.max(0, sweep - 0.024),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white.withValues(alpha: 0.20),
    );
  }

  void _paintSelectedSegment(
    Canvas canvas,
    Offset center,
    double radius,
    Rect rect,
    double start,
    double sweep,
    double reveal,
  ) {
    final glow = reveal.clamp(0.0, 1.0).toDouble();
    canvas.drawArc(
      rect.inflate(1.5 + glow * 2),
      start + 0.01,
      math.max(0, sweep - 0.02),
      true,
      Paint()..color = Colors.white.withValues(alpha: 0.08 + glow * 0.10),
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      start + 0.012,
      math.max(0, sweep - 0.024),
      true,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.8 + glow * 2.4
        ..color = Colors.white.withValues(alpha: 0.42 + glow * 0.34),
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius + 4),
      start + 0.012,
      math.max(0, sweep - 0.024),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2 + glow * 1.8
        ..strokeCap = StrokeCap.round
        ..color = accent.withValues(alpha: 0.34 + glow * 0.30),
    );
  }

  void _paintRim(Canvas canvas, Offset center, double radius) {
    final outer = radius + 17;
    final metalRect = Rect.fromCircle(center: center, radius: outer);
    canvas.drawCircle(
      center,
      outer - 3,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..shader = SweepGradient(
          colors: <Color>[
            Colors.white.withValues(alpha: 0.90),
            _mix(surfaceColor, accent, 0.36),
            _mix(Colors.black, accent, 0.26),
            Colors.white.withValues(alpha: 0.72),
            _mix(surfaceColor, accent, 0.36),
          ],
          stops: const <double>[0.0, 0.22, 0.52, 0.74, 1.0],
          transform: GradientRotation(rotation * 0.08),
        ).createShader(metalRect),
    );
    canvas.drawCircle(
      center,
      radius + 4,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = Colors.white.withValues(alpha: 0.80),
    );
    canvas.drawCircle(
      center.translate(0, 7),
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = Colors.black.withValues(alpha: 0.11),
    );
    canvas.drawCircle(
      center,
      radius - 10,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.30),
    );
  }

  void _paintRivets(Canvas canvas, Offset center, double radius) {
    if (options.isEmpty) {
      return;
    }
    final count = options.length <= 18 ? options.length : 18;
    for (var index = 0; index < count; index += 1) {
      final angle = -math.pi / 2 + rotation + index * math.pi * 2 / count;
      final position =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius + 10.5);
      final rivetRadius = index.isEven ? 2.8 : 2.3;
      canvas.drawCircle(
        position.translate(0, 1),
        rivetRadius + 0.5,
        Paint()..color = Colors.black.withValues(alpha: 0.18),
      );
      canvas.drawCircle(
        position,
        rivetRadius,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.42, -0.52),
            colors: <Color>[
              Colors.white,
              _mix(surfaceColor, accent, 0.46),
              _mix(Colors.black, accent, 0.24),
            ],
          ).createShader(Rect.fromCircle(center: position, radius: 4.5)),
      );
    }
  }

  void _paintTicks(Canvas canvas, Offset center, double radius) {
    final tickCount = math.max(24, options.length * 3).toInt();
    for (var tick = 0; tick < tickCount; tick += 1) {
      final angle = -math.pi / 2 + rotation + tick * math.pi * 2 / tickCount;
      final long = tick % 3 == 0;
      final p1 =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius - 2);
      final p2 =
          center +
          Offset(math.cos(angle), math.sin(angle)) * (radius - (long ? 14 : 9));
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..strokeWidth = long ? 1.5 : 0.9
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: long ? 0.50 : 0.28),
      );
    }
  }

  void _paintCenterCap(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center.translate(0, 4),
      radius * 0.25,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawCircle(
      center,
      radius * 0.26,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.5),
          colors: <Color>[
            Colors.white,
            _mix(surfaceColor, accent, 0.64),
            _mix(Colors.black, accent, 0.28),
          ],
          stops: const <double>[0.0, 0.56, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 0.27)),
    );
    canvas.drawCircle(
      center,
      radius * 0.26,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = Colors.white.withValues(alpha: 0.78),
    );
    canvas.drawCircle(
      center,
      radius * 0.14,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.42, -0.50),
          colors: <Color>[
            Colors.white.withValues(alpha: 0.96),
            _mix(surfaceColor, accent, 0.74),
            _mix(Colors.black, accent, 0.20),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius * 0.15)),
    );
    canvas.drawCircle(
      center.translate(-radius * 0.06, -radius * 0.08),
      radius * 0.038,
      Paint()..color = Colors.white.withValues(alpha: 0.82),
    );
    for (var index = 0; index < 6; index += 1) {
      final angle = -math.pi / 2 + index * math.pi * 2 / 6 + rotation * 0.12;
      final boltCenter =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius * 0.195);
      canvas.drawCircle(
        boltCenter,
        radius * 0.017,
        Paint()..color = Colors.black.withValues(alpha: 0.22),
      );
    }
  }

  Color _segmentColor(int index, bool selected) {
    final palette = <Color>[
      const Color(0xFFB84B3F),
      const Color(0xFFD9A642),
      const Color(0xFF2F7E78),
      const Color(0xFF355C9B),
      const Color(0xFF7A4FA3),
      const Color(0xFF5A7D43),
      const Color(0xFFC76B3C),
      const Color(0xFF2F719A),
    ];
    final base = palette[index % palette.length];
    return Color.lerp(
      base,
      accent,
      selected ? 0.18 : 0.04,
    )!.withValues(alpha: selected ? 0.98 : 0.90);
  }

  void _paintSeparator(
    Canvas canvas,
    Offset center,
    double radius,
    double angle,
  ) {
    final direction = Offset(math.cos(angle), math.sin(angle));
    canvas.drawLine(
      center + direction * (radius * 0.25),
      center + direction * (radius + 0.5),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.72)
        ..strokeWidth = 1.1,
    );
    canvas.drawLine(
      center + direction * (radius * 0.28),
      center + direction * (radius - 2),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.09)
        ..strokeWidth = 0.7,
    );
  }

  void _paintWheelLabel(
    Canvas canvas,
    String label,
    Offset center,
    double radius,
    double angle,
    bool selected,
    double selectedReveal,
  ) {
    final maxLength = options.length > 12 ? 6 : 8;
    final text = label.length > maxLength
        ? '${label.substring(0, maxLength)}…'
        : label;
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: selected ? 0.98 : 0.90),
          fontSize: options.length > 12 ? 10.5 : 11.5,
          fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
          letterSpacing: 0,
          shadows: <Shadow>[
            Shadow(
              color: Colors.black.withValues(alpha: 0.34),
              blurRadius: 5,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: options.length > 12 ? 58 : 78);
    final normalized = _normalizeAngle(angle);
    final flipped = normalized > math.pi / 2 && normalized < math.pi * 3 / 2;
    final labelRadius = radius * (options.length > 12 ? 0.58 : 0.62);
    final position =
        center + Offset(math.cos(angle), math.sin(angle)) * labelRadius;
    final backgroundAlpha = selected
        ? 0.20 + selectedReveal.clamp(0.0, 1.0).toDouble() * 0.08
        : 0.12;
    final labelRect = Rect.fromCenter(
      center: Offset.zero,
      width: painter.width + 14,
      height: painter.height + 7,
    );

    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(angle + (flipped ? math.pi : 0));
    canvas.drawRRect(
      RRect.fromRectAndRadius(labelRect, const Radius.circular(999)),
      Paint()..color = Colors.black.withValues(alpha: backgroundAlpha),
    );
    if (selected) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(labelRect, const Radius.circular(999)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.white.withValues(alpha: 0.42),
      );
    }
    painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
    canvas.restore();
  }

  double _normalizeAngle(double value) {
    final full = math.pi * 2;
    return ((value % full) + full) % full;
  }

  @override
  bool shouldRepaint(covariant _CustomRandomWheelPainter oldDelegate) {
    return oldDelegate.options != options ||
        oldDelegate.probabilities != probabilities ||
        oldDelegate.rotation != rotation ||
        oldDelegate.progress != progress ||
        oldDelegate.winnerId != winnerId ||
        oldDelegate.accent != accent ||
        oldDelegate.textColor != textColor ||
        oldDelegate.surfaceColor != surfaceColor ||
        oldDelegate.outlineColor != outlineColor;
  }

  Color _mix(Color a, Color b, double amount) {
    return Color.lerp(a, b, amount.clamp(0.0, 1.0).toDouble())!;
  }
}
