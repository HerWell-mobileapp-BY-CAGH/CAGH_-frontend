import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  // We don't know the exact midwife ID, so let's fetch profiles first.
  final profilesUrl = Uri.parse('https://cagh-backend-api.onrender.com/api/v1/midwives/profiles/');
  final res = await http.get(profilesUrl);
  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    if (data.isNotEmpty) {
      final midwifeId = data[0]['id'];
      print('Found Midwife: $midwifeId');
      
      final slotsUrl = Uri.parse('https://cagh-backend-api.onrender.com/api/v1/appointments/time-slots/?midwife_id=$midwifeId&date=2026-08-13');
      print('Fetching slots from: $slotsUrl');
      final slotRes = await http.get(slotsUrl);
      print('Status: ${slotRes.statusCode}');
      print('Body: ${slotRes.body}');
    } else {
      print('No midwives found.');
    }
  } else {
    print('Failed to fetch midwives: ${res.statusCode}');
  }
}
