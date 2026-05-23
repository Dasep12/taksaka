import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_spacing.dart';

/// ─────────────────────────────────────────
///  APP CARD  –  reusable surface container
/// ─────────────────────────────────────────
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.borderRadius,
    this.elevation = 0,
    this.onTap,
    this.border,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? borderRadius;
  final double elevation;
  final VoidCallback? onTap;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppRadius.lg;
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? AppColors.cardBg,
        borderRadius: BorderRadius.circular(radius),
        border: border,
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: elevation * 4,
                  offset: Offset(0, elevation * 2),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(
            padding: padding ??
                const EdgeInsets.all(AppSpacing.lg),
            child: child,
          ),
        ),
      ),
    );
  }
}
