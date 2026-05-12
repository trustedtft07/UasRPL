import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/app_colors.dart';
import '../../../core/currency_formatter.dart';
import '../../../core/snack_helper.dart';
import '../../../services/pos_service.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/section_title.dart';

class RiwayatTab extends StatefulWidget {
  const RiwayatTab({super.key});

  @override
  State<RiwayatTab> createState() => _RiwayatTabState();
}

class _RiwayatTabState extends State<RiwayatTab> {
  final PosService _posService = PosService();
  bool _isSyncing = false;

  // Set untuk track transaksi yang sedang di-sync agar tidak double-call
  final Set<String> _syncingIds = {};

  @override
  void initState() {
    super.initState();
    _syncSemuaPending();
  }

  /// Sync semua transaksi pending ke Midtrans secara paralel.
  Future<void> _syncSemuaPending() async {
    if (_isSyncing) return;
    if (mounted) setState(() => _isSyncing = true);

    try {
      final snap = await FirebaseFirestore.instance
          .collection('Transaksi')
          .where('IdMerchant', isEqualTo: PosService.activeMerchantId)
          .where('StatusTransaksi', isEqualTo: 'pending')
          .get();

      if (snap.docs.isEmpty) return;

      await Future.wait(
        snap.docs.map((doc) => _syncSatu(doc.id)),
      );
    } catch (_) {
      // Gagal sync tidak crash UI
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  /// Sync satu transaksi — cek ke Midtrans dan update Firestore jika perlu.
  Future<void> _syncSatu(String idTransaksi) async {
    if (_syncingIds.contains(idTransaksi)) return;
    _syncingIds.add(idTransaksi);
    try {
      await _posService.sinkronisasiManual(idTransaksi);
    } finally {
      _syncingIds.remove(idTransaksi);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              const Expanded(
                child: SectionTitle(
                  title: 'Riwayat Transaksi',
                  subtitle: 'Semua transaksi toko Anda',
                ),
              ),
              GestureDetector(
                onTap: _isSyncing ? null : _syncSemuaPending,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isSyncing
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: _isSyncing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.sync_rounded,
                          color: AppColors.primary, size: 18),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Transaksi')
                .where('IdMerchant',
                    isEqualTo: PosService.activeMerchantId)
                .orderBy('WaktuDibuat', descending: true)
                .limit(100)
                .snapshots(),
            builder: (context, snap) {
              if (snap.hasError) {
                return EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Terjadi Kesalahan',
                  subtitle: snap.error.toString(),
                  iconColor: Colors.redAccent,
                );
              }
              if (!snap.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
              if (snap.data!.docs.isEmpty) {
                return const EmptyState(
                  icon: Icons.receipt_long_rounded,
                  title: 'Belum Ada Transaksi',
                  subtitle: 'Transaksi akan muncul di sini.',
                );
              }

              final docs = snap.data!.docs;

              // Setiap kali stream update, auto-sync transaksi pending
              // yang belum sedang di-sync
              WidgetsBinding.instance.addPostFrameCallback((_) {
                for (final doc in docs) {
                  final d = doc.data() as Map<String, dynamic>;
                  if (d['StatusTransaksi'] == 'pending') {
                    _syncSatu(doc.id);
                  }
                }
              });

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: docs.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  final idTransaksi = docs[i].id;
                  return _TransaksiCard(
                    data: d,
                    idTransaksi: idTransaksi,
                    onRefresh: () async {
                      await _syncSatu(idTransaksi);
                      if (context.mounted) {
                        showAppSnack(context, 'Status diperbarui.',
                            isSuccess: true);
                      }
                    },
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

// ─────────────────────────────────────────────
// Card transaksi
// ─────────────────────────────────────────────
class _TransaksiCard extends StatelessWidget {
  const _TransaksiCard({
    required this.data,
    required this.idTransaksi,
    required this.onRefresh,
  });

  final Map<String, dynamic> data;
  final String idTransaksi;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final status = data['StatusTransaksi']?.toString() ?? 'pending';
    final isSuccess = status == 'success';
    final isPending = status == 'pending';
    final isFailed = status == 'failed';

    String timeLabel;
    if (isSuccess && data['WaktuSelesai'] != null) {
      final dt =
          DateTime.fromMillisecondsSinceEpoch(data['WaktuSelesai']);
      timeLabel =
          'Lunas: ${DateFormat('dd MMM, HH:mm', 'id').format(dt)}';
    } else if (isPending) {
      timeLabel = 'Menunggu Pembayaran';
    } else {
      timeLabel = 'Dibatalkan';
    }

    final Color iconBg = isSuccess
        ? AppColors.successLight
        : isFailed
            ? const Color(0xFFFEF2F2)
            : AppColors.warningLight;

    final Color iconColor = isSuccess
        ? AppColors.success
        : isFailed
            ? Colors.redAccent
            : AppColors.warning;

    final IconData iconData = isSuccess
        ? Icons.check_circle_rounded
        : isFailed
            ? Icons.cancel_rounded
            : Icons.hourglass_top_rounded;

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconData, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rp ${formatRupiah(data['Nominal'])}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeLabel,
                  style: TextStyle(
                    color: isSuccess
                        ? AppColors.successText
                        : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight:
                        isSuccess ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if ((data['Catatan'] ?? '').toString().isNotEmpty)
                  Text(
                    data['Catatan'],
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatusBadge(status: status),
              if (isPending) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onRefresh,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color:
                              AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh_rounded,
                            color: AppColors.primary, size: 11),
                        SizedBox(width: 3),
                        Text(
                          'Cek',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Status badge
// ─────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final isSuccess = status == 'success';
    final isPending = status == 'pending';

    final Color bg = isSuccess
        ? AppColors.successLight
        : isPending
            ? AppColors.warningLight
            : const Color(0xFFFEF2F2);

    final Color border = isSuccess
        ? AppColors.successBorder
        : isPending
            ? AppColors.warningBorder
            : const Color(0xFFFCA5A5);

    final Color text = isSuccess
        ? AppColors.successText
        : isPending
            ? AppColors.warning
            : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: text,
          fontWeight: FontWeight.w700,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
