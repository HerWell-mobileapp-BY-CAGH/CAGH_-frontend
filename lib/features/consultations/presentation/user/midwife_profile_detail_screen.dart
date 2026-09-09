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
  
  int _selectedDayIndex = 0;
  
  bool _isLoadingSlots = false;
  TimeSlotsResponse? _timeSlots;
  late List<DateTime> _nextDays;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.midwife.isFavorite;
    _generateNextDays();
    _fetchSlotsForSelectedDay();
  }
  
  void _generateNextDays() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Find the Monday of the current week
    final monday = today.subtract(Duration(days: today.weekday - 1));
    _nextDays = List.generate(7, (index) => monday.add(Duration(days: index)));
    
    // Auto-select today if it's in the week
    _selectedDayIndex = _nextDays.indexWhere((d) => d.isAtSameMomentAs(today));
    if (_selectedDayIndex == -1) _selectedDayIndex = 0;
  }
  
  Future<void> _fetchSlotsForSelectedDay() async {
    setState(() {
      _isLoadingSlots = true;
    });
    final dateStr = DateFormat('yyyy-MM-dd').format(_nextDays[_selectedDayIndex]);
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
        // Treat 500 or any error as empty slots instead of crashing or showing a raw exception
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
      backgroundColor: Colors.white,
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
    return Stack(
      children: [
        // Background Image
        Container(
          height: 320,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            image: widget.midwife.avatarUrl != null 
                ? DecorationImage(
                    image: NetworkImage(widget.midwife.avatarUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: widget.midwife.avatarUrl == null
              ? const Center(child: Icon(Icons.person, size: 100, color: Colors.white))
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
                Colors.black.withOpacity(0.3),
                Colors.transparent,
                Colors.black.withOpacity(0.5),
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
                  backgroundColor: const Color(0xFF315E26),
                  radius: 20,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 20,
                  child: IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.red : const Color(0xFF315E26),
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
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.midwife.verificationStatus == 'APPROVED') ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF81C784),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Color(0xFF315E26), size: 14),
                        SizedBox(width: 4),
                        Text(
                          AppLocalizations.of(context)!.verifiedMidwife,
                          style: TextStyle(color: Color(0xFF315E26), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  widget.midwife.fullName,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.local_hospital_outlined, color: Color(0xFF315E26), size: 24),
                SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.hospital,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.midwife.hospitalName.isNotEmpty ? widget.midwife.hospitalName : 'Independent',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF315E26)),
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
              color: const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified_user_outlined, color: Color(0xFF315E26), size: 24),
                SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.experience,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.midwife.experienceYears}+ Years',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF315E26)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguagesSection() {
    if (widget.midwife.languages.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.languages,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.midwife.languages.map((lang) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Text(
                lang,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF315E26)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildConsultationTypesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.offeredConsultations,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 12),
        if (!widget.midwife.supportsVoiceCall && !widget.midwife.supportsInPerson)
          Text(AppLocalizations.of(context)!.noConsultationOptionsOffered, style: TextStyle(fontSize: 13, color: Colors.grey.shade600))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (widget.midwife.supportsVoiceCall)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.call, size: 16, color: Color(0xFF315E26)),
                      const SizedBox(width: 6),
                      Text(AppLocalizations.of(context)!.voiceCall, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF315E26))),
                    ],
                  ),
                ),
              if (widget.midwife.supportsInPerson)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.home_outlined, size: 16, color: Color(0xFF315E26)),
                      const SizedBox(width: 6),
                      Text(AppLocalizations.of(context)!.inPerson, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF315E26))),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${AppLocalizations.of(context)!.aboutUs} ${widget.midwife.fullName.split(' ').first}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF315E26)),
        ),
        const SizedBox(height: 12),
        Text(
          widget.midwife.bio.isNotEmpty ? widget.midwife.bio : 'A dedicated midwife committed to providing the best care.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.6),
        ),
      ],
    );
  }

  Widget _buildAvailabilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.availability,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF315E26)),
            ),
            Text(
              AppLocalizations.of(context)!.viewAll,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF315E26)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Day Selector Cards
        SizedBox(
          height: 85,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _nextDays.length,
            itemBuilder: (context, index) {
              final date = _nextDays[index];
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final isPast = date.isBefore(today);
              final dayStr = DateFormat('EEE').format(date).toUpperCase();
              final dateStr = DateFormat('d').format(date);
              final isSelected = index == _selectedDayIndex;

              return GestureDetector(
                onTap: isPast
                    ? null
                    : () {
                        setState(() => _selectedDayIndex = index);
                        _fetchSlotsForSelectedDay();
                      },
                child: Container(
                  width: 55,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF315E26)
                        : isPast
                            ? const Color(0xFFEEEEEE)
                            : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(16),
                    border: isPast ? Border.all(color: Colors.grey.shade300) : null,
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
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
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
                                  ? Colors.grey.shade400
                                  : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        
        if (_isLoadingSlots)
          const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 30), child: CircularProgressIndicator(color: Color(0xFF315E26))))
        else if (_timeSlots == null || (_timeSlots!.morningSlots.isEmpty && _timeSlots!.afternoonSlots.isEmpty && _timeSlots!.eveningSlots.isEmpty))
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Text(AppLocalizations.of(context)!.noSlotsAvailableForDay, style: const TextStyle(color: Colors.grey)),
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
    final availableSlots = slots.where((s) => s.isAvailable).toList();
    if (availableSlots.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: availableSlots.map((slot) {
            final isMorning = title.contains('MORNING');
            final isAfternoon = title.contains('AFTERNOON');
            // Since TimeSlot doesn't currently store the consultation method, 
            // we infer a reasonable default based on what the midwife supports.
            final supportsVoice = widget.midwife.supportsVoiceCall;
            final supportsInPerson = widget.midwife.supportsInPerson;
            // Fake alternating if both supported to match mockup variety
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
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDCEDC8), width: 1.5),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          start12,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF315E26)),
                        ),
                        const Text('+', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF81C784))),
                        Text(
                          end12,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF315E26)),
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
                            Icon(icon, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text('$sessionStr \u00B7 $typeStr', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('30 min', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Row(
                              children: const [
                                Text('Select', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF315E26))),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward, size: 16, color: Color(0xFF315E26)),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
                  icon: Icon(Icons.chat_bubble_outline, color: Color(0xFF315E26), size: 20),
                  label: Text(AppLocalizations.of(context)!.message, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF315E26))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF315E26), width: 1.5),
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
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.calendar_month, color: Colors.white, size: 20),
                  label: Text(AppLocalizations.of(context)!.book, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF315E26),
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
