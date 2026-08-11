import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://cagh-backend-api.onrender.com/api/v1/auth/otp/send/');
  final payload = {
    'phone_number_or_email': 'ruthareda24@gmail.com',
    'purpose': 'REGISTRATION',
  };

  print('Sending request to backend...');
  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    ).timeout(Duration(seconds: 60));

    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
  } catch (e) {
    print('Error: $e');
  }
}
