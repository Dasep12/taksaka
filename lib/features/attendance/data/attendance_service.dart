import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../auth/data/auth_service.dart';
import '../domain/attendance_models.dart';
import 'location_service.dart';
import 'face_service.dart';

export 'location_service.dart';
export 'face_service.dart';

/// ─────────────────────────────────────────
///  ATTENDANCE SERVICE  –  koordinator utama
/// ─────────────────────────────────────────
class AttendanceService {
  AttendanceService._();
  static final instance = AttendanceService._();

  final location = LocationService.instance;
  final face = FaceService.instance;

  Future<List<OfficeLocation>> fetchAbsenceLocations() async {
    try {
      final token = await AuthService.instance.getToken();
      if (token == null) return [];

      final url = Uri.parse('${AuthService.instance.baseUrl}/location-absence');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true &&
            data['data'] != null &&
            (data['data'] as List).isNotEmpty) {
          final List<OfficeLocation> offices = (data['data'] as List).map((
            locData,
          ) {
            return OfficeLocation(
              name: locData['location'] ?? 'Kantor',
              address: locData['location'] ?? 'Lokasi Absensi',
              latitude: double.tryParse(locData['latitude'].toString()) ?? 0.0,
              longitude:
                  double.tryParse(
                    (locData['longitude'] ?? locData['langitude'] ?? 0.0)
                        .toString(),
                  ) ??
                  0.0,
              radiusMeters:
                  double.tryParse(locData['max_radius'].toString()) ?? 100.0,
            );
          }).toList();
          return offices;
        }
      }
      return [];
    } catch (e) {
      print('Error fetching location-absence: $e');
      return [];
    }
  }

  Future<AttendanceRecord> saveAttendance({
    required AttendanceType type,
    required UserLocation userLocation,
    required OfficeLocation office,
    required double faceConfidence,
  }) async {
    final token = await AuthService.instance.getToken();
    if (token == null) {
      throw Exception('Sesi telah berakhir, silakan login kembali.');
    }

    final now = DateTime.now();
    final workDate =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final datetimeStr =
        "$workDate ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

    final mode = type == AttendanceType.clockIn ? 'IN' : 'OUT';
    final timeIn = type == AttendanceType.clockIn ? datetimeStr : null;
    final timeOut = type == AttendanceType.clockOut ? datetimeStr : null;

    final url = Uri.parse('${AuthService.instance.baseUrl}/submit-absence');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'time_in': timeIn,
        'time_out': timeOut,
        'work_date': workDate,
        'type': mode,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body);
      if (json['success'] == true) {
        return AttendanceRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: type,
          timestamp: now,
          latitude: userLocation.latitude,
          longitude: userLocation.longitude,
          officeName: office.name,
          faceConfidence: faceConfidence,
        );
      } else {
        throw Exception(json['message'] ?? 'Gagal menyimpan absensi');
      }
    } else {
      String errorMessage =
          'Gagal absensi, status code: ${response.statusCode}';
      try {
        final json = jsonDecode(response.body);
        if (json['message'] != null) {
          errorMessage = json['message'];
        }
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }
}
