import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../data/auth_repository.dart';
import '../providers.dart';

/// Layar login: tanpa formulir registrasi, cukup akun Google (PRD F1).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _loading = false;

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      final signedIn = await ref.read(authRepositoryProvider).signInWithGoogle();
      if (!signedIn) {
        _showMessage('Login dibatalkan, atau belum ada akun Google di perangkat ini.');
      }
      // Kalau berhasil, AuthGate otomatis pindah ke AppShell.
    } on AuthFailure catch (e) {
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 3),
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  'K',
                  style: text.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Kocek',
                style: text.displaySmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Tahu uangmu, capai targetmu.',
                style: text.titleMedium?.copyWith(color: AppColors.textSecondary),
              ),
              const Spacer(flex: 4),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _signIn,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.login_rounded),
                  label: Text(_loading ? 'Memproses...' : 'Masuk dengan Google'),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Datamu tersimpan di akun Google-mu, jadi aman\ndan bisa dipulihkan di HP baru.',
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
