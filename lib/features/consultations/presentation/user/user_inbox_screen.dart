import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/features/consultations/data/services/chat_api_service.dart';
import 'package:cagh_frontend/features/consultations/data/services/midwife_api_service.dart';
import 'package:cagh_frontend/features/consultations/data/repositories/midwife_repository_impl.dart';
import 'package:cagh_frontend/shared/models/midwife_profile.dart';
import 'package:cagh_frontend/features/consultations/presentation/user/chat_screen.dart';
import 'package:cagh_frontend/shared/widgets/app_profile_avatar.dart';
import 'package:intl/intl.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';

class UserInboxScreen extends StatefulWidget {
  const UserInboxScreen({super.key});

  @override
  State<UserInboxScreen> createState() => _UserInboxScreenState();
}

class _UserInboxScreenState extends State<UserInboxScreen> with SingleTickerProviderStateMixin {
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
        namesMap[mw.id.toString()] = mw.fullName.isNotEmpty ? mw.fullName : 'Midwife';
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
      }
    } catch (e) {
      debugPrint("Error loading chat rooms in inbox: $e");
      // Gracefully set empty rooms if backend returns an error so user can still message midwives
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

    if (mwData is Map) {
      if (mwData['user'] is Map && mwData['user']['profile'] is Map) {
        final profile = mwData['user']['profile'];
        final fName = profile['first_name']?.toString() ?? '';
        final lName = profile['last_name']?.toString() ?? '';
        if (fName.isNotEmpty || lName.isNotEmpty) {
          return '$fName $lName'.trim();
        }
      } else if (mwData['user'] is Map) {
        final u = mwData['user'];
        if (u['first_name'] != null && u['first_name'].toString().isNotEmpty) {
          return u['first_name'];
        }
      }

      if (mwData['full_name'] != null && mwData['full_name'].toString().isNotEmpty) {
        return mwData['full_name'];
      }
    }

    final mwId = _extractMidwifeId(room);
    if (_midwifeNames.containsKey(mwId)) {
      return _midwifeNames[mwId]!;
    }

    return 'Midwife';
  }

  String _extractMidwifeId(Map<String, dynamic> room) {
    final dynamic mwData = room['midwife_detail'] ?? room['midwife'];

    if (mwData is Map && mwData['id'] != null) {
      return mwData['id'].toString();
    }
    if (mwData != null && mwData is! Map) {
      return mwData.toString();
    }
    return '0';
  }

  void _openChatWithMidwife(MidwifeProfile mw) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(midwife: mw),
      ),
    ).then((_) => _loadData());
  }

  void _openChatWithRoom(Map<String, dynamic> room) {
    final midwifeName = _extractMidwifeName(room);
    final midwifeId = _extractMidwifeId(room);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatRoomId: room['id']?.toString(),
          midwifeId: midwifeId,
          midwifeName: midwifeName,
        ),
      ),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.messages,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
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
              text: 'Conversations (${_rooms.length})',
            ),
            Tab(
              icon: const Icon(Icons.people_outline, size: 20),
              text: 'Midwives (${_midwives.length})',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _tabController.animateTo(1);
        },
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
        label: const Text(
          'New Message',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
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
                'Connect and message directly with our verified healthcare midwives.',
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
                label: const Text(
                  'Start Chat with a Midwife',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
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

          if (room['latest_message'] != null) {
            lastMessageText = room['latest_message']['text'] ?? lastMessageText;
            if (room['latest_message']['created_at'] != null) {
              try {
                final dt = DateTime.parse(room['latest_message']['created_at']).toLocal();
                timeText = DateFormat('h:mm a').format(dt);
              } catch (_) {}
            }
          } else if (room['created_at'] != null) {
            try {
              final dt = DateTime.parse(room['created_at']).toLocal();
              timeText = DateFormat('MMM d, h:mm a').format(dt);
            } catch (_) {}
          }

          final int unreadCount = room['unread_count'] ?? 0;
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
                imageUrl: room['midwife_detail']?['avatar_url'] ?? room['midwife']?['avatar_url'],
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
                  if (timeText.isNotEmpty)
                    Text(
                      timeText,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: hasUnread ? AppColors.primaryGreen : Theme.of(context).textTheme.bodySmall?.color,
                        fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
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
                              label: Text(
                                AppLocalizations.of(context)!.message,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
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
