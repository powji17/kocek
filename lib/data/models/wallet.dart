/// Dompet (Tunai, DANA, dll). Saldo TIDAK disimpan; dihitung dari
/// saldoAwal + transaksi (lihat domain/balances.dart).
class Wallet {
  const Wallet({
    required this.id,
    required this.name,
    required this.iconKey,
    this.initialBalance = 0,
    this.active = true,
    this.order = 0,
  });

  final String id;
  final String name;
  final String iconKey;
  final int initialBalance;
  final bool active;
  final int order;

  factory Wallet.fromMap(String id, Map<String, dynamic> map) {
    return Wallet(
      id: id,
      name: map['name'] as String? ?? '',
      iconKey: map['iconKey'] as String? ?? 'wallet',
      initialBalance: (map['initialBalance'] as num?)?.toInt() ?? 0,
      active: map['active'] as bool? ?? true,
      order: (map['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'iconKey': iconKey,
        'initialBalance': initialBalance,
        'active': active,
        'order': order,
      };

  Wallet copyWith({
    String? name,
    String? iconKey,
    int? initialBalance,
    bool? active,
    int? order,
  }) {
    return Wallet(
      id: id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      initialBalance: initialBalance ?? this.initialBalance,
      active: active ?? this.active,
      order: order ?? this.order,
    );
  }
}
