import 'package:flutter/material.dart';

import '../../models/play_config.dart';
import '../legacy_style.dart';

enum AppExperienceMode { sleep, focus }

AppExperienceMode experienceModeFromAppearance(AppearanceConfig appearance) {
  return switch (appearance.normalizedTheme) {
    'dark' => AppExperienceMode.sleep,
    _ => AppExperienceMode.focus,
  };
}

AppearanceConfig applyExperienceMode(
  AppearanceConfig base,
  AppExperienceMode mode,
) {
  return switch (mode) {
    AppExperienceMode.sleep => base.copyWith(
      theme: 'dark',
      compactLayout: false,
      enhancedBackground: true,
      frostedPanels: true,
      highContrastText: false,
      gradientIntensity: 0.18,
      effectIntensity: 0.08,
      backgroundImageOpacity: 0.22,
      randomEntryColors: false,
      rainbowText: false,
      marqueeText: false,
      breathingEffect: false,
      flowingEffect: false,
    ),
    AppExperienceMode.focus => base.copyWith(
      theme: 'tech',
      compactLayout: true,
      enhancedBackground: true,
      frostedPanels: false,
      highContrastText: false,
      gradientIntensity: 0.12,
      effectIntensity: 0.1,
      backgroundImageOpacity: 0.16,
      randomEntryColors: false,
      rainbowText: false,
      marqueeText: false,
      breathingEffect: false,
      flowingEffect: false,
    ),
  };
}

class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  const AppThemeTokens({
    required this.mode,
    required this.isDark,
    required this.canvas,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceStrong,
    required this.surfaceOverlay,
    required this.outline,
    required this.outlineStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.accentSoft,
    required this.success,
    required this.warning,
    required this.danger,
    required this.glow,
  });

  final AppExperienceMode mode;
  final bool isDark;
  final Color canvas;
  final Color surface;
  final Color surfaceMuted;
  final Color surfaceStrong;
  final Color surfaceOverlay;
  final Color outline;
  final Color outlineStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final Color accentSoft;
  final Color success;
  final Color warning;
  final Color danger;
  final Color glow;

  static AppThemeTokens of(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>();
    assert(tokens != null, 'AppThemeTokens is missing from ThemeData');
    return tokens!;
  }

  factory AppThemeTokens.fromAppearance(AppearanceConfig appearance) {
    LegacyStyle.applyAppearance(appearance);
    final accent = LegacyStyle.primary;
    final mode = experienceModeFromAppearance(appearance);
    return switch (appearance.normalizedTheme) {
      'ocean' => AppThemeTokens(
        mode: AppExperienceMode.focus,
        isDark: false,
        canvas: const Color(0xFFF1FBFF),
        surface: const Color(0xFFFFFFFF),
        surfaceMuted: const Color(0xFFEDF9FD),
        surfaceStrong: const Color(0xFFDDF2F8),
        surfaceOverlay: const Color(0xFFF8FDFF).withValues(alpha: 0.95),
        outline: const Color(0xFFC8E6EF),
        outlineStrong: const Color(0xFF74BFD3),
        textPrimary: const Color(0xFF0E5164),
        textSecondary: const Color(0xFF568194),
        accent: accent,
        accentSoft: Color.lerp(accent, Colors.white, 0.84)!,
        success: const Color(0xFF2DAE98),
        warning: const Color(0xFFE4A64C),
        danger: const Color(0xFFD96E7A),
        glow: accent.withValues(alpha: 0.14),
      ),
      'mono' => AppThemeTokens(
        mode: AppExperienceMode.focus,
        isDark: false,
        canvas: const Color(0xFFF9F9F7),
        surface: const Color(0xFFFFFFFF),
        surfaceMuted: const Color(0xFFF6F6F3),
        surfaceStrong: const Color(0xFFF0F0EC),
        surfaceOverlay: const Color(0xFFFFFFFF).withValues(alpha: 0.97),
        outline: const Color(0xFFE7E5E4),
        outlineStrong: const Color(0xFFA1A1AA),
        textPrimary: const Color(0xFF18181B),
        textSecondary: const Color(0xFF71717A),
        accent: accent,
        accentSoft: Color.lerp(accent, Colors.white, 0.93)!,
        success: const Color(0xFF4C6B58),
        warning: const Color(0xFF9F7B42),
        danger: const Color(0xFF946666),
        glow: accent.withValues(alpha: 0.04),
      ),
      _ => switch (mode) {
        AppExperienceMode.sleep => AppThemeTokens(
          mode: mode,
          isDark: true,
          canvas: const Color(0xFF08131F),
          surface: const Color(0xFF10253A),
          surfaceMuted: const Color(0xFF143049),
          surfaceStrong: const Color(0xFF1A3B59),
          surfaceOverlay: const Color(0xFF0F2132).withValues(alpha: 0.88),
          outline: const Color(0xFF30506F),
          outlineStrong: const Color(0xFF6FA4CC),
          textPrimary: const Color(0xFFF3FAFF),
          textSecondary: const Color(0xFFB7D1E6),
          accent: accent,
          accentSoft: Color.lerp(accent, Colors.white, 0.68)!,
          success: const Color(0xFF75D6B2),
          warning: const Color(0xFFF8CA6A),
          danger: const Color(0xFFFF8A8A),
          glow: accent.withValues(alpha: 0.34),
        ),
        AppExperienceMode.focus => AppThemeTokens(
          mode: mode,
          isDark: false,
          canvas: const Color(0xFFF4F7FB),
          surface: const Color(0xFFFFFFFF),
          surfaceMuted: const Color(0xFFF0F5FB),
          surfaceStrong: const Color(0xFFE7F0FB),
          surfaceOverlay: const Color(0xFFFCFDFF).withValues(alpha: 0.94),
          outline: const Color(0xFFD1DCEB),
          outlineStrong: const Color(0xFF7AA5D8),
          textPrimary: const Color(0xFF17324D),
          textSecondary: const Color(0xFF58728B),
          accent: accent,
          accentSoft: Color.lerp(accent, Colors.white, 0.82)!,
          success: const Color(0xFF2F9D7E),
          warning: const Color(0xFFE59E2D),
          danger: const Color(0xFFD95858),
          glow: accent.withValues(alpha: 0.16),
        ),
      },
    };
  }

  @override
  ThemeExtension<AppThemeTokens> copyWith({
    AppExperienceMode? mode,
    bool? isDark,
    Color? canvas,
    Color? surface,
    Color? surfaceMuted,
    Color? surfaceStrong,
    Color? surfaceOverlay,
    Color? outline,
    Color? outlineStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? accent,
    Color? accentSoft,
    Color? success,
    Color? warning,
    Color? danger,
    Color? glow,
  }) {
    return AppThemeTokens(
      mode: mode ?? this.mode,
      isDark: isDark ?? this.isDark,
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      surfaceStrong: surfaceStrong ?? this.surfaceStrong,
      surfaceOverlay: surfaceOverlay ?? this.surfaceOverlay,
      outline: outline ?? this.outline,
      outlineStrong: outlineStrong ?? this.outlineStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      glow: glow ?? this.glow,
    );
  }

  @override
  ThemeExtension<AppThemeTokens> lerp(
    covariant ThemeExtension<AppThemeTokens>? other,
    double t,
  ) {
    if (other is! AppThemeTokens) return this;
    return AppThemeTokens(
      mode: t < 0.5 ? mode : other.mode,
      isDark: t < 0.5 ? isDark : other.isDark,
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      surfaceStrong: Color.lerp(surfaceStrong, other.surfaceStrong, t)!,
      surfaceOverlay: Color.lerp(surfaceOverlay, other.surfaceOverlay, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      outlineStrong: Color.lerp(outlineStrong, other.outlineStrong, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
    );
  }
}

TextStyle? _scaleTextStyle(TextStyle? style, double scale) {
  if (style == null) return null;
  final baseSize = style.fontSize;
  if (baseSize == null) return style;
  return style.copyWith(fontSize: baseSize * scale);
}

TextTheme _scaleTextTheme(TextTheme base, double scale) {
  return base.copyWith(
    displayLarge: _scaleTextStyle(base.displayLarge, scale),
    displayMedium: _scaleTextStyle(base.displayMedium, scale),
    displaySmall: _scaleTextStyle(base.displaySmall, scale),
    headlineLarge: _scaleTextStyle(base.headlineLarge, scale),
    headlineMedium: _scaleTextStyle(base.headlineMedium, scale),
    headlineSmall: _scaleTextStyle(base.headlineSmall, scale),
    titleLarge: _scaleTextStyle(base.titleLarge, scale),
    titleMedium: _scaleTextStyle(base.titleMedium, scale),
    titleSmall: _scaleTextStyle(base.titleSmall, scale),
    bodyLarge: _scaleTextStyle(base.bodyLarge, scale),
    bodyMedium: _scaleTextStyle(base.bodyMedium, scale),
    bodySmall: _scaleTextStyle(base.bodySmall, scale),
    labelLarge: _scaleTextStyle(base.labelLarge, scale),
    labelMedium: _scaleTextStyle(base.labelMedium, scale),
    labelSmall: _scaleTextStyle(base.labelSmall, scale),
  );
}

double _contrastRatio(Color a, Color b) {
  final l1 = a.computeLuminance();
  final l2 = b.computeLuminance();
  final lighter = l1 > l2 ? l1 : l2;
  final darker = l1 > l2 ? l2 : l1;
  return (lighter + 0.05) / (darker + 0.05);
}

Color _resolvePrimaryButtonBackground(AppThemeTokens tokens) {
  final base = tokens.accent;
  final contrastWithSurface = _contrastRatio(base, tokens.surfaceOverlay);
  if (contrastWithSurface >= 1.75) return base;
  if (tokens.isDark) {
    return Color.lerp(base, Colors.white, 0.2)!;
  }
  return Color.lerp(base, const Color(0xFF0F3A5E), 0.42)!;
}

Color _resolvePrimaryButtonForeground(Color background, AppThemeTokens tokens) {
  if (background.computeLuminance() > 0.6) {
    return tokens.isDark ? const Color(0xFF062039) : const Color(0xFF0C2942);
  }
  return Colors.white;
}

ThemeData buildAppTheme(AppearanceConfig appearance) {
  LegacyStyle.applyAppearance(appearance);
  final tokens = AppThemeTokens.fromAppearance(appearance);
  final compact = appearance.compactLayout;
  final brightness = tokens.isDark ? Brightness.dark : Brightness.light;
  final primaryButtonBackground = _resolvePrimaryButtonBackground(tokens);
  final primaryButtonForeground = _resolvePrimaryButtonForeground(
    primaryButtonBackground,
    tokens,
  );
  final navigationSelectedColor =
      _contrastRatio(tokens.accent, tokens.surfaceOverlay) >= 2.4
      ? tokens.accent
      : tokens.textPrimary;
  final appBarBackground = Color.lerp(
    tokens.surfaceOverlay,
    tokens.surface,
    tokens.isDark ? 0.26 : 0.42,
  )!;
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: tokens.accent,
        brightness: brightness,
      ).copyWith(
        primary: primaryButtonBackground,
        secondary: tokens.accentSoft,
        secondaryContainer: Color.lerp(
          tokens.surfaceStrong,
          tokens.accent,
          tokens.isDark ? 0.42 : 0.24,
        )!,
        onPrimary: primaryButtonForeground,
        onSecondary: tokens.isDark
            ? tokens.textPrimary
            : const Color(0xFF102A42),
        onSecondaryContainer: tokens.isDark
            ? tokens.textPrimary
            : const Color(0xFF102A42),
        surface: tokens.surface,
        onSurface: tokens.textPrimary,
        outline: tokens.outline,
        error: tokens.danger,
      );

  final baseTheme = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: tokens.canvas,
    canvasColor: tokens.canvas,
    visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
    dividerColor: tokens.outline.withValues(alpha: 0.7),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: tokens.surfaceOverlay,
      surfaceTintColor: Colors.transparent,
      height: compact ? 68 : 74,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          color: selected ? navigationSelectedColor : tokens.textSecondary,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          fontSize: compact ? 12 : 13,
        );
      }),
      indicatorColor: navigationSelectedColor.withValues(
        alpha: tokens.isDark ? 0.24 : 0.16,
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? navigationSelectedColor : tokens.textSecondary,
          size: compact ? 22 : 24,
        );
      }),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: appBarBackground,
      foregroundColor: tokens.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: tokens.textPrimary,
        fontSize: compact ? 19 : 21,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: tokens.surfaceOverlay,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(compact ? 20 : 24),
        side: BorderSide(
          color: tokens.outline.withValues(alpha: 0.9),
          width: 1,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: tokens.surfaceMuted,
      selectedColor: tokens.accent.withValues(alpha: 0.16),
      side: BorderSide(color: tokens.outline),
      labelStyle: TextStyle(
        color: tokens.textSecondary,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        textStyle: WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w700, fontSize: compact ? 12 : 13),
        ),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return tokens.isDark ? tokens.textPrimary : const Color(0xFF0E2C45);
          }
          return tokens.textSecondary;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return tokens.accent.withValues(alpha: tokens.isDark ? 0.34 : 0.22);
          }
          return tokens.surfaceMuted.withValues(
            alpha: tokens.isDark ? 0.72 : 0.94,
          );
        }),
        side: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return BorderSide(
            color: selected
                ? tokens.accent.withValues(alpha: 0.86)
                : tokens.outline.withValues(alpha: 0.95),
            width: selected ? 1.4 : 1,
          );
        }),
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(
            horizontal: compact ? 12 : 14,
            vertical: compact ? 9 : 11,
          ),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(compact ? 14 : 16),
          ),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tokens.surfaceOverlay,
      hintStyle: TextStyle(color: tokens.textSecondary.withValues(alpha: 0.8)),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: compact ? 14 : 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
        borderSide: BorderSide(color: tokens.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
        borderSide: BorderSide(color: tokens.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
        borderSide: BorderSide(color: tokens.accent, width: 1.4),
      ),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 16,
        vertical: compact ? 6 : 8,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(compact ? 18 : 20),
      ),
      iconColor: tokens.textSecondary,
      textColor: tokens.textPrimary,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return tokens.accent;
        }
        return tokens.surfaceStrong;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return tokens.accent.withValues(alpha: 0.42);
        }
        return tokens.outline.withValues(alpha: 0.7);
      }),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primaryButtonBackground,
        foregroundColor: primaryButtonForeground,
        minimumSize: Size(0, compact ? 44 : 50),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 18 : 22,
          vertical: compact ? 10 : 14,
        ),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(compact ? 16 : 18),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: tokens.textPrimary,
        minimumSize: Size(0, compact ? 42 : 48),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 16 : 20,
          vertical: compact ? 10 : 14,
        ),
        side: BorderSide(color: tokens.outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(compact ? 16 : 18),
        ),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: tokens.surfaceOverlay,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: tokens.surfaceOverlay,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: tokens.surfaceStrong,
      contentTextStyle: TextStyle(color: tokens.textPrimary),
      behavior: SnackBarBehavior.floating,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: tokens.surfaceOverlay,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: tokens.outline),
      ),
    ),
    extensions: <ThemeExtension<dynamic>>[tokens],
  );

  final themedTextBase = baseTheme.textTheme.apply(
    fontFamily: LegacyStyle.fontFamily,
    bodyColor: tokens.textPrimary,
    displayColor: tokens.textPrimary,
  );
  final scaledText = _scaleTextTheme(
    themedTextBase,
    appearance.normalizedFontScale,
  );

  return baseTheme.copyWith(
    textTheme: scaledText.copyWith(
      headlineLarge: scaledText.headlineLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
      headlineMedium: scaledText.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
      titleLarge: scaledText.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: scaledText.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: scaledText.bodyLarge?.copyWith(height: 1.35),
      bodyMedium: scaledText.bodyMedium?.copyWith(height: 1.35),
      labelLarge: scaledText.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
    primaryTextTheme: scaledText,
  );
}
