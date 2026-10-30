/// Tipe transaksi (PRD bagian 11). Nilai teks disimpan di Firestore.
enum TransactionType {
  income('masuk'),
  expense('keluar'),
  transfer('pindah'),
  goalDeposit('setor-target');

  const TransactionType(this.value);

  final String value;

  static TransactionType fromValue(String? value) {
    return TransactionType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => TransactionType.expense,
    );
  }
}

enum CategoryType {
  income('masuk'),
  expense('keluar');

  const CategoryType(this.value);

  final String value;

  static CategoryType fromValue(String? value) {
    return CategoryType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => CategoryType.expense,
    );
  }
}

enum GoalStatus {
  active('aktif'),
  achieved('tercapai'),
  archived('diarsipkan');

  const GoalStatus(this.value);

  final String value;

  static GoalStatus fromValue(String? value) {
    return GoalStatus.values.firstWhere(
      (t) => t.value == value,
      orElse: () => GoalStatus.active,
    );
  }
}
