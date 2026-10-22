import 'package:flutter/material.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:cagh_frontend/features/learning/domain/models/learning_module.dart';
import 'package:cagh_frontend/features/learning/data/services/learning_bookmark_service.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/shared/widgets/custom_snackbar.dart';

class LearningMaterialDetailScreen extends StatefulWidget {
  final LearningModuleItem module;
  final int initialTopicIndex;
  final bool isMidwife;

  const LearningMaterialDetailScreen({
    super.key,
    required this.module,
    this.initialTopicIndex = 0,
    this.isMidwife = false,
  });

  @override
  State<LearningMaterialDetailScreen> createState() =>
      _LearningMaterialDetailScreenState();
}

class _LearningMaterialDetailScreenState
    extends State<LearningMaterialDetailScreen> {
  late int _currentTopicIndex;
  final ScrollController _scrollController = ScrollController();
  final Set<int> _checkedActionIndices = {};
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _currentTopicIndex = (widget.initialTopicIndex >= 0 &&
            widget.initialTopicIndex < widget.module.topicContents.length)
        ? widget.initialTopicIndex
        : 0;
    _checkBookmarkStatus();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkBookmarkStatus() async {
    final isBm = await LearningBookmarkService.isBookmarked(widget.module.id);
    if (mounted) {
      setState(() => _isBookmarked = isBm);
    }
  }

  Future<void> _toggleBookmark() async {
    final l10n = AppLocalizations.of(context)!;
    final title = widget.module.getTitle(l10n);
    final isNowBookmarked =
        await LearningBookmarkService.toggleBookmark(widget.module.id);

    if (mounted) {
      setState(() => _isBookmarked = isNowBookmarked);
      CustomSnackBar.show(
        context,
        message: isNowBookmarked
            ? 'Saved "$title" to bookmarks'
            : 'Removed "$title" from bookmarks',
        type: isNowBookmarked ? SnackBarType.success : SnackBarType.info,
      );
    }
  }

  void _switchTopic(int index) {
    if (index >= 0 && index < widget.module.topicContents.length) {
      setState(() {
        _currentTopicIndex = index;
        _checkedActionIndices.clear();
      });
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final module = widget.module;
    final title = module.getTitle(l10n);
    final themeColor = module.themeColor;

    final topic = (module.topicContents.isNotEmpty &&
            _currentTopicIndex < module.topicContents.length)
        ? module.topicContents[_currentTopicIndex]
        : null;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: _isBookmarked ? AppColors.primaryGreen : (isDark ? Colors.white70 : Colors.black87),
            ),
            tooltip: _isBookmarked ? 'Remove Bookmark' : 'Add to Bookmarks',
            onPressed: _toggleBookmark,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: topic == null
          ? const Center(child: Text('No topic content found'))
          : Column(
              children: [
                // 1. Horizontal Topics Tab Bar
                Container(
                  width: double.infinity,
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: module.topicsCovered.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final topicName = entry.value;
                        final isSelected = idx == _currentTopicIndex;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: InkWell(
                            onTap: () => _switchTopic(idx),
                            borderRadius: BorderRadius.circular(20),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? themeColor
                                    : (isDark
                                        ? const Color(0xFF2C2C2C)
                                        : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? themeColor
                                      : (isDark
                                          ? Colors.grey.shade800
                                          : const Color(0xFFCBD5E1)),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white.withValues(alpha: 0.25)
                                          : themeColor.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${idx + 1}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Colors.white
                                              : themeColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    topicName,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark
                                              ? Colors.grey.shade300
                                              : const Color(0xFF334155)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const Divider(height: 1),

                // 2. Reading Content
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Badge & Read Time
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: themeColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                module.category.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: themeColor,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 14,
                                  color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  topic.readTime,
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
                        const SizedBox(height: 12),

                        // Topic Title
                        Text(
                          topic.title,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Part ${_currentTopicIndex + 1} of ${module.topicContents.length}',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: themeColor,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Summary Box
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? themeColor.withValues(alpha: 0.12)
                                : themeColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: themeColor.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.lightbulb_outline_rounded,
                                  color: themeColor, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  topic.summary,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.grey.shade200
                                        : const Color(0xFF1E293B),
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Key Learning Points
                        Text(
                          'KEY LEARNING POINTS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...topic.keyPoints.map(
                          (point) => Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.check_circle_rounded,
                                    size: 16,
                                    color: themeColor,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    point,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? Colors.grey.shade200
                                          : const Color(0xFF334155),
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Detailed Reading Body
                        Text(
                          'IN-DEPTH GUIDE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            topic.detailedBody,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
                              height: 1.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Role Specific Callout
                        if (widget.isMidwife && topic.clinicalTip != null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF142416) : const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF86EFAC),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.medical_services_rounded,
                                    color: Color(0xFF16A34A), size: 22),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'CLINICAL & PROVIDER PROTOCOL',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF15803D),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        topic.clinicalTip!,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark ? Colors.grey.shade200 : const Color(0xFF166534),
                                          height: 1.45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ] else if (!widget.isMidwife && topic.patientAdvice != null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF261D13) : const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFFDE68A),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.favorite_rounded,
                                    color: Color(0xFFD97706), size: 22),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'PERSONAL HEALTH TAKEAWAY',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFB45309),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        topic.patientAdvice!,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark ? Colors.grey.shade200 : const Color(0xFF92400E),
                                          height: 1.45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Action Checklist
                        if (topic.actionChecklist != null &&
                            topic.actionChecklist!.isNotEmpty) ...[
                          Text(
                            'ACTIONABLE NEXT STEPS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...topic.actionChecklist!.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final action = entry.value;
                            final isChecked = _checkedActionIndices.contains(idx);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    if (isChecked) {
                                      _checkedActionIndices.remove(idx);
                                    } else {
                                      _checkedActionIndices.add(idx);
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E1E1E)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isChecked
                                          ? themeColor
                                          : (isDark
                                              ? Colors.grey.shade800
                                              : const Color(0xFFE2E8F0)),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isChecked
                                            ? Icons.check_box_rounded
                                            : Icons.check_box_outline_blank_rounded,
                                        color: isChecked
                                            ? themeColor
                                            : Colors.grey.shade400,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          action,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: isChecked
                                                ? (isDark
                                                    ? Colors.grey.shade400
                                                    : Colors.grey.shade600)
                                                : (isDark
                                                    ? Colors.white
                                                    : const Color(0xFF1E293B)),
                                            decoration: isChecked
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              if (_currentTopicIndex > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _switchTopic(_currentTopicIndex - 1),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Previous', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: themeColor),
                      foregroundColor: themeColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                  ),
                ),
              if (_currentTopicIndex > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (_currentTopicIndex < module.topicContents.length - 1) {
                      _switchTopic(_currentTopicIndex + 1);
                    } else {
                      CustomSnackBar.show(
                        context,
                        message: 'Completed "${module.category}" learning guide!',
                        type: SnackBarType.success,
                      );
                      Navigator.pop(context);
                    }
                  },
                  icon: Icon(
                    _currentTopicIndex < module.topicContents.length - 1
                        ? Icons.arrow_forward_rounded
                        : Icons.check_circle_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: Text(
                    _currentTopicIndex < module.topicContents.length - 1
                        ? 'Next: Topic ${_currentTopicIndex + 2}'
                        : 'Finish Module',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
