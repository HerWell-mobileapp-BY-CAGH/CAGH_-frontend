import 'dart:convert';
import 'package:http/http.dart' as http;

const baseUrl = 'https://cagh-backend-api.onrender.com/api/v1';

Future<void> main() async {
  // Step 1: Login
  print('=== STEP 1: Login ===');
  final email = const String.fromEnvironment('USER_EMAIL', defaultValue: '');
  final password = const String.fromEnvironment('USER_PASSWORD', defaultValue: '');

  final loginRes = await http.post(
    Uri.parse('$baseUrl/auth/login/'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': password}),
  ).timeout(const Duration(seconds: 60));

  print('Login status: ${loginRes.statusCode}');
  if (loginRes.statusCode != 200) {
    print('Login failed: ${loginRes.body}');
    return;
  }

  final loginData = jsonDecode(loginRes.body);
  print('Login keys: ${loginData.keys.toList()}');

  // Extract token from various possible keys
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

  // Step 2: Get user info
  print('\n=== STEP 2: Get User Info ===');
  final userRes = await http.get(
    Uri.parse('$baseUrl/users/me/'),
    headers: headers,
  ).timeout(const Duration(seconds: 30));
  print('User info status: ${userRes.statusCode}');
  if (userRes.statusCode == 200) {
    final userData = jsonDecode(userRes.body);
    print('User ID: ${userData['id'] ?? userData['user_id'] ?? userData['uid'] ?? 'unknown'}');
    print('User keys: ${userData.keys.toList()}');
  } else {
    print('User info failed: ${userRes.body}');
  }

  // Step 3: List consultations
  print('\n=== STEP 3: List Consultations ===');
  final consultRes = await http.get(
    Uri.parse('$baseUrl/consultations/'),
    headers: headers,
  ).timeout(const Duration(seconds: 30));
  print('Consultations status: ${consultRes.statusCode}');
  if (consultRes.statusCode == 200) {
    final consultData = jsonDecode(consultRes.body);
    if (consultData is List) {
      print('Found ${consultData.length} consultations');
      for (final c in consultData.take(3)) {
        print('  ID: ${c['id']}, status: ${c['status']}, appointment: ${c['appointment']}');
      }
    } else if (consultData is Map && consultData.containsKey('results')) {
      final results = consultData['results'] as List;
      print('Found ${results.length} consultations (paginated)');
      for (final c in results.take(3)) {
        print('  ID: ${c['id']}, status: ${c['status']}, appointment: ${c['appointment']}');
      }
    } else {
      print('Unexpected response structure: ${consultData.keys.toList()}');
      print('Body: ${consultRes.body}');
    }
  } else {
    print('Consultations failed: ${consultRes.body}');
  }

  // Step 4: Test voice-session token endpoint with a dummy consultation
  print('\n=== STEP 4: Test Voice-Session Token Endpoint ===');
  final testIds = ['2f5f2667-4c39-4130-98d8-3a50d021d9d7', '0e4e8394-fb6a-4c32-b099-81652935a508', '1e2bb605-4474-4279-9e0a-993627170ef5'];
  for (final id in testIds) {
    print('\n--- Testing consultation ID: $id ---');

    // Test start endpoint
    final startUrl = '$baseUrl/consultations/$id/voice-session/start/';
    print('POST $startUrl');
    final startRes = await http.post(
      Uri.parse(startUrl),
      headers: headers,
    ).timeout(const Duration(seconds: 30));
    print('Start status: ${startRes.statusCode}');
    print('Start body: ${startRes.body}');

    // Test token endpoint
    final tokenUrl = '$baseUrl/consultations/$id/voice-session/token/';
    print('POST $tokenUrl');
    final tokenRes = await http.post(
      Uri.parse(tokenUrl),
      headers: headers,
    ).timeout(const Duration(seconds: 30));
    print('Token status: ${tokenRes.statusCode}');
    print('Token body: ${tokenRes.body}');

    if (tokenRes.statusCode == 200 || tokenRes.statusCode == 201) {
      final tokenData = jsonDecode(tokenRes.body);
      print('\n=== VOICE SESSION RESPONSE ANALYSIS ===');
      print('Top-level keys: ${tokenData.keys.toList()}');
      print('Full response: ${const JsonEncoder.withIndent('  ').convert(tokenData)}');

      // Check each credential field
      final voiceSession = tokenData['voice_session'] ?? tokenData['consultation']?['voice_session'] ?? tokenData;
      print('\nVoice session object keys: ${voiceSession is Map ? voiceSession.keys.toList() : "not a map"}');

      final channelName = tokenData['channel_name'] ?? voiceSession['channel_name'] ?? '';
      final sessionKey = tokenData['session_key'] ?? tokenData['call_id'] ?? voiceSession['session_key'] ?? voiceSession['call_id'] ?? '';
      final uidRaw = tokenData['uid'] ?? voiceSession['uid'] ?? 0;

      print('\n=== PARSED CREDENTIALS ===');
      print('Session Key: "${sessionKey.toString()}" (length: ${sessionKey.toString().length})');
      print('Channel: "${channelName.toString()}" (length: ${channelName.toString().length})');
      print('UID: $uidRaw (parsed: ${int.tryParse(uidRaw.toString()) ?? 0})');

      // Validate
      print('\n=== VALIDATION ===');
      if (sessionKey.toString().isEmpty) {
        print('ERROR: Session Key is EMPTY!');
      } else {
        print('OK: Session Key present');
      }
      if (channelName.toString().isEmpty) {
        print('WARNING: Channel name is EMPTY - frontend will use fallback cagh_voice_{id}');
      } else {
        print('OK: Channel name present');
      }
      final uid = int.tryParse(uidRaw.toString()) ?? 0;
      if (uid == 0) {
        print('ERROR: UID is 0 or unparseable!');
      } else {
        print('OK: UID = $uid');
      }

      break; // Stop after first successful response
    }
  }
}
