import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_gate.dart';

class KocekApp extends StatelessWidget {
  const KocekApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kocek',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      // Bahasa Indonesia (PRD bagian 13).
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Belum login -> LoginScreen, sudah login -> AppShell.
      home: const AuthGate(),
    );
  }
}
