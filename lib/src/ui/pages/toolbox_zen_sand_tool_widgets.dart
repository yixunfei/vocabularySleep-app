part of 'toolbox_zen_sand_tool.dart';

class _ZenSheetFrame extends StatelessWidget {
  const _ZenSheetFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.88,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F2EA),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: child,
        ),
      ),
    );
  }
}
class _ZenSheetHeader extends StatelessWidget {
  const _ZenSheetHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF271F18),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF655949),
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
class _ZenSectionCard extends StatelessWidget {
  const _ZenSectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF281F16),
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ZenDrawerSectionCard extends StatelessWidget {
  const _ZenDrawerSectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.expanded,
    required this.onTap,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool expanded;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const accent = Color(0xFF7D6955);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.86),
        border: Border.all(
          color: expanded
              ? accent.withValues(alpha: 0.26)
              : const Color(0xFFE5D8CA),
        ),
        boxShadow: expanded
            ? <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : const <BoxShadow>[],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: accent.withValues(alpha: 0.12),
                      ),
                      child: Icon(icon, size: 18, color: accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF281F16),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF655949),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ClipRect(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: expanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      child: child,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZenGlassPill extends StatelessWidget {
  const _ZenGlassPill({
    required this.icon,
    required this.accent,
    required this.label,
  });

  final IconData icon;
  final Color accent;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.82),
        border: Border.all(color: Colors.white.withValues(alpha: 0.68)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(icon, size: 16, color: accent),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF4E4338),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZenActionBadge extends StatelessWidget {
  const _ZenActionBadge({
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
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.76),
        border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF6A5B4C),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: const Color(0xFF2C241E),
                    fontWeight: FontWeight.w800,
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

class _ZenQuickIconButton extends StatelessWidget {
  const _ZenQuickIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onPressed,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: const Color(0xFF2A241D)),
          ),
        ),
      ),
    );
  }
}

class _ZenDockButton extends StatelessWidget {
  const _ZenDockButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final foreground = enabled
        ? const Color(0xFF2C241E)
        : const Color(0xFFA49585);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: enabled ? onPressed : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 20, color: foreground),
            const SizedBox(height: 3),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZenCompactToolChip extends StatelessWidget {
  const _ZenCompactToolChip({
    required this.tool,
    required this.isZh,
    required this.selected,
    required this.onTap,
  });

  final _ZenToolSpec tool;
  final bool isZh;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: selected
            ? tool.tint.withValues(alpha: 0.16)
            : const Color(0xFFF3ECE3),
        border: Border.all(
          color: selected
              ? tool.tint.withValues(alpha: 0.42)
              : const Color(0xFFE2D8CC),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(tool.icon, size: 18, color: tool.tint),
              const SizedBox(width: 8),
              Text(
                tool.label(isZh),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2A2118),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZenCompactActionChip extends StatelessWidget {
  const _ZenCompactActionChip({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: enabled ? 1 : 0.42,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: accent.withValues(alpha: 0.12),
            border: Border.all(color: accent.withValues(alpha: 0.25)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, size: 18, color: accent),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF402E24),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ZenRitualQuickChip extends StatelessWidget {
  const _ZenRitualQuickChip({
    required this.preset,
    required this.isZh,
    required this.selected,
    required this.onTap,
  });

  final _ZenRitualPresetSpec preset;
  final bool isZh;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = preset.accent;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: selected
            ? accent.withValues(alpha: 0.16)
            : const Color(0xFFF6EEE4),
        border: Border.all(
          color: selected
              ? accent.withValues(alpha: 0.48)
              : const Color(0xFFE4D8CB),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(preset.icon, size: 18, color: accent),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    preset.title(isZh),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2A2118),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selected
                        ? (isZh ? '正在使用' : 'Active base')
                        : (isZh ? '点按套用' : 'Tap to apply'),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF6B5D4F),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZenColorChip extends StatelessWidget {
  const _ZenColorChip({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withValues(alpha: 0.14) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.76)
                  : const Color(0xFFE3D8CC),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF31261D),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZenToolCard extends StatelessWidget {
  const _ZenToolCard({
    required this.tool,
    required this.isZh,
    required this.selected,
    required this.onTap,
  });

  final _ZenToolSpec tool;
  final bool isZh;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Material(
        color: selected ? tool.tint.withValues(alpha: 0.14) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? tool.tint.withValues(alpha: 0.48)
                    : const Color(0xFFE5DBD0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: tool.tint.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(tool.icon, color: tool.tint),
                    ),
                    const Spacer(),
                    if (selected)
                      Icon(
                        Icons.check_circle_rounded,
                        color: tool.tint,
                        size: 22,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  tool.label(isZh),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2A2118),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tool.help(isZh),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6B5D4F),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ZenBackgroundCard extends StatelessWidget {
  const _ZenBackgroundCard({
    required this.background,
    required this.isZh,
    required this.selected,
    required this.onTap,
  });

  final _ZenBackgroundSpec background;
  final bool isZh;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? background.accent.withValues(alpha: 0.56)
                  : const Color(0xFFE3D8CC),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AspectRatio(
                aspectRatio: 1.1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: CustomPaint(
                    painter: _ZenScenePreviewPainter(background: background),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      background.label(isZh),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2A2118),
                      ),
                    ),
                  ),
                  if (selected)
                    Icon(
                      Icons.check_circle_rounded,
                      color: background.accent,
                      size: 22,
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                background.description(isZh),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6B5D4F),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZenRitualCard extends StatelessWidget {
  const _ZenRitualCard({
    required this.preset,
    required this.isZh,
    required this.selected,
    required this.onTap,
  });

  final _ZenRitualPresetSpec preset;
  final bool isZh;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? preset.accent.withValues(alpha: 0.56)
                  : const Color(0xFFE3D8CC),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AspectRatio(
                aspectRatio: 1.18,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: CustomPaint(
                    painter: _ZenRitualPreviewPainter(preset: preset),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: preset.accent.withValues(alpha: 0.14),
                    ),
                    alignment: Alignment.center,
                    child: Icon(preset.icon, color: preset.accent),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      preset.title(isZh),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2A2118),
                      ),
                    ),
                  ),
                  if (selected)
                    Icon(
                      Icons.check_circle_rounded,
                      color: preset.accent,
                      size: 22,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                preset.description(isZh),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6B5D4F),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isZh ? '点击套用，可替换或叠加。' : 'Tap to apply, replace, or layer.',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: preset.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZenToggleRow extends StatelessWidget {
  const _ZenToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2C241E),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF655949),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Switch.adaptive(
          value: value,
          activeTrackColor: activeColor.withValues(alpha: 0.36),
          activeThumbColor: activeColor,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ZenCanvasHint extends StatelessWidget {
  const _ZenCanvasHint({
    required this.label,
    required this.accent,
    this.trailing,
  });

  final String label;
  final Color accent;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.78),
        border: Border.all(color: Colors.white.withValues(alpha: 0.66)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3D3228),
              ),
            ),
            if (trailing != null) ...<Widget>[
              const SizedBox(width: 8),
              Text(
                trailing!,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF73614E),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ZenMiniMetric extends StatelessWidget {
  const _ZenMiniMetric({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.78),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: const Color(0xFF332920),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ZenToolPreview extends StatelessWidget {
  const _ZenToolPreview({
    required this.background,
    required this.tool,
    required this.brushSize,
    this.colorValue,
  });

  final _ZenBackgroundSpec background;
  final _ZenToolSpec tool;
  final double brushSize;
  final int? colorValue;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 78,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: CustomPaint(
          painter: _ZenToolPreviewPainter(
            background: background,
            tool: tool,
            brushSize: brushSize,
            colorValue: colorValue,
          ),
        ),
      ),
    );
  }
}
