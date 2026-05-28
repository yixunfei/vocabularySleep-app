part of '../toolbox_life_tools.dart';

class _RulerToolPage extends StatefulWidget {
  const _RulerToolPage();

  @override
  State<_RulerToolPage> createState() => _RulerToolPageState();
}

class _RulerToolPageState extends State<_RulerToolPage> {
  static const double _standardPixelsPerCm = 160.0 / 2.54;

  double _pixelsPerCm = _standardPixelsPerCm;

  void _setPixelsPerCm(double value) {
    setState(() {
      _pixelsPerCm = value.clamp(45.0, 95.0);
    });
  }

  void _nudgePixelsPerCm(double delta) {
    _setPixelsPerCm(_pixelsPerCm + delta);
  }

  void _resetStandard() {
    _setPixelsPerCm(_standardPixelsPerCm);
  }

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: _lifeText(context, zh: '尺子和量角器', en: 'Ruler and protractor'),
      subtitle: _lifeText(
        context,
        zh: '把手机边缘当作标尺使用，支持手动校准；量角器可叠加相机背景辅助对角。',
        en: 'Use the phone edge as a ruler with manual calibration, plus a protractor over a camera background.',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _MeasurementPreviewCard(
            pixelsPerCm: _pixelsPerCm,
            onChanged: _setPixelsPerCm,
            onReset: _resetStandard,
            onNudge: _nudgePixelsPerCm,
          ),
          const SizedBox(height: 12),
          _MeasurementActionCard(
            icon: Icons.straighten_rounded,
            title: _lifeText(context, zh: '横屏直尺', en: 'Landscape ruler'),
            subtitle: _lifeText(
              context,
              zh: '进入横屏全屏后，刻度贴近屏幕长边显示，方便用手机边缘直接量长度。',
              en: 'Open a landscape fullscreen ruler with ticks pinned to the screen edge for direct length checks.',
            ),
            actionLabel: _lifeText(context, zh: '打开直尺', en: 'Open ruler'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      _RulerFullscreenPage(pixelsPerCm: _pixelsPerCm),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _MeasurementActionCard(
            icon: Icons.change_history_rounded,
            title: _lifeText(context, zh: '量角器', en: 'Protractor'),
            subtitle: _lifeText(
              context,
              zh: '打开后会请求相机权限，并把相机画面放在量角器刻度下方作为背景。',
              en: 'Requests camera access and places the live camera feed under the protractor scale.',
            ),
            actionLabel: _lifeText(context, zh: '打开量角器', en: 'Open protractor'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const _ProtractorFullscreenPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MeasurementPreviewCard extends StatelessWidget {
  const _MeasurementPreviewCard({
    required this.pixelsPerCm,
    required this.onChanged,
    required this.onReset,
    required this.onNudge,
  });

  final double pixelsPerCm;
  final ValueChanged<double> onChanged;
  final VoidCallback onReset;
  final ValueChanged<double> onNudge;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _lifeText(
                context,
                zh: '校准参数：${pixelsPerCm.toStringAsFixed(1)} px/cm',
                en: 'Calibration: ${pixelsPerCm.toStringAsFixed(1)} px/cm',
              ),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Text(
              _lifeText(
                context,
                zh: '先看下方 1 cm 参考条是否接近真实长度，不准时可滑动微调，再重置回系统基线。',
                en: 'Check whether the 1 cm reference below matches reality, then fine tune or reset back to the default baseline.',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 64,
              child: CustomPaint(
                painter: _CalibrationPreviewPainter(pixelsPerCm: pixelsPerCm),
                child: const SizedBox.expand(),
              ),
            ),
            Slider(
              value: pixelsPerCm,
              min: 45.0,
              max: 95.0,
              divisions: 500,
              label: pixelsPerCm.toStringAsFixed(1),
              onChanged: onChanged,
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                FilledButton.tonal(
                  onPressed: () => onNudge(-0.5),
                  child: Text(
                    _lifeText(context, zh: '微调 -0.5', en: 'Fine tune -0.5'),
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () => onNudge(0.5),
                  child: Text(
                    _lifeText(context, zh: '微调 +0.5', en: 'Fine tune +0.5'),
                  ),
                ),
                FilledButton.tonal(
                  onPressed: onReset,
                  child: Text(
                    _lifeText(context, zh: '重置标准', en: 'Reset standard'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MeasurementActionCard extends StatelessWidget {
  const _MeasurementActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            FilledButton(onPressed: onPressed, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class _CalibrationPreviewPainter extends CustomPainter {
  const _CalibrationPreviewPainter({required this.pixelsPerCm});

  final double pixelsPerCm;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final backgroundPaint = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[Color(0xFF152235), Color(0xFF0A1018)],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      backgroundPaint,
    );

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..strokeWidth = 2;
    final minorPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.68)
      ..strokeWidth = 1;
    final startX = 16.0;
    final baselineY = size.height * 0.42;
    final tickSpacing = pixelsPerCm / 10;
    final marks = math.max(
      10,
      ((size.width - startX * 2) / tickSpacing).floor(),
    );

    canvas.drawLine(
      Offset(startX, baselineY),
      Offset(startX + tickSpacing * marks, baselineY),
      linePaint,
    );
    for (var i = 0; i <= marks; i += 1) {
      final x = startX + i * tickSpacing;
      final isCm = i % 10 == 0;
      final isHalf = i % 5 == 0;
      final tick = isCm ? 22.0 : (isHalf ? 15.0 : 10.0);
      canvas.drawLine(
        Offset(x, baselineY),
        Offset(x, baselineY + tick),
        isCm ? linePaint : minorPaint,
      );
    }

    final label =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(fontSize: 12, textAlign: TextAlign.left),
          )
          ..pushStyle(
            const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ).getTextStyle(),
          )
          ..addText('1 cm');
    final paragraph = label.build()
      ..layout(const ui.ParagraphConstraints(width: 64));
    canvas.drawParagraph(paragraph, Offset(startX, baselineY + 28));
  }

  @override
  bool shouldRepaint(covariant _CalibrationPreviewPainter oldDelegate) {
    return oldDelegate.pixelsPerCm != pixelsPerCm;
  }
}

class _RulerFullscreenPage extends StatefulWidget {
  const _RulerFullscreenPage({required this.pixelsPerCm});

  final double pixelsPerCm;

  @override
  State<_RulerFullscreenPage> createState() => _RulerFullscreenPageState();
}

class _RulerFullscreenPageState extends State<_RulerFullscreenPage> {
  @override
  void initState() {
    super.initState();
    _enterLifeLandscapeImmersive();
  }

  @override
  void dispose() {
    _exitLifeImmersive();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: CustomPaint(
              painter: _EdgeRulerPainter(pixelsPerCm: widget.pixelsPerCm),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: IconButton.filledTonal(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProtractorFullscreenPage extends StatefulWidget {
  const _ProtractorFullscreenPage();

  @override
  State<_ProtractorFullscreenPage> createState() =>
      _ProtractorFullscreenPageState();
}

class _ProtractorFullscreenPageState extends State<_ProtractorFullscreenPage> {
  CameraController? _controller;
  String? _statusText;
  bool _loadingCamera = true;

  @override
  void initState() {
    super.initState();
    _enterLifeLandscapeImmersive();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _exitLifeImmersive();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (!mounted) {
        return;
      }
      if (cameras.isEmpty) {
        setState(() {
          _statusText = _lifeText(
            context,
            zh: '没有找到可用相机，仍可使用纯刻度量角器。',
            en: 'No camera was found. You can still use the protractor scale.',
          );
          _loadingCamera = false;
        });
        return;
      }

      final camera = cameras.firstWhere(
        (item) => item.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _statusText = null;
        _loadingCamera = false;
      });
    } on CameraException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _statusText = switch (error.code) {
          'CameraAccessDenied' => _lifeText(
            context,
            zh: '相机权限被拒绝，请在系统设置中开启后再试。',
            en: 'Camera access was denied. Please enable it in system settings and try again.',
          ),
          'CameraAccessDeniedWithoutPrompt' => _lifeText(
            context,
            zh: '系统已禁止再次弹出相机授权，请手动去设置开启。',
            en: 'The system will not prompt again. Please enable camera access in settings.',
          ),
          _ => _lifeText(
            context,
            zh: '相机初始化失败，已降级为纯刻度量角器。',
            en: 'Camera initialization failed. Falling back to the protractor overlay only.',
          ),
        };
        _loadingCamera = false;
      });
    } on MissingPluginException {
      if (!mounted) {
        return;
      }
      setState(() {
        _statusText = _lifeText(
          context,
          zh: '当前平台不支持相机插件，已使用静态背景。',
          en: 'This platform does not support the camera plugin, so a static background is used.',
        );
        _loadingCamera = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _statusText = _lifeText(
          context,
          zh: '量角器背景启动失败，已保留刻度层。',
          en: 'The protractor background failed to start, but the scale overlay is still available.',
        );
        _loadingCamera = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (controller != null && controller.value.isInitialized)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.previewSize?.height ?? 1,
                height: controller.value.previewSize?.width ?? 1,
                child: CameraPreview(controller),
              ),
            )
          else
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: <Color>[Color(0xFF2A3445), Color(0xFF05070B)],
                  radius: 1.25,
                ),
              ),
            ),
          Container(color: Colors.black.withValues(alpha: 0.26)),
          const Positioned.fill(
            child: CustomPaint(painter: _ProtractorPainter()),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (_loadingCamera)
                    _StatusPill(
                      icon: Icons.hourglass_top_rounded,
                      label: _lifeText(
                        context,
                        zh: '正在请求相机权限',
                        en: 'Requesting camera access',
                      ),
                    )
                  else if (_statusText != null)
                    Expanded(
                      child: _StatusPill(
                        icon: Icons.warning_amber_rounded,
                        label: _statusText!,
                      ),
                    )
                  else
                    _StatusPill(
                      icon: Icons.camera_alt_rounded,
                      label: _lifeText(
                        context,
                        zh: '相机背景已开启',
                        en: 'Camera background active',
                      ),
                    ),
                  const Spacer(),
                  IconButton.filledTonal(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EdgeRulerPainter extends CustomPainter {
  const _EdgeRulerPainter({required this.pixelsPerCm});

  final double pixelsPerCm;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..strokeWidth = 2;
    final minorPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.72)
      ..strokeWidth = 1;
    final topBandPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color(0xD90B0F16),
          Color(0x600B0F16),
          Color(0x000B0F16),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 110));
    final baselineY = 24.0;
    final tickSpacing = pixelsPerCm / 10;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 110), topBandPaint);
    canvas.drawLine(
      Offset(0, baselineY),
      Offset(size.width, baselineY),
      linePaint,
    );

    for (var i = 0; i <= (size.width / tickSpacing).ceil(); i += 1) {
      final x = i * tickSpacing;
      if (x > size.width) {
        break;
      }
      final isCm = i % 10 == 0;
      final isHalf = i % 5 == 0;
      final tickHeight = isCm ? 34.0 : (isHalf ? 24.0 : 14.0);
      canvas.drawLine(
        Offset(x, baselineY),
        Offset(x, baselineY + tickHeight),
        isCm ? linePaint : minorPaint,
      );

      if (isCm) {
        final label =
            ui.ParagraphBuilder(
                ui.ParagraphStyle(fontSize: 12, textAlign: TextAlign.center),
              )
              ..pushStyle(
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ).getTextStyle(),
              )
              ..addText('${i ~/ 10}');
        final paragraph = label.build()
          ..layout(const ui.ParagraphConstraints(width: 36));
        canvas.drawParagraph(paragraph, Offset(x - 18, baselineY + 38));
      }
    }

    final footer =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(fontSize: 11, textAlign: TextAlign.right),
          )
          ..pushStyle(
            const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ).getTextStyle(),
          )
          ..addText('${(size.width / pixelsPerCm).toStringAsFixed(1)} cm');
    final footerParagraph = footer.build()
      ..layout(ui.ParagraphConstraints(width: size.width - 24));
    canvas.drawParagraph(footerParagraph, Offset(12, size.height - 28));
  }

  @override
  bool shouldRepaint(covariant _EdgeRulerPainter oldDelegate) {
    return oldDelegate.pixelsPerCm != pixelsPerCm;
  }
}

class _ProtractorPainter extends CustomPainter {
  const _ProtractorPainter();

  static const Color _plateDark = Color(0xE60B1220);
  static const Color _plateMid = Color(0xAA142033);
  static const Color _plateEdge = Color(0x221E293B);
  static const Color _outlineColor = Color(0xE6050A12);
  static const Color _majorColor = Color(0xFFFFD166);
  static const Color _minorColor = Color(0xFFE0E7FF);
  static const Color _guideColor = Color(0xFF7DD3FC);

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = _majorColor.withValues(alpha: 0.98)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final guidePaint = Paint()
      ..color = _guideColor.withValues(alpha: 0.94)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final minorPaint = Paint()
      ..color = _minorColor.withValues(alpha: 0.82)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final center = Offset(size.width * 0.5, size.height * 0.87);
    final radius = math.min(size.width * 0.44, size.height * 0.72);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final plateRadius = radius + 34;
    final plateRect = Rect.fromCircle(center: center, radius: plateRadius);

    final platePaint = Paint()
      ..shader = const RadialGradient(
        colors: <Color>[_plateDark, _plateMid, _plateEdge],
        stops: <double>[0.0, 0.74, 1.0],
      ).createShader(plateRect);

    canvas.drawCircle(center, plateRadius, platePaint);
    canvas.drawCircle(
      center,
      radius + 25,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.16),
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 32),
      math.pi,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = _guideColor.withValues(alpha: 0.38),
    );
    _drawOutlinedArc(canvas, rect, math.pi, math.pi, linePaint);
    _drawOutlinedLine(
      canvas,
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      linePaint,
    );
    _drawOutlinedLine(
      canvas,
      center,
      Offset(center.dx, center.dy - radius + 10),
      guidePaint,
    );

    for (var degree = 0; degree <= 180; degree += 2) {
      final rad = degree * math.pi / 180;
      final isMajor = degree % 10 == 0;
      final isMid = degree % 5 == 0;
      final tick = isMajor ? 24.0 : (isMid ? 16.0 : 9.0);
      final outerX = center.dx + radius * math.cos(math.pi - rad);
      final outerY = center.dy - radius * math.sin(math.pi - rad);
      final innerX = center.dx + (radius - tick) * math.cos(math.pi - rad);
      final innerY = center.dy - (radius - tick) * math.sin(math.pi - rad);
      _drawOutlinedLine(
        canvas,
        Offset(outerX, outerY),
        Offset(innerX, innerY),
        isMajor ? linePaint : minorPaint,
        outlineExtra: isMajor ? 3.4 : 2.4,
      );

      if (isMajor) {
        final labelX = center.dx + (radius - 36) * math.cos(math.pi - rad);
        final labelY = center.dy - (radius - 36) * math.sin(math.pi - rad);
        _drawDegreeLabel(canvas, '$degree', Offset(labelX - 17, labelY - 8));
      }
    }

    canvas.drawCircle(center, 7, Paint()..color = _outlineColor);
    canvas.drawCircle(
      center,
      4,
      Paint()..color = _majorColor.withValues(alpha: 0.98),
    );
  }

  void _drawOutlinedArc(
    Canvas canvas,
    Rect rect,
    double startAngle,
    double sweepAngle,
    Paint paint,
  ) {
    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = _outlineColor
        ..strokeWidth = paint.strokeWidth + 3.8
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  void _drawOutlinedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    double outlineExtra = 3.0,
  }) {
    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = _outlineColor
        ..strokeWidth = paint.strokeWidth + outlineExtra
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(start, end, paint);
  }

  void _drawDegreeLabel(Canvas canvas, String text, Offset offset) {
    final shadow =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(fontSize: 11, textAlign: TextAlign.center),
          )
          ..pushStyle(
            const TextStyle(
              color: _outlineColor,
              fontWeight: FontWeight.w900,
            ).getTextStyle(),
          )
          ..addText(text);
    final shadowParagraph = shadow.build()
      ..layout(const ui.ParagraphConstraints(width: 34));
    canvas.drawParagraph(shadowParagraph, offset + const Offset(1.2, 1.2));

    final label =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(fontSize: 11, textAlign: TextAlign.center),
          )
          ..pushStyle(
            const TextStyle(
              color: _majorColor,
              fontWeight: FontWeight.w800,
            ).getTextStyle(),
          )
          ..addText(text);
    final paragraph = label.build()
      ..layout(const ui.ParagraphConstraints(width: 34));
    canvas.drawParagraph(paragraph, offset);
  }

  @override
  bool shouldRepaint(covariant _ProtractorPainter oldDelegate) {
    return false;
  }
}
