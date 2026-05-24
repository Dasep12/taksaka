import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/attendance_models.dart';

/// ─────────────────────────────────────────
///  ATTENDANCE STEP INDICATOR
/// ─────────────────────────────────────────
class AttendanceStepIndicator extends StatelessWidget {
  const AttendanceStepIndicator({
    super.key,
    required this.currentStep,
  });

  final AttendanceStep currentStep;

  static const _steps = [
    _StepInfo(label: 'Lokasi',  icon: Icons.location_on_rounded),
    _StepInfo(label: 'Wajah',   icon: Icons.face_retouching_natural),
    _StepInfo(label: 'Selesai', icon: Icons.check_circle_rounded),
  ];

  int get _currentIndex => AttendanceStep.values.indexOf(currentStep);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line
          final lineIndex = i ~/ 2;
          final filled = _currentIndex > lineIndex;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              height: 2,
              color: filled ? AppColors.primary : AppColors.grey200,
            ),
          );
        }

        final stepIndex = i ~/ 2;
        final isCompleted = _currentIndex > stepIndex;
        final isActive    = _currentIndex == stepIndex;
        final step        = _steps[stepIndex];

        return _StepDot(
          label: step.label,
          icon: step.icon,
          isCompleted: isCompleted,
          isActive: isActive,
        );
      }),
    );
  }
}

class _StepInfo {
  const _StepInfo({required this.label, required this.icon});
  final String label;
  final IconData icon;
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.label,
    required this.icon,
    required this.isCompleted,
    required this.isActive,
  });

  final String label;
  final IconData icon;
  final bool isCompleted;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? AppColors.success
                : isActive
                    ? AppColors.primary
                    : AppColors.grey200,
            boxShadow: isActive
                ? [BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )]
                : null,
          ),
          child: Icon(
            isCompleted ? Icons.check_rounded : icon,
            size: 18,
            color: (isCompleted || isActive) ? Colors.white : AppColors.grey400,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            color: isActive
                ? AppColors.primary
                : isCompleted
                    ? AppColors.success
                    : AppColors.grey400,
          ),
        ),
      ],
    );
  }
}
