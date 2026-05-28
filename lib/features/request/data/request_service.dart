import 'dart:async';
import '../domain/request_models.dart';

/// ─────────────────────────────────────────
///  REQUEST SERVICE (Mock Implementation)
/// ─────────────────────────────────────────
class RequestService {
  RequestService._();
  static final instance = RequestService._();

  Future<void> submitOvertimeRequest(OvertimeRequest request) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    // Here you would typically send the data via HTTP POST
    print('Overtime request submitted: ${request.id}');
  }

  Future<void> submitLeaveRequest(LeaveRequest request) async {
    await Future.delayed(const Duration(seconds: 1));
    print('Leave request submitted: ${request.id}');
  }

  Future<void> submitPermissionRequest(PermissionRequest request) async {
    await Future.delayed(const Duration(seconds: 1));
    print('Permission request submitted: ${request.id}');
  }
}
