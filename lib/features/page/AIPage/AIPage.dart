import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/firebase/TransactionStorage.dart';
import '../../../data/model/ChatMessage.dart';
import '../../../data/model/TransactionModel.dart';
import '../../../data/model/UserModel.dart';
import '../../../data/model/WalletModel.dart';
import '../../../data/repositories/services/ChatAIService.dart';
import '../HomePage/bloc/transaction_bloc/transaction_bloc.dart';
import '../HomePage/bloc/transaction_bloc/transaction_event.dart';
import '../HomePage/bloc/transaction_bloc/transaction_state.dart';
import '../HomePage/bloc/wallet_bloc/wallet_bloc.dart';
import '../HomePage/bloc/wallet_bloc/wallet_event.dart';
import '../HomePage/bloc/wallet_bloc/wallet_state.dart';
import '../add_transaction/app_colors.dart';
import 'constants/ai_colors.dart';
import 'widgets/ai_header.dart';
import 'widgets/input_bar.dart';
import 'widgets/message_bubble.dart';
import 'widgets/suggestion_chips.dart';

class AIPage extends StatefulWidget {
  final UserModel user;
  const AIPage({super.key,required this.user});

  @override
  State<AIPage> createState() => _AIPageState();
}

class _AIPageState extends State<AIPage> with TickerProviderStateMixin {
  final ChatAIService _chatService = ChatAIService();
  final _inputCtrl  = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode  = FocusNode();

  late final AnimationController _headerCtrl;
  late final Animation<double>   _headerAnim;
  late final AnimationController _pulseCtrl;
  late final Animation<double>   _pulseAnim;

  final List<ChatMessage> _messages = [];
  bool _isTyping     = false;
  bool _inputFocused = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _headerCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700),
    );
    _headerAnim = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerCtrl.forward();

    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _focusNode.addListener(() {
      setState(() => _inputFocused = _focusNode.hasFocus);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _addWelcomeMessage());
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _pulseCtrl.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(ChatMessage(
        id:        'welcome',
        role:      MessageRole.assistant,
        content:   'Xin chào! Tôi là **DoctorĐồng AI** ✨\n\nTôi có thể giúp bạn:\n• 📊 Phân tích chi tiêu hàng tháng\n• 💡 Gợi ý cắt giảm & tiết kiệm\n• 🎯 Lập kế hoạch ngân sách\n\nBạn muốn hỏi gì hôm nay?',
        timestamp: DateTime.now(),
      ));
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isTyping) return;

    // 1. Lấy dữ liệu từ Bloc để gửi cho AI tính toán (nếu cần)
    final transactionState = context.read<TransactionBloc>().state;
    final walletState = context.read<WalletBloc>().state;
    List<TransactionModel> allTransactions = [];
    List<WalletModel> allWallets = [];
    if(walletState is WalletLoaded){
      allWallets = walletState.wallets;
    }
    if (transactionState is TransactionLoaded) {
      allTransactions = transactionState.transactions;
    }else {
      // Nếu chưa load xong, có thể AI sẽ báo "Không thấy dữ liệu"
      print("Cảnh báo: TransactionBloc chưa Loaded!");
    }

    // 2. Thêm tin nhắn của User vào giao diện
    final userMsgId = '${DateTime.now().millisecondsSinceEpoch}_user';
    setState(() {
      _messages.add(ChatMessage(
        id: userMsgId,
        role: MessageRole.user,
        content: text.trim(),
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
      _inputCtrl.clear();
    });
    _scrollToBottom();

    // 3. Tạo tin nhắn chờ (Loading) cho AI
    final loadingId = '${DateTime.now().millisecondsSinceEpoch}_ai';
    setState(() {
      _messages.add(ChatMessage(
        id: loadingId,
        role: MessageRole.assistant,
        content: '',
        timestamp: DateTime.now(),
        isLoading: true,
      ));
    });
    _scrollToBottom();

    try {
      final balance = allWallets.fold(0.0, (s, w) => s + w.balance);
      final response = await _chatService.getAIResponse(text.trim(), allTransactions,balance);
      print("DEBUG AI RESPONSE: $response");

      String aiReply = response['reply'] ?? "Tôi đang nghe đây...";
      Map<String, dynamic>? data = response['extracted_data'];
      print(data);
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == loadingId);
        if (idx != -1) {
          // KIỂM TRA AN TOÀN TRƯỚC KHI ÉP KIỂU
          double? amount;
          if (data != null && data.containsKey('amount') && data['amount'] != null) {
            amount = (data['amount'] as num).toDouble();
          }

          _messages[idx] = ChatMessage(
            id: loadingId,
            role: MessageRole.assistant,
            content: aiReply,
            timestamp: DateTime.now(),
            isLoading: false,
            amount: amount, // Chỉ có giá trị khi AI nhận diện được lệnh "Ăn cơm 30k"
            note: data?['note'],
            categoryId: data?['category']?.toString(),
            // CHỈ hiện Action Card nếu có số tiền cụ thể để LƯU
            showActionCard: amount != null,
          );
        }
      });
    } catch (e) {
      print("Lỗi Chat AI: $e");
      _replaceMessage(loadingId, '⚠️ Lỗi kết nối AI. Lân kiểm tra lại mạng hoặc API Key nhé!');
    } finally {
      if (mounted) setState(() => _isTyping = false);
      _scrollToBottom();
    }
  }
  void _onSelectWallet(String messageId, WalletModel wallet) {
    setState(() {
      final idx = _messages.indexWhere((m) => m.id == messageId);
      if (idx != -1) {
        _messages[idx] = _messages[idx].copyWith(
          selectedWalletId: wallet.id,
          content: "Bạn đã chọn ví **${wallet.name}**. Nhấn lưu để hoàn tất nhé! 👇",
        );
      }
    });
    _scrollToBottom();
  }
  Future<void> _handleSaveFromAI(ChatMessage msg) async {
    if (msg.amount == null || msg.selectedWalletId == null) return;

    setState(() => _isTyping = true); // Hiện loading giả trong lúc lưu

    try {
      final transactionStorage = TransactionStorage();
      await transactionStorage.saveTransaction(
        userId: widget.user.id,
        categoryId: msg.categoryId ?? '1', // Mặc định ăn uống nếu AI ko trả về
        walletId: msg.selectedWalletId!,
        amount: msg.amount!,
        type: TransactionType.expense,
        note: "${msg.note} (AI Chat)",
        date: DateTime.now(),
      );

      // Reload dữ liệu toàn app
      context.read<WalletBloc>().add(LoadWallets(widget.user.id));
      context.read<TransactionBloc>().add(RefreshTransactions(widget.user.id));

      // Ẩn Card sau khi lưu thành công và thông báo
      _replaceMessage(msg.id, "✅ Đã lưu thành công **${msg.amount}đ** vào ví của bạn!");
      _snack("Giao dịch đã được ghi lại! 🚀");

    } catch (e) {
      _snack("Lỗi lưu giao dịch: $e", color: Colors.red);
    } finally {
      setState(() => _isTyping = false);
    }
  }

  void _replaceMessage(String id, String content) {
    if (!mounted) return;
    setState(() {
      final idx = _messages.indexWhere((m) => m.id == id);
      if (idx != -1) {
        _messages[idx] = _messages[idx].copyWith(content: content, isLoading: false);
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }
  void _snack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp),
        ),
        backgroundColor: color ?? AppColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AIColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            FadeTransition(
              opacity: _headerAnim,
              child: AIHeader(
                isTyping:  _isTyping,
                pulseAnim: _pulseAnim,
                showClear: _messages.length > 1,
                onClear:   () => setState(() {
                  _messages.clear();
                  _addWelcomeMessage();
                }),
              ),
            ),
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState()
                  : _buildMessageList(),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: (!_inputFocused && _messages.length <= 1)
                  ? SuggestionChips(onTap: _sendMessage)
                  : const SizedBox.shrink(),
            ),
            InputBar(
              controller: _inputCtrl,
              focusNode:  _focusNode,
              isTyping:   _isTyping,
              isFocused:  _inputFocused,
              onSend:     _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('✦', style: TextStyle(fontSize: 52.sp, color: AIColors.gold)),
          SizedBox(height: 16.h),
          Text('Hỏi tôi bất cứ điều gì',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: AIColors.textPrimary)),
          SizedBox(height: 6.h),
          Text('về tài chính của bạn',
              style: TextStyle(fontSize: 14.sp, color: AIColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollCtrl,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      itemCount: _messages.length,
      itemBuilder: (_, i) {
        final msg      = _messages[i];
        final prev     = i > 0 ? _messages[i - 1] : null;
        final showTime = prev == null ||
            msg.timestamp.difference(prev.timestamp).inMinutes >= 5;
        return Column(
          children: [
            if (showTime) _buildTimestamp(msg.timestamp),
            MessageBubble(
                msg: msg,
                onSelectWallet: (wallet) => _onSelectWallet(msg.id, wallet),
                onSave: (message) => _handleSaveFromAI(message),
                showAvatar: prev == null || prev.role != msg.role),
          ],
        );
      },
    );
  }

  Widget _buildTimestamp(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Text('$h:$m',
          style: TextStyle(fontSize: 10.sp, color: AIColors.textSecondary.withOpacity(0.5))),
    );
  }
}