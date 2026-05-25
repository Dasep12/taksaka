import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';

/// ─────────────────────────────────────────
///  QUICK MENU GRID
/// ─────────────────────────────────────────
class QuickMenuGrid extends StatelessWidget {
  const QuickMenuGrid({super.key, required this.items});

  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: items.map((item) {
        return _QuickMenuItem(
          label: item['label'] as String,
          icon: item['icon'] as IconData,
          badge: item['badge'] as String?,
          onTap: item['onTap'] as VoidCallback?,
        );
      }).toList(),
    );
  }
}

class _QuickMenuItem extends StatelessWidget {
  const _QuickMenuItem({
    required this.label,
    required this.icon,
    this.badge,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, size: 22, color: AppColors.primary),
              ),
              if (badge != null)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: 64,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.grey800,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
