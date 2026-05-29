import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

// ─────────────────────────────────────────
//  E-SLIP SCREEN
//  Menampilkan slip gaji bulanan
// ─────────────────────────────────────────

class EslipScreen extends StatefulWidget {
  const EslipScreen({super.key});
  @override
  State<EslipScreen> createState() => _EslipScreenState();
}

class _EslipScreenState extends State<EslipScreen> {
  late int _selectedMonth;
  late int _selectedYear;

  static const _monthNames = [
    'Januari','Februari','Maret','April','Mei','Juni',
    'Juli','Agustus','September','Oktober','November','Desember',
  ];

  // Mock data — replace with API
  final _slipData = const _SlipData(
    employeeName: 'DASEP DEPIYAWAN',
    employeeId: 'EMP-001',
    department: 'IT Development',
    position: 'Software Engineer',
    period: 'Mei 2026',
    basicSalary: 8000000,
    transportAllowance: 500000,
    mealAllowance: 600000,
    positionAllowance: 1000000,
    overtimePay: 750000,
    bonus: 0,
    bpjsKes: 320000,
    bpjsTk: 240000,
    pph21: 450000,
    otherDeductions: 0,
  );

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth += delta;
      if (_selectedMonth > 12) { _selectedMonth = 1; _selectedYear++; }
      if (_selectedMonth < 1) { _selectedMonth = 12; _selectedYear--; }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Column(
        children: [
          _buildHeader(),
          _buildMonthSelector(),
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                children: [
                  _buildEmployeeInfo(),
                  const SizedBox(height: 12),
                  _buildEarningsCard(),
                  const SizedBox(height: 12),
                  _buildDeductionsCard(),
                  const SizedBox(height: 12),
                  _buildTotalCard(),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                ],
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
                Text('E-Slip Gaji', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                Text('Slip gaji digital Anda', style: TextStyle(fontSize: 12, color: Colors.white60)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _changeMonth(-1),
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    '${_monthNames[_selectedMonth - 1]} $_selectedYear',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _changeMonth(1),
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_slipData.employeeName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.grey900)),
                const SizedBox(height: 2),
                Text('${_slipData.employeeId} • ${_slipData.position}', style: const TextStyle(fontSize: 11, color: AppColors.grey500)),
                Text(_slipData.department, style: const TextStyle(fontSize: 11, color: AppColors.grey400)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsCard() {
    final d = _slipData;
    return _SectionCard(
      title: 'Pendapatan',
      icon: Icons.arrow_downward_rounded,
      color: AppColors.success,
      totalLabel: 'Total Pendapatan',
      total: d.totalEarnings,
      rows: [
        _SlipRow('Gaji Pokok', d.basicSalary),
        _SlipRow('Tunj. Transportasi', d.transportAllowance),
        _SlipRow('Tunj. Makan', d.mealAllowance),
        _SlipRow('Tunj. Jabatan', d.positionAllowance),
        _SlipRow('Lembur', d.overtimePay),
        if (d.bonus > 0) _SlipRow('Bonus', d.bonus),
      ],
    );
  }

  Widget _buildDeductionsCard() {
    final d = _slipData;
    return _SectionCard(
      title: 'Potongan',
      icon: Icons.arrow_upward_rounded,
      color: AppColors.error,
      totalLabel: 'Total Potongan',
      total: d.totalDeductions,
      rows: [
        _SlipRow('BPJS Kesehatan', d.bpjsKes),
        _SlipRow('BPJS Ketenagakerjaan', d.bpjsTk),
        _SlipRow('PPh 21', d.pph21),
        if (d.otherDeductions > 0) _SlipRow('Potongan Lain', d.otherDeductions),
      ],
    );
  }

  Widget _buildTotalCard() {
    final d = _slipData;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Take Home Pay', style: TextStyle(fontSize: 12, color: Colors.white70)),
              SizedBox(height: 2),
              Text('Gaji Bersih', style: TextStyle(fontSize: 10, color: Colors.white54)),
            ],
          ),
          Text(
            _formatCurrency(d.netSalary),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double val) {
    final s = val.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return 'Rp ${buf.toString()}';
  }
}

// ─── Data Model ────────────────────────────

class _SlipData {
  const _SlipData({
    required this.employeeName,
    required this.employeeId,
    required this.department,
    required this.position,
    required this.period,
    required this.basicSalary,
    required this.transportAllowance,
    required this.mealAllowance,
    required this.positionAllowance,
    required this.overtimePay,
    required this.bonus,
    required this.bpjsKes,
    required this.bpjsTk,
    required this.pph21,
    required this.otherDeductions,
  });
  final String employeeName, employeeId, department, position, period;
  final double basicSalary, transportAllowance, mealAllowance, positionAllowance;
  final double overtimePay, bonus;
  final double bpjsKes, bpjsTk, pph21, otherDeductions;

  double get totalEarnings =>
      basicSalary + transportAllowance + mealAllowance + positionAllowance + overtimePay + bonus;
  double get totalDeductions => bpjsKes + bpjsTk + pph21 + otherDeductions;
  double get netSalary => totalEarnings - totalDeductions;
}

class _SlipRow {
  const _SlipRow(this.label, this.amount);
  final String label;
  final double amount;
}

// ─── Section Card ──────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.totalLabel,
    required this.total,
    required this.rows,
  });
  final String title;
  final IconData icon;
  final Color color;
  final String totalLabel;
  final double total;
  final List<_SlipRow> rows;

  String _fmt(double val) {
    final s = val.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return 'Rp ${buf.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
              ],
            ),
          ),
          // Rows
          ...rows.map((r) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(r.label, style: const TextStyle(fontSize: 12, color: AppColors.grey600)),
                Text(_fmt(r.amount), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.grey900)),
              ],
            ),
          )),
          // Total
          Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(totalLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
                Text(_fmt(total), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
