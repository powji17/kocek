import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/money_transaction.dart';

/// Struktur data: users/{uid}/transactions/{transactionId}
class TransactionRepository {
  TransactionRepository(this._userDoc);

  final DocumentReference<Map<String, dynamic>> _userDoc;

  CollectionReference<Map<String, dynamic>> get _col =>
      _userDoc.collection('transactions');

  /// ID dibuat di perangkat, jadi aman dipakai saat offline.
  String newId() => _col.doc().id;

  /// Terbaru di atas.
  Stream<List<MoneyTransaction>> watchAll() {
    return _col.orderBy('date', descending: true).snapshots().map(
          (snap) => snap.docs
              .map((d) => MoneyTransaction.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Future<void> add(MoneyTransaction t) {
    return _col.doc(t.id).set({
      ...t.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> update(MoneyTransaction t) {
    return _col.doc(t.id).update({
      ...t.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String id) => _col.doc(id).delete();
}
