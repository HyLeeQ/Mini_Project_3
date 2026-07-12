import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/settings_colors.dart';
import '../models/setting_item.dart';

class SettingsSection extends StatelessWidget {
  final String title;
  final List<SettingItem> items;

  const SettingsSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 4.w, bottom: 10.h),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13.sp, fontWeight: FontWeight.w600,
                color: SettingsColors.textSecondary, letterSpacing: 0.2,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: SettingsColors.card,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: SettingsColors.border, width: 1.w),
            ),
            child: Column(
              children: List.generate(items.length, (i) => Column(
                children: [
                  _SettingRow(item: items[i]),
                  if (i < items.length - 1)
                    Divider(
                      height: 1, indent: 56.w,
                      color: SettingsColors.border.withOpacity(0.6),
                    ),
                ],
              )),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final SettingItem item;
  const _SettingRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(
          children: [
            Container(
              width: 36.w, height: 36.w,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(item.icon, color: item.color, size: 18.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.label,
                      style: TextStyle(
                        fontSize: 14.sp, fontWeight: FontWeight.w600,
                        color: SettingsColors.textPrimary,
                      )),
                  if (item.subtitle != null) ...[
                    SizedBox(height: 2.h),
                    Text(item.subtitle!,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: SettingsColors.textSecondary,
                        )),
                  ],
                ],
              ),
            ),
            item.trailing ??
                (item.onTap != null
                    ? Icon(Icons.chevron_right_rounded,
                    color: SettingsColors.textSecondary.withOpacity(0.4),
                    size: 18.sp)
                    : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}