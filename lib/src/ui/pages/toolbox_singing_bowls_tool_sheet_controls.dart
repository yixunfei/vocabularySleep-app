part of 'toolbox_singing_bowls_tool.dart';

// ============ Sheet 控件：频率列表 / 音色网格 / 自动播放 ============
// 从 *_sheet.dart 拆分出来，仅负责 sheet 内部的具体控件渲染；
// sheet 的 frame / header / detail 仍留在 *_sheet.dart。
// ================================================================

extension _SingingBowlsSheetControls on _SingingBowlsPracticeCardState {
  Widget buildSheetFrequencyGroup(
    BuildContext context, {
    required String groupLabel,
    required _SingingBowlGroup group,
    required StateSetter sheetSetState,
  }) {
    final items = _bowlFrequencySpecs
        .where((s) => s.group == group)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            groupLabel,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        ...items.map(
          (spec) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildSheetFrequencyTile(context, spec, sheetSetState),
          ),
        ),
      ],
    );
  }

  Widget _buildSheetFrequencyTile(
    BuildContext context,
    _SingingBowlFrequencySpec spec,
    StateSetter sheetSetState,
  ) {
    final selected = spec.id == _frequencyId;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          setFrequency(spec.id);
          sheetSetState(() {});
        },
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withValues(alpha: 0.9)
                : Colors.white.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? spec.accent
                  : Colors.white.withValues(alpha: 0.62),
            ),
            boxShadow: <BoxShadow>[
              if (selected)
                BoxShadow(
                  color: spec.glow.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected
                      ? spec.accent
                      : Colors.white.withValues(alpha: 0.78),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
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
                    const SizedBox(height: 3),
                    Text(
                      '${formatFrequency(spec.frequency)} Hz · ${spec.subtitle(isZh)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              if (selected)
                Icon(Icons.graphic_eq_rounded, color: spec.accent, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSheetVoiceGrid(BuildContext context, StateSetter sheetSetState) {
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
                  child: _buildSheetVoiceTile(context, spec, sheetSetState),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }

  Widget _buildSheetVoiceTile(
    BuildContext context,
    _SingingBowlVoiceSpec spec,
    StateSetter sheetSetState,
  ) {
    final selected = spec.id == _voiceId;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          setVoice(spec.id);
          sheetSetState(() {});
        },
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withValues(alpha: 0.92)
                : Colors.white.withValues(alpha: 0.48),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? frequencySpec.accent
                  : Colors.white.withValues(alpha: 0.72),
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

  Widget buildSheetAutoplay(BuildContext context, StateSetter sheetSetState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                t('间隔时间', 'Interval'),
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              '${_autoPlayIntervalMs ~/ 1000}s',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: frequencySpec.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: frequencySpec.accent,
            inactiveTrackColor: frequencySpec.accent.withValues(alpha: 0.16),
            thumbColor: frequencySpec.accent,
            overlayColor: frequencySpec.accent.withValues(alpha: 0.12),
          ),
          child: Slider(
            min: _SingingBowlsPracticeCardState.minAutoPlayMs.toDouble(),
            max: _SingingBowlsPracticeCardState.maxAutoPlayMs.toDouble(),
            divisions:
                ((_SingingBowlsPracticeCardState.maxAutoPlayMs -
                            _SingingBowlsPracticeCardState.minAutoPlayMs) /
                        1000)
                    .round(),
            value: _autoPlayIntervalMs.toDouble(),
            onChanged: (double value) {
              setAutoPlayInterval(value.round());
              sheetSetState(() {});
            },
          ),
        ),
        Row(
          children: <Widget>[
            Text('2s', style: Theme.of(context).textTheme.bodySmall),
            const Spacer(),
            Text('30s', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          value: _hapticsEnabled,
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(t('触感反馈', 'Haptics')),
          subtitle: Text(
            t('手动敲击时给一点轻微反馈', 'Add a light pulse on manual strike'),
          ),
          onChanged: (bool value) {
            toggleHaptics(value);
            sheetSetState(() {});
          },
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            FilledButton.tonalIcon(
              onPressed: () {
                toggleAutoPlay();
                sheetSetState(() {});
              },
              icon: Icon(
                _autoPlayEnabled
                    ? Icons.pause_circle_filled_rounded
                    : Icons.play_circle_fill_rounded,
              ),
              label: Text(
                _autoPlayEnabled
                    ? t('暂停自动敲击', 'Pause autoplay')
                    : t('开始自动敲击', 'Start autoplay'),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {
                stopResonance();
                sheetSetState(() {});
              },
              icon: const Icon(Icons.stop_circle_outlined),
              label: Text(t('停止余振', 'Stop resonance')),
            ),
          ],
        ),
      ],
    );
  }
}
