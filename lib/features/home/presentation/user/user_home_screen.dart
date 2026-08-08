import 'package:flutter/material.dart';
import 'package:cagh_frontend/core/services/auth_service.dart';
import 'package:cagh_frontend/core/services/language_service.dart';
import 'package:cagh_frontend/core/widgets/globe_language_picker.dart';
import 'package:cagh_frontend/features/consultations/presentation/consult_hub_screen.dart';
import 'package:cagh_frontend/features/consultations/presentation/find_midwife_screen.dart';
import 'package:cagh_frontend/features/profile/presentation/user_profile_screen.dart';
import 'package:cagh_frontend/features/virtual_consultation/presentation/emergency_support_screen.dart';
import 'package:cagh_frontend/features/ai_assistant/presentation/ai_assistant_screen.dart';
import 'package:cagh_frontend/core/widgets/floating_glass_nav_bar.dart';
import 'package:cagh_frontend/core/services/chat_service.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? _userProfile;
  final TextEditingController _aiQuestionController = TextEditingController();
  String? _latestAiAnswer;
  bool _isAiLoading = false;

  String? _activeChatMidwifeName;
  bool _showFindMidwifePage = false;
  bool _hasUpcomingAppointment = false;
  final TextEditingController _chatInputController = TextEditingController();

  final List<Map<String, String>> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final localData = await AuthService.getUserData();
    if (mounted) {
      setState(() {
        _userProfile = localData;
      });
    }

    final res = await AuthService.getProfile();
    if (res.success && res.data != null && mounted) {
      setState(() {
        _userProfile = res.data;
      });
    }
  }

  void _showNotificationsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.notifications_active, color: Color(0xFF1B5E20)),
                      SizedBox(width: 8),
                      Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  children: const [
                    _NotificationTile(
                      title: 'Appointment Reminder',
                      body: 'Your Virtual Voice consultation with Nurse Sarah Jenkins is tomorrow at 10:00 AM.',
                      time: '10 mins ago',
                      isUnread: true,
                      type: 'APPOINTMENT',
                    ),
                    _NotificationTile(
                      title: 'Chat Request Accepted',
                      body: 'Sr. Martha T. accepted your direct message request. You can now chat freely.',
                      time: '2 hours ago',
                      isUnread: true,
                      type: 'CHAT',
                    ),
                    _NotificationTile(
                      title: 'New Educational Content',
                      body: 'New article added: "Trimester 2 Nutrition & Essential Vitamins".',
                      time: '1 day ago',
                      isUnread: false,
                      type: 'LEARNING',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReviewModal() {
    int selectedStars = 5;
    final reviewController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Leave Consultation Review',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Rate your recent consultation with Sr. Martha T.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < selectedStars ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setModalState(() {
                            selectedStars = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reviewController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Share your feedback or experience...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Thank you! Your review has been submitted.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'Submit Review',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex == 4) {
      return Scaffold(
        extendBody: true,
        body: UserProfileScreen(
          onBackTap: () => setState(() => _currentIndex = 0),
        ),
        bottomNavigationBar: _buildBottomNav(),
      );
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFFFF8F5),
      body: SafeArea(
        child: Column(
          children: [
            // ===== GREEN APP BAR (only on Home tab) =====
            if (_currentIndex != 1)
              Container(
                width: double.infinity,
                color: const Color(0xFF1B5E20),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _userProfile != null && (_userProfile!['full_name'] != null || _userProfile!['email'] != null)
                          ? 'Hello, ${_userProfile!['full_name'] ?? _userProfile!['email']}'
                          : 'Hello 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        const GlobeLanguagePicker(iconColor: Colors.amber, iconSize: 24),
                        IconButton(
                          onPressed: _showReviewModal,
                          icon: const Icon(
                            Icons.rate_review_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        IconButton(
                          onPressed: _showNotificationsModal,
                          icon: const Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // ===== MAIN BODY BASED ON SELECTED TAB =====
            Expanded(
              child: Stack(
                children: [
                  IndexedStack(
                    index: _currentIndex,
                    children: [
                      _buildHomeTab(),
                      _buildConsultChatTab(),
                      _buildLearnTab(),
                      _buildAiAssistantTab(),
                    ],
                  ),
                  if (_currentIndex == 0)
                    Positioned(
                      right: 20,
                      bottom: 20,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _HoverScaleWidget(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const EmergencySupportScreen(),
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.15),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    alignment: Alignment.topRight,
                                    children: [
                                      const Icon(
                                        Icons.phone_in_talk_rounded,
                                        color: Colors.redAccent,
                                        size: 26,
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Text(
                                          '24',
                                          style: TextStyle(
                                            fontSize: 8,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Emergency',
                                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _HoverScaleWidget(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AiAssistantScreen(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6750A4),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6750A4).withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.psychology_outlined,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // TAB 0: HOME DASHBOARD
  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Upcoming Appointment Alert Card (Hidden by default for new users)
          if (_hasUpcomingAppointment) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1B5E20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.phone_in_talk, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Virtual Voice Consultation',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Tomorrow at 10:00 AM • Sr. Martha T.',
                          style: TextStyle(fontSize: 12.5, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Join', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          const Text(
            'ABOUT US',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We provide confidential consultation, education and care to help women and adolescent girls make informed choices and live healthier lives.',
            style: TextStyle(
              fontSize: 14.5,
              height: 1.45,
              color: Colors.grey.shade700,
            ),
          ),

          const SizedBox(height: 20),

          // Focus Areas Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/home_illustration.png',
              fit: BoxFit.contain,
              height: 160,
              errorBuilder: (_, __, ___) {
                return const Icon(
                  Icons.health_and_safety,
                  size: 70,
                  color: Color(0xFF1B5E20),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          const Center(
            child: Text(
              'Our Focus Areas',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B5E20),
              ),
            ),
          ),

          const SizedBox(height: 16),

          _buildFocusCard(
            icon: Icons.menu_book_rounded,
            color: const Color(0xFFE8F5E9),
            iconColor: const Color(0xFF1B5E20),
            title: 'Adolescent Girls Health & Nutrition',
            subtitle: 'Puberty, menstrual health, nutrition & life skills.',
          ),
          const SizedBox(height: 12),
          _buildFocusCard(
            icon: Icons.shield_outlined,
            color: const Color(0xFFFFF3E0),
            iconColor: Colors.orange.shade700,
            title: 'Prevention & Awareness',
            subtitle: 'STI/HIV prevention, HPV & cervical cancer awareness.',
          ),
          const SizedBox(height: 12),
          _buildFocusCard(
            icon: Icons.favorite_border_rounded,
            color: const Color(0xFFE3F2FD),
            iconColor: Colors.blue.shade700,
            title: 'Reproductive Health & Care',
            subtitle: 'Pregnancy prevention, ANC, newborn care, checkups.',
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // TAB 1: CONSULT HUB / CHAT / FIND MIDWIFE SCREEN
  Widget _buildConsultChatTab() {
    if (_activeChatMidwifeName != null) {
      return _buildChatRoomView(_activeChatMidwifeName!);
    }

    if (_showFindMidwifePage) {
      return FindMidwifeScreen(
        onBack: () {
          setState(() {
            _showFindMidwifePage = false;
          });
        },
        onMessageTap: (midwifeName) {
          setState(() {
            _showFindMidwifePage = false;
            _activeChatMidwifeName = midwifeName;
            _messages.clear();
          });
        },
      );
    }

    return ConsultHubScreen(
      onFindMidwifeTap: () {
        setState(() {
          _showFindMidwifePage = true;
        });
      },
      onChatSelected: (midwifeName) {
        setState(() {
          _activeChatMidwifeName = midwifeName;
          _messages.clear();
        });
      },
    );
  }

  // CHAT ROOM VIEW FOR A SELECTED MIDWIFE
  Widget _buildChatRoomView(String midwifeName) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF274E13),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _activeChatMidwifeName = null;
                    _showFindMidwifePage = true;
                  });
                },
              ),
              const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.person, color: Color(0xFF1B5E20), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      midwifeName,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: ChatService.isMidwifeTyping,
                      builder: (context, isTyping, _) {
                        if (isTyping) {
                          return Text(
                            '$midwifeName is typing...',
                            style: const TextStyle(fontSize: 11, color: Colors.amberAccent, fontStyle: FontStyle.italic),
                          );
                        }
                        return const Text(
                          'Online • Verified Midwife',
                          style: TextStyle(fontSize: 11, color: Colors.amber),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ValueListenableBuilder<List<ChatMessage>>(
            valueListenable: ChatService.getMessagesNotifier(midwifeName),
            builder: (context, messages, _) {
              if (messages.isEmpty) {
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFA5D6A7), width: 1.5),
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 44,
                            color: Color(0xFF274E13),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Consultation with $midwifeName',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF274E13),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Direct consultation messages between you and $midwifeName.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMe = msg.isMe;
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isMe ? const Color(0xFF274E13) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg.text,
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            msg.time,
                            style: TextStyle(
                              fontSize: 10,
                              color: isMe ? Colors.white70 : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.white,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.attach_file, color: Color(0xFF274E13)),
                onPressed: () {},
              ),
              Expanded(
                child: TextField(
                  controller: _chatInputController,
                  onSubmitted: (_) => _sendUserMessage(midwifeName),
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: const Color(0xFF274E13),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 18),
                  onPressed: () => _sendUserMessage(midwifeName),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _sendUserMessage(String midwifeName) {
    final text = _chatInputController.text.trim();
    if (text.isEmpty) return;

    ChatService.sendMessage(midwifeName: midwifeName, text: text);
    _chatInputController.clear();
  }

  // TAB 2: LEARNING CENTER
  Widget _buildLearnTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Learning Center',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1B5E20)),
          ),
          const SizedBox(height: 4),
          Text(
            'Expert health articles, guides, and reproductive education',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13.5),
          ),
          const SizedBox(height: 16),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip('All Articles', true),
                _buildCategoryChip('Antenatal Care', false),
                _buildCategoryChip('Menstrual Health', false),
                _buildCategoryChip('Nutrition', false),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _buildArticleCard(
            title: 'Essential Nutrition Guide for the 2nd Trimester',
            topic: 'Maternal Nutrition',
            readTime: '5 min read',
            description: 'Learn about key vitamins, iron intake, and safe diet practices during pregnancy.',
          ),
          const SizedBox(height: 14),
          _buildArticleCard(
            title: 'Understanding Puberty & Reproductive Health',
            topic: 'Adolescent Health',
            readTime: '7 min read',
            description: 'A practical, confidential guide to body changes, menstrual hygiene, and self-care.',
          ),
          const SizedBox(height: 14),
          _buildArticleCard(
            title: 'Postnatal Support & Breastfeeding Tips',
            topic: 'Postpartum Care',
            readTime: '4 min read',
            description: 'Practical advice from certified midwives on newborn care and mental well-being.',
          ),
        ],
      ),
    );
  }

  // TAB 3: AI ASSISTANT & NEARBY FACILITY
  Widget _buildAiAssistantTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.smart_toy_outlined, color: Colors.amber, size: 36),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Teniva AI Health Assistant',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Ask instant questions about health, symptoms & care',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Suggested Questions',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
          ),

          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSuggestedPrompt('What foods relieve morning sickness?'),
              _buildSuggestedPrompt('What are normal signs of early labor?'),
              _buildSuggestedPrompt('How can I track my menstrual cycle?'),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _aiQuestionController,
                  decoration: InputDecoration(
                    hintText: 'Type your health question...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isAiLoading
                    ? null
                    : () async {
                        final q = _aiQuestionController.text.trim();
                        if (q.isEmpty) return;
                        setState(() => _isAiLoading = true);
                        await Future.delayed(const Duration(seconds: 1));
                        setState(() {
                          _isAiLoading = false;
                          _latestAiAnswer =
                              'Based on medical guidelines: $q is common during pregnancy. Stay hydrated, eat small frequent meals, and contact your midwife if symptoms persist.';
                          _aiQuestionController.clear();
                        });
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                child: _isAiLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Ask', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),

          if (_latestAiAnswer != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AI Response:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                  const SizedBox(height: 6),
                  Text(_latestAiAnswer!, style: const TextStyle(fontSize: 13.5, height: 1.4)),
                ],
              ),
            ),
          ],

          const SizedBox(height: 30),

          const Text(
            'Nearby Hospitals & Facilities',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1B5E20)),
          ),
          const SizedBox(height: 12),

          _buildFacilityCard('St. Paul Hospital Millennium Medical College', 'Gullele, Addis Ababa', '1.2 km away'),
          const SizedBox(height: 10),
          _buildFacilityCard('Gandhi Memorial Women Hospital', 'Kirkos, Addis Ababa', '3.5 km away'),
        ],
      ),
    );
  }

  Widget _buildFocusCard({required IconData icon, required Color color, required Color iconColor, required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: color, radius: 20, child: Icon(icon, color: iconColor, size: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF1B5E20) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontSize: 12.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildArticleCard({required String title, required String topic, required String readTime, required String description}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(topic, style: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold, fontSize: 12)),
              Text(readTime, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(description, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSuggestedPrompt(String text) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 12)),
      onPressed: () {
        _aiQuestionController.text = text;
      },
      backgroundColor: Colors.grey.shade100,
    );
  }

  Widget _buildFacilityCard(String name, String address, String distance) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_hospital, color: Colors.redAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                Text(address, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
          Text(distance, style: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      FloatingNavBarItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: LanguageService.tr('home'),
      ),
      FloatingNavBarItem(
        icon: Icons.medical_services_outlined,
        activeIcon: Icons.medical_services_rounded,
        label: LanguageService.tr('consult'),
        showBadge: true, // Red notification badge dot like in screenshot
      ),
      FloatingNavBarItem(
        icon: Icons.menu_book_outlined,
        activeIcon: Icons.menu_book_rounded,
        label: LanguageService.tr('learn'),
      ),
      FloatingNavBarItem(
        icon: Icons.location_on_outlined,
        activeIcon: Icons.location_on_rounded,
        label: LanguageService.tr('ai_nearby'),
      ),
      FloatingNavBarItem(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: LanguageService.tr('profile'),
      ),
    ];

    return FloatingGlassNavBar(
      selectedIndex: _currentIndex,
      items: items,
      onTabSelected: (index) {
        setState(() {
          _currentIndex = index;
          if (index != 1) {
            _activeChatMidwifeName = null;
          }
        });
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final String title;
  final String body;
  final String time;
  final bool isUnread;
  final String type;

  const _NotificationTile({
    required this.title,
    required this.body,
    required this.time,
    required this.isUnread,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUnread ? const Color(0xFFF1F8E9) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF1B5E20),
            child: Icon(
              type == 'APPOINTMENT' ? Icons.calendar_today : Icons.chat,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                const SizedBox(height: 2),
                Text(body, style: TextStyle(color: Colors.grey.shade700, fontSize: 12.5)),
                const SizedBox(height: 4),
                Text(time, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HoverScaleWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _HoverScaleWidget({required this.child, required this.onTap});

  @override
  State<_HoverScaleWidget> createState() => _HoverScaleWidgetState();
}

class _HoverScaleWidgetState extends State<_HoverScaleWidget> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = _isPressed ? 0.92 : (_isHovered ? 1.12 : 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          child: widget.child,
        ),
      ),
    );
  }
}
