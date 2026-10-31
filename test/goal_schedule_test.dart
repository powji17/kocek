import 'package:flutter_test/flutter_test.dart';
import 'package:kocek/domain/goal_schedule.dart';

void main() {
  final now = DateTime(2026, 10, 30, 14, 20);

  group('daysUntil', () {
    test('hari yang sama = 0 (jam diabaikan)', () {
      expect(daysUntil(DateTime(2026, 10, 30, 0, 1), now), 0);
    });
    test('melintasi pergantian bulan', () {
      expect(daysUntil(DateTime(2026, 11, 2), now), 3);
    });
    test('sudah lewat = negatif', () {
      expect(daysUntil(DateTime(2026, 10, 27), now), -3);
    });
  });

  group('scheduleFor', () {
    test('tanpa deadline = null', () {
      expect(scheduleFor(remaining: 500000, deadline: null, now: now), isNull);
    });

    test('30 hari: 5 minggu dan 1 bulan', () {
      final s = scheduleFor(
        remaining: 600000,
        deadline: DateTime(2026, 11, 29),
        now: now,
      )!;
      expect(s.daysLeft, 30);
      expect(s.perWeek, 120000); // 600.000 / 5
      expect(s.perMonth, 600000); // 600.000 / 1
    });

    test('100 hari: 15 minggu dan 4 bulan', () {
      final s = scheduleFor(
        remaining: 1200000,
        deadline: DateTime(2027, 2, 7),
        now: now,
      )!;
      expect(s.daysLeft, 100);
      expect(s.perWeek, 80000); // 1.200.000 / 15
      expect(s.perMonth, 300000); // 1.200.000 / 4
    });

    test('nominal dibulatkan ke atas', () {
      final s = scheduleFor(
        remaining: 1000000,
        deadline: DateTime(2026, 12, 14),
        now: now,
      )!;
      expect(s.daysLeft, 45);
      expect(s.perWeek, 142858); // ceil(1.000.000 / 7)
      expect(s.perMonth, 500000); // 1.000.000 / 2
    });

    test('deadline hari ini: seluruh sisa dibutuhkan sekarang', () {
      final s = scheduleFor(
        remaining: 250000,
        deadline: DateTime(2026, 10, 30),
        now: now,
      )!;
      expect(s.daysLeft, 0);
      expect(s.perWeek, 250000);
      expect(s.perMonth, 250000);
    });

    test('deadline lewat: tanpa kebutuhan nabung', () {
      final s = scheduleFor(
        remaining: 250000,
        deadline: DateTime(2026, 10, 27),
        now: now,
      )!;
      expect(s.isOverdue, isTrue);
      expect(s.daysLeft, -3);
      expect(s.perWeek, isNull);
      expect(s.perMonth, isNull);
    });

    test('sudah tercukupi: tanpa kebutuhan nabung', () {
      final s = scheduleFor(
        remaining: 0,
        deadline: DateTime(2026, 12, 1),
        now: now,
      )!;
      expect(s.perWeek, isNull);
      expect(s.perMonth, isNull);
    });
  });

  group('reorderList', () {
    final base = ['a', 'b', 'c', 'd'];

    test('pindah ke bawah (newIndex dihitung sebelum item dicabut)', () {
      expect(reorderList(base, 0, 3), ['b', 'c', 'a', 'd']);
      expect(reorderList(base, 0, 4), ['b', 'c', 'd', 'a']);
    });
    test('pindah ke atas', () {
      expect(reorderList(base, 3, 1), ['a', 'd', 'b', 'c']);
    });
    test('tidak mengubah daftar asli', () {
      reorderList(base, 0, 2);
      expect(base, ['a', 'b', 'c', 'd']);
    });
  });
}
