import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/app_colors.dart';
import '../../../core/currency_formatter.dart';
import '../../../core/snack_helper.dart';
import '../../../services/pos_service.dart';
import '../../../services/midtrans_service.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/info_tile.dart';
import '../../../widgets/section_title.dart';

class PembayaranTab extends StatefulWidget {
  const PembayaranTab({super.key});

  @override
  State<PembayaranTab> createState() => _PembayaranTabState();
}

class _PembayaranTabState extends State<PembayaranTab> {
  final PosService _posService = PosService();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _generatePembayaran() async {
    final nominal = parseRupiah(_amountCtrl.text);
    if (nominal <= 0) {
      showAppSnack(context, 'Masukkan nominal yang valid.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final idTransaksi = 'TRX-${DateTime.now().millisecondsSinceEpoch}';
    final url = await MidtransService.generatePaymentUrl(
      idTransaksi: idTransaksi,
      nominal: nominal,
    );

    if (!mounted) return;

    if (url != null) {
      await _posService.simpanTransaksiDanRiwayat(
        idTransaksi: idTransaksi,
        nominal: nominal,
        catatan: _noteCtrl.text,
        qrUrl: url,
      );
      _posService.mulaiPantauStatus(idTransaksi);
      _amountCtrl.clear();
      _noteCtrl.clear();
      if (mounted) {
        showAppSnack(context, 'Tagihan dibuat! Membuka halaman pembayaran…',
            isSuccess: true);
      }
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        showAppSnack(context, 'Gagal membuat tagihan. Coba lagi.',
            isError: true);
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: 'Buat Tagihan',
            subtitle: 'Generate QRIS untuk terima pembayaran',
          ),
          const SizedBox(height: 20),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Nominal dengan format otomatis ---
                const Text(
                  'Nominal',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    RupiahInputFormatter(),
                  ],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.borderColor,
                    ),
                    prefixText: 'Rp ',
                    prefixStyle: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // --- Quick amount chips ---
                const Text(
                  'Nominal Cepat',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    10000, 25000, 50000, 100000, 250000, 500000
                  ].map((amount) {
                    return GestureDetector(
                      onTap: () {
                        _amountCtrl.text = formatRupiah(amount);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color:
                                  AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'Rp ${formatRupiah(amount)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // --- Catatan ---
                const Text(
                  'Catatan (Opsional)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _noteCtrl,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Deskripsi transaksi',
                    hintStyle: const TextStyle(
                        color: Color(0xFFA0AEC0), fontSize: 13),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 14, right: 10),
                      child: Icon(Icons.edit_note_rounded,
                          color: AppColors.primary, size: 20),
                    ),
                    prefixIconConstraints:
                        const BoxConstraints(minWidth: 0, minHeight: 0),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 0, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'GENERATE QRIS',
            icon: Icons.qr_code_2_rounded,
            onPressed: _isLoading ? null : _generatePembayaran,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 16),
          const InfoTile(
            icon: Icons.info_outline_rounded,
            text:
                'QRIS akan dibuka di browser. Saldo wallet otomatis bertambah setelah pembayaran berhasil.',
          ),
        ],
      ),
    );
  }
}
