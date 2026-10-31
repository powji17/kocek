import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums.dart';

/// Target tabungan (PRD F6). Jumlah "terkumpul" TIDAK disimpan; dihitung
/// dari transaksi (lihat domain/balances.dart).
class Goal {
  const Goal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.iconKey,
    required this.colorValue,
    this.deadline,
    this.order = 0,
    this.status = GoalStatus.active,
    this.achievedAt,
  });

  final String id;
  final String name;
  final int targetAmount;
  final String iconKey;
  final int colorValue;
  final DateTime? deadline;
  final int order;
  final GoalStatus status;
  final DateTime? achievedAt;

  bool get isActive => status == GoalStatus.active;

  factory Goal.fromMap(String id, Map<String, dynamic> map) {
    return Goal(
      id: id,
      name: map['name'] as String? ?? '',
      targetAmount: (map['targetAmount'] as num?)?.toInt() ?? 0,
      iconKey: map['iconKey'] as String? ?? 'flag',
      colorValue: (map['colorValue'] as num?)?.toInt() ?? 0xFFF59E0B,
      deadline: (map['deadline'] as Timestamp?)?.toDate(),
      order: (map['order'] as num?)?.toInt() ?? 0,
      status: GoalStatus.fromValue(map['status'] as String?),
      achievedAt: (map['achievedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'targetAmount': targetAmount,
        'iconKey': iconKey,
        'colorValue': colorValue,
        'deadline': deadline == null ? null : Timestamp.fromDate(deadline!),
        'order': order,
        'status': status.value,
        'achievedAt':
            achievedAt == null ? null : Timestamp.fromDate(achievedAt!),
      };

  /// [clearDeadline] / [clearAchievedAt] dipakai untuk mengosongkan nilainya.
  Goal copyWith({
    String? name,
    int? targetAmount,
    String? iconKey,
    int? colorValue,
    DateTime? deadline,
    bool clearDeadline = false,
    int? order,
    GoalStatus? status,
    DateTime? achievedAt,
    bool clearAchievedAt = false,
  }) {
    return Goal(
      id: id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
      order: order ?? this.order,
      status: status ?? this.status,
      achievedAt: clearAchievedAt ? null : (achievedAt ?? this.achievedAt),
    );
  }
}
