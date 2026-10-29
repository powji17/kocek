/// Teks pengganti saat pengguna memilih menyembunyikan nominal (PRD F9).
const String hiddenRupiah = 'Rp•••••';

/// Memformat bilangan bulat Rupiah, contoh: 1500000 -> "Rp1.500.000".
///
/// Nominal selalu disimpan sebagai int (tanpa desimal) — PRD bagian 11.
String formatRupiah(int amount, {bool withSign = false}) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final remaining = digits.length - i;
    buffer.write(digits[i]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
  }

  final String sign;
  if (amount < 0) {
    sign = '-';
  } else if (withSign && amount > 0) {
    sign = '+';
  } else {
    sign = '';
  }
  return '${sign}Rp$buffer';
}

/// Mengambil angka dari teks isian, contoh: "Rp 1.500.000" -> 1500000.
/// Teks kosong atau tanpa angka menghasilkan 0.
int parseRupiahInput(String input) {
  final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return 0;
  return int.tryParse(digits) ?? 0;
}
