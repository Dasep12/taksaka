import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// ─────────────────────────────────────────
///  AUTH BRAND HEADER  – Logo + tagline
/// ─────────────────────────────────────────
class AuthBrandHeader extends StatefulWidget {
  const AuthBrandHeader({super.key, this.subtitle});
  final String? subtitle;

  @override
  State<AuthBrandHeader> createState() => _AuthBrandHeaderState();
}

class _AuthBrandHeaderState extends State<AuthBrandHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideUp,
        child: Column(
          children: [
            // Logo mark
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // decorative ring
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        width: 1.5,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.people_alt_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                  // amber accent dot
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // App name
            const Text(
              'HRMS',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.subtitle ?? 'Human Resource Management System',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.grey600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
