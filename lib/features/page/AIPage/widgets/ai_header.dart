import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/ai_colors.dart';

class AIHeader extends StatelessWidget {
  final bool isTyping;
  final Animation<double> pulseAnim;
  final VoidCallback onClear;
  final bool showClear;

  const AIHeader({
    super.key,
    required this.isTyping,
    required this.pulseAnim,
    required this.onClear,
    required this.showClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 14.h),
      decoration: BoxDecoration(
        color: AIColors.bg,
        border: Border(bottom: BorderSide(color: AIColors.border, width: 1.h)),
      ),
      child: Row(
        children: [
          _buildAvatar(),
          SizedBox(width: 12.w),
          _buildNameStatus(),
          if (showClear) _buildClearButton(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return AnimatedBuilder(
      animation: pulseAnim,
      builder: (_, child) => Transform.scale(scale: pulseAnim.value, child: child),
      child: Stack(
        children: [
          Container(
            width: 46.w, height: 46.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                AIColors.gold.withOpacity(0.2),
                Colors.transparent,
              ]),
            ),
          ),
          Container(
            width: 46.w, height: 46.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AIColors.surface,
              border: Border.all(color: AIColors.gold.withOpacity(0.5), width: 1.5.w),
            ),
            child: Center(
              child: ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [AIColors.goldDeep, AIColors.goldLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(b),
                child: Text('✦', style: TextStyle(fontSize: 22.sp, color: Colors.white)),
              ),
            ),
          ),
          Positioned(
            right: 0, bottom: 0,
            child: Container(
              width: 12.w, height: 12.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2ECC8A),
                border: Border.all(color: AIColors.bg, width: 2.w),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameStatus() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('DoctorĐồng AI',
                  style: TextStyle(
                    fontSize: 16.sp, fontWeight: FontWeight.w700,
                    color: AIColors.textPrimary, letterSpacing: -0.3,
                  )),
              SizedBox(width: 6.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AIColors.gold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(5.r),
                  border: Border.all(color: AIColors.gold.withOpacity(0.3), width: 1.w),
                ),
                child: Text('AI',
                    style: TextStyle(
                      fontSize: 9.sp, color: AIColors.gold,
                      fontWeight: FontWeight.w800, letterSpacing: 0.5,
                    )),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Container(
                width: 6.w, height: 6.w,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0xFF2ECC8A),
                ),
              ),
              SizedBox(width: 5.w),
              Text(
                isTyping ? 'Đang soạn...' : 'Trợ lý tài chính thông minh',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: isTyping ? AIColors.gold : AIColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClearButton() {
    return GestureDetector(
      onTap: onClear,
      child: Container(
        width: 36.w, height: 36.w,
        decoration: BoxDecoration(
          color: AIColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AIColors.border, width: 1.w),
        ),
        child: Icon(Icons.refresh_rounded, color: AIColors.textSecondary, size: 17.sp),
      ),
    );
  }
}