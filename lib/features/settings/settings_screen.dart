import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/providers.dart';
import '../auth/providers.dart';
import '../bootstrap/bootstrap_gate.dart';
import '../categories/categories_screen.dart';
import '../goals/goals_screen.dart';
import '../widget/widget_service.dart';
import '../widget/widget_settings_screen.dart';
import '../wallets/wallets_screen.dart';

/// Pengaturan. Sekarang: Akun, Keuangan (kelola dompet), dan Data.
/// Kategori, target, dan tampilan hadir di langkah berikutnya.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Datamu tetap aman di akun Google-mu. Kamu bisa masuk lagi kapan saja.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      // Kosongkan widget supaya saldo tidak tertinggal di layar utama.
      await clearWidget();
      await ref.read(authRepositoryProvider).signOut();
      // AuthGate otomatis kembali ke layar login.
    }
  }

  Future<void> _confirmDeleteAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus semua data?'),
        content: const Text(
          'Semua dompet, transaksi, kategori, dan target akan dihapus '
          'permanen dari perangkat dan cloud. Tindakan ini tidak bisa '
          'dibatalkan. Akun Google-mu tidak ikut dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Hapus semua',
              style: TextStyle(color: AppColors.expense),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Menghapus data...')));
    try {
      await ref.read(userDataRepositoryProvider)?.deleteAllData();
      // Mulai ulang dari awal: pengecekan awal dijalankan lagi (kategori
      // bawaan diisi ulang) dan pengguna kembali ke onboarding.
      ref.read(onboardingCompletedProvider.notifier).reset();
      ref.invalidate(bootstrapProvider);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Semua data sudah dihapus.')),
        );
    } on FirebaseException catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menghapus data (${e.code}). Pastikan terhubung ke internet.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final user = ref.watch(authStateProvider).value;
    final name = user?.displayName ?? user?.email ?? 'Pengguna';
    final initial = String.fromCharCode(name.runes.first).toUpperCase();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(
          'Akun',
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primarySoft,
                  child: Text(
                    initial,
                    style: text.titleMedium?.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (user?.email != null)
                        Text(
                          user!.email!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Keluar'),
            onTap: () => _confirmSignOut(context, ref),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Keuangan',
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Kelola dompet'),
            subtitle: const Text('Ubah, tambah, atau sembunyikan dompet'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const WalletsScreen()),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Kelola kategori'),
            subtitle: const Text('Tambah, ubah, atau hapus kategori'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const CategoriesScreen()),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Target'),
            subtitle: const Text('Tambah, ubah, urutkan, atau arsipkan target'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const GoalsScreen()),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Aplikasi',
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.widgets_outlined),
            title: const Text('Widget homescreen'),
            subtitle: const Text('Pilih target dan sembunyikan nominal'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const WidgetSettingsScreen(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Data',
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.expense,
            ),
            title: const Text('Hapus semua data'),
            subtitle: const Text('Butuh internet. Tidak bisa dibatalkan.'),
            onTap: () => _confirmDeleteAll(context, ref),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            'Tampilan hadir\ndi langkah berikutnya.',
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
