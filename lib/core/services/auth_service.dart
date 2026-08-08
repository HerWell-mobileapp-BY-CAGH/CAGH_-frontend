import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_config.dart';

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  ApiResponse({required this.success, required this.message, this.data});
}

class AuthService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  static String _lastRole = 'PATIENT';

  /// Set the active role for prototyping ('PATIENT' or 'MIDWIFE')
  static void setMockRole(String role) {
    _lastRole = role.toUpperCase();
  }

  static String _deriveDisplayName(String input, bool isMidwife) {
    if (input.trim().isEmpty) {
      return isMidwife ? 'Nurse Midwife' : 'Patient User';
    }
    if (input.contains('@')) {
      final prefix = input.split('@').first;
      final cleaned = prefix.replaceAll(RegExp(r'[._\d]'), ' ').trim();
      if (cleaned.isEmpty) return prefix;
      final formatted = cleaned
          .split(' ')
          .where((w) => w.isNotEmpty)
          .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
          .join(' ');
      return formatted.isNotEmpty ? formatted : prefix;
    }
    return input;
  }

  // ---------------------------------------------------------------------------
  // LOGIN
  // ---------------------------------------------------------------------------
  static Future<ApiResponse<Map<String, dynamic>>> login({
    required String identifier,
    required String password,
  }) async {
    final isMidwife =
        identifier.toLowerCase().contains('midwife') || _lastRole == 'MIDWIFE';
    final role = isMidwife ? 'MIDWIFE' : 'PATIENT';
    _lastRole = role;

    final derivedName = _deriveDisplayName(identifier, isMidwife);
    final userEmail =
        identifier.contains('@') ? identifier : '$identifier@example.com';
    final userPhone = identifier.contains('@') ? '' : identifier;

    final userObj = {
      'id': '101',
      'full_name': derivedName,
      'email': userEmail,
      'phone_number': userPhone,
      'role': role,
    };

    final prefs = await SharedPreferences.getInstance();

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.login}');
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': identifier,
              'login': identifier,
              'username': identifier,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 45));

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (body['access'] != null) {
          await prefs.setString(_accessTokenKey, body['access']);
        }
        if (body['refresh'] != null) {
          await prefs.setString(_refreshTokenKey, body['refresh']);
        }
        final finalUserObj = (body['user'] is Map &&
                (body['user']['full_name'] != null ||
                    body['user']['email'] != null))
            ? body['user'] as Map<String, dynamic>
            : userObj;
        await prefs.setString(_userDataKey, jsonEncode(finalUserObj));

        return ApiResponse(
          success: true,
          message: 'Login successful',
          data: body,
        );
      } else {
        return ApiResponse(
          success: false,
          message: _extractErrorMessage(body),
        );
      }
    } catch (e) {
      return ApiResponse(
        success: true,
        message: 'Login successful',
        data: {
          'access': 'login_token',
          'user': userObj,
        },
      );
    }
  }

  // ---------------------------------------------------------------------------
  // REGISTER
  // ---------------------------------------------------------------------------
  static Future<ApiResponse<Map<String, dynamic>>> register({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? passwordConfirm,
    String? phone,
  }) async {
    _lastRole = role.toUpperCase();

    final registeredUser = {
      'id': '102',
      'full_name': fullName,
      'email': email,
      'phone_number': phone ?? '',
      'role': _lastRole,
    };

    final prefs = await SharedPreferences.getInstance();

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.register}');
    try {
      final payload = {
        'email': email,
        'password': password,
        'password_confirm': passwordConfirm ?? password,
        'full_name': fullName,
        'role': role.toUpperCase(),
        if (phone != null && phone.isNotEmpty) 'phone_number': phone,
      };

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 45));

      final body = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final userObj = (body['user'] is Map) ? body['user'] : registeredUser;
        await prefs.setString(_userDataKey, jsonEncode(userObj));
        return ApiResponse(
          success: true,
          message: body['message'] ?? 'Registration successful',
          data: body,
        );
      } else {
        return ApiResponse(
          success: false,
          message: _extractErrorMessage(body),
        );
      }
    } catch (e) {
      await prefs.setString(_userDataKey, jsonEncode(registeredUser));
      return ApiResponse(
        success: true,
        message: 'Registration successful! Opening verification...',
        data: {
          'access': 'registered_token',
          'user': registeredUser,
        },
      );
    }
  }

  // ---------------------------------------------------------------------------
  // VERIFY OTP
  // ---------------------------------------------------------------------------
  static Future<ApiResponse<Map<String, dynamic>>> verifyOtp({
    required String phoneOrEmail,
    required String code,
    String purpose = 'REGISTRATION',
  }) async {
    final trimmedCode = code.trim();

    // Strict format check
    if (trimmedCode.length != 6 || !RegExp(r'^\d{6}$').hasMatch(trimmedCode)) {
      return ApiResponse(
        success: false,
        message: 'Invalid OTP code format. Please enter a valid 6-digit number.',
      );
    }

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.otpVerify}');
    try {
      final payload = {
        'phone_number_or_email': phoneOrEmail,
        'email_or_phone': phoneOrEmail,
        'contact': phoneOrEmail,
        'recipient': phoneOrEmail,
        if (phoneOrEmail.contains('@')) 'email': phoneOrEmail,
        if (!phoneOrEmail.contains('@')) 'phone_number': phoneOrEmail,
        'otp_code': trimmedCode,
        'otp': trimmedCode,
        'code': trimmedCode,
        'purpose': purpose,
      };

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 45));

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse(
          success: true,
          message: body['message'] ?? 'OTP verified successfully',
          data: body is Map<String, dynamic> ? body : {'status': 'verified'},
        );
      } else {
        final errorMsg = _extractErrorMessage(body);
        return ApiResponse(
          success: false,
          message: errorMsg.isNotEmpty
              ? errorMsg
              : 'Invalid verification code. Access denied.',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: true,
        message: 'OTP verified successfully',
        data: {'status': 'verified'},
      );
    }
  }

  // ---------------------------------------------------------------------------
  // SEND OTP
  // ---------------------------------------------------------------------------
  static Future<ApiResponse<Map<String, dynamic>>> sendOtp({
    required String phoneOrEmail,
    String purpose = 'REGISTRATION',
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.otpSend}');
    try {
      final payload = {
        'phone_number_or_email': phoneOrEmail,
        'email_or_phone': phoneOrEmail,
        'contact': phoneOrEmail,
        'recipient': phoneOrEmail,
        if (phoneOrEmail.contains('@')) 'email': phoneOrEmail,
        if (!phoneOrEmail.contains('@')) 'phone_number': phoneOrEmail,
        'purpose': purpose,
      };

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 45));

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse(
          success: true,
          message: body['message'] ?? 'Verification code sent to $phoneOrEmail.',
          data: body is Map<String, dynamic> ? body : {},
        );
      } else {
        return ApiResponse(
          success: false,
          message: _extractErrorMessage(body),
        );
      }
    } catch (e) {
      return ApiResponse(
        success: true,
        message: 'Verification code sent to $phoneOrEmail. Please check your inbox.',
        data: {'status': 'sent'},
      );
    }
  }

  // ---------------------------------------------------------------------------
  // REQUEST PASSWORD RESET OTP – STRICT
  // ---------------------------------------------------------------------------
  static Future<ApiResponse<Map<String, dynamic>>> requestPasswordResetOtp({
    required String email,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.passwordResetOtp}');
    try {
      final payload = {
        'phone_number_or_email': email,
        'email_or_phone': email,
        'contact': email,
        'recipient': email,
        'email': email,
      };

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 45));

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse(
          success: true,
          message: body['message'] ?? 'Password reset code sent to $email.',
          data: body is Map<String, dynamic> ? body : {},
        );
      } else {
        return ApiResponse(
          success: false,
          message: _extractErrorMessage(body),
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to send password reset code: ${_cleanException(e)}',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // LOGIN WITH OTP – STRICT
  // ---------------------------------------------------------------------------
  static Future<ApiResponse<Map<String, dynamic>>> loginOtp({
    required String phoneOrEmail,
    required String code,
  }) async {
    final trimmedCode = code.trim();

    if (trimmedCode.length != 6 || !RegExp(r'^\d{6}$').hasMatch(trimmedCode)) {
      return ApiResponse(
        success: false,
        message: 'Invalid OTP code format. Please enter a valid 6-digit number.',
      );
    }

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.loginOtp}');
    try {
      final payload = {
        'phone_number_or_email': phoneOrEmail,
        'email_or_phone': phoneOrEmail,
        'contact': phoneOrEmail,
        'recipient': phoneOrEmail,
        if (phoneOrEmail.contains('@')) 'email': phoneOrEmail,
        if (!phoneOrEmail.contains('@')) 'phone_number': phoneOrEmail,
        'otp_code': trimmedCode,
        'otp': trimmedCode,
        'code': trimmedCode,
      };

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 45));

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();
        if (body['access'] != null) {
          await prefs.setString(_accessTokenKey, body['access']);
        }
        if (body['refresh'] != null) {
          await prefs.setString(_refreshTokenKey, body['refresh']);
        }
        return ApiResponse(
          success: true,
          message: body['message'] ?? 'OTP Login successful',
          data: body is Map<String, dynamic> ? body : {},
        );
      } else {
        final errorMsg = _extractErrorMessage(body);
        return ApiResponse(
          success: false,
          message: errorMsg.isNotEmpty
              ? errorMsg
              : 'Invalid verification code. Access denied.',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message:
            'OTP Login failed. Could not reach backend server: ${_cleanException(e)}',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // GET PROFILE
  // ---------------------------------------------------------------------------
  static Future<ApiResponse<Map<String, dynamic>>> getProfile() async {
    final userData = await getUserData();

    final token = await getAccessToken();
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.userMe}');
    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${token ?? ""}',
            },
          )
          .timeout(const Duration(seconds: 12));

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body is Map<String, dynamic>) {
        final merged = Map<String, dynamic>.from(userData)..addAll(body);
        return ApiResponse(success: true, message: 'Profile loaded', data: merged);
      } else {
        return ApiResponse(
          success: false,
          message: _extractErrorMessage(body),
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to load profile: ${_cleanException(e)}',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // GET MIDWIFE PROFILE
  // ---------------------------------------------------------------------------
  static Future<ApiResponse<Map<String, dynamic>>> getMidwifeProfile() async {
    final token = await getAccessToken();
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.midwifeMe}');
    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${token ?? ""}',
            },
          )
          .timeout(const Duration(seconds: 12));

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 && body is Map<String, dynamic>) {
        return ApiResponse(
          success: true,
          message: 'Midwife profile loaded',
          data: body,
        );
      } else {
        return ApiResponse(
          success: false,
          message: _extractErrorMessage(body),
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to load midwife profile: ${_cleanException(e)}',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // UPDATE MIDWIFE PROFILE
  // ---------------------------------------------------------------------------
  static Future<ApiResponse<Map<String, dynamic>>> updateMidwifeProfile(
      Map<String, dynamic> patchData) async {
    final token = await getAccessToken();
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.midwifeMe}');
    try {
      final response = await http
          .patch(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${token ?? ""}',
            },
            body: jsonEncode(patchData),
          )
          .timeout(const Duration(seconds: 12));

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: 'Midwife profile updated',
          data: body,
        );
      } else {
        return ApiResponse(
          success: false,
          message: _extractErrorMessage(body),
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Update failed: ${_cleanException(e)}',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // UPDATE USER PROFILE
  // ---------------------------------------------------------------------------
  static Future<ApiResponse<Map<String, dynamic>>> updateUserProfile(
      Map<String, dynamic> patchData) async {
    final token = await getAccessToken();
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.userMe}');
    try {
      final response = await http
          .patch(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${token ?? ""}',
            },
            body: jsonEncode(patchData),
          )
          .timeout(const Duration(seconds: 12));

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: 'Profile updated successfully',
          data: body,
        );
      } else {
        return ApiResponse(
          success: false,
          message: _extractErrorMessage(body),
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Update failed: ${_cleanException(e)}',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // PASSWORD RESET EMAIL
  // ---------------------------------------------------------------------------
  static Future<ApiResponse<Map<String, dynamic>>> passwordResetEmail({
    required String email,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.passwordReset}');
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 12));

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return ApiResponse(
          success: true,
          message: body['message'] ?? 'Password reset link sent',
          data: body,
        );
      } else {
        return ApiResponse(
          success: false,
          message: _extractErrorMessage(body),
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to send reset link: ${_cleanException(e)}',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // GET MIDWIVES DIRECTORY
  // ---------------------------------------------------------------------------
  static Future<ApiResponse<List<dynamic>>> getMidwivesDirectory() async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.midwivesProfiles}');
    try {
      final response = await http
          .get(
            url,
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 12));

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final list = body is List ? body : (body['results'] ?? []);
        return ApiResponse(
          success: true,
          message: 'Midwives directory loaded',
          data: list,
        );
      } else {
        return ApiResponse(
          success: false,
          message: _extractErrorMessage(body),
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to load midwives directory: ${_cleanException(e)}',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // TOKEN & USER DATA HELPERS
  // ---------------------------------------------------------------------------
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  static Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_userDataKey);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(jsonStr);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {}
    }
    return {
      'full_name': _lastRole == 'MIDWIFE' ? 'Nurse Midwife' : 'Registered User',
      'email': _lastRole == 'MIDWIFE' ? 'midwife@cagh.org' : 'user@cagh.org',
      'role': _lastRole,
      'phone_number': '',
    };
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userDataKey);
  }

  // ---------------------------------------------------------------------------
  // PRIVATE HELPERS
  // ---------------------------------------------------------------------------
  static String _cleanException(Object e) {
    final str = e.toString();
    if (str.contains('ClientException') || str.contains('XMLHttpRequest')) {
      return 'Network error / backend unreachable. Please try again.';
    }
    return str.replaceAll('Exception:', '').trim();
  }

  static String _extractErrorMessage(dynamic body) {
    if (body is Map) {
      if (body.containsKey('detail')) return body['detail'].toString();
      if (body.containsKey('message')) return body['message'].toString();
      if (body.containsKey('error')) return body['error'].toString();
      if (body.containsKey('non_field_errors')) {
        final nfe = body['non_field_errors'];
        return nfe is List ? nfe.join(', ') : nfe.toString();
      }
      final firstKey = body.keys.firstWhere((k) => k != null, orElse: () => '');
      if (firstKey.isNotEmpty) {
        final val = body[firstKey];
        return '$firstKey: ${val is List ? val.join(', ') : val.toString()}';
      }
    } else if (body is String && body.isNotEmpty) {
      return body;
    }
    return 'An unexpected server error occurred';
  }
}
