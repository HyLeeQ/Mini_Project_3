import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ManageWalletsScreen extends StatefulWidget {
  final String userId;
  const ManageWalletsScreen({super.key, required this.userId});

  @override
  State<ManageWalletsScreen> createState() => _ManageWalletsScreenState();
}

class _ManageWalletsScreenState extends State<ManageWalletsScreen> {
  // ── Luxury Design Tokens ────────────────────────────────────────
  static const _bg = Color(0xFF0A0A0F);
  static const _surface = Color(0xFF13131A);
  static const _card = Color(0xFF1C1C26);
  static const _gold = Color(0xFFD4A843);
  static const _textPrimary = Color(0xFFF2F0E8);
  static const _textSecondary = Color(0xFF7A7A8C);
  static const _border = Color(0xFF2A2A38);

  // ── Dữ liệu giả để Test giao diện (Lân thay bằng Bloc/Firebase sau) ──
  final List<Map<String, dynamic>> _dummyWallets = [
    {
      'name': 'Ví Tiền Mặt',
      'balance': 5250000.0,
      'color': Color(0xFF2ECC8A),
      'isCash': true,
    },
    {
      'name': 'Thẻ MB Bank',
      'balance': 12800000.0,
      'color': Color(0xFF4361EE),
      'isCash': false,
      'number': '8888'
    },
    {
      'name': 'Ví Momo',
      'balance': 450000.0,
      'color': Color(0xFFA50064),
      'isCash': false,
      'number': '0901'
    },
  ];

  String _fmt(double amount) {
    return amount.toInt().toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // 1. CHỨA DANH SÁCH
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(),
              _buildTotalAsset(),
              SliverToBoxAdapter(child: SizedBox(height: 24.h)),
              _buildWalletListHeader(),
              _buildWalletList(),
              SliverToBoxAdapter(child: SizedBox(height: 120.h)), // Chừa chỗ cho nút fixed
            ],
          ),

          // 2. NÚT ADD CỐ ĐỊNH (FIXED BUTTON)
          _buildAddButtonFixed(),
        ],
      ),
    );
  }

  // --- AppBar Luxury ---
  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: _bg,
      pinned: true,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: _textSecondary, size: 18.sp),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title: Text('VÍ CỦA TÔI',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: _textPrimary, letterSpacing: 1.5)),
    );
  }

  // --- Tổng tài sản (Luxury Style) ---
  Widget _buildTotalAsset() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TỔNG TÀI SẢN HIỆN CÓ',
                style: TextStyle(fontSize: 11.sp, color: _textSecondary, letterSpacing: 1)),
            SizedBox(height: 8.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('18.500.000', // BACKEND: Tổng tiền các ví cộng lại
                    style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.w900, color: _textPrimary)),
                Padding(
                  padding: EdgeInsets.only(bottom: 6.h, left: 6.w),
                  child: Text('₫', style: TextStyle(fontSize: 18.sp, color: _gold, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Header Danh sách ---
  Widget _buildWalletListHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
        child: Row(
          children: [
            Text('DANH SÁCH CHI TIẾT',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: _textSecondary)),
            const Spacer(),
            Icon(Icons.tune_rounded, color: _gold, size: 18.sp),
          ],
        ),
      ),
    );
  }

  // --- Danh sách ví ---
  Widget _buildWalletList() {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            final wallet = _dummyWallets[index];
            return _buildWalletItem(wallet);
          },
          childCount: _dummyWallets.length,
        ),
      ),
    );
  }

  // --- Item Ví (Card Design) ---
  Widget _buildWalletItem(Map<String, dynamic> wallet) {
    final Color accent = wallet['color'];
    return Container(
      height: 110.h,
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: _border, width: 1.2.w),
      ),
      child: Row(
        children: [
          // Icon ví
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(
              wallet['isCash'] ? Icons.payments_rounded : Icons.credit_card_rounded,
              color: accent,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),

          // Thông tin ví
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(wallet['name'],
                    style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: _textPrimary)),
                if (!wallet['isCash'])
                  Text('**** ${wallet['number']}',
                      style: TextStyle(fontSize: 11.sp, color: _textSecondary)),
              ],
            ),
          ),

          // Số dư
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${_fmt(wallet['balance'])}',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w800, color: _gold)),
              Text('VNĐ', style: TextStyle(fontSize: 10.sp, color: _textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  // --- Nút thêm ví (Floating Bottom) ---
  Widget _buildAddButtonFixed() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 34.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bg.withOpacity(0), _bg.withOpacity(0.9), _bg],
          ),
        ),
        child: Container(
          height: 56.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: [
              BoxShadow(color: _gold.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              // BACKEND: Navigator.push tới AddWalletScreen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: const Color(0xFF1A1200),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline_rounded, size: 20.sp),
                SizedBox(width: 10.w),
                Text('THÊM VÍ MỚI',
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}