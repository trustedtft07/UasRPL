import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Helper terpusat untuk menampilkan SnackBar konsisten di seluruh app.
void showAppSnack(
  BuildContext context,
  String msg, {
  bool isSuccess = false,
  bool isError = false,
}) {
  final color = isSuccess
      ? AppColors.success
      : isError
          ? Colors.redAccent
          : AppColors.primary;

  final icon = isSuccess
      ? Icons.check_circle_rounded
      : isError
          ? Icons.error_outline_rounded
          : Icons.info_rounded;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(msg,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ),
  );
}
