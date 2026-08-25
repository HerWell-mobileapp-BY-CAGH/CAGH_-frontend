import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cagh_frontend/features/virtual_consultation/data/services/sos_api_service.dart';
import 'package:cagh_frontend/features/virtual_consultation/domain/models/hotline.dart';

class EmergencySupportScreen extends StatefulWidget {
  const EmergencySupportScreen({super.key});

  @override
  State<EmergencySupportScreen> createState() => _EmergencySupportScreenState();
}

class _EmergencySupportScreenState extends State<EmergencySupportScreen> {
  final SosApiService _apiService = SosApiService();
  SosResponse? _sosData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchHotlines();
  }

  Future<void> _fetchHotlines() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _apiService.getHotlines();
      setState(() {
        _sosData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load emergency data.';
        _isLoading = false;
      });
    }
  }

  Future<void> _callHotline(String callUrl) async {
    final Uri uri = Uri.parse(callUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch dialer')),
        );
      }
    }
  }

  void _showHotlinesModal() {
    if (_sosData == null || _sosData!.hotlines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hotlines available')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Emergency Hotlines',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF900000),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: _sosData!.hotlines.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final hotline = _sosData!.hotlines[index];
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFFFE5E5),
                        child: Icon(Icons.phone, color: Color(0xFFC62828)),
                      ),
                      title: Text(hotline.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(hotline.number),
                      onTap: () {
                        Navigator.pop(context);
                        _callHotline(hotline.callUrl);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _triggerSos() async {
    // For now, we use default/empty coordinates as geolocator is not set up
    // In future, integrate geolocator to fetch real coordinates
    const double lat = 0.0;
    const double lng = 0.0;
    
    try {
      final response = await _apiService.triggerSosAlert(latitude: lat, longitude: lng);
      if (mounted) {
        final count = response.notifiedContactsCount ?? response.savedContactsCount;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('SOS Alert Triggered! Notified $count contacts.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to trigger SOS alert. Please call a hotline directly.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFE5E5),
        elevation: 0,
        centerTitle: true,
        leadingWidth: 80,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'close',
            style: TextStyle(
              color: Color(0xFF900000),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        title: const Text(
          'Emergency',
          style: TextStyle(
            color: Color(0xFF900000),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC62828)))
          : _errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_errorMessage!, style: const TextStyle(color: Color(0xFFC62828))),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC62828)),
                      onPressed: _fetchHotlines,
                      child: const Text('Retry', style: TextStyle(color: Colors.white)),
                    )
                  ],
                )
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    const Text(
                      'Are you okay?',
                      style: TextStyle(
                        color: Color(0xFFB71C1C),
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'If this is a life-threatening medical\nemergency, tap SOS immediately.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFC62828),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 50),
                    
                    // SOS Button
                    GestureDetector(
                      onTap: _triggerSos,
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFE53935).withOpacity(0.5), // Outer ring
                        ),
                        child: Center(
                          child: Container(
                            width: 170,
                            height: 170,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFB71C1C), // Inner circle
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.white,
                                  size: 48,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'SOS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 50),
                    
                    // Call Emergency Services Card
                    _buildActionCard(
                      icon: Icons.phone,
                      iconBgColor: const Color(0xFFFFEBEE),
                      iconColor: const Color(0xFFC62828),
                      title: 'Call Emergency\nServices',
                      subtitle: _sosData != null && _sosData!.primaryHotlineNumber.isNotEmpty
                          ? 'Primary: ${_sosData!.primaryHotlineNumber}'
                          : '',
                      onTap: _showHotlinesModal,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Notify Contacts Card
                    _buildActionCard(
                      icon: Icons.group,
                      iconBgColor: const Color(0xFFE8F5E9),
                      iconColor: const Color(0xFF2E7D32),
                      title: 'Notify Contacts',
                      subtitle: _sosData != null 
                          ? 'Send alert to ${_sosData!.savedContactsCount} contacts'
                          : 'Send alert to contacts',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Use the SOS button above to notify contacts.')),
                        );
                      },
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF315E26), width: 1.0), // Dark green border
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
