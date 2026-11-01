import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cagh_frontend/features/appointments/data/repositories/appointment_repository_impl.dart';
import 'package:cagh_frontend/features/appointments/data/services/appointment_api_service.dart';
import 'package:cagh_frontend/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:cagh_frontend/features/consultations/data/services/chat_api_service.dart';
import 'package:cagh_frontend/shared/models/appointment.dart';
import 'package:cagh_frontend/shared/models/working_hours.dart';
import 'package:cagh_frontend/core/utils/app_logger.dart';

/// Data class holding all real-time stats and bookings for the Professional Dashboard.
class MidwifeDashboardData {
  final List<Appointment> appointments;
  final List<WorkingHours> availabilities;
  final int unreadMessagesCount;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final DateTime lastFetched;

  const MidwifeDashboardData({
    this.appointments = const [],
    this.availabilities = const [],
    this.unreadMessagesCount = 0,
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    required this.lastFetched,
  });

  /// Real pending requests (active future booking requests awaiting midwife action)
  List<Appointment> get pendingRequests =>
      appointments.where((a) => a.status == AppointmentStatus.pending && !a.isPast).toList();

  int get pendingCount => pendingRequests.length;

  /// Confirmed consultations scheduled for today
  List<Appointment> get todayAppointments {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    return appointments.where((a) {
      if (a.status != AppointmentStatus.confirmed) return false;
      final d = a.date.trim();
      if (d.startsWith(todayStr)) return true;
      try {
        final parsed = DateTime.parse(d).toLocal();
        return parsed.year == now.year && parsed.month == now.month && parsed.day == now.day;
      } catch (_) {
        return false;
      }
    }).toList()..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  int get todayCount => todayAppointments.length;

  /// Completed consultations
  int get completedCount =>
      appointments.where((a) => a.status == AppointmentStatus.completed).length;

  /// Unique clients served
  int get totalClientsServed =>
      appointments
          .where((a) => a.status == AppointmentStatus.completed && a.userId.isNotEmpty)
          .map((a) => a.userId)
          .toSet()
          .length;

  /// Whether the midwife currently has configured active working hours
  bool get hasActiveAvailability =>
      availabilities.any((a) => a.isActive);

  MidwifeDashboardData copyWith({
    List<Appointment>? appointments,
    List<WorkingHours>? availabilities,
    int? unreadMessagesCount,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    DateTime? lastFetched,
  }) {
    return MidwifeDashboardData(
      appointments: appointments ?? this.appointments,
      availabilities: availabilities ?? this.availabilities,
      unreadMessagesCount: unreadMessagesCount ?? this.unreadMessagesCount,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error,
      lastFetched: lastFetched ?? this.lastFetched,
    );
  }
}

/// StateNotifier providing real-time data sync with periodic polling & immediate invalidation.
class MidwifeDashboardNotifier extends StateNotifier<MidwifeDashboardData> {
  final AppointmentRepository _appointmentRepository;
  Timer? _pollingTimer;

  MidwifeDashboardNotifier(this._appointmentRepository)
      : super(MidwifeDashboardData(lastFetched: DateTime.now())) {
    fetchDashboard(showLoading: true);
    // Background polling every 15 seconds for real-time booking updates
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      fetchDashboard(showLoading: false, isSilent: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchDashboard({bool showLoading = false, bool isSilent = false}) async {
    if (showLoading) {
      state = state.copyWith(isLoading: true, error: null);
    } else if (!isSilent) {
      state = state.copyWith(isRefreshing: true, error: null);
    }

    try {
      final results = await Future.wait([
        _appointmentRepository.getMidwifeAppointments().catchError((e) {
          AppLogger.d('MidwifeDashboard: Error fetching appointments: $e');
          return <Appointment>[];
        }),
        _appointmentRepository.getAvailabilities().catchError((e) {
          AppLogger.d('MidwifeDashboard: Error fetching availabilities: $e');
          return <WorkingHours>[];
        }),
        ChatApiService.getChatRooms().catchError((e) {
          AppLogger.d('MidwifeDashboard: Error fetching chat rooms: $e');
          return <Map<String, dynamic>>[];
        }),
      ]);

      final apts = results[0] as List<Appointment>;
      final avails = results[1] as List<WorkingHours>;
      final chatRooms = results[2] as List<Map<String, dynamic>>;

      int unread = 0;
      for (final room in chatRooms) {
        unread += int.tryParse(room['unread_count']?.toString() ?? '') ?? 0;
      }

      state = MidwifeDashboardData(
        appointments: apts,
        availabilities: avails,
        unreadMessagesCount: unread,
        isLoading: false,
        isRefreshing: false,
        error: null,
        lastFetched: DateTime.now(),
      );
    } catch (e) {
      AppLogger.d('MidwifeDashboard: Failed to refresh dashboard: $e');
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: e.toString(),
      );
    }
  }

  void refresh({bool isSilent = true}) {
    fetchDashboard(showLoading: false, isSilent: isSilent);
  }
}

/// Global provider for the Professional Dashboard state
final midwifeDashboardProvider =
    StateNotifierProvider<MidwifeDashboardNotifier, MidwifeDashboardData>((ref) {
  final repo = AppointmentRepositoryImpl(AppointmentApiService());
  return MidwifeDashboardNotifier(repo);
});

/// Shared provider to control selected tab in Consultations screen from Home
final midwifeConsultTabProvider = StateProvider<int>((ref) => 0);
