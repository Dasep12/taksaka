import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../auth/data/auth_service.dart';
import '../domain/home_models.dart';

class HomeService {
  HomeService._();
  static final instance = HomeService._();

  Future<AttendanceSchedule?> getTodaySchedule() async {
    try {
      final token = await AuthService.instance.getToken();
      if (token == null) return null;

      final url = Uri.parse('${AuthService.instance.baseUrl}/schedule-today');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null && (data['data'] as List).isNotEmpty) {
          final scheduleData = data['data'][0];
          
          final shiftName = scheduleData['shift_name'] ?? 'Unknown';
          final shiftTimeIn = scheduleData['shift_time_in'];
          final shiftTimeOut = scheduleData['shift_time_out'];
          final checkIn = scheduleData['check_in'];
          final checkOut = scheduleData['check_out'];
          final workDate = scheduleData['work_date'] ?? DateTime.now().toString().split(' ')[0];
          
          // Format times (assuming they come as HH:MM:SS or HH:MM)
          String formatTime(String? timeStr) {
            if (timeStr == null || timeStr.isEmpty) return '--:--';
            final parts = timeStr.split(':');
            if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
            return timeStr;
          }

          return AttendanceSchedule(
            shiftLabel: shiftName,
            date: workDate,
            startTime: formatTime(shiftTimeIn),
            endTime: formatTime(shiftTimeOut),
            isClockedIn: checkIn != null,
            isClockedOut: checkOut != null,
            checkInTime: checkIn,
            checkOutTime: checkOut,
          );
        }
      }
      return null;
    } catch (e) {
      print('Error fetching schedule: $e');
      return null;
    }
  }

  Future<List<Announcement>> getAnnouncements() async {
    try {
      final token = await AuthService.instance.getToken();
      if (token == null) return [];

      final url = Uri.parse('${AuthService.instance.baseUrl}/announcement');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> list = data['data'];
          return list.map((e) => Announcement.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching announcements: $e');
      return [];
    }
  }
}
