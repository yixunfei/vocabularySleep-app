part of 'toolbox_human_tests.dart';

class _HandEyeStageSurface extends StatelessWidget {
  const _HandEyeStageSurface({
    required this.accent,
    required this.child,
    this.fullBleed = false,
    this.whiteSurface = false,
  });

  final Color accent;
  final Widget child;
  final bool fullBleed;
  final bool whiteSurface;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(fullBleed ? 0 : 22),
      child: CustomPaint(
        painter: _HandEyeStagePainter(
          accent: accent,
          surface: whiteSurface ? Colors.white : colorScheme.surface,
          line: whiteSurface
              ? colorScheme.outlineVariant.withValues(alpha: 0.34)
              : colorScheme.outlineVariant,
          plain: whiteSurface,
        ),
        child: child,
      ),
    );
  }
}

class _HandEyePlayStage extends StatelessWidget {
  const _HandEyePlayStage({
    required this.state,
    required this.heightForConstraints,
    required this.fullscreen,
    this.activePadding = EdgeInsets.zero,
  });

  final _HandEyeCoordinationCardState state;
  final double Function(BoxConstraints constraints) heightForConstraints;
  final bool fullscreen;
  final EdgeInsets activePadding;

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final size = Size(width, heightForConstraints(constraints));
        final left = activePadding.left.clamp(0.0, size.width * 0.25);
        final right = activePadding.right.clamp(0.0, size.width * 0.25);
        final top = activePadding.top.clamp(0.0, size.height * 0.30);
        final bottom = activePadding.bottom.clamp(0.0, size.height * 0.30);
        final activeOrigin = Offset(left, top);
        final activeSize = Size(
          math.max(1, size.width - left - right),
          math.max(1, size.height - top - bottom),
        );
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => state._handleStageTap(
            activeSize,
            details.localPosition - activeOrigin,
          ),
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: AnimatedBuilder(
              animation: state._viewSignal,
              builder: (context, child) {
                final center = state._targetCenter(activeSize) + activeOrigin;
                return Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: _HandEyeStageSurface(
                        accent: _HandEyeCoordinationCardState._accent,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Text(
                              state._phaseText(i18n),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (state._phase == _HandEyePhase.visible)
                      ...state._distractors.map((target) {
                        final distractorCenter =
                            state._distractorCenter(activeSize, target) +
                            activeOrigin;
                        final distractorAccent = Color.lerp(
                          _HandEyeCoordinationCardState._accent,
                          Theme.of(context).colorScheme.error,
                          target.colorBlend,
                        )!;
                        return Positioned(
                          left: distractorCenter.dx - target.diameter / 2,
                          top: distractorCenter.dy - target.diameter / 2,
                          child: _HandEyeTargetMarker(
                            accent: distractorAccent,
                            diameter: target.diameter,
                            taps: 0,
                            requiredTaps: 1,
                            falseTarget: true,
                          ),
                        );
                      }),
                    if (state._phase == _HandEyePhase.visible)
                      Positioned(
                        left: center.dx - state._targetDiameter / 2,
                        top: center.dy - state._targetDiameter / 2,
                        child: _HandEyeTargetMarker(
                          accent: _HandEyeCoordinationCardState._accent,
                          diameter: state._targetDiameter,
                          taps: state._targetTaps,
                          requiredTaps: state._requiredTaps,
                        ),
                      ),
                    if (!fullscreen &&
                        (state._phase == _HandEyePhase.idle ||
                            state._phase == _HandEyePhase.done))
                      Center(
                        child: _HumanActionButton(
                          label: pickUiText(i18n, zh: '开始', en: 'Start'),
                          icon: Icons.play_arrow_rounded,
                          onPressed: state._start,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
    if (fullscreen) {
      return content;
    }
    return _HumanPanel(padding: EdgeInsets.zero, child: content);
  }
}

class _HumanTestFullscreenIconButton extends StatelessWidget {
  const _HumanTestFullscreenIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.56),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        tooltip: tooltip,
      ),
    );
  }
}

class _HumanTestFullscreenPanel extends StatelessWidget {
  const _HumanTestFullscreenPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    this.opacity = 0.78,
    this.shadowOpacity = 0.20,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double opacity;
  final double shadowOpacity;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.52),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: shadowOpacity),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _HumanTestFullscreenMetric extends StatelessWidget {
  const _HumanTestFullscreenMetric({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 74),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: accent.withValues(alpha: 0.11),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: accent,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _HandEyeFullscreenView extends StatefulWidget {
  const _HandEyeFullscreenView({required this.state});

  final _HandEyeCoordinationCardState state;

  @override
  State<_HandEyeFullscreenView> createState() => _HandEyeFullscreenViewState();
}

class _HandEyeFullscreenViewState extends State<_HandEyeFullscreenView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fullscreenTicker;
  bool _settingsOpen = false;

  _HandEyeCoordinationCardState get state => widget.state;

  @override
  void initState() {
    super.initState();
    state._pauseTargetMotionDriverForFullscreen();
    _fullscreenTicker = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..addListener(_tick);
    state._viewSignal.addListener(_syncTicker);
    _syncTicker();
  }

  @override
  void dispose() {
    state._viewSignal.removeListener(_syncTicker);
    _fullscreenTicker
      ..removeListener(_tick)
      ..dispose();
    state._resumeTargetMotionDriverAfterFullscreen();
    super.dispose();
  }

  void _tick() {
    if (state._phase == _HandEyePhase.visible) {
      state._notifyView();
    }
  }

  void _syncTicker() {
    final shouldRun = state._phase == _HandEyePhase.visible;
    if (shouldRun && !_fullscreenTicker.isAnimating) {
      _fullscreenTicker.repeat();
      return;
    }
    if (!shouldRun && _fullscreenTicker.isAnimating) {
      _fullscreenTicker.stop();
    }
  }

  void _toggleSettings() {
    setState(() => _settingsOpen = !_settingsOpen);
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      key: const ValueKey<String>('hand_eye_fullscreen_view'),
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: state._viewSignal,
        builder: (context, _) {
          final averageReaction = state._averageReaction;
          return OrientationBuilder(
            builder: (context, orientation) {
              final mediaSize = MediaQuery.sizeOf(context);
              final compact = mediaSize.shortestSide < 380;
              final settingsWidth = math.min(
                compact ? 304.0 : 380.0,
                math.max(240.0, mediaSize.width - 16),
              );
              return Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: _HandEyePlayStage(
                      state: state,
                      heightForConstraints: (constraints) =>
                          constraints.maxHeight,
                      fullscreen: true,
                      activePadding: EdgeInsets.fromLTRB(
                        8,
                        compact ? 132 : 108,
                        8,
                        84,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: SafeArea(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          _HumanTestFullscreenIconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icons.close_rounded,
                            tooltip: MaterialLocalizations.of(
                              context,
                            ).closeButtonLabel,
                          ),
                          const SizedBox(width: 8),
                          _HumanTestFullscreenIconButton(
                            key: const ValueKey<String>(
                              'hand_eye_fullscreen_settings_button',
                            ),
                            onPressed: _toggleSettings,
                            icon: _settingsOpen
                                ? Icons.tune_rounded
                                : Icons.settings_rounded,
                            tooltip: pickUiText(
                              i18n,
                              zh: '全屏设置',
                              en: 'Fullscreen settings',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: compact ? 64 : 8,
                    left: compact ? 8 : null,
                    right: 8,
                    child: SafeArea(
                      child: IgnorePointer(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: compact
                                ? math.max(240, mediaSize.width - 16)
                                : 520,
                          ),
                          child: _HumanTestFullscreenPanel(
                            padding: EdgeInsets.symmetric(
                              horizontal: compact ? 10 : 12,
                              vertical: compact ? 8 : 10,
                            ),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: <Widget>[
                                _HumanTestFullscreenMetric(
                                  label: pickUiText(
                                    i18n,
                                    zh: '轮次',
                                    en: 'Rounds',
                                  ),
                                  value:
                                      '${state._results.length}/${state._roundCount}',
                                  accent: _HandEyeCoordinationCardState._accent,
                                ),
                                _HumanTestFullscreenMetric(
                                  label: pickUiText(i18n, zh: '命中', en: 'Hits'),
                                  value: '${state._successes}',
                                  accent: _HandEyeCoordinationCardState._accent,
                                ),
                                _HumanTestFullscreenMetric(
                                  label: pickUiText(
                                    i18n,
                                    zh: '点空',
                                    en: 'Blanks',
                                  ),
                                  value: '${state._totalBlankTaps}',
                                  accent: _HandEyeCoordinationCardState._accent,
                                ),
                                if (!compact)
                                  _HumanTestFullscreenMetric(
                                    label: pickUiText(
                                      i18n,
                                      zh: '均值',
                                      en: 'Avg',
                                    ),
                                    value: averageReaction == null
                                        ? '-'
                                        : _formatMilliseconds(
                                            averageReaction.inMilliseconds,
                                          ),
                                    accent:
                                        _HandEyeCoordinationCardState._accent,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_settingsOpen)
                    Positioned(
                      top: compact ? 132 : 82,
                      right: 8,
                      bottom: 82,
                      child: SafeArea(
                        top: false,
                        bottom: false,
                        child: SizedBox(
                          width: settingsWidth,
                          child: KeyedSubtree(
                            key: const ValueKey<String>(
                              'hand_eye_fullscreen_settings_panel',
                            ),
                            child: _HumanTestFullscreenPanel(
                              padding: const EdgeInsets.all(12),
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Expanded(
                                          child: Text(
                                            pickUiText(
                                              i18n,
                                              zh: '全屏设置',
                                              en: 'Fullscreen settings',
                                            ),
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w900,
                                                ),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: _toggleSettings,
                                          icon: const Icon(Icons.close_rounded),
                                          tooltip: MaterialLocalizations.of(
                                            context,
                                          ).closeButtonLabel,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      pickUiText(
                                        i18n,
                                        zh: '未开始或完成后可直接调整；进行中会锁定测试参数。',
                                        en: 'Adjust before starting or after finishing. Running tests lock these parameters.',
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(height: 1.35),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      pickUiText(
                                        i18n,
                                        zh: '目标设置',
                                        en: 'Target settings',
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    state._buildTargetSettings(i18n),
                                    const Divider(height: 24),
                                    Text(
                                      pickUiText(
                                        i18n,
                                        zh: '高阶干扰设置',
                                        en: 'Advanced interference',
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    state._buildDistractorSettings(i18n),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: SafeArea(
                      child: Align(
                        alignment: orientation == Orientation.landscape
                            ? Alignment.bottomRight
                            : Alignment.bottomCenter,
                        child: _HumanTestFullscreenPanel(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: <Widget>[
                              FilledButton.icon(
                                key: const ValueKey<String>(
                                  'hand_eye_fullscreen_start_button',
                                ),
                                onPressed: state._active ? null : state._start,
                                icon: Icon(
                                  state._active
                                      ? Icons.track_changes_rounded
                                      : Icons.play_arrow_rounded,
                                ),
                                label: Text(
                                  state._active
                                      ? pickUiText(
                                          i18n,
                                          zh: '进行中',
                                          en: 'Running',
                                        )
                                      : pickUiText(i18n, zh: '开始', en: 'Start'),
                                ),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(108, 48),
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              OutlinedButton.icon(
                                key: const ValueKey<String>(
                                  'hand_eye_fullscreen_reset_button',
                                ),
                                onPressed: state._reset,
                                icon: const Icon(Icons.restart_alt_rounded),
                                label: Text(
                                  pickUiText(i18n, zh: '重置', en: 'Reset'),
                                ),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(96, 48),
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                  backgroundColor: colorScheme.surface
                                      .withValues(alpha: 0.58),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _HandEyeStagePainter extends CustomPainter {
  const _HandEyeStagePainter({
    required this.accent,
    required this.surface,
    required this.line,
    this.plain = false,
  });

  final Color accent;
  final Color surface;
  final Color line;
  final bool plain;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final background = Paint();
    if (plain) {
      background.color = surface;
    } else {
      background.shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          accent.withValues(alpha: 0.10),
          surface,
          accent.withValues(alpha: 0.05),
        ],
      ).createShader(rect);
    }
    canvas.drawRect(rect, background);

    final gridPaint = Paint()
      ..color = line.withValues(alpha: plain ? 0.20 : 0.42)
      ..strokeWidth = 1;
    final step = plain ? 36.0 : 32.0;
    for (var x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final focusPaint = Paint()
      ..color = accent.withValues(alpha: plain ? 0.055 : 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawCircle(
      size.center(Offset.zero),
      math.min(size.width, size.height) * 0.28,
      focusPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HandEyeStagePainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.surface != surface ||
        oldDelegate.line != line ||
        oldDelegate.plain != plain;
  }
}

class _HandEyeTargetMarker extends StatelessWidget {
  const _HandEyeTargetMarker({
    required this.accent,
    required this.diameter,
    required this.taps,
    required this.requiredTaps,
    this.falseTarget = false,
  });

  final Color accent;
  final double diameter;
  final int taps;
  final int requiredTaps;
  final bool falseTarget;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: diameter,
      height: diameter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: accent.withValues(alpha: falseTarget ? 0.10 : 0.18),
          border: Border.all(color: accent, width: 3),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: accent.withValues(alpha: falseTarget ? 0.10 : 0.22),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: (diameter * 0.32).clamp(9, 18),
            height: (diameter * 0.32).clamp(9, 18),
            decoration: BoxDecoration(
              shape: falseTarget ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: falseTarget ? BorderRadius.circular(3) : null,
              color: falseTarget ? Colors.transparent : accent,
              border: Border.all(color: Colors.white, width: 2),
            ),
            alignment: Alignment.center,
            child: falseTarget
                ? Icon(Icons.close_rounded, size: 11, color: accent)
                : requiredTaps <= 1
                ? null
                : Text(
                    '${taps + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _JoystickTargetMarker extends StatelessWidget {
  const _JoystickTargetMarker({
    super.key,
    required this.accent,
    required this.diameter,
    this.falseTarget = false,
  });

  final Color accent;
  final double diameter;
  final bool falseTarget;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: diameter,
      height: diameter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: accent.withValues(alpha: falseTarget ? 0.09 : 0.16),
          border: Border.all(color: accent, width: 2.5),
        ),
        child: Center(
          child: Container(
            width: (diameter * 0.22).clamp(9, 16),
            height: (diameter * 0.22).clamp(9, 16),
            decoration: BoxDecoration(
              shape: falseTarget ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: falseTarget ? BorderRadius.circular(3) : null,
              color: falseTarget ? Colors.transparent : accent,
              border: falseTarget
                  ? Border.all(color: Colors.white, width: 1.6)
                  : null,
            ),
            child: falseTarget
                ? Icon(Icons.close_rounded, size: 11, color: accent)
                : null,
          ),
        ),
      ),
    );
  }
}

class _HandEyeCrosshairMarker extends StatelessWidget {
  const _HandEyeCrosshairMarker({super.key, required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size.square(44),
      painter: _HandEyeCrosshairPainter(accent: accent),
    );
  }
}

class _HandEyeCrosshairPainter extends CustomPainter {
  const _HandEyeCrosshairPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, 13, paint);
    canvas.drawLine(Offset(center.dx, 1), Offset(center.dx, 10), paint);
    canvas.drawLine(
      Offset(center.dx, size.height - 1),
      Offset(center.dx, size.height - 10),
      paint,
    );
    canvas.drawLine(Offset(1, center.dy), Offset(10, center.dy), paint);
    canvas.drawLine(
      Offset(size.width - 1, center.dy),
      Offset(size.width - 10, center.dy),
      paint,
    );
    canvas.drawCircle(center, 2.5, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(covariant _HandEyeCrosshairPainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}

class _HandEyeJoystickPad extends StatefulWidget {
  const _HandEyeJoystickPad({
    super.key,
    required this.vector,
    required this.enabled,
    required this.onChanged,
    this.size = 132,
  });

  final Offset vector;
  final bool enabled;
  final ValueChanged<Offset> onChanged;
  final double size;

  @override
  State<_HandEyeJoystickPad> createState() => _HandEyeJoystickPadState();
}

class _HandEyeJoystickPadState extends State<_HandEyeJoystickPad> {
  int? _activePointer;

  Offset _resolveVector(Offset localPosition) {
    final radius = widget.size / 2;
    final raw = (localPosition - Offset(radius, radius)) / radius;
    final distance = raw.distance;
    if (distance <= 1.8) {
      return raw;
    }
    return raw / distance * 1.8;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (!widget.enabled || _activePointer != null) {
      return;
    }
    _activePointer = event.pointer;
    widget.onChanged(_resolveVector(event.localPosition));
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!widget.enabled || event.pointer != _activePointer) {
      return;
    }
    widget.onChanged(_resolveVector(event.localPosition));
  }

  void _handlePointerUp(PointerEvent event) {
    if (event.pointer != _activePointer) {
      return;
    }
    _releasePointer();
  }

  void _releasePointer() {
    if (_activePointer == null) {
      return;
    }
    _activePointer = null;
    widget.onChanged(Offset.zero);
  }

  @override
  void didUpdateWidget(covariant _HandEyeJoystickPad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && oldWidget.enabled) {
      _releasePointer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = _JoystickHandEyeCardState._accent;
    final knob = (widget.size * 0.35).clamp(38.0, 56.0);
    final center = Offset(widget.size / 2, widget.size / 2);
    final normalizedDistance = widget.vector.distance <= 1
        ? widget.vector.distance
        : 1 + (widget.vector.distance - 1) * 0.42;
    final visualVector = widget.vector.distance <= 0.001
        ? Offset.zero
        : widget.vector /
              widget.vector.distance *
              normalizedDistance.clamp(0.0, 1.34);
    final knobCenter = center + visualVector * (widget.size * 0.29);
    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: widget.enabled
          ? <Type, GestureRecognizerFactory>{
              EagerGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
                    EagerGestureRecognizer.new,
                    (EagerGestureRecognizer instance) {},
                  ),
            }
          : const <Type, GestureRecognizerFactory>{},
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _handlePointerDown,
        onPointerMove: _handlePointerMove,
        onPointerUp: _handlePointerUp,
        onPointerCancel: _handlePointerUp,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: widget.enabled ? 0.70 : 0.36,
                    ),
                    border: Border.all(
                      color: accent.withValues(
                        alpha: widget.enabled ? 0.36 : 0.16,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: knobCenter.dx - knob / 2,
                top: knobCenter.dy - knob / 2,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 80),
                  curve: Curves.easeOutCubic,
                  width: knob,
                  height: knob,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.enabled
                        ? accent.withValues(alpha: 0.86)
                        : colorScheme.outlineVariant,
                    boxShadow: widget.enabled
                        ? <BoxShadow>[
                            BoxShadow(
                              color: accent.withValues(alpha: 0.18),
                              blurRadius: 16,
                              offset: const Offset(0, 7),
                            ),
                          ]
                        : null,
                  ),
                  child: const Icon(
                    Icons.open_with_rounded,
                    color: Colors.white,
                    size: 20,
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

class _JoystickPlayStage extends StatelessWidget {
  const _JoystickPlayStage({
    required this.state,
    required this.heightForConstraints,
    this.showStartOverlay = true,
    this.showStageStatus = true,
    this.activePadding = EdgeInsets.zero,
    this.fullBleed = false,
    this.whiteSurface = false,
  });

  final _JoystickHandEyeCardState state;
  final double Function(BoxConstraints constraints) heightForConstraints;
  final bool showStartOverlay;
  final bool showStageStatus;
  final EdgeInsets activePadding;
  final bool fullBleed;
  final bool whiteSurface;

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          constraints.maxWidth,
          heightForConstraints(constraints),
        );
        final left = activePadding.left.clamp(0.0, size.width * 0.32);
        final right = activePadding.right.clamp(0.0, size.width * 0.32);
        final top = activePadding.top.clamp(0.0, size.height * 0.24);
        final bottom = activePadding.bottom.clamp(0.0, size.height * 0.24);
        final activeOrigin = Offset(left, top);
        final activeSize = Size(
          math.max(1, size.width - left - right),
          math.max(1, size.height - top - bottom),
        );
        state._stageSize = activeSize;
        return AnimatedBuilder(
          animation: state._viewSignal,
          builder: (context, _) {
            final targetCenter =
                Offset(
                  state._target.dx * activeSize.width,
                  state._target.dy * activeSize.height,
                ) +
                activeOrigin;
            final crosshairCenter =
                Offset(
                  state._crosshair.dx * activeSize.width,
                  state._crosshair.dy * activeSize.height,
                ) +
                activeOrigin;
            return SizedBox(
              width: size.width,
              height: size.height,
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: _HandEyeStageSurface(
                      accent: _JoystickHandEyeCardState._accent,
                      fullBleed: fullBleed,
                      whiteSurface: whiteSurface,
                      child: showStageStatus
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Text(
                                  state._statusText(i18n),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                            )
                          : const SizedBox.expand(),
                    ),
                  ),
                  if (state._targetActive)
                    ...state._distractors.map((target) {
                      final center =
                          state._distractorCenter(target) + activeOrigin;
                      final distractorAccent = Color.lerp(
                        _JoystickHandEyeCardState._accent,
                        Theme.of(context).colorScheme.error,
                        target.colorBlend,
                      )!;
                      return Positioned(
                        left: center.dx - target.diameter / 2,
                        top: center.dy - target.diameter / 2,
                        child: _JoystickTargetMarker(
                          accent: distractorAccent,
                          diameter: target.diameter,
                          falseTarget: true,
                        ),
                      );
                    }),
                  if (state._targetActive)
                    Positioned(
                      left: targetCenter.dx - state._targetDiameter / 2,
                      top: targetCenter.dy - state._targetDiameter / 2,
                      child: _JoystickTargetMarker(
                        key: const ValueKey<String>(
                          'joystick_real_target_marker',
                        ),
                        accent: _JoystickHandEyeCardState._accent,
                        diameter: state._targetDiameter,
                      ),
                    ),
                  Positioned(
                    left: crosshairCenter.dx - 22,
                    top: crosshairCenter.dy - 22,
                    child: const _HandEyeCrosshairMarker(
                      key: ValueKey<String>('joystick_crosshair_marker'),
                      accent: _JoystickHandEyeCardState._accent,
                    ),
                  ),
                  if (!state._running && showStartOverlay)
                    Center(
                      child: _HumanActionButton(
                        label: pickUiText(i18n, zh: '开始', en: 'Start'),
                        icon: Icons.play_arrow_rounded,
                        onPressed: state._start,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _JoystickControlDeck extends StatelessWidget {
  const _JoystickControlDeck({required this.state, required this.fullscreen});

  final _JoystickHandEyeCardState state;
  final bool fullscreen;

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final fireButton = FilledButton.icon(
      onPressed: state._running ? state._fire : null,
      icon: const Icon(Icons.my_location_rounded),
      label: Text(pickUiText(i18n, zh: '射击', en: 'Fire')),
      style: FilledButton.styleFrom(
        minimumSize: Size.fromHeight(fullscreen ? 88 : 64),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
    final secondaryActions = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: <Widget>[
        OutlinedButton.icon(
          onPressed: state._running ? state._finish : state._start,
          icon: Icon(
            state._running ? Icons.stop_rounded : Icons.play_arrow_rounded,
          ),
          label: Text(
            state._running
                ? pickUiText(i18n, zh: '结束', en: 'Finish')
                : pickUiText(i18n, zh: '开始', en: 'Start'),
          ),
        ),
        OutlinedButton.icon(
          onPressed: state._reset,
          icon: const Icon(Icons.restart_alt_rounded),
          label: Text(pickUiText(i18n, zh: '重置', en: 'Reset')),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (fullscreen)
          LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth.isFinite
                  ? constraints.maxWidth
                  : MediaQuery.sizeOf(context).width;
              final gap = maxWidth < 340 ? 10.0 : 18.0;
              final joystickSize = math
                  .min(164.0, math.max(108.0, maxWidth * 0.46))
                  .toDouble();
              final fireWidth = math
                  .min(150.0, math.max(96.0, maxWidth - joystickSize - gap))
                  .toDouble();
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  _HandEyeJoystickPad(
                    vector: state._joystickVector,
                    enabled: state._running,
                    size: joystickSize,
                    onChanged: state._setJoystickVector,
                  ),
                  SizedBox(width: gap),
                  SizedBox(width: fireWidth, child: fireButton),
                ],
              );
            },
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _HandEyeJoystickPad(
                key: const ValueKey<String>('joystick_hand_eye_pad'),
                vector: state._joystickVector,
                enabled: state._running,
                size: 132,
                onChanged: state._setJoystickVector,
              ),
              const SizedBox(width: 14),
              Expanded(child: fireButton),
            ],
          ),
        if (!fullscreen) ...<Widget>[
          const SizedBox(height: 10),
          secondaryActions,
        ],
      ],
    );
  }
}

class _HandEyeResultPanel extends StatelessWidget {
  const _HandEyeResultPanel({required this.results, required this.accent});

  final List<_HandEyeRoundResult> results;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    return _HumanPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            pickUiText(i18n, zh: '详细统计', en: 'Detailed results'),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: math.min(280, results.length * 48.0),
            child: ListView.separated(
              itemCount: results.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final result = results[index];
                return _HandEyeResultRow(
                  index: index + 1,
                  result: result,
                  accent: accent,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HandEyeResultRow extends StatelessWidget {
  const _HandEyeResultRow({
    required this.index,
    required this.result,
    required this.accent,
  });

  final int index;
  final _HandEyeRoundResult result;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = result.success ? accent : colorScheme.error;
    final reaction = result.firstReaction == null
        ? '-'
        : _formatMilliseconds(result.firstReaction!.inMilliseconds);
    final completion = result.completionLatency == null
        ? _formatMilliseconds(result.visibleFor.inMilliseconds)
        : _formatMilliseconds(result.completionLatency!.inMilliseconds);
    final falseHitText = result.distractorTaps > 0
        ? pickUiText(
            i18n,
            zh: '；假目标 ${result.distractorTaps}',
            en: '; false ${result.distractorTaps}',
          )
        : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: statusColor.withValues(alpha: 0.08),
        border: Border.all(color: statusColor.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            result.success ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: statusColor,
            size: 19,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              pickUiText(
                i18n,
                zh: '#$index  ${result.taps}/${result.requiredTaps} 次；点空 ${result.blankTaps}$falseHitText；反应 $reaction；窗口 $completion',
                en: '#$index  ${result.taps}/${result.requiredTaps} taps; blanks ${result.blankTaps}$falseHitText; reaction $reaction; window $completion',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JoystickResultPanel extends StatelessWidget {
  const _JoystickResultPanel({required this.reactions, required this.accent});

  final List<Duration> reactions;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final i18n = AppI18n(Localizations.localeOf(context).languageCode);
    final recent = reactions.length > 8
        ? reactions.sublist(reactions.length - 8)
        : reactions;
    return _HumanPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            pickUiText(i18n, zh: '命中延迟明细', en: 'Hit latency details'),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List<Widget>.generate(recent.length, (index) {
              final realIndex = reactions.length - recent.length + index + 1;
              return _HumanPill(
                text:
                    '#$realIndex ${_formatMilliseconds(recent[index].inMilliseconds)}',
                accent: accent,
              );
            }),
          ),
        ],
      ),
    );
  }
}
