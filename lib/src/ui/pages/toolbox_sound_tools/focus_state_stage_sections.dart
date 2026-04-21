part of '../toolbox_sound_tools.dart';

// ignore_for_file: dead_code, unused_element, unused_local_variable

extension _FocusBeatsToolStateStageSectionsX on _FocusBeatsToolState {
  Widget _buildMixSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('$label ${(value * 100).round()}%'),
        Slider(value: value, min: 0, max: 1, onChanged: onChanged),
      ],
    );
  }

  Widget _buildSelectionSummary(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _linkAnimationAndSound ? '动画与音色已结对' : '动画与音色独立选择',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: _previewCurrentSound,
                icon: const Icon(Icons.graphic_eq_rounded),
                label: const Text('试音'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _linkAnimationAndSound
                ? '切换动画时会同步匹配推荐音色，适合更完整的拟真体验。'
                : '视觉和音色可自由组合，适合按个人偏好做混搭。',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.35),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _FocusInfoPill(
                icon: _animationKind.icon,
                label: _animationLabel(_animationKind),
              ),
              _FocusInfoPill(
                icon: _soundKind.icon,
                label: _soundLabel(_soundKind),
              ),
              _FocusInfoPill(
                icon: Icons.auto_awesome_motion_rounded,
                label: _linkAnimationAndSound ? '推荐结对' : '自由混搭',
                emphasized: _linkAnimationAndSound,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _linkAnimationAndSound,
            onChanged: _setLinkAnimationAndSound,
            title: const Text('切换时自动匹配推荐音色'),
            subtitle: Text(
              _linkAnimationAndSound ? '当前会将动画与对应音色保持同步。' : '关闭后可以单独调整动画和音色。',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealismMeter(
    BuildContext context, {
    required int score,
    required String label,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        for (var i = 0; i < 5; i += 1)
          Container(
            width: 9,
            height: 9,
            margin: EdgeInsets.only(right: i == 4 ? 0 : 4),
            decoration: BoxDecoration(
              color: i < score
                  ? colorScheme.primary
                  : colorScheme.outlineVariant.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }

  Widget _buildAnimationOptionTile(
    BuildContext context,
    _FocusBeatAnimationKind kind,
  ) {
    final selected = _animationKind == kind;
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _setAnimationKind(kind),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primaryContainer.withValues(alpha: 0.9)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outlineVariant,
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
                    color: selected
                        ? colorScheme.primary.withValues(alpha: 0.14)
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    kind.icon,
                    color: selected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _animationLabel(kind),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: colorScheme.primary,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _animationDescription(kind),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(height: 1.35),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: <Widget>[
                _buildRealismMeter(
                  context,
                  score: _animationRealism(kind),
                  label: _realismLabel(_animationRealism(kind)),
                ),
                Text(
                  _animationSyncHint(kind),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundOptionTile(BuildContext context, _FocusBeatSoundKind kind) {
    final selected = _soundKind == kind;
    final colorScheme = Theme.of(context).colorScheme;
    final pairedAnimation = _pairedAnimationForSound(kind);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _setSoundKind(kind),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.secondaryContainer.withValues(alpha: 0.9)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? colorScheme.secondary
                : colorScheme.outlineVariant,
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
                    color: selected
                        ? colorScheme.secondary.withValues(alpha: 0.14)
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    kind.icon,
                    color: selected
                        ? colorScheme.secondary
                        : colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _soundLabel(kind),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: colorScheme.secondary,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _soundDescription(kind),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(height: 1.35),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: <Widget>[
                _buildRealismMeter(
                  context,
                  score: _soundRealism(kind),
                  label: _realismLabel(_soundRealism(kind)),
                ),
                Text(
                  '推荐动画：${_animationLabel(pairedAnimation)}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTempoSection(BuildContext context) {
    final tempoI18n = _i18nOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          pickUiText(
            tempoI18n,
            zh: '当前 $_bpm BPM，每拍 ${(60 / _bpm).toStringAsFixed(2)} 秒',
            en: 'Current tempo: $_bpm BPM, ${(60 / _bpm).toStringAsFixed(2)} s per beat',
          ),
        ),
        Slider(
          value: _bpm.toDouble(),
          min: 30,
          max: 220,
          divisions: 190,
          onChanged: (value) => _setBpm(value.round()),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            OutlinedButton(
              onPressed: () => _setBpm(_bpm - 5),
              child: const Text('-5'),
            ),
            OutlinedButton(
              onPressed: () => _setBpm(_bpm - 1),
              child: const Text('-1'),
            ),
            OutlinedButton(
              onPressed: () => _setBpm(_bpm + 1),
              child: const Text('+1'),
            ),
            OutlinedButton(
              onPressed: () => _setBpm(_bpm + 5),
              child: const Text('+5'),
            ),
            for (final quick in <int>[60, 72, 90, 108, 120, 144])
              ChoiceChip(
                label: Text('$quick'),
                selected: _bpm == quick,
                onSelected: (_) => _setBpm(quick),
              ),
          ],
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Tempo · $_bpm BPM · ${(60 / _bpm).toStringAsFixed(2)} 秒/拍'),
        Slider(
          value: _bpm.toDouble(),
          min: 30,
          max: 220,
          divisions: 190,
          onChanged: (value) => _setBpm(value.round()),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            OutlinedButton(
              onPressed: () => _setBpm(_bpm - 5),
              child: const Text('-5'),
            ),
            OutlinedButton(
              onPressed: () => _setBpm(_bpm - 1),
              child: const Text('-1'),
            ),
            OutlinedButton(
              onPressed: () => _setBpm(_bpm + 1),
              child: const Text('+1'),
            ),
            OutlinedButton(
              onPressed: () => _setBpm(_bpm + 5),
              child: const Text('+5'),
            ),
            for (final quick in <int>[60, 72, 90, 108, 120, 144])
              ChoiceChip(
                label: Text('$quick'),
                selected: _bpm == quick,
                onSelected: (_) => _setBpm(quick),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMeterSection(BuildContext context) {
    final meterI18n = _i18nOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          pickUiText(
            meterI18n,
            zh: '拍号决定重拍结构，细分决定每拍内的密度，两者都会直接影响舞台节奏。',
            en: 'Meter defines the strong-beat structure, while subdivisions control pulse density inside each beat.',
          ),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.35),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <int>[2, 3, 4, 5, 6, 7, 8]
              .map(
                (count) => ChoiceChip(
                  label: Text('$count/4'),
                  selected: _beatsPerBar == count,
                  onSelected: (_) => _setBeatsPerBar(count),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <int>[1, 2, 3, 4]
              .map(
                (division) => ChoiceChip(
                  label: Text(
                    pickUiText(
                      meterI18n,
                      zh: '子拍 ×$division',
                      en: 'Sub ×$division',
                    ),
                  ),
                  selected: _subdivision == division,
                  onSelected: (_) => _setSubdivision(division),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '拍号决定强弱拍结构，子拍决定每拍内部切分；两者会同步影响动画节奏和循环编排。',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.35),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <int>[2, 3, 4, 5, 6, 7, 8]
              .map(
                (count) => ChoiceChip(
                  label: Text('$count/4'),
                  selected: _beatsPerBar == count,
                  onSelected: (_) => _setBeatsPerBar(count),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <int>[1, 2, 3, 4]
              .map(
                (division) => ChoiceChip(
                  label: Text('子拍 ×$division'),
                  selected: _subdivision == division,
                  onSelected: (_) => _setSubdivision(division),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }

  Widget _buildStyleSection(BuildContext context) {
    final styleI18n = _i18nOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                _linkAnimationAndSound
                    ? pickUiText(
                        styleI18n,
                        zh: '动画与音色保持联动，适合快速切换一致风格。',
                        en: 'Animation and timbre are linked for fast style switching.',
                      )
                    : pickUiText(
                        styleI18n,
                        zh: '动画与音色独立选择，适合细调个人偏好。',
                        en: 'Animation and timbre are independent for finer tuning.',
                      ),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.35),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.tonalIcon(
              onPressed: _previewCurrentSound,
              icon: const Icon(Icons.graphic_eq_rounded),
              label: Text(pickUiText(styleI18n, zh: '试听', en: 'Preview')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: _linkAnimationAndSound,
          onChanged: _setLinkAnimationAndSound,
          title: Text(
            pickUiText(
              styleI18n,
              zh: '联动动画与音色',
              en: 'Link animation and timbre',
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          pickUiText(styleI18n, zh: '舞台动画', en: 'Stage animation'),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final kind in _FocusBeatAnimationKind.values)
              ChoiceChip(
                avatar: Icon(kind.icon, size: 18),
                label: Text(_animationName(context, kind)),
                selected: _animationKind == kind,
                onSelected: (_) => _setAnimationKind(kind),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          pickUiText(styleI18n, zh: '节拍音色', en: 'Beat timbre'),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final kind in _FocusBeatSoundKind.values)
              ChoiceChip(
                avatar: Icon(kind.icon, size: 18),
                label: Text(_soundName(context, kind)),
                selected: _soundKind == kind,
                onSelected: (_) => _setSoundKind(kind),
              ),
          ],
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSelectionSummary(context),
        const SizedBox(height: 14),
        Text(
          '动画样式',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        for (final kind in _FocusBeatAnimationKind.values) ...<Widget>[
          _buildAnimationOptionTile(context, kind),
          if (kind != _FocusBeatAnimationKind.values.last)
            const SizedBox(height: 10),
        ],
        const SizedBox(height: 16),
        Text(
          '音色样式',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        for (final kind in _FocusBeatSoundKind.values) ...<Widget>[
          _buildSoundOptionTile(context, kind),
          if (kind != _FocusBeatSoundKind.values.last)
            const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildArrangementSection(
    BuildContext context, {
    required String arrangementLabel,
  }) {
    final arrangementI18n = _i18nOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            _patternEnabled
                ? pickUiText(
                    arrangementI18n,
                    zh: '循环编排已启用',
                    en: 'Loop arrangement is enabled',
                  )
                : pickUiText(
                    arrangementI18n,
                    zh: '当前为单小节循环',
                    en: 'Currently using a single-bar loop',
                  ),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            pickUiText(
              arrangementI18n,
              zh: '当前编排：$arrangementLabel，共 ${_arrangementBeats.fold<int>(0, (sum, item) => sum + item)} 拍',
              en: 'Current arrangement: $arrangementLabel, ${_arrangementBeats.fold<int>(0, (sum, item) => sum + item)} beats in total',
            ),
          ),
          trailing: FilledButton.tonalIcon(
            onPressed: _openArrangementEditor,
            icon: const Icon(Icons.edit_note_rounded),
            label: Text(pickUiText(arrangementI18n, zh: '编辑', en: 'Edit')),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          pickUiText(
            arrangementI18n,
            zh: '通过段落组合，让动画和发音在一个循环里形成更清晰的推进感。',
            en: 'Combine phrases to create clearer motion and click progression inside each loop.',
          ),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.35),
        ),
        const SizedBox(height: 12),
        _buildPatternPreview(context),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            _patternEnabled ? '循环编排已启用' : '当前为单小节循环',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            '当前编排：$arrangementLabel（共 ${_arrangementBeats.fold<int>(0, (sum, item) => sum + item)} 拍）',
          ),
          trailing: FilledButton.tonalIcon(
            onPressed: _openArrangementEditor,
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text('编辑'),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '通过拍段组合可以让视觉与音色在一轮循环里形成更明显的段落感。',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.35),
        ),
        const SizedBox(height: 12),
        _buildPatternPreview(context),
      ],
    );
  }

  Widget _buildMixSection(BuildContext context) {
    final mixI18n = _i18nOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildMixSlider(
          label: pickUiText(mixI18n, zh: '总音量', en: 'Master'),
          value: _masterVolume,
          onChanged: (value) {
            _setViewState(() => _masterVolume = value);
            _scheduleSavePrefs();
          },
        ),
        _buildMixSlider(
          label: pickUiText(mixI18n, zh: '重拍', en: 'Accent'),
          value: _accentVolume,
          onChanged: (value) {
            _setViewState(() => _accentVolume = value);
            _scheduleSavePrefs();
          },
        ),
        _buildMixSlider(
          label: pickUiText(mixI18n, zh: '常规拍', en: 'Regular'),
          value: _regularVolume,
          onChanged: (value) {
            _setViewState(() => _regularVolume = value);
            _scheduleSavePrefs();
          },
        ),
        _buildMixSlider(
          label: pickUiText(mixI18n, zh: '子拍', en: 'Subdivision'),
          value: _subdivisionVolume,
          onChanged: (value) {
            _setViewState(() => _subdivisionVolume = value);
            _scheduleSavePrefs();
          },
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: _hapticsEnabled,
          onChanged: (value) {
            _setViewState(() => _hapticsEnabled = value);
            _scheduleSavePrefs();
          },
          title: Text(pickUiText(mixI18n, zh: '触感反馈', en: 'Haptic feedback')),
          subtitle: Text(
            pickUiText(
              mixI18n,
              zh: '在重拍和段落切换时给出更清晰的手机震动提示。',
              en: 'Add clearer vibration cues on accents and phrase changes.',
            ),
          ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildMixSlider(
          label: '总音量',
          value: _masterVolume,
          onChanged: (value) {
            _setViewState(() => _masterVolume = value);
            _scheduleSavePrefs();
          },
        ),
        _buildMixSlider(
          label: '重拍',
          value: _accentVolume,
          onChanged: (value) {
            _setViewState(() => _accentVolume = value);
            _scheduleSavePrefs();
          },
        ),
        _buildMixSlider(
          label: '普通拍',
          value: _regularVolume,
          onChanged: (value) {
            _setViewState(() => _regularVolume = value);
            _scheduleSavePrefs();
          },
        ),
        _buildMixSlider(
          label: '子拍',
          value: _subdivisionVolume,
          onChanged: (value) {
            _setViewState(() => _subdivisionVolume = value);
            _scheduleSavePrefs();
          },
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: _hapticsEnabled,
          onChanged: (value) {
            _setViewState(() => _hapticsEnabled = value);
            _scheduleSavePrefs();
          },
          title: const Text('触感反馈'),
          subtitle: const Text('重拍与段落切换时提供更明确的触觉提示。'),
        ),
      ],
    );
  }

  Widget _buildHeroSummary(
    BuildContext context, {
    required String beatLabel,
    required String subBeatLabel,
    required String segmentLabel,
    required String cycleLabel,
    required String arrangementLabel,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final palette = _visualPalette(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[palette.panelStrong, palette.panel],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: palette.stroke.withValues(alpha: 0.42)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _FocusInfoPill(
                icon: Icons.blur_on_rounded,
                label: '专注节拍工作台',
                emphasized: true,
                tone: palette.accent,
              ),
              _FocusInfoPill(
                icon: Icons.motion_photos_on_rounded,
                label: _running ? '当前正在驱动节奏' : '已准备好开始',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '把节拍收束成一条注意力轨迹',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _running
                ? '视觉、声音与拍点已经同步运行，保持动作或呼吸跟着这一条节奏线推进。'
                : '把 BPM、编排、音色与触感反馈整理进同一块舞台，开播前的信息一眼就够。',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _FocusHeroMetric(
                label: '节奏',
                value: '$_bpm BPM',
                caption: '${(60 / _bpm).toStringAsFixed(2)} 秒/拍',
              ),
              _FocusHeroMetric(
                label: '拍号',
                value: '$_beatsPerBar/4 × $_subdivision',
                caption: '决定强弱拍与子拍密度',
              ),
              _FocusHeroMetric(
                label: '当前拍',
                value: '$beatLabel · $subBeatLabel',
                caption: _running ? '跟随当下脉冲' : '等待开始',
              ),
              _FocusHeroMetric(
                label: '段落',
                value: segmentLabel,
                caption: '循环中的当前位置',
              ),
              _FocusHeroMetric(
                label: '循环',
                value: cycleLabel,
                caption: arrangementLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryControls(
    BuildContext context, {
    bool immersiveSheet = false,
  }) {
    final controlI18n = _i18nOf(context);
    final controlColorScheme = Theme.of(context).colorScheme;
    final controlPalette = _visualPalette(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: controlColorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: controlPalette.stroke.withValues(alpha: 0.30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: controlPalette.accent,
                    foregroundColor: const Color(0xFF09111B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: _running ? _stop : _start,
                  icon: Icon(
                    _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  ),
                  label: Text(
                    _running
                        ? pickUiText(controlI18n, zh: '停止节拍', en: 'Stop')
                        : pickUiText(controlI18n, zh: '开始节拍', en: 'Start'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: _tapTempo,
                icon: const Icon(Icons.touch_app_rounded),
                label: const Text('Tap'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilledButton.tonalIcon(
                onPressed: _previewCurrentSound,
                icon: const Icon(Icons.graphic_eq_rounded),
                label: Text(
                  pickUiText(controlI18n, zh: '试听当前音色', en: 'Preview sound'),
                ),
              ),
              if (!widget.fullScreen && widget.onOpenFullScreen != null)
                FilledButton.tonalIcon(
                  onPressed: () {
                    widget.onOpenFullScreen?.call(
                      autoStart: _running,
                      immersive: true,
                    );
                  },
                  icon: const Icon(Icons.open_in_full_rounded),
                  label: Text(
                    pickUiText(
                      controlI18n,
                      zh: '全屏舞台',
                      en: 'Full-screen stage',
                    ),
                  ),
                ),
              if (widget.fullScreen && !immersiveSheet)
                FilledButton.tonalIcon(
                  onPressed: _openImmersiveControlsSheet,
                  icon: const Icon(Icons.tune_rounded),
                  label: Text(
                    pickUiText(controlI18n, zh: '唤起控制', en: 'Open controls'),
                  ),
                ),
              if (widget.fullScreen && immersiveSheet)
                FilledButton.tonalIcon(
                  onPressed: widget.onExitFullScreen,
                  icon: const Icon(Icons.close_rounded),
                  label: Text(
                    pickUiText(controlI18n, zh: '退出全屏', en: 'Exit full screen'),
                  ),
                )
              else if (!widget.fullScreen)
                OutlinedButton.icon(
                  onPressed: _toggleImmersiveMode,
                  icon: const Icon(Icons.fullscreen_rounded),
                  label: Text(
                    pickUiText(controlI18n, zh: '沉浸全屏', en: 'Immersive stage'),
                  ),
                ),
              _FocusInfoPill(
                icon: Icons.auto_graph_rounded,
                label: _linkAnimationAndSound
                    ? pickUiText(
                        controlI18n,
                        zh: '动画音色联动',
                        en: 'Linked AV style',
                      )
                    : pickUiText(
                        controlI18n,
                        zh: '动画音色分离',
                        en: 'Split AV style',
                      ),
                emphasized: _linkAnimationAndSound,
                tone: controlPalette.accent,
              ),
              _FocusInfoPill(
                icon: Icons.vibration_rounded,
                label: _hapticsEnabled
                    ? pickUiText(controlI18n, zh: '触感已开', en: 'Haptics on')
                    : pickUiText(controlI18n, zh: '触感已关', en: 'Haptics off'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            pickUiText(
              controlI18n,
              zh: 'Tap 用于快速敲定速度；全屏后单击舞台呼出悬浮控件，上滑唤起完整菜单。',
              en: 'Use Tap to capture tempo quickly. In full screen, tap the stage for HUD controls and swipe up for the full menu.',
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: controlColorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
