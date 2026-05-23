import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_spacing.dart';

/// ─────────────────────────────────────────
///  APP BUTTON  –  Primary / Secondary / Ghost
/// ─────────────────────────────────────────
enum AppButtonVariant { primary, secondary, ghost, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = AppSizes.btnMd,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double height;

  Color get _bgColor => switch (variant) {
        AppButtonVariant.primary   => AppColors.primary,
        AppButtonVariant.secondary => AppColors.accent,
        AppButtonVariant.ghost     => Colors.transparent,
        AppButtonVariant.danger    => AppColors.error,
      };

  Color get _fgColor => switch (variant) {
        AppButtonVariant.primary   => AppColors.secondary,
        AppButtonVariant.secondary => AppColors.secondary,
        AppButtonVariant.ghost     => AppColors.primary,
        AppButtonVariant.danger    => AppColors.secondary,
      };

  @override
  Widget build(BuildContext context) {
    Widget content = isLoading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _fgColor,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: _fgColor),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _fgColor,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          );

    final btn = SizedBox(
      height: height,
      width: isFullWidth ? double.infinity : null,
      child: variant == AppButtonVariant.ghost
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: content,
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: _bgColor,
                foregroundColor: _fgColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: content,
            ),
    );

    return btn;
  }
}
