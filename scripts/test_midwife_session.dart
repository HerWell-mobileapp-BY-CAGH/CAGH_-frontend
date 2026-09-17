import 'dart:convert';
import 'package:http/http.dart' as http;

const baseUrl = 'https://cagh-backend-api.onrender.com/api/v1';

Future<void> main() async {
  print('=== STEP 1: Midwife Login ===');
  final email = const String.fromEnvironment('MIDWIFE_EMAIL', defaultValue: '');
  final password = const String.fromEnvironment('MIDWIFE_PASSWORD', defaultValue: '');

  final loginRes = await http.post(
    Uri.parse('$baseUrl/auth/login/'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': password}),
  ).timeout(const Duration(seconds: 60));

  print('Login status: ${loginRes.statusCode}');
  if (loginRes.statusCode != 200 && loginRes.statusCode != 201) {
    print('Login failed: ${loginRes.body}');
    return;
  }

  final loginData = jsonDecode(loginRes.body);
  final token = loginData['access'] ??
      loginData['access_token'] ??
      loginData['token'] ??
      loginData['data']?['access'] ??
      loginData['data']?['access_token'] ??
      '';
  print('Token found: ${token.isNotEmpty ? "yes (${token.length} chars)" : "NO"}');
  if (token.isEmpty) {
    print('Full login response: ${loginRes.body}');
    return;
  }

  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  print('\n=== STEP 2: Midwife Info ===');
  final userRes = await http.get(
    Uri.parse('$baseUrl/users/me/'),
    headers: headers,
  ).timeout(const Duration(seconds: 30));
  print('User info status: ${userRes.statusCode}');
  if (userRes.statusCode == 200) {
    final userData = jsonDecode(userRes.body);
    print('Midwife ID: ${userData['id'] ?? userData['user_id'] ?? userData['uid'] ?? 'unknown'}');
    print('Name: ${userData['full_name'] ?? userData['name'] ?? userData['first_name'] ?? 'unknown'}');
    print('Role: ${userData['role'] ?? userData['user_type'] ?? 'unknown'}');
  } else {
    print('User info failed: ${userRes.body}');
  }

  print('\n=== STEP 3: List Consultations ===');
  final consultRes = await http.get(
    Uri.parse('$baseUrl/consultations/'),
    headers: headers,
  ).timeout(const Duration(seconds: 30));
  print('Consultations status: ${consultRes.statusCode}');
  if (consultRes.statusCode == 200) {
    dynamic consultData = jsonDecode(consultRes.body);
    if (consultData is Map && consultData.containsKey('results')) {
      consultData = consultData['results'];
    }
    if (consultData is List) {
      print('Found ${consultData.length} consultations');
      for (final c in consultData) {
        final cid = c['id'] ?? c['consultation_id'] ?? '?';
        final status = c['status'] ?? '?';
        final appointment = c['appointment'] is Map ? c['appointment'] : {};
        final user = appointment['user'] is Map ? appointment['user'] : (c['user'] is Map ? c['user'] : {});
        final midwife = c['midwife'] is Map ? c['midwife'] : (appointment['midwife'] is Map ? appointment['midwife'] : {});
        final userId = user['id'] ?? user['user_id'] ?? (c['user_id'] ?? '?');
        final midwifeId = midwife['id'] ?? midwife['user_id'] ?? (c['midwife_id'] ?? '?');
        final userName = user['full_name'] ?? user['name'] ?? (c['user_full_name'] ?? '?');
        final midwifeName = midwife['full_name'] ?? midwife['name'] ?? (c['midwife_full_name'] ?? '?');
        print('  ID: $cid');
        print('    status: $status');
        print('    user: $userName ($userId)');
        print('    midwife: $midwifeName ($midwifeId)');
        print('    keys: ${c.keys.toList().take(20).toList()}');
      }
    } else {
      print('Unexpected response: ${consultRes.body}');
    }
  } else {
    print('Consultations failed: ${consultRes.body}');
  }
}