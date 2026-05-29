import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../auth/data/auth_service.dart';
import '../domain/schedule_models.dart';

// ─────────────────────────────────────────
//  SCHEDULE SERVICE
//  Endpoint: GET /api/v1/work-calendar
// ─────────────────────────────────────────
class ScheduleService {
  ScheduleService._();
  static final instance = ScheduleService._();

  Future<List<HolidayRecord>> fetchWorkCalendar({int? year}) async {
    try {
      final token = await AuthService.instance.getToken();
      if (token == null) return [];

      final y = year ?? DateTime.now().year;
      final uri = Uri.parse(
        '${AuthService.instance.baseUrl}/work-calendar?year=$y',
      );

      print('[SCHEDULE] GET $uri');

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

      print('[SCHEDULE] status=${response.statusCode}');

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

        final records = rawList
            .map((e) => HolidayRecord.fromJson(e as Map<String, dynamic>))
            .where((r) => r.isActive)
            .toList();

        // Sort by date
        records.sort((a, b) => a.holidayDate.compareTo(b.holidayDate));
        return records;
      }

      print('[SCHEDULE] Error ${response.statusCode}: ${response.body}');
      return [];
    } catch (e) {
      print('[SCHEDULE] Exception: $e');
      return [];
    }
  }

  /// Filter holidays by month
  List<HolidayRecord> filterByMonth(
      List<HolidayRecord> all, int month, int year) {
    return all
        .where((r) =>
            r.holidayDate.month == month && r.holidayDate.year == year)
        .toList();
  }

  /// Get all dates that are holidays for a given list
  Set<DateTime> getHolidayDates(List<HolidayRecord> records) {
    return records
        .map((r) => DateTime(
              r.holidayDate.year,
              r.holidayDate.month,
              r.holidayDate.day,
            ))
        .toSet();
  }
}
