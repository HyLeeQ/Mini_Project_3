import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/helper/aleart.dart';
import '../../../data/model/UserModel.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  bool checkName = true;
  bool checkEmail = true;

  // ── Thêm: lỗi validate password/confirm ──
  String? _passwordError;
  String? _confirmError;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _agreeTerms = false;
  int _step = 1;

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
  static const _success = Color(0xFF2ECC8A);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> createUserDocument(UserCredential? userCredential) async {
    if (userCredential != null && userCredential.user != null) {
      String email = userCredential.user!.email!;
      final docRef = FirebaseFirestore.instance.collection('Users').doc();
      String randomId = docRef.id;
      final user = UserModel(
        id: randomId,
        name: _nameController.text,
        email: email,
        createdAt: DateTime.now(),
      );
      await docRef.set(user.toJson());
    }
  }

  bool validateStep1() {
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    bool isValid = true;

    if (name.isEmpty) {
      checkName = false;
      isValid = false;
    } else {
      checkName = true;
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      checkEmail = false;
      isValid = false;
    } else {
      checkEmail = true;
    }

    setState(() {});
    return isValid;
  }

  // ── Kiểm tra độ mạnh mật khẩu ───────────────────────────────────
  // Trả về null nếu hợp lệ, trả về thông báo lỗi nếu không hợp lệ
  String? _validatePasswordStrength(String password) {
    if (password.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (password.length < 8) return 'Mật khẩu phải có ít nhất 8 ký tự';
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Mật khẩu phải có ít nhất 1 chữ hoa (A–Z)';
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Mật khẩu phải có ít nhất 1 chữ thường (a–z)';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Mật khẩu phải có ít nhất 1 chữ số (0–9)';
    }
    if (!password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) {
      return 'Mật khẩu phải có ít nhất 1 ký tự đặc biệt (!@#\$...)';
    }
    return null;
  }

  // ── Tính độ mạnh (0–4) dựa trên từng tiêu chí ───────────────────
  int _calcStrength(String password) {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) score++;
    return score;
  }

  bool validateStep2() {
    final pwdError = _validatePasswordStrength(_passwordController.text);
    String? cfmError;

    if (_confirmController.text.isEmpty) {
      cfmError = 'Vui lòng xác nhận mật khẩu';
    } else if (_confirmController.text != _passwordController.text) {
      cfmError = 'Mật khẩu xác nhận không khớp';
    }

    setState(() {
      _passwordError = pwdError;
      _confirmError = cfmError;
    });

    return pwdError == null && cfmError == null;
  }

  void _nextStep() {
    if (_step == 1) {
      if (!validateStep1()) return;
      _animController.reset();
      setState(() => _step = 2);
      _animController.forward();
    } else {
      if (!validateStep2()) return; // ← kiểm tra trước khi đăng ký
      _handleRegister();
    }
  }

  void _prevStep() {
    if (_step == 2) {
      _animController.reset();
      setState(() => _step = 1);
      _animController.forward();
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _handleRegister() async {
    setState(() => _isLoading = true);
    await _registerUser();
    setState(() => _isLoading = false);
  }

  Future<void> _registerUser() async {
    try {
      UserCredential? userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      await createUserDocument(userCredential);

      if (!mounted) return;

      displayMessageToUser(
        context,
        'Tạo tài khoản thành công',
        isSuccess: true,
        onOk: () => Navigator.pop(context),
      );
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        displayMessageToUser(
          context,
          _getFirebaseErrorMessage(e),
          isSuccess: false,
          onOk: () {},
        );
      }
    }
  }

  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email này đã được sử dụng cho tài khoản khác';
      case 'invalid-email':
        return 'Địa chỉ email không hợp lệ';
      case 'weak-password':
        return 'Mật khẩu quá yếu, vui lòng đặt mật khẩu mạnh hơn';
      case 'operation-not-allowed':
        return 'Đăng ký bằng email chưa được kích hoạt';
      case 'network-request-failed':
        return 'Không có kết nối mạng, vui lòng thử lại';
      case 'too-many-requests':
        return 'Quá nhiều yêu cầu, vui lòng thử lại sau';
      case 'user-disabled':
        return 'Tài khoản này đã bị vô hiệu hóa';
      default:
        return 'Đăng ký thất bại, vui lòng thử lại sau';
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
          // ── Background orbs ──────────────────────────────────────
          Positioned(
            top: 120.h,
            right: -100.w,
            child: Container(
              width: 300.w,
              height: 300.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF2E4A8F).withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -40.h,
            right: 20.w,
            child: Container(
              width: 180.w,
              height: 180.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_gold.withOpacity(0.12), Colors.transparent],
                ),
              ),
            ),
          ),

          // ── Main content ─────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 12.h,
                  ),
                  child: Row(
                    children: [
                      _buildBackButton(),
                      const Spacer(),
                      _buildStepIndicator(),
                      const Spacer(),
                      SizedBox(width: 44.w),
                    ],
                  ),
                ),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: 28.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 28.h),
                            _buildHeader(),
                            SizedBox(height: 40.h),
                            _buildFormCard(),
                            SizedBox(height: 28.h),
                            if (_step == 2) _buildTermsRow(),
                            if (_step == 2) SizedBox(height: 20.h),
                            _buildActionButton(),
                            SizedBox(height: 24.h),
                            _buildLoginLink(),
                            SizedBox(height: 32.h),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: _prevStep,
      child: Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: _border, width: 1.w),
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: _textPrimary,
          size: 18.sp,
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _stepDot(1),
        SizedBox(width: 6.w),
        Container(
          width: 24.w,
          height: 2.h,
          decoration: BoxDecoration(
            color: _step >= 2 ? _gold : _border,
            borderRadius: BorderRadius.circular(1.r),
          ),
        ),
        SizedBox(width: 6.w),
        _stepDot(2),
      ],
    );
  }

  Widget _stepDot(int step) {
    final isActive = _step == step;
    final isDone = _step > step;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 28.w,
      height: 28.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDone
            ? _success.withOpacity(0.15)
            : isActive
            ? _gold.withOpacity(0.15)
            : _surface,
        border: Border.all(
          color: isDone ? _success : isActive ? _gold : _border,
          width: 1.5.w,
        ),
      ),
      child: Center(
        child: isDone
            ? Icon(Icons.check_rounded, color: _success, size: 14.sp)
            : Text(
          '$step',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: isActive ? _gold : _textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _step == 1 ? 'Tạo tài khoản' : 'Bảo mật\ntài khoản',
          style: TextStyle(
            fontSize: 34.sp,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
            height: 1.15,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          _step == 1
              ? 'Điền thông tin để bắt đầu\nquản lý chi tiêu thông minh'
              : 'Tạo mật khẩu mạnh để\nbảo vệ tài khoản của bạn',
          style: TextStyle(
            fontSize: 15.sp,
            color: _textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: _border, width: 1.w),
      ),
      child: _step == 1 ? _buildStep1Fields() : _buildStep2Fields(),
    );
  }

  Widget _buildStep1Fields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: _nameController,
          label: 'Họ và tên',
          hint: 'Nguyễn Văn A',
          icon: Icons.person_outline_rounded,
        ),
        SizedBox(height: 5.h),
        if (!checkName)
          _buildErrorText('Vui lòng điền tên của bạn'),
        SizedBox(height: 16.h),
        _buildTextField(
          controller: _emailController,
          label: 'Email',
          hint: 'you@example.com',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: 5.h),
        if (!checkEmail)
          _buildErrorText('Email không hợp lệ'),
      ],
    );
  }

  Widget _buildStep2Fields() {
    return Column(
      children: [
        // ── Mật khẩu ──
        _buildTextField(
          controller: _passwordController,
          label: 'Mật khẩu',
          hint: 'Ít nhất 8 ký tự',
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

        // ── Thông báo lỗi mật khẩu ──
        if (_passwordError != null) ...[
          SizedBox(height: 6.h),
          _buildErrorText(_passwordError!),
        ],

        SizedBox(height: 12.h),

        // ── Strength indicator ──
        _buildPasswordStrength(),

        SizedBox(height: 16.h),

        // ── Confirm password ──
        _buildTextField(
          controller: _confirmController,
          label: 'Xác nhận mật khẩu',
          hint: 'Nhập lại mật khẩu',
          icon: Icons.lock_outline_rounded,
          obscure: _obscureConfirm,
          suffix: IconButton(
            icon: Icon(
              _obscureConfirm
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: _textSecondary,
              size: 20.sp,
            ),
            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),

        // ── Thông báo lỗi confirm ──
        if (_confirmError != null) ...[
          SizedBox(height: 6.h),
          _buildErrorText(_confirmError!),
        ],

        SizedBox(height: 16.h),

        // ── Checklist tiêu chí mật khẩu ──
        _buildPasswordChecklist(),
      ],
    );
  }

  // ── Strength bar (3 thanh màu) ───────────────────────────────────
  Widget _buildPasswordStrength() {
    final password = _passwordController.text;
    final strength = _calcStrength(password);

    final colors = [_border, Colors.redAccent, Colors.orange, _gold, _success];
    final labels = ['', 'Yếu', 'Trung bình', 'Tốt', 'Mạnh'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 4.h,
                margin: EdgeInsets.only(right: i < 3 ? 6.w : 0),
                decoration: BoxDecoration(
                  color: i < strength ? colors[strength] : _border,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            );
          }),
        ),
        if (strength > 0) ...[
          SizedBox(height: 6.h),
          Row(
            children: [
              Text(
                'Độ mạnh: ',
                style: TextStyle(fontSize: 12.sp, color: _textSecondary),
              ),
              Text(
                labels[strength],
                style: TextStyle(
                  fontSize: 12.sp,
                  color: colors[strength],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ── Checklist từng tiêu chí ──────────────────────────────────────
  Widget _buildPasswordChecklist() {
    final password = _passwordController.text;
    final criteria = [
      {'label': 'Ít nhất 8 ký tự', 'met': password.length >= 8},
      {'label': 'Có chữ hoa (A–Z)', 'met': password.contains(RegExp(r'[A-Z]'))},
      {'label': 'Có chữ thường (a–z)', 'met': password.contains(RegExp(r'[a-z]'))},
      {'label': 'Có chữ số (0–9)', 'met': password.contains(RegExp(r'[0-9]'))},
      {
        'label': 'Có ký tự đặc biệt (!@#\$...)',
        'met': password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))
      },
    ];

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _border, width: 1.w),
      ),
      child: Column(
        children: criteria.map((c) {
          final met = c['met'] as bool;
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 18.w,
                  height: 18.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: met ? _success.withOpacity(0.15) : Colors.transparent,
                    border: Border.all(
                      color: met ? _success : _textSecondary.withOpacity(0.4),
                      width: 1.5.w,
                    ),
                  ),
                  child: met
                      ? Icon(Icons.check_rounded, color: _success, size: 11.sp)
                      : null,
                ),
                SizedBox(width: 10.w),
                Text(
                  c['label'] as String,
                  style: TextStyle(
                    fontSize: 12.5.sp,
                    color: met ? _textPrimary : _textSecondary,
                    fontWeight: met ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Helper: error text ───────────────────────────────────────────
  Widget _buildErrorText(String message) {
    return Row(
      children: [
        Icon(Icons.info_outline_rounded,
            color: Colors.redAccent, size: 13.sp),
        SizedBox(width: 4.w),
        Text(
          message,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: Colors.redAccent,
          ),
        ),
      ],
    );
  }

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
          onChanged: (_) => setState(() {}),
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
              borderSide: BorderSide(color: _gold.withOpacity(0.6), width: 1.5.w),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsRow() {
    return GestureDetector(
      onTap: () => setState(() => _agreeTerms = !_agreeTerms),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22.w,
            height: 22.w,
            decoration: BoxDecoration(
              color: _agreeTerms ? _gold : Colors.transparent,
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(
                color: _agreeTerms ? _gold : _border,
                width: 1.5.w,
              ),
            ),
            child: _agreeTerms
                ? Icon(Icons.check_rounded,
                color: const Color(0xFF1A1200), size: 14.sp)
                : null,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 13.sp,
                  color: _textSecondary,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: 'Tôi đồng ý với '),
                  TextSpan(
                    text: 'Điều khoản dịch vụ',
                    style: TextStyle(
                        color: _gold, fontWeight: FontWeight.w500),
                  ),
                  const TextSpan(text: ' và '),
                  TextSpan(
                    text: 'Chính sách bảo mật',
                    style: TextStyle(
                        color: _gold, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    final canProceed = _step == 1 ? true : (_agreeTerms && !_isLoading);

    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: ElevatedButton(
        onPressed: canProceed ? _nextStep : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _gold,
          disabledBackgroundColor: _gold.withOpacity(0.3),
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
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _step == 1 ? 'Tiếp theo' : 'Tạo tài khoản',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            if (_step == 1) ...[
              SizedBox(width: 8.w),
              Icon(Icons.arrow_forward_rounded, size: 18.sp),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Đã có tài khoản? ',
          style: TextStyle(color: _textSecondary, fontSize: 14.sp),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Text(
            'Đăng nhập',
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