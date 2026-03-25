class TransactionModel {
  final String id;
  final String userId;
  final String categoryId;
  final String? walletId;
  final double amount;
  final TransactionType type;
  final String? note;
  final DateTime date;
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    this.walletId,
    required this.amount,
    required this.type,
    this.note,
    required this.date,
    required this.imageUrls,
    required this.createdAt,
    required this.updatedAt,
  });

  /// ================== TO JSON ==================
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'categoryId': categoryId,
      'walletId': walletId,
      'amount': amount,
      'type': type.name, // enum -> String
      'note': note,
      'date': date.toIso8601String(),
      'imageUrls': imageUrls,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// ================== FROM JSON ==================
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      categoryId: json['categoryId'] ?? '',
      walletId: json['walletId'],
      amount: (json['amount'] ?? 0).toDouble(),

      /// String -> enum
      type: TransactionType.values.firstWhere(
            (e) => e.name == json['type'],
        orElse: () => TransactionType.expense,
      ),

      note: json['note'],

      /// String -> DateTime
      date: DateTime.parse(json['date']),

      /// List<dynamic> -> List<String>
      imageUrls: List<String>.from(json['imageUrls'] ?? []),

      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
enum TransactionType { income, expense, transfer }