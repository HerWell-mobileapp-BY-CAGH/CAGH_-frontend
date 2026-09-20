import 'package:flutter/material.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/shared/widgets/custom_snackbar.dart';

class LearningModuleItem {
  final String id;
  final String category;
  final IconData icon;
  final Color themeColor;
  final Color bgLight;
  final Color bgDark;
  final String readTime;
  final String articlesCount;
  final String userBadge;
  final String midwifeBadge;
  final String Function(AppLocalizations l10n) getTitle;
  final String Function(AppLocalizations l10n) getDesc;
  final List<String> keyTakeaways;
  final List<String> topicsCovered;

  LearningModuleItem({
    required this.id,
    required this.category,
    required this.icon,
    required this.themeColor,
    required this.bgLight,
    required this.bgDark,
    required this.readTime,
    required this.articlesCount,
    required this.userBadge,
    required this.midwifeBadge,
    required this.getTitle,
    required this.getDesc,
    required this.keyTakeaways,
    required this.topicsCovered,
  });
}

class LearningCenterScreen extends StatefulWidget {
  final bool isMidwife;

  const LearningCenterScreen({
    super.key,
    this.isMidwife = false,
  });

  @override
  State<LearningCenterScreen> createState() => _LearningCenterScreenState();
}

class _LearningCenterScreenState extends State<LearningCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  final Set<String> _bookmarkedModuleIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LearningModuleItem> _getModules() {
    return [
      LearningModuleItem(
        id: 'adolescent_health',
        category: 'Nutrition & Growth',
        icon: Icons.spa_rounded,
        themeColor: const Color(0xFF2E7D32),
        bgLight: const Color(0xFFE8F5E9),
        bgDark: const Color(0xFF1B431E),
        readTime: '6 min read',
        articlesCount: '12 Guides',
        userBadge: 'Essential Health',
        midwifeBadge: 'Patient Education',
        getTitle: (l10n) => l10n.adolescentGirlsHealthAndNutrition,
        getDesc: (l10n) => l10n.adolescentGirlsHealthAndNutritionDesc,
        keyTakeaways: [
          'Understanding growth spurts, hormonal changes, and menstrual hygiene.',
          'Essential iron, micronutrient, and dietary guidelines for adolescent growth.',
          'Building positive body image, life skills, and mental well-being.',
        ],
        topicsCovered: [
          'Puberty & Hormonal Development',
          'Menstrual Hygiene Management (MHM)',
          'Iron & Anemia Prevention Nutrition',
          'Healthy Body Image & Physical Fitness',
        ],
      ),
      LearningModuleItem(
        id: 'prevention_awareness',
        category: 'Prevention & Safety',
        icon: Icons.shield_rounded,
        themeColor: const Color(0xFFE65100),
        bgLight: const Color(0xFFFFF3E0),
        bgDark: const Color(0xFF4A2500),
        readTime: '8 min read',
        articlesCount: '10 Guides',
        userBadge: 'Awareness & Safety',
        midwifeBadge: 'Clinical Guideline',
        getTitle: (l10n) => l10n.preventionAndAwareness,
        getDesc: (l10n) => l10n.preventionAndAwarenessDesc,
        keyTakeaways: [
          'Comprehensive STI & HIV prevention strategies and barrier protection.',
          'HPV vaccination schedules and early cervical cancer screening awareness.',
          'Identifying healthy vs unhealthy relationships and boundary setting.',
        ],
        topicsCovered: [
          'STI & HIV Transmission & Prevention',
          'HPV Vaccination & Pap Smear Awareness',
          'Consensual & Healthy Relationships',
          'Community Health Advocacy & Stigma Reduction',
        ],
      ),
      LearningModuleItem(
        id: 'psychosocial_support',
        category: 'Psychosocial & Support',
        icon: Icons.favorite_rounded,
        themeColor: const Color(0xFFC2185B),
        bgLight: const Color(0xFFFCE4EC),
        bgDark: const Color(0xFF4A1027),
        readTime: '7 min read',
        articlesCount: '14 Guides',
        userBadge: 'Mental Wellness',
        midwifeBadge: 'Crisis Response',
        getTitle: (l10n) => l10n.psychosocialSupportAndProtection,
        getDesc: (l10n) => l10n.psychosocialSupportAndProtectionDesc,
        keyTakeaways: [
          'Recognizing signs of anxiety, depression, and trauma in maternal care.',
          'Gender-Based Violence (GBV) survivor support, referral pathways, and safety planning.',
          'Accessing confidential emergency hotlines, counseling, and social support services.',
        ],
        topicsCovered: [
          'Perinatal & Postpartum Mental Health',
          'GBV First Line Support & Safe Referrals',
          'Stress Management & Self-Care Practices',
          'Community Support Groups & Hotlines',
        ],
      ),
      LearningModuleItem(
        id: 'reproductive_health',
        category: 'Reproductive & Care',
        icon: Icons.medical_services_rounded,
        themeColor: const Color(0xFF00796B),
        bgLight: const Color(0xFFE0F2F1),
        bgDark: const Color(0xFF003630),
        readTime: '10 min read',
        articlesCount: '16 Guides',
        userBadge: 'Maternal Care',
        midwifeBadge: 'Obstetric Standard',
        getTitle: (l10n) => l10n.reproductiveHealthAndCare,
        getDesc: (l10n) => l10n.reproductiveHealthAndCareDesc,
        keyTakeaways: [
          'Family planning options, birth control methods, and fertility awareness.',
          'Antenatal Care (ANC) schedule, danger signs during pregnancy, and nutrition.',
          'Essential newborn care, breastfeeding support, and postnatal checkups.',
        ],
        topicsCovered: [
          'Contraception Methods & Family Planning',
          'Antenatal Care (ANC) Milestone Checklist',
          'Warning Signs in Pregnancy & Labor Prep',
          'Postnatal Recovery & Infant Care',
        ],
      ),
    ];
  }

  void _toggleBookmark(String id, String title) {
    setState(() {
      if (_bookmarkedModuleIds.contains(id)) {
        _bookmarkedModuleIds.remove(id);
        CustomSnackBar.show(context, message: 'Removed "$title" from bookmarks');
      } else {
        _bookmarkedModuleIds.add(id);
        CustomSnackBar.show(context, message: 'Saved "$title" to bookmarks', isSuccess: true);
      }
    });
  }

  void _showModuleDetailModal(BuildContext context, LearningModuleItem module) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = module.getTitle(l10n);
    final desc = module.getDesc(l10n);
    final isBookmarked = _bookmarkedModuleIds.contains(module.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: 24 + MediaQuery.of(modalContext).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header Badge & Read Time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: module.themeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            module.category.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: module.themeColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.schedule_rounded, size: 14, color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(
                              module.readTime,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Title & Description
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      desc,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey.shade300 : const Color(0xFF475569),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Key Takeaways Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lightbulb_outline_rounded, size: 18, color: module.themeColor),
                              const SizedBox(width: 8),
                              Text(
                                'KEY TAKEAWAYS',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: module.themeColor,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...module.keyTakeaways.map((takeaway) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.check_circle_rounded, size: 16, color: module.themeColor),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        takeaway,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? Colors.grey.shade200 : const Color(0xFF334155),
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Topics Covered List
                    Text(
                      'TOPICS COVERED IN THIS MODULE',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...module.topicsCovered.asMap().entries.map((entry) {
                      final idx = entry.key + 1;
                      final topic = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade900 : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: module.themeColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '$idx',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: module.themeColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                topic,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey.shade400),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 24),

                    // Action Buttons Row
                    Row(
                      children: [
                        IconButton.outlined(
                          onPressed: () {
                            setModalState(() {});
                            _toggleBookmark(module.id, title);
                          },
                          style: IconButton.styleFrom(
                            side: BorderSide(
                              color: isBookmarked ? AppColors.primaryGreen : (isDark ? Colors.grey.shade700 : const Color(0xFFCBD5E1)),
                            ),
                            padding: const EdgeInsets.all(14),
                          ),
                          icon: Icon(
                            isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            color: isBookmarked ? AppColors.primaryGreen : (isDark ? Colors.white70 : const Color(0xFF475569)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(modalContext);
                                CustomSnackBar.show(
                                  context,
                                  message: 'Opening "${module.category}" learning guide...',
                                  isSuccess: true,
                                );
                              },
                              icon: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 18),
                              label: Text(
                                widget.isMidwife ? 'Access Clinical Guide' : 'Start Reading Module',
                                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allModules = _getModules();

    final categories = ['All', 'Nutrition & Growth', 'Prevention & Safety', 'Psychosocial & Support', 'Reproductive & Care'];

    final query = _searchController.text.trim().toLowerCase();
    final filteredModules = allModules.where((m) {
      final matchesCategory = _selectedCategory == 'All' || m.category == _selectedCategory;
      final mTitle = m.getTitle(l10n).toLowerCase();
      final mDesc = m.getDesc(l10n).toLowerCase();
      final matchesSearch = query.isEmpty || mTitle.contains(query) || mDesc.contains(query) || m.category.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Role-tailored Hero Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E3A1E), const Color(0xFF2E4823)]
                      : [AppColors.backgroundMintWhiteAlt, AppColors.backgroundMintWhite],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark ? Colors.grey.shade800 : AppColors.borderGreenGray,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.isMidwife ? Icons.verified_user_outlined : Icons.verified_outlined,
                              size: 14,
                              color: isDark ? const Color(0xFF81C784) : AppColors.primaryGreenDarker,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.isMidwife ? 'CLINICAL LEARNING HUB' : 'CERTIFIED HEALTH GUIDES',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFF81C784) : AppColors.primaryGreenDarker,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        widget.isMidwife ? Icons.medical_services_outlined : Icons.menu_book_rounded,
                        color: isDark ? Colors.white70 : AppColors.primaryGreen,
                        size: 26,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.isMidwife ? 'Midwife Knowledge & Clinical Hub' : 'Empower Your Maternal Health',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.primaryGreenDarker,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.isMidwife
                        ? 'Evidence-based clinical guidelines, patient counseling toolkits, & reference protocols.'
                        : 'Explore medically reviewed guides on adolescent health, nutrition, reproductive care, & safety.',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: isDark ? Colors.grey.shade300 : AppColors.sageGrey,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Search Field
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: widget.isMidwife ? 'Search clinical guides & topics...' : 'Search health guides & topics...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryGreen, size: 22),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? Colors.grey.shade900 : Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Category Filter Chips (Horizontal Scrollable)
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, idx) {
                  final cat = categories[idx];
                  final isSel = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(cat),
                      selected: isSel,
                      showCheckmark: false,
                      onSelected: (sel) {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      },
                      labelStyle: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                        color: isSel
                            ? Colors.white
                            : (isDark ? Colors.grey.shade300 : const Color(0xFF475569)),
                      ),
                      backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
                      selectedColor: AppColors.primaryGreen,
                      side: BorderSide(
                        color: isSel
                            ? AppColors.primaryGreen
                            : (isDark ? Colors.grey.shade800 : const Color(0xFFCBD5E1)),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // 4. Learning Module Cards List
            if (filteredModules.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'No learning modules found',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Try clearing your search query or selecting "All" categories.',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _selectedCategory = 'All';
                          });
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.primaryGreen),
                        label: const Text('Reset Filters', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredModules.length,
                itemBuilder: (context, index) {
                  final module = filteredModules[index];
                  final title = module.getTitle(l10n);
                  final desc = module.getDesc(l10n);
                  final badge = widget.isMidwife ? module.midwifeBadge : module.userBadge;
                  final isBookmarked = _bookmarkedModuleIds.contains(module.id);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade900 : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _showModuleDetailModal(context, module),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Info Row (Badge & Read time & Bookmark)
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: module.themeColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      badge,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: module.themeColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '•  ${module.readTime}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () => _toggleBookmark(module.id, title),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Icon(
                                        isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                        size: 20,
                                        color: isBookmarked ? AppColors.primaryGreen : Colors.grey.shade400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Main Row: Icon + Title & Description
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: isDark ? module.bgDark : module.bgLight,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        module.icon,
                                        color: isDark ? Colors.white : module.themeColor,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            height: 1.25,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          desc,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(height: 1, thickness: 1),
                              const SizedBox(height: 12),

                              // Bottom Action Row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.collections_bookmark_outlined, size: 14, color: Color(0xFF64748B)),
                                      const SizedBox(width: 6),
                                      Text(
                                        module.articlesCount,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        widget.isMidwife ? 'Clinical Reference' : 'Explore Guide',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryGreen,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 15,
                                        color: AppColors.primaryGreen,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }
}
