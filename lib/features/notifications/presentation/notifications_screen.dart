import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cagh_frontend/features/notifications/presentation/providers/notification_provider.dart';
import 'package:cagh_frontend/features/notifications/data/models/notification_model.dart';
import 'package:cagh_frontend/features/consultations/presentation/user/chat_screen.dart';
import 'package:cagh_frontend/features/consultations/presentation/user/user_inbox_screen.dart';
import 'package:cagh_frontend/features/consultations/presentation/midwife/midwife_chat_screen.dart';
import 'package:cagh_frontend/features/consultations/presentation/midwife/midwife_inbox_screen.dart';
import 'package:cagh_frontend/features/appointments/presentation/screens/my_appointments_screen.dart';
import 'package:cagh_frontend/features/consultations/presentation/midwife/midwife_consults_screen.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/shared/widgets/inner_page_app_bar.dart';
import 'package:timeago/timeago.dart' as timeago;

enum NotificationFilter { all, unread, consultations, messages }

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  NotificationFilter _activeFilter = NotificationFilter.all;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);
    final notifier = ref.read(notificationProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    // Filter notifications based on active tab
    final filteredNotifications = state.notifications.where((n) {
      switch (_activeFilter) {
        case NotificationFilter.all:
          return true;
        case NotificationFilter.unread:
          return !n.isRead;
        case NotificationFilter.consultations:
          final t = (n.relatedType ?? n.type).toLowerCase();
          return t.contains('consult') || t.contains('appoint') || t.contains('request');
        case NotificationFilter.messages:
          final t = (n.relatedType ?? n.type).toLowerCase();
          return t.contains('message') || t.contains('chat') || t.contains('conversation');
      }
    }).toList();

    final unreadCount = state.notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAF7),
      appBar: buildInnerPageAppBar(
        context,
        title: l10n.notifications,
        showLanguage: false,
        extraActions: [
          if (unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  notifier.markAllAsRead();
                },
                icon: const Icon(
                  Icons.done_all_rounded,
                  size: 16,
                  color: AppColors.accentYellow,
                ),
                label: Text(
                  l10n.markAllAsRead,
                  style: const TextStyle(
                    color: AppColors.accentYellow,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs Header
          _buildFilterTabs(state.notifications, unreadCount, isDark),

          // Main Notifications List
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primaryGreen,
              onRefresh: () => notifier.loadNotifications(),
              child: _buildContent(context, state, notifier, filteredNotifications, isDark, l10n),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(List<NotificationModel> all, int unreadCount, bool isDark) {
    final consultCount = all.where((n) {
      final t = (n.relatedType ?? n.type).toLowerCase();
      return t.contains('consult') || t.contains('appoint') || t.contains('request');
    }).length;

    final msgCount = all.where((n) {
      final t = (n.relatedType ?? n.type).toLowerCase();
      return t.contains('message') || t.contains('chat') || t.contains('conversation');
    }).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : const Color(0xFFE8ECE7),
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildTabChip(
              title: 'All',
              count: all.length,
              filter: NotificationFilter.all,
              isDark: isDark,
            ),
            const SizedBox(width: 8),
            _buildTabChip(
              title: 'Unread',
              count: unreadCount,
              filter: NotificationFilter.unread,
              isDark: isDark,
              highlightBadge: unreadCount > 0,
            ),
            const SizedBox(width: 8),
            _buildTabChip(
              title: 'Consultations',
              count: consultCount,
              filter: NotificationFilter.consultations,
              isDark: isDark,
              icon: Icons.calendar_today_rounded,
            ),
            const SizedBox(width: 8),
            _buildTabChip(
              title: 'Messages',
              count: msgCount,
              filter: NotificationFilter.messages,
              isDark: isDark,
              icon: Icons.chat_bubble_outline_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabChip({
    required String title,
    required int count,
    required NotificationFilter filter,
    required bool isDark,
    IconData? icon,
    bool highlightBadge = false,
  }) {
    final isSelected = _activeFilter == filter;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _activeFilter = filter);
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primaryGreen : const Color(0xFF2C5927))
              : (isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF1F4EE)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isDark ? AppColors.darkBorder : const Color(0xFFE2E7DE)),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (isDark ? AppColors.primaryGreen : const Color(0xFF2C5927)).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : (isDark ? Colors.grey.shade300 : const Color(0xFF4E574B)),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : (isDark ? Colors.grey.shade300 : const Color(0xFF333D29)),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.22)
                      : (highlightBadge
                          ? const Color(0xFFE53935)
                          : (isDark ? AppColors.darkBorder : const Color(0xFFDFE5DC))),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : (highlightBadge ? Colors.white : (isDark ? Colors.grey.shade300 : const Color(0xFF4A5545))),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    NotificationState state,
    NotificationStateNotifier notifier,
    List<NotificationModel> filteredNotifications,
    bool isDark,
    AppLocalizations l10n,
  ) {
    if (state.isLoading && state.notifications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      );
    }

    if (state.error != null && state.notifications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.errorRed),
              ),
              const SizedBox(height: 16),
              Text(
                '${l10n.failedToLoadNotifications}: ${state.error}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey.shade300 : AppColors.textGray,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => notifier.loadNotifications(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(l10n.retry),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (filteredNotifications.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceVariant
                      : const Color(0xFFEBF3E8),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : const Color(0xFFD6E4D1),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  size: 44,
                  color: Color(0xFF3B6B2B),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _activeFilter == NotificationFilter.unread
                    ? 'All Caught Up!'
                    : l10n.noNotificationsYet,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : const Color(0xFF2C3E26),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _activeFilter == NotificationFilter.unread
                    ? 'You have read all your notifications.'
                    : 'When you receive consultation updates, messages, or announcements, they will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  if (_activeFilter != NotificationFilter.all) {
                    setState(() => _activeFilter = NotificationFilter.all);
                  } else {
                    notifier.loadNotifications();
                  }
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(
                  _activeFilter != NotificationFilter.all ? 'View All' : l10n.retry,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? AppColors.darkPrimary : AppColors.primaryGreen,
                  side: BorderSide(
                    color: isDark ? AppColors.darkPrimary : AppColors.primaryGreen,
                    width: 1.2,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredNotifications.length,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      itemBuilder: (context, index) {
        final notification = filteredNotifications[index];
        return _NotificationCard(
          notification: notification,
          isDark: isDark,
          onTap: () async {
            await notifier.markAsRead(notification.id);
            if (context.mounted) {
              _handleNotificationRoute(context, ref, notification);
            }
          },
          onDismissed: () {
            notifier.markAsRead(notification.id);
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
          if (relId.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MidwifeChatScreen(
                  chatRoomId: relId,
                  patientId: relId,
                  patientName: notification.title,
                ),
              ),
            ).then((_) => ref.read(notificationProvider.notifier).refreshNotifications());
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MidwifeInboxScreen(),
              ),
            ).then((_) => ref.read(notificationProvider.notifier).refreshNotifications());
          }
        } else {
          if (relId.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  chatRoomId: relId,
                  midwifeName: notification.title,
                ),
              ),
            ).then((_) => ref.read(notificationProvider.notifier).refreshNotifications());
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const UserInboxScreen(),
              ),
            ).then((_) => ref.read(notificationProvider.notifier).refreshNotifications());
          }
        }
      }
    } else if (relType.contains('consultation') || relType.contains('appointment') || relType.contains('request')) {
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
              builder: (context) => const MyAppointmentsScreen(),
            ),
          ).then((_) => ref.read(notificationProvider.notifier).refreshNotifications());
        }
      }
    }
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const _NotificationCard({
    required this.notification,
    required this.isDark,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final typeInfo = _getTypeInfo(notification.type, notification.relatedType);

    return Dismissible(
      key: Key(notification.id),
      direction: isUnread ? DismissDirection.endToStart : DismissDirection.none,
      onDismissed: (_) => onDismissed(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF2C5927),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: const [
            Text(
              'Mark as Read',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
            ),
            SizedBox(width: 8),
            Icon(Icons.done_all_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isUnread
              ? (isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF3F7F2))
              : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnread
                ? (isDark ? AppColors.primaryGreen.withValues(alpha: 0.4) : const Color(0xFFD6E3D3))
                : (isDark ? AppColors.darkBorder : const Color(0xFFEBEFEA)),
            width: isUnread ? 1.2 : 0.9,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: typeInfo.bgColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: typeInfo.borderColor,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      typeInfo.icon,
                      color: typeInfo.iconColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Notification Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tag Pill & Relative Time
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: typeInfo.tagBgColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                typeInfo.label,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: typeInfo.tagTextColor,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ),
                            Text(
                              timeago.format(notification.createdAt),
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isUnread
                                    ? (isDark ? AppColors.darkPrimary : const Color(0xFF2C5927))
                                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                fontWeight: isUnread ? FontWeight.w700 : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Title
                        Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                            color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1B2A18),
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // Body
                        Text(
                          notification.body,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : (isUnread ? const Color(0xFF333F31) : Colors.grey.shade600),
                            fontWeight: isUnread ? FontWeight.w500 : FontWeight.w400,
                            height: 1.35,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Trailing Status Indicator & Chevron
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (isUnread)
                          Container(
                            width: 9,
                            height: 9,
                            decoration: const BoxDecoration(
                              color: Color(0xFF3B7D2A),
                              shape: BoxShape.circle,
                            ),
                          )
                        else
                          const SizedBox(width: 9, height: 9),
                        const SizedBox(height: 16),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  _TypeInfo _getTypeInfo(String type, String? relatedType) {
    final t = '${type}_${relatedType ?? ''}'.toLowerCase();

    if (t.contains('message') || t.contains('chat') || t.contains('conversation')) {
      return _TypeInfo(
        label: 'Message',
        icon: Icons.chat_bubble_outline_rounded,
        iconColor: const Color(0xFF00796B),
        bgColor: const Color(0xFFE0F2F1),
        borderColor: const Color(0xFFB2DFDB),
        tagBgColor: const Color(0xFFE0F2F1),
        tagTextColor: const Color(0xFF00695C),
      );
    } else if (t.contains('request')) {
      return _TypeInfo(
        label: 'Request',
        icon: Icons.person_add_alt_1_rounded,
        iconColor: const Color(0xFFD84315),
        bgColor: const Color(0xFFFBE9E7),
        borderColor: const Color(0xFFFFCCBC),
        tagBgColor: const Color(0xFFFBE9E7),
        tagTextColor: const Color(0xFFBF360C),
      );
    } else if (t.contains('consult') || t.contains('appoint')) {
      return _TypeInfo(
        label: 'Consultation',
        icon: Icons.calendar_month_rounded,
        iconColor: const Color(0xFF2E7D32),
        bgColor: const Color(0xFFE8F5E9),
        borderColor: const Color(0xFFC8E6C9),
        tagBgColor: const Color(0xFFE8F5E9),
        tagTextColor: const Color(0xFF1B5E20),
      );
    } else {
      return _TypeInfo(
        label: 'Update',
        icon: Icons.notifications_active_outlined,
        iconColor: const Color(0xFF5D4037),
        bgColor: const Color(0xFFEFEBE9),
        borderColor: const Color(0xFFD7CCC8),
        tagBgColor: const Color(0xFFEFEBE9),
        tagTextColor: const Color(0xFF4E342E),
      );
    }
  }
}

class _TypeInfo {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color borderColor;
  final Color tagBgColor;
  final Color tagTextColor;

  _TypeInfo({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.borderColor,
    required this.tagBgColor,
    required this.tagTextColor,
  });
}

