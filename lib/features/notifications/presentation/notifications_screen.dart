import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cagh_frontend/features/notifications/presentation/providers/notification_provider.dart';
import 'package:cagh_frontend/features/notifications/data/models/notification_model.dart';
import 'package:cagh_frontend/features/consultations/presentation/user/chat_screen.dart';
import 'package:cagh_frontend/features/consultations/presentation/midwife/midwife_chat_screen.dart';
import 'package:cagh_frontend/features/consultations/presentation/user/consult_hub_screen.dart';
import 'package:cagh_frontend/features/consultations/presentation/midwife/midwife_consults_screen.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationProvider);
    final notifier = ref.read(notificationProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.notifications,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (state.notifications.isNotEmpty && state.unreadCount > 0)
            TextButton(
              onPressed: () => notifier.markAllAsRead(),
              child: Text(
                AppLocalizations.of(context)!.markAllAsRead,
                style: const TextStyle(
                  color: AppColors.accentYellow,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primaryGreen,
        onRefresh: () => notifier.loadNotifications(),
        child: _buildBody(context, ref, state, notifier),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    NotificationState state,
    NotificationStateNotifier notifier,
  ) {
    if (state.isLoading && state.notifications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      );
    }

    if (state.error != null && state.notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 54, color: AppColors.errorRed),
              const SizedBox(height: 16),
              Text(
                '${AppLocalizations.of(context)!.failedToLoadNotifications}: ${state.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => notifier.loadNotifications(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(AppLocalizations.of(context)!.retry, style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (state.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 68, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noNotificationsYet,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: state.notifications.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final notification = state.notifications[index];
        return _NotificationItem(
          notification: notification,
          onTap: () async {
            await notifier.markAsRead(notification.id);
            if (context.mounted) {
              _handleNotificationRoute(context, ref, notification);
            }
          },
        );
      },
    );
  }

  Future<void> _handleNotificationRoute(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notification,
  ) async {
    final userData = await AuthService.getUserData();
    final userType = (userData['user_type'] ?? userData['role'] ?? 'USER').toString().toUpperCase();
    final isMidwife = userType == 'MIDWIFE';

    final relType = (notification.relatedType ?? notification.type).toLowerCase();
    final relId = notification.relatedId ?? '';

    if (relType.contains('conversation') || relType.contains('chat') || relType.contains('message')) {
      if (context.mounted) {
        if (isMidwife) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MidwifeChatScreen(
                chatRoomId: relId.isNotEmpty ? relId : null,
                patientId: relId,
                patientName: notification.title,
              ),
            ),
          ).then((_) => ref.read(notificationProvider.notifier).refreshNotifications());
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                chatRoomId: relId.isNotEmpty ? relId : null,
                midwifeName: notification.title,
              ),
            ),
          ).then((_) => ref.read(notificationProvider.notifier).refreshNotifications());
        }
      }
    } else if (relType.contains('consultation') || relType.contains('appointment')) {
      if (context.mounted) {
        if (isMidwife) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MidwifeConsultsScreen(),
            ),
          ).then((_) => ref.read(notificationProvider.notifier).refreshNotifications());
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ConsultHubScreen(isActive: true),
            ),
          ).then((_) => ref.read(notificationProvider.notifier).refreshNotifications());
        }
      }
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
      final t = type.toLowerCase();
      if (t.contains('message') || t.contains('chat')) {
        return Icons.chat_bubble_outline_rounded;
      } else if (t.contains('consultation') || t.contains('appointment')) {
        return Icons.calendar_today_rounded;
      } else if (t.contains('request')) {
        return Icons.person_add_alt_1_rounded;
      }
      return Icons.notifications_outlined;
    }

    Color getIconColor(String type) {
      final t = type.toLowerCase();
      if (t.contains('message') || t.contains('chat')) {
        return const Color(0xFF2E7D32);
      } else if (t.contains('consultation') || t.contains('appointment')) {
        return AppColors.primaryGreen;
      } else if (t.contains('request')) {
        return const Color(0xFFE65100);
      }
      return AppColors.primaryGreen;
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isUnread 
              ? AppColors.primaryGreen.withValues(alpha: 0.07) 
              : theme.scaffoldBackgroundColor,
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor.withValues(alpha: 0.6), 
              width: 0.8,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: getIconColor(notification.type).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                getIconForType(notification.type),
                color: getIconColor(notification.type),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
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
                            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                            fontSize: 14.5,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeago.format(notification.createdAt),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isUnread ? AppColors.primaryGreen : Colors.grey.shade600,
                          fontWeight: isUnread ? FontWeight.w700 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: isUnread 
                          ? theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.9) 
                          : Colors.grey.shade600,
                      fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isUnread) ...[
              const SizedBox(width: 10),
              Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.only(top: 8),
                decoration: const BoxDecoration(
                  color: AppColors.primaryGreen,
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
