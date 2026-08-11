import 'package:flutter/material.dart';
import 'user_type_selection_screen.dart';
import 'package:cagh_frontend/core/services/language_service.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  late String selectedCode;

  @override
  void initState() {
    super.initState();
    selectedCode = LanguageService.currentLanguage.value;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Green App Bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              color: const Color(0xFF1B5E20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    LanguageService.tr('app_title'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    Icons.language,
                    color: Colors.yellow.shade600,
                    size: 26,
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),

                    Text(
                      LanguageService.tr('choose_language'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      LanguageService.tr('sub_choose_language'),
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: Colors.grey.shade700,
                      ),
                    ),

                    const SizedBox(height: 40),

                    Text(
                      LanguageService.tr('select_language'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF333333),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Language Dropdown
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF1B5E20),
                          width: 1.5,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCode,
                          isExpanded: true,
                          icon: const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              color: Color(0xFF1B5E20),
                              size: 24,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          borderRadius: BorderRadius.circular(12),
                          items: LanguageService.supportedLanguages.map((lang) {
                            return DropdownMenuItem<String>(
                              value: lang.code,
                              child: Row(
                                children: [
                                  Text(lang.flag, style: const TextStyle(fontSize: 18)),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${lang.nativeName} (${lang.name})',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF1A1A1A),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (code) async {
                            if (code != null) {
                              setState(() {
                                selectedCode = code;
                              });
                              await LanguageService.setLanguage(code);
                            }
                          },
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Continue Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UserTypeSelectionScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B5E20),
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

                    const SizedBox(height: 16),

                    Center(
                      child: Text(
                        LanguageService.tr('change_later'),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
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
      ),
    );
  }
}
