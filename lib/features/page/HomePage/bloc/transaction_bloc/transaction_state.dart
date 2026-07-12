import '../../../../../data/model/TransactionModel.dart';

abstract class TransactionState {}

class TransactionInitial extends TransactionState {}

class TransactionLoading extends TransactionState {}

class TransactionLoaded extends TransactionState {
  final List<TransactionModel> transactions; // toàn bộ giao dịch
  final List<TransactionModel> recent;       // 5 gần nhất (đã sort)

  TransactionLoaded({
    required this.transactions,
    required this.recent,
  });

  // Tính tổng thu tháng hiện tại
  double get totalIncomeThisMonth {
    final now = DateTime.now();
    return transactions
        .where((t) =>
    t.type == TransactionType.income &&
        t.date.month == now.month &&
        t.date.year == now.year)
        .fold(0.0, (s, t) => s + t.amount);
  }

  // Tính tổng chi tháng hiện tại
  double get totalExpenseThisMonth {
    final now = DateTime.now();
    return transactions
        .where((t) =>
    t.type == TransactionType.expense &&
        t.date.month == now.month &&
        t.date.year == now.year)
        .fold(0.0, (s, t) => s + t.amount);
  }

  // Nhóm chi tiêu theo categoryId (tháng hiện tại)
  Map<String, double> get expenseByCategory {
    final now = DateTime.now();
    final Map<String, double> result = {};
    for (final t in transactions) {
      if (t.type == TransactionType.expense &&
          t.date.month == now.month &&
          t.date.year == now.year) {
        result[t.categoryId] = (result[t.categoryId] ?? 0) + t.amount;
      }
    }
    return result;
  }

  TransactionLoaded copyWith({
    List<TransactionModel>? transactions,
  }) {
    final all = transactions ?? this.transactions;
    final sorted = [...all]..sort((a, b) => b.date.compareTo(a.date));
    return TransactionLoaded(
      transactions: all,
      recent: sorted.take(5).toList(),
    );
  }
}

class TransactionError extends TransactionState {
  final String message;
  TransactionError(this.message);
}