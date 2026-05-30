part of 'toolbox_human_tests.dart';

enum _DragTrackDifficulty { gentle, standard, expert }

class FineDragTrackingTestPage extends StatelessWidget {
  const FineDragTrackingTestPage({super.key});

  static const Color _accent = Color(0xFF4E8B6B);

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanTestScaffold(
      title: i18n.t(
        'inline.ui.pages.toolbox_human_tests_drag_tracking.fine_drag_tracking_85aebd',
      ),
      subtitle: i18n.t(
        'inline.ui.pages.toolbox_human_tests_drag_tracking.drag_a_cursor_along_a_narrow_track_for_fine_movement_con_b64547',
      ),
      accent: _accent,
      icon: Icons.gesture_rounded,
      status: i18n.t(
        'inline.ui.pages.toolbox_human_tests_drag_tracking.next_hold_the_start_point_and_drag_along_the_track_008c1d',
      ),
      child: const _FineDragTrackingCard(),
    );
  }
}

class _DragTrackProjection {
  const _DragTrackProjection({
    required this.distance,
    required this.progress,
    required this.nearest,
  });

  final double distance;
  final double progress;
  final Offset nearest;
}

class _DragTrackRecord {
  const _DragTrackRecord({
    required this.milliseconds,
    required this.offTrackEvents,
    required this.averageDeviation,
    required this.maxDeviation,
    required this.difficulty,
  });

  final int milliseconds;
  final int offTrackEvents;
  final double averageDeviation;
  final double maxDeviation;
  final _DragTrackDifficulty difficulty;
}

class _FineDragTrackingCard extends StatefulWidget {
  const _FineDragTrackingCard();

  @override
  State<_FineDragTrackingCard> createState() => _FineDragTrackingCardState();
}

class _FineDragTrackingCardState extends State<_FineDragTrackingCard> {
  static const Color _accent = FineDragTrackingTestPage._accent;

  final math.Random _random = math.Random();
  final Stopwatch _stopwatch = Stopwatch();
  final List<_DragTrackRecord> _records = <_DragTrackRecord>[];
  Timer? _transitionTimer;

  _DragTrackDifficulty _difficulty = _DragTrackDifficulty.standard;
  int _roundCount = 4;
  double _trackWidth = 28;
  int _roundIndex = 0;
  int _offTrackInRound = 0;
  int _samples = 0;
  double _deviationSum = 0;
  double _maxDeviation = 0;
  double _progress = 0;
  bool _running = false;
  bool _roundComplete = false;
  bool _wasOffTrack = false;
  List<Offset> _path = const <Offset>[];
  Offset _cursor = const Offset(0.08, 0.5);

  int get _completed => _records.length;

  int get _averageDeviation {
    if (_samples == 0) {
      return 0;
    }
    return (_deviationSum / _samples).round();
  }

  int get _sessionAverageDeviation {
    if (_records.isEmpty) {
      return 0;
    }
    final total = _records.fold<double>(
      0,
      (sum, item) => sum + item.averageDeviation,
    );
    return (total / _records.length).round();
  }

  int get _bestMs {
    if (_records.isEmpty) {
      return 0;
    }
    return _records
        .map((item) => item.milliseconds)
        .reduce((a, b) => math.min(a, b));
  }

  @override
  void initState() {
    super.initState();
    _path = _generatePath();
    _cursor = _path.first;
  }

  @override
  void dispose() {
    _transitionTimer?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    super.dispose();
  }

  List<Offset> _generatePath() {
    final nodeCount = switch (_difficulty) {
      _DragTrackDifficulty.gentle => 5,
      _DragTrackDifficulty.standard => 7,
      _DragTrackDifficulty.expert => 9,
    };
    final amplitude = switch (_difficulty) {
      _DragTrackDifficulty.gentle => 0.16,
      _DragTrackDifficulty.standard => 0.26,
      _DragTrackDifficulty.expert => 0.34,
    };
    final phase = _random.nextDouble() * math.pi * 2;
    return List<Offset>.generate(nodeCount, (index) {
      final t = index / (nodeCount - 1);
      final x = 0.08 + t * 0.84;
      final y = index == 0 || index == nodeCount - 1
          ? 0.5
          : (0.5 +
                    math.sin(phase + t * math.pi * 2.6) * amplitude * 0.65 +
                    (_random.nextDouble() - 0.5) * amplitude)
                .clamp(0.18, 0.82)
                .toDouble();
      return Offset(x, y);
    }, growable: false);
  }

  void _start() {
    _transitionTimer?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    setState(() {
      _records.clear();
      _roundIndex = 0;
      _running = true;
    });
    _beginRound();
  }

  void _reset() {
    _transitionTimer?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    setState(() {
      _records.clear();
      _roundIndex = 0;
      _running = false;
      _roundComplete = false;
      _progress = 0;
      _offTrackInRound = 0;
      _samples = 0;
      _deviationSum = 0;
      _maxDeviation = 0;
      _path = _generatePath();
      _cursor = _path.first;
    });
  }

  void _beginRound() {
    if (!mounted || !_running) {
      return;
    }
    if (_roundIndex >= _roundCount) {
      _finish();
      return;
    }
    setState(() {
      _path = _generatePath();
      _cursor = _path.first;
      _progress = 0;
      _offTrackInRound = 0;
      _samples = 0;
      _deviationSum = 0;
      _maxDeviation = 0;
      _wasOffTrack = false;
      _roundComplete = false;
      _stopwatch
        ..reset()
        ..start();
    });
  }

  void _handlePointer(Offset localPosition, Size size) {
    if (!_running || _roundComplete || size.width <= 0 || size.height <= 0) {
      return;
    }
    final points = _scaledPath(size);
    final projection = _projectToPath(localPosition, points);
    final offTrack = projection.distance > _trackWidth * 0.55;
    setState(() {
      _cursor = Offset(
        (localPosition.dx / size.width).clamp(0.0, 1.0).toDouble(),
        (localPosition.dy / size.height).clamp(0.0, 1.0).toDouble(),
      );
      _samples += 1;
      _deviationSum += projection.distance;
      _maxDeviation = math.max(_maxDeviation, projection.distance);
      if (offTrack && !_wasOffTrack) {
        _offTrackInRound += 1;
      }
      _wasOffTrack = offTrack;
      if (!offTrack) {
        _progress = math.max(_progress, projection.progress);
      }
    });
    if (!offTrack && _progress >= 0.985) {
      _completeRound();
    }
  }

  void _completeRound() {
    if (_roundComplete) {
      return;
    }
    _stopwatch.stop();
    final averageDeviation = _samples == 0 ? 0.0 : _deviationSum / _samples;
    setState(() {
      _roundComplete = true;
      _roundIndex += 1;
      _records.add(
        _DragTrackRecord(
          milliseconds: math.max(1, _stopwatch.elapsedMilliseconds),
          offTrackEvents: _offTrackInRound,
          averageDeviation: averageDeviation,
          maxDeviation: _maxDeviation,
          difficulty: _difficulty,
        ),
      );
    });
    _transitionTimer?.cancel();
    _transitionTimer = Timer(const Duration(milliseconds: 720), _beginRound);
  }

  void _finish() {
    _transitionTimer?.cancel();
    _stopwatch
      ..stop()
      ..reset();
    setState(() {
      _running = false;
      _roundComplete = true;
    });
    unawaited(_showReport());
  }

  List<Offset> _scaledPath(Size size) {
    return _path
        .map((point) => Offset(point.dx * size.width, point.dy * size.height))
        .toList(growable: false);
  }

  _DragTrackProjection _projectToPath(Offset point, List<Offset> points) {
    var totalLength = 0.0;
    for (var index = 0; index < points.length - 1; index += 1) {
      totalLength += (points[index + 1] - points[index]).distance;
    }
    var traversed = 0.0;
    var bestDistance = double.infinity;
    var bestProgress = 0.0;
    var bestPoint = points.first;
    for (var index = 0; index < points.length - 1; index += 1) {
      final a = points[index];
      final b = points[index + 1];
      final segment = b - a;
      final segmentLength = segment.distance;
      if (segmentLength <= 0) {
        continue;
      }
      final t =
          (((point - a).dx * segment.dx + (point - a).dy * segment.dy) /
                  (segmentLength * segmentLength))
              .clamp(0.0, 1.0)
              .toDouble();
      final projected = a + segment * t;
      final distance = (point - projected).distance;
      if (distance < bestDistance) {
        bestDistance = distance;
        bestProgress = totalLength <= 0
            ? 0
            : ((traversed + segmentLength * t) / totalLength)
                  .clamp(0.0, 1.0)
                  .toDouble();
        bestPoint = projected;
      }
      traversed += segmentLength;
    }
    return _DragTrackProjection(
      distance: bestDistance,
      progress: bestProgress,
      nearest: bestPoint,
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _HumanMetricWrap(
          metrics: <(String, String)>[
            (i18n.t('progress'), '$_completed/$_roundCount'),
            (
              i18n.t('toolbox.sleep.assist.track'),
              '${(_progress * 100).round()}%',
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_drag_tracking.avg_deviation_74a634',
              ),
              _samples == 0 ? '-' : '${_averageDeviation}px',
            ),
            (
              i18n.t(
                'inline.ui.pages.toolbox_human_tests_drag_tracking.off_track_0fff30',
              ),
              '$_offTrackInRound',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _HumanSettingsSection(
          title: i18n.t(
            'inline.ui.pages.toolbox_human_tests_drag_tracking.drag_settings_9539df',
          ),
          subtitle: i18n.t(
            'inline.ui.pages.toolbox_human_tests_drag_tracking.adjust_track_complexity_width_and_round_count_48debf',
          ),
          child: _buildSettings(context, i18n),
        ),
        const SizedBox(height: 12),
        _HumanPanel(child: _buildStage(context, i18n)),
      ],
    );
  }

  Widget _buildStage(BuildContext context, AppI18n i18n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            _HumanActionButton(
              label: _running
                  ? i18n.t(
                      'inline.ui.pages.practice_session_page.restart_8b7fcc',
                    )
                  : i18n.t('toolbox.breathing.start'),
              icon: _running ? Icons.replay_rounded : Icons.play_arrow_rounded,
              onPressed: _start,
            ),
            OutlinedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(i18n.t('appearanceReset')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _running
              ? i18n.t(
                  'inline.ui.pages.toolbox_human_tests_drag_tracking.drag_the_cursor_along_the_path_leaving_the_track_is_reco_1c60d0',
                )
              : i18n.t(
                  'inline.ui.pages.toolbox_human_tests_drag_tracking.after_starting_drag_from_the_left_start_point_to_the_rig_7c7f58',
                ),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 1.62,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              return _HumanPointerDragBoundary(
                onPointerDown: (event) =>
                    _handlePointer(event.localPosition, size),
                onPointerMove: (event) =>
                    _handlePointer(event.localPosition, size),
                child: CustomPaint(
                  key: const ValueKey<String>('fine-drag-track-stage'),
                  painter: _DragTrackPainter(
                    path: _path,
                    cursor: _cursor,
                    progress: _progress,
                    trackWidth: _trackWidth,
                    accent: _accent,
                    offTrack: _wasOffTrack,
                    surface: Theme.of(context).colorScheme.surface,
                    outline: Theme.of(context).colorScheme.outlineVariant,
                    error: Theme.of(context).colorScheme.error,
                  ),
                  child: const SizedBox.expand(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSettings(BuildContext context, AppI18n i18n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          i18n.t(
            'inline.ui.pages.toolbox_human_tests_bimanual.difficulty_0f6c2f',
          ),
        ),
        Wrap(
          spacing: 8,
          children: _DragTrackDifficulty.values
              .map((difficulty) {
                return ChoiceChip(
                  label: Text(_difficultyLabel(i18n, difficulty)),
                  selected: _difficulty == difficulty,
                  onSelected: _running
                      ? null
                      : (_) {
                          setState(() {
                            _difficulty = difficulty;
                            _path = _generatePath();
                            _cursor = _path.first;
                          });
                        },
                );
              })
              .toList(growable: false),
        ),
        const SizedBox(height: 12),
        Text(
          i18n.t(
            'inline.ui.pages.toolbox_human_tests_drag_tracking.track_width_7cdc94',
          ),
        ),
        Slider(
          value: _trackWidth,
          min: 18,
          max: 38,
          divisions: 10,
          label: '${_trackWidth.round()} px',
          onChanged: _running
              ? null
              : (value) => setState(() => _trackWidth = value),
        ),
        const SizedBox(height: 12),
        Text(i18n.t('inline.plan294.breathing.rounds_06b0afec')),
        Wrap(
          spacing: 8,
          children: <int>[3, 4, 5, 6]
              .map(
                (value) => ChoiceChip(
                  label: Text('$value'),
                  selected: _roundCount == value,
                  onSelected: _running
                      ? null
                      : (_) => setState(() => _roundCount = value),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }

  String _difficultyLabel(AppI18n i18n, _DragTrackDifficulty difficulty) {
    return switch (difficulty) {
      _DragTrackDifficulty.gentle => i18n.t(
        'inline.plan295.breathing.gentle.26bb0cd9fc59',
      ),
      _DragTrackDifficulty.standard => i18n.t(
        'inline.ui.pages.toolbox_human_tests_bimanual.standard_b9acb5',
      ),
      _DragTrackDifficulty.expert => i18n.t(
        'inline.ui.pages.toolbox_human_tests_bimanual.expert_35af53',
      ),
    };
  }

  Future<void> _showReport() async {
    if (!mounted || _records.isEmpty) {
      return;
    }
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            i18n.t(
              'inline.ui.pages.toolbox_human_tests_drag_tracking.drag_tracking_report_1c3873',
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _HumanMetricWrap(
                  metrics: <(String, String)>[
                    (
                      i18n.t('toolbox.sleep.rhythm.completed'),
                      '${_records.length}/$_roundCount',
                    ),
                    (
                      i18n.t(
                        'inline.ui.pages.toolbox_human_tests_drag_tracking.best_time_1330b3',
                      ),
                      _formatMilliseconds(_bestMs),
                    ),
                    (
                      i18n.t(
                        'inline.ui.pages.toolbox_human_tests_drag_tracking.avg_deviation_74a634',
                      ),
                      '${_sessionAverageDeviation}px',
                    ),
                    (
                      i18n.t(
                        'inline.ui.pages.toolbox_human_tests_drag_tracking.off_track_total_1a308f',
                      ),
                      '${_records.fold<int>(0, (sum, item) => sum + item.offTrackEvents)}',
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _HumanPanel(
                  child: Text(
                    _sessionAverageDeviation <= _trackWidth * 0.35
                        ? i18n.t(
                            'inline.ui.pages.toolbox_human_tests_drag_tracking.control_is_stable_try_a_narrower_track_or_higher_difficu_315e7f',
                          )
                        : i18n.t(
                            'inline.ui.pages.toolbox_human_tests_drag_tracking.lower_the_difficulty_and_focus_on_slow_continuous_moveme_c03585',
                          ),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(i18n.t('inline.plan295.life.close.370fb8697deb')),
            ),
          ],
        );
      },
    );
  }
}

class _DragTrackPainter extends CustomPainter {
  const _DragTrackPainter({
    required this.path,
    required this.cursor,
    required this.progress,
    required this.trackWidth,
    required this.accent,
    required this.offTrack,
    required this.surface,
    required this.outline,
    required this.error,
  });

  final List<Offset> path;
  final Offset cursor;
  final double progress;
  final double trackWidth;
  final Color accent;
  final bool offTrack;
  final Color surface;
  final Color outline;
  final Color error;

  @override
  void paint(Canvas canvas, Size size) {
    if (path.length < 2) {
      return;
    }
    final points = path
        .map((point) => Offset(point.dx * size.width, point.dy * size.height))
        .toList(growable: false);
    final basePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      basePath.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      basePath,
      Paint()
        ..color = outline
        ..strokeWidth = trackWidth + 8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      basePath,
      Paint()
        ..color = surface
        ..strokeWidth = trackWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
    _drawProgress(canvas, points);
    canvas.drawCircle(points.first, 13, Paint()..color = accent);
    canvas.drawCircle(
      points.last,
      13,
      Paint()
        ..color = surface
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      points.last,
      13,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    final cursorPoint = Offset(cursor.dx * size.width, cursor.dy * size.height);
    canvas.drawCircle(
      cursorPoint,
      14,
      Paint()..color = (offTrack ? error : accent).withValues(alpha: 0.18),
    );
    canvas.drawCircle(
      cursorPoint,
      8,
      Paint()..color = offTrack ? error : accent,
    );
  }

  void _drawProgress(Canvas canvas, List<Offset> points) {
    final clamped = progress.clamp(0.0, 1.0).toDouble();
    if (clamped <= 0) {
      return;
    }
    var totalLength = 0.0;
    for (var index = 0; index < points.length - 1; index += 1) {
      totalLength += (points[index + 1] - points[index]).distance;
    }
    var remaining = totalLength * clamped;
    final progressPath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var index = 0; index < points.length - 1; index += 1) {
      final a = points[index];
      final b = points[index + 1];
      final segment = b - a;
      final length = segment.distance;
      if (remaining >= length) {
        progressPath.lineTo(b.dx, b.dy);
        remaining -= length;
      } else {
        final t = length == 0
            ? 0.0
            : (remaining / length).clamp(0.0, 1.0).toDouble();
        final end = a + segment * t;
        progressPath.lineTo(end.dx, end.dy);
        break;
      }
    }
    canvas.drawPath(
      progressPath,
      Paint()
        ..color = accent
        ..strokeWidth = math.max(4, trackWidth * 0.32)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _DragTrackPainter oldDelegate) {
    return oldDelegate.path != path ||
        oldDelegate.cursor != cursor ||
        oldDelegate.progress != progress ||
        oldDelegate.trackWidth != trackWidth ||
        oldDelegate.offTrack != offTrack ||
        oldDelegate.surface != surface ||
        oldDelegate.outline != outline ||
        oldDelegate.error != error;
  }
}
