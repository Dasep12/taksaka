import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum BadgeStatus { present, absent, late, leave, nonShift }

/// ─────────────────────────────────────────
///  STATUS BADGE
/// ─────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.status,
    this.backgroundColor,
    this.textColor,
    this.icon,
  });

  final String label;
  final BadgeStatus? status;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;

  Color get _bg {
    if (backgroundColor != null) return backgroundColor!;
    return switch (status) {
      BadgeStatus.present  => AppColors.success.withOpacity(0.15),
      BadgeStatus.absent   => AppColors.error.withOpacity(0.15),
      BadgeStatus.late     => AppColors.warning.withOpacity(0.15),
      BadgeStatus.leave    => AppColors.info.withOpacity(0.15),
      BadgeStatus.nonShift => Colors.white.withOpacity(0.2),
      null                 => AppColors.grey200,
    };
  }

  Color get _fg {
    if (textColor != null) return textColor!;
    return switch (status) {
      BadgeStatus.present  => AppColors.success,
      BadgeStatus.absent   => AppColors.error,
      BadgeStatus.late     => AppColors.warning,
      BadgeStatus.leave    => AppColors.info,
      BadgeStatus.nonShift => Colors.white,
      null                 => AppColors.grey800,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: _fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _fg,
            ),
          ),
        ],
      ),
    );
  }
}
