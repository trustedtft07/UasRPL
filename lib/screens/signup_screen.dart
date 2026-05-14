import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_colors.dart';
import '../services/pos_service.dart';
import '../widgets/styled_input.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final PosService _posService = PosService();
  final _namaTokoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _teleponCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _isLoading = false;
  bool _hidePass = true;

  @override
  void dispose() {
    _namaTokoCtrl.dispose();
    _emailCtrl.dispose();
    _teleponCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _daftar() async {
    if (_namaTokoCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty ||
        _passCtrl.text.isEmpty ||
        _teleponCtrl.text.isEmpty) {
      _showSnack('Harap lengkapi semua data toko!', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final user = await _posService.registerMerchant(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text.trim(),
      namaToko: _namaTokoCtrl.text.trim(),
      telepon: _teleponCtrl.text.trim(),
    );
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (user != null) {
      Navigator.pop(context);
      _showSnack('Pendaftaran Berhasil! Silakan Login.', isError: false);
    } else {
      _showSnack(
        'Pendaftaran Gagal. Format email salah atau sudah terdaftar.',
        isError: true,
      );
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(msg,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        backgroundColor:
            isError ? Colors.redAccent : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded,
                color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000), // black 4%
                        blurRadius: 24,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_business_rounded,
                          size: 48, color: AppColors.primary),
                      const SizedBox(height: 16),
                      const Text(
                        'Daftar Merchant Baru',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Lengkapi profil usaha Anda di bawah ini',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 14),
                      ),
                      const SizedBox(height: 32),
                      StyledInput(
                        controller: _namaTokoCtrl,
                        label: 'Nama Toko / UMKM',
                        hint: 'Contoh: Warung Haririe',
                        icon: Icons.storefront_rounded,
                      ),
                      const SizedBox(height: 16),
                      StyledInput(
                        controller: _teleponCtrl,
                        label: 'Nomor WhatsApp',
                        hint: '0812xxxx',
                        icon: Icons.phone_rounded,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      StyledInput(
                        controller: _emailCtrl,
                        label: 'Email Owner',
                        hint: 'nama@email.com',
                        icon: Icons.email_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      StyledInput(
                        controller: _passCtrl,
                        label: 'Password',
                        hint: 'Minimal 6 karakter',
                        icon: Icons.lock_rounded,
                        isPassword: true,
                        obscure: _hidePass,
                        onToggleObscure: () =>
                            setState(() => _hidePass = !_hidePass),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _daftar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text(
                                  'DAFTAR SEKARANG',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
