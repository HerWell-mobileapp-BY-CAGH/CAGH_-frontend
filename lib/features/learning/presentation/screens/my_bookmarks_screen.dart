import 'package:flutter/material.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:cagh_frontend/features/learning/data/repositories/learning_repository.dart';
import 'package:cagh_frontend/features/learning/data/services/learning_bookmark_service.dart';
import 'package:cagh_frontend/features/learning/presentation/screens/learning_material_detail_screen.dart';
import 'package:cagh_frontend/features/learning/presentation/screens/learning_center_screen.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/shared/widgets/custom_snackbar.dart';

class MyBookmarksScreen extends StatefulWidget {
  final bool isMidwife;

  const MyBookmarksScreen({
    super.key,
    this.isMidwife = false,
  });

  @override
  State<MyBookmarksScreen> createState() => _MyBookmarksScreenState();
}

class _MyBookmarksScreenState extends State<MyBookmarksScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    await LearningBookmarkService.init();
    await LearningRepository.fetchModules();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final allModules = LearningRepository.getModules();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor ??
            (isDark ? theme.scaffoldBackgroundColor : Colors.white),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.myBookmarks,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : ValueListenableBuilder<Set<String>>(
              valueListenable: LearningBookmarkService.bookmarksNotifier,
              builder: (context, bookmarkedIds, _) {
                final bookmarkedModules = allModules
                    .where((m) => bookmarkedIds.contains(m.id))
                    .toList();

                if (bookmarkedModules.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.bookmark_border_rounded,
                              size: 44,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            l10n.noBookmarksYet,
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.noBookmarksDesc,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 26),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LearningCenterScreen(
                                    isMidwife: widget.isMidwife,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.explore_outlined, color: Colors.white, size: 18),
                            label: Text(
                              l10n.exploreLearningModules,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: bookmarkedModules.length,
                  itemBuilder: (context, index) {
                    final module = bookmarkedModules[index];
                    final title = module.getTitle(l10n);
                    final desc = module.getDesc(l10n);
                    final badge = widget.isMidwife ? module.midwifeBadge : module.userBadge;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: [
                          if (!isDark)
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LearningMaterialDetailScreen(
                                module: module,
                                isMidwife: widget.isMidwife,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                    child: Icon(
                                      module.icon,
                                      color: module.themeColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: module.themeColor.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            badge.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: module.themeColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          title,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.bookmark_rounded,
                                      color: AppColors.primaryGreen,
                                    ),
                                    tooltip: 'Remove Bookmark',
                                    onPressed: () async {
                                      await LearningBookmarkService.removeBookmark(module.id);
                                      if (context.mounted) {
                                        CustomSnackBar.show(
                                          context,
                                          message: 'Removed "$title" from bookmarks',
                                          type: SnackBarType.info,
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                desc,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                                  height: 1.35,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 14,
                                    color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    module.readTime,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Icon(
                                    Icons.menu_book_rounded,
                                    size: 14,
                                    color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${module.topicsCovered.length} Topics',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                                    ),
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      Text(
                                        'Read',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          color: module.themeColor,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        size: 18,
                                        color: module.themeColor,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
