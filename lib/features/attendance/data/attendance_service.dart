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

  Future<AttendanceRecord> saveAttendance({
    required AttendanceType type,
    required UserLocation userLocation,
    required OfficeLocation office,
    required double faceConfidence,
  }) async {
    // Ganti dengan API call ke backend
    await Future.delayed(const Duration(milliseconds: 400));
    return AttendanceRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      timestamp: DateTime.now(),
      latitude: userLocation.latitude,
      longitude: userLocation.longitude,
      officeName: office.name,
      faceConfidence: faceConfidence,
    );
  }
}
