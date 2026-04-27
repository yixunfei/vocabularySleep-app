part of 'toolbox_singing_bowls_tool.dart';

// ============ 上拉 BottomSheet：frame / header / detail ============
// [风险] sheet 内部的 UI 状态需要和主页面 state 同步。采用 StatefulBuilder 包裹，
// 每次写回动作（setFrequency / setVoice / setAutoPlayInterval…）后额外调用
// sheetSetState，刷新 sheet 内的选中态与参数显示。仅属展示层同步，不侵入业务逻辑。
// 内部具体控件（频率列表 / 音色网格 / 自动播放）在 *_sheet_controls.dart 中。
// ===================================================================

extension _SingingBowlsSheet on _SingingBowlsPracticeCardState {
  void openControlsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.22),
      builder: (BuildContext sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.94,
          builder: (BuildContext ctx, ScrollController controller) {
            return StatefulBuilder(
              builder: (BuildContext ctx, StateSetter sheetSetState) {
                return _buildSheetBody(ctx, controller, sheetSetState);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSheetBody(
    BuildContext context,
    ScrollController controller,
    StateSetter sheetSetState,
  ) {
    final surface = Theme.of(context).colorScheme.surface;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color.lerp(surface, Colors.white, 0.65) ?? surface,
            surface,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.72),
          width: 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: EdgeInsets.fromLTRB(
                  18,
                  12,
                  18,
                  18 + MediaQuery.paddingOf(context).bottom,
                ),
                children: <Widget>[
                  _buildSheetHeader(context),
                  const SizedBox(height: 18),
                  _buildSheetDetailCard(context),
                  const SizedBox(height: 18),
                  sheetSectionTitle(
                    context,
                    title: t('频率菜单', 'Frequency menu'),
                    subtitle: t('七脉轮与古典共振频率', 'Chakra & resonance tones'),
                  ),
                  const SizedBox(height: 10),
                  buildSheetFrequencyGroup(
                    context,
                    groupLabel: t('七脉轮', 'Chakra series'),
                    group: _SingingBowlGroup.chakra,
                    sheetSetState: sheetSetState,
                  ),
                  const SizedBox(height: 14),
                  buildSheetFrequencyGroup(
                    context,
                    groupLabel: t('共振频率', 'Resonance tones'),
                    group: _SingingBowlGroup.resonance,
                    sheetSetState: sheetSetState,
                  ),
                  const SizedBox(height: 22),
                  sheetSectionTitle(
                    context,
                    title: t('音色', 'Voices'),
                    subtitle: t('四套钵体谐波', 'Four bowl harmonics'),
                  ),
                  const SizedBox(height: 10),
                  buildSheetVoiceGrid(context, sheetSetState),
                  const SizedBox(height: 22),
                  sheetSectionTitle(
                    context,
                    title: t('自动播放', 'Autoplay'),
                    subtitle: t('慢而宽地重复，不要急促敲击', 'Slow, spacious repetition'),
                  ),
                  const SizedBox(height: 10),
                  buildSheetAutoplay(context, sheetSetState),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetHeader(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                t('调音与节律', 'Tone & cadence'),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                t(
                  '挑一条频率，选一只音色，按你想要的节奏慢慢敲。',
                  'Pick a frequency, choose a voice, and tap at your own slow rhythm.',
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: t('收起', 'Close'),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }

  Widget _buildSheetDetailCard(BuildContext context) {
    final spec = frequencySpec;
    return ToolboxSurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      color: Colors.white.withValues(alpha: 0.64),
      radius: 22,
      borderColor: Colors.white.withValues(alpha: 0.78),
      shadowColor: spec.glow,
      shadowOpacity: 0.06,
      shadowBlur: 16,
      shadowOffsetY: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              ToolboxInfoPill(
                text: '${spec.note} · ${formatFrequency(spec.frequency)} Hz',
                accent: spec.accent,
                backgroundColor: Colors.white.withValues(alpha: 0.72),
                textColor: Theme.of(context).colorScheme.onSurface,
              ),
              ToolboxInfoPill(
                text: voiceSpec.name(isZh),
                accent: spec.glow,
                backgroundColor: Colors.white.withValues(alpha: 0.72),
                textColor: Theme.of(context).colorScheme.onSurface,
              ),
              if (_autoPlayEnabled)
                ToolboxInfoPill(
                  text: t(
                    '每 ${_autoPlayIntervalMs ~/ 1000} 秒自动敲击',
                    'Autoplay every ${_autoPlayIntervalMs ~/ 1000}s',
                  ),
                  accent: spec.accent.withValues(alpha: 0.78),
                  backgroundColor: Colors.white.withValues(alpha: 0.72),
                  textColor: Theme.of(context).colorScheme.onSurface,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            spec.name(isZh),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            spec.subtitle(isZh),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: spec.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            spec.description(isZh),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.55,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget sheetSectionTitle(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
