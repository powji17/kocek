import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tab yang sedang aktif di bottom navigation (0 Beranda, 1 Riwayat,
/// 2 Statistik, 3 Pengaturan). Dipisah supaya layar lain bisa pindah tab,
/// misalnya tombol "Lihat semua" di Beranda.
class SelectedTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final selectedTabProvider = NotifierProvider<SelectedTabNotifier, int>(
  SelectedTabNotifier.new,
);
