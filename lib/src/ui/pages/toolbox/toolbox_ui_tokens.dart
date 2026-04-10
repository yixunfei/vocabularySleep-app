import 'package:flutter/material.dart';

class ToolboxUiTokens {
  ToolboxUiTokens._();

  static const double contentMaxWidth = 600;
  static const double pageHorizontalPadding = 16;
  static const double pageTopPadding = 12;
  static const double pageBottomPadding = 24;
  static const double sectionSpacing = 20;
  static const double cardSpacing = 12;
  static const double cardRadius = 16;
  static const double iconRadius = 12;
  static const double iconSize = 44;
  static const double entryMinHeight = 92;
  static const double shellCardRadius = 18;
  static const double panelRadius = 24;
  static const double sectionPanelRadius = 22;
  static const double pillRadius = 999;
  static const double pillIconSize = 44;
  static const double panelShadowBlur = 20;
  static const double panelShadowOffsetY = 10;
}

BoxShadow toolboxCardShadow(Color color, {required bool pressed}) {
  return BoxShadow(
    color: color.withValues(alpha: pressed ? 0.08 : 0.12),
    blurRadius: pressed ? 10 : 18,
    offset: Offset(0, pressed ? 4 : 10),
  );
}

BoxShadow toolboxPanelShadow(
  Color color, {
  double opacity = 0.12,
  double blurRadius = ToolboxUiTokens.panelShadowBlur,
  double offsetY = ToolboxUiTokens.panelShadowOffsetY,
}) {
  return BoxShadow(
    color: color.withValues(alpha: opacity),
    blurRadius: blurRadius,
    offset: Offset(0, offsetY),
  );
}
