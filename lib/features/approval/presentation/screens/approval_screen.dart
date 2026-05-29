import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../request/presentation/screens/proposed_screen.dart';
import 'approval_detail_screen.dart';

// ─────────────────────────────────────────
//  APPROVAL SCREEN
//  Layar persetujuan pengajuan karyawan (Multi Approve / Multi Reject)
// ─────────────────────────────────────────

class ApprovalItem {
  ApprovalItem({
    required this.id,
    required this.employeeName,
    required this.employeeRole,
    required this.type,
    required this.title,
    required this.date,
    required this.description,
    this.avatarUrl,
  });

  final String id;
  final String employeeName;
  final String employeeRole;
  final ProposalType type;
  final String title;
  final String date;
  final String description;
  final String? avatarUrl;
}

class ApprovalScreen extends StatefulWidget {
  const ApprovalScreen({super.key});

  @override
  State<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends State<ApprovalScreen> {
  // Mock list of pending approvals
  final List<ApprovalItem> _pendingApprovals = [
    ApprovalItem(
      id: 'ap1',
      employeeName: 'Savannah Nguyen',
      employeeRole: 'Product Designer',
      type: ProposalType.leave,
      title: 'Cuti Tahunan',
      date: '12 - 15 Juni 2026',
      description: 'Acara pernikahan saudara kandung di luar kota.',
    ),
    ApprovalItem(
      id: 'ap2',
      employeeName: 'Leroy Davis',
      employeeRole: 'Frontend Engineer',
      type: ProposalType.overtime,
      title: 'Lembur Migrasi Database',
      date: '30 Mei 2026',
      description: 'Melakukan migrasi database dan release versi production.',
    ),
    ApprovalItem(
      id: 'ap3',
      employeeName: 'Tatiana Chen',
      employeeRole: 'UI Designer',
      type: ProposalType.permission,
      title: 'Izin Check-up Medis',
      date: '2 Juni 2026',
      description: 'Pemeriksaan rutin pasca rawat inap di RS Harapan.',
    ),
    ApprovalItem(
      id: 'ap4',
      employeeName: 'Nolan Douglas',
      employeeRole: 'Backend Engineer',
      type: ProposalType.overtime,
      title: 'Lembur Bug Fixing',
      date: '31 Mei 2026',
      description: 'Fixing critical issue payment gateway integration.',
    ),
    ApprovalItem(
      id: 'ap5',
      employeeName: 'Cheyenne Moore',
      employeeRole: 'QA Specialist',
      type: ProposalType.leave,
      title: 'Cuti Alasan Penting',
      date: '5 Juni 2026',
      description: 'Mengurus berkas kepindahan rumah tinggal.',
    ),
  ];

  // Selected item IDs for multi approve/reject
  final Set<String> _selectedIds = {};

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedIds.length == _pendingApprovals.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.clear();
        for (var item in _pendingApprovals) {
          _selectedIds.add(item.id);
        }
      }
    });
  }

  void _handleBulkApprove() {
    if (_selectedIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text('Setujui Pengajuan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: Text('Apakah Anda yakin ingin menyetujui ${_selectedIds.length} pengajuan yang dipilih?'),
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
              Navigator.pop(ctx);
              setState(() {
                _pendingApprovals.removeWhere((item) => _selectedIds.contains(item.id));
                _selectedIds.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pengajuan berhasil disetujui secara massal'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Ya, Setujui', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _handleBulkReject() {
    if (_selectedIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: const Text('Tolak Pengajuan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: Text('Apakah Anda yakin ingin menolak ${_selectedIds.length} pengajuan yang dipilih?'),
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
              Navigator.pop(ctx);
              setState(() {
                _pendingApprovals.removeWhere((item) => _selectedIds.contains(item.id));
                _selectedIds.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pengajuan berhasil ditolak secara massal'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            child: const Text('Ya, Tolak', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(ProposalType type) {
    switch (type) {
      case ProposalType.overtime:   return AppColors.warning;
      case ProposalType.leave:      return AppColors.info;
      case ProposalType.permission: return AppColors.success;
    }
  }

  IconData _getTypeIcon(ProposalType type) {
    switch (type) {
      case ProposalType.overtime:   return Icons.work_history_rounded;
      case ProposalType.leave:      return Icons.beach_access_rounded;
      case ProposalType.permission: return Icons.assignment_ind_rounded;
    }
  }

  String _getTypeLabel(ProposalType type) {
    switch (type) {
      case ProposalType.overtime:   return 'Overtime';
      case ProposalType.leave:      return 'Cuti';
      case ProposalType.permission: return 'Izin';
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final hasSelection = _selectedIds.isNotEmpty;

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Approval Pengajuan',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                      Text('Persetujuan massal pengajuan staf',
                          style: TextStyle(fontSize: 12, color: Colors.white60)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Select All / Action Header ──
          if (_pendingApprovals.isNotEmpty)
            Container(
              color: AppColors.cardBg,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _toggleSelectAll,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _selectedIds.length == _pendingApprovals.length,
                            onChanged: (_) => _toggleSelectAll(),
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _selectedIds.length == _pendingApprovals.length
                              ? 'Batal Pilih Semua'
                              : 'Pilih Semua (${_pendingApprovals.length})',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.grey800),
                        ),
                      ],
                    ),
                  ),
                  if (hasSelection)
                    Text(
                      '${_selectedIds.length} Terpilih',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                ],
              ),
            ),

          // ── Main List ──
          Expanded(
            child: _pendingApprovals.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    itemCount: _pendingApprovals.length,
                    itemBuilder: (ctx, index) {
                      final item = _pendingApprovals[index];
                      final isSelected = _selectedIds.contains(item.id);
                      final tc = _getTypeColor(item.type);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(10),
                          border: isSelected
                              ? Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5)
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ApprovalDetailScreen(item: item),
                                ),
                              );
                              if (!context.mounted) return;
                              if (result == 'approve') {
                                setState(() {
                                  _pendingApprovals.removeWhere((i) => i.id == item.id);
                                  _selectedIds.remove(item.id);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Pengajuan berhasil disetujui'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              } else if (result == 'reject') {
                                setState(() {
                                  _pendingApprovals.removeWhere((i) => i.id == item.id);
                                  _selectedIds.remove(item.id);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Pengajuan ditolak'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Checkbox selector
                                  GestureDetector(
                                    onTap: () {
                                      _toggleSelect(item.id);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 8, right: 10),
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: Checkbox(
                                          value: isSelected,
                                          onChanged: (_) => _toggleSelect(item.id),
                                          activeColor: AppColors.primary,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Main details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Requester Info
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 14,
                                              backgroundColor: AppColors.primarySurface,
                                              child: Text(
                                                item.employeeName[0],
                                                style: const TextStyle(
                                                    fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.employeeName,
                                                    style: const TextStyle(
                                                        fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.grey900),
                                                  ),
                                                  Text(
                                                    item.employeeRole,
                                                    style: const TextStyle(fontSize: 10, color: AppColors.grey500),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Request type tag
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: tc.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(_getTypeIcon(item.type), size: 10, color: tc),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    _getTypeLabel(item.type),
                                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: tc),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        const Divider(color: AppColors.grey200, height: 1),
                                        const SizedBox(height: 12),

                                        // Form data
                                        Text(
                                          item.title,
                                          style: const TextStyle(
                                              fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.grey900),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.grey400),
                                            const SizedBox(width: 6),
                                            Text(
                                              item.date,
                                              style: const TextStyle(fontSize: 11, color: AppColors.grey600),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          item.description,
                                          style: const TextStyle(fontSize: 12, color: AppColors.grey500, height: 1.4),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // ── Floating Action Bar (Approve / Reject Selected) ──
      bottomSheet: hasSelection
          ? Container(
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
                    color: Colors.black.withValues(alpha: 0.1),
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
                      onPressed: _handleBulkReject,
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: Text('Tolak (${_selectedIds.length})',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
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
                      onPressed: _handleBulkApprove,
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: Text('Setujui (${_selectedIds.length})',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.playlist_add_check_rounded, size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tidak Ada Pengajuan Pending',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.grey800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Semua pengajuan karyawan telah diproses.',
            style: TextStyle(fontSize: 12, color: AppColors.grey500),
          ),
        ],
      ),
    );
  }
}
