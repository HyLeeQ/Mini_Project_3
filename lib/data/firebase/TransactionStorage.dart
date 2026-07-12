import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/TransactionModel.dart';

class TransactionStorage {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveTransaction({
    required String userId,
    required String categoryId,
    required String walletId,
    required double amount,
    required TransactionType type,
    String? note,
    required DateTime date,
    String? toWalletId, // Dùng riêng cho trường hợp Chuyển khoản
  }) async {
    try {
      // Dùng runTransaction để đảm bảo tính toàn vẹn (Atomic)
      await _firestore.runTransaction((transaction) async {

        // 1. Tham chiếu và lấy dữ liệu ví (Ví chính/Ví gửi)
        DocumentReference walletRef = _firestore.collection('Wallets').doc(walletId);
        DocumentSnapshot walletSnap = await transaction.get(walletRef);

        if (!walletSnap.exists) throw Exception("Ví không tồn tại!");
        double currentBalance = (walletSnap.data() as Map<String, dynamic>)['balance'] ?? 0.0;

        // 2. Xử lý logic theo từng loại giao dịch
        if (type == TransactionType.transfer) {
          // --- LOGIC CHUYỂN KHOẢN ---
          if (toWalletId == null) throw Exception("Thiếu ví nhận khi chuyển khoản");

          DocumentReference toWalletRef = _firestore.collection('Wallets').doc(toWalletId);
          DocumentSnapshot toWalletSnap = await transaction.get(toWalletRef);

          if (!toWalletSnap.exists) throw Exception("Ví nhận không tồn tại!");
          double toBalance = (toWalletSnap.data() as Map<String, dynamic>)['balance'] ?? 0.0;

          // Cập nhật số dư cả 2 ví
          transaction.update(walletRef, {'balance': currentBalance - amount});
          transaction.update(toWalletRef, {'balance': toBalance + amount});
        } else {
          // --- LOGIC THU NHẬP / CHI TIÊU ---
          double newBalance = (type == TransactionType.expense)
              ? currentBalance - amount
              : currentBalance + amount;

          transaction.update(walletRef, {'balance': newBalance});
        }

        // 3. Tạo Document Transaction Log
        final docRef = _firestore.collection('Transactions').doc();
        final transactionModel = TransactionModel(
          id: docRef.id,
          userId: userId,
          categoryId: categoryId,
          walletId: walletId,
          amount: amount,
          type: type,
          note: note,
          date: date,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        transaction.set(docRef, transactionModel.toJson());
      });

      print("Giao dịch và cập nhật ví thành công!");
    } catch (e) {
      print("Lỗi khi lưu giao dịch: $e");
      rethrow; // Đẩy lỗi ra ngoài để UI hiển thị thông báo
    }
  }
}