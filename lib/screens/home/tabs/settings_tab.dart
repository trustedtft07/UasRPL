import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/app_colors.dart';
import '../../../core/currency_formatter.dart';
import '../../../core/snack_helper.dart';
import '../../../models/app_models.dart';
import '../../../services/pos_service.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/styled_input.dart';
import '../../login_screen.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isMerchant = PosService.activeRole == 'merchant';

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Merchant')
          .doc(PosService.activeMerchantId)
          .snapshots(),
      builder: (context, snap) {
        final merchant = snap.hasData && snap.data!.exists
            ? MerchantModel.fromFirestore(snap.data!)
            : null;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Profile hero card ---
              _ProfileHeroCard(merchant: merchant),
              const SizedBox(height: 24),

              // --- Wallet summary (merchant only) ---
              if (isMerchant) ...[
                _WalletSummaryCard(saldo: merchant?.saldo ?? 0),
                const SizedBox(height: 24),
              ],

              // --- Edit profil (merchant only) ---
              if (isMerchant) ...[
                _SectionHeader(
                    icon: Icons.edit_rounded, label: 'Edit Profil Toko'),
                const SizedBox(height: 12),
                _EditProfilCard(merchant: merchant),
                const SizedBox(height: 24),
              ],

              // --- Info akun ---
              _SectionHeader(
                  icon: Icons.info_outline_rounded, label: 'Info Akun'),
              const SizedBox(height: 12),
              _InfoAkunCard(merchant: merchant),
              const SizedBox(height: 24),

              // --- Danger zone ---
              _SectionHeader(
                  icon: Icons.shield_outlined, label: 'Keamanan & Sesi'),
              const SizedBox(height: 12),
              _DangerCard(),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Profile Hero Card
// ─────────────────────────────────────────────
class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({required this.merchant});
  final MerchantModel? merchant;

  @override
  Widget build(BuildContext context) {
    final initial = (merchant?.namaToko ?? 'T')
        .substring(0, 1)
        .toUpperCase();
    final role = PosService.activeRole;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4), width: 2),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  merchant?.namaToko ?? '—',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  merchant?.email ?? '—',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Wallet Summary Card
// ─────────────────────────────────────────────
class _WalletSummaryCard extends StatelessWidget {
  const _WalletSummaryCard({required this.saldo});
  final int saldo;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded,
                color: AppColors.success, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Saldo Wallet',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Rp ${formatRupiah(saldo)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.successBorder),
            ),
            child: const Text(
              'AKTIF',
              style: TextStyle(
                color: AppColors.successText,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Edit Profil Card
// ─────────────────────────────────────────────
class _EditProfilCard extends StatefulWidget {
  const _EditProfilCard({required this.merchant});
  final MerchantModel? merchant;

  @override
  State<_EditProfilCard> createState() => _EditProfilCardState();
}

class _EditProfilCardState extends State<_EditProfilCard> {
  final PosService _posService = PosService();
  final _namaCtrl = TextEditingController();
  final _teleponCtrl = TextEditingController();
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void didUpdateWidget(_EditProfilCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Isi field saat data merchant pertama kali tersedia
    if (widget.merchant != null && !_isEditing) {
      _namaCtrl.text = widget.merchant!.namaToko;
      _teleponCtrl.text = widget.merchant!.telepon;
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _teleponCtrl.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (_namaCtrl.text.trim().isEmpty) {
      showAppSnack(context, 'Nama toko tidak boleh kosong.', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    final ok = await _posService.updateProfilMerchant(
      namaToko: _namaCtrl.text.trim(),
      telepon: _teleponCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isEditing = false;
    });
    showAppSnack(
      context,
      ok ? 'Profil berhasil diperbarui!' : 'Gagal memperbarui profil.',
      isSuccess: ok,
      isError: !ok,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Isi awal saat belum pernah edit
    if (widget.merchant != null &&
        _namaCtrl.text.isEmpty &&
        _teleponCtrl.text.isEmpty) {
      _namaCtrl.text = widget.merchant!.namaToko;
      _teleponCtrl.text = widget.merchant!.telepon;
    }

    return AppCard(
      child: Column(
        children: [
          StyledInput(
            controller: _namaCtrl,
            label: 'Nama Toko / UMKM',
            hint: 'Nama usaha Anda',
            icon: Icons.storefront_rounded,
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 14),
          StyledInput(
            controller: _teleponCtrl,
            label: 'Nomor WhatsApp',
            hint: '0812xxxx',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () {
                setState(() => _isEditing = true);
                _simpan();
              },
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded, size: 18),
              label: Text(
                _isLoading ? 'Menyimpan…' : 'Simpan Perubahan',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Info Akun Card
// ─────────────────────────────────────────────
class _InfoAkunCard extends StatelessWidget {
  const _InfoAkunCard({required this.merchant});
  final MerchantModel? merchant;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.fingerprint_rounded,
            label: 'ID Merchant',
            value: PosService.activeMerchantId,
            canCopy: true,
          ),
          const _Divider(),
          _InfoRow(
            icon: Icons.email_rounded,
            label: 'Email',
            value: merchant?.email ?? '—',
          ),
          const _Divider(),
          _InfoRow(
            icon: Icons.phone_rounded,
            label: 'Nomor HP',
            value: merchant?.telepon.isNotEmpty == true
                ? merchant!.telepon
                : '—',
          ),
          const _Divider(),
          _InfoRow(
            icon: Icons.badge_rounded,
            label: 'Peran',
            value: PosService.activeRole == 'merchant'
                ? 'Merchant / Owner'
                : 'Kasir',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.canCopy = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool canCopy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (canCopy)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                showAppSnack(context, 'ID disalin ke clipboard!',
                    isSuccess: true);
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.copy_rounded,
                    color: AppColors.primary, size: 14),
              ),
            ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
        height: 1, thickness: 1, color: AppColors.borderColor);
  }
}

// ─────────────────────────────────────────────
// Danger / Logout Card
// ─────────────────────────────────────────────
class _DangerCard extends StatelessWidget {
  _DangerCard();

  final PosService _posService = PosService();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          _ActionTile(
            icon: Icons.logout_rounded,
            label: 'Keluar dari Akun',
            subtitle: 'Sesi akan diakhiri',
            color: Colors.redAccent,
            onTap: () => _confirmLogout(context),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Sesi Anda akan diakhiri dan kembali ke halaman login.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _posService.logout();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: color)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: color.withValues(alpha: 0.5), size: 20),
          ],
        ),
      ),
    );
  }
}
