import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://cagh-backend-api.onrender.com/api/v1/auth/login/');
  final payload = {
    'email': 'test@gmail.com',
    'password': '!1234abcd#'
  };

// ignore: avoid_print
  print('Sending request to backend...');
  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    ).timeout(Duration(seconds: 60));

    // ignore: avoid_print
    print('Status Code: ${response.statusCode}');
    // ignore: avoid_print
    print('Response Body: ${response.body}');
  } catch (e) {
    // ignore: avoid_print
    print('Error: $e');
  }
}
