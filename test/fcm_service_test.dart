import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cagh_frontend/core/services/fcm_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FcmService Token Registration & Refresh Tests', () {
    setUp(() async {
      dotenv.testLoad(fileInput: 'API_URL=http://localhost:8000/api/v1');
      SharedPreferences.setMockInitialValues({
        'auth_token': 'fake_jwt_token_123',
        'user_data': '{"id": "user_789", "role": "MIDWIFE"}',
        'last_registered_fcm_token_user_789': 'token_abc_123',
      });
    });

    test('registerDeviceToken dispatches HTTP POST when user is authenticated', () async {
      int postCount = 0;
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/notifications/register-device/')) {
          postCount++;
          expect(request.headers['Authorization'], contains('fake_jwt_token_123'));
          expect(request.body, contains('test_fcm_token_xyz'));
          return http.Response('{"status": "ok"}', 200);
        }
        return http.Response('Not Found', 404);
      });

      await FcmService.registerDeviceToken(
        overrideToken: 'test_fcm_token_xyz',
        force: true,
        httpClient: mockClient,
      );

      expect(postCount, 1);
    });

    test('registerDeviceToken respects force parameter and re-dispatches backend registration', () async {
      int postCount = 0;
      final mockClient = MockClient((request) async {
        postCount++;
        return http.Response('{"status": "ok"}', 200);
      });

      // 1. Forced registration dispatches POST request even if token is cached
      await FcmService.registerDeviceToken(
        overrideToken: 'token_abc_123',
        force: true,
        httpClient: mockClient,
      );
      expect(postCount, 1);

      // 2. Forced registration dispatches again to reactivate token on backend
      await FcmService.registerDeviceToken(
        overrideToken: 'token_abc_123',
        force: true,
        httpClient: mockClient,
      );
      expect(postCount, 2);
    });

    test('registerDeviceToken skips execution when user is not logged in', () async {
      SharedPreferences.setMockInitialValues({});
      int postCount = 0;
      final mockClient = MockClient((request) async {
        postCount++;
        return http.Response('{"status": "ok"}', 200);
      });

      await FcmService.registerDeviceToken(
        overrideToken: 'test_token',
        force: true,
        httpClient: mockClient,
      );

      expect(postCount, 0);
    });
  });
}
