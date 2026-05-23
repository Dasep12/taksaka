import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/home_models.dart';

/// ─────────────────────────────────────────
///  ANNOUNCEMENT CARD
/// ─────────────────────────────────────────
class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({
    super.key,
    required this.announcement,
    this.onTap,
  });

  final Announcement announcement;
  final VoidCallback? onTap;

  Color get _categoryColor => switch (announcement.category) {
        'Meeting' => AppColors.info,
        'Policy'  => AppColors.warning,
        'Holiday' => AppColors.success,
        _         => AppColors.grey400,
      };

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onTap,
      child: Row(
        children: [
          // Thumbnail / placeholder
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _categoryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              _categoryIcon,
              color: _categoryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        announcement.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey900,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (announcement.category != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _categoryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          announcement.category!,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: _categoryColor,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  announcement.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey600,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  announcement.date,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.grey400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData get _categoryIcon => switch (announcement.category) {
        'Meeting' => Icons.people_alt_rounded,
        'Policy'  => Icons.description_rounded,
        'Holiday' => Icons.celebration_rounded,
        _         => Icons.campaign_rounded,
      };
}
