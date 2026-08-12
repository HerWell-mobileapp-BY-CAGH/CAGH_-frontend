import 'package:flutter/material.dart';
import 'package:cagh_frontend/shared/models/appointment.dart';
import 'package:cagh_frontend/features/appointments/data/repositories/appointment_repository_impl.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';
import 'package:cagh_frontend/features/auth/presentation/midwife/midwife_login_screen.dart';
import 'package:cagh_frontend/shared/widgets/globe_language_picker.dart';
import 'package:cagh_frontend/features/appointments/data/services/appointment_api_service.dart';
import 'package:cagh_frontend/features/profile/presentation/midwife_profile_screen.dart';
import 'package:cagh_frontend/features/consultations/presentation/midwife/midwife_consults_screen.dart';
import 'package:cagh_frontend/features/scheduling/presentation/screens/midwife_schedule_screen.dart';
import 'package:cagh_frontend/features/scheduling/presentation/screens/midwife_manage_schedule_screen.dart';
import 'package:cagh_frontend/shared/widgets/floating_glass_nav_bar.dart';
import 'package:cagh_frontend/core/services/language_service.dart';

class MidwifeHomeScreen extends StatefulWidget {
  const MidwifeHomeScreen({super.key});

  @override
  State<MidwifeHomeScreen> createState() => _MidwifeHomeScreenState();
}

class _MidwifeHomeScreenState extends State<MidwifeHomeScreen> {
  String midwifeName = 'Sarah Jenkins';
  bool isLoadingProfile = true;
  int selectedIndex = 0;

  final TextEditingController _learnSearchController = TextEditingController();

  String _selectedLearnCategory = 'All';
  final Set<String> _bookmarkedArticles = {};

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _learnSearchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    try {
      final localData = await AuthService.getUserData();
      if (localData['full_name'] != null && localData['full_name'].toString().isNotEmpty && mounted) {
        setState(() {
          midwifeName = localData['full_name'].toString();
        });
      }

      final response = await AuthService.getProfile();
      if (response.success && response.data != null && mounted) {
        final profileData = response.data!;
        final fullName = profileData['full_name'] ?? profileData['email'] ?? '';
        if (fullName.toString().isNotEmpty) {
          setState(() {
            midwifeName = fullName.toString();
          });
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => isLoadingProfile = false);
    }
  }

  String _getFirstName(String fullName) {
    if (fullName.isEmpty) return 'Midwife';
    // If it happens to be an email, take the part before @
    if (fullName.contains('@')) {
      fullName = fullName.split('@').first;
    }
    // Return just the first name
    return fullName.trim().split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    if (selectedIndex == 1) {
      return Scaffold(
        extendBody: true,
        body: const MidwifeScheduleScreen(),
        bottomNavigationBar: _buildBottomBar(),
      );
    }

    if (selectedIndex == 2) {
      return Scaffold(
        extendBody: true,
        body: const MidwifeConsultsScreen(),
        bottomNavigationBar: _buildBottomBar(),
      );
    }

    if (selectedIndex == 4) {
      return Scaffold(
        extendBody: true,
        body: const MidwifeProfileScreen(),
        bottomNavigationBar: _buildBottomBar(),
      );
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFF9FAF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          _getAppBarTitle(selectedIndex),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          const GlobeLanguagePicker(iconColor: Colors.amber, iconSize: 24),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 26),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new clinical notifications')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: [
          _buildHomeDashboardTab(),
          const MidwifeScheduleScreen(),
          const MidwifeConsultsScreen(),
          _buildLearnTab(),
          const MidwifeProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return LanguageService.tr('home');
      case 1:
        return LanguageService.tr('schedule');
      case 2:
        return LanguageService.tr('consult');
      case 3:
        return LanguageService.tr('learn');
      case 4:
        return LanguageService.tr('profile');
      default:
        return LanguageService.tr('home');
    }
  }

  // TAB 0: HOME DASHBOARD
  Widget _buildHomeDashboardTab() {
    final appointmentRepo = AppointmentRepositoryImpl(AppointmentApiService());
    
    return FutureBuilder<List<Appointment>>(
      future: appointmentRepo.getMidwifeAppointments(),
      builder: (context, snapshot) {
        final aptList = snapshot.data ?? [];
        final upcomingApts = aptList.where((a) => a.status == AppointmentStatus.confirmed).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LanguageService.tr('welcome_back').toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Welcome ${_getFirstName(midwifeName)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            upcomingApts.isEmpty
                                ? 'Welcome to Digital Midwife! Your patient bookings will appear here.'
                                : 'You have ${upcomingApts.length} patient consultation bookings pending.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.87),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.medical_services_outlined, color: Colors.white, size: 48),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    LanguageService.tr('todays_appointments'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  if (upcomingApts.isNotEmpty)
                    Text(
                      '${upcomingApts.length} Total',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Manage Schedule Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MidwifeManageScheduleScreen()),
                    );
                  },
                  icon: const Icon(Icons.edit_calendar, color: Color(0xFF1B5E20)),
                  label: const Text(
                    'Manage Availability',
                    style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFF1B5E20)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
              else if (upcomingApts.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.calendar_month_outlined, size: 42, color: Colors.grey.shade400),
                      const SizedBox(height: 10),
                      Text(
                        LanguageService.tr('no_appointments'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF333333)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        LanguageService.tr('no_appointments_sub'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                      ),
                    ],
                  ),
                )
              else
                ...upcomingApts.map((apt) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildScheduleItem(
                      time: apt.startTime,
                      title: '${apt.userFullName ?? 'Patient'} - ${apt.appointmentType}',
                      subtitle: 'Date: ${apt.date}',
                      badgeLabel: 'BOOKED',
                      badgeColor: const Color(0xFFC8E6C9),
                      badgeTextColor: const Color(0xFF2E7D32),
                    ),
                  );
                }),

              const SizedBox(height: 90),
            ],
          ),
        );
      },
    );
  }

  // TAB 3: CLINICAL LEARNING HUB FOR MIDWIVES
  Widget _buildLearnTab() {
    final List<Map<String, dynamic>> articles = [
      {
        'id': 'art_1',
        'title': '2024 WHO Antenatal Care Guidelines: Comprehensive Update',
        'category': 'Obstetrics',
        'source': 'World Health Organization',
        'readTime': '6 min read',
        'summary': 'Key updates on ultrasound timing, iron supplement dosage, and routine blood pressure screening for maternal care.',
      },
      {
        'id': 'art_2',
        'title': 'Emergency Triage & Management of Severe Preeclampsia',
        'category': 'Emergency Triage',
        'source': 'Maternal Health Protocol',
        'readTime': '8 min read',
        'summary': 'Step-by-step magnesium sulfate dosing, antihypertensive administration, and fetal monitoring protocols.',
      },
      {
        'id': 'art_3',
        'title': 'Partograph Interpretation & Labor Progression',
        'category': 'Obstetrics',
        'source': 'Clinical Practice Guide',
        'readTime': '5 min read',
        'summary': 'Best practices for plotting alert lines, action lines, cervical dilation rates, and fetal descent tracking.',
      },
      {
        'id': 'art_4',
        'title': 'Golden Minute Neonatal Resuscitation Protocol',
        'category': 'Neonatal Care',
        'source': 'Pediatric & Newborn Health',
        'readTime': '7 min read',
        'summary': 'Immediate bag-mask ventilation, tactile stimulation, suctioning guidelines, and thermal control procedures.',
      },
      {
        'id': 'art_5',
        'title': 'Maternal Nutrition & Micronutrient Deficiencies',
        'category': 'Nutrition & Drugs',
        'source': 'Public Health Journal',
        'readTime': '4 min read',
        'summary': 'Addressing anemia, folic acid supplementation, calcium intake, and dietary counseling for expectant mothers.',
      },
    ];

    final filteredArticles = articles.where((art) {
      final matchesCategory = _selectedLearnCategory == 'All' || art['category'] == _selectedLearnCategory;
      final query = _learnSearchController.text.toLowerCase();
      final matchesQuery = query.isEmpty ||
          art['title'].toString().toLowerCase().contains(query) ||
          art['summary'].toString().toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LanguageService.tr('learn'),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Clinical Reference Guidelines & Evidence-Based Protocols',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.school_outlined, color: Color(0xFF1B5E20), size: 22),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Search Field
          TextField(
            controller: _learnSearchController,
            onChanged: (val) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search protocols, drugs, or WHO guidelines...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF1B5E20)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Obstetrics', 'Neonatal Care', 'Emergency Triage', 'Nutrition & Drugs'].map((cat) {
                final isSelected = _selectedLearnCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedLearnCategory = cat);
                    },
                    selectedColor: const Color(0xFF1B5E20),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF1B5E20) : Colors.grey.shade300,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),

          // Featured Video Masterclass Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'VIDEO SEMINAR',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Active Management of 3rd Stage Labor & PPH Prevention',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '15 min video guide featuring Ministry clinical leads',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Guideline Articles Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Clinical Articles & Protocols',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
              ),
              Text(
                '${filteredArticles.length} Available',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (filteredArticles.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: Text('No guidelines matching your search.', style: TextStyle(color: Colors.grey.shade600)),
            )
          else
            ...filteredArticles.map((art) {
              final isBookmarked = _bookmarkedArticles.contains(art['id']);
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            art['category'],
                            style: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                            color: isBookmarked ? const Color(0xFF1B5E20) : Colors.grey,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              if (isBookmarked) {
                                _bookmarkedArticles.remove(art['id']);
                              } else {
                                _bookmarkedArticles.add(art['id']);
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      art['title'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1A1A)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      art['summary'],
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 12.5, height: 1.3),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${art['source']} • ${art['readTime']}',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5),
                        ),
                        GestureDetector(
                          onTap: () {
                            _showArticleDetailModal(context, art);
                          },
                          child: const Row(
                            children: [
                              Text('Read Protocol', style: TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold, fontSize: 12.5)),
                              Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF1B5E20)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

          const SizedBox(height: 90),
        ],
      ),
    );
  }

  void _showArticleDetailModal(BuildContext context, Map<String, dynamic> art) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          builder: (context, controller) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: ListView(
                controller: controller,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(art['category'].toString().toUpperCase(), style: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text(art['title'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('${art['source']} • ${art['readTime']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  const Divider(height: 24),
                  const Text('Clinical Overview & Recommendations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  Text(
                    '${art['summary']}\n\n'
                    'Detailed Step-by-Step Triage Instructions:\n'
                    '1. Assess vital signs, maternal heart rate, and fetal movement frequency.\n'
                    '2. Cross-reference blood pressure readings with baseline first trimester measurements.\n'
                    '3. Prepare emergency medication kit if systolic BP > 140 mmHg or diastolic > 90 mmHg.\n'
                    '4. Document all findings in patient EHR HIPAA log immediately after consultation.',
                    style: TextStyle(color: Colors.grey.shade800, fontSize: 13.5, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                      child: const Text('Close Protocol', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  Widget _buildScheduleItem({required String time, required String title, required String subtitle, required String badgeLabel, required Color badgeColor, required Color badgeTextColor}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: Color(0xFF1B5E20), width: 4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
              Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(12)),
            child: Text(badgeLabel, style: TextStyle(color: badgeTextColor, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final items = [
      FloatingNavBarItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: LanguageService.tr('home'),
      ),
      FloatingNavBarItem(
        icon: Icons.calendar_month_outlined,
        activeIcon: Icons.calendar_month_rounded,
        label: LanguageService.tr('schedule'),
      ),
      FloatingNavBarItem(
        icon: Icons.chat_bubble_outline_rounded,
        activeIcon: Icons.chat_bubble_rounded,
        label: LanguageService.tr('consult'),
      ),
      FloatingNavBarItem(
        icon: Icons.menu_book_outlined,
        activeIcon: Icons.menu_book_rounded,
        label: LanguageService.tr('learn'),
      ),
      FloatingNavBarItem(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        label: LanguageService.tr('profile'),
      ),
    ];

    return FloatingGlassNavBar(
      selectedIndex: selectedIndex,
      items: items,
      onTabSelected: (index) {
        setState(() {
          selectedIndex = index;
        });
      },
    );
  }
}
