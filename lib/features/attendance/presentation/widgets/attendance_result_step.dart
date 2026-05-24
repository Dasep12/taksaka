import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/attendance_models.dart';

/// ─────────────────────────────────────────
///  STEP 3 – RESULT
///  Tampilan sukses / gagal absensi
/// ─────────────────────────────────────────
class AttendanceResultStep extends StatefulWidget {
  const AttendanceResultStep({
    super.key,
    required this.record,
    required this.onDone,
  });

  final AttendanceRecord record;
  final VoidCallback onDone;

  @override
  State<AttendanceResultStep> createState() => _AttendanceResultStepState();
}

class _AttendanceResultStepState extends State<AttendanceResultStep>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;
  late Animation<double> _slideY;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );
    _slideY = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool get _isClockIn => widget.record.type == AttendanceType.clockIn;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ── Success icon ──────────────────
        ScaleTransition(
          scale: _scale,
          child: _SuccessIcon(isClockIn: _isClockIn),
        ),
        const SizedBox(height: AppSpacing.xxl),

        // ── Details card ──────────────────
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) => Opacity(
            opacity: _fade.value,
            child: Transform.translate(
              offset: Offset(0, _slideY.value),
              child: child,
            ),
          ),
          child: _AttendanceDetailsCard(record: widget.record),
        ),

        const SizedBox(height: AppSpacing.xl),

        // ── Done button ───────────────────
        AnimatedBuilder(
          animation: _fade,
          builder: (_, child) =>
              Opacity(opacity: _fade.value, child: child),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: widget.onDone,
              icon: const Icon(Icons.home_rounded, size: 20),
              label: const Text('Kembali ke Beranda',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SuccessIcon extends StatelessWidget {
  const _SuccessIcon({required this.isClockIn});
  final bool isClockIn;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer ring
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withOpacity(0.08),
              ),
            ),
            // Inner ring
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withOpacity(0.15),
              ),
            ),
            // Icon
            Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success,
              ),
              child: Icon(
                isClockIn ? Icons.login_rounded : Icons.logout_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          isClockIn ? 'Clock In Berhasil! 🎉' : 'Clock Out Berhasil! 👋',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Absensi Anda telah tersimpan',
          style: TextStyle(fontSize: 14, color: AppColors.grey600),
        ),
      ],
    );
  }
}

class _AttendanceDetailsCard extends StatelessWidget {
  const _AttendanceDetailsCard({required this.record});
  final AttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.access_time_rounded,
            label: 'Waktu',
            value: record.formattedTime,
            valueColor: AppColors.primary,
          ),
          const Divider(height: 20),
          _DetailRow(
            icon: Icons.calendar_today_rounded,
            label: 'Tanggal',
            value: record.formattedDate,
          ),
          const Divider(height: 20),
          _DetailRow(
            icon: Icons.business_rounded,
            label: 'Kantor',
            value: record.officeName,
          ),
          const Divider(height: 20),
          _DetailRow(
            icon: Icons.location_on_rounded,
            label: 'Koordinat',
            value:
                '${record.latitude.toStringAsFixed(4)}, ${record.longitude.toStringAsFixed(4)}',
            valueColor: AppColors.grey600,
          ),
          const Divider(height: 20),
          _DetailRow(
            icon: Icons.face_retouching_natural,
            label: 'Verifikasi',
            value: 'Wajah Terdeteksi ✅',
            valueColor: AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.grey600)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.grey900,
          ),
        ),
      ],
    );
  }
}
