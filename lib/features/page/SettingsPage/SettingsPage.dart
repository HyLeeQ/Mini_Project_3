import 'package:expense_tracker/data/firebase/AuthFirestore.dart';
import 'package:expense_tracker/features/page/HomePage/bloc/wallet_bloc/wallet_bloc.dart';
import 'package:expense_tracker/features/page/HomePage/bloc/wallet_bloc/wallet_state.dart';
import 'package:expense_tracker/features/page/SettingsPage/pages/ManageWalletsScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../data/model/UserModel.dart';
import '../../auth/screens/LoginScreen.dart';
import 'constants/settings_colors.dart';
import 'models/setting_item.dart';
import 'widgets/danger_buttons.dart';
import 'widgets/profile_card.dart';
import 'widgets/settings_section.dart';
import 'widgets/settings_toggle.dart';

class SettingsPage extends StatefulWidget {
  final UserModel user;
  const SettingsPage({super.key, required this.user});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fadeAnim;

  bool _notifTransaction = true;
  bool _notifBudget      = true;
  bool _notifReport      = false;
  bool _biometric        = false;
  bool _hideBalance      = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _fadeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────────
  Future<void> _logout() async {
    final confirmed = await _showConfirmDialog(
      title:        'Đăng xuất',
      message:      'Bạn có chắc muốn đăng xuất khỏi tài khoản không?',
      confirmText:  'Đăng xuất',
      confirmColor: SettingsColors.red,
    );
    if (!confirmed) return;
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    AuthFireStore.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
    );
  }

  Future<void> _deleteAccount() async {
    final confirmed = await _showConfirmDialog(
      title:        'Xoá tài khoản',
      message:      'Hành động này không thể hoàn tác. Tất cả dữ liệu sẽ bị xoá vĩnh viễn.',
      confirmText:  'Xoá tài khoản',
      confirmColor: SettingsColors.red,
    );
    if (!confirmed) return;
    // TODO: xoá account từ Firebase
  }

  Future<bool> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color  confirmColor,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: SettingsColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56.w, height: 56.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: confirmColor.withOpacity(0.12),
                ),
                child: Icon(Icons.warning_amber_rounded,
                    color: confirmColor, size: 28.sp),
              ),
              SizedBox(height: 16.h),
              Text(title,
                  style: TextStyle(
                    fontSize: 18.sp, fontWeight: FontWeight.w700,
                    color: SettingsColors.textPrimary,
                  )),
              SizedBox(height: 8.h),
              Text(message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.sp, color: SettingsColors.textSecondary,
                    height: 1.5,
                  )),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SettingsColors.textSecondary,
                        side: BorderSide(color: SettingsColors.border, width: 1.w),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r)),
                        padding: EdgeInsets.symmetric(vertical: 13.h),
                      ),
                      child: Text('Huỷ', style: TextStyle(fontSize: 14.sp)),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r)),
                        padding: EdgeInsets.symmetric(vertical: 13.h),
                      ),
                      child: Text(confirmText,
                          style: TextStyle(
                            fontSize: 14.sp, fontWeight: FontWeight.w700,
                          )),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ) ?? false;
  }

  void _showSnack(String msg, {Color color = SettingsColors.green}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: TextStyle(color: SettingsColors.textPrimary, fontSize: 13.sp)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SettingsColors.bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: SizedBox(height: 20.h)),
              SliverToBoxAdapter(
                child: ProfileCard(
                  user:          widget.user,
                  onEditAvatar:  () => _showSnack('Tính năng đang phát triển'),
                  onEditProfile: () {},
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 24.h)),
              SliverToBoxAdapter(
                  child: SettingsSection(
                title: '💳  Tài khoản & Ví',
                items: [
                  SettingItem(
                    icon: Icons.account_balance_wallet_rounded,
                    color: SettingsColors.gold,
                    label: 'Quản lý ví',
                    subtitle: context.watch<WalletBloc>().state is WalletLoaded
                                ? '${(context.watch<WalletBloc>().state as WalletLoaded).wallets.length} ví đang hoạt động'
                                : '...',
                    onTap: () {
                      Navigator.push(context, PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => const ManageWalletsScreen(userId: '12321312',),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          const begin = Offset(1.0, 0.0);  // Bắt đầu bên phải màn hình
                          const end = Offset.zero;          // Kết thúc ở vị trí hiện tại
                          final tween = Tween(begin: begin, end: end);
                          final curvedAnimation = CurvedAnimation(parent: animation, curve: Curves.ease);

                          return SlideTransition(
                            position: tween.animate(curvedAnimation),
                            child: child,
                          );
                        },
                        transitionDuration: const Duration(milliseconds: 1000),  // thời gian chuyển cảnh
                      ));

                    },
                  ),
                  SettingItem(
                    icon: Icons.category_rounded,
                    color: SettingsColors.purple,
                    label: 'Danh mục chi tiêu',
                    subtitle: 'Tuỳ chỉnh danh mục',
                    onTap: () {},
                  ),
                  SettingItem(
                    icon: Icons.savings_rounded,
                    color: SettingsColors.green,
                    label: 'Ngân sách',
                    subtitle: 'Thiết lập hạn mức chi tiêu',
                    onTap: () {},
                  ),
                ],
              )),
              SliverToBoxAdapter(child: SizedBox(height: 16.h)),
              SliverToBoxAdapter(child: SettingsSection(
                title: '🔔  Thông báo',
                items: [
                  SettingItem(
                    icon: Icons.receipt_long_rounded,
                    color: SettingsColors.blue,
                    label: 'Giao dịch mới',
                    subtitle: 'Thông báo khi có giao dịch',
                    trailing: SettingsToggle(
                      value: _notifTransaction,
                      onChanged: (v) => setState(() => _notifTransaction = v),
                    ),
                  ),
                  SettingItem(
                    icon: Icons.pie_chart_rounded,
                    color: SettingsColors.red,
                    label: 'Cảnh báo ngân sách',
                    subtitle: 'Khi chi tiêu vượt hạn mức',
                    trailing: SettingsToggle(
                      value: _notifBudget,
                      onChanged: (v) => setState(() => _notifBudget = v),
                    ),
                  ),
                  SettingItem(
                    icon: Icons.bar_chart_rounded,
                    color: SettingsColors.gold,
                    label: 'Báo cáo định kỳ',
                    subtitle: 'Tổng kết hàng tuần / tháng',
                    trailing: SettingsToggle(
                      value: _notifReport,
                      onChanged: (v) => setState(() => _notifReport = v),
                    ),
                  ),
                ],
              )),
              SliverToBoxAdapter(child: SizedBox(height: 16.h)),
              SliverToBoxAdapter(child: SettingsSection(
                title: '🔒  Bảo mật & Quyền riêng tư',
                items: [
                  SettingItem(
                    icon: Icons.fingerprint_rounded,
                    color: SettingsColors.green,
                    label: 'Xác thực sinh trắc học',
                    subtitle: 'Vân tay / Face ID',
                    trailing: SettingsToggle(
                      value: _biometric,
                      onChanged: (v) => setState(() => _biometric = v),
                    ),
                  ),
                  SettingItem(
                    icon: Icons.visibility_off_rounded,
                    color: SettingsColors.textSecondary,
                    label: 'Ẩn số dư khi mở app',
                    subtitle: 'Bảo vệ thông tin tài chính',
                    trailing: SettingsToggle(
                      value: _hideBalance,
                      onChanged: (v) => setState(() => _hideBalance = v),
                    ),
                  ),
                  SettingItem(
                    icon: Icons.lock_reset_rounded,
                    color: SettingsColors.blue,
                    label: 'Đổi mật khẩu',
                    onTap: () => _showSnack('Tính năng đang phát triển'),
                  ),
                  SettingItem(
                    icon: Icons.shield_rounded,
                    color: SettingsColors.purple,
                    label: 'Phiên đăng nhập',
                    subtitle: 'Quản lý thiết bị đã đăng nhập',
                    onTap: () {},
                  ),
                ],
              )),
              SliverToBoxAdapter(child: SizedBox(height: 16.h)),
              SliverToBoxAdapter(child: SettingsSection(
                title: '⚙️  Ứng dụng',
                items: [
                  SettingItem(
                    icon: Icons.language_rounded,
                    color: SettingsColors.blue,
                    label: 'Ngôn ngữ',
                    subtitle: 'Tiếng Việt',
                    onTap: () {},
                  ),
                  SettingItem(
                    icon: Icons.attach_money_rounded,
                    color: SettingsColors.gold,
                    label: 'Đơn vị tiền tệ',
                    subtitle: 'VND — ₫',
                    onTap: () {},
                  ),
                  SettingItem(
                    icon: Icons.cloud_upload_rounded,
                    color: SettingsColors.green,
                    label: 'Sao lưu dữ liệu',
                    subtitle: 'Lần cuối: hôm nay lúc 08:30',
                    onTap: () => _showSnack('Đang sao lưu...'),
                  ),
                  SettingItem(
                    icon: Icons.download_rounded,
                    color: SettingsColors.purple,
                    label: 'Xuất dữ liệu',
                    subtitle: 'Xuất file Excel / PDF',
                    onTap: () {},
                  ),
                ],
              )),
              SliverToBoxAdapter(child: SizedBox(height: 16.h)),
              SliverToBoxAdapter(child: SettingsSection(
                title: '❓  Hỗ trợ',
                items: [
                  SettingItem(
                    icon: Icons.help_outline_rounded,
                    color: SettingsColors.blue,
                    label: 'Trung tâm trợ giúp',
                    onTap: () {},
                  ),
                  SettingItem(
                    icon: Icons.star_rounded,
                    color: SettingsColors.gold,
                    label: 'Đánh giá ứng dụng',
                    onTap: () {},
                  ),
                  SettingItem(
                    icon: Icons.info_outline_rounded,
                    color: SettingsColors.textSecondary,
                    label: 'Về ứng dụng',
                    subtitle: 'DoctorĐồng v1.0.0',
                    onTap: () {},
                  ),
                ],
              )),
              SliverToBoxAdapter(child: SizedBox(height: 20.h)),
              SliverToBoxAdapter(child: LogoutButton(onTap: _logout)),
              SliverToBoxAdapter(child: SizedBox(height: 12.h)),
              SliverToBoxAdapter(child: DeleteAccountButton(onTap: _deleteAccount)),
              SliverToBoxAdapter(child: SizedBox(height: 32.h)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
      child: Row(
        children: [
          Text('Cài đặt',
              style: TextStyle(
                fontSize: 24.sp, fontWeight: FontWeight.w800,
                color: SettingsColors.textPrimary, letterSpacing: -0.5,
              )),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: SettingsColors.gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                  color: SettingsColors.gold.withOpacity(0.3), width: 1.w),
            ),
            child: Text('v1.0.0',
                style: TextStyle(
                  fontSize: 11.sp, color: SettingsColors.gold,
                  fontWeight: FontWeight.w600,
                )),
          ),
        ],
      ),
    );
  }
}