import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cagh_frontend/features/consultations/data/services/chat_api_service.dart';

final chatNotificationProvider = StateNotifierProvider<ChatNotificationNotifier, Map<String, int>>((ref) {
  return ChatNotificationNotifier();
});

class ChatNotificationNotifier extends StateNotifier<Map<String, int>> {
  Timer? _timer;

  ChatNotificationNotifier() : super({}) {
    _startPolling();
  }

  void _startPolling() {
    _fetchUnreadCounts();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchUnreadCounts();
    });
  }

  Future<void> _fetchUnreadCounts() async {
    try {
      final rooms = await ChatApiService.getChatRooms();
      Map<String, int> newCounts = {};
      
      for (var room in rooms) {
        if (room is Map) {
          // Identify room by ID or participant ID
          // The Chat API response typically contains 'id', 'unread_count' or similar fields.
          String roomId = room['id']?.toString() ?? '';
          
          // Fallback logic for unread count
          int unreadCount = room['unread_count'] ?? room['unread_messages_count'] ?? 0;
          
          String midwifeId = (room['midwife'] is Map ? room['midwife']['id'] : room['midwife'])?.toString() ?? '';
          
          // API might use 'patient' or 'user' for the client ID
          String userId = '';
          if (room['patient'] != null) {
            userId = (room['patient'] is Map ? room['patient']['id'] : room['patient'])?.toString() ?? '';
          } else if (room['user'] != null) {
            userId = (room['user'] is Map ? room['user']['id'] : room['user'])?.toString() ?? '';
          }
          
          if (roomId.isNotEmpty) {
            newCounts[roomId] = unreadCount;
          }
          if (midwifeId.isNotEmpty) {
            newCounts['midwife_$midwifeId'] = (newCounts['midwife_$midwifeId'] ?? 0) + unreadCount;
          }
          if (userId.isNotEmpty) {
            newCounts['user_$userId'] = (newCounts['user_$userId'] ?? 0) + unreadCount;
          }
        }
      }
      state = newCounts;
    } catch (e) {
      // Ignore errors silently for polling
    }
  }

  void refresh() {
    _fetchUnreadCounts();
  }

  void markRoomAsReadLocally(String roomId, {String midwifeId = '', String userId = ''}) {
    if (state.containsKey(roomId)) {
      int unreadInRoom = state[roomId] ?? 0;
      if (unreadInRoom > 0) {
        Map<String, int> newState = Map.from(state);
        newState[roomId] = 0;
        
        if (midwifeId.isNotEmpty && newState.containsKey('midwife_$midwifeId')) {
          newState['midwife_$midwifeId'] = (newState['midwife_$midwifeId']! - unreadInRoom).clamp(0, 9999);
        }
        if (userId.isNotEmpty && newState.containsKey('user_$userId')) {
          newState['user_$userId'] = (newState['user_$userId']! - unreadInRoom).clamp(0, 9999);
        }
        
        state = newState;
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
