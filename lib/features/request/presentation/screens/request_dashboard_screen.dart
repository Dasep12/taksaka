import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/file_picker_widget.dart';
import '../../domain/request_models.dart';
import '../../data/request_service.dart';
import 'proposed_screen.dart';
import 'proposal_detail_screen.dart';

// ─────────────────────────────────────────
//  REQUEST DASHBOARD SCREEN
//  Menggunakan desain premium Tab & Sub-tab sesuai screenshot "Time Management"
// ─────────────────────────────────────────

class RequestDashboardScreen extends StatefulWidget {
  const RequestDashboardScreen({super.key});

  @override
  State<RequestDashboardScreen> createState() => _RequestDashboardScreenState();
}

class _RequestDashboardScreenState extends State<RequestDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // Sub-tabs index for each main tab: 0 = Request Form, 1 = Summary / History
  int _attendanceSubTab = 0;
  int _timeOffSubTab = 0;
  int _overtimeSubTab = 0;

  // ── Form State: Attendance/Izin ──
  final _attFormKey = GlobalKey<FormState>();
  DateTime? _attDate;
  String _attType = 'Izin Sakit';
  final List<String> _attTypes = ['Izin Sakit', 'Izin Terlambat', 'Izin Mendesak', 'Izin Setengah Hari'];
  final _attDescCtrl = TextEditingController();
  List<PlatformFile> _attFiles = [];
  bool _attLoading = false;

  // ── Form State: Time Off/Cuti ──
  final _toFormKey = GlobalKey<FormState>();
  DateTime? _toDate;
  String _toType = 'Cuti Tahunan';
  final List<String> _toTypes = ['Cuti Tahunan', 'Cuti Melahirkan', 'Cuti Besar', 'Cuti Menikah'];
  final _toDescCtrl = TextEditingController();
  List<PlatformFile> _toFiles = [];
  bool _toLoading = false;

  // ── Form State: Overtime/Lembur ──
  final _otFormKey = GlobalKey<FormState>();
  DateTime? _otDate;
  TimeOfDay? _otStart;
  TimeOfDay? _otEnd;
  final _otHoursCtrl = TextEditingController();
  final _otDescCtrl = TextEditingController();
  List<PlatformFile> _otFiles = [];
  bool _otLoading = false;

  // ── History Data (Mocked similarly to proposed_screen.dart) ──
  final List<ProposalItem> _historyItems = [
    ProposalItem(
      id: 'h1',
      type: ProposalType.overtime,
      title: 'Lembur Migrasi DB',
      date: '30 Mei 2026',
      submittedAt: DateTime(2026, 5, 29),
      status: ProposalStatus.pending,
      description: 'Lembur migrasi database versi baru.',
    ),
    ProposalItem(
      id: 'h2',
      type: ProposalType.leave,
      title: 'Cuti Tahunan',
      date: '12 - 15 Juni 2026',
      submittedAt: DateTime(2026, 5, 28),
      status: ProposalStatus.approved,
      description: 'Liburan bersama keluarga.',
    ),
    ProposalItem(
      id: 'h3',
      type: ProposalType.permission,
      title: 'Izin Check-up RS',
      date: '2 Juni 2026',
      submittedAt: DateTime(2026, 5, 27),
      status: ProposalStatus.pending,
      description: 'Check-up berkala kesehatan pasca rawat inap.',
    ),
    ProposalItem(
      id: 'h4',
      type: ProposalType.permission,
      title: 'Izin Terlambat',
      date: '25 Mei 2026',
      submittedAt: DateTime(2026, 5, 25),
      status: ProposalStatus.rejected,
      description: 'Ban bocor di jalan tol.',
    ),
    ProposalItem(
      id: 'h5',
      type: ProposalType.overtime,
      title: 'Lembur Akhir Pekan',
      date: '24 Mei 2026',
      submittedAt: DateTime(2026, 5, 23),
      status: ProposalStatus.approved,
      description: 'Penyelesaian bug critical payment gateway.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // 3 main tabs: Attendance, Time off, Overtime
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _attDescCtrl.dispose();
    _toDescCtrl.dispose();
    _otHoursCtrl.dispose();
    _otDescCtrl.dispose();
    super.dispose();
  }

  // ── Helper Pickers ──
  Future<void> _pickDate(Function(DateTime) onPicked) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => onPicked(date));
    }
  }

  Future<void> _pickTime(TimeOfDay? initial, Function(TimeOfDay) onPicked) async {
    final time = await showTimePicker(
      context: context,
      initialTime: initial ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() => onPicked(time));
    }
  }

  // ── Submission Handlers ──
  Future<void> _submitAttendance() async {
    if (!_attFormKey.currentState!.validate()) return;
    if (_attDate == null) {
      _showError('Pilih tanggal izin terlebih dahulu');
      return;
    }
    setState(() => _attLoading = true);
    try {
      final req = PermissionRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        permissionType: _attType,
        date: _attDate!,
        description: _attDescCtrl.text,
      );
      await RequestService.instance.submitPermissionRequest(req);
      _showSuccess('Pengajuan izin berhasil dikirim');
      setState(() {
        _attDate = null;
        _attDescCtrl.clear();
        _attFiles.clear();
        _attendanceSubTab = 1; // Switch to summary history tab
      });
    } catch (e) {
      _showError('Gagal mengirim: $e');
    } finally {
      setState(() => _attLoading = false);
    }
  }

  Future<void> _submitTimeOff() async {
    if (!_toFormKey.currentState!.validate()) return;
    if (_toDate == null) {
      _showError('Pilih tanggal cuti terlebih dahulu');
      return;
    }
    setState(() => _toLoading = true);
    try {
      final req = LeaveRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        leaveType: _toType,
        date: _toDate!,
        description: _toDescCtrl.text,
      );
      await RequestService.instance.submitLeaveRequest(req);
      _showSuccess('Pengajuan cuti berhasil dikirim');
      setState(() {
        _toDate = null;
        _toDescCtrl.clear();
        _toFiles.clear();
        _timeOffSubTab = 1; // Switch to summary history tab
      });
    } catch (e) {
      _showError('Gagal mengirim: $e');
    } finally {
      setState(() => _toLoading = false);
    }
  }

  Future<void> _submitOvertime() async {
    if (!_otFormKey.currentState!.validate()) return;
    if (_otDate == null) {
      _showError('Pilih tanggal lembur terlebih dahulu');
      return;
    }
    setState(() => _otLoading = true);
    try {
      final req = OvertimeRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: _otDate!,
        totalEarlyOvertime: _otHoursCtrl.text,
        earlyOvertimeStart: _otStart?.format(context) ?? '-',
        earlyOvertimeEnd: _otEnd?.format(context) ?? '-',
        totalLateOvertime: '0',
        lateOvertimeStart: '-',
        lateOvertimeEnd: '-',
        description: _otDescCtrl.text,
      );
      await RequestService.instance.submitOvertimeRequest(req);
      _showSuccess('Pengajuan lembur berhasil dikirim');
      setState(() {
        _otDate = null;
        _otStart = null;
        _otEnd = null;
        _otHoursCtrl.clear();
        _otDescCtrl.clear();
        _otFiles.clear();
        _overtimeSubTab = 1; // Switch to summary history tab
      });
    } catch (e) {
      _showError('Gagal mengirim: $e');
    } finally {
      setState(() => _otLoading = false);
    }
  }

  void _showError(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: AppColors.error),
    );
  }

  void _showSuccess(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Column(
        children: [
          // ── Header Premium (Charcoal & Gold Theme) ──
          Container(
            color: AppColors.primary,
            padding: EdgeInsets.fromLTRB(16, topPadding + 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Time Management',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Icon(Icons.more_horiz_rounded, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 20),
                TabBar(
                  controller: _tabCtrl,
                  indicatorColor: AppColors.accent,
                  indicatorWeight: 3,
                  labelColor: AppColors.accent,
                  unselectedLabelColor: Colors.white38,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  tabs: const [
                    Tab(text: 'Attendance'),
                    Tab(text: 'Time off'),
                    Tab(text: 'Overtime'),
                  ],
                ),
              ],
            ),
          ),

          // ── Content TabBarView ──
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                // Tab 1: Attendance (Permission)
                _buildTabContent(
                  subTabIndex: _attendanceSubTab,
                  requestLabel: 'Attendance Request',
                  summaryLabel: 'Attendance Summary',
                  onSubTabChanged: (idx) => setState(() => _attendanceSubTab = idx),
                  formChild: _buildAttendanceForm(),
                  historyChild: _buildHistoryList(ProposalType.permission),
                ),

                // Tab 2: Time off (Leave)
                _buildTabContent(
                  subTabIndex: _timeOffSubTab,
                  requestLabel: 'Time off Request',
                  summaryLabel: 'Time off Summary',
                  onSubTabChanged: (idx) => setState(() => _timeOffSubTab = idx),
                  formChild: _buildTimeOffForm(),
                  historyChild: _buildHistoryList(ProposalType.leave),
                ),

                // Tab 3: Overtime (Lembur)
                _buildTabContent(
                  subTabIndex: _overtimeSubTab,
                  requestLabel: 'Overtime Request',
                  summaryLabel: 'Overtime Summary',
                  onSubTabChanged: (idx) => setState(() => _overtimeSubTab = idx),
                  formChild: _buildOvertimeForm(),
                  historyChild: _buildHistoryList(ProposalType.overtime),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Sub-tab Switcher Frame Builder ──
  Widget _buildTabContent({
    required int subTabIndex,
    required String requestLabel,
    required String summaryLabel,
    required ValueChanged<int> onSubTabChanged,
    required Widget formChild,
    required Widget historyChild,
  }) {
    return Column(
      children: [
        // Sub-tabs Pill Container
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.scaffoldBg,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => onSubTabChanged(0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: subTabIndex == 0 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: subTabIndex == 0
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        requestLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: subTabIndex == 0 ? AppColors.grey900 : AppColors.grey500,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onSubTabChanged(1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: subTabIndex == 1 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: subTabIndex == 1
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        summaryLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: subTabIndex == 1 ? AppColors.grey900 : AppColors.grey500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Core View Body
        Expanded(
          child: subTabIndex == 0 ? formChild : historyChild,
        ),
      ],
    );
  }

  // ── Form Content Builders ──
  Widget _buildAttendanceForm() {
    return Form(
      key: _attFormKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Jenis Izin', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.grey800)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.grey200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _attType,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                items: _attTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type, style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _attType = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildDateField('Tanggal Izin', _attDate, (d) => _attDate = d),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Alasan Keperluan',
            controller: _attDescCtrl,
            hint: 'Tulis keperluan izin Anda...',
          ),
          const SizedBox(height: 16),
          const Text('Lampiran Dokumen', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.grey800)),
          const SizedBox(height: 8),
          FilePickerWidget(
            files: _attFiles,
            onPick: () async {
              final result = await FilePicker.platform.pickFiles(allowMultiple: true);
              if (result != null) setState(() => _attFiles.addAll(result.files));
            },
            onRemove: (i) => setState(() => _attFiles.removeAt(i)),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Kirim Pengajuan Izin',
            isLoading: _attLoading,
            onPressed: _submitAttendance,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeOffForm() {
    return Form(
      key: _toFormKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Jenis Cuti', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.grey800)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.grey200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _toType,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                items: _toTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type, style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _toType = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildDateField('Tanggal Mulai Cuti', _toDate, (d) => _toDate = d),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Keterangan Tambahan',
            controller: _toDescCtrl,
            hint: 'Tulis alasan cuti Anda...',
          ),
          const SizedBox(height: 16),
          const Text('Lampiran Pendukung', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.grey800)),
          const SizedBox(height: 8),
          FilePickerWidget(
            files: _toFiles,
            onPick: () async {
              final result = await FilePicker.platform.pickFiles(allowMultiple: true);
              if (result != null) setState(() => _toFiles.addAll(result.files));
            },
            onRemove: (i) => setState(() => _toFiles.removeAt(i)),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Kirim Pengajuan Cuti',
            isLoading: _toLoading,
            onPressed: _submitTimeOff,
          ),
        ],
      ),
    );
  }

  Widget _buildOvertimeForm() {
    return Form(
      key: _otFormKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDateField('Tanggal Lembur', _otDate, (d) => _otDate = d),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Jam Mulai', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.grey800)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _pickTime(_otStart, (t) => _otStart = t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.grey200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              _otStart == null ? 'Pilih Jam' : _otStart!.format(context),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.grey800),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Jam Selesai', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.grey800)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _pickTime(_otEnd, (t) => _otEnd = t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.grey200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              _otEnd == null ? 'Pilih Jam' : _otEnd!.format(context),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.grey800),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Estimasi Durasi (Jam)',
            controller: _otHoursCtrl,
            hint: 'Contoh: 3',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Rincian Pekerjaan Lembur',
            controller: _otDescCtrl,
            hint: 'Tulis deskripsi lembur...',
          ),
          const SizedBox(height: 16),
          const Text('Dokumen Pendukung', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.grey800)),
          const SizedBox(height: 8),
          FilePickerWidget(
            files: _otFiles,
            onPick: () async {
              final result = await FilePicker.platform.pickFiles(allowMultiple: true);
              if (result != null) setState(() => _otFiles.addAll(result.files));
            },
            onRemove: (i) => setState(() => _otFiles.removeAt(i)),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Kirim Pengajuan Lembur',
            isLoading: _otLoading,
            onPressed: _submitOvertime,
          ),
        ],
      ),
    );
  }

  // ── Date Field Selector Widget ──
  Widget _buildDateField(String label, DateTime? date, Function(DateTime) onPicked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.grey800)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickDate(onPicked),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 10),
                Text(
                  date == null ? 'Pilih Tanggal' : '${date.day}/${date.month}/${date.year}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.grey800),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Summary History List View (Berdasarkan Kategori) ──
  Widget _buildHistoryList(ProposalType type) {
    final filtered = _historyItems.where((i) => i.type == type).toList();

    return Column(
      children: [
        // Filter bar (Date picker & Search Input)
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              // Date picker simulator button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.grey600),
                    SizedBox(width: 6),
                    Text('Wed, 07 Aug', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.grey800)),
                    Icon(Icons.arrow_drop_down, size: 14, color: AppColors.grey600),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Search field
              Expanded(
                child: Container(
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.scaffoldBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      hintText: 'Search',
                      hintStyle: TextStyle(fontSize: 12, color: AppColors.grey400),
                      prefixIcon: Icon(Icons.search_rounded, size: 14, color: AppColors.grey400),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.tune_rounded, size: 14, color: AppColors.grey600),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyHistory()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, index) {
                    final item = filtered[index];
                    return _buildHistoryCard(item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(ProposalItem item) {
    Color typeColor;
    Color statusColor;
    String statusText;

    switch (item.type) {
      case ProposalType.overtime:   typeColor = AppColors.warning; break;
      case ProposalType.leave:      typeColor = AppColors.info; break;
      case ProposalType.permission: typeColor = AppColors.success; break;
    }

    switch (item.status) {
      case ProposalStatus.approved:
        statusColor = AppColors.success;
        statusText = 'Approved';
        break;
      case ProposalStatus.rejected:
        statusColor = AppColors.error;
        statusText = 'Rejected';
        break;
      case ProposalStatus.pending:
      default:
        statusColor = AppColors.warning;
        statusText = 'Pending';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Left border indicator color
              Container(width: 4, color: typeColor),
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProposalDetailScreen(item: item),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        // Circle initial avatar
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.primarySurface,
                          child: const Text('U', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ),
                        const SizedBox(width: 10),

                        // Title and date info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.grey800),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.date,
                                style: const TextStyle(fontSize: 11, color: AppColors.grey500),
                              ),
                            ],
                          ),
                        ),

                        // Status pill / duration & Chevron
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.grey400),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return const Center(
      child: Text(
        'Tidak ada riwayat pengajuan.',
        style: TextStyle(fontSize: 13, color: AppColors.grey400),
      ),
    );
  }
}
