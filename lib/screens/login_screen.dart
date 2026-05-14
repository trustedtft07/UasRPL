import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/pos_service.dart';
import '../widgets/styled_input.dart';
import 'home/home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final PosService _posService = PosService();

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _idMerchantCtrl = TextEditingController();
  final _namaKasirCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();

  bool _isLoading = false;
  bool _hidePass = true;
  bool _hidePin = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _idMerchantCtrl.dispose();
    _namaKasirCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isSuccess ? AppColors.success : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  Future<void> _login(bool isMerchant) async {
    setState(() => _isLoading = true);

    final success = isMerchant
        ? await _posService.loginMerchant(
            _emailCtrl.text.trim(), _passCtrl.text.trim())
        : await _posService.loginKasir(
            _idMerchantCtrl.text.trim(),
            _namaKasirCtrl.text.trim(),
            _pinCtrl.text.trim(),
          );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      _showSnack('Login Gagal. Pastikan data yang Anda masukkan benar.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0x1A0EA5E9), // primary 10%
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.point_of_sale_rounded,
                        size: 48, color: AppColors.primary),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'POS',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Silakan masuk ke akun Anda',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 15),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0D0F172A), // textPrimary 5%
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const TabBar(
                          labelColor: AppColors.primary,
                          unselectedLabelColor: AppColors.textSecondary,
                          indicatorColor: AppColors.primary,
                          indicatorSize: TabBarIndicatorSize.label,
                          dividerColor: Colors.transparent,
                          labelStyle: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13),
                          tabs: [
                            Tab(text: 'MERCHANT', height: 50),
                            Tab(text: 'KASIR', height: 50),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: SizedBox(
                            height: 340,
                            child: TabBarView(
                              children: [
                                _buildForm(
                                  isMerchant: true,
                                  children: [
                                    StyledInput(
                                      controller: _emailCtrl,
                                      label: 'Email Merchant',
                                      hint: 'merchant@gmail.com',
                                      icon: Icons.email_outlined,
                                      keyboardType:
                                          TextInputType.emailAddress,
                                    ),
                                    const SizedBox(height: 16),
                                    StyledInput(
                                      controller: _passCtrl,
                                      label: 'Password',
                                      hint: 'Password',
                                      icon: Icons.lock_outline_rounded,
                                      isPassword: true,
                                      obscure: _hidePass,
                                      onToggleObscure: () => setState(
                                          () => _hidePass = !_hidePass),
                                    ),
                                  ],
                                ),
                                _buildForm(
                                  isMerchant: false,
                                  children: [
                                    StyledInput(
                                      controller: _namaKasirCtrl,
                                      label: 'Nama Kasir',
                                      hint: 'Nama Lengkap',
                                      icon: Icons.person_outline_rounded,
                                    ),
                                    const SizedBox(height: 12),
                                    StyledInput(
                                      controller: _idMerchantCtrl,
                                      label: 'ID Merchant',
                                      hint: 'ID Toko',
                                      icon: Icons.storefront_rounded,
                                    ),
                                    const SizedBox(height: 12),
                                    StyledInput(
                                      controller: _pinCtrl,
                                      label: 'PIN Kasir',
                                      hint: '4 Digit PIN',
                                      icon: Icons.pin_rounded,
                                      isNumber: true,
                                      isPassword: true,
                                      obscure: _hidePin,
                                      onToggleObscure: () => setState(
                                          () => _hidePin = !_hidePin),
                                      maxLen: 4,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Belum punya akun?',
                          style:
                              TextStyle(color: AppColors.textSecondary)),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SignupScreen()),
                        ),
                        child: const Text(
                          'Daftar Sekarang',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm({
    required bool isMerchant,
    required List<Widget> children,
  }) {
    return Column(
      children: [
        ...children,
        const Spacer(),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isLoading ? null : () => _login(isMerchant),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Masuk ke Sistem',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ],
    );
  }
}
