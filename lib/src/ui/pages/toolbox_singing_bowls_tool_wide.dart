part of 'toolbox_singing_bowls_tool.dart';

// ============ Wide 布局：≥ 760dp 的桌面/平板形态 ============
// 结构保留原"左侧 sidebar + 右侧 summary/stage/footer/settings"，仅更换为自然色 palette。
// 辅助方法（wideSectionTitle / widePanelDecoration / wideInfoPill / widePillIcon）
// 定义在 toolbox_singing_bowls_tool_layout.dart 中共享复用。
// ============================================================

extension _SingingBowlsWide on _SingingBowlsPracticeCardState {
  Widget buildWideLayout(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Row(
        children: <Widget>[
          SizedBox(width: 308, child: _buildSidebar(context)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    buildWideActionButton(
                      context,
                      icon: _soundEnabled
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      active: _soundEnabled,
                      tooltip: _soundEnabled
                          ? t('点击静音', 'Mute')
                          : t('点击恢复声音', 'Enable sound'),
                      onTap: toggleSound,
                    ),
                    const SizedBox(width: 10),
                    buildWideActionButton(
                      context,
                      icon: _autoPlayEnabled
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_fill_rounded,
                      active: _autoPlayEnabled,
                      tooltip: _autoPlayEnabled
                          ? t('暂停自动敲击', 'Pause autoplay')
                          : t('开始自动敲击', 'Start autoplay'),
                      onTap: toggleAutoPlay,
                    ),
                    const SizedBox(width: 10),
                    buildWideActionButton(
                      context,
                      icon: Icons.stop_circle_outlined,
                      active: false,
                      tooltip: t('停止余振', 'Stop resonance'),
                      onTap: stopResonance,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: _buildWideSummaryCard(context),
                ),
                const SizedBox(height: 18),
                Expanded(child: buildStage(context, compact: false)),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Expanded(child: _buildWideFooterCard(context)),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 320,
                      child: _buildWideSettingsCard(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return DecoratedBox(
      decoration: widePanelDecoration(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                widePillIcon(
                  context,
                  icon: Icons.arrow_back_rounded,
                  active: false,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    t('返回工具箱', 'Back to toolbox'),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              t('空灵音钵', 'Healing bowls'),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              t(
                '十一组自然色调谐的频率与四套钵体谐波，给长时间聆听一个更温润的入口。',
                'Eleven nature-tuned frequencies and four bowl voices, shaped for a softer, longer listening session.',
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.45,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            wideSectionTitle(
              context,
              title: t('音色', 'Voices'),
              subtitle: t(
                '四套钵体谐波，慢慢换着听',
                'Four harmonic profiles to rotate through',
              ),
            ),
            const SizedBox(height: 10),
            buildWideVoiceGrid(context),
            const SizedBox(height: 18),
            wideSectionTitle(
              context,
              title: t('频率菜单', 'Frequency menu'),
              subtitle: t('七脉轮与古典共振频率', 'Chakra and resonance tones'),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: _bowlFrequencySpecs.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (BuildContext context, int index) {
                  final spec = _bowlFrequencySpecs[index];
                  return buildWideFrequencyTile(context, spec);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideSummaryCard(BuildContext context) {
    final spec = frequencySpec;
    return DecoratedBox(
      decoration: widePanelDecoration(context, alpha: 0.68, radius: 28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                wideInfoPill(
                  context,
                  text: '${spec.note} · ${formatFrequency(spec.frequency)} Hz',
                  accent: spec.accent,
                ),
                wideInfoPill(
                  context,
                  text: voiceSpec.name(isZh),
                  accent: spec.glow,
                ),
                if (_autoPlayEnabled)
                  wideInfoPill(
                    context,
                    text: t(
                      '每 ${_autoPlayIntervalMs ~/ 1000} 秒自动敲击',
                      'Autoplay every ${_autoPlayIntervalMs ~/ 1000}s',
                    ),
                    accent: spec.accent.withValues(alpha: 0.78),
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
            const SizedBox(height: 6),
            Text(
              '${spec.subtitle(isZh)} · ${voiceSpec.description(isZh)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: spec.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              spec.description(isZh),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.52,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideFooterCard(BuildContext context) {
    final spec = frequencySpec;
    return DecoratedBox(
      decoration: widePanelDecoration(context, alpha: 0.64, radius: 26),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              t('当前共振建议', 'Current listening note'),
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 10),
            Text(
              t(
                '夜里想要沉一点，优先尝试"深邃 + 地球 / 174 Hz"；白天短时调息，"水晶 + 和谐 / 528 Hz / 639 Hz"会更轻一些。',
                'At night, try Deep with Om / Earth or 174 Hz. For lighter daytime reset sessions, Crystal with Harmony, 528 Hz, or 639 Hz feels gentler.',
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.52,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                wideInfoPill(
                  context,
                  text: t('自然色调谐频率', 'Nature-tuned tones'),
                  accent: spec.accent,
                ),
                wideInfoPill(
                  context,
                  text: t('柔和扩散衰减', 'Soft spectral decay'),
                  accent: spec.glow,
                ),
                wideInfoPill(
                  context,
                  text: t('上拉抽屉控制', 'Pull-up sheet controls'),
                  accent: spec.accent.withValues(alpha: 0.78),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideSettingsCard(BuildContext context) {
    return DecoratedBox(
      decoration: widePanelDecoration(context, alpha: 0.7, radius: 26),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            wideSectionTitle(
              context,
              title: t('自动播放', 'Autoplay'),
              subtitle: t('慢而宽地重复，不要急促敲击', 'Slow, spacious repetition'),
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    t('间隔时间', 'Interval'),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
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
            const SizedBox(height: 4),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: frequencySpec.accent,
                inactiveTrackColor: frequencySpec.accent.withValues(
                  alpha: 0.16,
                ),
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
                onChanged: (double value) => setAutoPlayInterval(value.round()),
              ),
            ),
            Row(
              children: <Widget>[
                Text('2s', style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
                Text('30s', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              value: _hapticsEnabled,
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(t('触感反馈', 'Haptics')),
              subtitle: Text(
                t('手动敲击时提供轻微反馈', 'Add a light pulse on manual strike'),
              ),
              onChanged: toggleHaptics,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                FilledButton.tonalIcon(
                  onPressed: toggleAutoPlay,
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
                  onPressed: stopResonance,
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: Text(t('停止余振', 'Stop resonance')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
