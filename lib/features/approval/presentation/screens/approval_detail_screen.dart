import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../request/presentation/screens/proposed_screen.dart';
import 'approval_screen.dart';

// ─────────────────────────────────────────
//  APPROVAL DETAIL SCREEN
//  Menampilkan detail pengajuan dan tombol persetujuan individual (Approve/Reject)
// ─────────────────────────────────────────

class ApprovalDetailScreen extends StatelessWidget {
  const ApprovalDetailScreen({
    super.key,
    required this.item,
  });

  final ApprovalItem item;

  Color _getTypeColor(ProposalType type) {
    switch (type) {
      case ProposalType.overtime:   return AppColors.warning;
      case ProposalType.leave:      return AppColors.info;
      case ProposalType.permission: return AppColors.success;
    }
  }

  String _getTypeLabel(ProposalType type) {
    switch (type) {
      case ProposalType.overtime:   return 'Overtime';
      case ProposalType.leave:      return 'Cuti';
      case ProposalType.permission: return 'Izin';
    }
  }

  IconData _getTypeIcon(ProposalType type) {
    switch (type) {
      case ProposalType.overtime:   return Icons.work_history_rounded;
      case ProposalType.leave:      return Icons.beach_access_rounded;
      case ProposalType.permission: return Icons.assignment_ind_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final tc = _getTypeColor(item.type);

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
                  child: Text('Detail Pengajuan Staf',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ],
            ),
          ),

          // ── Scrollable Content ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Employee Info Card
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
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primarySurface,
                          child: Text(
                            item.employeeName[0],
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.employeeName,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.grey900),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.employeeRole,
                                style: const TextStyle(fontSize: 11, color: AppColors.grey500),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: tc.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_getTypeIcon(item.type), size: 12, color: tc),
                              const SizedBox(width: 4),
                              Text(
                                _getTypeLabel(item.type),
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: tc),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. Request Details Card
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informasi Pengajuan',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.grey900),
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: AppColors.grey200, height: 1),
                        const SizedBox(height: 12),
                        _buildDetailRow(Icons.title_rounded, 'Judul Pengajuan', item.title),
                        const SizedBox(height: 10),
                        _buildDetailRow(Icons.calendar_today_rounded, 'Tanggal / Periode', item.date),
                        const SizedBox(height: 12),
                        const Divider(color: AppColors.grey200, height: 1),
                        const SizedBox(height: 12),
                        const Text(
                          'Alasan / Keterangan',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.grey500),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.description,
                          style: const TextStyle(fontSize: 13, color: AppColors.grey800, height: 1.5),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. Workflow Steps Card (Tahapan approval saat ini)
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tahapan Persetujuan Saat Ini',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.grey900),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24, height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.warning, width: 1.5),
                              ),
                              child: const Center(
                                child: Text('1',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.warning)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Supervisor / Manager (Anda)',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.grey900)),
                                      Text('Menunggu',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.warning)),
                                    ],
                                  ),
                                  SizedBox(height: 2),
                                  Text('Tahap verifikasi pertama kelayakan pengajuan.',
                                      style: TextStyle(fontSize: 11, color: AppColors.grey500)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Bottom Action Buttons (Approve / Reject) ──
      bottomSheet: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Reject Button
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      title: const Text('Tolak Pengajuan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      content: const Text('Apakah Anda yakin ingin menolak pengajuan ini?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Batal', style: TextStyle(color: AppColors.grey500)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx); // Close dialog
                            Navigator.pop(context, 'reject'); // Return to list screen with 'reject'
                          },
                          child: const Text('Ya, Tolak', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Tolak', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 12),

            // Approve Button
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      title: const Text('Setujui Pengajuan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      content: const Text('Apakah Anda yakin ingin menyetujui pengajuan ini?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Batal', style: TextStyle(color: AppColors.grey500)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx); // Close dialog
                            Navigator.pop(context, 'approve'); // Return to list screen with 'approve'
                          },
                          child: const Text('Ya, Setujui', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Setujui', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.grey400),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.grey400)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.grey800)),
            ],
          ),
        ),
      ],
    );
  }
}
