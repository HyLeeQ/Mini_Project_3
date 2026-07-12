import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../data/model/TransactionModel.dart';
import '../app_colors.dart';
import '../formatters/vnd_formatter.dart';

class AmountSection extends StatelessWidget {
  final TextEditingController controller;
  final TransactionType txType;

  const AmountSection({
    super.key,
    required this.controller,
    required this.txType,
  });

  Color get _txColor {
    switch (txType) {
      case TransactionType.income:   return AppColors.green;
      case TransactionType.expense:  return AppColors.red;
      case TransactionType.transfer: return AppColors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_txColor.withOpacity(0.08), _txColor.withOpacity(0.03)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: _txColor.withOpacity(0.25), width: 1.5.w),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Số tiền',
              style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
            ),
            SizedBox(height: 8.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.w800,
                    color: _txColor,
                    letterSpacing: -1,
                  ),
                  child: Text(txType == TransactionType.income ? '+' : '-'),
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      VndFormatter(),
                    ],
                    style: TextStyle(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -1,
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary.withOpacity(0.3),
                        letterSpacing: -1,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                Text(
                  '₫',
                  style: TextStyle(
                    fontSize: 20.sp,
                    color: _txColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              children: [50000, 100000, 200000, 500000].map((v) {
                return GestureDetector(
                  onTap: () => controller.text = VndFormatter.format(v),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: _txColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: _txColor.withOpacity(0.25), width: 1.w),
                    ),
                    child: Text(
                      v >= 1000 ? '${v ~/ 1000}K' : '$v',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: _txColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}