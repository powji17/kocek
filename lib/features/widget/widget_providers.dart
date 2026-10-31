import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../../domain/widget_snapshot.dart';
import 'widget_service.dart';

/// Pengaturan widget (target pilihan dan sembunyikan nominal), disimpan di
/// perangkat ini lewat penyimpanan milik home_widget.
class WidgetSettingsNotifier extends AsyncNotifier<WidgetSettings> {
  @override
  Future<WidgetSettings> build() async {
    try {
      final goalId = await HomeWidget.getWidgetData<String>(kSettingsGoalKey);
      final hide = await HomeWidget.getWidgetData<String>(kSettingsHideKey);
      return WidgetSettings(goalId: goalId, hideAmounts: hide == '1');
    } catch (_) {
      return const WidgetSettings();
    }
  }

  /// [goalId]: null = target aktif pertama, [kWidgetGoalNone] = tanpa target.
  Future<void> setGoal(String? goalId) async {
    final current = state.value ?? const WidgetSettings();
    state = AsyncData(
      WidgetSettings(goalId: goalId, hideAmounts: current.hideAmounts),
    );
    try {
      await HomeWidget.saveWidgetData<String>(kSettingsGoalKey, goalId);
    } catch (_) {}
  }

  Future<void> setHideAmounts(bool hide) async {
    final current = state.value ?? const WidgetSettings();
    state = AsyncData(WidgetSettings(goalId: current.goalId, hideAmounts: hide));
    try {
      await HomeWidget.saveWidgetData<String>(kSettingsHideKey, hide ? '1' : '0');
    } catch (_) {}
  }
}

final widgetSettingsProvider =
    AsyncNotifierProvider<WidgetSettingsNotifier, WidgetSettings>(
  WidgetSettingsNotifier.new,
);
