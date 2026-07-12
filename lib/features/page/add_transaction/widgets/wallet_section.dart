import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../data/model/WalletModel.dart';
import '../app_colors.dart';

class WalletSection extends StatelessWidget {
  final List<WalletModel> wallets;
  final WalletModel? selectedWallet;
  final ValueChanged<WalletModel> onSelected;

  const WalletSection({
    super.key,
    required this.wallets,
    required this.selectedWallet,
    required this.onSelected,
  });

  String _fmtMoney(double amount) {
    final str = amount
        .abs()
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
    return '$str ₫';
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ví thanh toán',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: 10.h),
          SizedBox(
            height: 72.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: wallets.length,
              itemBuilder: (_, i) {
                final w = wallets[i];
                final isSelected = selectedWallet?.id == w.id;
                final color = _parseColor(w.colorHex);
                return GestureDetector(
                  onTap: () => onSelected(w),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: EdgeInsets.only(right: 10.w),
                    padding: EdgeInsets.symmetric(
                        horizontal: 14.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withOpacity(0.12)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: isSelected
                            ? color.withOpacity(0.5)
                            : AppColors.border,
                        width: isSelected ? 1.5.w : 1.w,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(w.icon, style: TextStyle(fontSize: 20.sp)),
                        SizedBox(width: 10.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              w.name,
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              _fmtMoney(w.balance),
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: isSelected
                                    ? color
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}