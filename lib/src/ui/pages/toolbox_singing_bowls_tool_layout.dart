part of 'toolbox_singing_bowls_tool.dart';

// ============ Layout：移动端三段式 + 共享样式 helpers ============
// 移动端新结构：Header (48dp) + Stage (扩展至约 55% 屏高) + SummaryBar (60dp)
// - SummaryBar 本体即"把手"，整条可点击 → 打开上拉 Sheet
// - Header 极轻：返回 + 静音 + 自动播放；主副标题都收到 Sheet 里
// [歧义] 宽屏结构保留原骨架，只套新自然色，相关 widget 已迁至 *_wide.dart；
// 本文件同时托管了被双端共用的 _pillIcon / _infoPill / _wideSectionTitle /
// _panelDecoration / _buildActionButton 辅助方法。
// =================================================================

extension _SingingBowlsLayout on _SingingBowlsPracticeCardState {
  Widget buildMobileLayout(BuildContext context, BoxConstraints constraints) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Column(
        children: <Widget>[
          _buildMobileHeader(context),
          const SizedBox(height: 8),
          Expanded(child: buildStage(context, compact: true)),
          const SizedBox(height: 10),
          _buildSummaryBar(context),
        ],
      ),
    );
  }

  Widget _buildMobileHeader(BuildContext context) {
    return Row(
      children: <Widget>[
        _pillIcon(
          context,
          icon: Icons.arrow_back_rounded,
          active: false,
          onTap: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            t('空灵音钵', 'Healing bowls'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
        ),
        _pillIcon(
          context,
          icon: _soundEnabled
              ? Icons.volume_up_rounded
              : Icons.volume_off_rounded,
          active: _soundEnabled,
          onTap: toggleSound,
        ),
        const SizedBox(width: 8),
        _pillIcon(
          context,
          icon: _autoPlayEnabled
              ? Icons.pause_circle_filled_rounded
              : Icons.play_circle_fill_rounded,
          active: _autoPlayEnabled,
          onTap: toggleAutoPlay,
        ),
      ],
    );
  }

  Widget _buildSummaryBar(BuildContext context) {
    final spec = frequencySpec;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => openControlsSheet(context),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.84),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.88)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: spec.glow.withValues(alpha: 0.22),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: spec.accent,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  spec.note,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      spec.name(isZh),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _summaryLine(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: spec.accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.keyboard_arrow_up_rounded,
                  size: 22,
                  color: spec.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _summaryLine() {
    final head =
        '${formatFrequency(frequencySpec.frequency)} Hz · '
        '${voiceSpec.name(isZh)}';
    if (!_autoPlayEnabled) {
      return head;
    }
    final interval = _autoPlayIntervalMs ~/ 1000;
    return head + t(' · 自动 ${interval}s', ' · Auto ${interval}s');
  }

  // ============ 被双端共享的辅助样式方法 ============

  Widget wideSectionTitle(
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

  Widget buildWideActionButton(
    BuildContext context, {
    required IconData icon,
    required bool active,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return ToolboxIconPillButton(
      icon: icon,
      active: active,
      onTap: onTap,
      tint: frequencySpec.accent,
      tooltip: tooltip,
    );
  }

  Widget _pillIcon(
    BuildContext context, {
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return ToolboxIconPillButton(
      icon: icon,
      active: active,
      onTap: onTap,
      tint: frequencySpec.accent,
    );
  }

  Widget widePillIcon(
    BuildContext context, {
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) => _pillIcon(context, icon: icon, active: active, onTap: onTap);

  Widget wideInfoPill(
    BuildContext context, {
    required String text,
    required Color accent,
  }) {
    return ToolboxInfoPill(
      text: text,
      accent: accent,
      backgroundColor: Colors.white.withValues(alpha: 0.6),
      textColor: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }

  BoxDecoration widePanelDecoration(
    BuildContext context, {
    double alpha = 0.74,
    double radius = 30,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: alpha),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 26,
          offset: const Offset(0, 14),
        ),
      ],
    );
  }
}
