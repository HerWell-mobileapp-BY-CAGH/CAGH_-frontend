import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:cagh_frontend/features/auth/presentation/user/user_login_screen.dart';
import 'package:cagh_frontend/features/auth/presentation/midwife/midwife_login_screen.dart';
import 'package:cagh_frontend/features/auth/data/services/auth_api_service.dart';

class UserTypeSelectionScreen extends StatefulWidget {
  const UserTypeSelectionScreen({super.key});

  @override
  State<UserTypeSelectionScreen> createState() => _UserTypeSelectionScreenState();
}

class _UserTypeSelectionScreenState extends State<UserTypeSelectionScreen> {
  String? selectedRole; // 'user' or 'midwife'

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF6F8F5);
    final primaryDarkGreen = const Color(0xFF385A2E);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    
                    // Illustration
                    Image.asset(
                      'assets/images/home_illustration.png',
                      height: 180,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) {
                        return const Icon(
                          Icons.image_not_supported,
                          size: 90,
                          color: Colors.grey,
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    Text(
                      AppLocalizations.of(context)!.chooseJourney,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: primaryDarkGreen,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      AppLocalizations.of(context)!.subUserType,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: isDark ? Colors.white70 : const Color(0xFF757575),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // User Card - Adolescent Girls and Young Women
                    _RoleSelectionCard(
                      iconWidget: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.person_outline, size: 28, color: Color(0xFF2C2C2C)),
                          Positioned(
                            right: -6,
                            bottom: -2,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFDB89),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.favorite_border, size: 16, color: Color(0xFF2C2C2C)),
                            ),
                          ),
                        ],
                      ),
                      iconBgColor: const Color(0xFFFFDB89),
                      badgeText: 'Adolescent Girls & Young Women',
                      title: 'User Login / Sign Up',
                      subtitle: 'For adolescent girls and young women seeking care & support',
                      isSelected: selectedRole == 'user',
                      isDark: isDark,
                      onTap: () {
                        setState(() => selectedRole = 'user');
                      },
                    ),

                    const SizedBox(height: 16),

                    // Health Professional Card - Healthcare Professionals
                    _RoleSelectionCard(
                      iconWidget: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.bottomCenter,
                        children: [
                          const Icon(Icons.person_outline, size: 28, color: Color(0xFF385A2E)),
                          Positioned(
                            bottom: -2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: const BoxDecoration(
                                color: Color(0xFFD6E5D0),
                              ),
                              child: const Icon(Icons.monitor_heart_outlined, size: 16, color: Color(0xFF385A2E)),
                            ),
                          ),
                        ],
                      ),
                      iconBgColor: const Color(0xFFD6E5D0),
                      badgeText: 'Healthcare Professionals',
                      title: 'Professional Login / Sign Up',
                      subtitle: 'For healthcare professionals providing care & guidance',
                      isSelected: selectedRole == 'midwife',
                      isDark: isDark,
                      onTap: () {
                        setState(() => selectedRole = 'midwife');
                      },
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            
            // Bottom Action Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: selectedRole == null
                      ? null
                      : () {
                          if (selectedRole == 'user') {
                            AuthService.setMockRole('PATIENT');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const UserLoginScreen(),
                              ),
                            );
                          } else if (selectedRole == 'midwife') {
                            AuthService.setMockRole('MIDWIFE');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MidwifeLoginScreen(),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryDarkGreen,
                    disabledBackgroundColor: const Color(0xFFE0E0E0),
                    disabledForegroundColor: const Color(0xFF9E9E9E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          selectedRole == 'user'
                              ? 'Continue to User Login'
                              : (selectedRole == 'midwife'
                                  ? 'Continue to Professional Login'
                                  : AppLocalizations.of(context)!.continueBtn),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleSelectionCard extends StatelessWidget {
  final Widget iconWidget;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final String? badgeText;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _RoleSelectionCard({
    required this.iconWidget,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    this.badgeText,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(minHeight: 104),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF385A2E)
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Center(child: iconWidget),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (badgeText != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF385A2E).withValues(alpha: 0.12)
                            : (isDark ? Colors.white10 : const Color(0xFFEFF3EE)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText!,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? const Color(0xFF385A2E)
                              : (isDark ? Colors.white70 : const Color(0xFF4C6B43)),
                        ),
                      ),
                    ),
                  ],
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1C1C1E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.3,
                      color: isDark ? Colors.white70 : const Color(0xFF757575),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF385A2E) : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF385A2E) : const Color(0xFF8C8C8C),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
