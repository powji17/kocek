import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/wallet.dart';

/// Struktur data: users/{uid}/wallets/{walletId}
///
/// PENTING (offline-first): Future dari set/update/delete baru selesai saat
/// server mengonfirmasi. Dari UI JANGAN di-`await` untuk menunggu tampilan
/// berubah; stream sudah langsung menerima perubahan lokal.
class WalletRepository {
  WalletRepository(this._userDoc);

  final DocumentReference<Map<String, dynamic>> _userDoc;

  CollectionReference<Map<String, dynamic>> get _col =>
      _userDoc.collection('wallets');

  String newId() => _col.doc().id;

  Stream<List<Wallet>> watchAll() {
    return _col.orderBy('order').snapshots().map(
          (snap) =>
              snap.docs.map((d) => Wallet.fromMap(d.id, d.data())).toList(),
        );
  }

  Future<void> save(Wallet wallet) => _col.doc(wallet.id).set(wallet.toMap());
}
