import 'package:flutter_test/flutter_test.dart';
import 'package:kocek/data/models/enums.dart';
import 'package:kocek/data/models/money_transaction.dart';
import 'package:kocek/domain/transaction_filter.dart';

MoneyTransaction t(
  String id,
  TransactionType type,
  DateTime date, {
  String wallet = 'tunai',
  String? to,
  String? cat,
  String note = '',
}) {
  return MoneyTransaction(
    id: id,
    type: type,
    amount: 1000,
    walletId: wallet,
    toWalletId: to,
    categoryId: cat,
    note: note,
    date: date,
  );
}

void main() {
  final a = t('a', TransactionType.expense, DateTime(2026, 10, 29, 9),
      cat: 'exp-makan', note: 'Nasi goreng');
  final b = t('b', TransactionType.income, DateTime(2026, 10, 28, 15),
      wallet: 'dana', cat: 'inc-uang-saku', note: 'Uang saku mingguan');
  final c = t('c', TransactionType.transfer, DateTime(2026, 10, 28, 8),
      wallet: 'dana', to: 'tunai');
  final d = t('d', TransactionType.expense, DateTime(2026, 10, 1, 23, 59),
      cat: 'exp-jajan');
  final e = t('e', TransactionType.goalDeposit, DateTime(2026, 9, 30));
  final all = [a, b, c, d, e];

  List<String> ids(List<MoneyTransaction> list) => list.map((x) => x.id).toList();

  test('tanpa filter semua transaksi lolos', () {
    const f = TransactionFilter();
    expect(f.isActive, isFalse);
    expect(ids(f.apply(all)), ['a', 'b', 'c', 'd', 'e']);
  });

  test('rentang tanggal inklusif dan dihitung per hari', () {
    final f = const TransactionFilter().withRange(
      DateTime(2026, 10, 28),
      DateTime(2026, 10, 29),
    );
    expect(ids(f.apply(all)), ['a', 'b', 'c']);

    // Transaksi jam 23:59 pada hari terakhir rentang tetap ikut.
    final one = const TransactionFilter().withRange(
      DateTime(2026, 10, 1),
      DateTime(2026, 10, 1),
    );
    expect(ids(one.apply(all)), ['d']);
  });

  test('filter tipe', () {
    final f = const TransactionFilter().withType(TransactionType.expense);
    expect(ids(f.apply(all)), ['a', 'd']);
  });

  test('filter dompet cocok dengan dompet asal maupun tujuan', () {
    expect(
      ids(const TransactionFilter().withWallet('tunai').apply(all)),
      ['a', 'c', 'd', 'e'],
    );
    expect(
      ids(const TransactionFilter().withWallet('dana').apply(all)),
      ['b', 'c'],
    );
  });

  test('filter kategori', () {
    final f = const TransactionFilter().withCategory('exp-makan');
    expect(ids(f.apply(all)), ['a']);
  });

  test('pencarian catatan tidak peka huruf besar-kecil dan mengabaikan spasi tepi', () {
    expect(ids(const TransactionFilter().withQuery('NASI').apply(all)), ['a']);
    expect(ids(const TransactionFilter().withQuery('  saku ').apply(all)), ['b']);
    expect(ids(const TransactionFilter().withQuery('tidak ada').apply(all)), isEmpty);
    expect(const TransactionFilter().withQuery('   ').isActive, isFalse);
  });

  test('beberapa filter digabung (harus lolos semuanya)', () {
    final f = const TransactionFilter()
        .withType(TransactionType.expense)
        .withWallet('tunai')
        .withQuery('nasi');
    expect(ids(f.apply(all)), ['a']);
    expect(f.isActive, isTrue);
  });

  test('mengubah satu filter tidak menghapus filter lain', () {
    final f = const TransactionFilter()
        .withType(TransactionType.income)
        .withWallet('dana')
        .withType(null);
    expect(f.type, isNull);
    expect(f.walletId, 'dana');
  });

  group('groupByDay', () {
    test('dikelompokkan per tanggal, terbaru di atas', () {
      final groups = groupByDay([d, a, e, c, b]); // sengaja acak
      expect(groups.map((g) => g.day).toList(), [
        DateTime(2026, 10, 29),
        DateTime(2026, 10, 28),
        DateTime(2026, 10, 1),
        DateTime(2026, 9, 30),
      ]);
      // Dalam satu hari, jam terbaru di atas: b (15:00) sebelum c (08:00).
      expect(ids(groups[1].items), ['b', 'c']);
    });

    test('daftar kosong menghasilkan kelompok kosong', () {
      expect(groupByDay(const []), isEmpty);
    });
  });
}
