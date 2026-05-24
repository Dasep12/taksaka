import 'package:geolocator/geolocator.dart';
import '../domain/attendance_models.dart';

/// ─────────────────────────────────────────
///  LOCATION SERVICE  –  GPS Sungguhan
///  menggunakan package: geolocator
/// ─────────────────────────────────────────
class LocationService {
  LocationService._();
  static final instance = LocationService._();

  /// Minta permission dan ambil posisi user sekarang
  Future<UserLocation> getCurrentLocation() async {
    // 1. Cek apakah GPS service aktif
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(
        'GPS tidak aktif. Aktifkan lokasi pada pengaturan perangkat.',
        LocationExceptionType.serviceDisabled,
      );
    }

    // 2. Cek / minta permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationException(
          'Izin lokasi ditolak. Berikan izin lokasi untuk melanjutkan.',
          LocationExceptionType.permissionDenied,
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Buka app settings agar user bisa enable manual
      await Geolocator.openAppSettings();
      throw const LocationException(
        'Izin lokasi ditolak permanen. Aktifkan di Pengaturan → Aplikasi → HRMS.',
        LocationExceptionType.permissionPermanentlyDenied,
      );
    }

    // 3. Ambil posisi dengan akurasi tinggi
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );

    return UserLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
    );
  }

  /// Stream lokasi untuk update real-time di peta
  Stream<UserLocation> locationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // update setiap 5 meter
      ),
    ).map((p) => UserLocation(
          latitude: p.latitude,
          longitude: p.longitude,
          accuracy: p.accuracy,
        ));
  }

  bool isInRange(UserLocation user, OfficeLocation office) =>
      user.distanceTo(office) <= office.radiusMeters;

  double getDistance(UserLocation user, OfficeLocation office) =>
      user.distanceTo(office);
}

// ── Exception ─────────────────────────────
enum LocationExceptionType {
  serviceDisabled,
  permissionDenied,
  permissionPermanentlyDenied,
  timeout,
  unknown,
}

class LocationException implements Exception {
  const LocationException(this.message, this.type);
  final String message;
  final LocationExceptionType type;

  @override
  String toString() => message;
}
