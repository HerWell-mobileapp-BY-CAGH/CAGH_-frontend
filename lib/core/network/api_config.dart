import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Production API Constants
class ApiConstants {
  // Production REST API Base URL
  static const String baseUrl = 'https://cagh-backend-api.onrender.com/api/v1';

  // Production WebSockets Base URL (Use wss:// for SSL security)
  static const String wsUrl = 'wss://cagh-backend-api.onrender.com/ws';
}

/// Core API Configuration for CAGH Application
class ApiConfig {
  /// Toggle to enable local UI prototyping without a running backend server.
  /// Set to `false` when integrating with live backend.
  static bool useMockData = false;

  /// Base REST API URL for backend calls.
  static String get baseUrl => ApiConstants.baseUrl;

  /// Base WebSockets URL for real-time channels.
  static String get wsUrl => ApiConstants.wsUrl;

  // Authentication & Security Endpoints
  static const String login = '/auth/login/';
  static const String loginOtp = '/auth/login/otp/';
  static const String register = '/auth/register/';
  static const String otpSend = '/auth/otp/send/';
  static const String otpVerify = '/auth/otp/verify/';
  static const String passwordReset = '/auth/password/reset/';
  static const String passwordResetOtp = '/auth/password/reset/otp/';
  static const String passwordResetConfirmOtp = '/auth/password/reset/otp/confirm/';
  static const String tokenRefresh = '/auth/token/refresh/';

  // User & Midwife Profiles Endpoints
  static const String userMe = '/users/me/';
  static const String midwivesProfiles = '/midwives/profiles/';
  static const String midwifeMe = '/midwives/profiles/me/';
  static const String midwifeDashboard = '/midwives/dashboard/';
  static const String midwifeBlockedDates = '/midwives/blocked-dates/';
  
  // Appointments Endpoints
  static const String appointments = '/appointments/';
  static const String timeSlots = '/appointments/time-slots/';
  static const String availabilities = '/appointments/availability/';

  // Consultations Endpoints
  static const String consultations = '/consultations/';

  // Nearby Facilities Endpoints
  static const String facilities = '/common/facilities/';
}
