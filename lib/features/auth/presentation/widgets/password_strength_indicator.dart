import 'package:flutter/material.dart';

enum PasswordStrength { weak, medium, strong, none }

class PasswordStrengthIndicator extends StatelessWidget {
  final PasswordStrength strength;

  const PasswordStrengthIndicator({
    super.key,
    required this.strength,
  });

  @override
  Widget build(BuildContext context) {
    int score = 0;
    Color color = Colors.grey.shade300;
    String label = 'Strength';

    switch (strength) {
      case PasswordStrength.weak:
        score = 1;
        color = Colors.red;
        label = 'Weak';
        break;
      case PasswordStrength.medium:
        score = 2;
        color = Colors.orange;
        label = 'Medium';
        break;
      case PasswordStrength.strong:
        score = 3;
        color = Colors.green;
        label = 'Strong';
        break;
      case PasswordStrength.none:
      default:
        score = 0;
        color = Colors.grey.shade300;
        label = 'Strength';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildBar(score >= 1, score >= 1 ? color : Colors.grey.shade300)),
            const SizedBox(width: 4),
            Expanded(child: _buildBar(score >= 2, score >= 2 ? color : Colors.grey.shade300)),
            const SizedBox(width: 4),
            Expanded(child: _buildBar(score >= 3, score >= 3 ? color : Colors.grey.shade300)),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: score == 0 ? Colors.grey.shade500 : color,
          ),
        ),
      ],
    );
  }

  Widget _buildBar(bool active, Color color) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
