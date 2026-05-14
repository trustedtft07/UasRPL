import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/app_colors.dart';
import '../../../core/snack_helper.dart';
import '../../../models/app_models.dart';
import '../../../services/pos_service.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/styled_input.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/section_title.dart';

class KasirTab extends StatefulWidget {
  const KasirTab({super.key});

  @override
  State<KasirTab> createState() => _KasirTabState();
}

class _KasirTabState extends State<KasirTab> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _namaKasirCtrl = TextEditingController();
  final _pinKasirCtrl = TextEditingController();

  @override
  void dispose() {
    _namaKasirCtrl.dispose();
    _pinKasirCtrl.dispose();
    super.dispose();
  }

  Future<void> _tambahKasir() async {
    final nama = _namaKasirCtrl.text.trim();
    final pin = _pinKasirCtrl.text.trim();
    if (nama.isEmpty || pin.isEmpty) return;

    final kasirBaru = KasirModel(
      idKasir: '',
      idMerchant: PosService.activeMerchantId,
      namaKasir: nama,
      pinLogin: pin,
      isActive: true,
    );
    await _db.collection('Kasir').add(kasirBaru.toMap());
    _namaKasirCtrl.clear();
    _pinKasirCtrl.clear();
    if (mounted) showAppSnack(context, 'Kasir berhasil ditambahkan!', isSuccess: true);
  }

  void _confirmDelete(DocumentReference ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Kasir?',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content:
            const Text('Kasir ini akan dihapus permanen dari sistem.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              ref.delete();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    showAppSnack(context, msg, isSuccess: isSuccess);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(
                title: 'Tim Kasir',
                subtitle: 'Kelola akses kasir toko Anda',
              ),
              const SizedBox(height: 12),
              _MerchantIdBadge(onCopied: () => _showSnack('ID Merchant disalin!', isSuccess: true)),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  children: [
                    StyledInput(
                      controller: _namaKasirCtrl,
                      label: 'Nama Kasir',
                      hint: 'Masukkan nama kasir',
                      icon: Icons.person_add_rounded,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: StyledInput(
                            controller: _pinKasirCtrl,
                            label: 'PIN Login',
                            hint: '4 digit PIN',
                            icon: Icons.pin_rounded,
                            isNumber: true,
                            maxLen: 4,
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _tambahKasir,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Tambah',
                                style:
                                    TextStyle(fontWeight: FontWeight.w700)),
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
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Daftar Kasir',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('Kasir')
                .where('IdMerchant',
                    isEqualTo: PosService.activeMerchantId)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary),
                );
              }
              if (snap.data!.docs.isEmpty) {
                return const EmptyState(
                  icon: Icons.group_off_rounded,
                  title: 'Belum Ada Kasir',
                  subtitle: 'Tambahkan kasir menggunakan form di atas.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: snap.data!.docs.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final doc = snap.data!.docs[i];
                  final d = doc.data() as Map<String, dynamic>;
                  return _KasirCard(
                    data: d,
                    onDelete: () => _confirmDelete(doc.reference),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// --- Sub-widget: Badge ID Merchant ---
class _MerchantIdBadge extends StatelessWidget {
  const _MerchantIdBadge({required this.onCopied});
  final VoidCallback onCopied;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(
            ClipboardData(text: PosService.activeMerchantId));
        onCopied();
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0x120EA5E9), // primary 7%
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x330EA5E9)), // primary 20%
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.fingerprint_rounded,
                color: AppColors.primary, size: 16),
            const SizedBox(width: 8),
            Text(
              'ID: ${PosService.activeMerchantId}',
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.copy_rounded,
                color: AppColors.primary, size: 14),
          ],
        ),
      ),
    );
  }
}

// --- Sub-widget: Card item kasir ---
class _KasirCard extends StatelessWidget {
  const _KasirCard({required this.data, required this.onDelete});
  final Map<String, dynamic> data;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isActive = data['IsActive'] == true;
    final initial = (data['NamaKasir'] ?? 'K')
        .toString()
        .substring(0, 1)
        .toUpperCase();

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xCC0EA5E9), AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['NamaKasir'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'PIN: ${data['PinLogin']}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.successLight
                  : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isActive ? 'Aktif' : 'Nonaktif',
              style: TextStyle(
                color: isActive
                    ? AppColors.successText
                    : Colors.redAccent,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_rounded,
                color: Colors.redAccent, size: 20),
            onPressed: onDelete,
            style: IconButton.styleFrom(
              backgroundColor: Colors.redAccent.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
