import 'package:flutter/material.dart';
import 'package:cagh_frontend/shared/constants/app_colors.dart';

class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final String? labelText;
  final String? errorText;
  final bool isPassword;
  final TextInputType keyboardType;
  final Widget? prefixIcon;

  const AppTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.labelText,
    this.errorText,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textGray;
    final fillColor = isDark ? Colors.grey.shade900 : AppColors.backgroundGrayLight;
    final hintColor = isDark ? Colors.grey.shade500 : Colors.grey.shade500;
    final iconColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: widget.isPassword && _obscureText,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(color: hintColor),
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: iconColor,
                    ),
                    onPressed: () {
                      setState(() => _obscureText = !_obscureText);
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            errorText: widget.errorText,
          ),
        ),
      ],
    );
  }
}
