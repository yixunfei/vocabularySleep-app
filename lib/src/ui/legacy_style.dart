import 'package:flutter/material.dart';

class LegacyStyle {
  static const Color primary = Color(0xFF2563EB);
  static const Color accent = Color(0xFF0EA5E9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF334155);
  static const Color border = Color(0xFFD3E5FF);

  static const LinearGradient pageGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFF8FAFC), Color(0xFFEFF6FF), Color(0xFFECFEFF)],
  );

  static const LinearGradient chipGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFE0ECFF), Color(0xFFD8F4FF)],
  );

  static BoxDecoration panelDecoration = BoxDecoration(
    color: surface.withValues(alpha: 0.9),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: border.withValues(alpha: 0.95), width: 1.2),
    boxShadow: <BoxShadow>[
      BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: 0.06),
        blurRadius: 18,
        offset: const Offset(0, 7),
      ),
    ],
  );

  static BoxDecoration cardDecoration = BoxDecoration(
    color: surface.withValues(alpha: 0.97),
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: border, width: 1.1),
  );
}
