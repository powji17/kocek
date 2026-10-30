import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/default_categories.dart';
import '../models/goal.dart';
import '../models/wallet.dart';

/// Isian dompet dari layar onboarding.
class OnboardingWallet {
  const OnboardingWallet({
    required this.name,
    required this.iconKey,
    required this.initialBalance,
  });

  final String name;
  final String iconKey;
  final int initialBalance;
}

/// Isian target pertama dari layar onboarding.
class OnboardingGoal {
  const OnboardingGoal({required this.name, required this.targetAmount});

  final String name;
  final int targetAmount;
}

/// Urusan level pengguna: pengisian awal, onboarding, dan penghapusan data.
class UserDataRepository {
  UserDataRepository(this._userDoc);

  final DocumentReference<Map<String, dynamic>> _userDoc;

  static const _subcollections = [
    'transactions',
    'goals',
    'wallets',
    'categories',
  ];

  /// Mengisi kategori bawaan satu kali saja, menyalin nama dan email akun
  /// ke dokumen pengguna (entitas User, PRD bagian 11), lalu mengembalikan
  /// apakah onboarding sudah selesai. Tidak pernah melempar error; kalau
  /// status tidak bisa dipastikan (misalnya offline tanpa cache), dianggap
  /// sudah selesai supaya pengguna tidak terhalang.
  Future<bool> bootstrap({String? name, String? email}) async {
    try {
      final snap = await _userDoc.get();
      final data = snap.data();

      if (data?['categoriesSeeded'] != true) {
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
      }
      final profile = <String, dynamic>{
        if (name != null && data?['name'] != name) 'name': name,
        if (email != null && data?['email'] != email) 'email': email,
      };
      if (profile.isNotEmpty) {
        unawaited(
          _userDoc
              .set(profile, SetOptions(merge: true))
              .catchError((Object _) {}),
        );
      }
      return data?['onboardingDone'] == true;
    } on FirebaseException {
      return true;
    }
  }

  /// Menyimpan hasil onboarding dalam SATU batch (semua atau tidak sama
  /// sekali): dompet, target pertama (opsional), dan penanda
  /// onboardingDone.
  ///
  /// Tidak di-await: saat offline, batch baru selesai setelah ada internet,
  /// sementara data lokal sudah langsung tampil lewat stream.
  void completeOnboarding({
    required List<OnboardingWallet> wallets,
    OnboardingGoal? goal,
  }) {
    final batch = _userDoc.firestore.batch();

    for (var i = 0; i < wallets.length; i++) {
      final ref = _userDoc.collection('wallets').doc();
      batch.set(
        ref,
        Wallet(
          id: ref.id,
          name: wallets[i].name,
          iconKey: wallets[i].iconKey,
          initialBalance: wallets[i].initialBalance,
          order: i,
        ).toMap(),
      );
    }

    if (goal != null) {
      final goalRef = _userDoc.collection('goals').doc();
      batch.set(
        goalRef,
        Goal(
          id: goalRef.id,
          name: goal.name,
          targetAmount: goal.targetAmount,
          iconKey: 'flag',
          colorValue: 0xFFF59E0B,
        ).toMap(),
      );
    }

    batch.set(_userDoc, {'onboardingDone': true}, SetOptions(merge: true));
    unawaited(batch.commit().catchError((Object _) {}));
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
