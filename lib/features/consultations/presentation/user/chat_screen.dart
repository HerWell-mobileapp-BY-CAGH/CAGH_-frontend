import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cagh_frontend/shared/models/midwife_profile.dart';
import 'package:cagh_frontend/features/consultations/data/services/chat_api_service.dart';
import 'package:cagh_frontend/features/consultations/data/services/chat_websocket_service.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cagh_frontend/features/notifications/presentation/providers/notification_provider.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final MidwifeProfile? midwife;
  final String? chatRoomId;
  final String? midwifeId;
  final String? midwifeName;
  final String? myUserId;

  const ChatScreen({
    super.key,
    this.midwife,
    this.chatRoomId,
    this.midwifeId,
    this.midwifeName,
    this.myUserId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  String? _roomId;
  String? _myUserId;
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
      final userDataStr = prefs.getString('user_data');
      if (userDataStr != null && userDataStr.isNotEmpty) {
        try {
          final userData = jsonDecode(userDataStr);
          _myUserId = userData['id']?.toString() ?? userData['user_id']?.toString() ?? '';
        } catch (e) {
          _myUserId = '';
        }
      } else {
        _myUserId = '';
      }
      if (widget.chatRoomId != null) {
        _roomId = widget.chatRoomId;
        _roomStatus = 'ACCEPTED';
      } else {
        final targetMidwifeId = widget.midwifeId ?? widget.midwife?.id.toString();
        if (targetMidwifeId != null) {
          final rooms = await ChatApiService.getChatRooms();
          Map<String, dynamic>? currentRoom;
          for (var room in rooms) {
            String? mId = room['midwife'] is Map ? room['midwife']['id']?.toString() : room['midwife']?.toString();
            if (mId == targetMidwifeId) {
              currentRoom = room;
              break;
            }
          }
          if (currentRoom != null) {
            _roomId = currentRoom['id']?.toString();
            _roomStatus = currentRoom['status'];
          }
        }
      }

      if (_roomId != null) {
        // 3. Fetch history
        final history = await ChatApiService.getMessageHistory(_roomId!);
        setState(() {
          for (var msg in history) {
            _messages.add(_parseMessage(msg));
          }
        });

        // 4. Connect WebSocket always to receive status updates or messages
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
      AppLogger.d("Error initializing chat: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
      
      _pollingTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
        if (_roomId == null || !mounted) return;
        // Skip HTTP polling when WebSocket is connected
        if (_wsService != null && _wsService!.isConnected) return;
        try {
          final history = await ChatApiService.getMessageHistory(_roomId!);
          if (mounted && history.isNotEmpty) {
            bool hasChanges = false;
            for (var msg in history) {
              final parsedMsg = _parseMessage(msg);
              
              // Deduplicate local optimistic messages
              final prevLen = _messages.length;
              _messages.removeWhere((m) => 
                  m['id'].toString().startsWith('local-') && 
                  m['text'] == parsedMsg['text']);
              if (_messages.length != prevLen) hasChanges = true;

              if (!_messages.any((m) => m['id'].toString() == parsedMsg['id'].toString())) {
                _messages.add(parsedMsg);
                hasChanges = true;
                if (!parsedMsg['isMe']) {
                  _wsService?.markRead();
                }
              }
            }

            if (hasChanges) {
              setState(() {});
            }
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
            if (_roomStatus == 'REQUESTED' && data['sender'] != null) {
              _roomStatus = 'ACCEPTED';
            }
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
      onTypingIndicator: (data) {
        // Implement typing UI if needed
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
      if (_myUserId != null && _myUserId!.isNotEmpty) {
        isMe = senderId == _myUserId;
      } else if (widget.myUserId != null) {
        isMe = senderId == widget.myUserId;
      }
    }

    return {
      "id": msg['id'],
      "text": msg['content'] ?? '',
      "time": timeString,
      "isMe": isMe,
      "isRead": msg['status'] == 'READ',
      "type": msg['message_type'],
      "attachment": msg['attachment'],
    };
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _pollingTimer?.cancel();
    _wsService?.disconnect();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (_roomId == null) {
      // Create new room request
      setState(() => _isLoading = true);
      try {
        final targetMidwifeId = widget.midwifeId ?? widget.midwife?.id.toString();
        if (targetMidwifeId == null) throw Exception("No midwife ID");
        final result = await ChatApiService.initiateChat(
          midwifeId: targetMidwifeId,
          initialMessage: text,
        );
        
        setState(() {
          _roomId = result['id'];
          _roomStatus = result['status']; // Usually 'REQUESTED'
          
          final now = DateTime.now();
          _messages.add({
            "id": "local-${now.millisecondsSinceEpoch}",
            "text": text,
            "time": DateFormat('h:mm a').format(now),
            "isMe": true,
            "isRead": false,
            "type": "TEXT",
          });
        });
        
        _messageController.clear();
        _scrollToBottom();
        await _connectWebSocket();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.failedToSendRequest), backgroundColor: Colors.red),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
      return;
    }

    if (_roomStatus == 'REQUESTED') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.waitForMidwifeAccept)),
      );
      return;
    }

    // Existing accepted room
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
      AppLogger.d('File upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToUploadFile), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingFile = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Theme.of(context).appBarTheme.foregroundColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                backgroundImage: widget.midwife?.avatarUrl != null ? NetworkImage(widget.midwife!.avatarUrl!) : null,
                child: widget.midwife?.avatarUrl == null ? const Icon(Icons.person, color: AppColors.primaryGreen, size: 20) : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.midwifeName ?? widget.midwife?.fullName ?? 'Midwife',
                    style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    AppLocalizations.of(context)!.online,
                    style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor?.withValues(alpha: 0.7), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.more_vert, color: Theme.of(context).appBarTheme.foregroundColor),
              onPressed: () {},
            ),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
        : Column(
          children: [
            if (_roomStatus == 'REQUESTED')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Colors.orange.shade100,
                child: Text(
                  AppLocalizations.of(context)!.waitingForConfirmation,
                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child: _messages.isEmpty 
                ? Center(child: Text(AppLocalizations.of(context)!.noMessagesYet, style: const TextStyle(color: Colors.grey)))
                : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                itemCount: _messages.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).dividerColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.today,
                            style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  }
                  
                  final msg = _messages[index - 1];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildMessageBubble(
                      text: msg['text'],
                      time: msg['time'],
                      isMe: msg['isMe'],
                      isRead: msg['isRead'],
                      attachment: msg['attachment'],
                    ),
                  );
                },
              ),
            ),
            _buildInputArea(),
          ],
        ),
    );
  }

  Widget _buildMessageBubble({
    required String text,
    required String time,
    required bool isMe,
    required bool isRead,
    Map<String, dynamic>? attachment,
  }) {
    final hasImage = attachment != null &&
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
                      cacheWidth: 600,
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
                            text.isNotEmpty ? text : AppLocalizations.of(context)!.professionalCv,
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
              if (text.isNotEmpty && (!hasImage))
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

  Widget _buildInputArea() {
    final bool disabled = _roomStatus == 'REQUESTED';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            GestureDetector(
              onTap: disabled || _isUploadingFile ? null : _pickAndSendFile,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: _isUploadingFile 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(Icons.add, color: disabled ? Colors.grey : Theme.of(context).colorScheme.primary, size: 24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: disabled ? Theme.of(context).disabledColor.withValues(alpha: 0.1) : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        onSubmitted: disabled ? null : (_) => _sendMessage(),
                        enabled: !disabled,
                        decoration: InputDecoration(
                          hintText: disabled ? AppLocalizations.of(context)!.pleaseAcceptRequest : AppLocalizations.of(context)!.typingPlaceholder,
                          hintStyle: TextStyle(color: Theme.of(context).hintColor, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: disabled ? null : _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: disabled ? Theme.of(context).disabledColor : Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.send, color: Theme.of(context).colorScheme.onPrimary, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

