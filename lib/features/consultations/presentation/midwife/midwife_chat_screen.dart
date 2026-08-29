import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cagh_frontend/shared/models/appointment.dart';
import 'package:cagh_frontend/features/consultations/data/services/chat_api_service.dart';
import 'package:cagh_frontend/features/consultations/data/services/chat_websocket_service.dart';
import 'package:intl/intl.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cagh_frontend/features/consultations/presentation/providers/chat_notification_provider.dart';

class MidwifeChatScreen extends ConsumerStatefulWidget {
  final Appointment appointment;

  const MidwifeChatScreen({super.key, required this.appointment});

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
      for (var room in rooms) {
        String? userId = room['user'] is Map ? room['user']['id']?.toString() : room['user']?.toString();
        String? patientId = room['patient'] is Map ? room['patient']['id']?.toString() : room['patient']?.toString();

        if (userId == widget.appointment.userId.toString() || patientId == widget.appointment.userId.toString()) {
          currentRoom = room;
          break;
        }
      }
      
      if (currentRoom == null && rooms.isNotEmpty) {
        // Fallback: The backend might have used a strange key name (like 'initiator', 'sender', etc)
        // Just search the entire room object for the user's ID
        for (var room in rooms) {
          if (room.toString().contains(widget.appointment.userId.toString())) {
            currentRoom = room;
            break;
          }
        }
      }
      
      if (currentRoom == null) {
        // Still not found? Debug SnackBar so the user can tell me what the backend returned
        Future.delayed(Duration.zero, () {
          if (mounted) {
            String debugMsg = rooms.isEmpty 
              ? "DEBUG: Rooms list is EMPTY!" 
              : "DEBUG ROOM: ${rooms.first.toString().length > 200 ? rooms.first.toString().substring(0, 200) : rooms.first.toString()}";
              
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("$debugMsg | Appt UserID: ${widget.appointment.userId}"),
              duration: const Duration(seconds: 15),
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
        ref.read(chatNotificationProvider.notifier).markRoomAsReadLocally(_roomId!, userId: widget.appointment.userId.toString());
      }
    } catch (e) {
      debugPrint("Error initializing chat: $e");
      Future.delayed(Duration.zero, () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("API ERROR: $e"),
            duration: const Duration(seconds: 15),
            backgroundColor: Colors.red,
          ));
        }
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
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
      isMe = senderId != widget.appointment.userId.toString();
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
          const SnackBar(content: Text('Failed to accept chat'), backgroundColor: Colors.red),
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
          const SnackBar(content: Text('Failed to reject chat'), backgroundColor: Colors.red),
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
        const SnackBar(content: Text('No active chat found. Patient must initiate.')),
      );
      return;
    }

    if (_roomStatus == 'REQUESTED') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the request before sending messages.')),
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
        const SnackBar(content: Text('Wait for the chat to be connected.')),
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
        SnackBar(content: Text('Failed to upload file: $e'), backgroundColor: Colors.red),
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
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: EdgeInsets.symmetric(
                horizontal: hasImage ? 4 : 16, vertical: hasImage ? 4 : 12),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFF315E26) : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (attachment != null) ...[
                  if (hasImage)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        attachment['file_url'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 40),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.insert_drive_file, color: Colors.white70),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              text.isNotEmpty ? text : 'Attachment',
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (text.isNotEmpty && !hasImage) const SizedBox(height: 8),
                ],
                if (text.isNotEmpty && (!hasImage || attachment == null))
                  Text(
                    text,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: isRead ? Colors.blue : Colors.grey.shade600,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPale,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white24,
              child: Text(
                (widget.appointment.userFullName != null && widget.appointment.userFullName!.isNotEmpty) ? widget.appointment.userFullName![0].toUpperCase() : 'P',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.appointment.userFullName ?? 'Patient',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _roomStatus == 'ACCEPTED' ? 'Online' : (_roomStatus == 'REQUESTED' ? 'Request Pending' : 'Offline'),
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['isMe'];
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primaryGreen : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 0),
                        bottomRight: Radius.circular(isMe ? 0 : 16),
                      ),
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
                        const Text(
                          'This patient has requested a chat consultation.',
                          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: _rejectRequest,
                              child: const Text('Reject', style: TextStyle(color: Colors.red)),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: _acceptRequest,
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF315E26)),
                              child: const Text('Accept', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
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
                        color: AppColors.backgroundMintGray,
                        borderRadius: BorderRadius.circular(24),
                      ),
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
                      color: Colors.white,
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
                                color: const Color(0xFFF4F6F4),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.attach_file, color: Colors.grey),
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
                            backgroundColor: _roomStatus == 'ACCEPTED' ? const Color(0xFF315E26) : Colors.grey,
                            child: IconButton(
                              icon: const Icon(Icons.send, color: Colors.white),
                              onPressed: _roomStatus == 'ACCEPTED' ? _sendMessage : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primaryGreen,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
