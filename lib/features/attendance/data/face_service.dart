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
      enableClassification: true,   // senyum, mata terbuka
      enableTracking: true,
      performanceMode: FaceDetectorMode.accurate,
      minFaceSize: 0.3,             // wajah minimal 30% lebar frame
    ),
  );

  // ── Camera helpers ────────────────────

  /// Daftar kamera yang tersedia (biasanya [back, front])
  Future<List<CameraDescription>> getAvailableCameras() =>
      availableCameras();

  /// Cari kamera depan
  Future<CameraDescription?> getFrontCamera() async {
    final cams = await availableCameras();
    try {
      return cams.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front);
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

    final rotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    if (rotation == null) return null;

    // Hanya support single plane (NV21 / BGRA8888)
    if (image.planes.isEmpty) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
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

    final w = imageSize.width;
    final h = imageSize.height;

    // Normalisasi posisi landmark ke [0,1]
    for (final type in landmarks) {
      final lm = face.landmarks[type];
      if (lm != null) {
        features.add(lm.position.x / w);
        features.add(lm.position.y / h);
      } else {
        features.add(0.0);
        features.add(0.0);
      }
    }

    // Tambah bounding box (4 nilai)
    final bb = face.boundingBox;
    features.add(bb.left / w);
    features.add(bb.top / h);
    features.add(bb.width / w);
    features.add(bb.height / h);

    // Tambah rotasi & klasifikasi (8 nilai)
    features.add((face.headEulerAngleX ?? 0) / 90);
    features.add((face.headEulerAngleY ?? 0) / 90);
    features.add((face.headEulerAngleZ ?? 0) / 90);
    features.add(face.smilingProbability ?? 0);
    features.add(face.leftEyeOpenProbability ?? 0);
    features.add(face.rightEyeOpenProbability ?? 0);
    features.add(0.0);
    features.add(0.0);

    // Pad atau potong ke 128 dim
    while (features.length < 128) features.add(0.0);
    return features.take(128).toList();
  }

  // ── Storage ───────────────────────────

  /// Simpan embedding wajah ke SharedPreferences
  Future<void> saveEmbedding(FaceEmbedding embedding) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadAllEmbeddings();

    // Hapus embedding lama untuk user yang sama, simpan yang baru
    final updated = existing
        .where((e) => e.userId != embedding.userId)
        .toList()
      ..add(embedding);

    final jsonList = updated.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_prefKey, jsonList);
  }

  /// Load semua embedding tersimpan
  Future<List<FaceEmbedding>> loadAllEmbeddings() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefKey) ?? [];
    return list.map((s) {
      try {
        return FaceEmbedding.fromJson(jsonDecode(s) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    }).whereType<FaceEmbedding>().toList();
  }

  /// Cek apakah user sudah registrasi wajah
  Future<bool> hasRegisteredFace(String userId) async {
    final all = await loadAllEmbeddings();
    return all.any((e) => e.userId == userId);
  }

  /// Hapus wajah terdaftar
  Future<void> clearFace(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadAllEmbeddings();
    final updated = existing.where((e) => e.userId != userId).toList();
    await prefs.setStringList(
      _prefKey,
      updated.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  // ── Verifikasi ────────────────────────

  /// Bandingkan embedding saat ini dengan embedding terdaftar.
  /// Return FaceVerifyResult dengan confidence score.
  Future<FaceVerifyResult> verifyAgainstStored({
    required String userId,
    required List<double> currentEmbedding,
  }) async {
    final stored = await loadAllEmbeddings();
    final userEmbeddings = stored.where((e) => e.userId == userId).toList();

    if (userEmbeddings.isEmpty) {
      return FaceVerifyResult.failure(
        'Wajah belum diregistrasi. Lakukan registrasi wajah terlebih dahulu.',
      );
    }

    // Ambil similarity tertinggi dari semua embedding tersimpan
    double best = 0;
    final current = FaceEmbedding(
      userId: userId,
      values: currentEmbedding,
      capturedAt: DateTime.now(),
    );

    for (final stored in userEmbeddings) {
      final sim = current.similarityTo(stored);
      if (sim > best) best = sim;
    }

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
