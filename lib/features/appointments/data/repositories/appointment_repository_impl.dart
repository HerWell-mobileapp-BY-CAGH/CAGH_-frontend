import 'package:cagh_frontend/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:cagh_frontend/features/appointments/data/services/appointment_api_service.dart';
import 'package:cagh_frontend/shared/models/appointment.dart';
import 'package:cagh_frontend/shared/models/time_slots_response.dart';
import 'package:cagh_frontend/shared/models/working_hours.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  final AppointmentApiService _apiService;

  AppointmentRepositoryImpl(this._apiService);

  @override
  Future<TimeSlotsResponse> getTimeSlots(String midwifeId, String date) async {
    final response = await _apiService.getTimeSlots(midwifeId, date);
    return TimeSlotsResponse.fromJson(response);
  }

  @override
  Future<Appointment> requestAppointment(Map<String, dynamic> body) async {
    final response = await _apiService.requestAppointment(body);
    return Appointment.fromJson(response);
  }

  @override
  Future<List<Appointment>> getUserAppointments() async {
    final response = await _apiService.getUserAppointments();
    return response.map((json) => Appointment.fromJson(Map<String, dynamic>.from(json as Map))).toList();
  }

  @override
  Future<List<Appointment>> getMidwifeAppointments() async {
    final response = await _apiService.getMidwifeAppointments();
    return response.map((json) => Appointment.fromJson(Map<String, dynamic>.from(json as Map))).toList();
  }

  @override
  Future<Appointment> acceptAppointment(String appointmentId) async {
    try {
      final data = await _apiService.acceptAppointment(appointmentId);
      final apptData = data.containsKey('appointment') && data['appointment'] is Map
          ? Map<String, dynamic>.from(data['appointment'] as Map)
          : data;
      if (apptData.containsKey('id') || apptData.containsKey('appointment_id')) {
        return Appointment.fromJson(apptData);
      }
      return Appointment(
        appointmentId: appointmentId,
        userId: '',
        midwifeId: '',
        date: '',
        startTime: '',
        endTime: '',
        appointmentType: '',
        status: AppointmentStatus.confirmed,
      );
    } catch (e) {
      final clean = e.toString().replaceAll('Exception: ', '').trim();
      throw Exception(clean.isNotEmpty ? clean : 'Failed to accept appointment.');
    }
  }

  @override
  Future<Appointment> declineAppointment(String appointmentId) async {
    try {
      final data = await _apiService.declineAppointment(appointmentId);
      final apptData = data.containsKey('appointment') && data['appointment'] is Map
          ? Map<String, dynamic>.from(data['appointment'] as Map)
          : data;
      if (apptData.containsKey('id') || apptData.containsKey('appointment_id')) {
        return Appointment.fromJson(apptData);
      }
      return Appointment(
        appointmentId: appointmentId,
        userId: '',
        midwifeId: '',
        date: '',
        startTime: '',
        endTime: '',
        appointmentType: '',
        status: AppointmentStatus.declined,
      );
    } catch (e) {
      final clean = e.toString().replaceAll('Exception: ', '').trim();
      throw Exception(clean.isNotEmpty ? clean : 'Failed to decline appointment.');
    }
  }

  @override
  Future<Appointment> cancelAppointment(String appointmentId) async {
    try {
      final data = await _apiService.cancelAppointment(appointmentId);
      final apptData = data.containsKey('appointment') && data['appointment'] is Map
          ? Map<String, dynamic>.from(data['appointment'] as Map)
          : data;
      if (apptData.containsKey('id') || apptData.containsKey('appointment_id')) {
        return Appointment.fromJson(apptData);
      }
      return Appointment(
        appointmentId: appointmentId,
        userId: '',
        midwifeId: '',
        date: '',
        startTime: '',
        endTime: '',
        appointmentType: '',
        status: AppointmentStatus.cancelled,
      );
    } catch (e) {
      final clean = e.toString().replaceAll('Exception: ', '').trim();
      throw Exception(clean.isNotEmpty ? clean : 'Failed to cancel appointment.');
    }
  }

  @override
  Future<Appointment> rescheduleAppointment({
    required String appointmentId,
    required String scheduledDate,
    required String startTime,
    required String endTime,
  }) async {
    try {
      final data = await _apiService.rescheduleAppointment(
        appointmentId: appointmentId,
        scheduledDate: scheduledDate,
        startTime: startTime,
        endTime: endTime,
      );
      final apptData = data.containsKey('appointment') && data['appointment'] is Map
          ? data['appointment']
          : data;
      return Appointment.fromJson(Map<String, dynamic>.from(apptData));
    } catch (e) {
      throw Exception('$e'.replaceAll('Exception: ', ''));
    }
  }


  @override
  Future<Appointment> getAppointmentDetails(String appointmentId) async {
    try {
      final data = await _apiService.getAppointmentDetails(appointmentId);
      return Appointment.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get appointment details: $e');
    }
  }

  @override
  Future<List<WorkingHours>> getAvailabilities() async {
    final response = await _apiService.getAvailabilities();
    return response.map((json) => WorkingHours.fromJson(json)).toList();
  }

  @override
  Future<WorkingHours> setAvailability(Map<String, dynamic> data) async {
    final response = await _apiService.setAvailability(data);
    return WorkingHours.fromJson(response);
  }

  @override
  Future<void> deleteAvailability(String id) async {
    await _apiService.deleteAvailability(id);
  }
}
