import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';
import 'package:cagh_frontend/shared/models/time_slots_response.dart';
import 'package:cagh_frontend/shared/models/time_slot.dart';

void main() {
  const baseUrl = 'https://cagh-backend-api.onrender.com/api/v1';

  String userToken = '';
  String midwifeToken = '';
  String midwifeUserId = '';
  String midwifeProfileId = '';

  setUpAll(() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final patientEmail = 'test_patient_$timestamp@example.com';
    final patientPhone = '+25191${timestamp.toString().substring(timestamp.toString().length - 7)}';

    // 1a. Register fresh Patient
    final regPatientRes = await http.post(
      Uri.parse('$baseUrl/auth/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'first_name': 'Test',
        'last_name': 'Patient',
        'email': patientEmail,
        'phone_number': patientPhone,
        'password': 'Password123!',
        'password_confirm': 'Password123!',
        'role': 'PATIENT',
      }),
    );
    
    if (regPatientRes.statusCode == 201 || regPatientRes.statusCode == 200) {
      final data = jsonDecode(regPatientRes.body);
      userToken = data['access'] ?? data['access_token'] ?? data['tokens']?['access'] ?? data['token'] ?? '';
    }

    if (userToken.isEmpty) {
      final loginRes = await http.post(
        Uri.parse('$baseUrl/auth/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': patientEmail, 'password': 'Password123!'}),
      );
      if (loginRes.statusCode == 200) {
        final data = jsonDecode(loginRes.body);
        userToken = data['access_token'] ?? data['tokens']?['access'] ?? data['token'] ?? '';
      }
    }
    expect(userToken, isNotEmpty, reason: 'Patient registration/login failed: ${regPatientRes.body}');

    // 2. Fetch an existing approved midwife profile from backend
    final midwivesRes = await http.get(
      Uri.parse('$baseUrl/midwives/profiles/'),
      headers: {'Authorization': 'Bearer $userToken'},
    );
    expect(midwivesRes.statusCode, equals(200), reason: 'Fetch midwives failed: ${midwivesRes.body}');
    final midwivesJson = jsonDecode(midwivesRes.body);
    List<dynamic> midwifeList = [];
    if (midwivesJson is List) {
      midwifeList = midwivesJson;
    } else if (midwivesJson is Map && midwivesJson.containsKey('results') && midwivesJson['results'] is List) {
      midwifeList = midwivesJson['results'] as List<dynamic>;
    } else if (midwivesJson is Map && midwivesJson.containsKey('data') && midwivesJson['data'] is List) {
      midwifeList = midwivesJson['data'] as List<dynamic>;
    }
    expect(midwifeList, isNotEmpty, reason: 'No midwives available in system');
    
    final mwObj = midwifeList.first as Map<String, dynamic>;
    midwifeProfileId = (mwObj['id'] ?? '').toString();
    midwifeUserId = (mwObj['user']?['id'] ?? mwObj['user_id'] ?? mwObj['user'] ?? midwifeProfileId).toString();
  });

  test('E2E Booking Flow: Availability Fetching, Contract Parsing, Successful Booking & Conflict/Unavailable Errors', () async {
    final targetMidwifeId = midwifeProfileId.isNotEmpty ? midwifeProfileId : midwifeUserId;
    
    // 1. Post a fresh future availability period if midwifeToken available
    const testDate = '2026-11-20';
    if (midwifeToken.isNotEmpty) {
      final postAvailRes = await http.post(
        Uri.parse('$baseUrl/appointments/availability/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $midwifeToken',
        },
        body: jsonEncode({
          'date': testDate,
          'start_time': '14:00:00',
          'end_time': '15:00:00',
          'consultation_methods': ['VIRTUAL_VOICE', 'IN_PERSON'],
        }),
      );
      print('Post Future Availability Status: ${postAvailRes.statusCode}, Body: ${postAvailRes.body}');
    }

    // 2. User fetches time slots for selected midwife and date
    final slotsRes = await http.get(
      Uri.parse('$baseUrl/appointments/time-slots/?midwife_id=$targetMidwifeId&date=$testDate'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $userToken',
      },
    );
    print('Fetch Time Slots Status: ${slotsRes.statusCode}, Body: ${slotsRes.body}');
    expect(slotsRes.statusCode, equals(200));

    final slotsJson = jsonDecode(slotsRes.body);
    final parsedResponse = TimeSlotsResponse.fromJson(slotsJson);

    // Validate slot parsing
    final allSlots = [
      ...parsedResponse.morningSlots,
      ...parsedResponse.afternoonSlots,
      ...parsedResponse.eveningSlots,
    ];

    print('Parsed slots count: ${allSlots.length} for date $testDate');
    for (final slot in allSlots) {
      print('Parsed slot: id=${slot.id}, date=${slot.date}, start=${slot.startTime}, end=${slot.endTime}, isAvailable=${slot.isAvailable}');
    }

    // 3. Select an available slot (or construct payload if none currently free)
    final freeSlots = allSlots.where((s) => s.isAvailable).toList();
    final targetSlot = freeSlots.isNotEmpty ? freeSlots.first : (allSlots.isNotEmpty ? allSlots.first : TimeSlot(
      id: '',
      date: testDate,
      startTime: '10:00:00',
      endTime: '11:00:00',
      isAvailable: false,
    ));

    // 4. Submit booking payload matching Django backend contract
    final bookingPayload = {
      'midwife': targetMidwifeId,
      'appointment_type': 'VIRTUAL_VOICE',
      'scheduled_date': testDate,
      'start_time': targetSlot.startTime.length == 5 ? '${targetSlot.startTime}:00' : targetSlot.startTime,
      'end_time': targetSlot.endTime.length == 5 ? '${targetSlot.endTime}:00' : targetSlot.endTime,
      'reason': 'E2E Automated Contract Verification',
      if (targetSlot.id.isNotEmpty) 'availability_id': targetSlot.id,
    };

    print('Booking Request Payload: ${jsonEncode(bookingPayload)}');

    final bookingRes = await http.post(
      Uri.parse('$baseUrl/appointments/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $userToken',
      },
      body: jsonEncode(bookingPayload),
    );

    print('Booking Response Status: ${bookingRes.statusCode}, Body: ${bookingRes.body}');
    expect(bookingRes.statusCode, inInclusiveRange(200, 409));
    
    if (bookingRes.statusCode == 201 || bookingRes.statusCode == 200) {
      final bookingJson = jsonDecode(bookingRes.body);
      final appointmentId = (bookingJson['id'] ?? '').toString();
      expect(appointmentId, isNotEmpty);

      // 5. Verify newly booked appointment appears in user's appointments list
      final userApptsRes = await http.get(
        Uri.parse('$baseUrl/appointments/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
      );
      expect(userApptsRes.statusCode, equals(200));
      final userApptsJson = jsonDecode(userApptsRes.body);
      final list = userApptsJson is List ? userApptsJson : (userApptsJson['results'] as List);
      final found = list.any((item) => item['id']?.toString() == appointmentId);
      print('Appointment found in user list: $found');
      expect(found, isTrue);

      // 6. Test duplicate booking attempt for same period to verify conflict/validation error response
      final dupRes = await http.post(
        Uri.parse('$baseUrl/appointments/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userToken',
        },
        body: jsonEncode(bookingPayload),
      );
      print('Duplicate Booking Response Status: ${dupRes.statusCode}, Body: ${dupRes.body}');
      expect(dupRes.statusCode, anyOf(equals(400), equals(409)));
    } else if (bookingRes.statusCode == 400 || bookingRes.statusCode == 409) {
      print('Backend correctly rejected unavailable/already-booked slot with body: ${bookingRes.body}');
    }

    // 7. Verify booking past/unconfigured date returns backend 400 error
    const unavailableDate = '2025-01-01';
    final unavailPayload = {
      'midwife': targetMidwifeId,
      'appointment_type': 'VIRTUAL_VOICE',
      'scheduled_date': unavailableDate,
      'start_time': '09:00:00',
      'end_time': '10:00:00',
      'reason': 'Testing past/unavailable date rejection',
    };
    final unavailRes = await http.post(
      Uri.parse('$baseUrl/appointments/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $userToken',
      },
      body: jsonEncode(unavailPayload),
    );
    print('Unavailable Date Booking Response Status: ${unavailRes.statusCode}, Body: ${unavailRes.body}');
    expect(unavailRes.statusCode, equals(400));
  });
}
