import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums.dart';

/// Satu transaksi. Dinamai MoneyTransaction agar tidak bentrok dengan
/// kelas `Transaction` milik cloud_firestore.
///
/// - income / expense : memengaruhi saldo [walletId]
/// - transfer         : memindahkan uang dari [walletId] ke [toWalletId]
///                      (total tabungan tidak berubah)
/// - goalDeposit      : menandai uang di [walletId] sebagai milik [goalId]
///                      (saldo dompet & total tidak berubah)
/// - expense dengan [goalId] : pembelian barang target; mengurangi dompet
///                      sekaligus terkumpul target
class MoneyTransaction {
  const MoneyTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.walletId,
    required this.date,
    this.toWalletId,
    this.categoryId,
    this.goalId,
    this.note = '',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final TransactionType type;

  /// Selalu positif, dalam Rupiah bulat.
  final int amount;
  final String walletId;
  final String? toWalletId;
  final String? categoryId;
  final String? goalId;
  final String note;
  final DateTime date;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory MoneyTransaction.fromMap(String id, Map<String, dynamic> map) {
    return MoneyTransaction(
      id: id,
      type: TransactionType.fromValue(map['type'] as String?),
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      walletId: map['walletId'] as String? ?? '',
      toWalletId: map['toWalletId'] as String?,
      categoryId: map['categoryId'] as String?,
      goalId: map['goalId'] as String?,
      note: map['note'] as String? ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// createdAt/updatedAt sengaja tidak ada di sini; diisi repository
  /// memakai waktu server.
  Map<String, dynamic> toMap() => {
        'type': type.value,
        'amount': amount,
        'walletId': walletId,
        'toWalletId': toWalletId,
        'categoryId': categoryId,
        'goalId': goalId,
        'note': note,
        'date': Timestamp.fromDate(date),
      };
}
