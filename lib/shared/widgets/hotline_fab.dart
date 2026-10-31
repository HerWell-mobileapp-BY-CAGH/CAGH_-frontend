import 'package:flutter/material.dart';
import 'package:cagh_frontend/shared/widgets/hover_scale_widget.dart';
import 'package:cagh_frontend/features/hotline/presentation/emergency_support_screen.dart';

class HotlineFab extends StatelessWidget {
  final double? size;

  const HotlineFab({super.key, this.size});

  @override
  Widget build(BuildContext context) {
    final btnSize = size ?? 48.0;
    final iconSize = (btnSize * 0.46).roundToDouble();
    final badgeSize = (btnSize * 0.32).clamp(14.0, 17.0);

    return Tooltip(
      message: 'Emergency Support Hotline (24/7)',
      child: HoverScaleWidget(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EmergencySupportScreen(),
            ),
          );
        },
        child: Container(
          width: btnSize,
          height: btnSize,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFE53935).withValues(alpha: 0.16),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Phone Handset Icon
              Padding(
                padding: const EdgeInsets.only(top: 1.5, right: 1.5),
                child: Icon(
                  Icons.phone_rounded,
                  color: const Color(0xFFE53935),
                  size: iconSize,
                ),
              ),
              // "24" Emergency Badge
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: badgeSize,
                  height: badgeSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Text(
                    '24',
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                      letterSpacing: -0.2,
                    ),
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
