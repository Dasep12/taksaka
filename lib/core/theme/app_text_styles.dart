import 'package:flutter/material.dart';
import 'app_colors.dart';

/// ─────────────────────────────────────────
///  APP TEXT STYLES
/// ─────────────────────────────────────────
class AppTextStyles {
  AppTextStyles._();

  // Display
  static const TextStyle h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    letterSpacing: -0.5,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    letterSpacing: -0.3,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.grey900,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.grey900,
  );

  // Body
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.grey800,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.grey800,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.grey600,
  );

  // Label
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.grey900,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.grey600,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.grey600,
  );

  // Special
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.grey400,
    letterSpacing: 0.2,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  static const TextStyle onPrimary = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.secondary,
  );
}
