import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/auth_models.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  // URL dasar API
  // Jika dijalankan di emulator Android, localhost adalah 10.0.2.2
  String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://192.168.10.212:8084/api/v1';
    }
    return 'http://192.168.10.212:8084/api/v1';
  }

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';
  static const String _employeeKey = 'auth_employee';

  Future<AuthResult> login(String email, String password) async {
    try {
      // ✅ Hanya kirim via JSON body — tidak ada query string
      final url = Uri.parse('$baseUrl/login');

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception(
              'Koneksi timeout. Periksa jaringan atau alamat server.',
            ),
          );

      // Debug: print response untuk troubleshooting
      print('[LOGIN] status=${response.statusCode} body=${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final data = jsonDecode(response.body);
          final result = AuthResult.fromJson(data);

          if (result.success && result.token != null) {
            await saveSession(result);
          } else if (!result.success) {
            // API kembalikan success=false dengan status 200
            return AuthResult.failure(
              result.message ?? 'Login ditolak oleh server.',
            );
          }
          return result;
        } catch (parseError) {
          print('[LOGIN] Parse error: $parseError');
          return AuthResult.failure(
            'Format response server tidak dikenali. Hubungi administrator.',
          );
        }
      } else {
        try {
          final data = jsonDecode(response.body);
          return AuthResult.failure(
            data['message'] ?? 'Gagal login, status: ${response.statusCode}',
          );
        } catch (_) {
          return AuthResult.failure(
            'Gagal login. Status code: ${response.statusCode}',
          );
        }
      }
    } catch (e) {
      print('[LOGIN] Error: $e');
      if (e.toString().contains('timeout')) {
        return AuthResult.failure(
          'Koneksi timeout. Periksa jaringan atau alamat server.',
        );
      }
      return AuthResult.failure('Koneksi bermasalah: $e');
    }
  }

  Future<void> saveSession(AuthResult result) async {
    final prefs = await SharedPreferences.getInstance();
    if (result.token != null) {
      await prefs.setString(_tokenKey, result.token!);
    }
    if (result.user != null) {
      await prefs.setString(_userKey, jsonEncode(result.user!.toJson()));
    }
    if (result.employee != null) {
      await prefs.setString(
        _employeeKey,
        jsonEncode(result.employee!.toJson()),
      );
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_employeeKey);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<ApiUser?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_userKey);
    if (data != null) {
      return ApiUser.fromJson(jsonDecode(data));
    }
    return null;
  }

  Future<ApiEmployee?> getEmployee() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_employeeKey);
    if (data != null) {
      final employee = ApiEmployee.fromJson(jsonDecode(data));
      return ApiEmployee(
        employeeId: employee.employeeId,
        employeeCode: employee.employeeCode,
        employeeName: employee.employeeName,
        email: employee.email,
        phone: employee.phone,
        photoPath: getFullPhotoUrl(employee.photoPath),
        gender: employee.gender,
      );
    }
    return null;
  }

  String? getFullPhotoUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) return null;
    if (relativePath.startsWith('http://') ||
        relativePath.startsWith('https://')) {
      return relativePath;
    }
    // Remove '/api/v1' from the baseUrl to get the host url
    final base = baseUrl.replaceAll('/api/v1', '');
    return '$base/$relativePath';
  }

  Future<ApiEmployee?> fetchMe() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final url = Uri.parse('$baseUrl/me');
      final response = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10), onTimeout: () => throw Exception('timeout'));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true && json['data'] != null) {
          final employeeData = json['data'];
          final employee = ApiEmployee(
            employeeId: employeeData['employee_id'] ?? 0,
            employeeCode: employeeData['employee_code'] ?? '',
            employeeName: employeeData['employee_name'] ?? '',
            email: employeeData['email'] ?? '',
            phone: employeeData['phone'],
            photoPath: employeeData['photo_path'],
            gender: employeeData['gender'],
          );

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_employeeKey, jsonEncode(employee.toJson()));

          return ApiEmployee(
            employeeId: employee.employeeId,
            employeeCode: employee.employeeCode,
            employeeName: employee.employeeName,
            email: employee.email,
            phone: employee.phone,
            photoPath: getFullPhotoUrl(employee.photoPath),
            gender: employee.gender,
          );
        }
      }
      return null;
    } catch (e) {
      print('Error fetching /me: $e');
      return null;
    }
  }
}
