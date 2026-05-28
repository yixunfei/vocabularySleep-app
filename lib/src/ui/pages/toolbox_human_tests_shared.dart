part of 'toolbox_human_tests.dart';

class _HumanTestEntry {
  const _HumanTestEntry({
    required this.id,
    required this.title,
    required this.shortTitle,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.pageBuilder,
  });

  final String id;
  final String title;
  final String shortTitle;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Widget Function() pageBuilder;
}

class _HumanTestEntryCard extends StatelessWidget {
  const _HumanTestEntryCard({
    required this.entry,
    this.compact = false,
    this.highlighted = false,
    this.dragging = false,
  });

  final _HumanTestEntry entry;
  final bool compact;
  final bool highlighted;
  final bool dragging;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final radius = BorderRadius.circular(compact ? 18 : 20);
    final card = AnimatedScale(
      scale: dragging ? 1.045 : (highlighted ? 1.015 : 1),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: dragging
              ? <BoxShadow>[
                  BoxShadow(
                    color: entry.accent.withValues(alpha: 0.22),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ]
              : const <BoxShadow>[],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            onTap: dragging
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => entry.pageBuilder(),
                      ),
                    );
                  },
            child: Ink(
              height: compact ? 126 : null,
              padding: EdgeInsets.all(compact ? 10 : 16),
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    entry.accent.withValues(
                      alpha: dragging ? 0.20 : (highlighted ? 0.17 : 0.075),
                    ),
                    colorScheme.surfaceContainerLowest,
                    colorScheme.surface,
                  ],
                ),
                border: Border.all(
                  color: entry.accent.withValues(
                    alpha: dragging ? 0.58 : (highlighted ? 0.52 : 0.14),
                  ),
                ),
                boxShadow: highlighted && !dragging
                    ? <BoxShadow>[
                        BoxShadow(
                          color: entry.accent.withValues(alpha: 0.14),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : const <BoxShadow>[],
              ),
              child: compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                              width: 18,
                              height: 2.5,
                              decoration: BoxDecoration(
                                color: entry.accent.withValues(alpha: 0.32),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.drag_indicator_rounded,
                              size: 12,
                              color: entry.accent.withValues(alpha: 0.28),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: entry.accent.withValues(
                              alpha: dragging ? 0.08 : 0.13,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: entry.accent.withValues(alpha: 0.14),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            entry.icon,
                            color: entry.accent,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 10),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            entry.shortTitle,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 17),
                          child: Text(
                            entry.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              height: 1.05,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const Spacer(),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: entry.accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Icon(entry.icon, color: entry.accent),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                entry.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                entry.subtitle,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          entry.shortTitle,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.outline,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: colorScheme.outline,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
    if (!compact) {
      return card;
    }
    return Tooltip(
      message: '${entry.title}\n${entry.subtitle}',
      child: Semantics(
        button: true,
        label: entry.title,
        hint: entry.subtitle,
        child: card,
      ),
    );
  }
}

class _HumanTestScaffold extends StatelessWidget {
  const _HumanTestScaffold({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.status,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final String status;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ToolboxToolPage(
      title: title,
      subtitle: subtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _HumanHeroPanel(
            title: title,
            subtitle: subtitle,
            accent: accent,
            icon: icon,
            status: status,
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _HumanHeroPanel extends StatelessWidget {
  const _HumanHeroPanel({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.status,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            accent.withValues(alpha: 0.14),
            colorScheme.surfaceContainerLowest,
            colorScheme.secondaryContainer.withValues(alpha: 0.34),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: accent.withValues(alpha: 0.14),
              border: Border.all(color: accent.withValues(alpha: 0.16)),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: accent, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
                ),
                const SizedBox(height: 12),
                _HumanPill(text: status, accent: accent),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HumanPanel extends StatelessWidget {
  const _HumanPanel({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: child,
    );
  }
}

class _HumanPointerDragBoundary extends StatelessWidget {
  const _HumanPointerDragBoundary({
    super.key,
    required this.child,
    this.enabled = true,
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerUp,
    this.onPointerCancel,
    this.behavior = HitTestBehavior.opaque,
  });

  final Widget child;
  final bool enabled;
  final PointerDownEventListener? onPointerDown;
  final PointerMoveEventListener? onPointerMove;
  final PointerUpEventListener? onPointerUp;
  final PointerCancelEventListener? onPointerCancel;
  final HitTestBehavior behavior;

  @override
  Widget build(BuildContext context) {
    final listener = Listener(
      behavior: behavior,
      onPointerDown: enabled ? onPointerDown : null,
      onPointerMove: enabled ? onPointerMove : null,
      onPointerUp: enabled ? onPointerUp : null,
      onPointerCancel: enabled ? onPointerCancel : null,
      child: child,
    );
    if (!enabled) {
      return listener;
    }
    return RawGestureDetector(
      behavior: behavior,
      gestures: <Type, GestureRecognizerFactory>{
        EagerGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
              EagerGestureRecognizer.new,
              (EagerGestureRecognizer instance) {},
            ),
      },
      child: listener,
    );
  }
}

class _HumanSettingsSection extends StatefulWidget {
  const _HumanSettingsSection({
    required this.title,
    required this.child,
    this.subtitle,
    this.initiallyExpanded = false,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final bool initiallyExpanded;

  @override
  State<_HumanSettingsSection> createState() => _HumanSettingsSectionState();
}

class _HumanSettingsSectionState extends State<_HumanSettingsSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final borderColor = _expanded
        ? colorScheme.primary.withValues(alpha: 0.44)
        : colorScheme.outlineVariant.withValues(alpha: 0.88);
    final headerTint = colorScheme.primary.withValues(
      alpha: _expanded ? 0.10 : 0.055,
    );
    final iconTint = _expanded
        ? colorScheme.primary.withValues(alpha: 0.18)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.72);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        color: colorScheme.surface.withValues(alpha: 0.72),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colorScheme.shadow.withValues(
              alpha: _expanded ? 0.10 : 0.06,
            ),
            blurRadius: _expanded ? 18 : 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggle,
                child: Ink(
                  decoration: BoxDecoration(color: headerTint),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
                    child: Row(
                      children: <Widget>[
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeInOutCubic,
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: iconTint,
                            border: Border.all(
                              color: colorScheme.primary.withValues(
                                alpha: _expanded ? 0.22 : 0.12,
                              ),
                            ),
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                widget.title,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (widget.subtitle != null) ...<Widget>[
                                const SizedBox(height: 3),
                                Text(
                                  widget.subtitle!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    height: 1.32,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeInOutCubic,
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _expanded
                                ? colorScheme.primary.withValues(alpha: 0.16)
                                : colorScheme.surface.withValues(alpha: 0.78),
                            border: Border.all(
                              color: colorScheme.primary.withValues(
                                alpha: _expanded ? 0.24 : 0.14,
                              ),
                            ),
                          ),
                          child: AnimatedRotation(
                            turns: _expanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeInOutCubic,
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    color: colorScheme.primary.withValues(alpha: 0.14),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    child: widget.child,
                  ),
                ],
              ),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
              sizeCurve: Curves.easeInOutCubic,
            ),
          ],
        ),
      ),
    );
  }
}

class _HumanPill extends StatelessWidget {
  const _HumanPill({required this.text, required this.accent});

  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: accent.withValues(alpha: 0.12),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          color: accent,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HumanMetricWrap extends StatelessWidget {
  const _HumanMetricWrap({required this.metrics});

  final List<(String, String)> metrics;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: metrics
          .map(
            (metric) => ToolboxMetricCard(label: metric.$1, value: metric.$2),
          )
          .toList(growable: false),
    );
  }
}

class _HumanActionButton extends StatelessWidget {
  const _HumanActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        minimumSize: const Size(120, 48),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

String _formatMilliseconds(num value) => '${value.round()} ms';

String _formatSeconds(num value) => '${value.toStringAsFixed(2)} s';

T _sample<T>(math.Random random, List<T> values) {
  return values[random.nextInt(values.length)];
}
