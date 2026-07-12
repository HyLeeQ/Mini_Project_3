import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/format/VndInputFormatter.dart';
import '../../../../data/firebase/WalletStorage.dart';
import '../../../../data/model/WalletModel.dart';

enum _WalletType { cash, bank }

class AddWalletScreen extends StatefulWidget {
  final String userId;
  const AddWalletScreen({super.key, required this.userId});

  @override
  State<AddWalletScreen> createState() => _AddWalletScreenState();
}

class _AddWalletScreenState extends State<AddWalletScreen> with SingleTickerProviderStateMixin {
  final WalletStorage _walletStorage = WalletStorage();
  // ── Design tokens ──────────────────────────────────────────────
  static const _bg = Color(0xFF0A0A0F);
  static const _surface = Color(0xFF13131A);
  static const _card = Color(0xFF1C1C26);
  static const _gold = Color(0xFFD4A843);
  static const _goldDeep = Color(0xFF9A721C);
  static const _green = Color(0xFF2ECC8A);
  static const _textPrimary = Color(0xFFF2F0E8);
  static const _textSecondary = Color(0xFF7A7A8C);
  static const _border = Color(0xFF2A2A38);
  static const _error = Color(0xFFE05555);

  // ── Controllers ────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _bankNameCtrl = TextEditingController();
  final _cardNumberCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();

  late final AnimationController _entryCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  // ── State ──────────────────────────────────────────────────────
  _WalletType _walletType = _WalletType.cash;
  bool _isLoading = false;
  bool _isDefault = false;
  String _selectedColorHex = '#2ECC8A'; // mặc định xanh cho tiền mặt

  // ── Preset colors ──────────────────────────────────────────────
  static const _colors = [
    '#2ECC8A',
    '#D4A843',
    '#5B8CFF',
    '#E05555',
    '#B05BFF',
    '#FF8C42',
    '#00C9B1',
    '#FF6B9D',
    '#A8E063',
    '#F7C59F',
    '#7B9EA6',
    '#C9ADA7',
  ];

  // ── Ngân hàng phổ biến ─────────────────────────────────────────
  static const _popularBanks = [
    ('Vietcombank', '🏦'),
    ('Techcombank', '💳'),
    ('BIDV', '🏦'),
    ('MB Bank', '💎'),
    ('VPBank', '📊'),
    ('Agribank', '🌾'),
    ('ACB', '🎯'),
    ('TPBank', '📱'),
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(
      parent: _entryCtrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _bankNameCtrl.dispose();
    _cardNumberCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────
  Color _parseColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return _gold;
    }
  }

  bool get _isCash => _walletType == _WalletType.cash;

  String get _walletIcon => _isCash ? '💵' : '💳';

  String get _walletName {
    if (_isCash) return 'Tiền mặt';
    return _bankNameCtrl.text.trim().isEmpty
        ? 'Ngân hàng'
        : _bankNameCtrl.text.trim();
  }

  double get _balance =>
      double.tryParse(
        _balanceCtrl.text.replaceAll('.', '').replaceAll(',', ''),
      ) ??
      0.0;

  String _fmtBalance(double v) {
    if (v == 0) return '0 ₫';
    return '${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')} ₫';
  }

  // ── Đổi loại ví ────────────────────────────────────────────────
  void _switchType(_WalletType type) {
    setState(() {
      _walletType = type;
      _selectedColorHex = _isCash ? '#2ECC8A' : '#D4A843';
      _bankNameCtrl.clear();
      _cardNumberCtrl.clear();
    });
  }

  // ── Save ────────────────────────────────────────────────────────
  Future<void> _saveWallet() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Chưa đăng nhập');

      final name = _isCash ? 'Tiền mặt' : _bankNameCtrl.text.trim();
      final wallet = await _walletStorage.addWallet(widget.userId, name, _walletIcon, _selectedColorHex, _balance, _isCash ? WalletType.cash : WalletType.bank, _isCash ? null : _cardNumberCtrl.text);

      if (!mounted) return;
      Navigator.pop(context, wallet);
    } catch (e) {
      if (!mounted) return;
      _showError('Không thể tạo ví: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: TextStyle(fontSize: 13.sp, color: _textPrimary),
        ),
        backgroundColor: _error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Background orb
          Positioned(
            top: -60.h,
            right: -60.w,
            child: Container(
              width: 240.w,
              height: 240.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _parseColor(_selectedColorHex).withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  children: [
                    _buildTopBar(),
                    Expanded(
                      child: Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 8.h),

                              // ── 1. Type selector ──────────────
                              _buildTypeSelector(),
                              SizedBox(height: 24.h),

                              // ── 2. Preview card ───────────────
                              _buildPreviewCard(),
                              SizedBox(height: 28.h),

                              // ── 3. Form fields ────────────────
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, anim) =>
                                    FadeTransition(
                                      opacity: anim,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0, 0.05),
                                          end: Offset.zero,
                                        ).animate(anim),
                                        child: child,
                                      ),
                                    ),
                                child: _isCash
                                    ? _buildCashFields()
                                    : _buildBankFields(),
                              ),

                              SizedBox(height: 24.h),

                              // ── 4. Color picker ───────────────
                              _buildColorPicker(),
                              SizedBox(height: 24.h),

                              // ── 6. Save button ────────────────
                              _buildSaveButton(),
                              SizedBox(height: 24.h),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top bar ─────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: _border, width: 1.w),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _textPrimary,
                size: 16.sp,
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thêm ví mới',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Chọn loại ví phù hợp',
                style: TextStyle(fontSize: 12.sp, color: _textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Type selector: Tiền mặt | Thẻ ngân hàng ────────────────────
  Widget _buildTypeSelector() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _border, width: 1.w),
      ),
      child: Row(
        children: [
          _typeTab(
            type: _WalletType.cash,
            icon: '💵',
            label: 'Tiền mặt',
            accentColor: _green,
          ),
          SizedBox(width: 4.w),
          _typeTab(
            type: _WalletType.bank,
            icon: '💳',
            label: 'Thẻ ngân hàng',
            accentColor: _gold,
          ),
        ],
      ),
    );
  }

  Widget _typeTab({
    required _WalletType type,
    required String icon,
    required String label,
    required Color accentColor,
  }) {
    final isSelected = _walletType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () => _switchType(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          height: 52.h,
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withOpacity(0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected
                  ? accentColor.withOpacity(0.4)
                  : Colors.transparent,
              width: 1.w,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: TextStyle(fontSize: 18.sp)),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected ? accentColor : _textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Preview card ────────────────────────────────────────────────
  Widget _buildPreviewCard() {
    final accent = _parseColor(_selectedColorHex);
    final cardNumber = _cardNumberCtrl.text.trim();
    final maskedCard = cardNumber.length >= 4
        ? '**** **** **** ${cardNumber.substring(cardNumber.length - 4)}'
        : '**** **** **** ****';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: 165.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        gradient: LinearGradient(
          colors: _isCash
              ? [const Color(0xFF1E2A1E), const Color(0xFF0F1A0F)]
              : [const Color(0xFF1A1A2E), const Color(0xFF0D0D1F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: accent.withOpacity(0.5), width: 1.5.w),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -24.h,
            right: -24.w,
            child: Container(
              width: 130.w,
              height: 130.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -28.h,
            left: -16.w,
            child: Container(
              width: 90.w,
              height: 90.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withOpacity(0.04),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Center(
                        child: Text(
                          _walletIcon,
                          style: TextStyle(fontSize: 18.sp),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        _walletName,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: _textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Type badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        _isCash ? 'Tiền mặt' : 'Ngân hàng',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Balance
                Text(
                  'Số dư',
                  style: TextStyle(fontSize: 11.sp, color: _textSecondary),
                ),
                SizedBox(height: 3.h),
                Text(
                  _fmtBalance(_balance),
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),

                // Card number (chỉ khi bank)
                if (!_isCash) ...[
                  SizedBox(height: 6.h),
                  Text(
                    maskedCard,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: _textSecondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],

                if (_isDefault) ...[
                  SizedBox(height: 5.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(5.r),
                    ),
                    child: Text(
                      'Ví mặc định',
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Cash fields: chỉ số dư ─────────────────────────────────────
  Widget _buildCashFields() {
    return Column(
      key: const ValueKey('cash'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          label: 'Số dư hiện có',
          child: TextFormField(
            controller: _balanceCtrl,
            onChanged: (_) => setState(() {}),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
            ],
            style: TextStyle(color: _textPrimary, fontSize: 15.sp),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              final raw = v.replaceAll('.', '').replaceAll(',', '');
              if (double.tryParse(raw) == null) return 'Số tiền không hợp lệ';
              return null;
            },
            decoration: _inputDeco(
              hint: '0',
              icon: Icons.account_balance_wallet_outlined,
              suffix: Padding(
                padding: EdgeInsets.only(right: 16.w),
                child: Text(
                  '₫',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: _green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Bank fields: tên ngân hàng + số thẻ + số dư ────────────────
  Widget _buildBankFields() {
    return Column(
      key: const ValueKey('bank'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tên ngân hàng
        _buildSection(
          label: 'Tên ngân hàng',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _bankNameCtrl,
                onChanged: (_) => setState(() {}),
                style: TextStyle(color: _textPrimary, fontSize: 15.sp),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Vui lòng nhập tên ngân hàng';
                  }
                  return null;
                },
                decoration: _inputDeco(
                  hint: 'VD: Vietcombank, Techcombank...',
                  icon: Icons.account_balance_rounded,
                ),
              ),
              SizedBox(height: 10.h),
              // Quick select ngân hàng phổ biến
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: _popularBanks.map((bank) {
                  final isSelected = _bankNameCtrl.text.trim() == bank.$1;
                  return GestureDetector(
                    onTap: () {
                      _bankNameCtrl.text = bank.$1;
                      setState(() {});
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? _gold.withOpacity(0.12) : _surface,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: isSelected ? _gold.withOpacity(0.4) : _border,
                          width: 1.w,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(bank.$2, style: TextStyle(fontSize: 13.sp)),
                          SizedBox(width: 5.w),
                          Text(
                            bank.$1,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: isSelected ? _gold : _textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        SizedBox(height: 20.h),

        // Số thẻ
        _buildSection(
          label: 'Số thẻ (tuỳ chọn)',
          child: TextFormField(
            controller: _cardNumberCtrl,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
              _CardNumberFormatter(),
            ],
            style: TextStyle(
              color: _textPrimary,
              fontSize: 15.sp,
              letterSpacing: 2,
            ),
            decoration: _inputDeco(
              hint: '0000 0000 0000 0000',
              icon: Icons.credit_card_rounded,
            ),
          ),
        ),

        SizedBox(height: 20.h),
        // so du
        _buildSection(
          label: 'Số dư hiện có',
          child: TextFormField(
            controller: _balanceCtrl,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.number,
            // ← chỉ số, không cần decimal
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly, // ← chỉ nhận chữ số
              VndInputFormatter(), // ← tự format 1.000.000
            ],
            style: TextStyle(color: _textPrimary, fontSize: 15.sp),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              if (parseVnd(v) < 0) return 'Số tiền không hợp lệ';
              return null;
            },
            decoration: _inputDeco(
              hint: '0',
              icon: Icons.account_balance_wallet_outlined,
              suffix: Padding(
                padding: EdgeInsets.only(right: 16.w),
                child: Text(
                  '₫',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: _gold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Color picker ────────────────────────────────────────────────
  Widget _buildColorPicker() {
    return _buildSection(
      label: 'Màu sắc',
      child: Wrap(
        spacing: 10.w,
        runSpacing: 10.h,
        children: _colors.map((hex) {
          final isSelected = _selectedColorHex == hex;
          final color = _parseColor(hex);
          return GestureDetector(
            onTap: () => setState(() => _selectedColorHex = hex),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(
                  color: isSelected ? _textPrimary : Colors.transparent,
                  width: 2.5.w,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)]
                    : null,
              ),
              child: isSelected
                  ? Icon(Icons.check_rounded, color: Colors.white, size: 16.sp)
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Save button ─────────────────────────────────────────────────
  Widget _buildSaveButton() {
    final accent = _parseColor(_selectedColorHex);
    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveWallet,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isCash ? _green : _gold,
          disabledBackgroundColor: (_isCash ? _green : _gold).withOpacity(0.3),
          foregroundColor: const Color(0xFF0A1A0A),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                width: 22.w,
                height: 22.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF0A1A0A),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isCash
                        ? Icons.account_balance_wallet_rounded
                        : Icons.credit_card_rounded,
                    size: 20.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    _isCash ? 'Tạo ví tiền mặt' : 'Thêm thẻ ngân hàng',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Section wrapper ─────────────────────────────────────────────
  Widget _buildSection({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: _textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        SizedBox(height: 10.h),
        child,
      ],
    );
  }

  // ── Input decoration ────────────────────────────────────────────
  InputDecoration _inputDeco({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: _textSecondary.withOpacity(0.5)),
      prefixIcon: Icon(icon, color: _textSecondary, size: 20.sp),
      suffixIcon: suffix,
      filled: true,
      fillColor: _surface,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
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
          color: (_isCash ? _green : _gold).withOpacity(0.6),
          width: 1.5.w,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: BorderSide(color: _error.withOpacity(0.6), width: 1.5.w),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: BorderSide(color: _error, width: 1.5.w),
      ),
      errorStyle: TextStyle(fontSize: 11.sp, color: _error),
    );
  }
}

// ── Card number formatter: 0000 0000 0000 0000 ─────────────────────
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final str = buffer.toString();
    return newValue.copyWith(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}
