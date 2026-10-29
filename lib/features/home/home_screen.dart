import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/rupiah.dart';

/// Data CONTOH untuk melihat tampilan tema. Diganti data asli
/// (Firestore) pada Langkah 3–5.
class _Preview {
  _Preview._();

  static const tunai = 850000;
  static const dana = 2400000;
  static const goalName = 'HP Baru';
  static const goalCollected = 2000000;
  static const goalTarget = 6000000;
}

/// Beranda — urutan konten mengikuti PRD F4.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const total = _Preview.tunai + _Preview.dana;
    const freeBalance = total - _Preview.goalCollected;
    final text = Theme.of(context).textTheme;

    return ListView(
      // Padding bawah ekstra supaya konten tidak tertutup tombol +.
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
      children: [
        const _BalanceCard(total: total, freeBalance: freeBalance),
        const SizedBox(height: 24),
        const _SectionTitle('Dompet'),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(
              child: _WalletTile(
                icon: Icons.payments_outlined,
                name: 'Tunai',
                amount: _Preview.tunai,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _WalletTile(
                icon: Icons.account_balance_wallet_outlined,
                name: 'DANA',
                amount: _Preview.dana,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _SectionTitle('Target'),
        const SizedBox(height: 12),
        const _GoalCard(
          name: _Preview.goalName,
          collected: _Preview.goalCollected,
          target: _Preview.goalTarget,
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            'Tampilan contoh — data asli menyusul di langkah berikutnya.',
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.total, required this.freeBalance});

  final int total;
  final int freeBalance;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total tabungan',
            style: text.labelLarge?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          // Angka saldo = bintang utama layar (bold + tabular figures).
          Text(
            formatRupiah(total),
            style: AppTheme.numeric(text.headlineLarge).copyWith(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Saldo bebas ${formatRupiah(freeBalance)}',
              style: AppTheme.numeric(text.labelLarge).copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletTile extends StatelessWidget {
  const _WalletTile({
    required this.icon,
    required this.name,
    required this.amount,
  });

  final IconData icon;
  final String name;
  final int amount;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: AppColors.primaryDark),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 2),
            Text(
              formatRupiah(amount),
              style: AppTheme.numeric(text.titleMedium).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.name,
    required this.collected,
    required this.target,
  });

  final String name;
  final int collected;
  final int target;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final progress = target == 0 ? 0.0 : (collected / target).clamp(0.0, 1.0);
    final percent = (progress * 100).round();
    final remaining = target - collected;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.goal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.smartphone_outlined,
                    size: 22,
                    color: AppColors.goal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '$percent%',
                  style: AppTheme.numeric(text.titleMedium).copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Bar progres terisi dengan animasi singkat (PRD bagian 14).
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 10,
                  color: AppColors.goal,
                  backgroundColor: AppColors.divider,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Terkumpul ${formatRupiah(collected)} dari ${formatRupiah(target)}',
              style: AppTheme.numeric(text.bodyMedium).copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Sisa ${formatRupiah(remaining)} lagi, semangat!',
              style: AppTheme.numeric(text.bodyMedium).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
