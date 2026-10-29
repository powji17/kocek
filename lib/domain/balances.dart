import 'dart:math' show max;

import '../data/models/enums.dart';
import '../data/models/goal.dart';
import '../data/models/money_transaction.dart';
import '../data/models/wallet.dart';

/// Hasil perhitungan saldo (PRD bagian 11 "Aturan perhitungan").
///
/// Fungsi murni tanpa Firebase, jadi mudah diuji.
class BalanceSummary {
  const BalanceSummary({
    required this.walletBalances,
    required this.totalSavings,
    required this.goalCollected,
    required this.freeBalance,
  });

  /// Saldo tiap dompet (termasuk dompet yang disembunyikan).
  final Map<String, int> walletBalances;

  /// Total tabungan = jumlah saldo semua dompet AKTIF.
  final int totalSavings;

  /// Terkumpul tiap target = setoran - pengeluaran yang ditautkan (minimal 0).
  final Map<String, int> goalCollected;

  /// Saldo bebas = total tabungan - terkumpul semua target AKTIF.
  final int freeBalance;

  factory BalanceSummary.compute({
    required List<Wallet> wallets,
    required List<MoneyTransaction> transactions,
    required List<Goal> goals,
  }) {
    final balances = <String, int>{
      for (final w in wallets) w.id: w.initialBalance,
    };
    final collected = <String, int>{for (final g in goals) g.id: 0};

    // Transaksi yang merujuk dompet/target yang sudah tidak ada diabaikan.
    void add(Map<String, int> map, String? key, int delta) {
      if (key != null && map.containsKey(key)) {
        map[key] = map[key]! + delta;
      }
    }

    for (final t in transactions) {
      switch (t.type) {
        case TransactionType.income:
          add(balances, t.walletId, t.amount);
        case TransactionType.expense:
          add(balances, t.walletId, -t.amount);
          add(collected, t.goalId, -t.amount);
        case TransactionType.transfer:
          add(balances, t.walletId, -t.amount);
          add(balances, t.toWalletId, t.amount);
        case TransactionType.goalDeposit:
          add(collected, t.goalId, t.amount);
      }
    }

    var total = 0;
    for (final w in wallets) {
      if (w.active) total += balances[w.id] ?? 0;
    }

    final goalCollected = <String, int>{
      for (final e in collected.entries) e.key: max(0, e.value),
    };

    var allocated = 0;
    for (final g in goals) {
      if (g.isActive) allocated += goalCollected[g.id] ?? 0;
    }

    return BalanceSummary(
      walletBalances: balances,
      totalSavings: total,
      goalCollected: goalCollected,
      freeBalance: total - allocated,
    );
  }
}
