import 'package:flutter_test/flutter_test.dart';
import 'package:kocek/core/utils/dates.dart';

void main() {
  final now = DateTime(2026, 10, 29, 15, 30);

  group('formatDateLabel', () {
    test('hari ini', () {
      expect(formatDateLabel(DateTime(2026, 10, 29, 8), now: now), 'Hari ini');
    });
    test('kemarin', () {
      expect(formatDateLabel(DateTime(2026, 10, 28, 23, 59), now: now), 'Kemarin');
    });
    test('kemarin melintasi pergantian bulan', () {
      final awalBulan = DateTime(2026, 11, 1, 9);
      expect(formatDateLabel(DateTime(2026, 10, 31, 20), now: awalBulan), 'Kemarin');
    });
    test('tahun yang sama tanpa tahun', () {
      expect(formatDateLabel(DateTime(2026, 3, 5), now: now), '5 Mar');
    });
    test('tahun berbeda memakai tahun', () {
      expect(formatDateLabel(DateTime(2025, 12, 31), now: now), '31 Des 2025');
    });
  });

  group('formatDateHeader', () {
    final today = DateTime(2026, 10, 30, 10); // Jumat
    test('hari ini', () {
      expect(formatDateHeader(DateTime(2026, 10, 30, 8), now: today), 'Hari ini, 30 Okt 2026');
    });
    test('kemarin', () {
      expect(formatDateHeader(DateTime(2026, 10, 29), now: today), 'Kemarin, 29 Okt 2026');
    });
    test('hari lain memakai nama hari', () {
      expect(formatDateHeader(DateTime(2026, 10, 28), now: today), 'Rabu, 28 Okt 2026');
      expect(formatDateHeader(DateTime(2026, 10, 25), now: today), 'Minggu, 25 Okt 2026');
    });
  });

  group('formatRangeLabel', () {
    test('satu hari', () {
      expect(formatRangeLabel(DateTime(2026, 10, 28), DateTime(2026, 10, 28)), '28 Okt 2026');
    });
    test('tahun sama', () {
      expect(formatRangeLabel(DateTime(2026, 10, 1), DateTime(2026, 10, 29)), '1 Okt – 29 Okt 2026');
    });
    test('beda tahun', () {
      expect(formatRangeLabel(DateTime(2025, 12, 30), DateTime(2026, 1, 2)), '30 Des 2025 – 2 Jan 2026');
    });
  });

  test('formatMonthYear', () {
    expect(formatMonthYear(DateTime(2026, 10, 29)), 'Oktober 2026');
    expect(formatMonthYear(DateTime(2027, 1, 1)), 'Januari 2027');
  });

  test('isSameDay mengabaikan jam', () {
    expect(isSameDay(DateTime(2026, 10, 29, 0, 1), DateTime(2026, 10, 29, 23, 59)), isTrue);
    expect(isSameDay(DateTime(2026, 10, 29), DateTime(2026, 10, 30)), isFalse);
  });
}
