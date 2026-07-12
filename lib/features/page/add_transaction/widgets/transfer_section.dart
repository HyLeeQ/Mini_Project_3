import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../data/model/WalletModel.dart';
import '../app_colors.dart';

class TransferSection extends StatelessWidget {
  final List<WalletModel> wallets;
  final WalletModel? fromWallet;
  final WalletModel? toWallet;
  final String amountText;
  final ValueChanged<WalletModel> onFromChanged;
  final ValueChanged<WalletModel> onToChanged;
  final VoidCallback onSwap;

  const TransferSection({
    super.key,
    required this.wallets,
    required this.fromWallet,
    required this.toWallet,
    required this.amountText,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onSwap,
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
    final sameWallet = fromWallet != null &&
        toWallet != null &&
        fromWallet!.id == toWallet!.id;
    final showSummary = fromWallet != null &&
        toWallet != null &&
        !sameWallet &&
        amountText.isNotEmpty;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Chuyển tiền'),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: AppColors.border, width: 1.w),
            ),
            child: Column(
              children: [
                _walletRow(
                  label: 'Từ ví',
                  selected: fromWallet,
                  other: toWallet,
                  onTap: (w) {
                    onFromChanged(w);
                    // auto-swap nếu trùng — xử lý ở parent
                  },
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Row(
                    children: [
                      Expanded(child: _divider()),
                      SizedBox(width: 12.w),
                      GestureDetector(
                        onTap: onSwap,
                        child: Container(
                          width: 40.w,
                          height: 40.w,
                          decoration: BoxDecoration(
                            color: AppColors.blue.withOpacity(0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.blue.withOpacity(0.35),
                                width: 1.5.w),
                          ),
                          child: Center(
                            child: Icon(Icons.swap_vert_rounded,
                                color: AppColors.blue, size: 20.sp),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(child: _divider()),
                    ],
                  ),
                ),
                _walletRow(
                  label: 'Đến ví',
                  selected: toWallet,
                  other: fromWallet,
                  onTap: (w) => onToChanged(w),
                ),
              ],
            ),
          ),

          // Warning: cùng ví
          if (sameWallet) ...[
            SizedBox(height: 10.h),
            Container(
              padding:
              EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                    color: AppColors.red.withOpacity(0.25), width: 1.w),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppColors.red, size: 15.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'Ví nguồn và ví đích không được trùng nhau',
                    style:
                    TextStyle(fontSize: 11.sp, color: AppColors.red),
                  ),
                ],
              ),
            ),
          ],

          // Summary
          if (showSummary) ...[
            SizedBox(height: 10.h),
            Container(
              padding:
              EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.blue.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                    color: AppColors.blue.withOpacity(0.2), width: 1.w),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: AppColors.blue, size: 14.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.textSecondary),
                        children: [
                          const TextSpan(text: 'Chuyển '),
                          TextSpan(
                            text: '$amountText ₫ ',
                            style: TextStyle(
                                color: AppColors.blue,
                                fontWeight: FontWeight.w600),
                          ),
                          const TextSpan(text: 'từ '),
                          TextSpan(
                            text:
                            '${fromWallet!.icon} ${fromWallet!.name} ',
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500),
                          ),
                          const TextSpan(text: '→ '),
                          TextSpan(
                            text: '${toWallet!.icon} ${toWallet!.name}',
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _walletRow({
    required String label,
    required WalletModel? selected,
    required WalletModel? other,
    required ValueChanged<WalletModel> onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11.sp, color: AppColors.textSecondary)),
        SizedBox(height: 8.h),
        SizedBox(
          height: 60.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: wallets.length,
            itemBuilder: (_, i) {
              final w = wallets[i];
              final isSelected = selected?.id == w.id;
              final isOther = other?.id == w.id;
              final color = _parseColor(w.colorHex);
              return GestureDetector(
                onTap: () => onTap(w),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: isOther ? 0.35 : 1.0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: EdgeInsets.only(right: 10.w),
                    padding: EdgeInsets.symmetric(
                        horizontal: 14.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withOpacity(0.14)
                          : AppColors.card,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: isSelected
                            ? color.withOpacity(0.55)
                            : AppColors.border,
                        width: isSelected ? 1.5.w : 1.w,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(w.icon, style: TextStyle(fontSize: 18.sp)),
                        SizedBox(width: 8.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              w.name,
                              style: TextStyle(
                                fontSize: 12.sp,
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
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _divider() => Container(
    height: 1,
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(
            color: AppColors.border,
            width: 1,
            style: BorderStyle.solid),
      ),
    ),
  );

  Widget _sectionLabel(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 13.sp,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
      letterSpacing: 0.3,
    ),
  );
}