import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../data/model/UserModel.dart';
import '../constants/settings_colors.dart';

class ProfileCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEditAvatar;
  final VoidCallback onEditProfile;

  const ProfileCard({
    super.key,
    required this.user,
    required this.onEditAvatar,
    required this.onEditProfile,
  });

  String _initials(String name) {
    final p = name.trim().split(' ');
    if (p.length >= 2) return '${p.first[0]}${p.last[0]}'.toUpperCase();
    return p.first[0].toUpperCase();
  }

  String _memberSince(DateTime dt) =>
      'Thành viên từ tháng ${dt.month}/${dt.year}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1C1A10), Color(0xFF12100A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
              color: SettingsColors.gold.withOpacity(0.25), width: 1.5.w),
        ),
        child: Stack(
          children: [
            // Background orb
            Positioned(
              top: -20.h, right: -20.w,
              child: Container(
                width: 120.w, height: 120.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    SettingsColors.gold.withOpacity(0.10),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),
            Row(
              children: [
                _buildAvatar(),
                SizedBox(width: 16.w),
                _buildInfo(),
                _buildEditArrow(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        Container(
          width: 64.w, height: 64.w,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [SettingsColors.goldDeep, SettingsColors.gold, SettingsColors.goldLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Text(
              _initials(user.name),
              style: TextStyle(
                fontSize: 22.sp, fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1200),
              ),
            ),
          ),
        ),
        Positioned(
          right: 0, bottom: 0,
          child: GestureDetector(
            onTap: onEditAvatar,
            child: Container(
              width: 22.w, height: 22.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SettingsColors.surface,
                border: Border.all(
                    color: SettingsColors.gold.withOpacity(0.5), width: 1.5.w),
              ),
              child: Icon(Icons.edit_rounded,
                  color: SettingsColors.gold, size: 11.sp),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfo() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user.name,
              style: TextStyle(
                fontSize: 17.sp, fontWeight: FontWeight.w700,
                color: SettingsColors.textPrimary, letterSpacing: -0.3,
              )),
          SizedBox(height: 3.h),
          Text(user.email,
              style: TextStyle(fontSize: 12.sp, color: SettingsColors.textSecondary),
              overflow: TextOverflow.ellipsis),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: SettingsColors.gold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(
                  color: SettingsColors.gold.withOpacity(0.25), width: 1.w),
            ),
            child: Text(
              _memberSince(user.createdAt),
              style: TextStyle(
                fontSize: 10.sp, color: SettingsColors.gold,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditArrow() {
    return GestureDetector(
      onTap: onEditProfile,
      child: Container(
        width: 36.w, height: 36.w,
        decoration: BoxDecoration(
          color: SettingsColors.gold.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
              color: SettingsColors.gold.withOpacity(0.25), width: 1.w),
        ),
        child: Icon(Icons.arrow_forward_ios_rounded,
            color: SettingsColors.gold, size: 14.sp),
      ),
    );
  }
}