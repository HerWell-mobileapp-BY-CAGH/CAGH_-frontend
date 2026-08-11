import 'package:flutter/material.dart';
import 'package:cagh_frontend/shared/models/appointment.dart';
import 'package:cagh_frontend/features/appointments/data/services/appointment_api_service.dart';
import 'package:cagh_frontend/features/appointments/data/repositories/appointment_repository_impl.dart';
import 'package:intl/intl.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final Appointment appointment;
  final Function(String midwifeName)? onMessageTap;

  const AppointmentDetailsScreen({
    super.key,
    required this.appointment,
    this.onMessageTap,
  });

  @override
  State<AppointmentDetailsScreen> createState() => _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  late Appointment _appointment;
  bool _isLoading = false;
  final _appointmentRepository = AppointmentRepositoryImpl(AppointmentApiService());

  @override
  void initState() {
    super.initState();
    _appointment = widget.appointment;
  }

  Future<void> _cancelAppointment() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final updated = await _appointmentRepository.cancelAppointment(_appointment.appointmentId);
      if (mounted) {
        setState(() {
          _appointment = updated;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment cancelled successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return Colors.green.shade700;
      case AppointmentStatus.pending:
        return Colors.orange.shade700;
      case AppointmentStatus.cancelled:
      case AppointmentStatus.declined:
        return Colors.red.shade700;
      case AppointmentStatus.completed:
        return Colors.blue.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('EEEE, MMMM d, yyyy').format(dt);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPending = _appointment.status == AppointmentStatus.pending;
    final isConfirmed = _appointment.status == AppointmentStatus.confirmed;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFF274E13),
        title: const Text('Appointment Details', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, true), // return true to indicate potential change
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF274E13)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getStatusColor(_appointment.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _getStatusColor(_appointment.status).withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          isConfirmed ? Icons.check_circle_outline : (isPending ? Icons.pending_actions : Icons.info_outline),
                          size: 48,
                          color: _getStatusColor(_appointment.status),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Status: ${_appointment.status.nameStr}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(_appointment.status),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Details Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(Icons.calendar_today, 'Date', _formatDate(_appointment.date)),
                        const Divider(height: 24),
                        _buildDetailRow(Icons.access_time, 'Time', '${_appointment.startTime} - ${_appointment.endTime}'),
                        const Divider(height: 24),
                        _buildDetailRow(Icons.medical_services_outlined, 'Type', _appointment.appointmentType),
                        const Divider(height: 24),
                        _buildDetailRow(Icons.person_outline, 'Participant', _appointment.midwifeName ?? _appointment.userFullName ?? 'Unknown'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),

                  // Action Buttons
                  if (isConfirmed)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (widget.onMessageTap != null && _appointment.midwifeName != null) {
                            Navigator.pop(context); // Close details
                            widget.onMessageTap!(_appointment.midwifeName!);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Chat integration not provided or Midwife name missing.')),
                            );
                          }
                        },
                        icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                        label: const Text(
                          'Message Midwife',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF274E13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                      ),
                    ),
                  
                  if (isPending)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _cancelAppointment,
                        icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                        label: const Text(
                          'Cancel Appointment',
                          style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}
