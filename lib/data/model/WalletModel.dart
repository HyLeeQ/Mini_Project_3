class WalletModel {
  final String id;
  final String userId;
  final String name;
  final String icon;
  final String colorHex;
  final double balance;

  const WalletModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.icon,
    required this.colorHex,
    required this.balance,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'name': name,
    'icon': icon,
    'colorHex': colorHex,
    'balance': balance,
  };
}
