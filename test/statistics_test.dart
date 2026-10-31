import 'package:flutter_test/flutter_test.dart';
import 'package:kocek/data/models/enums.dart';
import 'package:kocek/data/models/goal.dart';
import 'package:kocek/data/models/money_transaction.dart';
import 'package:kocek/data/models/wallet.dart';
import 'package:kocek/domain/balances.dart';
import 'package:kocek/domain/statistics.dart';

MoneyTransaction tx(
  TransactionType type,
  int amount,
  DateTime date, {
  String wallet = 'tunai',
  String? to,
  String? cat,
  String? goal,
}) {
  return MoneyTransaction(
    id: 'x${amount}_${date.millisecondsSinceEpoch}_${type.value}',
    type: type,
    amount: amount,
    walletId: wallet,
    toWalletId: to,
    categoryId: cat,
    goalId: goal,
    date: date,
  );
}

void main() {
  final oct = DateTime(2026, 10, 15);

  group('daysInMonth & weekCount', () {
    test('jumlah hari', () {
      expect(daysInMonth(DateTime(2026, 10, 1)), 31);
      expect(daysInMonth(DateTime(2026, 9, 1)), 30);
      expect(daysInMonth(DateTime(2027, 2, 1)), 28);
      expect(daysInMonth(DateTime(2028, 2, 1)), 29);
    });
    test('jumlah minggu', () {
      expect(weekCount(DateTime(2027, 2, 1)), 4); // 28 hari
      expect(weekCount(DateTime(2028, 2, 1)), 5); // 29 hari
      expect(weekCount(DateTime(2026, 10, 1)), 5); // 31 hari
    });
  });

  group('expenseByCategory', () {
    test('menjumlah per kategori, terbesar di atas, hanya bulan itu', () {
      final slices = expenseByCategory([
        tx(TransactionType.expense, 50000, DateTime(2026, 10, 3), cat: 'exp-makan'),
        tx(TransactionType.expense, 30000, DateTime(2026, 10, 20), cat: 'exp-makan'),
        tx(TransactionType.expense, 120000, DateTime(2026, 10, 5), cat: 'exp-jajan'),
        tx(TransactionType.expense, 10000, DateTime(2026, 10, 6)),
        tx(TransactionType.expense, 999, DateTime(2026, 9, 30), cat: 'exp-makan'),
        tx(TransactionType.income, 500000, DateTime(2026, 10, 1)),
        tx(TransactionType.transfer, 200000, DateTime(2026, 10, 2), to: 'dana'),
        tx(TransactionType.goalDeposit, 77000, DateTime(2026, 10, 2), goal: 'hp'),
      ], oct);

      expect(slices.map((s) => s.categoryId).toList(), ['exp-jajan', 'exp-makan', null]);
      expect(slices.map((s) => s.amount).toList(), [120000, 80000, 10000]);
    });

    test('tanpa pengeluaran = kosong', () {
      expect(expenseByCategory(const [], oct), isEmpty);
    });
  });

  group('weeklyTotals & dailyTotals', () {
    final data = [
      tx(TransactionType.income, 100, DateTime(2026, 10, 7)),
      tx(TransactionType.income, 200, DateTime(2026, 10, 8)),
      tx(TransactionType.expense, 50, DateTime(2026, 10, 28)),
      tx(TransactionType.expense, 70, DateTime(2026, 10, 29)),
      tx(TransactionType.income, 999, DateTime(2026, 9, 30)), // bulan lain
      tx(TransactionType.transfer, 5000, DateTime(2026, 10, 10)), // tidak dihitung
    ];

    test('per minggu: 1-7, 8-14, ..., 29 dst', () {
      final weeks = weeklyTotals(data, oct);
      expect(weeks.length, 5);
      expect(weeks.map((w) => w.income).toList(), [100, 200, 0, 0, 0]);
      expect(weeks.map((w) => w.expense).toList(), [0, 0, 0, 50, 70]);
    });

    test('per hari: indeks = tanggal - 1', () {
      final days = dailyTotals(data, oct);
      expect(days.length, 31);
      expect(days[6].income, 100); // 7 Okt
      expect(days[7].income, 200); // 8 Okt
      expect(days[27].expense, 50); // 28 Okt
      expect(days[28].expense, 70); // 29 Okt
      expect(days[0].income, 0);
    });
  });

  group('savingsSeries', () {
    const tunai = Wallet(id: 'tunai', name: 'Tunai', iconKey: 'cash', initialBalance: 100000);
    const dana = Wallet(id: 'dana', name: 'DANA', iconKey: 'wallet', initialBalance: 500000);
    const bank = Wallet(
      id: 'bank',
      name: 'Bank',
      iconKey: 'bank',
      initialBalance: 1000000,
      active: false,
    );
    final wallets = [tunai, dana, bank];
    final txs = [
      tx(TransactionType.income, 50000, DateTime(2026, 9, 20, 10)),
      tx(TransactionType.expense, 30000, DateTime(2026, 10, 2, 9), wallet: 'dana'),
      tx(TransactionType.income, 10000, DateTime(2026, 10, 2, 20)),
      tx(TransactionType.transfer, 100000, DateTime(2026, 10, 5, 8), wallet: 'dana', to: 'tunai'),
      tx(TransactionType.transfer, 20000, DateTime(2026, 10, 5, 9), wallet: 'dana', to: 'bank'),
      tx(TransactionType.goalDeposit, 40000, DateTime(2026, 10, 6, 7), goal: 'hp'),
    ];
    final now = DateTime(2026, 10, 6, 12);

    test('bulan ini: sampai hari ini, total akhir hari', () {
      final series = savingsSeries(wallets: wallets, transactions: txs, month: now, now: now);
      expect(series, [650000, 630000, 630000, 630000, 610000, 610000]);
    });

    test('hari terakhir sama dengan total tabungan di Beranda', () {
      const hp = Goal(
        id: 'hp',
        name: 'HP',
        targetAmount: 6000000,
        iconKey: 'phone',
        colorValue: 0xFFF59E0B,
      );
      final series = savingsSeries(wallets: wallets, transactions: txs, month: now, now: now);
      final summary = BalanceSummary.compute(wallets: wallets, transactions: txs, goals: [hp]);
      expect(series.last, summary.totalSavings);
    });

    test('bulan lalu: penuh satu bulan', () {
      final series = savingsSeries(
        wallets: wallets,
        transactions: txs,
        month: DateTime(2026, 9, 1),
        now: now,
      );
      expect(series.length, 30);
      expect(series[0], 600000); // 1 Sep, sebelum pemasukan 20 Sep
      expect(series[18], 600000); // 19 Sep
      expect(series[19], 650000); // 20 Sep
      expect(series.last, 650000);
    });

    test('bulan depan = kosong', () {
      expect(
        savingsSeries(
          wallets: wallets,
          transactions: txs,
          month: DateTime(2026, 11, 1),
          now: now,
        ),
        isEmpty,
      );
    });
  });

  group('buildInsight', () {
    final slices = [
      const CategorySlice(categoryId: 'exp-jajan', amount: 120000),
      const CategorySlice(categoryId: 'exp-makan', amount: 80000),
    ];
    const names = {'exp-jajan': 'Jajan', 'exp-makan': 'Makan'};
    final now = DateTime(2026, 10, 30);

    test('bulan ini', () {
      expect(
        buildInsight(slices: slices, categoryNames: names, month: DateTime(2026, 10), now: now),
        'Pengeluaran terbesar bulan ini: Jajan (Rp120.000).',
      );
    });
    test('bulan lain menyebut nama bulan', () {
      expect(
        buildInsight(slices: slices, categoryNames: names, month: DateTime(2026, 9), now: now),
        'Pengeluaran terbesar di September 2026: Jajan (Rp120.000).',
      );
    });
    test('tanpa pengeluaran', () {
      expect(
        buildInsight(slices: const [], categoryNames: names, month: DateTime(2026, 10), now: now),
        'Belum ada pengeluaran bulan ini.',
      );
    });
    test('kategori tidak dikenal', () {
      expect(
        buildInsight(
          slices: const [CategorySlice(categoryId: null, amount: 5000)],
          categoryNames: names,
          month: DateTime(2026, 10),
          now: now,
        ),
        'Pengeluaran terbesar bulan ini: Tanpa kategori (Rp5.000).',
      );
    });
  });

  test('formatPercent', () {
    expect(formatPercent(50, 100), '50%');
    expect(formatPercent(1, 3), '33%');
    expect(formatPercent(1, 1000), '<1%');
    expect(formatPercent(0, 0), '0%');
  });

  test('niceInterval memilih kelipatan 1, 2, 5 x 10^n', () {
    expect(niceInterval(1000000), 500000);
    expect(niceInterval(240000), 100000);
    expect(niceInterval(90), 50);
    expect(niceInterval(0), 1);
  });
}
