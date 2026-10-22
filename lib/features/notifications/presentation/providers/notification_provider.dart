import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  static const String _prefsKeyReadSynthetic = 'read_synthetic_notifications';

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
      final prefs = await SharedPreferences.getInstance();
      final readSyntheticIds = (prefs.getStringList(_prefsKeyReadSynthetic) ?? []).toSet();

      // 1. Fetch backend notifications, chat rooms, and user profile concurrently
      final results = await Future.wait([
        _repository.getNotifications().catchError((_) => <NotificationModel>[]),
        ChatApiService.getChatRooms().catchError((_) => <Map<String, dynamic>>[]),
        AuthService.getUserData().catchError((_) => <String, dynamic>{}),
      ]);

      final backendNotifications = results[0] as List<NotificationModel>;
      final chatRooms = results[1] as List<dynamic>;
      final userData = results[2] as Map<String, dynamic>;

      // 2. Compute unread chat messages & notification items
      int totalUnreadMessages = 0;
      final List<NotificationModel> chatNotifications = [];
      for (var room in chatRooms) {
        final int roomUnread = int.tryParse(room['unread_count']?.toString() ?? '') ?? 0;
        totalUnreadMessages += roomUnread;

        if (roomUnread > 0) {
          final roomId = room['id']?.toString() ?? '';
          final synId = 'chat_$roomId';
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
              id: synId,
              recipientId: '',
              type: 'message',
              title: partnerName,
              body: preview,
              isRead: readSyntheticIds.contains(synId),
              createdAt: msgTime,
              relatedId: roomId,
              relatedType: 'conversation',
            ),
          );
        }
      }

      // 3. Fetch appointments for upcoming consultations and pending requests
      int totalUpcoming = 0;
      final List<NotificationModel> appointmentNotifications = [];
      try {
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

            // Only synthesize an immediate reminder notification if consultation starts within next 2 hours
            DateTime? startDt;
            try {
              final parts = apt.date.split('-');
              if (parts.length >= 3) {
                final y = int.parse(parts[0]);
                final m = int.parse(parts[1]);
                final d = int.parse(parts[2]);
                int hr = 0, min = 0;
                if (apt.startTime.isNotEmpty) {
                  final tp = apt.startTime.split(':');
                  if (tp.length >= 2) {
                    hr = int.parse(tp[0]);
                    min = int.parse(tp[1]);
                  }
                }
                startDt = DateTime(y, m, d, hr, min);
              }
            } catch (_) {}

            if (startDt != null) {
              final diff = startDt.difference(now);
              if (diff.inMinutes >= 0 && diff.inMinutes <= 120) {
                final synId = 'apt_soon_${apt.appointmentId}';
                final isRead = readSyntheticIds.contains(synId);
                String partnerName = userType == 'MIDWIFE' 
                    ? (apt.userFullName ?? 'Patient') 
                    : (apt.midwifeName ?? 'Midwife');

                appointmentNotifications.add(
                  NotificationModel(
                    id: synId,
                    recipientId: '',
                    type: 'consultation_upcoming',
                    title: 'Upcoming Consultation in ${diff.inMinutes} mins',
                    body: '$partnerName • Today at ${apt.startTime}',
                    isRead: isRead,
                    createdAt: apt.createdAt ?? now,
                    relatedId: apt.appointmentId,
                    relatedType: 'consultation',
                  ),
                );
              }
            }
          } else if (apt.status == AppointmentStatus.pending && userType == 'MIDWIFE') {
            // Pending requests are genuine actionable notifications for midwives
            final synId = 'apt_req_${apt.appointmentId}';
            final isRead = readSyntheticIds.contains(synId);
            appointmentNotifications.add(
              NotificationModel(
                id: synId,
                recipientId: '',
                type: 'consultation_request',
                title: 'New Consultation Request',
                body: '${apt.userFullName ?? "Patient"} requested ${apt.date} at ${apt.startTime}',
                isRead: isRead,
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

      // 4. Combine notifications into unified list
      final Map<String, NotificationModel> mergedMap = {};
      
      // Backend notifications first (genuine server alerts)
      for (var n in backendNotifications) {
        mergedMap[n.id] = n;
      }
      
      // Merge chat notifications
      for (var n in chatNotifications) {
        mergedMap[n.id] = n;
      }

      // Merge urgent consultation notifications
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

      // Persist synthetic notification read status locally
      if (id.startsWith('chat_') || id.startsWith('apt_')) {
        final prefs = await SharedPreferences.getInstance();
        final readList = prefs.getStringList(_prefsKeyReadSynthetic) ?? [];
        if (!readList.contains(id)) {
          readList.add(id);
          await prefs.setStringList(_prefsKeyReadSynthetic, readList);
        }
      } else {
        // Backend notification: sync read status to server
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

    // Save all synthetic notifications as read in SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final readSet = (prefs.getStringList(_prefsKeyReadSynthetic) ?? []).toSet();
    for (var n in currentNotifications) {
      if (n.id.startsWith('chat_') || n.id.startsWith('apt_')) {
        readSet.add(n.id);
      }
    }
    await prefs.setStringList(_prefsKeyReadSynthetic, readSet.toList());

    // Mark all read in backend
    await _repository.markAllAsRead();
  }
}
