import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/ai_colors.dart';

class TypingBubble extends StatefulWidget {
  const TypingBubble({super.key});

  @override
  State<TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70.w,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AIColors.aiBubble,
        borderRadius: BorderRadius.only(
          topLeft:     Radius.circular(4.r),
          topRight:    Radius.circular(18.r),
          bottomLeft:  Radius.circular(18.r),
          bottomRight: Radius.circular(18.r),
        ),
        border: Border.all(color: AIColors.border, width: 1.w),
      ),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t  = (_ctrl.value + i * 0.33) % 1.0;
            final op = (t < 0.5 ? 0.3 + t * 1.4 : 1.0 - (t - 0.5) * 1.4).clamp(0.2, 1.0);
            final sc = (t < 0.5 ? 0.7 + t * 0.6 : 1.3 - (t - 0.5) * 0.6).clamp(0.7, 1.3);
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.w),
              child: Transform.scale(
                scale: sc,
                child: Container(
                  width: 7.w, height: 7.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AIColors.gold.withOpacity(op),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}