import 'package:flutter_test/flutter_test.dart';
import 'package:kocek/data/models/enums.dart';
import 'package:kocek/data/models/money_transaction.dart';
import 'package:kocek/domain/monthly_summary.dart';

MoneyTransaction tx(TransactionType type, int amount, DateTime date) {
  return MoneyTransaction(
    id: 'x${amount}_${date.millisecondsSinceEpoch}',
    type: type,
    amount: amount,
    walletId: 'tunai',
    date: date,
  );
}

void main() {
  final oct = DateTime(2026, 10, 15);

  test('menjumlah pemasukan dan pengeluaran bulan yang dipilih saja', () {
    final summary = MonthlySummary.compute([
      tx(TransactionType.income, 500000, DateTime(2026, 10, 1)),
      tx(TransactionType.expense, 120000, DateTime(2026, 10, 20)),
      tx(TransactionType.expense, 30000, DateTime(2026, 10, 31, 23, 59)),
      tx(TransactionType.expense, 999999, DateTime(2026, 9, 30)),
      tx(TransactionType.income, 999999, DateTime(2026, 11, 1)),
    ], oct);

    expect(summary.income, 500000);
    expect(summary.expense, 150000);
    expect(summary.net, 350000);
  });

  test('pindah dan setor target tidak dihitung', () {
    final summary = MonthlySummary.compute([
      tx(TransactionType.transfer, 200000, DateTime(2026, 10, 5)),
      tx(TransactionType.goalDeposit, 300000, DateTime(2026, 10, 6)),
    ], oct);

    expect(summary.income, 0);
    expect(summary.expense, 0);
    expect(summary.net, 0);
  });

  test('selisih bisa negatif', () {
    final summary = MonthlySummary.compute([
      tx(TransactionType.expense, 80000, DateTime(2026, 10, 2)),
    ], oct);
    expect(summary.net, -80000);
  });
}
