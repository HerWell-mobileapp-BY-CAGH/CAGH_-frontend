import 'package:flutter/material.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/features/consultations/data/services/chat_api_service.dart';
import 'package:cagh_frontend/features/consultations/presentation/midwife/midwife_chat_screen.dart';
import 'package:cagh_frontend/shared/widgets/app_profile_avatar.dart';
import 'package:cagh_frontend/shared/models/appointment.dart';
import 'package:intl/intl.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';

class MidwifeInboxScreen extends StatefulWidget {
  const MidwifeInboxScreen({super.key});

  @override
  State<MidwifeInboxScreen> createState() => _MidwifeInboxScreenState();
}

class _MidwifeInboxScreenState extends State<MidwifeInboxScreen> {
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
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load messages. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  String _extractUserName(Map<String, dynamic> room) {
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
    final dynamic uData = room['user_detail'] ?? room['user'] ?? room['patient'];
    if (uData is Map && uData['id'] != null) {
      return uData['id'].toString();
    }
    if (uData != null && uData is! Map) {
      return uData.toString();
    }
    return '0';
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
      // Reload rooms when returning from chat
      _loadRooms();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        title: Text(AppLocalizations.of(context)!.myMessages, style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadRooms,
                        style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                        child: Text(AppLocalizations.of(context)!.retry, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                      )
                    ],
                  ),
                )
              : _rooms.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade400),
                          SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context)!.noMessagesYet,
                            style: TextStyle(fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.whenPatientsMessageYou,
                            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _rooms.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final room = _rooms[index];
                        final patientName = _extractUserName(room);
                        final status = room['status'] ?? 'UNKNOWN';
                        final isRequested = status == 'REQUESTED';
                        
                        // Parse last message if available, otherwise show status
                        String lastMessageText = isRequested ? 'New chat request' : 'Tap to view conversation';
                        String timeText = '';
                        
                        if (room['latest_message'] != null) {
                          lastMessageText = room['latest_message']['text'] ?? lastMessageText;
                          if (room['latest_message']['created_at'] != null) {
                            try {
                              final dt = DateTime.parse(room['latest_message']['created_at']).toLocal();
                              timeText = DateFormat('h:mm a').format(dt);
                            } catch (e) {
                              timeText = '';
                            }
                          }
                        } else if (room['created_at'] != null) {
                          try {
                            final dt = DateTime.parse(room['created_at']).toLocal();
                            timeText = DateFormat('MMM d, h:mm a').format(dt);
                          } catch (e) {
                            timeText = '';
                          }
                        }

                        int unreadCount = room['unread_count'] ?? 0;
                        bool hasUnread = unreadCount > 0;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          leading: AppProfileAvatar(
                            radius: 26,
                            imageUrl: room['user_detail']?['avatar_url'] ?? room['user']?['avatar_url'] ?? room['patient']?['avatar_url'],
                            name: patientName,
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                  child: Text(
                                    patientName,
                                    style: TextStyle(fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
                                    maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (timeText.isNotEmpty)
                                  Text(
                                    timeText,
                                    style: TextStyle(fontSize: 12, color: hasUnread ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodySmall?.color),
                                  ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    lastMessageText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isRequested ? Colors.orange.shade700 : (hasUnread ? Theme.of(context).textTheme.bodyLarge?.color : Theme.of(context).textTheme.bodySmall?.color),
                                        fontWeight: isRequested || hasUnread ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                  ),
                                ),
                                if (hasUnread)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      unreadCount.toString(),
                                      style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                if (isRequested && !hasUnread)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      AppLocalizations.of(context)!.pending,
                                      style: TextStyle(fontSize: 10, color: Colors.orange.shade800, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          onTap: () => _openChat(room),
                        );
                      },
                    ),
    );
  }
}
