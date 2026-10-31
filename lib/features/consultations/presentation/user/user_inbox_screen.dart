import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/features/consultations/data/services/chat_api_service.dart';
import 'package:cagh_frontend/features/consultations/data/services/midwife_api_service.dart';
import 'package:cagh_frontend/features/consultations/data/repositories/midwife_repository_impl.dart';
import 'package:cagh_frontend/shared/models/midwife_profile.dart';
import 'package:cagh_frontend/features/consultations/presentation/user/chat_screen.dart';
import 'package:cagh_frontend/shared/widgets/app_profile_avatar.dart';
import 'package:cagh_frontend/features/notifications/presentation/providers/notification_provider.dart';
import 'package:intl/intl.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';

class UserInboxScreen extends ConsumerStatefulWidget {
  const UserInboxScreen({super.key});

  @override
  ConsumerState<UserInboxScreen> createState() => _UserInboxScreenState();
}

class _UserInboxScreenState extends ConsumerState<UserInboxScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final MidwifeRepositoryImpl _midwifeRepository = MidwifeRepositoryImpl(MidwifeApiService());

  bool _isLoading = true;
  List<Map<String, dynamic>> _rooms = [];
  List<MidwifeProfile> _midwives = [];
  List<MidwifeProfile> _filteredMidwives = [];
  Map<String, String> _midwifeNames = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // 1. Load Midwives List
    try {
      final mwData = await _midwifeRepository.getMidwives();
      final verified = mwData.where((m) =>
        m.verificationStatus.toUpperCase() == 'APPROVED' ||
        m.verificationStatus.toUpperCase() == 'VERIFIED'
      ).toList();

      final namesMap = <String, String>{};
      for (var mw in mwData) {
        namesMap[mw.id.toString()] = mw.fullName.isNotEmpty ? mw.fullName : 'Health Professional';
      }

      if (mounted) {
        setState(() {
          _midwives = verified.isNotEmpty ? verified : mwData;
          _filteredMidwives = _midwives;
          _midwifeNames = namesMap;
        });
      }
    } catch (e) {
      debugPrint("Error loading midwives in inbox: $e");
    }

    // 2. Load Chat Rooms
    try {
      final rooms = await ChatApiService.getChatRooms();
      final uniqueRooms = <String, Map<String, dynamic>>{};

      for (var room in rooms) {
        final mwId = _extractMidwifeId(room);
        if (!uniqueRooms.containsKey(mwId)) {
          uniqueRooms[mwId] = room;
        } else {
          final existingStatus = uniqueRooms[mwId]!['status'];
          final newStatus = room['status'];
          if (existingStatus == 'REQUESTED' && newStatus != 'REQUESTED') {
            uniqueRooms[mwId] = room;
          }
        }
      }

      if (mounted) {
        setState(() {
          _rooms = uniqueRooms.values.toList();
        });
        ref.read(notificationProvider.notifier).refreshNotifications();
      }
    } catch (e) {
      debugPrint("Error loading chat rooms in inbox: $e");
      if (mounted) {
        setState(() {
          _rooms = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredMidwives = _midwives;
      } else {
        _filteredMidwives = _midwives.where((m) =>
          m.fullName.toLowerCase().contains(_searchQuery) ||
          m.specialty.toLowerCase().contains(_searchQuery)
        ).toList();
      }
    });
  }

  String _extractMidwifeName(Map<String, dynamic> room) {
    final dynamic mwData = room['midwife_detail'] ?? room['midwife'];
    final dynamic mwUser = _mapPath('user', mwData);
    final dynamic mwProfile = _mapPath('profile', mwUser);

    if (mwProfile is Map) {
      final fName = mwProfile['first_name']?.toString() ?? '';
      final lName = mwProfile['last_name']?.toString() ?? '';
      if (fName.isNotEmpty || lName.isNotEmpty) {
        return '$fName $lName'.trim();
      }
    } else if (mwUser is Map) {
      final fName = mwUser['first_name']?.toString() ?? '';
      final lName = mwUser['last_name']?.toString() ?? '';
      if (fName.isNotEmpty || lName.isNotEmpty) {
        return '$fName $lName'.trim();
      }
      final name = mwUser['name']?.toString() ?? '';
      if (name.isNotEmpty) return name;
    } else if (mwData is Map) {
      final name = mwData['name'] ?? mwData['full_name'];
      if (name is String && name.isNotEmpty) return name;
    }

    final midwifeId = _extractMidwifeId(room);
    if (_midwifeNames.containsKey(midwifeId)) {
      return _midwifeNames[midwifeId]!;
    }

    return 'Health Professional';
  }

  String _extractMidwifeId(Map<String, dynamic> room) {
    final dynamic mwData = room['midwife_detail'] ?? room['midwife'];
    if (mwData is Map) {
      final id = mwData['id'] ?? mwData['user_id'];
      if (id != null) return id.toString();
    } else if (mwData is String || mwData is int) {
      return mwData.toString();
    }
    return room['midwife_id']?.toString() ?? '';
  }

  dynamic _mapPath(String path, dynamic root) {
    if (root == null || root is! Map) return null;
    if (path.startsWith('#')) {
      final key = path.substring(1);
      return root[key] ?? _mapPath(key, root['user']) ?? _mapPath(key, root['profile']);
    }
    return root[path];
  }

  void _openChatWithMidwife(MidwifeProfile mw) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          midwifeId: mw.id.toString(),
          midwifeName: mw.fullName,
        ),
      ),
    ).then((_) {
      _loadData();
      ref.read(notificationProvider.notifier).refreshNotifications();
    });
  }

  void _openChatWithRoom(Map<String, dynamic> room) {
    final midwifeId = _extractMidwifeId(room);
    final midwifeName = _extractMidwifeName(room);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatRoomId: room['id']?.toString(),
          midwifeId: midwifeId,
          midwifeName: midwifeName,
        ),
      ),
    ).then((_) {
      _loadData();
      ref.read(notificationProvider.notifier).refreshNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF385A2E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.messages,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentYellow,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
          tabs: [
            Tab(
              icon: const Icon(Icons.forum_outlined, size: 20),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  AppLocalizations.of(context)!.conversationsCount(_rooms.length),
                  maxLines: 1,
                ),
              ),
            ),
            Tab(
              icon: const Icon(Icons.people_outline, size: 20),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  AppLocalizations.of(context)!.midwivesCount(_midwives.length),
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                _tabController.animateTo(1);
              },
              backgroundColor: AppColors.primaryGreen,
              icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
              label: Text(
                AppLocalizations.of(context)!.newMessage,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Conversations List
                _buildConversationsTab(isDark, primaryColor),

                // Tab 2: Midwives Directory for Messaging
                _buildMidwivesTab(isDark, primaryColor),
              ],
            ),
    );
  }

  Widget _buildConversationsTab(bool isDark, Color primaryColor) {
    if (_rooms.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade800 : AppColors.lightGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 56,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)!.noMessagesYet,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.connectAndMessageDirectly,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  _tabController.animateTo(1);
                },
                icon: const Icon(Icons.person_search_rounded, color: Colors.white),
                label: Text(
                  AppLocalizations.of(context)!.startChatWithMidwife,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primaryGreen,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        itemCount: _rooms.length,
        separatorBuilder: (context, index) => Divider(color: Theme.of(context).dividerColor),
        itemBuilder: (context, index) {
          final room = _rooms[index];
          final midwifeName = _extractMidwifeName(room);
          final status = room['status'] ?? 'UNKNOWN';
          final isRequested = status == 'REQUESTED';

          String lastMessageText = isRequested ? 'Consultation requested' : 'Tap to open chat';
          String timeText = '';

          final latestMsg = room['latest_message'];
          if (latestMsg is Map) {
            final lmText = latestMsg['text'] ?? latestMsg['content'];
            if (lmText is String) lastMessageText = lmText;
            final lmCreated = latestMsg['created_at'] ?? latestMsg['sent_at'];
            if (lmCreated is String) {
              try {
                final dt = DateTime.parse(lmCreated).toLocal();
                timeText = DateFormat('h:mm a').format(dt);
              } catch (_) {}
            }
          } else if (room['created_at'] is String) {
            try {
              final dt = DateTime.parse(room['created_at']).toLocal();
              timeText = DateFormat('MMM d, h:mm a').format(dt);
            } catch (_) {}
          }

          final int unreadCount = int.tryParse(room['unread_count']?.toString() ?? '') ?? 0;
          final bool hasUnread = unreadCount > 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: AppProfileAvatar(
                radius: 26,
                imageUrl: _mapPath('#avatar_url', room['midwife_detail']) ?? _mapPath('#avatar_url', room['midwife']),
                name: midwifeName,
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      midwifeName,
                      style: TextStyle(
                        fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (timeText.isNotEmpty) ...[
                    Icon(
                      isRequested ? Icons.access_time : (hasUnread ? Icons.done : Icons.done_all),
                      size: 13,
                      color: isRequested
                          ? Colors.orange.shade700
                          : (hasUnread ? AppColors.primaryGreen : Colors.grey.shade500),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      timeText,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: hasUnread ? AppColors.primaryGreen : Theme.of(context).textTheme.bodySmall?.color,
                        fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        lastMessageText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isRequested
                              ? Colors.orange.shade700
                              : (hasUnread
                                  ? Theme.of(context).textTheme.bodyLarge?.color
                                  : Theme.of(context).textTheme.bodySmall?.color),
                          fontWeight: isRequested || hasUnread ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    if (hasUnread)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    if (isRequested && !hasUnread)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.pending,
                          style: TextStyle(fontSize: 10, color: Colors.orange.shade900, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
              onTap: () => _openChatWithRoom(room),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMidwivesTab(bool isDark, Color primaryColor) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                icon: const Icon(Icons.search, color: AppColors.primaryGreen, size: 20),
                hintText: AppLocalizations.of(context)!.searchByNameOrSpecialty,
                hintStyle: TextStyle(fontSize: 13.5, color: Theme.of(context).textTheme.bodySmall?.color),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),

        // List of Midwives
        Expanded(
          child: _filteredMidwives.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      AppLocalizations.of(context)!.noMidwivesAvailable,
                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppColors.primaryGreen,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _filteredMidwives.length,
                    itemBuilder: (context, index) {
                      final mw = _filteredMidwives[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Theme.of(context).dividerColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            AppProfileAvatar(
                              radius: 28,
                              imageUrl: mw.avatarUrl,
                              name: mw.fullName,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mw.fullName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    mw.specialty,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.primaryGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: AppColors.accentYellow, size: 14),
                                      const SizedBox(width: 3),
                                      Text(
                                        mw.ratingAverage.toStringAsFixed(1),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).textTheme.bodyMedium?.color,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Icon(Icons.work_outline, size: 13, color: Theme.of(context).textTheme.bodySmall?.color),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${mw.experienceYears} yrs exp',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: Theme.of(context).textTheme.bodySmall?.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => _openChatWithMidwife(mw),
                              icon: const Icon(Icons.chat_outlined, size: 16, color: Colors.white),
                              label: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  AppLocalizations.of(context)!.message,
                                  maxLines: 1,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

