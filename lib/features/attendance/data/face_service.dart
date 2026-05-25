import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../domain/attendance_models.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../auth/data/auth_service.dart';

/// ─────────────────────────────────────────
///  FACE SERVICE
///  - Deteksi wajah pakai ML Kit
///  - Simpan / load embedding ke SharedPreferences
///  - Verifikasi wajah saat absensi
/// ─────────────────────────────────────────
class FaceService {
  FaceService._();
  static final instance = FaceService._();

  static const _prefKey = 'hrms_face_embedding';

  // Threshold similarity: >= 0.75 = match
  static const double matchThreshold = 0.75;

  late final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true, // senyum, mata terbuka
      enableTracking: true,
      performanceMode: FaceDetectorMode.accurate,
      minFaceSize: 0.3, // wajah minimal 30% lebar frame
    ),
  );

  // ── Camera helpers ────────────────────

  /// Daftar kamera yang tersedia (biasanya [back, front])
  Future<List<CameraDescription>> getAvailableCameras() => availableCameras();

  /// Cari kamera depan
  Future<CameraDescription?> getFrontCamera() async {
    final cams = await availableCameras();
    try {
      return cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
    } catch (_) {
      return cams.isNotEmpty ? cams.first : null;
    }
  }

  // ── Deteksi wajah dari CameraImage ────

  /// Konversi CameraImage (YUV/BGRA) ke InputImage untuk ML Kit
  InputImage? cameraImageToInputImage(
    CameraImage image,
    CameraDescription camera,
  ) {
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final rotation = InputImageRotationValue.fromRawValue(
      camera.sensorOrientation,
    );
    if (rotation == null) return null;

    if (image.planes.isEmpty) return null;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  /// Deteksi wajah dari InputImage, return list Face
  Future<List<Face>> detectFaces(InputImage inputImage) =>
      _detector.processImage(inputImage);

  // ── Embedding ─────────────────────────

  /// Hasilkan embedding dari Face yang terdeteksi.
  /// ML Kit tidak ekspos embedding vektor langsung, jadi kita gunakan
  /// landmark + kontur wajah sebagai feature vector 128-dim.
  List<double> extractEmbedding(Face face, Size imageSize) {
    final features = <double>[];

    final landmarks = [
      FaceLandmarkType.leftEye,
      FaceLandmarkType.rightEye,
      FaceLandmarkType.noseBase,
      FaceLandmarkType.leftMouth,
      FaceLandmarkType.rightMouth,
      FaceLandmarkType.leftEar,
      FaceLandmarkType.rightEar,
      FaceLandmarkType.leftCheek,
      FaceLandmarkType.rightCheek,
      FaceLandmarkType.bottomMouth,
    ];

    final bb = face.boundingBox;

    // Normalisasi posisi landmark relatif terhadap bounding box wajah
    for (final type in landmarks) {
      final lm = face.landmarks[type];
      if (lm != null) {
        features.add((lm.position.x - bb.left) / bb.width);
        features.add((lm.position.y - bb.top) / bb.height);
      } else {
        features.add(0.5);
        features.add(0.5);
      }
    }

    // Tambah aspek rasio bounding box (posisi absolut dihapus agar pos-invariant)
    features.add(bb.width / bb.height);
    features.add(0.0);
    features.add(0.0);
    features.add(0.0);

    // Tambah rotasi & klasifikasi (bobot dikurangi agar lebih toleran)
    features.add(((face.headEulerAngleX ?? 0) / 90) * 0.5);
    features.add(((face.headEulerAngleY ?? 0) / 90) * 0.5);
    features.add(((face.headEulerAngleZ ?? 0) / 90) * 0.5);
    features.add((face.smilingProbability ?? 0) * 0.2);
    features.add((face.leftEyeOpenProbability ?? 0) * 0.2);
    features.add((face.rightEyeOpenProbability ?? 0) * 0.2);
    features.add(0.0);
    features.add(0.0);

    // Pad atau potong ke 128 dim
    while (features.length < 128) {
      features.add(0.0);
    }
    return features.take(128).toList();
  }

  // ── Storage ───────────────────────────

  // ── Storage ───────────────────────────

  /// Simpan embedding wajah ke Backend (API)
  Future<void> saveEmbedding(FaceEmbedding embedding) async {
    final token = await AuthService.instance.getToken();
    if (token == null) throw Exception('No token found');

    final url = Uri.parse('${AuthService.instance.baseUrl}/faceEmbeding');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'embedding': embedding.values,
        'photo_path': null, // Tambahkan logic upload foto jika ada
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to save embedding to server');
    }
  }

  /// Load embedding tersimpan dari Backend untuk user tertentu
  Future<FaceEmbedding?> loadUserEmbedding(String userId) async {
    final token = await AuthService.instance.getToken();
    if (token == null) return null;

    final url = Uri.parse('${AuthService.instance.baseUrl}/get-faceEmbeding');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        // Data dari Laravel bisa berupa array objek atau single objek
        final list = data['data'] is List
            ? data['data'] as List
            : [data['data']];
        if (list.isNotEmpty) {
          final first = list.first;
          // Format respons: employee_id, embedding, photo_path, dll
          // Embedding dari JSON bisa berupa string JSON atau List, tergantung dari respon backend
          List<double> values = [];
          if (first['embedding'] is String) {
            final decoded = jsonDecode(first['embedding']);
            values = (decoded as List)
                .map((e) => double.parse(e.toString()))
                .toList();
          } else if (first['embedding'] is List) {
            values = (first['embedding'] as List)
                .map((e) => double.parse(e.toString()))
                .toList();
          }

          if (values.isNotEmpty) {
            return FaceEmbedding(
              userId: first['employee_id'].toString(),
              values: values,
              capturedAt: first['created_at'] != null
                  ? DateTime.tryParse(first['created_at']) ?? DateTime.now()
                  : DateTime.now(),
            );
          }
        }
      }
    }
    return null;
  }

  /// Cek apakah user sudah registrasi wajah
  Future<bool> hasRegisteredFace(String userId) async {
    try {
      final embedding = await loadUserEmbedding(userId);
      return embedding != null;
    } catch (_) {
      return false;
    }
  }

  /// Hapus wajah terdaftar (Belum didukung oleh endpoint, bisa ditambahkan delete /faceEmbeding)
  Future<void> clearFace(String userId) async {
    // Implementasi delete ke server jika diperlukan
  }

  // ── Verifikasi ────────────────────────

  /// Bandingkan embedding saat ini dengan embedding terdaftar.
  /// Return FaceVerifyResult dengan confidence score.
  Future<FaceVerifyResult> verifyAgainstStored({
    required String userId,
    required List<double> currentEmbedding,
  }) async {
    final storedEmbedding = await loadUserEmbedding(userId);

    if (storedEmbedding == null) {
      return FaceVerifyResult.failure(
        'Wajah belum diregistrasi. Lakukan registrasi wajah terlebih dahulu.',
      );
    }

    // Ambil similarity dari embedding tersimpan
    final current = FaceEmbedding(
      userId: userId,
      values: currentEmbedding,
      capturedAt: DateTime.now(),
    );

    final sim = current.similarityTo(storedEmbedding);
    final best = sim;

    if (best >= matchThreshold) {
      return FaceVerifyResult.success(confidence: best);
    } else {
      return FaceVerifyResult.failure(
        'Wajah tidak cocok (similarity: ${(best * 100).toStringAsFixed(0)}%). '
        'Pastikan pencahayaan cukup dan wajah terlihat jelas.',
      );
    }
  }

  void dispose() {
    _detector.close();
  }
}

// ── Size helper ───────────────────────────
// class Size {
//   const Size(this.width, this.height);
//   final double width;
//   final double height;
// }
