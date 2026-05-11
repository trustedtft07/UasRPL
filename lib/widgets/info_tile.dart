import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// Tile informasi berwarna biru muda untuk pesan/petunjuk.
class InfoTile extends StatelessWidget {
  const InfoTile({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.infoBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.infoText,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
