import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cagh_frontend/features/notifications/data/models/notification_model.dart';
import 'package:cagh_frontend/features/notifications/data/repositories/notification_repository.dart';
import 'package:cagh_frontend/features/consultations/data/services/chat_api_service.dart';
import 'package:cagh_frontend/features/appointments/data/repositories/appointment_repository_impl.dart';
import 'package:cagh_frontend/features/appointments/data/services/appointment_api_service.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:cagh_frontend/shared/models/appointment.dart';

class NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final int unreadMessagesCount;
  final int upcomingAppointmentsCount;
  final bool isLoading;
  final String? error;

  NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.unreadMessagesCount = 0,
    this.upcomingAppointmentsCount = 0,
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    int? unreadMessagesCount,
    int? upcomingAppointmentsCount,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      unreadMessagesCount: unreadMessagesCount ?? this.unreadMessagesCount,
      upcomingAppointmentsCount: upcomingAppointmentsCount ?? this.upcomingAppointmentsCount,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

final notificationProvider = StateNotifierProvider<NotificationStateNotifier, NotificationState>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return NotificationStateNotifier(repository);
});

class NotificationStateNotifier extends StateNotifier<NotificationState> {
  final NotificationRepository _repository;
  final AppointmentRepositoryImpl _appointmentRepository =
      AppointmentRepositoryImpl(AppointmentApiService());

  NotificationStateNotifier(this._repository) : super(NotificationState()) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    await _fetchAndSynthesize();
  }

  Future<void> refreshNotifications() async {
    await _fetchAndSynthesize(isSilent: true);
  }

  Future<void> _fetchAndSynthesize({bool isSilent = false}) async {
    try {
      // 1. Fetch backend notifications & unread count
      final backendNotifications = await _repository.getNotifications();
      final backendUnreadCount = await _repository.getUnreadCount();

      // 2. Fetch Chat Rooms & compute unread messages
      int totalUnreadMessages = 0;
      final List<NotificationModel> chatNotifications = [];
      try {
        final chatRooms = await ChatApiService.getChatRooms();
        for (var room in chatRooms) {
          final int roomUnread = int.tryParse(room['unread_count']?.toString() ?? '') ?? 0;
          totalUnreadMessages += roomUnread;

          if (roomUnread > 0) {
            final roomId = room['id']?.toString() ?? '';
            // Determine partner name (midwife for patient, patient for midwife)
            final mw = room['midwife_detail'] ?? room['midwife'];
            final user = room['user_detail'] ?? room['user'] ?? room['patient'];
            String partnerName = 'Healthcare Provider';
            if (mw is Map && (mw['full_name'] != null || mw['name'] != null)) {
              partnerName = mw['full_name'] ?? mw['name'];
            } else if (user is Map && (user['full_name'] != null || user['first_name'] != null)) {
              partnerName = user['full_name'] ?? "${user['first_name']} ${user['last_name'] ?? ''}".trim();
            }

            String preview = 'You have $roomUnread new message(s)';
            DateTime msgTime = DateTime.now();
            if (room['latest_message'] is Map) {
              final lm = room['latest_message'];
              final content = lm['content'] ?? lm['text'] ?? '';
              if (content.toString().isNotEmpty) {
                preview = content.toString();
              }
              final createdStr = lm['created_at'] ?? lm['sent_at'];
              if (createdStr != null) {
                msgTime = DateTime.tryParse(createdStr.toString())?.toLocal() ?? DateTime.now();
              }
            }

            chatNotifications.add(
              NotificationModel(
                id: 'chat_$roomId',
                recipientId: '',
                type: 'message',
                title: partnerName,
                body: preview,
                isRead: false,
                createdAt: msgTime,
                relatedId: roomId,
                relatedType: 'conversation',
              ),
            );
          }
        }
      } catch (_) {
        // Chat rooms fetch fallback
      }

      // 3. Fetch user/midwife appointments to compute upcoming consultation events
      int totalUpcoming = 0;
      final List<NotificationModel> appointmentNotifications = [];
      try {
        final userData = await AuthService.getUserData();
        final userType = (userData['user_type'] ?? userData['role'] ?? 'USER').toString().toUpperCase();
        
        List<Appointment> appointments = [];
        if (userType == 'MIDWIFE') {
          appointments = await _appointmentRepository.getMidwifeAppointments();
        } else {
          appointments = await _appointmentRepository.getUserAppointments();
        }

        final now = DateTime.now();
        for (var apt in appointments) {
          if (apt.status == AppointmentStatus.confirmed && !apt.isPast) {
            totalUpcoming++;

            // Create notification item if within 48 hours or upcoming
            String partnerName = userType == 'MIDWIFE' 
                ? (apt.userFullName ?? 'Patient') 
                : (apt.midwifeName ?? 'Midwife');
            
            String title = '$partnerName • Virtual Consultation';
            String body = '${apt.date} at ${apt.startTime}';
            if (apt.reason != null && apt.reason!.isNotEmpty) {
              body = '$body (${apt.reason})';
            }

            appointmentNotifications.add(
              NotificationModel(
                id: 'apt_${apt.appointmentId}',
                recipientId: '',
                type: 'consultation_upcoming',
                title: title,
                body: body,
                isRead: false,
                createdAt: apt.createdAt ?? now,
                relatedId: apt.appointmentId,
                relatedType: 'consultation',
              ),
            );
          } else if (apt.status == AppointmentStatus.pending && userType == 'MIDWIFE') {
            appointmentNotifications.add(
              NotificationModel(
                id: 'apt_req_${apt.appointmentId}',
                recipientId: '',
                type: 'consultation_request',
                title: 'New Consultation Request',
                body: '${apt.userFullName ?? "Patient"} requested ${apt.date} at ${apt.startTime}',
                isRead: false,
                createdAt: apt.createdAt ?? now,
                relatedId: apt.appointmentId,
                relatedType: 'consultation',
              ),
            );
          }
        }
      } catch (_) {
        // Appointments fetch fallback
      }

      // 4. Combine backend notifications + dynamic real-time synthesized notifications
      final Map<String, NotificationModel> mergedMap = {};
      
      // Add backend items first
      for (var n in backendNotifications) {
        mergedMap[n.id] = n;
      }
      
      // Merge chat notifications (override or add if unread exists)
      for (var n in chatNotifications) {
        mergedMap[n.id] = n;
      }

      // Merge consultation notifications
      for (var n in appointmentNotifications) {
        mergedMap[n.id] = n;
      }

      final mergedList = mergedMap.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final effectiveUnreadCount = mergedList.where((n) => !n.isRead).length;

      state = state.copyWith(
        notifications: mergedList,
        unreadCount: effectiveUnreadCount,
        unreadMessagesCount: totalUnreadMessages,
        upcomingAppointmentsCount: totalUpcoming,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> markAsRead(String id) async {
    final currentNotifications = [...state.notifications];
    final index = currentNotifications.indexWhere((n) => n.id == id);

    if (index != -1 && !currentNotifications[index].isRead) {
      currentNotifications[index] = currentNotifications[index].copyWith(isRead: true);
      final newUnreadCount = currentNotifications.where((n) => !n.isRead).length;

      state = state.copyWith(
        notifications: currentNotifications,
        unreadCount: newUnreadCount,
      );

      // If it's a backend notification id (not synthetic chat/apt prefix), sync with backend
      if (!id.startsWith('chat_') && !id.startsWith('apt_')) {
        await _repository.markAsRead(id);
      }
    }
  }

  Future<void> markAllAsRead() async {
    final currentNotifications =
        state.notifications.map((n) => n.copyWith(isRead: true)).toList();

    state = state.copyWith(
      notifications: currentNotifications,
      unreadCount: 0,
    );

    await _repository.markAllAsRead();
  }
}
