import 'dart:math' show max;

/// Rencana menabung menuju deadline (PRD F6): sisa hari dan kebutuhan
/// nabung per minggu / per bulan.
class GoalSchedule {
  const GoalSchedule({required this.daysLeft, this.perWeek, this.perMonth});

  /// Negatif = deadline sudah lewat.
  final int daysLeft;

  /// null bila tidak ada kebutuhan (sudah tercukupi atau deadline lewat).
  final int? perWeek;
  final int? perMonth;

  bool get isOverdue => daysLeft < 0;
}

/// Selisih hari kalender dari [now] ke [deadline]; jam diabaikan.
int daysUntil(DateTime deadline, DateTime now) {
  final a = DateTime.utc(now.year, now.month, now.day);
  final b = DateTime.utc(deadline.year, deadline.month, deadline.day);
  return b.difference(a).inDays;
}

int _ceilDiv(int a, int b) => (a + b - 1) ~/ b;

/// null bila target tidak punya deadline. Nominal dibulatkan ke atas supaya
/// rencana nabung tidak pernah kurang.
GoalSchedule? scheduleFor({
  required int remaining,
  required DateTime? deadline,
  required DateTime now,
}) {
  if (deadline == null) return null;
  final days = daysUntil(deadline, now);
  if (remaining <= 0 || days < 0) return GoalSchedule(daysLeft: days);
  final weeks = max(1, (days / 7).ceil());
  final months = max(1, (days / 30).ceil());
  return GoalSchedule(
    daysLeft: days,
    perWeek: _ceilDiv(remaining, weeks),
    perMonth: _ceilDiv(remaining, months),
  );
}

/// Memindahkan item seperti ReorderableListView (newIndex dihitung sebelum
/// item dicabut).
List<T> reorderList<T>(List<T> list, int oldIndex, int newIndex) {
  final result = [...list];
  var target = newIndex;
  if (target > oldIndex) target -= 1;
  final item = result.removeAt(oldIndex);
  result.insert(target, item);
  return result;
}
