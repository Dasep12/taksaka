import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../domain/auth_models.dart';
import '../../data/auth_service.dart';
import '../widgets/auth_brand_header.dart';
import '../../../home/presentation/screens/home_screen.dart';

/// ─────────────────────────────────────────
///  LOGIN SCREEN
/// ─────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _rememberMe = false;
  bool _isLoading = false;

  // For the card slide-up animation
  late AnimationController _cardCtrl;
  late Animation<Offset> _cardSlide;
  late Animation<double> _cardFade;

  @override
  void initState() {
    super.initState();
    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _cardCtrl,
            curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
          ),
        );
    _cardFade = CurvedAnimation(
      parent: _cardCtrl,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    );
    _cardCtrl.forward();
  }

  @override
  void dispose() {
    _cardCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ── Handlers ─────────────────────────────

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    // Call API Login
    final result = await AuthService.instance.login(email, password);

    if (mounted) {
      setState(() => _isLoading = false);

      if (result.success) {
        _navigateToHome();
      } else {
        _showError(
          result.message ??
              'Login gagal. Periksa kembali email dan password Anda.',
        );
      }
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _fillDemo() {
    _emailCtrl.text = 'admin@admin.com';
    _passwordCtrl.text = '123456';
  }

  // ── Build ─────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // Background decorations
          const _BackgroundDecor(),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // ── Brand header (top section on primary bg)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.xxxl,
                  ),
                  child: const AuthBrandHeader(),
                ),

                // ── White card (slides up)
                Expanded(
                  child: FadeTransition(
                    opacity: _cardFade,
                    child: SlideTransition(
                      position: _cardSlide,
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.xxl,
                            AppSpacing.xxxl,
                            AppSpacing.xxl,
                            AppSpacing.xxl,
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title
                                const Text(
                                  'Selamat Datang 👋',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Masuk untuk melanjutkan ke akun Anda',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.grey600,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xxxl),

                                // Email field
                                AppTextField(
                                  label: 'Email Perusahaan',
                                  hint: 'nama@perusahaan.com',
                                  controller: _emailCtrl,
                                  focusNode: _emailFocus,
                                  keyboardType: TextInputType.emailAddress,
                                  prefixIcon: Icons.email_outlined,
                                  autofillHints: const [AutofillHints.email],
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) => FocusScope.of(
                                    context,
                                  ).requestFocus(_passwordFocus),
                                  validator: AuthValidators.validateEmail,
                                ),
                                const SizedBox(height: AppSpacing.xl),

                                // Password field
                                AppTextField(
                                  label: 'Password',
                                  hint: 'Masukkan password Anda',
                                  controller: _passwordCtrl,
                                  focusNode: _passwordFocus,
                                  isPassword: true,
                                  prefixIcon: Icons.lock_outline_rounded,
                                  autofillHints: const [AutofillHints.password],
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _handleLogin(),
                                  validator: AuthValidators.validatePassword,
                                ),
                                const SizedBox(height: AppSpacing.md),

                                // Remember me + Forgot password
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _RememberMe(
                                      value: _rememberMe,
                                      onChanged: (v) => setState(
                                        () => _rememberMe = v ?? false,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () =>
                                          _showForgotPasswordSheet(context),
                                      child: const Text(
                                        'Lupa Password?',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.accent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xxxl),

                                // Login button
                                AppButton(
                                  label: 'Masuk',
                                  onPressed: _handleLogin,
                                  isLoading: _isLoading,
                                  isFullWidth: true,
                                  height: 52,
                                  icon: _isLoading ? null : Icons.login_rounded,
                                ),
                                const SizedBox(height: AppSpacing.lg),

                                // Demo hint
                                _DemoHint(onTap: _fillDemo),
                                const SizedBox(height: AppSpacing.xxl),

                                // Footer
                                _LoginFooter(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ForgotPasswordSheet(),
    );
  }
}

// ── Background Decoration ─────────────────
class _BackgroundDecor extends StatelessWidget {
  const _BackgroundDecor();

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          // Top-right circle
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          // Small amber accent
          Positioned(
            top: 80,
            right: 40,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent,
              ),
            ),
          ),
          // Left mid circle
          Positioned(
            top: 140,
            left: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Remember Me checkbox ──────────────────
class _RememberMe extends StatelessWidget {
  const _RememberMe({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              side: const BorderSide(color: AppColors.grey400, width: 1.5),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Ingat saya',
            style: TextStyle(fontSize: 13, color: AppColors.grey600),
          ),
        ],
      ),
    );
  }
}

// ── Demo hint banner ──────────────────────
class _DemoHint extends StatelessWidget {
  const _DemoHint({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.accent.withOpacity(0.25),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.tips_and_updates_rounded,
                size: 14,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Demo Account',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey900,
                    ),
                  ),
                  Text(
                    'Tap untuk isi otomatis: admin@admin.com',
                    style: TextStyle(fontSize: 11, color: AppColors.grey600),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: AppColors.grey400,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Footer ────────────────────────────────
class _LoginFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: RichText(
        text: const TextSpan(
          text: 'Butuh bantuan? ',
          style: TextStyle(fontSize: 12, color: AppColors.grey600),
          children: [
            TextSpan(
              text: 'Hubungi HR Anda',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Forgot Password Bottom Sheet ──────────
class _ForgotPasswordSheet extends StatefulWidget {
  const _ForgotPasswordSheet();

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  final _ctrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _sent = false;
  bool _loading = false;

  Future<void> _handleSend() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted)
      setState(() {
        _loading = false;
        _sent = true;
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          if (!_sent) ...[
            const Text(
              'Lupa Password?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Masukkan email Anda, kami akan kirim\nlink reset password.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.grey600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: AppTextField(
                label: 'Email',
                hint: 'nama@perusahaan.com',
                controller: _ctrl,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                validator: AuthValidators.validateEmail,
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Kirim Link Reset',
              onPressed: _handleSend,
              isLoading: _loading,
              isFullWidth: true,
              height: 50,
              icon: _loading ? null : Icons.send_rounded,
            ),
          ] else ...[
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      size: 40,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Email Terkirim!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Link reset password sudah dikirim ke\n${_ctrl.text}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.grey600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Kembali ke Login',
                    onPressed: () => Navigator.pop(context),
                    isFullWidth: true,
                    height: 50,
                    icon: Icons.arrow_back_rounded,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
