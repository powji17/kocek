import 'package:flutter_test/flutter_test.dart';
import 'package:kocek/data/models/enums.dart';
import 'package:kocek/data/models/goal.dart';
import 'package:kocek/data/models/money_transaction.dart';
import 'package:kocek/data/models/wallet.dart';
import 'package:kocek/domain/balances.dart';

MoneyTransaction tx(
  TransactionType type,
  int amount, {
  required String wallet,
  String? to,
  String? goal,
}) {
  return MoneyTransaction(
    id: 'x${amount}_${type.value}',
    type: type,
    amount: amount,
    walletId: wallet,
    toWalletId: to,
    goalId: goal,
    date: DateTime(2026, 10, 29),
  );
}

void main() {
  const tunai = Wallet(id: 'tunai', name: 'Tunai', iconKey: 'cash', initialBalance: 100000);
  const dana = Wallet(id: 'dana', name: 'DANA', iconKey: 'wallet', initialBalance: 500000);
  const tersembunyi = Wallet(
    id: 'bank',
    name: 'Bank',
    iconKey: 'bank',
    initialBalance: 1000000,
    active: false,
  );
  const hp = Goal(
    id: 'hp',
    name: 'HP Baru',
    targetAmount: 6000000,
    iconKey: 'phone',
    colorValue: 0xFFF59E0B,
  );
  const liburan = Goal(
    id: 'liburan',
    name: 'Liburan',
    targetAmount: 3000000,
    iconKey: 'flag',
    colorValue: 0xFF14B8A6,
    status: GoalStatus.archived,
  );

  test('saldo dompet, total, terkumpul, dan saldo bebas', () {
    final summary = BalanceSummary.compute(
      wallets: [tunai, dana, tersembunyi],
      goals: [hp, liburan],
      transactions: [
        tx(TransactionType.income, 200000, wallet: 'tunai'),
        tx(TransactionType.expense, 50000, wallet: 'dana'),
        tx(TransactionType.transfer, 150000, wallet: 'dana', to: 'tunai'),
        tx(TransactionType.goalDeposit, 300000, wallet: 'dana', goal: 'hp'),
        tx(TransactionType.expense, 40000, wallet: 'tunai', goal: 'hp'),
        tx(TransactionType.goalDeposit, 100000, wallet: 'dana', goal: 'liburan'),
      ],
    );

    expect(summary.walletBalances['tunai'], 410000);
    expect(summary.walletBalances['dana'], 300000);
    expect(summary.walletBalances['bank'], 1000000);
    // Dompet tersembunyi tidak dihitung ke total.
    expect(summary.totalSavings, 710000);
    expect(summary.goalCollected['hp'], 260000);
    expect(summary.goalCollected['liburan'], 100000);
    // Hanya target aktif yang mengurangi saldo bebas.
    expect(summary.freeBalance, 450000);
  });

  test('transfer dan setor target tidak mengubah total tabungan', () {
    final before = BalanceSummary.compute(
      wallets: [tunai, dana],
      goals: [hp],
      transactions: const [],
    );
    final after = BalanceSummary.compute(
      wallets: [tunai, dana],
      goals: [hp],
      transactions: [
        tx(TransactionType.transfer, 250000, wallet: 'dana', to: 'tunai'),
        tx(TransactionType.goalDeposit, 100000, wallet: 'tunai', goal: 'hp'),
      ],
    );
    expect(after.totalSavings, before.totalSavings);
    expect(after.freeBalance, before.freeBalance - 100000);
  });

  test('terkumpul tidak pernah negatif', () {
    final summary = BalanceSummary.compute(
      wallets: [tunai],
      goals: [hp],
      transactions: [
        tx(TransactionType.expense, 80000, wallet: 'tunai', goal: 'hp'),
      ],
    );
    expect(summary.goalCollected['hp'], 0);
    expect(summary.totalSavings, 20000);
    expect(summary.freeBalance, 20000);
  });

  test('transaksi ke dompet atau target yang sudah tidak ada diabaikan', () {
    final summary = BalanceSummary.compute(
      wallets: [tunai],
      goals: [hp],
      transactions: [
        tx(TransactionType.income, 999999, wallet: 'hilang'),
        tx(TransactionType.goalDeposit, 500000, wallet: 'tunai', goal: 'hilang'),
      ],
    );
    expect(summary.totalSavings, 100000);
    expect(summary.freeBalance, 100000);
  });

  group('target mode otomatis', () {
    const hpAuto = Goal(
      id: 'hp',
      name: 'HP Baru',
      targetAmount: 6000000,
      iconKey: 'phone',
      colorValue: 0xFFF59E0B,
      fundingMode: GoalFundingMode.auto,
    );

    test('terkumpul mengikuti total tabungan', () {
      final summary = BalanceSummary.compute(
        wallets: [tunai, dana],
        goals: [hpAuto],
        transactions: const [],
      );
      expect(summary.autoGoalId, 'hp');
      expect(summary.totalSavings, 600000);
      expect(summary.goalCollected['hp'], 600000);
      expect(summary.freeBalance, 0);
    });

    test('mengubah saldo awal dompet ikut mengubah progres', () {
      final before = BalanceSummary.compute(
        wallets: [tunai, dana],
        goals: [hpAuto],
        transactions: const [],
      );
      final after = BalanceSummary.compute(
        wallets: [tunai, dana.copyWith(initialBalance: 800000)],
        goals: [hpAuto],
        transactions: const [],
      );
      expect(before.goalCollected['hp'], 600000);
      expect(after.goalCollected['hp'], 900000);
    });

    test('alokasi target manual lain dikecualikan dari target otomatis', () {
      const liburanAktif = Goal(
        id: 'liburan',
        name: 'Liburan',
        targetAmount: 3000000,
        iconKey: 'flag',
        colorValue: 0xFF14B8A6,
      );
      final summary = BalanceSummary.compute(
        wallets: [tunai, dana],
        goals: [hpAuto, liburanAktif],
        transactions: [
          tx(TransactionType.goalDeposit, 100000, wallet: 'dana', goal: 'liburan'),
        ],
      );
      expect(summary.goalCollected['liburan'], 100000);
      expect(summary.goalCollected['hp'], 500000);
      expect(summary.freeBalance, 0);
    });

    test('pengeluaran tertaut ke target otomatis tidak dihitung dua kali', () {
      final summary = BalanceSummary.compute(
        wallets: [tunai],
        goals: [hpAuto],
        transactions: [
          tx(TransactionType.expense, 30000, wallet: 'tunai', goal: 'hp'),
        ],
      );
      expect(summary.totalSavings, 70000);
      expect(summary.goalCollected['hp'], 70000);
    });

    test('hanya target otomatis aktif pertama yang berlaku', () {
      const hp2 = Goal(
        id: 'hp2',
        name: 'Cadangan',
        targetAmount: 1000000,
        iconKey: 'flag',
        colorValue: 0xFF14B8A6,
        fundingMode: GoalFundingMode.auto,
      );
      final summary = BalanceSummary.compute(
        wallets: [tunai, dana],
        goals: [hpAuto, hp2],
        transactions: [
          tx(TransactionType.goalDeposit, 50000, wallet: 'tunai', goal: 'hp2'),
        ],
      );
      expect(summary.autoGoalId, 'hp');
      expect(summary.goalCollected['hp2'], 50000);
      expect(summary.goalCollected['hp'], 550000);
    });

    test('target otomatis yang sudah tercapai kembali dihitung manual', () {
      const hpTercapai = Goal(
        id: 'hp',
        name: 'HP Baru',
        targetAmount: 6000000,
        iconKey: 'phone',
        colorValue: 0xFFF59E0B,
        status: GoalStatus.achieved,
        fundingMode: GoalFundingMode.auto,
      );
      final summary = BalanceSummary.compute(
        wallets: [tunai, dana],
        goals: [hpTercapai],
        transactions: [
          tx(TransactionType.goalDeposit, 20000, wallet: 'tunai', goal: 'hp'),
        ],
      );
      expect(summary.autoGoalId, isNull);
      expect(summary.goalCollected['hp'], 20000);
    });
  });
}
