import 'package:flutter_test/flutter_test.dart';
import 'package:kocek/core/utils/dates.dart';
import 'package:kocek/data/models/enums.dart';
import 'package:kocek/data/models/goal.dart';
import 'package:kocek/domain/balances.dart';
import 'package:kocek/domain/widget_snapshot.dart';

void main() {
  const hp = Goal(
    id: 'hp',
    name: 'HP Baru',
    targetAmount: 6000000,
    iconKey: 'phone',
    colorValue: 0xFFF59E0B,
  );
  const liburan = Goal(
    id: 'lib',
    name: 'Liburan',
    targetAmount: 3000000,
    iconKey: 'travel',
    colorValue: 0xFF14B8A6,
    order: 1,
  );
  const arsip = Goal(
    id: 'arc',
    name: 'Lama',
    targetAmount: 1000000,
    iconKey: 'flag',
    colorValue: 0xFF000000,
    status: GoalStatus.archived,
  );
  const summary = BalanceSummary(
    walletBalances: {},
    totalSavings: 3250000,
    goalCollected: {'hp': 2000000, 'lib': 100000, 'arc': 500000},
    freeBalance: 1150000,
  );
  final now = DateTime(2026, 10, 30, 14, 20);

  test('bawaan: target aktif pertama, nominal tampil', () {
    final s = buildWidgetSnapshot(
      summary: summary,
      goals: [hp, liburan],
      settings: const WidgetSettings(),
      now: now,
    );
    expect(s.totalText, 'Rp3.250.000');
    expect(s.goalVisible, isTrue);
    expect(s.goalName, 'HP Baru');
    expect(s.goalPercent, 33); // 33,3% dibulatkan ke bawah
    expect(s.goalDetail, 'Rp2.000.000 dari Rp6.000.000');
    expect(s.updatedText, 'Diperbarui 30 Okt 14.20');
  });

  test('sembunyikan nominal: Rp••••• tapi persen tetap tampil', () {
    final s = buildWidgetSnapshot(
      summary: summary,
      goals: [hp],
      settings: const WidgetSettings(hideAmounts: true),
      now: now,
    );
    expect(s.totalText, 'Rp•••••');
    expect(s.goalDetail, 'Rp••••• dari Rp•••••');
    expect(s.goalPercent, 33);
  });

  test('target pilihan pengguna', () {
    final s = buildWidgetSnapshot(
      summary: summary,
      goals: [hp, liburan],
      settings: const WidgetSettings(goalId: 'lib'),
      now: now,
    );
    expect(s.goalName, 'Liburan');
    expect(s.goalPercent, 3); // 3,3%
  });

  test('tanpa target', () {
    final s = buildWidgetSnapshot(
      summary: summary,
      goals: [hp, liburan],
      settings: const WidgetSettings(goalId: kWidgetGoalNone),
      now: now,
    );
    expect(s.goalVisible, isFalse);
    expect(s.totalText, 'Rp3.250.000');
  });

  test('target pilihan sudah diarsipkan atau hilang: pakai target aktif pertama', () {
    for (final id in ['arc', 'tidak-ada']) {
      final s = buildWidgetSnapshot(
        summary: summary,
        goals: [arsip, hp],
        settings: WidgetSettings(goalId: id),
        now: now,
      );
      expect(s.goalName, 'HP Baru');
    }
  });

  test('tidak ada target aktif: bagian target disembunyikan', () {
    final s = buildWidgetSnapshot(
      summary: summary,
      goals: [arsip],
      settings: const WidgetSettings(),
      now: now,
    );
    expect(s.goalVisible, isFalse);
  });

  test('99,6% tidak tampil 100%; tercapai = 100%', () {
    const near = BalanceSummary(
      walletBalances: {},
      totalSavings: 0,
      goalCollected: {'hp': 5976000},
      freeBalance: 0,
    );
    expect(
      buildWidgetSnapshot(
        summary: near,
        goals: [hp],
        settings: const WidgetSettings(),
        now: now,
      ).goalPercent,
      99,
    );
    const done = BalanceSummary(
      walletBalances: {},
      totalSavings: 0,
      goalCollected: {'hp': 7000000},
      freeBalance: 0,
    );
    expect(
      buildWidgetSnapshot(
        summary: done,
        goals: [hp],
        settings: const WidgetSettings(),
        now: now,
      ).goalPercent,
      100,
    );
  });

  test('data belum siap: total Rp0', () {
    final s = buildWidgetSnapshot(
      summary: null,
      goals: const [],
      settings: const WidgetSettings(),
      now: now,
    );
    expect(s.totalText, 'Rp0');
    expect(s.goalVisible, isFalse);
  });

  test('sameContentAs mengabaikan waktu pembaruan', () {
    final a = buildWidgetSnapshot(
      summary: summary,
      goals: [hp],
      settings: const WidgetSettings(),
      now: now,
    );
    final b = buildWidgetSnapshot(
      summary: summary,
      goals: [hp],
      settings: const WidgetSettings(),
      now: now.add(const Duration(hours: 3)),
    );
    expect(a.updatedText, isNot(b.updatedText));
    expect(a.sameContentAs(b), isTrue);
  });

  test('formatDateTimeShort', () {
    expect(formatDateTimeShort(DateTime(2026, 10, 30, 14, 5)), '30 Okt 14.05');
    expect(formatDateTimeShort(DateTime(2026, 1, 2, 9, 0)), '2 Jan 09.00');
  });
}
