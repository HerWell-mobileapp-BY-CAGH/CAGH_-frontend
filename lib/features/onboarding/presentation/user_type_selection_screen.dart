import 'package:flutter/material.dart';
import 'package:cagh_frontend/features/auth/presentation/user/user_login_screen.dart';
import 'package:cagh_frontend/features/auth/presentation/midwife/midwife_login_screen.dart';
import 'package:cagh_frontend/core/services/auth_service.dart';
import 'package:cagh_frontend/core/services/language_service.dart';

class UserTypeSelectionScreen extends StatefulWidget {
  const UserTypeSelectionScreen({super.key});

  @override
  State<UserTypeSelectionScreen> createState() =>
      _UserTypeSelectionScreenState();
}

class _UserTypeSelectionScreenState extends State<UserTypeSelectionScreen> {
  String? selectedRole; // 'user' or 'midwife'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      body: Column(
        children: [
          // Green App Bar
          Container(
            width: double.infinity,
            color: const Color(0xFF1B5E20),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.amber),
                    ),
                    Expanded(
                      child: Text(
                        LanguageService.tr('app_title'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 32),

                  // Illustration
                  Container(
                    width: 180,
                    height: 180,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFFF0E0),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/home_illustration.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return const Icon(
                            Icons.person,
                            size: 90,
                            color: Color(0xFF1B5E20),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    LanguageService.tr('choose_journey'),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B5E20),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    LanguageService.tr('sub_user_type'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: Colors.grey.shade700,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // User Card
                  _RoleCard(
                    icon: Icons.person,
                    iconBgColor: const Color(0xFFFFC107),
                    title: LanguageService.tr('user_title'),
                    subtitle: LanguageService.tr('user_subtitle'),
                    isSelected: selectedRole == 'user',
                    onTap: () {
                      setState(() => selectedRole = 'user');
                      AuthService.setMockRole('PATIENT');
                    },
                  ),

                  const SizedBox(height: 16),

                  // Midwife Card
                  _RoleCard(
                    icon: Icons.medical_services,
                    iconBgColor: const Color(0xFF4CAF50),
                    title: LanguageService.tr('midwife_title'),
                    subtitle: LanguageService.tr('midwife_subtitle'),
                    isSelected: selectedRole == 'midwife',
                    onTap: () {
                      setState(() => selectedRole = 'midwife');
                      AuthService.setMockRole('MIDWIFE');
                    },
                  ),

                  const SizedBox(height: 40),

                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: selectedRole == null
                          ? null
                          : () {
                        if (selectedRole == 'user') {
                          AuthService.setMockRole('PATIENT');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                              const UserLoginScreen(),
                            ),
                          );
                        } else if (selectedRole == 'midwife') {
                          AuthService.setMockRole('MIDWIFE');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                              const MidwifeLoginScreen(),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        disabledBackgroundColor: Colors.grey.shade400,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            LanguageService.tr('continue'),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1B5E20)
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
