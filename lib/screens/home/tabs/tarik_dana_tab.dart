import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/app_colors.dart';
import '../../../core/currency_formatter.dart';
import '../../../core/snack_helper.dart';
import '../../../services/pos_service.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/bank_picker.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/info_tile.dart';
import '../../../widgets/section_title.dart';
import '../../../widgets/styled_input.dart';

class TarikDanaTab extends StatefulWidget {
  const TarikDanaTab({super.key});

  @override
  State<TarikDanaTab> createState() => _TarikDanaTabState();
}

class _TarikDanaTabState extends State<TarikDanaTab> {
  final PosService _posService = PosService();
  final _nominalCtrl = TextEditingController();
  final _rekeningCtrl = TextEditingController();
  String? _selectedBank;
  bool _isLoading = false;

  @override
  void dispose() {
    _nominalCtrl.dispose();
    _rekeningCtrl.dispose();
    super.dispose();
  }

  Future<void> _ajukanPenarikan() async {
    final nominal = parseRupiah(_nominalCtrl.text);
    if (nominal <= 0) {
      showAppSnack(context, 'Masukkan nominal yang valid.', isError: true);
      return;
    }
    if (_selectedBank == null) {
      showAppSnack(context, 'Pilih bank atau dompet tujuan terlebih dahulu.',
          isError: true);
      return;
    }
    if (_rekeningCtrl.text.trim().isEmpty) {
      showAppSnack(context, 'Masukkan nomor rekening / akun tujuan.',
          isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final success = await _posService.ajukanPenarikan(
      nominal: nominal,
      bank: _selectedBank!,
      rekening: _rekeningCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      _nominalCtrl.clear();
      _rekeningCtrl.clear();
      setState(() => _selectedBank = null);
      showAppSnack(
        context,
        'Penarikan berhasil diajukan! Saldo telah dipotong.',
        isSuccess: true,
      );
    } else {
      showAppSnack(
        context,
        'Saldo tidak mencukupi untuk penarikan ini.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SectionTitle(
                title: 'Tarik Dana',
                subtitle: 'Cairkan saldo ke rekening Anda',
              ),
              const SizedBox(height: 16),

              // Wallet card live
              const _WalletCard(),
              const SizedBox(height: 16),

              const InfoTile(
                icon: Icons.schedule_rounded,
                text:
                    'Penarikan diproses dalam 1×24 jam kerja. Saldo langsung terpotong saat pengajuan.',
              ),
              const SizedBox(height: 20),

              // Form penarikan
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nominal Penarikan',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nominalCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        RupiahInputFormatter(),
                      ],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.borderColor,
                        ),
                        prefixText: 'Rp ',
                        prefixStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
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
                    const SizedBox(height: 20),
                    BankPicker(
                      selected: _selectedBank,
                      onSelected: (bank) =>
                          setState(() => _selectedBank = bank),
                    ),
                    const SizedBox(height: 20),
                    StyledInput(
                      controller: _rekeningCtrl,
                      label: 'Nomor Rekening / Akun',
                      hint: 'Masukkan nomor rekening',
                      icon: Icons.credit_card_rounded,
                      isNumber: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              PrimaryButton(
                label: 'AJUKAN PENARIKAN',
                icon: Icons.send_rounded,
                onPressed: _isLoading ? null : _ajukanPenarikan,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 32),

              // Header riwayat penarikan
              const _RiwayatHeader(),
              const SizedBox(height: 12),
            ]),
          ),
        ),

        // List riwayat penarikan — stream langsung dari Firestore
        _RiwayatPenarikanSliver(),

        // Bottom padding
        const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Wallet Card (live stream saldo)
// ─────────────────────────────────────────────
class _WalletCard extends StatelessWidget {
  const _WalletCard();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: PosService().streamMerchant(),
      builder: (context, snap) {
        final saldo = snap.data?.saldo ?? 0;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Saldo Wallet',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Rp ${formatRupiah(saldo)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tersedia untuk ditarik',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Header section riwayat
// ─────────────────────────────────────────────
class _RiwayatHeader extends StatelessWidget {
  const _RiwayatHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.history_rounded,
            color: AppColors.primary,
            size: 17,
          ),
        ),
        const SizedBox(width: 10),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Riwayat Penarikan',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              'Semua pengajuan penarikan dana',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Sliver list riwayat penarikan dari Firestore
// ─────────────────────────────────────────────
class _RiwayatPenarikanSliver extends StatelessWidget {
  _RiwayatPenarikanSliver();

  final Stream<QuerySnapshot> _stream = FirebaseFirestore.instance
      .collection('PenarikanDana')
      .where('IdMerchant', isEqualTo: PosService.activeMerchantId)
      .limit(50)
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.hasError) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _EmptyRiwayat(
                icon: Icons.error_outline_rounded,
                message: 'Gagal memuat riwayat.',
                iconColor: Colors.redAccent,
              ),
            ),
          );
        }

        if (!snap.hasData) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          );
        }

        if (snap.data!.docs.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _EmptyRiwayat(
                icon: Icons.inbox_rounded,
                message: 'Belum ada riwayat penarikan.',
              ),
            ),
          );
        }

        // Sort descending by WaktuPenarikan di sisi client
        final docs = [...snap.data!.docs];
        docs.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          final tA = _toMillis(dataA['WaktuPenarikan']);
          final tB = _toMillis(dataB['WaktuPenarikan']);
          return tB.compareTo(tA); // descending
        });

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.separated(
            itemCount: docs.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              return _PenarikanCard(data: d);
            },
          ),
        );
      },
    );
  }

  /// Konversi Firestore Timestamp atau int ke milliseconds untuk sorting.
  static int _toMillis(dynamic val) {
    if (val == null) return 0;
    if (val is Timestamp) return val.millisecondsSinceEpoch;
    if (val is int) return val;
    return 0;
  }
}

// ─────────────────────────────────────────────
// Card satu item riwayat penarikan
// ─────────────────────────────────────────────
class _PenarikanCard extends StatelessWidget {
  const _PenarikanCard({required this.data});

  final Map<String, dynamic> data;

  /// Cari warna bank dari daftar kBankOptions berdasarkan kode bank.
  Color _bankColor(String bankCode) {
    try {
      return kBankOptions
          .firstWhere(
            (b) => b.code == bankCode,
            orElse: () => kBankOptions.first,
          )
          .color;
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nominal = (data['NominalTarik'] as num?)?.toInt() ?? 0;
    final bank = data['BankTujuan']?.toString() ?? '—';
    final rekening = data['NomorRekening']?.toString() ?? '—';
    final status = data['StatusPenarikan']?.toString() ?? 'Diproses';

    // Parse waktu dari Firestore Timestamp
    String waktuLabel = '—';
    final rawWaktu = data['WaktuPenarikan'];
    if (rawWaktu != null) {
      DateTime dt;
      if (rawWaktu is Timestamp) {
        dt = rawWaktu.toDate();
      } else if (rawWaktu is int) {
        dt = DateTime.fromMillisecondsSinceEpoch(rawWaktu);
      } else {
        dt = DateTime.now();
      }
      waktuLabel = DateFormat('dd MMM yyyy, HH:mm', 'id').format(dt);
    }

    final isSelesai = status.toLowerCase() == 'selesai' ||
        status.toLowerCase() == 'berhasil' ||
        status.toLowerCase() == 'success';
    final isDitolak = status.toLowerCase() == 'ditolak' ||
        status.toLowerCase() == 'gagal' ||
        status.toLowerCase() == 'failed';

    final Color statusColor = isSelesai
        ? AppColors.successText
        : isDitolak
            ? Colors.redAccent
            : AppColors.warning;

    final Color statusBg = isSelesai
        ? AppColors.successLight
        : isDitolak
            ? const Color(0xFFFEF2F2)
            : AppColors.warningLight;

    final Color statusBorder = isSelesai
        ? AppColors.successBorder
        : isDitolak
            ? const Color(0xFFFCA5A5)
            : AppColors.warningBorder;

    final IconData statusIcon = isSelesai
        ? Icons.check_circle_rounded
        : isDitolak
            ? Icons.cancel_rounded
            : Icons.pending_rounded;

    final bankColor = _bankColor(bank);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris atas: bank icon + nominal + status badge
          Row(
            children: [
              // Bank avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bankColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: bankColor.withValues(alpha: 0.25)),
                ),
                child: Center(
                  child: Text(
                    bank.length >= 2 ? bank.substring(0, 2) : bank,
                    style: TextStyle(
                      color: bankColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rp ${formatRupiah(nominal)}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      waktuLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 11),
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderColor),
          const SizedBox(height: 12),

          // Baris bawah: detail bank & rekening
          Row(
            children: [
              Expanded(
                child: _DetailItem(
                  icon: Icons.account_balance_rounded,
                  label: 'Bank Tujuan',
                  value: bank,
                  valueColor: bankColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DetailItem(
                  icon: Icons.credit_card_rounded,
                  label: 'No. Rekening',
                  value: rekening,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Detail item kecil di dalam card
// ─────────────────────────────────────────────
class _DetailItem extends StatelessWidget {
  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = AppColors.textPrimary,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Icon(icon, size: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Empty state riwayat
// ─────────────────────────────────────────────
class _EmptyRiwayat extends StatelessWidget {
  const _EmptyRiwayat({
    required this.icon,
    required this.message,
    this.iconColor = AppColors.textSecondary,
  });

  final IconData icon;
  final String message;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor.withValues(alpha: 0.5), size: 36),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
