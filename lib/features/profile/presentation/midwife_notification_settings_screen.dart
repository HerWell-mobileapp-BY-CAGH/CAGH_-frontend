import 'package:flutter/material.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';

class MidwifeNotificationSettingsScreen extends StatefulWidget {
  const MidwifeNotificationSettingsScreen({super.key});

  @override
  State<MidwifeNotificationSettingsScreen> createState() => _MidwifeNotificationSettingsScreenState();
}

class _MidwifeNotificationSettingsScreenState extends State<MidwifeNotificationSettingsScreen> {
  bool pushNotifications = true;
  bool newMessages = true;
  bool consultationRequests = true;
  bool upcomingConsultations = true;
  bool scheduleReminders = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('General Notifications'),
            const SizedBox(height: 12),
            _buildSettingsCard([
              _buildSwitchRow(
                'Push Notifications',
                pushNotifications,
                (val) => setState(() => pushNotifications = val),
              ),
            ]),
            const SizedBox(height: 24),

            _buildSectionHeader('Messages'),
            const SizedBox(height: 12),
            _buildSettingsCard([
              _buildSwitchRow(
                'New Messages',
                newMessages,
                (val) => setState(() => newMessages = val),
              ),
            ]),
            const SizedBox(height: 24),

            _buildSectionHeader('Consultations'),
            const SizedBox(height: 12),
            _buildSettingsCard([
              _buildSwitchRow(
                'Consultation Requests',
                consultationRequests,
                (val) => setState(() => consultationRequests = val),
              ),
              _buildDivider(),
              _buildSwitchRow(
                'Upcoming Consultation',
                upcomingConsultations,
                (val) => setState(() => upcomingConsultations = val),
              ),
            ]),
            const SizedBox(height: 24),

            _buildSectionHeader('Schedule'),
            const SizedBox(height: 12),
            _buildSettingsCard([
              _buildSwitchRow(
                'Schedule Reminders',
                scheduleReminders,
                (val) => setState(() => scheduleReminders = val),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 3.5,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.accentYellow,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    );
  }

  Widget _buildSwitchRow(String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          Switch(
            value: value,
            activeColor: AppColors.primaryGreen,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).dividerColor,
      indent: 16,
      endIndent: 16,
    );
  }
}
