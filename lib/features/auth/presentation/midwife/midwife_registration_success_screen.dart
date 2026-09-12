import 'package:flutter/material.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';
import 'package:cagh_frontend/features/auth/presentation/user/user_login_screen.dart';

class MidwifeRegistrationSuccessScreen extends StatelessWidget {
  const MidwifeRegistrationSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5), // Light mint-like background from the image
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // No back button
        title: const Text(
          'Midwife Registration',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              
              // Custom Illustration (Checkmark with clipboard)
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryGreen.withValues(alpha: 0.8),
                        width: 2,
                      ),
                    ),
                  ),
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryGreen.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.check,
                    color: AppColors.primaryGreen,
                    size: 80,
                  ),
                  Positioned(
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.content_paste_rounded,
                        color: AppColors.primaryGreen,
                        size: 40,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -5,
                    right: 40,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  // Plus signs around
                  Positioned(top: 10, left: 20, child: Icon(Icons.add, color: Colors.green.shade300, size: 16)),
                  Positioned(top: 20, right: 20, child: Icon(Icons.add, color: Colors.green.shade300, size: 16)),
                  Positioned(bottom: 50, left: -10, child: Icon(Icons.add, color: Colors.green.shade300, size: 16)),
                  Positioned(bottom: 30, right: -10, child: Icon(Icons.add, color: Colors.green.shade300, size: 16)),
                ],
              ),
              
              const SizedBox(height: 40),
              
              const Text(
                'Registration Submitted',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryGreen,
                ),
              ),
              
              const SizedBox(height: 16),
              
              const Text(
                "After registration, your details will be reviewed by an administrator. You'll be able to access the midwife portal once approved.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.black87,
                ),
              ),
              
              const SizedBox(height: 30),
              
              const Divider(color: Colors.black12, thickness: 1),
              
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_active_outlined,
                      color: AppColors.primaryGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'You will be notified once your account is approved.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              
              const Spacer(),
              
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const UserLoginScreen()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const UserLoginScreen()),
                    (route) => false,
                  );
                },
                child: const Text(
                  'Back to Login',
                  style: TextStyle(
                    color: AppColors.primaryGreen,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
