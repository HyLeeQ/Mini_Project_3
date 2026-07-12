import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/settings_colors.dart';

class SettingsToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 46.w, height: 26.h,
        decoration: BoxDecoration(
          color: value ? SettingsColors.gold : SettingsColors.border,
          borderRadius: BorderRadius.circular(13.r),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.all(3.w),
            width: 20.w, height: 20.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}