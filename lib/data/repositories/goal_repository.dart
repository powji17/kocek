import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<void> delete(String id) => _col.doc(id).delete();
}
