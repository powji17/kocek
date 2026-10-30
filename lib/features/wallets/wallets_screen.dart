import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/icon_keys.dart';
import '../../core/utils/rupiah.dart';
import '../../data/models/wallet.dart';
import '../../data/providers.dart';
import 'wallet_form_sheet.dart';

/// Kelola dompet: lihat, ubah, tambah, dan sembunyikan (PRD F2).
class WalletsScreen extends ConsumerWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final wallets = ref.watch(walletsProvider).value ?? const <Wallet>[];
    final balances =
        ref.watch(balanceSummaryProvider).value?.walletBalances ?? const {};

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola dompet')),
      body: wallets.isEmpty
          ? Center(
              child: Text(
                'Belum ada dompet.',
                style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
              itemCount: wallets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final w = wallets[index];
                final muted = !w.active;
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: Icon(
                      iconForKey(w.iconKey),
                      color: muted
                          ? AppColors.textSecondary
                          : AppColors.primaryDark,
                    ),
                    title: Text(
                      w.name,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: muted
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                    ),
                    subtitle: muted ? const Text('Disembunyikan') : null,
                    trailing: Text(
                      formatRupiah(balances[w.id] ?? 0),
                      style: AppTheme.numeric(text.titleSmall).copyWith(
                        fontWeight: FontWeight.w700,
                        color: muted
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                    ),
                    onTap: () => showWalletFormSheet(context, existing: w),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showWalletFormSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah dompet'),
      ),
    );
  }
}
