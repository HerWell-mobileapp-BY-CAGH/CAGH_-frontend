import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cagh_frontend/features/consultations/data/services/chat_api_service.dart';
import 'package:cagh_frontend/features/consultations/presentation/midwife/midwife_chat_screen.dart';
import 'package:cagh_frontend/features/notifications/presentation/providers/notification_provider.dart';
import 'package:intl/intl.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';

import 'package:cagh_frontend/core/utils/app_logger.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/shared/widgets/globe_language_picker.dart';
import 'package:cagh_frontend/features/notifications/presentation/widgets/notification_bell.dart';

class MidwifeInboxScreen extends ConsumerStatefulWidget {
  const MidwifeInboxScreen({super.key});

  @override
  ConsumerState<MidwifeInboxScreen> createState() => _MidwifeInboxScreenState();
}

class _MidwifeInboxScreenState extends ConsumerState<MidwifeInboxScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _rooms = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rooms = await ChatApiService.getChatRooms();
      final uniqueRooms = <String, Map<String, dynamic>>{};
      for (var room in rooms) {
        final userId = _extractUserId(room);
        
        if (!uniqueRooms.containsKey(userId)) {
          uniqueRooms[userId] = room;
        } else {
          final existingStatus = uniqueRooms[userId]!['status'];
          final newStatus = room['status'];
          if (existingStatus == 'REQUESTED' && newStatus != 'REQUESTED') {
            uniqueRooms[userId] = room;
          }
        }
      }

      if (mounted) {
        setState(() {
          _rooms = uniqueRooms.values.toList();
          _isLoading = false;
        });
        ref.read(notificationProvider.notifier).refreshNotifications();
      }
    } catch (e, stack) {
      AppLogger.e('Error loading midwife chat rooms: $e', stack);
      if (mounted) {
        setState(() {
          _rooms = [];
          _isLoading = false;
        });
      }
    }
  }

  dynamic _mapPath(String key, dynamic holder) {
    if (holder is Map) return holder[key];
    return null;
  }

  Color _getAvatarColor(String name) {
    const colors = [
      Color(0xFF27AE60), // Green (like Eden)
      Color(0xFF8E44AD), // Purple (like Luna)
      Color(0xFF2980B9), // Blue
      Color(0xFFD35400), // Orange
      Color(0xFFC0392B), // Red
      Color(0xFF16A085), // Teal
      Color(0xFF6C5CE7), // Indigo
      Color(0xFFE84393), // Pink
    ];
    if (name.isEmpty) return colors[0];
    final hash = name.codeUnits.fold(0, (prev, elem) => prev + elem);
    return colors[hash.abs() % colors.length];
  }

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  String _extractUserName(Map<String, dynamic> room) {
    if (room['patient_name'] != null && room['patient_name'].toString().trim().isNotEmpty) {
      return room['patient_name'].toString().trim();
    }
    if (room['user_name'] != null && room['user_name'].toString().trim().isNotEmpty) {
      return room['user_name'].toString().trim();
    }
    if (room['client_name'] != null && room['client_name'].toString().trim().isNotEmpty) {
      return room['client_name'].toString().trim();
    }

    final dynamic uData = room['user_detail'] ?? room['user'] ?? room['patient'];

    if (uData is Map) {
      if (uData['profile'] is Map) {
        final profile = uData['profile'];
        final fName = profile['first_name']?.toString() ?? '';
        final lName = profile['last_name']?.toString() ?? '';
        if (fName.isNotEmpty || lName.isNotEmpty) {
          return '$fName $lName'.trim();
        }
      }
      if (uData['first_name'] != null && uData['first_name'].toString().isNotEmpty) {
        return "${uData['first_name']} ${uData['last_name'] ?? ''}".trim();
      }
      if (uData['full_name'] != null && uData['full_name'].toString().isNotEmpty) return uData['full_name'];
      if (uData['username'] != null && uData['username'].toString().isNotEmpty) return uData['username'];
    }
    return AppLocalizations.of(context)!.patient;
  }

  String _extractUserId(Map<String, dynamic> room) {
    if (room['patient_id'] != null && room['patient_id'].toString().trim().isNotEmpty) {
      return room['patient_id'].toString().trim();
    }
    if (room['user_id'] != null && room['user_id'].toString().trim().isNotEmpty) {
      return room['user_id'].toString().trim();
    }
    final dynamic uData = room['user_detail'] ?? room['user'] ?? room['patient'];
    if (uData is Map && uData['id'] != null) {
      return uData['id'].toString();
    }
    if (uData != null && uData is! Map) {
      return uData.toString();
    }
    return room['id']?.toString() ?? UniqueKey().toString();
  }

  void _openChat(Map<String, dynamic> room) {
    final patientName = _extractUserName(room);
    final patientId = _extractUserId(room);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MidwifeChatScreen(
          chatRoomId: room['id']?.toString(),
          patientId: patientId,
          patientName: patientName,
        ),
      ),
    ).then((_) {
      _loadRooms();
      ref.read(notificationProvider.notifier).refreshNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        title: Text(
          AppLocalizations.of(context)!.myMessages,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
            letterSpacing: -0.2,
          ),
        ),
        actions: const [
          Center(child: GlobeLanguagePicker(iconColor: Colors.white)),
          SizedBox(width: 6),
          NotificationBell(iconColor: Colors.white),
          SizedBox(width: 14),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRooms,
        color: Theme.of(context).colorScheme.primary,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
            : _errorMessage != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade300),
                            const SizedBox(height: 12),
                            Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadRooms,
                              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                              child: Text(AppLocalizations.of(context)!.retry, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : _rooms.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  AppLocalizations.of(context)!.noMessagesYet,
                                  style: TextStyle(fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  AppLocalizations.of(context)!.whenPatientsMessageYou,
                                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _rooms.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              thickness: 0.8,
                              color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                            ),
                            itemBuilder: (context, index) {
                              final room = _rooms[index];
                              final patientName = _extractUserName(room);
                              final status = room['status'] ?? 'UNKNOWN';
                              final isRequested = status == 'REQUESTED';
                              
                              String lastMessageText = isRequested ? 'New chat request' : 'Tap to view conversation';
                              String timeText = '';
                              
                              if (room['latest_message'] != null) {
                                final latestMsg = room['latest_message'];
                                if (latestMsg is Map) {
                                  lastMessageText = (latestMsg['text'] is String ? latestMsg['text'] : (latestMsg['content'] is String ? latestMsg['content'] : lastMessageText));
                                  final lmCreated = latestMsg['created_at'] is String ? latestMsg['created_at'] : (latestMsg['sent_at'] is String ? latestMsg['sent_at'] : null);
                                  if (lmCreated != null) {
                                    try {
                                      final dt = DateTime.parse(lmCreated).toLocal();
                                      timeText = DateFormat('h:mm a').format(dt);
                                    } catch (e) {
                                      timeText = '';
                                    }
                                  }
                                }
                              } else if (room['created_at'] is String) {
                                try {
                                  final dt = DateTime.parse(room['created_at']).toLocal();
                                  timeText = DateFormat('h:mm a').format(dt);
                                } catch (e) {
                                  timeText = '';
                                }
                              }

                              final avatarUrl = _mapPath('avatar_url', room['user_detail']) ??
                                  _mapPath('avatar_url', room['user']) ??
                                  _mapPath('avatar_url', room['patient']);
                              final avatarColor = _getAvatarColor(patientName);
                              final initials = _getInitials(patientName);

                              final int unreadCount = int.tryParse(room['unread_count']?.toString() ?? '') ?? 0;
                              final bool hasUnread = unreadCount > 0;

                              return InkWell(
                                onTap: () => _openChat(room),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Rounded Avatar with colored background & bold white initials
                                      CircleAvatar(
                                        radius: 25,
                                        backgroundColor: avatarColor,
                                        backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                                            ? NetworkImage(avatarUrl)
                                            : null,
                                        child: (avatarUrl == null || avatarUrl.isEmpty)
                                            ? Text(
                                                initials,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  letterSpacing: -0.2,
                                                ),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 14),

                                      // Patient Name & Subtitle
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              patientName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 16.5,
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? AppColors.darkTextPrimary : const Color(0xFF1E293B),
                                                letterSpacing: -0.2,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              lastMessageText,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: isRequested
                                                    ? Colors.orange.shade700
                                                    : (isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B)),
                                                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(width: 10),

                                      // Time & Trailing Badges/Checkmarks
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (timeText.isNotEmpty)
                                            Text(
                                              timeText,
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                color: isDark ? AppColors.darkTextSecondary : const Color(0xFF64748B),
                                              ),
                                            ),
                                          const SizedBox(height: 6),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (isRequested)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange.shade100,
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Text(
                                                    AppLocalizations.of(context)!.pending,
                                                    style: TextStyle(
                                                      fontSize: 10.5,
                                                      color: Colors.orange.shade800,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                )
                                              else ...[
                                                Icon(
                                                  hasUnread ? Icons.done_all : Icons.done,
                                                  size: 17,
                                                  color: hasUnread ? const Color(0xFF27AE60) : const Color(0xFF94A3B8),
                                                ),
                                                if (hasUnread) ...[
                                                  const SizedBox(width: 4),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: const BoxDecoration(
                                                      color: Color(0xFF27AE60),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Text(
                                                      unreadCount.toString(),
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10.5,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
      ),
    );
  }
}

