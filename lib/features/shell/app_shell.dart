import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/placeholder_screen.dart';
import '../goals/goal_celebration.dart';
import '../history/history_screen.dart';
import '../home/home_screen.dart';
import '../settings/settings_screen.dart';
import '../transactions/quick_add_sheet.dart';
import 'shell_providers.dart';

/// Kerangka utama: bottom navigation 4 tab (PRD bagian 10).
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const _titles = ['Kocek', 'Riwayat', 'Statistik', 'Pengaturan'];

  // IndexedStack menjaga state tiap tab saat berpindah.
  static const _screens = <Widget>[
    HomeScreen(),
    HistoryScreen(),
    PlaceholderScreen(
      icon: Icons.pie_chart_outline,
      title: 'Statistik',
      message: 'Grafik donat, batang, dan garis hadir di Langkah 8.',
    ),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(selectedTabProvider);
    // Perayaan sederhana saat progres sebuah target menembus 100% (PRD F6).
    listenForGoalCelebration(ref, context);
    return Scaffold(
      appBar: AppBar(title: Text(_titles[index])),
      body: IndexedStack(index: index, children: _screens),
      // Tombol + hanya di Beranda (PRD F3).
      floatingActionButton: index == 0
          ? FloatingActionButton.extended(
              onPressed: () => showQuickAddSheet(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Catat'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) =>
            ref.read(selectedTabProvider.notifier).select(i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Statistik',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}
