import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';

class AiChatInputBar extends StatefulWidget {
  final Future<void> Function(String text, {String? attachmentPath}) onSend;

  const AiChatInputBar({super.key, required this.onSend});

  @override
  State<AiChatInputBar> createState() => _AiChatInputBarState();
}

class _AiChatInputBarState extends State<AiChatInputBar> {
  final TextEditingController _controller = TextEditingController();
  bool _isComposing = false;
  String? _attachmentPath;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _isComposing = _controller.text.trim().isNotEmpty || _attachmentPath != null;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleAttach() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png', 'webp'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _attachmentPath = result.files.single.path;
          _isComposing = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.failedToUploadFile}: $e')),
        );
      }
    }
  }

  void _handleSend() {
    if (_isComposing) {
      final text = _controller.text.trim();
      widget.onSend(text, attachmentPath: _attachmentPath);
      _controller.clear();
      setState(() {
        _attachmentPath = null;
        _isComposing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_attachmentPath != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.attach_file, size: 20, color: Colors.black54),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _attachmentPath!.split('/').last,
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          _attachmentPath = null;
                          _isComposing = _controller.text.trim().isNotEmpty;
                        });
                      },
                    ),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Color(0xFF315E26)),
                  onPressed: _handleAttach,
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _controller,
                      maxLines: 5,
                      minLines: 1,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.typeHealthQuestion,
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: _isComposing ? const Color(0xFF315E26) : Colors.grey,
                  onPressed: _isComposing ? _handleSend : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
