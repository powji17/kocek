import 'package:flutter/material.dart';

import '../../shared/widgets/placeholder_screen.dart';
import '../home/home_screen.dart';
import '../transactions/quick_add_sheet.dart';

/// Kerangka utama: bottom navigation 4 tab (PRD bagian 10).
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _titles = ['Kocek', 'Riwayat', 'Statistik', 'Pengaturan'];

  // IndexedStack menjaga state tiap tab saat berpindah.
  static const _screens = <Widget>[
    HomeScreen(),
    PlaceholderScreen(
      icon: Icons.receipt_long_outlined,
      title: 'Riwayat',
      message: 'Daftar transaksi, filter, dan pencarian hadir di Langkah 6.',
    ),
    PlaceholderScreen(
      icon: Icons.pie_chart_outline,
      title: 'Statistik',
      message: 'Grafik donat, batang, dan garis hadir di Langkah 8.',
    ),
    PlaceholderScreen(
      icon: Icons.settings_outlined,
      title: 'Pengaturan',
      message: 'Dompet, kategori, target, dan akun hadir bertahap.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      body: IndexedStack(index: _index, children: _screens),
      // Tombol + hanya di Beranda (PRD F3).
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: () => showQuickAddSheet(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Catat'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
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
