import 'dart:convert';
import 'package:http/http.dart' as http;

const baseUrl = 'https://cagh-backend-api.onrender.com/api/v1';
const midwifeId = 'b8d8c088-bf5e-4b3f-a4c4-2e78cea6b470';
const userId = 'e0ed50ba-b4b9-49ec-99f4-9ffc02dfbe8d';

Future<void> main() async {
  final loginRes = await http.post(
    Uri.parse('$baseUrl/auth/login/'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': 'bitsuan.abate@aastustudent.edu.et', 'password': 'zxcvbnm,'}),
  ).timeout(const Duration(seconds: 60));
  final loginData = jsonDecode(loginRes.body);
  final token = loginData['access'] ?? loginData['access_token'] ?? loginData['token'] ?? '';
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  final consultRes = await http.get(
    Uri.parse('$baseUrl/consultations/'),
    headers: headers,
  ).timeout(const Duration(seconds: 30));
  dynamic consultData = jsonDecode(consultRes.body);
  if (consultData is Map && consultData.containsKey('results')) {
    consultData = consultData['results'];
  }
  if (consultData is! List) {
    print('Unexpected: $consultRes.body');
    return;
  }

  print('Total consultations: ${consultData.length}');
  for (final c in consultData) {
    final cid = c['id'] ?? '?';
    final status = c['status'] ?? '?';

    final userDetail = c['user_detail'];
    final udId = userDetail is Map ? (userDetail['id'] ?? userDetail['user_id']) : null;
    final udEmail = userDetail is Map ? (userDetail['email'] ?? userDetail['username']) : null;
    final udName = userDetail is Map
        ? (userDetail['full_name'] ?? userDetail['name'] ?? userDetail['first_name'])
        : null;

    final matches = (udId?.toString() == userId) || (udEmail?.toString().toLowerCase() == 'bitsuanabate45@gmail.com');

    print('ID: $cid | status: $status | user_detail: $udName <$udEmail> ($udId) ${matches ? "  <<< MATCH" : ""}');

    if (matches && status == 'ACTIVE') {
      print('  voice_session: ${c['voice_session']}');
    }
  }
}