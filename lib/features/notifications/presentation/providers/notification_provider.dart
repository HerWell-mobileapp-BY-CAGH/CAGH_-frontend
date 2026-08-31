import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cagh_frontend/features/notifications/data/models/notification_model.dart';
import 'package:cagh_frontend/features/notifications/data/repositories/notification_repository.dart';

class NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
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

  NotificationStateNotifier(this._repository) : super(NotificationState()) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final notifications = await _repository.getNotifications();
      final unreadCount = await _repository.getUnreadCount();
      
      // If the backend doesn't properly return unreadCount via the dedicated endpoint, 
      // we can fallback to calculating it locally from the loaded notifications:
      final localUnreadCount = unreadCount > 0 
          ? unreadCount 
          : notifications.where((n) => !n.isRead).length;

      state = state.copyWith(
        notifications: notifications,
        unreadCount: localUnreadCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refreshNotifications() async {
    // Silently refresh without triggering full loading UI
    try {
      final notifications = await _repository.getNotifications();
      final unreadCount = await _repository.getUnreadCount();
      
      final localUnreadCount = unreadCount > 0 
          ? unreadCount 
          : notifications.where((n) => !n.isRead).length;

      state = state.copyWith(
        notifications: notifications,
        unreadCount: localUnreadCount,
        error: null,
      );
    } catch (e) {
      // Keep old state on silent refresh failure
    }
  }

  Future<void> markAsRead(String id) async {
    // Optimistic UI update
    final currentNotifications = [...state.notifications];
    final index = currentNotifications.indexWhere((n) => n.id == id);
    
    if (index != -1 && !currentNotifications[index].isRead) {
      currentNotifications[index] = currentNotifications[index].copyWith(isRead: true);
      final newUnreadCount = (state.unreadCount - 1).clamp(0, 9999);
      
      state = state.copyWith(
        notifications: currentNotifications,
        unreadCount: newUnreadCount,
      );
      
      // Perform API call
      final success = await _repository.markAsRead(id);
      if (!success) {
        // Revert on failure (could be omitted depending on UX preferences)
        refreshNotifications();
      }
    }
  }

  Future<void> markAllAsRead() async {
    // Optimistic UI update
    final currentNotifications = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    
    state = state.copyWith(
      notifications: currentNotifications,
      unreadCount: 0,
    );
    
    // Perform API call
    final success = await _repository.markAllAsRead();
    if (!success) {
      refreshNotifications();
    }
  }
}
