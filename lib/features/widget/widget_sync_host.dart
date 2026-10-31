import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/goal.dart';
import '../../data/providers.dart';
import '../../domain/widget_snapshot.dart';
import 'widget_providers.dart';
import 'widget_service.dart';

/// Menjaga widget tetap mutakhir (PRD F9): data dikirim ulang setiap ada
/// perubahan saldo, target, atau pengaturan widget, dan saat aplikasi dibuka
/// kembali. Pembaruan beruntun digabung (debounce) agar hemat.
class WidgetSyncHost extends ConsumerStatefulWidget {
  const WidgetSyncHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<WidgetSyncHost> createState() => _WidgetSyncHostState();
}

class _WidgetSyncHostState extends ConsumerState<WidgetSyncHost>
    with WidgetsBindingObserver {
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Kirim data awal setelah frame pertama, saat provider sudah terisi.
    WidgetsBinding.instance.addPostFrameCallback((_) => _schedule());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _schedule();
  }

  void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _push);
  }

  void _push() {
    if (!mounted) return;
    final summary = ref.read(balanceSummaryProvider).value;
    final settings = ref.read(widgetSettingsProvider).value;
    if (summary == null || settings == null) return;
    final goals = ref.read(goalsProvider).value ?? const <Goal>[];
    unawaited(
      pushWidgetSnapshot(
        buildWidgetSnapshot(
          summary: summary,
          goals: goals,
          settings: settings,
          now: DateTime.now(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(balanceSummaryProvider, (previous, next) => _schedule());
    ref.listen(goalsProvider, (previous, next) => _schedule());
    ref.listen(widgetSettingsProvider, (previous, next) => _schedule());
    return widget.child;
  }
}
