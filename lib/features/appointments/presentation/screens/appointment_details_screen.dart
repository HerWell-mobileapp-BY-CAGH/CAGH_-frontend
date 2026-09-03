import 'package:flutter/material.dart';
import 'package:cagh_frontend/shared/models/appointment.dart';
import 'package:cagh_frontend/features/appointments/data/services/appointment_api_service.dart';
import 'package:cagh_frontend/features/appointments/data/repositories/appointment_repository_impl.dart';
import 'package:intl/intl.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final Appointment appointment;

  const AppointmentDetailsScreen({
    super.key,
    required this.appointment,
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
        title: Text(AppLocalizations.of(context)!.cancelAppointment),
        content: Text(AppLocalizations.of(context)!.areYouSureCancelAppointment),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.no),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.yesCancel, style: TextStyle(color: Colors.red)),
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
          SnackBar(content: Text(AppLocalizations.of(context)!.appointmentCancelledSuccessfully)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.failedToUpdateStatus}: $e'), backgroundColor: Colors.red),
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
      backgroundColor: AppColors.backgroundPale,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: Text(AppLocalizations.of(context)!.appointmentDetails, style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, true), // return true to indicate potential change
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
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

                  if (isPending)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _cancelAppointment,
                        icon: Icon(Icons.cancel_outlined, color: Colors.red),
                        label: Text(
                          AppLocalizations.of(context)!.cancelAppointment,
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
