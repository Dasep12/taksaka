import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../domain/home_models.dart';

/// ─────────────────────────────────────────
///  ATTENDANCE CARD
/// ─────────────────────────────────────────
class AttendanceCard extends StatelessWidget {
  const AttendanceCard({
    super.key,
    required this.schedule,
    this.onClockIn,
    this.onClockOut,
  });

  final AttendanceSchedule schedule;
  final VoidCallback? onClockIn;
  final VoidCallback? onClockOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        // subtle gradient overlay
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryLight, AppColors.primaryDark],
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shift badge + date
          StatusBadge(
            label: schedule.shiftLabel,
            status: BadgeStatus.nonShift,
            icon: Icons.work_outline_rounded,
          ),
          const SizedBox(height: AppSpacing.md),

          // Date row
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: Colors.white70,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${schedule.date} (${schedule.timeRange})',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Clock In / Clock Out row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ClockButton(
                      label: schedule.checkInTime != null
                          ? 'Clock In \n' + schedule.checkInTime!
                          : 'Clock In \n --:--',
                      icon: Icons.login_rounded,
                      isActive: !schedule.isClockedIn,
                      onTap: onClockIn,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ClockButton(
                      label: schedule.checkOutTime != null
                          ? 'Clock Out \n' + schedule.checkOutTime!
                          : 'Clock Out \n --:--',
                      icon: Icons.logout_rounded,
                      isActive: schedule.isClockedIn && !schedule.isClockedOut,
                      onTap: schedule.isClockedIn ? onClockOut : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClockButton extends StatelessWidget {
  const _ClockButton({
    required this.label,
    required this.icon,
    required this.isActive,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withOpacity(0.15)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: isActive
              ? Border.all(color: Colors.white.withOpacity(0.3), width: 1)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isActive ? Colors.white : Colors.white38,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : Colors.white38,
                  ),
                ),
              ],
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: isActive ? Colors.white70 : Colors.white24,
            ),
          ],
        ),
      ),
    );
  }
}
