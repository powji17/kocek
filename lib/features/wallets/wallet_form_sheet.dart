import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/ui/icon_keys.dart';
import '../../core/utils/rupiah.dart';
import '../../data/models/wallet.dart';
import '../../data/providers.dart';
import '../../shared/widgets/rupiah_field.dart';

/// Bottom sheet tambah / ubah dompet (PRD F2). [existing] null = tambah baru.
Future<void> showWalletFormSheet(BuildContext context, {Wallet? existing}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => WalletFormSheet(existing: existing),
  );
}

class WalletFormSheet extends ConsumerStatefulWidget {
  const WalletFormSheet({super.key, this.existing});

  final Wallet? existing;

  @override
  ConsumerState<WalletFormSheet> createState() => _WalletFormSheetState();
}

class _WalletFormSheetState extends ConsumerState<WalletFormSheet> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _balance = TextEditingController(
    text: (widget.existing?.initialBalance ?? 0) == 0
        ? ''
        : formatThousands(widget.existing!.initialBalance),
  );
  late String _iconKey = widget.existing?.iconKey ?? 'bank';
  late bool _active = widget.existing?.active ?? true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    final wallets = ref.read(walletsProvider).value ?? const <Wallet>[];
    final existing = widget.existing;

    if (name.isEmpty) {
      setState(() => _error = 'Nama dompet tidak boleh kosong.');
      return;
    }
    final duplicate = wallets.any(
      (w) => w.id != existing?.id && w.name.toLowerCase() == name.toLowerCase(),
    );
    if (duplicate) {
      setState(() => _error = 'Sudah ada dompet dengan nama itu.');
      return;
    }

    final repo = ref.read(walletRepositoryProvider);
    if (repo == null) return;

    final balance = parseRupiahInput(_balance.text);
    final wallet = existing != null
        ? existing.copyWith(
            name: name,
            iconKey: _iconKey,
            initialBalance: balance,
            active: _active,
          )
        : Wallet(
            id: repo.newId(),
            name: name,
            iconKey: _iconKey,
            initialBalance: balance,
            active: _active,
            order: wallets.length,
          );

    // Tidak di-await (offline-first): tampilan sudah berubah lewat stream lokal.
    unawaited(repo.save(wallet).catchError((Object _) {}));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final isEdit = widget.existing != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? 'Ubah dompet' : 'Tambah dompet',
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              inputFormatters: [LengthLimitingTextInputFormatter(20)],
              decoration: const InputDecoration(labelText: 'Nama dompet'),
            ),
            const SizedBox(height: 12),
            RupiahField(
              controller: _balance,
              label: 'Saldo awal',
              helperText: 'Mengubah saldo awal ikut mengubah total tabungan.',
            ),
            const SizedBox(height: 16),
            Text(
              'Ikon',
              style: text.labelLarge?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final key in walletIconKeys)
                  ChoiceChip(
                    showCheckmark: false,
                    label: Icon(iconForKey(key), size: 20),
                    selected: _iconKey == key,
                    onSelected: (_) => setState(() => _iconKey = key),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tampilkan di total tabungan'),
              subtitle: const Text('Matikan untuk menyembunyikan dompet ini.'),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
            if (_error != null) ...[
              const SizedBox(height: 4),
              Text(
                _error!,
                style: text.bodyMedium?.copyWith(color: AppColors.expense),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: const Text('Simpan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
