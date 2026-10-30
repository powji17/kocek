const List<String> _monthsShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

const List<String> _monthsLong = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

const List<String> _weekdays = [
  'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
];

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// "Hari ini", "Kemarin", "29 Okt" (tahun ini), atau "29 Okt 2025".
/// [now] hanya untuk pengujian.
String formatDateLabel(DateTime date, {DateTime? now}) {
  final today = now ?? DateTime.now();
  if (isSameDay(date, today)) return 'Hari ini';
  final yesterday = DateTime(today.year, today.month, today.day - 1);
  if (isSameDay(date, yesterday)) return 'Kemarin';
  final base = '${date.day} ${_monthsShort[date.month - 1]}';
  return date.year == today.year ? base : '$base ${date.year}';
}

/// Judul kelompok tanggal di Riwayat: "Hari ini, 30 Okt 2026",
/// "Kemarin, 29 Okt 2026", atau "Rabu, 28 Okt 2026".
String formatDateHeader(DateTime date, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final full = '${date.day} ${_monthsShort[date.month - 1]} ${date.year}';
  if (isSameDay(date, today)) return 'Hari ini, $full';
  final yesterday = DateTime(today.year, today.month, today.day - 1);
  if (isSameDay(date, yesterday)) return 'Kemarin, $full';
  return '${_weekdays[date.weekday - 1]}, $full';
}

/// Label rentang tanggal, contoh: "1 Okt – 29 Okt 2026".
String formatRangeLabel(DateTime from, DateTime to) {
  String d(DateTime x) => '${x.day} ${_monthsShort[x.month - 1]}';
  if (isSameDay(from, to)) return '${d(from)} ${from.year}';
  if (from.year == to.year) return '${d(from)} – ${d(to)} ${to.year}';
  return '${d(from)} ${from.year} – ${d(to)} ${to.year}';
}

/// "Oktober 2026".
String formatMonthYear(DateTime date) {
  return '${_monthsLong[date.month - 1]} ${date.year}';
}
