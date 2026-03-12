import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_i18n.dart';
import '../../models/play_config.dart';
import '../../state/app_state.dart';
import '../legacy_style.dart';
import '../theme/app_theme.dart';
import '../ui_copy.dart';
import '../widgets/section_header.dart';

class AppearanceStudioPage extends StatelessWidget {
  const AppearanceStudioPage({super.key});

  static const List<String> _themes = <String>[
    'flat',
    'tech',
    'dark',
    'fantasy',
    'nature',
    'sunset',
    'ocean',
    'mono',
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final i18n = AppI18n(state.uiLanguage);
    final config = state.config;
    final appearance = config.appearance;
    final mode = experienceModeFromAppearance(appearance);
    final tokens = AppThemeTokens.of(context);

    final fontScaleValue = ((appearance.normalizedFontScale - 0.85) / 0.6)
        .clamp(0.0, 1.0)
        .toDouble();
    final imageOpacity = appearance.normalizedBackgroundImageOpacity
        .clamp(0.0, 0.8)
        .toDouble();

    return Scaffold(
      appBar: AppBar(
        title: Text(pickUiText(i18n, zh: '外观工作室', en: 'Appearance studio')),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compactWidth = constraints.maxWidth < 390;
          final sectionPadding = compactWidth ? 14.0 : 18.0;
          final sectionSpacing = compactWidth ? 14.0 : 16.0;
          final controlSpacing = compactWidth ? 8.0 : 10.0;
          final listBottomPadding = compactWidth ? 20.0 : 24.0;

          return ListView(
            padding: EdgeInsets.fromLTRB(16, 12, 16, listBottomPadding),
            children: <Widget>[
              _sectionCard(
                padding: sectionPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SectionHeader(
                      title: pickUiText(
                        i18n,
                        zh: '体验模式',
                        en: 'Experience mode',
                      ),
                      subtitle: pickUiText(
                        i18n,
                        zh: '快速切换助眠/专注视觉。',
                        en: 'Quick switch between sleep and focus.',
                      ),
                    ),
                    SizedBox(height: compactWidth ? 10 : 12),
                    SegmentedButton<AppExperienceMode>(
                      segments: AppExperienceMode.values
                          .map(
                            (item) => ButtonSegment<AppExperienceMode>(
                              value: item,
                              label: Text(experienceModeTitle(i18n, item)),
                            ),
                          )
                          .toList(growable: false),
                      selected: <AppExperienceMode>{mode},
                      onSelectionChanged: (selection) {
                        _apply(
                          state,
                          config,
                          applyExperienceMode(appearance, selection.first),
                        );
                      },
                    ),
                    SizedBox(height: controlSpacing),
                    OutlinedButton.icon(
                      onPressed: () =>
                          _apply(state, config, AppearanceConfig.defaults),
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: Text(i18n.t('appearanceReset')),
                    ),
                  ],
                ),
              ),
              SizedBox(height: sectionSpacing),
              _sectionCard(
                padding: sectionPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SectionHeader(
                      title: i18n.t('appearanceTypographyTitle'),
                      subtitle: pickUiText(
                        i18n,
                        zh: '字体家族、字号缩放、字重。',
                        en: 'Font family, scale, and weights.',
                      ),
                    ),
                    SizedBox(height: compactWidth ? 10 : 12),
                    DropdownButtonFormField<String>(
                      initialValue: appearance.normalizedTheme,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: i18n.t('appearanceThemeTitle'),
                      ),
                      items: _themes
                          .map(
                            (value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(_themeLabel(i18n, value)),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) return;
                        _apply(
                          state,
                          config,
                          appearance.copyWith(theme: value),
                        );
                      },
                    ),
                    SizedBox(height: controlSpacing),
                    DropdownButtonFormField<String>(
                      initialValue: appearance.normalizedFontFamilyKey,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: i18n.t('appearanceFontFamily'),
                      ),
                      items: <DropdownMenuItem<String>>[
                        DropdownMenuItem(
                          value: 'system',
                          child: Text(i18n.t('appearanceFontFamilySystem')),
                        ),
                        DropdownMenuItem(
                          value: 'serif',
                          child: Text(i18n.t('appearanceFontFamilySerif')),
                        ),
                        DropdownMenuItem(
                          value: 'mono',
                          child: Text(i18n.t('appearanceFontFamilyMono')),
                        ),
                        DropdownMenuItem(
                          value: 'rounded',
                          child: Text(i18n.t('appearanceFontFamilyRounded')),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        _apply(
                          state,
                          config,
                          appearance.copyWith(fontFamilyKey: value),
                        );
                      },
                    ),
                    SizedBox(height: controlSpacing),
                    _slider(
                      context,
                      compact: compactWidth,
                      title: i18n.t('appearanceFontScale'),
                      subtitle: i18n.t('appearanceFontScaleHint'),
                      value: fontScaleValue,
                      valueLabel: appearance.normalizedFontScale
                          .toStringAsFixed(2),
                      onChanged: (value) {
                        final mapped = 0.85 + value * 0.6;
                        _apply(
                          state,
                          config,
                          appearance.copyWith(fontScale: mapped),
                        );
                      },
                    ),
                    SizedBox(height: controlSpacing),
                    DropdownButtonFormField<String>(
                      initialValue: appearance.normalizedTitleWeightKey,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: i18n.t('appearanceTitleWeight'),
                      ),
                      items: _weights(i18n),
                      onChanged: (value) {
                        if (value == null) return;
                        _apply(
                          state,
                          config,
                          appearance.copyWith(titleWeightKey: value),
                        );
                      },
                    ),
                    SizedBox(height: controlSpacing),
                    DropdownButtonFormField<String>(
                      initialValue: appearance.normalizedBodyWeightKey,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: i18n.t('appearanceBodyWeight'),
                      ),
                      items: _weights(i18n),
                      onChanged: (value) {
                        if (value == null) return;
                        _apply(
                          state,
                          config,
                          appearance.copyWith(bodyWeightKey: value),
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: sectionSpacing),
              _sectionCard(
                padding: sectionPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SectionHeader(
                      title: i18n.t('appearanceColorsTitle'),
                      subtitle: pickUiText(
                        i18n,
                        zh: '配色、透明度与面板材质。',
                        en: 'Colors, opacity, and panel styles.',
                      ),
                    ),
                    SizedBox(height: controlSpacing),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: appearance.compactLayout,
                      title: Text(i18n.t('appearanceCompactLayout')),
                      subtitle: Text(i18n.t('appearanceCompactLayoutHint')),
                      onChanged: (value) => _apply(
                        state,
                        config,
                        appearance.copyWith(compactLayout: value),
                      ),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: appearance.frostedPanels,
                      title: Text(i18n.t('appearanceFrostedPanels')),
                      subtitle: Text(i18n.t('appearanceFrostedPanelsHint')),
                      onChanged: (value) => _apply(
                        state,
                        config,
                        appearance.copyWith(frostedPanels: value),
                      ),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: appearance.highContrastText,
                      title: Text(i18n.t('appearanceHighContrastText')),
                      subtitle: Text(i18n.t('appearanceHighContrastTextHint')),
                      onChanged: (value) => _apply(
                        state,
                        config,
                        appearance.copyWith(highContrastText: value),
                      ),
                    ),
                    _slider(
                      context,
                      compact: compactWidth,
                      title: i18n.t('appearanceGradientIntensity'),
                      subtitle: i18n.t('appearanceGradientIntensityHint'),
                      value: appearance.normalizedGradientIntensity,
                      valueLabel:
                          '${(appearance.normalizedGradientIntensity * 100).round()}%',
                      onChanged: (value) => _apply(
                        state,
                        config,
                        appearance.copyWith(gradientIntensity: value),
                      ),
                    ),
                    _slider(
                      context,
                      compact: compactWidth,
                      title: i18n.t('appearanceSidebarOpacity'),
                      subtitle: i18n.t('appearanceSidebarOpacityHint'),
                      value: appearance.normalizedSidebarOpacity,
                      valueLabel:
                          '${(appearance.normalizedSidebarOpacity * 100).round()}%',
                      onChanged: (value) => _apply(
                        state,
                        config,
                        appearance.copyWith(sidebarOpacity: value),
                      ),
                    ),
                    _slider(
                      context,
                      compact: compactWidth,
                      title: i18n.t('appearanceDetailOpacity'),
                      subtitle: i18n.t('appearanceDetailOpacityHint'),
                      value: appearance.normalizedDetailOpacity,
                      valueLabel:
                          '${(appearance.normalizedDetailOpacity * 100).round()}%',
                      onChanged: (value) => _apply(
                        state,
                        config,
                        appearance.copyWith(detailOpacity: value),
                      ),
                    ),
                    _slider(
                      context,
                      compact: compactWidth,
                      title: i18n.t('appearancePlaybackOpacity'),
                      subtitle: i18n.t('appearancePlaybackOpacityHint'),
                      value: appearance.normalizedPlaybackOpacity,
                      valueLabel:
                          '${(appearance.normalizedPlaybackOpacity * 100).round()}%',
                      onChanged: (value) => _apply(
                        state,
                        config,
                        appearance.copyWith(playbackOpacity: value),
                      ),
                    ),
                    _slider(
                      context,
                      compact: compactWidth,
                      title: i18n.t('appearanceFieldOpacity'),
                      subtitle: i18n.t('appearanceFieldOpacityHint'),
                      value: appearance.normalizedFieldOpacity,
                      valueLabel:
                          '${(appearance.normalizedFieldOpacity * 100).round()}%',
                      onChanged: (value) => _apply(
                        state,
                        config,
                        appearance.copyWith(fieldOpacity: value),
                      ),
                    ),
                    SizedBox(height: compactWidth ? 6 : 8),
                    _hexInput(
                      context,
                      i18n: i18n,
                      title: i18n.t('appearanceColorAccent'),
                      hint: '#2563EB',
                      value: appearance.accentColorHex,
                      onChanged: (value) => _apply(
                        state,
                        config,
                        appearance.copyWith(accentColorHex: value),
                      ),
                    ),
                    SizedBox(height: compactWidth ? 6 : 8),
                    _hexInput(
                      context,
                      i18n: i18n,
                      title: i18n.t('appearanceColorBorder'),
                      hint: '#D1DCEB',
                      value: appearance.borderColorHex,
                      onChanged: (value) => _apply(
                        state,
                        config,
                        appearance.copyWith(borderColorHex: value),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _hexInput(
                      context,
                      i18n: i18n,
                      title: i18n.t('appearanceColorBackground'),
                      hint: '#FFFFFF',
                      value: appearance.pageBackgroundHex,
                      onChanged: (value) => _apply(
                        state,
                        config,
                        appearance.copyWith(pageBackgroundHex: value),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: sectionSpacing),
              _sectionCard(
                padding: sectionPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SectionHeader(
                      title: i18n.t('appearanceEffectsTitle'),
                      subtitle: pickUiText(
                        i18n,
                        zh: '随机颜色、彩虹字体与动态特效。',
                        en: 'Random colors, rainbow text, and motion effects.',
                      ),
                    ),
                    SizedBox(height: controlSpacing),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: appearance.randomEntryColors,
                      title: Text(i18n.t('appearanceRandomEntryColors')),
                      subtitle: Text(i18n.t('appearanceRandomEntryColorsHint')),
                      onChanged: (value) => _apply(
                        state,
                        config,
                        appearance.copyWith(randomEntryColors: value),
                      ),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: appearance.rainbowText,
                      title: Text(i18n.t('appearanceRainbowText')),
                      subtitle: Text(i18n.t('appearanceRainbowTextHint')),
                      onChanged: (value) => _apply(
                        state,
                        config,
                        appearance.copyWith(rainbowText: value),
                      ),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: appearance.marqueeText,
                      title: Text(i18n.t('appearanceMarqueeText')),
                      subtitle: Text(i18n.t('appearanceMarqueeTextHint')),
                      onChanged: (value) => _apply(
                        state,
                        config,
                        appearance.copyWith(marqueeText: value),
                      ),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: appearance.breathingEffect,
                      title: Text(i18n.t('appearanceBreathingEffect')),
                      subtitle: Text(i18n.t('appearanceBreathingEffectHint')),
                      onChanged: (value) => _apply(
                        state,
                        config,
                        appearance.copyWith(breathingEffect: value),
                      ),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: appearance.flowingEffect,
                      title: Text(i18n.t('appearanceFlowingEffect')),
                      subtitle: Text(i18n.t('appearanceFlowingEffectHint')),
                      onChanged: (value) => _apply(
                        state,
                        config,
                        appearance.copyWith(flowingEffect: value),
                      ),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: appearance.fieldGradientAccent,
                      title: Text(i18n.t('appearanceFieldGradientAccent')),
                      subtitle: Text(
                        i18n.t('appearanceFieldGradientAccentHint'),
                      ),
                      onChanged: (value) => _apply(
                        state,
                        config,
                        appearance.copyWith(fieldGradientAccent: value),
                      ),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: appearance.fieldGlow,
                      title: Text(i18n.t('appearanceFieldGlow')),
                      subtitle: Text(i18n.t('appearanceFieldGlowHint')),
                      onChanged: (value) => _apply(
                        state,
                        config,
                        appearance.copyWith(fieldGlow: value),
                      ),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: appearance.playbackGlow,
                      title: Text(i18n.t('appearancePlaybackGlow')),
                      subtitle: Text(i18n.t('appearancePlaybackGlowHint')),
                      onChanged: (value) => _apply(
                        state,
                        config,
                        appearance.copyWith(playbackGlow: value),
                      ),
                    ),
                    _slider(
                      context,
                      compact: compactWidth,
                      title: i18n.t('appearanceEffectIntensity'),
                      subtitle: i18n.t('appearanceEffectIntensityHint'),
                      value: appearance.normalizedEffectIntensity,
                      valueLabel:
                          '${(appearance.normalizedEffectIntensity * 100).round()}%',
                      onChanged: (value) => _apply(
                        state,
                        config,
                        appearance.copyWith(effectIntensity: value),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: sectionSpacing),
              _sectionCard(
                padding: sectionPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SectionHeader(
                      title: i18n.t('appearanceBackgroundTitle'),
                      subtitle: i18n.t('appearanceBackgroundHint'),
                    ),
                    SizedBox(height: compactWidth ? 10 : 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final path = await state.pickBackgroundImageByPicker();
                        if (path == null || path.trim().isEmpty) return;
                        _apply(
                          state,
                          config,
                          appearance.copyWith(backgroundImagePath: path),
                        );
                      },
                      icon: const Icon(Icons.image_outlined),
                      label: Text(i18n.t('appearanceBackgroundImagePick')),
                    ),
                    if (appearance.backgroundImagePath
                        .trim()
                        .isNotEmpty) ...<Widget>[
                      SizedBox(height: compactWidth ? 6 : 8),
                      Text(
                        appearance.backgroundImagePath,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      SizedBox(height: compactWidth ? 6 : 8),
                      OutlinedButton.icon(
                        onPressed: () => _apply(
                          state,
                          config,
                          appearance.copyWith(backgroundImagePath: ''),
                        ),
                        icon: const Icon(Icons.hide_image_outlined),
                        label: Text(i18n.t('appearanceBackgroundImageClear')),
                      ),
                    ],
                    SizedBox(height: controlSpacing),
                    DropdownButtonFormField<String>(
                      initialValue: appearance.normalizedBackgroundImageMode,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: i18n.t('appearanceBackgroundImageMode'),
                      ),
                      items: <DropdownMenuItem<String>>[
                        DropdownMenuItem(
                          value: 'cover',
                          child: Text(i18n.t('appearanceBgModeCover')),
                        ),
                        DropdownMenuItem(
                          value: 'contain',
                          child: Text(i18n.t('appearanceBgModeContain')),
                        ),
                        DropdownMenuItem(
                          value: 'stretch',
                          child: Text(i18n.t('appearanceBgModeStretch')),
                        ),
                        DropdownMenuItem(
                          value: 'top',
                          child: Text(i18n.t('appearanceBgModeTop')),
                        ),
                        DropdownMenuItem(
                          value: 'tile',
                          child: Text(i18n.t('appearanceBgModeTile')),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        _apply(
                          state,
                          config,
                          appearance.copyWith(backgroundImageMode: value),
                        );
                      },
                    ),
                    SizedBox(height: controlSpacing),
                    _slider(
                      context,
                      compact: compactWidth,
                      title: i18n.t('appearanceBackgroundImageOpacity'),
                      subtitle: i18n.t('appearanceBackgroundImageOpacityHint'),
                      value: imageOpacity / 0.8,
                      valueLabel: '${(imageOpacity * 100).round()}%',
                      onChanged: (value) => _apply(
                        state,
                        config,
                        appearance.copyWith(
                          backgroundImageOpacity: value * 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: sectionSpacing),
              _sectionCard(
                padding: compactWidth ? 12 : 14,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    Chip(
                      label: Text(i18n.t('appearancePreviewTitle')),
                      backgroundColor: tokens.accent.withValues(alpha: 0.16),
                    ),
                    Chip(label: Text(experienceModeTitle(i18n, mode))),
                    Chip(
                      label: Text(
                        _themeLabel(i18n, appearance.normalizedTheme),
                      ),
                    ),
                    Chip(
                      label: Text(
                        '${i18n.t('appearanceFontScale')}: ${appearance.normalizedFontScale.toStringAsFixed(2)}',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _apply(AppState state, PlayConfig config, AppearanceConfig appearance) {
    state.updateConfig(config.copyWith(appearance: appearance));
  }

  Widget _sectionCard({required double padding, required Widget child}) {
    return Card(
      child: Padding(padding: EdgeInsets.all(padding), child: child),
    );
  }

  String _themeLabel(AppI18n i18n, String theme) {
    return switch (theme) {
      'flat' => i18n.t('themeFlat'),
      'tech' => i18n.t('themeTech'),
      'dark' => i18n.t('themeDark'),
      'fantasy' => i18n.t('themeFantasy'),
      'nature' => i18n.t('themeNature'),
      'sunset' => i18n.t('themeSunset'),
      'ocean' => i18n.t('themeOcean'),
      'mono' => i18n.t('themeMono'),
      _ => theme,
    };
  }

  List<DropdownMenuItem<String>> _weights(AppI18n i18n) {
    return <DropdownMenuItem<String>>[
      DropdownMenuItem(
        value: 'regular',
        child: Text(i18n.t('appearanceWeightRegular')),
      ),
      DropdownMenuItem(
        value: 'medium',
        child: Text(i18n.t('appearanceWeightMedium')),
      ),
      DropdownMenuItem(
        value: 'semibold',
        child: Text(i18n.t('appearanceWeightSemibold')),
      ),
      DropdownMenuItem(
        value: 'bold',
        child: Text(i18n.t('appearanceWeightBold')),
      ),
    ];
  }

  Widget _slider(
    BuildContext context, {
    required bool compact,
    required String title,
    required String subtitle,
    required double value,
    required String valueLabel,
    required ValueChanged<double> onChanged,
  }) {
    final badge = DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(valueLabel, style: Theme.of(context).textTheme.labelMedium),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stackBadge = compact && constraints.maxWidth < 320;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (stackBadge) ...<Widget>[
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: badge),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  badge,
                ],
              ),
            Slider(
              min: 0,
              max: 1,
              divisions: 100,
              value: value.clamp(0.0, 1.0).toDouble(),
              onChanged: onChanged,
            ),
          ],
        );
      },
    );
  }

  Widget _hexInput(
    BuildContext context, {
    required AppI18n i18n,
    required String title,
    required String hint,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    final normalized = value.trim();
    final preview =
        LegacyStyle.parseHexColor(normalized) ??
        LegacyStyle.parseHexColor(hint) ??
        Theme.of(context).colorScheme.primary;
    return TextFormField(
      key: ValueKey<String>('appearance-color-$title-$normalized'),
      initialValue: normalized,
      onChanged: (raw) => onChanged(raw.trim()),
      decoration: InputDecoration(
        labelText: title,
        hintText: hint,
        prefixIcon: preview == null
            ? null
            : Padding(
                padding: const EdgeInsets.all(12),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: preview,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: const SizedBox(width: 16, height: 16),
                ),
              ),
        suffixIcon: SizedBox(
          width: normalized.isEmpty ? 48 : 96,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              IconButton(
                tooltip: pickUiText(i18n, zh: '选择颜色', en: 'Pick color'),
                onPressed: () async {
                  final picked = await _showColorPickerDialog(
                    context: context,
                    i18n: i18n,
                    title: title,
                    initialColor: preview,
                  );
                  if (picked == null) return;
                  final includeAlpha = picked.a < 1;
                  onChanged(
                    LegacyStyle.colorToHex(picked, includeAlpha: includeAlpha),
                  );
                },
                icon: const Icon(Icons.color_lens_outlined),
              ),
              if (normalized.isNotEmpty)
                IconButton(
                  tooltip: pickUiText(i18n, zh: '清空颜色', en: 'Clear color'),
                  onPressed: () => onChanged(''),
                  icon: const Icon(Icons.clear_rounded),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Color?> _showColorPickerDialog({
    required BuildContext context,
    required AppI18n i18n,
    required String title,
    required Color initialColor,
  }) async {
    var hsl = HSLColor.fromColor(initialColor);
    var alpha = initialColor.a;

    return showDialog<Color>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final preview = hsl.withAlpha(alpha).toColor();
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: preview,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(dialogContext).dividerColor,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        LegacyStyle.colorToHex(
                          preview,
                          includeAlpha: alpha < 1,
                        ),
                        style: Theme.of(dialogContext).textTheme.titleSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color:
                                  ThemeData.estimateBrightnessForColor(
                                        preview,
                                      ) ==
                                      Brightness.dark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _colorSlider(
                      context,
                      label: pickUiText(i18n, zh: '色相', en: 'Hue'),
                      value: hsl.hue,
                      min: 0,
                      max: 360,
                      onChanged: (value) {
                        setDialogState(() {
                          hsl = hsl.withHue(value);
                        });
                      },
                    ),
                    _colorSlider(
                      context,
                      label: pickUiText(i18n, zh: '饱和度', en: 'Saturation'),
                      value: hsl.saturation,
                      min: 0,
                      max: 1,
                      onChanged: (value) {
                        setDialogState(() {
                          hsl = hsl.withSaturation(value);
                        });
                      },
                    ),
                    _colorSlider(
                      context,
                      label: pickUiText(i18n, zh: '明度', en: 'Lightness'),
                      value: hsl.lightness,
                      min: 0,
                      max: 1,
                      onChanged: (value) {
                        setDialogState(() {
                          hsl = hsl.withLightness(value);
                        });
                      },
                    ),
                    _colorSlider(
                      context,
                      label: pickUiText(i18n, zh: '透明度', en: 'Alpha'),
                      value: alpha,
                      min: 0,
                      max: 1,
                      valueLabel: '${(alpha * 100).round()}%',
                      onChanged: (value) {
                        setDialogState(() {
                          alpha = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    MaterialLocalizations.of(dialogContext).cancelButtonLabel,
                  ),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(preview),
                  child: Text(
                    MaterialLocalizations.of(dialogContext).okButtonLabel,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _colorSlider(
    BuildContext context, {
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    String? valueLabel,
  }) {
    return Row(
      children: <Widget>[
        SizedBox(width: 88, child: Text(label)),
        Expanded(
          child: Slider(
            value: value.clamp(min, max).toDouble(),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 64,
          child: Text(
            valueLabel ??
                (max == 1
                    ? '${(value * 100).round()}%'
                    : value.toStringAsFixed(0)),
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
