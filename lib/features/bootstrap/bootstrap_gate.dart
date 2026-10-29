import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';

/// Pengisian awal (kategori bawaan) sekali per pengguna.
final bootstrapProvider = FutureProvider<void>((ref) async {
  final repo = ref.watch(userDataRepositoryProvider);
  if (repo == null) return;
  await repo.ensureDefaults();
});

/// Menahan layar utama sebentar sampai pengecekan awal selesai.
/// ensureDefaults() tidak pernah melempar error, jadi aplikasi selalu lanjut.
class BootstrapGate extends ConsumerWidget {
  const BootstrapGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boot = ref.watch(bootstrapProvider);
    if (boot.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return child;
  }
}
