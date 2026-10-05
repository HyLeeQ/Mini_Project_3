enum MessageRole { user, assistant }

class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final bool isLoading;

  // --- THÊM CÁC TRƯỜNG NÀY ---
  final double? amount;
  final String? note;
  final String? categoryId;
  final String? selectedWalletId; // Ví người dùng chọn
  final bool showActionCard; // Cờ để biết có hiện Card hay không

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isLoading = false,
    this.amount,
    this.note,
    this.categoryId,
    this.selectedWalletId,
    this.showActionCard = false,
  });

  // Đừng quên tạo hàm copyWith để cập nhật khi chọn ví
  ChatMessage copyWith({
    String? content,
    String? selectedWalletId,
    bool? showActionCard,
    bool? isLoading, // Thêm vào tham số nhận vào
  }) {
    return ChatMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      timestamp: timestamp,
      isLoading: isLoading ?? this.isLoading, // TRUYỀN GIÁ TRỊ VÀO ĐÂY
      amount: amount,
      note: note,
      categoryId: categoryId,
      selectedWalletId: selectedWalletId ?? this.selectedWalletId,
      showActionCard: showActionCard ?? this.showActionCard,
    );
  }
}
