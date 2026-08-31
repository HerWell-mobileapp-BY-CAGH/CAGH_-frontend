import 'package:flutter/material.dart';
import 'package:cagh_frontend/features/consultations/data/services/consultation_api_service.dart';
import 'package:cagh_frontend/shared/models/appointment.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';

class ConsultationSessionScreen extends StatefulWidget {
  final Map<String, dynamic> sessionData;
  final Appointment appointment;

  const ConsultationSessionScreen({
    super.key,
    required this.sessionData,
    required this.appointment,
  });

  @override
  State<ConsultationSessionScreen> createState() => _ConsultationSessionScreenState();
}

class _ConsultationSessionScreenState extends State<ConsultationSessionScreen> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _recommendationController = TextEditingController();
  
  bool _followUpRequired = false;
  DateTime? _followUpDate;

  final ConsultationApiService _apiService = ConsultationApiService();
  bool _isLoading = false;
  bool _isSessionActive = false;

  late String _sessionId;

  @override
  void initState() {
    super.initState();
    _sessionId = widget.sessionData['id']?.toString() ?? widget.sessionData['session_id']?.toString() ?? '';
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    try {
      // Start the consultation
      await _apiService.startConsultation(_sessionId);
      
      // Start Video or Voice if virtual
      if (widget.appointment.appointmentType == 'VIRTUAL_VIDEO') {
        await _apiService.startVideoSession(_sessionId);
      } else if (widget.appointment.appointmentType == 'VIRTUAL_VOICE') {
        await _apiService.startVoiceSession(_sessionId);
      }

      if (mounted) {
        setState(() {
          _isSessionActive = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize session: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _completeSession() async {
    if (_summaryController.text.isEmpty || _diagnosisController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.summaryAndDiagnosisRequired), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // Add a general note if provided
      if (_notesController.text.isNotEmpty) {
        await _apiService.addClinicalNote(_sessionId, _notesController.text);
      }

      // Complete the consultation with the final medical data
      final completeData = {
        "summary": _summaryController.text,
        "diagnosis": _diagnosisController.text,
        "recommendation": _recommendationController.text,
        "follow_up_required": _followUpRequired,
      };
      
      if (_followUpRequired && _followUpDate != null) {
        completeData["follow_up_date"] = "${_followUpDate!.year}-${_followUpDate!.month.toString().padLeft(2, '0')}-${_followUpDate!.day.toString().padLeft(2, '0')}";
      }

      await _apiService.completeConsultation(_sessionId, completeData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.consultationCompletedSuccessfully), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Return true to signal refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _summaryController.dispose();
    _diagnosisController.dispose();
    _recommendationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPinkGray,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        title: Row(
          children: [
            Text(AppLocalizations.of(context)!.consultationSession, style: TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(width: 12),
            if (_isSessionActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.lightGreen,
                    child: Icon(Icons.person, color: AppColors.primaryGreen, size: 34),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.appointment.userFullName ?? AppLocalizations.of(context)!.patient,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Type: ${widget.appointment.appointmentType}',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),



            // Completion Form
            Text(
              AppLocalizations.of(context)!.consultationReport,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 16),
            
            _buildTextField('Summary (Required)', _summaryController, maxLines: 2),
            const SizedBox(height: 12),
            _buildTextField('Diagnosis (Required)', _diagnosisController, maxLines: 2),
            const SizedBox(height: 12),
            _buildTextField('Recommendation', _recommendationController, maxLines: 3),
            const SizedBox(height: 12),
            _buildTextField('Additional Clinical Notes', _notesController, maxLines: 3),
            
            const SizedBox(height: 16),
            
            // Follow up
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _followUpRequired,
                        activeColor: AppColors.primaryGreen,
                        onChanged: (val) {
                          setState(() {
                            _followUpRequired = val ?? false;
                            if (!_followUpRequired) _followUpDate = null;
                          });
                        },
                      ),
                      Text(AppLocalizations.of(context)!.followUpRequired, style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (_followUpRequired) ...[
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() => _followUpDate = date);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_followUpDate == null ? 'Select Follow-up Date' : '${_followUpDate!.year}-${_followUpDate!.month}-${_followUpDate!.day}'),
                            const Icon(Icons.calendar_month, color: AppColors.primaryGreen),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Complete Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _completeSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        AppLocalizations.of(context)!.completeConsultation,
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: true,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
        ),
      ),
    );
  }
}

