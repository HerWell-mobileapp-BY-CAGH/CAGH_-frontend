import 'package:cagh_frontend/shared/models/appointment.dart';
import 'package:cagh_frontend/shared/models/time_slots_response.dart';
import 'package:cagh_frontend/shared/models/working_hours.dart';

abstract class AppointmentRepository {
  Future<TimeSlotsResponse> getTimeSlots(String midwifeId, String date);
  
  Future<Appointment> requestAppointment(Map<String, dynamic> body);

  /// Get appointments for the authenticated user
  Future<List<Appointment>> getUserAppointments();

  /// Get appointments for the authenticated midwife
  Future<List<Appointment>> getMidwifeAppointments();

  /// Accept a pending appointment (Midwife only)
  Future<Appointment> acceptAppointment(String appointmentId);

  /// Decline a pending appointment (Midwife only)
  Future<Appointment> declineAppointment(String appointmentId);

  /// Cancel an upcoming appointment
  Future<Appointment> cancelAppointment(String appointmentId);
  
  /// Get specific appointment details
  Future<Appointment> getAppointmentDetails(String appointmentId);
  
  Future<List<WorkingHours>> getAvailabilities();
  
  Future<WorkingHours> setAvailability(Map<String, dynamic> data);

  Future<void> deleteAvailability(String id);
}
