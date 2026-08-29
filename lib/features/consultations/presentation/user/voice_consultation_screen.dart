import 'package:flutter/material.dart';
import 'package:cagh_frontend/shared/models/appointment.dart';
import 'package:cagh_frontend/features/consultations/presentation/common/voice_call_screen.dart';

class VoiceConsultationScreen extends StatelessWidget {
  final String consultationId;
  final String midwifeName;
  final String phoneNumber;
  final bool isCaller;
  final Appointment? appointment;

  const VoiceConsultationScreen({
    super.key,
    required this.consultationId,
    required this.midwifeName,
    required this.phoneNumber,
    this.isCaller = true,
    this.appointment,
  });

  @override
  Widget build(BuildContext context) {
    return VoiceCallScreen(
      consultationId: consultationId,
      appointment: appointment ?? Appointment(
        appointmentId: consultationId,
        userId: '',
        midwifeId: '',
        date: '',
        startTime: '',
        endTime: '',
        appointmentType: 'VIRTUAL_VOICE',
        status: AppointmentStatus.confirmed,
        midwifeName: midwifeName,
      ),
      isCaller: isCaller,
    );
  }
}