import 'package:flutter/material.dart';

/// ─────────────────────────────────────────
///  APP COLORS
/// ─────────────────────────────────────────
class AppColors {
  AppColors._();

  // Brand palette
  static const Color primary = Color(0xFF1A1D24); // Dark Charcoal/Slate
  static const Color secondary = Color(0xFFFFFFFF); // White
  static const Color accent = Color(0xFFE2B038); // Gold/Yellow

  // Tints of primary
  static const Color primaryLight = Color(0xFF2E323F);
  static const Color primaryDark = Color(0xFF101217);
  static const Color primarySurface = Color(0xFFF1F3F6); // very light tint

  // Neutral
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Backgrounds
  static const Color scaffoldBg = Color(0xFFF4F5F9);
  static const Color cardBg = Color(0xFFFFFFFF);
}
