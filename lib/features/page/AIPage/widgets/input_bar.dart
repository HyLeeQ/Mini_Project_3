import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/ai_colors.dart';

class InputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isTyping;
  final bool isFocused;
  final void Function(String) onSend;

  const InputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isTyping,
    required this.isFocused,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AIColors.bg,
        border: Border(
          top: BorderSide(
            color: isFocused ? AIColors.gold.withOpacity(0.2) : AIColors.border,
            width: 1.h,
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 14.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: _buildTextField()),
          SizedBox(width: 10.w),
          _buildSendButton(),
        ],
      ),
    );
  }

  Widget _buildTextField() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      constraints: BoxConstraints(maxHeight: 130.h),
      decoration: BoxDecoration(
        color: AIColors.surface,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(
          color: isFocused ? AIColors.gold.withOpacity(0.45) : AIColors.border,
          width: isFocused ? 1.5.w : 1.w,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(width: 16.w),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              maxLines: 5,
              minLines: 1,
              style: TextStyle(fontSize: 14.sp, color: AIColors.textPrimary, height: 1.4),
              decoration: InputDecoration(
                hintText: 'Hỏi về tài chính của bạn...',
                hintStyle: TextStyle(
                  fontSize: 14.sp,
                  color: AIColors.textSecondary.withOpacity(0.45),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 11.h),
              ),
              onSubmitted: (v) {
                if (v.trim().isNotEmpty && !isTyping) onSend(v);
              },
              textInputAction: TextInputAction.send,
            ),
          ),
          SizedBox(width: 12.w),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    return ListenableBuilder(
      listenable: controller,
      builder: (_, __) {
        final hasText = controller.text.trim().isNotEmpty;
        return GestureDetector(
          onTap: hasText && !isTyping ? () => onSend(controller.text) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 46.w, height: 46.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasText && !isTyping ? AIColors.gold : AIColors.surface,
              border: Border.all(
                color: hasText && !isTyping ? AIColors.gold : AIColors.border,
                width: 1.w,
              ),
            ),
            child: isTyping
                ? Padding(
              padding: EdgeInsets.all(13.w),
              child: CircularProgressIndicator(
                strokeWidth: 2, color: AIColors.textSecondary,
              ),
            )
                : Icon(
              Icons.arrow_upward_rounded,
              color: hasText ? const Color(0xFF1A1200) : AIColors.textSecondary,
              size: 20.sp,
            ),
          ),
        );
      },
    );
  }
}