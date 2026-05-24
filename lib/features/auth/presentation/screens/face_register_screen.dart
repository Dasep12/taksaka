import 'dart:async';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../attendance/data/face_service.dart';
import '../../../attendance/domain/attendance_models.dart';

/// ─────────────────────────────────────────
///  FACE REGISTER SCREEN
///  Ambil 3 foto wajah dari berbagai sudut,
///  simpan embedding ke SharedPreferences
/// ─────────────────────────────────────────
class FaceRegisterScreen extends StatefulWidget {
  const FaceRegisterScreen({super.key, required this.userId, required this.userName});
  final String userId;
  final String userName;

  @override
  State<FaceRegisterScreen> createState() => _FaceRegisterScreenState();
}

class _FaceRegisterScreenState extends State<FaceRegisterScreen>
    with TickerProviderStateMixin {
  CameraController? _cam;
  bool _camReady = false;
  String? _camError;

  // 3 captures required: frontal, slight-left, slight-right
  static const _requiredCaptures = 3;
  final List<_CaptureStep> _steps = [
    _CaptureStep(label: 'Hadap Lurus', hint: 'Lihat langsung ke kamera', icon: Icons.face_rounded),
    _CaptureStep(label: 'Sedikit Kiri', hint: 'Putar kepala sedikit ke kiri', icon: Icons.arrow_back_rounded),
    _CaptureStep(label: 'Sedikit Kanan', hint: 'Putar kepala sedikit ke kanan', icon: Icons.arrow_forward_rounded),
  ];

  int _currentStep = 0;
  List<List<double>> _capturedEmbeddings = [];
  bool _isCapturing = false;
  bool _isProcessing = false;
  bool _done = false;
  String? _errorMsg;
  Face? _liveDetectedFace;
  bool _isStreamRunning = false;
  bool _isProcessingFrame = false;

  late AnimationController _successCtrl;
  late Animation<double> _successScale;
  late AnimationController _captureCtrl;
  late Animation<double> _captureFlash;

  @override
  void initState() {
    super.initState();
    _successCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 700));
    _successScale = CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut);

    _captureCtrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 250));
    _captureFlash = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _captureCtrl, curve: Curves.easeOut));

    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cam = await FaceService.instance.getFrontCamera();
      if (cam == null) throw Exception('Kamera depan tidak ditemukan');
      final ctrl = CameraController(cam, ResolutionPreset.high,
          enableAudio: false, imageFormatGroup: ImageFormatGroup.nv21);
      await ctrl.initialize();
      if (!mounted) { ctrl.dispose(); return; }
      setState(() { _cam = ctrl; _camReady = true; });
      _startLiveFaceDetection();
    } catch (e) {
      if (mounted) setState(() => _camError = e.toString());
    }
  }

  void _startLiveFaceDetection() async {
    if (!_camReady || _cam == null || _isStreamRunning) return;
    _isStreamRunning = true;
    await _cam!.startImageStream(_onLiveFrame);
  }

  Future<void> _stopStream() async {
    if (!_isStreamRunning) return;
    _isStreamRunning = false;
    await _cam?.stopImageStream();
  }

  Future<void> _onLiveFrame(CameraImage image) async {
    if (_isProcessingFrame || _isCapturing) return;
    _isProcessingFrame = true;
    try {
      final cam = await FaceService.instance.getFrontCamera();
      if (cam == null) { _isProcessingFrame = false; return; }
      final input = FaceService.instance.cameraImageToInputImage(image, cam);
      if (input == null) { _isProcessingFrame = false; return; }
      final faces = await FaceService.instance.detectFaces(input);
      if (!mounted) { _isProcessingFrame = false; return; }
      setState(() => _liveDetectedFace = faces.isEmpty ? null :
          faces.reduce((a, b) => a.boundingBox.width > b.boundingBox.width ? a : b));
    } catch (_) {}
    _isProcessingFrame = false;
  }

  // ── Capture ───────────────────────────

  Future<void> _captureStep() async {
    if (_isCapturing || !_camReady || _cam == null) return;
    if (_liveDetectedFace == null) {
      _showError('Posisikan wajah dalam oval terlebih dahulu');
      return;
    }

    setState(() { _isCapturing = true; _errorMsg = null; });

    // Flash effect
    _captureCtrl.forward(from: 0).then((_) => _captureCtrl.reverse());

    try {
      await _stopStream();

      // Take photo
      final xfile = await _cam!.takePicture();

      // Re-detect from the still image
      final input = InputImage.fromFilePath(xfile.path);
      final faces = await FaceService.instance.detectFaces(input);

      if (faces.isEmpty) {
        _showError('Wajah tidak terdeteksi saat pengambilan foto. Coba lagi.');
        await _restartStream();
        return;
      }

      final face = faces.reduce((a, b) =>
          a.boundingBox.width > b.boundingBox.width ? a : b);

      // Validasi pose per step
      final yaw   = face.headEulerAngleY ?? 0;
      final pitch = (face.headEulerAngleX ?? 0).abs();
      if (pitch > 20) {
        _showError('Jaga kepala tetap tegak (jangan mendongak/menunduk)');
        await _restartStream();
        return;
      }
      if (_currentStep == 0 && yaw.abs() > 15) {
        _showError('Langkah ini perlu wajah lurus ke depan');
        await _restartStream();
        return;
      }
      if (_currentStep == 1 && yaw > -5) {
        _showError('Putar kepala sedikit ke kiri');
        await _restartStream();
        return;
      }
      if (_currentStep == 2 && yaw < 5) {
        _showError('Putar kepala sedikit ke kanan');
        await _restartStream();
        return;
      }

      // Extract embedding — use photo dimensions
      // We use a rough size (takePicture doesn't expose easy dimensions here)
      // final embedding = FaceService.instance.extractEmbedding(
      //   face,
      //   FaceService.Size(1080, 1920),
      // );
      final embedding = FaceService.instance.extractEmbedding(
        face,
        Size(1080, 1920),
      );
      _capturedEmbeddings.add(embedding);

      if (_currentStep < _requiredCaptures - 1) {
        setState(() => _currentStep++);
        await _restartStream();
      } else {
        // All captures done → save averaged embedding
        setState(() { _isProcessing = true; });
        await _saveEmbeddings();
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
      await _restartStream();
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _restartStream() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _isStreamRunning = false;
    _startLiveFaceDetection();
  }

  Future<void> _saveEmbeddings() async {
    try {
      // Average the 3 embeddings into one representative embedding
      final len = _capturedEmbeddings.first.length;
      final averaged = List<double>.generate(len, (i) {
        double sum = 0;
        for (final emb in _capturedEmbeddings) sum += emb[i];
        return sum / _capturedEmbeddings.length;
      });

      final embedding = FaceEmbedding(
        userId: widget.userId,
        values: averaged,
        capturedAt: DateTime.now(),
      );
      await FaceService.instance.saveEmbedding(embedding);

      if (mounted) {
        setState(() { _isProcessing = false; _done = true; });
        _successCtrl.forward();
        await _stopStream();
      }
    } catch (e) {
      if (mounted) setState(() { _isProcessing = false; _errorMsg = e.toString(); });
    }
  }

  void _showError(String msg) {
    if (mounted) setState(() { _errorMsg = msg; _isCapturing = false; });
  }

  @override
  void dispose() {
    _stopStream();
    _cam?.dispose();
    _successCtrl.dispose();
    _captureCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────
            _RegHeader(
              userName: widget.userName,
              currentStep: _currentStep,
              totalSteps: _requiredCaptures,
              done: _done,
            ),

            // ── Camera + overlay ────────────
            Expanded(
              child: _done
                  ? _DoneView(
                      userName: widget.userName,
                      scaleAnim: _successScale,
                      onDone: () => Navigator.pop(context, true),
                    )
                  : _buildCameraView(),
            ),

            // ── Bottom panel ────────────────
            if (!_done)
              _BottomPanel(
                steps: _steps,
                currentStep: _currentStep,
                capturedCount: _capturedEmbeddings.length,
                hasFace: _liveDetectedFace != null,
                isCapturing: _isCapturing,
                isProcessing: _isProcessing,
                errorMsg: _errorMsg,
                onCapture: _captureStep,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    if (_camError != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.camera_alt_outlined, color: Colors.white38, size: 56),
          const SizedBox(height: 12),
          Text(_camError!, style: const TextStyle(color: Colors.white54),
              textAlign: TextAlign.center),
        ]),
      ));
    }
    if (!_camReady || _cam == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_cam!),

        // Oval mask
        CustomPaint(
          painter: _RegisterOvalPainter(
            hasFace: _liveDetectedFace != null,
            stepIndex: _currentStep,
          ),
        ),

        // Capture flash
        AnimatedBuilder(
          animation: _captureFlash,
          builder: (_, __) => _captureFlash.value > 0
              ? Opacity(
                  opacity: _captureFlash.value * 0.6,
                  child: Container(color: Colors.white),
                )
              : const SizedBox(),
        ),

        // Step indicators on sides
        Positioned(
          top: 16, left: 0, right: 0,
          child: _StepDotsRow(
            currentStep: _currentStep,
            captured: _capturedEmbeddings.length,
            total: _requiredCaptures,
          ),
        ),

        // Face quality indicator
        if (_liveDetectedFace != null)
          Positioned(
            bottom: 100, left: 0, right: 0,
            child: Center(child: _FaceQualityBar(face: _liveDetectedFace!)),
          ),
      ],
    );
  }
}

// ── Oval painter for register ─────────────
class _RegisterOvalPainter extends CustomPainter {
  _RegisterOvalPainter({
    required this.hasFace,
    required this.stepIndex,
  });

  final bool hasFace;
  final int stepIndex;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {

    final cx = size.width / 2;
    final cy = size.height / 2 - 20;

    final rw = size.width * 0.36;
    final rh = size.height * 0.36;

    final oval = Rect.fromCenter(
      center: Offset(cx, cy),
      width: rw * 2,
      height: rh * 2,
    );

    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addOval(oval)
        ..fillType = PathFillType.evenOdd,
      Paint()..color = Colors.black.withOpacity(0.5),
    );

    final colors = [
      Colors.white54,
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
    ];

    final color = hasFace
        ? AppColors.accent
        : colors[stepIndex % colors.length];

    canvas.drawOval(
      oval,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _RegisterOvalPainter old) {
    return old.hasFace != hasFace ||
        old.stepIndex != stepIndex;
  }
}

// ── Face quality bar ──────────────────────
class _FaceQualityBar extends StatelessWidget {
  const _FaceQualityBar({required this.face});
  final Face face;

  double get _quality {
    final yaw   = 1 - (face.headEulerAngleY ?? 0).abs() / 90;
    final pitch = 1 - (face.headEulerAngleX ?? 0).abs() / 90;
    final eye   = ((face.leftEyeOpenProbability ?? 0.5) +
        (face.rightEyeOpenProbability ?? 0.5)) / 2;
    return (yaw * 0.35 + pitch * 0.35 + eye * 0.30).clamp(0.0, 1.0);
  }

  Color get _color {
    if (_quality > 0.75) return AppColors.success;
    if (_quality > 0.5)  return AppColors.accent;
    return AppColors.error;
  }

  String get _label {
    if (_quality > 0.75) return 'Kualitas Baik ✅';
    if (_quality > 0.5)  return 'Kualitas Cukup';
    return 'Kurang Jelas';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: Colors.black54,
          borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(_label, style: TextStyle(color: _color, fontSize: 12,
              fontWeight: FontWeight.w700)),
          Text('${(_quality * 100).toStringAsFixed(0)}%',
              style: TextStyle(color: _color, fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _quality,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(_color),
            minHeight: 5,
          ),
        ),
      ]),
    );
  }
}

// ── Step dots row ─────────────────────────
class _StepDotsRow extends StatelessWidget {
  const _StepDotsRow({required this.currentStep, required this.captured,
      required this.total});
  final int currentStep, captured, total;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isDone = i < captured;
        final isActive = i == currentStep && !isDone;
        return Container(
          width: isDone || isActive ? 28 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: isDone ? AppColors.success : isActive ? AppColors.accent : Colors.white24,
            borderRadius: BorderRadius.circular(4),
          ),
          child: isDone ? const Icon(Icons.check, size: 8, color: Colors.white) : null,
        );
      }),
    );
  }
}

// ── Header ────────────────────────────────
class _RegHeader extends StatelessWidget {
  const _RegHeader({required this.userName, required this.currentStep,
      required this.totalSteps, required this.done});
  final String userName;
  final int currentStep, totalSteps;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(0)),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Registrasi Wajah', style: TextStyle(fontSize: 16,
              fontWeight: FontWeight.w700, color: Colors.white)),
          Text(done ? 'Selesai' : 'Langkah ${currentStep + 1} dari $totalSteps — $userName',
              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
        ])),
        if (!done)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('${currentStep + 1}/$totalSteps',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
      ]),
    );
  }
}

// ── Bottom panel ──────────────────────────
class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.steps, required this.currentStep, required this.capturedCount,
    required this.hasFace, required this.isCapturing, required this.isProcessing,
    required this.errorMsg, required this.onCapture,
  });

  final List<_CaptureStep> steps;
  final int currentStep, capturedCount;
  final bool hasFace, isCapturing, isProcessing;
  final String? errorMsg;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    final step = steps[currentStep];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF12122A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Current step info
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(step.icon, color: AppColors.accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(step.label, style: const TextStyle(fontSize: 15,
                fontWeight: FontWeight.w700, color: Colors.white)),
            Text(step.hint, style: const TextStyle(fontSize: 12, color: Colors.white54)),
          ])),
          // Previous captures
          Row(children: List.generate(capturedCount, (_) =>
              Container(width: 8, height: 8,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: AppColors.success)),
          )),
        ]),

        if (errorMsg != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.error.withOpacity(0.3))),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(errorMsg!,
                  style: const TextStyle(fontSize: 12, color: AppColors.error))),
            ]),
          ),
        ],

        const SizedBox(height: 16),

        // Capture button
        GestureDetector(
          onTap: (isCapturing || isProcessing) ? null : onCapture,
          child: Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: hasFace ? AppColors.accent : Colors.white24, width: 3),
              color: (isCapturing || isProcessing)
                  ? Colors.white12
                  : hasFace ? AppColors.accent.withOpacity(0.15) : Colors.transparent,
            ),
            child: Center(
              child: isCapturing || isProcessing
                  ? const CircularProgressIndicator(
                      color: AppColors.accent, strokeWidth: 3)
                  : Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasFace ? AppColors.accent : Colors.white24,
                      ),
                    ),
            ),
          ),
        ),

        const SizedBox(height: 10),
        Text(
          isProcessing ? 'Menyimpan data wajah...' :
          isCapturing  ? 'Mengambil foto...' :
          hasFace      ? 'Tekan untuk foto' :
                         'Posisikan wajah dalam oval',
          style: const TextStyle(fontSize: 12, color: Colors.white54),
        ),
      ]),
    );
  }
}

// ── Done screen ───────────────────────────
class _DoneView extends StatelessWidget {
  const _DoneView({required this.userName, required this.scaleAnim,
      required this.onDone});
  final String userName;
  final Animation<double> scaleAnim;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      child: Center(
        child: ScaleTransition(
          scale: scaleAnim,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: AppColors.success.withOpacity(0.15)),
                child: const Icon(Icons.face_retouching_natural,
                    color: AppColors.success, size: 52),
              ),
              const SizedBox(height: 24),
              const Text('Wajah Berhasil Diregistrasi! 🎉',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                      color: Colors.white)),
              const SizedBox(height: 8),
              Text('Halo $userName, wajah Anda sudah tersimpan.\nSekarang Anda bisa absen menggunakan scan wajah.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.6)),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton.icon(
                  onPressed: onDone,
                  icon: const Icon(Icons.check_circle_rounded, size: 20),
                  label: const Text('Selesai', style: TextStyle(fontSize: 15,
                      fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Model ─────────────────────────────────
class _CaptureStep {
  const _CaptureStep({required this.label, required this.hint, required this.icon});
  final String label, hint;
  final IconData icon;
}
