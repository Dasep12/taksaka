import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/schedule_models.dart';
import '../../data/schedule_service.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  final _service = ScheduleService.instance;

  late int _selectedYear;
  late int _selectedMonth;
  bool _isLoading = true;
  List<HolidayRecord> _allHolidays = [];
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  static const _monthNames = [
    'Januari','Februari','Maret','April','Mei','Juni',
    'Juli','Agustus','September','Oktober','November','Desember',
  ];
  static const _dayShort = ['Sen','Sel','Rab','Kam','Jum','Sab','Min'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
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

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _fadeCtrl.reset();
    final data = await _service.fetchWorkCalendar(year: _selectedYear);
    if (mounted) {
      setState(() {
        _allHolidays = data;
        _isLoading = false;
      });
      _fadeCtrl.forward();
    }
  }

  void _changeYear(int delta) {
    setState(() => _selectedYear += delta);
    _loadData();
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth += delta;
      if (_selectedMonth > 12) { _selectedMonth = 1; _selectedYear++; _loadData(); return; }
      if (_selectedMonth < 1)  { _selectedMonth = 12; _selectedYear--; _loadData(); return; }
    });
  }

  List<HolidayRecord> get _monthHolidays =>
      _service.filterByMonth(_allHolidays, _selectedMonth, _selectedYear);

  Set<DateTime> get _holidayDates =>
      _service.getHolidayDates(_allHolidays);

  // ── Build ─────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : FadeTransition(
                    opacity: _fadeAnim,
                    child: _buildBody(),
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
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kalender Kerja',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                Text('Hari libur nasional & perusahaan',
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
            child: const Icon(Icons.event_rounded, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Year selector
          SliverToBoxAdapter(child: _buildYearSelector()),
          // Calendar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _buildCalendar(),
            ),
          ),
          // Yearly summary
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildYearlySummary(),
            ),
          ),
          // Month holiday list
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _buildMonthHeader(),
            ),
          ),
          if (_monthHolidays.isEmpty)
            SliverToBoxAdapter(child: _buildNoHoliday())
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: _HolidayCard(record: _monthHolidays[i]),
                ),
                childCount: _monthHolidays.length,
              ),
            ),

          // Extra bottom padding so content never gets cut off
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.of(context).padding.bottom + 32,
            ),
          ),
        ],
      ),
    );
  }

  // ── Year Selector ─────────────────────────

  Widget _buildYearSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ← Prev year
          IconButton(
            onPressed: () => _changeYear(-1),
            icon: const Icon(Icons.chevron_left_rounded, color: AppColors.primary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '$_selectedYear',
                  style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary,
                  ),
                ),
                Text(
                  '${_allHolidays.length} hari libur',
                  style: const TextStyle(fontSize: 11, color: AppColors.grey500),
                ),
              ],
            ),
          ),
          // → Next year (max current year + 1)
          IconButton(
            onPressed: _selectedYear < DateTime.now().year + 1
                ? () => _changeYear(1)
                : null,
            icon: Icon(
              Icons.chevron_right_rounded,
              color: _selectedYear < DateTime.now().year + 1
                  ? AppColors.primary
                  : AppColors.grey300,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  // ── Mini Calendar ─────────────────────────

  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Month nav bar
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _changeMonth(-1),
                  icon: const Icon(Icons.chevron_left_rounded, color: AppColors.primary, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                Expanded(
                  child: Text(
                    '${_monthNames[_selectedMonth - 1]} $_selectedYear',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.grey900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _changeMonth(1),
                  icon: const Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
          // Day headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: _dayShort.map((d) {
                final isSun = d == 'Min';
                final isSat = d == 'Sab';
                return Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSun || isSat ? AppColors.error : AppColors.grey500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),
          // Date grid
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: _buildDateGrid(),
          ),
          // Legend
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                _LegendDot(color: AppColors.error, label: 'Libur Nasional'),
                const SizedBox(width: 16),
                _LegendDot(color: AppColors.warning, label: 'Libur Perusahaan'),
                const SizedBox(width: 16),
                _LegendDot(color: AppColors.info, label: 'Cuti Bersama'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateGrid() {
    final today = DateTime.now();
    final firstDay = DateTime(_selectedYear, _selectedMonth, 1);
    // weekday: Mon=1 → offset 0, Sun=7 → offset 6
    final startOffset = (firstDay.weekday - 1) % 7;
    final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final holidayDates = _holidayDates;

    return Column(
      children: List.generate(rows, (row) {
        return Row(
          children: List.generate(7, (col) {
            final cellIndex = row * 7 + col;
            final dayNum = cellIndex - startOffset + 1;
            if (dayNum < 1 || dayNum > daysInMonth) {
              return const Expanded(child: SizedBox(height: 36));
            }

            final date = DateTime(_selectedYear, _selectedMonth, dayNum);
            final isHoliday = holidayDates.contains(date);
            final isToday = date.year == today.year &&
                date.month == today.month &&
                date.day == today.day;
            final isWeekend = date.weekday == 6 || date.weekday == 7;

            // Find holiday type for color
            Color? dotColor;
            if (isHoliday) {
              final h = _allHolidays.firstWhere(
                (r) => r.holidayDate.year == date.year &&
                    r.holidayDate.month == date.month &&
                    r.holidayDate.day == date.day,
              );
              switch (h.holidayType) {
                case HolidayType.national:  dotColor = AppColors.error; break;
                case HolidayType.company:   dotColor = AppColors.warning; break;
                case HolidayType.massLeave: dotColor = AppColors.info; break;
              }
            }

            return Expanded(
              child: GestureDetector(
                onTap: isHoliday ? () => _onHolidayTap(date) : null,
                child: Container(
                  height: 36,
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: isHoliday
                        ? dotColor!.withValues(alpha: 0.12)
                        : isToday
                            ? AppColors.primary
                            : null,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday
                        ? Border.all(color: AppColors.primary, width: 1.5)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNum',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isToday || isHoliday
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isToday
                              ? Colors.white
                              : isHoliday
                                  ? dotColor
                                  : isWeekend
                                      ? AppColors.error.withValues(alpha: 0.6)
                                      : AppColors.grey800,
                        ),
                      ),
                      if (isHoliday)
                        Container(
                          width: 4, height: 4,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  void _onHolidayTap(DateTime date) {
    final holidays = _allHolidays.where(
      (r) => r.holidayDate.year == date.year &&
          r.holidayDate.month == date.month &&
          r.holidayDate.day == date.day,
    ).toList();
    if (holidays.isEmpty) return;
    final h = holidays.first;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${h.shortDate}: ${h.holidayName}'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Yearly Summary ────────────────────────

  Widget _buildYearlySummary() {
    final national = _allHolidays.where((h) => h.holidayType == HolidayType.national).length;
    final company  = _allHolidays.where((h) => h.holidayType == HolidayType.company).length;
    final mass     = _allHolidays.where((h) => h.holidayType == HolidayType.massLeave).length;

    return Row(
      children: [
        _SummaryChip(label: 'Nasional', count: national, color: AppColors.error),
        const SizedBox(width: 10),
        _SummaryChip(label: 'Perusahaan', count: company, color: AppColors.warning),
        const SizedBox(width: 10),
        _SummaryChip(label: 'Cuti Bersama', count: mass, color: AppColors.info),
      ],
    );
  }

  // ── Month Header ──────────────────────────

  Widget _buildMonthHeader() {
    return Row(
      children: [
        Text(
          'Libur ${_monthNames[_selectedMonth - 1]}',
          style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.grey900,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${_monthHolidays.length} hari',
            style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoHoliday() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.celebration_rounded, size: 36, color: AppColors.grey400),
          const SizedBox(height: 8),
          Text(
            'Tidak ada hari libur\ndi ${_monthNames[_selectedMonth - 1]} $_selectedYear',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.grey500, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ─── Holiday Card ──────────────────────────

class _HolidayCard extends StatelessWidget {
  const _HolidayCard({required this.record});
  final HolidayRecord record;

  Color get _typeColor {
    switch (record.holidayType) {
      case HolidayType.national:  return AppColors.error;
      case HolidayType.company:   return AppColors.warning;
      case HolidayType.massLeave: return AppColors.info;
    }
  }

  IconData get _typeIcon {
    switch (record.holidayType) {
      case HolidayType.national:  return Icons.flag_rounded;
      case HolidayType.company:   return Icons.business_rounded;
      case HolidayType.massLeave: return Icons.beach_access_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _typeColor;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left accent bar
          Container(
            width: 4,
            height: 62,
            decoration: BoxDecoration(
              color: c,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
            ),
          ),
          const SizedBox(width: 12),
          // Date badge
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${record.holidayDate.day}',
                  style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: c, height: 1,
                  ),
                ),
                Text(
                  record.shortDate.split(' ').last,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: c),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.holidayName,
                    style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.grey900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    record.formattedDate,
                    style: const TextStyle(fontSize: 11, color: AppColors.grey500),
                  ),
                ],
              ),
            ),
          ),
          // Type badge
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_typeIcon, size: 10, color: c),
                  const SizedBox(width: 3),
                  Text(
                    record.typeLabel,
                    style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700, color: c,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Summary Chip ──────────────────────────

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.count,
    required this.color,
  });
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10, color: AppColors.grey600, fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Legend Dot ────────────────────────────

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 9, color: AppColors.grey500)),
      ],
    );
  }
}
