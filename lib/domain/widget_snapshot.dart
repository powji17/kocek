import '../core/utils/dates.dart';
import '../core/utils/rupiah.dart';
import '../data/models/goal.dart';
import 'balances.dart';

/// Nilai [WidgetSettings.goalId] untuk "tanpa target".
const String kWidgetGoalNone = '-';

/// Pengaturan widget homescreen (PRD F9). Disimpan di perangkat ini saja.
class WidgetSettings {
  const WidgetSettings({this.goalId, this.hideAmounts = false});

  /// null = target aktif pertama, [kWidgetGoalNone] = tidak menampilkan
  /// target, selain itu = id target pilihan pengguna.
  final String? goalId;

  /// true = nominal ditampilkan sebagai Rp•••••.
  final bool hideAmounts;
}

/// Teks siap tampil untuk widget. Semua pemformatan dilakukan di sini supaya
/// kode Android (Kotlin) cukup menampilkannya.
class WidgetSnapshot {
  const WidgetSnapshot({
    required this.totalText,
    required this.goalVisible,
    required this.goalName,
    required this.goalPercent,
    required this.goalDetail,
    required this.updatedText,
  });

  final String totalText;
  final bool goalVisible;
  final String goalName;
  final int goalPercent;
  final String goalDetail;

  /// Contoh: "Diperbarui 30 Okt 14.05" (PRD bagian 16: tampilkan waktu pembaruan).
  final String updatedText;

  /// Membandingkan isi tanpa waktu pembaruan.
  bool sameContentAs(WidgetSnapshot other) {
    return totalText == other.totalText &&
        goalVisible == other.goalVisible &&
        goalName == other.goalName &&
        goalPercent == other.goalPercent &&
        goalDetail == other.goalDetail;
  }
}

/// Menyusun isi widget (PRD F9): total saldo, progres SATU target pilihan
/// pengguna (bar mini), dan waktu pembaruan.
WidgetSnapshot buildWidgetSnapshot({
  required BalanceSummary? summary,
  required List<Goal> goals,
  required WidgetSettings settings,
  required DateTime now,
}) {
  final hide = settings.hideAmounts;
  final total = summary?.totalSavings ?? 0;

  final active = goals.where((g) => g.isActive).toList();
  Goal? chosen;
  if (settings.goalId != kWidgetGoalNone) {
    final wanted = settings.goalId;
    if (wanted != null) {
      for (final g in active) {
        if (g.id == wanted) chosen = g;
      }
    }
    // Belum memilih, atau target pilihan sudah dihapus/diarsipkan:
    // pakai target aktif pertama.
    chosen ??= active.isEmpty ? null : active.first;
  }

  var percent = 0;
  var detail = '';
  var name = '';
  if (chosen != null) {
    name = chosen.name;
    final collected = summary?.goalCollected[chosen.id] ?? 0;
    final target = chosen.targetAmount;
    final ratio = target <= 0 ? 0.0 : (collected / target).clamp(0.0, 1.0);
    // 99,6% tidak boleh tampil sebagai 100%.
    percent = ratio >= 1 ? 100 : (ratio * 100).floor();
    detail = hide
        ? '$hiddenRupiah dari $hiddenRupiah'
        : '${formatRupiah(collected)} dari ${formatRupiah(target)}';
  }

  return WidgetSnapshot(
    totalText: hide ? hiddenRupiah : formatRupiah(total),
    goalVisible: chosen != null,
    goalName: name,
    goalPercent: percent,
    goalDetail: detail,
    updatedText: 'Diperbarui ${formatDateTimeShort(now)}',
  );
}
