import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/enums.dart';
import '../../data/models/goal.dart';
import '../../data/providers.dart';
import '../../data/repositories/goal_repository.dart';

void _markAchieved(GoalRepository repo, Goal goal) {
  unawaited(
    repo
        .save(
          goal.copyWith(
            status: GoalStatus.achieved,
            achievedAt: DateTime.now(),
          ),
        )
        .catchError((Object _) {}),
  );
}

/// Menandai target sebagai tercapai (PRD F6).
void markGoalAchieved(WidgetRef ref, Goal goal) {
  final repo = ref.read(goalRepositoryProvider);
  if (repo == null) return;
  _markAchieved(repo, goal);
}

/// Setelah pengeluaran ditautkan ke target, aplikasi menawarkan menandai
/// target itu tercapai (PRD F6).
Future<void> offerMarkAchieved(
  BuildContext context,
  GoalRepository repo,
  Goal goal,
) async {
  if (!context.mounted) return;
  final yes = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Tandai "${goal.name}" tercapai?'),
      content: const Text(
        'Pengeluaran untuk target ini sudah dicatat. Kalau barangnya sudah '
        'terbeli, tandai target ini sebagai tercapai.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Nanti'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Tandai tercapai'),
        ),
      ],
    ),
  );
  if (yes == true) _markAchieved(repo, goal);
}
