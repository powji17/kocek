const List<String> _monthsShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

const List<String> _monthsLong = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
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

/// "Oktober 2026".
String formatMonthYear(DateTime date) {
  return '${_monthsLong[date.month - 1]} ${date.year}';
}
