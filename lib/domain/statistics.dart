import 'dart:math' as math;

import '../core/utils/dates.dart';
import '../core/utils/rupiah.dart';
import '../data/models/enums.dart';
import '../data/models/money_transaction.dart';
import '../data/models/wallet.dart';

/// Perhitungan untuk layar Statistik (PRD F8). Fungsi murni tanpa Firebase.

int daysInMonth(DateTime month) => DateTime(month.year, month.month + 1, 0).day;

bool _inMonth(DateTime d, DateTime month) {
  return d.year == month.year && d.month == month.month;
}

/// Total pengeluaran satu kategori pada sebuah bulan.
class CategorySlice {
  const CategorySlice({required this.categoryId, required this.amount});

  /// null = pengeluaran tanpa kategori.
  final String? categoryId;
  final int amount;
}

/// Komposisi pengeluaran per kategori, terbesar di atas. Hanya transaksi
/// bertipe Keluar; pindah dan setor target tidak dihitung.
List<CategorySlice> expenseByCategory(
  List<MoneyTransaction> transactions,
  DateTime month,
) {
  final sums = <String?, int>{};
  for (final t in transactions) {
    if (t.type != TransactionType.expense || !_inMonth(t.date, month)) continue;
    sums[t.categoryId] = (sums[t.categoryId] ?? 0) + t.amount;
  }
  final list = [
    for (final e in sums.entries)
      CategorySlice(categoryId: e.key, amount: e.value),
  ];
  list.sort((a, b) {
    final byAmount = b.amount.compareTo(a.amount);
    if (byAmount != 0) return byAmount;
    return (a.categoryId ?? '').compareTo(b.categoryId ?? '');
  });
  return list;
}

/// Pemasukan dan pengeluaran pada satu periode (minggu atau hari).
class PeriodTotals {
  const PeriodTotals({this.income = 0, this.expense = 0});

  final int income;
  final int expense;
}

/// Minggu 1 = tanggal 1-7, minggu 2 = 8-14, dst. Tanggal 29-31 masuk minggu 5.
int weekCount(DateTime month) => ((daysInMonth(month) - 1) ~/ 7) + 1;

List<PeriodTotals> _bucketTotals(
  List<MoneyTransaction> transactions,
  DateTime month,
  int buckets,
  int Function(int day) bucketOfDay,
) {
  final income = List<int>.filled(buckets, 0);
  final expense = List<int>.filled(buckets, 0);
  for (final t in transactions) {
    if (!_inMonth(t.date, month)) continue;
    final i = bucketOfDay(t.date.day);
    if (t.type == TransactionType.income) {
      income[i] += t.amount;
    } else if (t.type == TransactionType.expense) {
      expense[i] += t.amount;
    }
  }
  return [
    for (var i = 0; i < buckets; i++)
      PeriodTotals(income: income[i], expense: expense[i]),
  ];
}

/// Pemasukan vs pengeluaran per minggu dalam bulan (PRD F8).
List<PeriodTotals> weeklyTotals(
  List<MoneyTransaction> transactions,
  DateTime month,
) {
  return _bucketTotals(
    transactions,
    month,
    weekCount(month),
    (day) => (day - 1) ~/ 7,
  );
}

/// Pemasukan vs pengeluaran per hari dalam bulan (PRD F8).
List<PeriodTotals> dailyTotals(
  List<MoneyTransaction> transactions,
  DateTime month,
) {
  return _bucketTotals(
    transactions,
    month,
    daysInMonth(month),
    (day) => day - 1,
  );
}

/// Total tabungan pada akhir setiap hari dalam [month] (PRD F8: perkembangan
/// total tabungan). Aturannya sama dengan perhitungan saldo di Beranda:
/// saldo awal dompet + pemasukan - pengeluaran +/- pindah, dihitung untuk
/// dompet aktif saja; setor target tidak mengubah total.
///
/// Saldo awal dompet dianggap sudah ada sejak awal (tidak punya tanggal).
/// Bulan ini hanya sampai hari ini; bulan depan menghasilkan daftar kosong.
List<int> savingsSeries({
  required List<Wallet> wallets,
  required List<MoneyTransaction> transactions,
  required DateTime month,
  required DateTime now,
}) {
  final int lastDay;
  if (month.year > now.year || (month.year == now.year && month.month > now.month)) {
    lastDay = 0;
  } else if (month.year == now.year && month.month == now.month) {
    lastDay = now.day;
  } else {
    lastDay = daysInMonth(month);
  }
  if (lastDay <= 0) return const [];

  final balances = <String, int>{for (final w in wallets) w.id: w.initialBalance};

  void add(String? id, int delta) {
    if (id != null && balances.containsKey(id)) {
      balances[id] = balances[id]! + delta;
    }
  }

  void apply(MoneyTransaction t) {
    switch (t.type) {
      case TransactionType.income:
        add(t.walletId, t.amount);
      case TransactionType.expense:
        add(t.walletId, -t.amount);
      case TransactionType.transfer:
        add(t.walletId, -t.amount);
        add(t.toWalletId, t.amount);
      case TransactionType.goalDeposit:
        break;
    }
  }

  final sorted = [...transactions]..sort((a, b) => a.date.compareTo(b.date));
  final monthStart = DateTime(month.year, month.month);
  var i = 0;
  while (i < sorted.length && sorted[i].date.isBefore(monthStart)) {
    apply(sorted[i]);
    i++;
  }

  final result = <int>[];
  for (var day = 1; day <= lastDay; day++) {
    final nextDay = DateTime(month.year, month.month, day + 1);
    while (i < sorted.length && sorted[i].date.isBefore(nextDay)) {
      apply(sorted[i]);
      i++;
    }
    var total = 0;
    for (final w in wallets) {
      if (w.active) total += balances[w.id] ?? 0;
    }
    result.add(total);
  }
  return result;
}

/// Satu kalimat insight otomatis (PRD F8), contoh:
/// "Pengeluaran terbesar bulan ini: Jajan (Rp240.000)."
String buildInsight({
  required List<CategorySlice> slices,
  required Map<String, String> categoryNames,
  required DateTime month,
  required DateTime now,
}) {
  final current = month.year == now.year && month.month == now.month;
  final when = current ? 'bulan ini' : 'di ${formatMonthYear(month)}';
  if (slices.isEmpty) return 'Belum ada pengeluaran $when.';
  final top = slices.first;
  final name = categoryNames[top.categoryId] ?? 'Tanpa kategori';
  return 'Pengeluaran terbesar $when: $name (${formatRupiah(top.amount)}).';
}

/// "50%", "33%", atau "<1%" untuk bagian yang sangat kecil.
String formatPercent(int part, int total) {
  if (total <= 0) return '0%';
  final p = part * 100 / total;
  if (p > 0 && p < 1) return '<1%';
  return '${p.round()}%';
}

/// Jarak antar garis bantu sumbu yang "bulat" (1, 2, 5 x 10^n).
double niceInterval(num maxValue, {int ticks = 4}) {
  if (maxValue <= 0) return 1;
  final raw = maxValue / ticks;
  final magnitude = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
  final f = raw / magnitude;
  final nice = f <= 1 ? 1 : (f <= 2 ? 2 : (f <= 5 ? 5 : 10));
  return nice * magnitude;
}
