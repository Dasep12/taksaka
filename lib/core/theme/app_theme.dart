import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// ─────────────────────────────────────────
///  APP THEME
/// ─────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          onPrimary: AppColors.secondary,
          secondary: AppColors.accent,
          onSecondary: AppColors.secondary,
          surface: AppColors.cardBg,
          onSurface: AppColors.grey900,
          error: AppColors.error,
          brightness: Brightness.light,
        ),

        // Scaffold
        scaffoldBackgroundColor: AppColors.scaffoldBg,

        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.secondary,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.secondary,
          ),
        ),

        // Card
        cardTheme: CardThemeData(
          color: AppColors.cardBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: EdgeInsets.zero,
        ),

        // ElevatedButton
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.secondary,
            elevation: 0,
            textStyle: AppTextStyles.buttonText,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),

        // OutlinedButton
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            textStyle: AppTextStyles.buttonText,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),

        // TextButton
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: AppTextStyles.buttonText,
          ),
        ),

        // Input
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.grey100,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.grey400,
          ),
          prefixIconColor: AppColors.grey400,
        ),

        // BottomNavigationBar
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.cardBg,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.grey400,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
          selectedLabelStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
        ),

        // Chip
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.primarySurface,
          labelStyle: AppTextStyles.labelMedium.copyWith(
            color: AppColors.primary,
          ),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),

        // Divider
        dividerTheme: const DividerThemeData(
          color: AppColors.grey200,
          thickness: 1,
          space: 1,
        ),

        // Typography
        textTheme: TextTheme(
          displayLarge: AppTextStyles.h1,
          displayMedium: AppTextStyles.h2,
          headlineMedium: AppTextStyles.h3,
          titleLarge: AppTextStyles.h4,
          bodyLarge: AppTextStyles.bodyLarge,
          bodyMedium: AppTextStyles.bodyMedium,
          bodySmall: AppTextStyles.bodySmall,
          labelLarge: AppTextStyles.labelLarge,
          labelMedium: AppTextStyles.labelMedium,
          labelSmall: AppTextStyles.labelSmall,
        ),
      );
}
