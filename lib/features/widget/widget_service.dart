import 'package:flutter/foundation.dart' show debugPrint;
import 'package:home_widget/home_widget.dart';

import '../../domain/widget_snapshot.dart';

/// Nama lengkap kelas AppWidgetProvider di Android (harus sama dengan
/// package + nama kelas di KocekWidgetProvider.kt).
const String kWidgetQualifiedName = 'com.powji.kocek.KocekWidgetProvider';

// Kunci data yang dibaca widget (semuanya String agar aman dibaca Kotlin).
const String _kTotal = 'total_text';
const String _kGoalVisible = 'goal_visible';
const String _kGoalName = 'goal_name';
const String _kGoalPercent = 'goal_percent';
const String _kGoalDetail = 'goal_detail';
const String _kUpdated = 'updated_text';

// Kunci pengaturan widget (disimpan di perangkat).
const String kSettingsGoalKey = 'settings_goal_id';
const String kSettingsHideKey = 'settings_hide';

/// Menyimpan isi widget lalu meminta Android menggambar ulang.
/// Tidak pernah melempar error (mis. perangkat tanpa dukungan widget).
Future<void> pushWidgetSnapshot(WidgetSnapshot s) async {
  try {
    await HomeWidget.saveWidgetData<String>(_kTotal, s.totalText);
    await HomeWidget.saveWidgetData<String>(_kGoalVisible, s.goalVisible ? '1' : '0');
    await HomeWidget.saveWidgetData<String>(_kGoalName, s.goalName);
    await HomeWidget.saveWidgetData<String>(_kGoalPercent, '${s.goalPercent}');
    await HomeWidget.saveWidgetData<String>(_kGoalDetail, s.goalDetail);
    await HomeWidget.saveWidgetData<String>(_kUpdated, s.updatedText);
    await HomeWidget.updateWidget(
      androidName: 'KocekWidgetProvider',
      qualifiedAndroidName: kWidgetQualifiedName,
    );
  } catch (e) {
    debugPrint('Widget gagal diperbarui: $e');
  }
}

/// Mengosongkan widget (dipanggil saat keluar akun) agar saldo tidak
/// tertinggal di layar utama.
Future<void> clearWidget() {
  return pushWidgetSnapshot(
    const WidgetSnapshot(
      totalText: 'Masuk ke Kocek',
      goalVisible: false,
      goalName: '',
      goalPercent: 0,
      goalDetail: '',
      updatedText: '',
    ),
  );
}
