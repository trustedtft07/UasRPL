import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formatter untuk input nominal rupiah dengan pemisah ribuan otomatis.
/// Contoh: user ketik "10000" → tampil "10.000"
class RupiahInputFormatter extends TextInputFormatter {
  final _fmt = NumberFormat('#,###', 'id');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Ambil hanya digit
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return newValue.copyWith(text: '');
    }
    final number = int.parse(digits);
    final formatted = _fmt.format(number);
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

int parseRupiah(String formatted) {
  final digits = formatted.replaceAll(RegExp(r'[^0-9]'), '');
  return int.tryParse(digits) ?? 0;
}

String formatRupiah(dynamic val) {
  if (val == null) return '0';
  final n = int.tryParse(val.toString()) ?? 0;
  return NumberFormat('#,###', 'id').format(n);
}
