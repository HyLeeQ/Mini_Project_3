enum WalletType {
  cash,
  bank,
  ewallet,
}

class WalletModel {
  final String id;
  final String userId;
  final String name;
  final String icon;
  final String colorHex;
  final double balance;
  final WalletType type;

  final String? cardNumber; // chỉ dùng cho bank

  const WalletModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.icon,
    required this.colorHex,
    required this.balance,
    required this.type,
    this.cardNumber,
  }) : assert(
  type != WalletType.bank || cardNumber != null,
  'Bank wallet must have cardNumber',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'name': name,
    'icon': icon,
    'colorHex': colorHex,
    'balance': balance,
    'type': type.name,
    'cardNumber': cardNumber,
  };
  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      colorHex: json['colorHex'] as String,
      balance: (json['balance'] as num).toDouble(),

      type: WalletType.values.firstWhere(
            (e) => e.name == json['type'],
        orElse: () => WalletType.cash, // fallback tránh crash
      ),

      cardNumber: json['cardNumber'] as String?,
    );
  }
}