import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../features/page/AIPage/AIPage.dart';
import '../../features/page/AddPage/AddPage.dart';
import '../../features/page/AnalyticsPage/AnalyticsPage.dart';
import '../../features/page/HomePage/HomePage.dart';
import '../../features/page/SettingsPage/SettingsPage.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  List<Widget> _pages = [];

  // ── Design tokens (khớp Login / Register) ─────────────────────
  static const _bg      = Color(0xFF0A0A0F);
  static const _surface = Color(0xFF13131A);
  static const _card    = Color(0xFF1C1C26);
  static const _gold    = Color(0xFFD4A843);
  static const _border  = Color(0xFF2A2A38);
  static const _inactive = Color(0xFF4A4A5A);

  // ── Nav items ──────────────────────────────────────────────────
  static const _navItems = [
    _NavMeta(iconPath: 'assets/icons/homepage.png',      label: 'Trang chủ'),
    _NavMeta(iconPath: 'assets/icons/AnalyticsPage.png', label: 'Thống kê'),
    _NavMeta(iconPath: 'assets/icons/addpage.png',       label: 'Thêm'),
    _NavMeta(iconPath: 'assets/icons/AIPage.png',        label: 'AI'),
    _NavMeta(iconPath: 'assets/icons/settingpage.png',   label: 'Cài đặt'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _loadPages();
  }

  void _loadPages() {
    setState(() {
      _pages = [
        const HomePage(),
        const AnalyticsPage(),
        const AddPage(),
        const AIPage(),
        const SettingsPage(),
      ];
    });
  }

  void _onTap(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    if (_pages.isEmpty) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: CircularProgressIndicator(color: _gold),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Bottom nav bar ─────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        border: Border(
          top: BorderSide(color: _border, width: 1.h),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64.h,
          child: Row(
            children: List.generate(
              _navItems.length,
                  (i) => Expanded(child: _NavItem(
                meta: _navItems[i],
                isSelected: _selectedIndex == i,
                onTap: () => _onTap(i),
                // Tab "Thêm" (index 2) có kiểu đặc biệt
                isSpecial: i == 2,
              )),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Single nav item ────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final _NavMeta meta;
  final bool isSelected;
  final bool isSpecial;
  final VoidCallback onTap;

  static const _gold    = Color(0xFFD4A843);
  static const _surface = Color(0xFF13131A);
  static const _card    = Color(0xFF1C1C26);
  static const _inactive = Color(0xFF4A4A5A);

  const _NavItem({
    required this.meta,
    required this.isSelected,
    required this.onTap,
    this.isSpecial = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isSpecial) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? _gold : _gold.withOpacity(0.15),
                border: Border.all(
                  color: _gold,
                  width: isSelected ? 0 : 1.5.w,
                ),
              ),
              child: Center(
                child: Image.asset(
                  meta.iconPath,
                  width: 22.w,
                  height: 22.w,
                  color: isSelected ? const Color(0xFF1A1200) : _gold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Tab thường
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon với pill background khi active
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: isSelected ? _gold.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: AnimatedScale(
              scale: isSelected ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Image.asset(
                meta.iconPath,
                width: 22.w,
                height: 22.w,
                color: isSelected ? _gold : _inactive,
              ),
            ),
          ),
          SizedBox(height: 3.h),
          // Label
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? _gold : _inactive,
              letterSpacing: 0.2,
            ),
            child: Text(meta.label),
          ),
        ],
      ),
    );
  }
}

// ── Data model ─────────────────────────────────────────────────────
class _NavMeta {
  final String iconPath;
  final String label;
  const _NavMeta({required this.iconPath, required this.label});
}