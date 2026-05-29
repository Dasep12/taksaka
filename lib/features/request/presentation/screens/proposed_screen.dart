import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'proposal_detail_screen.dart';

// ─────────────────────────────────────────
//  PROPOSED SCREEN
//  Menampilkan semua pengajuan: Overtime, Cuti, Izin
// ─────────────────────────────────────────

enum ProposalType { overtime, leave, permission }
enum ProposalStatus { pending, approved, rejected }

class ProposalItem {
  const ProposalItem({
    required this.id,
    required this.type,
    required this.title,
    required this.date,
    required this.submittedAt,
    required this.status,
    this.description,
  });
  final String id;
  final ProposalType type;
  final String title;
  final String date;
  final DateTime submittedAt;
  final ProposalStatus status;
  final String? description;
}

class ProposedScreen extends StatefulWidget {
  const ProposedScreen({super.key});
  @override
  State<ProposedScreen> createState() => _ProposedScreenState();
}

class _ProposedScreenState extends State<ProposedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  ProposalType? _filter;

  // ── Mock data (replace with API later) ──
  final List<ProposalItem> _items = [
    ProposalItem(
      id: '1',
      type: ProposalType.overtime,
      title: 'Lembur Awal',
      date: '28 Mei 2026',
      submittedAt: DateTime(2026, 5, 28),
      status: ProposalStatus.pending,
      description: 'Lembur pekerjaan proyek deadline',
    ),
    ProposalItem(
      id: '2',
      type: ProposalType.leave,
      title: 'Cuti Tahunan',
      date: '1–3 Juni 2026',
      submittedAt: DateTime(2026, 5, 27),
      status: ProposalStatus.approved,
      description: 'Liburan keluarga',
    ),
    ProposalItem(
      id: '3',
      type: ProposalType.permission,
      title: 'Izin Sakit',
      date: '25 Mei 2026',
      submittedAt: DateTime(2026, 5, 25),
      status: ProposalStatus.rejected,
      description: 'Demam dan flu',
    ),
    ProposalItem(
      id: '4',
      type: ProposalType.overtime,
      title: 'Lembur Pulang',
      date: '20 Mei 2026',
      submittedAt: DateTime(2026, 5, 20),
      status: ProposalStatus.approved,
      description: 'Penyelesaian laporan bulanan',
    ),
    ProposalItem(
      id: '5',
      type: ProposalType.permission,
      title: 'Izin Keperluan Keluarga',
      date: '15 Mei 2026',
      submittedAt: DateTime(2026, 5, 14),
      status: ProposalStatus.pending,
      description: 'Acara pernikahan saudara',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _tabCtrl.addListener(() {
      setState(() {
        switch (_tabCtrl.index) {
          case 0: _filter = null; break;
          case 1: _filter = ProposalType.overtime; break;
          case 2: _filter = ProposalType.leave; break;
          case 3: _filter = ProposalType.permission; break;
        }
      });
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  List<ProposalItem> get _filtered =>
      _filter == null ? _items : _items.where((i) => i.type == _filter).toList();

  int _countByStatus(ProposalStatus s) =>
      _items.where((i) => i.status == s).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Column(
        children: [
          _buildHeader(),
          _buildSummaryRow(),
          _buildTabBar(),
          Expanded(
            child: _filtered.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProposalDetailScreen(item: _filtered[i]),
                          ),
                        );
                      },
                      child: _ProposalCard(item: _filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, 16),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pengajuan Saya',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                Text('Riwayat semua pengajuan Anda',
                    style: TextStyle(fontSize: 12, color: Colors.white60)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.assignment_rounded, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          _StatusChip(
            label: 'Menunggu',
            count: _countByStatus(ProposalStatus.pending),
            color: AppColors.warning,
          ),
          const SizedBox(width: 10),
          _StatusChip(
            label: 'Disetujui',
            count: _countByStatus(ProposalStatus.approved),
            color: AppColors.success,
          ),
          const SizedBox(width: 10),
          _StatusChip(
            label: 'Ditolak',
            count: _countByStatus(ProposalStatus.rejected),
            color: AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.cardBg,
      child: TabBar(
        controller: _tabCtrl,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.grey500,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        tabs: const [
          Tab(text: 'Semua'),
          Tab(text: 'Overtime'),
          Tab(text: 'Cuti'),
          Tab(text: 'Izin'),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, size: 56, color: AppColors.grey300),
          const SizedBox(height: 12),
          const Text('Belum ada pengajuan',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.grey600)),
          const SizedBox(height: 6),
          Text('Tidak ada data untuk kategori ini',
              style: const TextStyle(fontSize: 13, color: AppColors.grey400)),
        ],
      ),
    );
  }
}

// ─── Proposal Card ─────────────────────────

class _ProposalCard extends StatelessWidget {
  const _ProposalCard({required this.item});
  final ProposalItem item;

  Color get _typeColor {
    switch (item.type) {
      case ProposalType.overtime:   return AppColors.warning;
      case ProposalType.leave:      return AppColors.info;
      case ProposalType.permission: return AppColors.success;
    }
  }

  IconData get _typeIcon {
    switch (item.type) {
      case ProposalType.overtime:   return Icons.work_history_rounded;
      case ProposalType.leave:      return Icons.beach_access_rounded;
      case ProposalType.permission: return Icons.assignment_ind_rounded;
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

  IconData get _statusIcon {
    switch (item.status) {
      case ProposalStatus.pending:  return Icons.hourglass_empty_rounded;
      case ProposalStatus.approved: return Icons.check_circle_rounded;
      case ProposalStatus.rejected: return Icons.cancel_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = _typeColor;
    final sc = _statusColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left type bar
          Container(
            width: 4, height: 70,
            decoration: BoxDecoration(
              color: tc,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            ),
          ),
          const SizedBox(width: 12),
          // Type icon
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: tc.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_typeIcon, color: tc, size: 20),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: tc.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(_typeLabel,
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: tc)),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.grey900),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 11, color: AppColors.grey400),
                      const SizedBox(width: 4),
                      Text(item.date,
                          style: const TextStyle(fontSize: 11, color: AppColors.grey500)),
                    ],
                  ),
                  if (item.description != null) ...[
                    const SizedBox(height: 2),
                    Text(item.description!,
                        style: const TextStyle(fontSize: 11, color: AppColors.grey400),
                        overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
          ),
          // Status badge
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: sc.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_statusIcon, size: 11, color: sc),
                  const SizedBox(width: 3),
                  Text(_statusLabel,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: sc)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status Chip ───────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.count, required this.color});
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text('$count',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.white70),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
