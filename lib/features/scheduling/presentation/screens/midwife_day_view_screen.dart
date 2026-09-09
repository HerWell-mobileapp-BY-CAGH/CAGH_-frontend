import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cagh_frontend/features/appointments/data/services/appointment_api_service.dart';
import 'package:cagh_frontend/shared/models/availability_slot.dart';
import 'package:cagh_frontend/features/scheduling/presentation/screens/midwife_add_availability_screen.dart';
import 'package:cagh_frontend/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:cagh_frontend/shared/widgets/globe_language_picker.dart';

class MidwifeDayViewScreen extends StatefulWidget {
  final DateTime date;
  const MidwifeDayViewScreen({super.key, required this.date});

  @override
  State<MidwifeDayViewScreen> createState() => _MidwifeDayViewScreenState();
}

class _MidwifeDayViewScreenState extends State<MidwifeDayViewScreen> {
  final _appointmentsApi = AppointmentApiService();
  bool _isLoading = true;
  List<AvailabilitySlot> _slots = [];
  String _debugAvailData = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final availData = await _appointmentsApi.getAvailabilities();
      final dateString = DateFormat('yyyy-MM-dd').format(widget.date);
      final dayOfWeekString = (widget.date.weekday - 1).toString();
      final slots = availData
          .map((e) => AvailabilitySlot.fromJson(e))
          .where((a) {
            final d = a.dateOrDay.toLowerCase();
            return d == dateString.toLowerCase() || d == dayOfWeekString;
          })
          .toList();

      if (mounted) {
        setState(() {
          _slots = slots;
        });
      }
      debugPrint('RAW AVAIL DATA: $availData');
    } catch (e) {
      debugPrint('Error fetching slots: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF385A2E), // Dark green background for scaffold
      body: SafeArea(
        child: Column(
          children: [
            // Top Green App Bar
            Container(
              width: double.infinity,
              color: const Color(0xFF385A2E),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Text(
                    'Schedule',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      Row(
                        children: [
                          const GlobeLanguagePicker(iconColor: Colors.white, iconSize: 24),
                          const SizedBox(width: 8),
                          const Icon(Icons.notifications_none, color: Colors.white),
                          const SizedBox(width: 16),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFFDFDFD), // Very light/white background
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('EEEE, MMMM d, yyyy').format(widget.date),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF182335)),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${_slots.length} calendar entries',
                              style: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MidwifeAddAvailabilityScreen(initialDate: widget.date),
                              ),
                            ).then((_) => _fetchData());
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBF3EA), // Light green
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.add, color: Color(0xFF385A2E), size: 28),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    Expanded(
                      child: _isLoading 
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFF385A2E)))
                          : _slots.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFE8EFE8),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.access_time, size: 40, color: Color(0xFF385A2E)),
                                      ),
                                      const SizedBox(height: 24),
                                      const Text(
                                        'No availability created',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1C2A3A)),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Add a time slot for this date.',
                                        style: TextStyle(fontSize: 13, color: Colors.black54),
                                      ),
                                      const SizedBox(height: 100),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _slots.length,
                                  itemBuilder: (context, index) {
                                    final slot = _slots[index];
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 16),
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.all(color: Colors.black.withOpacity(0.06)),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  slot.formattedTimeRange,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF182335)),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFEBF3EA),
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: const Text('Available', style: TextStyle(color: Color(0xFF385A2E), fontSize: 12, fontWeight: FontWeight.bold)),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF385A2E)),
                                                const SizedBox(width: 6),
                                                Text(
                                                  slot.isInPerson && slot.isVoiceCall 
                                                      ? 'In-person & Voice call'
                                                      : slot.isInPerson 
                                                          ? 'In-person meeting \u00B7 Hospital' 
                                                          : 'Online meeting \u00B7 Phone call', 
                                                  style: const TextStyle(fontSize: 14, color: Colors.black54)
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 16),
                                            const Divider(height: 1, color: Colors.black12),
                                            const SizedBox(height: 16),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                InkWell(
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) => MidwifeAddAvailabilityScreen(
                                                          initialDate: widget.date,
                                                          existingSlot: slot,
                                                        ),
                                                      ),
                                                    ).then((_) => _fetchData());
                                                  },
                                                  child: Row(
                                                    children: const [
                                                      Icon(Icons.edit_outlined, size: 16, color: Color(0xFF385A2E)),
                                                      SizedBox(width: 6),
                                                      Text('Edit', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF182335), fontSize: 14)),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 20),
                                                Container(width: 1, height: 14, color: Colors.black26),
                                                const SizedBox(width: 20),
                                                InkWell(
                                                  onTap: () async {
                                                    final confirm = await showDialog<bool>(
                                                      context: context,
                                                      builder: (context) => AlertDialog(
                                                        title: const Text('Delete Slot'),
                                                        content: const Text('Are you sure you want to delete this availability slot?'),
                                                        actions: [
                                                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                                        ],
                                                      ),
                                                    );
                                                    if (confirm == true) {
                                                      setState(() => _isLoading = true);
                                                      try {
                                                        await _appointmentsApi.deleteAvailability(slot.availabilityId);
                                                        _fetchData();
                                                      } catch (e) {
                                                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                                        setState(() => _isLoading = false);
                                                      }
                                                    }
                                                  },
                                                  child: Row(
                                                    children: const [
                                                      Icon(Icons.delete_outline, size: 18, color: Color(0xFFE53935)),
                                                      SizedBox(width: 6),
                                                      Text('Delete', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE53935), fontSize: 14)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      );
                                  },
                                ),
                    ),
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
