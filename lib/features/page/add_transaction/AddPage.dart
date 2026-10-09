import 'dart:io';

import 'package:camera/camera.dart';
import 'package:expense_tracker/data/firebase/TransactionStorage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/firebase/WalletStorage.dart';
import '../../../data/model/CategoryModel.dart';
import '../../../data/model/TransactionModel.dart';
import '../../../data/model/WalletModel.dart';
import '../../../data/repositories/services/OCRService.dart';
import '../../../data/repositories/local/DatabaseHelper.dart';
import '../HomePage/bloc/transaction_bloc/transaction_bloc.dart';
import '../HomePage/bloc/transaction_bloc/transaction_event.dart';
import '../HomePage/bloc/wallet_bloc/wallet_bloc.dart';
import '../HomePage/bloc/wallet_bloc/wallet_event.dart';
import '../HomePage/bloc/wallet_bloc/wallet_state.dart';
import 'app_colors.dart';
import 'models/sample_data.dart';
import 'widgets/amount_section.dart';
import 'widgets/ai_scanner.dart';
import 'widgets/category_section.dart';
import 'widgets/wallet_section.dart';
import 'widgets/transfer_section.dart';

class AddPage extends StatefulWidget {
  final String userId;
  final List<CategoryModel> categories;

  const AddPage({super.key, required this.userId, this.categories = const []});

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> with TickerProviderStateMixin {
  final ReceiptAIService _geminiServices = ReceiptAIService();
  final walletStorage = WalletStorage();
  final transactionStorage = TransactionStorage();
  // ── Controllers ────────────────────────────────────────────────
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  late final AnimationController _scanCtrl;
  late final Animation<double> _scanAnim;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  //- Camera
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  File? _previewImage;
  XFile? _capturedImage;
  bool _flashEnabled = false;
  bool _cameraInitializing = false;
  String? _cameraError;
  Offset? _focusPoint;

  // ── State ──────────────────────────────────────────────────────
  TransactionType _txType = TransactionType.expense;
  CategoryModel? _selectedCat;
  WalletModel? _selectedWallet;
  WalletModel? _transferFrom;
  WalletModel? _transferTo;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _showScanner = false;
  bool _isScanning = false;
  String? _cachedReceiptThumbnail;
  String? _extractedMerchantName;

  // ── Data ───────────────────────────────────────────────────────
  List<CategoryModel> get _categories =>
      widget.categories.isNotEmpty ? widget.categories : SampleData.categories;

  List<CategoryModel> get _filteredCats => _categories.where((c) {
    if (_txType == TransactionType.income) return c.type == CategoryType.income;
    if (_txType == TransactionType.expense)
      return c.type == CategoryType.expense;
    return true;
  }).toList();

  // ── Lifecycle ──────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initCamera();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _scanAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut));

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }
  Future<void> _initCamera() async {
    if (_cameraInitializing) return;
    _cameraInitializing = true;
    try {
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) throw CameraException('NoCamera', 'Không tìm thấy camera.');
      final camera = _cameras!.firstWhere((item) => item.lensDirection == CameraLensDirection.back, orElse: () => _cameras!.first);
      final controller = CameraController(camera, ResolutionPreset.medium, enableAudio: false);
      _cameraController = controller;
      await controller.initialize();
      if (mounted) setState(() => _cameraError = null);
    } on CameraException catch (e) {
      if (mounted) setState(() => _cameraError = e.description ?? 'Không thể mở camera (${e.code}).');
    } catch (e) {
      if (mounted) setState(() => _cameraError = 'Không thể khởi tạo camera: $e');
    } finally {
      _cameraInitializing = false;
    }
  }
  @override
  void dispose() {
    _cameraController?.dispose();
    _fadeCtrl.dispose();
    _scanCtrl.dispose();
    _pulseCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────
  Color get _txColor {
    switch (_txType) {
      case TransactionType.income:
        return AppColors.green;
      case TransactionType.expense:
        return AppColors.red;
      case TransactionType.transfer:
        return AppColors.blue;
    }
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    if (d.day == now.day && d.month == now.month && d.year == now.year)
      return 'Hôm nay';
    return '${d.day}/${d.month}/${d.year}';
  }

  // ── Actions ────────────────────────────────────────────────────
  void _switchType(TransactionType type, List<WalletModel> wallets) {
    setState(() {
      _txType = type;
      _selectedCat = null;
      _showScanner = false;
      if (type == TransactionType.transfer && wallets.length >= 2) {
        _transferFrom = wallets.first;
        _transferTo = wallets[1];
      }
    });
  }

  Future<void> _startAIScan() async{
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _snack('Camera chưa sẵn sàng', color: AppColors.red);
      return;
    }
    setState(() => _isScanning = true);
    _scanCtrl.repeat(reverse: true);

    try{
      final XFile image = await _cameraController!.takePicture();
      // await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      _scanCtrl.stop();

      setState(() {
        _capturedImage = image;
        _isScanning = false;

        // _amountCtrl.text = '125.000'; // Số tiền nhận diện được
        // _noteCtrl.text = 'Hóa đơn cửa hàng - AI Scan';

        // Tự động chọn danh mục phù hợp nếu cần
        // if (_filteredCats.isNotEmpty) {
        //   _selectedCat = _filteredCats.first;
        // }
      });
    }catch(e){
      _scanCtrl.stop();
      setState(() => _isScanning = false);
      _snack('Lỗi khi chụp ảnh: $e', color: AppColors.red);
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized || _capturedImage != null) return;
    try {
      final enabled = !_flashEnabled;
      await controller.setFlashMode(enabled ? FlashMode.torch : FlashMode.off);
      if (mounted) setState(() => _flashEnabled = enabled);
    } on CameraException catch (e) {
      if (mounted) _snack(e.description ?? 'Thiết bị không hỗ trợ flash.', color: AppColors.red);
    }
  }

  Future<void> _focusCamera(TapDownDetails details, Size size) async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized || _capturedImage != null || size.isEmpty) return;
    final point = Offset((details.localPosition.dx / size.width).clamp(0.0, 1.0), (details.localPosition.dy / size.height).clamp(0.0, 1.0));
    setState(() => _focusPoint = point);
    try {
      await controller.setFocusPoint(point);
      await controller.setExposurePoint(point);
    } on CameraException catch (e) {
      if (mounted) _snack(e.description ?? 'Không thể lấy nét tại vị trí này.', color: AppColors.red);
    } catch (e) {
      if (mounted) _snack('Thiết bị không hỗ trợ lấy nét chạm: $e', color: AppColors.red);
    }
  }

  void _retakePhoto() => setState(() => _capturedImage = null);

  Future<void> _useCapturedPhoto() async {
    final image = _capturedImage;
    if (image == null) return;
    setState(() => _capturedImage = null);
    await processDetailed(image);
  }
  // Đọc văn bản từ hình ảnh bằng On-Device ML Kit và Heuristic Regex
  Future<void> processDetailed(XFile image) async {
    if (!mounted) return;

    final imageFile = File(image.path);
    setState(() {
      _previewImage = imageFile;
      _isScanning = true;
      _isLoading = true;
    });

    // Chạy hiệu ứng thanh quét kính ngắm
    _scanCtrl.repeat(reverse: true);
    try {
      // 1. Cache và nén thumbnail hóa đơn vào thư mục app local (thực hiện yêu cầu đề bài)
      final cachedPath = await DatabaseHelper.instance.cacheReceiptThumbnail(imageFile);
      if (mounted && cachedPath != null) {
        _cachedReceiptThumbnail = cachedPath;
      }

      // 2. Nhận diện offline on-device bằng Google ML Kit có framing crop
      final cleanData = await _geminiServices.scanReceipt(
        imageFile,
        cropRectRatio: const Rect.fromLTWH(0.05, 0.08, 0.90, 0.84),
      );

      if (cleanData != null && mounted) {
        setState(() {
          // Tự động điền số tiền
          if (cleanData['total'] != null) {
            _amountCtrl.text = cleanData['total'].toString();
          }

          // Tự động điền tên cửa hàng / ghi chú
          _extractedMerchantName = cleanData['merchantName'];
          if (cleanData['note'] != null) {
            _noteCtrl.text = cleanData['note'];
          }

          // Tự động cập nhật ngày giao dịch từ hóa đơn
          if (cleanData['date'] is DateTime) {
            _selectedDate = cleanData['date'] as DateTime;
          }

          // Phân loại danh mục tự động (Food, Study, Travel, Gear, Entertainment)
          String idFromAI = cleanData['categoryId'] ?? '1';
          _selectedCat = SampleData.categories.firstWhere(
            (cat) => cat.id == idFromAI,
            orElse: () => SampleData.categories[0],
          );
        });
        _snack("Quét hóa đơn Offline (Google ML Kit) thành công!");
      } else {
        _snack("Không trích xuất được văn bản từ ảnh", color: AppColors.red);
      }
    } catch (e) {
      debugPrint("Lỗi xử lý OCR: $e");
      _snack("Lỗi hệ thống khi quét ảnh", color: AppColors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _isLoading = false;
          _previewImage = null;
        });
        _scanCtrl.stop();
      }
    }
  }

  Future<XFile?> pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();

      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1280,
      );

      return pickedFile;
    } catch (e) {
      debugPrint("Lỗi chọn ảnh: $e");
      return null;
    }
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
            primary: AppColors.gold,
            surface: AppColors.card,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    // 1. Kiểm tra đầu vào (Validate review form)
    final amountText = _amountCtrl.text.replaceAll('.', '').replaceAll(',', '');
    if (amountText.isEmpty || double.tryParse(amountText) == null || double.parse(amountText) <= 0) {
      _snack('Vui lòng nhập số tiền hợp lệ', color: AppColors.red);
      return;
    }

    if (_txType != TransactionType.transfer && _selectedCat == null) {
      _snack('Vui lòng chọn danh mục', color: AppColors.red);
      return;
    }

    // 2. Bắt đầu quá trình lưu
    setState(() => _isLoading = true);

    try {
      final double finalAmount = double.parse(amountText);
      final txId = 'tx_${DateTime.now().millisecondsSinceEpoch}';

      // 3. Lưu vào Local Database (SQLite) theo đúng yêu cầu đề bài Mini-Project 3
      final localTx = TransactionModel(
        id: txId,
        userId: widget.userId,
        categoryId: _txType == TransactionType.transfer ? 'TRANSFER_SYSTEM' : _selectedCat!.id,
        walletId: _txType == TransactionType.transfer ? (_transferFrom?.id ?? '') : (_selectedWallet?.id ?? ''),
        amount: finalAmount,
        type: _txType,
        note: _noteCtrl.text.trim(),
        merchantName: _extractedMerchantName,
        receiptImagePath: _cachedReceiptThumbnail,
        date: _selectedDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await DatabaseHelper.instance.insertTransaction(localTx);

      // 4. Đồng bộ thêm lên Firestore nếu có mạng / hỗ trợ sync
      try {
        if (_selectedWallet != null || _txType == TransactionType.transfer) {
          await transactionStorage.saveTransaction(
            userId: widget.userId,
            categoryId: _txType == TransactionType.transfer ? 'TRANSFER_SYSTEM' : _selectedCat!.id,
            walletId: _txType == TransactionType.transfer ? _transferFrom!.id : _selectedWallet!.id,
            toWalletId: _txType == TransactionType.transfer ? _transferTo!.id : null,
            amount: finalAmount,
            type: _txType,
            note: _noteCtrl.text.trim(),
            date: _selectedDate,
          );
        }
      } catch (firestoreError) {
        debugPrint("Lưu Firestore offline/bỏ qua: $firestoreError");
      }

      // 5. Cập nhật Bloc State
      if (mounted) {
        context.read<WalletBloc>().add(RefreshWallets(widget.userId));
        context.read<TransactionBloc>().add(AddTransaction(localTx));
        _snack(_txType == TransactionType.transfer
            ? 'Chuyển tiền thành công!'
            : 'Đã lưu giao dịch vào cơ sở dữ liệu (SQLite)!');

        _amountCtrl.text = '';
        _noteCtrl.text = '';
        _cachedReceiptThumbnail = null;
        _extractedMerchantName = null;
      }
    } catch (e) {
      _snack('Lỗi hệ thống: $e', color: AppColors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp),
        ),
        backgroundColor: color ?? AppColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          List<WalletModel> currentWallets = [];

          if (state is WalletLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          }

          if (state is WalletLoaded) {
            currentWallets = state.wallets;
            // Khởi tạo ví mặc định khi dữ liệu vừa tải xong
            if (_selectedWallet == null && currentWallets.isNotEmpty) {
              _selectedWallet = currentWallets.first;
              _transferFrom = currentWallets.first;
              _transferTo = currentWallets.length > 1
                  ? currentWallets[1]
                  : null;
            }
          } else if (state is WalletError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          return FadeTransition(
            opacity: _fadeAnim,
            child: SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(child: SizedBox(height: 20.h)),
                  SliverToBoxAdapter(child: _buildTypeSelector(currentWallets)),
                  SliverToBoxAdapter(child: SizedBox(height: 20.h)),
                  SliverToBoxAdapter(
                    child: AmountSection(
                      controller: _amountCtrl,
                      txType: _txType,
                    ),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: 16.h)),

                  if (_txType == TransactionType.expense) ...[
                    SliverToBoxAdapter(
                      child: AIScannerButton(
                        isOpen: _showScanner,
                        pulseAnim: _pulseAnim,
                        onTap: () =>
                            setState(() => _showScanner = !_showScanner),
                      ),
                    ),
                    if (_showScanner) ...[
                      SliverToBoxAdapter(child: SizedBox(height: 12.h)),
                      SliverToBoxAdapter(
                        child: AIScannerPanel(
                          isScanning: _isScanning,
                          scanAnim: _scanAnim,
                          onCapture: _startAIScan,
                          onPickImage: () async{
                            final imageFile = await pickImageFromGallery();
                            if(imageFile != null){
                              setState(() {
                                _showScanner = true;
                              });
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                processDetailed(imageFile);
                              });
                            }
                            },
                          controller: _cameraController,
                          previewImage: _previewImage,
                          capturedImage: _capturedImage,
                          cameraError: _cameraError,
                          focusPoint: _focusPoint,
                          flashEnabled: _flashEnabled,
                          onFlashToggle: _toggleFlash,
                          onFocus: _focusCamera,
                          onRetake: _retakePhoto,
                          onUsePhoto: _useCapturedPhoto,
                        ),
                      ),
                    ],
                  ],

                  SliverToBoxAdapter(child: SizedBox(height: 20.h)),
                  SliverToBoxAdapter(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (_txType != TransactionType.transfer) ...[
                            CategorySection(
                              categories: _filteredCats,
                              selectedCat: _selectedCat,
                              onSelected: (cat) =>
                                  setState(() => _selectedCat = cat),
                            ),
                            SizedBox(height: 16.h),
                            WalletSection(
                              wallets: currentWallets,
                              selectedWallet: _selectedWallet,
                              onSelected: (w) =>
                                  setState(() => _selectedWallet = w),
                            ),
                          ] else ...[
                            TransferSection(
                              wallets: currentWallets,
                              fromWallet: _transferFrom,
                              toWallet: _transferTo,
                              amountText: _amountCtrl.text,
                              onFromChanged: (w) => setState(() {
                                _transferFrom = w;
                                if (_transferTo?.id == w.id) {
                                  _transferTo = currentWallets.firstWhere(
                                    (x) => x.id != w.id,
                                    orElse: () => w,
                                  );
                                }
                              }),
                              onToChanged: (w) => setState(() {
                                _transferTo = w;
                                if (_transferFrom?.id == w.id) {
                                  _transferFrom = currentWallets.firstWhere(
                                    (x) => x.id != w.id,
                                    orElse: () => w,
                                  );
                                }
                              }),
                              onSwap: () => setState(() {
                                final tmp = _transferFrom;
                                _transferFrom = _transferTo;
                                _transferTo = tmp;
                              }),
                            ),
                          ],
                          SizedBox(height: 16.h),
                          _buildDateSection(),
                          SizedBox(height: 16.h),
                          _buildNoteSection(),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: 24.h)),
                  SliverToBoxAdapter(child: _buildSaveButton()),
                  SliverToBoxAdapter(child: SizedBox(height: 32.h)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Header & Widgets khác ──────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thêm giao dịch',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Nhập thủ công hoặc dùng AI',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: AppColors.border, width: 1.w),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    color: AppColors.gold,
                    size: 13.sp,
                  ),
                  SizedBox(width: 5.w),
                  Text(
                    _formatDate(_selectedDate),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector(List<WalletModel> wallets) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.border, width: 1.w),
        ),
        child: Row(
          children: [
            _typeTab(
              TransactionType.income,
              '↑',
              'Thu nhập',
              AppColors.green,
              wallets,
            ),
            SizedBox(width: 4.w),
            _typeTab(
              TransactionType.expense,
              '↓',
              'Chi tiêu',
              AppColors.red,
              wallets,
            ),
            SizedBox(width: 4.w),
            _typeTab(
              TransactionType.transfer,
              '⇄',
              'Chuyển',
              AppColors.blue,
              wallets,
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeTab(
    TransactionType type,
    String arrow,
    String label,
    Color color,
    List<WalletModel> wallets,
  ) {
    final isSelected = _txType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchType(type, wallets),
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
              Text(
                arrow,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isSelected ? color : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 5.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isSelected ? color : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Ngày giao dịch'),
          SizedBox(height: 10.h),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              height: 50.h,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColors.border, width: 1.w),
              ),
              child: Row(
                children: [
                  SizedBox(width: 16.w),
                  Icon(
                    Icons.calendar_today_rounded,
                    color: AppColors.gold,
                    size: 18.sp,
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(_selectedDate),
                    style: TextStyle(fontSize: 12.sp, color: AppColors.gold),
                  ),
                  SizedBox(width: 16.w),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Ghi chú (tuỳ chọn)'),
          SizedBox(height: 10.h),
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 14.sp),
            decoration: InputDecoration(
              hintText: 'Thêm ghi chú cho giao dịch này...',
              hintStyle: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: EdgeInsets.all(16.w),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide(color: AppColors.border, width: 1.w),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide(color: AppColors.border, width: 1.w),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide(
                  color: _txColor.withOpacity(0.5),
                  width: 1.5.w,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
              borderRadius: BorderRadius.circular(18.r),
            ),
          ),
          child: _isLoading
              ? SizedBox(
                  width: 22.w,
                  height: 22.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
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
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 13.sp,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
      letterSpacing: 0.3,
    ),
  );
}
