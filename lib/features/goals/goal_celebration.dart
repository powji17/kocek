import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/rupiah.dart';
import '../../data/models/goal.dart';
import '../../data/providers.dart';
import '../../domain/balances.dart';
import 'goal_actions.dart';

/// Target yang sudah dirayakan pada sesi ini (supaya tidak berulang).
final Set<String> _celebrated = <String>{};

/// Memantau saldo: saat progres sebuah target AKTIF menembus 100%, tampil
/// perayaan sederhana dengan opsi menandai tercapai (PRD F6).
/// Harus dipanggil dari dalam build().
void listenForGoalCelebration(WidgetRef ref, BuildContext context) {
  ref.listen<AsyncValue<BalanceSummary>>(balanceSummaryProvider, (
    previous,
    next,
  ) {
    final before = previous?.value;
    final after = next.value;
    if (before == null || after == null) return;

    final goals = ref.read(goalsProvider).value ?? const <Goal>[];
    for (final g in goals) {
      if (!g.isActive || g.targetAmount <= 0 || _celebrated.contains(g.id)) {
        continue;
      }
      final was = before.goalCollected[g.id] ?? 0;
      final now = after.goalCollected[g.id] ?? 0;
      if (was < g.targetAmount && now >= g.targetAmount) {
        _celebrated.add(g.id);
        showDialog<void>(
          context: context,
          builder: (_) => _CelebrationDialog(
            goal: g,
            collected: now,
            onMarkAchieved: () => markGoalAchieved(ref, g),
          ),
        );
        break;
      }
    }
  });
}

class _CelebrationDialog extends StatelessWidget {
  const _CelebrationDialog({
    required this.goal,
    required this.collected,
    required this.onMarkAchieved,
  });

  final Goal goal;
  final int collected;
  final VoidCallback onMarkAchieved;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final accent = Color(goal.colorValue);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(child: _Confetti(accent: accent)),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.4, end: 1),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) =>
                        Transform.scale(scale: value, child: child),
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.emoji_events_rounded,
                        size: 52,
                        color: accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Target tercapai!',
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              '"${goal.name}" sudah terkumpul ${formatRupiah(collected)} '
              'dari ${formatRupiah(goal.targetAmount)}.',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Nanti'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      onMarkAchieved();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Tandai tercapai'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Konfeti ringan: titik-titik berwarna yang menyebar lalu memudar.
class _Confetti extends StatefulWidget {
  const _Confetti({required this.accent});

  final Color accent;

  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<_Confetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        painter: _ConfettiPainter(_controller.value, widget.accent),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t, this.accent);

  final double t;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final colors = <Color>[
      accent,
      AppColors.primary,
      AppColors.goal,
      AppColors.income,
      AppColors.expense,
    ];
    final center = Offset(size.width / 2, size.height / 2);
    const count = 28;
    final eased = Curves.easeOutCubic.transform(t);
    for (var i = 0; i < count; i++) {
      final angle = (i / count) * 2 * math.pi + (i % 3) * 0.15;
      final distance = eased * (50 + (i % 5) * 16);
      final pos = center + Offset(math.cos(angle), math.sin(angle)) * distance;
      final paint = Paint()
        ..color = colors[i % colors.length].withValues(
          alpha: (1 - t).clamp(0.0, 1.0),
        );
      canvas.drawCircle(pos, 3 + (i % 3).toDouble(), paint);
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => oldDelegate.t != t;
}
