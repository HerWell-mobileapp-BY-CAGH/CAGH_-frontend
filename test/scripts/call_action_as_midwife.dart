import 'dart:convert';
import 'package:http/http.dart' as http;

const baseUrl = 'https://cagh-backend-api.onrender.com/api/v1';
const consultationId = '2f5f2667-4c39-4130-98d8-3a50d021d9d7';

Future<void> main(List<String> args) async {
  final action = args.isNotEmpty ? args[0] : 'start';

  final email = const String.fromEnvironment('MIDWIFE_EMAIL', defaultValue: '');
  final password = const String.fromEnvironment('MIDWIFE_PASSWORD', defaultValue: '');

  final loginRes = await http.post(
    Uri.parse('$baseUrl/auth/login/'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': password}),
  ).timeout(const Duration(seconds: 60));
  final loginData = jsonDecode(loginRes.body);
  final token = loginData['access'] ?? loginData['access_token'] ?? loginData['token'] ?? '';
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  final url = '$baseUrl/consultations/$consultationId/voice-session/$action/';
  print('>>> POST $url (as midwife b8d8c088)');
  final res = await http.post(
    Uri.parse(url),
    headers: headers,
  ).timeout(const Duration(seconds: 60));
  print('<<< status=${res.statusCode}');
  print('<<< body=${res.body}');
}