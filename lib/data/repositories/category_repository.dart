import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/category.dart';

/// Struktur data: users/{uid}/categories/{categoryId}
class CategoryRepository {
  CategoryRepository(this._userDoc);

  final DocumentReference<Map<String, dynamic>> _userDoc;

  CollectionReference<Map<String, dynamic>> get _col =>
      _userDoc.collection('categories');

  String newId() => _col.doc().id;

  Stream<List<Category>> watchAll() {
    return _col.snapshots().map(
          (snap) =>
              snap.docs.map((d) => Category.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> save(Category category) =>
      _col.doc(category.id).set(category.toMap());

  Future<void> delete(String id) => _col.doc(id).delete();

  /// Menghapus kategori dan memindahkan semua transaksinya ke [fallbackId]
  /// ("Lainnya"), sesuai PRD F5. Penulisan dibagi per 400 dokumen (batas
  /// Firestore 500 per batch) dan tidak di-await, jadi aman dipakai offline.
  Future<void> deleteAndReassign({
    required String categoryId,
    required String fallbackId,
  }) async {
    final txs = await _userDoc
        .collection('transactions')
        .where('categoryId', isEqualTo: categoryId)
        .get();

    final batches = <WriteBatch>[];
    var batch = _userDoc.firestore.batch();
    var count = 0;
    for (final d in txs.docs) {
      batch.update(d.reference, {
        'categoryId': fallbackId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      count++;
      if (count == 400) {
        batches.add(batch);
        batch = _userDoc.firestore.batch();
        count = 0;
      }
    }
    batch.delete(_col.doc(categoryId));
    batches.add(batch);

    for (final b in batches) {
      unawaited(b.commit().catchError((Object _) {}));
    }
  }
}
