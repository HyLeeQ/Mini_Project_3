import '../../../../../data/model/TransactionModel.dart';

abstract class TransactionEvent {}

// Load 5 giao dịch gần nhất của user
class LoadRecentTransactions extends TransactionEvent {
  final String userId;
  LoadRecentTransactions(this.userId);
}

// Thêm giao dịch mới (sau khi AddPage lưu thành công)
class AddTransaction extends TransactionEvent {
  final TransactionModel transaction;
  AddTransaction(this.transaction);
}

// Xoá giao dịch
class DeleteTransaction extends TransactionEvent {
  final String transactionId;
  DeleteTransaction(this.transactionId);
}

// Reload lại (pull to refresh)
class RefreshTransactions extends TransactionEvent {
  final String userId;
  RefreshTransactions(this.userId);
}