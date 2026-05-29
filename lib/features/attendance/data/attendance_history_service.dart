import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../auth/data/auth_service.dart';
import '../domain/attendance_history_models.dart';

/// ─────────────────────────────────────────
///  ATTENDANCE HISTORY SERVICE
///  Endpoint: GET /api/v1/history-attendance-monthly?month=MM&year=YYYY
/// ─────────────────────────────────────────
class AttendanceHistoryService {
  AttendanceHistoryService._();
  static final instance = AttendanceHistoryService._();

  Future<List<AttendanceHistoryRecord>> fetchHistory({
    required int month,
    required int year,
  }) async {
    try {
      final token = await AuthService.instance.getToken();
      if (token == null) return [];

      final uri = Uri.parse(
        '${AuthService.instance.baseUrl}/history-attendance-monthly'
        '?month=$month&year=$year',
      );

      print('[HISTORY] GET $uri');

      final response = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('Request timeout'),
          );

      print('[HISTORY] status=${response.statusCode}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        List<dynamic> rawList = [];
        if (body is Map) {
          if (body['data'] is List) {
            rawList = body['data'] as List;
          } else if (body['data'] is Map && body['data']['data'] is List) {
            rawList = body['data']['data'] as List;
          }
        } else if (body is List) {
          rawList = body;
        }

        return rawList
            .map((e) => AttendanceHistoryRecord.fromJson(
                  e as Map<String, dynamic>,
                ))
            .toList();
      }

      print('[HISTORY] Error status ${response.statusCode}: ${response.body}');
      return [];
    } catch (e) {
      print('[HISTORY] Exception: $e');
      return [];
    }
  }

  /// Hitung summary dari daftar records
  AttendanceMonthlySummary buildSummary(
    List<AttendanceHistoryRecord> records,
    int month,
    int year,
  ) {
    int present = 0, late = 0, absent = 0, leave = 0, holiday = 0;

    for (final r in records) {
      switch (r.resolvedStatus) {
        case AttendanceStatus.present:
          present++;
          break;
        case AttendanceStatus.late:
          late++;
          break;
        case AttendanceStatus.absent:
          absent++;
          break;
        case AttendanceStatus.leave:
        case AttendanceStatus.permission:
          leave++;
          break;
        case AttendanceStatus.holiday:
          holiday++;
          break;
      }
    }

    // Hari kerja = total records – hari libur (Off)
    final totalWorkDays = records.length - holiday;

    return AttendanceMonthlySummary(
      month: month,
      year: year,
      totalPresent: present,
      totalLate: late,
      totalAbsent: absent,
      totalLeave: leave,
      totalHoliday: holiday,
      totalWorkDays: totalWorkDays,
    );
  }
}
