import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/models/play_config.dart';
import 'package:vocabulary_sleep_app/src/ui/theme/app_theme.dart';

void main() {
  group('buildAppTheme', () {
    test('ocean theme uses deep ocean dark tokens', () {
      final theme = buildAppTheme(const AppearanceConfig(theme: 'ocean'));
      final tokens = theme.extension<AppThemeTokens>();

      expect(theme.brightness, Brightness.dark);
      expect(tokens, isNotNull);
      expect(tokens!.isDark, isTrue);
      expect(tokens.canvas, const Color(0xFF04111B));
      expect(tokens.surface, const Color(0xFF0A2233));
      expect(tokens.accent, const Color(0xFF38BDF8));
    });

    test('mono theme stays neutral and grayscale', () {
      final theme = buildAppTheme(const AppearanceConfig(theme: 'mono'));
      final tokens = theme.extension<AppThemeTokens>();

      expect(theme.brightness, Brightness.light);
      expect(tokens, isNotNull);
      expect(tokens!.isDark, isFalse);
      expect(tokens.canvas, const Color(0xFFF7F7F4));
      expect(
        tokens.surfaceOverlay,
        const Color(0xFFFDFDFC).withValues(alpha: 0.96),
      );
      expect(tokens.accent, const Color(0xFF18181B));
    });
  });
}
