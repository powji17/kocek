import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/balances.dart';
import '../features/auth/providers.dart';
import 'models/category.dart';
import 'models/goal.dart';
import 'models/money_transaction.dart';
import 'models/wallet.dart';
import 'repositories/category_repository.dart';
import 'repositories/goal_repository.dart';
import 'repositories/transaction_repository.dart';
import 'repositories/user_data_repository.dart';
import 'repositories/wallet_repository.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Dokumen induk data pengguna yang sedang login: users/{uid}.
/// null bila belum login.
final userDocProvider =
    Provider<DocumentReference<Map<String, dynamic>>?>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return null;
  return ref.watch(firestoreProvider).collection('users').doc(uid);
});

// ---- Repository ----

final walletRepositoryProvider = Provider<WalletRepository?>((ref) {
  final doc = ref.watch(userDocProvider);
  return doc == null ? null : WalletRepository(doc);
});

final categoryRepositoryProvider = Provider<CategoryRepository?>((ref) {
  final doc = ref.watch(userDocProvider);
  return doc == null ? null : CategoryRepository(doc);
});

final transactionRepositoryProvider = Provider<TransactionRepository?>((ref) {
  final doc = ref.watch(userDocProvider);
  return doc == null ? null : TransactionRepository(doc);
});

final goalRepositoryProvider = Provider<GoalRepository?>((ref) {
  final doc = ref.watch(userDocProvider);
  return doc == null ? null : GoalRepository(doc);
});

final userDataRepositoryProvider = Provider<UserDataRepository?>((ref) {
  final doc = ref.watch(userDocProvider);
  return doc == null ? null : UserDataRepository(doc);
});

// ---- Data real-time (stream) ----

final walletsProvider = StreamProvider<List<Wallet>>((ref) {
  final repo = ref.watch(walletRepositoryProvider);
  return repo == null ? Stream.value(const <Wallet>[]) : repo.watchAll();
});

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo == null ? Stream.value(const <Category>[]) : repo.watchAll();
});

final transactionsProvider = StreamProvider<List<MoneyTransaction>>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo == null
      ? Stream.value(const <MoneyTransaction>[])
      : repo.watchAll();
});

final goalsProvider = StreamProvider<List<Goal>>((ref) {
  final repo = ref.watch(goalRepositoryProvider);
  return repo == null ? Stream.value(const <Goal>[]) : repo.watchAll();
});

// ---- Turunan: saldo ----

/// Ringkasan saldo dihitung ulang otomatis tiap data berubah.
final balanceSummaryProvider = Provider<AsyncValue<BalanceSummary>>((ref) {
  final wallets = ref.watch(walletsProvider);
  final transactions = ref.watch(transactionsProvider);
  final goals = ref.watch(goalsProvider);

  for (final a in [wallets, transactions, goals]) {
    if (a.hasError) {
      return AsyncError<BalanceSummary>(
        a.error!,
        a.stackTrace ?? StackTrace.current,
      );
    }
  }
  if (!wallets.hasValue || !transactions.hasValue || !goals.hasValue) {
    return const AsyncLoading<BalanceSummary>();
  }
  return AsyncData<BalanceSummary>(
    BalanceSummary.compute(
      wallets: wallets.requireValue,
      transactions: transactions.requireValue,
      goals: goals.requireValue,
    ),
  );
});
