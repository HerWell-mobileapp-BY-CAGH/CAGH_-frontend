import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cagh_frontend/features/appointments/presentation/screens/book_appointment_screen.dart';
import 'package:cagh_frontend/shared/models/midwife_profile.dart';
import 'package:cagh_frontend/shared/models/time_slots_response.dart';
import 'package:cagh_frontend/shared/models/time_slot.dart';
import 'package:cagh_frontend/features/consultations/data/services/midwife_api_service.dart';
import 'package:cagh_frontend/features/consultations/data/repositories/midwife_repository_impl.dart';
import 'package:cagh_frontend/features/appointments/data/services/appointment_api_service.dart';
import 'package:cagh_frontend/features/appointments/data/repositories/appointment_repository_impl.dart';
import 'package:cagh_frontend/features/consultations/presentation/user/chat_screen.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';

class MidwifeProfileDetailScreen extends StatefulWidget {
  final MidwifeProfile midwife;

  const MidwifeProfileDetailScreen({
    super.key,
    required this.midwife,
  });

  @override
  State<MidwifeProfileDetailScreen> createState() => _MidwifeProfileDetailScreenState();
}

class _MidwifeProfileDetailScreenState extends State<MidwifeProfileDetailScreen> {
  late bool _isFavorite;
  final _repository = MidwifeRepositoryImpl(MidwifeApiService());
  final _appointmentRepo = AppointmentRepositoryImpl(AppointmentApiService());
  
  late DateTime _selectedDate;
  late DateTime _focusedDay;
  int _selectedDayIndex = 0;
  
  bool _isLoadingSlots = false;
  TimeSlotsResponse? _timeSlots;
  late List<DateTime> _nextDays;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.midwife.isFavorite;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _selectedDate = today;
    _focusedDay = today;
    _generateNextDays(today);
    _fetchSlotsForDate(today);
  }
  
  void _generateNextDays(DateTime centerDate) {
    final monday = centerDate.subtract(Duration(days: centerDate.weekday - 1));
    _nextDays = List.generate(14, (index) => monday.add(Duration(days: index)));
    _selectedDayIndex = _nextDays.indexWhere((d) => isSameDay(d, _selectedDate));
    if (_selectedDayIndex == -1) {
      _nextDays.insert(0, _selectedDate);
      _selectedDayIndex = 0;
    }
  }
  
  Future<void> _fetchSlotsForDate(DateTime date) async {
    setState(() {
      _isLoadingSlots = true;
    });
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    try {
      final slots = await _appointmentRepo.getTimeSlots(widget.midwife.id, dateStr);
      if (mounted) {
        setState(() {
          _timeSlots = slots;
          _isLoadingSlots = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _timeSlots = TimeSlotsResponse(
            midwifeId: widget.midwife.id,
            midwifeName: widget.midwife.fullName,
            date: dateStr,
            offeredConsultationTypes: [],
            availableSlotsCount: 0,
            morningSlots: [],
            afternoonSlots: [],
            eveningSlots: [],
          );
          _isLoadingSlots = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final newStatus = !_isFavorite;
    setState(() => _isFavorite = newStatus);
    try {
      await _repository.toggleFavorite(widget.midwife.id);
    } catch (e) {
      if (mounted) setState(() => _isFavorite = !newStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderSection(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        _buildStatsRow(),
                        const SizedBox(height: 24),
                        _buildLanguagesSection(),
                        const SizedBox(height: 24),
                        _buildConsultationTypesSection(),
                        const SizedBox(height: 24),
                        _buildAboutSection(),
                        const SizedBox(height: 32),
                        _buildAvailabilitySection(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : const Color(0xFF315E26);
    final sheetBg = isDark ? AppColors.darkBackground : Colors.white;
    final textPrimary = isDark ? AppColors.darkTextPrimary : const Color(0xFF1A1A1A);
    final badgeBg = isDark ? AppColors.darkSurfaceVariant : const Color(0xFF81C784);

    return Stack(
      children: [
        // Background Image
        Container(
          height: 320,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceVariant : Colors.grey.shade200,
            image: widget.midwife.avatarUrl != null 
                ? DecorationImage(
                    image: NetworkImage(widget.midwife.avatarUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: widget.midwife.avatarUrl == null
              ? Center(child: Icon(Icons.person, size: 100, color: isDark ? AppColors.darkPrimary : Colors.white))
              : null,
        ),
        // Overlay Gradient for text readability
        Container(
          height: 320,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.3),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.5),
              ],
            ),
          ),
        ),
        // App Bar Controls
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: isDark ? AppColors.darkSurfaceVariant : const Color(0xFF315E26),
                  radius: 20,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: isDark ? AppColors.darkPrimary : Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                CircleAvatar(
                  backgroundColor: isDark ? AppColors.darkSurfaceVariant : Colors.white,
                  radius: 20,
                  child: IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.red : primaryColor,
                      size: 20,
                    ),
                    onPressed: _toggleFavorite,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Bottom Overlapping Content
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: sheetBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.midwife.verificationStatus == 'APPROVED') ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? AppColors.darkBorder : Colors.transparent),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: primaryColor, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          AppLocalizations.of(context)!.verifiedMidwife,
                          style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  widget.midwife.fullName,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: textPrimary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : const Color(0xFF315E26);
    final cardBg = isDark ? AppColors.darkSurface : const Color(0xFFF1F8E9);
    final labelColor = isDark ? AppColors.darkTextSecondary : Colors.grey.shade600;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.darkBorder : Colors.transparent),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.local_hospital_outlined, color: primaryColor, size: 24),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.hospital,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: labelColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.midwife.hospitalName.isNotEmpty ? widget.midwife.hospitalName : 'Independent',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.darkBorder : Colors.transparent),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.verified_user_outlined, color: primaryColor, size: 24),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.experience,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: labelColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.midwife.experienceYears}+ Years',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagesSection() {
    if (widget.midwife.languages.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : const Color(0xFF315E26);
    final chipBg = isDark ? AppColors.darkSurfaceVariant : Colors.white;
    final chipBorder = isDark ? AppColors.darkBorder : const Color(0xFFE0E0E0);
    final labelColor = isDark ? AppColors.darkTextSecondary : Colors.grey.shade500;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.languages,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: labelColor),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.midwife.languages.map((lang) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: chipBorder),
              ),
              child: Text(
                lang,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: primaryColor),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildConsultationTypesSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : const Color(0xFF315E26);
    final chipBg = isDark ? AppColors.darkSurfaceVariant : const Color(0xFFE8F5E9);
    final labelColor = isDark ? AppColors.darkTextSecondary : Colors.grey.shade500;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.offeredConsultations,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: labelColor),
        ),
        const SizedBox(height: 12),
        if (!widget.midwife.supportsVoiceCall && !widget.midwife.supportsInPerson)
          Text(AppLocalizations.of(context)!.noConsultationOptionsOffered, style: TextStyle(fontSize: 13, color: labelColor))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (widget.midwife.supportsVoiceCall)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.darkBorder : Colors.transparent),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.call, size: 16, color: primaryColor),
                      const SizedBox(width: 6),
                      Text(AppLocalizations.of(context)!.voiceCall, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
                    ],
                  ),
                ),
              if (widget.midwife.supportsInPerson)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.darkBorder : Colors.transparent),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.home_outlined, size: 16, color: primaryColor),
                      const SizedBox(width: 6),
                      Text(AppLocalizations.of(context)!.inPerson, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor)),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildAboutSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : const Color(0xFF315E26);
    final bioColor = isDark ? AppColors.darkTextSecondary : Colors.grey.shade600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${AppLocalizations.of(context)!.aboutUs} ${widget.midwife.fullName.split(' ').first}',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
        ),
        const SizedBox(height: 12),
        Text(
          widget.midwife.bio.isNotEmpty ? widget.midwife.bio : 'A dedicated health professional committed to providing the best care.',
          style: TextStyle(fontSize: 14, color: bioColor, height: 1.6),
        ),
      ],
    );
  }

  Widget _buildAvailabilitySection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : const Color(0xFF315E26);
    final selectedColor = isDark ? AppColors.darkButtonGreen : const Color(0xFF315E26);
    final unselectedBg = isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF5F5F5);
    final pastBg = isDark ? AppColors.darkSurfaceVariant.withValues(alpha: 0.4) : const Color(0xFFEEEEEE);
    final textPrimary = isDark ? AppColors.darkTextPrimary : Colors.black87;
    final textSecondary = isDark ? AppColors.darkTextSecondary : Colors.grey.shade600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.availability,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookAppointmentScreen(
                      midwife: widget.midwife,
                      initialSelectedDay: _selectedDate,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.viewAll,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 16,
                      color: primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildWeekDayCards(primaryColor, selectedColor, unselectedBg, pastBg, textPrimary, textSecondary, isDark),
        const SizedBox(height: 24),
        
        if (_isLoadingSlots)
          Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 30), child: CircularProgressIndicator(color: primaryColor)))
        else if (_timeSlots == null || (_timeSlots!.morningSlots.isEmpty && _timeSlots!.afternoonSlots.isEmpty && _timeSlots!.eveningSlots.isEmpty))
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Text(AppLocalizations.of(context)!.noSlotsAvailableForDay, style: TextStyle(color: textSecondary)),
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTimeSlotSection('MORNING SLOTS', _timeSlots!.morningSlots),
              _buildTimeSlotSection('AFTERNOON SLOTS', _timeSlots!.afternoonSlots),
              _buildTimeSlotSection('EVENING SLOTS', _timeSlots!.eveningSlots),
            ],
          ),
      ],
    );
  }

  Widget _buildWeekDayCards(
    Color primaryColor,
    Color selectedColor,
    Color unselectedBg,
    Color pastBg,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return SizedBox(
      height: 85,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _nextDays.length,
        itemBuilder: (context, index) {
          final date = _nextDays[index];
          final isPast = date.isBefore(today);
          final dayStr = DateFormat('EEE').format(date).toUpperCase();
          final dateStr = DateFormat('d').format(date);
          final isSelected = isSameDay(date, _selectedDate);

          return GestureDetector(
            onTap: isPast
                ? null
                : () {
                    setState(() {
                      _selectedDayIndex = index;
                      _selectedDate = date;
                      _focusedDay = date;
                    });
                    _fetchSlotsForDate(date);
                  },
            child: Container(
              width: 55,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSelected
                    ? selectedColor
                    : isPast
                        ? pastBg
                        : unselectedBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorder
                      : (isPast ? Colors.grey.shade300 : Colors.transparent),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: selectedColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  Text(
                    dayStr,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white70
                          : isPast
                              ? textSecondary.withValues(alpha: 0.5)
                              : textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : isPast
                              ? textSecondary.withValues(alpha: 0.5)
                              : textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTime12h(String time) {
    if (time.isEmpty) return '';
    try {
      final parts = time.split(':');
      int hour = int.parse(parts[0]);
      int min = int.parse(parts[1]);
      String period = hour >= 12 ? 'PM' : 'AM';
      hour = hour % 12;
      if (hour == 0) hour = 12;
      return '${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')} $period';
    } catch (_) {
      return time;
    }
  }

  Widget _buildTimeSlotSection(String title, List<TimeSlot> slots) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : const Color(0xFF315E26);
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final cardBorder = isDark ? AppColors.darkBorder : const Color(0xFFDCEDC8);
    final textSecondary = isDark ? AppColors.darkTextSecondary : Colors.grey.shade600;

    final now = DateTime.now();
    final isSelectedDayToday = _nextDays.isNotEmpty && 
        _selectedDayIndex < _nextDays.length && 
        _nextDays[_selectedDayIndex].year == now.year &&
        _nextDays[_selectedDayIndex].month == now.month &&
        _nextDays[_selectedDayIndex].day == now.day;
    final currentMinutes = now.hour * 60 + now.minute;

    final availableSlots = slots.where((s) {
      if (!s.isAvailable) return false;
      if (isSelectedDayToday && s.startTime.isNotEmpty) {
        try {
          final parts = s.startTime.split(':');
          final slotMinutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
          if (slotMinutes <= currentMinutes) {
            return false;
          }
        } catch (_) {}
      }
      return true;
    }).toList();

    if (availableSlots.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: availableSlots.map((slot) {
            final isMorning = title.contains('MORNING');
            final isAfternoon = title.contains('AFTERNOON');
            final supportsVoice = widget.midwife.supportsVoiceCall;
            final supportsInPerson = widget.midwife.supportsInPerson;
            final isVoice = supportsVoice && (!supportsInPerson || slot.startTime.contains('30')); 
            
            final icon = isVoice ? Icons.call_outlined : Icons.location_on_outlined;
            final typeStr = isVoice ? 'Voice call' : 'In-person';
            final sessionStr = isMorning ? 'Morning session' : isAfternoon ? 'Afternoon session' : 'Evening session';
            
            final start12 = slot.displayTime.isNotEmpty ? slot.displayTime : _formatTime12h(slot.startTime);
            final end12 = slot.endTime.isNotEmpty ? _formatTime12h(slot.endTime) : '08:30 AM';

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookAppointmentScreen(
                      midwife: widget.midwife,
                      initialSelectedDay: _selectedDate,
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder, width: 1.5),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          start12,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: primaryColor),
                        ),
                        Icon(Icons.add, size: 20, color: isDark ? AppColors.darkPrimary : const Color(0xFF81C784)),
                        Text(
                          end12,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: primaryColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Icon(icon, size: 16, color: textSecondary),
                            const SizedBox(width: 6),
                            Text('$sessionStr \u00B7 $typeStr', style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('30 min', style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text('Select', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor)),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_forward, size: 16, color: primaryColor),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : const Color(0xFF315E26);
    final buttonGreen = isDark ? AppColors.darkButtonGreen : const Color(0xFF315E26);
    final barBg = isDark ? AppColors.darkSurface : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: barBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(midwife: widget.midwife)));
                  },
                  icon: Icon(Icons.chat_bubble_outline, color: primaryColor, size: 20),
                  label: Text(AppLocalizations.of(context)!.message, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryColor)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: primaryColor, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookAppointmentScreen(
                          midwife: widget.midwife,
                          initialSelectedDay: _selectedDate,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.calendar_month, color: Colors.white, size: 20),
                  label: Text(AppLocalizations.of(context)!.book, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
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
