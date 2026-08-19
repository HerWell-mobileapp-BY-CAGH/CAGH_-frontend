import 'package:flutter/material.dart';
import 'package:cagh_frontend/shared/widgets/hover_scale_widget.dart';
import 'package:cagh_frontend/features/virtual_consultation/presentation/emergency_support_screen.dart';

class HotlineFab extends StatelessWidget {
  const HotlineFab({super.key});

  @override
  Widget build(BuildContext context) {
    return HoverScaleWidget(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EmergencySupportScreen(),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                const Icon(
                  Icons.phone_rounded,
                  color: Colors.redAccent,
                  size: 26,
                ),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '24',
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
