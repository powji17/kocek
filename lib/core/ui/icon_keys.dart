import 'package:flutter/material.dart';

/// Kunci ikon (teks) yang disimpan di Firestore -> IconData.
/// Menyimpan teks, bukan kode ikon, supaya data tidak rusak saat Flutter
/// memperbarui set ikonnya.
const Map<String, IconData> _icons = {
  // Dompet
  'cash': Icons.payments_outlined,
  'wallet': Icons.account_balance_wallet_outlined,
  'bank': Icons.account_balance_outlined,
  'card': Icons.credit_card_outlined,
  'savings': Icons.savings_outlined,
  // Target
  'phone': Icons.smartphone_outlined,
  'flag': Icons.flag_outlined,
  // Kategori
  'smartphone': Icons.smartphone_outlined,
  'restaurant': Icons.restaurant_outlined,
  'fastfood': Icons.fastfood_outlined,
  'directions_bus': Icons.directions_bus_outlined,
  'shopping_bag': Icons.shopping_bag_outlined,
  'movie': Icons.movie_outlined,
  'school': Icons.school_outlined,
  'work': Icons.work_outline,
  'card_giftcard': Icons.card_giftcard_outlined,
  'more_horiz': Icons.more_horiz,
};

/// Pilihan ikon untuk dompet.
const List<String> walletIconKeys = ['cash', 'wallet', 'bank', 'card', 'savings'];

IconData iconForKey(String key) => _icons[key] ?? Icons.circle_outlined;
