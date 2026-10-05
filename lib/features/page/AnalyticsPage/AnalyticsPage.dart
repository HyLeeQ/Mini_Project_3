import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../data/model/CategoryModel.dart';
import '../../../data/model/TransactionModel.dart';
import '../HomePage/bloc/transaction_bloc/transaction_state.dart';
import '../HomePage/bloc/transaction_bloc/transaction_bloc.dart';
import 'CanvasChartsPage.dart';

// import 'package:your_app/data/model/TransactionModel.dart';
// import 'package:your_app/data/model/CategoryModel.dart';
// import 'package:your_app/data/model/WalletModel.dart';

// ── Stub models (xoá khi import thật) ─────────────────────────────

class AnalyticsPage extends StatefulWidget {
  final List<TransactionModel> transactions;
  final List<CategoryModel> categories;

  const AnalyticsPage({
    super.key,
    this.transactions = const [],
    this.categories = const [],
  });

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage>
    with SingleTickerProviderStateMixin {
  // ── Design tokens ──────────────────────────────────────────────
  static const _bg = Color(0xFF0A0A0F);
  static const _surface = Color(0xFF13131A);
  static const _card = Color(0xFF1C1C26);
  static const _gold = Color(0xFFD4A843);
  static const _goldDeep = Color(0xFF9A721C);
  static const _goldLight = Color(0xFFF5D07A);
  static const _green = Color(0xFF2ECC8A);
  static const _red = Color(0xFFE05555);
  static const _textPrimary = Color(0xFFF2F0E8);
  static const _textSecondary = Color(0xFF7A7A8C);
  static const _border = Color(0xFF2A2A38);

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  // ── Period selector ────────────────────────────────────────────
  int _selectedPeriod = 1; // 0=week 1=month 2=year
  static const _periods = ['Tuần', 'Tháng', 'Năm'];

  // ── Bar chart selector ─────────────────────────────────────────
  int _selectedBarIndex = 0;

  List<TransactionModel> listTran = [];

  @override
  void initState() {
    super.initState();
    _sourceTransactions;
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── Computed values ────────────────────────────────────────────
  void get _sourceTransactions {
    final state = context.read<TransactionBloc>().state;
    if (state is TransactionLoaded) listTran = state.transactions;
    listTran = widget.transactions;
  }

  List<TransactionModel> get _filtered {
    final now = DateTime.now();
    return listTran.where((t) {
      switch (_selectedPeriod) {
        case 0: // week
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          final weekEnd = weekStart.add(const Duration(days: 7));
          return !t.date.isBefore(weekStart) && t.date.isBefore(weekEnd);
        case 1: // month
          return t.date.month == now.month && t.date.year == now.year;
        case 2: // year
          return t.date.year == now.year;
        default:
          return true;
      }
    }).toList();
  }

  double get _totalIncome => _filtered
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (s, t) => s + t.amount);

  double get _totalExpense => _filtered
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (s, t) => s + t.amount);

  double get _netBalance => _totalIncome - _totalExpense;

  double get _savingRate =>
      _totalIncome > 0 ? (_netBalance / _totalIncome * 100) : 0;

  // ── Category breakdown ─────────────────────────────────────────
  List<_CatStat> get _categoryStats {
    final Map<String, double> map = {};
    for (final t in _filtered.where((t) => t.type == TransactionType.expense)) {
      map[t.categoryId] = (map[t.categoryId] ?? 0) + t.amount;
    }
    return map.entries.map((e) {
      final cat = _catById(e.key);
      return _CatStat(
        name: cat?.name ?? 'Khác',
        icon: cat?.icon ?? '📌',
        amount: e.value,
        color: _parseColor(cat?.colorHex ?? '#7A7A8C'),
      );
    }).toList()..sort((a, b) => b.amount.compareTo(a.amount));
  }

  List<_BarData> get _weekBars {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    const labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return List.generate(7, (i) {
      final dayStart = DateTime(
        weekStart.year,
        weekStart.month,
        weekStart.day + i,
      );
      final dayEnd = dayStart.add(const Duration(days: 1));
      final inc = listTran
          .where(
            (t) =>
                t.type == TransactionType.income &&
                !t.date.isBefore(dayStart) &&
                t.date.isBefore(dayEnd),
          )
          .fold(0.0, (s, t) => s + t.amount);
      final exp = listTran
          .where(
            (t) =>
                t.type == TransactionType.expense &&
                !t.date.isBefore(dayStart) &&
                t.date.isBefore(dayEnd),
          )
          .fold(0.0, (s, t) => s + t.amount);
      return _BarData(label: labels[i], income: inc, expense: exp);
    });
  }

  List<_BarData> get _monthBars {
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    final daysInMonth = nextMonth.subtract(const Duration(days: 1)).day;
    final weeks = (daysInMonth / 7).ceil();
    return List.generate(weeks, (i) {
      final dayFrom = 1 + i * 7;
      final dayTo = math.min(daysInMonth, dayFrom + 6);
      final rangeStart = DateTime(now.year, now.month, dayFrom);
      final rangeEnd = DateTime(now.year, now.month, dayTo + 1);
      final inc = listTran
          .where(
            (t) =>
                t.type == TransactionType.income &&
                !t.date.isBefore(rangeStart) &&
                t.date.isBefore(rangeEnd),
          )
          .fold(0.0, (s, t) => s + t.amount);
      final exp = listTran
          .where(
            (t) =>
                t.type == TransactionType.expense &&
                !t.date.isBefore(rangeStart) &&
                t.date.isBefore(rangeEnd),
          )
          .fold(0.0, (s, t) => s + t.amount);
      return _BarData(label: 'Tuần ${i + 1}', income: inc, expense: exp);
    });
  }

  List<_BarData> get _yearBars {
    final now = DateTime.now();
    return List.generate(12, (i) {
      final month = i + 1;
      final inc = listTran
          .where(
            (t) =>
                t.type == TransactionType.income &&
                t.date.month == month &&
                t.date.year == now.year,
          )
          .fold(0.0, (s, t) => s + t.amount);
      final exp = listTran
          .where(
            (t) =>
                t.type == TransactionType.expense &&
                t.date.month == month &&
                t.date.year == now.year,
          )
          .fold(0.0, (s, t) => s + t.amount);
      return _BarData(label: 'T$month', income: inc, expense: exp);
    });
  }

  List<_BarData> get _barData {
    switch (_selectedPeriod) {
      case 0:
        return _weekBars;
      case 1:
        return _monthBars;
      default:
        return _yearBars;
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────
  CategoryModel? _catById(String id) {
    try {
      return widget.categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return _textSecondary;
    }
  }

  String _fmt(double v) {
    return v
        .abs()
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
  }

  String _fmtFull(double v) {
    return '${v.abs().toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')} ₫';
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
              SliverToBoxAdapter(child: _buildPeriodSelector()),
              SliverToBoxAdapter(child: SizedBox(height: 20.h)),
              SliverToBoxAdapter(child: _buildSummaryCards()),
              SliverToBoxAdapter(child: SizedBox(height: 20.h)),
              SliverToBoxAdapter(child: _buildBarChartSection()),
              SliverToBoxAdapter(child: SizedBox(height: 20.h)),
              SliverToBoxAdapter(child: _buildDonutSection()),
              SliverToBoxAdapter(child: SizedBox(height: 20.h)),
              SliverToBoxAdapter(child: _buildCategoryList()),
              SliverToBoxAdapter(child: SizedBox(height: 24.h)),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thống kê',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Tổng quan tài chính',
                style: TextStyle(fontSize: 13.sp, color: _textSecondary),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Biểu đồ canvas',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => CanvasChartsPage(transactions: listTran, categories: widget.categories),
            )),
            icon: const Icon(Icons.show_chart_rounded, color: _gold),
          ),
          // Year badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: _gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: _gold.withOpacity(0.3), width: 1.w),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, color: _gold, size: 12.sp),
                SizedBox(width: 5.w),
                Text(
                  '${DateTime.now().year}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: _gold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Period selector ─────────────────────────────────────────────
  Widget _buildPeriodSelector() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: _border, width: 1.w),
        ),
        child: Row(
          children: List.generate(_periods.length, (i) {
            final isSelected = _selectedPeriod == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedPeriod = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: 38.h,
                  decoration: BoxDecoration(
                    color: isSelected ? _gold : Colors.transparent,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Center(
                    child: Text(
                      _periods[i],
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: isSelected
                            ? const Color(0xFF1A1200)
                            : _textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── Summary cards: Thu | Chi | Tiết kiệm ───────────────────────
  Widget _buildSummaryCards() {
    final rate = _savingRate;
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        final listTransaction = state is TransactionLoaded ? state.transactions : <TransactionModel>[];
        if(listTransaction.isNotEmpty){
          listTran = listTransaction;

        }
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            children: [
              // Net balance card — full width
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  gradient: LinearGradient(
                    colors: [
                      _netBalance >= 0
                          ? const Color(0xFF0F2A1E)
                          : const Color(0xFF2A0F0F),
                      _netBalance >= 0
                          ? const Color(0xFF081A10)
                          : const Color(0xFF1A0808),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: (_netBalance >= 0 ? _green : _red).withOpacity(0.3),
                    width: 1.w,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -20.h,
                      right: -20.w,
                      child: Container(
                        width: 100.w,
                        height: 100.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (_netBalance >= 0 ? _green : _red).withOpacity(
                            0.06,
                          ),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Cân đối',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: _textSecondary,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 3.h,
                              ),
                              decoration: BoxDecoration(
                                color: (_netBalance >= 0 ? _green : _red)
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                _netBalance >= 0 ? '↑ Dư' : '↓ Âm',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: _netBalance >= 0 ? _green : _red,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          '${_netBalance >= 0 ? '+' : ''}${_fmtFull(_netBalance)}',
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.w800,
                            color: _netBalance >= 0 ? _green : _red,
                            letterSpacing: -0.8,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        // Saving rate bar
                        Row(
                          children: [
                            Text(
                              'Tỉ lệ tiết kiệm',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: _textSecondary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${rate.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: rate >= 0 ? _green : _red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4.r),
                          child: LinearProgressIndicator(
                            value: (rate / 100).clamp(0.0, 1.0),
                            minHeight: 5.h,
                            backgroundColor: _border,
                            valueColor: AlwaysStoppedAnimation(
                              rate >= 0 ? _green : _red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12.h),

              // Income + Expense row
              Row(
                children: [
                  Expanded(
                    child: _buildMiniCard(
                      label: 'Thu nhập',
                      value: _totalIncome,
                      color: _green,
                      icon: Icons.trending_up_rounded,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildMiniCard(
                      label: 'Chi tiêu',
                      value: _totalExpense,
                      color: _red,
                      icon: Icons.trending_down_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

      },
    );
  }

  Widget _buildMiniCard({
    required String label,
    required double value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: _border, width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30.w,
                height: 30.w,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, color: color, size: 15.sp),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_outward_rounded,
                color: _textSecondary.withOpacity(0.4),
                size: 14.sp,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            label,
            style: TextStyle(fontSize: 11.sp, color: _textSecondary),
          ),
          SizedBox(height: 4.h),
          Text(
            _fmtFull(value),
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bar chart: Thu/Chi 12 tháng ────────────────────────────────
  String get _barTitle {
    switch (_selectedPeriod) {
      case 0:
        return 'Thu & Chi theo tuần';
      case 1:
        return 'Thu & Chi theo tháng';
      default:
        return 'Thu & Chi theo năm';
    }
  }

  Widget _buildBarChartSection() {
    final bars = _barData;
    if (_selectedBarIndex >= bars.length) _selectedBarIndex = bars.length - 1;
    if (_selectedBarIndex < 0) _selectedBarIndex = 0;
    final maxVal = bars.fold(
      0.0,
      (m, b) => math.max(m, math.max(b.income, b.expense)),
    );

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
            // Header
            Row(
              children: [
                Text(
                  _barTitle,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const Spacer(),
                // Legend
                _legend(_green, 'Thu'),
                SizedBox(width: 12.w),
                _legend(_red, 'Chi'),
              ],
            ),
            SizedBox(height: 20.h),

            // Bar chart
            SizedBox(
              height: 160.h,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(bars.length, (i) {
                  final bar = bars[i];
                  final isActive = _selectedBarIndex == i;
                  final incH = maxVal > 0 ? (bar.income / maxVal) * 130.h : 0.0;
                  final expH = maxVal > 0
                      ? (bar.expense / maxVal) * 130.h
                      : 0.0;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedBarIndex = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(horizontal: 2.w),
                        decoration: BoxDecoration(
                          color: isActive
                              ? _gold.withOpacity(0.06)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Tooltip khi active
                            if (isActive &&
                                _selectedPeriod == 2 &&
                                (bar.income > 0 || bar.expense > 0))
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4.w,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color: _gold.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Text(
                                  _fmt(math.max(bar.income, bar.expense)),
                                  style: TextStyle(
                                    fontSize: 8.sp,
                                    color: _gold,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            SizedBox(height: 3.h),

                            // Bars side by side
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Income bar
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeOut,
                                  width: 5.w,
                                  height: incH == 0 ? 2.h : incH,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? _green
                                        : _green.withOpacity(0.5),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(3.r),
                                      topRight: Radius.circular(3.r),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 2.w),
                                // Expense bar
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeOut,
                                  width: 5.w,
                                  height: expH == 0 ? 2.h : expH,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? _red
                                        : _red.withOpacity(0.5),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(3.r),
                                      topRight: Radius.circular(3.r),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              bar.label,
                              style: TextStyle(
                                fontSize: 9.sp,
                                color: isActive ? _gold : _textSecondary,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Selected month detail
            if (bars.isNotEmpty) ...[
              SizedBox(height: 14.h),
              Divider(color: _border, height: 1),
              SizedBox(height: 14.h),
              _buildPeriodDetail(bars[_selectedBarIndex]),
            ],
          ],
        ),
      ),
    );
  }

  String _selectedBarLabel(_BarData bar) {
    if (_selectedPeriod == 2) {
      return 'Tháng ${_selectedBarIndex + 1}';
    }
    return bar.label;
  }

  Widget _buildPeriodDetail(_BarData bar) {
    return Row(
      children: [
        Text(
          _selectedBarLabel(bar),
          style: TextStyle(
            fontSize: 12.sp,
            color: _textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        _tag(_green, '+${_fmtFull(bar.income)}'),
        SizedBox(width: 8.w),
        _tag(_red, '-${_fmtFull(bar.expense)}'),
      ],
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        SizedBox(width: 4.w),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: _textSecondary),
        ),
      ],
    );
  }

  Widget _tag(Color color, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.sp,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── Donut chart ─────────────────────────────────────────────────
  Widget _buildDonutSection() {
    final stats = _categoryStats;
    final total = stats.fold(0.0, (s, c) => s + c.amount);

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
                Text(
                  'Phân bổ chi tiêu',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: _gold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: _gold.withOpacity(0.3),
                      width: 1.w,
                    ),
                  ),
                  child: Text(
                    _fmtFull(total),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: _gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),

            stats.isEmpty
                ? _buildEmptyState('Chưa có dữ liệu chi tiêu')
                : Row(
                    children: [
                      // Donut
                      SizedBox(
                        width: 130.w,
                        height: 130.w,
                        child: CustomPaint(
                          painter: _DonutPainter(stats: stats),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Chi tiêu',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: _textSecondary,
                                  ),
                                ),
                                Text(
                                  _fmt(total),
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w800,
                                    color: _textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                Text(
                                  '₫',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: _gold,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 20.w),
                      // Legend
                      Expanded(
                        child: Column(
                          children: stats.take(5).map((s) {
                            final pct = total > 0
                                ? (s.amount / total * 100).toStringAsFixed(1)
                                : '0';
                            return Padding(
                              padding: EdgeInsets.only(bottom: 11.h),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10.w,
                                    height: 10.w,
                                    decoration: BoxDecoration(
                                      color: s.color,
                                      borderRadius: BorderRadius.circular(3.r),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    s.icon,
                                    style: TextStyle(fontSize: 12.sp),
                                  ),
                                  SizedBox(width: 4.w),
                                  Expanded(
                                    child: Text(
                                      s.name,
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: _textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '$pct%',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: s.color,
                                      fontWeight: FontWeight.w700,
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
  }

  // ── Category list ────────────────────────────────────────────────
  Widget _buildCategoryList() {
    final stats = _categoryStats;
    final total = stats.fold(0.0, (s, c) => s + c.amount);
    if (stats.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chi tiết danh mục',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          SizedBox(height: 14.h),
          Container(
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: _border, width: 1.w),
            ),
            child: Column(
              children: List.generate(stats.length, (i) {
                final s = stats[i];
                final pct = total > 0 ? s.amount / total : 0.0;
                return Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // Icon
                              Container(
                                width: 40.w,
                                height: 40.w,
                                decoration: BoxDecoration(
                                  color: s.color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(11.r),
                                ),
                                child: Center(
                                  child: Text(
                                    s.icon,
                                    style: TextStyle(fontSize: 18.sp),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            s.name,
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w600,
                                              color: _textPrimary,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _fmtFull(s.amount),
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w700,
                                            color: _textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8.h),
                                    // Progress bar
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(3.r),
                                      child: LinearProgressIndicator(
                                        value: pct,
                                        minHeight: 4.h,
                                        backgroundColor: _border,
                                        valueColor: AlwaysStoppedAnimation(
                                          s.color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${(pct * 100).toStringAsFixed(1)}% tổng chi tiêu',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: s.color.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i < stats.length - 1)
                      Divider(height: 1, indent: 68.w, color: _border),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return SizedBox(
      height: 80.h,
      child: Center(
        child: Text(
          msg,
          style: TextStyle(fontSize: 13.sp, color: _textSecondary),
        ),
      ),
    );
  }
}

// ── Data models ─────────────────────────────────────────────────────
class _CatStat {
  final String name, icon;
  final double amount;
  final Color color;

  const _CatStat({
    required this.name,
    required this.icon,
    required this.amount,
    required this.color,
  });
}

class _BarData {
  final String label;
  final double income, expense;

  const _BarData({
    required this.label,
    required this.income,
    required this.expense,
  });
}

// ── Donut chart painter ─────────────────────────────────────────────
class _DonutPainter extends CustomPainter {
  final List<_CatStat> stats;

  _DonutPainter({required this.stats});

  @override
  void paint(Canvas canvas, Size size) {
    final total = stats.fold(0.0, (s, c) => s + c.amount);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    const strokeWidth = 16.0;
    final radius = size.width / 2 - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = const Color(0xFF2A2A38);
    canvas.drawCircle(center, radius, bgPaint);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    double startAngle = -math.pi / 2;
    const gap = 0.04;

    for (final s in stats) {
      final sweep = (s.amount / total) * 2 * math.pi - gap;
      if (sweep <= 0) continue;
      paint.color = s.color;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.stats != stats;
}
