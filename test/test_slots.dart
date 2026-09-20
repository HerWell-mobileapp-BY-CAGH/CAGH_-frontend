import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final loginUrl = Uri.parse('https://cagh-backend-api.onrender.com/api/v1/auth/login/');
  final loginRes = await http.post(
    loginUrl,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'username': 'dilaminidilame_5c0b86',
      'password': 'password123',
    }),
  );
  
  print('Login username status: ${loginRes.statusCode}');
  print('Login username body: ${loginRes.body}');
}
