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
    this.message,
    this.token,
    this.user,
    this.employee,
  });

  final bool success;
  final String? message;
  final String? token;
  final ApiUser? user;
  final ApiEmployee? employee;

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    final success = json['success'] == true;
    final data = json['data'] as Map<String, dynamic>?;

    return AuthResult(
      success: success,
      message: json['message'] as String?,
      token: data?['token'] as String?,
      user: data?['user'] != null ? ApiUser.fromJson(data!['user']) : null,
      employee: data?['employee'] != null
          ? ApiEmployee.fromJson(data!['employee'])
          : null,
    );
  }

  factory AuthResult.failure(String message) =>
      AuthResult(success: false, message: message);
}

class ApiUser {
  const ApiUser({
    required this.id,
    required this.name,
    required this.email,
    this.companyId,
    this.employeeId,
  });

  final int id;
  final String name;
  final String email;
  final int? companyId;
  final int? employeeId;

  factory ApiUser.fromJson(Map<String, dynamic> json) => ApiUser(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        companyId: json['company_id'],
        employeeId: json['employee_id'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'company_id': companyId,
        'employee_id': employeeId,
      };
}

class ApiEmployee {
  const ApiEmployee({
    required this.employeeId,
    required this.employeeCode,
    required this.employeeName,
    required this.email,
    this.phone,
    this.photoPath,
    this.gender,
  });

  final int employeeId;
  final String employeeCode;
  final String employeeName;
  final String email;
  final String? phone;
  final String? photoPath;
  final String? gender;

  factory ApiEmployee.fromJson(Map<String, dynamic> json) => ApiEmployee(
        employeeId: json['employee_id'],
        employeeCode: json['employee_code'],
        employeeName: json['employee_name'],
        email: json['email'],
        phone: json['phone'],
        photoPath: json['photo_path'],
        gender: json['gender'],
      );

  Map<String, dynamic> toJson() => {
        'employee_id': employeeId,
        'employee_code': employeeCode,
        'employee_name': employeeName,
        'email': email,
        'phone': phone,
        'photo_path': photoPath,
        'gender': gender,
      };
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
