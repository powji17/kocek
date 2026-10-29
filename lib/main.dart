import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
// File ini dibuat otomatis oleh perintah `flutterfire configure`.
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Mode offline-first (PRD bagian 13): data disimpan di perangkat dan
  // otomatis tersinkron ke cloud saat internet kembali.
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  runApp(const ProviderScope(child: KocekApp()));
}
