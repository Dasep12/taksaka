import 'dart:math';

/// ─────────────────────────────────────────
///  ATTENDANCE – DOMAIN MODELS
/// ─────────────────────────────────────────

enum AttendanceType { clockIn, clockOut }

enum AttendanceStep { locationCheck, faceVerify, result }

enum LocationStatus { checking, inRange, outOfRange, error, permissionDenied }

enum FaceVerifyStatus { idle, scanning, verified, failed }

enum FaceRegisterStatus { idle, capturing, processing, done, failed }

// ── Office Location ───────────────────────
class OfficeLocation {
  const OfficeLocation({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 100.0,
  });

  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double radiusMeters;
}

// ── User Location ─────────────────────────
class UserLocation {
  const UserLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
  });

  final double latitude;
  final double longitude;
  final double accuracy;

  /// Haversine distance ke kantor (meter)
  double distanceTo(OfficeLocation office) {
    const r = 6371000.0;
    final lat1 = latitude * (pi / 180);
    final lat2 = office.latitude * (pi / 180);
    final dLat = (office.latitude - latitude) * (pi / 180);
    final dLon = (office.longitude - longitude) * (pi / 180);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }
}

// ── Face data (embedding vektor) ─────────
class FaceEmbedding {
  const FaceEmbedding({
    required this.userId,
    required this.values,
    required this.capturedAt,
  });

  final String userId;
  final List<double> values; // 128-dim embedding dari ML Kit
  final DateTime capturedAt;

  /// Cosine similarity: 1.0 = identik, < 0.5 = berbeda
  double similarityTo(FaceEmbedding other) {
    if (values.length != other.values.length) return 0;
    double dot = 0, normA = 0, normB = 0;
    for (int i = 0; i < values.length; i++) {
      dot += values[i] * other.values[i];
      normA += values[i] * values[i];
      normB += other.values[i] * other.values[i];
    }
    if (normA == 0 || normB == 0) return 0;
    return dot / (sqrt(normA) * sqrt(normB));
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'values': values,
    'capturedAt': capturedAt.toIso8601String(),
  };

  factory FaceEmbedding.fromJson(Map<String, dynamic> json) => FaceEmbedding(
    userId: json['userId'] as String,
    values: List<double>.from(json['values'] as List),
    capturedAt: DateTime.parse(json['capturedAt'] as String),
  );
}

// ── Attendance Record ─────────────────────
class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.officeName,
    this.faceConfidence,
    this.note,
  });

  final String id;
  final AttendanceType type;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String officeName;
  final double? faceConfidence;
  final String? note;

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get formattedDate {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${timestamp.day} ${months[timestamp.month - 1]} ${timestamp.year}';
  }
}

// ── Face Verify Result ─────────────────────
class FaceVerifyResult {
  const FaceVerifyResult({
    required this.success,
    this.confidence,
    this.errorMessage,
  });

  final bool success;
  final double? confidence;
  final String? errorMessage;

  factory FaceVerifyResult.success({required double confidence}) =>
      FaceVerifyResult(success: true, confidence: confidence);

  factory FaceVerifyResult.failure(String msg) =>
      FaceVerifyResult(success: false, errorMessage: msg);
}

// ── Office config ─────────────────────────
class AttendanceMockData {
  /// ⚠️  Ganti koordinat ini dengan lokasi kantor sungguhan
  static const OfficeLocation mainOffice = OfficeLocation(
    name: 'Kantor Pusat',
    address: 'Jl. Jend. Sudirman No.1, Jakarta Pusat',
    latitude: -6.2572863,
    longitude: 107.0831963,
    radiusMeters: 200,
  );

  static const List<OfficeLocation> allOffices = [mainOffice];
}
