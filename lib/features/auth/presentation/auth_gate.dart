import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bootstrap/bootstrap_gate.dart';
import '../../shell/app_shell.dart';
import '../providers.dart';
import 'login_screen.dart';

/// Gerbang autentikasi: menentukan layar pertama berdasarkan status login.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return auth.when(
      data: (user) => user == null
          ? const LoginScreen()
          : const BootstrapGate(child: AppShell()),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Terjadi kesalahan saat memeriksa login.\n$error'),
          ),
        ),
      ),
    );
  }
}
