import 'package:flutter/material.dart';
import 'package:cagh_frontend/features/virtual_consultation/presentation/emergency_support_screen.dart';
import 'package:cagh_frontend/features/ai_assistant/presentation/ai_assistant_screen.dart';
import 'package:cagh_frontend/features/consultations/presentation/midwife_profile_detail_screen.dart';
import 'package:cagh_frontend/core/widgets/globe_language_picker.dart';

class FindMidwifeScreen extends StatefulWidget {
  final Function(String midwifeName)? onMessageTap;
  final VoidCallback? onBack;

  const FindMidwifeScreen({super.key, this.onMessageTap, this.onBack});

  @override
  State<FindMidwifeScreen> createState() => _FindMidwifeScreenState();
}

class _FindMidwifeScreenState extends State<FindMidwifeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _midwives = [
    {
      'id': '1',
      'name': 'Sr. Martha T.',
      'specialty': 'Maternal Health Specialist',
      'rating': '4.8',
      'reviews': '120 reviews',
      'isFavorite': false,
      'avatar': 'assets/images/midwife_martha.png',
      'bio': 'Certified Senior Nurse Midwife with 12+ years experience in maternal healthcare, natural labor support, and antenatal counseling.',
      'qualifications': 'MSc in Midwifery • Board Certified',
    },
    {
      'id': '2',
      'name': 'Sr. Bethlehem A.',
      'specialty': 'Family Planning Specialist',
      'rating': '4.9',
      'reviews': '215 reviews',
      'isFavorite': false,
      'avatar': 'assets/images/midwife_bethlehem.png',
      'bio': 'Specialist in reproductive health choices, family planning, adolescent guidance, and postnatal wellbeing.',
      'qualifications': 'BSc Nursing & Reproductive Care',
    },
  ];



  @override
  Widget build(BuildContext context) {
    final filteredMidwives = _midwives.where((m) {
      final q = _searchQuery.toLowerCase();
      return m['name'].toString().toLowerCase().contains(q) ||
          m['specialty'].toString().toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF274E13),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Find a Midwife',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          const GlobeLanguagePicker(iconColor: Colors.amber),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Input Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F4EE),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() => _searchQuery = val);
                    },
                    decoration: InputDecoration(
                      icon: Icon(Icons.search, color: Colors.grey.shade600, size: 22),
                      hintText: 'Search by name or specialty...',
                      hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      border: InputBorder.none,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Midwife Cards List
                ...filteredMidwives.map((mw) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: const Color(0xFFE8F5E9),
                              child: Icon(
                                Icons.person,
                                color: Colors.green.shade800,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        mw['name'],
                                        style: const TextStyle(
                                          fontSize: 16.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1A1A1A),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF8E1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.star, color: Colors.amber, size: 14),
                                            const SizedBox(width: 3),
                                            Text(
                                              mw['rating'],
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    mw['specialty'],
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF274E13),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Text(
                                        mw['reviews'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            mw['isFavorite'] = !mw['isFavorite'];
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFF8E1),
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                mw['isFavorite'] ? Icons.favorite : Icons.favorite_border,
                                                size: 14,
                                                color: Colors.amber.shade800,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                mw['isFavorite'] ? 'Favorited' : 'Add to Favorite',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.amber.shade900,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Action Buttons Row (Message & View Profile)
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 42,
                                child: OutlinedButton(
                                  onPressed: () {
                                    if (widget.onMessageTap != null) {
                                      widget.onMessageTap!(mw['name']);
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFF274E13), width: 1.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'Message',
                                    style: TextStyle(
                                      color: Color(0xFF274E13),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 42,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MidwifeProfileDetailScreen(
                                          midwife: mw,
                                          onMessageTap: widget.onMessageTap,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF274E13),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'View Profile',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 100),
              ],
            ),
          ),

          // Floating Action Buttons Overlay (Bottom Right)
          Positioned(
            right: 20,
            bottom: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 24/7 Telehealth Call Badge with Hover Effect
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

                // Purple FAB with Hover Effect
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
