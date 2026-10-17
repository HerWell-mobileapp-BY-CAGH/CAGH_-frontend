import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cagh_frontend/core/network/api_config.dart';
import 'package:cagh_frontend/core/services/global_call_service.dart';
import 'package:cagh_frontend/core/services/global_call_websocket_manager.dart';
import 'package:cagh_frontend/core/services/fcm_service.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  ApiResponse({required this.success, required this.message, this.data});
}

class AuthService {
  static const String _accessTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  static const String _lastActiveKey = 'last_active_timestamp';
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
    String? role,
  }) async {
    final trimmed = identifier.trim();
    final isMidwife =
        trimmed.toLowerCase().contains('midwife') || _lastRole == 'MIDWIFE' || role == 'MIDWIFE';
    final activeRole = role ?? (isMidwife ? 'MIDWIFE' : 'PATIENT');
    _lastRole = activeRole;

    final isEmail = trimmed.contains('@');
    final cleanPhone = trimmed.replaceAll(RegExp(r'[\s\-()]'), '');
    final normalizedPhone = cleanPhone.startsWith('+251')
        ? cleanPhone
        : (cleanPhone.startsWith('0')
            ? '+251${cleanPhone.substring(1)}'
            : (cleanPhone.length == 9 && (cleanPhone.startsWith('9') || cleanPhone.startsWith('7'))
                ? '+251$cleanPhone'
                : cleanPhone));

    final derivedName = _deriveDisplayName(trimmed, isMidwife);
    final userEmail = isEmail ? trimmed : '$cleanPhone@example.com';
    final userPhone = isEmail ? '' : normalizedPhone;

    final userObj = {
      'id': '101',
      'full_name': derivedName,
      'email': userEmail,
      'phone_number': userPhone,
      'role': activeRole,
    };

    final prefs = await SharedPreferences.getInstance();

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.login}');
    try {
      Future<http.Response> postLogin(Map<String, dynamic> payload) {
        return http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 45));
      }

      http.Response response;
      if (isEmail) {
        response = await postLogin({
          'email': trimmed.toLowerCase(),
          'login': trimmed,
          'username': trimmed,
          'password': password,
          'role': activeRole,
          'expected_role': activeRole,
        });
      } else {
        // Attempt 1: Authenticate using normalized phone number (+251...)
        response = await postLogin({
          'phone_number': normalizedPhone,
          'login': normalizedPhone,
          'username': normalizedPhone,
          'password': password,
          'role': activeRole,
          'expected_role': activeRole,
        });

        // Attempt 2: If attempt 1 failed with 400/401 and clean format differs, retry with cleanPhone (e.g. 09...)
        if ((response.statusCode == 400 || response.statusCode == 401) &&
            cleanPhone != normalizedPhone) {
          final retryResponse = await postLogin({
            'phone_number': cleanPhone,
            'login': cleanPhone,
            'username': cleanPhone,
            'password': password,
            'role': activeRole,
            'expected_role': activeRole,
          });
          if (retryResponse.statusCode == 200 || retryResponse.statusCode == 201) {
            response = retryResponse;
          }
        }
      }

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
                    body['user']['email'] != null ||
                    body['user']['role'] != null))
            ? body['user'] as Map<String, dynamic>
            : userObj;

        // Role enforcement: 1 account for 1 role only
        final serverRole = (finalUserObj['role'] ?? body['role'] ?? '').toString().toUpperCase();
        if (role != null && serverRole.isNotEmpty && serverRole != role.toUpperCase()) {
          await prefs.remove(_accessTokenKey);
          await prefs.remove(_refreshTokenKey);
          await prefs.remove(_userDataKey);
          await prefs.remove(_lastActiveKey);

          if (role.toUpperCase() == 'MIDWIFE' && serverRole == 'PATIENT') {
            return ApiResponse(
              success: false,
              message: 'This account is registered as an adolescent/patient account. Please use the User login.',
            );
          } else if (role.toUpperCase() == 'PATIENT' && serverRole == 'MIDWIFE') {
            return ApiResponse(
              success: false,
              message: 'This account is registered as a healthcare provider/midwife account. Please use the Midwife login.',
            );
          } else {
            return ApiResponse(
              success: false,
              message: 'Role mismatch: You cannot log into this role with this account.',
            );
          }
        }

        await prefs.setString(_userDataKey, jsonEncode(finalUserObj));
        await prefs.setString(_lastActiveKey, DateTime.now().toIso8601String());

        try {
          await GlobalCallService.initUserCallListener(force: true);
          await FcmService.registerDeviceToken(force: true);
        } catch (e) {
          AppLogger.d('Failed to initialize GlobalCallService or FCM token on login: $e');
        }

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
      final reason = _cleanException(e);
      return ApiResponse(
        success: false,
        message: 'Login failed: $reason',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // REGISTER
  // ---------------------------------------------------------------------------
  static Future<ApiResponse<Map<String, dynamic>>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
    String? passwordConfirm,
    String? phone,
    int? yearsOfExperience,
  }) async {
    _lastRole = role.toUpperCase();

    final registeredUser = {
      'id': '102',
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone_number': phone ?? '',
      'role': _lastRole,
    };

    final prefs = await SharedPreferences.getInstance();
    // Clear any existing session to ensure a clean slate for the new registration
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userDataKey);
    await prefs.remove(_lastActiveKey);

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.register}');
    try {
      final payload = {
        'email': email,
        'password': password,
        'password_confirm': passwordConfirm ?? password,
        'first_name': firstName,
        'last_name': lastName,
        'role': role.toUpperCase(),
        if (phone != null && phone.isNotEmpty) 'phone_number': phone,
        // ignore: use_null_aware_elements
        if (yearsOfExperience != null) 'years_of_experience': yearsOfExperience,
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
        await prefs.setString(_lastActiveKey, DateTime.now().toIso8601String());
        return ApiResponse(
          success: true,
          message: body['message'] ?? 'Registration successful',
          data: body,
        );
      } else {
        AppLogger.d('Registration Failed. Raw backend response: $body');
        return ApiResponse(
          success: false,
          message: _extractErrorMessage(body),
        );
      }
    } catch (e) {
      final reason = _cleanException(e);
      return ApiResponse(
        success: false,
        message: 'Registration failed: $reason',
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
      // Backend requires ONLY these exact field names (confirmed by API test)
      final payload = <String, dynamic>{
        'phone_number_or_email': phoneOrEmail,
        'otp_code': trimmedCode,
        'purpose': purpose,
      };

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 60));

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (body is Map<String, dynamic>) {
          final prefs = await SharedPreferences.getInstance();
          if (body['access'] != null) {
            await prefs.setString(_accessTokenKey, body['access']);
          }
          if (body['refresh'] != null) {
            await prefs.setString(_refreshTokenKey, body['refresh']);
          }
          await prefs.setString(_lastActiveKey, DateTime.now().toIso8601String());
          try {
            await GlobalCallService.initUserCallListener(force: true);
            await FcmService.registerDeviceToken(force: true);
          } catch (e) {
            AppLogger.d('Failed to initialize GlobalCallService or FCM token on verifyOtp: $e');
          }
        }
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
      final reason = _cleanException(e);
      return ApiResponse(
        success: false,
        message: 'OTP verification failed: $reason',
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
      // Backend requires ONLY these exact field names (confirmed by API test)
      final payload = <String, dynamic>{
        'phone_number_or_email': phoneOrEmail,
        'purpose': purpose,
      };

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 60));

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
      final reason = _cleanException(e);
      return ApiResponse(
        success: false,
        message: 'OTP send failed: $reason',
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
        await prefs.setString(_lastActiveKey, DateTime.now().toIso8601String());
        try {
          await GlobalCallService.initUserCallListener(force: true);
          await FcmService.registerDeviceToken(force: true);
        } catch (e) {
          AppLogger.d('Failed to initialize GlobalCallService or FCM token on loginOtp: $e');
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
  // RESET PASSWORD (WITH OTP/TOKEN)
  // ---------------------------------------------------------------------------
  static Future<ApiResponse<Map<String, dynamic>>> resetPassword({
    required String contact,
    required String newPassword,
    required String resetToken,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.passwordResetConfirmOtp}');
    try {
      final payload = {
        'phone_number_or_email': contact,
        'email_or_phone': contact,
        'contact': contact,
        if (contact.contains('@')) 'email': contact,
        if (!contact.contains('@')) 'phone_number': contact,
        'new_password': newPassword,
        'new_password_confirm': newPassword,
        'password': newPassword,
        'otp_code': resetToken,
        'otp': resetToken,
        'token': resetToken,
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
          message: body['message'] ?? 'Password reset successfully.',
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
        message: 'Failed to reset password: ${_cleanException(e)}',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // GET MIDWIVES DIRECTORY
  // ---------------------------------------------------------------------------
  static Future<ApiResponse<List<Map<String, dynamic>>>> getMidwivesDirectory() async {
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

  static Future<bool> isSessionValid() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_accessTokenKey) ?? prefs.getString('access_token') ?? prefs.getString('access');
    
    if (token == null || token.trim().isEmpty) return false;

    final lastActiveStr = prefs.getString(_lastActiveKey);
    if (lastActiveStr != null && lastActiveStr.isNotEmpty) {
      try {
        final lastActive = DateTime.parse(lastActiveStr);
        final difference = DateTime.now().difference(lastActive);
        if (difference.inDays < 7) {
          // Extend session window
          await prefs.setString(_lastActiveKey, DateTime.now().toIso8601String());
          return true;
        } else {
          AppLogger.d('[AUTH] Session expired due to 7 days of inactivity.');
          return false;
        }
      } catch (e) {
        AppLogger.d('[AUTH] Error parsing last active timestamp: $e');
        return false;
      }
    } else {
      // If we have a token but no timestamp, we migrate them to valid and set the timestamp.
      await prefs.setString(_lastActiveKey, DateTime.now().toIso8601String());
      return true;
    }
  }

  static Completer<bool>? _refreshCompleter;

  static int? getAccessTokenExpirationSeconds(String? token) {
    if (token == null || token.trim().isEmpty) return null;
    try {
      var cleanToken = token.trim();
      if (cleanToken.startsWith('Bearer ')) {
        cleanToken = cleanToken.substring(7).trim();
      }
      cleanToken = cleanToken.replaceAll('"', '').replaceAll("'", '').trim();
      if (cleanToken.endsWith('#')) {
        cleanToken = cleanToken.substring(0, cleanToken.length - 1).trim();
      }
      final parts = cleanToken.split('.');
      if (parts.length != 3) return null;
      var payload = parts[1];
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }
      final decodedBytes = base64Url.decode(payload);
      final decodedMap = jsonDecode(utf8.decode(decodedBytes));
      if (decodedMap is Map && decodedMap.containsKey('exp')) {
        return int.tryParse(decodedMap['exp'].toString());
      }
    } catch (_) {}
    return null;
  }

  static bool isAccessTokenValid(String? token) {
    final expSeconds = getAccessTokenExpirationSeconds(token);
    if (expSeconds == null) return false;

    final expDate = DateTime.fromMillisecondsSinceEpoch(expSeconds * 1000, isUtc: true);
    final now = DateTime.now().toUtc();
    final secondsRemaining = expDate.difference(now).inSeconds;

    return secondsRemaining > 10;
  }

  static Future<bool> forceTokenRefresh() async {
    if (_refreshCompleter != null) {
      AppLogger.d('[AUTH REFRESH] started (Awaiting inflight refresh)');
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();
    AppLogger.d('[AUTH REFRESH] started');

    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(_refreshTokenKey) ?? prefs.getString('refresh_token');

      if (refreshToken == null || refreshToken.trim().isEmpty) {
        AppLogger.d('[AUTH REFRESH] refresh failed (No refresh token available)');
        await logout();
        AppLogger.d('[AUTH REFRESH] session cleared');
        _refreshCompleter!.complete(false);
        _refreshCompleter = null;
        return false;
      }

      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.tokenRefresh}');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken.trim()}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final newAccess = (data['access'] ?? data['access_token'] ?? '').toString().trim();
        final newRefresh = (data['refresh'] ?? data['refresh_token'] ?? '').toString().trim();

        if (newAccess.isNotEmpty) {
          await prefs.setString(_accessTokenKey, newAccess);
          if (newRefresh.isNotEmpty) {
            await prefs.setString(_refreshTokenKey, newRefresh);
          }
          await prefs.setString(_lastActiveKey, DateTime.now().toIso8601String());

          final newExp = getAccessTokenExpirationSeconds(newAccess);
          AppLogger.d('[AUTH REFRESH] request succeeded');
          AppLogger.d('[AUTH REFRESH] access token stored');
          AppLogger.d('[AUTH REFRESH] new token expiration: $newExp');
          _refreshCompleter!.complete(true);
          _refreshCompleter = null;
          return true;
        }
      }

      AppLogger.d('[AUTH REFRESH] refresh failed (Status ${response.statusCode})');
      await logout();
      AppLogger.d('[AUTH REFRESH] session cleared');
      _refreshCompleter!.complete(false);
      _refreshCompleter = null;
      return false;
    } catch (e) {
      AppLogger.d('[AUTH REFRESH] refresh failed (Error: $e)');
      await logout();
      AppLogger.d('[AUTH REFRESH] session cleared');
      if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
        _refreshCompleter!.complete(false);
      }
      _refreshCompleter = null;
      return false;
    }
  }

  static Future<bool> trySilentAuthRestore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_accessTokenKey) ?? prefs.getString('access_token') ?? prefs.getString('access');
      if (isAccessTokenValid(token)) {
        return true;
      }
      return await forceTokenRefresh();
    } catch (e) {
      AppLogger.d('[AUTH] trySilentAuthRestore error: $e');
    }
    return false;
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
      } catch (e) {
        AppLogger.d('AuthApiService: Error decoding cached user data: $e');
      }
    }
    return {};
  }

  static Future<void> logout() async {
    try {
      GlobalCallWebSocketManager.instance.disconnectForLogout();
    } catch (_) {}
    GlobalCallService.dispose();
    final prefs = await SharedPreferences.getInstance();
    final userData = await AuthService.getUserData();
    final userId = (userData['id'] ?? userData['user_id'] ?? '').toString();
    if (userId.isNotEmpty) {
      await prefs.remove('last_registered_fcm_token_$userId');
    }
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userDataKey);
    await prefs.remove(_lastActiveKey);
  }

  // ---------------------------------------------------------------------------
  // PRIVATE HELPERS
  // ---------------------------------------------------------------------------
  static String _cleanException(Object e) {
    final str = e.toString();
    if (str.contains('XMLHttpRequest')) {
      return 'The server blocked this request (CORS). This is a backend configuration issue, not your internet.';
    }
    if (str.contains('ClientException') || str.contains('SocketException')) {
      return 'Unable to connect. Please check your internet connection and try again.';
    }
    if (str.contains('TimeoutException')) {
      return 'The connection is taking too long. Please try again.';
    }
    if (str.contains('FormatException')) {
      return 'We couldn\'t process that information. Please check your details and try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  static String _extractErrorMessage(Object? body) {
    if (body is Map) {
      String msg = '';
      if (body.containsKey('detail')) {
        msg = body['detail'].toString();
      } else if (body.containsKey('message')) {
        msg = body['message'].toString();
      } else if (body.containsKey('error')) {
        msg = body['error'].toString();
      }
      else if (body.containsKey('non_field_errors')) {
        final nfe = body['non_field_errors'];
        msg = nfe is List ? nfe.join(', ') : nfe.toString();
      } else {
        final firstKey = body.keys.firstWhere((k) => k != null, orElse: () => '');
        if (firstKey.isNotEmpty) {
          final val = body[firstKey];
          msg = '$firstKey: ${val is List ? val.join(', ') : val.toString()}';
        }
      }
      
      final lowerMsg = msg.toLowerCase();
      if (lowerMsg.contains('access denied') || lowerMsg.contains('registered as') || lowerMsg.contains('role_mismatch') || lowerMsg.contains('cannot log in')) {
        return msg;
      }
      if (lowerMsg.contains('no active account') || 
          lowerMsg.contains('unauthorized') || 
          lowerMsg.contains('invalid credentials') || 
          lowerMsg.contains('given credentials') || 
          lowerMsg.contains('user not found') || 
          lowerMsg.contains('wrong password') || 
          lowerMsg.contains('incorrect password') || 
          lowerMsg.contains('invalid email or password')) {
        return 'Incorrect email or password. Please try again.';
      }
      if (msg.isNotEmpty) return msg;
    } else if (body is String && body.isNotEmpty) {
      final lowerBody = body.toLowerCase();
      if (lowerBody.contains('no active account') || 
          lowerBody.contains('unauthorized') || 
          lowerBody.contains('invalid credentials') || 
          lowerBody.contains('given credentials') || 
          lowerBody.contains('user not found') || 
          lowerBody.contains('wrong password') || 
          lowerBody.contains('incorrect password') || 
          lowerBody.contains('invalid email or password')) {
        return 'Incorrect email or password. Please try again.';
      }
      return body;
    }
    return 'Something went wrong on our side. Please try again in a moment.';
  }
}
