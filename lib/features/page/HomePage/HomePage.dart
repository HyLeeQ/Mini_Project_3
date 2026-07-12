import 'dart:math' as math;
import 'package:expense_tracker/features/page/HomePage/screens/AddWalletScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../data/model/CategoryModel.dart';
import '../../../data/model/TransactionModel.dart';
import '../../../data/model/UserModel.dart';
import '../../../data/model/WalletModel.dart';
import 'screens/AllTransactionsScreen.dart';
import '../add_transaction/models/sample_data.dart';
import 'bloc/transaction_bloc/transaction_bloc.dart';
import 'bloc/transaction_bloc/transaction_state.dart';
import 'bloc/wallet_bloc/wallet_bloc.dart';
import 'bloc/wallet_bloc/wallet_event.dart';
import 'bloc/wallet_bloc/wallet_state.dart';

class HomePage extends StatefulWidget {
  final UserModel user;
  final List<CategoryModel> categories;

  const HomePage({super.key, required this.user, this.categories = const []});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  // ── Design tokens ──────────────────────────────────────────────
  static const _bg = Color(0xFF0A0A0F);
  static const _surface = Color(0xFF13131A);
  static const _card = Color(0xFF1C1C26);
  static const _gold = Color(0xFFD4A843);
  static const _goldDeep = Color(0xFF9A721C);
  static const _textPrimary = Color(0xFFF2F0E8);
  static const _textSecondary = Color(0xFF7A7A8C);
  static const _border = Color(0xFF2A2A38);

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  bool _isHidden = false;
  int _selectedWalletIndex = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _toggleHidden() => setState(() => _isHidden = !_isHidden);

  // ── Format helpers ──────────────────────────────────────────────
  String _fmt(double amount, {bool showSign = false}) {
    if (_isHidden) return '••••••';
    final sign = showSign && amount > 0 ? '+' : '';
    final str = amount
        .abs()
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
    return '${showSign && amount < 0 ? '-' : sign}$str ₫';
  }

  String _fmtDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    // 1. Dưới 1 phút
    if (diff.inMinutes < 1) {
      return 'Vừa xong';
    }

    // 2. Dưới 1 giờ → phút
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} phút trước';
    }

    // 3. Dưới 24 giờ → giờ
    if (diff.inHours < 24) {
      return '${diff.inHours} giờ trước';
    }

    // 4. Hôm qua
    if (diff.inDays == 1) {
      return 'Hôm qua';
    }

    // 5. 2–6 ngày trước
    if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    }

    // 6. Lâu hơn → format ngày
    return '${date.day}/${date.month}';
  }

  String _firstName(String name) {
    final parts = name.trim().split(' ');
    return parts.last;
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  // ── Parse colorHex ──────────────────────────────────────────────
  Color _parseColor(String hex, {Color fallback = const Color(0xFF7A7A8C)}) {
    try {
      final cleaned = hex.replaceAll('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  // ── Lấy category theo id ────────────────────────────────────────
  List<CategoryModel> get _allCategories =>
      widget.categories.isNotEmpty ? widget.categories : SampleData.categories;

  CategoryModel? _categoryById(String id) {
    try {
      return _allCategories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
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
              SliverToBoxAdapter(child: _buildGreeting()),
              SliverToBoxAdapter(child: SizedBox(height: 20.h)),
              SliverToBoxAdapter(child: _buildWalletSection()),
              SliverToBoxAdapter(child: SizedBox(height: 24.h)),
              SliverToBoxAdapter(child: _buildChartSection()),
              SliverToBoxAdapter(child: SizedBox(height: 24.h)),
              SliverToBoxAdapter(child: _buildTransactionsSection()),
              SliverToBoxAdapter(child: SizedBox(height: 24.h)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Greeting ────────────────────────────────────────────────────
  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Chào buổi sáng'
        : hour < 18
        ? 'Chào buổi chiều'
        : 'Chào buổi tối';
    final name = widget.user?.name ?? 'Bạn';

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting 👋',
                  style: TextStyle(fontSize: 13.sp, color: _textSecondary),
                ),
                SizedBox(height: 3.h),
                Text(
                  _firstName(name),
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              // Nút mắt ẩn/hiện
              GestureDetector(
                onTap: _toggleHidden,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 38.w,
                  height: 38.w,
                  decoration: BoxDecoration(
                    color: _isHidden ? _gold.withOpacity(0.12) : _surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isHidden ? _gold.withOpacity(0.4) : _border,
                      width: 1.w,
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _isHidden
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      key: ValueKey(_isHidden),
                      color: _isHidden ? _gold : _textSecondary,
                      size: 17.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              // Notification
              Container(
                width: 38.w,
                height: 38.w,
                decoration: BoxDecoration(
                  color: _surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: _border, width: 1.w),
                ),
                child: Icon(
                  Icons.notifications_outlined,
                  color: _textSecondary,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 8.w),
              // Avatar
              Container(
                width: 38.w,
                height: 38.w,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [_goldDeep, _gold],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    _initials(name),
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1200),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Wallet section ──────────────────────────────────────────────
  Widget _buildWalletSection() {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        final wallets = state is WalletLoaded ? state.wallets : <WalletModel>[];
        final isLoading = state is WalletLoading;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                children: [
                  Text('Ví của tôi', style: _sectionTitle()),
                  const Spacer(),
                  Text(
                    _isHidden
                        ? '••••••'
                        : _fmt(wallets.fold(0.0, (s, w) => s + w.balance)),
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: _isHidden ? _textSecondary : _gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  _addBtn(() => _goToAddWallet(context)),
                ],
              ),
            ),
            SizedBox(height: 14.h),
            if (isLoading)
              _buildWalletSkeleton()
            else
              SizedBox(
                height: 160.h,
                child: wallets.isEmpty
                    ? _buildEmptyWallet()
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        itemCount: wallets.length + 1,
                        itemBuilder: (_, i) {
                          if (i == wallets.length) return _buildAddCardBtn();
                          return _buildWalletCard(wallets[i], i);
                        },
                      ),
              ),
          ],
        );
      },
    );
  }

  void _goToAddWallet(BuildContext context) async {
    final newWallet = await Navigator.push<WalletModel>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) =>
            AddWalletScreen(userId: widget.user.id),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.ease)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );

    // Dispatch event nếu có wallet mới trả về
    if (newWallet != null && context.mounted) {
      context.read<WalletBloc>().add(AddWallet(newWallet));
    }
  }

  Widget _buildWalletSkeleton() {
    return SizedBox(
      height: 160.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        itemCount: 3,
        // 2 card skeleton + 1 nút thêm
        itemBuilder: (_, i) {
          if (i == 2) {
            // Nút thêm skeleton
            return Container(
              width: 120.w,
              margin: EdgeInsets.only(right: 20.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: _border, width: 1.w),
                color: _surface,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Shimmer(
                    width: 36.w,
                    height: 36.w,
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                  SizedBox(height: 8.h),
                  _Shimmer(
                    width: 48.w,
                    height: 12.h,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                ],
              ),
            );
          }
          // Wallet card skeleton
          return Container(
            width: 200.w,
            margin: EdgeInsets.only(right: 12.w),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: _border, width: 1.w),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    _Shimmer(
                      width: 32.w,
                      height: 32.w,
                      borderRadius: BorderRadius.circular(9.r),
                    ),
                    SizedBox(width: 8.w),
                    _Shimmer(
                      width: i == 0 ? 80.w : 64.w,
                      height: 12.h,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                  ],
                ),
                const Spacer(),
                // Label + balance
                _Shimmer(
                  width: 36.w,
                  height: 10.h,
                  borderRadius: BorderRadius.circular(5.r),
                ),
                SizedBox(height: 5.h),
                _Shimmer(
                  width: i == 0 ? 110.w : 90.w,
                  height: 18.h,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                // Card number chỉ card đầu
                if (i == 0) ...[
                  SizedBox(height: 6.h),
                  _Shimmer(
                    width: 100.w,
                    height: 10.h,
                    borderRadius: BorderRadius.circular(5.r),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWalletCard(WalletModel wallet, int index) {
    final isSelected = _selectedWalletIndex == index;
    final accentColor = _parseColor(wallet.colorHex, fallback: _gold);

    final isCash =
        wallet.icon == 'cash' ||
        wallet.name.toLowerCase().contains('tiền mặt') ||
        wallet.name.toLowerCase().contains('cash');

    return GestureDetector(
      onTap: () => setState(() => _selectedWalletIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 200.w,
        margin: EdgeInsets.only(right: 12.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          gradient: LinearGradient(
            colors: isCash
                ? [const Color(0xFF1E2A1E), const Color(0xFF0F1A0F)]
                : [const Color(0xFF1A1A2E), const Color(0xFF0D0D1F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: isSelected ? accentColor.withOpacity(0.5) : _border,
            width: isSelected ? 1.5.w : 1.w,
          ),
        ),
        child: Stack(
          children: [
            // Orb deco
            Positioned(
              top: -20.h,
              right: -20.w,
              child: Container(
                width: 100.w,
                height: 100.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -30.h,
              left: -10.w,
              child: Container(
                width: 80.w,
                height: 80.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withOpacity(0.04),
                ),
              ),
            ),

            // Content
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 32.w,
                        height: 32.w,
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(9.r),
                        ),
                        child: Icon(
                          isCash
                              ? Icons.account_balance_wallet_rounded
                              : Icons.credit_card_rounded,
                          color: accentColor,
                          size: 16.sp,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          wallet.name,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: _textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        width: 6.w,
                        height: 6.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Balance label
                  Text(
                    'Số dư',
                    style: TextStyle(fontSize: 11.sp, color: _textSecondary),
                  ),
                  SizedBox(height: 4.h),

                  // Balance — ẩn/hiện
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: Text(
                      _fmt(wallet.balance),
                      key: ValueKey('${_isHidden}_${wallet.id}_bal'),
                      style: TextStyle(
                        fontSize: _isHidden ? 16.sp : 18.sp,
                        fontWeight: FontWeight.w700,
                        color: _isHidden ? _textSecondary : _textPrimary,
                        letterSpacing: _isHidden ? 3 : -0.3,
                      ),
                    ),
                  ),

                  // Card number (nếu không phải tiền mặt)
                  if (!isCash) ...[
                    SizedBox(height: 6.h),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: Text(
                        _isHidden
                            ? '**** **** **** ****'
                            : wallet.cardNumber.toString(),
                        key: ValueKey('${_isHidden}_${wallet.id}_digits'),
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: _isHidden
                              ? _textSecondary.withOpacity(0.4)
                              : _textSecondary,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCardBtn() {
    return GestureDetector(
      onTap: () {
        _goToAddWallet(context);
      },
      child: Container(
        width: 120.w,
        margin: EdgeInsets.only(right: 20.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: _border, width: 1.w),
          color: _surface,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _gold.withOpacity(0.12),
                border: Border.all(color: _gold.withOpacity(0.3), width: 1.w),
              ),
              child: Icon(Icons.add_rounded, color: _gold, size: 18.sp),
            ),
            SizedBox(height: 8.h),
            Text(
              'Thêm ví',
              style: TextStyle(
                fontSize: 12.sp,
                color: _gold,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWallet() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: _border),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                color: _textSecondary,
                size: 28.sp,
              ),
              SizedBox(height: 8.h),
              Text(
                'Chưa có ví nào',
                style: TextStyle(fontSize: 13.sp, color: _textSecondary),
              ),
              SizedBox(height: 4.h),
              Text(
                'Nhấn + để thêm ví',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: _gold,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Chart section ───────────────────────────────────────────────
  Widget _buildChartSection() {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        final total = state is TransactionLoaded
            ? state.totalExpenseThisMonth
            : 0.0;
        final expByCat = state is TransactionLoaded
            ? state.expenseByCategory
            : <String, double>{};
        print("HOME DEBUG - Tổng: $total | Chi tiết: $expByCat");
        final chartCategories = expByCat.entries.map((e) {
          final cat = _categoryById(e.key);
          return _ChartItem(
            name: cat?.name ?? 'Khác',
            amount: e.value,
            color: cat != null ? _parseColor(cat.colorHex) : _textSecondary,
          );
        }).toList()..sort((a, b) => b.amount.compareTo(a.amount));

        final now = DateTime.now();

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: _border, width: 1.w),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Chi tiêu tháng ${now.month}', style: _sectionTitle()),
                    const Spacer(),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        key: ValueKey(_isHidden),
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: _gold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: _gold.withOpacity(0.3),
                            width: 1.w,
                          ),
                        ),
                        child: Text(
                          _isHidden ? '••••••' : _fmt(total),
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: _gold,
                            fontWeight: FontWeight.w600,
                            letterSpacing: _isHidden ? 2 : 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),

                // Skeleton khi đang load
                if (state is TransactionLoading)
                  _buildChartSkeleton()
                else if (chartCategories.isEmpty)
                  _buildEmptyChart()
                else
                  Row(
                    children: [
                      SizedBox(
                        width: 120.w,
                        height: 120.w,
                        child: CustomPaint(
                          painter: _DonutPainter(items: chartCategories),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Tổng',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: _textSecondary,
                                  ),
                                ),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Text(
                                    _isHidden
                                        ? '•••'
                                        : _fmt(total),
                                    key: ValueKey(_isHidden),
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
                                      color: _isHidden
                                          ? _textSecondary
                                          : _textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 20.w),
                      Expanded(
                        child: Column(
                          children: chartCategories.take(5).map((item) {
                            final pct = total > 0
                                ? (item.amount / total * 100).toStringAsFixed(0)
                                : '0';
                            return Padding(
                              padding: EdgeInsets.only(bottom: 10.h),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10.w,
                                    height: 10.w,
                                    decoration: BoxDecoration(
                                      color: item.color,
                                      borderRadius: BorderRadius.circular(3.r),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      item.name,
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: _textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '$pct%',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      color: item.color,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChartSkeleton() {
    return Row(
      children: [
        _Shimmer(
          width: 120.w,
          height: 120.w,
          borderRadius: BorderRadius.circular(60.r),
        ),
        SizedBox(width: 20.w),
        Expanded(
          child: Column(
            children: List.generate(
              4,
              (i) => Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Row(
                  children: [
                    _Shimmer(
                      width: 10.w,
                      height: 10.w,
                      borderRadius: BorderRadius.circular(3.r),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: _Shimmer(
                        width: double.infinity,
                        height: 10.h,
                        borderRadius: BorderRadius.circular(5.r),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    _Shimmer(
                      width: 28.w,
                      height: 10.h,
                      borderRadius: BorderRadius.circular(5.r),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTxSkeleton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Giao dịch gần đây', style: _sectionTitle()),
              const Spacer(),
              _Shimmer(
                width: 60.w,
                height: 12.h,
                borderRadius: BorderRadius.circular(6.r),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Container(
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: _border, width: 1.w),
            ),
            child: Column(
              children: List.generate(
                4,
                (i) => Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 13.h,
                      ),
                      child: Row(
                        children: [
                          _Shimmer(
                            width: 42.w,
                            height: 42.w,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Shimmer(
                                  width: 120.w,
                                  height: 13.h,
                                  borderRadius: BorderRadius.circular(6.r),
                                ),
                                SizedBox(height: 5.h),
                                _Shimmer(
                                  width: 80.w,
                                  height: 10.h,
                                  borderRadius: BorderRadius.circular(5.r),
                                ),
                              ],
                            ),
                          ),
                          _Shimmer(
                            width: 64.w,
                            height: 13.h,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                        ],
                      ),
                    ),
                    if (i < 3) Divider(height: 1, indent: 70.w, color: _border),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart() {
    return SizedBox(
      height: 80.h,
      child: Center(
        child: Text(
          'Chưa có chi tiêu tháng này',
          style: TextStyle(fontSize: 13.sp, color: _textSecondary),
        ),
      ),
    );
  }

  // ── Transactions section ────────────────────────────────────────
  Widget _buildTransactionsSection() {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        if (state is TransactionLoading) {
          return _buildTxSkeleton();
        }
        if (state is TransactionError) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: _border, width: 1.w),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: const Color(0xFFE05555),
                    size: 18.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      state.message,
                      style: TextStyle(fontSize: 12.sp, color: _textSecondary),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        final recent = state is TransactionLoaded
            ? state.recent
            : <TransactionModel>[];
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Giao dịch gần đây', style: _sectionTitle()),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      final txBloc = context.read<TransactionBloc>();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: txBloc,
                            child: AllTransactionsScreen(
                              userId: widget.user.id,
                              categories: _allCategories,
                            ),
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'Xem tất cả',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: _gold,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              recent.isEmpty
                  ? _buildEmptyTx()
                  : Container(
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: _border, width: 1.w),
                      ),
                      child: Column(
                        children: List.generate(recent.length, (i) {
                          return _buildTxItem(
                            recent[i],
                            isLast: i == recent.length - 1,
                          );
                        }),
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTxItem(TransactionModel tx, {required bool isLast}) {
    final cat = _categoryById(tx.categoryId);
    final catName = cat?.name ?? 'Khác';
    final catColor = cat != null ? _parseColor(cat.colorHex) : _textSecondary;
    final isExpense = tx.type == TransactionType.expense;
    final isTransfer = tx.type == TransactionType.transfer;
    final amountColor = isTransfer
        ? _gold
        : isExpense
        ? const Color(0xFFE05555)
        : const Color(0xFF2ECC8A);
    final sign = isTransfer
        ? '⇄'
        : isExpense
        ? '-'
        : '+';

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            children: [
              // Category icon
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: catColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: Text(
                    cat?.icon ?? '💳',
                    style: TextStyle(fontSize: 18.sp),
                  ),
                ),
              ),
              SizedBox(width: 12.w),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.note?.isNotEmpty == true ? tx.note! : catName,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Text(
                          catName,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: _textSecondary,
                          ),
                        ),
                        Text(
                          '  ·  ${_fmtDate(tx.date)}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: _textSecondary.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Amount — ẩn/hiện
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _isHidden ? '$sign ••••••' : '$sign ${_fmt(tx.amount)}',
                  key: ValueKey('${_isHidden}_${tx.id}'),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: _isHidden ? _textSecondary : amountColor,
                    letterSpacing: _isHidden ? 2 : 0,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, indent: 70.w, color: _border),
      ],
    );
  }

  Widget _buildEmptyTx() {
    return Container(
      height: 100.h,
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: _border),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              color: _textSecondary,
              size: 28.sp,
            ),
            SizedBox(height: 8.h),
            Text(
              'Chưa có giao dịch nào',
              style: TextStyle(fontSize: 13.sp, color: _textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────
  TextStyle _sectionTitle() => TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w700,
    color: _textPrimary,
    letterSpacing: -0.2,
  );

  Widget _addBtn(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30.w,
        height: 30.w,
        decoration: BoxDecoration(
          color: _gold.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: _gold.withOpacity(0.3), width: 1.w),
        ),
        child: Icon(Icons.add_rounded, color: _gold, size: 16.sp),
      ),
    );
  }
}

// ── Chart data model nội bộ ─────────────────────────────────────────
class _ChartItem {
  final String name;
  final double amount;
  final Color color;

  const _ChartItem({
    required this.name,
    required this.amount,
    required this.color,
  });
}

// ── Donut chart painter ─────────────────────────────────────────────
class _DonutPainter extends CustomPainter {
  final List<_ChartItem> items;

  _DonutPainter({required this.items});

  @override
  void paint(Canvas canvas, Size size) {
    final total = items.fold(0.0, (s, i) => s + i.amount);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 14.0;
    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // background ring
    paint.color = const Color(0xFF2A2A38);
    canvas.drawCircle(center, radius - strokeWidth / 2, paint);

    double startAngle = -math.pi / 2;
    const gap = 0.03;

    for (final item in items) {
      final sweep = (item.amount / total) * 2 * math.pi - gap;
      paint.color = item.color;
      canvas.drawArc(
        rect,
        startAngle,
        sweep.clamp(0.01, 2 * math.pi),
        false,
        paint,
      );
      startAngle += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.items != items;
}

class _Shimmer extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const _Shimmer({
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.linear);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          gradient: LinearGradient(
            begin: Alignment(-1.5 + _anim.value * 3, 0),
            end: Alignment(-0.5 + _anim.value * 3, 0),
            colors: const [
              Color(0xFF1C1C26),
              Color(0xFF2A2A38),
              Color(0xFF1C1C26),
            ],
          ),
        ),
      ),
    );
  }
}
