import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/default_categories.dart';

/// Urusan level pengguna: pengisian awal dan penghapusan seluruh data.
class UserDataRepository {
  UserDataRepository(this._userDoc);

  final DocumentReference<Map<String, dynamic>> _userDoc;

  static const _subcollections = [
    'transactions',
    'goals',
    'wallets',
    'categories',
  ];

  /// Mengisi kategori bawaan satu kali saja (penanda: categoriesSeeded).
  /// Tidak pernah melempar error; kalau gagal (misalnya offline tanpa cache),
  /// akan dicoba lagi saat aplikasi dibuka berikutnya.
  Future<void> ensureDefaults() async {
    try {
      final snap = await _userDoc.get();
      if (snap.data()?['categoriesSeeded'] == true) return;

      final batch = _userDoc.firestore.batch();
      for (final c in DefaultCategories.all) {
        batch.set(_userDoc.collection('categories').doc(c.id), c.toMap());
      }
      batch.set(
        _userDoc,
        {
          'categoriesSeeded': true,
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      // Tidak di-await supaya tidak menggantung saat offline.
      unawaited(batch.commit().catchError((Object _) {}));
    } on FirebaseException {
      // Dicoba lagi di peluncuran berikutnya.
    }
  }

  /// Menghapus SELURUH data pengguna (PRD F1). Butuh internet; dibaca dari
  /// server supaya gagal cepat kalau sedang offline.
  Future<void> deleteAllData() async {
    for (final name in _subcollections) {
      final col = _userDoc.collection(name);
      while (true) {
        final snap =
            await col.limit(400).get(const GetOptions(source: Source.server));
        if (snap.docs.isEmpty) break;
        final batch = _userDoc.firestore.batch();
        for (final d in snap.docs) {
          batch.delete(d.reference);
        }
        await batch.commit();
      }
    }
    await _userDoc.delete();
  }
}
