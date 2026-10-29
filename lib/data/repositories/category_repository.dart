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
}
