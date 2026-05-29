// ─────────────────────────────────────────
//  SCHEDULE / WORK CALENDAR – DOMAIN MODELS
//  Source: mst_holiday table
// ─────────────────────────────────────────

enum HolidayType { national, company, massLeave }

class HolidayRecord {
  const HolidayRecord({
    required this.holidayId,
    required this.holidayDate,
    required this.holidayName,
    required this.holidayType,
    this.isActive = true,
  });

  final int holidayId;
  final DateTime holidayDate;
  final String holidayName;
  final HolidayType holidayType;
  final bool isActive;

  factory HolidayRecord.fromJson(Map<String, dynamic> json) {
    DateTime date;
    try {
      date = DateTime.parse(json['holiday_date'] as String);
    } catch (_) {
      date = DateTime.now();
    }

    HolidayType type;
    switch ((json['holiday_type'] as String? ?? '').toUpperCase()) {
      case 'COMPANY':
        type = HolidayType.company;
        break;
      case 'MASS LEAVE':
        type = HolidayType.massLeave;
        break;
      default:
        type = HolidayType.national;
    }

    return HolidayRecord(
      holidayId: (json['holiday_id'] as num?)?.toInt() ?? 0,
      holidayDate: date,
      holidayName: json['holiday_name'] as String? ?? '',
      holidayType: type,
      isActive: (json['is_active'] as int? ?? 1) == 1,
    );
  }

  String get typeLabel {
    switch (holidayType) {
      case HolidayType.national:  return 'Nasional';
      case HolidayType.company:   return 'Perusahaan';
      case HolidayType.massLeave: return 'Cuti Bersama';
    }
  }

  /// "Kamis, 29 Mei 2026"
  String get formattedDate {
    const days = ['Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu'];
    const months = ['Januari','Februari','Maret','April','Mei','Juni',
        'Juli','Agustus','September','Oktober','November','Desember'];
    return '${days[holidayDate.weekday - 1]}, '
        '${holidayDate.day} ${months[holidayDate.month - 1]} ${holidayDate.year}';
  }

  String get shortDate {
    const months = ['Jan','Feb','Mar','Apr','Mei','Jun',
        'Jul','Ags','Sep','Okt','Nov','Des'];
    return '${holidayDate.day} ${months[holidayDate.month - 1]}';
  }
}
