import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/ui/icon_keys.dart';
import '../../core/utils/rupiah.dart';
import '../../data/providers.dart';
import '../../data/repositories/user_data_repository.dart';
import '../../shared/widgets/rupiah_field.dart';
import '../bootstrap/bootstrap_gate.dart';

class _WalletDraft {
  _WalletDraft({required String name, required this.iconKey})
      : name = TextEditingController(text: name),
        balance = TextEditingController();

  final TextEditingController name;
  final TextEditingController balance;
  final String iconKey;

  void dispose() {
    name.dispose();
    balance.dispose();
  }
}

/// Onboarding 2 langkah (PRD bagian 9): atur dompet + saldo awal,
/// lalu target pertama (boleh dilewati).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _maxWallets = 6;

  int _step = 0;
  String? _error;
  bool _collectedTouched = false;

  final List<_WalletDraft> _wallets = [
    _WalletDraft(name: 'Tunai', iconKey: 'cash'),
    _WalletDraft(name: 'DANA', iconKey: 'wallet'),
  ];
  final _goalName = TextEditingController(text: 'HP Baru');
  final _goalTarget = TextEditingController();
  final _goalCollected = TextEditingController();

  @override
  void dispose() {
    for (final w in _wallets) {
      w.dispose();
    }
    _goalName.dispose();
    _goalTarget.dispose();
    _goalCollected.dispose();
    super.dispose();
  }

  int get _totalBalance => _wallets.fold(
        0,
        (sum, w) => sum + parseRupiahInput(w.balance.text),
      );

  void _addWallet() {
    if (_wallets.length >= _maxWallets) return;
    setState(() {
      _wallets.add(_WalletDraft(name: '', iconKey: 'bank'));
      _error = null;
    });
  }

  void _removeWallet(int index) {
    if (_wallets.length <= 1) return;
    setState(() {
      _wallets.removeAt(index).dispose();
      _error = null;
    });
  }

  void _goToGoalStep() {
    final names = _wallets.map((w) => w.name.text.trim()).toList();
    if (names.any((n) => n.isEmpty)) {
      setState(() => _error = 'Nama dompet tidak boleh kosong.');
      return;
    }
    final lower = names.map((n) => n.toLowerCase()).toSet();
    if (lower.length != names.length) {
      setState(() => _error = 'Nama dompet tidak boleh kembar.');
      return;
    }
    setState(() {
      _error = null;
      _step = 1;
      // Saran awal: seluruh tabunganmu memang untuk target ini.
      if (!_collectedTouched) {
        final total = _totalBalance;
        _goalCollected.text = total > 0 ? formatThousands(total) : '';
      }
    });
  }

  void _finish({required bool skipGoal}) {
    final repo = ref.read(userDataRepositoryProvider);
    if (repo == null) return;

    OnboardingGoal? goal;
    if (!skipGoal) {
      final name = _goalName.text.trim();
      final target = parseRupiahInput(_goalTarget.text);
      final collected = parseRupiahInput(_goalCollected.text);
      if (name.isEmpty) {
        setState(() => _error = 'Nama target tidak boleh kosong.');
        return;
      }
      if (target <= 0) {
        setState(() => _error = 'Isi nominal target lebih dari Rp0.');
        return;
      }
      if (collected > _totalBalance) {
        setState(() {
          _error = 'Yang sudah terkumpul tidak boleh melebihi total saldo '
              '${formatRupiah(_totalBalance)}.';
        });
        return;
      }
      goal = OnboardingGoal(
        name: name,
        targetAmount: target,
        alreadyCollected: collected,
      );
    }

    repo.completeOnboarding(
      wallets: [
        for (final w in _wallets)
          OnboardingWallet(
            name: w.name.text.trim(),
            iconKey: w.iconKey,
            initialBalance: parseRupiahInput(w.balance.text),
          ),
      ],
      goal: goal,
    );
    ref.read(onboardingCompletedProvider.notifier).markCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                'Langkah ${_step + 1} dari 2',
                style: text.labelLarge?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: (_step + 1) / 2,
                  minHeight: 6,
                  color: AppColors.primary,
                  backgroundColor: AppColors.primarySoft,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: _step == 0 ? _buildWalletStep(text) : _buildGoalStep(text),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: text.bodyMedium?.copyWith(color: AppColors.expense),
                ),
              ],
              const SizedBox(height: 12),
              if (_step == 0)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _goToGoalStep,
                    child: const Text('Lanjut'),
                  ),
                )
              else
                Row(
                  children: [
                    TextButton(
                      onPressed: () => setState(() {
                        _step = 0;
                        _error = null;
                      }),
                      child: const Text('Kembali'),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _finish(skipGoal: true),
                      child: const Text('Lewati'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => _finish(skipGoal: false),
                      child: const Text('Selesai'),
                    ),
                  ],
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletStep(TextTheme text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Atur dompetmu',
          style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Isi saldo awal tiap tempat kamu menyimpan uang. '
          'Semuanya bisa diubah nanti di Pengaturan.',
          style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < _wallets.length; i++) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Icon(
                      iconForKey(_wallets[i].iconKey),
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: [
                        TextField(
                          controller: _wallets[i].name,
                          textCapitalization: TextCapitalization.words,
                          inputFormatters: [LengthLimitingTextInputFormatter(20)],
                          decoration: const InputDecoration(labelText: 'Nama dompet'),
                        ),
                        const SizedBox(height: 12),
                        RupiahField(
                          controller: _wallets[i].balance,
                          label: 'Saldo awal',
                        ),
                      ],
                    ),
                  ),
                  if (_wallets.length > 1)
                    IconButton(
                      tooltip: 'Hapus dompet',
                      onPressed: () => _removeWallet(i),
                      icon: const Icon(Icons.close_rounded),
                    )
                  else
                    const SizedBox(width: 8),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (_wallets.length < _maxWallets)
          OutlinedButton.icon(
            onPressed: _addWallet,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tambah dompet'),
          ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildGoalStep(TextTheme text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target pertamamu',
          style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Lagi nabung buat apa? Target lain bisa ditambah kapan saja, '
          'dan langkah ini boleh dilewati.',
          style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _goalName,
          textCapitalization: TextCapitalization.words,
          inputFormatters: [LengthLimitingTextInputFormatter(30)],
          decoration: const InputDecoration(labelText: 'Nama target'),
        ),
        const SizedBox(height: 12),
        RupiahField(controller: _goalTarget, label: 'Nominal target'),
        const SizedBox(height: 12),
        RupiahField(
          controller: _goalCollected,
          label: 'Sudah terkumpul',
          helperText: 'Dari total saldo ${formatRupiah(_totalBalance)}. '
              'Diisi otomatis, silakan ubah sesuai kebutuhan.',
          onChanged: (_) => _collectedTouched = true,
        ),
      ],
    );
  }
}
