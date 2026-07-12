import 'package:expense_tracker/features/page/HomePage/bloc/wallet_bloc/wallet_bloc.dart';
import 'package:expense_tracker/features/page/HomePage/bloc/wallet_bloc/wallet_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../data/model/ChatMessage.dart';
import '../../../../data/model/WalletModel.dart';
import '../constants/ai_colors.dart';
import 'typing_bubble.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage msg;
  final bool showAvatar;
  // --- Thêm 2 callback để gọi ngược về AIPage ---
  final Function(WalletModel)? onSelectWallet;
  final Function(ChatMessage)? onSave;

  const MessageBubble({
    super.key,
    required this.msg,
    required this.showAvatar,
    this.onSelectWallet,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == MessageRole.user;
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h), // Tăng padding một chút để thoáng
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _buildAIAvatar(showAvatar),
            SizedBox(width: 8.w),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                msg.isLoading
                    ? const TypingBubble()
                    : _buildTextBubble(isUser),

                // --- HIỂN THỊ ACTION CARD NẾU AI NHẬN DIỆN ĐƯỢC CHI TIÊU ---
                if (!isUser && msg.showActionCard && !msg.isLoading)
                  _buildActionCard(context),
              ],
            ),
          ),
          if (isUser) ...[
            SizedBox(width: 8.w),
            _buildUserAvatar(showAvatar),
          ],
        ],
      ),
    );
  }

  // Widget hiển thị khung chọn ví và nút lưu
  Widget _buildActionCard(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 8.h, left: 4.w),
      padding: EdgeInsets.all(12.w),
      constraints: BoxConstraints(maxWidth: 250.w),
      decoration: BoxDecoration(
        color: AIColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AIColors.gold.withOpacity(0.3), width: 1.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('💰', style: TextStyle(fontSize: 14.sp)),
              SizedBox(width: 6.w),
              Text(
                'Xác nhận chi tiêu',
                style: TextStyle(
                  color: AIColors.gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
          Divider(color: AIColors.gold.withOpacity(0.1), height: 16.h),

          // 1. NẾU CHƯA CHỌN VÍ: Hiện các nút chọn ví
          if (msg.selectedWalletId == null) ...[
            Text(
              'Bạn đã thanh toán bằng ví nào?',
              style: TextStyle(color: AIColors.textSecondary, fontSize: 11.sp),
            ),
            SizedBox(height: 10.h),
            BlocBuilder<WalletBloc, WalletState>(
              builder: (context, state) {
                if (state is WalletLoaded) {
                  return Wrap(
                    spacing: 6.w,
                    runSpacing: 6.h,
                    children: state.wallets.map((wallet) {
                      return InkWell(
                        onTap: () => onSelectWallet?.call(wallet),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: AIColors.card,
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(color: AIColors.gold.withOpacity(0.2)),
                          ),
                          child: Text(
                            wallet.name,
                            style: TextStyle(color: Colors.white, fontSize: 11.sp),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ]

          // 2. NẾU ĐÃ CHỌN VÍ: Hiện nút xác nhận lưu
          else ...[
            SizedBox(
              width: double.infinity,
              height: 40.h,
              child: ElevatedButton(
                onPressed: () => onSave?.call(msg),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.withOpacity(0.8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 16.sp, color: Colors.white),
                    SizedBox(width: 8.w),
                    Text(
                      'Xác nhận Lưu',
                      style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- Các Widget Avatar và Text cũ của Lân giữ nguyên bên dưới ---
  Widget _buildAIAvatar(bool show) {
    if (!show) return SizedBox(width: 28.w);
    return Container(
      width: 28.w, height: 28.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AIColors.surface,
        border: Border.all(color: AIColors.gold.withOpacity(0.35), width: 1.w),
      ),
      child: Center(
        child: Text('✦', style: TextStyle(fontSize: 12.sp, color: AIColors.gold)),
      ),
    );
  }

  Widget _buildUserAvatar(bool show) {
    if (!show) return SizedBox(width: 28.w);
    return Container(
      width: 28.w, height: 28.w,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AIColors.goldDeep, AIColors.gold],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text('Bạn',
            style: TextStyle(
              fontSize: 7.sp, fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1200),
            )),
      ),
    );
  }

  Widget _buildTextBubble(bool isUser) {
    return Container(
      constraints: BoxConstraints(maxWidth: 265.w),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isUser ? AIColors.gold.withOpacity(0.13) : AIColors.aiBubble,
        borderRadius: BorderRadius.only(
          topLeft:     Radius.circular(isUser ? 18.r : 4.r),
          topRight:    Radius.circular(isUser ? 4.r : 18.r),
          bottomLeft:  Radius.circular(18.r),
          bottomRight: Radius.circular(18.r),
        ),
        border: Border.all(
          color: isUser ? AIColors.gold.withOpacity(0.25) : AIColors.border,
          width: 1.w,
        ),
      ),
      child: _MarkdownText(text: msg.content, isUser: isUser),
    );
  }
}

// ── Internal markdown widget (Giữ nguyên của Lân) ──────────────────
class _MarkdownText extends StatelessWidget {
  final String text;
  final bool   isUser;

  const _MarkdownText({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty) {
        if (widgets.isNotEmpty) widgets.add(SizedBox(height: 4.h));
        continue;
      }
      widgets.add(_parseLine(line));
      if (i < lines.length - 1) widgets.add(SizedBox(height: 2.h));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }

  Widget _parseLine(String line) {
    final regex = RegExp(r'\*\*(.+?)\*\*');
    final spans = <InlineSpan>[];
    int last = 0;

    for (final m in regex.allMatches(line)) {
      if (m.start > last) spans.add(TextSpan(text: line.substring(last, m.start)));
      spans.add(TextSpan(
        text:  m.group(1),
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: isUser ? AIColors.goldLight : AIColors.gold,
        ),
      ));
      last = m.end;
    }
    if (last < line.length) spans.add(TextSpan(text: line.substring(last)));

    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 14.sp, color: AIColors.textPrimary, height: 1.45),
        children: spans,
      ),
    );
  }
}