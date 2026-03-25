import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// import 'package:your_app/data/model/UserModel.dart';
// import 'package:your_app/features/auth/screens/LoginScreen.dart';

// ── Stub UserModel (xoá khi import thật) ───────────────────────────
class UserModel {
  final String id, name, email;
  final DateTime createdAt;
  const UserModel({
    required this.id, required this.name,
    required this.email, required this.createdAt,
  });
}
// ──────────────────────────────────────────────────────────────────

class SettingsPage extends StatefulWidget {
  final UserModel? user;
  const SettingsPage({super.key, this.user});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  // ── Design tokens ──────────────────────────────────────────────
  static const _bg            = Color(0xFF0A0A0F);
  static const _surface       = Color(0xFF13131A);
  static const _card          = Color(0xFF1C1C26);
  static const _gold          = Color(0xFFD4A843);
  static const _goldDeep      = Color(0xFF9A721C);
  static const _goldLight     = Color(0xFFF5D07A);
  static const _green         = Color(0xFF2ECC8A);
  static const _red           = Color(0xFFE05555);
  static const _blue          = Color(0xFF5B8CFF);
  static const _purple        = Color(0xFFB05BFF);
  static const _textPrimary   = Color(0xFFF2F0E8);
  static const _textSecondary = Color(0xFF7A7A8C);
  static const _border        = Color(0xFF2A2A38);

  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fadeAnim;

  // ── Toggle states ──────────────────────────────────────────────
  bool _notifTransaction = true;
  bool _notifBudget      = true;
  bool _notifReport      = false;
  bool _biometric        = false;
  bool _hideBalance      = false;

  // ── Sample user ─────────────────────────────────────────────────
  UserModel get _user =>
      widget.user ??
          UserModel(
            id:        'demo',
            name:      'Nguyễn Văn A',
            email:     'nguyenvana@gmail.com',
            createdAt: DateTime(2024, 1, 15),
          );

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

  // ── Helpers ─────────────────────────────────────────────────────
  String _initials(String name) {
    final p = name.trim().split(' ');
    if (p.length >= 2) return '${p.first[0]}${p.last[0]}'.toUpperCase();
    return p.first[0].toUpperCase();
  }

  String _memberSince(DateTime dt) =>
      'Thành viên từ tháng ${dt.month}/${dt.year}';

  Future<void> _logout() async {
    final confirmed = await _showConfirmDialog(
      title:   'Đăng xuất',
      message: 'Bạn có chắc muốn đăng xuất khỏi tài khoản không?',
      confirmText:  'Đăng xuất',
      confirmColor: _red,
    );
    if (!confirmed) return;
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    // Navigator.pushAndRemoveUntil(
    //   context,
    //   MaterialPageRoute(builder: (_) => const LoginScreen()),
    //   (_) => false,
    // );
  }

  Future<void> _deleteAccount() async {
    final confirmed = await _showConfirmDialog(
      title:   'Xoá tài khoản',
      message: 'Hành động này không thể hoàn tác. Tất cả dữ liệu sẽ bị xoá vĩnh viễn.',
      confirmText:  'Xoá tài khoản',
      confirmColor: _red,
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
        backgroundColor: _card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r)),
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
                    color: _textPrimary,
                  )),
              SizedBox(height: 8.h),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.sp, color: _textSecondary, height: 1.5,
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _textSecondary,
                        side: BorderSide(color: _border, width: 1.w),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r)),
                        padding: EdgeInsets.symmetric(vertical: 13.h),
                      ),
                      child: Text('Huỷ',
                          style: TextStyle(fontSize: 14.sp)),
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
    ) ??
        false;
  }

  void _showSnack(String msg, {Color color = const Color(0xFF2ECC8A)}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: TextStyle(color: _textPrimary, fontSize: 13.sp)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: SizedBox(height: 20.h)),
              SliverToBoxAdapter(child: _buildProfileCard()),
              SliverToBoxAdapter(child: SizedBox(height: 24.h)),
              SliverToBoxAdapter(child: _buildSection(
                title: '💳  Tài khoản & Ví',
                items: [
                  _SettingItem(
                    icon: Icons.account_balance_wallet_rounded,
                    color: _gold,
                    label: 'Quản lý ví',
                    subtitle: '${2} ví đang hoạt động',
                    onTap: () {},
                  ),
                  _SettingItem(
                    icon: Icons.category_rounded,
                    color: _purple,
                    label: 'Danh mục chi tiêu',
                    subtitle: 'Tuỳ chỉnh danh mục',
                    onTap: () {},
                  ),
                  _SettingItem(
                    icon: Icons.savings_rounded,
                    color: _green,
                    label: 'Ngân sách',
                    subtitle: 'Thiết lập hạn mức chi tiêu',
                    onTap: () {},
                  ),
                ],
              )),
              SliverToBoxAdapter(child: SizedBox(height: 16.h)),
              SliverToBoxAdapter(child: _buildSection(
                title: '🔔  Thông báo',
                items: [
                  _SettingItem(
                    icon: Icons.receipt_long_rounded,
                    color: _blue,
                    label: 'Giao dịch mới',
                    subtitle: 'Thông báo khi có giao dịch',
                    trailing: _buildToggle(
                      value: _notifTransaction,
                      onChanged: (v) =>
                          setState(() => _notifTransaction = v),
                    ),
                  ),
                  _SettingItem(
                    icon: Icons.pie_chart_rounded,
                    color: _red,
                    label: 'Cảnh báo ngân sách',
                    subtitle: 'Khi chi tiêu vượt hạn mức',
                    trailing: _buildToggle(
                      value: _notifBudget,
                      onChanged: (v) =>
                          setState(() => _notifBudget = v),
                    ),
                  ),
                  _SettingItem(
                    icon: Icons.bar_chart_rounded,
                    color: _gold,
                    label: 'Báo cáo định kỳ',
                    subtitle: 'Tổng kết hàng tuần / tháng',
                    trailing: _buildToggle(
                      value: _notifReport,
                      onChanged: (v) =>
                          setState(() => _notifReport = v),
                    ),
                  ),
                ],
              )),
              SliverToBoxAdapter(child: SizedBox(height: 16.h)),
              SliverToBoxAdapter(child: _buildSection(
                title: '🔒  Bảo mật & Quyền riêng tư',
                items: [
                  _SettingItem(
                    icon: Icons.fingerprint_rounded,
                    color: _green,
                    label: 'Xác thực sinh trắc học',
                    subtitle: 'Vân tay / Face ID',
                    trailing: _buildToggle(
                      value: _biometric,
                      onChanged: (v) => setState(() => _biometric = v),
                    ),
                  ),
                  _SettingItem(
                    icon: Icons.visibility_off_rounded,
                    color: _textSecondary,
                    label: 'Ẩn số dư khi mở app',
                    subtitle: 'Bảo vệ thông tin tài chính',
                    trailing: _buildToggle(
                      value: _hideBalance,
                      onChanged: (v) => setState(() => _hideBalance = v),
                    ),
                  ),
                  _SettingItem(
                    icon: Icons.lock_reset_rounded,
                    color: _blue,
                    label: 'Đổi mật khẩu',
                    onTap: () => _showSnack('Tính năng đang phát triển'),
                  ),
                  _SettingItem(
                    icon: Icons.shield_rounded,
                    color: _purple,
                    label: 'Phiên đăng nhập',
                    subtitle: 'Quản lý thiết bị đã đăng nhập',
                    onTap: () {},
                  ),
                ],
              )),
              SliverToBoxAdapter(child: SizedBox(height: 16.h)),
              SliverToBoxAdapter(child: _buildSection(
                title: '⚙️  Ứng dụng',
                items: [
                  _SettingItem(
                    icon: Icons.language_rounded,
                    color: _blue,
                    label: 'Ngôn ngữ',
                    subtitle: 'Tiếng Việt',
                    onTap: () {},
                  ),
                  _SettingItem(
                    icon: Icons.attach_money_rounded,
                    color: _gold,
                    label: 'Đơn vị tiền tệ',
                    subtitle: 'VND — ₫',
                    onTap: () {},
                  ),
                  _SettingItem(
                    icon: Icons.cloud_upload_rounded,
                    color: _green,
                    label: 'Sao lưu dữ liệu',
                    subtitle: 'Lần cuối: hôm nay lúc 08:30',
                    onTap: () => _showSnack('Đang sao lưu...'),
                  ),
                  _SettingItem(
                    icon: Icons.download_rounded,
                    color: _purple,
                    label: 'Xuất dữ liệu',
                    subtitle: 'Xuất file Excel / PDF',
                    onTap: () {},
                  ),
                ],
              )),
              SliverToBoxAdapter(child: SizedBox(height: 16.h)),
              SliverToBoxAdapter(child: _buildSection(
                title: '❓  Hỗ trợ',
                items: [
                  _SettingItem(
                    icon: Icons.help_outline_rounded,
                    color: _blue,
                    label: 'Trung tâm trợ giúp',
                    onTap: () {},
                  ),
                  _SettingItem(
                    icon: Icons.star_rounded,
                    color: _gold,
                    label: 'Đánh giá ứng dụng',
                    onTap: () {},
                  ),
                  _SettingItem(
                    icon: Icons.info_outline_rounded,
                    color: _textSecondary,
                    label: 'Về ứng dụng',
                    subtitle: 'DoctorĐồng v1.0.0',
                    onTap: () {},
                  ),
                ],
              )),
              SliverToBoxAdapter(child: SizedBox(height: 20.h)),
              SliverToBoxAdapter(child: _buildLogoutButton()),
              SliverToBoxAdapter(child: SizedBox(height: 12.h)),
              SliverToBoxAdapter(child: _buildDeleteAccountButton()),
              SliverToBoxAdapter(child: SizedBox(height: 32.h)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
      child: Row(
        children: [
          Text('Cài đặt',
              style: TextStyle(
                fontSize: 24.sp, fontWeight: FontWeight.w800,
                color: _textPrimary, letterSpacing: -0.5,
              )),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: _gold.withOpacity(0.3), width: 1.w),
            ),
            child: Text('v1.0.0',
                style: TextStyle(
                  fontSize: 11.sp, color: _gold, fontWeight: FontWeight.w600,
                )),
          ),
        ],
      ),
    );
  }

  // ── Profile card ────────────────────────────────────────────────
  Widget _buildProfileCard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1C1A10),
              const Color(0xFF12100A),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: _gold.withOpacity(0.25), width: 1.5.w),
        ),
        child: Stack(
          children: [
            // Orb
            Positioned(
              top: -20.h, right: -20.w,
              child: Container(
                width: 120.w, height: 120.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    _gold.withOpacity(0.10),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),

            Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    Container(
                      width: 64.w, height: 64.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [_goldDeep, _gold, _goldLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _initials(_user.name),
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
                        onTap: () => _showSnack('Tính năng đang phát triển'),
                        child: Container(
                          width: 22.w, height: 22.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _surface,
                            border: Border.all(
                                color: _gold.withOpacity(0.5), width: 1.5.w),
                          ),
                          child: Icon(Icons.edit_rounded,
                              color: _gold, size: 11.sp),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 16.w),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _user.name,
                        style: TextStyle(
                          fontSize: 17.sp, fontWeight: FontWeight.w700,
                          color: _textPrimary, letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        _user.email,
                        style: TextStyle(
                          fontSize: 12.sp, color: _textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: _gold.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(
                              color: _gold.withOpacity(0.25), width: 1.w),
                        ),
                        child: Text(
                          _memberSince(_user.createdAt),
                          style: TextStyle(
                            fontSize: 10.sp, color: _gold,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Edit profile arrow
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 36.w, height: 36.w,
                    decoration: BoxDecoration(
                      color: _gold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                          color: _gold.withOpacity(0.25), width: 1.w),
                    ),
                    child: Icon(Icons.arrow_forward_ios_rounded,
                        color: _gold, size: 14.sp),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Section ──────────────────────────────────────────────────────
  Widget _buildSection({
    required String title,
    required List<_SettingItem> items,
  }) {
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
                color: _textSecondary, letterSpacing: 0.2,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: _border, width: 1.w),
            ),
            child: Column(
              children: List.generate(items.length, (i) {
                return Column(
                  children: [
                    _buildSettingRow(items[i]),
                    if (i < items.length - 1)
                      Divider(
                        height: 1, indent: 56.w,
                        color: _border.withOpacity(0.6),
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(_SettingItem item) {
    return GestureDetector(
      onTap: item.onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(
          children: [
            // Icon box
            Container(
              width: 36.w, height: 36.w,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(item.icon, color: item.color, size: 18.sp),
            ),
            SizedBox(width: 14.w),

            // Label + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.label,
                      style: TextStyle(
                        fontSize: 14.sp, fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      )),
                  if (item.subtitle != null) ...[
                    SizedBox(height: 2.h),
                    Text(item.subtitle!,
                        style: TextStyle(
                          fontSize: 11.sp, color: _textSecondary,
                        )),
                  ],
                ],
              ),
            ),

            // Trailing: toggle, chevron, or custom
            item.trailing ??
                (item.onTap != null
                    ? Icon(Icons.chevron_right_rounded,
                    color: _textSecondary.withOpacity(0.4), size: 18.sp)
                    : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  // ── Custom toggle switch ─────────────────────────────────────────
  Widget _buildToggle({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 46.w, height: 26.h,
        decoration: BoxDecoration(
          color: value ? _gold : _border,
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

  // ── Logout button ────────────────────────────────────────────────
  Widget _buildLogoutButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: GestureDetector(
        onTap: _logout,
        child: Container(
          height: 54.h,
          decoration: BoxDecoration(
            color: _red.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: _red.withOpacity(0.3), width: 1.w),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: _red, size: 20.sp),
              SizedBox(width: 10.w),
              Text('Đăng xuất',
                  style: TextStyle(
                    fontSize: 15.sp, fontWeight: FontWeight.w700,
                    color: _red,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ── Delete account ───────────────────────────────────────────────
  Widget _buildDeleteAccountButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: GestureDetector(
        onTap: _deleteAccount,
        child: Center(
          child: Text(
            'Xoá tài khoản',
            style: TextStyle(
              fontSize: 13.sp,
              color: _textSecondary.withOpacity(0.5),
              decoration: TextDecoration.underline,
              decorationColor: _textSecondary.withOpacity(0.3),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Data model ───────────────────────────────────────────────────────
class _SettingItem {
  final IconData  icon;
  final Color     color;
  final String    label;
  final String?   subtitle;
  final Widget?   trailing;
  final VoidCallback? onTap;

  const _SettingItem({
    required this.icon,
    required this.color,
    required this.label,
    this.subtitle,
    this.trailing,
    this.onTap,
  });
}