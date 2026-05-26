part of '../toolbox_life_tools.dart';

class _LifeColorSearchPanel extends StatelessWidget {
  const _LifeColorSearchPanel({
    required this.controller,
    required this.query,
    required this.total,
    required this.filtered,
    required this.pagePreviewEnabled,
    required this.onTogglePagePreview,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String query;
  final int total;
  final int filtered;
  final bool pagePreviewEnabled;
  final ValueChanged<bool> onTogglePagePreview;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _lifeText(context, zh: '融合色库', en: 'Unified palette'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _LifeColorInfoPill(
                text: _lifeText(
                  context,
                  zh: '$filtered / $total 色',
                  en: '$filtered / $total colors',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: _lifeText(context, zh: '清空', en: 'Clear'),
                      onPressed: onClear,
                      icon: const Icon(Icons.close_rounded),
                    ),
              border: const OutlineInputBorder(),
              labelText: _lifeText(
                context,
                zh: '名称 / 拼音 / 罗马音 / HEX / ??FF??',
                en: 'Name / pinyin / romaji / hex / ??FF??',
              ),
            ),
            textInputAction: TextInputAction.search,
            onChanged: onChanged,
          ),
          const SizedBox(height: 10),
          _LifeColorBackgroundSwitch(
            controlKey: const ValueKey<String>(
              'life_color_search_background_toggle',
            ),
            value: pagePreviewEnabled,
            onChanged: onTogglePagePreview,
          ),
        ],
      ),
    );
  }
}

class _LifeColorBackgroundSwitch extends StatelessWidget {
  const _LifeColorBackgroundSwitch({
    required this.value,
    required this.onChanged,
    this.controlKey,
    this.foreground,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Key? controlKey;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = foreground ?? theme.colorScheme.primary;
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tone.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.format_color_fill_rounded, color: tone, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _lifeText(context, zh: '页面背景', en: 'Page background'),
              style: theme.textTheme.labelLarge?.copyWith(
                color: tone,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Switch(key: controlKey, value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _LifeColorInfoPill extends StatelessWidget {
  const _LifeColorInfoPill({required this.text, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = color ?? theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.withValues(alpha: 0.16)),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          color: tone,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _LifeColorMetricChip extends StatelessWidget {
  const _LifeColorMetricChip({
    required this.label,
    required this.value,
    required this.foreground,
  });

  final String label;
  final String value;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 88),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: foreground.withValues(alpha: 0.18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground.withValues(alpha: 0.78),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _LifeColorActionButton extends StatelessWidget {
  const _LifeColorActionButton({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: foreground,
        side: BorderSide(color: foreground.withValues(alpha: 0.28)),
        backgroundColor: foreground.withValues(alpha: 0.08),
        minimumSize: const Size(48, 42),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _UnifiedColorWall extends StatelessWidget {
  const _UnifiedColorWall({
    required this.colors,
    required this.expandedKey,
    required this.pagePreviewEnabled,
    required this.onToggle,
    required this.onTogglePagePreview,
    required this.onCopyHex,
    required this.onCopyName,
  });

  final List<_LifePaletteColor> colors;
  final String? expandedKey;
  final bool pagePreviewEnabled;
  final ValueChanged<_LifePaletteColor> onToggle;
  final ValueChanged<bool> onTogglePagePreview;
  final ValueChanged<_LifePaletteColor> onCopyHex;
  final ValueChanged<_LifePaletteColor> onCopyName;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 3 : 2;
        final spacing = constraints.maxWidth >= 560 ? 12.0 : 10.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        final rows = <Widget>[];
        for (var start = 0; start < colors.length; start += columns) {
          final rowColors = colors
              .skip(start)
              .take(columns)
              .toList(growable: false);
          _LifePaletteColor? expandedEntry;
          for (final entry in rowColors) {
            if (entry.stableKey == expandedKey) {
              expandedEntry = entry;
              break;
            }
          }

          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (var index = 0; index < columns; index += 1) ...<Widget>[
                  if (index > 0) SizedBox(width: spacing),
                  SizedBox(
                    width: itemWidth,
                    child: index < rowColors.length
                        ? _UnifiedColorTile(
                            entry: rowColors[index],
                            selected: expandedKey == rowColors[index].stableKey,
                            onTap: () => onToggle(rowColors[index]),
                          )
                        : const SizedBox(height: 154),
                  ),
                ],
              ],
            ),
          );

          if (expandedEntry != null) {
            final rowExpandedEntry = expandedEntry;
            rows.add(SizedBox(height: spacing));
            rows.add(
              _UnifiedColorRowDetails(
                entry: rowExpandedEntry,
                pagePreviewEnabled: pagePreviewEnabled,
                onTogglePagePreview: onTogglePagePreview,
                onCopyHex: () => onCopyHex(rowExpandedEntry),
                onCopyName: () => onCopyName(rowExpandedEntry),
              ),
            );
          }

          if (start + columns < colors.length) {
            rows.add(SizedBox(height: spacing));
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rows,
        );
      },
    );
  }
}

class _UnifiedColorTile extends StatelessWidget {
  const _UnifiedColorTile({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final _LifePaletteColor entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = entry.isLight ? Colors.black : Colors.white;
    return Tooltip(
      message: '${entry.name} ${entry.hex}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            height: 154,
            decoration: BoxDecoration(
              color: entry.color,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? foreground.withValues(alpha: 0.82)
                    : foreground.withValues(alpha: 0.14),
                width: selected ? 2 : 1,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: entry.color.withValues(alpha: selected ? 0.28 : 0.12),
                  blurRadius: selected ? 20 : 10,
                  offset: Offset(0, selected ? 10 : 5),
                ),
              ],
            ),
            child: _UnifiedColorSwatchHeader(
              entry: entry,
              foreground: foreground,
              selected: selected,
            ),
          ),
        ),
      ),
    );
  }
}

class _UnifiedColorSwatchHeader extends StatelessWidget {
  const _UnifiedColorSwatchHeader({
    required this.entry,
    required this.foreground,
    required this.selected,
  });

  final _LifePaletteColor entry;
  final Color foreground;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  entry.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: foreground,
                size: 22,
              ),
            ],
          ),
          const Spacer(),
          Text(
            entry.upperPhonetic,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground.withValues(alpha: 0.82),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            entry.hex,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnifiedColorRowDetails extends StatelessWidget {
  const _UnifiedColorRowDetails({
    required this.entry,
    required this.pagePreviewEnabled,
    required this.onTogglePagePreview,
    required this.onCopyHex,
    required this.onCopyName,
  });

  final _LifePaletteColor entry;
  final bool pagePreviewEnabled;
  final ValueChanged<bool> onTogglePagePreview;
  final VoidCallback onCopyHex;
  final VoidCallback onCopyName;

  @override
  Widget build(BuildContext context) {
    final foreground = entry.isLight ? Colors.black : Colors.white;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeInOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: entry.color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: foreground.withValues(alpha: 0.20)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: entry.color.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 520;
          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                entry.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                entry.upperPhonetic,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: foreground.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          );
          final values = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _LifeColorMetricChip(
                label: 'HEX',
                value: entry.hex,
                foreground: foreground,
              ),
              _LifeColorMetricChip(
                label: 'RGB',
                value: _lifeRgbText(entry),
                foreground: foreground,
              ),
              _LifeColorMetricChip(
                label: 'CMYK',
                value: _lifeCmykText(entry),
                foreground: foreground,
              ),
            ],
          );
          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _LifeColorActionButton(
                label: _lifeText(context, zh: '复制色值', en: 'Copy hex'),
                icon: Icons.copy_rounded,
                foreground: foreground,
                onPressed: onCopyHex,
              ),
              _LifeColorActionButton(
                label: _lifeText(context, zh: '复制色名', en: 'Copy name'),
                icon: Icons.badge_rounded,
                foreground: foreground,
                onPressed: onCopyName,
              ),
            ],
          );
          final backgroundSwitch = _LifeColorBackgroundSwitch(
            controlKey: const ValueKey<String>(
              'life_color_detail_background_toggle',
            ),
            value: pagePreviewEnabled,
            onChanged: onTogglePagePreview,
            foreground: foreground,
          );

          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                title,
                const SizedBox(height: 12),
                values,
                const SizedBox(height: 10),
                actions,
                const SizedBox(height: 10),
                backgroundSwitch,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(flex: 4, child: title),
              const SizedBox(width: 14),
              Expanded(
                flex: 7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    values,
                    const SizedBox(height: 10),
                    actions,
                    const SizedBox(height: 10),
                    backgroundSwitch,
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

String _lifeRgbText(_LifePaletteColor color) {
  return '${color.rgb[0]}, ${color.rgb[1]}, ${color.rgb[2]}';
}

String _lifeCmykText(_LifePaletteColor color) {
  return '${color.cmyk[0]}%, ${color.cmyk[1]}%, ${color.cmyk[2]}%, ${color.cmyk[3]}%';
}
