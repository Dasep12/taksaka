import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/attendance_models.dart';
import '../../data/attendance_service.dart';
import '../../data/location_service.dart';
import '../widgets/attendance_step_indicator.dart';
import '../widgets/location_check_step.dart';
import '../widgets/face_verify_step.dart';
import '../widgets/attendance_result_step.dart';

/// ─────────────────────────────────────────
///  ATTENDANCE SCREEN  –  full real flow
/// ─────────────────────────────────────────
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({
    super.key,
    required this.type,
    this.userId = 'demo_user',
  });

  final AttendanceType type;
  final String userId;

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  AttendanceStep _currentStep = AttendanceStep.locationCheck;
  UserLocation? _verifiedLocation;
  AttendanceRecord? _record;

  late AnimationController _transCtrl;
  late Animation<double> _transAnim;

  OfficeLocation? _verifiedOffice;
  List<OfficeLocation> _offices = [];
  bool _isLoadingOffice = true;

  @override
  void initState() {
    super.initState();
    _loadOffice();
    _transCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _transAnim = CurvedAnimation(
      parent: _transCtrl,
      curve: Curves.easeOutCubic,
    );
    _transCtrl.forward();
  }

  @override
  void dispose() {
    _transCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOffice() async {
    final offices = await AttendanceService.instance.fetchAbsenceLocations();
    if (mounted) {
      setState(() {
        if (offices.isNotEmpty) {
          _offices = offices;
        } else {
          // Fallback to mock data if API fails or returns empty
          _offices = [AttendanceMockData.mainOffice];
        }
        _isLoadingOffice = false;
      });
    }
  }

  void _goToStep(AttendanceStep next) {
    _transCtrl.reverse().then((_) {
      setState(() => _currentStep = next);
      _transCtrl.forward();
    });
  }

  void _onLocationVerified(UserLocation loc, OfficeLocation nearestOffice) {
    _verifiedLocation = loc;
    _verifiedOffice = nearestOffice;
    _goToStep(AttendanceStep.faceVerify);
  }

  Future<void> _onFaceVerified(FaceVerifyResult result) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final record = await AttendanceService.instance.saveAttendance(
        type: widget.type,
        userLocation: _verifiedLocation!,
        office: _verifiedOffice!,
        faceConfidence: result.confidence ?? 0.0,
      );
      if (mounted) {
        Navigator.pop(context); // Pop loading spinner
        setState(() => _record = record);
        _goToStep(AttendanceStep.result);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Pop loading spinner
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Gagal Absensi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Tutup',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  void _onDone() => Navigator.pop(context, _record);

  String get _title =>
      widget.type == AttendanceType.clockIn ? 'Clock In' : 'Clock Out';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Column(
        children: [
          _AttendanceHeader(
            title: _title,
            canBack: _currentStep != AttendanceStep.result,
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                children: [
                  if (_currentStep != AttendanceStep.result)
                    AttendanceStepIndicator(currentStep: _currentStep),

                  const SizedBox(height: AppSpacing.lg),

                  AnimatedBuilder(
                    animation: _transAnim,
                    builder: (_, child) => Opacity(
                      opacity: _transAnim.value,
                      child: Transform.translate(
                        offset: Offset(0, (1 - _transAnim.value) * 18),
                        child: child,
                      ),
                    ),
                    child: _isLoadingOffice
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: CircularProgressIndicator(color: AppColors.primary),
                            ),
                          )
                        : _buildStep(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    return switch (_currentStep) {
      AttendanceStep.locationCheck => SizedBox(
        height: 520,
        child: LocationCheckStep(
          offices: _offices,
          onLocationVerified: _onLocationVerified,
        ),
      ),
      AttendanceStep.faceVerify => SizedBox(
        height: 520,
        child: FaceVerifyStep(
          attendanceType: widget.type,
          userId: widget.userId,
          onVerified: _onFaceVerified,
          onFailed: (_) {},
        ),
      ),
      AttendanceStep.result => AttendanceResultStep(
        record: _record!,
        onDone: _onDone,
      ),
    };
  }
}

class _AttendanceHeader extends StatelessWidget {
  const _AttendanceHeader({required this.title, required this.canBack});
  final String title;
  final bool canBack;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      color: AppColors.primary,
      padding: EdgeInsets.fromLTRB(16, top + 12, 16, 16),
      child: Row(
        children: [
          if (canBack)
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            )
          else
            const SizedBox(width: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          _LiveClock(),
        ],
      ),
    );
  }
}

class _LiveClock extends StatefulWidget {
  @override
  State<_LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<_LiveClock> {
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _now = DateTime.now());
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final h = _now.hour.toString().padLeft(2, '0');
    final m = _now.minute.toString().padLeft(2, '0');
    final s = _now.second.toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$h:$m:$s',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
