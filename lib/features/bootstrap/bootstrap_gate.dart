import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../onboarding/onboarding_screen.dart';

/// Pengecekan awal per pengguna: mengisi kategori bawaan dan membaca apakah
/// onboarding sudah selesai (true = sudah).
final bootstrapProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(userDataRepositoryProvider);
  if (repo == null) return true;
  return repo.bootstrap();
});

/// Penanda "baru saja menyelesaikan onboarding" agar layar langsung pindah
/// tanpa menunggu server. Otomatis kembali false saat akun berganti.
class OnboardingCompletedNotifier extends Notifier<bool> {
  @override
  bool build() {
    ref.watch(userDocProvider);
    return false;
  }

  void markCompleted() => state = true;

  void reset() => state = false;
}

final onboardingCompletedProvider =
    NotifierProvider<OnboardingCompletedNotifier, bool>(
  OnboardingCompletedNotifier.new,
);

/// Menentukan layar setelah login: onboarding (pengguna baru) atau [child].
class BootstrapGate extends ConsumerWidget {
  const BootstrapGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boot = ref.watch(bootstrapProvider);
    if (boot.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final onboardingDone =
        (boot.value ?? true) || ref.watch(onboardingCompletedProvider);
    return onboardingDone ? child : const OnboardingScreen();
  }
}
