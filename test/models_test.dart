import 'package:flutter_test/flutter_test.dart';
import 'package:kocek/data/models/enums.dart';
import 'package:kocek/data/models/goal.dart';
import 'package:kocek/data/models/money_transaction.dart';
import 'package:kocek/data/models/wallet.dart';

void main() {
  test('MoneyTransaction: toMap lalu fromMap menghasilkan data yang sama', () {
    final t = MoneyTransaction(
      id: 't1',
      type: TransactionType.transfer,
      amount: 150000,
      walletId: 'dana',
      toWalletId: 'tunai',
      note: 'tarik tunai',
      date: DateTime(2026, 10, 29, 8, 30),
    );
    final back = MoneyTransaction.fromMap('t1', t.toMap());
    expect(back.type, TransactionType.transfer);
    expect(back.amount, 150000);
    expect(back.walletId, 'dana');
    expect(back.toWalletId, 'tunai');
    expect(back.note, 'tarik tunai');
    expect(back.date.isAtSameMomentAs(t.date), isTrue);
  });

  test('Goal: toMap lalu fromMap, termasuk deadline dan status', () {
    final g = Goal(
      id: 'g1',
      name: 'HP Baru',
      targetAmount: 6000000,
      iconKey: 'phone',
      colorValue: 0xFFF59E0B,
      deadline: DateTime(2027, 3, 1),
      status: GoalStatus.achieved,
    );
    final back = Goal.fromMap('g1', g.toMap());
    expect(back.name, 'HP Baru');
    expect(back.targetAmount, 6000000);
    expect(back.status, GoalStatus.achieved);
    expect(back.deadline!.isAtSameMomentAs(g.deadline!), isTrue);
    expect(back.isActive, isFalse);
  });

  test('Wallet: toMap lalu fromMap', () {
    const w = Wallet(id: 'w1', name: 'DANA', iconKey: 'wallet', initialBalance: 250000, order: 1);
    final back = Wallet.fromMap('w1', w.toMap());
    expect(back.name, 'DANA');
    expect(back.initialBalance, 250000);
    expect(back.active, isTrue);
    expect(back.order, 1);
  });

  test('nilai enum tidak dikenal jatuh ke default', () {
    expect(TransactionType.fromValue('aneh'), TransactionType.expense);
    expect(GoalStatus.fromValue(null), GoalStatus.active);
  });
}
