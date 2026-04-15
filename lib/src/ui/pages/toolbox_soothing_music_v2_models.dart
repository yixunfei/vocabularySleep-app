part of 'toolbox_soothing_music_v2_page.dart';

class _SoothingModeTheme {
  const _SoothingModeTheme({
    required this.id,
    required this.zhTitle,
    required this.enTitle,
    required this.zhSubtitle,
    required this.enSubtitle,
    required this.zhDescription,
    required this.enDescription,
    required this.icon,
    required this.accent,
    required this.orbitAccent,
    required this.backgroundA,
    required this.backgroundB,
    required this.blobA,
    required this.blobB,
    required this.footerZh,
    required this.footerEn,
  });

  final String id;
  final String zhTitle;
  final String enTitle;
  final String zhSubtitle;
  final String enSubtitle;
  final String zhDescription;
  final String enDescription;
  final IconData icon;
  final Color accent;
  final Color orbitAccent;
  final Color backgroundA;
  final Color backgroundB;
  final Color blobA;
  final Color blobB;
  final String footerZh;
  final String footerEn;

  String title(AppI18n i18n) => SoothingMusicCopy.modeTitle(i18n, id);
  String subtitle(AppI18n i18n) => SoothingMusicCopy.modeSubtitle(i18n, id);
  String description(AppI18n i18n) =>
      SoothingMusicCopy.modeDescription(i18n, id);
  String footer(AppI18n i18n) => SoothingMusicCopy.modeFooter(i18n, id);
}

class _TrackLabelPair {
  const _TrackLabelPair({required this.zh, required this.en});

  final String zh;
  final String en;
}

class _SoothingVisualPalette {
  const _SoothingVisualPalette({
    required this.isDark,
    required this.backgroundTop,
    required this.backgroundBottom,
    required this.panelSurface,
    required this.panelSurfaceMuted,
    required this.controlSurface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.orbitAccent,
    required this.glowA,
    required this.glowB,
    required this.dangerBg,
    required this.dangerFg,
  });

  final bool isDark;
  final Color backgroundTop;
  final Color backgroundBottom;
  final Color panelSurface;
  final Color panelSurfaceMuted;
  final Color controlSurface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final Color orbitAccent;
  final Color glowA;
  final Color glowB;
  final Color dangerBg;
  final Color dangerFg;

  factory _SoothingVisualPalette.resolve({
    required bool isDark,
    required AppearanceConfig appearance,
    required _SoothingModeTheme mode,
  }) {
    final effectStrength =
        0.34 + appearance.normalizedEffectIntensity * (isDark ? 0.42 : 0.28);
    final accent = mode.accent;
    final orbitAccent = mode.orbitAccent;
    final backgroundTop = isDark
        ? const Color(0xFF2A384B)
        : const Color(0xFFF4F7F9);
    final backgroundBottom = isDark
        ? const Color(0xFF101823)
        : const Color(0xFFDDE5EA);
    final panelSurface = Color.lerp(
      isDark ? const Color(0xFF182433) : Colors.white,
      accent,
      isDark ? 0.1 + effectStrength * 0.04 : 0.04 + effectStrength * 0.03,
    )!.withValues(alpha: isDark ? 0.94 : 0.96);
    final panelSurfaceMuted = Color.lerp(
      isDark ? const Color(0xFF1E2B3C) : const Color(0xFFF7FAFC),
      orbitAccent,
      isDark ? 0.08 : 0.04,
    )!.withValues(alpha: isDark ? 0.92 : 0.96);
    final controlSurface = Color.lerp(
      isDark ? const Color(0xFF233245) : Colors.white,
      accent,
      isDark ? 0.14 : 0.06,
    )!.withValues(alpha: isDark ? 0.96 : 0.98);
    final border = Color.lerp(
      isDark ? const Color(0xFF41556D) : const Color(0xFFB8C4CE),
      accent,
      isDark ? 0.18 : 0.12,
    )!;
    final textPrimary = isDark
        ? const Color(0xFFF5F7FA)
        : const Color(0xFF122235);
    final textSecondary = isDark
        ? const Color(0xFFB5C2CF)
        : const Color(0xFF586978);

    return _SoothingVisualPalette(
      isDark: isDark,
      backgroundTop: backgroundTop,
      backgroundBottom: backgroundBottom,
      panelSurface: panelSurface,
      panelSurfaceMuted: panelSurfaceMuted,
      controlSurface: controlSurface,
      border: border,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      accent: accent,
      orbitAccent: orbitAccent,
      glowA: Color.lerp(mode.blobA, accent, 0.42)!,
      glowB: Color.lerp(mode.blobB, orbitAccent, 0.36)!,
      dangerBg: isDark ? const Color(0xFF4B2B30) : const Color(0xFFF3D7DA),
      dangerFg: isDark ? const Color(0xFFFFC5CB) : const Color(0xFF7A1E27),
    );
  }
}
