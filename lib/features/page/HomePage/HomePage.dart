import 'dart:math' as math;
import 'package:expense_tracker/features/page/HomePage/screens/AddWalletScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../data/model/CategoryModel.dart';
import '../../../data/model/TransactionModel.dart';
import '../../../data/model/UserModel.dart';
import '../../../data/model/WalletModel.dart';

class HomePage extends StatefulWidget {
  // Truyền data từ ngoài vào — thay bằng Provider/Bloc/stream nếu dùng state management
  final UserModel? user;
  final List<WalletModel> wallets;
  final List<TransactionModel> transactions;
  final List<CategoryModel> categories;

  const HomePage({
    super.key,
    this.user,
    this.wallets = const [],
    this.transactions = const [],
    this.categories = const [],
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  // ── Design tokens ──────────────────────────────────────────────
  static const _bg            = Color(0xFF0A0A0F);
  static const _surface       = Color(0xFF13131A);
  static const _card          = Color(0xFF1C1C26);
  static const _gold          = Color(0xFFD4A843);
  static const _goldDeep      = Color(0xFF9A721C);
  static const _textPrimary   = Color(0xFFF2F0E8);
  static const _textSecondary = Color(0xFF7A7A8C);
  static const _border        = Color(0xFF2A2A38);

  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fadeAnim;

  bool _isHidden            = false;
  int  _selectedWalletIndex = 0;

  // ── Lấy 5 giao dịch gần nhất ───────────────────────────────────
  List<TransactionModel> get _recentTransactions {
    final sorted = [...widget.transactions]
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(5).toList();
  }

  // ── Tính tổng chi tiêu tháng hiện tại ──────────────────────────
  double get _totalExpenseThisMonth {
    final now = DateTime.now();
    return widget.transactions
        .where((t) =>
    t.type == TransactionType.expense &&
        t.date.month == now.month &&
        t.date.year == now.year)
        .fold(0.0, (s, t) => s + t.amount);
  }

  // ── Tính tổng balance tất cả ví ────────────────────────────────
  double get _totalBalance =>
      widget.wallets.fold(0.0, (s, w) => s + w.balance);

  // ── Nhóm chi tiêu theo category (tháng hiện tại) ───────────────
  Map<String, double> get _expenseByCategory {
    final now = DateTime.now();
    final Map<String, double> result = {};
    for (final t in widget.transactions) {
      if (t.type == TransactionType.expense &&
          t.date.month == now.month &&
          t.date.year == now.year) {
        result[t.categoryId] = (result[t.categoryId] ?? 0) + t.amount;
      }
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
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
    if (amount.abs() >= 1000000) {
      return '$sign${(amount / 1000000).toStringAsFixed(1)}M ₫';
    }
    final str = amount.abs().toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]}.',
    );
    return '${showSign && amount < 0 ? '-' : sign}$str ₫';
  }

  String _fmtDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inHours < 24) return '${diff.inHours}h trước';
    if (diff.inDays == 1) return 'Hôm qua';
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
  CategoryModel? _categoryById(String id) {
    try {
      return widget.categories.firstWhere((c) => c.id == id);
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
    final hour     = DateTime.now().hour;
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
                width: 38.w, height: 38.w,
                decoration: BoxDecoration(
                  color: _surface, shape: BoxShape.circle,
                  border: Border.all(color: _border, width: 1.w),
                ),
                child: Icon(Icons.notifications_outlined,
                    color: _textSecondary, size: 18.sp),
              ),
              SizedBox(width: 8.w),
              // Avatar
              Container(
                width: 38.w, height: 38.w,
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
                      fontSize: 13.sp, fontWeight: FontWeight.w700,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Row(
            children: [
              Text('Ví của tôi', style: _sectionTitle()),
              const Spacer(),
              // Tổng balance tất cả ví
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _isHidden ? '••••••' : _fmt(_totalBalance),
                  key: ValueKey(_isHidden),
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: _isHidden ? _textSecondary : _gold,
                    fontWeight: FontWeight.w600,
                    letterSpacing: _isHidden ? 2 : 0,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              _addBtn(() {
                Navigator.push(context, PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const AddWalletScreen(),
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
              }),
            ],
          ),
        ),
        SizedBox(height: 14.h),
        SizedBox(
          height: 160.h,
          child: widget.wallets.isEmpty
              ? _buildEmptyWallet()
              : ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            itemCount: widget.wallets.length + 1,
            itemBuilder: (_, i) {
              if (i == widget.wallets.length) return _buildAddCardBtn();
              return _buildWalletCard(widget.wallets[i], i);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWalletCard(WalletModel wallet, int index) {
    final isSelected  = _selectedWalletIndex == index;
    final accentColor = _parseColor(wallet.colorHex, fallback: _gold);

    // Xác định là tiền mặt hay thẻ ngân hàng dựa vào icon field
    final isCash = wallet.icon == 'cash' ||
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
              top: -20.h, right: -20.w,
              child: Container(
                width: 100.w, height: 100.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -30.h, left: -10.w,
              child: Container(
                width: 80.w, height: 80.w,
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
                        width: 32.w, height: 32.w,
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
                            fontSize: 12.sp, color: _textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                        Container(
                          width: 6.w, height: 6.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle, color: accentColor,
                          ),
                        ),
                    ],
                  ),

                  const Spacer(),

                  // Balance label
                  Text('Số dư',
                      style: TextStyle(fontSize: 11.sp, color: _textSecondary)),
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
                            ? '**** **** **** ••••'
                            : '**** **** **** ****',
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
      onTap: () {},
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
              width: 36.w, height: 36.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _gold.withOpacity(0.12),
                border: Border.all(color: _gold.withOpacity(0.3), width: 1.w),
              ),
              child: Icon(Icons.add_rounded, color: _gold, size: 18.sp),
            ),
            SizedBox(height: 8.h),
            Text('Thêm ví',
                style: TextStyle(fontSize: 12.sp, color: _gold, fontWeight: FontWeight.w500)),
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
              Icon(Icons.account_balance_wallet_outlined,
                  color: _textSecondary, size: 28.sp),
              SizedBox(height: 8.h),
              Text('Chưa có ví nào',
                  style: TextStyle(fontSize: 13.sp, color: _textSecondary)),
              SizedBox(height: 4.h),
              Text('Nhấn + để thêm ví',
                  style: TextStyle(
                      fontSize: 12.sp, color: _gold, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Chart section ───────────────────────────────────────────────
  Widget _buildChartSection() {
    final expByCat = _expenseByCategory;
    final total    = _totalExpenseThisMonth;

    // Chỉ lấy các category có chi tiêu
    final chartCategories = expByCat.entries.map((e) {
      final cat = _categoryById(e.key);
      return _ChartItem(
        name:   cat?.name ?? 'Khác',
        amount: e.value,
        color:  cat != null ? _parseColor(cat.colorHex) : _textSecondary,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

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
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: _gold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: _gold.withOpacity(0.3), width: 1.w),
                    ),
                    child: Text(
                      _isHidden ? '••••••' : _fmt(total),
                      style: TextStyle(
                        fontSize: 11.sp, color: _gold, fontWeight: FontWeight.w600,
                        letterSpacing: _isHidden ? 2 : 0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            chartCategories.isEmpty
                ? _buildEmptyChart()
                : Row(
              children: [
                // Donut chart
                SizedBox(
                  width: 120.w,
                  height: 120.w,
                  child: CustomPaint(
                    painter: _DonutPainter(items: chartCategories),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Tổng',
                              style: TextStyle(
                                  fontSize: 10.sp, color: _textSecondary)),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              _isHidden
                                  ? '•••'
                                  : '${(total / 1000000).toStringAsFixed(1)}M',
                              key: ValueKey(_isHidden),
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: _isHidden
                                    ? _textSecondary
                                    : _textPrimary,
                                letterSpacing: _isHidden ? 2 : 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 20.w),

                // Legend — tối đa 5 items
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
                              width: 10.w, height: 10.w,
                              decoration: BoxDecoration(
                                color: item.color,
                                borderRadius: BorderRadius.circular(3.r),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(item.name,
                                  style: TextStyle(
                                      fontSize: 12.sp,
                                      color: _textSecondary),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            Text('$pct%',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: item.color,
                                )),
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
  }

  Widget _buildEmptyChart() {
    return SizedBox(
      height: 80.h,
      child: Center(
        child: Text('Chưa có chi tiêu tháng này',
            style: TextStyle(fontSize: 13.sp, color: _textSecondary)),
      ),
    );
  }

  // ── Transactions section ────────────────────────────────────────
  Widget _buildTransactionsSection() {
    final recent = _recentTransactions;

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
                onTap: () {},
                child: Text('Xem tất cả',
                    style: TextStyle(
                        fontSize: 13.sp, color: _gold, fontWeight: FontWeight.w500)),
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
  }

  Widget _buildTxItem(TransactionModel tx, {required bool isLast}) {
    final cat         = _categoryById(tx.categoryId);
    final catName     = cat?.name ?? 'Khác';
    final catColor    = cat != null ? _parseColor(cat.colorHex) : _textSecondary;
    final isExpense   = tx.type == TransactionType.expense;
    final isTransfer  = tx.type == TransactionType.transfer;
    final amountColor = isTransfer
        ? _gold
        : isExpense
        ? const Color(0xFFE05555)
        : const Color(0xFF2ECC8A);
    final sign        = isTransfer ? '⇄' : isExpense ? '-' : '+';

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            children: [
              // Category icon
              Container(
                width: 42.w, height: 42.w,
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
                        fontSize: 14.sp, fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Text(catName,
                            style: TextStyle(
                                fontSize: 11.sp, color: _textSecondary)),
                        Text(
                          '  ·  ${_fmtDate(tx.date)}',
                          style: TextStyle(
                              fontSize: 11.sp,
                              color: _textSecondary.withOpacity(0.6)),
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
                    fontSize: 14.sp, fontWeight: FontWeight.w700,
                    color: _isHidden ? _textSecondary : amountColor,
                    letterSpacing: _isHidden ? 2 : 0,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, indent: 70.w, color: _border),
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
            Icon(Icons.receipt_long_outlined,
                color: _textSecondary, size: 28.sp),
            SizedBox(height: 8.h),
            Text('Chưa có giao dịch nào',
                style: TextStyle(fontSize: 13.sp, color: _textSecondary)),
          ],
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────
  TextStyle _sectionTitle() => TextStyle(
    fontSize: 16.sp, fontWeight: FontWeight.w700,
    color: _textPrimary, letterSpacing: -0.2,
  );

  Widget _addBtn(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30.w, height: 30.w,
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
  final Color  color;
  const _ChartItem({required this.name, required this.amount, required this.color});
}

// ── Donut chart painter ─────────────────────────────────────────────
class _DonutPainter extends CustomPainter {
  final List<_ChartItem> items;
  _DonutPainter({required this.items});

  @override
  void paint(Canvas canvas, Size size) {
    final total  = items.fold(0.0, (s, i) => s + i.amount);
    if (total == 0) return;

    final center      = Offset(size.width / 2, size.height / 2);
    final radius      = size.width / 2;
    const strokeWidth = 14.0;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    final paint = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap   = StrokeCap.butt;

    // background ring
    paint.color = const Color(0xFF2A2A38);
    canvas.drawCircle(center, radius - strokeWidth / 2, paint);

    double startAngle = -math.pi / 2;
    const gap         = 0.03;

    for (final item in items) {
      final sweep = (item.amount / total) * 2 * math.pi - gap;
      paint.color = item.color;
      canvas.drawArc(rect, startAngle, sweep.clamp(0.01, 2 * math.pi), false, paint);
      startAngle += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.items != items;
}