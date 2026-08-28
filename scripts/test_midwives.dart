import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('https://cagh-backend-api.onrender.com/api/v1/midwives/profiles/');

// ignore: avoid_print
  print('Fetching midwives from backend...');
  try {
    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    ).timeout(Duration(seconds: 30));

    // ignore: avoid_print
    print('Status Code: ${response.statusCode}');
    // ignore: avoid_print
    print('Response Body: ${response.body}');
  } catch (e) {
    // ignore: avoid_print
    print('Error: $e');
  }
}
