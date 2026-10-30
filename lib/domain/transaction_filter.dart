import '../data/models/enums.dart';
import '../data/models/money_transaction.dart';

/// Filter Riwayat (PRD F7): rentang tanggal, tipe, dompet, kategori, dan
/// pencarian catatan. Fungsi murni tanpa Firebase, jadi mudah diuji.
class TransactionFilter {
  const TransactionFilter({
    this.from,
    this.to,
    this.type,
    this.walletId,
    this.categoryId,
    this.query = '',
  });

  /// Rentang tanggal, keduanya inklusif dan dibandingkan per hari.
  final DateTime? from;
  final DateTime? to;
  final TransactionType? type;

  /// Cocok bila dompet asal ATAU dompet tujuan (pindah) sama.
  final String? walletId;
  final String? categoryId;

  /// Dicari di kolom catatan, tidak peka huruf besar-kecil.
  final String query;

  bool get hasRange => from != null && to != null;

  bool get isActive =>
      hasRange ||
      type != null ||
      walletId != null ||
      categoryId != null ||
      query.trim().isNotEmpty;

  TransactionFilter withRange(DateTime? from, DateTime? to) {
    return TransactionFilter(
      from: from,
      to: to,
      type: type,
      walletId: walletId,
      categoryId: categoryId,
      query: query,
    );
  }

  TransactionFilter withType(TransactionType? type) {
    return TransactionFilter(
      from: from,
      to: to,
      type: type,
      walletId: walletId,
      categoryId: categoryId,
      query: query,
    );
  }

  TransactionFilter withWallet(String? walletId) {
    return TransactionFilter(
      from: from,
      to: to,
      type: type,
      walletId: walletId,
      categoryId: categoryId,
      query: query,
    );
  }

  TransactionFilter withCategory(String? categoryId) {
    return TransactionFilter(
      from: from,
      to: to,
      type: type,
      walletId: walletId,
      categoryId: categoryId,
      query: query,
    );
  }

  TransactionFilter withQuery(String query) {
    return TransactionFilter(
      from: from,
      to: to,
      type: type,
      walletId: walletId,
      categoryId: categoryId,
      query: query,
    );
  }

  bool matches(MoneyTransaction t) {
    final day = DateTime(t.date.year, t.date.month, t.date.day);
    final start = from;
    if (start != null &&
        day.isBefore(DateTime(start.year, start.month, start.day))) {
      return false;
    }
    final end = to;
    if (end != null && day.isAfter(DateTime(end.year, end.month, end.day))) {
      return false;
    }
    if (type != null && t.type != type) return false;
    if (walletId != null && t.walletId != walletId && t.toWalletId != walletId) {
      return false;
    }
    if (categoryId != null && t.categoryId != categoryId) return false;

    final q = query.trim().toLowerCase();
    if (q.isNotEmpty && !t.note.toLowerCase().contains(q)) return false;
    return true;
  }

  List<MoneyTransaction> apply(List<MoneyTransaction> all) {
    return all.where(matches).toList();
  }
}

/// Transaksi pada satu hari.
class DayGroup {
  const DayGroup({required this.day, required this.items});

  /// Tanggal (jam 00:00).
  final DateTime day;

  /// Terbaru di atas.
  final List<MoneyTransaction> items;
}

/// Mengelompokkan transaksi per tanggal, terbaru di atas (PRD F7).
List<DayGroup> groupByDay(List<MoneyTransaction> transactions) {
  final sorted = [...transactions]..sort((a, b) => b.date.compareTo(a.date));
  final groups = <DayGroup>[];
  for (final t in sorted) {
    final day = DateTime(t.date.year, t.date.month, t.date.day);
    if (groups.isNotEmpty && groups.last.day == day) {
      groups.last.items.add(t);
    } else {
      groups.add(DayGroup(day: day, items: [t]));
    }
  }
  return groups;
}
