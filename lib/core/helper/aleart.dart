import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ── Màu sắc theo theme đen xám vàng ──
const _kBgColor      = Color(0xFF1E1E1E);   // nền dialog
const _kSurfaceColor = Color(0xFF2C2C2C);   // nền button row
const _kYellow       = Color(0xFFFFD600);   // primary / accent
const _kTextPrimary  = Color(0xFFF5F5F5);
const _kTextSecondary = Color(0xFF9E9E9E);

void displayMessageToUser(
    BuildContext context,
    String message, {
      bool isSuccess = true,
      VoidCallback? onOk,
    }) {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: _kBgColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSuccess ? _kYellow.withOpacity(0.4) : Colors.redAccent.withOpacity(0.4),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: (isSuccess ? _kYellow : Colors.redAccent).withOpacity(0.15),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon ──
            Container(
              width: 64.w,
              height: 64.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isSuccess ? _kYellow : Colors.redAccent).withOpacity(0.12),
              ),
              child: Icon(
                isSuccess ? Icons.check_rounded : Icons.warning_amber_rounded,
                color: isSuccess ? _kYellow : Colors.redAccent,
                size: 32.sp,
              ),
            ),

            SizedBox(height: 16.h),

            // ── Title ──
            Text(
              isSuccess ? 'Hoàn thành!' : 'Có lỗi xảy ra!',
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: _kTextPrimary,
                letterSpacing: 0.3,
              ),
            ),

            SizedBox(height: 8.h),

            // ── Message ──
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5.sp,
                color: _kTextSecondary,
                height: 1.5,
              ),
            ),

            SizedBox(height: 24.h),

            // ── Divider ──
            Divider(color: Colors.white.withOpacity(0.07), height: 1),

            // ── OK Button ──
            InkWell(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20.r)),
              onTap: () {
                Navigator.pop(context);
                onOk?.call();
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                alignment: Alignment.center,
                child: Text(
                  'OK',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: isSuccess ? _kYellow : Colors.redAccent,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}