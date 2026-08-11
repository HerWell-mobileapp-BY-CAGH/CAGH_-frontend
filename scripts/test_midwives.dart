import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://cagh-backend-api.onrender.com/api/v1/midwives/profiles/');

  print('Fetching midwives from backend...');
  try {
    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    ).timeout(Duration(seconds: 30));

    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');
  } catch (e) {
    print('Error: $e');
  }
}
