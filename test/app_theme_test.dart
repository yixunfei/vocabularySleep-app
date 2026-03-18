import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vocabulary_sleep_app/src/models/play_config.dart';
import 'package:vocabulary_sleep_app/src/ui/theme/app_theme.dart';

void main() {
  group('buildAppTheme', () {
    test('ocean theme uses light cyan-blue immersive tokens', () {
      final theme = buildAppTheme(const AppearanceConfig(theme: 'ocean'));
      final tokens = theme.extension<AppThemeTokens>();

      expect(theme.brightness, Brightness.light);
      expect(tokens, isNotNull);
      expect(tokens!.isDark, isFalse);
      expect(tokens.canvas, const Color(0xFFF1FBFF));
      expect(tokens.surface, const Color(0xFFFFFFFF));
      expect(tokens.accent, const Color(0xFF0EA5E9));
    });

    test('mono theme stays pure white-gray and low contrast', () {
      final theme = buildAppTheme(const AppearanceConfig(theme: 'mono'));
      final tokens = theme.extension<AppThemeTokens>();

      expect(theme.brightness, Brightness.light);
      expect(tokens, isNotNull);
      expect(tokens!.isDark, isFalse);
      expect(tokens.canvas, const Color(0xFFF9F9F7));
      expect(
        tokens.surfaceOverlay,
        const Color(0xFFFFFFFF).withValues(alpha: 0.97),
      );
      expect(tokens.accent, const Color(0xFF18181B));
    });
  });
}
