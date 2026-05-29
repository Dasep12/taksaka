// ─────────────────────────────────────────
//  ATTENDANCE HISTORY – DOMAIN MODELS
//  Sesuai response: GET /api/v1/history-attendance-monthly
// ─────────────────────────────────────────

enum AttendanceStatus { present, late, absent, leave, permission, holiday }

class AttendanceHistoryRecord {
  AttendanceHistoryRecord({
    required this.employeeId,
    required this.employeeName,
    required this.workDate,
    required this.shiftName,
    this.checkIn,
    this.checkOut,
    this.attendanceStatus,
  });

  final int employeeId;
  final String employeeName;
  final DateTime workDate;
  final String shiftName;     // "Off" | "Non Shift" | nama shift lain
  final String? checkIn;      // "20:24:15" atau null
  final String? checkOut;     // "20:26:36" atau null
  final String? attendanceStatus; // "LATE" | "ON_TIME" | "LEAVE" | null

  factory AttendanceHistoryRecord.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['work_date'] as String);
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return AttendanceHistoryRecord(
      employeeId: (json['employee_id'] as num?)?.toInt() ?? 0,
      employeeName: json['employee_name'] as String? ?? '',
      workDate: parsedDate,
      shiftName: json['shift_name'] as String? ?? '',
      checkIn: _sanitizeTime(json['check_in']),
      checkOut: _sanitizeTime(json['check_out']),
      attendanceStatus: json['attendance_status'] as String?,
    );
  }

  /// Resolve status dari data API
  AttendanceStatus get resolvedStatus {
    // Off shift → libur
    if (shiftName.toLowerCase() == 'off') return AttendanceStatus.holiday;

    final s = (attendanceStatus ?? '').toUpperCase();
    if (s == 'LATE') return AttendanceStatus.late;
    if (s == 'ON_TIME' || s == 'PRESENT') return AttendanceStatus.present;
    if (s == 'LEAVE' || s == 'CUTI') return AttendanceStatus.leave;
    if (s == 'PERMISSION' || s == 'IZIN') return AttendanceStatus.permission;

    // Ada check_in tapi status null → anggap hadir
    if (checkIn != null) return AttendanceStatus.present;

    // Workday tapi tidak ada data → tidak hadir
    return AttendanceStatus.absent;
  }

  String get statusLabel {
    switch (resolvedStatus) {
      case AttendanceStatus.present:    return 'Hadir';
      case AttendanceStatus.late:       return 'Terlambat';
      case AttendanceStatus.absent:     return 'Tidak Hadir';
      case AttendanceStatus.leave:      return 'Cuti';
      case AttendanceStatus.permission: return 'Izin';
      case AttendanceStatus.holiday:    return 'Libur';
    }
  }

  /// "Kamis, 29 Mei 2026"
  String get formattedDate {
    const days = ['Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu'];
    const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Ags','Sep','Okt','Nov','Des'];
    return '${days[workDate.weekday - 1]}, ${workDate.day} ${months[workDate.month - 1]} ${workDate.year}';
  }

  /// Nama hari singkat: "Sen"
  String get dayShort {
    const days = ['Sen','Sel','Rab','Kam','Jum','Sab','Min'];
    return days[workDate.weekday - 1];
  }

  /// Format "20:24" dari "20:24:15"
  String formatTime(String? t) {
    if (t == null) return '-';
    final parts = t.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return t;
  }

  String get timeInFormatted  => formatTime(checkIn);
  String get timeOutFormatted => formatTime(checkOut);

  /// Durasi kerja hh jam mm menit
  String get workDuration {
    if (checkIn == null || checkOut == null) return '-';
    try {
      final i = _toMinutes(checkIn!);
      final o = _toMinutes(checkOut!);
      final diff = o - i;
      if (diff <= 0) return '-';
      final h = diff ~/ 60;
      final m = diff % 60;
      return h > 0 ? '${h}j ${m}m' : '${m}m';
    } catch (_) {
      return '-';
    }
  }

  // ── helpers ──
  static int _toMinutes(String t) {
    final p = t.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }

  static String? _sanitizeTime(dynamic val) {
    if (val == null) return null;
    final s = val.toString().trim();
    if (s.isEmpty || s == 'null') return null;
    return s;
  }
}

/// Summary statistik untuk satu bulan
class AttendanceMonthlySummary {
  const AttendanceMonthlySummary({
    required this.month,
    required this.year,
    required this.totalPresent,
    required this.totalLate,
    required this.totalAbsent,
    required this.totalLeave,
    required this.totalHoliday,
    required this.totalWorkDays,
  });

  final int month;
  final int year;
  final int totalPresent;
  final int totalLate;
  final int totalAbsent;
  final int totalLeave;
  final int totalHoliday;
  final int totalWorkDays; // hari kerja (non-Off)

  double get attendanceRate {
    if (totalWorkDays == 0) return 0;
    return ((totalPresent + totalLate) / totalWorkDays * 100).clamp(0, 100);
  }

  String get monthLabel {
    const months = [
      'Januari','Februari','Maret','April','Mei','Juni',
      'Juli','Agustus','September','Oktober','November','Desember',
    ];
    return '${months[month - 1]} $year';
  }
}
