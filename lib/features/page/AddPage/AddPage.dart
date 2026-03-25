import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// import 'package:your_app/data/model/TransactionModel.dart';
// import 'package:your_app/data/model/CategoryModel.dart';
// import 'package:your_app/data/model/WalletModel.dart';

// ── Stub models (xoá khi import thật) ─────────────────────────────
enum TransactionType { income, expense, transfer }
enum CategoryType    { income, expense }

class CategoryModel {
  final String id, name, icon, colorHex;
  final CategoryType type;
  const CategoryModel({required this.id, required this.name,
    required this.icon, required this.colorHex, required this.type});
}

class WalletModel {
  final String id, name, icon, colorHex;
  final double balance;
  const WalletModel({required this.id, required this.name,
    required this.icon, required this.colorHex, required this.balance});
}
// ──────────────────────────────────────────────────────────────────

class AddPage extends StatefulWidget {
  final List<CategoryModel> categories;
  final List<WalletModel>   wallets;

  const AddPage({
    super.key,
    this.categories = const [],
    this.wallets    = const [],
  });

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> with TickerProviderStateMixin {
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
  static const _textPrimary   = Color(0xFFF2F0E8);
  static const _textSecondary = Color(0xFF7A7A8C);
  static const _border        = Color(0xFF2A2A38);

  // ── Controllers ────────────────────────────────────────────────
  final _amountCtrl = TextEditingController();
  final _noteCtrl   = TextEditingController();
  final _formKey    = GlobalKey<FormState>();

  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fadeAnim;
  late final AnimationController _scanCtrl;   // scanning line animation
  late final Animation<double>   _scanAnim;
  late final AnimationController _pulseCtrl;  // AI button pulse
  late final Animation<double>   _pulseAnim;

  // ── State ──────────────────────────────────────────────────────
  TransactionType  _txType         = TransactionType.expense;
  CategoryModel?   _selectedCat;
  WalletModel?     _selectedWallet;
  DateTime         _selectedDate   = DateTime.now();
  bool             _isLoading      = false;
  bool             _showAIScanner  = false; // toggle camera section
  bool             _isScanning     = false; // AI scanning animation

  // ── Sample data (thay bằng data từ Firestore/Provider) ─────────
  final List<CategoryModel> _sampleCats = [
    const CategoryModel(id:'1', name:'Ăn uống',   icon:'🍔', colorHex:'#E05555', type: CategoryType.expense),
    const CategoryModel(id:'2', name:'Shopping',  icon:'🛍️', colorHex:'#D4A843', type: CategoryType.expense),
    const CategoryModel(id:'3', name:'Di chuyển', icon:'🚗', colorHex:'#5B8CFF', type: CategoryType.expense),
    const CategoryModel(id:'4', name:'Sức khỏe',  icon:'💊', colorHex:'#2ECC8A', type: CategoryType.expense),
    const CategoryModel(id:'5', name:'Giải trí',  icon:'🎬', colorHex:'#B05BFF', type: CategoryType.expense),
    const CategoryModel(id:'6', name:'Nhà ở',     icon:'🏠', colorHex:'#FF8C42', type: CategoryType.expense),
    const CategoryModel(id:'7', name:'Lương',     icon:'💰', colorHex:'#2ECC8A', type: CategoryType.income),
    const CategoryModel(id:'8', name:'Thưởng',    icon:'🎁', colorHex:'#D4A843', type: CategoryType.income),
  ];

  final List<WalletModel> _sampleWallets = [
    const WalletModel(id:'1', name:'Tiền mặt',   icon:'💵', colorHex:'#2ECC8A', balance: 2500000),
    const WalletModel(id:'2', name:'Vietcombank', icon:'💳', colorHex:'#D4A843', balance: 15750000),
  ];

  List<CategoryModel> get _filteredCats {
    final cats = widget.categories.isNotEmpty ? widget.categories : _sampleCats;
    return cats.where((c) {
      if (_txType == TransactionType.income)   return c.type == CategoryType.income;
      if (_txType == TransactionType.expense)  return c.type == CategoryType.expense;
      return true;
    }).toList();
  }

  List<WalletModel> get _wallets =>
      widget.wallets.isNotEmpty ? widget.wallets : _sampleWallets;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _fadeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    // Scanning line animation
    _scanCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800),
    );
    _scanAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut),
    );

    // AI button pulse
    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Default wallet
    if (_wallets.isNotEmpty) _selectedWallet = _wallets.first;
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _scanCtrl.dispose();
    _pulseCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────
  Color _parseColor(String hex) {
    try { return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16)); }
    catch (_) { return _textSecondary; }
  }

  Color get _txColor {
    switch (_txType) {
      case TransactionType.income:   return _green;
      case TransactionType.expense:  return _red;
      case TransactionType.transfer: return _blue;
    }
  }

  void _startAIScan() {
    setState(() => _isScanning = true);
    _scanCtrl.repeat(reverse: true);
    // TODO: gọi camera + AI nhận diện ở đây
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      _scanCtrl.stop();
      setState(() {
        _isScanning = false;
        // TODO: set data từ AI trả về
        _amountCtrl.text = '85.000';
        _selectedCat = _filteredCats.isNotEmpty ? _filteredCats.first : null;
        _noteCtrl.text = 'Grab Food - AI nhận diện';
      });
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _gold,
            surface: Color(0xFF1C1C26),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  String _formatDate(DateTime d) {
    if (d.day == DateTime.now().day &&
        d.month == DateTime.now().month &&
        d.year == DateTime.now().year) return 'Hôm nay';
    return '${d.day}/${d.month}/${d.year}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _isLoading = false);
    // TODO: lưu TransactionModel vào Firestore
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã lưu giao dịch!',
            style: TextStyle(color: _textPrimary, fontSize: 13.sp)),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      ),
    );
    _amountCtrl.clear();
    _noteCtrl.clear();
    setState(() => _selectedCat = null);
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
              SliverToBoxAdapter(child: _buildTypeSelector()),
              SliverToBoxAdapter(child: SizedBox(height: 20.h)),
              SliverToBoxAdapter(child: _buildAmountSection()),
              SliverToBoxAdapter(child: SizedBox(height: 16.h)),
              // AI Scanner toggle
              SliverToBoxAdapter(child: _buildAIButton()),
              // AI Scanner panel
              if (_showAIScanner) ...[
                SliverToBoxAdapter(child: SizedBox(height: 16.h)),
                SliverToBoxAdapter(child: _buildAIScannerPanel()),
              ],
              SliverToBoxAdapter(child: SizedBox(height: 20.h)),
              SliverToBoxAdapter(child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildCategorySection(),
                    SizedBox(height: 16.h),
                    _buildWalletSection(),
                    SizedBox(height: 16.h),
                    _buildDateSection(),
                    SizedBox(height: 16.h),
                    _buildNoteSection(),
                  ],
                ),
              )),
              SliverToBoxAdapter(child: SizedBox(height: 24.h)),
              SliverToBoxAdapter(child: _buildSaveButton()),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Thêm giao dịch',
                  style: TextStyle(
                    fontSize: 22.sp, fontWeight: FontWeight.w800,
                    color: _textPrimary, letterSpacing: -0.5,
                  )),
              Text('Nhập thủ công hoặc dùng AI',
                  style: TextStyle(fontSize: 12.sp, color: _textSecondary)),
            ],
          ),
          const Spacer(),
          // Date chip
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: _border, width: 1.w),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      color: _gold, size: 13.sp),
                  SizedBox(width: 5.w),
                  Text(_formatDate(_selectedDate),
                      style: TextStyle(
                        fontSize: 12.sp, color: _textPrimary,
                        fontWeight: FontWeight.w500,
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Transaction type: Thu | Chi | Chuyển ───────────────────────
  Widget _buildTypeSelector() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: _border, width: 1.w),
        ),
        child: Row(
          children: [
            _typeTab(TransactionType.income,   '↑', 'Thu nhập', _green),
            SizedBox(width: 4.w),
            _typeTab(TransactionType.expense,  '↓', 'Chi tiêu',  _red),
            SizedBox(width: 4.w),
            _typeTab(TransactionType.transfer, '⇄', 'Chuyển',   _blue),
          ],
        ),
      ),
    );
  }

  Widget _typeTab(TransactionType type, String arrow, String label, Color color) {
    final isSelected = _txType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _txType       = type;
          _selectedCat  = null;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 44.h,
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected ? color.withOpacity(0.45) : Colors.transparent,
              width: 1.w,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(arrow,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: isSelected ? color : _textSecondary,
                    fontWeight: FontWeight.w700,
                  )),
              SizedBox(width: 5.w),
              Text(label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isSelected ? color : _textSecondary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ── Amount input — big & bold ────────────────────────────────────
  Widget _buildAmountSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _txColor.withOpacity(0.08),
              _txColor.withOpacity(0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: _txColor.withOpacity(0.25), width: 1.5.w),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Số tiền',
                style: TextStyle(fontSize: 12.sp, color: _textSecondary)),
            SizedBox(height: 8.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 32.sp, fontWeight: FontWeight.w800,
                    color: _txColor, letterSpacing: -1,
                  ),
                  child: Text(_txType == TransactionType.income ? '+' : '-'),
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _VndFormatter(),
                    ],
                    style: TextStyle(
                      fontSize: 32.sp, fontWeight: FontWeight.w800,
                      color: _textPrimary, letterSpacing: -1,
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(
                        fontSize: 32.sp, fontWeight: FontWeight.w800,
                        color: _textSecondary.withOpacity(0.3),
                        letterSpacing: -1,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                Text('₫',
                    style: TextStyle(
                      fontSize: 20.sp, color: _txColor,
                      fontWeight: FontWeight.w700,
                    )),
              ],
            ),
            SizedBox(height: 12.h),
            // Quick amount chips
            Wrap(
              spacing: 8.w,
              children: [50000, 100000, 200000, 500000].map((v) {
                return GestureDetector(
                  onTap: () => setState(() {
                    _amountCtrl.text = _VndFormatter.format(v);
                  }),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 12.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: _txColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                          color: _txColor.withOpacity(0.25), width: 1.w),
                    ),
                    child: Text(
                      v >= 1000 ? '${v ~/ 1000}K' : '$v',
                      style: TextStyle(
                        fontSize: 12.sp, color: _txColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ── AI Scanner button ────────────────────────────────────────────
  Widget _buildAIButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: GestureDetector(
        onTap: () => setState(() => _showAIScanner = !_showAIScanner),
        child: AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, child) => Transform.scale(
            scale: _showAIScanner ? 1.0 : _pulseAnim.value,
            child: child,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 54.h,
            decoration: BoxDecoration(
              gradient: _showAIScanner
                  ? LinearGradient(colors: [
                _gold.withOpacity(0.2),
                _goldDeep.withOpacity(0.15),
              ])
                  : LinearGradient(colors: [
                _surface,
                _card,
              ]),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: _showAIScanner
                    ? _gold.withOpacity(0.5)
                    : _gold.withOpacity(0.3),
                width: _showAIScanner ? 1.5.w : 1.w,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // AI sparkle icon
                Container(
                  width: 32.w, height: 32.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      _gold.withOpacity(0.25),
                      _gold.withOpacity(0.05),
                    ]),
                  ),
                  child: Center(
                    child: Text('✨',
                        style: TextStyle(fontSize: 16.sp)),
                  ),
                ),
                SizedBox(width: 10.w),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _showAIScanner ? 'Đóng AI Scanner' : 'Dùng AI nhận diện',
                      style: TextStyle(
                        fontSize: 14.sp, fontWeight: FontWeight.w700,
                        color: _gold,
                      ),
                    ),
                    Text(
                      'Chụp hoá đơn để tự động điền',
                      style: TextStyle(
                        fontSize: 11.sp, color: _textSecondary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: _showAIScanner ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      color: _gold, size: 20.sp),
                ),
                SizedBox(width: 16.w),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── AI Scanner panel ────────────────────────────────────────────
  Widget _buildAIScannerPanel() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: _gold.withOpacity(0.2), width: 1.w),
        ),
        child: Column(
          children: [
            // Camera viewfinder mock
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              child: Container(
                height: 200.h,
                color: const Color(0xFF080808),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Grid lines (viewfinder feel)
                    CustomPaint(painter: _ViewfinderPainter()),

                    // Corner brackets
                    Positioned(top: 20.h,   left: 20.w,  child: _corner(false, false)),
                    Positioned(top: 20.h,   right: 20.w, child: _corner(false, true)),
                    Positioned(bottom: 20.h, left: 20.w,  child: _corner(true, false)),
                    Positioned(bottom: 20.h, right: 20.w, child: _corner(true, true)),

                    // Scanning line animation
                    if (_isScanning)
                      AnimatedBuilder(
                        animation: _scanAnim,
                        builder: (_, __) => Positioned(
                          top: _scanAnim.value * 160.h + 20.h,
                          left: 20.w,
                          right: 20.w,
                          child: Container(
                            height: 2.h,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                Colors.transparent,
                                _gold.withOpacity(0.8),
                                Colors.transparent,
                              ]),
                            ),
                          ),
                        ),
                      ),

                    // Center prompt
                    if (!_isScanning)
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 56.w, height: 56.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _gold.withOpacity(0.1),
                                border: Border.all(
                                    color: _gold.withOpacity(0.3), width: 1.w),
                              ),
                              child: Icon(Icons.camera_alt_outlined,
                                  color: _gold, size: 24.sp),
                            ),
                            SizedBox(height: 10.h),
                            Text('Hướng camera vào hoá đơn',
                                style: TextStyle(
                                  fontSize: 12.sp, color: _textSecondary,
                                )),
                          ],
                        ),
                      ),

                    // Scanning overlay text
                    if (_isScanning)
                      Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 14.w, height: 14.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _gold,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text('AI đang nhận diện...',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: _gold,
                                    fontWeight: FontWeight.w600,
                                  )),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Action buttons
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  // Chụp ảnh
                  Expanded(
                    child: _scanActionBtn(
                      icon: Icons.camera_alt_rounded,
                      label: 'Chụp hoá đơn',
                      color: _gold,
                      onTap: _isScanning ? null : _startAIScan,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // Chọn từ thư viện
                  Expanded(
                    child: _scanActionBtn(
                      icon: Icons.photo_library_outlined,
                      label: 'Chọn ảnh',
                      color: _blue,
                      onTap: _isScanning ? null : () {
                        // TODO: mở image picker
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Tips
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              child: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: _gold.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: _gold.withOpacity(0.15), width: 1.w),
                ),
                child: Row(
                  children: [
                    Text('💡', style: TextStyle(fontSize: 14.sp)),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'AI có thể nhận diện: số tiền, tên cửa hàng, ngày giao dịch từ hoá đơn',
                        style: TextStyle(
                          fontSize: 11.sp, color: _textSecondary, height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scanActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.4 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: 46.h,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: color.withOpacity(0.3), width: 1.w),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18.sp),
              SizedBox(width: 6.w),
              Text(label,
                  style: TextStyle(
                    fontSize: 13.sp, color: color, fontWeight: FontWeight.w600,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // Corner bracket widget
  Widget _corner(bool bottom, bool right) {
    return CustomPaint(
      size: Size(20.w, 20.w),
      painter: _CornerPainter(
        bottom: bottom, right: right, color: _gold,
      ),
    );
  }

  // ── Category grid ────────────────────────────────────────────────
  Widget _buildCategorySection() {
    final cats = _filteredCats;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Danh mục'),
          SizedBox(height: 10.h),
          cats.isEmpty
              ? _emptySection('Chưa có danh mục')
              : GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10.w,
              mainAxisSpacing: 10.h,
              childAspectRatio: 0.85,
            ),
            itemCount: cats.length,
            itemBuilder: (_, i) => _buildCatCell(cats[i]),
          ),
        ],
      ),
    );
  }

  Widget _buildCatCell(CategoryModel cat) {
    final isSelected = _selectedCat?.id == cat.id;
    final color      = _parseColor(cat.colorHex);
    return GestureDetector(
      onTap: () => setState(() => _selectedCat = cat),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : _surface,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.5) : _border,
            width: isSelected ? 1.5.w : 1.w,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 180),
              child: Text(cat.icon, style: TextStyle(fontSize: 22.sp)),
            ),
            SizedBox(height: 5.h),
            Text(
              cat.name,
              style: TextStyle(
                fontSize: 10.sp,
                color: isSelected ? color : _textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ── Wallet selector ──────────────────────────────────────────────
  Widget _buildWalletSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Ví thanh toán'),
          SizedBox(height: 10.h),
          SizedBox(
            height: 72.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _wallets.length,
              itemBuilder: (_, i) {
                final w          = _wallets[i];
                final isSelected = _selectedWallet?.id == w.id;
                final color      = _parseColor(w.colorHex);
                return GestureDetector(
                  onTap: () => setState(() => _selectedWallet = w),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: EdgeInsets.only(right: 10.w),
                    padding: EdgeInsets.symmetric(
                        horizontal: 14.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withOpacity(0.12) : _surface,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: isSelected ? color.withOpacity(0.5) : _border,
                        width: isSelected ? 1.5.w : 1.w,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(w.icon, style: TextStyle(fontSize: 20.sp)),
                        SizedBox(width: 10.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(w.name,
                                style: TextStyle(
                                  fontSize: 13.sp, fontWeight: FontWeight.w600,
                                  color: isSelected ? _textPrimary : _textSecondary,
                                )),
                            Text(
                              '${(w.balance / 1000000).toStringAsFixed(1)}M ₫',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: isSelected ? color : _textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Date ─────────────────────────────────────────────────────────
  Widget _buildDateSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Ngày giao dịch'),
          SizedBox(height: 10.h),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              height: 50.h,
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: _border, width: 1.w),
              ),
              child: Row(
                children: [
                  SizedBox(width: 16.w),
                  Icon(Icons.calendar_today_rounded, color: _gold, size: 18.sp),
                  SizedBox(width: 12.w),
                  Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: TextStyle(
                      fontSize: 15.sp, color: _textPrimary, fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(_formatDate(_selectedDate),
                      style: TextStyle(fontSize: 12.sp, color: _gold)),
                  SizedBox(width: 16.w),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Note ─────────────────────────────────────────────────────────
  Widget _buildNoteSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Ghi chú (tuỳ chọn)'),
          SizedBox(height: 10.h),
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            style: TextStyle(color: _textPrimary, fontSize: 14.sp),
            decoration: InputDecoration(
              hintText: 'Thêm ghi chú cho giao dịch này...',
              hintStyle: TextStyle(color: _textSecondary.withOpacity(0.5)),
              filled: true,
              fillColor: _surface,
              contentPadding: EdgeInsets.all(16.w),
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
                    color: _txColor.withOpacity(0.5), width: 1.5.w),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Save button ──────────────────────────────────────────────────
  Widget _buildSaveButton() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: SizedBox(
        width: double.infinity,
        height: 56.h,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: _txColor,
            disabledBackgroundColor: _txColor.withOpacity(0.3),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18.r)),
          ),
          child: _isLoading
              ? SizedBox(
            width: 22.w, height: 22.w,
            child: CircularProgressIndicator(
                strokeWidth: 2.5, color: Colors.white),
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded, size: 22.sp),
              SizedBox(width: 8.w),
              Text(
                _txType == TransactionType.income
                    ? 'Lưu thu nhập'
                    : _txType == TransactionType.expense
                    ? 'Lưu chi tiêu'
                    : 'Lưu chuyển khoản',
                style: TextStyle(
                  fontSize: 16.sp, fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────
  Widget _sectionLabel(String text) => Text(text,
      style: TextStyle(
        fontSize: 13.sp, fontWeight: FontWeight.w600,
        color: _textSecondary, letterSpacing: 0.3,
      ));

  Widget _emptySection(String msg) => Container(
    height: 60.h,
    alignment: Alignment.center,
    child: Text(msg,
        style: TextStyle(fontSize: 13.sp, color: _textSecondary)),
  );
}

// ── VND Formatter ────────────────────────────────────────────────────
class _VndFormatter extends TextInputFormatter {
  static String format(int v) {
    final s = v.toString();
    final result = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) result.write('.');
      result.write(s[i]);
    }
    return result.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue val) {
    final digits = val.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return val.copyWith(text: '');
    final clean = digits.replaceFirst(RegExp(r'^0+'), '');
    if (clean.isEmpty) return val.copyWith(text: '0');
    final result = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      if (i > 0 && (clean.length - i) % 3 == 0) result.write('.');
      result.write(clean[i]);
    }
    final s = result.toString();
    return val.copyWith(
      text: s, selection: TextSelection.collapsed(offset: s.length),
    );
  }
}

// ── Viewfinder grid painter ──────────────────────────────────────────
class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2A2A38)
      ..strokeWidth = 0.5;
    for (int i = 1; i < 3; i++) {
      final x = size.width * i / 3;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override bool shouldRepaint(_) => false;
}

// ── Corner bracket painter ───────────────────────────────────────────
class _CornerPainter extends CustomPainter {
  final bool bottom, right;
  final Color color;
  _CornerPainter({required this.bottom, required this.right, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final x = right ? 0.0 : size.width;
    final y = bottom ? 0.0 : size.height;
    final dx = right ? size.width : -size.width;
    final dy = bottom ? size.height : -size.height;
    canvas.drawLine(Offset(x, y), Offset(x + dx, y), paint);
    canvas.drawLine(Offset(x, y), Offset(x, y + dy), paint);
  }
  @override bool shouldRepaint(_) => false;
}