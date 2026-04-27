import 'package:flutter/material.dart';

import '../../motion/app_motion.dart';
import 'toolbox_ui_tokens.dart';

class ToolboxSurfaceCard extends StatelessWidget {
  const ToolboxSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.gradient,
    this.borderColor,
    this.borderWidth = 1,
    this.radius = ToolboxUiTokens.panelRadius,
    this.shadowColor,
    this.shadowOpacity = 0.08,
    this.shadowBlur = ToolboxUiTokens.panelShadowBlur,
    this.shadowOffsetY = ToolboxUiTokens.panelShadowOffsetY,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Gradient? gradient;
  final Color? borderColor;
  final double borderWidth;
  final double radius;
  final Color? shadowColor;
  final double shadowOpacity;
  final double shadowBlur;
  final double shadowOffsetY;

  @override
  Widget build(BuildContext context) {
    final fallbackBorder =
        borderColor ?? Theme.of(context).colorScheme.outlineVariant;
    final effectiveShadowColor =
        shadowColor ?? Theme.of(context).colorScheme.shadow;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: fallbackBorder, width: borderWidth),
        boxShadow: <BoxShadow>[
          toolboxPanelShadow(
            effectiveShadowColor,
            opacity: shadowOpacity,
            blurRadius: shadowBlur,
            offsetY: shadowOffsetY,
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class ToolboxSelectablePill extends StatelessWidget {
  const ToolboxSelectablePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.tint,
    this.leading,
    this.showLabel = true,
    this.tooltip,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    this.radius = ToolboxUiTokens.pillRadius,
  });

  final Widget label;
  final bool selected;
  final VoidCallback onTap;
  final Color tint;
  final Widget? leading;
  final bool showLabel;
  final String? tooltip;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pill = AnimatedScale(
      scale: selected ? 1 : 0.985,
      duration: AppDurations.quick,
      curve: AppEasing.snappy,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppDurations.standard,
            curve: AppEasing.standard,
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  selected
                      ? tint.withValues(alpha: 0.18)
                      : theme.colorScheme.surfaceContainerLow,
                  selected
                      ? tint.withValues(alpha: 0.07)
                      : theme.colorScheme.surface,
                ],
              ),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: selected
                    ? tint.withValues(alpha: 0.7)
                    : theme.colorScheme.outlineVariant,
              ),
              boxShadow: selected
                  ? <BoxShadow>[
                      toolboxPanelShadow(
                        tint,
                        opacity: 0.14,
                        blurRadius: 14,
                        offsetY: 6,
                      ),
                    ]
                  : const <BoxShadow>[],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (leading != null) ...<Widget>[
                  leading!,
                  if (showLabel) const SizedBox(width: 6),
                ],
                if (showLabel)
                  Flexible(
                    child: DefaultTextStyle(
                      style: theme.textTheme.labelLarge!.copyWith(
                        fontWeight: FontWeight.w800,
                        color: selected
                            ? tint
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      child: label,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    final semanticPill = Semantics(
      button: true,
      selected: selected,
      label: tooltip,
      child: pill,
    );
    return tooltip == null
        ? semanticPill
        : Tooltip(message: tooltip!, child: semanticPill);
  }
}

class ToolboxInfoPill extends StatelessWidget {
  const ToolboxInfoPill({
    super.key,
    required this.text,
    required this.accent,
    this.backgroundColor,
    this.textColor,
  });

  final String text;
  final Color accent;
  final Color? backgroundColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final effectiveBackground =
        backgroundColor ?? Colors.white.withValues(alpha: 0.6);
    final effectiveTextColor =
        textColor ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: effectiveBackground,
        borderRadius: BorderRadius.circular(ToolboxUiTokens.pillRadius),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: effectiveTextColor,
          ),
        ),
      ),
    );
  }
}

class ToolboxIconPillButton extends StatelessWidget {
  const ToolboxIconPillButton({
    super.key,
    required this.icon,
    required this.active,
    required this.onTap,
    required this.tint,
    this.tooltip,
    this.size = ToolboxUiTokens.pillIconSize,
    this.radius = 16,
  });

  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final Color tint;
  final String? tooltip;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: active
                ? tint.withValues(alpha: 0.92)
                : Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: active ? tint : Colors.white.withValues(alpha: 0.82),
            ),
            boxShadow: <BoxShadow>[
              toolboxPanelShadow(
                Colors.black,
                opacity: 0.06,
                blurRadius: 16,
                offsetY: 8,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: active ? Colors.white : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
    if (tooltip == null || tooltip!.isEmpty) {
      return button;
    }
    return Tooltip(message: tooltip!, child: button);
  }
}
