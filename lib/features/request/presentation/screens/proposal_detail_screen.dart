import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'proposed_screen.dart';

// ─────────────────────────────────────────
//  PROPOSAL DETAIL SCREEN
//  Menampilkan rincian pengajuan & tahapan persetujuan (approval)
// ─────────────────────────────────────────

class ApprovalStage {
  const ApprovalStage({
    required this.role,
    required this.approverName,
    required this.status,
    this.approvedAt,
    this.note,
  });

  final String role;
  final String approverName;
  final ProposalStatus status;
  final String? approvedAt;
  final String? note;
}

class ProposalDetailScreen extends StatelessWidget {
  const ProposalDetailScreen({
    super.key,
    required this.item,
  });

  final ProposalItem item;

  Color get _typeColor {
    switch (item.type) {
      case ProposalType.overtime:   return AppColors.warning;
      case ProposalType.leave:      return AppColors.info;
      case ProposalType.permission: return AppColors.success;
    }
  }

  String get _typeLabel {
    switch (item.type) {
      case ProposalType.overtime:   return 'Overtime';
      case ProposalType.leave:      return 'Cuti';
      case ProposalType.permission: return 'Izin';
    }
  }

  Color get _statusColor {
    switch (item.status) {
      case ProposalStatus.pending:  return AppColors.warning;
      case ProposalStatus.approved: return AppColors.success;
      case ProposalStatus.rejected: return AppColors.error;
    }
  }

  String get _statusLabel {
    switch (item.status) {
      case ProposalStatus.pending:  return 'Menunggu';
      case ProposalStatus.approved: return 'Disetujui';
      case ProposalStatus.rejected: return 'Ditolak';
    }
  }

  // Generate mock approval stages based on current proposal status
  List<ApprovalStage> get _stages {
    switch (item.status) {
      case ProposalStatus.approved:
        return const [
          ApprovalStage(
            role: 'Supervisor / Manager',
            approverName: 'Hendra Wijaya',
            status: ProposalStatus.approved,
            approvedAt: '28 Mei 2026 09:30',
            note: 'Approved, pastikan hand-over pekerjaan berjalan lancar.',
          ),
          ApprovalStage(
            role: 'HR Department',
            approverName: 'Riana Lestari',
            status: ProposalStatus.approved,
            approvedAt: '28 Mei 2026 14:15',
            note: 'Sesuai dengan ketentuan kuota tahunan.',
          ),
        ];
      case ProposalStatus.rejected:
        return const [
          ApprovalStage(
            role: 'Supervisor / Manager',
            approverName: 'Hendra Wijaya',
            status: ProposalStatus.rejected,
            approvedAt: '26 Mei 2026 08:12',
            note: 'Ditolak karena berbenturan dengan jadwal rilis produksi penting.',
          ),
          ApprovalStage(
            role: 'HR Department',
            approverName: 'Riana Lestari',
            status: ProposalStatus.pending,
          ),
        ];
      case ProposalStatus.pending:
        return const [
          ApprovalStage(
            role: 'Supervisor / Manager',
            approverName: 'Hendra Wijaya',
            status: ProposalStatus.approved,
            approvedAt: '28 Mei 2026 17:00',
            note: 'Disetujui di tingkat pertama.',
          ),
          ApprovalStage(
            role: 'HR Department',
            approverName: 'Riana Lestari',
            status: ProposalStatus.pending,
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final tc = _typeColor;
    final sc = _statusColor;

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
                  child: Text('Detail Pengajuan',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ],
            ),
          ),

          // ── Scrollable Body ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Info Card Utama
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: tc.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(_typeLabel,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: tc)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: sc.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(_statusLabel,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sc)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.grey900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: AppColors.grey200, height: 1),
                        const SizedBox(height: 12),
                        _buildDetailRow(Icons.calendar_today_rounded, 'Tanggal Pengajuan', item.date),
                        const SizedBox(height: 8),
                        _buildDetailRow(Icons.history_rounded, 'Tanggal Dibuat',
                            '${item.submittedAt.day} Mei ${item.submittedAt.year}'),
                        if (item.description != null) ...[
                          const SizedBox(height: 12),
                          const Divider(color: AppColors.grey200, height: 1),
                          const SizedBox(height: 12),
                          const Text(
                            'Keterangan / Alasan',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.grey500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.description!,
                            style: const TextStyle(fontSize: 13, color: AppColors.grey800, height: 1.4),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 2. Tahapan Approval (Workflow)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Text(
                      'Tahapan Persetujuan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

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
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _stages.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 20),
                      itemBuilder: (ctx, index) {
                        final stage = _stages[index];
                        return _buildWorkflowStep(index + 1, stage, index == _stages.length - 1);
                      },
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.grey400),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.grey500)),
              Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grey800)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkflowStep(int stepNumber, ApprovalStage stage, bool isLast) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (stage.status) {
      case ProposalStatus.approved:
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_rounded;
        statusText = 'Disetujui';
        break;
      case ProposalStatus.rejected:
        statusColor = AppColors.error;
        statusIcon = Icons.cancel_rounded;
        statusText = 'Ditolak';
        break;
      case ProposalStatus.pending:
        statusColor = AppColors.warning;
        statusIcon = Icons.hourglass_empty_rounded;
        statusText = 'Menunggu';
        break;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Indikator Tahap (Nomor / Lingkaran)
        Column(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: statusColor, width: 1.5),
              ),
              child: Center(
                child: Text(
                  '$stepNumber',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: statusColor),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 14),

        // Konten Informasi
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    stage.role,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.grey900),
                  ),
                  Row(
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                stage.approverName,
                style: const TextStyle(fontSize: 12, color: AppColors.grey800),
              ),
              if (stage.approvedAt != null) ...[
                const SizedBox(height: 2),
                Text(
                  stage.approvedAt!,
                  style: const TextStyle(fontSize: 10, color: AppColors.grey400),
                ),
              ],
              if (stage.note != null) ...[
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    stage.note!,
                    style: const TextStyle(fontSize: 11, color: AppColors.grey600, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
