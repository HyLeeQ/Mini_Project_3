import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String userId;
  final String categoryId;
  final String walletId;
  final double amount;
  final TransactionType type;
  final String? note;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.walletId,
    required this.amount,
    required this.type,
    this.note,
    required this.date,
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
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// ================== FROM JSON ==================
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value, {DateTime? fallback}) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
      }
      return fallback ?? DateTime.now();
    }

    return TransactionModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      categoryId: json['categoryId'] ?? '',
      walletId: json['walletId'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),

      /// String -> enum
      type: TransactionType.values.firstWhere(
            (e) => e.name == json['type'],
        orElse: () => TransactionType.expense,
      ),

      note: json['note'],

      /// String -> DateTime
      date: parseDate(json['date']),


      createdAt: parseDate(json['createdAt'], fallback: parseDate(json['date'])),
      updatedAt: parseDate(json['updatedAt'], fallback: parseDate(json['createdAt'])),
    );
  }
}
enum TransactionType { income, expense, transfer }