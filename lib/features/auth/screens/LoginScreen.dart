import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/core/widget/Main_bottom_nav.dart';
import 'package:expense_tracker/data/model/UserModel.dart';
import 'package:expense_tracker/data/repositories/prefs/UserPrefsService.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/helper/aleart.dart';
import 'RegisterScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ── Design tokens ──────────────────────────────────────────────
  static const _bg = Color(0xFF0A0A0F);
  static const _surface = Color(0xFF13131A);
  static const _card = Color(0xFF1C1C26);
  static const _gold = Color(0xFFD4A843);
  static const _textPrimary = Color(0xFFF2F0E8);
  static const _textSecondary = Color(0xFF7A7A8C);
  static const _border = Color(0xFF2A2A38);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
          ),
        );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() =>
            _isLoading = true
    );
    // await Future.delayed(const Duration(milliseconds: 1500));
    await signIn();
    setState(() =>
       _isLoading = false
    );
  }
  Future<void> signIn() async{
    try{
      final query = await FirebaseFirestore.instance
          .collection('Users')
          .where('email', isEqualTo: _emailController.text)
          .limit(1)
          .get();
      if (query.docs.isEmpty) {
        displayMessageToUser(context, 'Không tìm thấy tài khoản này', isSuccess: false);
        return;
      }else{
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: _emailController.text, password: _passwordController.text);
        final data = query.docs.first.data();
        final user = UserModel.fromJson(data);

        await UserPrefsService.saveUser(user);
        Navigator.push(context, PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => MainNavigationScreen(user: user,),
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
      }
    }on FirebaseAuthException catch (e) {
      if (context.mounted) {
        displayMessageToUser(context, 'Tài khoản hoặc mật khẩu không đúng', isSuccess: false);
      }
    } catch (e) {
      if (context.mounted) {
        displayMessageToUser(context, 'Có lỗi xảy ra: $e', isSuccess: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // ── Background orb top-right ────────────────────────────
          Positioned(
            top: -80.h,
            right: -60.w,
            child: Container(
              width: 260.w,
              height: 260.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_gold.withOpacity(0.18), _gold.withOpacity(0.0)],
                ),
              ),
            ),
          ),
          // ── Background orb bottom-left ──────────────────────────
          Positioned(
            bottom: 80.h,
            left: -80.w,
            child: Container(
              width: 200.w,
              height: 200.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF4A3F8F).withOpacity(0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Scrollable body ─────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 28.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 48.h),
                      _buildHeader(),
                      SizedBox(height: 52.h),
                      _buildFormCard(),
                      SizedBox(height: 28.h),
                      _buildRegisterLink(),
                      SizedBox(height: 32.h),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo box
        Container(
          width: 150.w,
          height: 52.h,
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: _gold.withOpacity(0.4), width: 1.w),
          ),
          child: Padding(
            padding: EdgeInsets.all(8.w),
            child: Center(
              child: Text(
                'DoctorDong',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: _gold,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 32.h),
        Text(
          'Chào mừng\ntrở lại',
          style: TextStyle(
            fontSize: 36.sp,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
            height: 1.15,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          'Đăng nhập để quản lý tài chính của bạn',
          style: TextStyle(fontSize: 15.sp, color: _textSecondary, height: 1.5),
        ),
      ],
    );
  }

  // ── Form card ───────────────────────────────────────────────────
  Widget _buildFormCard() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: _border, width: 1.w),
      ),
      child: Column(
        children: [
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'you@example.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 16.h),
          _buildTextField(
            controller: _passwordController,
            label: 'Mật khẩu',
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscure: _obscurePassword,
            suffix: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: _textSecondary,
                size: 20.sp,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          SizedBox(height: 12.h),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Quên mật khẩu?',
              style: TextStyle(
                fontSize: 13.sp,
                color: _gold,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(height: 24.h),
          _buildLoginButton(),
          SizedBox(height: 20.h),
          _buildDivider(),
          SizedBox(height: 20.h),
          _buildSocialButton(
            icon: Icons.g_mobiledata_rounded,
            label: 'Tiếp tục với Google',
          ),
        ],
      ),
    );
  }

  // ── Text field ──────────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
            color: _textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: TextStyle(color: _textPrimary, fontSize: 15.sp),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _textSecondary.withOpacity(0.5)),
            prefixIcon: Icon(icon, color: _textSecondary, size: 20.sp),
            suffixIcon: suffix,
            filled: true,
            fillColor: _surface,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(color: _border, width: 1.w),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(color: _border, width: 1.w),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(
                color: _gold.withOpacity(0.6),
                width: 1.5.w,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Login button ────────────────────────────────────────────────
  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: _gold,
          foregroundColor: const Color(0xFF1A1200),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? SizedBox(
                width: 22.w,
                height: 22.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF1A1200),
                ),
              )
            : Text(
                'Đăng nhập',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }

  // ── Divider ─────────────────────────────────────────────────────
  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(color: _border, thickness: 1.h),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Text(
            'hoặc',
            style: TextStyle(fontSize: 13.sp, color: _textSecondary),
          ),
        ),
        Expanded(
          child: Divider(color: _border, thickness: 1.h),
        ),
      ],
    );
  }

  // ── Social button ───────────────────────────────────────────────
  Widget _buildSocialButton({required IconData icon, required String label}) {
    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(icon, color: _textPrimary, size: 22.sp),
        label: Text(
          label,
          style: TextStyle(
            color: _textPrimary,
            fontSize: 15.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: _border, width: 1.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
      ),
    );
  }

  // ── Register link ────────────────────────────────────────────────
  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Chưa có tài khoản? ',
          style: TextStyle(color: _textSecondary, fontSize: 14.sp),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, a, __) => const RegisterScreen(),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 300),
            ),
          ),
          child: Text(
            'Đăng ký ngay',
            style: TextStyle(
              color: _gold,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
