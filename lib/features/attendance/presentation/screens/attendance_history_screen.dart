import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/attendance_history_models.dart';
import '../../data/attendance_history_service.dart';

/// ─────────────────────────────────────────
///  ATTENDANCE HISTORY SCREEN
/// ─────────────────────────────────────────
class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen>
    with SingleTickerProviderStateMixin {
  final _service = AttendanceHistoryService.instance;

  late int _selectedMonth;
  late int _selectedYear;
  bool _isLoading = true;
  List<AttendanceHistoryRecord> _records = [];
  AttendanceMonthlySummary? _summary;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  static const _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadData();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Data Loading ─────────────────────────

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    _fadeCtrl.reset();

    final records = await _service.fetchHistory(
      month: _selectedMonth,
      year: _selectedYear,
    );
    final summary = _service.buildSummary(records, _selectedMonth, _selectedYear);

    if (mounted) {
      setState(() {
        _records = records;
        _summary = summary;
        _isLoading = false;
      });
      _fadeCtrl.forward();
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth += delta;
      if (_selectedMonth > 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else if (_selectedMonth < 1) {
        _selectedMonth = 12;
        _selectedYear--;
      }
    });
    _loadData();
  }

  // ── Year Picker Dialog ────────────────────

  void _showYearPicker() {
    final now = DateTime.now();
    final years = List.generate(5, (i) => now.year - 3 + i);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pilih Tahun',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              ...years.map((y) {
                final isSelected = y == _selectedYear;
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    if (y != _selectedYear) {
                      setState(() => _selectedYear = y);
                      _loadData();
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$y',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppColors.primary,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Column(
        children: [
          _buildHeader(),
          _buildMonthYearSelector(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : FadeTransition(
                    opacity: _fadeAnim,
                    child: _records.isEmpty
                        ? _buildEmptyState()
                        : _buildContent(),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────

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
      padding: EdgeInsets.fromLTRB(16, top + 12, 16, 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Riwayat Absensi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Rekap kehadiran bulanan',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // ── Month + Year Selector ─────────────────

  Widget _buildMonthYearSelector() {
    final now = DateTime.now();
    final isCurrentMonth =
        _selectedMonth == now.month && _selectedYear == now.year;

    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            // ← prev month
            _NavBtn(
              icon: Icons.chevron_left_rounded,
              onTap: () => _changeMonth(-1),
            ),

            // Month name
            Expanded(
              child: GestureDetector(
                onTap: _showYearPicker,
                child: Column(
                  children: [
                    Text(
                      _monthNames[_selectedMonth - 1],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    // Year with dropdown icon — tap to change
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$_selectedYear',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.arrow_drop_down_rounded,
                          size: 16,
                          color: Colors.white70,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // → next month
            _NavBtn(
              icon: Icons.chevron_right_rounded,
              onTap: isCurrentMonth ? null : () => _changeMonth(1),
              disabled: isCurrentMonth,
            ),
          ],
        ),
      ),
    );
  }

  // ── Content ───────────────────────────────

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Summary
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: _buildSummaryCards(),
            ),
          ),

          // Attendance rate
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildRateCard(),
            ),
          ),

          // Section title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  const Text(
                    'Detail Kehadiran',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey900,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_records.length} hari',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Record list
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: _AttendanceRecordCard(record: _records[i]),
              ),
              childCount: _records.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  // ── Summary Cards ─────────────────────────

  Widget _buildSummaryCards() {
    final s = _summary;
    if (s == null) return const SizedBox.shrink();

    return Row(
      children: [
        _SummaryTile(
          label: 'Hadir',
          value: '${s.totalPresent}',
          color: AppColors.success,
          icon: Icons.check_circle_rounded,
        ),
        const SizedBox(width: 8),
        _SummaryTile(
          label: 'Terlambat',
          value: '${s.totalLate}',
          color: AppColors.warning,
          icon: Icons.access_time_rounded,
        ),
        const SizedBox(width: 8),
        _SummaryTile(
          label: 'Tdk Hadir',
          value: '${s.totalAbsent}',
          color: AppColors.error,
          icon: Icons.cancel_rounded,
        ),
        const SizedBox(width: 8),
        _SummaryTile(
          label: 'Libur',
          value: '${s.totalHoliday}',
          color: AppColors.info,
          icon: Icons.beach_access_rounded,
        ),
      ],
    );
  }

  // ── Rate Card ─────────────────────────────

  Widget _buildRateCard() {
    final s = _summary;
    if (s == null) return const SizedBox.shrink();
    final rate = s.attendanceRate;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
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
              const Text(
                'Tingkat Kehadiran',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey800,
                ),
              ),
              Text(
                '${rate.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: rate / 100,
              minHeight: 8,
              backgroundColor: AppColors.grey200,
              valueColor: AlwaysStoppedAnimation<Color>(
                rate >= 90
                    ? AppColors.success
                    : rate >= 70
                        ? AppColors.warning
                        : AppColors.error,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${s.totalPresent + s.totalLate} hadir dari ${s.totalWorkDays} hari kerja',
            style: const TextStyle(fontSize: 11, color: AppColors.grey500),
          ),
        ],
      ),
    );
  }

  // ── Empty State ───────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_busy_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada data absensi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.grey800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tidak ada rekap untuk ${_monthNames[_selectedMonth - 1]} $_selectedYear',
            style: const TextStyle(fontSize: 13, color: AppColors.grey500),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Muat Ulang'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Summary Tile ──────────────────────────

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.grey500,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Nav Button ────────────────────────────

class _NavBtn extends StatelessWidget {
  const _NavBtn({required this.icon, this.onTap, this.disabled = false});
  final IconData icon;
  final VoidCallback? onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: disabled
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: disabled ? Colors.white30 : Colors.white,
          size: 22,
        ),
      ),
    );
  }
}

// ─── Record Card ───────────────────────────

class _AttendanceRecordCard extends StatelessWidget {
  const _AttendanceRecordCard({required this.record});
  final AttendanceHistoryRecord record;

  Color _statusColor(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.present:    return AppColors.success;
      case AttendanceStatus.late:       return AppColors.warning;
      case AttendanceStatus.absent:     return AppColors.error;
      case AttendanceStatus.leave:
      case AttendanceStatus.permission: return AppColors.info;
      case AttendanceStatus.holiday:    return AppColors.grey500;
    }
  }

  IconData _statusIcon(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.present:    return Icons.check_circle_rounded;
      case AttendanceStatus.late:       return Icons.access_time_rounded;
      case AttendanceStatus.absent:     return Icons.cancel_rounded;
      case AttendanceStatus.leave:      return Icons.beach_access_rounded;
      case AttendanceStatus.permission: return Icons.assignment_rounded;
      case AttendanceStatus.holiday:    return Icons.weekend_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = record.resolvedStatus;
    final sColor = _statusColor(status);
    final isHoliday = status == AttendanceStatus.holiday;

    return Container(
      decoration: BoxDecoration(
        color: isHoliday
            ? AppColors.grey100
            : AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: isHoliday
            ? Border.all(color: AppColors.grey200)
            : null,
        boxShadow: isHoliday
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // ── Date badge ──
            Container(
              width: 48,
              height: 54,
              decoration: BoxDecoration(
                color: isHoliday
                    ? AppColors.grey200
                    : AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${record.workDate.day}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isHoliday ? AppColors.grey500 : AppColors.primary,
                      height: 1,
                    ),
                  ),
                  Text(
                    record.dayShort,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isHoliday
                          ? AppColors.grey400
                          : AppColors.primaryLight,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // ── Info column ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date + status badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          record.formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isHoliday
                                ? AppColors.grey500
                                : AppColors.grey900,
                          ),
                        ),
                      ),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: sColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: sColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _statusIcon(status),
                              size: 10,
                              color: sColor,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              record.statusLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: sColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Shift name
                  Row(
                    children: [
                      Icon(
                        Icons.work_outline_rounded,
                        size: 11,
                        color: isHoliday ? AppColors.grey400 : AppColors.grey500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        record.shiftName,
                        style: TextStyle(
                          fontSize: 11,
                          color: isHoliday ? AppColors.grey400 : AppColors.grey500,
                        ),
                      ),
                    ],
                  ),

                  // ── Divider + time row (all non-holiday workdays) ──
                  if (!isHoliday) ...[
                    const SizedBox(height: 8),
                    const Divider(height: 1, color: AppColors.grey200),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _TimeChip(
                          icon: Icons.login_rounded,
                          label: 'Masuk',
                          time: record.timeInFormatted,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 12),
                        _TimeChip(
                          icon: Icons.logout_rounded,
                          label: 'Keluar',
                          time: record.timeOutFormatted,
                          color: AppColors.error,
                        ),
                        const Spacer(),
                        // Durasi hanya jika keduanya ada
                        if (record.checkIn != null && record.checkOut != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Durasi',
                                  style: TextStyle(
                                      fontSize: 9, color: AppColors.grey500)),
                              Text(
                                record.workDuration,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],

                  // Late badge
                  if (status == AttendanceStatus.late) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time_filled_rounded,
                            size: 11,
                            color: AppColors.warning,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Terlambat masuk kerja',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Time Chip ─────────────────────────────

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.icon,
    required this.label,
    required this.time,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String time;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 13, color: color),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 9, color: AppColors.grey500),
            ),
            Text(
              time,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.grey900,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
