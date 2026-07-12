import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/settings_colors.dart';

class LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const LogoutButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 54.h,
          decoration: BoxDecoration(
            color: SettingsColors.red.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
                color: SettingsColors.red.withOpacity(0.3), width: 1.w),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: SettingsColors.red, size: 20.sp),
              SizedBox(width: 10.w),
              Text('Đăng xuất',
                  style: TextStyle(
                    fontSize: 15.sp, fontWeight: FontWeight.w700,
                    color: SettingsColors.red,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class DeleteAccountButton extends StatelessWidget {
  final VoidCallback onTap;
  const DeleteAccountButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: GestureDetector(
        onTap: onTap,
        child: Center(
          child: Text(
            'Xoá tài khoản',
            style: TextStyle(
              fontSize: 13.sp,
              color: SettingsColors.textSecondary.withOpacity(0.5),
              decoration: TextDecoration.underline,
              decorationColor: SettingsColors.textSecondary.withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }
}