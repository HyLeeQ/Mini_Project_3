class Budget {
  final String id;
  final String userId;
  final String categoryId;
  final double limitAmount;
  final double spentAmount;
  final BudgetPeriod period; // daily | weekly | monthly | yearly
  final DateTime startDate;
  final DateTime endDate;

  Budget({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.limitAmount,
    required this.spentAmount,
    required this.period,
    required this.startDate,
    required this.endDate,
  });

  /// ============ TO JSON ============
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'categoryId': categoryId,
      'limitAmount': limitAmount,
      'spentAmount': spentAmount,
      'period': period.name, // enum -> String
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }

  /// ============ FROM JSON ============
  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      categoryId: json['categoryId'] ?? '',

      /// double safe
      limitAmount: (json['limitAmount'] ?? 0).toDouble(),
      spentAmount: (json['spentAmount'] ?? 0).toDouble(),

      /// enum
      period: BudgetPeriod.values.firstWhere(
            (e) => e.name == json['period'],
        orElse: () => BudgetPeriod.monthly,
      ),

      /// DateTime
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
    );
  }
}
enum BudgetPeriod { daily, weekly, monthly, yearly }