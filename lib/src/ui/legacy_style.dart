import 'package:flutter/material.dart';

import '../models/play_config.dart';

enum LegacyModule {
  generic,
  sidebar,
  detail,
  playback,
  listItem,
  fieldItem,
  dialog,
}

class LegacyStyle {
  static AppearanceConfig _appearance = AppearanceConfig.defaults;

  static Color? parseHexColor(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return null;
    final normalized = value.replaceAll('#', '');
    if (normalized.length == 6) {
      final parsed = int.tryParse('FF$normalized', radix: 16);
      if (parsed == null) return null;
      return Color(parsed);
    }
    if (normalized.length == 8) {
      final parsed = int.tryParse(normalized, radix: 16);
      if (parsed == null) return null;
      return Color(parsed);
    }
    return null;
  }

  static String colorToHex(Color color, {bool includeAlpha = false}) {
    final alpha = color.a.round().toRadixString(16).padLeft(2, '0');
    final red = color.r.round().toRadixString(16).padLeft(2, '0');
    final green = color.g.round().toRadixString(16).padLeft(2, '0');
    final blue = color.b.round().toRadixString(16).padLeft(2, '0');
    return includeAlpha
        ? '#$alpha$red$green$blue'.toUpperCase()
        : '#$red$green$blue'.toUpperCase();
  }

  static final Map<String, _LegacyPalette> _palettes = <String, _LegacyPalette>{
    'flat': const _LegacyPalette(
      primary: Color(0xFF3B82F6),
      accent: Color(0xFF1D4ED8),
      surface: Color(0xFFFFFFFF),
      textPrimary: Color(0xFF334155),
      textSecondary: Color(0xFF334155),
      border: Color(0xFFDBEAFE),
      pageGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color(0xFFFFFFFF),
          Color(0xFFFFFFFF),
          Color(0xFFF8FAFC),
        ],
      ),
      dark: false,
    ),
    'tech': const _LegacyPalette(
      primary: Color(0xFF2563EB),
      accent: Color(0xFF0EA5E9),
      surface: Color(0xFFF8FAFC),
      textPrimary: Color(0xFF1E293B),
      textSecondary: Color(0xFF334155),
      border: Color(0xFFBFDBFE),
      pageGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color(0xFFF8FBFF),
          Color(0xFFEEF5FF),
          Color(0xFFEAF2FF),
        ],
      ),
      dark: false,
    ),
    'dark': const _LegacyPalette(
      primary: Color(0xFF0EA5E9),
      accent: Color(0xFF0284C7),
      surface: Color(0xFFFFFFFF),
      textPrimary: Color(0xFF0F172A),
      textSecondary: Color(0xFF334155),
      border: Color(0xFFBAE6FD),
      pageGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color(0xFFFFFFFF),
          Color(0xFFF0F9FF),
          Color(0xFFE0F2FE),
        ],
      ),
      dark: false,
    ),
    'fantasy': const _LegacyPalette(
      primary: Color(0xFFBE185D),
      accent: Color(0xFFDB2777),
      surface: Color(0xFFFFFCFF),
      textPrimary: Color(0xFF6B214E),
      textSecondary: Color(0xFF7E3A6A),
      border: Color(0xFFF5D0FE),
      pageGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color(0xFFFFF7FB),
          Color(0xFFFDF2F8),
          Color(0xFFF5F3FF),
        ],
      ),
      dark: false,
    ),
    'nature': const _LegacyPalette(
      primary: Color(0xFF16A34A),
      accent: Color(0xFF059669),
      surface: Color(0xFFFFFFFF),
      textPrimary: Color(0xFF14532D),
      textSecondary: Color(0xFF166534),
      border: Color(0xFFBBF7D0),
      pageGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color(0xFFFFFFFF),
          Color(0xFFF7FDF7),
          Color(0xFFF0FDF4),
          Color(0xFFECFDF5),
        ],
      ),
      dark: false,
    ),
    'sunset': const _LegacyPalette(
      primary: Color(0xFFEA580C),
      accent: Color(0xFFF97316),
      surface: Color(0xFFFFFFFF),
      textPrimary: Color(0xFF7C2D12),
      textSecondary: Color(0xFF9A3412),
      border: Color(0xFFFED7AA),
      pageGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color(0xFFFFFFFF),
          Color(0xFFFFF7ED),
          Color(0xFFFFEDD5),
        ],
      ),
      dark: false,
    ),
    'ocean': const _LegacyPalette(
      primary: Color(0xFF0EA5E9),
      accent: Color(0xFF2DD4BF),
      surface: Color(0xFFFCFEFF),
      textPrimary: Color(0xFF0E5164),
      textSecondary: Color(0xFF568194),
      border: Color(0xFFC8EAF2),
      pageGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color(0xFFFFFFFF),
          Color(0xFFF2FBFF),
          Color(0xFFE3F8FE),
          Color(0xFFD8F1FB),
        ],
      ),
      dark: false,
    ),
    'mono': const _LegacyPalette(
      primary: Color(0xFF18181B),
      accent: Color(0xFF71717A),
      surface: Color(0xFFFFFFFF),
      textPrimary: Color(0xFF18181B),
      textSecondary: Color(0xFF71717A),
      border: Color(0xFFE7E5E4),
      pageGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color(0xFFFFFFFF),
          Color(0xFFFAFAF8),
          Color(0xFFF4F4F1),
        ],
      ),
      dark: false,
    ),
  };

  static void applyAppearance(AppearanceConfig appearance) {
    _appearance = appearance;
  }

  static AppearanceConfig get appearance => _appearance;

  static _LegacyPalette get _palette =>
      _palettes[_appearance.normalizedTheme] ?? _palettes['flat']!;

  static bool get isDark => _palette.dark;

  static bool get isCompact => _appearance.compactLayout;

  static Color get primary =>
      parseHexColor(_appearance.accentColorHex) ?? _palette.primary;

  static Color get accent => _palette.accent;

  static Color get surface => _palette.surface;

  static Color get textPrimary {
    if (!_appearance.highContrastText) return _palette.textPrimary;
    return _palette.dark ? Colors.white : const Color(0xFF0B1220);
  }

  static Color get textSecondary {
    if (!_appearance.highContrastText) return _palette.textSecondary;
    return _palette.dark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B);
  }

  static Color get border {
    final customized = parseHexColor(_appearance.borderColorHex);
    if (customized != null) return customized;
    if (!_appearance.highContrastText) return _palette.border;
    return _palette.dark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
  }

  static Color get appBarBackground => switch (_appearance.normalizedTheme) {
    'ocean' => const Color(0xFFF7FDFF).withValues(alpha: 0.95),
    'mono' => const Color(0xFFFFFFFF).withValues(alpha: 0.95),
    _ =>
      _palette.dark
          ? const Color(0xFF0F172A).withValues(alpha: 0.95)
          : Colors.white.withValues(alpha: 0.92),
  };

  static LinearGradient get pageGradient {
    final customBg = parseHexColor(_appearance.pageBackgroundHex);
    final customGradientStart = parseHexColor(
      _appearance.backgroundGradientStartHex,
    );
    final customGradientEnd = parseHexColor(
      _appearance.backgroundGradientEndHex,
    );
    final neutralBase = customBg ?? surface;
    final neutral = customGradientStart != null || customGradientEnd != null
        ? <Color>[
            (customGradientStart ?? neutralBase).withValues(alpha: 0.96),
            Color.lerp(
                  customGradientStart ?? neutralBase,
                  customGradientEnd ?? neutralBase,
                  0.5,
                )?.withValues(alpha: 0.93) ??
                neutralBase.withValues(alpha: 0.93),
            (customGradientEnd ?? neutralBase).withValues(alpha: 0.9),
          ]
        : <Color>[
            neutralBase.withValues(alpha: 0.985),
            neutralBase.withValues(alpha: 0.955),
            neutralBase.withValues(alpha: 0.93),
          ];
    final vivid = _appearance.enhancedBackground
        ? _palette.pageGradient.colors
        : neutral;
    final t = _appearance.normalizedGradientIntensity;
    final blended = <Color>[];
    for (var i = 0; i < neutral.length; i++) {
      blended.add(Color.lerp(neutral[i], vivid[i], t) ?? vivid[i]);
    }
    return LinearGradient(
      begin: _palette.pageGradient.begin,
      end: _palette.pageGradient.end,
      colors: blended,
    );
  }

  static LinearGradient get chipGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[
      primary.withValues(
        alpha: 0.12 + 0.18 * _appearance.normalizedGradientIntensity,
      ),
      accent.withValues(
        alpha: 0.16 + 0.22 * _appearance.normalizedGradientIntensity,
      ),
    ],
  );

  static double moduleRadius(LegacyModule module) {
    final compact = _appearance.compactLayout;
    return switch (module) {
      LegacyModule.sidebar => compact ? 12 : 15,
      LegacyModule.detail => compact ? 13 : 16,
      LegacyModule.playback => compact ? 12 : 14,
      LegacyModule.listItem => compact ? 10 : 12,
      LegacyModule.fieldItem => compact ? 10 : 13,
      LegacyModule.dialog => compact ? 13 : 16,
      LegacyModule.generic => compact ? 14 : 18,
    };
  }

  static double _moduleOpacity(LegacyModule module) {
    final defaultValue = switch (module) {
      LegacyModule.sidebar => _appearance.normalizedSidebarOpacity,
      LegacyModule.detail => _appearance.normalizedDetailOpacity,
      LegacyModule.playback => _appearance.normalizedPlaybackOpacity,
      LegacyModule.fieldItem => _appearance.normalizedFieldOpacity,
      LegacyModule.listItem => _appearance.normalizedFieldOpacity,
      LegacyModule.dialog => _appearance.normalizedDetailOpacity,
      LegacyModule.generic => _appearance.normalizedDetailOpacity,
    };
    return defaultValue.clamp(0.45, 1).toDouble();
  }

  static Color _moduleBaseColor(LegacyModule module) {
    final custom = switch (module) {
      LegacyModule.sidebar => parseHexColor(_appearance.sidebarColorHex),
      LegacyModule.detail => parseHexColor(_appearance.detailColorHex),
      LegacyModule.playback => parseHexColor(_appearance.playbackColorHex),
      LegacyModule.fieldItem => parseHexColor(_appearance.fieldColorHex),
      LegacyModule.listItem => parseHexColor(_appearance.fieldColorHex),
      LegacyModule.dialog => parseHexColor(_appearance.detailColorHex),
      LegacyModule.generic => parseHexColor(_appearance.detailColorHex),
    };
    return custom ?? surface;
  }

  static BoxDecoration panelDecorationFor(
    LegacyModule module, {
    Color? accentColor,
    bool selected = false,
  }) {
    final compact = _appearance.compactLayout;
    final frosted = _appearance.frostedPanels;
    final gradientAmount = _appearance.normalizedGradientIntensity;
    final effectAmount = _appearance.normalizedEffectIntensity;
    final moduleOpacity = _moduleOpacity(module);
    final radius = moduleRadius(module);
    final surfaceAlphaBase = frosted
        ? (_palette.dark ? 0.43 : 0.79)
        : (_palette.dark ? 0.74 : 0.94);
    final surfaceAlpha = (surfaceAlphaBase * moduleOpacity).clamp(0.34, 0.98);
    final accentValue = accentColor ?? primary;
    final baseSurface = _moduleBaseColor(module);
    final gradient = gradientAmount > 0.02
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              accentValue.withValues(alpha: 0.05 + gradientAmount * 0.15),
              accent.withValues(alpha: 0.03 + gradientAmount * 0.12),
            ],
          )
        : null;

    return BoxDecoration(
      color: baseSurface.withValues(alpha: surfaceAlpha),
      borderRadius: BorderRadius.circular(radius),
      gradient: gradient,
      border: Border.all(
        color: (selected ? accentValue : border).withValues(
          alpha: frosted ? 0.92 : 1,
        ),
        width: compact ? 1.0 : 1.15,
      ),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: (_palette.dark ? Colors.black : const Color(0xFF0F172A))
              .withValues(alpha: 0.05 + effectAmount * 0.12),
          blurRadius: (compact ? 11 : 15) + effectAmount * 8,
          offset: Offset(0, compact ? 4 : 6),
        ),
        if (selected)
          BoxShadow(
            color: accentValue.withValues(alpha: 0.05 + effectAmount * 0.15),
            blurRadius: 8 + effectAmount * 12,
            spreadRadius: 0.2,
          ),
      ],
    );
  }

  static BoxDecoration get panelDecoration =>
      panelDecorationFor(LegacyModule.generic);

  static BoxDecoration cardDecorationFor(
    LegacyModule module, {
    Color? accentColor,
    bool selected = false,
    bool gradientAccent = false,
  }) {
    final compact = _appearance.compactLayout;
    final effectAmount = _appearance.normalizedEffectIntensity;
    final gradientAmount = _appearance.normalizedGradientIntensity;
    final moduleOpacity = _moduleOpacity(module);
    final radius = moduleRadius(module);
    final accentValue = accentColor ?? primary;
    final baseSurface = _moduleBaseColor(module);
    final useGradient = gradientAccent && gradientAmount > 0.03;
    return BoxDecoration(
      color: baseSurface.withValues(
        alpha: ((_palette.dark ? 0.66 : 0.92) * moduleOpacity).clamp(0.3, 0.98),
      ),
      borderRadius: BorderRadius.circular(radius),
      gradient: useGradient
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                accentValue.withValues(alpha: 0.06 + gradientAmount * 0.14),
                accent.withValues(alpha: 0.04 + gradientAmount * 0.1),
              ],
            )
          : null,
      border: Border.all(
        color: (selected ? accentValue : border).withValues(
          alpha: selected ? 0.75 : 1,
        ),
        width: compact ? 1 : 1.1,
      ),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: (_palette.dark ? Colors.black : const Color(0xFF0F172A))
              .withValues(alpha: 0.03 + effectAmount * 0.08),
          blurRadius: (compact ? 8 : 10) + effectAmount * 6,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  static BoxDecoration fieldCardDecoration({
    required Color accentColor,
    String? fieldKey,
    bool selected = false,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    final useGradient = _appearance.fieldGradientAccent;
    final glow = _appearance.fieldGlow;
    final effectAmount = _appearance.normalizedEffectIntensity;
    final gradientAmount = _appearance.normalizedGradientIntensity;
    final moduleOpacity = _appearance.normalizedFieldOpacity;
    final baseColor =
        backgroundColor ??
        _moduleBaseColor(LegacyModule.fieldItem).withValues(
          alpha: ((_palette.dark ? 0.62 : 0.92) * moduleOpacity).clamp(
            0.32,
            0.98,
          ),
        );
    final useFieldGradient = useGradient && backgroundColor == null;
    final resolvedBorderColor =
        borderColor ?? accentColor.withValues(alpha: selected ? 0.6 : 0.35);
    return BoxDecoration(
      color: baseColor,
      borderRadius: BorderRadius.circular(moduleRadius(LegacyModule.fieldItem)),
      gradient: useFieldGradient
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                accentColor.withValues(alpha: 0.05 + gradientAmount * 0.18),
                accent.withValues(alpha: 0.03 + gradientAmount * 0.12),
              ],
            )
          : null,
      border: Border.all(
        color: resolvedBorderColor,
        width: _appearance.compactLayout ? 1 : 1.15,
      ),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: (_palette.dark ? Colors.black : const Color(0xFF0F172A))
              .withValues(alpha: 0.03 + effectAmount * 0.08),
          blurRadius: 8 + effectAmount * 8,
          offset: const Offset(0, 3),
        ),
        if (glow)
          BoxShadow(
            color: accentColor.withValues(alpha: 0.04 + effectAmount * 0.14),
            blurRadius: 8 + effectAmount * 16,
            spreadRadius: 0.3,
          ),
      ],
    );
  }

  static BoxDecoration get cardDecoration =>
      cardDecorationFor(LegacyModule.listItem);

  static String? get fontFamily {
    return switch (_appearance.normalizedFontFamilyKey) {
      'serif' => 'serif',
      'mono' => 'monospace',
      'rounded' => 'sans-serif',
      _ => null,
    };
  }

  static FontWeight fontWeightFromKey(String key) {
    return switch (key) {
      'medium' => FontWeight.w500,
      'semibold' => FontWeight.w600,
      'bold' => FontWeight.w700,
      _ => FontWeight.w400,
    };
  }

  static FontWeight get titleFontWeight =>
      fontWeightFromKey(_appearance.normalizedTitleWeightKey);

  static FontWeight get bodyFontWeight =>
      fontWeightFromKey(_appearance.normalizedBodyWeightKey);
}

class _LegacyPalette {
  const _LegacyPalette({
    required this.primary,
    required this.accent,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.pageGradient,
    required this.dark,
  });

  final Color primary;
  final Color accent;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final LinearGradient pageGradient;
  final bool dark;
}
