/// ─────────────────────────────────────────
///  AUTH – DOMAIN MODELS
/// ─────────────────────────────────────────

class LoginRequest {
  const LoginRequest({
    required this.email,
    required this.password,
    this.rememberMe = false,
  });

  final String email;
  final String password;
  final bool rememberMe;
}

class AuthResult {
  const AuthResult({
    required this.success,
    this.token,
    this.errorMessage,
    this.user,
  });

  final bool success;
  final String? token;
  final String? errorMessage;
  final AuthUser? user;

  factory AuthResult.success({required String token, required AuthUser user}) =>
      AuthResult(success: true, token: token, user: user);

  factory AuthResult.failure(String message) =>
      AuthResult(success: false, errorMessage: message);
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.position,
    this.department,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String email;
  final String position;
  final String? department;
  final String? avatarUrl;
}

/// Simple form validation helpers
class AuthValidators {
  AuthValidators._();

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email tidak boleh kosong';
    final emailRegex = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Format email tidak valid';
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password tidak boleh kosong';
    if (value.length < 6) return 'Password minimal 6 karakter';
    return null;
  }
}
