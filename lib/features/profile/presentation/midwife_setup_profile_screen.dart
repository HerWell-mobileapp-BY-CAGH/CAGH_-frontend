import 'package:flutter/material.dart';
import 'package:cagh_frontend/features/consultations/data/repositories/midwife_repository_impl.dart';
import 'package:cagh_frontend/features/consultations/data/services/midwife_api_service.dart';
import 'package:cagh_frontend/features/home/presentation/midwife/midwife_home_screen.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/l10n/app_localizations.dart';

class MidwifeSetupProfileScreen extends StatefulWidget {
  const MidwifeSetupProfileScreen({super.key});

  @override
  State<MidwifeSetupProfileScreen> createState() => _MidwifeSetupProfileScreenState();
}

class _MidwifeSetupProfileScreenState extends State<MidwifeSetupProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _licenseController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _experienceController = TextEditingController();
  
  bool _isLoading = false;

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = MidwifeRepositoryImpl(MidwifeApiService());
      await repo.createMyProfile({
        'license_number': _licenseController.text.trim(),
        'specialty': _specialtyController.text.trim(),
        'hospital_affiliation': _hospitalController.text.trim(),
        'experience_years': int.tryParse(_experienceController.text.trim()) ?? 0,
        'bio': 'I am a passionate midwife dedicated to providing the best care.', // Default bio
      });

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.profileCreatedSuccess),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MidwifeHomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.failedToUpdateStatus}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _licenseController.dispose();
    _specialtyController.dispose();
    _hospitalController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.completeYourProfile),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.completeYourProfile,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.createAccountSubtitle,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              
              TextFormField(
                controller: _licenseController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.licenseNumber,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.badge),
                ),
                validator: (value) => value == null || value.isEmpty ? AppLocalizations.of(context)!.valNameReq : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _specialtyController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.specialty,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.medical_services),
                ),
                validator: (value) => value == null || value.isEmpty ? AppLocalizations.of(context)!.valNameReq : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _experienceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.yearsOfExperience,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.work_history),
                ),
                validator: (value) => value == null || value.isEmpty ? AppLocalizations.of(context)!.valNameReq : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _hospitalController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.hospitalAffiliationOptional,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.local_hospital),
                ),
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(AppLocalizations.of(context)!.completeSetup, style: const TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
