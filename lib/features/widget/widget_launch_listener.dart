import 'dart:async';

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import '../transactions/quick_add_sheet.dart';

// Peluncuran awal dari widget hanya diproses sekali per proses aplikasi.
bool _initialLaunchHandled = false;

/// Saat tombol + di widget ditekan, aplikasi terbuka dengan alamat
/// "kocek://add" dan langsung menampilkan layar pencatatan (PRD F9).
/// Dipasang di dalam layar utama, jadi baru aktif setelah login dan onboarding.
class WidgetLaunchListener extends StatefulWidget {
  const WidgetLaunchListener({super.key, required this.child});

  final Widget child;

  @override
  State<WidgetLaunchListener> createState() => _WidgetLaunchListenerState();
}

class _WidgetLaunchListenerState extends State<WidgetLaunchListener> {
  StreamSubscription<Uri?>? _sub;

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  Future<void> _init() async {
    try {
      if (!_initialLaunchHandled) {
        _initialLaunchHandled = true;
        final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
        _handle(uri);
      }
      if (!mounted) return;
      _sub = HomeWidget.widgetClicked.listen(_handle);
    } catch (_) {
      // Perangkat tanpa dukungan widget: abaikan.
    }
  }

  void _handle(Uri? uri) {
    if (uri == null || uri.host != 'add') return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(showQuickAddSheet(context));
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
