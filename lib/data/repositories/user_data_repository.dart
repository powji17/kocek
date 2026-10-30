import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/default_categories.dart';
import '../models/enums.dart';
import '../models/goal.dart';
import '../models/money_transaction.dart';
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
  const OnboardingGoal({
    required this.name,
    required this.targetAmount,
    required this.alreadyCollected,
  });

  final String name;
  final int targetAmount;

  /// Bagian dari tabungan yang sudah disisihkan untuk target ini.
  final int alreadyCollected;
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

  /// Mengisi kategori bawaan satu kali saja, lalu mengembalikan apakah
  /// onboarding sudah selesai. Tidak pernah melempar error; kalau status
  /// tidak bisa dipastikan (misalnya offline tanpa cache), dianggap sudah
  /// selesai supaya pengguna tidak terhalang.
  Future<bool> bootstrap() async {
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
      return data?['onboardingDone'] == true;
    } on FirebaseException {
      return true;
    }
  }

  /// Menyimpan hasil onboarding dalam SATU batch (semua atau tidak sama
  /// sekali): dompet, target pertama (opsional), setoran awal ke target,
  /// dan penanda onboardingDone.
  ///
  /// Tidak di-await: saat offline, batch baru selesai setelah ada internet,
  /// sementara data lokal sudah langsung tampil lewat stream.
  void completeOnboarding({
    required List<OnboardingWallet> wallets,
    OnboardingGoal? goal,
  }) {
    final batch = _userDoc.firestore.batch();

    final walletIds = <String>[];
    for (var i = 0; i < wallets.length; i++) {
      final ref = _userDoc.collection('wallets').doc();
      walletIds.add(ref.id);
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

      if (goal.alreadyCollected > 0 && walletIds.isNotEmpty) {
        final txRef = _userDoc.collection('transactions').doc();
        batch.set(txRef, {
          ...MoneyTransaction(
            id: txRef.id,
            type: TransactionType.goalDeposit,
            amount: goal.alreadyCollected,
            walletId: walletIds.first,
            goalId: goalRef.id,
            note: 'Saldo awal target',
            date: DateTime.now(),
          ).toMap(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
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
