import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cagh_frontend/shared/widgets/globe_language_picker.dart';
import 'package:cagh_frontend/features/scheduling/presentation/screens/midwife_add_availability_screen.dart';
import 'package:cagh_frontend/features/appointments/data/services/appointment_api_service.dart';
import 'package:cagh_frontend/shared/models/availability_slot.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final availData = await _appointmentsApi.getAvailabilities();
      final dateString = DateFormat('yyyy-MM-dd').format(widget.date).toLowerCase();
      final dayIndex = (widget.date.weekday - 1).toString();
      final dayIndex1Based = widget.date.weekday.toString();
      const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
      final dayName = days[widget.date.weekday - 1];

      final slots = availData
          .map((e) => AvailabilitySlot.fromJson(e))
          .where((a) {
            final d = a.dateOrDay.trim().toLowerCase();
            if (d == dateString || d == dayIndex || d == dayIndex1Based || d == dayName) {
              return true;
            }
            if (a.dayName != null && a.dayName!.trim().toLowerCase() == dayName) {
              return true;
            }
            return false;
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
    final currentLocale = Localizations.localeOf(context).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primaryGreen;
    final headerBg = isDark ? AppColors.darkBackground : AppColors.primaryGreen;
    final sheetBg = isDark ? AppColors.darkBackground : const Color(0xFFFDFDFD);
    final textPrimary = isDark ? AppColors.darkTextPrimary : const Color(0xFF182335);
    final textSecondary = isDark ? AppColors.darkTextSecondary : Colors.black54;
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final cardBorder = isDark ? AppColors.darkBorder : Colors.black.withValues(alpha: 0.06);
    final badgeBg = isDark ? AppColors.darkSurfaceVariant : const Color(0xFFEBF3EA);
    final iconColor = isDark ? AppColors.darkPrimary : const Color(0xFF385A2E);

    return Scaffold(
      backgroundColor: headerBg,
      body: Column(
        children: [
          // Top Green App Bar
          Container(
            width: double.infinity,
            color: headerBg,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.schedule,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                        Row(
                          children: const [
                            GlobeLanguagePicker(iconColor: Colors.white, iconSize: 22),
                            SizedBox(width: 2),
                            Icon(Icons.notifications_none, color: Colors.white, size: 22),
                            SizedBox(width: 12),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius: const BorderRadius.only(
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('EEEE, MMMM d, yyyy', currentLocale).format(widget.date),
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              AppLocalizations.of(context)!.calendarEntries(_slots.length),
                              style: TextStyle(fontSize: 14, color: textSecondary, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!widget.date.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)))
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
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: isDark ? AppColors.darkBorder : Colors.transparent),
                            ),
                            child: Icon(Icons.add, color: iconColor, size: 28),
                          ),
                        )
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  Expanded(
                    child: _isLoading 
                        ? Center(child: CircularProgressIndicator(color: primaryColor))
                        : _slots.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: badgeBg,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.access_time, size: 40, color: iconColor),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      AppLocalizations.of(context)!.noAvailabilityCreated,
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      AppLocalizations.of(context)!.addTimeSlotPrompt,
                                      style: TextStyle(fontSize: 13, color: textSecondary),
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
                                      color: cardBg,
                                      border: Border.all(color: cardBorder),
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
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: textPrimary,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: badgeBg,
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(color: isDark ? AppColors.darkBorder : Colors.transparent),
                                              ),
                                              child: Text(
                                                AppLocalizations.of(context)!.available,
                                                style: TextStyle(
                                                  color: iconColor,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Icon(
                                              slot.isInPerson && slot.isVoiceCall
                                                  ? Icons.devices_other_outlined
                                                  : slot.isVoiceCall
                                                      ? Icons.call_outlined
                                                      : Icons.location_on_outlined,
                                              size: 18,
                                              color: iconColor,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              slot.consultationTypeTagText,
                                              style: TextStyle(fontSize: 14, color: textSecondary, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Divider(height: 1, color: isDark ? AppColors.darkBorder : Colors.black12),
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
                                                children: [
                                                  Icon(Icons.edit_outlined, size: 16, color: iconColor),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    AppLocalizations.of(context)!.edit,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: textPrimary,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 20),
                                            Container(width: 1, height: 14, color: isDark ? AppColors.darkBorder : Colors.black26),
                                            const SizedBox(width: 20),
                                            InkWell(
                                              onTap: () async {
                                                final confirm = await showDialog<bool>(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    title: Text(AppLocalizations.of(context)!.deleteSlot),
                                                    content: Text(AppLocalizations.of(context)!.deleteSlotConfirm),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(context, false),
                                                        child: Text(AppLocalizations.of(context)!.cancel),
                                                      ),
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(context, true),
                                                        child: Text(
                                                          AppLocalizations.of(context)!.delete,
                                                          style: const TextStyle(color: Colors.red),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                if (confirm == true) {
                                                  setState(() => _isLoading = true);
                                                  try {
                                                    await _appointmentsApi.deleteAvailability(slot.availabilityId);
                                                    _fetchData();
                                                  } catch (e) {
                                                    if (mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(content: Text('Error: $e')),
                                                      );
                                                    }
                                                    setState(() => _isLoading = false);
                                                  }
                                                }
                                              },
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    AppLocalizations.of(context)!.delete,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.red,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
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
    );
  }
}
