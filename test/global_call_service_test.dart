import 'package:flutter_test/flutter_test.dart';
import 'package:cagh_frontend/core/services/global_call_service.dart';

void main() {
  group('GlobalCallService ID & Name Extraction Tests', () {
    test('extractId resolves correctly across string and map values', () {
      expect(GlobalCallService.extractId('123'), '123');
      expect(GlobalCallService.extractId({'id': '456'}), '456');
      expect(GlobalCallService.extractId({'user_id': '789'}), '789');
      expect(GlobalCallService.extractId(null), '');
      expect(GlobalCallService.extractId(''), '');
    });

    test('extractPersonName resolves caller and receiver names cleanly', () {
      final callerData = {
        'sender_name': 'Sarah Connor',
        'receiver_name': 'John Doe',
      };

      expect(
        GlobalCallService.extractPersonName(callerData, isSender: true),
        'Sarah Connor',
      );
      expect(
        GlobalCallService.extractPersonName(callerData, isSender: false),
        'John Doe',
      );
    });
  });
}
