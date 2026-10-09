# Mini-Project 3: OCR Expense Tracker & Receipt Parser (Flutter & Dart)

An advanced personal finance and receipt parsing application built with Flutter, powered by **On-Device Google ML Kit**, **Heuristic Regex Engine**, **Offline SQLite Database**, and **Interactive CustomPainter Canvas Charts**.

---

## 🎯 Learning Objectives & Deliverables Met

- ✅ **On-Device AI Offline Receipt Parsing**: Integrated `google_mlkit_text_recognition` for sub-100ms offline text extraction (zero cloud cost).
- ✅ **Custom Heuristic Regex Engine**: Bóc tách chính xác tổng tiền (`150,000 VND`, `150.000 đ`), ngày giao dịch (`DD/MM/YYYY`), và tên thương hiệu/cửa hàng.
- ✅ **Live Camera & Framing Crop Overlay**: Kính ngắm trực tiếp, bật/tắt flash, chạm lấy nét (tap-to-focus) và cắt ảnh theo khung kính ngắm trước khi quét.
- ✅ **Local Database & Transaction Lifecycle**: Lưu trữ offline bền vững bằng `sqflite` với 5 nhóm danh mục chuẩn sinh viên (`Food`, `Study`, `Travel`, `Gear`, `Entertainment`) và cơ chế cache nén thumbnail hóa đơn trong bộ nhớ máy.
- ✅ **Custom Canvas Visualizations**: Vẽ biểu đồ tròn phân bổ danh mục (Donut Chart) và biểu đồ cột chi tiêu tuần (Weekly Bar Chart) bằng `CustomPainter`, hoạt họa mượt mà, không phụ thuộc thư viện đồ thị bên thứ ba.

---

## 🏗️ Kiến trúc dự án (Modular Architecture)

```
lib/
├── core/
│   ├── format/                 # Bộ định dạng tiền tệ VND
│   ├── helper/                 # Alert dialog & helpers
│   └── widget/                 # Main Bottom Navigation Screen
├── data/
│   ├── model/                  # Data Models (Transaction, Category, Wallet, User)
│   ├── firebase/               # Tích hợp Cloud Firestore & Storage
│   └── repositories/
│       ├── local/              # DatabaseHelper (SQLite & Receipt Thumbnail Cache)
│       └── services/           
│           ├── ReceiptMLKitService.dart # Google ML Kit On-Device & Regex Heuristics
│           ├── OCRService.dart          # Adapter OCR Service
│           ├── PermissionService.dart   # Quản lý quyền Camera, Storage
│           └── notification.dart        # Thông báo cục bộ & FCM
└── features/
    ├── intro/                  # Splash screen & kiểm tra đăng nhập
    ├── auth/                   # Màn hình Login / Register
    └── page/
        ├── HomePage/           # Quản lý ví, danh sách giao dịch gần đây, BLoC
        ├── add_transaction/    # Live Camera, AI Scanner, Framing Crop, Review Form
        ├── AnalyticsPage/      # Thống kê & Custom Canvas Visualizations
        │   └── CanvasChartsPage.dart # DonutChart & WeeklyBarChart bằng CustomPainter
        ├── AIPage/             # Trợ lý tài chính cá nhân AI
        └── SettingsPage/       # Quản lý cài đặt & thông tin người dùng
```

---

## 🚀 Hướng dẫn cài đặt & Chạy ứng dụng

### 1. Yêu cầu môi trường
- **Flutter SDK**: `^3.10.0` (Khuyến nghị `3.24.x` trở lên)
- **Dart SDK**: `^3.x`
- **Android Studio / VS Code** với Flutter extension
- **Thiết bị**: Android thiết bị thật hoặc máy ảo (hỗ trợ Camera & Google Play Services)

### 2. Cài đặt Dependencies
```bash
flutter pub get
```

### 3. Chạy ứng dụng (Debug Mode)
```bash
flutter run
```

### 4. Build Release APK để nộp bài
```bash
flutter build apk --release
```
File APK xuất ra tại đường dẫn:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## 📋 Feature Checklist (Bảng đối chiếu yêu cầu Mini-Project 3)

| Nhóm chức năng | Chi tiết yêu cầu | Tình trạng |
| :--- | :--- | :---: |
| **1. Camera & Framing Crop** | Live viewfinder + Flash toggle + Tap to focus | ✅ Đạt 100% |
| | Framing crop overlay (cắt ảnh theo khung kính ngắm) | ✅ Đạt 100% |
| **2. On-Device OCR & Regex** | Google ML Kit on-device (offline, sub-100ms, $0) | ✅ Đạt 100% |
| | Regex parse total amount (`150,000 VND`, `150.000 đ`) | ✅ Đạt 100% |
| | Regex parse transaction dates (`DD/MM/YYYY`) | ✅ Đạt 100% |
| | Heuristic extract merchant name (Tên cửa hàng) | ✅ Đạt 100% |
| | Interactive review screen (cho phép chỉnh sửa trước khi lưu) | ✅ Đạt 100% |
| **3. Local Database & Storage** | Persistent storage với `sqflite` | ✅ Đạt 100% |
| | Phân loại 5 nhóm: Food, Study, Travel, Gear, Entertainment | ✅ Đạt 100% |
| | Cache thumbnail hóa đơn vào thư mục app storage | ✅ Đạt 100% |
| **4. Custom Canvas Charts** | Animated category distribution donut chart (`CustomPainter`) | ✅ Đạt 100% |
| | Interactive weekly spending bar chart (`CustomPainter`) | ✅ Đạt 100% |
| | Không sử dụng thư viện chart bên thứ ba | ✅ Đạt 100% |