import 'package:flutter/material.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  final List<Map<String, String>> _messages = [
    {
      'sender': 'AI',
      'text': "Hello! I'm your Health Assistant. How can I help you with your reproductive health today?",
      'time': 'Just now',
    },
  ];

  void _sendMessage(String query) async {
    if (query.trim().isEmpty) return;

    final userText = query.trim();
    _questionController.clear();

    setState(() {
      _messages.add({
        'sender': 'User',
        'text': userText,
        'time': 'Just now',
      });
      _isLoading = true;
    });

    _scrollToBottom();

    await Future.delayed(const Duration(seconds: 1, milliseconds: 500));

    String aiReply =
        'Based on reproductive health guidelines: $userText is an important topic. Stay hydrated, keep track of cycle dates, and consult your midwife for personalized medical support.';

    final qLower = userText.toLowerCase();
    if (qLower.contains('luteal')) {
      aiReply =
          'The luteal phase is the second half of your menstrual cycle. It starts after ovulation and ends when your period begins. During this time, the follicle that released the egg transforms into the corpus luteum, which produces progesterone to prepare the uterine lining for a possible pregnancy.';
    } else if (qLower.contains('pcos')) {
      aiReply =
          'Polycystic Ovary Syndrome (PCOS) is a hormonal disorder common among women of reproductive age. Symptoms include irregular periods, excess androgen levels, and polycystic ovaries. Lifestyle modifications and medical guidance can help manage symptoms effectively.';
    } else if (qLower.contains('nutrition') || qLower.contains('food')) {
      aiReply =
          'Essential nutrition tips: prioritize folate-rich leafy greens, iron-rich foods, omega-3 fatty acids, complex carbohydrates, and maintain proper hydration daily.';
    } else if (qLower.contains('morning sickness')) {
      aiReply =
          'Morning sickness tips: Eat small, frequent meals throughout the day, sip ginger tea or lemon water, avoid strong food odors, and rest whenever possible.';
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _messages.add({
          'sender': 'AI',
          'text': aiReply,
          'time': 'Just now',
        });
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
      backgroundColor: const Color(0xFFF9FBF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF274E13),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF6750A4),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.2),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.psychology_outlined, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Ask Midwife AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Warning / Educational Disclaimer Banner (Matching Screenshot)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(16),
              border: const Border(
                left: BorderSide(color: Color(0xFFC62828), width: 4),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFC62828),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Educational information only. In case of emergency, call local emergency services immediately.',
                    style: TextStyle(
                      color: const Color(0xFFB71C1C),
                      fontSize: 12.5,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Message Thread List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildTypingIndicator();
                }

                final msg = _messages[index];
                final isUser = msg['sender'] == 'User';

                if (isUser) {
                  return _buildUserBubble(msg['text']!);
                } else {
                  return _buildAiBubble(msg['text']!);
                }
              },
            ),
          ),

          // Suggested Prompts Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPromptChip('⏱ Nutrition Tips'),
                  _buildPromptChip('📋 Ask about PCOS'),
                  _buildPromptChip('🩸 Menstrual Cycle'),
                ],
              ),
            ),
          ),

          // Ask Me Anything Input Bar (Matching Screenshot)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Container(
              padding: const EdgeInsets.only(left: 18, right: 6, top: 4, bottom: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFE0E0E0), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _questionController,
                      style: const TextStyle(fontSize: 14.5),
                      decoration: const InputDecoration(
                        hintText: 'Ask me anything about your health...',
                        hintStyle: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
                        border: InputBorder.none,
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF274E13),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: () => _sendMessage(_questionController.text),
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

  Widget _buildAiBubble(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF274E13),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFF0F0F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                text,
                style: const TextStyle(
                  color: Color(0xFF2E2E2E),
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ),
          ),
          const SizedBox(width: 30),
        ],
      ),
    );
  }

  Widget _buildUserBubble(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 40),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF274E13),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFE8F5E9),
            child: Icon(Icons.person, color: Color(0xFF274E13), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF274E13),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF0F0F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        color: Color(0xFF81C784),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildPromptChip(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        backgroundColor: const Color(0xFFEEEEEE),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide.none,
        ),
        onPressed: () => _sendMessage(label.replaceAll(RegExp(r'^[^\s]+\s*'), '')),
      ),
    );
  }
}
