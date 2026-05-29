import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/home_models.dart';

// ─────────────────────────────────────────
//  ANNOUNCEMENT DETAIL SCREEN
// ─────────────────────────────────────────

class AnnouncementDetailScreen extends StatelessWidget {
  const AnnouncementDetailScreen({
    super.key,
    required this.announcement,
  });

  final Announcement announcement;

  Color get _catColor => switch (announcement.category) {
    'Meeting' => AppColors.info,
    'Policy'  => AppColors.warning,
    'Holiday' => AppColors.success,
    _         => AppColors.grey400,
  };

  IconData get _catIcon => switch (announcement.category) {
    'Meeting' => Icons.people_alt_rounded,
    'Policy'  => Icons.description_rounded,
    'Holiday' => Icons.celebration_rounded,
    _         => Icons.campaign_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Column(
        children: [
          // ── Header ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.fromLTRB(16, top + 12, 16, 20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Detail Pengumuman',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ],
            ),
          ),

          // ── Content ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category + Date
                  Row(
                    children: [
                      if (announcement.category != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _catColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_catIcon, size: 12, color: _catColor),
                              const SizedBox(width: 4),
                              Text(
                                announcement.category!,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _catColor),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      const Icon(Icons.access_time_rounded, size: 12, color: AppColors.grey400),
                      const SizedBox(width: 4),
                      Text(announcement.date,
                          style: const TextStyle(fontSize: 11, color: AppColors.grey500)),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Title
                  Text(
                    announcement.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.grey900,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: AppColors.grey200, height: 1),
                  const SizedBox(height: 16),

                  // Content body
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      announcement.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.grey800,
                        height: 1.7,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Attachments section (placeholder for future API)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.attach_file_rounded, size: 16, color: AppColors.primary),
                            SizedBox(width: 6),
                            Text('Lampiran',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.grey900)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // No attachments placeholder
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: AppColors.grey100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.grey200),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.folder_open_rounded, size: 28, color: AppColors.grey400),
                              SizedBox(height: 6),
                              Text('Tidak ada lampiran',
                                  style: TextStyle(fontSize: 12, color: AppColors.grey500)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
