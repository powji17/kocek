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
  'coffee': Icons.local_cafe_outlined,
  'directions_bus': Icons.directions_bus_outlined,
  'car': Icons.directions_car_outlined,
  'shopping_bag': Icons.shopping_bag_outlined,
  'movie': Icons.movie_outlined,
  'games': Icons.sports_esports_outlined,
  'school': Icons.school_outlined,
  'books': Icons.menu_book_outlined,
  'health': Icons.medical_services_outlined,
  'home': Icons.home_outlined,
  'pets': Icons.pets_outlined,
  'fitness': Icons.fitness_center_outlined,
  'travel': Icons.flight_outlined,
  'music': Icons.music_note_outlined,
  'work': Icons.work_outline,
  'card_giftcard': Icons.card_giftcard_outlined,
  'more_horiz': Icons.more_horiz,
};

/// Pilihan ikon untuk dompet.
const List<String> walletIconKeys = ['cash', 'wallet', 'bank', 'card', 'savings'];

/// Pilihan ikon untuk kategori buatan pengguna (PRD F5).
const List<String> categoryIconKeys = [
  'restaurant',
  'fastfood',
  'coffee',
  'directions_bus',
  'car',
  'shopping_bag',
  'smartphone',
  'movie',
  'games',
  'school',
  'books',
  'health',
  'home',
  'pets',
  'fitness',
  'travel',
  'music',
  'savings',
  'work',
  'card_giftcard',
  'more_horiz',
];

/// Warna untuk kategori baru; dipakai bergiliran.
const List<int> categoryColorPalette = [
  0xFFF97316,
  0xFFEC4899,
  0xFF3B82F6,
  0xFF8B5CF6,
  0xFF14B8A6,
  0xFFEAB308,
  0xFF6366F1,
  0xFF22C55E,
  0xFF0EA5E9,
  0xFFEF4444,
];

/// Pilihan ikon untuk target tabungan (PRD F6).
const List<String> goalIconKeys = [
  'flag',
  'phone',
  'travel',
  'home',
  'car',
  'books',
  'health',
  'savings',
  'games',
  'music',
  'fitness',
  'pets',
  'school',
  'shopping_bag',
];

/// Pilihan warna untuk target tabungan; yang pertama (amber) adalah bawaan.
const List<int> goalColorPalette = [
  0xFFF59E0B,
  0xFF0F766E,
  0xFF3B82F6,
  0xFF8B5CF6,
  0xFFEC4899,
  0xFFEF4444,
  0xFF22C55E,
  0xFF0EA5E9,
];

IconData iconForKey(String key) => _icons[key] ?? Icons.circle_outlined;
