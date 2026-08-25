import 'package:cagh_frontend/features/appointments/data/services/appointment_api_service.dart';
import 'package:cagh_frontend/features/consultations/data/services/chat_api_service.dart';
import 'package:intl/intl.dart';

class NotificationGeneratorService {
  static Future<List<Map<String, dynamic>>> getMidwifeNotifications() async {
    List<Map<String, dynamic>> notifications = [];
    final aptApi = AppointmentApiService();

    try {
      // 1. Fetch appointments
      final apts = await aptApi.getMidwifeAppointments();
      for (var apt in apts) {
        final status = apt['status']?.toString().toUpperCase();
        if (status == 'PENDING' || status == 'REQUESTED') {
          notifications.add({
            'title': 'New Consultation Request',
            'body': 'Patient ${apt['user_full_name'] ?? 'Unknown'} has requested a new consultation.',
            'time': _formatTimeAgo(apt['created_at']),
            'isUnread': true,
            'type': 'APPOINTMENT',
            'rawDate': _parseDate(apt['created_at'] ?? DateTime.now().toIso8601String()),
          });
        } else if (status == 'CONFIRMED' || status == 'ACCEPTED') {
          // Upcoming reminder if within 2 days
          final dateStr = apt['appointment_date'];
          if (dateStr != null) {
            final aptDate = DateTime.tryParse(dateStr);
            if (aptDate != null && aptDate.isAfter(DateTime.now()) && aptDate.difference(DateTime.now()).inDays <= 2) {
              notifications.add({
                'title': 'Upcoming Consultation',
                'body': 'You have an upcoming consultation with ${apt['user_full_name'] ?? 'Patient'} on ${DateFormat('MMM d, h:mm a').format(aptDate)}.',
                'time': 'Upcoming',
                'isUnread': false,
                'type': 'APPOINTMENT',
                'rawDate': aptDate,
              });
            }
          }
        }
      }

      // 2. Fetch chats
      final chats = await ChatApiService.getChatRooms();
      for (var chat in chats) {
        final status = chat['status']?.toString().toUpperCase();
        if (status == 'REQUESTED') {
          notifications.add({
            'title': 'New Chat Request',
            'body': 'A patient has requested to chat with you.',
            'time': _formatTimeAgo(chat['created_at']),
            'isUnread': true,
            'type': 'CHAT',
            'rawDate': _parseDate(chat['created_at'] ?? DateTime.now().toIso8601String()),
          });
        } else if (status == 'ACCEPTED') {
          notifications.add({
            'title': 'Active Chat',
            'body': 'You have an active chat session.',
            'time': _formatTimeAgo(chat['updated_at'] ?? chat['created_at']),
            'isUnread': false,
            'type': 'CHAT',
            'rawDate': _parseDate(chat['updated_at'] ?? chat['created_at'] ?? DateTime.now().toIso8601String()),
          });
        }
      }
    } catch (e) {
      // Ignore errors silently for notifications
    }

    // Sort by most recent
    notifications.sort((a, b) => b['rawDate'].compareTo(a['rawDate']));
    return notifications;
  }

  static Future<List<Map<String, dynamic>>> getUserNotifications() async {
    List<Map<String, dynamic>> notifications = [];
    final aptApi = AppointmentApiService();

    try {
      // 1. Fetch appointments
      final apts = await aptApi.getUserAppointments();
      for (var apt in apts) {
        final status = apt['status']?.toString().toUpperCase();
        if (status == 'CONFIRMED' || status == 'ACCEPTED') {
          final dateStr = apt['appointment_date'];
          if (dateStr != null) {
            final aptDate = DateTime.tryParse(dateStr);
            if (aptDate != null && aptDate.isAfter(DateTime.now()) && aptDate.difference(DateTime.now()).inDays <= 2) {
              notifications.add({
                'title': 'Appointment Reminder',
                'body': 'Your consultation with ${apt['midwife_full_name'] ?? 'Midwife'} is coming up on ${DateFormat('MMM d, h:mm a').format(aptDate)}.',
                'time': 'Upcoming',
                'isUnread': true,
                'type': 'APPOINTMENT',
                'rawDate': aptDate,
              });
            }
          }
        }
      }

      // 2. Fetch chats
      final chats = await ChatApiService.getChatRooms();
      for (var chat in chats) {
        final status = chat['status']?.toString().toUpperCase();
        if (status == 'ACCEPTED') {
          notifications.add({
            'title': 'Chat Request Accepted',
            'body': 'A midwife has accepted your direct message request. You can now chat freely.',
            'time': _formatTimeAgo(chat['updated_at'] ?? chat['created_at']),
            'isUnread': true,
            'type': 'CHAT',
            'rawDate': _parseDate(chat['updated_at'] ?? chat['created_at'] ?? DateTime.now().toIso8601String()),
          });
        }
      }
    } catch (e) {
      // Ignore errors silently
    }

    notifications.sort((a, b) => b['rawDate'].compareTo(a['rawDate']));
    return notifications;
  }

  static DateTime _parseDate(String? dateStr) {
    if (dateStr == null) return DateTime.now();
    return DateTime.tryParse(dateStr) ?? DateTime.now();
  }

  static String _formatTimeAgo(String? dateStr) {
    if (dateStr == null) return 'Recently';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return 'Recently';

    final diff = DateTime.now().difference(date);
    if (diff.inDays > 1) return '${diff.inDays} days ago';
    if (diff.inDays == 1) return '1 day ago';
    if (diff.inHours > 1) return '${diff.inHours} hours ago';
    if (diff.inHours == 1) return '1 hour ago';
    if (diff.inMinutes > 1) return '${diff.inMinutes} mins ago';
    return 'Just now';
  }
}
