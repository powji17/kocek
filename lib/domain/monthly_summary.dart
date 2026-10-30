import '../data/models/enums.dart';
import '../data/models/money_transaction.dart';

/// Ringkasan pemasukan dan pengeluaran sebuah bulan (PRD F4).
/// Pindah antar dompet dan setor target tidak dihitung.
class MonthlySummary {
  const MonthlySummary({required this.income, required this.expense});

  final int income;
  final int expense;

  /// Selisih = masuk - keluar.
  int get net => income - expense;

  factory MonthlySummary.compute(
    List<MoneyTransaction> transactions,
    DateTime month,
  ) {
    var income = 0;
    var expense = 0;
    for (final t in transactions) {
      if (t.date.year != month.year || t.date.month != month.month) continue;
      if (t.type == TransactionType.income) {
        income += t.amount;
      } else if (t.type == TransactionType.expense) {
        expense += t.amount;
      }
    }
    return MonthlySummary(income: income, expense: expense);
  }
}
