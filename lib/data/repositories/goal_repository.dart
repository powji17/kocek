import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/enums.dart';
import '../models/goal.dart';

/// Struktur data: users/{uid}/goals/{goalId}
class GoalRepository {
  GoalRepository(this._userDoc);

  final DocumentReference<Map<String, dynamic>> _userDoc;

  CollectionReference<Map<String, dynamic>> get _col =>
      _userDoc.collection('goals');

  String newId() => _col.doc().id;

  Stream<List<Goal>> watchAll() {
    return _col.orderBy('order').snapshots().map(
          (snap) => snap.docs.map((d) => Goal.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> save(Goal goal) => _col.doc(goal.id).set(goal.toMap());

  /// Menyimpan urutan baru (urutan = posisi dalam [ordered]).
  Future<void> saveOrder(List<Goal> ordered) {
    final batch = _userDoc.firestore.batch();
    for (var i = 0; i < ordered.length; i++) {
      batch.update(_col.doc(ordered[i].id), {'order': i});
    }
    return batch.commit();
  }

  /// Menghapus target (PRD F6). Setoran ke target ini ikut dihapus sehingga
  /// uangnya kembali menjadi saldo bebas; pengeluaran biasa tidak disentuh.
  /// Dibagi per 400 dokumen dan tidak di-await, jadi aman dipakai offline.
  Future<void> deleteWithDeposits(String goalId) async {
    final linked = await _userDoc
        .collection('transactions')
        .where('goalId', isEqualTo: goalId)
        .get();

    final batches = <WriteBatch>[];
    var batch = _userDoc.firestore.batch();
    var count = 0;
    for (final d in linked.docs) {
      if (d.data()['type'] != TransactionType.goalDeposit.value) continue;
      batch.delete(d.reference);
      count++;
      if (count == 400) {
        batches.add(batch);
        batch = _userDoc.firestore.batch();
        count = 0;
      }
    }
    batch.delete(_col.doc(goalId));
    batches.add(batch);

    for (final b in batches) {
      unawaited(b.commit().catchError((Object _) {}));
    }
  }
}
