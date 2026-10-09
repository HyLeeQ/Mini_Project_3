# BÁO CÁO KỸ THUẬT MINI-PROJECT 3
## OCR Expense Tracker & Receipt Parser (Flutter & Dart)

- **Môn học:** Lập trình Thiết bị Di động nâng cao / Flutter Development
- **Học phần:** Mini-Project 3 (Weight: 10%)
- **Nền tảng:** Flutter 3.x, Dart 3.x
- **Sinh viên thực hiện:** Đội ngũ phát triển Expense Tracker

---

## 1. TỔNG QUAN DỰ ÁN & VẤN ĐỀ GIẢI QUYẾT (Project Overview & Problem Scenario)

### 1.1 Vấn đề thực tế
Sinh viên và thủ quỹ các câu lạc bộ thường xuyên phải xử lý số lượng lớn hóa đơn giấy từ siêu thị, quán ăn, nhà sách, và cửa hàng tiện lợi. Việc nhập tay từng con số vào bảng tính (Excel/Google Sheets) tốn nhiều thời gian, dễ nhầm lẫn và thiếu tính trực quan trong theo dõi ngân sách.

### 1.2 Giải pháp ứng dụng
Dự án **OCR Expense Tracker & Receipt Parser** cung cấp giải pháp quản lý tài chính thông minh:
1. **Quét hóa đơn offline trực tiếp:** Ứng dụng tích hợp **Google ML Kit** chạy trực tiếp trên thiết bị (On-Device), nhận diện văn bản nhanh dưới 100ms, không phụ thuộc vào internet và không tốn chi phí gọi API đám mây.
2. **Bộ bóc tách Heuristic Regex:** Tự động trích xuất tổng số tiền, ngày giao dịch, tên cửa hàng và phân loại vào các nhóm danh mục phù hợp.
3. **Lưu trữ cục bộ SQLite (`sqflite`):** Đảm bảo tính toàn vẹn dữ liệu ngoại tuyến, kèm cơ chế nén và lưu trữ thumbnail hóa đơn.
4. **Biểu đồ động vẽ bằng Canvas (`CustomPainter`):** Trực quan hóa chi tiêu theo tuần và theo danh mục mà không cần phụ thuộc vào thư viện bên thứ ba.

---

## 2. KIẾN TRÚC HỆ THỐNG & CẤU TRÚC MÃ NGUỒN (System Architecture)

### 2.1 Sơ đồ kiến trúc tầng (Layered Architecture)
```
┌────────────────────────────────────────────────────────┐
│             PRESENTATION / UI LAYER                    │
│  - Live Viewfinder & Framing Overlay (CameraPreview)   │
│  - Interactive Review Screen (Form Fields & Inputs)    │
│  - Canvas Charts Page (_DonutPainter, _WeeklyPainter)  │
└───────────────────────────▲────────────────────────────┘
                            │
┌───────────────────────────┴────────────────────────────┐
│              BUSINESS LOGIC LAYER (BLoC)               │
│  - TransactionBloc (Offline-first State & Events)      │
│  - WalletBloc (Balance & Transfer Operations)          │
└───────────────────────────▲────────────────────────────┘
                            │
┌───────────────────────────┴────────────────────────────┐
│             DATA & SERVICE LAYER                       │
│  - ReceiptMLKitService (Google ML Kit Latin OCR)       │
│  - Heuristic Regex Engine (Amount, Date, Merchant)     │
│  - DatabaseHelper (SQLite CRUD & Thumbnail Caching)    │
│  - Cloud Sync Adapter (Firebase Firestore Fallback)    │
└────────────────────────────────────────────────────────┘
```

### 2.2 Các Module chính
- `lib/data/repositories/services/ReceiptMLKitService.dart`: Xử lý nhận diện ký tự quang học offline và bóc tách dữ liệu theo biểu thức chính quy (Regex).
- `lib/data/repositories/local/DatabaseHelper.dart`: Quản lý CSDL SQLite (`expense_tracker.db`) và thư mục cache ảnh (`receipt_thumbnails/`).
- `lib/features/page/add_transaction/AddPage.dart`: Kính ngắm camera, hiệu ứng quét, form xác nhận và chỉnh sửa thông tin.
- `lib/features/page/AnalyticsPage/CanvasChartsPage.dart`: Hệ thống biểu đồ CustomPainter tự phát triển.

---

## 3. TRIỂN KHAI CÁC TÍNH NĂNG CỐT LÕI (Core Functional Implementations)

### 3.1 Camera Capture & Image Cropping
- **Kính ngắm trực tiếp (Live Viewfinder):** Tích hợp thông qua `camera: ^0.12.0+1`, tự động khởi tạo luồng camera với độ phân giải tối ưu.
- **Bật/Tắt đèn Flash:** Hỗ trợ chuyển đổi giữa chế độ `FlashMode.torch` và `FlashMode.off`.
- **Chạm lấy nét (Tap-to-Focus):** Bắt sự kiện `onTapDown`, tính toán tọa độ điểm chạm trên tỷ lệ khung hình và gọi `setFocusPoint()` kết hợp `setExposurePoint()`, đồng thời hiển thị khung viền hoạt họa màu vàng tại điểm chạm.
- **Framing Crop Overlay:** Overlay được vẽ bằng `CustomPainter (ViewfinderPainter)` với 4 góc căn chỉnh. Trước khi đưa ảnh vào mô hình nhận diện, hàm `cropImageWithRatio()` sẽ cắt ảnh theo đúng tỷ lệ khung ngắm nhằm loại bỏ tạp âm viền xung quanh.

### 3.2 On-Device Text Recognition & Regex Heuristics
- **Google ML Kit Text Recognition:** Sử dụng `TextRecognizer(script: TextRecognitionScript.latin)` trích xuất toàn bộ khối chữ trên thiết bị với độ trễ cực thấp (<100ms) và chi phí 0đ.
- **Regex trích xuất Tổng tiền (Monetary Totals):**
  - Bắt các từ khóa: `tổng cộng`, `tổng tiền`, `thành tiền`, `thanh toán`, `total`, `amount due`, `tiền mặt`.
  - Regex lọc số: `r'(?:[\$₫]|vnd|vnđ)?\s*(\d{1,3}(?:[\.,]\d{3})+(?:[\.,]\d{2})?|\d{4,})\s*(?:[\$₫]|vnd|vnđ)?'`.
  - Chuẩn hóa khoảng trắng và lọc bỏ số điện thoại, mã số thuế.
- **Regex trích xuất Ngày giao dịch (Transaction Dates):**
  - Regex bắt định dạng ngày: `DD/MM/YYYY`, `DD-MM-YYYY`, `DD.MM.YYYY`, `YYYY-MM-DD`.
  - Chuyển đổi trực tiếp thành đối tượng `DateTime`.
- **Heuristics trích xuất Tên cửa hàng (Merchant Names):**
  - Tự động nhận dạng các chuỗi siêu thị và cửa hàng phổ biến: Co.opmart, WinMart, Circle K, 7-Eleven, FamilyMart, Highlands Coffee, Phúc Long, KFC, Lotteria, Fahasa, Bách Hóa Xanh,...
  - Loại bỏ các dòng tiêu đề chung như `HÓA ĐƠN`, `PHIẾU TÍNH TIỀN`, `RECEIPT`, `MST`.
- **Màn hình Review tương tác:** Sau khi quét, toàn bộ thông tin (số tiền, danh mục, tên cửa hàng, ngày) tự động điền vào Form để người dùng kiểm tra, chỉnh sửa tùy ý trước khi xác nhận lưu.

### 3.3 Cơ sở dữ liệu cục bộ SQLite & Quản lý vòng đời giao dịch
- **SQLite Database (`sqflite`):** Bảng `transactions` lưu trữ đầy đủ thông tin giao dịch, hoạt động offline 100%.
- **5 Danh mục chuẩn đề bài:**
  1. `Food (Ăn uống)`
  2. `Study (Học tập)`
  3. `Travel (Di chuyển / Du lịch)`
  4. `Gear (Thiết bị / Đồ dùng)`
  5. `Entertainment (Giải trí)`
- **Thumbnail Caching:** Ảnh hóa đơn sau khi chụp được giải mã, nén xuống kích thước chuẩn (width 500px, quality 75) bằng package `image` và lưu vào thư mục `app_documents_path/receipt_thumbnails/`. Đường dẫn ảnh được lưu kèm vào bản ghi giao dịch.

### 3.4 Đồ họa Canvas tùy chỉnh (`CustomPainter`)
- **Donut Chart phân bổ chi tiêu:**
  - Lớp `_DonutCanvasPainter` vẽ cung tròn (`drawArc`) tương ứng với tỷ lệ phần trăm của từng danh mục.
  - Tích hợp `AnimationController` tạo hiệu ứng xoay tròn và nở góc mượt mà từ 0 đến 360 độ.
- **Weekly Spending Bar Chart:**
  - Lớp `_WeeklyCanvasPainter` vẽ lưới tọa độ (`drawLine`) và các cột chi tiêu theo ngày (`drawRRect`).
  - Hỗ trợ tương tác cảm ứng: người dùng chạm vào từng cột để xem chi tiết số tiền chi tiêu trong ngày.

---

## 4. BẢNG KIỂM TRA ĐÁNH GIÁ (Feature Checklist)

| Yêu cầu đề bài | Kết quả thực nghiệm | Đánh giá |
| :--- | :--- | :---: |
| Live camera viewfinder with flash toggle, focus tap, framing crop overlay | Hoạt động trơn tru trên thiết bị, lấy nét nhanh, có nút flash và crop khung ngắm | **PASS (100%)** |
| Google ML Kit Text Recognition on-device (offline, sub-100ms, zero cloud cost) | Tích hợp thành công `google_mlkit_text_recognition`, không cần kết nối mạng | **PASS (100%)** |
| Regex heuristic parser (Amount, Date, Merchant Name) | Bóc tách chính xác các hóa đơn mẫu phổ biến tại Việt Nam | **PASS (100%)** |
| Interactive review screen | Cho phép chỉnh sửa toàn bộ các trường trước khi nhấn Lưu | **PASS (100%)** |
| Persistent storage with `sqflite` (Food, Study, Travel, Gear, Entertainment) | Đầy đủ CRUD trên SQLite với 5 danh mục chuẩn | **PASS (100%)** |
| Receipt thumbnail caching in app storage | Nén và lưu ảnh vào bộ nhớ trong máy, liên kết với transaction | **PASS (100%)** |
| Animated Donut Chart & Weekly Bar Chart with CustomPainter | Tự vẽ 100% bằng Canvas, không dùng thư viện ngoài | **PASS (100%)** |

---

## 5. KẾT LUẬN & HƯỚNG PHÁT TRIỂN

Dự án đã hoàn thành **100% các tiêu chí kỹ thuật** theo yêu cầu của Mini-Project 3. Ứng dụng đáp ứng tốt bài toán số hóa hóa đơn nhanh chóng, chính xác, hoàn toàn offline và đem lại trải nghiệm giao diện người dùng hiện đại.
Hướng phát triển trong tương lai:
- Hỗ trợ xuất báo cáo sao kê dạng file CSV/Excel.
- Huấn luyện thêm mô hình trích xuất bảng chi tiết từng món đồ trong hóa đơn (Itemized receipts).
