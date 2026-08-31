import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cagh_frontend/features/notifications/presentation/providers/notification_provider.dart';
import 'package:cagh_frontend/features/notifications/data/models/notification_model.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationProvider);
    final notifier = ref.read(notificationProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        actions: [
          if (state.notifications.isNotEmpty && state.unreadCount > 0)
            TextButton(
              onPressed: () => notifier.markAllAsRead(),
              child: Text(AppLocalizations.of(context)!.markAllAsRead),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => notifier.loadNotifications(),
        child: _buildBody(context, state, notifier),
      ),
    );
  }

  Widget _buildBody(BuildContext context, NotificationState state, NotificationStateNotifier notifier) {
    if (state.isLoading && state.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Failed to load notifications: ${state.error}'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => notifier.loadNotifications(),
              child: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      );
    }

    if (state.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noNotificationsYet,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: state.notifications.length,
      itemBuilder: (context, index) {
        final notification = state.notifications[index];
        return _NotificationItem(
          notification: notification,
          onTap: () {
            notifier.markAsRead(notification.id);
            _handleNotificationRoute(context, notification);
          },
        );
      },
    );
  }

  void _handleNotificationRoute(BuildContext context, NotificationModel notification) {
    // Basic routing logic
    if (notification.relatedType == 'conversation') {
      // TODO: Route to chat screen with notification.relatedId
    } else if (notification.relatedType == 'consultation') {
      // TODO: Route to consultation details
    }
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationItem({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !notification.isRead;

    IconData getIconForType(String type) {
      switch (type.toLowerCase()) {
        case 'message':
        case 'chat':
          return Icons.chat_bubble_outline;
        case 'consultation':
        case 'appointment':
          return Icons.calendar_today_outlined;
        default:
          return Icons.notifications_outlined;
      }
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUnread ? theme.primaryColor.withOpacity(0.05) : theme.scaffoldBackgroundColor,
          border: Border(
            bottom: BorderSide(color: theme.dividerColor, width: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                getIconForType(notification.type),
                color: theme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeago.format(notification.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: isUnread ? theme.primaryColor : Colors.grey[600],
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 14,
                      color: isUnread ? theme.textTheme.bodyLarge?.color : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isUnread) ...[
              const SizedBox(width: 12),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
