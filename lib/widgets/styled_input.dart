import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// Input field bergaya standar yang dipakai di seluruh aplikasi.
class StyledInput extends StatelessWidget {
  const StyledInput({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.isNumber = false,
    this.isPassword = false,
    this.obscure = false,
    this.onToggleObscure,
    this.maxLen,
    this.prefix,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool isNumber;
  final bool isPassword;
  final bool obscure;
  final VoidCallback? onToggleObscure;
  final int? maxLen;
  final String? prefix;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final effectiveKeyboard = keyboardType ??
        (isNumber ? TextInputType.number : TextInputType.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: effectiveKeyboard,
          obscureText: obscure,
          maxLength: maxLen,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFFA0AEC0), // textSecondary 60%
              fontSize: 13,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            prefixText: prefix,
            prefixStyle: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscure
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: onToggleObscure,
                  )
                : null,
            counterText: '',
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
