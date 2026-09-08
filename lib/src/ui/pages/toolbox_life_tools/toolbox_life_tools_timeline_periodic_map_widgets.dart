part of '../toolbox_life_tools.dart';

class _TimelineMapStage extends StatelessWidget {
  const _TimelineMapStage({
    required this.facts,
    required this.window,
    required this.selected,
    required this.controller,
    required this.onSelected,
    required this.onReset,
    required this.onFullscreen,
    this.showFullscreen = true,
  });

  final List<_TimelineFact> facts;
  final _TimelineWindow window;
  final _TimelineFact selected;
  final TransformationController controller;
  final ValueChanged<_TimelineFact> onSelected;
  final VoidCallback onReset;
  final VoidCallback onFullscreen;
  final bool showFullscreen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.max(
          constraints.maxWidth * 3.4,
          window.id == 'all' ? 2200.0 : 1500.0,
        );
        return Container(
          key: const ValueKey<String>('history-timeline-stage'),
          height: 520,
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.32,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: InteractiveViewer(
                  transformationController: controller,
                  constrained: false,
                  minScale: 0.5,
                  maxScale: 4,
                  boundaryMargin: const EdgeInsets.symmetric(
                    horizontal: 500,
                    vertical: 120,
                  ),
                  child: SizedBox(
                    width: width,
                    height: 520,
                    child: _TimelineMapCanvas(
                      facts: facts,
                      window: window,
                      selected: selected,
                      onSelected: onSelected,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (showFullscreen) ...<Widget>[
                      IconButton.filledTonal(
                        tooltip: _lifeI18nText(
                          context,
                          'toolbox.life.timeline.fullscreen',
                        ),
                        onPressed: onFullscreen,
                        icon: const Icon(Icons.fullscreen_rounded),
                      ),
                      const SizedBox(width: 8),
                    ],
                    IconButton.filledTonal(
                      tooltip: _lifeI18nText(
                        context,
                        'toolbox.life.timeline.reset_view',
                      ),
                      onPressed: onReset,
                      icon: const Icon(Icons.center_focus_strong_rounded),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TimelineMapCanvas extends StatelessWidget {
  const _TimelineMapCanvas({
    required this.facts,
    required this.window,
    required this.selected,
    required this.onSelected,
  });

  final List<_TimelineFact> facts;
  final _TimelineWindow window;
  final _TimelineFact selected;
  final ValueChanged<_TimelineFact> onSelected;

  @override
  Widget build(BuildContext context) {
    const leftPad = 92.0;
    const rightPad = 118.0;
    const topPad = 42.0;
    const laneHeight = 66.0;
    const markerWidth = 164.0;
    final lanes = _timelineLanes;
    final labels = lanes
        .map((category) => _timelineCategoryLabel(context, category))
        .toList(growable: false);
    return LayoutBuilder(
      builder: (context, constraints) {
        final usableWidth = math.max(
          1.0,
          constraints.maxWidth - leftPad - rightPad,
        );
        return Stack(
          children: <Widget>[
            Positioned.fill(
              child: CustomPaint(
                painter: _TimelineAxisPainter(
                  window: window,
                  labels: labels,
                  leftPad: leftPad,
                  rightPad: rightPad,
                  topPad: topPad,
                  laneHeight: laneHeight,
                  textColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  lineColor: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            for (final fact in facts)
              Positioned(
                left:
                    (leftPad +
                            _timelineX(
                              fact.yearsBeforePresent,
                              window,
                              usableWidth,
                            ) -
                            markerWidth / 2)
                        .clamp(8.0, constraints.maxWidth - markerWidth - 8),
                top:
                    topPad +
                    math.max(0, lanes.indexOf(fact.category)) * laneHeight +
                    4,
                width: markerWidth,
                child: _TimelineMarker(
                  fact: fact,
                  selected:
                      _timelineFactKey(fact) == _timelineFactKey(selected),
                  onTap: () => onSelected(fact),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TimelineAxisPainter extends CustomPainter {
  const _TimelineAxisPainter({
    required this.window,
    required this.labels,
    required this.leftPad,
    required this.rightPad,
    required this.topPad,
    required this.laneHeight,
    required this.textColor,
    required this.lineColor,
  });

  final _TimelineWindow window;
  final List<String> labels;
  final double leftPad;
  final double rightPad;
  final double topPad;
  final double laneHeight;
  final Color textColor;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    final usableWidth = math.max(1.0, size.width - leftPad - rightPad);
    final axisY = topPad + labels.length * laneHeight + 20;
    for (var index = 0; index < labels.length; index += 1) {
      final y = topPad + index * laneHeight + 24;
      canvas.drawLine(
        Offset(leftPad, y),
        Offset(size.width - rightPad, y),
        paint,
      );
      _paintText(canvas, labels[index], Offset(12, y - 8), 11, 76);
    }
    canvas.drawLine(
      Offset(leftPad, axisY),
      Offset(size.width - rightPad, axisY),
      paint..strokeWidth = 1.4,
    );
    for (final tick in _timelineTicks(window)) {
      final x = leftPad + _timelineX(tick, window, usableWidth);
      canvas.drawLine(Offset(x, axisY - 6), Offset(x, axisY + 6), paint);
      _paintText(
        canvas,
        _compactYearsBeforePresent(tick),
        Offset(x - 26, axisY + 12),
        10,
        70,
      );
    }
  }

  void _paintText(
    Canvas canvas,
    String value,
    Offset offset,
    double fontSize,
    double maxWidth,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _TimelineAxisPainter oldDelegate) {
    return oldDelegate.window.id != window.id ||
        oldDelegate.labels != labels ||
        oldDelegate.textColor != textColor ||
        oldDelegate.lineColor != lineColor;
  }
}

class _TimelineMarker extends StatelessWidget {
  const _TimelineMarker({
    required this.fact,
    required this.selected,
    required this.onTap,
  });

  final _TimelineFact fact;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _timelineCategoryColor(fact.category);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
          decoration: BoxDecoration(
            color: Color.lerp(
              theme.colorScheme.surface,
              color,
              selected ? 0.2 : 0.08,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : color.withValues(alpha: 0.4),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                _lifeI18nText(context, fact.displayKey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _lifeI18nText(context, fact.titleKey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineImmersivePage extends StatefulWidget {
  const _TimelineImmersivePage({
    required this.facts,
    required this.initialSelected,
    required this.initialMode,
    required this.rangeLabel,
  });

  final List<_TimelineFact> facts;
  final _TimelineFact initialSelected;
  final String initialMode;
  final String rangeLabel;

  @override
  State<_TimelineImmersivePage> createState() => _TimelineImmersivePageState();
}

class _TimelineImmersivePageState extends State<_TimelineImmersivePage> {
  late _TimelineFact _selected;
  late String _mode;
  final TransformationController _controller = TransformationController();

  @override
  void initState() {
    super.initState();
    _selected =
        widget.facts.any(
          (fact) =>
              _timelineFactKey(fact) ==
              _timelineFactKey(widget.initialSelected),
        )
        ? widget.initialSelected
        : widget.facts.first;
    _mode = widget.initialMode == 'map' ? 'map' : 'story';
    unawaited(
      _enterLifeImmersive(orientations: _lifeAllOrientations, brightness: 0.9),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    unawaited(_exitLifeImmersive());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark(useMaterial3: true),
      child: Scaffold(
        key: const ValueKey<String>('timeline-immersive-page'),
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 10, 10),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _lifeI18nText(
                              context,
                              'toolbox.life.timeline.overview_title',
                            ),
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _lifeI18nText(
                              context,
                              'toolbox.life.timeline.results',
                              params: <String, Object?>{
                                'count': widget.facts.length,
                              },
                            ),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.72),
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      key: const ValueKey<String>('timeline-immersive-close'),
                      tooltip: _lifeI18nText(
                        context,
                        'toolbox.life.timeline.reset_view',
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_fullscreen_rounded),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SegmentedButton<String>(
                  segments: <ButtonSegment<String>>[
                    ButtonSegment<String>(
                      value: 'story',
                      label: Text(
                        _lifeI18nText(
                          context,
                          'toolbox.life.timeline.story_mode',
                        ),
                      ),
                      icon: const Icon(Icons.view_agenda_outlined),
                    ),
                    ButtonSegment<String>(
                      value: 'map',
                      label: Text(
                        _lifeI18nText(
                          context,
                          'toolbox.life.timeline.map_mode',
                        ),
                      ),
                      icon: const Icon(Icons.timeline_outlined),
                    ),
                  ],
                  selected: <String>{_mode},
                  onSelectionChanged: (value) =>
                      setState(() => _mode = value.first),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  child: _mode == 'story'
                      ? _TimelineStoryStage(
                          facts: widget.facts,
                          selected: _selected,
                          immersive: true,
                          onSelected: (fact) =>
                              setState(() => _selected = fact),
                        )
                      : _TimelineMapStage(
                          facts: widget.facts,
                          window: _timelineWindow('all'),
                          selected: _selected,
                          controller: _controller,
                          onSelected: (fact) =>
                              setState(() => _selected = fact),
                          onReset: () => _controller.value = Matrix4.identity(),
                          onFullscreen: () {},
                          showFullscreen: false,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
