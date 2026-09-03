import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cagh_frontend/shared/models/appointment.dart';
import 'package:cagh_frontend/features/consultations/data/services/chat_api_service.dart';
import 'package:cagh_frontend/features/consultations/data/services/chat_websocket_service.dart';
import 'package:intl/intl.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cagh_frontend/features/notifications/presentation/providers/notification_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';

class MidwifeChatScreen extends ConsumerStatefulWidget {
  final String? chatRoomId;
  final String patientId;
  final String patientName;

  const MidwifeChatScreen({
    super.key,
    this.chatRoomId,
    required this.patientId,
    required this.patientName,
  });

  @override
  ConsumerState<MidwifeChatScreen> createState() => _MidwifeChatScreenState();
}

class _MidwifeChatScreenState extends ConsumerState<MidwifeChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  String? _myUserId;
  String? _roomId;
  String? _roomStatus;
  ChatWebSocketService? _wsService;
  bool _isUploadingFile = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _myUserId = prefs.getInt('user_id')?.toString() ?? prefs.getString('user_id') ?? '';
      
      final rooms = await ChatApiService.getChatRooms();
      
      Map<String, dynamic>? currentRoom;
      
      if (widget.chatRoomId != null) {
        // If we have a direct room ID from the inbox, find it to get status
        for (var room in rooms) {
          if (room['id']?.toString() == widget.chatRoomId) {
            currentRoom = room;
            break;
          }
        }
        // If not found in list but we have ID, we can still try to proceed
        _roomId = widget.chatRoomId;
      } else {
        // Fallback for when opened from an Appointment without a room ID
        for (var room in rooms) {
          String? userId = room['user'] is Map ? room['user']['id']?.toString() : room['user']?.toString();
          String? patientId = room['patient'] is Map ? room['patient']['id']?.toString() : room['patient']?.toString();

          if (userId == widget.patientId || patientId == widget.patientId) {
            currentRoom = room;
            break;
          }
        }
      }

      if (currentRoom != null) {
        _roomId = currentRoom['id']?.toString();
        _roomStatus = currentRoom['status'];
      } else if (_roomId == null) {
        // Still not found and no ID provided?
        Future.delayed(Duration.zero, () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(AppLocalizations.of(context)!.noActiveChatFound),
              backgroundColor: Colors.red,
            ));
          }
        });
      }

      if (currentRoom != null) {
        _roomId = currentRoom['id']?.toString();
        _roomStatus = currentRoom['status'];

        final history = await ChatApiService.getMessageHistory(_roomId!);
        setState(() {
          for (var msg in history) {
            _messages.add(_parseMessage(msg));
          }
        });

        // Connect WebSocket always
        await _connectWebSocket();

        // 5. Mark messages as read and clear local badge
        try {
          await ChatApiService.markMessagesAsRead(_roomId!);
        } catch (e) {
          debugPrint("markMessagesAsRead failed: $e");
        }
        _wsService?.markRead();
        ref.read(notificationProvider.notifier).refreshNotifications();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.failedToUpdateStatus}: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }

      _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
        if (_roomId == null || !mounted) return;
        try {
          final history = await ChatApiService.getMessageHistory(_roomId!);
          if (mounted) {
            setState(() {
              for (var msg in history) {
                final parsedMsg = _parseMessage(msg);

                // Deduplicate local optimistic messages
                _messages.removeWhere((m) => 
                    m['id'].toString().startsWith('local-') && 
                    m['text'] == parsedMsg['text']);

                if (!_messages.any((m) => m['id'].toString() == parsedMsg['id'].toString())) {
                  _messages.add(parsedMsg);
                  if (!parsedMsg['isMe']) {
                    _wsService?.markRead();
                  }
                }
              }
            });
          }
        } catch (e) {
          // Silent fail for polling
        }
      });
    }
  }

  Future<void> _connectWebSocket() async {
    if (_roomId == null) return;
    
    _wsService = ChatWebSocketService(
      onMessageReceived: (data) {
        if (mounted) {
          setState(() {
            final parsedMsg = _parseMessage(data);
            // Deduplicate local optimistic messages
            _messages.removeWhere((m) => 
                m['id'].toString().startsWith('local-') && 
                m['text'] == parsedMsg['text']);
            
            // Also ensure we don't add duplicate server messages
            if (!_messages.any((m) => m['id'].toString() == parsedMsg['id'].toString())) {
              _messages.add(parsedMsg);
              // It's a new message, we are on the screen, mark it as read
              if (!parsedMsg['isMe']) {
                _wsService?.markRead();
              }
            }
          });
          _scrollToBottom();
        }
      },
      onReadReceipt: (data) {
        if (mounted) {
          setState(() {
            for (var msg in _messages) {
              if (data['message_ids'] != null) {
                if (data['message_ids'].contains(msg['id'])) {
                  msg['isRead'] = true;
                }
              } else {
                // If message_ids is missing, assume all previous messages are read
                msg['isRead'] = true;
              }
            }
          });
        }
      },
      onError: (data) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Error sending message'), backgroundColor: Colors.red),
          );
        }
      },
    );

    await _wsService!.connect(_roomId!);
  }

  Map<String, dynamic> _parseMessage(Map<String, dynamic> msg) {
    final sentAt = DateTime.tryParse(msg['sent_at'] ?? '')?.toLocal() ?? DateTime.now();
    final timeString = DateFormat('h:mm a').format(sentAt);
    
    String? senderId = msg['sender'] is Map ? msg['sender']['id']?.toString() : msg['sender']?.toString();

    bool isMe = false;
    if (senderId != null) {
      // In same-browser testing, _myUserId from SharedPreferences can be overwritten. 
      // Safest way is to check if the sender is NOT the patient.
      isMe = senderId != widget.patientId;
    }

    return {
      "id": msg['id']?.toString() ?? "local-${DateTime.now().millisecondsSinceEpoch}",
      "text": msg['content'] ?? '',
      "time": timeString,
      "isMe": isMe,
      "isRead": msg['status'] == 'READ',
      "type": msg['message_type'],
      "attachment": msg['attachment'],
    };
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _acceptRequest() async {
    if (_roomId == null) return;
    setState(() => _isLoading = true);
    try {
      await ChatApiService.acceptChat(_roomId!);
      setState(() {
        _roomStatus = 'ACCEPTED';
      });
      _connectWebSocket();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept chat'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _rejectRequest() async {
    if (_roomId == null) return;
    setState(() => _isLoading = true);
    try {
      await ChatApiService.rejectChat(_roomId!);
      setState(() {
        _roomStatus = 'REJECTED';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject chat'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (_roomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.noActiveChatFound)),
      );
      return;
    }

    if (_roomStatus == 'REQUESTED') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseAcceptRequest)),
      );
      return;
    }

    if (_wsService != null && _roomStatus == 'ACCEPTED') {
      final now = DateTime.now();
      setState(() {
        _messages.add({
          "id": "local-${now.millisecondsSinceEpoch}",
          "text": text,
          "time": DateFormat('h:mm a').format(now),
          "isMe": true,
          "isRead": false,
          "type": "TEXT",
        });
      });
      
      _wsService!.sendMessage(text);
      _messageController.clear();
      _scrollToBottom();
    }
  }

  Future<void> _pickAndSendFile() async {
    if (_roomId == null || _roomStatus != 'ACCEPTED') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.waitForChatConnected)),
      );
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        setState(() {
          _isUploadingFile = true;
        });

        // 1. Upload to API
        final uploadResponse = await ChatApiService.uploadAttachment(_roomId!, file);
        final attachmentId = uploadResponse['id'];

        // 2. Send WS message
        if (_wsService != null) {
          _wsService!.sendMessage(
            file.name,
            messageType: 'FILE',
            attachmentId: attachmentId,
          );
        }
      }
    } catch (e) {
      debugPrint('File upload error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.failedToUploadFile}: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingFile = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _pollingTimer?.cancel();
    _wsService?.disconnect();
    super.dispose();
  }

  Widget _buildMessageBubble({
    required String text,
    required String time,
    required bool isMe,
    required bool isRead,
    Map<String, dynamic>? attachment,
  }) {
    final bool hasImage = attachment != null &&
        attachment['file_url'] != null &&
        (attachment['file_url'].toString().endsWith('.png') ||
         attachment['file_url'].toString().endsWith('.jpg') ||
         attachment['file_url'].toString().endsWith('.jpeg'));

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.only(left: 14, right: 14, top: 10, bottom: 8),
        decoration: BoxDecoration(
          color: isMe ? Theme.of(context).colorScheme.primary : Theme.of(context).cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (attachment != null) ...[
                if (hasImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      attachment['file_url'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.insert_drive_file, color: isMe ? Colors.white70 : Colors.black54),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            text.isNotEmpty ? text : 'Attachment',
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (text.isNotEmpty && !hasImage) const SizedBox(height: 6),
              ],
              if (text.isNotEmpty && (!hasImage || attachment == null))
                Text(
                  text,
                  style: TextStyle(
                    color: isMe ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.bottomRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 11,
                        color: isMe ? Colors.white70 : Colors.grey.shade500,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        isRead ? Icons.done_all : Icons.done,
                        size: 14,
                        color: isRead ? const Color(0xFF64B5F6) : Colors.white70,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).appBarTheme.foregroundColor?.withOpacity(0.2) ?? Colors.white24,
              child: Text(
                widget.patientName.isNotEmpty ? widget.patientName[0].toUpperCase() : 'P',
                style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.patientName,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).appBarTheme.foregroundColor),
                  ),
                  Text(
                    _roomStatus == 'ACCEPTED' ? AppLocalizations.of(context)!.online : (_roomStatus == 'REQUESTED' ? 'Request Pending' : 'Offline'),
                    style: TextStyle(fontSize: 12, color: Theme.of(context).appBarTheme.foregroundColor?.withOpacity(0.7)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_roomStatus == 'REQUESTED')
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 1,
                itemBuilder: (context, index) {
                  return Align(
                    alignment: Alignment.center,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${widget.patientName} has requested a chat consultation.',
                            style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: _rejectRequest,
                                child: Text(AppLocalizations.of(context)!.reject, style: TextStyle(color: Colors.red)),
                              ),
                              SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: _acceptRequest,
                                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                                child: Text(AppLocalizations.of(context)!.accept, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isMe = msg['isMe'];
                  final isRead = msg['isRead'] ?? false;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildMessageBubble(
                      text: msg['text'] ?? '',
                      time: msg['time'],
                      isMe: isMe,
                      isRead: isRead,
                      attachment: msg['type'] == 'FILE' ? msg['attachment'] : null,
                    ),
                  );
                },
              ),
            ),
          if (_roomStatus != 'REQUESTED' && _roomId != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.attach_file, color: Theme.of(context).hintColor),
                              onPressed: _roomStatus == 'ACCEPTED' && !_isUploadingFile ? _pickAndSendFile : null,
                            ),
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                decoration: InputDecoration(
                                  hintText: _roomStatus == 'ACCEPTED' ? 'Type a message...' : 'Chat is not active',
                                  border: InputBorder.none,
                                ),
                                enabled: _roomStatus == 'ACCEPTED',
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: _roomStatus == 'ACCEPTED' ? Theme.of(context).colorScheme.primary : Theme.of(context).disabledColor,
                      child: IconButton(
                        icon: Icon(Icons.send, color: Theme.of(context).colorScheme.onPrimary),
                        onPressed: _roomStatus == 'ACCEPTED' ? _sendMessage : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
