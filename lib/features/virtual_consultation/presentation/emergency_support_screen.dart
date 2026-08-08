import 'package:flutter/material.dart';

class EmergencySupportScreen extends StatefulWidget {
  const EmergencySupportScreen({super.key});

  @override
  State<EmergencySupportScreen> createState() => _EmergencySupportScreenState();
}

class _EmergencySupportScreenState extends State<EmergencySupportScreen> {
  bool _isCallActive = false;
  int _callSeconds = 0;
  bool _isMuted = false;
  bool _isSpeaker = false;

  void _toggleCall() {
    setState(() {
      _isCallActive = !_isCallActive;
      _callSeconds = 0;
    });

    if (_isCallActive) {
      _startCallTimer();
    }
  }

  void _startCallTimer() async {
    while (_isCallActive && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && _isCallActive) {
        setState(() {
          _callSeconds++;
        });
      }
    }
  }

  String _formatCallTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD32F2F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '24/7 Emergency Support',
          style: TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hotline Action Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.phone_in_talk_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Emergency Midwife Line',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Toll-Free Hotline: 907',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (_isCallActive) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Connected • ${_formatCallTime(_callSeconds)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            _isMuted ? Icons.mic_off : Icons.mic,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () => setState(() => _isMuted = !_isMuted),
                        ),
                        const SizedBox(width: 24),
                        ElevatedButton.icon(
                          onPressed: _toggleCall,
                          icon: const Icon(Icons.call_end, color: Colors.white),
                          label: const Text('End Call', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black54,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                        ),
                        const SizedBox(width: 24),
                        IconButton(
                          icon: Icon(
                            _isSpeaker ? Icons.volume_up : Icons.volume_down,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () => setState(() => _isSpeaker = !_isSpeaker),
                        ),
                      ],
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _toggleCall,
                        icon: const Icon(Icons.call, color: Color(0xFFD32F2F)),
                        label: const Text(
                          'Call Emergency Hotline Now',
                          style: TextStyle(
                            color: Color(0xFFD32F2F),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Send SOS Alert Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('SOS Alert sent with current GPS location to nearest dispatch!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
                icon: const Icon(Icons.location_on, color: Color(0xFFD32F2F)),
                label: const Text(
                  'Send GPS Location SOS Alert',
                  style: TextStyle(
                    color: Color(0xFFD32F2F),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Emergency Symptoms Guide',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Seek immediate emergency care if you experience any of the following:',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),

            const SizedBox(height: 14),

            _buildSymptomCard(
              title: 'Severe Abdominal Pain or Cramping',
              description: 'Persistent sharp pain in lower abdomen or pelvic area.',
              severity: 'CRITICAL',
            ),
            const SizedBox(height: 10),
            _buildSymptomCard(
              title: 'Heavy Vaginal Bleeding',
              description: 'Bright red fluid loss requiring immediate medical evaluation.',
              severity: 'CRITICAL',
            ),
            const SizedBox(height: 10),
            _buildSymptomCard(
              title: 'Significant Reduction in Fetal Movement',
              description: 'Fewer than 10 kick counts over 2 hours during trimester 3.',
              severity: 'URGENT',
            ),
            const SizedBox(height: 10),
            _buildSymptomCard(
              title: 'Severe Sudden Swelling or Blurred Vision',
              description: 'Swelling in hands/face accompanied by severe headache.',
              severity: 'URGENT',
            ),

            const SizedBox(height: 28),

            const Text(
              'Nearest Emergency Centers',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 12),

            _buildHospitalTile(
              name: 'St. Paul Hospital Millennium Medical College',
              address: 'Gullele, Addis Ababa',
              distance: '1.2 km away',
              phone: '+251 112 757 676',
            ),
            const SizedBox(height: 10),
            _buildHospitalTile(
              name: 'Gandhi Memorial Women Hospital',
              address: 'Kirkos, Addis Ababa',
              distance: '3.5 km away',
              phone: '+251 115 518 085',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomCard({
    required String title,
    required String description,
    required String severity,
  }) {
    final isCritical = severity == 'CRITICAL';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCritical ? Colors.red.shade200 : Colors.orange.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCritical ? Icons.warning_amber_rounded : Icons.info_outline,
            color: isCritical ? Colors.red : Colors.orange.shade800,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalTile({
    required String name,
    required String address,
    required String distance,
    required String phone,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_hospital_rounded, color: Colors.redAccent, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                Text(
                  address,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.call, color: Color(0xFF1B5E20)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Dialing $phone...')),
              );
            },
          ),
        ],
      ),
    );
  }
}
