import 'package:flutter_test/flutter_test.dart';
import 'package:cagh_frontend/features/notifications/data/models/notification_model.dart';

void main() {
  group('NotificationModel Backend Deserialization Tests', () {
    test('Correctly maps backend OpenAPI schema fields into NotificationModel', () {
      final backendJson = {
        'id': 'b1c7a8e2-63b2-4d5e-9e7f-826f0edcaf82',
        'user': 'a5b3c2d1-0000-1111-2222-333344445555',
        'title': 'Consultation Confirmed',
        'body': 'Your appointment with Sister Sara has been approved.',
        'type': 'consultation',
        'action': 'view_appointment',
        'reference_id': 'apt-98765',
        'is_read': false,
        'created_at': '2026-10-22T14:30:00Z',
      };

      final model = NotificationModel.fromJson(backendJson);

      expect(model.id, equals('b1c7a8e2-63b2-4d5e-9e7f-826f0edcaf82'));
      expect(model.recipientId, equals('a5b3c2d1-0000-1111-2222-333344445555'));
      expect(model.title, equals('Consultation Confirmed'));
      expect(model.body, equals('Your appointment with Sister Sara has been approved.'));
      expect(model.type, equals('consultation'));
      expect(model.relatedType, equals('view_appointment'));
      expect(model.relatedId, equals('apt-98765'));
      expect(model.isRead, isFalse);
    });

    test('Correctly identifies read status across all valid backend representations', () {
      // 1. is_read boolean true
      final n1 = NotificationModel.fromJson({'id': '1', 'is_read': true});
      expect(n1.isRead, isTrue);

      // 2. is_read string 'true'
      final n2 = NotificationModel.fromJson({'id': '2', 'is_read': 'true'});
      expect(n2.isRead, isTrue);

      // 3. is_read integer 1
      final n3 = NotificationModel.fromJson({'id': '3', 'is_read': 1});
      expect(n3.isRead, isTrue);

      // 4. read boolean true
      final n4 = NotificationModel.fromJson({'id': '4', 'read': true});
      expect(n4.isRead, isTrue);

      // 5. status string 'READ'
      final n5 = NotificationModel.fromJson({'id': '5', 'status': 'READ'});
      expect(n5.isRead, isTrue);

      // 6. unread cases
      final n6 = NotificationModel.fromJson({'id': '6', 'is_read': false});
      expect(n6.isRead, isFalse);

      final n7 = NotificationModel.fromJson({'id': '7', 'is_read': 'false'});
      expect(n7.isRead, isFalse);

      final n8 = NotificationModel.fromJson({'id': '8', 'is_read': 0});
      expect(n8.isRead, isFalse);
    });

    test('Supports fallback body extraction from message and content fields', () {
      final jsonWithMessage = {
        'id': 'msg-1',
        'title': 'New Message',
        'message': 'Hello, how can I help you today?',
        'is_read': false,
      };
      final m1 = NotificationModel.fromJson(jsonWithMessage);
      expect(m1.body, equals('Hello, how can I help you today?'));

      final jsonWithContent = {
        'id': 'msg-2',
        'title': 'New Message',
        'content': 'Please verify your phone number.',
        'is_read': false,
      };
      final m2 = NotificationModel.fromJson(jsonWithContent);
      expect(m2.body, equals('Please verify your phone number.'));
    });
  });
}
