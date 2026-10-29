import 'package:flutter/material.dart';

/// Palet "Teal Tenang" — sesuai PRD bagian 14.
class AppColors {
  AppColors._();

  static const background = Color(0xFFF8FAF9); // putih tulang
  static const surface = Color(0xFFFFFFFF); // kartu
  static const primary = Color(0xFF0F766E); // teal (aksen utama)
  static const primarySoft = Color(0xFFCCEBE7); // latar chip / indikator
  static const income = Color(0xFF16A34A); // pemasukan
  static const expense = Color(0xFFE11D48); // pengeluaran
  static const goal = Color(0xFFF59E0B); // progres target (amber)
  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF6B7280);
  static const divider = Color(0xFFE5E7EB);

  /// Tambahan kecil di luar PRD: teks di atas [primarySoft] agar kontrasnya aman.
  static const primaryDark = Color(0xFF134E4A);
}
