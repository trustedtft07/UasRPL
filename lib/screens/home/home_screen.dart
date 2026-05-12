import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_colors.dart';
import '../../core/currency_formatter.dart';
import '../../models/app_models.dart';
import '../../services/pos_service.dart';
import 'tabs/pembayaran_tab.dart';
import 'tabs/riwayat_tab.dart';
import 'tabs/kasir_tab.dart';
import 'tabs/tarik_dana_tab.dart';
import 'tabs/settings_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final PosService _posService = PosService();

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _switchTab(int i) {
    if (_selectedIndex == i) return;
    _fadeCtrl.reset();
    setState(() => _selectedIndex = i);
    _fadeCtrl.forward();
  }

  List<Map<String, dynamic>> _buildTabs(bool isMerchant) => [
        {'icon': Icons.qr_code_rounded, 'label': 'Bayar'},
        {'icon': Icons.receipt_long_rounded, 'label': 'Riwayat'},
        if (isMerchant) {'icon': Icons.group_rounded, 'label': 'Kasir'},
        if (isMerchant)
          {'icon': Icons.account_balance_rounded, 'label': 'Tarik'},
        {'icon': Icons.settings_rounded, 'label': 'Setelan'},
      ];

  Widget _buildPanel(bool isMerchant) {
    // Hitung index settings secara dinamis
    final settingsIndex = isMerchant ? 4 : 2;

    if (_selectedIndex == 0) return const PembayaranTab();
    if (_selectedIndex == 1) return const RiwayatTab();
    if (isMerchant && _selectedIndex == 2) return const KasirTab();
    if (isMerchant && _selectedIndex == 3) return const TarikDanaTab();
    if (_selectedIndex == settingsIndex) return const SettingsTab();
    return const PembayaranTab();
  }

  @override
  Widget build(BuildContext context) {
    final isMerchant = PosService.activeRole == 'merchant';
    final tabs = _buildTabs(isMerchant);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: Column(
          children: [
            _HomeHeader(posService: _posService),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: _buildPanel(isMerchant),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _HomeBottomNav(
          tabs: tabs,
          selectedIndex: _selectedIndex,
          onTabSelected: _switchTab,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Header dengan wallet live
// ─────────────────────────────────────────────
class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.posService});
  final PosService posService;

  @override
  Widget build(BuildContext context) {
    final isMerchant = PosService.activeRole == 'merchant';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.storefront_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StreamBuilder<MerchantModel?>(
                      stream: posService.streamMerchant(),
                      builder: (context, snap) {
                        final nama = snap.data?.namaToko ?? 'POS Dashboard';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nama,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              PosService.activeRole.toUpperCase(),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
              // Wallet strip (merchant only)
              if (isMerchant) ...[
                const SizedBox(height: 16),
                StreamBuilder<MerchantModel?>(
                  stream: posService.streamMerchant(),
                  builder: (context, snap) {
                    final saldo = snap.data?.saldo ?? 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white,
                              size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Saldo Wallet',
                                  style: TextStyle(
                                    color: Colors.white
                                        .withValues(alpha: 0.75),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Rp ${formatRupiah(saldo)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              snap.hasData ? 'LIVE' : '...',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Bottom Navigation
// ─────────────────────────────────────────────
class _HomeBottomNav extends StatelessWidget {
  const _HomeBottomNav({
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final List<Map<String, dynamic>> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: List.generate(tabs.length, (i) {
              final selected = selectedIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTabSelected(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0x1A0EA5E9)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedScale(
                          scale: selected ? 1.15 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            tabs[i]['icon'] as IconData,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tabs[i]['label'] as String,
                          style: TextStyle(
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
