import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// Data model untuk satu opsi bank.
class BankOption {
  const BankOption({
    required this.code,
    required this.name,
    required this.color,
    required this.icon,
  });

  final String code;
  final String name;
  final Color color;
  final IconData icon;
}

/// Daftar bank yang tersedia.
const List<BankOption> kBankOptions = [
  BankOption(
    code: 'BCA',
    name: 'Bank BCA',
    color: Color(0xFF005BAC),
    icon: Icons.account_balance_rounded,
  ),
  BankOption(
    code: 'BRI',
    name: 'Bank BRI',
    color: Color(0xFF003D7A),
    icon: Icons.account_balance_rounded,
  ),
  BankOption(
    code: 'BNI',
    name: 'Bank BNI',
    color: Color(0xFFFF6600),
    icon: Icons.account_balance_rounded,
  ),
  BankOption(
    code: 'Mandiri',
    name: 'Bank Mandiri',
    color: Color(0xFF003087),
    icon: Icons.account_balance_rounded,
  ),
  BankOption(
    code: 'BSI',
    name: 'Bank BSI',
    color: Color(0xFF00703C),
    icon: Icons.account_balance_rounded,
  ),
  BankOption(
    code: 'CIMB',
    name: 'CIMB Niaga',
    color: Color(0xFFCC0000),
    icon: Icons.account_balance_rounded,
  ),
  BankOption(
    code: 'Jago',
    name: 'Bank Jago',
    color: Color(0xFF00C853),
    icon: Icons.phone_android_rounded,
  ),
  BankOption(
    code: 'SeaBank',
    name: 'SeaBank',
    color: Color(0xFF2B5CE6),
    icon: Icons.phone_android_rounded,
  ),
  BankOption(
    code: 'GoPay',
    name: 'GoPay',
    color: Color(0xFF00AED6),
    icon: Icons.account_balance_wallet_rounded,
  ),
  BankOption(
    code: 'OVO',
    name: 'OVO',
    color: Color(0xFF4C3494),
    icon: Icons.account_balance_wallet_rounded,
  ),
  BankOption(
    code: 'Dana',
    name: 'DANA',
    color: Color(0xFF118EEA),
    icon: Icons.account_balance_wallet_rounded,
  ),
  BankOption(
    code: 'ShopeePay',
    name: 'ShopeePay',
    color: Color(0xFFEE4D2D),
    icon: Icons.account_balance_wallet_rounded,
  ),
];

/// Widget picker bank berbentuk grid chip yang bisa di-scroll.
class BankPicker extends StatelessWidget {
  const BankPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bank / Dompet Tujuan',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kBankOptions.map((bank) {
            final isSelected = selected == bank.code;
            return GestureDetector(
              onTap: () => onSelected(bank.code),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? bank.color.withValues(alpha: 0.12)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? bank.color : AppColors.borderColor,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: bank.color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(bank.icon,
                          color: Colors.white, size: 13),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      bank.code,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? bank.color
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.check_circle_rounded,
                          color: bank.color, size: 14),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
