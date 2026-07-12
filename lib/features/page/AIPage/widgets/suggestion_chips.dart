import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/ai_colors.dart';
import '../constants/ai_suggestions.dart';

class SuggestionChips extends StatelessWidget {
  final void Function(String) onTap;

  const SuggestionChips({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('suggestions'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 8.h),
          child: Row(
            children: [
              Container(
                width: 4.w, height: 4.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AIColors.gold.withOpacity(0.7),
                ),
              ),
              SizedBox(width: 6.w),
              Text('Gợi ý câu hỏi',
                  style: TextStyle(
                    fontSize: 12.sp, color: AIColors.textSecondary,
                    fontWeight: FontWeight.w500, letterSpacing: 0.2,
                  )),
            ],
          ),
        ),
        SizedBox(
          height: 82.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: kAISuggestions.length,
            itemBuilder: (_, i) => _buildChip(kAISuggestions[i]),
          ),
        ),
        SizedBox(height: 8.h),
      ],
    );
  }

  Widget _buildChip(AISuggestion s) {
    return GestureDetector(
      onTap: () => onTap(s.text),
      child: Container(
        margin: EdgeInsets.only(right: 10.w),
        width:  155.w,
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: AIColors.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AIColors.border, width: 1.w),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.emoji, style: TextStyle(fontSize: 12.sp)),
            SizedBox(height: 5.h),
            Text(s.text,
                style: TextStyle(fontSize: 10.sp, color: AIColors.textSecondary, height: 1.35),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}