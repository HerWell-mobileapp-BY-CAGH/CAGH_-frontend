import 'package:flutter/material.dart';
import 'package:cagh_frontend/core/services/auth_service.dart';
import 'package:cagh_frontend/core/services/language_service.dart';
import 'package:cagh_frontend/features/auth/presentation/user/user_login_screen.dart';
import 'package:cagh_frontend/features/profile/presentation/personal_information_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final VoidCallback? onBackTap;
  const UserProfileScreen({super.key, this.onBackTap});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool isLoading = true;
  bool notificationsEnabled = true;
  String fullName = 'User Profile';
  String email = 'user@cagh.org';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final localData = await AuthService.getUserData();
      if (mounted) {
        setState(() {
          if (localData['full_name'] != null && localData['full_name'].toString().isNotEmpty) {
            fullName = localData['full_name'].toString();
          }
          if (localData['email'] != null && localData['email'].toString().isNotEmpty) {
            email = localData['email'].toString();
          } else if (localData['phone_number'] != null && localData['phone_number'].toString().isNotEmpty) {
            email = localData['phone_number'].toString();
          }
        });
      }

      final res = await AuthService.getProfile();
      if (res.success && res.data != null && mounted) {
        final d = res.data!;
        setState(() {
          if (d['full_name'] != null && d['full_name'].toString().isNotEmpty) {
            fullName = d['full_name'].toString();
          }
          if (d['email'] != null && d['email'].toString().isNotEmpty) {
            email = d['email'].toString();
          } else if (d['phone_number'] != null) {
            email = d['phone_number'].toString();
          }
        });
      }
    } catch (_) {}
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeLang = LanguageService.currentLanguage.value == 'am'
        ? 'Amharic (አማርኛ)'
        : 'English (US)';

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.amber),
          onPressed: () {
            if (widget.onBackTap != null) {
              widget.onBackTap!();
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'User Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  // User Avatar Header
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PersonalInformationScreen(),
                              ),
                            ).then((_) => _fetchProfile());
                          },
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.amber,
                                ),
                                child: CircleAvatar(
                                  radius: 42,
                                  backgroundColor: const Color(0xFFE8F5E9),
                                  child: Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1B5E20),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          fullName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 1. Account & Records
                  _buildSectionHeader('Account & Records'),
                  const SizedBox(height: 10),
                  _buildGroupedCard([
                    _buildListTile(
                      icon: Icons.person_outline,
                      title: 'Personal Information',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PersonalInformationScreen(),
                          ),
                        ).then((_) => _fetchProfile());
                      },
                    ),
                    _buildDivider(),
                    _buildListTile(
                      icon: Icons.assignment_outlined,
                      title: 'Medical Records',
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildListTile(
                      icon: Icons.calendar_today_outlined,
                      title: 'Appointments',
                      badge: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '1 UPCOMING',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ),
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildListTile(
                      icon: Icons.history_toggle_off_rounded,
                      title: 'Consultation History',
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildListTile(
                      icon: Icons.bookmark_outline_rounded,
                      title: 'Saved Midwives',
                      onTap: () {},
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // 2. Settings
                  _buildSectionHeader('Settings'),
                  const SizedBox(height: 10),
                  _buildGroupedCard([
                    _buildListTile(
                      icon: Icons.language_rounded,
                      title: 'Language',
                      subtitle: activeLang,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFA5D6A7)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: LanguageService.currentLanguage.value,
                            isDense: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF1B5E20), size: 20),
                            borderRadius: BorderRadius.circular(12),
                            items: LanguageService.supportedLanguages.map((lang) {
                              return DropdownMenuItem<String>(
                                value: lang.code,
                                child: Text(
                                  '${lang.flag} ${lang.nativeName}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? code) async {
                              if (code != null) {
                                await LanguageService.setLanguage(code);
                                if (mounted) setState(() {});
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    _buildDivider(),
                    _buildListTile(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications',
                      trailing: Switch(
                        value: notificationsEnabled,
                        activeColor: const Color(0xFF1B5E20),
                        onChanged: (val) {
                          setState(() => notificationsEnabled = val);
                        },
                      ),
                    ),
                    _buildDivider(),
                    _buildListTile(
                      icon: Icons.shield_outlined,
                      title: 'Privacy & Security',
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildListTile(
                      icon: Icons.contact_phone_outlined,
                      title: 'Emergency Contacts',
                      onTap: () {},
                    ),
                  ]),

                  const SizedBox(height: 24),

                  // 3. Support
                  _buildSectionHeader('Support'),
                  const SizedBox(height: 10),
                  _buildGroupedCard([
                    _buildListTile(
                      icon: Icons.help_outline_rounded,
                      title: 'Help & Support',
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _buildListTile(
                      icon: Icons.info_outline_rounded,
                      title: 'About Bloom',
                      onTap: () {},
                    ),
                  ]),

                  const SizedBox(height: 28),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await AuthService.logout();
                        if (mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UserLoginScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Version 2.4.1 (Build 890)',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.grey.shade500,
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 3.5,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFF1B5E20),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1B5E20),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupedCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? badge,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(icon, color: const Color(0xFF1B5E20), size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF222222),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            )
          : null,
      trailing: trailing ??
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (badge != null) ...[badge, const SizedBox(width: 8)],
              Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 22),
            ],
          ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade100,
      indent: 16,
      endIndent: 16,
    );
  }
}
