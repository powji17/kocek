import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Langkah 2 akan menambahkan inisialisasi Firebase di sini.
  runApp(const ProviderScope(child: KocekApp()));
}
