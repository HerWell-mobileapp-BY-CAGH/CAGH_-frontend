import 'package:cagh_frontend/features/notifications/data/models/notification_model.dart';
import 'package:cagh_frontend/features/notifications/data/services/notification_api_service.dart';

class NotificationRepository {
  final NotificationApiService _apiService;

  NotificationRepository({NotificationApiService? apiService})
      : _apiService = apiService ?? NotificationApiService();

  Future<List<NotificationModel>> getNotifications() async {
    return await _apiService.fetchNotifications();
  }

  Future<int> getUnreadCount() async {
    return await _apiService.getUnreadCount();
  }

  Future<bool> markAsRead(String id) async {
    return await _apiService.markAsRead(id);
  }

  Future<bool> markAllAsRead() async {
    return await _apiService.markAllAsRead();
  }
}
