import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// ─────────────────────────────────────────
///  SECTION HEADER with optional "View All"
/// ─────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.onViewAll,
    this.viewAllLabel = 'View All',
    this.padding,
  });

  final String title;
  final VoidCallback? onViewAll;
  final String viewAllLabel;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.h4),
          if (onViewAll != null)
            GestureDetector(
              onTap: onViewAll,
              child: Text(
                viewAllLabel,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
