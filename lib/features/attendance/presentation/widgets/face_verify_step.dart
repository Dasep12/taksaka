import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/attendance_models.dart';
import '../../data/face_service.dart';

/// ─────────────────────────────────────────
///  STEP 2 – FACE VERIFY (kamera + ML Kit nyata)
/// ─────────────────────────────────────────
class FaceVerifyStep extends StatefulWidget {
  const FaceVerifyStep({
    super.key,
    required this.attendanceType,
    required this.userId,
    required this.onVerified,
    required this.onFailed,
  });

  final AttendanceType attendanceType;
  final String userId;
  final void Function(FaceVerifyResult result) onVerified;
  final void Function(String reason) onFailed;

  @override
  State<FaceVerifyStep> createState() => _FaceVerifyStepState();
}

class _FaceVerifyStepState extends State<FaceVerifyStep>
    with TickerProviderStateMixin {
  CameraController? _cameraCtrl;
  bool _cameraReady = false;
  String? _cameraError;

  FaceVerifyStatus _status = FaceVerifyStatus.idle;
  FaceVerifyResult? _result;
  Face? _detectedFace;
  bool _isProcessingFrame = false;
  Timer? _frameTimer;

  // Animations
  late AnimationController _scanCtrl;
  late Animation<double> _scanLine;
  late AnimationController _resultCtrl;
  late Animation<double> _resultScale;

  @override
  void initState() {
    super.initState();

    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _scanLine = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut));

    _resultCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _resultScale = CurvedAnimation(
      parent: _resultCtrl,
      curve: Curves.elasticOut,
    );

    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cam = await FaceService.instance.getFrontCamera();
      if (cam == null) {
        throw Exception('Kamera depan tidak ditemukan');
      }

      final ctrl = CameraController(
        cam,
        ResolutionPreset.medium,
        enableAudio: false,

        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await ctrl.initialize();

      // 🔥 tambahan penting
      await ctrl.lockCaptureOrientation();

      if (!mounted) {
        await ctrl.dispose();
        return;
      }

      setState(() {
        _cameraCtrl = ctrl;
        _cameraReady = true;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraError = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _frameTimer?.cancel();

    _scanCtrl.dispose();
    _resultCtrl.dispose();

    if (_cameraCtrl?.value.isStreamingImages == true) {
      _cameraCtrl?.stopImageStream().catchError((_) {});
    }
    _cameraCtrl?.dispose();

    super.dispose();
  }

  // ── Capture ───────────────────────────

  Future<void> _startScan() async {
    if (!_cameraReady || _cameraCtrl == null) return;
    setState(() {
      _status = FaceVerifyStatus.scanning;
      _detectedFace = null;
    });
    _scanCtrl.repeat(reverse: true);

    // Start image stream for live face detection
    if (!_cameraCtrl!.value.isStreamingImages) {
      try {
        await _cameraCtrl!.startImageStream(_onCameraFrame);
      } catch (e) {
        debugPrint('Error startImageStream: $e');
      }
    }

    // Auto-timeout after 10s
    _frameTimer = Timer(const Duration(seconds: 10), () {
      if (_status == FaceVerifyStatus.scanning) _onScanTimeout();
    });
  }

  void _onScanTimeout() {
    if (_cameraCtrl?.value.isStreamingImages == true) {
      _cameraCtrl?.stopImageStream().catchError((_) {});
    }
    _frameTimer?.cancel();
    _scanCtrl.stop();
    _handleFailed(
      'Wajah tidak terdeteksi dalam 10 detik. Pastikan wajah terlihat jelas dan pencahayaan cukup.',
    );
  }

  Future<void> _onCameraFrame(CameraImage image) async {
    if (_isProcessingFrame || _status != FaceVerifyStatus.scanning) {
      return;
    }

    _isProcessingFrame = true;

    try {
      final cam = await FaceService.instance.getFrontCamera();

      if (cam == null) {
        _isProcessingFrame = false;
        return;
      }

      final inputImage = FaceService.instance.cameraImageToInputImage(
        image,
        cam,
      );

      if (inputImage == null) {
        _isProcessingFrame = false;
        return;
      }

      final faces = await FaceService.instance.detectFaces(inputImage);

      if (!mounted) {
        _isProcessingFrame = false;
        return;
      }

      if (faces.isEmpty) {
        setState(() {
          _detectedFace = null;
        });

        _isProcessingFrame = false;
        return;
      }

      // 🔥 ambil wajah terbesar
      final face = faces.reduce(
        (a, b) => a.boundingBox.width > b.boundingBox.width ? a : b,
      );

      setState(() {
        _detectedFace = face;
      });

      // 🔥 VALIDASI WAJAH
      final yaw = (face.headEulerAngleY ?? 0).abs();
      final pitch = (face.headEulerAngleX ?? 0).abs();

      // wajah terlalu miring (dilonggarkan dari 20 ke 35 derajat)
      if (yaw > 35 || pitch > 35) {
        _isProcessingFrame = false;
        return;
      }

      // mata tertutup (hanya validasi jika nilainya tersedia dari ML Kit)
      if (face.leftEyeOpenProbability != null && face.leftEyeOpenProbability! < 0.3) {
        _isProcessingFrame = false;
        return;
      }
      if (face.rightEyeOpenProbability != null && face.rightEyeOpenProbability! < 0.3) {
        _isProcessingFrame = false;
        return;
      }

      // 🔥 STOP STREAM
      _frameTimer?.cancel();

      if (_cameraCtrl?.value.isStreamingImages == true) {
        await _cameraCtrl?.stopImageStream();
      }

      _scanCtrl.stop();

      // 🔥 EXTRACT EMBEDDING
      final embedding = FaceService.instance.extractEmbedding(
        face,
        Size(image.width.toDouble(), image.height.toDouble()),
      );

      // 🔥 VERIFY
      final result = await FaceService.instance.verifyAgainstStored(
        userId: widget.userId,
        currentEmbedding: embedding,
      );

      if (!mounted) return;

      if (result.success) {
        setState(() {
          _status = FaceVerifyStatus.verified;
          _result = result;
        });

        _resultCtrl.forward();

        await Future.delayed(const Duration(milliseconds: 1400));

        if (mounted) {
          widget.onVerified(result);
        }
      } else {
        _handleFailed(result.errorMessage ?? 'Verifikasi gagal');
      }
    } catch (e) {
      _handleFailed('Error: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  void _handleFailed(String reason) {
    if (!mounted) return;
    setState(() {
      _status = FaceVerifyStatus.failed;
      _result = FaceVerifyResult.failure(reason);
    });
    _resultCtrl.forward();
  }

  void _retry() {
    _resultCtrl.reset();
    _frameTimer?.cancel();
    setState(() {
      _status = FaceVerifyStatus.idle;
      _result = null;
      _detectedFace = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Camera View ─────────────────────
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: _cameraError != null
                ? _CameraErrorView(error: _cameraError!)
                : !_cameraReady
                ? const _CameraLoadingView()
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      // Live camera feed
                      FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: 100,
                          height: 100 * _cameraCtrl!.value.aspectRatio,
                          child: CameraPreview(_cameraCtrl!),
                        ),
                      ),

                      // Oval overlay
                      CustomPaint(
                        painter: _FaceOvalOverlayPainter(
                          hasFace: _detectedFace != null,
                          status: _status,
                        ),
                      ),

                      // Scan line (during scanning)
                      if (_status == FaceVerifyStatus.scanning)
                        AnimatedBuilder(
                          animation: _scanLine,
                          builder: (_, __) {
                            final h = MediaQuery.of(context).size.height * 0.35;
                            final top = h * 0.1 + _scanLine.value * h * 0.7;
                            return Positioned(
                              top: top,
                              left: MediaQuery.of(context).size.width * 0.15,
                              right: MediaQuery.of(context).size.width * 0.15,
                              child: Container(
                                height: 2.5,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      AppColors.accent.withOpacity(0.9),
                                      AppColors.accent,
                                      AppColors.accent.withOpacity(0.9),
                                      Colors.transparent,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.accent.withOpacity(0.6),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                      // Face bounding box guide
                      if (_detectedFace != null &&
                          _status == FaceVerifyStatus.scanning)
                        _FaceGuideBox(
                          face: _detectedFace!,
                          previewSize: _cameraCtrl!.value.previewSize!,
                        ),

                      // Result overlay
                      if (_status == FaceVerifyStatus.verified ||
                          _status == FaceVerifyStatus.failed)
                        Container(
                          color: Colors.black54,
                          child: Center(
                            child: ScaleTransition(
                              scale: _resultScale,
                              child: _ResultBadge(
                                success: _status == FaceVerifyStatus.verified,
                                confidence: _result?.confidence,
                              ),
                            ),
                          ),
                        ),

                      // Top status bar
                      Positioned(
                        top: 14,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: _CameraStatusBadge(
                            status: _status,
                            hasFace: _detectedFace != null,
                          ),
                        ),
                      ),

                      // Face quality hints
                      if (_status == FaceVerifyStatus.scanning)
                        const Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: _FaceHints(),
                        ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // ── Control panel ───────────────────
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: switch (_status) {
            FaceVerifyStatus.idle => _IdlePanel(
              key: const ValueKey('idle'),
              typeLabel: widget.attendanceType == AttendanceType.clockIn
                  ? 'Clock In'
                  : 'Clock Out',
              cameraReady: _cameraReady,
              onScan: _startScan,
            ),
            FaceVerifyStatus.scanning => _ScanningPanel(
              key: const ValueKey('scan'),
              hasFace: _detectedFace != null,
            ),
            FaceVerifyStatus.verified => _VerifiedPanel(
              key: const ValueKey('ok'),
              confidence: _result?.confidence ?? 0,
            ),
            FaceVerifyStatus.failed => _FailedPanel(
              key: const ValueKey('fail'),
              reason: _result?.errorMessage ?? 'Gagal',
              onRetry: _retry,
            ),
          },
        ),
      ],
    );
  }
}

// ── Oval frame painter ────────────────────
class _FaceOvalOverlayPainter extends CustomPainter {
  _FaceOvalOverlayPainter({required this.hasFace, required this.status});
  final bool hasFace;
  final FaceVerifyStatus status;

  @override
  void paint(ui.Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rw = size.width * 0.38;
    final rh = size.height * 0.38;
    final oval = Rect.fromCenter(
      center: Offset(cx, cy),
      width: rw * 2,
      height: rh * 2,
    );

    // Dark mask outside oval
    final bgPaint = Paint()..color = Colors.black.withOpacity(0.45);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(oval)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, bgPaint);

    // Oval border
    final borderColor = switch (status) {
      FaceVerifyStatus.verified => AppColors.success,
      FaceVerifyStatus.failed => AppColors.error,
      FaceVerifyStatus.scanning => hasFace ? AppColors.accent : Colors.white54,
      _ => Colors.white38,
    };

    canvas.drawOval(
      oval,
      Paint()
        ..color = borderColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _FaceOvalOverlayPainter old) =>
      old.hasFace != hasFace || old.status != status;
}

// ── Face guide box ────────────────────────
class _FaceGuideBox extends StatelessWidget {
  const _FaceGuideBox({required this.face, required this.previewSize});
  final Face face;
  final Size previewSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final scaleX = constraints.maxWidth / previewSize.width;
        final scaleY = constraints.maxHeight / previewSize.height;
        final bb = face.boundingBox;
        final left = bb.left * scaleX;
        final top = bb.top * scaleY;
        final width = bb.width * scaleX;
        final height = bb.height * scaleY;

        return Positioned(
          left: left,
          top: top,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.accent.withOpacity(0.7),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      },
    );
  }
}

// ── Camera status badge ───────────────────
class _CameraStatusBadge extends StatelessWidget {
  const _CameraStatusBadge({required this.status, required this.hasFace});
  final FaceVerifyStatus status;
  final bool hasFace;

  @override
  Widget build(BuildContext context) {
    final (label, dotColor) = switch (status) {
      FaceVerifyStatus.scanning when hasFace => (
        'WAJAH TERDETEKSI',
        AppColors.accent,
      ),
      FaceVerifyStatus.scanning => ('MENCARI WAJAH...', AppColors.warning),
      FaceVerifyStatus.verified => ('TERVERIFIKASI', AppColors.success),
      FaceVerifyStatus.failed => ('GAGAL', AppColors.error),
      _ => ('KAMERA AKTIF', Colors.white54),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _FaceHints extends StatelessWidget {
  const _FaceHints();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Hint(icon: Icons.wb_sunny_outlined, label: 'Cahaya cukup'),
          _Hint(icon: Icons.face_outlined, label: 'Wajah lurus'),
          _Hint(icon: Icons.remove_red_eye_outlined, label: 'Mata terbuka'),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.white70),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white70),
        ),
      ],
    );
  }
}

class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.success, this.confidence});
  final bool success;
  final double? confidence;
  @override
  Widget build(BuildContext context) {
    final color = success ? AppColors.success : AppColors.error;
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black87,
        border: Border.all(color: color, width: 3),
        boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 24)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            success ? Icons.check_rounded : Icons.close_rounded,
            color: color,
            size: 44,
          ),
          if (success && confidence != null)
            Text(
              '${(confidence! * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }
}

class _CameraLoadingView extends StatelessWidget {
  const _CameraLoadingView();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.accent),
            SizedBox(height: 12),
            Text(
              'Membuka kamera...',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraErrorView extends StatelessWidget {
  const _CameraErrorView({required this.error});
  final String error;
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              color: Colors.white38,
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              'Kamera tidak tersedia',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom panels ─────────────────────────

class _IdlePanel extends StatelessWidget {
  const _IdlePanel({
    super.key,
    required this.typeLabel,
    required this.cameraReady,
    required this.onScan,
  });
  final String typeLabel;
  final bool cameraReady;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.face_retouching_natural,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verifikasi Wajah',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'Posisikan wajah di dalam oval, lalu tekan Scan',
                      style: TextStyle(fontSize: 12, color: AppColors.grey600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: cameraReady ? onScan : null,
              icon: const Icon(Icons.camera_alt_rounded, size: 20),
              label: Text(
                'Scan Wajah untuk $typeLabel',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanningPanel extends StatelessWidget {
  const _ScanningPanel({super.key, required this.hasFace});
  final bool hasFace;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: hasFace
            ? AppColors.accent.withOpacity(0.08)
            : AppColors.primarySurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasFace
              ? AppColors.accent.withOpacity(0.3)
              : AppColors.primary.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: hasFace ? AppColors.accent : AppColors.primary,
              backgroundColor: (hasFace ? AppColors.accent : AppColors.primary)
                  .withOpacity(0.2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasFace
                      ? 'Wajah terdeteksi — memverifikasi...'
                      : 'Mendeteksi wajah...',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey900,
                  ),
                ),
                Text(
                  hasFace
                      ? 'Tetap diam sejenak'
                      : 'Hadapkan wajah Anda ke kamera',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifiedPanel extends StatelessWidget {
  const _VerifiedPanel({super.key, required this.confidence});
  final double confidence;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: AppColors.success,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Wajah Terverifikasi ✅',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
                Text(
                  'Kecocokan ${(confidence * 100).toStringAsFixed(1)}% — Menyimpan absensi...',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _FailedPanel extends StatelessWidget {
  const _FailedPanel({super.key, required this.reason, required this.onRetry});
  final String reason;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.error.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.face_retouching_off,
                  color: AppColors.error,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Verifikasi Gagal',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                      ),
                    ),
                    Text(
                      reason,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.grey600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Coba Lagi'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
