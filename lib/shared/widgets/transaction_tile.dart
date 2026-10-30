import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/icon_keys.dart';
import '../../core/utils/dates.dart';
import '../../core/utils/rupiah.dart';
import '../../data/models/category.dart';
import '../../data/models/enums.dart';
import '../../data/models/goal.dart';
import '../../data/models/money_transaction.dart';
import '../../data/models/wallet.dart';

/// Satu baris transaksi, dipakai di Beranda dan (nanti) Riwayat.
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    required this.categories,
    required this.wallets,
    required this.goals,
    this.onTap,
  });

  final MoneyTransaction transaction;
  final Map<String, Category> categories;
  final Map<String, Wallet> wallets;
  final Map<String, Goal> goals;
  final VoidCallback? onTap;

  _Display _display() {
    final t = transaction;
    switch (t.type) {
      case TransactionType.income:
        {
          final c = categories[t.categoryId];
          return _Display(
            title: c?.name ?? 'Pemasukan',
            icon: iconForKey(c?.iconKey ?? 'more_horiz'),
            color: c == null ? AppColors.income : Color(c.colorValue),
            amountText: formatRupiah(t.amount, withSign: true),
            amountColor: AppColors.income,
          );
        }
      case TransactionType.expense:
        {
          final c = categories[t.categoryId];
          return _Display(
            title: c?.name ?? 'Pengeluaran',
            icon: iconForKey(c?.iconKey ?? 'more_horiz'),
            color: c == null ? AppColors.expense : Color(c.colorValue),
            amountText: formatRupiah(-t.amount),
            amountColor: AppColors.expense,
          );
        }
      case TransactionType.transfer:
        {
          final to = wallets[t.toWalletId]?.name ?? 'dompet lain';
          return _Display(
            title: 'Pindah ke $to',
            icon: Icons.swap_horiz_rounded,
            color: AppColors.primary,
            amountText: formatRupiah(t.amount),
            amountColor: AppColors.textPrimary,
          );
        }
      case TransactionType.goalDeposit:
        {
          final goal = goals[t.goalId]?.name ?? 'target';
          return _Display(
            title: 'Setor ke $goal',
            icon: Icons.flag_outlined,
            color: AppColors.goal,
            amountText: formatRupiah(t.amount),
            amountColor: AppColors.textPrimary,
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final t = transaction;
    final d = _display();
    final walletName = wallets[t.walletId]?.name ?? 'Dompet';
    final subtitle = [
      walletName,
      formatDateLabel(t.date),
      if (t.note.isNotEmpty) t.note,
    ].join(' · ');

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: d.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(d.icon, size: 22, color: d.color),
      ),
      title: Text(
        d.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
      ),
      trailing: Text(
        d.amountText,
        style: AppTheme.numeric(text.titleSmall).copyWith(
          fontWeight: FontWeight.w700,
          color: d.amountColor,
        ),
      ),
    );
  }
}

class _Display {
  const _Display({
    required this.title,
    required this.icon,
    required this.color,
    required this.amountText,
    required this.amountColor,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String amountText;
  final Color amountColor;
}
