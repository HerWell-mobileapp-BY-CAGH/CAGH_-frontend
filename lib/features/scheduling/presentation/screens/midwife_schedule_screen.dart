import 'package:flutter/material.dart';
import 'package:cagh_frontend/features/scheduling/presentation/screens/midwife_add_availability_screen.dart';
import 'package:cagh_frontend/features/scheduling/presentation/screens/midwife_day_view_screen.dart';
import 'package:cagh_frontend/features/appointments/data/services/appointment_api_service.dart';
import 'package:cagh_frontend/shared/models/availability_slot.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:cagh_frontend/shared/utils/ethiopian_date_time.dart';
import 'package:cagh_frontend/shared/widgets/ethiopian_calendar_view.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/shared/widgets/custom_snackbar.dart';

class MidwifeScheduleScreen extends StatefulWidget {
  const MidwifeScheduleScreen({super.key});

  @override
  State<MidwifeScheduleScreen> createState() => _MidwifeScheduleScreenState();
}

class _MidwifeScheduleScreenState extends State<MidwifeScheduleScreen> {
  final _appointmentsApi = AppointmentApiService();
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = true;
  List<AvailabilitySlot> _availabilities = [];

  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = DateTime(now.year, now.month, now.day);
    _selectedDay = DateTime(now.year, now.month, now.day);
    _fetchData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final availData = await _appointmentsApi.getAvailabilities();
      final allSlots = availData.map((e) => AvailabilitySlot.fromJson(e)).toList();

      // Separate past slots from present/future slots
      final pastSlots = allSlots.where((s) => s.isPast).toList();
      final activeSlots = allSlots.where((s) => !s.isPast).toList();

      // Clean up past slots from backend so the database stays fresh
      for (final past in pastSlots) {
        if (past.availabilityId.isNotEmpty) {
          _appointmentsApi.deleteAvailability(past.availabilityId).catchError((_) {});
        }
      }

      // Sort upcoming slots chronologically (closest date first, then by start time)
      activeSlots.sort((a, b) {
        final da = a.parsedDate;
        final db = b.parsedDate;
        if (da != null && db != null) {
          final cmp = da.compareTo(db);
          if (cmp != 0) return cmp;
        } else if (da != null) {
          return -1;
        } else if (db != null) {
          return 1;
        }
        return a.startTime.compareTo(b.startTime);
      });

      if (mounted) {
        setState(() {
          _availabilities = activeSlots;
        });
      }
    } catch (e) {
      debugPrint('Error fetching schedule data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openAddAvailability({DateTime? targetDate, AvailabilitySlot? existingSlot}) async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => MidwifeAddAvailabilityScreen(
          initialDate: targetDate ?? _selectedDay,
          existingSlot: existingSlot,
        ),
      ),
    );

    if (result is DateTime) {
      final clean = DateTime(result.year, result.month, result.day);
      setState(() {
        _selectedDay = clean;
        _focusedDay = clean;
      });
    }
    await _fetchData();
  }

  List<AvailabilitySlot> _getAvailabilitiesForDay(DateTime day) {
    return _availabilities.where((a) => a.matchesDate(day)).toList();
  }

  Future<void> _deleteSlot(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteSlot),
        content: Text(AppLocalizations.of(context)!.deleteSlotConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _appointmentsApi.deleteAvailability(id);
        if (mounted) {
          CustomSnackBar.show(context, message: 'Slot deleted successfully', isSuccess: true);
        }
        _fetchData();
      } catch (e) {
        if (mounted) {
          CustomSnackBar.show(context, message: 'Failed to delete slot: $e', isError: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : const Color(0xFF385A2E);
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final cardBorder = isDark ? AppColors.darkBorder : Colors.black12;
    final textPrimary = isDark ? AppColors.darkTextPrimary : const Color(0xFF182335);
    final textSecondary = isDark ? AppColors.darkTextSecondary : Colors.black54;
    final badgeBg = isDark ? AppColors.darkSurfaceVariant : const Color(0xFFEBF3EA);

    final selectedSlots = _getAvailabilitiesForDay(_selectedDay);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: primaryColor,
        child: Column(
          children: [
            Expanded(
              child: _isLoading 
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.availabilityCalendar,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.availabilitySubtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () => _openAddAvailability(targetDate: _selectedDay),
                            icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
                            label: Text(
                              AppLocalizations.of(context)!.addAvailability,
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Calendar Container
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: cardBorder, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${EthiopianDate.fromGregorian(_focusedDay).getMonthName(currentLocale)} ${EthiopianDate.fromGregorian(_focusedDay).year}',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          AppLocalizations.of(context)!.selectDayToManage,
                                          style: TextStyle(
                                            fontSize: 12, 
                                            color: textSecondary,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      OutlinedButton(
                                        onPressed: () {
                                          final now = DateTime.now();
                                          final today = DateTime(now.year, now.month, now.day);
                                          setState(() {
                                            _focusedDay = today;
                                            _selectedDay = today;
                                          });
                                        },
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(color: cardBorder),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        child: Text(
                                          AppLocalizations.of(context)!.today,
                                          style: TextStyle(
                                            color: primaryColor, 
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            final eth = EthiopianDate.fromGregorian(_focusedDay); 
                                            int m = eth.month - 1; 
                                            int y = eth.year; 
                                            if (m < 1) { m = 13; y -= 1; } 
                                            _focusedDay = EthiopianDate(y, m, 1).toGregorian();
                                          });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Icon(
                                            Icons.chevron_left, 
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            final eth = EthiopianDate.fromGregorian(_focusedDay); 
                                            int m = eth.month + 1; 
                                            int y = eth.year; 
                                            if (m > 13) { m = 1; y += 1; } 
                                            _focusedDay = EthiopianDate(y, m, 1).toGregorian();
                                          });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Icon(
                                            Icons.chevron_right, 
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              EthiopianCalendarView(
                                locale: currentLocale,
                                focusedDay: _focusedDay,
                                selectedDay: _selectedDay,
                                showHeader: false,
                                enabledDayPredicate: (day) {
                                  final now = DateTime.now();
                                  final today = DateTime(now.year, now.month, now.day);
                                  return !day.isBefore(today);
                                },
                                onPageChanged: (focusedDay) {
                                  setState(() => _focusedDay = focusedDay);
                                },
                                eventLoader: (day) => _getAvailabilitiesForDay(day),
                                onDaySelected: (selectedDay, focusedDay) {
                                  setState(() {
                                    _selectedDay = selectedDay;
                                    _focusedDay = focusedDay;
                                  });
                                },
                              ),
                              
                              Divider(height: 28, color: cardBorder),
                               
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    Container(width: 8, height: 8, decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle)),
                                    const SizedBox(width: 6),
                                    Text(
                                      AppLocalizations.of(context)!.available, 
                                      style: TextStyle(fontSize: 12, color: textSecondary),
                                    ),
                                    const SizedBox(width: 14),
                                    Container(
                                      width: 8, 
                                      height: 8, 
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.grey.shade600 : Colors.black45, 
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      AppLocalizations.of(context)!.pastStatus, 
                                      style: TextStyle(fontSize: 12, color: textSecondary),
                                    ),
                                    const SizedBox(width: 14),
                                    TextButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => MidwifeDayViewScreen(date: _selectedDay),
                                          ),
                                        ).then((_) => _fetchData());
                                      },
                                      icon: const Icon(Icons.fullscreen, size: 16),
                                      label: Text(
                                        currentLocale.startsWith('am') ? 'ሙሉ የቀን እይታ' : 'Day View',
                                        style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.bold),
                                      ),
                                      style: TextButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Selected Day Slots Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    EthiopianDateHelper.formatEthiopianDate(_selectedDay, locale: currentLocale, includeWeekday: true),
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${selectedSlots.length} ${currentLocale.startsWith('am') ? 'የተመደቡ ሰዓታት' : 'slots configured'}',
                                    style: TextStyle(fontSize: 12, color: textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Add availability for this date',
                              icon: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: badgeBg,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: cardBorder),
                                ),
                                child: Icon(Icons.add, color: primaryColor, size: 20),
                              ),
                              onPressed: () => _openAddAvailability(targetDate: _selectedDay),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Selected Day Slots Cards
                        if (selectedSlots.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: cardBorder),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.event_busy_outlined, size: 36, color: textSecondary.withValues(alpha: 0.6)),
                                const SizedBox(height: 8),
                                Text(
                                  AppLocalizations.of(context)!.noAvailabilityCreated,
                                  style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppLocalizations.of(context)!.addTimeSlotPrompt,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: textSecondary, fontSize: 12),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: () => _openAddAvailability(targetDate: _selectedDay),
                                  icon: Icon(Icons.add, size: 16, color: primaryColor),
                                  label: Text(
                                    AppLocalizations.of(context)!.addAvailability,
                                    style: TextStyle(color: primaryColor, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: primaryColor),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ...selectedSlots.map((slot) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: cardBorder),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: badgeBg,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.access_time_filled, color: primaryColor, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          slot.formattedEthiopianTimeRange(currentLocale),
                                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
                                        ),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: badgeBg,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                slot.consultationTypeTagText,
                                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor),
                                              ),
                                            ),
                                            Text(
                                              slot.status,
                                              style: TextStyle(fontSize: 10, color: textSecondary, fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.edit_outlined, size: 18, color: textSecondary),
                                    tooltip: 'Edit',
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _openAddAvailability(
                                      targetDate: _selectedDay,
                                      existingSlot: slot,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                    tooltip: 'Delete',
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _deleteSlot(slot.availabilityId),
                                  ),
                                ],
                              ),
                            );
                          }),

                        const SizedBox(height: 24),

                        // All Upcoming Availabilities Summary Section
                        if (_availabilities.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                currentLocale.startsWith('am') ? 'ሁሉም የተመደቡ ሰዓታት' : 'All Configured Slots',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: badgeBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_availabilities.length}',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ..._availabilities.map((slot) {
                            final isCurrentSelected = slot.matchesDate(_selectedDay);
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  final p = slot.parsedDate;
                                  if (p != null) {
                                    setState(() {
                                      _selectedDay = p;
                                      _focusedDay = p;
                                    });
                                    _scrollController.animateTo(
                                      240,
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeOut,
                                    );
                                  }
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isCurrentSelected ? primaryColor : cardBorder,
                                      width: isCurrentSelected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 16, color: primaryColor),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              slot.formattedDayDisplay(locale: currentLocale, includeWeekday: true),
                                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                                            ),
                                            Text(
                                              slot.formattedEthiopianTimeRange(currentLocale),
                                              style: TextStyle(fontSize: 12, color: textSecondary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: badgeBg,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            slot.consultationTypeTagText,
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryColor),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () => _deleteSlot(slot.availabilityId),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                        const SizedBox(height: 40),
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
