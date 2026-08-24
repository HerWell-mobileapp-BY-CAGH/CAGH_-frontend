import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cagh_frontend/shared/models/midwife_profile.dart';
import 'package:cagh_frontend/features/consultations/data/services/chat_api_service.dart';
import 'package:cagh_frontend/features/consultations/data/services/chat_websocket_service.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

class ChatScreen extends StatefulWidget {
  final MidwifeProfile midwife;
  final String? myUserId;

  const ChatScreen({super.key, required this.midwife, this.myUserId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  String? _roomId;
  String? _roomStatus;
  ChatWebSocketService? _wsService;
  String? _myUserId;
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
      
      // 1. Fetch all rooms
      final rooms = await ChatApiService.getChatRooms();
      
      // 2. Find room with this midwife
      Map<String, dynamic>? currentRoom;
      for (var room in rooms) {
        String? midwifeId = room['midwife'] is Map ? room['midwife']['id']?.toString() : room['midwife']?.toString();
        if (midwifeId == widget.midwife.id.toString()) {
          currentRoom = room;
          break;
        }
      }

      if (currentRoom != null) {
        _roomId = currentRoom['id'];
        _roomStatus = currentRoom['status'];

        // 3. Fetch history
        final history = await ChatApiService.getMessageHistory(_roomId!);
        setState(() {
          for (var msg in history) {
            _messages.add(_parseMessage(msg));
          }
        });

        // 4. Connect WebSocket if accepted
        if (_roomStatus == 'ACCEPTED') {
          _connectWebSocket();
        }
      }
    } catch (e) {
      debugPrint("Error initializing chat: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }

  void _connectWebSocket() async {
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
              if (data['message_ids']?.contains(msg['id']) ?? false) {
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
      if (widget.myUserId != null) {
        isMe = senderId == widget.myUserId;
      } else {
        // Fallback if myUserId is not provided (should not happen if navigating from ConsultHub)
        isMe = senderId != widget.midwife.userId.toString() && senderId != widget.midwife.id.toString();
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
        final result = await ChatApiService.initiateChat(
          midwifeId: widget.midwife.id,
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
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send request. Try again.'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _isLoading = false);
      }
      return;
    }

    if (_roomStatus == 'REQUESTED') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waiting for midwife to accept request before sending more messages.')),
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
      backgroundColor: const Color(0xFFF7F9F4),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: const Color(0xFF315E26),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFFFFD22B)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                backgroundImage: widget.midwife.avatarUrl != null ? NetworkImage(widget.midwife.avatarUrl!) : null,
                child: widget.midwife.avatarUrl == null ? const Icon(Icons.person, color: Color(0xFF315E26), size: 20) : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.midwife.fullName,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Online',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert, color: Color(0xFFFFD22B)),
              onPressed: () {},
            ),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF315E26)))
        : Column(
          children: [
            if (_roomStatus == 'REQUESTED')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Colors.orange.shade100,
                child: const Text(
                  'Waiting for midwife to accept request...',
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child: _messages.isEmpty 
                ? const Center(child: Text("No messages yet. Start the conversation!", style: TextStyle(color: Colors.grey)))
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
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Today',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
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
              color: isMe ? const Color(0xFF33691E) : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 20),
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
                const SizedBox(width: 4),
                Icon(
                  isRead ? Icons.done_all : Icons.done,
                  size: 14,
                  color: isRead ? Colors.blue : Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    final bool disabled = _roomStatus == 'REQUESTED';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: _isUploadingFile 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(Icons.add, color: disabled ? Colors.grey : const Color(0xFF315E26), size: 24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: disabled ? Colors.grey.shade100 : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        onSubmitted: disabled ? null : (_) => _sendMessage(),
                        enabled: !disabled,
                        decoration: InputDecoration(
                          hintText: disabled ? 'Cannot reply yet...' : 'Type your message...',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
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
                  color: disabled ? Colors.grey.shade400 : const Color(0xFF315E26),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
