part of 'toolbox_singing_bowls_tool.dart';

// ============ Wide 布局：tile 组件（音色 / 频率） ============
// 从 *_wide.dart 拆出，纯粹的展示层 tile 渲染。
// ============================================================

extension _SingingBowlsWideTiles on _SingingBowlsPracticeCardState {
  Widget buildWideVoiceGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const spacing = 10.0;
        final itemWidth = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: _bowlVoiceSpecs
              .map(
                (spec) => SizedBox(
                  width: itemWidth,
                  child: _buildWideVoiceTile(context, spec),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }

  Widget _buildWideVoiceTile(BuildContext context, _SingingBowlVoiceSpec spec) {
    final selected = spec.id == _voiceId;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => setVoice(spec.id),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withValues(alpha: 0.92)
                : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? frequencySpec.accent
                  : Colors.white.withValues(alpha: 0.78),
            ),
            boxShadow: <BoxShadow>[
              if (selected)
                BoxShadow(
                  color: frequencySpec.glow.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    spec.icon,
                    size: 18,
                    color: selected
                        ? frequencySpec.accent
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      spec.name(isZh),
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                spec.description(isZh),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  height: 1.42,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildWideFrequencyTile(
    BuildContext context,
    _SingingBowlFrequencySpec spec,
  ) {
    final selected = spec.id == _frequencyId;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => setFrequency(spec.id),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withValues(alpha: 0.92)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? spec.accent
                  : Colors.white.withValues(alpha: 0.24),
            ),
            boxShadow: <BoxShadow>[
              if (selected)
                BoxShadow(
                  color: spec.glow.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: selected
                      ? spec.accent
                      : Colors.white.withValues(alpha: 0.78),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    spec.note,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: selected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      spec.name(isZh),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${formatFrequency(spec.frequency)} Hz · ${spec.subtitle(isZh)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      spec.description(isZh),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.4,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (selected)
                Icon(Icons.graphic_eq_rounded, color: spec.accent, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
