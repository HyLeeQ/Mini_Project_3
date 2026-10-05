import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../app_colors.dart';
import '../painters/scanner_painters.dart';

class AIScannerButton extends StatelessWidget {
  final bool isOpen;
  final Animation<double> pulseAnim;
  final VoidCallback onTap;

  const AIScannerButton({
    super.key,
    required this.isOpen,
    required this.pulseAnim,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedBuilder(
          animation: pulseAnim,
          builder: (_, child) => Transform.scale(
            scale: isOpen ? 1.0 : pulseAnim.value,
            child: child,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 54.h,
            decoration: BoxDecoration(
              gradient: isOpen
                  ? LinearGradient(
                      colors: [
                        AppColors.gold.withOpacity(0.2),
                        AppColors.goldDeep.withOpacity(0.15),
                      ],
                    )
                  : LinearGradient(colors: [AppColors.surface, AppColors.card]),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isOpen
                    ? AppColors.gold.withOpacity(0.5)
                    : AppColors.gold.withOpacity(0.3),
                width: isOpen ? 1.5.w : 1.w,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.gold.withOpacity(0.25),
                        AppColors.gold.withOpacity(0.05),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text('✨', style: TextStyle(fontSize: 16.sp)),
                  ),
                ),
                SizedBox(width: 10.w),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOpen ? 'Đóng AI Scanner' : 'Dùng AI nhận diện',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gold,
                      ),
                    ),
                    Text(
                      'Chụp hoá đơn để tự động điền',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: isOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.gold,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 16.w),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AIScannerPanel extends StatelessWidget {
  final bool isScanning;
  final Animation<double> scanAnim;
  final VoidCallback? onCapture;
  final VoidCallback? onPickImage;
  final CameraController? controller; // Thêm controller để nhận dữ liệu camera
  final File? previewImage;
  final XFile? capturedImage;
  final String? cameraError;
  final Offset? focusPoint;
  final bool flashEnabled;
  final VoidCallback? onFlashToggle;
  final void Function(TapDownDetails details, Size size)? onFocus;
  final VoidCallback? onRetake;
  final VoidCallback? onUsePhoto;

  const AIScannerPanel({
    super.key,
    required this.isScanning,
    required this.scanAnim,
    required this.onCapture,
    required this.onPickImage,
    this.controller, // Khai báo trong constructor
    this.previewImage,
    this.capturedImage,
    this.cameraError,
    this.focusPoint,
    this.flashEnabled = false,
    this.onFlashToggle,
    this.onFocus,
    this.onRetake,
    this.onUsePhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: AppColors.gold.withOpacity(0.2),
            width: 1.w,
          ),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              child: Container(
                height: 200.h,
                width: double.infinity,
                color: const Color(0xFF080808),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (capturedImage != null)
                      Image.file(File(capturedImage!.path), fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                    else if (previewImage != null)
                    // Ưu tiên hiển thị ảnh đã chụp/chọn
                      Image.file(
                        previewImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    else if (controller != null && controller!.value.isInitialized)
                    // Nếu không có ảnh preview mới hiển thị Camera live
                      Center(
                        child: AspectRatio(
                          aspectRatio: controller!.value.aspectRatio,
                          child: CameraPreview(controller!),
                        ),
                      )
                    else if (cameraError != null)
                      Center(child: Padding(padding: EdgeInsets.all(16.w), child: Text(cameraError!, textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 12.sp))))
                    else
                      const Center(
                        child: CircularProgressIndicator(color: AppColors.gold),
                      ),

                    // 2. LỚP PAINTER (Kính ngắm & các góc trang trí)
                    CustomPaint(painter: ViewfinderPainter()),
                    Positioned(
                      top: 20.h,
                      left: 20.w,
                      child: _corner(false, false),
                    ),
                    Positioned(
                      top: 20.h,
                      right: 20.w,
                      child: _corner(false, true),
                    ),
                    Positioned(
                      bottom: 20.h,
                      left: 20.w,
                      child: _corner(true, false),
                    ),
                    Positioned(
                      bottom: 20.h,
                      right: 20.w,
                      child: _corner(true, true),
                    ),

                    // 3. HIỆU ỨNG QUÉT KHI ĐANG SCAN
                    if (isScanning)
                      AnimatedBuilder(
                        animation: scanAnim,
                        builder: (_, __) => Positioned(
                          top: scanAnim.value * 160.h + 20.h,
                          left: 20.w,
                          right: 20.w,
                          child: Container(
                            height: 2.h,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  AppColors.gold.withOpacity(0.8),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (capturedImage == null && controller != null && controller!.value.isInitialized && !isScanning)
                      Positioned.fill(child: LayoutBuilder(builder: (context, constraints) => GestureDetector(behavior: HitTestBehavior.opaque, onTapDown: (details) => onFocus?.call(details, constraints.biggest), child: const SizedBox.expand()))),
                    if (capturedImage == null && controller != null && controller!.value.isInitialized)
                      Positioned(top: 10.h, right: 10.w, child: IconButton.filledTonal(onPressed: onFlashToggle, icon: Icon(flashEnabled ? Icons.flash_on : Icons.flash_off), tooltip: 'Bật/tắt flash')),
                    if (capturedImage == null && focusPoint != null)
                      Positioned(
                        left: focusPoint!.dx * (MediaQuery.sizeOf(context).width - 40.w) - 18.w,
                        top: focusPoint!.dy * 200.h - 18.h,
                        child: IgnorePointer(child: Container(
                          width: 36.w,
                          height: 36.w,
                          decoration: BoxDecoration(border: Border.all(color: AppColors.gold, width: 2), borderRadius: BorderRadius.circular(6.r)),
                        )),
                      ),

                    // 4. HƯỚNG DẪN KHI CHƯA SCAN & CAMERA CHƯA SẴN SÀNG
                    if (!isScanning &&
                        (controller == null ||
                            !controller!.value.isInitialized))
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 56.w,
                              height: 56.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.gold.withOpacity(0.1),
                                border: Border.all(
                                  color: AppColors.gold.withOpacity(0.3),
                                  width: 1.w,
                                ),
                              ),
                              child: Icon(
                                Icons.camera_alt_outlined,
                                color: AppColors.gold,
                                size: 24.sp,
                              ),
                            ),
                            SizedBox(height: 10.h),
                            Text(
                              'Đang khởi động camera...',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // 5. TRẠNG THÁI AI ĐANG XỬ LÝ
                    if (isScanning)
                      Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 14.w,
                                height: 14.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.gold,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'AI đang nhận diện...',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // --- CÁC NÚT HÀNH ĐỘNG ---
            if (capturedImage != null)
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
                child: Row(children: [
                  Expanded(child: _actionBtn(icon: Icons.refresh, label: 'Chụp lại', color: AppColors.blue, onTap: onRetake)),
                  SizedBox(width: 12.w),
                  Expanded(child: _actionBtn(icon: Icons.check, label: 'Dùng ảnh này', color: AppColors.gold, onTap: onUsePhoto)),
                ]),
              ),
            if (capturedImage == null) Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  Expanded(
                    child: _actionBtn(
                      icon: Icons.camera_alt_rounded,
                      label: 'Chụp hoá đơn',
                      color: AppColors.gold,
                      onTap: isScanning ? null : onCapture,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _actionBtn(
                      icon: Icons.photo_library_outlined,
                      label: 'Chọn ảnh',
                      color: AppColors.blue,
                      onTap: isScanning ? null : onPickImage,
                    ),
                  ),
                ],
              ),
            ),

            // --- GỢI Ý ---
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              child: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.gold.withOpacity(0.15),
                    width: 1.w,
                  ),
                ),
                child: Row(
                  children: [
                    Text('💡', style: TextStyle(fontSize: 14.sp)),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'AI có thể nhận diện: số tiền, tên cửa hàng, ngày giao dịch từ hoá đơn',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _corner(bool bottom, bool right) => CustomPaint(
    size: Size(20.w, 20.w),
    painter: CornerPainter(bottom: bottom, right: right, color: AppColors.gold),
  );

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.4 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: 46.h,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: color.withOpacity(0.3), width: 1.w),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18.sp),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
