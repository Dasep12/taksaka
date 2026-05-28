/// ─────────────────────────────────────────
///  REQUEST MODELS
/// ─────────────────────────────────────────

enum RequestStatus { pending, approved, rejected }

class OvertimeRequest {
  final String id;
  final DateTime date;
  final String totalEarlyOvertime;
  final String earlyOvertimeStart;
  final String earlyOvertimeEnd;
  final String totalLateOvertime;
  final String lateOvertimeStart;
  final String lateOvertimeEnd;
  final String description;
  final String? attachmentPath;
  final RequestStatus status;

  OvertimeRequest({
    required this.id,
    required this.date,
    required this.totalEarlyOvertime,
    required this.earlyOvertimeStart,
    required this.earlyOvertimeEnd,
    required this.totalLateOvertime,
    required this.lateOvertimeStart,
    required this.lateOvertimeEnd,
    required this.description,
    this.attachmentPath,
    this.status = RequestStatus.pending,
  });
}

class LeaveRequest {
  final String id;
  final String leaveType;
  final DateTime date;
  final String description;
  final String? attachmentPath;
  final RequestStatus status;

  LeaveRequest({
    required this.id,
    required this.leaveType,
    required this.date,
    required this.description,
    this.attachmentPath,
    this.status = RequestStatus.pending,
  });
}

class PermissionRequest {
  final String id;
  final String permissionType;
  final DateTime date;
  final String description;
  final String? attachmentPath;
  final RequestStatus status;

  PermissionRequest({
    required this.id,
    required this.permissionType,
    required this.date,
    required this.description,
    this.attachmentPath,
    this.status = RequestStatus.pending,
  });
}
